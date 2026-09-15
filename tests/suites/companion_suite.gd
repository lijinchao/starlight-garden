## Companion suite - 迭代 O A-real 照料对象（有需要 / 有自主 / 有取舍）
extends "res://tests/suites/test_suite.gd"


func test_companion_care() -> void:
	SaveManager.reset_save()

	assert_equal(CompanionService.get_stage(), 0, "初始照料对象处于沉睡阶段")
	assert_equal(CompanionService.get_affinity(), 0, "初始累计照料为 0")
	var request = CompanionService.get_current_request()
	assert_true(not str(request.get("key", "")).is_empty(), "初始就有一个具体请求")
	assert_true(str(request.get("text", "")).contains("小星"), "请求用名字表达")

	var light_result = CompanionService.feed_matches({Constants.TileType.YELLOW_SUNFLOWER: 10})
	assert_true(light_result.get("gains", {}).has("light"), "黄色花对应光的需要")
	assert_equal(int(light_result.get("gains", {}).get("light", 0)), 10, "喂食量等于消除数量")
	assert_equal(SaveManager.get_companion_data().get("affinity", 0), 10, "照料状态写入存档")
	assert_true(str(light_result.get("reaction", "")).contains("小星"), "照料对象用名字回应")

	var needs_before = CompanionService.get_needs()
	var request_key = str(CompanionService.get_current_request().get("key", "light"))
	var tile_for_request = Constants.TileType.YELLOW_SUNFLOWER
	if request_key == "water":
		tile_for_request = Constants.TileType.BLUE_FORGET_ME_NOT
	elif request_key == "company":
		tile_for_request = Constants.TileType.RED_ROSE
	var satisfied_result = CompanionService.feed_matches({tile_for_request: 5})
	assert_true(satisfied_result.get("satisfied_request", false), "喂到请求的颜色会被识别为满足")
	assert_true(
		int(satisfied_result.get("needs", {}).get(request_key, 0)) > int(needs_before.get(request_key, 0)),
		"对应需要上升"
	)

	CompanionService.feed_matches({Constants.TileType.RED_ROSE: 300})
	assert_equal(CompanionService.get_stage(), CompanionService.STAGE_NAMES.size() - 1, "持续照料推进到最高阶段")

	# 时间推移：注入时间后需要下降，但保留下限
	var now = 1800000000
	SaveManager.reset_save()
	CompanionService.feed_matches({Constants.TileType.YELLOW_SUNFLOWER: 5}, now)
	var decay = CompanionService.apply_offline_decay(now + 3600)
	assert_equal(int(decay.get("elapsed_seconds", 0)), 3600, "按真实时间计算离开时长")
	assert_true(int(decay.get("decayed", {}).get("light", 0)) > 0, "离开后对应需要下降")
	assert_true(int(CompanionService.get_needs().get("light", 0)) >= 10, "需要下降但保留下限")

	# 回访观察：离开超过阈值才生成
	SaveManager.reset_save()
	CompanionService.feed_matches({Constants.TileType.YELLOW_SUNFLOWER: 5}, now)
	assert_true(CompanionService.build_away_report_for(now + 60).is_empty(), "短暂离开不生成回访观察")
	var away_report = CompanionService.build_away_report_for(now + 3600)
	assert_true(away_report.contains("你不在的时候"), "离开超过阈值生成回访观察")
	assert_true(away_report.contains("小星"), "回访观察指认照料对象")

	# 旧存档迁移：N 版的 companion 段没有 needs 字段
	var legacy = SaveManager.get_companion_data()
	legacy.erase("needs")
	SaveManager.update_companion_data(legacy)
	var migrated = SaveManager.get_companion_data()
	assert_true(migrated.get("needs", {}).has("light"), "旧照料存档自动补齐需要字段")
	assert_equal(CompanionService.get_needs().size(), 3, "补齐后有三个需要")

	CompanionService.reset()
	assert_equal(CompanionService.get_affinity(), 0, "重置后回到初始状态")
	SaveManager.reset_save()

	var controller = SimpleGameController.new()
	add_child(controller)
	controller._start_level(1)
	assert_true(controller.companion_panel == null, "迭代 P：照料对象面板已移出局内")
	controller.free()
	SaveManager.reset_save()
