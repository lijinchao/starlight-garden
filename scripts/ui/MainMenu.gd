## MainMenu - 主菜单界面
class_name MainMenu
extends Control

const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")

# ==================== 信号 ====================
signal start_game()
signal open_settings()
signal open_garden()
signal open_flower_journal()
signal open_daily_gift()

# ==================== 节点引用 ====================
var title_label: Label
var start_btn: Button
var garden_btn: Button
var flower_journal_btn: Button
var daily_gift_btn: Button
var settings_btn: Button
var level_label: Label
var restoration_label: Label
var restoration_hint_label: Label
var restoration_preview_label: Label
var restoration_goal_label: Label
var restoration_focus_label: Label
var restoration_scene_strip: HBoxContainer
var background_rect: TextureRect
var background_tint: ColorRect
var stage_strip: HBoxContainer
var decoration_petals: Array[Label] = []
var decoration_tweens: Array[Tween] = []
var active_tweens: Array[Tween] = []

const META_UNLOCK_RUNS: int = 3

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_ui()
	_connect_signals()
	_update_display()


func _exit_tree() -> void:
	for tween in decoration_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	decoration_tweens.clear()
	active_tweens.clear()
	decoration_petals.clear()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 设置全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	background_tint = ColorRect.new()
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_tint.color = Color(0.99, 0.96, 0.98, 0.34)
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_tint)
	
	# 装饰性背景元素
	_create_decorations()
	
	# 主容器 - 使用PRESET_CENTER_WIDE并设置偏移
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(350, 500)
	main_container.add_theme_constant_override("separation", 30)
	add_child(main_container)
	
	# 标题
	title_label = Label.new()
	title_label.text = "🌸 星光花园 🌸"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	main_container.add_child(title_label)
	
	# 副标题
	var subtitle = Label.new()
	subtitle.text = "治愈你的碎片时光"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.modulate = Color(0.6, 0.5, 0.7)
	main_container.add_child(subtitle)
	
	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	main_container.add_child(spacer1)
	
	# 开始游戏按钮
	start_btn = Button.new()
	start_btn.text = "✨ 开始游戏"
	start_btn.custom_minimum_size = Vector2(300, 70)
	start_btn.add_theme_font_size_override("font_size", 28)
	main_container.add_child(start_btn)
	
	# 花园按钮
	garden_btn = Button.new()
	garden_btn.text = "🌿 我的花园"
	garden_btn.custom_minimum_size = Vector2(300, 60)
	garden_btn.add_theme_font_size_override("font_size", 24)
	main_container.add_child(garden_btn)

	# 花语日记按钮
	flower_journal_btn = Button.new()
	flower_journal_btn.text = "📖 花语日记"
	flower_journal_btn.custom_minimum_size = Vector2(300, 60)
	flower_journal_btn.add_theme_font_size_override("font_size", 24)
	main_container.add_child(flower_journal_btn)

	# 今日花礼按钮
	daily_gift_btn = Button.new()
	daily_gift_btn.text = "🌤 今日花礼"
	daily_gift_btn.custom_minimum_size = Vector2(300, 60)
	daily_gift_btn.add_theme_font_size_override("font_size", 24)
	main_container.add_child(daily_gift_btn)
	
	# 当前关卡显示
	level_label = Label.new()
	level_label.text = "当前关卡: 1"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	main_container.add_child(level_label)

	restoration_label = Label.new()
	restoration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_label.add_theme_font_size_override("font_size", 22)
	main_container.add_child(restoration_label)

	restoration_hint_label = Label.new()
	restoration_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_hint_label.add_theme_font_size_override("font_size", 18)
	restoration_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_hint_label.custom_minimum_size = Vector2(320, 52)
	main_container.add_child(restoration_hint_label)

	restoration_preview_label = Label.new()
	restoration_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_preview_label.add_theme_font_size_override("font_size", 34)
	main_container.add_child(restoration_preview_label)

	restoration_focus_label = Label.new()
	restoration_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_focus_label.add_theme_font_size_override("font_size", 18)
	restoration_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_focus_label.custom_minimum_size = Vector2(320, 40)
	main_container.add_child(restoration_focus_label)

	restoration_scene_strip = HBoxContainer.new()
	restoration_scene_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	restoration_scene_strip.add_theme_constant_override("separation", 12)
	main_container.add_child(restoration_scene_strip)

	restoration_goal_label = Label.new()
	restoration_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_goal_label.add_theme_font_size_override("font_size", 16)
	restoration_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_goal_label.custom_minimum_size = Vector2(320, 44)
	main_container.add_child(restoration_goal_label)

	stage_strip = HBoxContainer.new()
	stage_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_strip.add_theme_constant_override("separation", 14)
	main_container.add_child(stage_strip)
	
	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	main_container.add_child(spacer2)
	
	# 设置按钮
	settings_btn = Button.new()
	settings_btn.text = "⚙️ 设置"
	settings_btn.custom_minimum_size = Vector2(200, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	main_container.add_child(settings_btn)

# 创建装饰元素
func _create_decorations() -> void:
	# 飘落花瓣效果（简单实现）
	for i in range(10):
		var petal = Label.new()
		petal.text = ["🌸", "🌺", "✨", "💫"].pick_random()
		petal.add_theme_font_size_override("font_size", randi_range(20, 40))
		petal.position = Vector2(randf_range(0, 750), randf_range(0, 1334))
		petal.modulate.a = 0.5
		add_child(petal)
		decoration_petals.append(petal)
		
		# 飘落动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(petal, "position:y", 1400, randf_range(5, 10))
		tween.tween_callback(func(): petal.position.y = -50)
		decoration_tweens.append(tween)

# ==================== 信号连接 ====================
func _connect_signals() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	garden_btn.pressed.connect(_on_garden_pressed)
	flower_journal_btn.pressed.connect(_on_flower_journal_pressed)
	daily_gift_btn.pressed.connect(_on_daily_gift_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

# ==================== 数据更新 ====================
func _update_display() -> void:
	var player_data = SaveManager.get_player_data()
	level_label.text = "当前关卡: %d" % player_data.get("level", 1)
	flower_journal_btn.visible = is_flower_journal_unlocked()
	daily_gift_btn.visible = is_daily_gift_unlocked()
	_update_restoration_display()


func _update_restoration_display() -> void:
	var restoration = SaveManager.get_restoration_state()
	var stage = int(restoration.get("stage", 0))
	var total_runs = int(SaveManager.get_player_data().get("total_runs", 0))
	title_label.text = "%s 星光花园 %s" % [restoration.get("icon", "🌸"), restoration.get("icon", "🌸")]
	restoration_label.text = "花园恢复：%s" % restoration.get("name", "沉睡角")
	restoration_hint_label.text = str(restoration.get("description", ""))
	restoration_preview_label.text = str(restoration.get("preview", "🌸"))
	restoration_focus_label.text = "现在最明显的是：%s" % str(restoration.get("focus_title", "左侧空盆"))
	restoration_goal_label.text = str(restoration.get("next_goal", ""))
	start_btn.text = "✨ 开始修复" if total_runs < META_UNLOCK_RUNS else "✨ 开始游戏"
	garden_btn.text = "🌿 看看花园" if total_runs < META_UNLOCK_RUNS else "🌿 我的花园"
	if background_rect:
		background_rect.texture = VisualAssetCatalogScript.get_garden_background(stage)
	if background_tint:
		background_tint.color = Color(_get_stage_color(stage), 0.34)
	_render_restoration_scene(stage)
	_render_stage_strip(stage)


func _render_restoration_scene(current_stage: int) -> void:
	if not restoration_scene_strip:
		return
	for child in restoration_scene_strip.get_children():
		child.queue_free()

	var scene_icons = _get_scene_icons(current_stage)
	for i in range(scene_icons.size()):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(86, 86)
		card.self_modulate = _get_scene_card_color(current_stage, i)

		var label = Label.new()
		label.text = "%s\n%s" % [scene_icons[i], _get_scene_caption(current_stage, i)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		card.add_child(label)

		restoration_scene_strip.add_child(card)


func _get_scene_icons(stage: int) -> Array[String]:
	match stage:
		0:
			return ["🍂", "🪴", "🌙"]
		1:
			return ["🌱", "🪴", "✨"]
		2:
			return ["🌿", "🌸", "✨"]
		_:
			return ["🌸", "✨", "🏡"]


func _get_scene_caption(stage: int, index: int) -> String:
	var captions = {
		0: ["沉睡", "空盆", "待亮"],
		1: ["新芽", "守着", "起光"],
		2: ["舒展", "花开", "变暖"],
		3: ["盛开", "点亮", "可停留"]
	}
	return str(captions.get(stage, captions[3])[index])


func _get_scene_card_color(stage: int, index: int) -> Color:
	var active_color = _get_stage_color(stage)
	return active_color.lightened(0.04 * float(index))


func _render_stage_strip(current_stage: int) -> void:
	if not stage_strip:
		return
	for child in stage_strip.get_children():
		child.queue_free()

	var stages = [
		{"icon": "🌙", "name": "沉睡"},
		{"icon": "🌱", "name": "发芽"},
		{"icon": "🌸", "name": "初绽"},
		{"icon": "✨", "name": "微光"}
	]
	for stage_data in stages:
		var stage_index = stages.find(stage_data)
		var chip = VBoxContainer.new()
		chip.custom_minimum_size = Vector2(68, 54)

		var icon_label = Label.new()
		icon_label.text = stage_data.get("icon", "🌸")
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 28)
		icon_label.modulate = Color(1, 1, 1, 1) if stage_index <= current_stage else Color(0.62, 0.62, 0.68, 1)
		chip.add_child(icon_label)

		var name_label = Label.new()
		name_label.text = stage_data.get("name", "")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.modulate = Color(0.25, 0.25, 0.32) if stage_index <= current_stage else Color(0.55, 0.55, 0.6)
		chip.add_child(name_label)

		stage_strip.add_child(chip)


func _get_stage_color(stage: int) -> Color:
	match stage:
		0:
			return Color(0.96, 0.94, 0.98, 1)
		1:
			return Color(0.93, 0.97, 0.92, 1)
		2:
			return Color(0.99, 0.95, 0.90, 1)
		_:
			return Color(0.95, 0.97, 1.0, 1)

# ==================== 按钮回调 ====================
func _on_start_pressed() -> void:
	# 播放点击音效
	AudioManager.play_ui_click()
	
	# 发射开始游戏信号
	start_game.emit()

func _on_garden_pressed() -> void:
	AudioManager.play_ui_click()
	open_garden.emit()

func _on_flower_journal_pressed() -> void:
	AudioManager.play_ui_click()
	open_flower_journal.emit()

func _on_daily_gift_pressed() -> void:
	AudioManager.play_ui_click()
	open_daily_gift.emit()

func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	open_settings.emit()

# ==================== 公开方法 ====================
func show_menu() -> void:
	visible = true
	_update_display()
	
	# 显示动画
	modulate.a = 0
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.finished.connect(_remove_tween.bind(tween))

func hide_menu() -> void:
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	tween.finished.connect(_remove_tween.bind(tween))


func _remove_tween(tween: Tween) -> void:
	var index = active_tweens.find(tween)
	if index >= 0:
		active_tweens.remove_at(index)


func is_flower_journal_unlocked() -> bool:
	if int(SaveManager.get_player_data().get("total_runs", 0)) < META_UNLOCK_RUNS:
		return false
	var flower_language = SaveManager.get_flower_language_data()
	if not flower_language.get("unlocked", []).is_empty():
		return true

	var fragments = flower_language.get("fragments", {})
	for key in fragments.keys():
		if int(fragments[key]) > 0:
			return true
	return false


func is_daily_gift_unlocked() -> bool:
	return int(SaveManager.get_player_data().get("total_runs", 0)) >= META_UNLOCK_RUNS
