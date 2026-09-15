## Board - 消除棋盘核心逻辑
class_name Board
extends Node2D

const AsyncUtilsScript = preload("res://scripts/utils/AsyncUtils.gd")

# ==================== 信号 ====================
signal tiles_swapped(pos1: Vector2i, pos2: Vector2i)
signal tiles_matched(positions: Array, tile_type: int)
signal tiles_fallen()
signal chain_triggered(chain_count: int)
signal board_updated()

# ==================== 变量 ====================
var grid: Array = []  # 2D数组存储元素类型
var selected_tile: Vector2i = Vector2i(-1, -1)
var board_processing: bool = false
var combo_count: int = 0
var available_types: Array = []
var garden_layers: Dictionary = {}
var dew_buds: Dictionary = {}
var special_grid: Array = []
var blocker_cells: Dictionary = {}
var blocker_hp: Dictionary = {}
var preferred_direction: String = ""
var random_generator := RandomNumberGenerator.new()

const MAX_CASCADE_CHAINS: int = 8

# ==================== 生命周期 ====================
func _ready() -> void:
	initialize_grid()

# ==================== 初始化 ====================
func initialize_grid(level_config: Dictionary = {}) -> void:
	grid.clear()
	special_grid.clear()

	configure(level_config)
	
	for row in range(Constants.GRID_ROWS):
		grid.append([])
		special_grid.append([])
		for col in range(Constants.GRID_COLS):
			grid[row].append(_get_random_tile_no_match(row, col))
			special_grid[row].append("")
	
	for blocker_pos in blocker_cells.keys():
		grid[blocker_pos.x][blocker_pos.y] = Constants.TileType.BLOCKER
	
	while find_all_matches().size() > 0:
		shuffle_board()
	
	while not has_valid_moves():
		shuffle_board()


func configure(level_config: Dictionary = {}) -> void:
	available_types = level_config.get("available_types", _get_default_types()).duplicate()
	if available_types.is_empty():
		available_types = _get_default_types()
	preferred_direction = str(level_config.get("daily_challenge", {}).get("preferred_direction", ""))
	var board_seed = int(level_config.get("board_seed", 0))
	if board_seed != 0:
		random_generator.seed = board_seed
	else:
		random_generator.randomize()
	garden_layers.clear()
	var layer_config = level_config.get("target", {}).get("garden_layer", {})
	for raw_cell in layer_config.get("cells", []):
		if raw_cell is Array and raw_cell.size() >= 2:
			var pos = Vector2i(int(raw_cell[0]), int(raw_cell[1]))
			if _is_valid_position(pos):
				garden_layers[pos] = true
	dew_buds.clear()
	for raw_bud in layer_config.get("dew_buds", []):
		if raw_bud is Array and raw_bud.size() >= 2:
			var bud_pos = Vector2i(int(raw_bud[0]), int(raw_bud[1]))
			if garden_layers.has(bud_pos):
				dew_buds[bud_pos] = true
	blocker_cells.clear()
	blocker_hp.clear()
	for raw_blocker in level_config.get("target", {}).get("blockers", []):
		if raw_blocker is Array and raw_blocker.size() >= 2:
			var blocker_pos = Vector2i(int(raw_blocker[0]), int(raw_blocker[1]))
			if _is_valid_position(blocker_pos):
				blocker_cells[blocker_pos] = true
				blocker_hp[blocker_pos] = 2


func _get_default_types() -> Array:
	return [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]

# 获取随机元素（避免初始匹配）
func _get_random_tile_no_match(row: int, col: int) -> int:
	# 最多尝试20次
	for i in range(20):
		var type = available_types[random_generator.randi_range(0, available_types.size() - 1)]
		
		# 检查水平匹配
		var horizontal_match = false
		if col >= 2 and row < grid.size() and grid[row].size() > col - 1:
			if grid[row][col-1] == type and grid[row][col-2] == type:
				horizontal_match = true
		
		# 检查垂直匹配
		var vertical_match = false
		if row >= 2 and row - 1 < grid.size() and grid[row-1].size() > col:
			if grid[row-1][col] == type and grid[row-2][col] == type:
				vertical_match = true
		
		if not horizontal_match and not vertical_match:
			return type
	
	return available_types[0]

# ==================== 核心操作 ====================
# 选择元素
func select_tile(pos: Vector2i) -> void:
	if board_processing:
		return
	
	if not _is_valid_position(pos):
		return
	
	if selected_tile == Vector2i(-1, -1):
		# 第一次选择
		selected_tile = pos
		_highlight_tile(pos, true)
	else:
		# 第二次选择，尝试交换
		if is_adjacent(selected_tile, pos):
			_attempt_swap(selected_tile, pos)
		else:
			# 选择新元素
			_highlight_tile(selected_tile, false)
			selected_tile = pos
			_highlight_tile(pos, true)

# 尝试交换
func _attempt_swap(pos1: Vector2i, pos2: Vector2i) -> void:
	board_processing = true
	_highlight_tile(selected_tile, false)
	selected_tile = Vector2i(-1, -1)
	
	# 执行交换
	swap_tiles(pos1, pos2)
	tiles_swapped.emit(pos1, pos2)
	
	# 检查匹配
	await AsyncUtilsScript.create_delay_tween(self, Constants.SWAP_DURATION).finished
	var matches = find_all_matches()
	
	if matches.size() > 0:
		# 有匹配，处理消除
		await _process_matches(matches)
	else:
		# 无匹配，交换回来
		swap_tiles(pos1, pos2)
	
	board_processing = false
	board_updated.emit()

# 交换两个元素
func swap_tiles(pos1: Vector2i, pos2: Vector2i) -> void:
	var temp = grid[pos1.x][pos1.y]
	grid[pos1.x][pos1.y] = grid[pos2.x][pos2.y]
	grid[pos2.x][pos2.y] = temp


func resolve_swap(pos1: Vector2i, pos2: Vector2i) -> Dictionary:
	if not _is_valid_position(pos1) or not _is_valid_position(pos2):
		return {"matched": false, "reverted": false, "chains": []}

	if not is_adjacent(pos1, pos2):
		return {"matched": false, "reverted": false, "chains": []}

	if grid[pos1.x][pos1.y] == Constants.TileType.BLOCKER or grid[pos2.x][pos2.y] == Constants.TileType.BLOCKER:
		return {"matched": false, "reverted": false, "chains": []}

	swap_tiles(pos1, pos2)
	tiles_swapped.emit(pos1, pos2)

	var matches = find_all_matches()
	if matches.is_empty():
		swap_tiles(pos1, pos2)
		return {"matched": false, "reverted": true, "chains": []}

	var chains = []
	var chain_count = 0
	# 同一次交换内，同一石块最多被敲一次
	var damaged_this_action: Dictionary = {}

	while not matches.is_empty() and chain_count < MAX_CASCADE_CHAINS:
		chain_count += 1
		chain_triggered.emit(chain_count)

		chains.append(_resolve_chain_step(matches.duplicate(true), damaged_this_action))

		matches = find_all_matches()

	var chain_capped = not matches.is_empty()
	if chain_capped:
		_rebuild_stable_grid()

	board_updated.emit()
	return {
		"matched": true,
		"reverted": false,
		"chains": chains,
		"chain_capped": chain_capped
	}


# 统一的一段连锁结算：匹配 → 生成清风块 → 触发 → 敲石块 → 清落叶 → 掉落补牌
func _resolve_chain_step(chain_matches: Array, damaged_this_action: Dictionary = {}) -> Dictionary:
	for match_data in chain_matches:
		tiles_matched.emit(match_data["positions"], match_data["type"])

	var specials_created = _create_specials(chain_matches)
	var anchor_positions: Array = []
	for created in specials_created:
		anchor_positions.append(created["position"])
	var triggered_specials = _collect_triggered_specials(chain_matches, anchor_positions)
	remove_matched_tiles(chain_matches, anchor_positions)
	var blocker_result = _resolve_blockers(chain_matches, damaged_this_action)
	var blockers_broken: Array = (blocker_result.get("broken", []) as Array).duplicate()
	var blockers_damaged: Array = (blocker_result.get("damaged", []) as Array).duplicate()

	var special_result = _apply_specials(triggered_specials)
	var special_cleared: Array = special_result.get("cleared", [])
	for special_broken in special_result.get("blockers_broken", []):
		if not blockers_broken.has(special_broken):
			blockers_broken.append(special_broken)

	var cleared_positions: Array = []
	for match_data in chain_matches:
		for match_pos in match_data.get("positions", []):
			if not anchor_positions.has(match_pos):
				cleared_positions.append(match_pos)
	for special_pos in special_cleared:
		cleared_positions.append(special_pos)
	for broken_pos in blockers_broken:
		cleared_positions.append(broken_pos)

	var garden_result = _resolve_garden_layers(cleared_positions)
	var fall_result = _drop_and_fill_collect()
	return {
		"matches": chain_matches,
		"specials_created": specials_created,
		"specials_triggered": triggered_specials,
		"special_cleared": special_cleared,
		"blockers_broken": blockers_broken,
		"blockers_damaged": blockers_damaged,
		"awakening_count": 0,
		"awakening_matches": [],
		"garden_cleared": garden_result.get("cleared", []),
		"dew_bursts": garden_result.get("dew_bursts", []),
		"breeze_paths": [],
		"movements": fall_result["movements"],
		"new_tiles": fall_result["new_tiles"]
	}


func get_garden_layer_positions() -> Array:
	return garden_layers.keys()


func get_dew_bud_positions() -> Array:
	return dew_buds.keys()


func get_special_grid() -> Array:
	return special_grid


func get_blocker_positions() -> Array:
	return blocker_cells.keys()


func get_blocker_hp(pos: Vector2i) -> int:
	return int(blocker_hp.get(pos, 0))


func get_blocker_hp_map() -> Dictionary:
	return blocker_hp.duplicate()


func _is_matchable(tile_type: int) -> bool:
	return tile_type != Constants.TileType.NONE and tile_type != Constants.TileType.BLOCKER


# 与石块相邻的消除会敲裂它；两次才碎
func _resolve_blockers(matches: Array, damaged_this_action: Dictionary = {}) -> Dictionary:
	var hit: Dictionary = {}
	for match_data in matches:
		for match_pos in match_data.get("positions", []):
			for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var candidate: Vector2i = match_pos + offset
				if not _is_valid_position(candidate):
					continue
				if grid[candidate.x][candidate.y] != Constants.TileType.BLOCKER:
					continue
				# 同一次移动内已敲过的石块不再重复结算：连锁掉落重新凑成的消除不能重复敲同一块
				if damaged_this_action.has(candidate):
					continue
				hit[candidate] = true
	var broken: Array = []
	var damaged: Array = []
	for candidate in hit.keys():
		damaged_this_action[candidate] = true
		var hp = int(blocker_hp.get(candidate, 2))
		# 相邻消除只能把石块敲到“裂开”（最低 1 点耐久），永远敲不碎；只有清风能击碎
		if hp > 1:
			blocker_hp[candidate] = hp - 1
			damaged.append(candidate)
	return {"broken": broken, "damaged": damaged}


func get_special_at(pos: Vector2i) -> String:
	if _is_valid_position(pos) and pos.x < special_grid.size() and pos.y < special_grid[pos.x].size():
		return str(special_grid[pos.x][pos.y])
	return ""


# 主动触发：玩家点一下清风块即可发动，不消耗步数
func activate_special(pos: Vector2i) -> Dictionary:
	if not _is_valid_position(pos):
		return {"matched": false, "reverted": false, "chains": []}
	var direction = get_special_at(pos)
	if direction.is_empty():
		return {"matched": false, "reverted": false, "chains": []}

	special_grid[pos.x][pos.y] = ""
	grid[pos.x][pos.y] = Constants.TileType.NONE
	var triggered: Array = [{"position": pos, "direction": direction}]
	var special_result = _apply_specials(triggered)
	var special_cleared: Array = special_result.get("cleared", [])
	var activation_broken: Array = (special_result.get("blockers_broken", []) as Array).duplicate()

	var cleared_positions: Array = [pos]
	for special_pos in special_cleared:
		cleared_positions.append(special_pos)
	for broken_pos in activation_broken:
		cleared_positions.append(broken_pos)
	var garden_result = _resolve_garden_layers(cleared_positions)
	var fall_result = _drop_and_fill_collect()

	var chains: Array = [{
		"matches": [],
		"specials_created": [],
		"specials_triggered": triggered,
		"special_cleared": special_cleared,
		"blockers_broken": activation_broken,
		"blockers_damaged": [],
		"awakening_count": 0,
		"awakening_matches": [],
		"garden_cleared": garden_result.get("cleared", []),
		"dew_bursts": garden_result.get("dew_bursts", []),
		"breeze_paths": [],
		"movements": fall_result["movements"],
		"new_tiles": fall_result["new_tiles"]
	}]

	# 触发后的掉落补牌可能重新凑成三连：与 resolve_swap 一样继续连锁结算
	var matches = find_all_matches()
	var chain_count = 0
	# 同一次清风触发内，同一石块最多被敲一次
	var damaged_this_action: Dictionary = {}
	while not matches.is_empty() and chain_count < MAX_CASCADE_CHAINS:
		chain_count += 1
		chain_triggered.emit(chain_count)
		chains.append(_resolve_chain_step(matches.duplicate(true), damaged_this_action))
		matches = find_all_matches()

	var chain_capped = not matches.is_empty()
	if chain_capped:
		_rebuild_stable_grid()

	board_updated.emit()
	return {
		"matched": true,
		"reverted": false,
		"chain_capped": chain_capped,
		"chains": chains
	}


func _resolve_garden_layers(cleared_positions: Array) -> Dictionary:
	if garden_layers.is_empty():
		return {"cleared": [], "paths": [], "dew_bursts": []}

	var clear_candidates: Dictionary = {}
	for cleared_pos in cleared_positions:
		for offset in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var candidate: Vector2i = cleared_pos + offset
			if garden_layers.has(candidate):
				clear_candidates[candidate] = true

	var dew_bursts: Array = []
	var pending_buds: Array = []
	for pos in clear_candidates.keys():
		if dew_buds.has(pos):
			pending_buds.append(pos)

	while not pending_buds.is_empty():
		var bud_pos: Vector2i = pending_buds.pop_front()
		if not dew_buds.has(bud_pos):
			continue
		dew_buds.erase(bud_pos)
		var burst_cleared: Array = []
		var burst_distance = 2 if not preferred_direction.is_empty() else 1
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			for distance in range(1, burst_distance + 1):
				var candidate = bud_pos + offset * distance
				if not garden_layers.has(candidate) or clear_candidates.has(candidate):
					continue
				clear_candidates[candidate] = true
				burst_cleared.append(candidate)
				if dew_buds.has(candidate):
					pending_buds.append(candidate)
		dew_bursts.append({
			"position": bud_pos,
			"chain_index": dew_bursts.size() + 1,
			"cleared_positions": burst_cleared
		})

	var cleared: Array = clear_candidates.keys()
	for pos in cleared:
		garden_layers.erase(pos)
	return {"cleared": cleared, "paths": [], "dew_bursts": dew_bursts}


# ==================== 清风特殊块 ====================
func _infer_direction(positions: Array) -> String:
	if positions.size() < 2:
		return ""
	var same_row = true
	var same_col = true
	var first: Vector2i = positions[0]
	for pos in positions:
		if pos.x != first.x:
			same_row = false
		if pos.y != first.y:
			same_col = false
	if same_row:
		return "row"
	if same_col:
		return "col"
	return ""


func _create_specials(chain_matches: Array) -> Array:
	var created: Array = []
	for match_data in chain_matches:
		var positions: Array = match_data.get("positions", [])
		if positions.size() < 4:
			continue
		var direction = _infer_direction(positions)
		if direction.is_empty():
			continue
		# 选一个还没有清风块的位置当锚点，避免覆盖掉已经攒下的块
		var anchor: Vector2i = Vector2i(-1, -1)
		var middle = int(positions.size() / 2)
		for offset in range(positions.size()):
			var candidate: Vector2i = positions[(middle + offset) % positions.size()]
			if str(special_grid[candidate.x][candidate.y]).is_empty():
				anchor = candidate
				break
		if anchor == Vector2i(-1, -1):
			continue
		special_grid[anchor.x][anchor.y] = direction
		created.append({
			"position": anchor,
			"direction": direction,
			"type": int(match_data.get("type", Constants.TileType.NONE))
		})
	return created


func _collect_triggered_specials(chain_matches: Array, anchor_positions: Array) -> Array:
	var triggered: Array = []
	for match_data in chain_matches:
		for match_pos in match_data.get("positions", []):
			if anchor_positions.has(match_pos):
				continue
			var direction = str(special_grid[match_pos.x][match_pos.y])
			if direction.is_empty():
				continue
			triggered.append({"position": match_pos, "direction": direction})
			special_grid[match_pos.x][match_pos.y] = ""
	return triggered


func _apply_specials(triggered: Array) -> Dictionary:
	var cleared: Array = []
	var blockers_broken: Array = []
	var processed: Dictionary = {}
	var queue: Array = triggered.duplicate()
	while not queue.is_empty():
		var item: Dictionary = queue.pop_front()
		var origin: Vector2i = item.get("position", Vector2i(-1, -1))
		var direction = str(item.get("direction", ""))
		var key = "%d:%d:%s" % [origin.x, origin.y, direction]
		if processed.has(key):
			continue
		processed[key] = true
		var line: Array = []
		if direction == "row":
			for col in range(Constants.GRID_COLS):
				line.append(Vector2i(origin.x, col))
		else:
			for row in range(Constants.GRID_ROWS):
				line.append(Vector2i(row, origin.y))
		for pos in line:
			if not _is_valid_position(pos):
				continue
			if grid[pos.x][pos.y] == Constants.TileType.NONE:
				continue
			var nested = str(special_grid[pos.x][pos.y])
			if not nested.is_empty():
				queue.append({"position": pos, "direction": nested})
				special_grid[pos.x][pos.y] = ""
			if grid[pos.x][pos.y] == Constants.TileType.BLOCKER:
				blocker_cells.erase(pos)
				blocker_hp.erase(pos)
				blockers_broken.append(pos)
			grid[pos.x][pos.y] = Constants.TileType.NONE
			cleared.append(pos)
	return {"cleared": cleared, "blockers_broken": blockers_broken}


func _has_preferred_breeze(paths: Array) -> bool:
	if preferred_direction.is_empty():
		return false
	for path in paths:
		if str(path.get("direction", "")) == preferred_direction:
			return true
	return false


func _get_breeze_paths(positions: Array) -> Array:
	var row_counts: Dictionary = {}
	var column_counts: Dictionary = {}
	for pos in positions:
		row_counts[pos.x] = int(row_counts.get(pos.x, 0)) + 1
		column_counts[pos.y] = int(column_counts.get(pos.y, 0)) + 1

	var paths: Array = []
	for row in row_counts:
		if int(row_counts[row]) >= 4:
			paths.append({"direction": "horizontal", "index": int(row)})
	for column in column_counts:
		if int(column_counts[column]) >= 4:
			paths.append({"direction": "vertical", "index": int(column)})
	return paths

# ==================== 匹配检测 ====================
# 查找所有匹配
func find_all_matches() -> Array:
	var all_matches = []
	all_matches.append_array(_find_horizontal_matches())
	all_matches.append_array(_find_vertical_matches())
	return _merge_matches(all_matches)

# 查找水平匹配
func _find_horizontal_matches() -> Array:
	var matches = []
	
	# 边界检查
	if grid.size() == 0:
		return matches
	
	for row in range(Constants.GRID_ROWS):
		# 边界检查
		if row >= grid.size() or grid[row].size() == 0:
			continue
		
		var count = 1
		var current_type = grid[row][0]
		
		for col in range(1, Constants.GRID_COLS):
			if col >= grid[row].size():
				break
			if grid[row][col] == current_type and _is_matchable(current_type):
				count += 1
			else:
				if count >= Constants.MIN_MATCH_COUNT and _is_matchable(current_type):
					var positions = []
					for i in range(count):
						positions.append(Vector2i(row, col - count + i))
					matches.append({
						"type": current_type,
						"positions": positions,
						"direction": "horizontal"
					})
				count = 1
				current_type = grid[row][col]
		
		# 检查行尾
		if count >= Constants.MIN_MATCH_COUNT and _is_matchable(current_type):
			var positions = []
			for i in range(count):
				positions.append(Vector2i(row, Constants.GRID_COLS - count + i))
			matches.append({
				"type": current_type,
				"positions": positions,
				"direction": "horizontal"
			})
	
	return matches

# 查找垂直匹配
func _find_vertical_matches() -> Array:
	var matches = []
	
	# 边界检查
	if grid.size() == 0:
		return matches
	
	for col in range(Constants.GRID_COLS):
		# 边界检查
		if grid[0].size() == 0 or col >= grid[0].size():
			continue
		
		var count = 1
		var current_type = grid[0][col]
		
		for row in range(1, Constants.GRID_ROWS):
			if row >= grid.size() or col >= grid[row].size():
				break
			if grid[row][col] == current_type and _is_matchable(current_type):
				count += 1
			else:
				if count >= Constants.MIN_MATCH_COUNT and _is_matchable(current_type):
					var positions = []
					for i in range(count):
						positions.append(Vector2i(row - count + i, col))
					matches.append({
						"type": current_type,
						"positions": positions,
						"direction": "vertical"
					})
				count = 1
				current_type = grid[row][col]
		
		# 检查列尾
		if count >= Constants.MIN_MATCH_COUNT and _is_matchable(current_type):
			var positions = []
			for i in range(count):
				positions.append(Vector2i(Constants.GRID_ROWS - count + i, col))
			matches.append({
				"type": current_type,
				"positions": positions,
				"direction": "vertical"
			})
	
	return matches

# 合并重叠匹配（十字消除）
func _merge_matches(matches: Array) -> Array:
	var merged: Array = []
	for match_data in matches:
		var candidate = {
			"type": int(match_data["type"]),
			"positions": match_data["positions"].duplicate()
		}
		var index = 0
		while index < merged.size():
			var existing = merged[index]
			if int(existing["type"]) == int(candidate["type"]) and _positions_overlap(existing["positions"], candidate["positions"]):
				for pos in existing["positions"]:
					if not candidate["positions"].has(pos):
						candidate["positions"].append(pos)
				merged.remove_at(index)
				index = 0
				continue
			index += 1
		merged.append(candidate)
	return merged


func _positions_overlap(first: Array, second: Array) -> bool:
	for pos in first:
		if second.has(pos):
			return true
	return false


func _rebuild_stable_grid() -> void:
	grid.clear()
	special_grid.clear()
	for row in range(Constants.GRID_ROWS):
		grid.append([])
		special_grid.append([])
		for col in range(Constants.GRID_COLS):
			grid[row].append(_get_random_tile_no_match(row, col))
			special_grid[row].append("")
	for blocker_pos in blocker_cells.keys():
		grid[blocker_pos.x][blocker_pos.y] = Constants.TileType.BLOCKER
	while not has_valid_moves():
		shuffle_board()

# ==================== 消除处理 ====================
# 处理匹配
func _process_matches(matches: Array) -> void:
	combo_count = 0
	
	while matches.size() > 0:
		combo_count += 1
		chain_triggered.emit(combo_count)
		
		# 计算分数
		var total_tiles = 0
		for match_data in matches:
			total_tiles += match_data["positions"].size()
		var score = total_tiles * Constants.BASE_SCORE_PER_TILE
		if combo_count > 1:
			score = int(score * pow(Constants.COMBO_MULTIPLIER, combo_count - 1))
		
		# 发送消除信号
		for match_data in matches:
			tiles_matched.emit(match_data["positions"], match_data["type"])
		
		# 消除元素
		remove_matched_tiles(matches)
		
		# 等待消除动画
		await AsyncUtilsScript.create_delay_tween(self, Constants.MATCH_DURATION).finished
		
		# 下落填充
		await _drop_and_fill()
		
		# 检查新的匹配
		matches = find_all_matches()
	
	combo_count = 0

# 移除匹配的元素
func remove_matched_tiles(matches: Array, skip_positions: Array = []) -> void:
	for match_data in matches:
		for pos in match_data["positions"]:
			if skip_positions.has(pos):
				continue
			grid[pos.x][pos.y] = Constants.TileType.NONE
			if pos.x < special_grid.size() and pos.y < special_grid[pos.x].size():
				special_grid[pos.x][pos.y] = ""

# 下落和填充
func _drop_and_fill() -> void:
	_drop_and_fill_collect()
	await AsyncUtilsScript.create_delay_tween(self, Constants.FALL_DURATION).finished

# ==================== 辅助函数 ====================
# 检查位置是否有效
func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < Constants.GRID_ROWS and \
		   pos.y >= 0 and pos.y < Constants.GRID_COLS

# 检查是否相邻
func is_adjacent(pos1: Vector2i, pos2: Vector2i) -> bool:
	var diff = (pos1 - pos2).abs()
	return (diff.x == 1 and diff.y == 0) or (diff.x == 0 and diff.y == 1)

# 高亮元素
func _highlight_tile(_pos: Vector2i, _highlight: bool) -> void:
	# TODO: 实现高亮效果
	pass

# 获取随机基础元素
func get_random_basic_tile() -> int:
	return available_types[random_generator.randi_range(0, available_types.size() - 1)]

# 获取元素类型
func get_tile_at(pos: Vector2i) -> int:
	if _is_valid_position(pos):
		return grid[pos.x][pos.y]
	return Constants.TileType.NONE

# 检查是否有可用移动
func has_valid_moves() -> bool:
	return not find_valid_move().is_empty()


func find_valid_move() -> Dictionary:
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			# 检查水平交换
			if col < Constants.GRID_COLS - 1:
				var horizontal_move = _evaluate_potential_move(Vector2i(row, col), Vector2i(row, col + 1))
				if not horizontal_move.is_empty():
					return horizontal_move
			
			# 检查垂直交换
			if row < Constants.GRID_ROWS - 1:
				var vertical_move = _evaluate_potential_move(Vector2i(row, col), Vector2i(row + 1, col))
				if not vertical_move.is_empty():
					return vertical_move
	
	return {}


func _evaluate_potential_move(pos1: Vector2i, pos2: Vector2i) -> Dictionary:
	if grid[pos1.x][pos1.y] == Constants.TileType.BLOCKER or grid[pos2.x][pos2.y] == Constants.TileType.BLOCKER:
		return {}
	swap_tiles(pos1, pos2)
	var matches = find_all_matches()
	swap_tiles(pos1, pos2)

	if matches.is_empty():
		return {}

	return {
		"pos1": pos1,
		"pos2": pos2,
		"matches": matches
	}

# 重新洗牌
func shuffle_board() -> void:
	var positions: Array = []
	var tiles: Array = []
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			if grid[row][col] != Constants.TileType.NONE and grid[row][col] != Constants.TileType.BLOCKER:
				positions.append(Vector2i(row, col))
				tiles.append({"type": grid[row][col], "special": str(special_grid[row][col])})
	
	for index in range(tiles.size() - 1, 0, -1):
		var swap_index = random_generator.randi_range(0, index)
		var temporary = tiles[index]
		tiles[index] = tiles[swap_index]
		tiles[swap_index] = temporary
	
	for index in range(positions.size()):
		var position: Vector2i = positions[index]
		grid[position.x][position.y] = int(tiles[index]["type"])
		special_grid[position.x][position.y] = str(tiles[index]["special"])
	
	# 确保没有初始匹配
	while find_all_matches().size() > 0:
		shuffle_board()


func _drop_and_fill_collect() -> Dictionary:
	var movements = []
	var new_tiles = []

	for col in range(Constants.GRID_COLS):
		var row = Constants.GRID_ROWS - 1
		while row >= 0:
			if grid[row][col] == Constants.TileType.BLOCKER:
				row -= 1
				continue
			var segment_bottom = row
			var segment_top = row
			while segment_top - 1 >= 0 and grid[segment_top - 1][col] != Constants.TileType.BLOCKER:
				segment_top -= 1
			var write_row = segment_bottom
			for read_row in range(segment_bottom, segment_top - 1, -1):
				var tile_type = grid[read_row][col]
				if tile_type == Constants.TileType.NONE:
					continue
				if read_row != write_row:
					var special_type = str(special_grid[read_row][col])
					grid[write_row][col] = tile_type
					special_grid[write_row][col] = special_type
					grid[read_row][col] = Constants.TileType.NONE
					special_grid[read_row][col] = ""
					movements.append({
						"from": Vector2i(read_row, col),
						"to": Vector2i(write_row, col),
						"delay": (write_row - read_row) * 0.05
					})
				write_row -= 1
			for fill_row in range(write_row, segment_top - 1, -1):
				var new_type = get_random_basic_tile()
				grid[fill_row][col] = new_type
				special_grid[fill_row][col] = ""
				new_tiles.append({
					"pos": Vector2i(fill_row, col),
					"type": new_type,
					"delay": (write_row - fill_row) * 0.05
				})
			row = segment_top - 1

	tiles_fallen.emit()
	return {
		"movements": movements,
		"new_tiles": new_tiles
	}

# ==================== 公开接口 ====================
# 处理匹配并自动执行下落填充
func process_matches(matches: Array) -> void:
	combo_count = 0
	
	while matches.size() > 0:
		combo_count += 1
		chain_triggered.emit(combo_count)
		
		# 计算分数
		var total_tiles = 0
		for match_data in matches:
			total_tiles += match_data["positions"].size()
		var score = total_tiles * Constants.BASE_SCORE_PER_TILE
		if combo_count > 1:
			score = int(score * pow(Constants.COMBO_MULTIPLIER, combo_count - 1))
		
		# 发送消除信号
		for match_data in matches:
			tiles_matched.emit(match_data["positions"], match_data["type"])
		
		# 消除元素
		remove_matched_tiles(matches)
		
		# 等待消除动画
		await AsyncUtilsScript.create_delay_tween(self, Constants.MATCH_DURATION).finished
		
		# 下落填充
		await drop_and_fill()
		
		# 检查新的匹配
		matches = find_all_matches()
	
	combo_count = 0

# 下落和填充
func drop_and_fill() -> void:
	# 下落现有元素
	for col in range(Constants.GRID_COLS):
		var empty_row = Constants.GRID_ROWS - 1
		
		for row in range(Constants.GRID_ROWS - 1, -1, -1):
			if grid[row][col] != Constants.TileType.NONE:
				if row != empty_row:
					grid[empty_row][col] = grid[row][col]
					grid[row][col] = Constants.TileType.NONE
				empty_row -= 1
		
		# 填充新元素
		for row in range(empty_row, -1, -1):
			grid[row][col] = get_random_basic_tile()
	
	tiles_fallen.emit()
	await AsyncUtilsScript.create_delay_tween(self, Constants.FALL_DURATION).finished
