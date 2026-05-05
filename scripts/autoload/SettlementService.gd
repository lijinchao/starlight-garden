## SettlementService - 统一关卡结算与资源发放
extends Node

const DEFAULT_BASE_STARS: int = 20
const DEFAULT_FIRST_CLEAR_STARS: int = 30
const DEFAULT_SEED_COUNT: int = 1
const DEFAULT_CONTINUE_COST: int = 10
const DEFAULT_CONTINUE_MOVES: int = 5
const FAILURE_BASE_STARS: int = 4
const FAILURE_BONUS_STARS: int = 8
const FAILURE_STREAK_THRESHOLD: int = 2
const FAILURE_STREAK_BONUS_STARS: int = 6
const VICTORY_FLOWER_LANGUAGE_FRAGMENTS: int = 2
const FIRST_CLEAR_FLOWER_LANGUAGE_FRAGMENTS: int = 1
const FAILURE_FLOWER_LANGUAGE_FRAGMENTS: int = 1

func build_victory_settlement(level_id: int, stars: int, score: int, level_config: Dictionary) -> Dictionary:
	var reward_config = _get_reward_config(level_config)
	var seed_type = _get_seed_type(level_config)
	var base_seed_count = int(reward_config.get("seed_count", DEFAULT_SEED_COUNT))
	var base_star_reward = int(reward_config.get("stars", DEFAULT_BASE_STARS))
	var first_clear_bonus = reward_config.get("first_clear_bonus", {})
	var is_first_clear = not _has_cleared_level(level_id)

	var total_seed_count = base_seed_count
	var total_star_reward = base_star_reward
	var flower_language_fragments = VICTORY_FLOWER_LANGUAGE_FRAGMENTS

	if is_first_clear:
		total_seed_count += int(first_clear_bonus.get("seed_count", 0))
		total_star_reward += int(first_clear_bonus.get("stars", DEFAULT_FIRST_CLEAR_STARS))
		flower_language_fragments += FIRST_CLEAR_FLOWER_LANGUAGE_FRAGMENTS

	return {
		"outcome": "victory",
		"level_id": level_id,
		"score": score,
		"stars_earned": stars,
		"is_first_clear": is_first_clear,
		"rewards": {
			"stars": total_star_reward,
			"seed_type": seed_type,
			"seed_level": 1,
			"seed_count": total_seed_count,
			"flower_language_type": seed_type,
			"flower_language_fragments": flower_language_fragments,
			"base_stars": base_star_reward,
			"first_clear_bonus": {
				"stars": int(first_clear_bonus.get("stars", DEFAULT_FIRST_CLEAR_STARS)) if is_first_clear else 0,
				"seed_count": int(first_clear_bonus.get("seed_count", 0)) if is_first_clear else 0,
				"flower_language_fragments": FIRST_CLEAR_FLOWER_LANGUAGE_FRAGMENTS if is_first_clear else 0
			}
		}
	}


func apply_victory_settlement(settlement: Dictionary) -> void:
	if settlement.get("outcome", "") != "victory":
		return

	var rewards = settlement.get("rewards", {})
	var player_data = SaveManager.get_player_data()
	player_data["total_score"] = player_data.get("total_score", 0) + int(settlement.get("score", 0))
	player_data["failure_streak"] = 0

	var level_id = int(settlement.get("level_id", 1))
	if level_id >= player_data.get("level", 1):
		player_data["level"] = level_id + 1

	var cleared_levels = player_data.get("cleared_levels", []).duplicate()
	if not cleared_levels.has(level_id):
		cleared_levels.append(level_id)
	player_data["cleared_levels"] = cleared_levels
	SaveManager.update_player_data(player_data)
	EconomyService.add_stars(int(rewards.get("stars", 0)))

	var seed_type = int(rewards.get("seed_type", Constants.TileType.RED_ROSE))
	var seed_level = int(rewards.get("seed_level", 1))
	var seed_count = int(rewards.get("seed_count", 0))
	if seed_count > 0:
		SaveManager.add_garden_inventory_item(seed_type, seed_level, seed_count)

	var fragment_count = int(rewards.get("flower_language_fragments", 0))
	if fragment_count > 0:
		var fragment_reward = FlowerLanguageService.add_fragments(
			int(rewards.get("flower_language_type", seed_type)),
			fragment_count
		)
		settlement["flower_language_reward"] = fragment_reward

	DailyService.record_event(DailyService.TASK_PLAY_LEVEL)
	GameManager.complete_level(int(settlement.get("stars_earned", 1)), int(settlement.get("score", 0)))


func build_failure_settlement(level_system: LevelSystem, continue_cost: int = DEFAULT_CONTINUE_COST) -> Dictionary:
	var progress_ratio = _calculate_progress_ratio(level_system.level_config, level_system.collected_tiles)
	var rest_stars = FAILURE_BASE_STARS + int(round(progress_ratio * FAILURE_BONUS_STARS))
	var current_failure_streak = int(SaveManager.get_player_data().get("failure_streak", 0))
	var next_failure_streak = current_failure_streak + 1
	var encouragement_triggered = next_failure_streak >= FAILURE_STREAK_THRESHOLD
	var encouragement_seed_type = _get_seed_type(level_system.level_config)
	var encouragement_seed_count = 1 if encouragement_triggered else 0
	var encouragement_bonus_stars = FAILURE_STREAK_BONUS_STARS if encouragement_triggered else 0

	return {
		"outcome": "failure",
		"level_id": level_system.current_level_id,
		"progress_ratio": progress_ratio,
		"failure_streak": next_failure_streak,
		"encouragement_triggered": encouragement_triggered,
		"moves_used": level_system.level_config.get("moves", Constants.MAX_MOVES_DEFAULT) - level_system.moves_left,
		"continue_cost": continue_cost,
		"rest_rewards": {
			"stars": rest_stars + encouragement_bonus_stars,
			"base_stars": rest_stars,
			"encouragement_bonus_stars": encouragement_bonus_stars,
			"seed_type": encouragement_seed_type,
			"seed_level": 1,
			"seed_count": encouragement_seed_count,
			"flower_language_type": encouragement_seed_type,
			"flower_language_fragments": FAILURE_FLOWER_LANGUAGE_FRAGMENTS
		}
	}


func apply_failure_settlement(settlement: Dictionary) -> void:
	if settlement.get("outcome", "") != "failure":
		return

	var player_data = SaveManager.get_player_data()
	var rest_rewards = settlement.get("rest_rewards", {})
	player_data["failure_streak"] = player_data.get("failure_streak", 0) + 1
	SaveManager.update_player_data(player_data)
	EconomyService.add_stars(int(rest_rewards.get("stars", 0)))

	var seed_count = int(rest_rewards.get("seed_count", 0))
	if seed_count > 0:
		SaveManager.add_garden_inventory_item(
			int(rest_rewards.get("seed_type", Constants.TileType.RED_ROSE)),
			int(rest_rewards.get("seed_level", 1)),
			seed_count
		)

	var fragment_count = int(rest_rewards.get("flower_language_fragments", 0))
	if fragment_count > 0:
		var fragment_reward = FlowerLanguageService.add_fragments(
			int(rest_rewards.get("flower_language_type", rest_rewards.get("seed_type", Constants.TileType.RED_ROSE))),
			fragment_count
		)
		settlement["flower_language_reward"] = fragment_reward

	DailyService.record_event(DailyService.TASK_PLAY_LEVEL)


func try_continue_level(level_system: LevelSystem, continue_cost: int = DEFAULT_CONTINUE_COST, extra_moves: int = DEFAULT_CONTINUE_MOVES) -> bool:
	if EconomyService.get_stars() < continue_cost:
		return false

	if not level_system.continue_level(extra_moves):
		return false

	if not EconomyService.spend_stars(continue_cost):
		return false
	return true


func format_rewards_summary(settlement: Dictionary) -> Array:
	var lines = []
	if settlement.get("outcome", "") == "victory":
		var rewards = settlement.get("rewards", {})
		var seed_count = int(rewards.get("seed_count", 0))
		var seed_type = int(rewards.get("seed_type", Constants.TileType.RED_ROSE))
		var star_reward = int(rewards.get("stars", 0))
		lines.append("获得 %d ✨" % star_reward)
		if seed_count > 0:
			lines.append("获得 %s 花种 x%d" % [Constants.TILE_NAMES.get(seed_type, "花种"), seed_count])
		var fragment_count = int(rewards.get("flower_language_fragments", 0))
		if fragment_count > 0:
			var fragment_reward = settlement.get("flower_language_reward", {
				"flower_type": int(rewards.get("flower_language_type", seed_type)),
				"amount": fragment_count
			})
			lines.append(FlowerLanguageService.format_fragment_reward(fragment_reward))
		if settlement.get("is_first_clear", false):
			lines.append("首通奖励已发放")
	elif settlement.get("outcome", "") == "failure":
		var rest_rewards = settlement.get("rest_rewards", {})
		lines.append("安慰奖励 %d ✨" % int(rest_rewards.get("stars", 0)))
		var seed_count = int(rest_rewards.get("seed_count", 0))
		if seed_count > 0:
			var seed_type = int(rest_rewards.get("seed_type", Constants.TileType.RED_ROSE))
			lines.append("获得鼓励花种 %s x%d" % [Constants.TILE_NAMES.get(seed_type, "花种"), seed_count])
		var fragment_count = int(rest_rewards.get("flower_language_fragments", 0))
		if fragment_count > 0:
			var fragment_reward = settlement.get("flower_language_reward", {
				"flower_type": int(rest_rewards.get("flower_language_type", rest_rewards.get("seed_type", Constants.TileType.RED_ROSE))),
				"amount": fragment_count
			})
			lines.append(FlowerLanguageService.format_fragment_reward(fragment_reward))
		if settlement.get("encouragement_triggered", false):
			lines.append("连续失败鼓励已触发")
		lines.append("完成度 %d%%" % int(round(float(settlement.get("progress_ratio", 0.0)) * 100.0)))
	return lines


func _get_reward_config(level_config: Dictionary) -> Dictionary:
	var rewards = level_config.get("rewards", {})
	if rewards.is_empty():
		return {
			"seed_type": _get_seed_type(level_config),
			"seed_count": DEFAULT_SEED_COUNT,
			"stars": DEFAULT_BASE_STARS,
			"first_clear_bonus": {
				"stars": DEFAULT_FIRST_CLEAR_STARS,
				"seed_count": 1
			}
		}
	return rewards


func _get_seed_type(level_config: Dictionary) -> int:
	var rewards = level_config.get("rewards", {})
	if rewards.has("seed_type"):
		return int(rewards.get("seed_type", Constants.TileType.RED_ROSE))

	var requirements = level_config.get("target", {}).get("requirements", [])
	if not requirements.is_empty():
		return int(requirements[0].get("tile_type", Constants.TileType.RED_ROSE))

	var available_types = level_config.get("available_types", [])
	if not available_types.is_empty():
		return int(available_types[0])

	return Constants.TileType.RED_ROSE


func _has_cleared_level(level_id: int) -> bool:
	var player_data = SaveManager.get_player_data()
	var cleared_levels = player_data.get("cleared_levels", [])
	return cleared_levels.has(level_id)


func _calculate_progress_ratio(level_config: Dictionary, collected_tiles: Dictionary) -> float:
	var requirements = level_config.get("target", {}).get("requirements", [])
	if requirements.is_empty():
		return 0.0

	var total_required = 0
	var total_collected = 0
	for req in requirements:
		var tile_type = int(req.get("tile_type", Constants.TileType.RED_ROSE))
		var required_count = int(req.get("count", 0))
		total_required += required_count
		total_collected += mini(int(collected_tiles.get(str(tile_type), 0)), required_count)

	if total_required <= 0:
		return 0.0

	return clampf(float(total_collected) / float(total_required), 0.0, 1.0)
