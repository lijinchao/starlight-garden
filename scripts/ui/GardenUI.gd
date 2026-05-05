## GardenUI - 花园界面
class_name GardenUI
extends Control

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

# ==================== UI创建 ====================
func _create_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.85, 0.95, 0.85, 1)  # 浅绿色
	add_child(bg)
	
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
	decoration_title.text = "🏡 花园装饰"
	decoration_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decoration_title.add_theme_font_size_override("font_size", 22)
	decoration_container.add_child(decoration_title)

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
		pot_icon.text = "🪴"
		status_label.text = "空闲"
		status_label.modulate = Color.GRAY
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

		if GardenSynthesisService.can_synthesize(flower_type, level, amount):
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

	var display_data = DecorationService.get_display_data()
	if atmosphere_label:
		atmosphere_label.text = "氛围值 %d" % int(display_data.get("atmosphere", 0))

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
func show_garden() -> void:
	visible = true
	_load_garden_data()
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_garden() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

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
