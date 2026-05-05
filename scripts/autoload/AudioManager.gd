## AudioManager - 全局音频管理器
extends Node

# 音频播放器
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_players: Array = []  # 多个SFX播放器用于同时播放

# 音量设置
var bgm_volume: float = 0.5
var sfx_volume: float = 0.7

# 预生成的音效缓存
var sound_cache: Dictionary = {}

func _ready() -> void:
	# 创建BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = linear_to_db(bgm_volume)
	add_child(bgm_player)
	
	# 创建主SFX播放器
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = linear_to_db(sfx_volume)
	add_child(sfx_player)
	
	# 创建额外的SFX播放器（用于同时播放多个音效）
	for i in range(4):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)
	
	# 预生成音效
	_pregenerate_sounds()
	
	print("AudioManager initialized")

# 预生成所有音效
func _pregenerate_sounds() -> void:
	sound_cache["click"] = SoundGenerator.generate_click_sound()
	sound_cache["match"] = SoundGenerator.generate_match_sound()
	sound_cache["swap"] = SoundGenerator.generate_swap_sound()
	sound_cache["fall"] = SoundGenerator.generate_fall_sound()
	sound_cache["victory"] = SoundGenerator.generate_victory_sound()
	sound_cache["failure"] = SoundGenerator.generate_failure_sound()
	sound_cache["bgm"] = SoundGenerator.generate_bgm_loop()
	
	# 预生成连击音效
	for i in range(1, 8):
		sound_cache["combo_%d" % i] = SoundGenerator.generate_combo_sound(i)
	
	print("Sound cache generated: ", sound_cache.keys())

# ==================== BGM控制 ====================
# 播放背景音乐
func play_bgm(fade_in: bool = true) -> void:
	var bgm = sound_cache.get("bgm")
	if not bgm:
		return
	
	if bgm_player.stream == bgm and bgm_player.playing:
		return
	
	bgm_player.stream = bgm
	bgm_player.bus = "Master"
	
	if fade_in:
		var tween = create_tween()
		bgm_player.volume_db = -80
		bgm_player.play()
		tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume), 1.0)
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()

# 停止背景音乐
func stop_bgm(fade_out: bool = true) -> void:
	if fade_out:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80, 0.5)
		tween.tween_callback(bgm_player.stop)
	else:
		bgm_player.stop()

# ==================== SFX播放 ====================
# 播放UI点击音效
func play_ui_click() -> void:
	_play_sfx("click")

# 播放消除音效
func play_match() -> void:
	_play_sfx("match")

# 播放交换音效
func play_swap() -> void:
	_play_sfx("swap")

# 播放下落音效
func play_fall() -> void:
	_play_sfx("fall")

# 播放连击音效
func play_combo(combo_count: int) -> void:
	var key = "combo_%d" % mini(combo_count, 7)
	_play_sfx(key)

# 播放胜利音效
func play_victory() -> void:
	_play_sfx("victory")

# 播放失败音效
func play_failure() -> void:
	_play_sfx("failure")

# 内部播放方法
func _play_sfx(sound_key: String) -> void:
	var sound = sound_cache.get(sound_key)
	if not sound:
		print("Sound not found: ", sound_key)
		return
	
	# 找一个空闲的播放器
	var player = _get_free_sfx_player()
	if player:
		player.stream = sound
		player.volume_db = linear_to_db(sfx_volume)
		player.play()

# 获取空闲的SFX播放器
func _get_free_sfx_player() -> AudioStreamPlayer:
	# 首先检查主播放器
	if not sfx_player.playing:
		return sfx_player
	
	# 检查额外的播放器
	for player in sfx_players:
		if not player.playing:
			return player
	
	# 如果都忙，使用主播放器（会打断当前音效）
	return sfx_player

# ==================== 音量控制 ====================
# 设置BGM音量
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clampf(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume)

# 设置SFX音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	sfx_player.volume_db = linear_to_db(sfx_volume)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)

# 获取BGM音量
func get_bgm_volume() -> float:
	return bgm_volume

# 获取SFX音量
func get_sfx_volume() -> float:
	return sfx_volume

# ==================== 便利方法 ====================
# 播放通用音效
func play_sound(sound_key: String) -> void:
	_play_sfx(sound_key)

# 停止所有音效
func stop_all_sfx() -> void:
	sfx_player.stop()
	for player in sfx_players:
		player.stop()

# 静音所有
func mute_all() -> void:
	bgm_player.volume_db = -80
	sfx_player.volume_db = -80
	for player in sfx_players:
		player.volume_db = -80

# 恢复音量
func unmute_all() -> void:
	bgm_player.volume_db = linear_to_db(bgm_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)
