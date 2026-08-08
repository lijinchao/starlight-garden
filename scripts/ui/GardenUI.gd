## GardenUI - 花园界面
class_name GardenUI
extends Control

const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")

# ==================== 信号 ====================
signal back_pressed()
signal flower_planted(slot: int, flower_type: int)
signal flower_synthesized(flower_type: int, from_level: int, to_level: int)

# ==================== 节点引用 ====================
var back_btn: Button
var garden_grid: GridContainer
var flower_slots: Array = []
var selected_slot: int = -1
var inventory_container: VBoxContainer
var star_count_label: Label
var inventory_list: VBoxContainer
var decoration_container: VBoxContainer
var decoration_list: VBoxContainer
var atmosphere_label: Label
var restoration_label: Label
var restoration_hint_label: Label
var restoration_preview_label: Label
var restoration_goal_label: Label
var restoration_focus_label: Label
var restoration_badges: HBoxContainer
var background_rect: TextureRect
var background_tint: ColorRect
var arrival_overlay: PanelContainer
var arrival_title_label: Label
var arrival_detail_label: Label
var arrival_preview_label: Label
var last_arrival_message: String = ""
var last_arrival_detail: String = ""
var highlighted_restoration_slot: int = -1
var active_tweens: Array[Tween] = []

const META_UNLOCK_RUNS: int = 3

# ==================== 变量 ====================
var garden_data: Dictionary = {
	"slots": [],
	"inventory": [],
	"decorations": []
}

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_ui()
	_connect_signals()
	_load_garden_data()


func _exit_tree() -> void:
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 背景
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	background_tint = ColorRect.new()
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_tint.color = Color(0.92, 0.96, 0.92, 0.28)
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_tint)
	
	# 顶部栏
	var top_bar = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(20, 20)
	add_child(top_bar)
	
	# 返回按钮
	back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(120, 50)
	back_btn.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(back_btn)
	
	# 标题
	var title = Label.new()
	title.text = "🌿 我的花园"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	
	# 星光数量
	var star_container = HBoxContainer.new()
	top_bar.add_child(star_container)
	
	var star_icon = Label.new()
	star_icon.text = "✨"
	star_icon.add_theme_font_size_override("font_size", 28)
	star_container.add_child(star_icon)
	
	star_count_label = Label.new()
	star_count_label.text = "0"
	star_count_label.add_theme_font_size_override("font_size", 24)
	star_container.add_child(star_count_label)
	
	# 花园网格
	garden_grid = GridContainer.new()
	garden_grid.columns = 2
	garden_grid.set_anchors_preset(Control.PRESET_CENTER)
	garden_grid.position = Vector2(-200, -200)
	garden_grid.add_theme_constant_override("h_separation", 20)
	garden_grid.add_theme_constant_override("v_separation", 20)
	add_child(garden_grid)
	
	# 创建花盆位
	for i in range(4):
		var slot = _create_flower_slot(i)
		garden_grid.add_child(slot)
		flower_slots.append(slot)

	# 装饰容器
	decoration_container = VBoxContainer.new()
	decoration_container.position = Vector2(470, 150)
	decoration_container.custom_minimum_size = Vector2(250, 360)
	decoration_container.add_theme_constant_override("separation", 10)
	add_child(decoration_container)

	var decoration_title = Label.new()
	decoration_title.text = "🏡 花园恢复"
	decoration_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decoration_title.add_theme_font_size_override("font_size", 22)
	decoration_container.add_child(decoration_title)

	restoration_label = Label.new()
	restoration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_label.add_theme_font_size_override("font_size", 20)
	decoration_container.add_child(restoration_label)

	restoration_hint_label = Label.new()
	restoration_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_hint_label.custom_minimum_size = Vector2(220, 54)
	restoration_hint_label.add_theme_font_size_override("font_size", 16)
	decoration_container.add_child(restoration_hint_label)

	restoration_preview_label = Label.new()
	restoration_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_preview_label.add_theme_font_size_override("font_size", 30)
	decoration_container.add_child(restoration_preview_label)

	restoration_focus_label = Label.new()
	restoration_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_focus_label.custom_minimum_size = Vector2(220, 44)
	restoration_focus_label.add_theme_font_size_override("font_size", 16)
	decoration_container.add_child(restoration_focus_label)

	restoration_goal_label = Label.new()
	restoration_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_goal_label.custom_minimum_size = Vector2(220, 48)
	restoration_goal_label.add_theme_font_size_override("font_size", 15)
	decoration_container.add_child(restoration_goal_label)

	restoration_badges = HBoxContainer.new()
	restoration_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	restoration_badges.add_theme_constant_override("separation", 10)
	decoration_container.add_child(restoration_badges)

	atmosphere_label = Label.new()
	atmosphere_label.text = "氛围值 0"
	atmosphere_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atmosphere_label.add_theme_font_size_override("font_size", 18)
	decoration_container.add_child(atmosphere_label)

	decoration_list = VBoxContainer.new()
	decoration_list.add_theme_constant_override("separation", 8)
	decoration_container.add_child(decoration_list)
	
	# 背包容器
	inventory_container = VBoxContainer.new()
	inventory_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	inventory_container.position = Vector2(0, -200)
	add_child(inventory_container)
	
	var inventory_title = Label.new()
	inventory_title.text = "🎒 背包"
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title.add_theme_font_size_override("font_size", 24)
	inventory_container.add_child(inventory_title)

	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 8)
	inventory_container.add_child(inventory_list)

	arrival_overlay = PanelContainer.new()
	arrival_overlay.set_anchors_preset(Control.PRESET_CENTER)
	arrival_overlay.custom_minimum_size = Vector2(320, 180)
	arrival_overlay.position = Vector2(-160, -90)
	arrival_overlay.visible = false
	arrival_overlay.modulate = Color(1, 1, 1, 0)
	add_child(arrival_overlay)

	var overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 10)
	arrival_overlay.add_child(overlay_box)

	arrival_title_label = Label.new()
	arrival_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrival_title_label.add_theme_font_size_override("font_size", 24)
	overlay_box.add_child(arrival_title_label)

	arrival_preview_label = Label.new()
	arrival_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrival_preview_label.add_theme_font_size_override("font_size", 38)
	overlay_box.add_child(arrival_preview_label)

	arrival_detail_label = Label.new()
	arrival_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrival_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arrival_detail_label.custom_minimum_size = Vector2(280, 50)
	arrival_detail_label.add_theme_font_size_override("font_size", 16)
	overlay_box.add_child(arrival_detail_label)

# 创建花盆位
func _create_flower_slot(index: int) -> Control:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(180, 180)
	slot.name = "Slot%d" % index
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	slot.add_child(vbox)
	
	# 花盆图标
	var pot = Label.new()
	pot.text = "🪴"
	pot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot.add_theme_font_size_override("font_size", 64)
	pot.name = "PotIcon"
	vbox.add_child(pot)
	
	# 状态文本
	var status = Label.new()
	status.text = "空闲"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 16)
	status.name = "StatusLabel"
	vbox.add_child(status)
	
	# 点击区域
	slot.gui_input.connect(_on_slot_input.bind(index))
	
	return slot

# ==================== 信号连接 ====================
func _connect_signals() -> void:
	back_btn.pressed.connect(_on_back_pressed)

# ==================== 数据加载 ====================
func _load_garden_data() -> void:
	garden_data = SaveManager.get_garden_data()
	_refresh_growth_states()
	_update_garden_display()

func _update_garden_display() -> void:
	# 更新星光数量
	var player_data = SaveManager.get_player_data()
	star_count_label.text = str(player_data.get("stars", 0))
	var restoration = SaveManager.get_restoration_state()
	highlighted_restoration_slot = int(restoration.get("focus_slot", -1))
	
	# 更新花盆位
	var slots = garden_data.get("slots", [])
	for i in range(flower_slots.size()):
		var slot = flower_slots[i]
		var slot_data = slots[i] if i < slots.size() else {}
		_update_slot_display(slot, slot_data, i)

	_update_inventory_display()
	_update_decoration_display()

func _update_slot_display(slot: Control, data: Dictionary, _index: int) -> void:
	# 获取VBoxContainer中的节点
	var vbox = slot.get_child(0)  # VBoxContainer是第一个子节点
	if not vbox:
		return
	
	var pot_icon = vbox.get_node_or_null("PotIcon")
	var status_label = vbox.get_node_or_null("StatusLabel")
	
	if not pot_icon or not status_label:
		return
	
	if data.is_empty():
		var empty_visual = _get_empty_slot_visual(_index)
		pot_icon.text = str(empty_visual.get("icon", "🪴"))
		status_label.text = str(empty_visual.get("label", "空闲"))
		status_label.modulate = empty_visual.get("color", Color.GRAY)
		slot.self_modulate = _get_slot_modulate(_index)
	else:
		var flower_type = data.get("type", 1)
		var flower_level = data.get("level", 1)
		var growth = data.get("growth", 0.0)
		
		# 根据等级显示不同花朵
		var flower_icons = ["🌱", "🌿", "🌸", "🌺", "💐"]
		pot_icon.text = flower_icons[mini(flower_level - 1, 4)]
		
		# 状态文本
		if growth >= 1.0:
			status_label.text = "可收获"
			status_label.modulate = Color(0.2, 0.8, 0.2)
		else:
			status_label.text = "成长中 %d%%" % int(growth * 100)
			status_label.modulate = Color(0.8, 0.6, 0.2)
		slot.self_modulate = Color(1, 1, 1, 1)


func _get_empty_slot_visual(slot_index: int) -> Dictionary:
	var stage = int(SaveManager.get_restoration_state().get("stage", 0))
	match stage:
		0:
			return {
				"icon": "🍂",
				"label": "静待唤醒",
				"color": Color(0.5, 0.5, 0.5)
			}
		1:
			if slot_index == 0:
				return {
					"icon": "🌱",
					"label": "第一簇新芽",
					"color": Color(0.25, 0.65, 0.3)
				}
			return {
				"icon": "🪴",
				"label": "等下一束微光",
				"color": Color(0.45, 0.5, 0.45)
			}
		2:
			if slot_index == 0:
				return {
					"icon": "🌿",
					"label": "花叶舒展",
					"color": Color(0.2, 0.65, 0.3)
				}
			if slot_index == 1:
				return {
					"icon": "🌸",
					"label": "第一朵花",
					"color": Color(0.85, 0.4, 0.65)
				}
			return {
				"icon": "🪴",
				"label": "角落将继续开花",
				"color": Color(0.45, 0.55, 0.45)
			}
		_:
			return {
				"icon": "✨",
				"label": "微光已落下",
				"color": Color(0.75, 0.65, 0.2)
			}


func _update_inventory_display() -> void:
	if not inventory_list:
		return

	for child in inventory_list.get_children():
		child.queue_free()

	var inventory = garden_data.get("inventory", [])
	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无花种，先去闯关收集吧"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		inventory_list.add_child(empty_label)
		return

	for item in inventory:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)

		var flower_type = item.get("type", Constants.TileType.RED_ROSE)
		var level = item.get("level", 1)
		var amount = item.get("amount", 0)
		var label = Label.new()
		label.text = "%s Lv.%d x%d" % [
			Constants.TILE_NAMES.get(flower_type, "花种"),
			level,
			amount
		]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		row.add_child(label)

		if is_synthesis_unlocked() and GardenSynthesisService.can_synthesize(flower_type, level, amount):
			var synth_btn = Button.new()
			synth_btn.text = "合成"
			synth_btn.custom_minimum_size = Vector2(90, 36)
			synth_btn.pressed.connect(_on_synthesize_pressed.bind(flower_type, level))
			row.add_child(synth_btn)

		inventory_list.add_child(row)


func _update_decoration_display() -> void:
	if not decoration_list:
		return

	for child in decoration_list.get_children():
		child.queue_free()

	var restoration = SaveManager.get_restoration_state()
	if restoration_label:
		restoration_label.text = "%s %s" % [restoration.get("icon", "🌿"), restoration.get("name", "沉睡角")]
	if restoration_hint_label:
		restoration_hint_label.text = str(restoration.get("description", ""))
	if restoration_preview_label:
		restoration_preview_label.text = str(restoration.get("preview", "🌿"))
	if restoration_focus_label:
		restoration_focus_label.text = "现在最明显的是：%s" % str(restoration.get("focus_title", "左侧空盆"))
	if restoration_goal_label:
		restoration_goal_label.text = str(restoration.get("next_goal", ""))
	highlighted_restoration_slot = int(restoration.get("focus_slot", -1))
	_render_restoration_badges(int(restoration.get("stage", 0)))
	_update_restoration_palette(int(restoration.get("stage", 0)))

	var display_data = DecorationService.get_display_data()
	if atmosphere_label:
		atmosphere_label.text = "氛围值 %d" % int(display_data.get("atmosphere", 0))
		atmosphere_label.visible = is_decoration_unlocked()

	if not is_decoration_unlocked():
		var locked_label = Label.new()
		locked_label.text = "完成第 3 局后，这里会慢慢开放装饰与点亮。"
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked_label.add_theme_font_size_override("font_size", 15)
		decoration_list.add_child(locked_label)
		return

	var catalog = display_data.get("catalog", [])
	for decoration in catalog:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.text = "%s %s\n%d✨  +%d氛围" % [
			decoration.get("icon", ""),
			decoration.get("name", "装饰"),
			int(decoration.get("cost", 0)),
			int(decoration.get("atmosphere", 0))
		]
		label.add_theme_font_size_override("font_size", 15)
		label.custom_minimum_size = Vector2(145, 48)
		row.add_child(label)

		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(84, 40)
		if decoration.get("owned", false):
			action_btn.text = "已点亮"
			action_btn.disabled = true
		else:
			action_btn.text = "购买"
			action_btn.pressed.connect(_on_decoration_purchase_pressed.bind(str(decoration.get("id", ""))))
		row.add_child(action_btn)

		decoration_list.add_child(row)


func _render_restoration_badges(current_stage: int) -> void:
	if not restoration_badges:
		return
	for child in restoration_badges.get_children():
		child.queue_free()

	var stages = ["🌙", "🌱", "🌸", "✨"]
	for stage_index in range(stages.size()):
		var badge = Label.new()
		badge.text = stages[stage_index]
		badge.add_theme_font_size_override("font_size", 24)
		badge.modulate = Color(1, 1, 1, 1) if stage_index <= current_stage else Color(0.7, 0.7, 0.7, 1)
		restoration_badges.add_child(badge)


func _update_restoration_palette(stage: int) -> void:
	if background_rect == null:
		return
	background_rect.texture = VisualAssetCatalogScript.get_garden_background(stage)
	if background_tint == null:
		return
	match stage:
		0:
			background_tint.color = Color(0.88, 0.92, 0.9, 0.34)
		1:
			background_tint.color = Color(0.86, 0.95, 0.88, 0.3)
		2:
			background_tint.color = Color(0.92, 0.97, 0.88, 0.26)
		_:
			background_tint.color = Color(0.95, 0.98, 0.92, 0.22)


func _get_slot_modulate(slot_index: int) -> Color:
	if slot_index == highlighted_restoration_slot:
		return Color(1.0, 0.98, 0.86, 1.0)
	return Color(0.94, 0.94, 0.94, 1.0)

# ==================== 输入处理 ====================
func _on_slot_input(index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_slot_clicked(index)

func _on_slot_clicked(index: int) -> void:
	AudioManager.play_ui_click()
	
	# 检查花盆状态
	var slots = garden_data.get("slots", [])
	if index < slots.size() and not slots[index].is_empty():
		# 有花朵，可以收获或合成
		_handle_flower_action(index, slots[index])
	else:
		# 空花盆，可以种植
		_handle_plant_action(index)

func _handle_flower_action(index: int, flower_data: Dictionary) -> void:
	_refresh_growth_states()

	var growth = flower_data.get("growth", 0.0)
	
	if growth >= 1.0:
		# 可以收获
		_harvest_flower(index)
	else:
		# 显示详情
		var flower_type = flower_data.get("type", 1)
		var level = flower_data.get("level", 1)
		var flower_name = Constants.TILE_NAMES.get(flower_type, "Unknown")
		PopupManager.show_toast("%s Lv.%d - 成长中..." % [flower_name, level])

func _handle_plant_action(index: int) -> void:
	var seed = _get_first_plantable_seed()
	if seed.is_empty():
		PopupManager.show_toast("没有可种植的花种，先去闯关吧")
		return

	var flower_type = seed.get("type", Constants.TileType.RED_ROSE)
	var level = seed.get("level", 1)
	if not SaveManager.consume_garden_inventory_item(flower_type, level, 1):
		PopupManager.show_toast("花种数量不足")
		return

	_load_garden_data()
	plant_flower(index, flower_type, level)
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	PopupManager.show_toast("种下了 %s 花种" % flower_name)

func _harvest_flower(index: int) -> void:
	var slots = garden_data.get("slots", [])
	if index < slots.size():
		var flower = slots[index]
		var flower_type = flower.get("type", 1)
		var level = flower.get("level", 1)
		
		# 计算奖励
		var stars = _get_harvest_reward(level)
		
		# 更新玩家数据
		var player_data = SaveManager.get_player_data()
		player_data["stars"] = player_data.get("stars", 0) + stars
		SaveManager.update_player_data(player_data)
		DailyService.record_event(DailyService.TASK_HARVEST_FLOWER)
		
		# 清空花盆
		slots[index] = {}
		garden_data["slots"] = slots
		SaveManager.update_garden_data(garden_data)
		
		# 更新显示
		_update_garden_display()
		
		# 提示
		var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
		PopupManager.show_toast("收获 %s！获得 %d ✨" % [flower_name, stars])


func _on_synthesize_pressed(flower_type: int, level: int) -> void:
	if not is_synthesis_unlocked():
		PopupManager.show_toast("先完成前三局，让花园先恢复呼吸。")
		return
	AudioManager.play_ui_click()
	var result = GardenSynthesisService.synthesize_once(flower_type, level)
	if not result.get("success", false):
		PopupManager.show_toast("材料不足，无法合成")
		return

	_load_garden_data()
	flower_synthesized.emit(flower_type, level, int(result.get("to_level", level + 1)))
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	PopupManager.show_toast("%s Lv.%d 合成为 Lv.%d" % [flower_name, level, int(result.get("to_level", level + 1))])


func _on_decoration_purchase_pressed(decoration_id: String) -> void:
	if not is_decoration_unlocked():
		PopupManager.show_toast("先让花园恢复到微光庭，再来点亮装饰。")
		return
	AudioManager.play_ui_click()
	var result = DecorationService.purchase_decoration(decoration_id)
	if not result.get("success", false):
		PopupManager.show_toast(_get_decoration_error_message(str(result.get("reason", ""))))
		return

	garden_data = SaveManager.get_garden_data()
	_update_garden_display()
	var decoration = result.get("decoration", {})
	PopupManager.show_toast("点亮 %s，氛围值 +%d" % [
		decoration.get("name", "装饰"),
		int(result.get("atmosphere", 0))
	])


func _get_decoration_error_message(reason: String) -> String:
	match reason:
		"not_enough_stars":
			return "星光不足，先去闯关或收获花朵吧"
		"already_owned":
			return "这个装饰已经点亮了"
		"invalid_id":
			return "装饰配置不存在"
		_:
			return "暂时无法购买装饰"

# ==================== 按钮回调 ====================
func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	back_pressed.emit()

# ==================== 公开方法 ====================
func show_garden(context: Dictionary = {}) -> void:
	visible = true
	_load_garden_data()
	modulate.a = 0
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.finished.connect(_remove_tween.bind(tween))
	_play_arrival_feedback(context)


func is_synthesis_unlocked() -> bool:
	return int(SaveManager.get_player_data().get("total_runs", 0)) >= META_UNLOCK_RUNS


func is_decoration_unlocked() -> bool:
	return int(SaveManager.get_player_data().get("total_runs", 0)) >= META_UNLOCK_RUNS

func hide_garden() -> void:
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	tween.finished.connect(_remove_tween.bind(tween))

func plant_flower(slot_index: int, flower_type: int, level: int = 1) -> void:
	var slots = garden_data.get("slots", [])
	
	# 确保slots数组足够大
	while slots.size() <= slot_index:
		slots.append({})
	
	slots[slot_index] = {
		"type": flower_type,
		"level": level,
		"growth": 0.0,
		"planted_at": Time.get_unix_time_from_system()
	}
	
	garden_data["slots"] = slots
	SaveManager.update_garden_data(garden_data)
	_update_garden_display()
	
	flower_planted.emit(slot_index, flower_type)


func _refresh_growth_states() -> void:
	var slots = garden_data.get("slots", [])
	var changed = false

	for i in range(slots.size()):
		var slot_data = slots[i]
		if slot_data.is_empty():
			continue

		var planted_at = float(slot_data.get("planted_at", 0.0))
		if planted_at <= 0.0:
			continue

		var duration = _get_growth_duration(slot_data.get("level", 1))
		var elapsed = Time.get_unix_time_from_system() - planted_at
		var growth = clampf(elapsed / duration, 0.0, 1.0)

		if absf(growth - float(slot_data.get("growth", 0.0))) > 0.001:
			slot_data["growth"] = growth
			slots[i] = slot_data
			changed = true

	if changed:
		garden_data["slots"] = slots
		SaveManager.update_garden_data(garden_data)


func _get_growth_duration(level: int) -> float:
	return Constants.FLOWER_GROWTH_DURATION * maxf(1.0, float(level))


func _get_first_plantable_seed() -> Dictionary:
	var inventory = garden_data.get("inventory", [])
	for item in inventory:
		if int(item.get("level", 1)) <= GardenSynthesisService.MAX_SYNTHESIS_LEVEL:
			return item
	return {}


func _get_harvest_reward(level: int) -> int:
	match level:
		1:
			return 10
		2:
			return 25
		3:
			return 45
		_:
			return 10 + max(0, level - 1) * 20


func _play_arrival_feedback(context: Dictionary) -> void:
	last_arrival_message = ""
	last_arrival_detail = ""
	if not arrival_overlay:
		return

	arrival_overlay.visible = false
	arrival_overlay.modulate = Color(1, 1, 1, 0)

	var restoration = context.get("restoration_progress", {})
	if not (restoration is Dictionary) or not bool(restoration.get("changed", false)):
		return

	var stage_name = str(restoration.get("name", SaveManager.get_restoration_state().get("name", "发芽角")))
	var stage_icon = str(restoration.get("icon", SaveManager.get_restoration_state().get("icon", "✨")))
	var current_state = SaveManager.get_restoration_state()
	var preview = str(current_state.get("preview", stage_icon))
	var focus_detail = str(restoration.get("focus_detail", current_state.get("focus_detail", "这一局带回来的微光落在这里了。")))
	last_arrival_message = "花园恢复到「%s」" % stage_name
	last_arrival_detail = focus_detail

	arrival_title_label.text = last_arrival_message
	arrival_preview_label.text = preview
	arrival_detail_label.text = focus_detail
	arrival_overlay.visible = true

	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(arrival_overlay, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(arrival_overlay, "scale", Vector2(1.04, 1.04), 0.22).from(Vector2(0.92, 0.92))
	tween.tween_interval(0.9)
	tween.tween_property(arrival_overlay, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(arrival_overlay, "scale", Vector2.ONE, 0.28)
	tween.tween_callback(func() -> void:
		arrival_overlay.visible = false
		arrival_overlay.scale = Vector2.ONE
	)
	tween.finished.connect(_remove_tween.bind(tween))


func _remove_tween(tween: Tween) -> void:
	var index = active_tweens.find(tween)
	if index >= 0:
		active_tweens.remove_at(index)
