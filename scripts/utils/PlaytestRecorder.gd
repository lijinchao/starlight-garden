## PlaytestRecorder - 本地试玩事件记录器，不联网、不写入正式存档
class_name PlaytestRecorder
extends Node

const DEFAULT_LOG_PATH := "user://playtest/events.jsonl"

var log_path: String
var session_id: String
var sequence: int = 0
var enabled: bool = true


func _init(path_override: String = "") -> void:
	log_path = path_override if not path_override.is_empty() else DEFAULT_LOG_PATH
	session_id = "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec()]


func _ready() -> void:
	record_event("session_started", {
		"version": ProjectSettings.get_setting("application/config/version", "unknown")
	})


func record_event(event_name: String, payload: Dictionary = {}) -> bool:
	if not enabled or event_name.is_empty():
		return false

	var directory = log_path.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))

	var mode = FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE_READ
	var file = FileAccess.open(log_path, mode)
	if file == null:
		push_warning("无法写入试玩记录: %s" % log_path)
		return false

	file.seek_end()
	sequence += 1
	file.store_line(JSON.stringify({
		"event": event_name,
		"payload": payload,
		"sequence": sequence,
		"session_id": session_id,
		"timestamp_unix_ms": int(Time.get_unix_time_from_system() * 1000.0),
		"version": ProjectSettings.get_setting("application/config/version", "unknown")
	}))
	file.close()
	return true


static func read_events(path: String = DEFAULT_LOG_PATH) -> Array:
	var events: Array = []
	if not FileAccess.file_exists(path):
		return events

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return events

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if parsed is Dictionary:
			events.append(parsed)
	file.close()
	return events
