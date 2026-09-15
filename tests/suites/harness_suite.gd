## Harness integrity suite - 测试基础设施自身的完整性
##
## 背景：一个测试套件脚本解析失败时，运行器曾把“套件没跑成”当成“全绿”。
## 这里断言：套件级错误必须计入失败，否则任何 broken 的测试都会伪装成通过。
extends "res://tests/suites/test_suite.gd"


func test_broken_suite_is_counted_as_failure() -> void:
	var saved_suites = runner.enabled_suites
	runner.enabled_suites = PackedStringArray()

	var before_failed = runner.test_results["failed"]
	var before_total = runner.test_results["total"]
	var before_errors = runner.test_results["errors"].size()

	# res://levels/*.json 不是 Script，必然无法实例化为测试套件。
	runner._run_test_suite("Broken Suite Fixture", "res://levels/level_006.json", "test_x")

	var failed_delta = runner.test_results["failed"] - before_failed
	var total_delta = runner.test_results["total"] - before_total
	var error_delta = runner.test_results["errors"].size() - before_errors

	# 撤销这次故意注入的失败记录，避免污染整轮汇总。
	runner.test_results["failed"] -= failed_delta
	runner.test_results["total"] -= total_delta
	for _index in range(error_delta):
		runner.test_results["errors"].pop_back()
	runner.enabled_suites = saved_suites

	assert_true(
		failed_delta == 1 and total_delta == 1 and error_delta == 1,
		"无法实例化的测试套件必须被计为一次失败，而不是被静默跳过"
	)
