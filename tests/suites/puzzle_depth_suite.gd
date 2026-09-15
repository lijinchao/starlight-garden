## Puzzle depth suite - 迭代 P：关卡意图解探针（目标级验收测试）
##
## 这一组测试问的不是“代码有没有跑通”，而是：
## 玩家可观察的关卡，到底有没有一个“需要计划才找得到”的解。
##
## 判据（贪心机器人 vs 规划机器人，同一批种子）：
##   贪心过不了 + 规划能过 => 有意图解，红转绿。
extends "res://tests/suites/test_suite.gd"

const ProbeScript = preload("res://scripts/tools/puzzle_depth_probe.gd")
const RUNS := 40


func test_levels_require_a_plan() -> void:
	var probe = ProbeScript.new()
	add_child(probe)

	# 校准：探针必须能在明显容易的关卡上赢。
	# 否则“贪心过不了”可能只是探针坏了，而不是关卡有深度。
	var easy_config := {
		"moves": 20,
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[3, 3]]},
		"available_types": [1, 2, 3]
	}
	# 校准：明显容易的关卡，会攒清风的规划机器人必须能稳定通关，否则探针本身坏了。
	# 新机制下“贪心”不会对准清风，在容易关也可能失败，所以校准用规划机器人。
	var easy_plan = probe.measure(easy_config, "patient", RUNS, 1000)
	print("探针校准（1 块石块 / 20 步）：规划通过率 %.2f" % easy_plan["clear_rate"])
	assert_greater(easy_plan["clear_rate"], 0.8, "探针校准：规划机器人能通过明显容易的关卡，说明探针本身有效")

	var level_system = LevelSystem.new()
	add_child(level_system)

	for level_id in [6, 7, 8]:
		var config = level_system.get_level_config(level_id)
		var greedy = probe.measure(config, "greedy", RUNS, 2000)
		var patient = probe.measure(config, "patient", RUNS, 2000)
		print("第 %d 关：贪心通过率 %.2f，规划通过率 %.2f（%.2f / %.2f 步）" % [
			level_id,
			greedy["clear_rate"],
			patient["clear_rate"],
			greedy["avg_moves_when_cleared"],
			patient["avg_moves_when_cleared"]
		])
		assert_true(greedy["clear_rate"] <= 0.2, "第%d关不能被无前瞻的贪心解通关，否则没有需要计划的空间" % level_id)
		assert_true(patient["clear_rate"] >= 0.5, "第%d关存在规划型解，说明题目可解而不是单纯过难" % level_id)

	level_system.free()
	probe.free()
