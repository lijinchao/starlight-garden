## DecorationService - 花园装饰购买与氛围值服务
extends Node

const DECORATIONS: Array[Dictionary] = [
	{
		"id": "bench",
		"name": "木纹长椅",
		"icon": "🪑",
		"cost": 30,
		"atmosphere": 2
	},
	{
		"id": "lantern",
		"name": "星光灯笼",
		"icon": "🏮",
		"cost": 35,
		"atmosphere": 3
	},
	{
		"id": "fountain",
		"name": "小喷泉",
		"icon": "⛲",
		"cost": 45,
		"atmosphere": 4
	},
	{
		"id": "hedge",
		"name": "柔软花篱",
		"icon": "🌿",
		"cost": 25,
		"atmosphere": 2
	}
]


func get_decoration_catalog() -> Array:
	var catalog: Array = []
	for decoration in DECORATIONS:
		catalog.append(decoration.duplicate(true))
	return catalog


func get_owned_decorations() -> Array:
	return SaveManager.get_garden_data().get("decorations", [])


func is_owned(decoration_id: String) -> bool:
	for decoration in get_owned_decorations():
		if _get_owned_decoration_id(decoration) == decoration_id:
			return true
	return false


func purchase_decoration(decoration_id: String) -> Dictionary:
	var config = _get_decoration_config(decoration_id)
	if config.is_empty():
		return {
			"success": false,
			"reason": "invalid_id"
		}

	if is_owned(decoration_id):
		return {
			"success": false,
			"reason": "already_owned",
			"decoration": config
		}

	var cost = int(config.get("cost", 0))
	if not EconomyService.spend_stars(cost):
		return {
			"success": false,
			"reason": "not_enough_stars",
			"cost": cost,
			"decoration": config
		}

	var garden_data = SaveManager.get_garden_data()
	var decorations = garden_data.get("decorations", [])
	decorations.append({
		"id": decoration_id
	})
	garden_data["decorations"] = decorations
	SaveManager.update_garden_data(garden_data)

	return {
		"success": true,
		"decoration": config,
		"cost": cost,
		"atmosphere": int(config.get("atmosphere", 0))
	}


func get_atmosphere_value() -> int:
	var total = 0
	for decoration in get_owned_decorations():
		var config = _get_decoration_config(_get_owned_decoration_id(decoration))
		total += int(config.get("atmosphere", 0))
	return total


func get_display_data() -> Dictionary:
	var catalog: Array = []
	for decoration in DECORATIONS:
		var entry = decoration.duplicate(true)
		entry["owned"] = is_owned(str(entry.get("id", "")))
		catalog.append(entry)

	return {
		"catalog": catalog,
		"owned": get_owned_decorations(),
		"atmosphere": get_atmosphere_value(),
		"stars": EconomyService.get_stars()
	}


func _get_decoration_config(decoration_id: String) -> Dictionary:
	for decoration in DECORATIONS:
		if str(decoration.get("id", "")) == decoration_id:
			return decoration.duplicate(true)
	return {}


func _get_owned_decoration_id(decoration) -> String:
	if decoration is Dictionary:
		return str(decoration.get("id", ""))
	return str(decoration)
