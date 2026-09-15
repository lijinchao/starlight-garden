## CompanionService - 具名照料对象（方向 A-real / 迭代 O）
## 它有三个具体需要，会在局内提出请求；消除对应颜色才会喂到对应需要。
## 需要随真实时间缓慢下降，离开一段时间回来能看到“它在你不在时……”的观察。
extends Node

const COMPANION_DEFAULT_NAME := "小星"
const STAGE_NAMES: Array[String] = ["沉睡", "初醒", "亲近", "微光"]
const STAGE_SYMBOLS: Array[String] = ["🌙", "🌱", "🌸", "✨"]
const STAGE_THRESHOLDS: Array[int] = [0, 30, 90, 200]

const NEED_KEYS: Array[String] = ["light", "water", "company"]
const NEED_LABELS: Dictionary = {"light": "光", "water": "水", "company": "陪伴"}
const NEED_DEFAULT := 60
const NEED_FLOOR := 10
const NEED_CEIL := 100
const DECAY_PER_MINUTE := 1.0
const AWAY_REPORT_MIN_SECONDS := 300

var _pending_away_report: String = ""


func _ready() -> void:
	_pending_away_report = build_away_report_for()
	apply_offline_decay()


func get_companion_name() -> String:
	return str(SaveManager.get_companion_data().get("name", COMPANION_DEFAULT_NAME))


func get_affinity() -> int:
	return int(SaveManager.get_companion_data().get("affinity", 0))


func get_stage() -> int:
	var affinity = get_affinity()
	var stage = 0
	for index in range(STAGE_THRESHOLDS.size()):
		if affinity >= STAGE_THRESHOLDS[index]:
			stage = index
	return mini(stage, STAGE_NAMES.size() - 1)


func get_stage_name(stage: int = -1) -> String:
	var resolved = get_stage() if stage < 0 else stage
	return STAGE_NAMES[clampi(resolved, 0, STAGE_NAMES.size() - 1)]


func get_stage_symbol(stage: int = -1) -> String:
	var resolved = get_stage() if stage < 0 else stage
	return STAGE_SYMBOLS[clampi(resolved, 0, STAGE_SYMBOLS.size() - 1)]


func get_needs() -> Dictionary:
	var raw = SaveManager.get_companion_data().get("needs", {})
	var needs: Dictionary = {}
	for key in NEED_KEYS:
		var value = raw.get(key, NEED_DEFAULT) if raw is Dictionary else NEED_DEFAULT
		needs[key] = clampi(int(value), NEED_FLOOR, NEED_CEIL)
	return needs


func get_current_request() -> Dictionary:
	var needs = get_needs()
	var lowest_key = NEED_KEYS[0]
	for key in NEED_KEYS:
		if int(needs[key]) < int(needs[lowest_key]):
			lowest_key = key
	return {
		"key": lowest_key,
		"label": str(NEED_LABELS.get(lowest_key, "光")),
		"value": int(needs[lowest_key]),
		"text": _request_text(lowest_key)
	}


func get_progress_text() -> String:
	return "想要%s · 已收下 %d 份照料" % [str(get_current_request().get("label", "光")), get_affinity()]


func get_needs_text() -> String:
	var needs = get_needs()
	var parts: Array[String] = []
	for key in NEED_KEYS:
		parts.append("%s %d" % [str(NEED_LABELS.get(key, key)), int(needs[key])])
	return " · ".join(parts)


func feed_matches(type_counts: Dictionary, now_unix: int = 0) -> Dictionary:
	var needs = get_needs()
	var request_key = str(get_current_request().get("key", "light"))
	var gains: Dictionary = {}
	var total_gain = 0
	for raw_type in type_counts.keys():
		var count = int(type_counts[raw_type])
		if count <= 0:
			continue
		var need_key = _need_for_tile(int(raw_type))
		needs[need_key] = clampi(int(needs[need_key]) + count, NEED_FLOOR, NEED_CEIL)
		gains[need_key] = int(gains.get(need_key, 0)) + count
		total_gain += count
	if total_gain <= 0:
		return {}

	var data = SaveManager.get_companion_data()
	var before_stage = get_stage()
	data["affinity"] = int(data.get("affinity", 0)) + total_gain
	data["last_fed_total"] = int(data.get("last_fed_total", 0)) + total_gain
	data["needs"] = needs
	data["met"] = true
	data["last_seen_unix"] = _now(now_unix)
	SaveManager.update_companion_data(data)

	var after_stage = get_stage()
	var satisfied = int(gains.get(request_key, 0)) > 0
	return {
		"name": get_companion_name(),
		"gains": gains,
		"total_gain": total_gain,
		"request_key": request_key,
		"satisfied_request": satisfied,
		"needs": needs,
		"affinity": int(data.get("affinity", 0)),
		"stage": after_stage,
		"stage_changed": after_stage > before_stage,
		"reaction": _reaction(request_key, satisfied, after_stage, before_stage)
	}


func apply_offline_decay(now_unix: int = 0) -> Dictionary:
	var data = SaveManager.get_companion_data()
	var last_seen = int(data.get("last_seen_unix", 0))
	var now = _now(now_unix)
	if last_seen <= 0:
		data["last_seen_unix"] = now
		SaveManager.update_companion_data(data)
		return {}
	var elapsed = now - last_seen
	if elapsed <= 0:
		return {}

	var needs = get_needs()
	var decay = float(elapsed) / 60.0 * DECAY_PER_MINUTE
	var decayed: Dictionary = {}
	for key in NEED_KEYS:
		var before = int(needs[key])
		needs[key] = clampi(int(floor(float(before) - decay)), NEED_FLOOR, NEED_CEIL)
		decayed[key] = before - int(needs[key])
	data["needs"] = needs
	data["last_seen_unix"] = now
	SaveManager.update_companion_data(data)
	return {"elapsed_seconds": elapsed, "decayed": decayed}


func peek_away_report() -> String:
	return _pending_away_report


func consume_away_report() -> String:
	var report = _pending_away_report
	_pending_away_report = ""
	return report


func reset() -> void:
	var data = SaveManager.get_companion_data()
	data["affinity"] = 0
	data["last_fed_total"] = 0
	data["met"] = false
	data["needs"] = _default_needs()
	data["last_seen_unix"] = 0
	SaveManager.update_companion_data(data)
	_pending_away_report = ""


func _default_needs() -> Dictionary:
	var needs: Dictionary = {}
	for key in NEED_KEYS:
		needs[key] = NEED_DEFAULT
	return needs


func _need_for_tile(tile_type: int) -> String:
	if tile_type == Constants.TileType.YELLOW_SUNFLOWER or tile_type == Constants.TileType.PINK_CHERRY:
		return "light"
	if tile_type == Constants.TileType.BLUE_FORGET_ME_NOT or tile_type == Constants.TileType.WHITE_JASMINE:
		return "water"
	return "company"


func _request_text(need_key: String) -> String:
	if need_key == "water":
		return "%s有点渴，想要一点水。" % get_companion_name()
	if need_key == "company":
		return "%s想让你陪一会儿。" % get_companion_name()
	return "%s想要一点光。" % get_companion_name()


func _reaction(request_key: String, satisfied: bool, after_stage: int, before_stage: int) -> String:
	var companion_name = get_companion_name()
	if after_stage > before_stage:
		return "「%s」比之前更亮了，它认得你了。" % companion_name
	if satisfied:
		return "「%s」满足地安静下来。" % companion_name
	return "「%s」还在等它想要的那一样%s。" % [companion_name, str(NEED_LABELS.get(request_key, "光"))]


func build_away_report_for(now_unix: int = 0) -> String:
	var last_seen = int(SaveManager.get_companion_data().get("last_seen_unix", 0))
	if last_seen <= 0:
		return ""
	return _build_away_report_from_elapsed(_now(now_unix) - last_seen)


func _build_away_report_from_elapsed(elapsed: int) -> String:
	if elapsed < AWAY_REPORT_MIN_SECONDS:
		return ""
	var request = get_current_request()
	return "你不在的时候，「%s」一直惦记着%s。" % [get_companion_name(), str(request.get("label", "光"))]


func _now(now_unix: int = 0) -> int:
	if now_unix > 0:
		return now_unix
	return int(Time.get_unix_time_from_system())
