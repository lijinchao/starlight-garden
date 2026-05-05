## TestRunner - 测试运行器
class_name TestRunner
extends Node

const Fragment = preload("res://scripts/ui/Fragment.gd")

# ==================== 信号 ====================
signal test_suite_completed(results: Dictionary)

# ==================== 变量 ====================
var test_results: Dictionary = {
	"total": 0,
	"passed": 0,
	"failed": 0,
	"errors": []
}

# ==================== 公开方法 ====================
# 运行所有测试
func run_all_tests() -> Dictionary:
	test_results = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	print("\n=====================================")
	print("   星光花园 - 测试套件")
	print("=====================================\n")
	
	# 运行单元测试
	_run_test_suite("Constants", Callable(self, "test_constants"))
	_run_test_suite("Board Logic", Callable(self, "test_board_logic"))
	_run_test_suite("Board Level Config", Callable(self, "test_board_level_config"))
	_run_test_suite("Board Visual Input", Callable(self, "test_board_visual_input"))
	_run_test_suite("Match Detection", Callable(self, "test_match_detection"))
	_run_test_suite("Level System", Callable(self, "test_level_system"))
	_run_test_suite("Level Progression", Callable(self, "test_level_progression"))
	_run_test_suite("Level Continue", Callable(self, "test_level_continue"))
	_run_test_suite("Settlement Service", Callable(self, "test_settlement_service"))
	_run_test_suite("Flower Language", Callable(self, "test_flower_language"))
	_run_test_suite("Fragment Generation", Callable(self, "test_fragment_generation"))
	_run_test_suite("Daily Service", Callable(self, "test_daily_service"))
	_run_test_suite("Decoration Service", Callable(self, "test_decoration_service"))
	_run_test_suite("Economy And Boost", Callable(self, "test_economy_and_boost"))
	_run_test_suite("Save Manager", Callable(self, "test_save_manager"))
	_run_test_suite("Garden Loop", Callable(self, "test_garden_loop"))
	_run_test_suite("Garden Synthesis", Callable(self, "test_garden_synthesis"))
	_run_test_suite("Tutorial Flow", Callable(self, "test_tutorial_flow"))
	_run_test_suite("Tutorial Highlight", Callable(self, "test_tutorial_highlight"))
	
	# 输出结果
	print("\n=====================================")
	print("   测试结果汇总")
	print("=====================================")
	print("总计: %d" % test_results["total"])
	print("通过: %d ✅" % test_results["passed"])
	print("失败: %d ❌" % test_results["failed"])
	
	if test_results["errors"].size() > 0:
		print("\n错误详情:")
		for error in test_results["errors"]:
			print("  ❌ %s" % error)
	
	print("=====================================\n")
	
	test_suite_completed.emit(test_results)
	return test_results

# 运行测试套件
func _run_test_suite(suite_name: String, test_func: Callable) -> void:
	print("📦 测试套件: %s" % suite_name)
	test_func.call()
	print("")

# 断言方法
func assert_true(condition: bool, message: String = "") -> bool:
	test_results["total"] += 1
	if condition:
		test_results["passed"] += 1
		print("  ✅ PASS: %s" % message)
		return true
	else:
		test_results["failed"] += 1
		var error_msg = "FAIL: %s" % message
		test_results["errors"].append(error_msg)
		print("  ❌ %s" % error_msg)
		return false

func assert_equal(actual, expected, message: String = "") -> bool:
	test_results["total"] += 1
	if actual == expected:
		test_results["passed"] += 1
		print("  ✅ PASS: %s" % message)
		return true
	else:
		test_results["failed"] += 1
		var error_msg = "FAIL: %s (期望: %s, 实际: %s)" % [message, str(expected), str(actual)]
		test_results["errors"].append(error_msg)
		print("  ❌ %s" % error_msg)
		return false

func assert_not_equal(actual, expected, message: String = "") -> bool:
	test_results["total"] += 1
	if actual != expected:
		test_results["passed"] += 1
		print("  ✅ PASS: %s" % message)
		return true
	else:
		test_results["failed"] += 1
		var error_msg = "FAIL: %s (不应等于: %s)" % [message, str(expected)]
		test_results["errors"].append(error_msg)
		print("  ❌ %s" % error_msg)
		return false

func assert_greater(actual: float, threshold: float, message: String = "") -> bool:
	test_results["total"] += 1
	if actual > threshold:
		test_results["passed"] += 1
		print("  ✅ PASS: %s" % message)
		return true
	else:
		test_results["failed"] += 1
		var error_msg = "FAIL: %s (%f 不大于 %f)" % [message, actual, threshold]
		test_results["errors"].append(error_msg)
		print("  ❌ %s" % error_msg)
		return false

# ==================== 测试用例 ====================
# 测试常量定义
func test_constants() -> void:
	assert_true(Constants.GRID_ROWS == 7, "网格行数应为7")
	assert_true(Constants.GRID_COLS == 7, "网格列数应为7")
	assert_true(Constants.MIN_MATCH_COUNT == 3, "最小匹配数应为3")
	assert_true(Constants.TILE_SIZE == 96, "元素大小应为96")
	assert_true(Constants.TILE_COLORS.size() >= 6, "至少定义6种颜色")

# 测试棋盘逻辑
func test_board_logic() -> void:
	var board = Board.new()
	add_child(board)
	
	# 测试网格初始化
	assert_equal(board.grid.size(), Constants.GRID_ROWS, "网格行数正确")
	for row in board.grid:
		assert_equal(row.size(), Constants.GRID_COLS, "网格列数正确")
	
	# 测试位置有效性
	assert_true(board._is_valid_position(Vector2i(0, 0)), "位置(0,0)有效")
	assert_true(board._is_valid_position(Vector2i(6, 6)), "位置(6,6)有效")
	assert_true(not board._is_valid_position(Vector2i(-1, 0)), "位置(-1,0)无效")
	assert_true(not board._is_valid_position(Vector2i(0, 7)), "位置(0,7)无效")
	
	# 测试相邻判断（使用公开接口）
	assert_true(board.is_adjacent(Vector2i(3, 3), Vector2i(3, 4)), "水平相邻")
	assert_true(board.is_adjacent(Vector2i(3, 3), Vector2i(4, 3)), "垂直相邻")
	assert_true(not board.is_adjacent(Vector2i(3, 3), Vector2i(3, 5)), "不相邻(距离2)")
	assert_true(not board.is_adjacent(Vector2i(3, 3), Vector2i(4, 4)), "不相邻(对角)")
	
	board.free()


func test_board_level_config() -> void:
	var board = Board.new()
	add_child(board)

	var limited_types = [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER
	]
	board.initialize_grid({"available_types": limited_types})

	for row in board.grid:
		for tile_type in row:
			assert_true(limited_types.has(tile_type), "棋盘元素受关卡配置限制")

	board.free()


func test_board_visual_input() -> void:
	var board_visual = BoardVisual.new()
	add_child(board_visual)

	var grid = []
	for row in range(Constants.GRID_ROWS):
		var row_data = []
		for col in range(Constants.GRID_COLS):
			row_data.append(Constants.TileType.RED_ROSE)
		grid.append(row_data)

	board_visual.initialize_grid(grid)

	var click_pos = board_visual.to_global(board_visual._grid_to_world(Vector2i(0, 0)) + Vector2(10, 10))
	board_visual._emit_click_at_position(click_pos)

	assert_equal(board_visual.last_clicked_pos, Vector2i(0, 0), "棋盘点击映射到正确格子")

	board_visual.free()

# 测试匹配检测
func test_match_detection() -> void:
	var board = Board.new()
	add_child(board)
	
	# 手动设置网格进行测试
	# 测试水平匹配
	board.grid = []
	for row in range(Constants.GRID_ROWS):
		var row_data = []
		for col in range(Constants.GRID_COLS):
			row_data.append(Constants.TileType.NONE)
		board.grid.append(row_data)
	
	# 设置一个水平3连
	board.grid[0][0] = Constants.TileType.RED_ROSE
	board.grid[0][1] = Constants.TileType.RED_ROSE
	board.grid[0][2] = Constants.TileType.RED_ROSE
	
	var matches = board.find_all_matches()
	assert_true(matches.size() > 0, "检测到水平匹配")
	
	# 设置一个垂直3连
	board.grid = []
	for row in range(Constants.GRID_ROWS):
		var row_data = []
		for col in range(Constants.GRID_COLS):
			row_data.append(Constants.TileType.NONE)
		board.grid.append(row_data)
	
	board.grid[0][0] = Constants.TileType.BLUE_FORGET_ME_NOT
	board.grid[1][0] = Constants.TileType.BLUE_FORGET_ME_NOT
	board.grid[2][0] = Constants.TileType.BLUE_FORGET_ME_NOT
	
	matches = board.find_all_matches()
	assert_true(matches.size() > 0, "检测到垂直匹配")
	
	board.free()

# 测试关卡系统
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
		level_system.collected_tiles[str(req["tile_type"])] = req["count"]
	
	assert_true(level_system._check_win_condition(), "收集完成后胜利")
	
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


func test_settlement_service() -> void:
	SaveManager.reset_save()

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(2)

	var victory = SettlementService.build_victory_settlement(2, 3, 180, level_system.level_config)
	assert_true(victory.get("is_first_clear", false), "首次通关时应识别首通奖励")
	SettlementService.apply_victory_settlement(victory)

	var player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("total_score", 0), 180, "胜利结算会写入分数")
	assert_true(player_data.get("cleared_levels", []).has(2), "胜利结算会记录已通关关卡")
	assert_equal(player_data.get("stars", 0), 50, "胜利结算会发放基础星光和首通奖励")

	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "胜利结算会发放花种")
	assert_equal(garden.get("inventory", [])[0].get("amount", 0), 2, "首通奖励会增加花种数量")
	assert_equal(garden.get("inventory", [])[0].get("type", 0), 2, "结算奖励会读取关卡配置中的seed_type")

	var repeat_victory = SettlementService.build_victory_settlement(2, 3, 200, level_system.level_config)
	assert_true(not repeat_victory.get("is_first_clear", true), "重复通关不应再次判定为首通")

	level_system.moves_left = 0
	level_system._fail_level()
	level_system.collected_tiles.clear()
	var failure = SettlementService.build_failure_settlement(level_system, 10)
	SettlementService.apply_failure_settlement(failure)
	player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("failure_streak", 0), 1, "失败结算会累计失败次数")
	assert_equal(player_data.get("stars", 0), 54, "失败结算会发放保底星光")

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
	var garden_after_failure = SaveManager.get_garden_data()
	assert_true(garden_after_failure.get("inventory", []).size() >= 1, "连续失败鼓励会发放花种")

	level_system.free()
	SaveManager.reset_save()


func test_flower_language() -> void:
	SaveManager.reset_save()

	var flower_language = SaveManager.get_flower_language_data()
	assert_true(flower_language.has("fragments"), "花语数据包含碎片表")
	assert_true(flower_language.has("unlocked"), "花语数据包含解锁列表")

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(1)

	var victory = SettlementService.build_victory_settlement(1, 3, 100, level_system.level_config)
	SettlementService.apply_victory_settlement(victory)
	var reward = victory.get("flower_language_reward", {})
	assert_true(reward.get("success", false), "胜利结算会发放花语碎片")
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.RED_ROSE),
		3,
		"首次通关会发放基础和首通花语碎片"
	)
	assert_true(
		"\n".join(SettlementService.format_rewards_summary(victory)).contains("花语碎片"),
		"胜利结算摘要包含花语碎片"
	)

	var repeat_victory = SettlementService.build_victory_settlement(1, 3, 100, level_system.level_config)
	SettlementService.apply_victory_settlement(repeat_victory)
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.RED_ROSE),
		5,
		"重复通关只发放基础花语碎片并达到解锁条件"
	)
	assert_true(
		FlowerLanguageService.is_unlocked(Constants.TileType.RED_ROSE),
		"5个碎片会自动解锁花语"
	)

	level_system.start_level(2)
	level_system.moves_left = 0
	level_system._fail_level()
	var failure = SettlementService.build_failure_settlement(level_system, 10)
	SettlementService.apply_failure_settlement(failure)
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.BLUE_FORGET_ME_NOT),
		1,
		"失败保底会发放对应花语碎片"
	)
	assert_true(
		"\n".join(SettlementService.format_rewards_summary(failure)).contains("花语碎片"),
		"失败结算摘要包含花语碎片"
	)

	var entries = FlowerLanguageService.get_journal_entries()
	assert_equal(entries.size(), 6, "花语日记包含6种基础花")

	level_system.free()
	SaveManager.reset_save()


func test_fragment_generation() -> void:
	var flower_types = [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]

	for flower_type in flower_types:
		var texture = SpriteGenerator.generate_fragment_texture(flower_type, 32)
		assert_true(texture != null and texture is ImageTexture, "花语碎片纹理生成成功")

	var synthesis_texture = SpriteGenerator.generate_synthesis_texture(64)
	assert_true(synthesis_texture != null and synthesis_texture is ImageTexture, "合成特效纹理生成成功")

	var flower_texture = SpriteGenerator.generate_flower_texture(Constants.TileType.RED_ROSE, 96)
	assert_true(flower_texture != null and flower_texture is ImageTexture, "花朵纹理生成成功")


func test_daily_service() -> void:
	SaveManager.reset_save()

	var daily = DailyService.get_daily_state()
	assert_true(daily.has("date"), "每日数据包含日期")
	assert_true(daily.has("tasks"), "每日数据包含任务")
	assert_true(daily.get("tasks", {}).has(DailyService.TASK_PLAY_LEVEL), "每日任务包含完成任意1局")
	assert_true(not DailyService.can_claim_gift(), "任务未完成时不能领取今日花礼")

	DailyService.record_event(DailyService.TASK_PLAY_LEVEL)
	DailyService.record_event(DailyService.TASK_HARVEST_FLOWER)
	assert_true(not DailyService.can_claim_gift(), "只完成部分任务时不能领取今日花礼")

	DailyService.record_event(DailyService.TASK_COLLECT_FLOWER_FRAGMENT)
	assert_true(DailyService.can_claim_gift(), "完成全部任务后可以领取今日花礼")

	var claim_result = DailyService.claim_gift()
	assert_true(claim_result.get("success", false), "今日花礼领取成功")
	assert_equal(EconomyService.get_stars(), DailyService.GIFT_STARS, "今日花礼发放星光")
	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "今日花礼发放花种")
	assert_true(not DailyService.claim_gift().get("success", true), "今日花礼不可重复领取")

	var old_daily = SaveManager.get_daily_data()
	old_daily["date"] = "2000-01-01"
	old_daily["gift_claimed"] = true
	old_daily["tasks"][DailyService.TASK_PLAY_LEVEL]["progress"] = 1
	old_daily["tasks"][DailyService.TASK_PLAY_LEVEL]["completed"] = true
	SaveManager.update_daily_data(old_daily)

	var refreshed = DailyService.get_daily_state()
	assert_equal(refreshed.get("date", ""), DailyService.get_today_key(), "日期变化时每日数据刷新为今天")
	assert_true(not refreshed.get("gift_claimed", true), "日期变化后礼包领取状态重置")
	assert_equal(
		refreshed.get("tasks", {}).get(DailyService.TASK_PLAY_LEVEL, {}).get("progress", -1),
		0,
		"日期变化后任务进度重置"
	)

	SaveManager.reset_save()


func test_decoration_service() -> void:
	SaveManager.reset_save()

	var catalog = DecorationService.get_decoration_catalog()
	assert_greater(catalog.size(), 3, "装饰目录至少包含4个装饰")
	assert_equal(DecorationService.get_atmosphere_value(), 0, "默认花园氛围值为0")
	assert_true(not DecorationService.is_owned("bench"), "默认未拥有长椅装饰")

	var invalid_result = DecorationService.purchase_decoration("missing")
	assert_true(not invalid_result.get("success", true), "非法装饰ID无法购买")
	assert_equal(invalid_result.get("reason", ""), "invalid_id", "非法装饰ID返回明确原因")

	var insufficient_result = DecorationService.purchase_decoration("bench")
	assert_true(not insufficient_result.get("success", true), "星光不足时无法购买装饰")
	assert_equal(insufficient_result.get("reason", ""), "not_enough_stars", "星光不足返回明确原因")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 0, "购买失败不写入装饰存档")

	EconomyService.add_stars(40)
	var purchase_result = DecorationService.purchase_decoration("bench")
	assert_true(purchase_result.get("success", false), "星光足够时装饰购买成功")
	assert_equal(EconomyService.get_stars(), 10, "购买装饰后扣除星光")
	assert_true(DecorationService.is_owned("bench"), "购买后装饰变为已拥有")
	assert_equal(DecorationService.get_atmosphere_value(), 2, "购买装饰后氛围值提升")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 1, "购买成功写入装饰存档")

	var repeat_result = DecorationService.purchase_decoration("bench")
	assert_true(not repeat_result.get("success", true), "已拥有装饰不可重复购买")
	assert_equal(repeat_result.get("reason", ""), "already_owned", "重复购买返回明确原因")
	assert_equal(EconomyService.get_stars(), 10, "重复购买不会重复扣费")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 1, "重复购买不会重复写入")

	var display_data = DecorationService.get_display_data()
	assert_equal(display_data.get("atmosphere", 0), 2, "装饰展示数据包含氛围值")
	assert_equal(display_data.get("stars", 0), 10, "装饰展示数据包含当前星光")

	SaveManager.reset_save()


func test_economy_and_boost() -> void:
	SaveManager.reset_save()
	assert_true(EconomyService.add_stars(20), "可增加星光")
	assert_equal(EconomyService.get_stars(), 20, "增加星光后数值正确")
	assert_true(EconomyService.spend_stars(12), "星光足够时可消耗")
	assert_equal(EconomyService.get_stars(), 8, "消耗星光后数值正确")
	assert_true(not EconomyService.spend_stars(12), "星光不足时不可消耗")

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(1, 3)
	assert_equal(level_system.moves_left, 33, "开局祝福会增加初始步数")
	level_system.free()
	SaveManager.reset_save()


func test_save_manager() -> void:
	SaveManager.reset_save()

	var garden = SaveManager.get_garden_data()
	assert_true(garden.has("slots"), "花园数据包含slots")
	assert_true(garden.has("inventory"), "花园数据包含inventory")
	assert_true(garden.has("decorations"), "花园数据包含decorations")
	assert_equal(garden.get("slots", []).size(), 0, "默认花园槽位为空")

	var player = SaveManager.get_player_data()
	assert_true(player.has("cleared_levels"), "玩家数据包含cleared_levels")
	assert_true(player.has("failure_streak"), "玩家数据包含failure_streak")

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

	SaveManager.reset_save()


func test_garden_loop() -> void:
	SaveManager.reset_save()
	SaveManager.add_garden_inventory_item(Constants.TileType.BLUE_FORGET_ME_NOT, 1, 1)

	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	garden_ui._load_garden_data()
	garden_ui._handle_plant_action(0)

	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 0, "种植后库存已扣减")
	assert_equal(garden.get("slots", []).size(), 1, "种植后花园槽位已有花朵")

	var slots = garden.get("slots", [])
	slots[0]["planted_at"] = Time.get_unix_time_from_system() - int(Constants.FLOWER_GROWTH_DURATION + 1.0)
	slots[0]["growth"] = 0.0
	garden["slots"] = slots
	SaveManager.update_garden_data(garden)

	garden_ui._load_garden_data()
	garden = SaveManager.get_garden_data()
	assert_true(garden["slots"][0].get("growth", 0.0) >= 1.0, "花朵会按时间成长完成")

	garden_ui._harvest_flower(0)
	var player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("stars", 0), 10, "收获花朵后获得星光")
	garden = SaveManager.get_garden_data()
	assert_true(garden["slots"][0].is_empty(), "收获后花盆被清空")

	garden_ui.free()
	SaveManager.reset_save()


func test_garden_synthesis() -> void:
	SaveManager.reset_save()
	SaveManager.add_garden_inventory_item(Constants.TileType.RED_ROSE, 1, 2)

	assert_true(GardenSynthesisService.can_synthesize(Constants.TileType.RED_ROSE, 1, 2), "两个同等级花种可以合成")
	var result = GardenSynthesisService.synthesize_once(Constants.TileType.RED_ROSE, 1)
	assert_true(result.get("success", false), "合成执行成功")

	var garden = SaveManager.get_garden_data()
	var inventory = garden.get("inventory", [])
	var lv1_amount = 0
	var lv2_amount = 0
	for item in inventory:
		if item.get("type") == Constants.TileType.RED_ROSE and item.get("level", 1) == 1:
			lv1_amount = item.get("amount", 0)
		if item.get("type") == Constants.TileType.RED_ROSE and item.get("level", 1) == 2:
			lv2_amount = item.get("amount", 0)

	assert_equal(lv1_amount, 0, "合成后旧等级材料被扣除")
	assert_equal(lv2_amount, 1, "合成后获得高一级花种")

	var fail_result = GardenSynthesisService.synthesize_once(Constants.TileType.RED_ROSE, 2)
	assert_true(not fail_result.get("success", true), "材料不足时无法继续合成")

	SaveManager.reset_save()


func test_tutorial_flow() -> void:
	TutorialManager.reset_tutorial()

	var tutorial_system = TutorialSystem.new()
	add_child(tutorial_system)
	tutorial_system.start_tutorial()

	tutorial_system._next_step()
	tutorial_system._next_step()
	tutorial_system._next_step()

	assert_equal(tutorial_system.current_step, 3, "教程已进入首次交换步骤")
	assert_true(tutorial_system.is_running(), "教程处于运行状态")

	tutorial_system.notify_action_completed("wait_swap")
	assert_equal(tutorial_system.current_step, 4, "完成交换后教程自动推进")

	tutorial_system.free()
	TutorialManager.reset_tutorial()


func test_tutorial_highlight() -> void:
	TutorialManager.reset_tutorial()

	var tutorial_system = TutorialSystem.new()
	add_child(tutorial_system)
	tutorial_system.start_tutorial()
	tutorial_system._show_step(1)

	assert_true(tutorial_system.highlight_rect.visible, "HUD 引导步骤会显示高亮区域")

	tutorial_system._show_step(5)
	assert_true(tutorial_system.highlight_rect.visible, "步数引导步骤会显示高亮区域")

	tutorial_system.free()
	TutorialManager.reset_tutorial()
