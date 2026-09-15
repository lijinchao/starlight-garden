## Board suite
extends "res://tests/suites/test_suite.gd"


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

	board.grid = [
		[1, 2, 1, 2, 1, 2, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 2, 3, 1, 3, 1, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 2, 3, 1, 3, 1, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 1, 3, 1, 3, 1, 3]
	]
	assert_true(board.find_all_matches().is_empty(), "间隔相同花朵不会被判为连续消除")

	var cross_matches = board._merge_matches([
		{"type": 1, "positions": [Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]},
		{"type": 1, "positions": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]}
	])
	assert_equal(cross_matches.size(), 1, "十字匹配合并为一个连续消除组")
	assert_equal(cross_matches[0]["positions"].size(), 5, "十字匹配保留全部五个位置")

	board.grid = [
		[1, 1, 1, 2, 1, 2, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 2, 3, 1, 3, 1, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 2, 3, 1, 3, 1, 3],
		[2, 3, 2, 3, 2, 3, 2],
		[3, 1, 3, 1, 3, 1, 3]
	]
	var turn_result = board.resolve_swap(Vector2i(0, 3), Vector2i(0, 4))
	assert_true(turn_result.get("matched", false), "四连交换会形成有效消除")
	var first_chain: Dictionary = turn_result.get("chains", [])[0]
	assert_equal((first_chain.get("specials_created", []) as Array).size(), 1, "四连会生成一个清风块")
	var created_special: Dictionary = first_chain.get("specials_created", [])[0]
	assert_equal(str(created_special.get("direction", "")), "row", "横向四连生成横向清风块")
	
	board.free()


func test_breeze_path() -> void:
	var board = Board.new()
	add_child(board)
	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {"cells": [[2, 3], [0, 0]]}}
	})
	var normal_match = {
		"type": 1,
		"positions": [Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4)]
	}
	var normal_clear = board._resolve_garden_layers(normal_match["positions"])
	assert_true(normal_clear.get("cleared", []).has(Vector2i(2, 3)), "普通三连会扫开上下左右相邻落叶")
	assert_true(board.get_garden_layer_positions().has(Vector2i(0, 0)), "普通三连不会扫开远处落叶")
	var cross_only = [
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3),
		Vector2i(1, 2), Vector2i(3, 2)
	]
	assert_true(board._get_breeze_paths(cross_only).is_empty(), "两个三连交叉不会误判为方向四连")

	# 四连不再立即清线，而是生成留在盘面的清风块；触发时才清整行/整列
	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {"cells": [[1, 6], [5, 5]]}}
	})
	var horizontal_match = {
		"type": 1,
		"positions": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
	}
	var horizontal_specials = board._create_specials([horizontal_match])
	assert_equal(horizontal_specials.size(), 1, "横向四连生成一个清风块")
	var horizontal_special_pos: Vector2i = horizontal_specials[0]["position"]
	assert_equal(board.get_special_at(horizontal_special_pos), "row", "横向四连生成横向清风块")
	var horizontal_cleared = board._apply_specials([{"position": horizontal_special_pos, "direction": "row"}]).get("cleared", [])
	var horizontal_garden = board._resolve_garden_layers(horizontal_cleared)
	assert_true(horizontal_garden.get("cleared", []).has(Vector2i(1, 6)), "触发横向清风块会扫开同一行远处落叶")
	assert_true(board.get_garden_layer_positions().has(Vector2i(5, 5)), "横向清风不会误扫其他行")

	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {"cells": [[6, 4], [5, 5]]}}
	})
	var vertical_match = {
		"type": 2,
		"positions": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
	}
	var vertical_specials = board._create_specials([vertical_match])
	assert_equal(board.get_special_at(vertical_specials[0]["position"]), "col", "纵向四连生成纵向清风块")
	var vertical_special_pos: Vector2i = vertical_specials[0]["position"]
	var vertical_cleared = board._apply_specials([{"position": vertical_special_pos, "direction": "col"}]).get("cleared", [])
	var vertical_garden = board._resolve_garden_layers(vertical_cleared)
	assert_true(vertical_garden.get("cleared", []).has(Vector2i(6, 4)), "触发纵向清风块会扫开同一列远处落叶")

	# 两个清风块一起触发形成十字清场
	board.configure({"available_types": [1, 2, 3], "target": {}})
	var cross_cleared = board._apply_specials([
		{"position": Vector2i(0, 0), "direction": "row"},
		{"position": Vector2i(3, 3), "direction": "col"}
	]).get("cleared", [])
	var has_row_cell = false
	var has_col_cell = false
	for pos in cross_cleared:
		if pos.x == 0:
			has_row_cell = true
		if pos.y == 3:
			has_col_cell = true
	assert_true(has_row_cell and has_col_cell, "两个清风块一起触发形成十字清场")

	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {
			"cells": [[2, 3], [1, 3], [2, 2], [2, 4], [0, 0]],
			"dew_buds": [[2, 3]]
		}}
	})
	var dew_match = {
		"type": 1,
		"positions": [Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4)]
	}
	var single_dew_clear = board._resolve_garden_layers(dew_match["positions"])
	assert_equal(single_dew_clear.get("dew_bursts", []).size(), 1, "扫开晨露花苞会触发一次绽放")
	assert_true(single_dew_clear.get("cleared", []).has(Vector2i(1, 3)), "晨露花苞会额外扫开十字邻域落叶")
	assert_true(board.get_garden_layer_positions().has(Vector2i(0, 0)), "晨露花苞不会误扫远处落叶")

	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {
			"cells": [[2, 3], [1, 3], [0, 3], [6, 6]],
			"dew_buds": [[2, 3], [1, 3], [0, 3]]
		}}
	})
	var chained_dew_clear = board._resolve_garden_layers(dew_match["positions"])
	assert_equal(chained_dew_clear.get("dew_bursts", []).size(), 3, "晨露扩散命中下一枚花苞会继续连锁")
	assert_equal(chained_dew_clear.get("dew_bursts", [])[2].get("chain_index", 0), 3, "晨露连锁按传播顺序编号")
	assert_true(board.get_garden_layer_positions().has(Vector2i(6, 6)), "晨露连锁不会越过未连接的远处落叶")

	board.configure({
		"available_types": [1, 2, 3],
		"target": {"garden_layer": {
			"cells": [[0, 0], [0, 1], [1, 0], [6, 6]],
			"dew_buds": [[0, 0], [0, 0], [5, 5]]
		}}
	})
	var edge_match = {
		"type": 1,
		"positions": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
	}
	var edge_dew_clear = board._resolve_garden_layers(edge_match["positions"])
	assert_equal(board.get_dew_bud_positions().size(), 0, "花苞配置会忽略重复和不在落叶层中的位置")
	assert_equal(edge_dew_clear.get("dew_bursts", []).size(), 1, "边界晨露花苞可以安全触发")
	assert_true(edge_dew_clear.get("cleared", []).has(Vector2i(0, 1)), "边界花苞仍会清扫棋盘内相邻落叶")

	board.configure({
		"available_types": [1, 2, 3],
		"daily_challenge": {"preferred_direction": "horizontal"},
		"target": {"garden_layer": {
			"cells": [[3, 3], [2, 3], [1, 3]],
			"dew_buds": [[3, 3]]
		}}
	})
	var preferred_match = {
		"type": 1,
		"positions": [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3)]
	}
	var preferred_clear = board._resolve_garden_layers(preferred_match["positions"])
	assert_true(preferred_clear.get("cleared", []).has(Vector2i(1, 3)), "推荐风向四连会让晨露多扫开一圈落叶")
	board.free()

	var level_system = LevelSystem.new()
	add_child(level_system)
	for level_id in range(2, 6):
		var config = level_system.get_level_config(level_id)
		var layer = config.get("target", {}).get("garden_layer", {})
		assert_equal(layer.get("required", 0), level_id + 1, "第%d关落叶数量按阶段递增" % level_id)
	level_system.start_level(2)
	var requirement = level_system.level_config.get("target", {}).get("requirements", [])[0]
	level_system.collected_tiles[str(int(requirement.get("tile_type", 0)))] = int(requirement.get("count", 0))
	assert_true(level_system._check_win_condition(), "普通关收集满花朵即可通关，落叶是可选的")
	assert_true(level_system.get_target_progress_text().contains("顺带扫开落叶 0/3（可选）"), "普通关 HUD 把落叶标为可选进度")
	level_system.start_level_config({
		"level_id": 2,
		"moves": 26,
		"available_types": [1, 2, 3, 4],
		"is_daily_challenge": true,
		"target": {
			"type": "collect",
			"requirements": [{"tile_type": 1, "count": 5}],
			"garden_layer": {"type": "fallen_leaves", "required": 3, "required_for_clear": true, "cells": [[2, 1], [2, 3], [2, 5]]}
		},
		"rewards": {"seed_type": 1, "seed_count": 0, "stars": 0, "first_clear_bonus": {"stars": 0, "seed_count": 0}}
	})
	level_system.collected_tiles["1"] = 5
	assert_true(not level_system._check_win_condition(), "声明 required_for_clear 的关卡仍需扫净落叶")
	level_system.clear_garden_layers(3)
	assert_true(level_system._check_win_condition(), "落叶与收集都完成后才能通关")
	level_system.free()

	var board_visual = BoardVisual.new()
	add_child(board_visual)
	board_visual.initialize_garden_layers([Vector2i(1, 1), Vector2i(1, 5)])
	assert_equal(board_visual.garden_layer_markers.size(), 2, "棋盘会显示配置中的落叶层")
	board_visual.show_garden_layer_clear([Vector2i(1, 1)], [{"direction": "horizontal", "index": 1}])
	assert_true(board_visual.has_node("BreezePath"), "方向四连会显示贯穿棋盘的清风路径")
	assert_equal(board_visual.garden_layer_markers.size(), 1, "扫开的落叶会从棋盘视觉状态移除")
	board_visual.initialize_garden_layers([Vector2i(2, 2)], [Vector2i(2, 2)])
	assert_equal(board_visual.dew_bud_markers.size(), 1, "晨露花苞在落叶层上保留可见提示")
	board_visual.show_garden_layer_clear([Vector2i(2, 2)], [], [{
		"position": Vector2i(2, 2), "chain_index": 1, "cleared_positions": []
	}])
	assert_equal(board_visual.dew_bud_markers.size(), 0, "触发后移除晨露花苞提示")
	assert_true(board_visual.has_node("DewBudBurst"), "触发晨露花苞显示绽放扩散反馈")
	board_visual.free()


func test_special_activation() -> void:
	var board = Board.new()
	add_child(board)
	board.initialize_grid({"available_types": [1, 2, 3]})

	board.grid[3][3] = 1
	board.special_grid[3][3] = "row"
	assert_true(not board.get_special_at(Vector2i(3, 3)).is_empty(), "盘面保留清风块")
	var result = board.activate_special(Vector2i(3, 3))
	assert_true(result.get("matched", false), "点击清风块会立刻触发")
	assert_true((result.get("chains", [])[0].get("special_cleared", []) as Array).size() > 0, "触发后清除整行棋子")
	assert_true(board.get_special_at(Vector2i(3, 3)).is_empty(), "触发后清风块被消耗")

	var empty_result = board.activate_special(Vector2i(0, 0))
	assert_true(not empty_result.get("matched", true), "非清风块位置点击不会触发")
	board.free()

	var controller = SimpleGameController.new()
	add_child(controller)
	assert_true(controller.has_method("_activate_special"), "控制器支持直接触发清风块")
	controller.free()


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

	var level_system = LevelSystem.new()
	var target_types: Dictionary = {}
	for level_id in range(1, 11):
		var config = level_system.get_level_config(level_id)
		var requirements = config.get("target", {}).get("requirements", [])
		var reward_type = int(config.get("rewards", {}).get("seed_type", 0))
		assert_true(config.get("available_types", []).has(reward_type), "第%d关棋盘包含奖励花种" % level_id)
		if requirements.is_empty():
			var goal_type = str(config.get("target", {}).get("type", ""))
			assert_true(goal_type == "clear_leaves" or goal_type == "clear_blockers", "第%d关是单一空间目标" % level_id)
			target_types[reward_type] = true
			continue
		var target_type = int(requirements[0].get("tile_type", 0))
		assert_equal(target_type, reward_type, "第%d关目标花与奖励花种一致" % level_id)
		assert_true(config.get("available_types", []).has(target_type), "第%d关棋盘包含目标花" % level_id)
		target_types[target_type] = true
	assert_true(target_types.size() >= 4, "前10关至少覆盖4种目标花")
	level_system.free()


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
	var controller_source = FileAccess.get_file_as_string("res://scripts/ui/SimpleGameController.gd")
	assert_true(controller_source.contains("func _input(event"), "棋盘使用控制器单一输入入口")
	assert_equal(board_visual.click_control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "BoardVisual 不再重复消费点击")

	assert_true(board_visual.has_method("show_reshuffle_animation"), "棋盘重排提供可见过渡动画")

	board_visual.free()

	var controller = SimpleGameController.new()
	add_child(controller)
	controller._start_level(1)
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = controller.board_container.global_position + Vector2(10, 10)
	controller._input(click_event)
	assert_equal(controller.selected_tile, Vector2i(0, 0), "实际鼠标事件可以选中花朵")
	controller.free()


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
