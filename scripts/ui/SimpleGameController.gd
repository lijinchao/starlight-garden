## SimpleGameController - 简化的游戏控制器（用于测试）
class_name SimpleGameController
extends Control

signal first_interaction(payload: Dictionary)
signal breeze_awakened(payload: Dictionary)
signal garden_layer_cleared(payload: Dictionary)
signal dew_bud_triggered(payload: Dictionary)
signal daily_challenge_retried(payload: Dictionary)
signal invalid_swap(payload: Dictionary)
signal level_settled(payload: Dictionary)
signal home_requested()

const AsyncUtilsScript = preload("res://scripts/utils/AsyncUtils.gd")
const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")

# 系统
var board: Board
var board_visual: BoardVisual
var level_system: LevelSystem

# UI节点
var hud_container: VBoxContainer
var moves_label: Label
var score_label: Label
var target_label: Label
var status_label: Label
var breeze_btn: Button
var home_btn: Button
var board_container: Control  # 改为Control类型
var background_rect: TextureRect
var background_tint: ColorRect

# 状态
var selected_tile: Vector2i = Vector2i(-1, -1)
var board_processing: bool = false  # 重命名以避免遮蔽基类属性
var combo_count: int = 0
var first_interaction_recorded: bool = false
var active_daily_challenge: Dictionary = {}

const FAILURE_CONTINUE_COST: int = 10
const PRE_LEVEL_BLESSING_COST: int = 12
const PRE_LEVEL_BLESSING_MOVES: int = 3
const META_UNLOCK_RUNS: int = 3

func _ready() -> void:
	# 设置Control大小
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	
	_create_ui()
	_setup_systems()
	_connect_signals()
	
	# 不在这里启动游戏，由SceneManager控制


func _input(event: InputEvent) -> void:
	if not visible or _is_board_input_blocked():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_board_pointer(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_board_pointer(event.position)


func _create_ui() -> void:
	# 创建背景
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.name = "Background"
	add_child(background_rect)

	background_tint = ColorRect.new()
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_tint.color = Color(0.96, 0.95, 1.0, 0.24)
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_tint)

	home_btn = Button.new()
	home_btn.text = "⌂"
	home_btn.tooltip_text = "返回主页"
	home_btn.custom_minimum_size = Vector2(56, 48)
	home_btn.position = Vector2(20, 20)
	home_btn.add_theme_font_size_override("font_size", 28)
	home_btn.pressed.connect(_on_home_pressed)
	add_child(home_btn)
	
	# 创建HUD容器
	hud_container = VBoxContainer.new()
	hud_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_container.position = Vector2(0, 20)
	hud_container.add_theme_constant_override("separation", 10)
	add_child(hud_container)
	
	# 步数标签
	moves_label = Label.new()
	moves_label.text = "步数: 30"
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.add_theme_font_size_override("font_size", 28)
	hud_container.add_child(moves_label)
	
	# 分数标签
	score_label = Label.new()
	score_label.text = "分数: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	hud_container.add_child(score_label)
	
	# 目标标签
	target_label = Label.new()
	target_label.text = "目标: -"
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 20)
	hud_container.add_child(target_label)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(640, 58)
	hud_container.add_child(status_label)

	breeze_btn = Button.new()
	breeze_btn.custom_minimum_size = Vector2(220, 44)
	breeze_btn.add_theme_font_size_override("font_size", 18)
	breeze_btn.pressed.connect(_on_breeze_pressed)
	hud_container.add_child(breeze_btn)
	
	# 创建棋盘容器
	var board_size = Constants.GRID_COLS * (Constants.TILE_SIZE + Constants.TILE_GAP)
	board_container = Control.new()
	board_container.custom_minimum_size = Vector2(board_size, board_size)
	board_container.size = Vector2(board_size, board_size)
	board_container.position = Vector2((750 - board_size) / 2, 330)
	add_child(board_container)

func _setup_systems() -> void:
	# 创建关卡系统
	level_system = LevelSystem.new()
	add_child(level_system)
	
	# 创建棋盘逻辑
	board = Board.new()
	board.position = Vector2(0, 0)
	board_container.add_child(board)
	
	# 创建棋盘可视化
	board_visual = BoardVisual.new()
	board_visual.position = Vector2(0, 0)
	board_container.add_child(board_visual)

func _connect_signals() -> void:
	# 棋盘逻辑信号
	board.tiles_matched.connect(_on_tiles_matched)
	board.tiles_fallen.connect(_on_tiles_fallen)
	board.chain_triggered.connect(_on_chain_triggered)
	
	# 关卡系统信号
	level_system.level_loaded.connect(_on_level_loaded)
	level_system.level_won.connect(_on_level_won)
	level_system.level_failed.connect(_on_level_failed)

func _start_level(level_id: int, bonus_moves: int = 0) -> void:
	active_daily_challenge.clear()
	visible = true
	_update_level_background(level_id)
	
	GameManager.start_level(level_id)
	InLevelAssistService.start_level(level_id)
	level_system.start_level(level_id, bonus_moves)
	board.initialize_grid(level_system.level_config)
	board_visual.initialize_grid(board.grid)
	board_visual.initialize_garden_layers(board.get_garden_layer_positions(), board.get_dew_bud_positions())
	_update_hud()
	combo_count = 0
	first_interaction_recorded = false
	if status_label:
		status_label.text = level_system.get_target_intro_text()


func _start_daily_challenge(challenge_config: Dictionary) -> void:
	active_daily_challenge = challenge_config.get("daily_challenge", {}).duplicate(true)
	visible = true
	_update_level_background(int(challenge_config.get("level_id", 4)))
	GameManager.start_level(int(challenge_config.get("level_id", 4)))
	InLevelAssistService.start_level(int(challenge_config.get("level_id", 4)))
	level_system.start_level_config(challenge_config)
	board.initialize_grid(level_system.level_config)
	board_visual.initialize_grid(board.grid)
	board_visual.initialize_garden_layers(board.get_garden_layer_positions(), board.get_dew_bud_positions())
	_update_hud()
	combo_count = 0
	first_interaction_recorded = false
	if status_label:
		var direction = "横向" if str(active_daily_challenge.get("preferred_direction", "horizontal")) == "horizontal" else "纵向"
		status_label.text = "今日推荐%s四连：晨露花苞会多扫开一圈落叶。" % direction


func _update_level_background(level_id: int) -> void:
	if background_rect:
		background_rect.texture = VisualAssetCatalogScript.get_game_background(level_id)


func _handle_board_pointer(screen_pos: Vector2) -> void:
	var local_pos = screen_pos - board_container.global_position
	var board_size = Constants.GRID_COLS * (Constants.TILE_SIZE + Constants.TILE_GAP)
	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x >= board_size or local_pos.y >= board_size:
		return

	var col = int(local_pos.x / (Constants.TILE_SIZE + Constants.TILE_GAP))
	var row = int(local_pos.y / (Constants.TILE_SIZE + Constants.TILE_GAP))
	var grid_pos = Vector2i(row, col)
	if board_visual.has_tile_at(grid_pos):
		_on_tile_clicked(grid_pos)


func _is_board_input_blocked() -> bool:
	if PopupManager.active_popups.size() > 0:
		return true

	if TutorialManager.is_tutorial_running():
		var tutorial_system = TutorialManager.tutorial_system
		if tutorial_system != null and tutorial_system.dialog_panel != null and tutorial_system.dialog_panel.visible:
			return true

	return false

# ==================== 输入处理 ====================
func _on_tile_clicked(pos: Vector2i) -> void:
	if not visible or board_processing or _is_board_input_blocked():
		return
	if not first_interaction_recorded:
		first_interaction_recorded = true
		first_interaction.emit({
			"level_id": level_system.current_level_id,
			"moves_left": level_system.moves_left
		})
	
	if selected_tile == Vector2i(-1, -1):
		# 第一次选择
		selected_tile = pos
		board_visual.highlight_tile(pos, true)
	else:
		# 第二次选择
		if pos == selected_tile:
			# 取消选择
			board_visual.highlight_tile(selected_tile, false)
			selected_tile = Vector2i(-1, -1)
		elif board.is_adjacent(selected_tile, pos):
			# 尝试交换
			_attempt_swap(selected_tile, pos)
		else:
			# 选择新元素
			board_visual.highlight_tile(selected_tile, false)
			selected_tile = pos
			board_visual.highlight_tile(pos, true)

func _attempt_swap(pos1: Vector2i, pos2: Vector2i) -> void:
	board_processing = true
	board_visual.highlight_tile(selected_tile, false)
	selected_tile = Vector2i(-1, -1)
	
	# 执行交换
	board_visual.update_tile_position(pos1, pos2)
	var turn_result = board.resolve_swap(pos1, pos2)
	
	# 检查匹配
	await AsyncUtilsScript.create_delay_tween(self, Constants.SWAP_DURATION + 0.1).finished
	if turn_result.get("matched", false):
		# 使用步数
		level_system.use_move()
		TutorialManager.notify_action_completed("wait_swap")
		# 处理匹配
		await _process_matches(turn_result)
		level_system.finish_turn()
	else:
		# 无匹配，交换回来
		board_visual.update_tile_position(pos2, pos1)
		if status_label:
			status_label.text = "没有连成 3 朵，步数不扣。"
		invalid_swap.emit({
			"level_id": level_system.current_level_id,
			"moves_left": level_system.moves_left
		})
	
	board_processing = false

# ==================== 匹配处理 ====================
func _process_matches(turn_result: Dictionary) -> void:
	combo_count = 0
	
	for chain_data in turn_result.get("chains", []):
		combo_count += 1
		
		# 显示匹配动画并收集分数
		for match_data in chain_data["matches"]:
			var positions = match_data["positions"]
			var tile_type = match_data["type"]
			
			# 收集元素
			level_system.collect_tiles(tile_type, positions.size())
			
			# 增加分数
			var score = positions.size() * Constants.BASE_SCORE_PER_TILE
			if combo_count > 1:
				score = int(score * pow(Constants.COMBO_MULTIPLIER, combo_count - 1))
			level_system.add_score(score)

		var cleared_layers: Array = chain_data.get("garden_cleared", [])
		var dew_bursts: Array = chain_data.get("dew_bursts", [])
		var breeze_paths: Array = chain_data.get("breeze_paths", [])
		if not cleared_layers.is_empty():
			level_system.clear_garden_layers(cleared_layers.size())
			garden_layer_cleared.emit({
				"cleared_count": cleared_layers.size(),
				"directional": not breeze_paths.is_empty(),
				"level_id": level_system.current_level_id,
				"moves_left": level_system.moves_left,
				"remaining": level_system.garden_layers_total - level_system.garden_layers_cleared
			})
		if not dew_bursts.is_empty():
			level_system.record_dew_bud_bursts(dew_bursts)
			for burst in dew_bursts:
				AudioManager.play_combo(mini(7, int(burst.get("chain_index", 1)) + 1))
				dew_bud_triggered.emit({
					"level_id": level_system.current_level_id,
					"position": burst.get("position", Vector2i(-1, -1)),
					"chain_index": int(burst.get("chain_index", 1)),
					"extra_cleared": (burst.get("cleared_positions", []) as Array).size(),
					"moves_left": level_system.moves_left
				})
		if not cleared_layers.is_empty() or not breeze_paths.is_empty() or not dew_bursts.is_empty():
			await board_visual.show_garden_layer_clear(cleared_layers, breeze_paths, dew_bursts)

		var awakening_count = int(chain_data.get("awakening_count", 0))
		if awakening_count > 0:
			var awakening_result = level_system.apply_breeze_awakening(awakening_count)
			var focus_name = str(awakening_result.get("focus_name", level_system.get_theme_progress_snapshot().get("focus_name", "花圃")))
			board_visual.show_awakening_animation(
				_collect_awakening_positions(chain_data.get("awakening_matches", [])),
				focus_name,
				str(awakening_result.get("breeze_label", "清风唤醒"))
			)
			if status_label:
				status_label.text = "清风吹开了「%s」，目标推进 +%d" % [
					focus_name,
					int(awakening_result.get("bonus_progress", 0))
				]
			breeze_awakened.emit({
				"awakening_count": awakening_count,
				"bonus_progress": int(awakening_result.get("bonus_progress", 0)),
				"garden_layers_cleared": cleared_layers.size(),
				"path_count": breeze_paths.size(),
				"focus_name": focus_name,
				"level_id": level_system.current_level_id,
				"moves_left": level_system.moves_left
			})
			await AsyncUtilsScript.create_delay_tween(self, 0.35).finished
		elif not dew_bursts.is_empty() and status_label:
			status_label.text = "晨露连锁 x%d · 额外扫开 %d 处落叶" % [
				int(dew_bursts.back().get("chain_index", 1)),
				maxi(0, cleared_layers.size() - dew_bursts.size())
			]
		
		# 显示消除动画（等待完成）
		for match_data in chain_data["matches"]:
			await board_visual.show_match_animation(match_data["positions"])
		
		# 下落填充
		await board_visual.show_fall_animation(chain_data["movements"])
		await board_visual.show_new_tiles(chain_data["new_tiles"])
		await AsyncUtilsScript.create_delay_tween(self, 0.3).finished
		
		# 更新UI
		_update_hud()
	
	combo_count = 0
	if turn_result.get("chain_capped", false):
		await board_visual.show_reshuffle_animation(board.grid)
		if status_label:
			status_label.text = "连锁太旺，花园已经轻轻整理好棋盘。"
	else:
		board_visual.sync_with_grid(board.grid)

# ==================== UI更新 ====================
func _update_hud() -> void:
	if moves_label:
		moves_label.text = "步数: %d" % level_system.moves_left
	if score_label:
		score_label.text = "分数: %d" % level_system.current_score
	if target_label:
		target_label.text = level_system.get_target_progress_text()
	if status_label and status_label.text.is_empty():
		status_label.text = level_system.get_target_intro_text()
	_update_breeze_button()


func _update_breeze_button() -> void:
	if not breeze_btn:
		return
	var unlocked = MetaUnlockService.is_unlocked(MetaUnlockService.FEATURE_STAR_BLESSING)
	breeze_btn.visible = unlocked
	if not unlocked:
		return
	var remaining = InLevelAssistService.get_breeze_uses_remaining()
	breeze_btn.text = "星光微风 %d✨ (%d/%d)" % [
		InLevelAssistService.BREEZE_COST,
		remaining,
		InLevelAssistService.BREEZE_MAX_USES_PER_LEVEL
	]
	breeze_btn.disabled = remaining <= 0 or not level_system.is_level_active


func _on_breeze_pressed() -> void:
	if not MetaUnlockService.is_unlocked(MetaUnlockService.FEATURE_STAR_BLESSING):
		PopupManager.show_toast("先完成前三局，让花园先恢复呼吸。")
		return
	if board_processing:
		PopupManager.show_toast("稍等花朵落定后再试")
		return

	var hint = board.find_valid_move()
	if hint.is_empty():
		PopupManager.show_toast("花园正在整理棋盘，暂时没有提示")
		return

	var result = InLevelAssistService.try_use_breeze()
	if not result.get("success", false):
		PopupManager.show_toast(_get_breeze_error_message(str(result.get("reason", ""))))
		_update_breeze_button()
		return

	board_visual.show_hint(hint["pos1"], hint["pos2"])
	if target_label:
		target_label.text = "星光微风指向了一步温柔交换"
	_update_breeze_button()


func _on_home_pressed() -> void:
	if board_processing:
		PopupManager.show_toast("稍等花朵落定后再返回")
		return
	home_requested.emit()


func cancel_level() -> void:
	if selected_tile != Vector2i(-1, -1) and board_visual:
		board_visual.highlight_tile(selected_tile, false)
	selected_tile = Vector2i(-1, -1)
	board_processing = false
	if level_system:
		level_system.is_level_active = false


func _get_breeze_error_message(reason: String) -> String:
	match reason:
		"not_enough_stars":
			return "星光不足，先去闯关或收获花朵吧"
		"limit_reached":
			return "本局微风已经吹过了"
		_:
			return "星光微风暂时不可用"

# ==================== 信号回调 ====================
func _on_tiles_matched(_positions: Array, _tile_type: int) -> void:
	pass

func _on_tiles_fallen() -> void:
	pass

func _on_chain_triggered(_chain_count: int) -> void:
	pass

func _on_level_loaded(_level_data: Dictionary) -> void:
	_update_hud()

func _on_level_won(stars: int, score: int) -> void:
	if not active_daily_challenge.is_empty():
		_settle_daily_challenge(true, score)
		return
	var settlement = SettlementService.build_victory_settlement(
		level_system.current_level_id,
		stars,
		score,
		level_system.level_config,
		{"theme_progress": level_system.get_theme_progress_snapshot()}
	)
	SettlementService.apply_victory_settlement(settlement)
	level_settled.emit(_build_playtest_settlement_payload(settlement))

	if target_label:
		target_label.text = "🎉 恭喜过关！"
	if status_label:
		status_label.text = "这阵清风让花园更亮了一点。"

	PopupManager.show_victory(
		settlement,
		func() -> void:
			if int(settlement.get("player_total_runs_after", 0)) <= META_UNLOCK_RUNS:
				GameManager.open_garden(settlement)
				return
			_start_level(level_system.current_level_id + 1)
	)

func _on_level_failed() -> void:
	if not active_daily_challenge.is_empty():
		_settle_daily_challenge(false, level_system.current_score)
		return
	var settlement = SettlementService.build_failure_settlement(
		level_system,
		FAILURE_CONTINUE_COST,
		{"theme_progress": level_system.get_theme_progress_snapshot()}
	)
	SettlementService.apply_failure_settlement(settlement)
	level_settled.emit(_build_playtest_settlement_payload(settlement))

	if target_label:
		target_label.text = "💫 进入休息时刻"
	if status_label:
		status_label.text = "今天也把花园照料了一点。"

	var continue_action = func() -> void:
		if SettlementService.try_continue_level(level_system, FAILURE_CONTINUE_COST, 5):
			target_label.text = "✨ 已恢复 5 步"
			_update_hud()
			PopupManager.close_popup("failure")
		else:
			PopupManager.show_toast("星光不足，无法继续挑战")

	var rest_action = func() -> void:
		PopupManager.close_popup("failure")
		GameManager.open_garden(settlement)

	PopupManager.show_failure(
		settlement,
		continue_action,
		rest_action
	)


func _collect_awakening_positions(awakening_matches: Array) -> Array:
	var positions: Array = []
	for match_data in awakening_matches:
		for pos in match_data.get("positions", []):
			positions.append(pos)
	return positions


func _build_playtest_settlement_payload(settlement: Dictionary) -> Dictionary:
	var theme_progress = settlement.get("theme_progress", {})
	return {
		"awakening_count": int(theme_progress.get("awakenings", 0)),
		"garden_layers_cleared": int(theme_progress.get("garden_layers_cleared", 0)),
		"garden_layers_total": int(theme_progress.get("garden_layers_total", 0)),
		"dew_buds_triggered": int(theme_progress.get("dew_buds_triggered", 0)),
		"max_dew_chain": int(theme_progress.get("max_dew_chain", 0)),
		"level_id": int(settlement.get("level_id", level_system.current_level_id)),
		"moves_left": level_system.moves_left,
		"outcome": str(settlement.get("outcome", "unknown")),
		"player_total_runs_after": int(settlement.get("player_total_runs_after", 0)),
		"progress_ratio": float(settlement.get("progress_ratio", 1.0))
	}


func _settle_daily_challenge(won: bool, score: int) -> void:
	var theme_progress = level_system.get_theme_progress_snapshot()
	var result = DailyChallengeService.record_result(active_daily_challenge, won, level_system.moves_left, theme_progress)
	var payload = {
		"outcome": "victory" if won else "failure",
		"is_daily_challenge": true,
		"challenge_id": str(active_daily_challenge.get("challenge_id", "")),
		"layout_id": str(active_daily_challenge.get("layout_id", "")),
		"preferred_direction": str(active_daily_challenge.get("preferred_direction", "")),
		"moves_left": level_system.moves_left,
		"score": score,
		"max_dew_chain": int(theme_progress.get("max_dew_chain", 0)),
		"garden_layers_cleared": int(theme_progress.get("garden_layers_cleared", 0)),
		"garden_layers_total": int(theme_progress.get("garden_layers_total", 0)),
		"attempts": int(result.get("attempts", 0))
	}
	level_settled.emit(payload)
	if won:
		PopupManager.show_confirm(
			"今日风庭完成",
			"晨露最大连锁 x%d，剩余 %d 步。今日可随时再试，挑战更高连锁。" % [int(theme_progress.get("max_dew_chain", 0)), level_system.moves_left],
			func() -> void: GameManager.go_to_menu()
		)
		return
	PopupManager.show_confirm(
		"今日风庭未完成",
		"已扫开 %d/%d 片落叶。重试会保留同一布局与初始棋盘。" % [int(theme_progress.get("garden_layers_cleared", 0)), int(theme_progress.get("garden_layers_total", 0))],
		func() -> void:
			daily_challenge_retried.emit({
				"challenge_id": str(active_daily_challenge.get("challenge_id", "")),
				"last_max_dew_chain": int(theme_progress.get("max_dew_chain", 0)),
				"last_leaf_ratio": float(theme_progress.get("garden_layers_cleared", 0)) / maxi(1, int(theme_progress.get("garden_layers_total", 0)))
			})
			_start_daily_challenge(DailyChallengeService.get_today_challenge().get("config", {})),
		func() -> void: GameManager.go_to_menu()
	)
