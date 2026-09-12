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
var preferred_direction: String = ""
var random_generator := RandomNumberGenerator.new()

const MAX_CASCADE_CHAINS: int = 8

# ==================== 生命周期 ====================
func _ready() -> void:
	initialize_grid()

# ==================== 初始化 ====================
func initialize_grid(level_config: Dictionary = {}) -> void:
	grid.clear()

	configure(level_config)
	
	for row in range(Constants.GRID_ROWS):
		grid.append([])
		for col in range(Constants.GRID_COLS):
			grid[row].append(_get_random_tile_no_match(row, col))
	
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

	swap_tiles(pos1, pos2)
	tiles_swapped.emit(pos1, pos2)

	var matches = find_all_matches()
	if matches.is_empty():
		swap_tiles(pos1, pos2)
		return {"matched": false, "reverted": true, "chains": []}

	var chains = []
	var chain_count = 0

	while not matches.is_empty() and chain_count < MAX_CASCADE_CHAINS:
		chain_count += 1
		chain_triggered.emit(chain_count)

		var chain_matches = matches.duplicate(true)
		for match_data in chain_matches:
			tiles_matched.emit(match_data["positions"], match_data["type"])

		remove_matched_tiles(chain_matches)
		var fall_result = _drop_and_fill_collect()
		var awakening_matches = []
		for match_data in chain_matches:
			if not _get_breeze_paths(match_data.get("positions", [])).is_empty():
				awakening_matches.append(match_data)
		var garden_result = _resolve_garden_layers(chain_matches, awakening_matches)

		chains.append({
			"matches": chain_matches,
			"awakening_count": awakening_matches.size(),
			"awakening_matches": awakening_matches,
			"garden_cleared": garden_result.get("cleared", []),
			"dew_bursts": garden_result.get("dew_bursts", []),
			"breeze_paths": garden_result.get("paths", []),
			"movements": fall_result["movements"],
			"new_tiles": fall_result["new_tiles"]
		})

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


func get_garden_layer_positions() -> Array:
	return garden_layers.keys()


func get_dew_bud_positions() -> Array:
	return dew_buds.keys()


func _resolve_garden_layers(matches: Array, awakening_matches: Array) -> Dictionary:
	if garden_layers.is_empty():
		return {"cleared": [], "paths": [], "dew_bursts": []}

	var clear_candidates: Dictionary = {}
	for match_data in matches:
		for match_pos in match_data.get("positions", []):
			for offset in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var candidate = match_pos + offset
				if garden_layers.has(candidate):
					clear_candidates[candidate] = true

	var paths: Array = []
	for match_data in awakening_matches:
		for path in _get_breeze_paths(match_data.get("positions", [])):
			paths.append(path)
			for layer_pos in garden_layers.keys():
				if path.get("direction") == "horizontal" and layer_pos.x == int(path.get("index", -1)):
					clear_candidates[layer_pos] = true
				elif path.get("direction") == "vertical" and layer_pos.y == int(path.get("index", -1)):
					clear_candidates[layer_pos] = true

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
		var burst_distance = 2 if _has_preferred_breeze(paths) else 1
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
	return {"cleared": cleared, "paths": paths, "dew_bursts": dew_bursts}


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
			if grid[row][col] == current_type and current_type != Constants.TileType.NONE:
				count += 1
			else:
				if count >= Constants.MIN_MATCH_COUNT and current_type != Constants.TileType.NONE:
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
		if count >= Constants.MIN_MATCH_COUNT and current_type != Constants.TileType.NONE:
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
			if grid[row][col] == current_type and current_type != Constants.TileType.NONE:
				count += 1
			else:
				if count >= Constants.MIN_MATCH_COUNT and current_type != Constants.TileType.NONE:
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
		if count >= Constants.MIN_MATCH_COUNT and current_type != Constants.TileType.NONE:
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
	for row in range(Constants.GRID_ROWS):
		grid.append([])
		for col in range(Constants.GRID_COLS):
			grid[row].append(_get_random_tile_no_match(row, col))
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
func remove_matched_tiles(matches: Array) -> void:
	for match_data in matches:
		for pos in match_data["positions"]:
			grid[pos.x][pos.y] = Constants.TileType.NONE

# 下落和填充
func _drop_and_fill() -> void:
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
	var all_tiles = []
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			if grid[row][col] != Constants.TileType.NONE:
				all_tiles.append(grid[row][col])
	
	for index in range(all_tiles.size() - 1, 0, -1):
		var swap_index = random_generator.randi_range(0, index)
		var temporary = all_tiles[index]
		all_tiles[index] = all_tiles[swap_index]
		all_tiles[swap_index] = temporary
	
	var index = 0
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			if grid[row][col] != Constants.TileType.NONE:
				grid[row][col] = all_tiles[index]
				index += 1
	
	# 确保没有初始匹配
	while find_all_matches().size() > 0:
		shuffle_board()


func _drop_and_fill_collect() -> Dictionary:
	var movements = []
	var new_tiles = []

	for col in range(Constants.GRID_COLS):
		var empty_row = Constants.GRID_ROWS - 1

		for row in range(Constants.GRID_ROWS - 1, -1, -1):
			if grid[row][col] != Constants.TileType.NONE:
				if row != empty_row:
					var tile_type = grid[row][col]
					grid[empty_row][col] = tile_type
					grid[row][col] = Constants.TileType.NONE

					movements.append({
						"from": Vector2i(row, col),
						"to": Vector2i(empty_row, col),
						"delay": (empty_row - row) * 0.05
					})

				empty_row -= 1

		for row in range(empty_row, -1, -1):
			var new_type = get_random_basic_tile()
			grid[row][col] = new_type
			new_tiles.append({
				"pos": Vector2i(row, col),
				"type": new_type,
				"delay": (empty_row - row) * 0.05
			})

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
