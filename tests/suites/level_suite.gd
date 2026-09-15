## Level suite
extends "res://tests/suites/test_suite.gd"


func test_level_system() -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)
	
	# 测试关卡配置生成
	var config = level_system.get_level_config(1)
	assert_true(config.has("level_id"), "关卡配置包含level_id")
	assert_true(config.has("moves"), "关卡配置包含moves")
	assert_true(config.has("target"), "关卡配置包含target")
	assert_true(config.has("rewards"), "关卡配置包含rewards")
	assert_true(config["rewards"].has("seed_type"), "奖励配置包含seed_type")
	assert_true(config["rewards"].has("first_clear_bonus"), "奖励配置包含首通奖励")
	assert_true(config["target"].has("theme"), "前期关卡配置包含主题化目标")
	
	# 测试难度递增
	var config_1 = level_system.get_level_config(1)
	var config_10 = level_system.get_level_config(10)
	assert_true(config_1["moves"] >= config_10["moves"], "高关卡步数更少")
	
	# 测试胜利条件检查
	level_system.start_level(1)
	assert_true(not level_system._check_win_condition(), "初始状态未胜利")
	
	# 模拟收集完成
	var requirements = config["target"]["requirements"]
	for req in requirements:
		level_system.collected_tiles[str(int(req["tile_type"]))] = req["count"]
	
	assert_true(level_system._check_win_condition(), "收集完成后胜利")
	assert_true(level_system.get_target_progress_text().contains("唤醒") or level_system.get_target_progress_text().contains("点亮"), "局内目标进度文本采用主题化表达")
	assert_true(level_system.get_target_progress_text().contains("通关："), "局内目标明确说明通关条件")
	assert_true(level_system.get_target_intro_text().contains("即可通过"), "首关提示明确说明如何通过")

	var outcomes = {"won": 0, "failed": 0}
	level_system.level_won.connect(func(_stars: int, _score: int) -> void: outcomes["won"] += 1)
	level_system.level_failed.connect(func() -> void: outcomes["failed"] += 1)
	level_system.start_level(1)
	var requirement = level_system.level_config["target"]["requirements"][0]
	var target_key = str(int(requirement["tile_type"]))
	level_system.collected_tiles[target_key] = int(requirement["count"]) - 2
	level_system.moves_left = 1
	level_system.use_move()
	level_system.apply_breeze_awakening(1)
	level_system.finish_turn()
	assert_equal(outcomes["won"], 1, "最后一步清风完成目标时只结算胜利")
	assert_equal(outcomes["failed"], 0, "最后一步效果完成前不会提前失败")
	
	level_system.free()


func test_single_spatial_goal() -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)

	for level_id in range(6, 9):
		var config = level_system.get_level_config(level_id)
		var target = config.get("target", {})
		var goal_type = str(target.get("type", ""))
		assert_true(goal_type == "clear_blockers" or goal_type == "clear_leaves", "第%d关是单一空间目标" % level_id)
		assert_true((target.get("requirements", []) as Array).is_empty(), "第%d关没有收集要求" % level_id)
		# 步数不再用固定上限判断“紧张”；真正的紧张由 test_levels_require_a_plan 的探针校验。
		assert_true(int(config.get("moves", 0)) <= 24, "第%d关步数设有上限" % level_id)

	level_system.start_level(6)
	assert_true(not level_system._check_win_condition(), "目标未完成时不能通关")
	assert_true(level_system.get_target_progress_text().contains("石块"), "HUD 显示单一目标进度")
	assert_true(not level_system.get_target_progress_text().contains("通关："), "HUD 不再显示收集数字")
	level_system.free()


func test_level_progression() -> void:
	SaveManager.reset_save()
	GameManager.start_level(4)

	var controller = SimpleGameController.new()
	controller.level_system = LevelSystem.new()
	add_child(controller.level_system)
	controller.level_system.start_level(4)
	controller._on_level_won(3, 120)

	var player_data = SaveManager.get_player_data()
	assert_equal(controller.level_system.current_level_id, 4, "当前关卡ID记录正确")
	assert_equal(player_data.get("level", 1), 5, "通关后解锁下一关")
	assert_equal(player_data.get("total_score", 0), 120, "通关分数已写入存档")
	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "通关奖励已进入花园库存")

	controller.level_system.free()
	controller.free()
	SaveManager.reset_save()


func test_garden_corner_growth() -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)

	level_system.start_level(2)
	assert_equal(level_system.garden_corner_stage, 0, "开局花园角落处于第 0 阶段")
	var requirement = level_system.level_config.get("target", {}).get("requirements", [])[0]
	var target_key = str(int(requirement.get("tile_type", 0)))
	var required_count = int(requirement.get("count", 0))
	level_system.collected_tiles[target_key] = int(ceil(required_count / 3.0)) + 1
	var growth = level_system.refresh_garden_corner()
	assert_true(not growth.is_empty(), "有效消除推进会产出可读取的花园角落事件")
	assert_true(int(growth.get("stage", 0)) >= 1, "收集推进到三分之一后花园角落进入可见阶段")
	assert_equal(
		str(growth.get("focus_name", "")),
		str(level_system.get_theme_target_data().get("focus_name", "")),
		"花园角落事件带上本局照料目标"
	)
	level_system.collected_tiles[target_key] = required_count
	level_system.refresh_garden_corner()
	assert_equal(level_system.garden_corner_stage, LevelSystem.GARDEN_CORNER_STAGES, "完成主目标后花园角落进入完成阶段")
	assert_true(level_system.refresh_garden_corner().is_empty(), "同一阶段不重复发出推进事件")

	level_system.start_level_config({
		"level_id": 2,
		"moves": 26,
		"available_types": [1, 2, 3, 4],
		"is_daily_challenge": true,
		"target": {
			"type": "collect",
			"requirements": [{"tile_type": 1, "count": 9}],
			"garden_layer": {"type": "fallen_leaves", "required": 3, "required_for_clear": true, "cells": [[2, 1], [2, 3], [2, 5]]}
		},
		"rewards": {"seed_type": 1, "seed_count": 0, "stars": 0, "first_clear_bonus": {"stars": 0, "seed_count": 0}}
	})
	level_system.collected_tiles["1"] = 9
	level_system.refresh_garden_corner()
	assert_equal(level_system.garden_corner_stage, 0, "必需落叶未扫时花园角落不进入完成阶段")
	level_system.clear_garden_layers(3)
	level_system.refresh_garden_corner()
	assert_equal(level_system.garden_corner_stage, LevelSystem.GARDEN_CORNER_STAGES, "主目标与必需落叶都完成后花园角落进入完成阶段")
	level_system.free()

	var controller = SimpleGameController.new()
	add_child(controller)
	controller._start_level(1)
	assert_true(controller.companion_panel == null, "迭代 P：普通关局内不再显示照料对象面板")
	controller.free()


func test_rhythm_escalation() -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)

	level_system.start_level(2)
	assert_equal(level_system.rhythm_tier, 0, "开局情绪处于平静档")
	var requirement = level_system.level_config.get("target", {}).get("requirements", [])[0]
	var target_key = str(int(requirement.get("tile_type", 0)))
	var required_count = int(requirement.get("count", 0))

	var captured: Array = []
	level_system.rhythm_changed.connect(func(payload: Dictionary) -> void: captured.append(payload))

	level_system.collected_tiles[target_key] = int(ceil(required_count * 0.7))
	var first_escalation = level_system.refresh_rhythm()
	assert_true(not first_escalation.is_empty(), "接近目标触发分级升温事件")
	assert_equal(int(first_escalation.get("tier", 0)), 1, "推进到七成时进入第一档")
	assert_equal(captured.size(), 1, "分级升温同时发出信号")
	assert_true(level_system.refresh_rhythm().is_empty(), "同一档不会重复升温")

	level_system.collected_tiles[target_key] = int(ceil(required_count * 0.95))
	var second_escalation = level_system.refresh_rhythm()
	assert_equal(int(second_escalation.get("tier", 0)), 2, "接近完成时进入临门档")

	level_system.start_level(2)
	level_system.collected_tiles[target_key] = int(ceil(required_count * 0.5))
	level_system.moves_left = 2
	level_system.refresh_rhythm()
	assert_true(level_system.rhythm_tier >= 1, "剩余步数偏低时也会升温")
	level_system.free()

	var controller = SimpleGameController.new()
	add_child(controller)
	controller._start_level(1)
	assert_true(controller.has_method("_play_level_climax"), "控制器提供完成高潮反馈")
	controller.free()


func test_level_continue() -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)

	level_system.start_level(1)
	level_system.moves_left = 0
	level_system._fail_level()

	assert_true(not level_system.is_level_active, "失败后关卡处于非激活状态")
	assert_true(level_system.continue_level(5), "失败后可以继续关卡")
	assert_true(level_system.is_level_active, "继续后关卡恢复激活")
	assert_equal(level_system.moves_left, 5, "继续后恢复额外步数")

	level_system.free()
