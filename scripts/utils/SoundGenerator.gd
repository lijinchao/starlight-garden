## SoundGenerator - 程序化音效生成器
class_name SoundGenerator
extends Node

# ==================== 音频生成 ====================
# 生成消除音效
static func generate_match_sound() -> AudioStream:
	# 创建音频流
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	# 生成音效数据（上升音调）
	var duration = 0.15  # 150毫秒
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var freq = 440.0 + t * 2000.0  # 从440Hz上升到2440Hz
		var amplitude = 0.5 * (1.0 - t / duration)  # 音量逐渐减弱
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		# 转换为16位整数
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成连击音效
static func generate_combo_sound(combo_count: int) -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	# 连击数越高，音调越高
	var base_freq = 440.0 + combo_count * 100.0
	var duration = 0.2
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var freq = base_freq + sin(t * 20.0) * 50.0  # 添加颤音效果
		var amplitude = 0.6 * (1.0 - t / duration)
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成点击音效
static func generate_click_sound() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	var duration = 0.05  # 50毫秒
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var freq = 800.0
		var amplitude = 0.3 * (1.0 - t / duration)
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成胜利音效
static func generate_victory_sound() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	var duration = 0.8
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	# 和弦音效 (C-E-G)
	var chords = [
		[261.63, 329.63, 392.00],  # C4-E4-G4
		[293.66, 369.99, 440.00],  # D4-F#4-A4
		[329.63, 415.30, 493.88]   # E4-G#4-B4
	]
	
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var chord_index = int(t / 0.25) % chords.size()
		var chord = chords[chord_index]
		
		var sample = 0.0
		for freq in chord:
			sample += sin(2.0 * PI * freq * t) * 0.2
		
		var amplitude = 0.5 * (1.0 - t / duration)
		sample *= amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成失败音效
static func generate_failure_sound() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	var duration = 0.5
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	# 下降音调
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var freq = 440.0 - t * 300.0  # 从440Hz下降到140Hz
		var amplitude = 0.4 * (1.0 - t / duration)
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成交换音效
static func generate_swap_sound() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	var duration = 0.1
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	# 短促的滑音
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var progress = t / duration
		var freq = 300.0 + progress * 200.0  # 从300Hz滑到500Hz
		var amplitude = 0.3 * sin(progress * PI)  # 铃形包络
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成下落音效
static func generate_fall_sound() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	var duration = 0.12
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	# 短促的低音
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var freq = 150.0
		var amplitude = 0.25 * (1.0 - t / duration)
		var sample = sin(2.0 * PI * freq * t) * amplitude
		
		var sample_int = int(sample * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	return audio_stream

# 生成背景音乐（简单循环）
static func generate_bgm_loop() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 44100
	audio_stream.stereo = false
	
	# 生成4秒的循环音乐
	var duration = 4.0
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	
	# 简单的和弦进行 C-Am-F-G
	var chord_progression = [
		[261.63, 329.63, 392.00],  # C
		[220.00, 261.63, 329.63],  # Am
		[174.61, 220.00, 261.63],  # F
		[196.00, 246.94, 293.66]   # G
	]
	
	var beat_duration = 1.0  # 每个和弦1秒
	
	for i in range(sample_count):
		var t = float(i) / 44100.0
		var chord_index = int(t / beat_duration) % chord_progression.size()
		var chord = chord_progression[chord_index]
		
		var sample = 0.0
		for freq in chord:
			# 添加轻微的音量变化
			var vibrato = sin(2.0 * PI * 5.0 * t) * 0.05
			sample += sin(2.0 * PI * freq * t * (1.0 + vibrato)) * 0.15
		
		# 添加包络
		var beat_progress = fmod(t, beat_duration)
		var envelope = 0.5 + 0.5 * cos(beat_progress * PI)
		sample *= envelope * 0.3
		
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	audio_stream.data = data
	audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio_stream.loop_begin = 0
	audio_stream.loop_end = sample_count
	
	return audio_stream
