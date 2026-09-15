## Settlement suite
extends "res://tests/suites/test_suite.gd"


func test_settlement_service() -> void:
	SaveManager.reset_save()

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(2)
	level_system.apply_breeze_awakening(1)

	var victory = SettlementService.build_victory_settlement(
		2,
		3,
		180,
		level_system.level_config,
		{"theme_progress": level_system.get_theme_progress_snapshot()}
	)
	assert_true(victory.get("is_first_clear", false), "首次通关时应识别首通奖励")
	SettlementService.apply_victory_settlement(victory)

	var player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("total_score", 0), 180, "胜利结算会写入分数")
	assert_equal(player_data.get("total_runs", 0), 1, "胜利结算会累计总局数")
	assert_true(player_data.get("cleared_levels", []).has(2), "胜利结算会记录已通关关卡")
	assert_equal(player_data.get("stars", 0), 50, "胜利结算会发放基础星光和首通奖励")
	assert_equal(SaveManager.get_garden_data().get("restoration_stage", -1), 1, "首局胜利后花园恢复阶段推进到1")
	assert_true(
		"\n".join(SettlementService.format_primary_rewards_summary(victory)).contains("花园恢复"),
		"前三局胜利结算首层摘要包含花园恢复反馈"
	)
	assert_true(
		"\n".join(SettlementService.format_primary_rewards_summary(victory)).contains("清风唤醒了"),
		"前三局胜利结算首层摘要包含局内清风唤醒反馈"
	)
	assert_true(
		SettlementService.format_emotional_reply(victory).contains("露台花藤"),
		"胜利结算的情绪回应绑定本局照料目标"
	)
	assert_equal(
		SettlementService.format_primary_rewards_summary(victory)[0],
		SettlementService.format_emotional_reply(victory),
		"情绪回应作为结算首层第一句"
	)

	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "胜利结算会发放花种")
	assert_equal(garden.get("inventory", [])[0].get("amount", 0), 2, "首通奖励会增加花种数量")
	assert_equal(garden.get("inventory", [])[0].get("type", 0), 2, "结算奖励会读取关卡配置中的seed_type")

	var repeat_victory = SettlementService.build_victory_settlement(2, 3, 200, level_system.level_config)
	assert_true(not repeat_victory.get("is_first_clear", true), "重复通关不应再次判定为首通")

	level_system.moves_left = 0
	level_system._fail_level()
	level_system.collected_tiles.clear()
	var failure = SettlementService.build_failure_settlement(
		level_system,
		10,
		{"theme_progress": level_system.get_theme_progress_snapshot()}
	)
	SettlementService.apply_failure_settlement(failure)
	player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("failure_streak", 0), 1, "失败结算会累计失败次数")
	assert_equal(player_data.get("total_runs", 0), 2, "失败结算会累计总局数")
	assert_equal(player_data.get("stars", 0), 54, "失败结算会发放保底星光")
	assert_equal(SaveManager.get_garden_data().get("restoration_stage", -1), 2, "第二局失败后花园恢复阶段推进到2")
	assert_true(
		SettlementService.format_emotional_reply(failure).contains("露台花藤"),
		"失败结算同样回应本局照料目标"
	)

	assert_true(SettlementService.try_continue_level(level_system, 10, 5), "星光足够时可继续挑战")
	player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("stars", 0), 44, "继续挑战会扣除星光")

	level_system.moves_left = 0
	level_system._fail_level()
	var second_failure = SettlementService.build_failure_settlement(level_system, 10)
	assert_true(second_failure.get("encouragement_triggered", false), "连续失败达到阈值会触发鼓励奖励")
	SettlementService.apply_failure_settlement(second_failure)
	player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("failure_streak", 0), 2, "连续失败次数会继续累计")
	assert_equal(player_data.get("stars", 0), 54, "连续失败鼓励会额外增加星光")
	assert_equal(SaveManager.get_garden_data().get("restoration_stage", -1), 3, "第三局后花园恢复阶段推进到3")
	var garden_after_failure = SaveManager.get_garden_data()
	assert_true(garden_after_failure.get("inventory", []).size() >= 1, "连续失败鼓励会发放花种")

	level_system.free()
	SaveManager.reset_save()
