## MainMenu - 主菜单界面
class_name MainMenu
extends Control

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

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_ui()
	_connect_signals()
	_update_display()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 设置全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	
	# 背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.98, 0.95, 0.98, 1)  # 淡粉色
	add_child(bg)
	
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
		
		# 飘落动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(petal, "position:y", 1400, randf_range(5, 10))
		tween.tween_callback(func(): petal.position.y = -50)

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
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_menu() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
