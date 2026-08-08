## SaveManager - 全局存档管理器
extends Node

# 存档路径
const SAVE_PATH = "user://savegame.dat"

# 默认存档数据
const DEFAULT_DATA = {
	"player": {
		"level": 1,
		"stars": 0,
		"coins": 0,
		"total_score": 0,
		"total_runs": 0,
		"cleared_levels": [],
		"failure_streak": 0
	},
	"garden": {
		"slots": [],
		"inventory": [],
		"decorations": [],
		"restoration_stage": 0
	},
	"flower_language": {
		"fragments": {},
		"unlocked": []
	},
	"daily": {
		"date": "",
		"gift_claimed": false,
		"tasks": {}
	},
	"settings": {
		"bgm_volume": 0.5,
		"sfx_volume": 0.7,
		"language": "zh_CN"
	}
}

const RESTORATION_STAGES: Array[Dictionary] = [
	{
		"stage": 0,
		"name": "沉睡角",
		"icon": "🌙",
		"description": "先打一局，让第一束微光落进花园。",
		"preview": "🪴   🍂   🌙",
		"next_goal": "再完成 1 局，这里会冒出第一簇新芽。",
		"focus_title": "左侧空盆",
		"focus_detail": "第一束微光会先落在左侧空盆。",
		"focus_slot": 0
	},
	{
		"stage": 1,
		"name": "发芽角",
		"icon": "🌱",
		"description": "第一处花圃苏醒了。",
		"preview": "🪴   🌱   ✨",
		"next_goal": "再完成 1 局，会有第一朵花先开。",
		"focus_title": "第一簇新芽",
		"focus_detail": "左侧空盆已经冒出第一簇新芽。",
		"focus_slot": 0
	},
	{
		"stage": 2,
		"name": "初绽角",
		"icon": "🌸",
		"description": "第二处角落开始开花。",
		"preview": "🌿   🌸   ✨",
		"next_goal": "再完成 1 局，花园会点亮成微光庭。",
		"focus_title": "第一朵花",
		"focus_detail": "中间花圃已经先开出第一朵花。",
		"focus_slot": 1
	},
	{
		"stage": 3,
		"name": "微光庭",
		"icon": "✨",
		"description": "花园已经会轻轻呼吸了。",
		"preview": "🌸   ✨   🏡",
		"next_goal": "前三局恢复完成，接下来可以慢慢装点这里。",
		"focus_title": "门前微灯",
		"focus_detail": "门前的微灯已经亮起来了。",
		"focus_slot": 3
	}
]

# 当前存档数据
var save_data: Dictionary = {}

func _ready() -> void:
	load_game()
	print("SaveManager initialized")

# 保存游戏
func save_game() -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully")
		return true
	else:
		print("Failed to save game")
		return false

# 加载游戏
func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				save_data = _normalize_save_data(json.data)
				print("Game loaded successfully")
				return
	
	# 如果没有存档或加载失败，使用默认数据
	save_data = _normalize_save_data(DEFAULT_DATA.duplicate(true))
	print("Using default save data")

# 获取玩家数据
func get_player_data() -> Dictionary:
	return save_data.get("player", DEFAULT_DATA["player"])

# 更新玩家数据
func update_player_data(data: Dictionary) -> void:
	if not save_data.has("player"):
		save_data["player"] = {}
	save_data["player"].merge(data, true)
	save_game()

# 获取花园数据
func get_garden_data() -> Dictionary:
	if not save_data.has("garden"):
		save_data["garden"] = DEFAULT_DATA["garden"].duplicate(true)
	return _normalize_garden_data(save_data["garden"])

# 更新花园数据
func update_garden_data(data: Dictionary) -> void:
	save_data["garden"] = _normalize_garden_data(data)
	save_game()


func get_restoration_state() -> Dictionary:
	var garden_data = get_garden_data()
	var stage = clampi(int(garden_data.get("restoration_stage", 0)), 0, RESTORATION_STAGES.size() - 1)
	var state = RESTORATION_STAGES[stage].duplicate(true)
	state["total_stages"] = RESTORATION_STAGES.size() - 1
	return state


func sync_restoration_stage(total_runs: int = -1) -> Dictionary:
	var normalized_total_runs = total_runs
	if normalized_total_runs < 0:
		normalized_total_runs = int(get_player_data().get("total_runs", 0))

	var target_stage = clampi(normalized_total_runs, 0, RESTORATION_STAGES.size() - 1)
	var garden_data = get_garden_data()
	var previous_stage = int(garden_data.get("restoration_stage", 0))
	if previous_stage != target_stage:
		garden_data["restoration_stage"] = target_stage
		update_garden_data(garden_data)

	var state = get_restoration_state()
	state["changed"] = previous_stage != target_stage
	state["previous_stage"] = previous_stage
	state["target_stage"] = target_stage
	state["total_runs"] = normalized_total_runs
	return state


func get_flower_language_data() -> Dictionary:
	if not save_data.has("flower_language"):
		save_data["flower_language"] = DEFAULT_DATA["flower_language"].duplicate(true)
	return _normalize_flower_language_data(save_data["flower_language"])


func update_flower_language_data(data: Dictionary) -> void:
	save_data["flower_language"] = _normalize_flower_language_data(data)
	save_game()


func get_daily_data() -> Dictionary:
	if not save_data.has("daily"):
		save_data["daily"] = DEFAULT_DATA["daily"].duplicate(true)
	return _normalize_daily_data(save_data["daily"])


func update_daily_data(data: Dictionary) -> void:
	save_data["daily"] = _normalize_daily_data(data)
	save_game()


func add_garden_inventory_item(flower_type: int, level: int = 1, amount: int = 1) -> void:
	if amount <= 0:
		return

	var garden_data = get_garden_data()
	var inventory = garden_data.get("inventory", [])
	var item_found = false

	for item in inventory:
		if item.get("type") == flower_type and item.get("level", 1) == level:
			item["amount"] = item.get("amount", 0) + amount
			item_found = true
			break

	if not item_found:
		inventory.append({
			"type": flower_type,
			"level": level,
			"amount": amount
		})

	garden_data["inventory"] = inventory
	update_garden_data(garden_data)


func consume_garden_inventory_item(flower_type: int, level: int = 1, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var garden_data = get_garden_data()
	var inventory = garden_data.get("inventory", [])

	for i in range(inventory.size()):
		var item = inventory[i]
		if item.get("type") == flower_type and item.get("level", 1) == level:
			var current_amount = item.get("amount", 0)
			if current_amount < amount:
				return false

			item["amount"] = current_amount - amount
			if item["amount"] <= 0:
				inventory.remove_at(i)
			else:
				inventory[i] = item

			garden_data["inventory"] = inventory
			update_garden_data(garden_data)
			return true

	return false

# 获取设置
func get_settings() -> Dictionary:
	return save_data.get("settings", DEFAULT_DATA["settings"])

# 更新设置
func update_settings(data: Dictionary) -> void:
	if not save_data.has("settings"):
		save_data["settings"] = {}
	save_data["settings"].merge(data, true)
	save_game()

# 重置存档
func reset_save() -> void:
	save_data = _normalize_save_data(DEFAULT_DATA.duplicate(true))
	save_game()
	print("Save data reset")

# 删除存档
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	save_data = _normalize_save_data(DEFAULT_DATA.duplicate(true))
	print("Save data deleted")


func _normalize_save_data(data: Dictionary) -> Dictionary:
	var normalized = DEFAULT_DATA.duplicate(true)

	if data.has("player") and data["player"] is Dictionary:
		normalized["player"].merge(data["player"], true)

	if data.has("settings") and data["settings"] is Dictionary:
		normalized["settings"].merge(data["settings"], true)

	if data.has("garden") and data["garden"] is Dictionary:
		normalized["garden"] = _normalize_garden_data(data["garden"])

	if data.has("flower_language") and data["flower_language"] is Dictionary:
		normalized["flower_language"] = _normalize_flower_language_data(data["flower_language"])

	if data.has("daily") and data["daily"] is Dictionary:
		normalized["daily"] = _normalize_daily_data(data["daily"])

	return normalized


func _normalize_garden_data(data: Dictionary) -> Dictionary:
	var normalized = {
		"slots": [],
		"inventory": [],
		"decorations": [],
		"restoration_stage": 0
	}

	if data.has("slots") and data["slots"] is Array:
		normalized["slots"] = data["slots"].duplicate(true)
	elif data.has("flowers") and data["flowers"] is Array:
		normalized["slots"] = data["flowers"].duplicate(true)

	if data.has("inventory") and data["inventory"] is Array:
		normalized["inventory"] = data["inventory"].duplicate(true)

	if data.has("decorations") and data["decorations"] is Array:
		normalized["decorations"] = data["decorations"].duplicate(true)

	normalized["restoration_stage"] = clampi(int(data.get("restoration_stage", 0)), 0, RESTORATION_STAGES.size() - 1)

	return normalized


func _normalize_flower_language_data(data: Dictionary) -> Dictionary:
	var normalized = {
		"fragments": {},
		"unlocked": []
	}

	if data.has("fragments") and data["fragments"] is Dictionary:
		for key in data["fragments"].keys():
			normalized["fragments"][str(key)] = int(data["fragments"][key])

	if data.has("unlocked") and data["unlocked"] is Array:
		for flower_type in data["unlocked"]:
			var type_id = int(flower_type)
			if not normalized["unlocked"].has(type_id):
				normalized["unlocked"].append(type_id)

	return normalized


func _normalize_daily_data(data: Dictionary) -> Dictionary:
	var normalized = {
		"date": str(data.get("date", "")),
		"gift_claimed": bool(data.get("gift_claimed", false)),
		"tasks": {}
	}

	if data.has("tasks") and data["tasks"] is Dictionary:
		for key in data["tasks"].keys():
			var task = data["tasks"][key]
			if not task is Dictionary:
				continue
			normalized["tasks"][str(key)] = {
				"title": str(task.get("title", "")),
				"progress": int(task.get("progress", 0)),
				"target": max(1, int(task.get("target", 1))),
				"completed": bool(task.get("completed", false))
			}

	return normalized
