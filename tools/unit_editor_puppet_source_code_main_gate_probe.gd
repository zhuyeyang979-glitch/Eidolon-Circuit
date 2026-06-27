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


func _minimal_puppet(main, unit_name: String) -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find("puppet")
	var core_index: int = int(main._component_index_by_name("puppet", "muscle", "FLOATING BIT CORE", 95))
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "puppet",
		"archetype": "custom",
		"special": 0,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": core_index,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"blank_canvas": false,
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

	var valid_bp := _minimal_puppet(main, "Puppet Source Gate Legal")
	var valid_note := main._training_blueprint_illegal_note(1, "puppet", valid_bp)
	_require(valid_note == "", "Puppet fixture with Source Code should remain legal, got %s" % valid_note)
	if failed:
		quit(1)
		return

	var invalid_bp: Dictionary = valid_bp.duplicate(true)
	invalid_bp["name"] = "Puppet Source Gate Invalid"
	invalid_bp["unit_name"] = "Puppet Source Gate Invalid"
	invalid_bp["special"] = -1
	invalid_bp["slot_payloads"] = []

	var invalid_note := main._training_blueprint_illegal_note(1, "puppet", invalid_bp)
	_require(invalid_note.find("puppet_source_code_missing") >= 0, "Puppet without Source Code should be blocked by the service code, got %s" % invalid_note)
	if failed:
		quit(1)
		return

	_set_editor_blueprint(main, "puppet", invalid_bp)
	var import_result: bool = bool(main._prepare_editor_canvas_training_import())
	_require(not import_result, "Puppet without Source Code should be rejected before training import.")
	var import_feedback := String(main.editor_save_unit_feedback_label.text) if main.editor_save_unit_feedback_label != null else ""
	_require(import_feedback.find("源代码") >= 0 or import_feedback.find("Source Code") >= 0 or import_feedback.find("puppet_source_code_missing") >= 0, "Training import feedback should describe missing Source Code, got %s" % import_feedback)
	if failed:
		quit(1)
		return

	_set_editor_blueprint(main, "puppet", invalid_bp)
	var invalid_path := "%s/puppet_source_gate_invalid_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var invalid_result := main._save_editor_current_unit_to_library_named("Puppet Source Gate Invalid", invalid_path, true)
	if invalid_result != "":
		_remove_saved_file(invalid_path)
		_fail("Puppet without Source Code should be rejected before write, got %s" % invalid_result)
	if FileAccess.file_exists(invalid_path):
		_remove_saved_file(invalid_path)
		_fail("Puppet without Source Code created a library file.")
	if failed:
		quit(1)
		return

	var entry_note := main._saved_unit_entry_illegal_note({
		"unit_library": true,
		"role": "puppet",
		"path": "probe://puppet-source-gate",
		"unit_name": "Puppet Source Gate Invalid",
		"blueprint": invalid_bp,
	})
	_require(entry_note.find("puppet_source_code_missing") >= 0, "Saved-unit entry gate should name puppet_source_code_missing, got %s" % entry_note)

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_PUPPET_SOURCE_CODE_MAIN_GATE_PROBE ok note=%s" % invalid_note)
	quit(0)
