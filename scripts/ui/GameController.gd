## GameController - 游戏控制器（带音效集成）
class_name GameController
extends Control

const AsyncUtilsScript = preload("res://scripts/utils/AsyncUtils.gd")

# 系统
var board: Board
var board_visual: BoardVisual
var level_system: LevelSystem

# UI节点（动态创建）
var hud_container: VBoxContainer
var moves_label: Label
var score_label: Label
var target_label: Label
var combo_label: Label
var status_label: Label
var board_container: Node2D

# 状态
var selected_tile: Vector2i = Vector2i(-1, -1)
var is_processing_tile: bool = false
var combo_count: int = 0

const FAILURE_CONTINUE_COST: int = 10
const PRE_LEVEL_BLESSING_COST: int = 12
const PRE_LEVEL_BLESSING_MOVES: int = 3

func _ready() -> void:
	_create_ui()
	_setup_systems()
	_connect_signals()
	_start_level(1)
	
	# 播放背景音乐
	AudioManager.play_bgm()

func _create_ui() -> void:
	# 创建背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.98, 0.95, 0.98, 1)
	add_child(bg)
	
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
	
	# 连击标签
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 36)
	combo_label.modulate.a = 0
	hud_container.add_child(combo_label)
	
	# 状态标签
	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	hud_container.add_child(status_label)
	
	# 创建棋盘容器
	board_container = Node2D.new()
	board_container.position = Vector2(375, 750)
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
	board_visual.position = Vector2(
		int(Constants.GRID_COLS * (Constants.TILE_SIZE + Constants.TILE_GAP) / -2.0),
		int(Constants.GRID_ROWS * (Constants.TILE_SIZE + Constants.TILE_GAP) / -2.0)
	)
	board_container.add_child(board_visual)

func _connect_signals() -> void:
	# 棋盘可视化信号
	board_visual.tile_clicked.connect(_on_tile_clicked)
	
	# 棋盘逻辑信号
	board.tiles_matched.connect(_on_tiles_matched)
	board.tiles_fallen.connect(_on_tiles_fallen)
	board.chain_triggered.connect(_on_chain_triggered)
	
	# 关卡系统信号
	level_system.level_loaded.connect(_on_level_loaded)
	level_system.level_won.connect(_on_level_won)
	level_system.level_failed.connect(_on_level_failed)

func _start_level(level_id: int, bonus_moves: int = 0) -> void:
	GameManager.start_level(level_id)
	level_system.start_level(level_id, bonus_moves)
	board.initialize_grid(level_system.level_config)
	board_visual.initialize_grid(board.grid)
	_update_hud()
	combo_count = 0
	status_label.text = ""

# ==================== 输入处理 ====================
func _on_tile_clicked(pos: Vector2i) -> void:
	if is_processing_tile:
		return
	
	# 播放点击音效
	AudioManager.play_ui_click()
	
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
	is_processing_tile = true
	board_visual.highlight_tile(selected_tile, false)
	selected_tile = Vector2i(-1, -1)
	
	# 播放交换音效
	AudioManager.play_swap()
	
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
	else:
		# 无匹配，交换回来
		board_visual.update_tile_position(pos2, pos1)
	
	is_processing_tile = false

# ==================== 匹配处理 ====================
func _process_matches(turn_result: Dictionary) -> void:
	combo_count = 0
	
	for chain_data in turn_result.get("chains", []):
		combo_count += 1
		
		# 播放消除音效
		if combo_count == 1:
			AudioManager.play_match()
		else:
			AudioManager.play_combo(combo_count)
		
		# 收集分数
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
		
		# 显示消除动画（等待完成）
		for match_data in chain_data["matches"]:
			await board_visual.show_match_animation(match_data["positions"])
		
		# 显示连击
		if combo_count > 1:
			_show_combo(combo_count)
		
		# 下落填充
		AudioManager.play_fall()
		await board_visual.show_fall_animation(chain_data["movements"])
		await board_visual.show_new_tiles(chain_data["new_tiles"])
		board_visual.sync_with_grid(board.grid)
		
		# 更新UI
		_update_hud()
	
	combo_count = 0

# ==================== UI更新 ====================
func _update_hud() -> void:
	if moves_label:
		moves_label.text = "步数: %d" % level_system.moves_left
	if score_label:
		score_label.text = "分数: %d" % level_system.current_score
	if target_label:
		target_label.text = level_system.get_target_progress_text()

func _show_combo(count: int) -> void:
	if not combo_label:
		return
	
	var texts = ["", "", "Good!", "Great!", "Amazing!", "Fantastic!", "Incredible!"]
	var text = texts[mini(count, texts.size() - 1)]
	
	combo_label.text = "x%d %s" % [count, text]
	combo_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_interval(0.5)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.3)

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
	print("Level Won! Stars: %d, Score: %d" % [stars, score])
	
	# 播放胜利音效
	AudioManager.play_victory()
	var settlement = SettlementService.build_victory_settlement(
		level_system.current_level_id,
		stars,
		score,
		level_system.level_config
	)
	SettlementService.apply_victory_settlement(settlement)
	
	if status_label:
		status_label.text = "🎉 恭喜过关！"
	PopupManager.show_victory(
		settlement,
		func() -> void:
			_start_level(level_system.current_level_id + 1),
		func() -> void:
			_start_level(level_system.current_level_id + 1)
	)

func _on_level_failed() -> void:
	print("Level Failed!")
	
	# 播放失败音效
	AudioManager.play_failure()
	var settlement = SettlementService.build_failure_settlement(level_system, FAILURE_CONTINUE_COST)
	SettlementService.apply_failure_settlement(settlement)
	
	if status_label:
		status_label.text = "💫 进入休息时刻"

	var continue_action = func() -> void:
		if SettlementService.try_continue_level(level_system, FAILURE_CONTINUE_COST, 5):
			status_label.text = "✨ 星光鼓励你继续前行"
			_update_hud()
			PopupManager.close_popup("failure")
		else:
			PopupManager.show_toast("星光不足，无法继续挑战")

	var rest_action = func() -> void:
		PopupManager.close_popup("failure")
		GameManager.go_to_menu()

	PopupManager.show_failure(
		settlement,
		continue_action,
		rest_action
	)

# ==================== 暂停/继续 ====================
func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false

func restart_level() -> void:
	_start_level(level_system.current_level_id)
