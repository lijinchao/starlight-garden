## TutorialSystem - 新手引导系统
class_name TutorialSystem
extends CanvasLayer

# ==================== 信号 ====================
signal tutorial_completed()
signal step_completed(step_id: int)

# ==================== 枚举 ====================
enum TutorialState {
	INACTIVE,
	RUNNING,
	PAUSED,
	COMPLETED
}

# ==================== 变量 ====================
var current_state: TutorialState = TutorialState.INACTIVE
var current_step: int = 0
var tutorial_steps: Array = []

# UI组件
var overlay: ColorRect
var dialog_panel: PanelContainer
var dialog_label: RichTextLabel
var next_btn: Button
var skip_btn: Button
var pointer: Control
var highlight_rect: Control
var pointer_tween: Tween

# ==================== 生命周期 ====================
func _ready() -> void:
	layer = 200  # 确保在最上层
	_create_ui()
	_load_tutorial_steps()


func _exit_tree() -> void:
	_cleanup_runtime_state()


func shutdown() -> void:
	_cleanup_runtime_state()


func _cleanup_runtime_state() -> void:
	if pointer_tween and is_instance_valid(pointer_tween):
		pointer_tween.kill()
		pointer_tween = null
	current_state = TutorialState.INACTIVE
	current_step = 0
	if overlay:
		overlay.visible = false
	if dialog_panel:
		dialog_panel.visible = false
	if pointer:
		pointer.visible = false
	_clear_highlight()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 半透明遮罩 - 默认不阻止输入
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不阻止鼠标输入
	overlay.visible = false
	add_child(overlay)
	
	# 高亮区域
	var highlight_panel = PanelContainer.new()
	highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_panel.visible = false
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 1, 1, 0.08)
	highlight_style.border_width_left = 4
	highlight_style.border_width_top = 4
	highlight_style.border_width_right = 4
	highlight_style.border_width_bottom = 4
	highlight_style.border_color = Color(1.0, 0.9, 0.4, 0.95)
	highlight_style.corner_radius_top_left = 16
	highlight_style.corner_radius_top_right = 16
	highlight_style.corner_radius_bottom_left = 16
	highlight_style.corner_radius_bottom_right = 16
	highlight_panel.add_theme_stylebox_override("panel", highlight_style)
	highlight_rect = highlight_panel
	add_child(highlight_rect)
	
	# 指示箭头
	pointer = _create_pointer()
	pointer.visible = false
	add_child(pointer)
	
	# 对话面板
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_panel.position = Vector2(-300, -250)
	dialog_panel.custom_minimum_size = Vector2(600, 200)
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # 接收输入
	dialog_panel.visible = false
	add_child(dialog_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	dialog_panel.add_child(vbox)
	
	# 对话文本
	dialog_label = RichTextLabel.new()
	dialog_label.bbcode_enabled = true
	dialog_label.custom_minimum_size = Vector2(580, 120)
	dialog_label.add_theme_font_size_override("normal_font_size", 22)
	vbox.add_child(dialog_label)
	
	# 按钮容器
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_END
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)
	
	# 跳过按钮
	skip_btn = Button.new()
	skip_btn.text = "跳过引导"
	skip_btn.custom_minimum_size = Vector2(120, 45)
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_btn.pressed.connect(_on_skip_pressed)
	btn_container.add_child(skip_btn)
	
	# 下一步按钮
	next_btn = Button.new()
	next_btn.text = "下一步 →"
	next_btn.custom_minimum_size = Vector2(120, 45)
	next_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	next_btn.pressed.connect(_on_next_pressed)
	btn_container.add_child(next_btn)

func _create_pointer() -> Control:
	var pointer_node = Control.new()
	pointer_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var arrow = Label.new()
	arrow.text = "👇"
	arrow.add_theme_font_size_override("font_size", 48)
	pointer_node.add_child(arrow)
	
	# 上下浮动动画
	pointer_tween = create_tween()
	pointer_tween.set_loops()
	pointer_tween.tween_property(arrow, "position:y", 10, 0.5)
	pointer_tween.tween_property(arrow, "position:y", 0, 0.5)
	
	return pointer_node

# ==================== 引导步骤 ====================
func _load_tutorial_steps() -> void:
	tutorial_steps = [
		{
			"id": 0,
			"type": "dialog",
			"title": "欢迎来到星光花园！",
			"text": "[center]🌸 欢迎来到星光花园！[/center]\n\n在这里，你可以通过消除花朵，\n收集星光，打造属于你的治愈花园。\n\n让我们开始吧！",
			"action": "none"
		},
		{
			"id": 1,
			"type": "dialog",
			"title": "游戏目标",
			"text": "[center]🎯 游戏目标[/center]\n\n每个关卡都有一个收集目标，\n比如收集指定数量的花朵。\n\n在顶部可以看到当前目标。",
			"action": "highlight_hud"
		},
		{
			"id": 2,
			"type": "dialog",
			"title": "消除玩法",
			"text": "[center]✨ 消除玩法[/center]\n\n交换相邻的花朵，\n让3个或以上相同花朵连成一线，\n即可消除它们！",
			"action": "none"
		},
		{
			"id": 3,
			"type": "action",
			"title": "试试看！",
			"text": "现在试试交换两个相邻的花朵，\n完成你的第一次消除！",
			"action": "wait_swap",
			"highlight": "board"
		},
		{
			"id": 4,
			"type": "dialog",
			"title": "太棒了！",
			"text": "[center]🎉 太棒了！[/center]\n\n你成功完成了第一次消除！\n\n消除的花朵会自动收集，\n记得关注顶部的目标进度哦。",
			"action": "none"
		},
		{
			"id": 5,
			"type": "dialog",
			"title": "步数限制",
			"text": "[center]👣 步数限制[/center]\n\n每关有固定的步数限制，\n步数用完前完成目标即可过关。\n\n步数显示在左上角。",
			"action": "highlight_moves"
		},
		{
			"id": 6,
			"type": "dialog",
			"title": "准备好了！",
			"text": "[center]🌟 准备好了！[/center]\n\n现在你已经了解了基本玩法，\n开始你的星光之旅吧！\n\n记住，即使失败也没关系，\n每一次尝试都是成长~",
			"action": "none"
		}
	]

# ==================== 引导流程 ====================
func start_tutorial() -> void:
	if TutorialManager.is_tutorial_completed():
		return
	
	current_state = TutorialState.RUNNING
	current_step = 0
	visible = true
	overlay.visible = true
	
	_show_step(current_step)

func _show_step(step_index: int) -> void:
	if step_index >= tutorial_steps.size():
		_complete_tutorial()
		return
	
	var step = tutorial_steps[step_index]
	
	# 执行步骤动作
	_execute_step_action(step)
	
	# 显示对话
	if step.get("type") == "dialog":
		_show_dialog(step)
	else:
		# 动作步骤，等待用户操作
		_show_action_hint(step)

func _execute_step_action(step: Dictionary) -> void:
	var action = step.get("action", "none")
	
	match action:
		"highlight_hud":
			_show_highlight(Rect2(60, 20, 630, 150))
		"highlight_moves":
			_show_highlight(Rect2(220, 20, 310, 60))
		"wait_swap":
			_clear_highlight()
		"none":
			_clear_highlight()

func _show_dialog(step: Dictionary) -> void:
	dialog_panel.visible = true
	pointer.visible = false
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 对话框时阻止背景输入
	
	var _title = step.get("title", "")  # 未使用，但保留以备将来使用
	var text = step.get("text", "")
	
	dialog_label.text = text
	
	# 更新按钮文本
	if current_step >= tutorial_steps.size() - 1:
		next_btn.text = "开始游戏！"
	else:
		next_btn.text = "下一步 →"

func _show_action_hint(step: Dictionary) -> void:
	dialog_panel.visible = false
	pointer.visible = false
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_highlight()
	
	# 显示指示箭头
	pointer.visible = true
	match step.get("highlight", ""):
		"board":
			pointer.set_anchors_preset(Control.PRESET_CENTER)
			pointer.position = Vector2(-24, 120)
		_:
			pointer.position = Vector2.ZERO

func _next_step() -> void:
	current_step += 1
	
	if current_step >= tutorial_steps.size():
		_complete_tutorial()
	else:
		_show_step(current_step)
	
	step_completed.emit(current_step - 1)

func _complete_tutorial() -> void:
	current_state = TutorialState.COMPLETED
	visible = false
	_clear_highlight()
	
	# 保存完成状态
	TutorialManager.mark_tutorial_completed()
	
	tutorial_completed.emit()

# ==================== 按钮回调 ====================
func _on_next_pressed() -> void:
	AudioManager.play_ui_click()
	_next_step()

func _on_skip_pressed() -> void:
	AudioManager.play_ui_click()

	pause_tutorial()
	
	PopupManager.show_confirm(
		"跳过引导",
		"确定要跳过新手引导吗？\n你可以在设置中重新查看。",
		func(): _complete_tutorial(),
		func(): resume_tutorial()
	)

# ==================== 公开方法 ====================
func pause_tutorial() -> void:
	if current_state == TutorialState.RUNNING:
		current_state = TutorialState.PAUSED
		visible = false

func resume_tutorial() -> void:
	if current_state == TutorialState.PAUSED:
		current_state = TutorialState.RUNNING
		visible = true
		if current_step < tutorial_steps.size():
			_show_step(current_step)

func is_running() -> bool:
	return current_state == TutorialState.RUNNING

func notify_action_completed(action: String) -> void:
	# 当用户完成某个引导动作时调用
	var current_step_data = tutorial_steps[current_step] if current_step < tutorial_steps.size() else {}
	if current_step_data.get("action") == action:
		_next_step()


func _show_highlight(target_rect: Rect2) -> void:
	highlight_rect.visible = true
	highlight_rect.position = target_rect.position
	highlight_rect.size = target_rect.size


func _clear_highlight() -> void:
	highlight_rect.visible = false
