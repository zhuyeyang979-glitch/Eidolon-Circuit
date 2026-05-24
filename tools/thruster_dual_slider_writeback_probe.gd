extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(Dictionary(main._catalog_for("hero", slot)[i]))):
			return i
	return -1


func _entry(data: Dictionary, prefix: String) -> Dictionary:
	for raw_entry in Array(data.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("id", "")).begins_with(prefix):
			return Dictionary(raw_entry)
	return {}


func _build_unit(main, engine_index: int, booster_index: int) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var nodes: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_boost_brake_allocation_max_for_part(part) > main._thruster_boost_brake_allocation_min_for_part(part))
	if engine_index < 0 or booster_index < 0:
		_fail("Missing engine or boost-capable booster.")
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main, engine_index, booster_index)
	main.editor_panel_mode = "parts"
	main._open_engine_momentum_allocation_for_payload(0)
	var data := main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var drive_entry := _entry(data, "booster_drive:")
	var boost_entry := _entry(data, "booster_boost_brake:")
	if drive_entry.is_empty() or boost_entry.is_empty():
		_fail("Missing dual thruster allocation entries.")
	if bool(drive_entry.get("readonly", false)) or bool(boost_entry.get("readonly", false)):
		_fail("Boost-capable thruster entries should be adjustable.")
	main._set_engine_momentum_allocation_value(String(drive_entry.get("id", "")), float(drive_entry.get("max_momentum", 0.0)) * 9.0)
	main._set_engine_momentum_allocation_value(String(boost_entry.get("id", "")), float(boost_entry.get("max_momentum", 0.0)) * 9.0)
	var payloads: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	var booster_payload: Dictionary = payloads[1]
	var drive_value := float(booster_payload.get("thruster_drive_allocated_momentum", -1.0))
	var boost_value := float(booster_payload.get("thruster_boost_brake_allocated_momentum", -1.0))
	if absf(drive_value - float(drive_entry.get("max_momentum", 0.0))) > 0.01:
		_fail("Drive slider did not clamp/write max: %.3f" % drive_value)
	if absf(boost_value - float(boost_entry.get("max_momentum", 0.0))) > 0.01:
		_fail("Boost/brake slider did not clamp/write max: %.3f" % boost_value)
	print("THRUSTER_DUAL_SLIDER_WRITEBACK_PROBE ok drive=%.1f boost=%.1f" % [drive_value, boost_value])
	quit()
