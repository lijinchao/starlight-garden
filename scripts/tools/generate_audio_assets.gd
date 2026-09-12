extends SceneTree


func _init() -> void:
	var stream = SoundGenerator.generate_bgm_loop() as AudioStreamWAV
	var result = stream.save_to_wav("res://assets/audio/soft_garden_loop")
	print("Background music export: %s" % error_string(result))
	quit(0 if result == OK else 1)
