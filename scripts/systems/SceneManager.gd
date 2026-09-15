## SceneManager - 场景管理器（编排当前唯一局内控制器 SimpleGameController）
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
var tutorial_start_generation: int = 0

# 预加载脚本
var SimpleGameControllerScript = preload("res://scripts/ui/SimpleGameController.gd")
var FlowerLanguageUIScript = preload("res://scripts/ui/FlowerLanguageUI.gd")
var DailyGiftUIScript = preload("res://scripts/ui/DailyGiftUI.gd")
const PRE_LEVEL_BLESSING_COST: int = 12
const PRE_LEVEL_BLESSING_MOVES: int = 3

# ==================== 生命周期 ====================
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_audio_settings()
	_setup_scenes()
	_setup_playtest_recording()
	_connect_signals()
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.garden_requested.connect(_on_game_garden_requested)
	# 默认显示菜单 - 不要在这里自动开始游戏
	_show_menu()
	call_deferred("_sync_scene_sizes")


func _apply_audio_settings() -> void:
	var settings = SaveManager.get_settings()
	AudioManager.set_bgm_volume(float(settings.get("bgm_volume", 0.35)))
	AudioManager.set_sfx_volume(float(settings.get("sfx_volume", 0.7)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_sync_scene_sizes()

# ==================== 场景设置 ====================
func _setup_scenes() -> void:
	# 设置SceneManager自身为全屏
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
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


func _sync_scene_sizes() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for scene in [main_menu, game_controller, garden_ui, flower_language_ui, daily_gift_ui, settings_ui]:
		if scene == null:
			continue
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _connect_signals() -> void:
	# 主菜单信号
	main_menu.start_game.connect(_on_start_game)
	main_menu.start_specific_level.connect(_on_secondary_start_level)
	main_menu.open_garden.connect(_on_open_garden)
	main_menu.open_flower_journal.connect(_on_open_flower_journal)
	main_menu.open_daily_gift.connect(_on_open_daily_gift)
	main_menu.open_settings.connect(_on_open_settings)
	main_menu.playtest_event.connect(_on_playtest_event)
	
	# 花园信号
	garden_ui.back_pressed.connect(_on_garden_back)
	garden_ui.playtest_event.connect(_on_playtest_event)

	# 花语日记信号
	flower_language_ui.back_pressed.connect(_on_flower_journal_back)
	flower_language_ui.start_level_requested.connect(_on_secondary_start_level)

	# 今日花礼信号
	daily_gift_ui.back_pressed.connect(_on_daily_gift_back)
	daily_gift_ui.action_requested.connect(_on_daily_action_requested)
	
	# 设置信号
	settings_ui.back_pressed.connect(_on_settings_back)
	game_controller.first_interaction.connect(_on_playtest_first_interaction)
	game_controller.breeze_awakened.connect(_on_playtest_breeze_awakened)
	game_controller.garden_layer_cleared.connect(_on_playtest_garden_layer_cleared)
	game_controller.dew_bud_triggered.connect(_on_playtest_dew_bud_triggered)
	game_controller.daily_challenge_retried.connect(_on_playtest_daily_challenge_retried)
	game_controller.garden_corner_changed.connect(_on_playtest_garden_corner_changed)
	game_controller.companion_fed.connect(_on_playtest_companion_fed)
	game_controller.rhythm_changed.connect(_on_playtest_rhythm_changed)
	game_controller.level_climax.connect(_on_playtest_level_climax)
	game_controller.invalid_swap.connect(_on_playtest_invalid_swap)
	game_controller.level_settled.connect(_on_playtest_level_settled)
	game_controller.home_requested.connect(_on_game_home_requested)


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
		var request_generation = tutorial_start_generation
		await AsyncUtilsScript.create_delay_tween(self, 1.0).finished
		if request_generation != tutorial_start_generation:
			return
		if current_scene != SceneType.GAME or not game_controller.visible:
			return
		if GameManager.current_state != GameManager.GameState.PLAYING:
			return
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
	if MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_FLOWER_JOURNAL):
		playtest_recorder.record_event("home_recommendation_completed", {
			"feature_id": MetaUnlockService.FEATURE_FLOWER_JOURNAL,
			"stage": "task_completed"
		})

func _show_daily_gift() -> void:
	_hide_all_scenes()
	daily_gift_ui.show_daily_gift()
	current_scene = SceneType.DAILY_GIFT
	scene_changed.emit("daily_gift")
	if MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_DAILY_GIFT):
		playtest_recorder.record_event("home_recommendation_completed", {
			"feature_id": MetaUnlockService.FEATURE_DAILY_GIFT,
			"stage": "task_completed"
		})

func _show_settings() -> void:
	_hide_all_scenes()
	settings_ui.show_settings()
	current_scene = SceneType.SETTINGS
	scene_changed.emit("settings")

func _hide_all_scenes() -> void:
	_cancel_pending_tutorial()
	main_menu.visible = false
	game_controller.visible = false
	garden_ui.hide_garden()
	flower_language_ui.hide_journal()
	daily_gift_ui.hide_daily_gift()
	settings_ui.hide_settings()


func _cancel_pending_tutorial() -> void:
	tutorial_start_generation += 1
	TutorialManager.clear_tutorial_system()

# ==================== 信号处理 ====================
func _on_start_game() -> void:
	var player_data = SaveManager.get_player_data()
	var level = player_data.get("level", 1)
	if not MetaUnlockService.is_unlocked(MetaUnlockService.FEATURE_STAR_BLESSING) or EconomyService.get_stars() < PRE_LEVEL_BLESSING_COST:
		_start_game(level)
		return
	if MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_STAR_BLESSING):
		playtest_recorder.record_event("home_recommendation_completed", {
			"feature_id": MetaUnlockService.FEATURE_STAR_BLESSING,
			"stage": "task_completed"
		})

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
	GameManager.go_to_menu()

func _on_flower_journal_back() -> void:
	playtest_recorder.record_event("secondary_page_returned", {"page": "flower_journal"})
	_show_menu()

func _on_daily_gift_back() -> void:
	playtest_recorder.record_event("secondary_page_returned", {"page": "daily_gift"})
	_show_menu()

func _on_settings_back() -> void:
	playtest_recorder.record_event("secondary_page_returned", {"page": "settings"})
	_show_menu()


func _on_secondary_start_level(level_id: int) -> void:
	_start_game(level_id)


func _on_daily_action_requested(action: String, level_id: int) -> void:
	if action == "garden":
		_show_garden()
	elif action == "daily_challenge":
		_start_daily_challenge()
	else:
		_start_game(level_id)


func _start_daily_challenge() -> void:
	var daily_challenge = DailyChallengeService.get_today_challenge()
	var config = daily_challenge.get("config", {})
	if config.is_empty():
		PopupManager.show_toast("今日风庭正在准备，请稍后再试")
		return
	_hide_all_scenes()
	game_controller.visible = true
	game_controller._start_daily_challenge(config)
	playtest_recorder.record_event("daily_challenge_started", {
		"challenge_id": str(daily_challenge.get("challenge", {}).get("challenge_id", "")),
		"layout_id": str(daily_challenge.get("challenge", {}).get("layout_id", "")),
		"transform": str(daily_challenge.get("challenge", {}).get("transform", "")),
		"preferred_direction": str(daily_challenge.get("challenge", {}).get("preferred_direction", "")),
		"attempts_before": int(DailyChallengeService.get_today_progress().get("attempts", 0))
	})
	current_scene = SceneType.GAME
	scene_changed.emit("game")


func _on_game_home_requested() -> void:
	if current_scene != SceneType.GAME:
		return
	PopupManager.show_confirm(
		"返回主页",
		"本局尚未结算，当前棋盘进度不会保留。",
		_leave_game_to_menu
	)


func _leave_game_to_menu() -> void:
	game_controller.cancel_level()
	_cancel_pending_tutorial()
	GameManager.go_to_menu()

# ==================== 游戏信号处理（由当前局内控制器处理） ====================
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


func _on_playtest_garden_layer_cleared(payload: Dictionary) -> void:
	playtest_recorder.record_event("garden_layer_cleared", payload)


func _on_playtest_dew_bud_triggered(payload: Dictionary) -> void:
	playtest_recorder.record_event("dew_bud_triggered", payload)


func _on_playtest_daily_challenge_retried(payload: Dictionary) -> void:
	playtest_recorder.record_event("daily_challenge_retried", payload)


func _on_playtest_garden_corner_changed(payload: Dictionary) -> void:
	playtest_recorder.record_event("garden_corner_grew", payload)


func _on_playtest_rhythm_changed(payload: Dictionary) -> void:
	playtest_recorder.record_event("rhythm_escalated", payload)


func _on_playtest_companion_fed(payload: Dictionary) -> void:
	playtest_recorder.record_event("companion_fed", payload)


func _on_playtest_level_climax(payload: Dictionary) -> void:
	playtest_recorder.record_event("level_climax", payload)


func _on_playtest_invalid_swap(payload: Dictionary) -> void:
	playtest_recorder.record_event("invalid_swap", payload)


func _on_playtest_level_settled(payload: Dictionary) -> void:
	playtest_recorder.record_event("level_settled", payload)
	if bool(payload.get("is_daily_challenge", false)):
		playtest_recorder.record_event("daily_challenge_settled", payload)


func _on_playtest_event(event_name: String, payload: Dictionary) -> void:
	playtest_recorder.record_event(event_name, payload)
