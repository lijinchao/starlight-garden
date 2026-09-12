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
