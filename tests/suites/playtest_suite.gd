## Playtest suite
extends "res://tests/suites/test_suite.gd"


func test_playtest_recording() -> void:
	var path = "user://test_playtest_events.jsonl"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var recorder = PlaytestRecorderScript.new(path)
	recorder.enabled = true
	var first_write = recorder.record_event("level_started", {"level_id": 1})
	var second_write = recorder.record_event("breeze_awakened", {"level_id": 1})
	assert_true(first_write, "试玩事件可以写入本地 JSONL")
	assert_true(second_write, "试玩事件可以连续追加")
	assert_true(recorder.flush(), "试玩事件可以批量刷新到本地文件")

	var events = PlaytestRecorderScript.read_events(path)
	assert_equal(events.size(), 2, "试玩记录可逐行读取")
	if events.size() < 2:
		recorder.free()
		return
	assert_equal(events[0].get("event", ""), "level_started", "试玩记录包含事件名称")
	assert_equal(events[0].get("payload", {}).get("level_id", 0), 1, "试玩记录保留事件负载")
	assert_true(not str(events[0].get("session_id", "")).is_empty(), "试玩记录包含会话 ID")
	var expected_version = FileAccess.get_file_as_string("res://VERSION").strip_edges()
	assert_equal(events[0].get("version", ""), expected_version, "试玩记录包含当前版本")

	recorder.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_playtest_report() -> void:
	var events = [
		{"event": "session_started", "session_id": "s1", "sequence": 1, "timestamp_unix_ms": 1000},
		{"event": "level_started", "session_id": "s1", "sequence": 2, "timestamp_unix_ms": 1500},
		{"event": "first_interaction", "session_id": "s1", "sequence": 3, "timestamp_unix_ms": 2200},
		{"event": "garden_layer_cleared", "session_id": "s1", "sequence": 4, "timestamp_unix_ms": 3000, "payload": {"cleared_count": 2, "directional": false}},
		{"event": "garden_layer_cleared", "session_id": "s1", "sequence": 5, "timestamp_unix_ms": 3600, "payload": {"cleared_count": 3, "directional": true}},
		{"event": "dew_bud_triggered", "session_id": "s1", "sequence": 6, "timestamp_unix_ms": 4100, "payload": {"chain_index": 1, "extra_cleared": 3}},
		{"event": "dew_bud_triggered", "session_id": "s1", "sequence": 7, "timestamp_unix_ms": 4300, "payload": {"chain_index": 2, "extra_cleared": 2}},
		{"event": "daily_challenge_started", "session_id": "s1", "sequence": 8, "timestamp_unix_ms": 4500},
		{"event": "daily_challenge_settled", "session_id": "s1", "sequence": 9, "timestamp_unix_ms": 4700, "payload": {"outcome": "failure"}},
		{"event": "daily_challenge_retried", "session_id": "s1", "sequence": 10, "timestamp_unix_ms": 4800},
		{"event": "daily_challenge_settled", "session_id": "s1", "sequence": 11, "timestamp_unix_ms": 4900, "payload": {"outcome": "victory"}},
		{"event": "level_settled", "session_id": "s1", "sequence": 12, "timestamp_unix_ms": 5000, "payload": {"level_id": 1, "outcome": "failure"}},
		{"event": "level_settled", "session_id": "s1", "sequence": 13, "timestamp_unix_ms": 7000, "payload": {"level_id": 1, "outcome": "victory"}},
		{"event": "garden_viewed", "session_id": "s1", "sequence": 14, "timestamp_unix_ms": 7500},
		{"event": "level_started", "session_id": "s1", "sequence": 15, "timestamp_unix_ms": 8000}
	]
	var summary = PlaytestReportScript.build_summary(events)
	assert_equal(summary.get("victory_count", 0), 1, "试玩报告单独统计胜利结算")
	assert_equal(summary.get("failure_count", 0), 1, "试玩报告单独统计失败结算")
	assert_equal(summary.get("completed_levels", {}).get(1, 0), 1, "失败不会计入胜利通关分布")
	assert_equal(summary.get("first_interaction_median_ms", -1), 700, "试玩报告从关卡开始计算首次操作耗时")
	assert_equal(summary.get("garden_after_settlement", {}).get("matched", 0), 1, "试玩报告计算结算后花园转化")
	assert_equal(summary.get("garden_after_settlement", {}).get("total", 0), 2, "花园转化包含胜利与失败结算分母")
	assert_equal(summary.get("restart_after_garden", {}).get("matched", 0), 1, "试玩报告计算花园后再次开局")
	assert_equal(summary.get("garden_layer_clear_count", 0), 2, "试玩报告统计扫叶触发次数")
	assert_equal(summary.get("garden_layers_cleared", 0), 5, "试玩报告累计扫开的落叶数量")
	assert_equal(summary.get("directional_clear_count", 0), 1, "试玩报告区分方向清风扫叶")
	assert_equal(summary.get("dew_bud_triggered_count", 0), 2, "试玩报告统计晨露花苞触发次数")
	assert_equal(summary.get("dew_bud_extra_cleared", 0), 5, "试玩报告累计晨露额外扫叶数量")
	assert_equal(summary.get("max_dew_chain", 0), 2, "试玩报告统计最大晨露连锁")
	assert_equal(summary.get("daily_challenge_started_count", 0), 1, "试玩报告统计每日风庭开局")
	assert_equal(summary.get("daily_challenge_failure_count", 0), 1, "试玩报告统计每日风庭失败")
	assert_equal(summary.get("daily_challenge_victory_count", 0), 1, "试玩报告统计每日风庭胜利")
	assert_equal(summary.get("daily_challenge_retry_count", 0), 1, "试玩报告统计每日风庭重试")
