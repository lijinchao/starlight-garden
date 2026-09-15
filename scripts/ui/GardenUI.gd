## GardenUI - 花园界面
class_name GardenUI
extends Control

const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")
const GardenPlantVisualScript = preload("res://scripts/ui/GardenPlantVisual.gd")

# ==================== 信号 ====================
signal back_pressed()
signal flower_planted(slot: int, flower_type: int)
signal flower_synthesized(flower_type: int, from_level: int, to_level: int)
signal playtest_event(event_name: String, payload: Dictionary)

# ==================== 节点引用 ====================
var back_btn: Button
var garden_grid: Control
var flower_slots: Array = []
var selected_slot: int = -1
var inventory_container: VBoxContainer
var star_count_label: Label
var inventory_list: VBoxContainer
var decoration_container: VBoxContainer
var decoration_backdrop: ColorRect
var decoration_list: HBoxContainer
var atmosphere_label: Label
var restoration_label: Label
var restoration_hint_label: Label
var restoration_preview_label: Label
var restoration_goal_label: Label
var restoration_focus_label: Label
var restored_corners_label: Label
var restored_corner_layer: Control
var restored_corner_markers: Dictionary = {}
var restoration_badges: HBoxContainer
var background_rect: TextureRect
var background_tint: ColorRect
var inventory_backdrop: ColorRect
var decoration_visual_layer: Control
var decoration_visuals: Dictionary = {}
var top_bar_panel: PanelContainer
var restoration_summary_panel: PanelContainer
var arrival_overlay: PanelContainer
var arrival_title_label: Label
var arrival_detail_label: Label
var arrival_preview_label: Label
var last_arrival_message: String = ""
var last_arrival_detail: String = ""
var highlighted_restoration_slot: int = -1
var active_tweens: Array[Tween] = []
var seed_picker_overlay: Control
var seed_picker_list: VBoxContainer
var pending_plant_slot: int = -1
var last_selected_seed: Dictionary = {}
var previewed_decoration_id: String = ""
var last_synthesis_preview: Dictionary = {}
var decoration_drop_zone: PanelContainer
var decoration_drop_label: Label
var decoration_drag_ghost: TextureRect
var dragging_decoration_id: String = ""
var decoration_choice_buttons: Dictionary = {}

const DECORATION_LAYOUT: Dictionary = {
	"bench": {"position": Vector2(150, 450), "size": Vector2(300, 250)},
	"fountain": {"position": Vector2(190, 430), "size": Vector2(250, 250)},
	"lantern": {"position": Vector2(600, 250), "size": Vector2(120, 200)},
	"hedge": {"position": Vector2(430, 520), "size": Vector2(240, 150)}
}

const FLOWER_HOTSPOT_LAYOUT: Array[Dictionary] = [
	{"position": Vector2(36, 555), "size": Vector2(190, 190)},
	{"position": Vector2(214, 650), "size": Vector2(132, 150)},
	{"position": Vector2(430, 480), "size": Vector2(210, 190)},
	{"position": Vector2(630, 570), "size": Vector2(112, 155)}
]

# 已恢复的具名角落落在花园上排的固定位置，一眼能看出“哪里被打通了”。
const RESTORED_CORNER_LAYOUT: Array[Dictionary] = [
	{"position": Vector2(30, 12), "size": Vector2(160, 118)},
	{"position": Vector2(205, 12), "size": Vector2(160, 118)},
	{"position": Vector2(380, 12), "size": Vector2(160, 118)},
	{"position": Vector2(555, 12), "size": Vector2(160, 118)}
]

const PRIMARY_DECORATION_CHOICES: Array[String] = [
	"bench",
	"fountain"
]

const DECORATION_DROP_RECT := Rect2(145, 430, 330, 280)

const EMPTY_SLOT_STYLE := Color(0.95, 0.98, 0.9, 0.16)
const ACTIVE_SLOT_STYLE := Color(1.0, 0.94, 0.7, 0.34)

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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO

	# 背景
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)

	background_tint = ColorRect.new()
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_tint.color = Color(0.98, 0.96, 0.92, 0.08)
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_tint)

	decoration_visual_layer = Control.new()
	decoration_visual_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decoration_visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decoration_visual_layer)
	_create_decoration_visuals()
	
	# 顶部导航使用独立底板，避免按钮和背景插画混在一起。
	top_bar_panel = PanelContainer.new()
	top_bar_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar_panel.offset_left = 16
	top_bar_panel.offset_top = 16
	top_bar_panel.offset_right = -16
	top_bar_panel.offset_bottom = 76
	top_bar_panel.add_theme_stylebox_override("panel", _create_surface_style(Color(0.98, 0.99, 0.97, 0.94)))
	top_bar_panel.z_index = 10
	add_child(top_bar_panel)

	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	top_bar_panel.add_child(top_bar)
	
	# 返回按钮
	back_btn = Button.new()
	back_btn.text = "←"
	back_btn.tooltip_text = "返回首页"
	back_btn.custom_minimum_size = Vector2(56, 44)
	back_btn.add_theme_font_size_override("font_size", 26)
	top_bar.add_child(back_btn)
	
	# 标题
	var title = Label.new()
	title.text = "我的花园"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.16, 0.22, 0.18))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	
	# 星光数量
	var star_container = HBoxContainer.new()
	star_container.custom_minimum_size = Vector2(88, 44)
	star_container.alignment = BoxContainer.ALIGNMENT_END
	top_bar.add_child(star_container)
	
	var star_icon = Label.new()
	star_icon.text = "✨"
	star_icon.add_theme_font_size_override("font_size", 28)
	star_icon.add_theme_color_override("font_color", Color(0.2, 0.24, 0.18))
	star_container.add_child(star_icon)
	
	star_count_label = Label.new()
	star_count_label.text = "0"
	star_count_label.add_theme_font_size_override("font_size", 24)
	star_count_label.add_theme_color_override("font_color", Color(0.16, 0.22, 0.18))
	star_container.add_child(star_count_label)
	
	# 恢复信息压缩成一条场景目标，不覆盖主要花园空间。
	restoration_summary_panel = PanelContainer.new()
	restoration_summary_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	restoration_summary_panel.offset_left = 24
	restoration_summary_panel.offset_top = 88
	restoration_summary_panel.offset_right = -24
	restoration_summary_panel.offset_bottom = 158
	restoration_summary_panel.add_theme_stylebox_override("panel", _create_surface_style(Color(0.1, 0.12, 0.08, 0.58)))
	restoration_summary_panel.z_index = 10
	add_child(restoration_summary_panel)

	var restoration_summary = VBoxContainer.new()
	restoration_summary.alignment = BoxContainer.ALIGNMENT_CENTER
	restoration_summary.add_theme_constant_override("separation", 4)
	restoration_summary_panel.add_child(restoration_summary)

	restoration_label = Label.new()
	restoration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_label.add_theme_font_size_override("font_size", 18)
	restoration_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	restoration_summary.add_child(restoration_label)

	restoration_focus_label = Label.new()
	restoration_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_focus_label.custom_minimum_size = Vector2(620, 24)
	restoration_focus_label.add_theme_font_size_override("font_size", 15)
	restoration_focus_label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.86))
	restoration_summary.add_child(restoration_focus_label)

	# 具名因果：把“这一局打通了哪一处”长期留在花园首屏。
	restored_corners_label = Label.new()
	restored_corners_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restored_corners_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restored_corners_label.custom_minimum_size = Vector2(620, 20)
	restored_corners_label.add_theme_font_size_override("font_size", 14)
	restored_corners_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
	restoration_summary.add_child(restored_corners_label)

	restoration_goal_label = Label.new()
	restoration_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restoration_goal_label.custom_minimum_size = Vector2(620, 26)
	restoration_goal_label.add_theme_font_size_override("font_size", 14)
	restoration_goal_label.visible = false
	restoration_summary.add_child(restoration_goal_label)

	restoration_badges = HBoxContainer.new()
	restoration_badges.visible = false
	restoration_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	restoration_badges.add_theme_constant_override("separation", 10)
	restoration_summary.add_child(restoration_badges)

	# 保留数据节点供状态更新使用，但不再把长说明重复展示在首屏。
	restoration_hint_label = Label.new()
	restoration_hint_label.visible = false
	restoration_preview_label = Label.new()
	restoration_preview_label.visible = false

	# 花盆与花圃直接映射到背景中的实际位置。
	garden_grid = Control.new()
	garden_grid.name = "GardenHotspots"
	garden_grid.position = Vector2(0, 160)
	garden_grid.size = Vector2(750, 760)
	add_child(garden_grid)

	# 创建花盆位
	for i in range(4):
		var slot = _create_flower_slot(i)
		garden_grid.add_child(slot)
		var layout: Dictionary = FLOWER_HOTSPOT_LAYOUT[i]
		slot.position = layout.get("position", Vector2.ZERO)
		slot.size = layout.get("size", Vector2(150, 150))
		flower_slots.append(slot)

	# 已恢复角落的可见标记层（在花位上方一排）。
	restored_corner_layer = Control.new()
	restored_corner_layer.name = "RestoredCorners"
	restored_corner_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	restored_corner_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	garden_grid.add_child(restored_corner_layer)

	# 装饰从商品列表改为底部二选一拖放托盘。
	decoration_backdrop = ColorRect.new()
	decoration_backdrop.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	decoration_backdrop.offset_top = -360
	decoration_backdrop.offset_bottom = 0
	decoration_backdrop.color = Color(0.06, 0.07, 0.05, 0.72)
	decoration_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decoration_backdrop.z_index = 20
	add_child(decoration_backdrop)

	decoration_container = VBoxContainer.new()
	decoration_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	decoration_container.offset_left = 24
	decoration_container.offset_top = -344
	decoration_container.offset_right = -24
	decoration_container.offset_bottom = -18
	decoration_container.add_theme_constant_override("separation", 8)
	decoration_container.z_index = 21
	add_child(decoration_container)

	var decoration_title = Label.new()
	decoration_title.text = "拖到庭院中，选择会永久保留"
	decoration_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decoration_title.add_theme_font_size_override("font_size", 19)
	decoration_title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	decoration_container.add_child(decoration_title)

	atmosphere_label = Label.new()
	atmosphere_label.text = "完成第一次收获后，可以布置一处休憩角"
	atmosphere_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atmosphere_label.add_theme_font_size_override("font_size", 14)
	atmosphere_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.82))
	decoration_container.add_child(atmosphere_label)

	decoration_list = HBoxContainer.new()
	decoration_list.alignment = BoxContainer.ALIGNMENT_CENTER
	decoration_list.add_theme_constant_override("separation", 18)
	decoration_container.add_child(decoration_list)

	# 旧背包/合成面板保留节点兼容调用，但不再占据首屏。
	inventory_backdrop = ColorRect.new()
	inventory_backdrop.visible = false
	inventory_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inventory_backdrop)

	inventory_container = VBoxContainer.new()
	inventory_container.visible = false
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
	arrival_overlay.z_index = 20
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

	_create_seed_picker()
	_create_decoration_drop_zone()
	_create_decoration_drag_ghost()

# 创建花盆位
func _create_flower_slot(index: int) -> Control:
	var slot = PanelContainer.new()
	slot.name = "Slot%d" % index
	slot.tooltip_text = "点击照料这处花园"
	var slot_style = _create_surface_style(EMPTY_SLOT_STYLE)
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = Color(1.0, 0.94, 0.68, 0.62)
	slot.add_theme_stylebox_override("panel", slot_style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	var plant_visual = GardenPlantVisualScript.new()
	plant_visual.name = "PlantVisual"
	plant_visual.custom_minimum_size = Vector2(86, 112)
	plant_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plant_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plant_visual.visible = false
	vbox.add_child(plant_visual)
	
	# 空热点保留轻量状态符号；花朵本体使用项目 PNG。
	var pot = Label.new()
	pot.text = "+"
	pot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot.add_theme_font_size_override("font_size", 38)
	pot.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78))
	pot.name = "PotIcon"
	vbox.add_child(pot)
	
	# 状态文本
	var status = Label.new()
	status.text = "空闲"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	status.add_theme_color_override("font_shadow_color", Color(0.05, 0.05, 0.03, 0.9))
	status.add_theme_constant_override("shadow_offset_x", 1)
	status.add_theme_constant_override("shadow_offset_y", 1)
	status.name = "StatusLabel"
	vbox.add_child(status)
	
	# 点击区域
	slot.gui_input.connect(_on_slot_input.bind(index))
	
	return slot


func _create_decoration_drop_zone() -> void:
	decoration_drop_zone = PanelContainer.new()
	decoration_drop_zone.name = "DecorationDropZone"
	decoration_drop_zone.position = DECORATION_DROP_RECT.position
	decoration_drop_zone.size = DECORATION_DROP_RECT.size
	decoration_drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decoration_drop_zone.z_index = 12
	decoration_drop_zone.visible = false
	var style = _create_surface_style(Color(1.0, 0.9, 0.55, 0.12))
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.92, 0.56, 0.82)
	decoration_drop_zone.add_theme_stylebox_override("panel", style)
	add_child(decoration_drop_zone)

	decoration_drop_label = Label.new()
	decoration_drop_label.text = "拖到这里"
	decoration_drop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decoration_drop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	decoration_drop_label.add_theme_font_size_override("font_size", 20)
	decoration_drop_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
	decoration_drop_zone.add_child(decoration_drop_label)


func _create_decoration_drag_ghost() -> void:
	decoration_drag_ghost = TextureRect.new()
	decoration_drag_ghost.name = "DecorationDragGhost"
	decoration_drag_ghost.size = Vector2(210, 190)
	decoration_drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	decoration_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	decoration_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decoration_drag_ghost.modulate = Color(1.05, 1.05, 0.94, 0.86)
	decoration_drag_ghost.z_index = 35
	decoration_drag_ghost.visible = false
	add_child(decoration_drag_ghost)


func _create_surface_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _create_decoration_visuals() -> void:
	for decoration_id in DECORATION_LAYOUT:
		var layout: Dictionary = DECORATION_LAYOUT[decoration_id]
		var visual = TextureRect.new()
		visual.name = "Decoration_%s" % decoration_id
		visual.position = layout.get("position", Vector2.ZERO)
		visual.size = layout.get("size", Vector2(120, 120))
		visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.texture = VisualAssetCatalogScript.get_decoration_texture(decoration_id)
		visual.visible = false
		decoration_visual_layer.add_child(visual)
		decoration_visuals[decoration_id] = visual


func _create_seed_picker() -> void:
	seed_picker_overlay = Control.new()
	seed_picker_overlay.name = "SeedPicker"
	seed_picker_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	seed_picker_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	seed_picker_overlay.z_index = 40
	seed_picker_overlay.visible = false
	add_child(seed_picker_overlay)

	var shade = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.08, 0.06, 0.32)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	seed_picker_overlay.add_child(shade)

	var panel = PanelContainer.new()
	panel.name = "SeedPickerSheet"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 20
	panel.offset_top = -390
	panel.offset_right = -20
	panel.offset_bottom = -18
	panel.add_theme_stylebox_override("panel", _create_surface_style(Color(0.97, 0.99, 0.96, 1.0)))
	seed_picker_overlay.add_child(panel)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title = Label.new()
	title.text = "选择要种下的花种"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.12, 0.2, 0.14))
	content.add_child(title)

	var hint = Label.new()
	hint.text = "种下后会消耗 1 颗，成熟可收获星光"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.24, 0.32, 0.25))
	content.add_child(hint)

	var seed_scroll = ScrollContainer.new()
	seed_scroll.custom_minimum_size = Vector2(0, 245)
	seed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(seed_scroll)

	seed_picker_list = VBoxContainer.new()
	seed_picker_list.custom_minimum_size = Vector2(660, 0)
	seed_picker_list.add_theme_constant_override("separation", 10)
	seed_scroll.add_child(seed_picker_list)

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
	_update_restored_corner_markers()

func _update_slot_display(slot: Control, data: Dictionary, _index: int) -> void:
	# 获取VBoxContainer中的节点
	var vbox = slot.get_child(0)  # VBoxContainer是第一个子节点
	if not vbox:
		return
	
	var pot_icon = vbox.get_node_or_null("PotIcon")
	var status_label = vbox.get_node_or_null("StatusLabel")
	var plant_visual = vbox.get_node_or_null("PlantVisual")
	
	if not pot_icon or not status_label or not plant_visual:
		return
	
	if data.is_empty():
		var empty_visual = _get_empty_slot_visual(_index)
		pot_icon.text = str(empty_visual.get("icon", "🪴"))
		pot_icon.visible = true
		plant_visual.visible = false
		status_label.text = str(empty_visual.get("label", "空闲"))
		status_label.modulate = Color.WHITE
		_apply_hotspot_style(slot, _index == highlighted_restoration_slot)
	else:
		var flower_type = data.get("type", 1)
		var flower_level = data.get("level", 1)
		var growth = data.get("growth", 0.0)
		pot_icon.visible = false
		var flower_texture = VisualAssetCatalogScript.get_tile_texture(int(flower_type))
		plant_visual.set_plant(flower_texture, float(growth), int(flower_level), _index)
		plant_visual.visible = flower_texture != null
		
		# 状态文本
		if growth >= 1.0:
			status_label.text = "点击收获"
			status_label.modulate = Color(1.0, 0.96, 0.58)
		else:
			status_label.text = "%s · %d%%" % [Constants.TILE_NAMES.get(flower_type, "花朵"), int(growth * 100)]
			status_label.modulate = Color.WHITE
		_apply_planted_style(slot)


func _apply_hotspot_style(slot: Control, active: bool) -> void:
	if not slot is PanelContainer:
		return
	var style = _create_surface_style(ACTIVE_SLOT_STYLE if active else EMPTY_SLOT_STYLE)
	style.border_width_left = 3 if active else 1
	style.border_width_top = 3 if active else 1
	style.border_width_right = 3 if active else 1
	style.border_width_bottom = 3 if active else 1
	style.border_color = Color(1.0, 0.93, 0.55, 0.9 if active else 0.38)
	(slot as PanelContainer).add_theme_stylebox_override("panel", style)


func _apply_planted_style(slot: Control) -> void:
	if not slot is PanelContainer:
		return
	var style = _create_surface_style(Color(0, 0, 0, 0))
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	(slot as PanelContainer).add_theme_stylebox_override("panel", style)


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
			var spatial_prompts: Array[String] = [
				"种在大花盆",
				"种在蓝花盆",
				"照料中央花圃",
				"点亮右侧花盆"
			]
			return {
				"icon": "+",
				"label": spatial_prompts[clampi(slot_index, 0, spatial_prompts.size() - 1)],
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
	decoration_choice_buttons.clear()

	var restoration = SaveManager.get_restoration_state()
	if restoration_label:
		restoration_label.text = "%s %s" % [restoration.get("icon", "🌿"), restoration.get("name", "沉睡角")]
	if restoration_hint_label:
		restoration_hint_label.text = str(restoration.get("description", ""))
	if restoration_preview_label:
		restoration_preview_label.text = str(restoration.get("preview", "🌿"))
	if restoration_focus_label:
		restoration_focus_label.text = "现在最明显的是：%s" % str(restoration.get("focus_title", "左侧空盆"))
	if restored_corners_label:
		restored_corners_label.text = _format_restored_corners_text()
	if restoration_goal_label:
		restoration_goal_label.text = str(restoration.get("next_goal", ""))
	highlighted_restoration_slot = int(restoration.get("focus_slot", -1))
	_render_restoration_badges(int(restoration.get("stage", 0)))
	_update_restoration_palette(int(restoration.get("stage", 0)))
	_update_decoration_visuals()

	var decoration_unlocked = is_decoration_unlocked()
	var choice_available = decoration_unlocked and not _has_primary_decoration_choice()
	decoration_container.visible = choice_available
	decoration_backdrop.visible = choice_available
	if not choice_available:
		return

	if atmosphere_label:
		atmosphere_label.visible = true

	for decoration_id in PRIMARY_DECORATION_CHOICES:
		var decoration = DecorationService.get_decoration(decoration_id)
		var texture = VisualAssetCatalogScript.get_decoration_texture(decoration_id)
		if decoration.is_empty() or texture == null:
			continue
		var choice_btn = Button.new()
		choice_btn.name = "DecorationChoice_%s" % decoration_id
		choice_btn.text = "%s · %d ✨" % [
			decoration.get("name", "装饰"),
			int(decoration.get("cost", 0))
		]
		choice_btn.icon = texture
		choice_btn.expand_icon = true
		choice_btn.add_theme_constant_override("icon_max_width", 190)
		choice_btn.custom_minimum_size = Vector2(280, 230)
		choice_btn.add_theme_font_size_override("font_size", 17)
		choice_btn.tooltip_text = "按住并拖到庭院中的发光位置"
		choice_btn.button_down.connect(_begin_decoration_drag.bind(decoration_id))
		decoration_list.add_child(choice_btn)
		decoration_choice_buttons[decoration_id] = choice_btn


func _format_restored_corners_text() -> String:
	var names: Array = []
	for corner in SaveManager.get_restored_corners():
		var corner_name = str(corner.get("name", "")).strip_edges()
		if not corner_name.is_empty():
			names.append("「%s」" % corner_name)
	if names.is_empty():
		return "花园还没有点亮的角落"
	return "已点亮 %d 处角落：%s" % [names.size(), " ".join(names)]


# 已恢复的具名角落落在花园里的可见位置。
func get_restored_corner_slot_position(level_id: int) -> Vector2:
	var corners = SaveManager.get_restored_corners()
	for index in range(mini(corners.size(), RESTORED_CORNER_LAYOUT.size())):
		if int(corners[index].get("level_id", 0)) == level_id:
			return RESTORED_CORNER_LAYOUT[index].get("position", Vector2.ZERO)
	return Vector2.ZERO


func _update_restored_corner_markers() -> void:
	if restored_corner_layer == null:
		return
	for child in restored_corner_layer.get_children():
		child.queue_free()
	restored_corner_markers.clear()

	var corners = SaveManager.get_restored_corners()
	for index in range(mini(corners.size(), RESTORED_CORNER_LAYOUT.size())):
		var corner: Dictionary = corners[index]
		var level_id = int(corner.get("level_id", 0))
		var layout: Dictionary = RESTORED_CORNER_LAYOUT[index]
		var marker = _create_restored_corner_marker(corner)
		marker.position = layout.get("position", Vector2.ZERO)
		marker.size = layout.get("size", Vector2(160, 118))
		restored_corner_layer.add_child(marker)
		restored_corner_markers[level_id] = marker


func _create_restored_corner_marker(corner: Dictionary) -> Control:
	var marker = PanelContainer.new()
	marker.name = "RestoredCorner_%d" % int(corner.get("level_id", 0))
	var style = _create_surface_style(Color(0.98, 0.93, 0.62, 0.30))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.92, 0.5, 0.85)
	marker.add_theme_stylebox_override("panel", style)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	marker.add_child(box)

	var flower_type = int(corner.get("flower_type", 0))
	if flower_type > 0:
		var texture = VisualAssetCatalogScript.get_tile_texture(flower_type)
		if texture != null:
			var icon = TextureRect.new()
			icon.texture = texture
			icon.custom_minimum_size = Vector2(46, 46)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			box.add_child(icon)

	var name_label = Label.new()
	name_label.text = str(corner.get("name", "已恢复"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.18, 0.22, 0.14))
	box.add_child(name_label)
	return marker


func _has_primary_decoration_choice() -> bool:
	for decoration_id in PRIMARY_DECORATION_CHOICES:
		if DecorationService.is_owned(decoration_id):
			return true
	return false


func _update_decoration_visuals() -> void:
	for decoration_id in decoration_visuals:
		var visual = decoration_visuals[decoration_id] as TextureRect
		if visual == null:
			continue
		var is_preview = decoration_id == previewed_decoration_id
		visual.visible = DecorationService.is_owned(decoration_id) or is_preview
		visual.modulate = Color(1.1, 1.0, 0.72, 0.34) if is_preview else Color.WHITE


func _begin_decoration_drag(decoration_id: String) -> void:
	if not is_decoration_unlocked() or _has_primary_decoration_choice():
		return
	var texture = VisualAssetCatalogScript.get_decoration_texture(decoration_id)
	if texture == null:
		return
	dragging_decoration_id = decoration_id
	previewed_decoration_id = decoration_id
	decoration_drag_ghost.texture = texture
	decoration_drag_ghost.visible = true
	decoration_drop_zone.visible = true
	decoration_drop_label.text = "松手放置%s" % DecorationService.get_decoration(decoration_id).get("name", "装饰")
	_update_decoration_drag_position(get_viewport().get_mouse_position())
	_update_decoration_visuals()
	playtest_event.emit("decoration_drag_started", {"decoration_id": decoration_id})


func _input(event: InputEvent) -> void:
	if dragging_decoration_id.is_empty():
		return
	if event is InputEventMouseMotion:
		_update_decoration_drag_position(event.position)
	elif event is InputEventMouseButton and not event.pressed:
		_finish_decoration_drag(event.position)
	elif event is InputEventScreenDrag:
		_update_decoration_drag_position(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_decoration_drag(event.position)


func _update_decoration_drag_position(pointer_position: Vector2) -> void:
	if decoration_drag_ghost:
		decoration_drag_ghost.position = pointer_position - decoration_drag_ghost.size * 0.5


func _finish_decoration_drag(pointer_position: Vector2) -> void:
	var decoration_id = dragging_decoration_id
	var dropped_in_zone = decoration_drop_zone.get_global_rect().has_point(pointer_position)
	dragging_decoration_id = ""
	decoration_drag_ghost.visible = false
	decoration_drop_zone.visible = false
	if dropped_in_zone:
		playtest_event.emit("decoration_dropped", {"decoration_id": decoration_id})
		_confirm_decoration_purchase(decoration_id)
		return
	_cancel_decoration_preview()
	PopupManager.show_toast("把装饰拖到发光的庭院位置")


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
	# 空间交互需要稳定构图；恢复进度由热点和放置物呈现，不再切换镜头完全不同的背景。
	background_rect.texture = VisualAssetCatalogScript.get_garden_background(0)
	if background_tint == null:
		return
	match stage:
		0:
			background_tint.color = Color(0.72, 0.78, 0.76, 0.18)
		1:
			background_tint.color = Color(0.9, 0.94, 0.84, 0.12)
		2:
			background_tint.color = Color(0.98, 0.92, 0.78, 0.08)
		_:
			background_tint.color = Color(1.0, 0.9, 0.76, 0.04)


func _get_slot_modulate(slot_index: int) -> Color:
	if slot_index == highlighted_restoration_slot:
		return Color(1.0, 0.98, 0.86, 1.0)
	return Color(0.94, 0.94, 0.94, 1.0)

# ==================== 输入处理 ====================
func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_slot_clicked(index)
	elif event is InputEventScreenTouch and event.pressed:
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
	var plantable_seeds = _get_plantable_seeds()
	if plantable_seeds.is_empty():
		PopupManager.show_toast("没有可种植的花种，先去闯关吧")
		return
	_show_seed_picker(index, plantable_seeds)


func _show_seed_picker(slot_index: int, seeds: Array = []) -> void:
	if seeds.is_empty():
		seeds = _get_plantable_seeds()
	if seeds.is_empty():
		return
	pending_plant_slot = slot_index
	for child in seed_picker_list.get_children():
		child.queue_free()

	for seed in seeds:
		var flower_type = int(seed.get("type", Constants.TileType.RED_ROSE))
		var level = int(seed.get("level", 1))
		var amount = int(seed.get("amount", 0))
		var seed_btn = Button.new()
		seed_btn.text = "%s  Lv.%d  x%d    成熟收获 %d ✨" % [
			Constants.TILE_NAMES.get(flower_type, "花种"),
			level,
			amount,
			_get_harvest_reward(level)
		]
		seed_btn.icon = VisualAssetCatalogScript.get_tile_texture(flower_type)
		seed_btn.expand_icon = true
		seed_btn.add_theme_constant_override("icon_max_width", 52)
		seed_btn.custom_minimum_size = Vector2(640, 58)
		seed_btn.add_theme_font_size_override("font_size", 17)
		seed_btn.pressed.connect(_confirm_seed_selection.bind(slot_index, flower_type, level))
		seed_picker_list.add_child(seed_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "暂不种植"
	cancel_btn.custom_minimum_size = Vector2(460, 44)
	cancel_btn.pressed.connect(_hide_seed_picker)
	seed_picker_list.add_child(cancel_btn)
	seed_picker_overlay.visible = true


func _hide_seed_picker() -> void:
	seed_picker_overlay.visible = false
	pending_plant_slot = -1


func _confirm_seed_selection(slot_index: int, flower_type: int, level: int) -> void:
	if pending_plant_slot != slot_index:
		return
	var slots = SaveManager.get_garden_data().get("slots", [])
	if slot_index < slots.size() and not slots[slot_index].is_empty():
		_hide_seed_picker()
		PopupManager.show_toast("这个花盆已经有花了")
		return
	if not SaveManager.consume_garden_inventory_item(flower_type, level, 1):
		PopupManager.show_toast("花种数量不足")
		return

	last_selected_seed = {"slot": slot_index, "type": flower_type, "level": level}
	playtest_event.emit("garden_seed_selected", last_selected_seed.duplicate(true))
	_hide_seed_picker()
	_load_garden_data()
	plant_flower(slot_index, flower_type, level)
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	PopupManager.show_toast("种下了 %s Lv.%d，成熟可收获 %d ✨" % [flower_name, level, _get_harvest_reward(level)])

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
		MetaUnlockService.record_behavior(MetaUnlockService.BEHAVIOR_FLOWER_HARVESTED)
		
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
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	last_synthesis_preview = {
		"type": flower_type,
		"from_level": level,
		"to_level": level + 1,
		"cost_count": GardenSynthesisService.SYNTHESIS_COST_COUNT,
		"from_reward": _get_harvest_reward(level),
		"to_reward": _get_harvest_reward(level + 1)
	}
	playtest_event.emit("garden_synthesis_previewed", last_synthesis_preview.duplicate(true))
	PopupManager.show_confirm(
		"合成预览",
		"消耗：%s Lv.%d x%d\n获得：%s Lv.%d x1\n成熟收获：%d ✨ → %d ✨" % [
			flower_name,
			level,
			GardenSynthesisService.SYNTHESIS_COST_COUNT,
			flower_name,
			level + 1,
			_get_harvest_reward(level),
			_get_harvest_reward(level + 1)
		],
		_perform_synthesis.bind(flower_type, level)
	)


func _perform_synthesis(flower_type: int, level: int) -> void:
	var result = GardenSynthesisService.synthesize_once(flower_type, level)
	if not result.get("success", false):
		PopupManager.show_toast("材料不足，无法合成")
		return

	_load_garden_data()
	flower_synthesized.emit(flower_type, level, int(result.get("to_level", level + 1)))
	MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_SYNTHESIS)
	playtest_event.emit("garden_synthesis_completed", result.duplicate(true))
	var flower_name = Constants.TILE_NAMES.get(flower_type, "花朵")
	PopupManager.show_toast("%s 升到 Lv.%d，成熟收获提升到 %d ✨" % [
		flower_name,
		int(result.get("to_level", level + 1)),
		_get_harvest_reward(int(result.get("to_level", level + 1)))
	])


func _on_decoration_purchase_pressed(decoration_id: String) -> void:
	if not is_decoration_unlocked():
		PopupManager.show_toast("先让花园恢复到微光庭，再来点亮装饰。")
		return
	AudioManager.play_ui_click()
	var decoration = DecorationService.get_decoration(decoration_id)
	if decoration.is_empty() or VisualAssetCatalogScript.get_decoration_texture(decoration_id) == null:
		PopupManager.show_toast("装饰素材尚未准备好")
		return
	if DecorationService.is_owned(decoration_id):
		PopupManager.show_toast("这个装饰已经点亮了")
		return

	previewed_decoration_id = decoration_id
	_update_decoration_visuals()
	playtest_event.emit("decoration_previewed", {"decoration_id": decoration_id})
	PopupManager.show_confirm(
		"放置预览",
		"%s · 消耗 %d ✨ · 花园氛围 +%d\n花园画面同时显示购买后的固定位置。" % [
			decoration.get("name", "装饰"),
			int(decoration.get("cost", 0)),
			int(decoration.get("atmosphere", 0))
		],
		_confirm_decoration_purchase.bind(decoration_id),
		_cancel_decoration_preview,
		VisualAssetCatalogScript.get_decoration_texture(decoration_id)
	)


func _cancel_decoration_preview() -> void:
	dragging_decoration_id = ""
	previewed_decoration_id = ""
	if decoration_drag_ghost:
		decoration_drag_ghost.visible = false
	if decoration_drop_zone:
		decoration_drop_zone.visible = false
	_update_decoration_visuals()


func _confirm_decoration_purchase(decoration_id: String) -> void:
	var result = DecorationService.purchase_decoration(decoration_id)
	if not result.get("success", false):
		_cancel_decoration_preview()
		PopupManager.show_toast(_get_decoration_error_message(str(result.get("reason", ""))))
		return

	previewed_decoration_id = ""
	garden_data = SaveManager.get_garden_data()
	_update_garden_display()
	var decoration = result.get("decoration", {})
	_play_decoration_placed_feedback(decoration_id)
	MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_DECORATION)
	playtest_event.emit("decoration_placed", {
		"decoration_id": decoration_id,
		"atmosphere": int(result.get("atmosphere", 0))
	})
	PopupManager.show_toast("%s 已成为这处庭院的永久选择" % decoration.get("name", "装饰"))


func _play_decoration_placed_feedback(decoration_id: String) -> void:
	var visual = decoration_visuals.get(decoration_id) as TextureRect
	if visual == null:
		return
	visual.modulate = Color(1.15, 1.15, 0.8, 0.25)
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.45)


func _get_decoration_error_message(reason: String) -> String:
	match reason:
		"not_enough_stars":
			return "星光不足，先去闯关或收获花朵吧"
		"already_owned":
			return "这个装饰已经点亮了"
		"choice_locked":
			return "这处庭院已经完成布置"
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
	_stop_active_tweens()
	visible = true
	_load_garden_data()
	modulate.a = 1.0
	_play_arrival_feedback(context)


func is_synthesis_unlocked() -> bool:
	return MetaUnlockService.is_unlocked(MetaUnlockService.FEATURE_SYNTHESIS)


func is_decoration_unlocked() -> bool:
	return MetaUnlockService.is_unlocked(MetaUnlockService.FEATURE_DECORATION)

func hide_garden() -> void:
	_stop_active_tweens()
	modulate.a = 1.0
	visible = false

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


func _get_plantable_seeds() -> Array:
	var plantable: Array = []
	var inventory = garden_data.get("inventory", [])
	for item in inventory:
		if int(item.get("amount", 0)) > 0 and int(item.get("level", 1)) <= GardenSynthesisService.MAX_SYNTHESIS_LEVEL:
			plantable.append(item)
	return plantable


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


func _stop_active_tweens() -> void:
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
