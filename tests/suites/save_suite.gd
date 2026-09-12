## Save suite
extends "res://tests/suites/test_suite.gd"


func test_save_manager() -> void:
	SaveManager.reset_save()

	var garden = SaveManager.get_garden_data()
	assert_true(garden.has("slots"), "花园数据包含slots")
	assert_true(garden.has("inventory"), "花园数据包含inventory")
	assert_true(garden.has("decorations"), "花园数据包含decorations")
	assert_true(garden.has("restoration_stage"), "花园数据包含restoration_stage")
	assert_equal(garden.get("slots", []).size(), 0, "默认花园槽位为空")

	var player = SaveManager.get_player_data()
	assert_true(player.has("cleared_levels"), "玩家数据包含cleared_levels")
	assert_true(player.has("failure_streak"), "玩家数据包含failure_streak")
	assert_true(player.has("total_runs"), "玩家数据包含total_runs")

	SaveManager.update_garden_data({
		"slots": [{"type": Constants.TileType.RED_ROSE, "level": 1}],
		"decorations": [{"id": "bench"}]
	})
	garden = SaveManager.get_garden_data()
	assert_equal(garden.get("slots", []).size(), 1, "花园槽位更新成功")
	assert_equal(garden.get("inventory", []).size(), 0, "缺省inventory自动补齐")

	var legacy_save = SaveManager.DEFAULT_DATA.duplicate(true)
	legacy_save["garden"] = {
		"flowers": [{"type": Constants.TileType.BLUE_FORGET_ME_NOT, "level": 2}],
		"decorations": []
	}
	SaveManager.save_data = legacy_save
	garden = SaveManager.get_garden_data()
	assert_equal(garden.get("slots", []).size(), 1, "旧flowers字段已迁移到slots")
	assert_true(not garden.has("flowers"), "标准化后的花园数据不再暴露flowers字段")

	legacy_save = SaveManager.DEFAULT_DATA.duplicate(true)
	legacy_save.erase("meta_progression")
	legacy_save["player"]["total_runs"] = 3
	legacy_save["flower_language"]["fragments"] = {str(Constants.TileType.RED_ROSE): 1}
	SaveManager.save_data = SaveManager._normalize_save_data(legacy_save)
	var migrated_meta = SaveManager.get_meta_progression_data()
	assert_true(migrated_meta.get("unlocked", []).has(MetaUnlockService.FEATURE_SYNTHESIS), "旧版3局后存档保留合成入口")
	assert_true(migrated_meta.get("unlocked", []).has(MetaUnlockService.FEATURE_DAILY_GIFT), "旧版3局后存档保留花礼入口")
	assert_true(migrated_meta.get("unlocked", []).has(MetaUnlockService.FEATURE_FLOWER_JOURNAL), "旧版已有碎片存档保留花语入口")
	assert_equal(migrated_meta.get("active_prompt", ""), "", "旧版已见功能不会重新触发首次提示")

	SaveManager.reset_save()
