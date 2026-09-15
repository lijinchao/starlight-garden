## TestRunner - 测试运行器
## 只负责调度与结果汇总；测试用例按领域放在 tests/suites/ 下。
class_name TestRunner
extends Node

# ==================== 信号 ====================
signal test_suite_completed(results: Dictionary)

# ==================== 变量 ====================
var test_results: Dictionary = {
	"total": 0,
	"passed": 0,
	"failed": 0,
	"errors": []
}
var enabled_suites: PackedStringArray = []

# 每个测试用例与其所属的套件脚本；顺序即执行顺序。
const SUITE_TESTS: Array = [
	["Constants", "res://tests/suites/constants_suite.gd", "test_constants"],
	["Board Logic", "res://tests/suites/board_suite.gd", "test_board_logic"],
	["Breeze Path", "res://tests/suites/board_suite.gd", "test_breeze_path"],
	["Board Level Config", "res://tests/suites/board_suite.gd", "test_board_level_config"],
	["Special Activation", "res://tests/suites/board_suite.gd", "test_special_activation"],
	["Blocker Obstacles", "res://tests/suites/blocker_suite.gd", "test_blocker_obstacles"],
	["Blocker Gravity", "res://tests/suites/blocker_suite.gd", "test_blocker_gravity"],
	["Blocker Only Breeze Breaks", "res://tests/suites/blocker_suite.gd", "test_blocker_only_breeze_breaks"],
	["Blocker Damage Visual", "res://tests/suites/blocker_suite.gd", "test_blocker_damage_visual"],
	["Breeze Breaks Blocker", "res://tests/suites/blocker_suite.gd", "test_breeze_breaks_blocker"],
	["One Move Chips Once", "res://tests/suites/blocker_suite.gd", "test_one_move_chips_blocker_once"],
	["Special Tap Cascades", "res://tests/suites/blocker_suite.gd", "test_special_tap_cascades"],
	["Puzzle Depth", "res://tests/suites/puzzle_depth_suite.gd", "test_levels_require_a_plan"],
	["Harness Integrity", "res://tests/suites/harness_suite.gd", "test_broken_suite_is_counted_as_failure"],
	["Board Visual Input", "res://tests/suites/board_suite.gd", "test_board_visual_input"],
	["Visual Asset Integration", "res://tests/suites/visual_suite.gd", "test_visual_asset_integration"],
	["Playtest Recording", "res://tests/suites/playtest_suite.gd", "test_playtest_recording"],
	["Playtest Report", "res://tests/suites/playtest_suite.gd", "test_playtest_report"],
	["Match Detection", "res://tests/suites/board_suite.gd", "test_match_detection"],
	["Level System", "res://tests/suites/level_suite.gd", "test_level_system"],
	["Level Progression", "res://tests/suites/level_suite.gd", "test_level_progression"],
	["Level Continue", "res://tests/suites/level_suite.gd", "test_level_continue"],
	["Single Spatial Goal", "res://tests/suites/level_suite.gd", "test_single_spatial_goal"],
	["Garden Corner Growth", "res://tests/suites/level_suite.gd", "test_garden_corner_growth"],
	["Rhythm Escalation", "res://tests/suites/level_suite.gd", "test_rhythm_escalation"],
	["Settlement Service", "res://tests/suites/settlement_suite.gd", "test_settlement_service"],
	["Flower Language", "res://tests/suites/meta_suite.gd", "test_flower_language"],
	["Fragment Generation", "res://tests/suites/meta_suite.gd", "test_fragment_generation"],
	["Daily Service", "res://tests/suites/meta_suite.gd", "test_daily_service"],
	["Decoration Service", "res://tests/suites/meta_suite.gd", "test_decoration_service"],
	["Economy And Boost", "res://tests/suites/meta_suite.gd", "test_economy_and_boost"],
	["Progressive Disclosure", "res://tests/suites/meta_suite.gd", "test_progressive_disclosure"],
	["Navigation And Guidance", "res://tests/suites/ui_suite.gd", "test_navigation_and_guidance"],
	["Restoration Feedback", "res://tests/suites/ui_suite.gd", "test_restoration_feedback"],
	["Garden Payoff", "res://tests/suites/garden_payoff_suite.gd", "test_clearing_restores_named_corner"],
	["Garden Payoff Dedup", "res://tests/suites/garden_payoff_suite.gd", "test_restored_corner_is_not_duplicated"],
	["Garden Payoff Display", "res://tests/suites/garden_payoff_suite.gd", "test_garden_shows_restored_corner"],
	["Garden Payoff Lights Up", "res://tests/suites/garden_payoff_suite.gd", "test_garden_lights_up_restored_corner"],
	["Level Select Replay", "res://tests/suites/ui_suite.gd", "test_level_select_replay"],
	["Home Return Paths", "res://tests/suites/ui_suite.gd", "test_home_return_paths"],
	["Companion Care", "res://tests/suites/companion_suite.gd", "test_companion_care"],
	["Save Manager", "res://tests/suites/save_suite.gd", "test_save_manager"],
	["Garden Loop", "res://tests/suites/meta_suite.gd", "test_garden_loop"],
	["Garden Synthesis", "res://tests/suites/meta_suite.gd", "test_garden_synthesis"],
	["Tutorial Flow", "res://tests/suites/tutorial_suite.gd", "test_tutorial_flow"],
	["Tutorial Highlight", "res://tests/suites/tutorial_suite.gd", "test_tutorial_highlight"],
]

# ==================== 公开方法 ====================
# 运行所有测试
func run_all_tests() -> Dictionary:
	test_results = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	enabled_suites = _read_enabled_suites()

	print("\n=====================================")
	print("   星光花园 - 测试套件")
	print("=====================================\n")
	if not enabled_suites.is_empty():
		print("筛选套件: %s\n" % ", ".join(enabled_suites))

	for entry in SUITE_TESTS:
		_run_test_suite(entry[0], entry[1], entry[2])

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


# 运行单个测试用例；每个用例使用独立的套件实例。
func _run_test_suite(suite_name: String, script_path: String, method_name: String) -> void:
	if not _should_run_suite(suite_name):
		print("⏭️ 跳过测试套件: %s" % suite_name)
		print("")
		return
	print("📦 测试套件: %s" % suite_name)
	var script = load(script_path)
	if script == null or not (script is Script) or not script.can_instantiate():
		_record_suite_error(suite_name, "套件脚本无法加载、解析或实例化：%s" % script_path)
		print("")
		return
	var suite = script.new()
	suite.runner = self
	add_child(suite)
	if not suite.has_method(method_name):
		_record_suite_error(suite_name, "套件缺少测试方法：%s.%s" % [script_path, method_name])
		suite.queue_free()
		print("")
		return
	suite.call(method_name)
	suite.queue_free()
	print("")


# 套件级错误也必须计入失败，否则“脚本解析失败/方法不存在”会被当成全绿。
func _record_suite_error(suite_name: String, reason: String) -> void:
	test_results["total"] += 1
	test_results["failed"] += 1
	var error_msg = "FAIL: [%s] %s" % [suite_name, reason]
	test_results["errors"].append(error_msg)
	print("  ❌ %s" % error_msg)


func _read_enabled_suites() -> PackedStringArray:
	var raw_value = OS.get_environment("TEST_SUITES").strip_edges()
	if raw_value.is_empty():
		return PackedStringArray()

	var suites := PackedStringArray()
	for item in raw_value.split(","):
		var normalized = item.strip_edges()
		if not normalized.is_empty():
			suites.append(normalized)
	return suites


func _should_run_suite(suite_name: String) -> bool:
	if enabled_suites.is_empty():
		return true
	for candidate in enabled_suites:
		if candidate.to_lower() == suite_name.to_lower():
			return true
	return false


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

