extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	unit_bp["unit_name"] = "Saved Units Return Probe"
	unit_bp["probe_marker"] = "editor-canvas"
	main._show_saved_units_library("", "editor")
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Opening saved units from editor should enter saved-units state.")
	if main.saved_units_return_context != "editor":
		_fail("Saved units return context should be editor.")
	main._page_options_back("saved_units")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Back from saved units should return to TeamEdit when opened from editor.")
	var returned_bp: Dictionary = main._editor_current_blueprint()
	if String(returned_bp.get("probe_marker", "")) != "editor-canvas":
		_fail("Returning to editor should preserve the current canvas blueprint.")
	main._show_menu()
	main._show_saved_units_library("", "menu")
	if main.saved_units_return_context != "menu":
		_fail("Saved units return context should be menu when opened from menu.")
	main._page_options_back("saved_units")
	if main.game_state != MainScene.STATE_MENU:
		_fail("Back from saved units should return to main menu when opened from menu.")
	print("SAVED_UNITS_BACK_TO_EDITOR_PROBE ok")
	quit()
