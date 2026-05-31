extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", slot)[i])
		if bool(predicate.call(part)):
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_allocation_max_for_part(part) > 0.0)
	if torso_index < 0 or engine_index < 0 or booster_index < 0:
		_fail("Missing torso, engine, or booster.")
	var nodes: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _first_drive_entry(data: Dictionary) -> Dictionary:
	for raw_entry in Array(data.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "booster_drive":
			return Dictionary(raw_entry)
	return {}


func _send_enter(main) -> void:
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	main._input(enter)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main._open_engine_momentum_allocation_for_payload(0)
	await process_frame
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var entry := _first_drive_entry(data)
	if entry.is_empty():
		_fail("Missing booster drive allocation entry.")
	var entry_id := String(entry.get("id", ""))
	var before := float(entry.get("momentum", 0.0))
	var edit: LineEdit = main.engine_momentum_allocation_view.entry_value_edits.get(entry_id, null)
	if edit == null:
		_fail("Drive value LineEdit was not created.")
	edit.grab_focus()
	edit.text = "not-a-number"
	_send_enter(main)
	var after: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var after_entry := _first_drive_entry(after)
	var actual := float(after_entry.get("momentum", -1.0))
	if main.game_state != MainScene.STATE_EDITOR:
		_fail("Invalid allocation Enter navigated away from Unit Edit.")
	if absf(actual - before) > 0.05:
		_fail("Invalid allocation text changed momentum: before %.2f after %.2f" % [before, actual])
	if String(edit.text).find("not-a-number") >= 0:
		_fail("Invalid allocation text was not restored to the current value.")
	print("POWER_ALLOCATION_INVALID_ENTER_NO_NAVIGATION_PROBE ok momentum=%.2f" % actual)
	quit()
