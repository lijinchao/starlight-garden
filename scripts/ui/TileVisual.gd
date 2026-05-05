## TileVisual - 元素可视化组件
class_name TileVisual
extends Node2D

# ==================== 变量 ====================
var tile_type: int = Constants.TileType.NONE
var grid_position: Vector2i = Vector2i.ZERO
var is_selected: bool = false
var is_matched: bool = false

# 节点引用
var sprite: Sprite2D
var highlight: Sprite2D
var particles: GPUParticles2D

# ==================== 初始化 ====================
func _ready() -> void:
	_create_visual()
	_update_color()

func initialize(type: int, pos: Vector2i) -> void:
	tile_type = type
	grid_position = pos
	_update_color()

# ==================== 视觉创建 ====================
func _create_visual() -> void:
	# 创建精灵
	sprite = Sprite2D.new()
	sprite.texture = _create_circle_texture()
	add_child(sprite)
	
	# 创建高亮效果
	highlight = Sprite2D.new()
	highlight.texture = _create_circle_texture()
	highlight.modulate = Color(1, 1, 1, 0.5)
	highlight.scale = Vector2(1.2, 1.2)
	highlight.visible = false
	add_child(highlight)

# 创建圆形纹理（程序化生成）
func _create_circle_texture() -> ImageTexture:
	var size = Constants.TILE_SIZE - 8
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 2
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= radius:
				# 渐变效果
				var alpha = 1.0 - (distance / radius) * 0.3
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)

# ==================== 视觉更新 ====================
func _update_color() -> void:
	if sprite and tile_type != Constants.TileType.NONE:
		var color = Constants.TILE_COLORS.get(tile_type, Color.WHITE)
		sprite.modulate = color

func set_selected(selected: bool) -> void:
	is_selected = selected
	if highlight:
		highlight.visible = selected
	
	if selected:
		_play_select_animation()
	else:
		_play_deselect_animation()

func set_matched(matched: bool) -> void:
	is_matched = matched
	if matched:
		_play_match_animation()

# ==================== 动画 ====================
func _play_select_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _play_deselect_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _play_match_animation() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_callback(queue_free)

func _play_swap_animation(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, Constants.SWAP_DURATION)

func _play_fall_animation(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, Constants.FALL_DURATION)\
		 .set_ease(Tween.EASE_IN)

# ==================== 输入处理 ====================
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()

func _on_clicked() -> void:
	# 发送点击信号给Board
	var board = get_parent()
	if board and board.has_method("select_tile"):
		board.select_tile(grid_position)
