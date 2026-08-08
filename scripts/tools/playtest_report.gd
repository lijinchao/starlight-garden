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

	var counts: Dictionary = {}
	var sessions: Dictionary = {}
	var completed_levels: Dictionary = {}
	for item in events:
		var event_name = str(item.get("event", "unknown"))
		counts[event_name] = int(counts.get(event_name, 0)) + 1
		sessions[str(item.get("session_id", "unknown"))] = true
		if event_name == "level_settled":
			var payload = item.get("payload", {})
			var level_id = int(payload.get("level_id", 0))
			completed_levels[level_id] = int(completed_levels.get(level_id, 0)) + 1

	print("\n星光花园试玩记录")
	print("日志: %s" % ProjectSettings.globalize_path(path))
	print("会话: %d" % sessions.size())
	print("事件: %d" % events.size())
	for event_name in counts.keys():
		print("  %s: %d" % [event_name, counts[event_name]])
	if not completed_levels.is_empty():
		print("完成关卡分布:")
		for level_id in completed_levels.keys():
			print("  Level %d: %d" % [level_id, completed_levels[level_id]])
	quit(0)
