extends SceneTree

const MENU_VIEW_PATH := "res://scripts/views/menu_view.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MENU_VIEW_PATH))
	if source.is_empty():
		_fail("Could not read MenuView source.")
	for token in ["main_ref", "func bind(", "_ui_viewport_size", "._show_", "._begin_battle", "._battle_", "._settings_"]:
		if source.find(token) >= 0:
			_fail("MenuView should not retain main/page private references: %s" % token)
	for token in [
		"signal main_menu_pressed",
		"signal page_option_pressed",
		"signal battle_runtime_pressed",
		"func set_viewport_size",
		"var viewport_size",
		"UILayoutTokens.to_screen_rect",
	]:
		if source.find(token) < 0:
			_fail("MenuView missing detached view contract token: %s" % token)
	print("MENU_VIEW_NO_MAIN_REF_PROBE ok")
	quit(0)
