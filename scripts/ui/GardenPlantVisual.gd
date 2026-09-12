class_name GardenPlantVisual
extends Control

var flower_texture: Texture2D
var growth: float = 0.0
var flower_level: int = 1
var slot_index: int = 0


func set_plant(texture: Texture2D, new_growth: float, level: int, index: int) -> void:
	flower_texture = texture
	growth = clampf(new_growth, 0.0, 1.0)
	flower_level = maxi(1, level)
	slot_index = index
	queue_redraw()


func get_root_point() -> Vector2:
	var root_ratios = [0.68, 0.7, 0.75, 0.7]
	var ratio = root_ratios[clampi(slot_index, 0, root_ratios.size() - 1)]
	return Vector2(size.x * 0.5, size.y * ratio)


func get_bloom_center() -> Vector2:
	var visible_growth = lerpf(0.32, 1.0, growth)
	var stem_length = minf(size.y * 0.48, 72.0) * visible_growth
	return get_root_point() - Vector2(0, stem_length)


func uses_pot_rim() -> bool:
	return slot_index != 2


func _draw() -> void:
	if flower_texture == null:
		return

	var root = get_root_point()
	var bloom_center = get_bloom_center()
	var visible_growth = lerpf(0.32, 1.0, growth)
	var stem_color = Color(0.18, 0.43, 0.19).lerp(Color(0.28, 0.58, 0.25), growth)

	_draw_soil_contact(root)
	draw_line(root + Vector2(0, 4), bloom_center + Vector2(0, 7), stem_color, 5.0 * visible_growth, true)
	_draw_leaf(root.lerp(bloom_center, 0.38), -1.0, visible_growth, stem_color)
	_draw_leaf(root.lerp(bloom_center, 0.58), 1.0, visible_growth * 0.9, stem_color)

	var level_scale = 1.0 + minf(float(flower_level - 1) * 0.08, 0.24)
	var bloom_size = lerpf(28.0, minf(size.x * 0.58, 70.0), visible_growth) * level_scale
	var bloom_rect = Rect2(bloom_center - Vector2.ONE * bloom_size * 0.5, Vector2.ONE * bloom_size)
	draw_texture_rect(flower_texture, bloom_rect, false, Color(0.78, 0.84, 0.72) if growth < 1.0 else Color.WHITE)

	if uses_pot_rim():
		_draw_front_pot_rim(root)


func _draw_soil_contact(root: Vector2) -> void:
	draw_set_transform(root + Vector2(0, 4), 0.0, Vector2(1.7, 0.42))
	draw_circle(Vector2.ZERO, 15.0, Color(0.16, 0.09, 0.045, 0.78))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_front_pot_rim(root: Vector2) -> void:
	var rim_color = Color(0.42, 0.2, 0.1, 0.9) if slot_index != 1 else Color(0.16, 0.28, 0.38, 0.92)
	var rim_highlight = Color(0.86, 0.6, 0.38, 0.9) if slot_index != 1 else Color(0.48, 0.68, 0.78, 0.92)
	draw_set_transform(root + Vector2(0, 3), 0.0, Vector2(1.7, 0.42))
	draw_arc(Vector2.ZERO, 15.0, 0.0, PI, 28, rim_color, 8.0, true)
	draw_arc(Vector2.ZERO, 15.0, 0.0, PI, 28, rim_highlight, 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_leaf(origin: Vector2, direction: float, scale_factor: float, color: Color) -> void:
	var points = PackedVector2Array([
		origin,
		origin + Vector2(18.0 * direction, -7.0) * scale_factor,
		origin + Vector2(24.0 * direction, 2.0) * scale_factor,
		origin + Vector2(9.0 * direction, 7.0) * scale_factor
	])
	draw_colored_polygon(points, color)
