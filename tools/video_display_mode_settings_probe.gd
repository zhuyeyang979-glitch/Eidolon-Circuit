extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_settings()
	main._show_settings_category("video")
	if not main.settings_video_buttons.has("display_mode"):
		_fail("Video settings missing display_mode row.")
		return
	if not main.settings_video_buttons.has("window_size"):
		_fail("Video settings missing window_size row.")
		return
	var original_mode := String(main.display_mode_setting)
	var original_size := String(main.window_size_setting)
	main._apply_display_mode_setting("windowed", "1280x720", false)
	if main.display_mode_setting != "windowed" or main.window_size_setting != "1280x720":
		_fail("Windowed display setting did not apply.")
		return
	main._apply_display_mode_setting("borderless_fullscreen", "native", false)
	if main.display_mode_setting != "borderless_fullscreen" or main.window_size_setting != "native":
		_fail("Borderless display setting did not apply.")
		return
	main._apply_display_mode_setting("fullscreen", "1920x1080", false)
	if main.display_mode_setting != "fullscreen" or main.window_size_setting != "1920x1080":
		_fail("Fullscreen display setting did not apply.")
		return
	main._apply_display_mode_setting(original_mode, original_size, false)
	print("VIDEO_DISPLAY_MODE_SETTINGS_PROBE ok rows=display_mode,window_size restored=%s/%s" % [original_mode, original_size])
	quit(0)
