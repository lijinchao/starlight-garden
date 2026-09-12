## DailyChallengeService - 本地、可复现的每日风庭配置与成绩
extends Node

const CHALLENGE_VERSION := "daily_v1"
const BASE_LEVEL_ID := 4
const TRANSFORMS := ["origin", "mirror_horizontal", "mirror_vertical", "rotate_180"]

const LAYOUTS: Array[Dictionary] = [
	{
		"id": "ring", "name": "露珠环庭",
		"cells": [[2, 2], [2, 3], [2, 4], [3, 2], [3, 4], [4, 2], [4, 3], [4, 4]],
		"dew_buds": [[2, 3], [4, 3]]
	},
	{
		"id": "double_island", "name": "双岛花径",
		"cells": [[1, 1], [1, 2], [2, 1], [2, 2], [3, 4], [3, 5], [4, 4], [4, 5]],
		"dew_buds": [[2, 2], [3, 4]]
	},
	{
		"id": "diagonal", "name": "斜风小径",
		"cells": [[1, 1], [1, 2], [2, 1], [2, 2], [2, 3], [3, 2], [3, 3], [3, 4], [4, 3], [4, 4], [4, 5], [5, 4], [5, 5]],
		"dew_buds": [[2, 2], [3, 3], [4, 4]]
	}
]


func get_today_challenge() -> Dictionary:
	return get_challenge_for_date(DailyService.get_today_key())


func get_challenge_for_date(date_key: String) -> Dictionary:
	var date_number = _date_number(date_key)
	var seed = _seed_from_date(date_key)
	var layout_index = posmod(date_number, LAYOUTS.size())
	var transform_index = posmod(int(date_number / LAYOUTS.size()), TRANSFORMS.size())
	var preferred_direction = "horizontal" if posmod(date_number, 2) == 0 else "vertical"
	var layout = LAYOUTS[layout_index]
	var transformed_cells = _transform_positions(layout.get("cells", []), TRANSFORMS[transform_index])
	var transformed_buds = _transform_positions(layout.get("dew_buds", []), TRANSFORMS[transform_index])
	var challenge_id = "%s_%s" % [CHALLENGE_VERSION, date_key.replace("-", "")]
	var config = {
		"level_id": BASE_LEVEL_ID,
		"moves": 26,
		"available_types": [
			Constants.TileType.RED_ROSE,
			Constants.TileType.BLUE_FORGET_ME_NOT,
			Constants.TileType.PURPLE_LAVENDER,
			Constants.TileType.YELLOW_SUNFLOWER
		],
		"board_seed": seed,
		"is_daily_challenge": true,
		"daily_challenge": {
			"challenge_id": challenge_id,
			"date": date_key,
			"layout_id": str(layout.get("id", "ring")),
			"layout_name": str(layout.get("name", "今日风庭")),
			"transform": TRANSFORMS[transform_index],
			"seed": seed,
			"preferred_direction": preferred_direction
		},
		"target": {
			"type": "collect",
			"requirements": [{"tile_type": Constants.TileType.RED_ROSE, "count": 18}],
			"garden_layer": {
				"type": "fallen_leaves",
				"required": transformed_cells.size(),
				"cells": transformed_cells,
				"dew_buds": transformed_buds
			},
			"theme": {
				"objective_name": "今日风庭：%s" % str(layout.get("name", "晨露花庭")),
				"objective_detail": "观察晨露花苞的位置，顺着风向扫开整片落叶。",
				"focus_name": "晨露花庭",
				"breeze_label": "今日清风",
				"breeze_bonus": 2,
				"result_name": "今日花庭亮起来了"
			},
		},
		"rewards": {"seed_type": Constants.TileType.RED_ROSE, "seed_count": 0, "stars": 0, "first_clear_bonus": {"stars": 0, "seed_count": 0}}
	}
	return {"challenge": config.get("daily_challenge", {}).duplicate(true), "config": config}


func get_today_progress() -> Dictionary:
	var daily = DailyService.get_daily_state()
	var challenge = get_today_challenge().get("challenge", {})
	var progress = daily.get("challenge", {})
	if str(progress.get("challenge_id", "")) != str(challenge.get("challenge_id", "")):
		progress = {}
	return progress.duplicate(true)


func record_result(challenge: Dictionary, won: bool, moves_left: int, theme_progress: Dictionary) -> Dictionary:
	var daily = DailyService.get_daily_state()
	var result = daily.get("challenge", {})
	if str(result.get("challenge_id", "")) != str(challenge.get("challenge_id", "")):
		result = {"challenge_id": str(challenge.get("challenge_id", "")), "attempts": 0, "completed": false, "best_moves_left": -1, "best_chain": 0, "best_leaf_ratio": 0.0}
	result["attempts"] = int(result.get("attempts", 0)) + 1
	result["completed"] = bool(result.get("completed", false)) or won
	result["best_moves_left"] = maxi(int(result.get("best_moves_left", -1)), moves_left if won else -1)
	result["best_chain"] = maxi(int(result.get("best_chain", 0)), int(theme_progress.get("max_dew_chain", 0)))
	var total = maxi(1, int(theme_progress.get("garden_layers_total", 0)))
	var ratio = float(theme_progress.get("garden_layers_cleared", 0)) / total
	result["best_leaf_ratio"] = maxf(float(result.get("best_leaf_ratio", 0.0)), ratio)
	result["last_outcome"] = "victory" if won else "failure"
	daily["challenge"] = result
	SaveManager.update_daily_data(daily)
	return result.duplicate(true)


func _seed_from_date(date_key: String) -> int:
	return _date_number(date_key) * 1103515245 + 12345


func _date_number(date_key: String) -> int:
	var digits = date_key.replace("-", "")
	if not digits.is_valid_int():
		return 20260825
	return int(digits)


func _transform_positions(positions: Array, transform: String) -> Array:
	var transformed: Array = []
	for raw_pos in positions:
		if not raw_pos is Array or raw_pos.size() < 2:
			continue
		var row = int(raw_pos[0])
		var col = int(raw_pos[1])
		match transform:
			"mirror_horizontal": col = Constants.GRID_COLS - 1 - col
			"mirror_vertical": row = Constants.GRID_ROWS - 1 - row
			"rotate_180":
				row = Constants.GRID_ROWS - 1 - row
				col = Constants.GRID_COLS - 1 - col
		transformed.append([row, col])
	return transformed
