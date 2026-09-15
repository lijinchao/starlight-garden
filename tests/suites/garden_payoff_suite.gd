## Garden payoff suite - 迭代 P / B-7：清光一处石块 → 花园里具名的那一处永久恢复
##
## 目标级问题：通关之后，花园里“被打通的那一处”是否被真正记住、并且能被玩家看见？
extends "res://tests/suites/test_suite.gd"


func _settle_victory(level_id: int) -> void:
	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(level_id)
	var settlement = SettlementService.build_victory_settlement(
		level_id,
		3,
		180,
		level_system.level_config,
		{"theme_progress": level_system.get_theme_progress_snapshot()}
	)
	SettlementService.apply_victory_settlement(settlement)
	level_system.free()


func _restored_names() -> Array:
	var names: Array = []
	for corner in SaveManager.get_restored_corners():
		names.append(str(corner.get("name", "")))
	return names


func test_clearing_restores_named_corner() -> void:
	SaveManager.reset_save()
	_settle_victory(6)

	assert_true(SaveManager.get_restored_corners().size() >= 1, "通关后花园记录了恢复的角落")
	assert_true(_restored_names().has("石阶小径"), "第6关通关后，花园里『石阶小径』被恢复")

	# 因果要跨存档：重开也还在
	SaveManager.load_game()
	assert_true(_restored_names().has("石阶小径"), "恢复记录跨存档保留")
	SaveManager.reset_save()


func test_restored_corner_is_not_duplicated() -> void:
	SaveManager.reset_save()
	_settle_victory(6)
	_settle_victory(6)

	var six_count := 0
	for corner in SaveManager.get_restored_corners():
		if int(corner.get("level_id", -1)) == 6:
			six_count += 1
	assert_equal(six_count, 1, "重玩已通关的关卡不会重复恢复同一角落")
	SaveManager.reset_save()


func test_garden_shows_restored_corner() -> void:
	SaveManager.reset_save()
	_settle_victory(6)

	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	garden_ui._load_garden_data()
	var joined := " ".join(_find_label_texts(garden_ui))
	assert_true(joined.contains("石阶小径"), "花园界面显示已恢复的具名角落")
	garden_ui.free()
	SaveManager.reset_save()

func test_garden_lights_up_restored_corner() -> void:
	SaveManager.reset_save()

	# 未恢复任何角落时，花园里没有可见标记
	var empty_garden = GardenUI.new()
	add_child(empty_garden)
	empty_garden._load_garden_data()
	assert_equal(empty_garden.restored_corner_markers.size(), 0, "没有恢复角落时花园里没有可见标记")
	empty_garden.free()

	_settle_victory(6)

	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	garden_ui._load_garden_data()

	assert_true(garden_ui.restored_corner_markers.has(6), "花园为已恢复的第6关生成了可见标记")
	var marker = garden_ui.restored_corner_markers[6]
	assert_true(marker.visible, "已恢复角落的标记可见")
	assert_true(" ".join(_find_label_texts(marker)).contains("石阶小径"), "可见标记上写着那处角落的名字")
	assert_true(garden_ui.get_restored_corner_slot_position(6) != Vector2.ZERO, "恢复角落有明确的花园位置")
	assert_equal(marker.position, garden_ui.get_restored_corner_slot_position(6), "标记就落在该角落对应的花园位置上")

	garden_ui.free()
	SaveManager.reset_save()
