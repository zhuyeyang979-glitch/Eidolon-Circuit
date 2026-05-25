extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entry_exists(main: Node, path: String) -> bool:
	for raw_entry in main._unit_library_entries():
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("path", "")) == path:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	var unit_name := "Complex UI Save Probe %d" % int(Time.get_ticks_msec())
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	bp["blank_canvas"] = false
	bp["unit_name"] = unit_name
	bp["power"] = 99.0
	bp["energy"] = 42.0
	bp["attack_groups"] = [{"legacy": true}]
	var topology: Dictionary = Dictionary(bp.get("custom_topology", {})).duplicate(true)
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	if nodes.is_empty():
		_fail("Default topology did not create nodes.")
		return
	var node0: Dictionary = Dictionary(nodes[0]).duplicate(true)
	node0["joint_power"] = 12.0
	node0["allocated_momentum"] = 6.0
	node0["action_groups"] = [{"legacy": true}]
	nodes[0] = node0
	topology["nodes"] = nodes
	bp["custom_topology"] = topology
	bp["slot_payloads"] = [
		{"kind": "engine", "engine": 0, "power": 7.0, "energy": 3.0, "hp": 12},
		{"kind": "module", "module": 0, "normal_damage": 99, "hp": 1},
		{"kind": "special", "special": 0, "power": 5.0, "source_rules": [], "hp": 2},
	]
	bp["module_bindings"] = [{"attack_key": 1, "target_nodes": [0], "attack_groups": [{"legacy": true}], "joint_power": 3.0}]
	if not main.editor_action_buttons.has("save_canvas"):
		_fail("Save Unit button missing.")
		return
	var save_canvas_button: Button = main.editor_action_buttons["save_canvas"]
	save_canvas_button.pressed.emit()
	if main.editor_save_unit_name_panel == null or not main.editor_save_unit_name_panel.visible:
		_fail("Save name panel did not open.")
		return
	main.editor_save_unit_name_edit.text = unit_name
	var raw_save_button: Node = main.editor_save_unit_name_panel.get_node_or_null("save_name_stay")
	if not (raw_save_button is Button):
		_fail("Save confirm button missing.")
		return
	var save_button: Button = raw_save_button
	save_button.pressed.emit()
	var saved_path := String(main.editor_source_saved_unit_path)
	if saved_path == "" or not FileAccess.file_exists(saved_path):
		_fail("Complex save did not create a visible saved path.")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(saved_path))
	if not (parsed is Dictionary):
		_fail("Complex save did not write a dictionary payload.")
		return
	var payload: Dictionary = parsed
	var legacy_path := main._saved_payload_legacy_path(payload)
	if legacy_path != "":
		_fail("Saved payload still has legacy drive/pointer data at %s." % legacy_path)
		return
	var combat_path := main._saved_payload_nonphysical_combat_path(payload)
	if combat_path != "":
		_fail("Saved payload still has nonphysical combat data at %s." % combat_path)
		return
	var open_button: Button = main.editor_action_buttons["open_saved_units"]
	open_button.pressed.emit()
	if main.game_state != MainScene.STATE_SAVED_UNITS:
		_fail("Saved Units button did not open the library.")
		return
	if not _entry_exists(main, saved_path):
		_fail("Complex saved unit was not visible in Saved Units.")
		return
	if main.saved_unit_selected_index < 0:
		_fail("Complex saved unit was not focused.")
		return
	if not main._load_saved_unit_into_unit_editor(saved_path):
		_fail("Complex saved unit could not load back into Unit Edit.")
		return
	if String(main._editor_current_blueprint().get("unit_name", "")) != unit_name:
		_fail("Complex loaded unit name mismatch.")
		return
	if FileAccess.file_exists(saved_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
	print("TEAMEDIT_SAVE_COMPLEX_UNIT_REAL_UI_PROBE ok path=%s" % saved_path)
	quit(0)
