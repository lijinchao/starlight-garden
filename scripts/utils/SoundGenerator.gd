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

# 生成柔和但有轻快律动、无硬切的花园音乐循环。
static func generate_bgm_loop() -> AudioStream:
	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 22050
	audio_stream.stereo = true

	var duration = 12.0
	var sample_count = int(audio_stream.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	# C6 - Am7 - Fmaj7 - G6，保持温暖明亮，避免尖锐的大跳。
	var chord_progression = [
		[130.81, 164.81, 196.00, 220.00],
		[110.00, 130.81, 164.81, 196.00],
		[130.81, 174.61, 220.00, 261.63],
		[98.00, 146.83, 196.00, 246.94]
	]
	var melody = [
		329.63, 392.00, 440.00, 523.25,
		440.00, 392.00, 329.63, 293.66,
		329.63, 392.00, 523.25, 440.00,
		392.00, 329.63, 293.66, 261.63
	]
	var chord_duration = duration / chord_progression.size()
	var melody_duration = duration / melody.size()

	for i in range(sample_count):
		var t = float(i) / audio_stream.mix_rate
		var chord_index = int(t / chord_duration) % chord_progression.size()
		var next_chord_index = (chord_index + 1) % chord_progression.size()
		var chord_progress = fmod(t, chord_duration) / chord_duration
		var blend = clampf((chord_progress - 0.78) / 0.22, 0.0, 1.0)
		blend = blend * blend * (3.0 - 2.0 * blend)
		var current_gain = cos(blend * PI * 0.5)
		var next_gain = sin(blend * PI * 0.5)
		var left = 0.0
		var right = 0.0

		for note_index in range(4):
			var current_freq = _loop_safe_frequency(float(chord_progression[chord_index][note_index]), duration)
			var next_freq = _loop_safe_frequency(float(chord_progression[next_chord_index][note_index]), duration)
			var current_voice = sin(TAU * current_freq * t) * current_gain
			var next_voice = sin(TAU * next_freq * t) * next_gain
			var voice = (current_voice + next_voice) * 0.025
			var pan = -0.34 + note_index * 0.23
			left += voice * (1.0 - pan) * 0.5
			right += voice * (1.0 + pan) * 0.5

		var melody_index = int(t / melody_duration) % melody.size()
		var melody_progress = fmod(t, melody_duration) / melody_duration
		var melody_envelope = sin(PI * melody_progress) * exp(-1.35 * melody_progress)
		var beat_accent = 1.12 if melody_index % 4 == 0 else (1.0 if melody_index % 2 == 0 else 0.9)
		var melody_freq = _loop_safe_frequency(float(melody[melody_index]), duration)
		var melody_voice = sin(TAU * melody_freq * t) * melody_envelope * 0.026 * beat_accent
		var sparkle = sin(TAU * melody_freq * 2.0 * t) * melody_envelope * melody_envelope * 0.0035
		var melody_pan = -0.16 if melody_index % 2 == 0 else 0.16
		var breathing = 0.97 + sin(TAU * t / 6.0) * 0.03
		left = (left + (melody_voice + sparkle) * (1.0 - melody_pan) * 0.5) * breathing
		right = (right + (melody_voice + sparkle) * (1.0 + melody_pan) * 0.5) * breathing

		var left_sample = int(clampf(left, -0.32, 0.32) * 32767.0)
		var right_sample = int(clampf(right, -0.32, 0.32) * 32767.0)
		var offset = i * 4
		data.encode_s16(offset, left_sample)
		data.encode_s16(offset + 2, right_sample)

	audio_stream.data = data
	audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio_stream.loop_begin = 0
	audio_stream.loop_end = sample_count

	return audio_stream


static func _loop_safe_frequency(frequency: float, duration: float) -> float:
	return round(frequency * duration) / duration
