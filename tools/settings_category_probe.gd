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
	if main.game_state != MainScene.STATE_SETTINGS:
		_fail("Settings did not enter settings state.")
	for key in ["sound", "video", "language", "input"]:
		if not main.settings_category_buttons.has(key):
			_fail("Missing settings category button: %s" % key)
	main._show_settings_category("input")
	if main.settings_labels.size() <= 0:
		_fail("Input settings category should populate rebindable battle actions.")
	main._show_settings_category("sound")
	if main.settings_labels.size() != 0:
		_fail("Sound category should not expose battle input rebind rows.")
	main._show_settings_category("language")
	if main.settings_list_container.get_child_count() < 3:
		_fail("Language category should include language choices.")
	print("SETTINGS_CATEGORY_PROBE ok")
	quit()
