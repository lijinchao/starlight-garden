## PlaytestRecorder - 本地试玩事件记录器，不联网、不写入正式存档
class_name PlaytestRecorder
extends Node

const DEFAULT_LOG_PATH := "user://playtest/events.jsonl"
const MAX_LOG_BYTES: int = 1024 * 1024
const MAX_PENDING_EVENTS: int = 16
const FLUSH_INTERVAL_SECONDS: float = 1.0

var log_path: String
var session_id: String
var sequence: int = 0
var enabled: bool
var pending_lines: Array[String] = []
var flush_elapsed: float = 0.0


func _init(path_override: String = "") -> void:
	log_path = path_override if not path_override.is_empty() else DEFAULT_LOG_PATH
	session_id = "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	enabled = _is_playtest_environment()


func _ready() -> void:
	set_process(enabled)
	record_event("session_started", {
		"version": ProjectSettings.get_setting("application/config/version", "unknown")
	})


func _process(delta: float) -> void:
	if not enabled or pending_lines.is_empty():
		return
	flush_elapsed += delta
	if flush_elapsed >= FLUSH_INTERVAL_SECONDS:
		flush()


func _exit_tree() -> void:
	flush()


func record_event(event_name: String, payload: Dictionary = {}) -> bool:
	if not enabled or event_name.is_empty():
		return false

	sequence += 1
	pending_lines.append(JSON.stringify({
		"event": event_name,
		"payload": payload,
		"sequence": sequence,
		"session_id": session_id,
		"timestamp_unix_ms": int(Time.get_unix_time_from_system() * 1000.0),
		"version": ProjectSettings.get_setting("application/config/version", "unknown")
	}))
	if pending_lines.size() >= MAX_PENDING_EVENTS:
		return flush()
	return true


func flush() -> bool:
	if pending_lines.is_empty():
		return true

	var directory = log_path.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))

	_rotate_if_needed()
	var mode = FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE_READ
	var file = FileAccess.open(log_path, mode)
	if file == null:
		push_warning("无法写入试玩记录: %s" % log_path)
		return false

	file.seek_end()
	file.store_string("\n".join(pending_lines) + "\n")
	file.close()
	pending_lines.clear()
	flush_elapsed = 0.0
	return true


func _rotate_if_needed() -> void:
	if not FileAccess.file_exists(log_path):
		return
	var file = FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return
	var current_size = file.get_length()
	file.close()
	if current_size < MAX_LOG_BYTES:
		return

	var absolute_path = ProjectSettings.globalize_path(log_path)
	var backup_path = absolute_path + ".1"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	DirAccess.rename_absolute(absolute_path, backup_path)


static func _is_playtest_environment() -> bool:
	if OS.has_feature("editor"):
		return true
	for argument in OS.get_cmdline_user_args():
		if argument == "--playtest-recording":
			return true
	return false


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
