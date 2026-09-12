## BoardVisual - 棋盘可视化管理器
class_name BoardVisual
extends Node2D

const AsyncUtilsScript = preload("res://scripts/utils/AsyncUtils.gd")
const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")

# ==================== 信号 ====================
signal tile_clicked(pos: Vector2i)

# ==================== 变量 ====================
var tiles: Dictionary = {}  # {Vector2i: Tile}
var garden_layer_markers: Dictionary = {}
var dew_bud_markers: Dictionary = {}
var click_control: Control
var last_clicked_pos: Vector2i = Vector2i(-1, -1)
var transient_tweens: Array[Tween] = []

# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_click_area()


func _exit_tree() -> void:
	for tween in transient_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	transient_tweens.clear()
	clear_all_tiles()
	clear_garden_layers()
	if click_control and is_instance_valid(click_control):
		click_control.queue_free()
		click_control = null

func _setup_click_area() -> void:
	# 使用覆盖整个棋盘的 Control 来稳定接收点击，避免被上层 Control 吃掉事件
	click_control = Control.new()
	var board_size = Constants.GRID_COLS * (Constants.TILE_SIZE + Constants.TILE_GAP)
	click_control.custom_minimum_size = Vector2(board_size, board_size)
	click_control.size = Vector2(board_size, board_size)
	click_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(click_control)


func _emit_click_at_position(local_pos: Vector2) -> void:
	if not _is_inside_board(local_pos):
		return

	var grid_pos = _world_to_grid(local_pos)
	if tiles.has(grid_pos):
		last_clicked_pos = grid_pos
		tile_clicked.emit(grid_pos)

# ==================== 初始化 ====================
func initialize_grid(grid: Array) -> void:
	clear_all_tiles()
	clear_garden_layers()
	
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var tile_type = grid[row][col]
			if tile_type != Constants.TileType.NONE:
				var pos = Vector2i(row, col)
				_create_tile(tile_type, pos)


func initialize_garden_layers(positions: Array, dew_bud_positions: Array = []) -> void:
	clear_garden_layers()
	for pos in positions:
		var marker = Label.new()
		marker.name = "FallenLeaves_%d_%d" % [pos.x, pos.y]
		marker.text = "🍂"
		marker.position = _grid_to_world(pos) + Vector2(18, 14)
		marker.size = Vector2(64, 64)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_theme_font_size_override("font_size", 44)
		marker.add_theme_color_override("font_shadow_color", Color(0.18, 0.1, 0.04, 0.72))
		marker.add_theme_constant_override("shadow_offset_x", 2)
		marker.add_theme_constant_override("shadow_offset_y", 3)
		marker.z_index = 18
		add_child(marker)
		garden_layer_markers[pos] = marker
	for pos in dew_bud_positions:
		if not garden_layer_markers.has(pos):
			continue
		var bud_marker = Label.new()
		bud_marker.name = "DewBud_%d_%d" % [pos.x, pos.y]
		bud_marker.text = "💧"
		bud_marker.position = _grid_to_world(pos) + Vector2(25, 17)
		bud_marker.size = Vector2(46, 46)
		bud_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bud_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bud_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bud_marker.add_theme_font_size_override("font_size", 34)
		bud_marker.add_theme_color_override("font_color", Color(0.76, 1.0, 0.96, 1.0))
		bud_marker.add_theme_color_override("font_outline_color", Color(0.06, 0.34, 0.25, 0.96))
		bud_marker.add_theme_constant_override("outline_size", 4)
		bud_marker.add_theme_color_override("font_shadow_color", Color(0.02, 0.16, 0.1, 0.9))
		bud_marker.add_theme_constant_override("shadow_offset_x", 2)
		bud_marker.add_theme_constant_override("shadow_offset_y", 3)
		bud_marker.z_index = 19
		add_child(bud_marker)
		dew_bud_markers[pos] = bud_marker

func _create_tile(tile_type: int, pos: Vector2i, with_animation: bool = false) -> Tile:
	var tile = Tile.new()
	tile.initialize(tile_type, pos)
	tile.position = _grid_to_world(pos)
	add_child(tile)
	tiles[pos] = tile
	
	if with_animation:
		tile.play_spawn_animation()
	
	return tile

# ==================== 坐标转换 ====================
# 注意：使用 Vector2i(row, col) 格式，其中 row 是行索引，col 是列索引
func _grid_to_world(pos: Vector2i) -> Vector2:
	# pos.x 是行索引（垂直方向），pos.y 是列索引（水平方向）
	var x = pos.y * (Constants.TILE_SIZE + Constants.TILE_GAP)
	var y = pos.x * (Constants.TILE_SIZE + Constants.TILE_GAP)
	return Vector2(x, y)

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# 从世界坐标转换为网格坐标
	var col = int(world_pos.x / (Constants.TILE_SIZE + Constants.TILE_GAP))
	var row = int(world_pos.y / (Constants.TILE_SIZE + Constants.TILE_GAP))
	return Vector2i(row, col)


func _is_inside_board(local_pos: Vector2) -> bool:
	var board_size = Constants.GRID_COLS * (Constants.TILE_SIZE + Constants.TILE_GAP)
	return local_pos.x >= 0 and local_pos.y >= 0 and \
		local_pos.x < board_size and local_pos.y < board_size

# ==================== 视觉更新 ====================
func update_tile_position(old_pos: Vector2i, new_pos: Vector2i) -> void:
	if not tiles.has(old_pos) and not tiles.has(new_pos):
		return

	if tiles.has(old_pos) and tiles.has(new_pos):
		var old_tile = tiles[old_pos]
		var new_tile = tiles[new_pos]
		tiles[old_pos] = new_tile
		tiles[new_pos] = old_tile

		old_tile.set_grid_position(new_pos)
		new_tile.set_grid_position(old_pos)
		old_tile.play_swap_animation(_grid_to_world(new_pos))
		new_tile.play_swap_animation(_grid_to_world(old_pos))
		return

	if tiles.has(old_pos):
		var tile = tiles[old_pos]
		tiles.erase(old_pos)
		tiles[new_pos] = tile
		tile.set_grid_position(new_pos)
		tile.play_swap_animation(_grid_to_world(new_pos))
		return

	var reverse_tile = tiles[new_pos]
	tiles.erase(new_pos)
	tiles[old_pos] = reverse_tile
	reverse_tile.set_grid_position(old_pos)
	reverse_tile.play_swap_animation(_grid_to_world(old_pos))

func show_match_animation(positions: Array) -> void:
	for pos in positions:
		if tiles.has(pos):
			var tile = tiles[pos]
			tile.play_match_animation()
			tiles.erase(pos)
	# 等待匹配动画完成
	await AsyncUtilsScript.create_delay_tween(self, Constants.MATCH_DURATION).finished

func show_fall_animation(movements: Array) -> void:
	# movements: [{from: Vector2i, to: Vector2i, delay: float}]
	var max_duration = 0.0
	
	for movement in movements:
		var from_pos = movement["from"]
		var to_pos = movement["to"]
		var delay = movement.get("delay", 0.0)
		
		if tiles.has(from_pos):
			var tile = tiles[from_pos]
			tiles.erase(from_pos)
			tiles[to_pos] = tile
			tile.set_grid_position(to_pos)
			tile.play_fall_animation(_grid_to_world(to_pos), delay)
			
			var duration = delay + Constants.FALL_DURATION
			if duration > max_duration:
				max_duration = duration
	
	if max_duration > 0:
		await AsyncUtilsScript.create_delay_tween(self, max_duration).finished

func show_new_tiles(new_tiles: Array) -> void:
	# new_tiles: [{pos: Vector2i, type: int, delay: float}]
	for tile_data in new_tiles:
		var pos = tile_data["pos"]
		var type = tile_data["type"]
		var delay = tile_data.get("delay", 0.0)
		
		if delay > 0:
			await AsyncUtilsScript.create_delay_tween(self, delay).finished
		
		if not tiles.has(pos):
			_create_tile(type, pos, true)  # 启用生成动画

func sync_with_grid(grid: Array) -> void:
	var valid_positions := {}

	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var pos = Vector2i(row, col)
			var tile_type = grid[row][col]
			if tile_type == Constants.TileType.NONE:
				continue

			valid_positions[pos] = true
			if not tiles.has(pos):
				_create_tile(tile_type, pos)
				continue

			var tile = tiles[pos]
			if tile.get_tile_type() != tile_type:
				if is_instance_valid(tile):
					tile.queue_free()
				tiles.erase(pos)
				_create_tile(tile_type, pos)
			else:
				tile.set_grid_position(pos)
				tile.position = _grid_to_world(pos)

	for pos in tiles.keys():
		if not valid_positions.has(pos):
			clear_tile(pos)


func show_reshuffle_animation(grid: Array) -> void:
	var fade_out = create_tween()
	transient_tweens.append(fade_out)
	fade_out.tween_property(self, "modulate:a", 0.0, 0.16)
	await fade_out.finished
	_remove_transient_tween(fade_out)

	sync_with_grid(grid)

	var fade_in = create_tween()
	transient_tweens.append(fade_in)
	fade_in.tween_property(self, "modulate:a", 1.0, 0.22)
	await fade_in.finished
	_remove_transient_tween(fade_in)

func highlight_tile(pos: Vector2i, highlight: bool) -> void:
	if tiles.has(pos):
		var tile = tiles[pos]
		if highlight:
			tile.select()
		else:
			tile.deselect()

func show_hint(pos1: Vector2i, pos2: Vector2i) -> void:
	if tiles.has(pos1):
		tiles[pos1].play_hint_animation()
	if tiles.has(pos2):
		tiles[pos2].play_hint_animation()


func show_awakening_animation(positions: Array, focus_name: String, caption: String = "清风唤醒") -> void:
	if positions.is_empty():
		return

	var center = Vector2.ZERO
	for pos in positions:
		center += _grid_to_world(pos) + Vector2(Constants.TILE_SIZE / 2.0, Constants.TILE_SIZE / 2.0)
	center /= float(positions.size())

	var trail = _create_awakening_sprite(
		VisualAssetCatalogScript.get_breeze_trail_texture(),
		"BreezeTrail",
		center,
		320.0
	)
	var burst = _create_awakening_sprite(
		VisualAssetCatalogScript.get_breeze_burst_texture(),
		"BreezeBurst",
		center,
		180.0
	)

	var label = Label.new()
	label.text = "%s\n%s" % [caption, focus_name]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.modulate = Color(1.0, 0.92, 0.58, 0.0)
	label.position = center + Vector2(-90, -40)
	add_child(label)

	var tween = create_tween()
	transient_tweens.append(tween)
	if trail:
		var trail_scale = trail.scale
		trail.scale *= 0.72
		trail.rotation = -0.08
		tween.tween_property(trail, "modulate:a", 0.95, 0.12)
		tween.parallel().tween_property(trail, "scale", trail_scale, 0.28).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(trail, "rotation", 0.04, 0.32)
	else:
		tween.tween_interval(0.12)
	if burst:
		var burst_scale = burst.scale
		burst.scale *= 0.45
		tween.parallel().tween_property(burst, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(burst, "scale", burst_scale, 0.24).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "position:y", label.position.y - 20.0, 0.2)
	tween.tween_interval(0.3)
	if trail:
		tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.2)
	if burst:
		tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
		if trail and is_instance_valid(trail):
			trail.queue_free()
		if burst and is_instance_valid(burst):
			burst.queue_free()
	)
	tween.finished.connect(_remove_transient_tween.bind(tween))


func show_garden_layer_clear(cleared_positions: Array, paths: Array, dew_bursts: Array = []) -> void:
	for path in paths:
		var trail = Line2D.new()
		trail.name = "BreezePath"
		trail.width = 26.0
		trail.default_color = Color(0.76, 1.0, 0.84, 0.78)
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		trail.z_index = 30
		var index = int(path.get("index", 0))
		var cell_span = Constants.TILE_SIZE + Constants.TILE_GAP
		var board_span = Constants.GRID_COLS * cell_span
		var direction_label = Label.new()
		direction_label.name = "BreezePathLabel"
		direction_label.text = "清风  →" if path.get("direction") == "horizontal" else "清风  ↓"
		direction_label.add_theme_font_size_override("font_size", 22)
		direction_label.add_theme_color_override("font_color", Color(0.96, 1.0, 0.82))
		direction_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.28, 0.18, 0.9))
		direction_label.add_theme_constant_override("shadow_offset_x", 2)
		direction_label.add_theme_constant_override("shadow_offset_y", 2)
		direction_label.z_index = 31
		if path.get("direction") == "horizontal":
			var y = index * cell_span + Constants.TILE_SIZE / 2.0
			trail.add_point(Vector2(0, y))
			trail.add_point(Vector2(board_span, y))
			direction_label.position = Vector2(18, y - 38)
		else:
			var x = index * cell_span + Constants.TILE_SIZE / 2.0
			trail.add_point(Vector2(x, 0))
			trail.add_point(Vector2(x, board_span))
			direction_label.position = Vector2(x + 12, 18)
		add_child(trail)
		add_child(direction_label)
		var trail_tween = create_tween()
		transient_tweens.append(trail_tween)
		trail.scale = Vector2(0.2, 1.0) if path.get("direction") == "horizontal" else Vector2(1.0, 0.2)
		trail_tween.tween_property(trail, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)
		if path.get("direction") == "horizontal":
			trail_tween.parallel().tween_property(direction_label, "position:x", board_span - 118, 0.34)
		else:
			trail_tween.parallel().tween_property(direction_label, "position:y", board_span - 58, 0.34)
		trail_tween.tween_property(trail, "modulate:a", 0.0, 0.24)
		trail_tween.parallel().tween_property(direction_label, "modulate:a", 0.0, 0.24)
		trail_tween.tween_callback(trail.queue_free)
		trail_tween.tween_callback(direction_label.queue_free)
		trail_tween.finished.connect(_remove_transient_tween.bind(trail_tween))

	for pos in cleared_positions:
		if dew_bud_markers.has(pos):
			var bud_marker = dew_bud_markers[pos]
			dew_bud_markers.erase(pos)
			if is_instance_valid(bud_marker):
				bud_marker.queue_free()
		if not garden_layer_markers.has(pos):
			continue
		var marker = garden_layer_markers[pos]
		garden_layer_markers.erase(pos)
		var marker_tween = create_tween()
		transient_tweens.append(marker_tween)
		marker_tween.tween_property(marker, "position:y", marker.position.y - 24.0, 0.2)
		marker_tween.parallel().tween_property(marker, "scale", Vector2(1.35, 1.35), 0.2)
		marker_tween.parallel().tween_property(marker, "modulate:a", 0.0, 0.25)
		marker_tween.tween_callback(marker.queue_free)
		marker_tween.finished.connect(_remove_transient_tween.bind(marker_tween))

	for burst in dew_bursts:
		await _show_dew_bud_burst(burst)

	if not cleared_positions.is_empty() or not paths.is_empty() or not dew_bursts.is_empty():
		await AsyncUtilsScript.create_delay_tween(self, 0.3).finished


func _show_dew_bud_burst(burst: Dictionary) -> void:
	var pos: Vector2i = burst.get("position", Vector2i(-1, -1))
	if pos.x < 0 or pos.y < 0:
		return
	var center = _grid_to_world(pos) + Vector2(Constants.TILE_SIZE * 0.5, Constants.TILE_SIZE * 0.5)
	var ring = Line2D.new()
	ring.name = "DewBudBurst"
	ring.width = 8.0
	ring.default_color = Color(0.7, 1.0, 0.86, 0.9)
	ring.z_index = 32
	for point_index in range(13):
		var angle = TAU * float(point_index) / 12.0
		ring.add_point(center + Vector2(cos(angle), sin(angle)) * 20.0)
	add_child(ring)

	var caption = Label.new()
	caption.name = "DewBudCaption"
	caption.text = "晨露连锁 x%d" % int(burst.get("chain_index", 1))
	caption.position = center + Vector2(-78, -46)
	caption.size = Vector2(156, 32)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color(0.9, 1.0, 0.78))
	caption.add_theme_color_override("font_shadow_color", Color(0.08, 0.28, 0.16, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.modulate.a = 0.0
	caption.z_index = 33
	add_child(caption)

	var tween = create_tween()
	transient_tweens.append(tween)
	ring.scale = Vector2(0.35, 0.35)
	tween.tween_property(ring, "scale", Vector2(2.0, 2.0), 0.14).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.parallel().tween_property(caption, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(caption, "position:y", caption.position.y - 16.0, 0.2)
	tween.tween_property(caption, "modulate:a", 0.0, 0.12)
	tween.tween_callback(ring.queue_free)
	tween.tween_callback(caption.queue_free)
	await tween.finished
	_remove_transient_tween(tween)


func _create_awakening_sprite(texture: Texture2D, node_name: String, center: Vector2, target_width: float) -> Sprite2D:
	if texture == null or texture.get_width() <= 0:
		return null
	var effect = Sprite2D.new()
	effect.name = node_name
	effect.texture = texture
	effect.position = center
	effect.z_index = 40
	effect.modulate.a = 0.0
	var uniform_scale = target_width / float(texture.get_width())
	effect.scale = Vector2.ONE * uniform_scale
	add_child(effect)
	return effect

# ==================== 清理 ====================
func clear_all_tiles() -> void:
	for tile in tiles.values():
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()


func clear_garden_layers() -> void:
	for marker in garden_layer_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	garden_layer_markers.clear()
	for marker in dew_bud_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	dew_bud_markers.clear()

func clear_tile(pos: Vector2i) -> void:
	if tiles.has(pos):
		var tile = tiles[pos]
		if is_instance_valid(tile):
			tile.queue_free()
		tiles.erase(pos)

# ==================== 公开方法 ====================
func get_tile_at(pos: Vector2i) -> Tile:
	return tiles.get(pos, null)

func has_tile_at(pos: Vector2i) -> bool:
	return tiles.has(pos)

func get_all_tile_positions() -> Array:
	return tiles.keys()


func _remove_transient_tween(tween: Tween) -> void:
	var index = transient_tweens.find(tween)
	if index >= 0:
		transient_tweens.remove_at(index)
