## MetaUnlockService - 行为驱动的局外能力解锁与单提示队列
extends Node

const FEATURE_SYNTHESIS := "synthesis"
const FEATURE_FLOWER_JOURNAL := "flower_journal"
const FEATURE_DAILY_GIFT := "daily_gift"
const FEATURE_DECORATION := "decoration"
const FEATURE_STAR_BLESSING := "star_blessing"

const BEHAVIOR_FLOWER_HARVESTED := "flower_harvested"
const BEHAVIOR_LEVEL_FAILED := "level_failed"

const FEATURE_ORDER: Array[String] = [
	FEATURE_SYNTHESIS,
	FEATURE_FLOWER_JOURNAL,
	FEATURE_DAILY_GIFT,
	FEATURE_DECORATION,
	FEATURE_STAR_BLESSING
]

const FEATURE_CONFIGS: Dictionary = {
	FEATURE_SYNTHESIS: {
		"title": "新发现：花种合成",
		"detail": "背包里有两颗同级花种，去花园预览一次合成收益。",
		"action": "garden"
	},
	FEATURE_FLOWER_JOURNAL: {
		"title": "新发现：第一则花语",
		"detail": "一朵花的碎片已经集齐，去看看刚解锁的花语。",
		"action": "flower_journal"
	},
	FEATURE_DAILY_GIFT: {
		"title": "新发现：今日花礼",
		"detail": "你已经完成第一次收获，今日小目标现在有了实际进度。",
		"action": "daily_gift"
	},
	FEATURE_DECORATION: {
		"title": "新发现：固定装饰",
		"detail": "收获的星光已经足够点亮一处花园装饰。",
		"action": "garden"
	},
	FEATURE_STAR_BLESSING: {
		"title": "新发现：星光祝福",
		"detail": "失败后可以用少量星光换取额外步数，也可以直接继续。",
		"action": "start"
	}
}


func is_unlocked(feature_id: String) -> bool:
	return SaveManager.get_meta_progression_data().get("unlocked", []).has(feature_id)


func record_behavior(behavior_id: String, amount: int = 1) -> void:
	if behavior_id.is_empty() or amount <= 0:
		return
	var state = SaveManager.get_meta_progression_data()
	var counts = state.get("behavior_counts", {})
	counts[behavior_id] = int(counts.get(behavior_id, 0)) + amount
	state["behavior_counts"] = counts
	_refresh_state(state)
	SaveManager.update_meta_progression_data(state)


func refresh_eligibility() -> Array[String]:
	var state = SaveManager.get_meta_progression_data()
	var added = _refresh_state(state)
	if not added.is_empty():
		SaveManager.update_meta_progression_data(state)
	return added


func begin_home_visit() -> Dictionary:
	var state = SaveManager.get_meta_progression_data()
	_refresh_state(state)
	var active_prompt = str(state.get("active_prompt", ""))
	var newly_presented = false

	if active_prompt.is_empty():
		var pending = state.get("pending", [])
		if not pending.is_empty():
			active_prompt = str(pending.pop_front())
			state["pending"] = pending
			var unlocked = state.get("unlocked", [])
			if not unlocked.has(active_prompt):
				unlocked.append(active_prompt)
			state["unlocked"] = unlocked
			state["active_prompt"] = active_prompt
			newly_presented = true

	SaveManager.update_meta_progression_data(state)
	var prompt = get_feature_config(active_prompt)
	if not prompt.is_empty():
		prompt["feature_id"] = active_prompt
		prompt["newly_presented"] = newly_presented
	return prompt


func get_active_prompt() -> Dictionary:
	var feature_id = str(SaveManager.get_meta_progression_data().get("active_prompt", ""))
	var prompt = get_feature_config(feature_id)
	if not prompt.is_empty():
		prompt["feature_id"] = feature_id
		prompt["newly_presented"] = false
	return prompt


func complete_feature_task(feature_id: String) -> bool:
	if feature_id.is_empty() or not is_unlocked(feature_id):
		return false
	var state = SaveManager.get_meta_progression_data()
	var completed = state.get("completed_tasks", [])
	if completed.has(feature_id):
		return false
	completed.append(feature_id)
	state["completed_tasks"] = completed
	if str(state.get("active_prompt", "")) == feature_id:
		state["active_prompt"] = ""
	_refresh_state(state)
	SaveManager.update_meta_progression_data(state)
	return true


func get_feature_config(feature_id: String) -> Dictionary:
	if not FEATURE_CONFIGS.has(feature_id):
		return {}
	return FEATURE_CONFIGS[feature_id].duplicate(true)


func _refresh_state(state: Dictionary) -> Array[String]:
	var added: Array[String] = []
	var unlocked = state.get("unlocked", [])
	var pending = state.get("pending", [])
	for feature_id in FEATURE_ORDER:
		if unlocked.has(feature_id) or pending.has(feature_id):
			continue
		if _is_eligible(feature_id, state):
			pending.append(feature_id)
			added.append(feature_id)
	state["pending"] = pending
	return added


func _is_eligible(feature_id: String, state: Dictionary) -> bool:
	match feature_id:
		FEATURE_SYNTHESIS:
			return _has_synthesis_pair()
		FEATURE_FLOWER_JOURNAL:
			return not SaveManager.get_flower_language_data().get("unlocked", []).is_empty()
		FEATURE_DAILY_GIFT:
			return _get_behavior_count(state, BEHAVIOR_FLOWER_HARVESTED) > 0
		FEATURE_DECORATION:
			return (
				_get_behavior_count(state, BEHAVIOR_FLOWER_HARVESTED) > 0
				and EconomyService.get_stars() >= 25
			)
		FEATURE_STAR_BLESSING:
			return _get_behavior_count(state, BEHAVIOR_LEVEL_FAILED) > 0
	return false


func _get_behavior_count(state: Dictionary, behavior_id: String) -> int:
	return int(state.get("behavior_counts", {}).get(behavior_id, 0))


func _has_synthesis_pair() -> bool:
	for item in SaveManager.get_garden_data().get("inventory", []):
		if GardenSynthesisService.can_synthesize(
			int(item.get("type", Constants.TileType.RED_ROSE)),
			int(item.get("level", 1)),
			int(item.get("amount", 0))
		):
			return true
	return false
