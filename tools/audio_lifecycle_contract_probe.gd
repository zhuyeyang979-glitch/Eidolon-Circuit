extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string(MAIN_PATH)
	for token in [
		"func _exit_tree() -> void:",
		"_shutdown_audio_system()",
		"func _audio_system_enabled() -> bool:",
		"DisplayServer.get_name() != \"headless\"",
		"if not is_inside_tree() or not _audio_system_enabled():",
		"func _shutdown_audio_system() -> void:",
		"player.stop()",
		"player.stream = null",
		"music_playback = null",
		"music_player = null",
		"parent.remove_child(player)",
		"player.free()",
	]:
		if source.find(token) < 0:
			_fail("main.gd missing audio lifecycle token: %s" % token)
			return
	var headless_main = MainScene.new()
	root.add_child(headless_main)
	headless_main._ready()
	if headless_main.music_player != null or headless_main.music_playback != null:
		_fail("Headless probes should not start procedural audio.")
		return
	headless_main.free()
	var main = MainScene.new()
	var player := AudioStreamPlayer.new()
	main.add_child(player)
	main.music_player = player
	main._shutdown_audio_system()
	if main.music_playback != null:
		_fail("Procedural music playback reference was not released.")
		return
	if main.music_player != null:
		_fail("Procedural music player reference was not released.")
		return
	if is_instance_valid(player):
		_fail("Procedural music player node was not freed.")
		return
	main.free()
	print("AUDIO_LIFECYCLE_CONTRACT_PROBE ok")
	quit(0)
