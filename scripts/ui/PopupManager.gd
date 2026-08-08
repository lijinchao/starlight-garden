## PopupManager - 弹窗管理器（自动加载单例）
extends CanvasLayer

const META_UNLOCK_RUNS: int = 3

# ==================== 信号 ====================
signal popup_closed(popup_name: String)

# ==================== 变量 ====================
var active_popups: Dictionary = {}
var popup_stack: Array = []
var popup_actions: Dictionary = {}

# 弹窗场景预加载
var popup_scenes: Dictionary = {}

# ==================== 生命周期 ====================
func _ready() -> void:
	layer = 100  # 确保在最上层
	_register_popups()


func _exit_tree() -> void:
	close_all_popups()
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# 注册弹窗场景
func _register_popups() -> void:
	# 将在运行时创建弹窗
	pass

# ==================== 弹窗显示 ====================
# 显示胜利弹窗
func show_victory(settlement: Dictionary, on_next_level: Callable = Callable(), on_double_reward: Callable = Callable()) -> void:
	close_popup("victory")
	popup_actions["victory"] = {
		"next": on_next_level,
		"double": on_double_reward
	}
	var popup = _create_victory_popup(settlement)
	_show_popup("victory", popup)

# 显示失败弹窗
func show_failure(settlement: Dictionary, on_continue: Callable = Callable(), on_rest: Callable = Callable()) -> void:
	close_popup("failure")
	popup_actions["failure"] = {
		"continue": on_continue,
		"rest": on_rest
	}
	var popup = _create_failure_popup(settlement)
	_show_popup("failure", popup)

# 显示暂停弹窗
func show_pause() -> void:
	var popup = _create_pause_popup()
	_show_popup("pause", popup)

# 显示确认弹窗
func show_confirm(title: String, message: String, on_confirm: Callable, on_cancel: Callable = Callable()) -> void:
	var popup = _create_confirm_popup(title, message, on_confirm, on_cancel)
	_show_popup("confirm", popup)

# 显示提示弹窗
func show_toast(message: String, duration: float = 2.0) -> void:
	var toast = _create_toast(message)
	add_child(toast)

	# 用 tween 串联展示与淡出，避免遗留 SceneTreeTimer 到退出阶段。
	toast.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(toast.queue_free)

# 关闭弹窗
func close_popup(popup_name: String) -> void:
	if active_popups.has(popup_name):
		var popup = active_popups[popup_name]
		if is_instance_valid(popup):
			popup.queue_free()
		active_popups.erase(popup_name)
		popup_actions.erase(popup_name)
		popup_closed.emit(popup_name)

# 关闭所有弹窗
func close_all_popups() -> void:
	for popup_name in active_popups.keys():
		close_popup(popup_name)

# ==================== 弹窗创建 ====================
# 创建胜利弹窗
func _create_victory_popup(settlement: Dictionary) -> Control:
	var stars = int(settlement.get("stars_earned", 1))
	var score = int(settlement.get("score", 0))
	var level = int(settlement.get("level_id", 1))
	var reward_lines = SettlementService.format_primary_rewards_summary(settlement)
	var early_focus = int(settlement.get("player_total_runs_after", SaveManager.get_player_data().get("total_runs", 0))) <= META_UNLOCK_RUNS

	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景遮罩
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	popup.add_child(bg)
	
	# 弹窗面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.position = Vector2(-250, -200)
	
	# 内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "🎉 恭喜过关！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)
	
	# 星星
	var stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var star = Label.new()
		star.text = "⭐" if i < stars else "☆"
		star.add_theme_font_size_override("font_size", 48)
		stars_container.add_child(star)
	vbox.add_child(stars_container)
	
	# 分数
	var score_label = Label.new()
	score_label.text = "得分: %d" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(score_label)
	
	# 关卡
	var level_label = Label.new()
	level_label.text = "第 %d 关" % level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(level_label)

	var reward_label = Label.new()
	reward_label.text = "\n".join(reward_lines)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(reward_label)
	
	# 按钮容器
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)
	
	# 下一关按钮
	var next_btn = Button.new()
	next_btn.text = "回花园看看" if early_focus else "下一关"
	next_btn.custom_minimum_size = Vector2(120, 50)
	next_btn.pressed.connect(_on_next_level_pressed)
	btn_container.add_child(next_btn)
	
	if popup_actions.get("victory", {}).get("double", Callable()).is_valid():
		var double_btn = Button.new()
		double_btn.text = "双倍奖励"
		double_btn.custom_minimum_size = Vector2(120, 50)
		double_btn.pressed.connect(_on_double_reward_pressed)
		btn_container.add_child(double_btn)
	
	popup.add_child(panel)
	return popup

# 创建失败弹窗
func _create_failure_popup(settlement: Dictionary) -> Control:
	var moves_used = int(settlement.get("moves_used", 0))
	var continue_cost = int(settlement.get("continue_cost", 0))
	var reward_lines = SettlementService.format_primary_rewards_summary(settlement)
	var early_focus = int(settlement.get("player_total_runs_after", SaveManager.get_player_data().get("total_runs", 0))) <= META_UNLOCK_RUNS

	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景遮罩
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	popup.add_child(bg)
	
	# 弹窗面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 350)
	panel.position = Vector2(-250, -175)
	
	# 内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "💫 星星也需要休息"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	# 治愈语录
	var quote = Label.new()
	quote.text = "别担心，每一次尝试都是成长~\n明天继续闪耀吧！"
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 18)
	vbox.add_child(quote)
	
	# 提示
	var hint = Label.new()
	hint.text = "使用了 %d 步" % moves_used
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	vbox.add_child(hint)

	var reward_label = Label.new()
	reward_label.text = "\n".join(reward_lines)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(reward_label)

	if continue_cost > 0 and not early_focus:
		var continue_hint = Label.new()
		continue_hint.text = "消耗 %d ✨ 可继续获得 5 步" % continue_cost
		continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		continue_hint.add_theme_font_size_override("font_size", 16)
		vbox.add_child(continue_hint)
	
	# 按钮容器
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)
	
	# 休息一下按钮
	var rest_btn = Button.new()
	rest_btn.text = "回花园看看" if early_focus else "休息一下"
	rest_btn.custom_minimum_size = Vector2(120, 50)
	rest_btn.pressed.connect(_on_rest_pressed)
	btn_container.add_child(rest_btn)
	
	if not early_focus:
		var continue_btn = Button.new()
		continue_btn.text = "继续挑战" if continue_cost > 0 else "继续挑战 📺"
		continue_btn.custom_minimum_size = Vector2(120, 50)
		continue_btn.pressed.connect(_on_continue_pressed)
		btn_container.add_child(continue_btn)
	
	popup.add_child(panel)
	return popup

# 创建暂停弹窗
func _create_pause_popup() -> Control:
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景遮罩
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	popup.add_child(bg)
	
	# 弹窗面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 300)
	panel.position = Vector2(-200, -150)
	
	# 内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "⏸️ 暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	# 按钮
	var resume_btn = Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.custom_minimum_size = Vector2(200, 50)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	
	var restart_btn = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "返回菜单"
	menu_btn.custom_minimum_size = Vector2(200, 50)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)
	
	popup.add_child(panel)
	return popup

# 创建确认弹窗
func _create_confirm_popup(title: String, message: String, on_confirm: Callable, on_cancel: Callable) -> Control:
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景遮罩
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	popup.add_child(bg)
	
	# 弹窗面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 250)
	panel.position = Vector2(-200, -125)
	
	# 内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# 标题
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	
	# 消息
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(msg_label)
	
	# 按钮容器
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)
	
	# 取消按钮
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	if on_cancel.is_valid():
		cancel_btn.pressed.connect(on_cancel)
	cancel_btn.pressed.connect(func(): close_popup("confirm"))
	btn_container.add_child(cancel_btn)
	
	# 确认按钮
	var confirm_btn = Button.new()
	confirm_btn.text = "确认"
	confirm_btn.custom_minimum_size = Vector2(100, 45)
	confirm_btn.pressed.connect(on_confirm)
	confirm_btn.pressed.connect(func(): close_popup("confirm"))
	btn_container.add_child(confirm_btn)
	
	popup.add_child(panel)
	return popup

# 创建提示
func _create_toast(message: String) -> Control:
	var toast = PanelContainer.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-150, 100)
	toast.custom_minimum_size = Vector2(300, 60)
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	toast.add_child(label)
	
	return toast

# ==================== 显示逻辑 ====================
func _show_popup(popup_name: String, popup: Control) -> void:
	# 如果同名弹窗已存在，先关闭
	if active_popups.has(popup_name):
		close_popup(popup_name)
	
	active_popups[popup_name] = popup
	popup_stack.append(popup_name)
	add_child(popup)
	
	# 弹出动画
	popup.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.2)

# ==================== 按钮回调 ====================
func _on_next_level_pressed() -> void:
	var actions = popup_actions.get("victory", {})
	var on_next_level = actions.get("next", Callable())
	close_popup("victory")
	if on_next_level.is_valid():
		on_next_level.call()

func _on_double_reward_pressed() -> void:
	var actions = popup_actions.get("victory", {})
	var on_double_reward = actions.get("double", Callable())
	close_popup("victory")
	if on_double_reward.is_valid():
		on_double_reward.call()

func _on_rest_pressed() -> void:
	var actions = popup_actions.get("failure", {})
	var on_rest = actions.get("rest", Callable())
	close_popup("failure")
	if on_rest.is_valid():
		on_rest.call()
	else:
		GameManager.go_to_menu()

func _on_continue_pressed() -> void:
	var actions = popup_actions.get("failure", {})
	var on_continue = actions.get("continue", Callable())
	if on_continue.is_valid():
		on_continue.call()
		return

func _on_resume_pressed() -> void:
	close_popup("pause")
	GameManager.resume_game()

func _on_restart_pressed() -> void:
	close_popup("pause")
	GameManager.start_level(GameManager.current_level)

func _on_menu_pressed() -> void:
	close_popup("pause")
	GameManager.go_to_menu()
