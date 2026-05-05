## FlowerLanguageService - 花语碎片与解锁服务
extends Node

const FRAGMENTS_TO_UNLOCK: int = 5

const FLOWER_TYPES: Array[int] = [
	Constants.TileType.RED_ROSE,
	Constants.TileType.BLUE_FORGET_ME_NOT,
	Constants.TileType.PURPLE_LAVENDER,
	Constants.TileType.YELLOW_SUNFLOWER,
	Constants.TileType.WHITE_JASMINE,
	Constants.TileType.PINK_CHERRY
]


func add_fragments(flower_type: int, amount: int) -> Dictionary:
	if amount <= 0 or not FLOWER_TYPES.has(flower_type):
		return {
			"success": false,
			"flower_type": flower_type,
			"amount": 0,
			"unlocked_now": false
		}

	var flower_language = SaveManager.get_flower_language_data()
	var fragments = flower_language.get("fragments", {})
	var unlocked = flower_language.get("unlocked", [])
	var key = str(flower_type)
	var previous_amount = int(fragments.get(key, 0))
	var new_amount = mini(previous_amount + amount, FRAGMENTS_TO_UNLOCK)
	var was_unlocked = unlocked.has(flower_type)

	fragments[key] = new_amount
	var unlocked_now = false
	if new_amount >= FRAGMENTS_TO_UNLOCK and not was_unlocked:
		unlocked.append(flower_type)
		unlocked_now = true

	flower_language["fragments"] = fragments
	flower_language["unlocked"] = unlocked
	SaveManager.update_flower_language_data(flower_language)
	DailyService.record_event(DailyService.TASK_COLLECT_FLOWER_FRAGMENT, amount)

	return {
		"success": true,
		"flower_type": flower_type,
		"amount": amount,
		"total_fragments": new_amount,
		"required_fragments": FRAGMENTS_TO_UNLOCK,
		"unlocked_now": unlocked_now
	}


func is_unlocked(flower_type: int) -> bool:
	return SaveManager.get_flower_language_data().get("unlocked", []).has(flower_type)


func get_fragment_count(flower_type: int) -> int:
	var fragments = SaveManager.get_flower_language_data().get("fragments", {})
	return int(fragments.get(str(flower_type), 0))


func get_journal_entries() -> Array:
	var entries = []
	for flower_type in FLOWER_TYPES:
		var unlocked = is_unlocked(flower_type)
		entries.append({
			"flower_type": flower_type,
			"name": Constants.TILE_NAMES.get(flower_type, "花朵"),
			"language": Constants.TILE_LANGUAGES.get(flower_type, ""),
			"fragments": get_fragment_count(flower_type),
			"required_fragments": FRAGMENTS_TO_UNLOCK,
			"unlocked": unlocked
		})
	return entries


func format_fragment_reward(reward: Dictionary) -> String:
	var flower_type = int(reward.get("flower_type", Constants.TileType.RED_ROSE))
	var amount = int(reward.get("amount", 0))
	var total = int(reward.get("total_fragments", get_fragment_count(flower_type)))
	var required = int(reward.get("required_fragments", FRAGMENTS_TO_UNLOCK))
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	var line = "获得 %s 花语碎片 x%d（%d/%d）" % [flower_name, amount, total, required]
	if reward.get("unlocked_now", false):
		line += "\n解锁花语：%s" % Constants.TILE_LANGUAGES.get(flower_type, "")
	return line
