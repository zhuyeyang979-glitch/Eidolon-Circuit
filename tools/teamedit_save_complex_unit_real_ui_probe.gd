extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	if saved_path != "":
		_fail("Blueprint containing legacy fields should not be saved.")
		return
	if main.editor_save_unit_feedback_label == null or not main.editor_save_unit_feedback_label.visible:
		_fail("Rejected legacy save did not show visible feedback.")
		return
	var feedback := String(main.editor_save_unit_feedback_label.text)
	if feedback.find("legacy drive/pointer field") < 0 or feedback.find("power") < 0:
		_fail("Rejected legacy save did not report its first legacy field: %s" % feedback)
		return
	if not main.editor_save_feedback_is_error:
		_fail("Rejected legacy save should be marked as an error.")
		return
	print("TEAMEDIT_SAVE_COMPLEX_UNIT_REAL_UI_PROBE ok rejected=%s" % feedback)
	quit(0)
