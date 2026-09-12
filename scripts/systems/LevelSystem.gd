## LevelSystem - 关卡管理系统
class_name LevelSystem
extends Node

# ==================== 信号 ====================
signal level_loaded(level_data: Dictionary)
signal moves_updated(moves_left: int)
signal target_updated(collected: Dictionary)
signal level_won(stars: int, score: int)
signal level_failed()
signal level_continued(extra_moves: int)

# ==================== 变量 ====================
var current_level_id: int = 1
var level_config: Dictionary = {}
var moves_left: int = 0
var collected_tiles: Dictionary = {}
var current_score: int = 0
var is_level_active: bool = false
var breeze_awakenings: int = 0
var breeze_bonus_progress: int = 0
var last_awakened_focus: String = ""
var garden_layers_cleared: int = 0
var garden_layers_total: int = 0
var dew_buds_triggered: int = 0
var max_dew_chain: int = 0

# ==================== 关卡配置 ====================
# 获取关卡配置（程序化生成或从文件加载）
func get_level_config(level_id: int) -> Dictionary:
	if level_id < 1:
		push_error("Invalid level_id: %d" % level_id)
		level_id = 1
	
	# 尝试从文件加载
	var file_path = "res://levels/level_%03d.json" % level_id
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		json.parse(file.get_as_text())
		file.close()
		return _normalize_level_config(json.data)
	
	# 程序化生成关卡
	return _normalize_level_config(_generate_level(level_id))

# 程序化生成关卡
func _generate_level(level_id: int) -> Dictionary:
	# 难度曲线
	var difficulty = _calculate_difficulty(level_id)
	
	# 可用元素类型
	var available_types = _get_available_types(level_id)
	
	# 生成目标
	var target = _generate_target(level_id, difficulty, available_types)
	
	return {
		"level_id": level_id,
		"moves": int(30 - difficulty * 5),  # 难度越高，步数越少
		"target": target,
		"available_types": available_types,
		"rewards": _generate_rewards(level_id, available_types),
		"special_elements": {
			"bomb_probability": 0.03 + difficulty * 0.02,
			"rainbow_probability": 0.02 + difficulty * 0.01
		}
	}

# 计算难度
func _calculate_difficulty(level_id: int) -> float:
	# 0.0 - 1.0 的难度值
	return clampf((level_id - 1) * 0.05, 0.0, 1.0)

# 获取可用元素类型
func _get_available_types(level_id: int) -> Array:
	var all_types = [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]
	
	# 前5关只用3种元素
	if level_id <= 5:
		return all_types.slice(0, 3)
	# 6-15关用4种元素
	elif level_id <= 15:
		return all_types.slice(0, 4)
	# 16关以后用5-6种元素
	else:
		return all_types.slice(0, mini(5 + int((level_id - 16) / 10.0), 6))

# 生成目标
func _generate_target(_level_id: int, difficulty: float, available_types: Array) -> Dictionary:
	var requirements = []
	
	# 收集类关卡
	var num_types = mini(1 + int(difficulty * 2), available_types.size())
	for i in range(num_types):
		var tile_type = available_types[i]
		var count = int(15 + difficulty * 20)
		requirements.append({
			"tile_type": tile_type,
			"count": count
		})
	
	return {
		"type": "collect",
		"requirements": requirements
	}


func _generate_rewards(level_id: int, available_types: Array) -> Dictionary:
	var stage_seed_count = 1
	var stage_stars = 20
	var first_clear_stars = 30
	var first_clear_seed_count = 1

	if level_id >= 6 and level_id <= 12:
		stage_stars = 26
		first_clear_stars = 36
	elif level_id >= 13:
		stage_seed_count = 2
		stage_stars = 34
		first_clear_stars = 48
		first_clear_seed_count = 2

	var reward_seed_type = available_types.back() if not available_types.is_empty() else Constants.TileType.RED_ROSE

	return {
		"seed_type": int(reward_seed_type),
		"seed_count": stage_seed_count,
		"stars": stage_stars,
		"first_clear_bonus": {
			"stars": first_clear_stars,
			"seed_count": first_clear_seed_count
		}
	}


func _normalize_level_config(level_config: Dictionary) -> Dictionary:
	var normalized = level_config.duplicate(true)
	var available_types: Array = []
	for tile_type in normalized.get("available_types", _get_default_types()):
		available_types.append(int(tile_type))
	normalized["available_types"] = available_types
	normalized["target"] = _normalize_target(normalized.get("target", {}))
	normalized["rewards"] = _normalize_rewards(
		normalized.get("level_id", 1),
		available_types,
		normalized.get("rewards", {})
	)
	return normalized


func _normalize_target(target: Dictionary) -> Dictionary:
	var normalized = target.duplicate(true)
	var requirements = normalized.get("requirements", [])
	var primary_requirement = requirements[0] if requirements is Array and not requirements.is_empty() else {}
	var primary_type = int(primary_requirement.get("tile_type", Constants.TileType.RED_ROSE))
	var flower_name = Constants.TILE_NAMES.get(primary_type, "花圃")

	var theme = {}
	if normalized.has("theme") and normalized["theme"] is Dictionary:
		theme = normalized["theme"].duplicate(true)

	if not theme.has("objective_name"):
		theme["objective_name"] = "唤醒%s花圃" % flower_name
	if not theme.has("objective_detail"):
		theme["objective_detail"] = "让一阵清风先吹开这里的枯叶。"
	if not theme.has("focus_name"):
		theme["focus_name"] = flower_name
	if not theme.has("breeze_label"):
		theme["breeze_label"] = "清风唤醒"
	if not theme.has("breeze_bonus"):
		theme["breeze_bonus"] = 2
	if not theme.has("result_name"):
		theme["result_name"] = "花圃亮了一点"

	normalized["theme"] = theme
	if normalized.get("garden_layer", {}) is Dictionary:
		var layer = normalized.get("garden_layer", {}).duplicate(true)
		var cells: Array = []
		for raw_cell in layer.get("cells", []):
			if raw_cell is Array and raw_cell.size() >= 2:
				cells.append([int(raw_cell[0]), int(raw_cell[1])])
		layer["cells"] = cells
		layer["required"] = clampi(int(layer.get("required", cells.size())), 0, cells.size())
		var valid_cells: Dictionary = {}
		for cell in cells:
			valid_cells[Vector2i(int(cell[0]), int(cell[1]))] = true
		var dew_buds: Array = []
		var seen_buds: Dictionary = {}
		for raw_bud in layer.get("dew_buds", []):
			if raw_bud is Array and raw_bud.size() >= 2:
				var bud_pos = Vector2i(int(raw_bud[0]), int(raw_bud[1]))
				if valid_cells.has(bud_pos) and not seen_buds.has(bud_pos):
					seen_buds[bud_pos] = true
					dew_buds.append([bud_pos.x, bud_pos.y])
		layer["dew_buds"] = dew_buds
		normalized["garden_layer"] = layer
	return normalized


func _normalize_rewards(level_id: int, available_types: Array, rewards: Dictionary) -> Dictionary:
	var generated = _generate_rewards(level_id, available_types)
	if rewards.is_empty():
		return generated

	var normalized = generated.duplicate(true)
	normalized.merge(rewards, true)

	var first_clear_bonus = generated.get("first_clear_bonus", {}).duplicate(true)
	if rewards.has("first_clear_bonus") and rewards["first_clear_bonus"] is Dictionary:
		first_clear_bonus.merge(rewards["first_clear_bonus"], true)
	normalized["first_clear_bonus"] = first_clear_bonus
	return normalized


func _get_default_types() -> Array:
	return [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]

# ==================== 关卡流程 ====================
# 开始关卡
func start_level(level_id: int, bonus_moves: int = 0) -> void:
	start_level_config(get_level_config(level_id), bonus_moves)


func start_level_config(config: Dictionary, bonus_moves: int = 0) -> void:
	level_config = _normalize_level_config(config)
	current_level_id = int(level_config.get("level_id", 1))
	moves_left = level_config.get("moves", Constants.MAX_MOVES_DEFAULT) + max(0, bonus_moves)
	collected_tiles.clear()
	current_score = 0
	is_level_active = true
	breeze_awakenings = 0
	breeze_bonus_progress = 0
	last_awakened_focus = ""
	garden_layers_cleared = 0
	dew_buds_triggered = 0
	max_dew_chain = 0
	var layer_config = level_config.get("target", {}).get("garden_layer", {})
	garden_layers_total = int(layer_config.get("required", layer_config.get("cells", []).size()))
	
	level_loaded.emit(level_config)

# 使用一步
func use_move() -> bool:
	if not is_level_active:
		return false
	
	if moves_left > 0:
		moves_left -= 1
		moves_updated.emit(moves_left)
		return true
	
	return false

# 收集元素
func collect_tiles(tile_type: int, count: int) -> void:
	if not is_level_active:
		return
	
	var type_name = str(tile_type)
	if not collected_tiles.has(type_name):
		collected_tiles[type_name] = 0
	collected_tiles[type_name] += count
	
	target_updated.emit(collected_tiles)


func clear_garden_layers(count: int) -> void:
	if not is_level_active or count <= 0:
		return
	garden_layers_cleared = mini(garden_layers_total, garden_layers_cleared + count)
	target_updated.emit(collected_tiles)


func record_dew_bud_bursts(bursts: Array) -> void:
	if not is_level_active or bursts.is_empty():
		return
	dew_buds_triggered += bursts.size()
	for burst in bursts:
		max_dew_chain = maxi(max_dew_chain, int(burst.get("chain_index", 1)))
	target_updated.emit(collected_tiles)


# 一次交换的全部匹配、连锁和清风结算后再统一裁决胜负。
func finish_turn() -> void:
	if not is_level_active:
		return
	if _check_win_condition():
		_win_level()
	elif moves_left <= 0:
		_fail_level()

# 添加分数
func add_score(points: int) -> void:
	current_score += points

# 检查胜利条件
func _check_win_condition() -> bool:
	var requirements = level_config.get("target", {}).get("requirements", [])
	
	for req in requirements:
		var tile_type = int(req["tile_type"])
		var required_count = req["count"]
		var collected = collected_tiles.get(str(tile_type), 0)
		
		if collected < required_count:
			return false
	if garden_layers_cleared < garden_layers_total:
		return false
	
	return true

# 计算星级
func _calculate_stars() -> int:
	var moves_ratio = float(moves_left) / level_config.get("moves", 30)
	
	if moves_ratio >= 0.5:
		return 3
	elif moves_ratio >= 0.3:
		return 2
	else:
		return 1

# 胜利
func _win_level() -> void:
	is_level_active = false
	var stars = _calculate_stars()
	
	level_won.emit(stars, current_score)

# 失败
func _fail_level() -> void:
	is_level_active = false
	level_failed.emit()


func continue_level(extra_moves: int = 5) -> bool:
	if is_level_active or extra_moves <= 0:
		return false

	if _check_win_condition():
		return false

	moves_left += extra_moves
	is_level_active = true
	moves_updated.emit(moves_left)
	level_continued.emit(extra_moves)
	return true

# 重新开始关卡
func restart_level() -> void:
	if bool(level_config.get("is_daily_challenge", false)):
		start_level_config(level_config)
		return
	start_level(current_level_id)

# 获取目标进度文本
func get_target_progress_text() -> String:
	var requirements = level_config.get("target", {}).get("requirements", [])
	var texts = []
	var theme = get_theme_target_data()
	
	for req in requirements:
		var tile_type = int(req["tile_type"])  # 确保是整数类型
		var required = req["count"]
		var collected = collected_tiles.get(str(tile_type), 0)
		var tile_name = Constants.TILE_NAMES.get(tile_type, "Unknown")
		if not str(theme.get("objective_name", "")).is_empty():
			texts.append("%s\n通关：%s %d/%d" % [theme.get("objective_name", tile_name), tile_name, collected, required])
		else:
			texts.append("通关：%s %d/%d" % [tile_name, collected, required])
	if garden_layers_total > 0:
		texts.append("扫开落叶 %d/%d" % [garden_layers_cleared, garden_layers_total])
	
	return "\n".join(texts)


func get_target_intro_text() -> String:
	var requirements = level_config.get("target", {}).get("requirements", [])
	if requirements.is_empty():
		return str(get_theme_target_data().get("objective_detail", "让这里先亮起来。"))
	var requirement = requirements[0]
	var tile_type = int(requirement.get("tile_type", Constants.TileType.RED_ROSE))
	var reward_type = int(level_config.get("rewards", {}).get("seed_type", tile_type))
	if garden_layers_total > 0:
		var garden_layer = level_config.get("target", {}).get("garden_layer", {})
		var dew_hint = ""
		if garden_layer is Dictionary and not garden_layer.get("dew_buds", []).is_empty():
			dew_hint = " 晨露花苞绽放后会扫开十字落叶。"
		return "在落叶旁消除；四连会沿横/竖方向吹过整条路径。%s\n扫净落叶并收集满 %d 朵%s，带回%s花种。" % [
			dew_hint,
			int(requirement.get("count", 0)),
			Constants.TILE_NAMES.get(tile_type, "花"),
			Constants.TILE_NAMES.get(reward_type, "花")
		]
	var detail = str(get_theme_target_data().get("objective_detail", "让这里先亮起来。"))
	return "%s 收集满 %d 朵%s即可通过。\n完成后带回%s花种。" % [
		detail,
		int(requirement.get("count", 0)),
		Constants.TILE_NAMES.get(tile_type, "花"),
		Constants.TILE_NAMES.get(reward_type, "花")
	]


func get_theme_target_data() -> Dictionary:
	var target = level_config.get("target", {})
	if target is Dictionary and target.get("theme", {}) is Dictionary:
		return target.get("theme", {})
	return {}


func get_theme_progress_snapshot() -> Dictionary:
	var theme = get_theme_target_data()
	return {
		"objective_name": str(theme.get("objective_name", "")),
		"objective_detail": str(theme.get("objective_detail", "")),
		"focus_name": str(theme.get("focus_name", "")),
		"result_name": str(theme.get("result_name", "")),
		"breeze_label": str(theme.get("breeze_label", "清风唤醒")),
		"breeze_bonus": int(theme.get("breeze_bonus", 0)),
		"awakenings": breeze_awakenings,
		"bonus_progress": breeze_bonus_progress,
		"garden_layers_cleared": garden_layers_cleared,
		"garden_layers_total": garden_layers_total,
		"dew_buds_triggered": dew_buds_triggered,
		"max_dew_chain": max_dew_chain,
		"last_awakened_focus": last_awakened_focus
	}


func apply_breeze_awakening(awakening_count: int) -> Dictionary:
	if awakening_count <= 0 or not is_level_active:
		return {}

	var requirements = level_config.get("target", {}).get("requirements", [])
	if requirements.is_empty():
		return {}

	var theme = get_theme_target_data()
	var primary_requirement = requirements[0]
	var tile_type = int(primary_requirement.get("tile_type", Constants.TileType.RED_ROSE))
	var bonus_per_awakening = max(1, int(theme.get("breeze_bonus", 2)))
	var total_bonus = awakening_count * bonus_per_awakening

	var key = str(tile_type)
	if not collected_tiles.has(key):
		collected_tiles[key] = 0
	collected_tiles[key] += total_bonus

	breeze_awakenings += awakening_count
	breeze_bonus_progress += total_bonus
	last_awakened_focus = str(theme.get("focus_name", "花圃"))

	target_updated.emit(collected_tiles)

	return {
		"awakening_count": awakening_count,
		"bonus_progress": total_bonus,
		"focus_name": last_awakened_focus,
		"breeze_label": str(theme.get("breeze_label", "清风唤醒"))
	}
