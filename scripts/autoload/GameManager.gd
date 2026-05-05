## GameManager - 全局游戏管理器
extends Node

# 游戏状态枚举
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# 当前游戏状态
var current_state: GameState = GameState.MENU

# 当前关卡
var current_level: int = 1

# 游戏数据
var player_data: Dictionary = {
	"level": 1,
	"stars": 0,
	"coins": 0,
	"total_score": 0
}

# 信号
signal state_changed(new_state: GameState)
signal level_completed(level: int, stars: int)
signal score_updated(new_score: int)

func _ready() -> void:
	print("GameManager initialized")

# 改变游戏状态
func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	print("Game state changed to: ", GameState.keys()[new_state])

# 开始关卡
func start_level(level_id: int) -> void:
	current_level = level_id
	change_state(GameState.PLAYING)

# 完成关卡
func complete_level(stars: int, score: int) -> void:
	player_data.total_score += score
	if current_level >= player_data.level:
		player_data.level = current_level + 1
	level_completed.emit(current_level, stars)
	change_state(GameState.VICTORY)

# 游戏失败
func game_over() -> void:
	change_state(GameState.GAME_OVER)

# 返回主菜单
func go_to_menu() -> void:
	change_state(GameState.MENU)

# 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true

# 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		get_tree().paused = false
		change_state(GameState.PLAYING)

# 更新分数
func update_score(score: int) -> void:
	score_updated.emit(score)
