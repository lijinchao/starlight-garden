## SpriteGenerator - 程序化精灵生成器
class_name SpriteGenerator
extends Node

# ==================== 花朵纹理生成 ====================
# 生成花朵纹理
static func generate_flower_texture(tile_type: int, size: int = 96) -> ImageTexture:
	var color = Constants.TILE_COLORS.get(tile_type, Color.WHITE)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	match tile_type:
		Constants.TileType.RED_ROSE:
			_draw_rose(image, size, color)
		Constants.TileType.BLUE_FORGET_ME_NOT:
			_draw_forget_me_not(image, size, color)
		Constants.TileType.PURPLE_LAVENDER:
			_draw_lavender(image, size, color)
		Constants.TileType.YELLOW_SUNFLOWER:
			_draw_sunflower(image, size, color)
		Constants.TileType.WHITE_JASMINE:
			_draw_jasmine(image, size, color)
		Constants.TileType.PINK_CHERRY:
			_draw_cherry_blossom(image, size, color)
		Constants.TileType.BOMB:
			_draw_bomb(image, size, color)
		Constants.TileType.RAINBOW:
			_draw_rainbow(image, size, color)
		_:
			_draw_circle(image, size, color)
	
	return ImageTexture.create_from_image(image)

# 绘制玫瑰
static func _draw_rose(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	var radius = int(size / 2.0) - 4
	
	# 绘制花瓣（螺旋状）
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		for r in range(int(radius * 0.3), int(radius)):
			var x = int(center.x + cos(rad) * r)
			var y = int(center.y + sin(rad) * r)
			if x >= 0 and x < size and y >= 0 and y < size:
				var alpha = 1.0 - (float(r) / radius) * 0.3
				var petal_color = color.lightened((float(r) / radius) * 0.2)
				petal_color.a = alpha
				image.set_pixel(x, y, petal_color)
	
	# 绘制花蕊
	for x in range(int(center.x - 8), int(center.x + 8)):
		for y in range(int(center.y - 8), int(center.y + 8)):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 8:
				image.set_pixel(x, y, Color(1, 0.8, 0, 1))
	
	# 添加光泽效果（高光）
	_add_gloss_effect(image, center, radius, 0.3)

# 绘制勿忘我
static func _draw_forget_me_not(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制5片花瓣
	for i in range(5):
		var angle = deg_to_rad(i * 72 - 90)
		var petal_center = Vector2(
			center.x + cos(angle) * 15,
			center.y + sin(angle) * 15
		)
		_draw_circle_at(image, petal_center, 18, color)
	
	# 绘制花蕊
	_draw_circle_at(image, center, 10, Color(1, 1, 0, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, center, 20, 0.4)

# 绘制薰衣草
static func _draw_lavender(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制穗状花序
	for i in range(8):
		var y = int(center.y - 30 + i * 8)
		var width = 12 - abs(i - 4) * 2
		for x in range(int(center.x - width), int(center.x + width)):
			if x >= 0 and x < size and y >= 0 and y < size:
				var alpha = 1.0 - abs(i - 4) * 0.15
				var c = color
				c.a = alpha
				image.set_pixel(x, y, c)
	
	# 绘制茎
	for y in range(int(center.y + 10), size - 4):
		image.set_pixel(int(center.x), y, Color(0.3, 0.6, 0.3, 1))
		image.set_pixel(int(center.x) + 1, y, Color(0.3, 0.6, 0.3, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, Vector2(center.x, center.y - 10), 15, 0.5)

# 绘制向日葵
static func _draw_sunflower(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	var radius = int(size / 2.0) - 4
	
	# 绘制花瓣（放射状）
	for angle in range(0, 360, 20):
		var rad = deg_to_rad(angle)
		for r in range(int(radius * 0.4), int(radius)):
			var x = int(center.x + cos(rad) * r)
			var y = int(center.y + sin(rad) * r)
			if x >= 0 and x < size and y >= 0 and y < size:
				var alpha = 1.0 - (float(r) / radius) * 0.2
				var c = color
				c.a = alpha
				image.set_pixel(x, y, c)
	
	# 绘制花盘
	_draw_circle_at(image, center, int(radius * 0.4), Color(0.4, 0.2, 0, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, center, int(radius * 0.6), 0.35)

# 绘制茉莉
static func _draw_jasmine(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制多层花瓣
	for layer in range(3):
		var layer_radius = 30 - layer * 8
		var layer_offset = layer * 15
		for i in range(6):
			var angle = deg_to_rad(i * 60 + layer_offset)
			var petal_center = Vector2(
				center.x + cos(angle) * (layer_radius * 0.5),
				center.y + sin(angle) * (layer_radius * 0.5)
			)
			var c = color.lightened(layer * 0.1)
			_draw_circle_at(image, petal_center, int(layer_radius * 0.6), c)
	
	# 绘制花蕊
	_draw_circle_at(image, center, 8, Color(1, 1, 0.8, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, center, 25, 0.45)

# 绘制樱花
static func _draw_cherry_blossom(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制5片心形花瓣
	for i in range(5):
		var angle = deg_to_rad(i * 72 - 90)
		var petal_center = Vector2(
			center.x + cos(angle) * 18,
			center.y + sin(angle) * 18
		)
		_draw_heart(image, petal_center, 16, color)
	
	# 绘制花蕊
	_draw_circle_at(image, center, 6, Color(1, 0.8, 0, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, center, 20, 0.5)

# 绘制心形
static func _draw_heart(image: Image, center: Vector2, size: int, color: Color) -> void:
	for x in range(-size, size):
		for y in range(-size, size):
			var px = int(center.x + x)
			var py = int(center.y + y)
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				# 心形方程
				var fx = float(x) / size
				var fy = float(y) / size
				if (fx * fx + fy * fy - 1) * (fx * fx + fy * fy - 1) * (fx * fx + fy * fy - 1) - fx * fx * fy * fy * fy <= 0:
					image.set_pixel(px, py, color)

# 添加光泽效果（高光）
static func _add_gloss_effect(image: Image, center: Vector2, radius: int, intensity: float = 0.3) -> void:
	var size = image.get_width()
	# 在左上角添加椭圆形高光
	var gloss_center = Vector2(center.x - radius * 0.3, center.y - radius * 0.3)
	var gloss_radius_x = radius * 0.4
	var gloss_radius_y = radius * 0.25
	
	for x in range(size):
		for y in range(size):
			var dx = (x - gloss_center.x) / gloss_radius_x
			var dy = (y - gloss_center.y) / gloss_radius_y
			var dist = sqrt(dx * dx + dy * dy)
			
			if dist <= 1.0:
				var alpha = (1.0 - dist) * intensity
				var pixel_color = image.get_pixel(x, y)
				# 添加白色高光
				pixel_color.r = min(1.0, pixel_color.r + alpha)
				pixel_color.g = min(1.0, pixel_color.g + alpha)
				pixel_color.b = min(1.0, pixel_color.b + alpha)
				image.set_pixel(x, y, pixel_color)

# 绘制炸弹
static func _draw_bomb(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制圆形主体
	_draw_circle_at(image, center, 30, color)
	
	# 绘制引线
	for i in range(15):
		var x = int(center.x + i * 1.5)
		var y = int(center.y - 30 - i * 0.8)
		if x < size and y >= 0:
			image.set_pixel(x, y, Color(0.6, 0.4, 0.2, 1))
	
	# 绘制火花
	_draw_circle_at(image, Vector2(center.x + 22, center.y - 42), 8, Color(1, 0.8, 0, 1))
	_draw_circle_at(image, Vector2(center.x + 25, center.y - 45), 5, Color(1, 0.5, 0, 1))
	
	# 添加光泽效果
	_add_gloss_effect(image, center, 30, 0.4)

# 绘制彩虹花
static func _draw_rainbow(image: Image, size: int, _color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	var radius = int(size / 2.0) - 4
	
	# 绘制彩虹色环
	var rainbow_colors = [
		Color(1, 0, 0, 1),      # 红
		Color(1, 0.5, 0, 1),    # 橙
		Color(1, 1, 0, 1),      # 黄
		Color(0, 1, 0, 1),      # 绿
		Color(0, 0.5, 1, 1),    # 蓝
		Color(0.5, 0, 1, 1)     # 紫
	]
	
	for ring in range(6):
		var inner_r = radius * (ring + 1) / 7.0
		var outer_r = radius * (ring + 2) / 7.0
		var ring_color = rainbow_colors[ring]
		
		for x in range(size):
			for y in range(size):
				var dist = Vector2(x, y).distance_to(center)
				if dist >= inner_r and dist < outer_r:
					image.set_pixel(x, y, ring_color)
	
	# 添加光泽效果
	_add_gloss_effect(image, center, radius, 0.25)

# 绘制圆形
static func _draw_circle(image: Image, size: int, color: Color) -> void:
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	var radius = int(size / 2.0) - 4
	_draw_circle_at(image, center, int(radius), color)

# 在指定位置绘制圆形
static func _draw_circle_at(image: Image, center: Vector2, radius: int, color: Color) -> void:
	var size = image.get_width()
	for x in range(int(center.x) - radius, int(center.x) + radius):
		for y in range(int(center.y) - radius, int(center.y) + radius):
			if x >= 0 and x < size and y >= 0 and y < size:
				var dist = Vector2(x, y).distance_to(center)
				if dist <= radius:
					var alpha = 1.0 - (float(dist) / radius) * 0.2
					var c = color
					c.a = alpha
					image.set_pixel(x, y, c)

# ==================== 花语碎片生成 ====================
# 生成花语碎片纹理
static func generate_fragment_texture(flower_type: int, size: int = 32) -> ImageTexture:
	var color = Constants.TILE_COLORS.get(flower_type, Color.WHITE)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	match flower_type:
		Constants.TileType.RED_ROSE:
			_draw_heart_fragment(image, size, color)
		Constants.TileType.BLUE_FORGET_ME_NOT:
			_draw_star_fragment(image, size, color)
		Constants.TileType.PURPLE_LAVENDER:
			_draw_spike_fragment(image, size, color)
		Constants.TileType.YELLOW_SUNFLOWER:
			_draw_ray_fragment(image, size, color)
		Constants.TileType.WHITE_JASMINE:
			_draw_layered_fragment(image, size, color)
		Constants.TileType.PINK_CHERRY:
			_draw_petal_fragment(image, size, color)
		_:
			_draw_circle_fragment(image, size, color)
	
	# 添加碎片光泽
	_add_fragment_gloss(image, size)
	
	return ImageTexture.create_from_image(image)

# 绘制心形碎片（红玫瑰）
static func _draw_heart_fragment(image: Image, size: int, color: Color) -> void:
	_draw_heart(image, Vector2(size/2, size/2), size/2, color)

# 绘制星形碎片（蓝勿忘我）
static func _draw_star_fragment(image: Image, size: int, color: Color) -> void:
	var center = Vector2(size/2, size/2)
	var points = []
	for i in range(10):
		var angle = deg_to_rad(i * 36 - 90)
		var r = size/2 - 4 if i % 2 == 0 else size/4
		points.append(Vector2(center.x + cos(angle) * r, center.y + sin(angle) * r))
	
	for x in range(size):
		for y in range(size):
			if _point_in_polygon(Vector2(x, y), points):
				image.set_pixel(x, y, color)

# 绘制穗状碎片（紫薰衣草）
static func _draw_spike_fragment(image: Image, size: int, color: Color) -> void:
	var center_x = size / 2
	for y in range(size):
		var width = int(size / 3 - abs(y - size/2) * 0.3)
		for x in range(int(center_x - width), int(center_x + width)):
			if x >= 0 and x < size:
				image.set_pixel(x, y, color)

# 绘制放射状碎片（黄向日葵）
static func _draw_ray_fragment(image: Image, size: int, color: Color) -> void:
	var center = Vector2(size/2, size/2)
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		for r in range(size/4, size/2):
			var x = int(center.x + cos(rad) * r)
			var y = int(center.y + sin(rad) * r)
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, color)

# 绘制层叠碎片（白茉莉）
static func _draw_layered_fragment(image: Image, size: int, color: Color) -> void:
	var center = Vector2(size/2, size/2)
	for layer in range(2):
		var r = size/2 - layer * 8
		_draw_circle_at(image, center, r, color.lightened(layer * 0.1))

# 绘制花瓣碎片（粉樱花）
static func _draw_petal_fragment(image: Image, size: int, color: Color) -> void:
	var center = Vector2(size/2, size/2)
	for i in range(4):
		var angle = deg_to_rad(i * 90)
		var petal_center = Vector2(center.x + cos(angle) * 6, center.y + sin(angle) * 6)
		_draw_circle_at(image, petal_center, size/4, color)

# 绘制圆形碎片（默认）
static func _draw_circle_fragment(image: Image, size: int, color: Color) -> void:
	_draw_circle_at(image, Vector2(size/2, size/2), size/2 - 2, color)


static func _add_fragment_gloss(image: Image, size: int) -> void:
	var center = Vector2(size * 0.35, size * 0.30)
	var radius = max(4.0, size * 0.22)

	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist > radius:
				continue

			var alpha = (1.0 - dist / radius) * 0.35
			var pixel_color = image.get_pixel(x, y)
			if pixel_color.a <= 0.0:
				continue

			pixel_color.r = min(1.0, pixel_color.r + alpha)
			pixel_color.g = min(1.0, pixel_color.g + alpha)
			pixel_color.b = min(1.0, pixel_color.b + alpha)
			image.set_pixel(x, y, pixel_color)

# ==================== 合成特效生成 ====================
# 生成合成漩涡纹理
static func generate_synthesis_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)
	
	# 绘制漩涡光效
	for angle in range(0, 360, 5):
		var rad = deg_to_rad(angle)
		for r in range(5, size/2 - 4):
			var x = int(center.x + cos(rad + r * 0.1) * r)
			var y = int(center.y + sin(rad + r * 0.1) * r)
			if x >= 0 and x < size and y >= 0 and y < size:
				var alpha = 1.0 - (float(r) / (size/2))
				var color = Color(1, 1, 0.8, alpha * 0.6)
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

# 计算到角落的距离
static func _corner_distance(x: int, y: int, width: int, height: int, radius: int) -> float:
	var corners = [
		Vector2(radius, radius),
		Vector2(width - radius, radius),
		Vector2(radius, height - radius),
		Vector2(width - radius, height - radius)
	]
	
	var min_dist = INF
	for corner in corners:
		var dist = Vector2(x, y).distance_to(corner)
		min_dist = min(min_dist, dist)
	
	return min_dist

# 生成星星纹理
static func generate_star_texture(size: int = 48, color: Color = Color(1, 0.8, 0, 1)) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(int(size / 2.0), int(size / 2.0))
	
	# 绘制五角星
	var points = []
	for i in range(10):
		var angle = deg_to_rad(i * 36 - 90)
		var r = int(size / 2.0) - 4 if i % 2 == 0 else int(size / 4.0)
		points.append(Vector2(
			center.x + cos(angle) * r,
			center.y + sin(angle) * r
		))
	
	# 填充星星
	for x in range(size):
		for y in range(size):
			if _point_in_polygon(Vector2(x, y), points):
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

# 判断点是否在多边形内
static func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / float(polygon[j].y - polygon[i].y) + polygon[i].x):
			inside = not inside
		j = i
	
	return inside
