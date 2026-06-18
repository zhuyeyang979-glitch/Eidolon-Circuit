extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _two_link_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_two_torso_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _first_index(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _first_index(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _first_index(main, "booster", func(part: Dictionary) -> bool: return main._thruster_allocated_momentum_for_part(part) > 0.0)
	var module_index := _two_link_index(main)
	var nodes: Array = []
	var edges: Array = []
	var torso_a: int = main._append_component_root_node(nodes, "CORE A", Vector2(0.32, 0.45), torso_index)
	var limb_a1: int = main._append_directed_component_node("hero", unit, nodes, edges, torso_a, "A1", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	var limb_a2: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_a1, "A2", "limb_muscle", 0, Vector2.RIGHT)
	var torso_b: int = main._append_component_root_node(nodes, "CORE B", Vector2(0.32, 0.68), torso_index)
	var limb_b1: int = main._append_directed_component_node("hero", unit, nodes, edges, torso_b, "B1", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	var limb_b2: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_b1, "B2", "limb_muscle", 0, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso_a},
		{"kind": "booster", "booster": booster_index, "torso_node": torso_a},
		{"kind": "module", "module": module_index, "torso_node": torso_a},
		{"kind": "engine", "engine": engine_index, "torso_node": torso_b},
		{"kind": "booster", "booster": booster_index, "torso_node": torso_b},
		{"kind": "module", "module": module_index, "torso_node": torso_b},
	]
	unit["module_bindings"] = [
		{"software_slot_index": 2, "module_index": module_index, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a1, limb_a2], "target_torso_node": torso_a, "binding_valid_note": "OK"},
		{"software_slot_index": 5, "module_index": module_index, "attack_key": 2, "target_kind": "limb", "target_nodes": [limb_b1, limb_b2], "target_torso_node": torso_b, "binding_valid_note": "OK"},
	]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	unit["_torso_a"] = torso_a
	unit["_torso_b"] = torso_b
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var unit := _build_two_torso_unit(main)
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit
	var data_a: Dictionary = main._engine_momentum_allocation_data(unit, int(unit["_torso_a"]), 0)
	var data_b: Dictionary = main._engine_momentum_allocation_data(unit, int(unit["_torso_b"]), 3)
	var ids_a: Array = []
	for entry in Array(data_a.get("entries", [])):
		if entry is Dictionary:
			ids_a.append(String(Dictionary(entry).get("id", "")))
	if not ids_a.has("booster_drive:1") or not ids_a.has("booster_boost_brake:1") or ids_a.has("booster_drive:4") or ids_a.has("booster_boost_brake:4"):
		_fail("First torso booster scope is wrong: %s" % str(ids_a))
		return
	for id in ids_a:
		if String(id).begins_with("limb:1:"):
			_fail("First torso leaked second torso binding: %s" % str(ids_a))
			return
	var ids_b: Array = []
	for entry in Array(data_b.get("entries", [])):
		if entry is Dictionary:
			ids_b.append(String(Dictionary(entry).get("id", "")))
	if not ids_b.has("booster_drive:4") or not ids_b.has("booster_boost_brake:4") or ids_b.has("booster_drive:1") or ids_b.has("booster_boost_brake:1"):
		_fail("Second torso booster scope is wrong: %s" % str(ids_b))
		return
	for id in ids_b:
		if String(id).begins_with("limb:0:"):
			_fail("Second torso leaked first torso binding: %s" % str(ids_b))
			return
	print("ENGINE_POWER_ALLOCATION_SCOPE_PROBE ok a=%s b=%s" % [str(ids_a), str(ids_b)])
	quit()
