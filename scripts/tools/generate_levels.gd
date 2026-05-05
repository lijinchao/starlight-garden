#!/usr/bin/env -S godot --headless --script
## 关卡生成脚本 - 自动生成20个关卡JSON文件
extends SceneTree

func _init() -> void:
	print("=====================================")
	print("   星光花园 - 关卡生成器")
	print("=====================================\n")
	
	# 创建关卡目录
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("levels"):
		dir.make_dir("levels")
	
	# 生成20个关卡
	for i in range(1, 21):
		var level_data = _generate_level(i)
		_save_level(i, level_data)
		print("✅ 生成关卡 %d: %d步, %d种元素" % [i, level_data["moves"], level_data["available_types"].size()])
	
	print("\n=====================================")
	print("   关卡生成完成！共生成20个关卡")
	print("=====================================")
	
	quit()

func _generate_level(level_id: int) -> Dictionary:
	# 难度计算
	var difficulty = clampf((level_id - 1) * 0.05, 0.0, 1.0)
	
	# 步数：从30逐渐减少到15
	var moves = int(30 - difficulty * 15)
	
	# 可用元素类型
	var available_types = _get_available_types(level_id)
	
	# 生成目标
	var target = _generate_target(level_id, difficulty, available_types)
	
	# 特殊元素概率
	var bomb_prob = 0.03 + difficulty * 0.02
	var rainbow_prob = 0.01 + difficulty * 0.015
	
	return {
		"level_id": level_id,
		"moves": moves,
		"target": target,
		"available_types": available_types,
		"special_elements": {
			"bomb_probability": bomb_prob,
			"rainbow_probability": rainbow_prob
		}
	}

func _get_available_types(level_id: int) -> Array:
	var all_types = [1, 2, 3, 4, 5, 6]  # 对应6种花朵
	
	if level_id <= 5:
		# 1-5关：3种元素
		return all_types.slice(0, 3)
	elif level_id <= 10:
		# 6-10关：4种元素
		return all_types.slice(0, 4)
	elif level_id <= 15:
		# 11-15关：5种元素
		return all_types.slice(0, 5)
	else:
		# 16-20关：6种元素
		return all_types

func _generate_target(_level_id: int, difficulty: float, available_types: Array) -> Dictionary:
	var requirements = []
	
	# 目标数量类型
	var num_types = mini(1 + int(difficulty * 2), available_types.size())
	
	for i in range(num_types):
		var tile_type = available_types[i]
		# 收集数量：从15逐渐增加到35
		var count = int(15 + difficulty * 20)
		
		# 添加一些随机性
		count += randi() % 5 - 2
		count = maxi(count, 10)
		
		requirements.append({
			"tile_type": tile_type,
			"count": count
		})
	
	return {
		"type": "collect",
		"requirements": requirements
	}

func _save_level(level_id: int, data: Dictionary) -> void:
	var file_path = "res://levels/level_%03d.json" % level_id
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		print("❌ 保存关卡失败: ", file_path)
