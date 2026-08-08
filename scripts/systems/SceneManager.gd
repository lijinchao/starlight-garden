## SceneManager - 场景管理器（使用GameController）
class_name SceneManager
extends Control  # 改为Control以支持子节点锚点

const AsyncUtilsScript = preload("res://scripts/utils/AsyncUtils.gd")
const PlaytestRecorderScript = preload("res://scripts/utils/PlaytestRecorder.gd")

# ==================== 信号 ====================
signal scene_changed(scene_name: String)

# ==================== 枚举 ====================
enum SceneType {
	MENU,
	GAME,
	GARDEN,
	FLOWER_JOURNAL,
	DAILY_GIFT,
	SETTINGS
}

# ==================== 变量 ====================
var current_scene: SceneType = SceneType.MENU

# UI组件
var main_menu: MainMenu
var game_controller: Control  # 使用Control类型
var garden_ui: GardenUI
var flower_language_ui: FlowerLanguageUI
var daily_gift_ui: DailyGiftUI
var settings_ui: SettingsUI
var playtest_recorder: PlaytestRecorder

# 预加载脚本
var SimpleGameControllerScript = preload("res://scripts/ui/SimpleGameController.gd")
var FlowerLanguageUIScript = preload("res://scripts/ui/FlowerLanguageUI.gd")
var DailyGiftUIScript = preload("res://scripts/ui/DailyGiftUI.gd")
const PRE_LEVEL_BLESSING_COST: int = 12
const PRE_LEVEL_BLESSING_MOVES: int = 3
const META_UNLOCK_RUNS: int = 3

# ==================== 生命周期 ====================
func _ready() -> void:
	# 动态获取视口大小并设置
	size = get_viewport_rect().size
	_setup_scenes()
	_setup_playtest_recording()
	_connect_signals()
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.garden_requested.connect(_on_game_garden_requested)
	# 默认显示菜单 - 不要在这里自动开始游戏
	_show_menu()

# ==================== 场景设置 ====================
func _setup_scenes() -> void:
	# 设置SceneManager自身为全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 创建主菜单
	main_menu = MainMenu.new()
	main_menu.visible = false
	add_child(main_menu)
	
	# 创建游戏控制器（包含所有游戏UI）
	game_controller = SimpleGameControllerScript.new()
	game_controller.visible = false
	add_child(game_controller)
	
	# 创建花园界面
	garden_ui = GardenUI.new()
	garden_ui.visible = false
	add_child(garden_ui)

	# 创建花语日记界面
	flower_language_ui = FlowerLanguageUIScript.new()
	flower_language_ui.visible = false
	add_child(flower_language_ui)

	# 创建今日花礼界面
	daily_gift_ui = DailyGiftUIScript.new()
	daily_gift_ui.visible = false
	add_child(daily_gift_ui)
	
	# 创建设置界面
	settings_ui = SettingsUI.new()
	settings_ui.visible = false
	add_child(settings_ui)

func _connect_signals() -> void:
	# 主菜单信号
	main_menu.start_game.connect(_on_start_game)
	main_menu.open_garden.connect(_on_open_garden)
	main_menu.open_flower_journal.connect(_on_open_flower_journal)
	main_menu.open_daily_gift.connect(_on_open_daily_gift)
	main_menu.open_settings.connect(_on_open_settings)
	
	# 花园信号
	garden_ui.back_pressed.connect(_on_garden_back)

	# 花语日记信号
	flower_language_ui.back_pressed.connect(_on_flower_journal_back)

	# 今日花礼信号
	daily_gift_ui.back_pressed.connect(_on_daily_gift_back)
	
	# 设置信号
	settings_ui.back_pressed.connect(_on_settings_back)
	game_controller.first_interaction.connect(_on_playtest_first_interaction)
	game_controller.breeze_awakened.connect(_on_playtest_breeze_awakened)
	game_controller.level_settled.connect(_on_playtest_level_settled)


func _setup_playtest_recording() -> void:
	playtest_recorder = PlaytestRecorderScript.new()
	add_child(playtest_recorder)

# ==================== 场景切换 ====================
func _show_menu() -> void:
	_hide_all_scenes()
	main_menu.show_menu()
	current_scene = SceneType.MENU
	scene_changed.emit("menu")
	
	# 播放背景音乐
	AudioManager.play_bgm()

func _start_game(level_id: int, bonus_moves: int = 0) -> void:
	_hide_all_scenes()
	
	# 显示游戏控制器
	game_controller.visible = true
	game_controller._start_level(level_id, bonus_moves)
	playtest_recorder.record_event("level_started", {
		"bonus_moves": bonus_moves,
		"level_id": level_id,
		"total_runs_before": int(SaveManager.get_player_data().get("total_runs", 0))
	})
	
	current_scene = SceneType.GAME
	scene_changed.emit("game")
	
	# 显示新手引导（如果是第一次玩）
	if TutorialManager.should_show_tutorial():
		await AsyncUtilsScript.create_delay_tween(self, 1.0).finished
		TutorialManager.start_tutorial()

func _show_garden(context: Dictionary = {}) -> void:
	_hide_all_scenes()
	garden_ui.show_garden(context)
	current_scene = SceneType.GARDEN
	scene_changed.emit("garden")
	playtest_recorder.record_event("garden_viewed", {
		"level_id": int(context.get("level_id", 0)),
		"outcome": str(context.get("outcome", "direct")),
		"total_runs": int(SaveManager.get_player_data().get("total_runs", 0))
	})

func _show_flower_journal() -> void:
	_hide_all_scenes()
	flower_language_ui.show_journal()
	current_scene = SceneType.FLOWER_JOURNAL
	scene_changed.emit("flower_journal")

func _show_daily_gift() -> void:
	_hide_all_scenes()
	daily_gift_ui.show_daily_gift()
	current_scene = SceneType.DAILY_GIFT
	scene_changed.emit("daily_gift")

func _show_settings() -> void:
	_hide_all_scenes()
	settings_ui.show_settings()
	current_scene = SceneType.SETTINGS
	scene_changed.emit("settings")

func _hide_all_scenes() -> void:
	main_menu.visible = false
	game_controller.visible = false
	garden_ui.hide_garden()
	flower_language_ui.hide_journal()
	daily_gift_ui.hide_daily_gift()
	settings_ui.hide_settings()

# ==================== 信号处理 ====================
func _on_start_game() -> void:
	var player_data = SaveManager.get_player_data()
	var level = player_data.get("level", 1)
	if int(player_data.get("total_runs", 0)) < META_UNLOCK_RUNS or EconomyService.get_stars() < PRE_LEVEL_BLESSING_COST:
		_start_game(level)
		return

	var confirm_action = func() -> void:
		if EconomyService.spend_stars(PRE_LEVEL_BLESSING_COST):
			_start_game(level, PRE_LEVEL_BLESSING_MOVES)
		else:
			PopupManager.show_toast("星光不足，直接开始本局")
			_start_game(level)

	var cancel_action = func() -> void:
		_start_game(level)

	PopupManager.show_confirm(
		"星光祝福",
		"消耗 %d ✨，本局开局额外获得 %d 步？" % [PRE_LEVEL_BLESSING_COST, PRE_LEVEL_BLESSING_MOVES],
		confirm_action,
		cancel_action
	)

func _on_open_garden() -> void:
	_show_garden()

func _on_open_flower_journal() -> void:
	_show_flower_journal()

func _on_open_daily_gift() -> void:
	_show_daily_gift()

func _on_open_settings() -> void:
	_show_settings()

func _on_pause_pressed() -> void:
	GameManager.pause_game()
	PopupManager.show_pause()

func _on_hint_pressed() -> void:
	PopupManager.show_toast("提示：寻找可以形成3连的交换！")

func _on_garden_back() -> void:
	_show_menu()

func _on_flower_journal_back() -> void:
	_show_menu()

func _on_daily_gift_back() -> void:
	_show_menu()

func _on_settings_back() -> void:
	_show_menu()

# ==================== 游戏信号处理（由GameController处理） ====================
func _on_tiles_matched(_positions: Array, _tile_type: int) -> void:
	pass

func _on_tiles_fallen() -> void:
	pass

func _on_chain_triggered(_chain_count: int) -> void:
	pass

func _on_level_loaded(_level_data: Dictionary) -> void:
	pass

func _on_level_won(_stars: int, _score: int) -> void:
	pass

func _on_level_failed() -> void:
	pass


func _on_game_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.MENU:
		_show_menu()


func _on_game_garden_requested(context: Dictionary = {}) -> void:
	_show_garden(context)


func _on_playtest_first_interaction(payload: Dictionary) -> void:
	playtest_recorder.record_event("first_interaction", payload)


func _on_playtest_breeze_awakened(payload: Dictionary) -> void:
	playtest_recorder.record_event("breeze_awakened", payload)


func _on_playtest_level_settled(payload: Dictionary) -> void:
	playtest_recorder.record_event("level_settled", payload)
