## FlowerLanguageUI - 花语日记界面
class_name FlowerLanguageUI
extends Control

signal back_pressed()

var back_btn: Button
var entries_list: VBoxContainer


func _ready() -> void:
	_create_ui()
	_connect_signals()
	_update_entries()


func _create_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.96, 0.93, 0.98, 1)
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
	title.text = "📖 花语日记"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(120, 50)
	top_bar.add_child(spacer)

	var subtitle = Label.new()
	subtitle.text = "收集碎片，解锁属于每朵花的治愈话语"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(0.45, 0.38, 0.55)
	subtitle.position = Vector2(0, 95)
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(subtitle)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_top = 150
	scroll.offset_right = -40
	scroll.offset_bottom = -40
	add_child(scroll)

	entries_list = VBoxContainer.new()
	entries_list.add_theme_constant_override("separation", 14)
	scroll.add_child(entries_list)


func _connect_signals() -> void:
	back_btn.pressed.connect(_on_back_pressed)


func _update_entries() -> void:
	if entries_list == null:
		return

	for child in entries_list.get_children():
		child.queue_free()

	for entry in FlowerLanguageService.get_journal_entries():
		entries_list.add_child(_create_entry_card(entry))


func _create_entry_card(entry: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 110)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "%s  %s" % [
		_get_flower_icon(int(entry.get("flower_type", Constants.TileType.RED_ROSE))),
		entry.get("name", "花朵")
	]
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var progress = Label.new()
	progress.text = "碎片进度：%d/%d" % [
		int(entry.get("fragments", 0)),
		int(entry.get("required_fragments", FlowerLanguageService.FRAGMENTS_TO_UNLOCK))
	]
	progress.add_theme_font_size_override("font_size", 16)
	vbox.add_child(progress)

	var language = Label.new()
	if entry.get("unlocked", false):
		language.text = "花语：%s" % entry.get("language", "")
		language.modulate = Color(0.35, 0.25, 0.45)
	else:
		language.text = "继续收集碎片，解锁这朵花的心意。"
		language.modulate = Color(0.55, 0.55, 0.60)
	language.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	language.add_theme_font_size_override("font_size", 17)
	vbox.add_child(language)

	return panel


func _get_flower_icon(flower_type: int) -> String:
	match flower_type:
		Constants.TileType.RED_ROSE:
			return "🌹"
		Constants.TileType.BLUE_FORGET_ME_NOT:
			return "💙"
		Constants.TileType.PURPLE_LAVENDER:
			return "💜"
		Constants.TileType.YELLOW_SUNFLOWER:
			return "🌻"
		Constants.TileType.WHITE_JASMINE:
			return "🤍"
		Constants.TileType.PINK_CHERRY:
			return "🌸"
		_:
			return "🌼"


func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	back_pressed.emit()


func show_journal() -> void:
	visible = true
	_update_entries()
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_journal() -> void:
	if not visible:
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
