## SettingsUI - 设置界面
class_name SettingsUI
extends Control

# ==================== 信号 ====================
signal back_pressed()

# ==================== 节点引用 ====================
var back_btn: Button
var bgm_slider: HSlider
var sfx_slider: HSlider
var reset_btn: Button
var tutorial_btn: Button
var transition_tween: Tween

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_ui()
	_connect_signals()
	_load_settings()


func _exit_tree() -> void:
	_stop_transition()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.95, 0.95, 0.98, 1)
	add_child(bg)
	
	# 顶部栏
	var top_bar = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(20, 20)
	add_child(top_bar)
	
	back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(120, 50)
	top_bar.add_child(back_btn)
	
	var title = Label.new()
	title.text = "⚙️ 设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	
	# 设置内容
	var content = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.position = Vector2(-200, -200)
	content.custom_minimum_size = Vector2(400, 400)
	content.add_theme_constant_override("separation", 30)
	add_child(content)
	
	# BGM音量
	var bgm_container = _create_slider_setting("🎵 背景音乐", "bgm")
	bgm_slider = bgm_container.get_node("Slider")
	content.add_child(bgm_container)
	
	# SFX音量
	var sfx_container = _create_slider_setting("🔊 音效", "sfx")
	sfx_slider = sfx_container.get_node("Slider")
	content.add_child(sfx_container)
	
	# 间距
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	content.add_child(spacer)
	
	# 重新引导按钮
	tutorial_btn = Button.new()
	tutorial_btn.text = "📖 重新查看新手引导"
	tutorial_btn.custom_minimum_size = Vector2(300, 50)
	tutorial_btn.add_theme_font_size_override("font_size", 18)
	content.add_child(tutorial_btn)
	
	# 重置存档按钮
	reset_btn = Button.new()
	reset_btn.text = "🗑️ 重置游戏数据"
	reset_btn.custom_minimum_size = Vector2(300, 50)
	reset_btn.add_theme_font_size_override("font_size", 18)
	reset_btn.modulate = Color(1, 0.5, 0.5)
	content.add_child(reset_btn)

func _create_slider_setting(label_text: String, setting_name: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.name = setting_name.capitalize()
	container.add_theme_constant_override("separation", 20)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 40)
	label.add_theme_font_size_override("font_size", 20)
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 50
	slider.custom_minimum_size = Vector2(200, 40)
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "50%"
	value_label.custom_minimum_size = Vector2(60, 40)
	value_label.add_theme_font_size_override("font_size", 18)
	container.add_child(value_label)
	
	# 连接信号
	slider.value_changed.connect(_on_slider_changed.bind(value_label, setting_name))
	
	return container

# ==================== 信号连接 ====================
func _connect_signals() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)

# ==================== 数据加载 ====================
func _load_settings() -> void:
	var settings = SaveManager.get_settings()
	
	bgm_slider.value = settings.get("bgm_volume", 0.35) * 100
	sfx_slider.value = settings.get("sfx_volume", 0.7) * 100

func _on_slider_changed(value: float, value_label: Label, setting_name: String) -> void:
	value_label.text = "%d%%" % int(value)
	
	# 保存设置
	var settings = SaveManager.get_settings()
	settings[setting_name + "_volume"] = value / 100.0
	SaveManager.update_settings(settings)
	
	# 应用设置
	match setting_name:
		"bgm":
			AudioManager.set_bgm_volume(value / 100.0)
		"sfx":
			AudioManager.set_sfx_volume(value / 100.0)

# ==================== 按钮回调 ====================
func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	back_pressed.emit()

func _on_tutorial_pressed() -> void:
	AudioManager.play_ui_click()
	TutorialManager.reset_tutorial()
	PopupManager.show_toast("新手引导已重置，下次进入关卡时将重新显示")

func _on_reset_pressed() -> void:
	AudioManager.play_ui_click()
	PopupManager.show_confirm(
		"重置游戏数据",
		"确定要重置所有游戏数据吗？\n此操作不可撤销！",
		func():
			SaveManager.reset_save()
			PopupManager.show_toast("游戏数据已重置")
			_load_settings(),
		Callable()
	)

# ==================== 公开方法 ====================
func show_settings() -> void:
	_stop_transition()
	visible = true
	_load_settings()
	modulate.a = 0
	transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_settings() -> void:
	_stop_transition()
	if not visible:
		return
	transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	transition_tween.tween_callback(_finish_hide)


func _finish_hide() -> void:
	visible = false
	transition_tween = null


func _stop_transition() -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	transition_tween = null
