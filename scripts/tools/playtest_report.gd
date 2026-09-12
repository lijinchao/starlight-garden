## 输出本机试玩事件摘要
extends SceneTree

const PlaytestRecorderScript = preload("res://scripts/utils/PlaytestRecorder.gd")


func _init() -> void:
	var path = PlaytestRecorderScript.DEFAULT_LOG_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--log="):
			path = argument.trim_prefix("--log=")

	var events = PlaytestRecorderScript.read_events(path)
	if events.is_empty():
		print("没有找到试玩事件: %s" % ProjectSettings.globalize_path(path))
		quit(1)
		return

	var summary = build_summary(events)
	var counts: Dictionary = summary.get("counts", {})
	var completed_levels: Dictionary = summary.get("completed_levels", {})

	print("\n星光花园试玩记录")
	print("日志: %s" % ProjectSettings.globalize_path(path))
	print("会话: %d" % int(summary.get("session_count", 0)))
	print("事件: %d" % events.size())
	for event_name in counts.keys():
		print("  %s: %d" % [event_name, counts[event_name]])
	print("胜利结算: %d" % int(summary.get("victory_count", 0)))
	print("失败结算: %d" % int(summary.get("failure_count", 0)))
	print("扫叶触发: %d（方向清风 %d）" % [
		int(summary.get("garden_layer_clear_count", 0)),
		int(summary.get("directional_clear_count", 0))
	])
	print("累计扫开落叶: %d" % int(summary.get("garden_layers_cleared", 0)))
	print("晨露花苞: 触发 %d，最大连锁 %d，额外扫叶 %d" % [
		int(summary.get("dew_bud_triggered_count", 0)),
		int(summary.get("max_dew_chain", 0)),
		int(summary.get("dew_bud_extra_cleared", 0))
	])
	print("今日风庭: 开始 %d，胜利 %d，失败 %d，重试 %d" % [
		int(summary.get("daily_challenge_started_count", 0)),
		int(summary.get("daily_challenge_victory_count", 0)),
		int(summary.get("daily_challenge_failure_count", 0)),
		int(summary.get("daily_challenge_retry_count", 0))
	])
	_print_duration("首次操作中位耗时", int(summary.get("first_interaction_median_ms", -1)))
	_print_duration("单次结算中位耗时", int(summary.get("level_settlement_median_ms", -1)))
	print("结算后进入花园: %s" % _format_rate(summary.get("garden_after_settlement", {})))
	print("花园后再次开局: %s" % _format_rate(summary.get("restart_after_garden", {})))
	if not completed_levels.is_empty():
		print("胜利通关分布:")
		for level_id in completed_levels.keys():
			print("  Level %d: %d" % [level_id, completed_levels[level_id]])
	quit(0)


static func build_summary(events: Array) -> Dictionary:
	var counts: Dictionary = {}
	var sessions: Dictionary = {}
	var completed_levels: Dictionary = {}
	var victory_count = 0
	var failure_count = 0
	var garden_layer_clear_count = 0
	var directional_clear_count = 0
	var garden_layers_cleared = 0
	var dew_bud_triggered_count = 0
	var dew_bud_extra_cleared = 0
	var max_dew_chain = 0
	var daily_challenge_started_count = 0
	var daily_challenge_victory_count = 0
	var daily_challenge_failure_count = 0
	var daily_challenge_retry_count = 0

	for item in events:
		var event_name = str(item.get("event", "unknown"))
		counts[event_name] = int(counts.get(event_name, 0)) + 1
		var session_id = str(item.get("session_id", "unknown"))
		if not sessions.has(session_id):
			sessions[session_id] = []
		sessions[session_id].append(item)

		if event_name == "garden_layer_cleared":
			garden_layer_clear_count += 1
			var clear_payload = item.get("payload", {})
			garden_layers_cleared += int(clear_payload.get("cleared_count", 0))
			if bool(clear_payload.get("directional", false)):
				directional_clear_count += 1
		elif event_name == "dew_bud_triggered":
			var dew_payload = item.get("payload", {})
			dew_bud_triggered_count += 1
			dew_bud_extra_cleared += int(dew_payload.get("extra_cleared", 0))
			max_dew_chain = maxi(max_dew_chain, int(dew_payload.get("chain_index", 1)))
		elif event_name == "daily_challenge_started":
			daily_challenge_started_count += 1
		elif event_name == "daily_challenge_retried":
			daily_challenge_retry_count += 1
		elif event_name == "daily_challenge_settled":
			var daily_payload = item.get("payload", {})
			if str(daily_payload.get("outcome", "")) == "victory":
				daily_challenge_victory_count += 1
			elif str(daily_payload.get("outcome", "")) == "failure":
				daily_challenge_failure_count += 1

		if event_name != "level_settled":
			continue
		var payload = item.get("payload", {})
		var outcome = str(payload.get("outcome", "unknown"))
		if outcome == "victory":
			victory_count += 1
			var level_id = int(payload.get("level_id", 0))
			completed_levels[level_id] = int(completed_levels.get(level_id, 0)) + 1
		elif outcome == "failure":
			failure_count += 1

	var first_interaction_durations: Array[int] = []
	var settlement_durations: Array[int] = []
	var garden_after_settlement = {"matched": 0, "total": 0}
	var restart_after_garden = {"matched": 0, "total": 0}

	for session_events in sessions.values():
		session_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
		)
		_collect_session_metrics(
			session_events,
			first_interaction_durations,
			settlement_durations,
			garden_after_settlement,
			restart_after_garden
		)

	return {
		"completed_levels": completed_levels,
		"counts": counts,
		"failure_count": failure_count,
		"garden_layer_clear_count": garden_layer_clear_count,
		"garden_layers_cleared": garden_layers_cleared,
		"directional_clear_count": directional_clear_count,
		"dew_bud_triggered_count": dew_bud_triggered_count,
		"dew_bud_extra_cleared": dew_bud_extra_cleared,
		"max_dew_chain": max_dew_chain,
		"daily_challenge_started_count": daily_challenge_started_count,
		"daily_challenge_victory_count": daily_challenge_victory_count,
		"daily_challenge_failure_count": daily_challenge_failure_count,
		"daily_challenge_retry_count": daily_challenge_retry_count,
		"first_interaction_median_ms": _median(first_interaction_durations),
		"garden_after_settlement": garden_after_settlement,
		"level_settlement_median_ms": _median(settlement_durations),
		"restart_after_garden": restart_after_garden,
		"session_count": sessions.size(),
		"victory_count": victory_count
	}


static func _collect_session_metrics(
	session_events: Array,
	first_interaction_durations: Array[int],
	settlement_durations: Array[int],
	garden_after_settlement: Dictionary,
	restart_after_garden: Dictionary
) -> void:
	var session_started_at = -1
	var level_started_at = -1
	var first_interaction_recorded = false

	for index in range(session_events.size()):
		var item: Dictionary = session_events[index]
		var event_name = str(item.get("event", "unknown"))
		var timestamp = int(item.get("timestamp_unix_ms", -1))
		match event_name:
			"session_started":
				if session_started_at < 0:
					session_started_at = timestamp
			"level_started":
				level_started_at = timestamp
			"first_interaction":
				if not first_interaction_recorded:
					var origin = level_started_at if level_started_at >= 0 else session_started_at
					if origin >= 0 and timestamp >= origin:
						first_interaction_durations.append(timestamp - origin)
					first_interaction_recorded = true
			"level_settled":
				if level_started_at >= 0 and timestamp >= level_started_at:
					settlement_durations.append(timestamp - level_started_at)
				garden_after_settlement["total"] = int(garden_after_settlement["total"]) + 1
				if _has_event_before_any(session_events, index, "garden_viewed", ["level_started", "level_settled"]):
					garden_after_settlement["matched"] = int(garden_after_settlement["matched"]) + 1
			"garden_viewed":
				restart_after_garden["total"] = int(restart_after_garden["total"]) + 1
				if _has_event_before_any(session_events, index, "level_started", ["garden_viewed"]):
					restart_after_garden["matched"] = int(restart_after_garden["matched"]) + 1


static func _has_event_before_any(events: Array, start_index: int, target: String, stops: Array) -> bool:
	for index in range(start_index + 1, events.size()):
		var event_name = str(events[index].get("event", "unknown"))
		if event_name == target:
			return true
		if stops.has(event_name):
			return false
	return false


static func _median(values: Array[int]) -> int:
	if values.is_empty():
		return -1
	var sorted_values = values.duplicate()
	sorted_values.sort()
	var middle = sorted_values.size() / 2
	if sorted_values.size() % 2 == 1:
		return int(sorted_values[middle])
	return int(round((int(sorted_values[middle - 1]) + int(sorted_values[middle])) / 2.0))


static func _print_duration(label: String, duration_ms: int) -> void:
	if duration_ms < 0:
		print("%s: 暂无数据" % label)
		return
	print("%s: %.2f 秒" % [label, duration_ms / 1000.0])


static func _format_rate(rate: Dictionary) -> String:
	var matched = int(rate.get("matched", 0))
	var total = int(rate.get("total", 0))
	if total <= 0:
		return "暂无数据"
	return "%d/%d (%.1f%%)" % [matched, total, matched * 100.0 / total]
