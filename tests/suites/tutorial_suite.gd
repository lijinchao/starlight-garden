## Tutorial suite
extends "res://tests/suites/test_suite.gd"


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

	tutorial_system.shutdown()
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

	tutorial_system.shutdown()
	tutorial_system.free()
	TutorialManager.reset_tutorial()
