extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("balanced_4080s", true)
	main._show_settings()
	main._show_settings_category("video")
	if not main.settings_video_buttons.has("performance_profile"):
		_fail("Video settings did not expose the performance profile action row.")
		return
	if main.settings_labels.is_empty():
		_fail("Video settings did not create selectable rows.")
		return
	main._activate_settings_item(0)
	if main.performance_profile == "balanced_4080s":
		_fail("Activating the video profile row did not cycle the profile.")
		return
	if Engine.max_fps != int(main._runtime_quality_value("fps_cap", 0)):
		_fail("Engine FPS cap does not match runtime quality config.")
		return
	main._apply_performance_profile("balanced_4080s", true)
	print("SETTINGS_FUNCTIONAL_VIDEO_PROBE ok cycled profile and restored balanced")
	quit(0)
