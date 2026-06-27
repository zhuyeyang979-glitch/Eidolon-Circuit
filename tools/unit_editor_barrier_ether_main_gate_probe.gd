extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _remove_saved_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _set_editor_blueprint(main, role_key: String, unit_bp: Dictionary) -> void:
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_working_role_key = role_key
	main.editor_working_blueprint = unit_bp.duplicate(true)
	main.editor_canvas_mode = "blank"


func _minimal_barrier(main, unit_name: String) -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find("barrier")
	var panel_index: int = int(main._component_index_by_name("barrier", "muscle", "MAZE HARDLIGHT CAGE WALL PANEL", 14))
	var node: Dictionary = main._topology_component_node(0, "PANEL", Vector2(0.5, 0.5), "muscle", panel_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "barrier",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": panel_index,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"blank_canvas": false,
		"barrier_tiles": [{"index": 0, "muscle": panel_index}],
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var valid_bp := _minimal_barrier(main, "Barrier Ether Gate Legal")
	var valid_note := main._training_blueprint_illegal_note(1, "barrier", valid_bp)
	_require(valid_note == "", "Barrier fixture with Ether should remain legal, got %s" % valid_note)
	if failed:
		quit(1)
		return

	var invalid_bp: Dictionary = valid_bp.duplicate(true)
	invalid_bp["name"] = "Barrier Ether Gate Invalid"
	invalid_bp["unit_name"] = "Barrier Ether Gate Invalid"
	invalid_bp["special"] = -1
	invalid_bp["slot_payloads"] = []

	var invalid_note := main._training_blueprint_illegal_note(1, "barrier", invalid_bp)
	_require(invalid_note.find("barrier_ether_missing") >= 0, "Barrier without Ether should be blocked by the service code, got %s" % invalid_note)
	if failed:
		quit(1)
		return

	_set_editor_blueprint(main, "barrier", invalid_bp)
	var import_result: bool = bool(main._prepare_editor_canvas_training_import())
	_require(not import_result, "Barrier without Ether should be rejected before training import.")
	var import_feedback := String(main.editor_save_unit_feedback_label.text) if main.editor_save_unit_feedback_label != null else ""
	_require(import_feedback.find("以太") >= 0 or import_feedback.find("Ether") >= 0 or import_feedback.find("barrier_ether_missing") >= 0, "Training import feedback should describe missing Ether, got %s" % import_feedback)
	if failed:
		quit(1)
		return

	_set_editor_blueprint(main, "barrier", invalid_bp)
	var invalid_path := "%s/barrier_ether_gate_invalid_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var invalid_result := main._save_editor_current_unit_to_library_named("Barrier Ether Gate Invalid", invalid_path, true)
	if invalid_result != "":
		_remove_saved_file(invalid_path)
		_fail("Barrier without Ether should be rejected before write, got %s" % invalid_result)
	if FileAccess.file_exists(invalid_path):
		_remove_saved_file(invalid_path)
		_fail("Barrier without Ether created a library file.")
	if failed:
		quit(1)
		return

	var entry_note := main._saved_unit_entry_illegal_note({
		"unit_library": true,
		"role": "barrier",
		"path": "probe://barrier-ether-gate",
		"unit_name": "Barrier Ether Gate Invalid",
		"blueprint": invalid_bp,
	})
	_require(entry_note.find("barrier_ether_missing") >= 0, "Saved-unit entry gate should name barrier_ether_missing, got %s" % entry_note)

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_BARRIER_ETHER_MAIN_GATE_PROBE ok note=%s" % invalid_note)
	quit(0)
