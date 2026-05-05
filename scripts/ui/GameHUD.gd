## GameHUD - 游戏界面HUD
class_name GameHUD
extends Control

# ==================== 信号 ====================
signal pause_pressed()
signal hint_pressed()

# ==================== 节点引用 ====================
var moves_container: HBoxContainer
var moves_label: Label
var score_container: HBoxContainer
var score_label: Label
var target_container: VBoxContainer
var target_title: Label
var target_list: VBoxContainer
var combo_label: Label
var pause_btn: Button
var hint_btn: Button

# ==================== 变量 ====================
var current_moves: int = 0
var current_score: int = 0
var combo_count: int = 0

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_ui()
	_connect_signals()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 顶部容器
	var top_container = VBoxContainer.new()
	top_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_container.position = Vector2(0, 20)
	add_child(top_container)
	
	# 第一行：步数和分数
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 20)
	top_container.add_child(row1)
	
	# 暂停按钮
	pause_btn = Button.new()
	pause_btn.text = "⏸️"
	pause_btn.custom_minimum_size = Vector2(60, 60)
	pause_btn.add_theme_font_size_override("font_size", 24)
	row1.add_child(pause_btn)
	
	# 步数容器
	moves_container = HBoxContainer.new()
	moves_container.add_theme_constant_override("separation", 10)
	row1.add_child(moves_container)
	
	var moves_icon = Label.new()
	moves_icon.text = "👣"
	moves_icon.add_theme_font_size_override("font_size", 28)
	moves_container.add_child(moves_icon)
	
	moves_label = Label.new()
	moves_label.text = "30"
	moves_label.add_theme_font_size_override("font_size", 32)
	moves_container.add_child(moves_label)
	
	# 分数容器
	score_container = HBoxContainer.new()
	score_container.add_theme_constant_override("separation", 10)
	row1.add_child(score_container)
	
	var score_icon = Label.new()
	score_icon.text = "⭐"
	score_icon.add_theme_font_size_override("font_size", 28)
	score_container.add_child(score_icon)
	
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 32)
	score_container.add_child(score_label)
	
	# 提示按钮
	hint_btn = Button.new()
	hint_btn.text = "💡"
	hint_btn.custom_minimum_size = Vector2(60, 60)
	hint_btn.add_theme_font_size_override("font_size", 24)
	row1.add_child(hint_btn)
	
	# 第二行：目标
	var row2 = MarginContainer.new()
	row2.add_theme_constant_override("margin_left", 30)
	row2.add_theme_constant_override("margin_right", 30)
	top_container.add_child(row2)
	
	target_container = VBoxContainer.new()
	target_container.add_theme_constant_override("separation", 5)
	row2.add_child(target_container)
	
	target_title = Label.new()
	target_title.text = "🎯 目标"
	target_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_title.add_theme_font_size_override("font_size", 20)
	target_container.add_child(target_title)
	
	target_list = VBoxContainer.new()
	target_list.add_theme_constant_override("separation", 3)
	target_container.add_child(target_list)
	
	# 连击显示（居中）
	combo_label = Label.new()
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.position = Vector2(-100, -300)
	combo_label.custom_minimum_size = Vector2(200, 100)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 48)
	combo_label.modulate = Color(1, 0.8, 0, 0)  # 初始透明
	add_child(combo_label)

# ==================== 信号连接 ====================
func _connect_signals() -> void:
	pause_btn.pressed.connect(_on_pause_pressed)
	hint_btn.pressed.connect(_on_hint_pressed)

# ==================== 数据更新 ====================
func update_moves(moves: int) -> void:
	current_moves = moves
	moves_label.text = str(moves)
	
	# 步数不足时变红
	if moves <= 5:
		moves_label.modulate = Color(1, 0.3, 0.3)
	else:
		moves_label.modulate = Color.WHITE
	
	# 步数减少动画
	var tween = create_tween()
	tween.tween_property(moves_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(moves_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_score(score: int) -> void:
	current_score = score
	score_label.text = str(score)
	
	# 分数增加动画
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.15)

func update_target(requirements: Array, collected: Dictionary) -> void:
	# 清空目标列表
	for child in target_list.get_children():
		child.queue_free()
	
	# 添加目标
	for req in requirements:
		var tile_type = req["tile_type"]
		var required = req["count"]
		var current = collected.get(str(tile_type), 0)
		var tile_name = Constants.TILE_NAMES.get(tile_type, "Unknown")
		
		var target_item = HBoxContainer.new()
		target_item.add_theme_constant_override("separation", 10)
		
		# 元素图标（用颜色代替）
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.color = Constants.TILE_COLORS.get(tile_type, Color.WHITE)
		target_item.add_child(icon)
		
		# 进度文本
		var progress = Label.new()
		progress.text = "%s: %d/%d" % [tile_name, current, required]
		progress.add_theme_font_size_override("font_size", 18)
		
		# 完成时变绿
		if current >= required:
			progress.modulate = Color(0.2, 0.8, 0.2)
		
		target_item.add_child(progress)
		target_list.add_child(target_item)

func show_combo(count: int) -> void:
	if count < 2:
		return
	
	combo_count = count
	var texts = ["", "", "Good!", "Great!", "Amazing!", "Fantastic!", "Incredible!"]
	var text = texts[mini(count, texts.size() - 1)]
	
	combo_label.text = "x%d %s" % [count, text]
	
	# 显示动画
	var tween = create_tween()
	tween.tween_property(combo_label, "modulate:a", 1.0, 0.1)
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_interval(0.5)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.3)

# ==================== 按钮回调 ====================
func _on_pause_pressed() -> void:
	AudioManager.play_ui_click()
	pause_pressed.emit()

func _on_hint_pressed() -> void:
	AudioManager.play_ui_click()
	hint_pressed.emit()

# ==================== 公开方法 ====================
func show_hud() -> void:
	visible = true
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_hud() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

func reset() -> void:
	update_moves(0)
	update_score(0)
	combo_count = 0
