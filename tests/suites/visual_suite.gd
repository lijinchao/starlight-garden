## Visual asset suite
extends "res://tests/suites/test_suite.gd"


func test_visual_asset_integration() -> void:
	var bgm = SoundGenerator.generate_bgm_loop() as AudioStreamWAV
	assert_true(bgm != null, "柔和花园背景音乐可生成")
	assert_true(bgm.stereo, "背景音乐使用立体声柔化声场")
	assert_equal(bgm.mix_rate, 22050, "背景音乐使用适合环境音垫的采样率")
	assert_equal(bgm.loop_mode, AudioStreamWAV.LOOP_FORWARD, "背景音乐启用无缝正向循环")
	var frame_count = bgm.data.size() / 4
	assert_true(abs(float(frame_count) / bgm.mix_rate - 12.0) < 0.01, "背景音乐循环长度为12秒")
	var peak = 0
	# 固定间隔覆盖整段波形，避免测试为峰值检查逐样本解码 50 余万次。
	for offset in range(0, bgm.data.size(), 128):
		peak = maxi(peak, absi(bgm.data.decode_s16(offset)))
	assert_true(peak > 300, "背景音乐包含可听见的有效波形")
	assert_true(peak < 6000, "背景音乐限制峰值避免刺耳和削波")
	assert_true(abs(bgm.data.decode_s16(bgm.data.size() - 4) - bgm.data.decode_s16(0)) < 700, "背景音乐左声道首尾平滑衔接")
	assert_true(abs(bgm.data.decode_s16(bgm.data.size() - 2) - bgm.data.decode_s16(2)) < 700, "背景音乐右声道首尾平滑衔接")
	var runtime_bgm = AudioManager.sound_cache.get("bgm") as AudioStreamWAV
	assert_true(runtime_bgm != null, "运行时加载柔和背景音乐素材")
	assert_equal(runtime_bgm.loop_mode, AudioStreamWAV.LOOP_FORWARD, "运行时背景音乐持续循环")
	assert_equal(runtime_bgm.mix_rate, 22050, "运行时背景音乐保持低负载采样率")

	var early_background = VisualAssetCatalogScript.get_game_background(1)
	var regular_background = VisualAssetCatalogScript.get_game_background(4)
	assert_true(early_background != null, "前3关局内背景素材可加载")
	assert_true(regular_background != null, "通用局内背景素材可加载")
	assert_not_equal(early_background.resource_path, regular_background.resource_path, "前期与通用局内背景使用不同素材")
	for stage in range(1, 4):
		assert_true(VisualAssetCatalogScript.get_garden_background(stage) != null, "花园阶段%d背景素材可加载" % stage)

	for tile_type in Constants.TILE_NAMES.keys():
		var tile_texture = VisualAssetCatalogScript.get_tile_texture(tile_type)
		assert_true(tile_texture != null, "%s 棋子素材可加载" % Constants.TILE_NAMES[tile_type])
		assert_true(tile_texture.get_width() > Constants.TILE_SIZE, "%s 棋子素材支持清晰缩放" % Constants.TILE_NAMES[tile_type])

	for decoration_id in VisualAssetCatalogScript.DECORATION_TEXTURE_PATHS:
		var decoration_texture = VisualAssetCatalogScript.get_decoration_texture(decoration_id)
		assert_true(decoration_texture != null, "%s 装饰素材可加载" % decoration_id)
		assert_true(decoration_texture.get_width() >= 512, "%s 装饰素材支持清晰缩放" % decoration_id)

	var tile = Tile.new()
	tile.initialize(Constants.TileType.RED_ROSE, Vector2i.ZERO)
	assert_equal(tile.sprite.texture.resource_path, VisualAssetCatalogScript.TILE_TEXTURE_PATHS[Constants.TileType.RED_ROSE], "棋子优先使用本地PNG")
	assert_true(not tile.label.visible, "使用图形素材后隐藏重复花名标签")
	tile.free()

	var board_visual = BoardVisual.new()
	add_child(board_visual)
	board_visual.show_awakening_animation([Vector2i(0, 0), Vector2i(0, 1)], "左侧花圃")
	assert_true(board_visual.has_node("BreezeTrail"), "清风唤醒创建轨迹特效")
	assert_true(board_visual.has_node("BreezeBurst"), "清风唤醒创建闪光特效")
	board_visual.free()
