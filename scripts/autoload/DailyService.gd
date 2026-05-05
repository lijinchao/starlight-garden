## DailyService - 每日任务与今日花礼服务
extends Node

const TASK_PLAY_LEVEL: String = "play_level"
const TASK_HARVEST_FLOWER: String = "harvest_flower"
const TASK_COLLECT_FLOWER_FRAGMENT: String = "collect_flower_fragment"

const GIFT_STARS: int = 20
const GIFT_SEED_TYPE: int = Constants.TileType.RED_ROSE
const GIFT_SEED_LEVEL: int = 1
const GIFT_SEED_COUNT: int = 1

const TASK_CONFIGS: Array[Dictionary] = [
	{
		"id": TASK_PLAY_LEVEL,
		"title": "完成任意 1 局",
		"target": 1
	},
	{
		"id": TASK_HARVEST_FLOWER,
		"title": "收获任意 1 朵花",
		"target": 1
	},
	{
		"id": TASK_COLLECT_FLOWER_FRAGMENT,
		"title": "获得任意 1 个花语碎片",
		"target": 1
	}
]


func get_today_key() -> String:
	var date = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]


func get_daily_state() -> Dictionary:
	var daily = SaveManager.get_daily_data()
	var today = get_today_key()
	if daily.get("date", "") != today:
		daily = _build_default_daily_data(today)
		SaveManager.update_daily_data(daily)
	return daily


func record_event(task_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0:
		return get_daily_state()

	var daily = get_daily_state()
	var tasks = daily.get("tasks", {})
	if not tasks.has(task_id):
		return daily

	var task = tasks[task_id]
	var target = int(task.get("target", 1))
	var progress = mini(int(task.get("progress", 0)) + amount, target)
	task["progress"] = progress
	task["completed"] = progress >= target
	tasks[task_id] = task
	daily["tasks"] = tasks
	SaveManager.update_daily_data(daily)
	return daily


func can_claim_gift() -> bool:
	var daily = get_daily_state()
	return not daily.get("gift_claimed", false) and _all_tasks_completed(daily)


func claim_gift() -> Dictionary:
	var daily = get_daily_state()
	if daily.get("gift_claimed", false):
		return {
			"success": false,
			"reason": "claimed"
		}

	if not _all_tasks_completed(daily):
		return {
			"success": false,
			"reason": "incomplete"
		}

	EconomyService.add_stars(GIFT_STARS)
	SaveManager.add_garden_inventory_item(GIFT_SEED_TYPE, GIFT_SEED_LEVEL, GIFT_SEED_COUNT)
	daily["gift_claimed"] = true
	SaveManager.update_daily_data(daily)

	return {
		"success": true,
		"stars": GIFT_STARS,
		"seed_type": GIFT_SEED_TYPE,
		"seed_level": GIFT_SEED_LEVEL,
		"seed_count": GIFT_SEED_COUNT
	}


func get_display_data() -> Dictionary:
	var daily = get_daily_state()
	var task_entries = []
	var tasks = daily.get("tasks", {})
	for config in TASK_CONFIGS:
		var task_id = config.get("id", "")
		var task = tasks.get(task_id, _build_task(config))
		task_entries.append({
			"id": task_id,
			"title": task.get("title", config.get("title", "")),
			"progress": int(task.get("progress", 0)),
			"target": int(task.get("target", config.get("target", 1))),
			"completed": task.get("completed", false)
		})

	return {
		"date": daily.get("date", get_today_key()),
		"tasks": task_entries,
		"gift_claimed": daily.get("gift_claimed", false),
		"can_claim": can_claim_gift(),
		"gift_stars": GIFT_STARS,
		"gift_seed_type": GIFT_SEED_TYPE,
		"gift_seed_count": GIFT_SEED_COUNT
	}


func _all_tasks_completed(daily: Dictionary) -> bool:
	var tasks = daily.get("tasks", {})
	for config in TASK_CONFIGS:
		var task = tasks.get(config.get("id", ""), {})
		if not task.get("completed", false):
			return false
	return true


func _build_default_daily_data(date_key: String = "") -> Dictionary:
	var tasks = {}
	for config in TASK_CONFIGS:
		tasks[config.get("id", "")] = _build_task(config)
	return {
		"date": date_key if not date_key.is_empty() else get_today_key(),
		"gift_claimed": false,
		"tasks": tasks
	}


func _build_task(config: Dictionary) -> Dictionary:
	return {
		"title": config.get("title", ""),
		"progress": 0,
		"target": int(config.get("target", 1)),
		"completed": false
	}
