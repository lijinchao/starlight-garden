## GardenSynthesisService - 花园合成服务
extends Node

const MAX_SYNTHESIS_LEVEL: int = 3
const SYNTHESIS_COST_COUNT: int = 2

func can_synthesize(flower_type: int, level: int, amount: int) -> bool:
	return level >= 1 and level < MAX_SYNTHESIS_LEVEL and amount >= SYNTHESIS_COST_COUNT


func synthesize_once(flower_type: int, level: int) -> Dictionary:
	if level < 1 or level >= MAX_SYNTHESIS_LEVEL:
		return {"success": false, "reason": "invalid_level"}

	var garden_data = SaveManager.get_garden_data()
	var inventory = garden_data.get("inventory", [])
	var current_amount = _get_inventory_amount(inventory, flower_type, level)
	if current_amount < SYNTHESIS_COST_COUNT:
		return {"success": false, "reason": "not_enough_items"}

	if not SaveManager.consume_garden_inventory_item(flower_type, level, SYNTHESIS_COST_COUNT):
		return {"success": false, "reason": "consume_failed"}

	SaveManager.add_garden_inventory_item(flower_type, level + 1, 1)
	return {
		"success": true,
		"from_type": flower_type,
		"from_level": level,
		"to_level": level + 1,
		"cost_count": SYNTHESIS_COST_COUNT
	}


func _get_inventory_amount(inventory: Array, flower_type: int, level: int) -> int:
	for item in inventory:
		if item.get("type") == flower_type and item.get("level", 1) == level:
			return int(item.get("amount", 0))
	return 0
