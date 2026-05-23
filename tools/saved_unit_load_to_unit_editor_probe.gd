extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var bp: Dictionary = main._blueprint_for(1, "hero", 0).duplicate(true)
	bp["unit_name"] = "Probe Load To Unit Edit"
	bp["probe_load_marker"] = "before-save"
	var entry := {"unit_library": true, "path": "probe://load_unit", "role": "hero", "blueprint": bp, "unit_name": "Probe Load To Unit Edit"}
	main._show_saved_units_library("", "editor", false, true)
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Expected saved-units page before edit load.")
	if not main._load_saved_unit_entry_into_unit_editor(entry):
		_fail("Saved unit edit load helper returned false.")
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Saved unit edit load should enter Unit Edit.")
	var loaded: Dictionary = main._editor_current_blueprint()
	if String(loaded.get("unit_name", "")) != "Probe Load To Unit Edit":
		_fail("Loaded editor blueprint did not preserve saved unit name.")
	if String(loaded.get("probe_load_marker", "")) != "before-save":
		_fail("Loaded editor blueprint did not preserve saved blueprint fields.")
	print("SAVED_UNIT_LOAD_TO_UNIT_EDITOR_PROBE ok")
	quit()
