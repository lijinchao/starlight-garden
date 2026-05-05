## EconomyService - 统一经济资源接口
extends Node

func get_stars() -> int:
	return int(SaveManager.get_player_data().get("stars", 0))


func add_stars(amount: int) -> bool:
	if amount <= 0:
		return false

	var player_data = SaveManager.get_player_data()
	player_data["stars"] = int(player_data.get("stars", 0)) + amount
	SaveManager.update_player_data(player_data)
	return true


func spend_stars(amount: int) -> bool:
	if amount <= 0:
		return false

	var player_data = SaveManager.get_player_data()
	var current_stars = int(player_data.get("stars", 0))
	if current_stars < amount:
		return false

	player_data["stars"] = current_stars - amount
	SaveManager.update_player_data(player_data)
	return true
