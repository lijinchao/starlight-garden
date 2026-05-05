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
	var available_types = normalized.get("available_types", _get_default_types())
	normalized["available_types"] = available_types
	normalized["rewards"] = _normalize_rewards(
		normalized.get("level_id", 1),
		available_types,
		normalized.get("rewards", {})
	)
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
	current_level_id = level_id
	level_config = get_level_config(level_id)
	moves_left = level_config.get("moves", Constants.MAX_MOVES_DEFAULT) + max(0, bonus_moves)
	collected_tiles.clear()
	current_score = 0
	is_level_active = true
	
	level_loaded.emit(level_config)

# 使用一步
func use_move() -> bool:
	if not is_level_active:
		return false
	
	if moves_left > 0:
		moves_left -= 1
		moves_updated.emit(moves_left)
		
		# 检查是否失败
		if moves_left <= 0 and not _check_win_condition():
			_fail_level()
		
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
	
	# 检查是否胜利
	if _check_win_condition():
		_win_level()

# 添加分数
func add_score(points: int) -> void:
	current_score += points

# 检查胜利条件
func _check_win_condition() -> bool:
	var requirements = level_config.get("target", {}).get("requirements", [])
	
	for req in requirements:
		var tile_type = req["tile_type"]
		var required_count = req["count"]
		var collected = collected_tiles.get(str(tile_type), 0)
		
		if collected < required_count:
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
	start_level(current_level_id)

# 获取目标进度文本
func get_target_progress_text() -> String:
	var requirements = level_config.get("target", {}).get("requirements", [])
	var texts = []
	
	for req in requirements:
		var tile_type = int(req["tile_type"])  # 确保是整数类型
		var required = req["count"]
		var collected = collected_tiles.get(str(tile_type), 0)
		var tile_name = Constants.TILE_NAMES.get(tile_type, "Unknown")
		texts.append("%s: %d/%d" % [tile_name, collected, required])
	
	return "\n".join(texts)
