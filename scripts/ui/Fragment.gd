## Fragment - 花语碎片节点
class_name Fragment
extends Node2D

# ==================== 变量 ====================
var flower_type: int = Constants.TileType.RED_ROSE
var is_collected: bool = false

# 节点引用
var sprite: Sprite2D
var pulse_tween: Tween

# ==================== 生命周期 ====================
func _ready() -> void:
	_create_visual()
	_start_pulse_animation()


func _exit_tree() -> void:
	if pulse_tween and is_instance_valid(pulse_tween):
		pulse_tween.kill()
		pulse_tween = null

# ==================== 初始化 ====================
func initialize(type: int) -> void:
	flower_type = type
	if sprite:
		var texture = SpriteGenerator.generate_fragment_texture(type, 32)
		sprite.texture = texture

# ==================== 视觉创建 ====================
func _create_visual() -> void:
	# 创建精灵
	sprite = Sprite2D.new()
	sprite.texture = SpriteGenerator.generate_fragment_texture(flower_type, 32)
	sprite.offset = Vector2(16, 16)
	_add_fragment_material(sprite)
	add_child(sprite)

# 添加碎片材质
func _add_fragment_material(sprite: Sprite2D) -> void:
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = material

# ==================== 动画 ====================
func _start_pulse_animation() -> void:
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(sprite, "modulate:a", 0.6, 1.0)\
		.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(sprite, "modulate:a", 1.0, 1.0)\
		.set_ease(Tween.EASE_IN_OUT)

func play_collect_animation() -> void:
	is_collected = true
	if pulse_tween and is_instance_valid(pulse_tween):
		pulse_tween.kill()
		pulse_tween = null
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
