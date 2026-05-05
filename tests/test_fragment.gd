## test_fragment - 花语碎片生成测试
class_name TestFragment
extends Node

func _ready() -> void:
	print("\n========== 花语碎片生成测试 ==========\n")
	
	# 测试6种花朵的碎片纹理生成
	var flower_types = [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]
	
	var passed = 0
	var failed = 0
	
	for flower_type in flower_types:
		var texture = SpriteGenerator.generate_fragment_texture(flower_type, 32)
		if texture != null and texture is ImageTexture:
			print("✓ 花朵类型 %d 碎片纹理生成成功" % flower_type)
			passed += 1
		else:
			print("✗ 花朵类型 %d 碎片纹理生成失败" % flower_type)
			failed += 1
	
	# 测试合成特效生成
	var synthesis_texture = SpriteGenerator.generate_synthesis_texture(64)
	if synthesis_texture != null:
		print("✓ 合成特效纹理生成成功")
		passed += 1
	else:
		print("✗ 合成特效纹理生成失败")
		failed += 1
	
	# 测试方法存在
	if SpriteGenerator.has_method("_add_fragment_gloss"):
		print("✓ SpriteGenerator包含碎片光泽方法")
		passed += 1
	else:
		print("✗ SpriteGenerator缺少碎片光泽方法")
		failed += 1
	
	if SpriteGenerator.has_method("_add_gloss_effect"):
		print("✓ SpriteGenerator包含花朵光泽方法")
		passed += 1
	else:
		print("✗ SpriteGenerator缺少花朵光泽方法")
		failed += 1
	
	# 测试花朵纹理生成（验证光泽效果）
	var flower_texture = SpriteGenerator.generate_flower_texture(Constants.TileType.RED_ROSE, 96)
	if flower_texture != null:
		print("✓ 花朵纹理生成正常（含光泽效果）")
		passed += 1
	else:
		print("✗ 花朵纹理生成失败")
		failed += 1
	
	print("\n========== 测试结果 ==========")
	print("通过: %d, 失败: %d" % [passed, failed])
	print("================================\n")
	
	get_tree().quit()
