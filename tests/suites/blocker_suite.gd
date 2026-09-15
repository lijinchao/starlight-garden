## Blocker suite - 迭代 P / B-3 不可移动石块（目标级验收测试）
extends "res://tests/suites/test_suite.gd"


func test_blocker_obstacles() -> void:
	SaveManager.reset_save()

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(6)
	var target = level_system.level_config.get("target", {})
	assert_equal(str(target.get("type", "")), "clear_blockers", "第6关是清光石块的单一目标")
	assert_true((target.get("blockers", []) as Array).size() > 0, "第6关配置了石块")
	assert_equal(level_system.blockers_total, (target.get("blockers", []) as Array).size(), "石块总数来自配置")
	assert_true(not level_system._check_win_condition(), "石块未清光时不能通关")
	assert_true(level_system.get_target_progress_text().contains("石块"), "HUD 显示石块进度")
	level_system.clear_blockers(level_system.blockers_total)
	assert_true(level_system._check_win_condition(), "清光石块后可以通关")
	level_system.free()

	var board = Board.new()
	add_child(board)
	board.initialize_grid({
		"available_types": [1, 2, 3],
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[3, 3]]}
	})
	assert_equal(board.get_blocker_positions().size(), 1, "棋盘放置配置中的石块")
	assert_equal(board.grid[3][3], Constants.TileType.BLOCKER, "石块占据该格")

	for match_data in board.find_all_matches():
		assert_true(not match_data["positions"].has(Vector2i(3, 3)), "石块不参与匹配")

	var swap_result = board.resolve_swap(Vector2i(3, 3), Vector2i(3, 4))
	assert_true(not swap_result.get("matched", true), "石块不能被交换")
	assert_equal(board.grid[3][3], Constants.TileType.BLOCKER, "交换失败后石块仍在原位")

	board.grid[3][0] = 1
	board.grid[3][1] = 1
	board.grid[3][2] = 1
	var first_hit = board._resolve_blockers([{"type": 1, "positions": [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)]}])
	assert_equal((first_hit.get("damaged", []) as Array).size(), 1, "相邻消除把石块敲到裂开")
	assert_equal((first_hit.get("broken", []) as Array).size(), 0, "相邻消除不会击碎石块")
	assert_equal(board.get_blocker_hp(Vector2i(3, 3)), 1, "敲裂后石块只剩 1 点耐久")
	board.grid[3][0] = 1
	board.grid[3][1] = 1
	board.grid[3][2] = 1
	var second_hit = board._resolve_blockers([{"type": 1, "positions": [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)]}])
	assert_equal((second_hit.get("broken", []) as Array).size(), 0, "再敲一次也击不碎")
	assert_equal(board.get_blocker_positions().size(), 1, "裂开的石块仍在盘面，只有清风能击碎")
	board.free()
	SaveManager.reset_save()


func test_blocker_only_breeze_breaks() -> void:
	var board = Board.new()
	add_child(board)
	board.initialize_grid({
		"available_types": [1, 2, 3],
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[3, 3]]}
	})
	board.grid[3][0] = 1
	board.grid[3][1] = 1
	board.grid[3][2] = 1
	var first_match = {"type": 1, "positions": [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)]}
	board._resolve_blockers([first_match])
	assert_equal(board.get_blocker_hp(Vector2i(3, 3)), 1, "相邻消除先把石块敲裂")

	board.grid[4][2] = 1
	board.grid[4][3] = 1
	board.grid[4][4] = 1
	var second_match = {"type": 1, "positions": [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)]}
	board._resolve_blockers([second_match])
	assert_equal(board.get_blocker_positions().size(), 1, "相邻消除敲两次也击不碎石块")
	assert_equal(board.get_blocker_hp(Vector2i(3, 3)), 1, "石块停在裂开状态")

	board.special_grid[3][5] = "row"
	board.grid[3][5] = 1
	board.activate_special(Vector2i(3, 5))
	assert_equal(board.get_blocker_positions().size(), 0, "只有清风能击碎石块")
	board.free()


func test_breeze_breaks_blocker() -> void:
	var board = Board.new()
	add_child(board)
	board.initialize_grid({
		"available_types": [1, 2, 3],
		"board_seed": 7,
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[3, 3]]}
	})
	board.special_grid[3][0] = "row"
	board.grid[3][0] = 1
	var result = board.activate_special(Vector2i(3, 0))
	assert_equal(board.get_blocker_positions().size(), 0, "清风扫过会击碎石块")
	var reported = false
	for chain in result.get("chains", []):
		for pos in chain.get("blockers_broken", []):
			if pos == Vector2i(3, 3):
				reported = true
	assert_true(reported, "清风击碎的石块必须计入击碎列表，否则进度不更新")
	board.free()


func test_special_tap_cascades() -> void:
	for seed in range(1, 11):
		var board = Board.new()
		add_child(board)
		board.initialize_grid({
			"available_types": [1, 2, 3, 4],
			"board_seed": seed,
			"target": {"type": "clear_blockers", "requirements": [], "blockers": []}
		})
		board.special_grid[3][3] = "row"
		board.grid[3][3] = 1
		board.activate_special(Vector2i(3, 3))
		assert_true(board.find_all_matches().is_empty(), "种子 %d：触发清风后不应残留未消的三连" % seed)
		board.free()


func test_blocker_damage_visual() -> void:
	var board_visual = BoardVisual.new()
	add_child(board_visual)
	board_visual.set_blockers([Vector2i(1, 1), Vector2i(2, 2)], {Vector2i(1, 1): 2, Vector2i(2, 2): 1})
	var intact = board_visual.blocker_markers[Vector2i(1, 1)]
	var damaged = board_visual.blocker_markers[Vector2i(2, 2)]
	assert_true(intact.modulate == Color(1, 1, 1, 1), "完好的石块没有受损色")
	assert_true(damaged.modulate != Color(1, 1, 1, 1), "裂开的石块有可见的受损色")
	assert_true(damaged.get_child_count() > 0, "裂开的石块带裂痕标记")
	board_visual.free()


func test_blocker_gravity() -> void:
	var board = Board.new()
	add_child(board)
	board.initialize_grid({
		"available_types": [1, 2, 3],
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[3, 3]]}
	})
	var below_before: Array = []
	for row in range(4, Constants.GRID_ROWS):
		below_before.append(board.grid[row][3])
	for row in range(0, 3):
		board.grid[row][3] = Constants.TileType.NONE
	board._drop_and_fill_collect()
	assert_equal(board.grid[3][3], Constants.TileType.BLOCKER, "石块不会随下落移动")
	var below_after: Array = []
	for row in range(4, Constants.GRID_ROWS):
		below_after.append(board.grid[row][3])
	assert_equal(below_after, below_before, "石块下方的棋子不受上方下落影响")
	for row in range(0, 3):
		assert_true(board.grid[row][3] != Constants.TileType.NONE, "石块上方被补满")
	board.free()

func test_one_move_chips_blocker_once() -> void:
	# 目标：一次移动（一次交换）对同一石块最多结算一次伤害。
	# 连锁掉落重新凑成的消除不能再敲同一块石头。
	var blocker := Vector2i(3, 3)
	var checked := 0
	var multi_hit_samples := 0
	for seed in range(1, 40):
		var scout = _make_blocker_board(seed, blocker)
		var moves = _collect_valid_moves(scout)
		scout.free()
		for move in moves.slice(0, 10):
			var board = _make_blocker_board(seed, blocker)
			var hp_before = board.get_blocker_hp(blocker)
			var result = board.resolve_swap(move["pos1"], move["pos2"])
			var used_special := false
			for chain in result.get("chains", []):
				if not (chain.get("specials_triggered", []) as Array).is_empty():
					used_special = true
			var adjacent_hits = _count_adjacent_chain_hits(result, blocker)
			var hp_after = board.get_blocker_hp(blocker)
			board.free()
			if used_special:
				continue
			checked += 1
			if adjacent_hits >= 2:
				multi_hit_samples += 1
			assert_true(hp_before - hp_after <= 1, "种子 %d：一次移动不能让同一石块掉超过 1 点耐久" % seed)
	assert_greater(float(checked), 0.0, "至少检查到一个不涉及清风的有效移动")
	assert_greater(float(multi_hit_samples), 0.0, "至少找到一个“一次移动内两次相邻命中同一石块”的样本，否则没覆盖目标场景")


func _make_blocker_board(seed: int, blocker: Vector2i) -> Board:
	var board = Board.new()
	add_child(board)
	board.initialize_grid({
		"available_types": [1, 2, 3],
		"board_seed": seed,
		"target": {"type": "clear_blockers", "requirements": [], "blockers": [[blocker.x, blocker.y]]}
	})
	return board


func _collect_valid_moves(board: Board) -> Array:
	var moves: Array = []
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var p1 := Vector2i(row, col)
			for offset in [Vector2i(0, 1), Vector2i(1, 0)]:
				var p2: Vector2i = p1 + offset
				if p2.x >= Constants.GRID_ROWS or p2.y >= Constants.GRID_COLS:
					continue
				var move = board._evaluate_potential_move(p1, p2)
				if not move.is_empty():
					moves.append({"pos1": p1, "pos2": p2})
	return moves


func _count_adjacent_chain_hits(result: Dictionary, blocker: Vector2i) -> int:
	var hits := 0
	for chain in result.get("chains", []):
		var adjacent := false
		for match_data in chain.get("matches", []):
			for pos in match_data.get("positions", []):
				if abs(pos.x - blocker.x) + abs(pos.y - blocker.y) == 1:
					adjacent = true
		if adjacent:
			hits += 1
	return hits
