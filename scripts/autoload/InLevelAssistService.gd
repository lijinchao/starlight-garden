## InLevelAssistService - 局内星光辅助服务
extends Node

const BREEZE_COST: int = 8
const BREEZE_MAX_USES_PER_LEVEL: int = 1

var current_level_id: int = 0
var breeze_uses: int = 0


func start_level(level_id: int) -> void:
	current_level_id = level_id
	breeze_uses = 0


func get_breeze_uses_remaining() -> int:
	return maxi(0, BREEZE_MAX_USES_PER_LEVEL - breeze_uses)


func try_use_breeze() -> Dictionary:
	if get_breeze_uses_remaining() <= 0:
		return {
			"success": false,
			"reason": "limit_reached",
			"cost": BREEZE_COST,
			"remaining": 0
		}

	if not EconomyService.spend_stars(BREEZE_COST):
		return {
			"success": false,
			"reason": "not_enough_stars",
			"cost": BREEZE_COST,
			"remaining": get_breeze_uses_remaining()
		}

	breeze_uses += 1
	return {
		"success": true,
		"cost": BREEZE_COST,
		"remaining": get_breeze_uses_remaining()
	}
