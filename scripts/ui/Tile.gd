## Tile - 消除元素节点
class_name Tile
extends Node2D

# ==================== 变量 ====================
var tile_type: int = Constants.TileType.NONE
var grid_position: Vector2i = Vector2i.ZERO
var is_selected: bool = false
var is_matched: bool = false

# 节点引用
var sprite: Sprite2D
var highlight: Sprite2D
var label: Label
var background: ColorRect

# ==================== 生命周期 ====================
func _ready() -> void:
	pass  # 不再需要设置 Area2D，点击由 BoardVisual 的 click_control 处理

# ==================== 初始化 ====================
func initialize(type: int, pos: Vector2i) -> void:
	tile_type = type
	grid_position = pos
	
	# 创建背景（浅色圆角矩形）
	background = ColorRect.new()
	background.color = Color(1, 1, 1, 0.9)
	background.custom_minimum_size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	background.size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	add_child(background)
	
	# 生成纹理
	var texture = SpriteGenerator.generate_flower_texture(type, Constants.TILE_SIZE)
	
	# 创建精灵（居中偏移）
	if not sprite:
		sprite = Sprite2D.new()
		sprite.offset = Vector2(Constants.TILE_SIZE / 2.0, Constants.TILE_SIZE / 2.0)
		_add_tile_material(sprite)
		add_child(sprite)
	sprite.texture = texture
	
	# 创建高亮效果（居中偏移）
	if not highlight:
		highlight = Sprite2D.new()
		highlight.offset = Vector2(Constants.TILE_SIZE / 2.0, Constants.TILE_SIZE / 2.0)
		highlight.texture = texture
		highlight.modulate = Color(1, 1, 1, 0.5)
		highlight.visible = false
		add_child(highlight)
	
	# 创建花朵名称标签
	label = Label.new()
	label.text = _get_tile_short_name(type)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.position = Vector2(0, Constants.TILE_SIZE - 20)
	label.custom_minimum_size = Vector2(Constants.TILE_SIZE, 20)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.8))
	add_child(label)
	
	name = "Tile_%d_%d" % [pos.x, pos.y]

# 为精灵添加材质
func _add_tile_material(sprite: Sprite2D) -> void:
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = material

# 获取花朵简称
func _get_tile_short_name(type: int) -> String:
	match type:
		Constants.TileType.RED_ROSE:
			return "玫瑰"
		Constants.TileType.BLUE_FORGET_ME_NOT:
			return "勿忘我"
		Constants.TileType.PURPLE_LAVENDER:
			return "薰衣草"
		Constants.TileType.YELLOW_SUNFLOWER:
			return "向日葵"
		Constants.TileType.WHITE_JASMINE:
			return "茉莉"
		Constants.TileType.PINK_CHERRY:
			return "樱花"
		_:
			return ""

# ==================== 交互 ====================
func select() -> void:
	is_selected = true
	if highlight:
		highlight.visible = true
	_play_select_animation()

func deselect() -> void:
	is_selected = false
	if highlight:
		highlight.visible = false
	_play_deselect_animation()

# ==================== 动画 ====================
func _play_select_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)

func _play_deselect_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func play_match_animation() -> void:
	is_matched = true
	var tween = create_tween()
	# 消除时光效扩散
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2(1.3, 1.3), 0.25)
	# 添加消除光效（通过调整modulate实现）
	tween.parallel().tween_method(_set_glow_intensity, 0.0, 1.0, 0.15)
	tween.tween_method(_set_glow_intensity, 1.0, 0.0, 0.1)
	tween.tween_callback(queue_free)

func _set_glow_intensity(value: float) -> void:
	if sprite and sprite.material is CanvasItemMaterial:
		# 通过modulate实现发光效果
		sprite.modulate = Color(1, 1, 1, 1 - value * 0.5)

func play_swap_animation(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, Constants.SWAP_DURATION)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func play_fall_animation(target_pos: Vector2, delay: float = 0.0) -> void:
	var tween = create_tween()
	if delay > 0:
		tween.tween_interval(delay)
	tween.tween_property(self, "position", target_pos, Constants.FALL_DURATION)\
		 .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func play_spawn_animation() -> void:
	scale = Vector2.ZERO
	modulate.a = 0
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15)

func play_hint_animation() -> void:
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

# ==================== 公开方法 ====================
func get_tile_type() -> int:
	return tile_type

func get_grid_position() -> Vector2i:
	return grid_position

func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos
