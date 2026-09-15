## PuzzleDepthProbe - 迭代 P 关卡深度探针
##
## 目标级问题：这一关到底有没有一个“需要计划才找得到”的解？
##
## 做法：让两个机器人跑同一关的同一批种子，比较通关率：
##   - greedy : 无前瞻。能打到石块就立刻打，见到能用的清风块就立刻点，从不攒。
##   - patient: 会攒清风块。只有在一击能扫到 >= 2 块石块时才点，
##              并优先制造“所在行/列还有 >= 2 块石块”的四连。
##
## 判据：贪心过不了、但规划能过 => 这关有意图解（需要计划）。
##       贪心也能过              => 这关没有可找的计划。
##       两个都过不了            => 只是难/不可解，不算深度。
##
## 只读取棋盘状态，不改动游戏代码；供目标级测试调用。

extends Node

const POLICY_GREEDY := "greedy"
const POLICY_PATIENT := "patient"

const BLOCKER_HIT_WEIGHT := 10.0
const LINE_BLOCKER_WEIGHT := 8.0


func measure(level_config: Dictionary, policy: String, runs: int, base_seed: int = 1000) -> Dictionary:
	var cleared_runs := 0
	var total_moves := 0
	var best_moves := -1
	var created_total := 0
	var tapped_total := 0
	var special_breaks_total := 0
	for index in range(runs):
		var config: Dictionary = level_config.duplicate(true)
		config["board_seed"] = base_seed + index
		var board := Board.new()
		add_child(board)
		board.initialize_grid(config)
		var result := _play(board, config, policy)
		board.free()
		created_total += int(result.get("specials_created", 0))
		tapped_total += int(result.get("specials_tapped", 0))
		special_breaks_total += int(result.get("blockers_broken_total", 0))
		if bool(result.get("cleared", false)):
			cleared_runs += 1
			var used := int(result.get("moves_used", 0))
			total_moves += used
			if best_moves < 0 or used < best_moves:
				best_moves = used
	return {
		"policy": policy,
		"runs": runs,
		"cleared_runs": cleared_runs,
		"clear_rate": float(cleared_runs) / float(maxi(1, runs)),
		"avg_moves_when_cleared": float(total_moves) / float(maxi(1, cleared_runs)),
		"best_moves": best_moves,
		"specials_created": created_total,
		"specials_tapped": tapped_total,
		"blockers_broken_total": special_breaks_total
	}


func _play(board: Board, level_config: Dictionary, policy: String) -> Dictionary:
	var moves_total := int(level_config.get("moves", Constants.MAX_MOVES_DEFAULT))
	var moves_used := 0
	var guard := 0
	var created := 0
	var tapped := 0
	var special_breaks := 0
	while guard < 500:
		guard += 1
		if _is_cleared(board, level_config):
			return _sample(true, moves_used, created, tapped, special_breaks)
		if moves_used >= moves_total:
			break
		var action := _choose_action(board, policy, moves_total - moves_used)
		if action.is_empty():
			if board.has_valid_moves():
				var fallback := _first_valid_move(board)
				if fallback.is_empty():
					break
				action = fallback
			else:
				board.shuffle_board()
				continue
		var outcome := _apply_action(board, action)
		created += int(outcome.get("created", 0))
		tapped += int(outcome.get("tapped", 0))
		special_breaks += int(outcome.get("special_breaks", 0))
		if bool(outcome.get("consumes", false)):
			moves_used += 1
	return _sample(_is_cleared(board, level_config), moves_used, created, tapped, special_breaks)


func _sample(cleared: bool, moves_used: int, created: int, tapped: int, special_breaks: int) -> Dictionary:
	return {
		"cleared": cleared,
		"moves_used": moves_used,
		"specials_created": created,
		"specials_tapped": tapped,
		"blockers_broken_total": special_breaks
	}


func _choose_action(board: Board, policy: String, moves_left: int) -> Dictionary:
	var best_tap := _best_tap(_special_taps(board))
	var is_patient := policy == POLICY_PATIENT

	# 规划型：只有一击清 >= 2 块才肯点，这就是“攒清风”的延迟满足
	if is_patient and not best_tap.is_empty() and int(best_tap["blockers"]) >= 2:
		return {"type": "special", "position": best_tap["position"]}
	# 贪心：清风只要能打到一块就立刻点，从不留
	if not is_patient and not best_tap.is_empty() and int(best_tap["blockers"]) >= 1:
		return {"type": "special", "position": best_tap["position"]}
	# 规划型：步数将尽，不再等待
	if is_patient and moves_left <= 2 and not best_tap.is_empty() and int(best_tap["blockers"]) >= 1:
		return {"type": "special", "position": best_tap["position"]}

	var best_swap := _best_swap_lookahead(board) if is_patient else _best_swap(board, false)
	if not best_swap.is_empty():
		return best_swap
	if not best_tap.is_empty() and int(best_tap["blockers"]) >= 1:
		return {"type": "special", "position": best_tap["position"]}
	return {}


func _apply_action(board: Board, action: Dictionary) -> Dictionary:
	var stats := {"created": 0, "tapped": 0, "special_breaks": 0}
	if str(action.get("type", "")) == "special":
		var tap_result = board.activate_special(action["position"])
		stats["tapped"] = 1
		_accumulate_chain_stats(tap_result, stats)
		stats["consumes"] = false  # 点击清风不消耗步数
		return stats
	var result = board.resolve_swap(action["pos1"], action["pos2"])
	_accumulate_chain_stats(result, stats)
	stats["consumes"] = bool(result.get("matched", false))
	return stats


func _accumulate_chain_stats(result: Dictionary, stats: Dictionary) -> void:
	for chain in result.get("chains", []):
		stats["created"] += (chain.get("specials_created", []) as Array).size()
		stats["special_breaks"] += (chain.get("blockers_broken", []) as Array).size()


func _is_cleared(board: Board, level_config: Dictionary) -> bool:
	var target: Dictionary = level_config.get("target", {})
	if str(target.get("type", "")) == "clear_blockers":
		return board.get_blocker_positions().is_empty()
	var layer: Dictionary = target.get("garden_layer", {})
	if not layer.is_empty() and bool(layer.get("required_for_clear", false)):
		return board.get_garden_layer_positions().is_empty()
	return false


func _special_taps(board: Board) -> Array:
	var taps: Array = []
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var direction := board.get_special_at(Vector2i(row, col))
			if direction.is_empty():
				continue
			taps.append({
				"position": Vector2i(row, col),
				"blockers": _blockers_on_line(board, Vector2i(row, col), direction)
			})
	return taps


func _best_tap(taps: Array) -> Dictionary:
	var best: Dictionary = {}
	for tap in taps:
		if best.is_empty() or int(tap["blockers"]) > int(best["blockers"]):
			best = tap
	return best


func _blockers_on_line(board: Board, anchor: Vector2i, direction: String) -> int:
	var count := 0
	if direction == "row":
		for col in range(Constants.GRID_COLS):
			if board.blocker_cells.has(Vector2i(anchor.x, col)):
				count += 1
	else:
		for row in range(Constants.GRID_ROWS):
			if board.blocker_cells.has(Vector2i(row, anchor.y)):
				count += 1
	return count


func _best_swap(board: Board, include_setup: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1.0
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var p1 := Vector2i(row, col)
			for offset in [Vector2i(0, 1), Vector2i(1, 0)]:
				var p2: Vector2i = p1 + offset
				if p2.x >= Constants.GRID_ROWS or p2.y >= Constants.GRID_COLS:
					continue
				if board.grid[p1.x][p1.y] == Constants.TileType.BLOCKER:
					continue
				if board.grid[p2.x][p2.y] == Constants.TileType.BLOCKER:
					continue
				board.swap_tiles(p1, p2)
				var matches = board.find_all_matches()
				board.swap_tiles(p1, p2)
				if matches.is_empty():
					continue
				var score := _score_matches(board, matches, include_setup)
				if score > best_score:
					best_score = score
					best = {"type": "swap", "pos1": p1, "pos2": p2}
	return best


func _score_matches(board: Board, matches: Array, include_setup: bool) -> float:
	var hit: Dictionary = {}
	var cleared := 0
	var setup := 0.0
	for match_data in matches:
		var positions: Array = match_data.get("positions", [])
		cleared += positions.size()
		for pos in positions:
			for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var neighbor: Vector2i = pos + offset
				if board.blocker_cells.has(neighbor):
					hit[neighbor] = true
		if include_setup and positions.size() >= 4:
			var direction := str(board._infer_direction(positions))
			if not direction.is_empty():
				var line_blockers := _blockers_on_line(board, positions[0], direction)
				if line_blockers >= 2:
					setup = maxf(setup, float(line_blockers) * LINE_BLOCKER_WEIGHT)
	return float(hit.size()) * BLOCKER_HIT_WEIGHT + float(cleared) + setup


# 规划型的 1 步前瞻：模拟每一手后，看新盘面里还留着多少“可被清风扫到的石块”。
func _best_swap_lookahead(board: Board) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1.0
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var p1 := Vector2i(row, col)
			for offset in [Vector2i(0, 1), Vector2i(1, 0)]:
				var p2: Vector2i = p1 + offset
				if p2.x >= Constants.GRID_ROWS or p2.y >= Constants.GRID_COLS:
					continue
				if board.grid[p1.x][p1.y] == Constants.TileType.BLOCKER:
					continue
				if board.grid[p2.x][p2.y] == Constants.TileType.BLOCKER:
					continue
				board.swap_tiles(p1, p2)
				var matches = board.find_all_matches()
				board.swap_tiles(p1, p2)
				if matches.is_empty():
					continue
				var snapshot := _snapshot(board)
				var result = board.resolve_swap(p1, p2)
				var broken := 0
				for chain in result.get("chains", []):
					broken += (chain.get("blockers_broken", []) as Array).size()
				var future := 0
				for tap in _special_taps(board):
					future = maxi(future, int(tap["blockers"]))
				_restore(board, snapshot)
				var score := float(broken) * BLOCKER_HIT_WEIGHT + float(future) * LINE_BLOCKER_WEIGHT
				if score > best_score:
					best_score = score
					best = {"type": "swap", "pos1": p1, "pos2": p2}
	return best


func _snapshot(board: Board) -> Dictionary:
	return {
		"grid": board.grid.duplicate(true),
		"special_grid": board.special_grid.duplicate(true),
		"blocker_cells": board.blocker_cells.duplicate(true),
		"blocker_hp": board.blocker_hp.duplicate(true),
		"garden_layers": board.garden_layers.duplicate(true),
		"dew_buds": board.dew_buds.duplicate(true)
	}


func _restore(board: Board, snapshot: Dictionary) -> void:
	board.grid = snapshot["grid"]
	board.special_grid = snapshot["special_grid"]
	board.blocker_cells = snapshot["blocker_cells"]
	board.blocker_hp = snapshot["blocker_hp"]
	board.garden_layers = snapshot["garden_layers"]
	board.dew_buds = snapshot["dew_buds"]


func _first_valid_move(board: Board) -> Dictionary:
	for row in range(Constants.GRID_ROWS):
		for col in range(Constants.GRID_COLS):
			var p1 := Vector2i(row, col)
			for offset in [Vector2i(0, 1), Vector2i(1, 0)]:
				var p2: Vector2i = p1 + offset
				if p2.x >= Constants.GRID_ROWS or p2.y >= Constants.GRID_COLS:
					continue
				var move = board._evaluate_potential_move(p1, p2)
				if not move.is_empty():
					return {"type": "swap", "pos1": p1, "pos2": p2}
	return {}
