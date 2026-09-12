## DailyGiftUI - 今日花礼界面
class_name DailyGiftUI
extends Control

signal back_pressed()
signal action_requested(action: String, level_id: int)

var back_btn: Button
var date_label: Label
var task_list: VBoxContainer
var gift_label: Label
var claim_btn: Button
var challenge_label: Label
var challenge_btn: Button
var next_action: Dictionary = {}


func _ready() -> void:
	_create_ui()
	_connect_signals()
	_update_display()


func _create_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.97, 0.94, 0.88, 1)
	add_child(bg)

	var top_bar = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(20, 20)
	add_child(top_bar)

	back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(120, 50)
	back_btn.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(back_btn)

	var title = Label.new()
	title.text = "🌤 今日花礼"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.25, 0.20, 0.14))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(120, 50)
	top_bar.add_child(spacer)

	var content = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.custom_minimum_size = Vector2(620, 620)
	content.position = Vector2(-310, -310)
	content.add_theme_constant_override("separation", 18)
	add_child(content)

	challenge_label = Label.new()
	challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge_label.add_theme_font_size_override("font_size", 18)
	challenge_label.add_theme_color_override("font_color", Color(0.18, 0.38, 0.3))
	content.add_child(challenge_label)

	challenge_btn = Button.new()
	challenge_btn.custom_minimum_size = Vector2(300, 56)
	challenge_btn.add_theme_font_size_override("font_size", 21)
	content.add_child(challenge_btn)

	date_label = Label.new()
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 20)
	date_label.modulate = Color(0.45, 0.35, 0.25)
	content.add_child(date_label)

	var subtitle = Label.new()
	subtitle.text = "完成今日小目标，领取一份温柔奖励。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.42, 0.34, 0.24))
	content.add_child(subtitle)

	task_list = VBoxContainer.new()
	task_list.add_theme_constant_override("separation", 10)
	content.add_child(task_list)

	gift_label = Label.new()
	gift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gift_label.add_theme_font_size_override("font_size", 18)
	gift_label.add_theme_color_override("font_color", Color(0.38, 0.30, 0.20))
	content.add_child(gift_label)

	claim_btn = Button.new()
	claim_btn.custom_minimum_size = Vector2(300, 60)
	claim_btn.add_theme_font_size_override("font_size", 22)
	content.add_child(claim_btn)


func _connect_signals() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	claim_btn.pressed.connect(_on_claim_pressed)
	challenge_btn.pressed.connect(_on_challenge_pressed)


func _update_display() -> void:
	var data = DailyService.get_display_data()
	date_label.text = "今日：%s" % data.get("date", "")
	var challenge = DailyChallengeService.get_today_challenge().get("challenge", {})
	var progress = DailyChallengeService.get_today_progress()
	var direction = "横向" if str(challenge.get("preferred_direction", "horizontal")) == "horizontal" else "纵向"
	challenge_label.text = "今日风庭 · %s · 推荐%s四连\n%s" % [
		str(challenge.get("layout_name", "晨露花庭")),
		direction,
		"最佳连锁 x%d · 已尝试 %d 次" % [int(progress.get("best_chain", 0)), int(progress.get("attempts", 0))]
	]
	challenge_btn.text = "再试一次今日风庭" if bool(progress.get("completed", false)) else "开始今日风庭"

	for child in task_list.get_children():
		child.queue_free()

	for task in data.get("tasks", []):
		task_list.add_child(_create_task_row(task))

	var seed_name = Constants.TILE_NAMES.get(int(data.get("gift_seed_type", Constants.TileType.RED_ROSE)), "花种")
	gift_label.text = "今日花礼：%d ✨ + %s 花种 x%d" % [
		int(data.get("gift_stars", 0)),
		seed_name,
		int(data.get("gift_seed_count", 0))
	]

	if data.get("gift_claimed", false):
		claim_btn.text = "今日已领取"
		claim_btn.disabled = true
	elif data.get("can_claim", false):
		claim_btn.text = "领取今日花礼"
		claim_btn.disabled = false
	else:
		next_action = _get_next_action(data.get("tasks", []))
		claim_btn.text = str(next_action.get("label", "继续完成今日目标"))
		claim_btn.disabled = false


func _get_next_action(tasks: Array) -> Dictionary:
	for task in tasks:
		if task.get("completed", false):
			continue
		var task_id = str(task.get("id", ""))
		if task_id == DailyService.TASK_HARVEST_FLOWER:
			var garden = SaveManager.get_garden_data()
			var has_planted_flower = false
			for slot in garden.get("slots", []):
				if slot is Dictionary and not slot.is_empty():
					has_planted_flower = true
					break
			if has_planted_flower or not garden.get("inventory", []).is_empty():
				return {"action": "garden", "label": "去花园完成一次收获"}
		var level_id = int(SaveManager.get_player_data().get("level", 1))
		return {"action": "start", "level_id": level_id, "label": "去完成第 %d 关" % level_id}
	return {"action": "start", "level_id": int(SaveManager.get_player_data().get("level", 1)), "label": "继续完成今日目标"}


func _create_task_row(task: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 72)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var check = Label.new()
	check.text = "✓" if task.get("completed", false) else "·"
	check.add_theme_font_size_override("font_size", 24)
	row.add_child(check)

	var title = Label.new()
	title.text = "%s  %d/%d" % [
		task.get("title", ""),
		int(task.get("progress", 0)),
		int(task.get("target", 1))
	]
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	return panel


func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	back_pressed.emit()


func _on_claim_pressed() -> void:
	AudioManager.play_ui_click()
	if not DailyService.can_claim_gift():
		action_requested.emit(
			str(next_action.get("action", "start")),
			int(next_action.get("level_id", SaveManager.get_player_data().get("level", 1)))
		)
		return
	var result = DailyService.claim_gift()
	if result.get("success", false):
		var seed_name = Constants.TILE_NAMES.get(int(result.get("seed_type", Constants.TileType.RED_ROSE)), "花种")
		PopupManager.show_toast("领取今日花礼：%d ✨ + %s x%d" % [
			int(result.get("stars", 0)),
			seed_name,
			int(result.get("seed_count", 0))
		])
	else:
		PopupManager.show_toast("今日花礼暂不可领取")
	_update_display()


func _on_challenge_pressed() -> void:
	AudioManager.play_ui_click()
	action_requested.emit("daily_challenge", 0)


func show_daily_gift() -> void:
	visible = true
	_update_display()
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_daily_gift() -> void:
	if not visible:
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
