extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_engine(main) -> int:
	for i in range(main._catalog_for("hero", "engine").size()):
		if main._engine_momentum_output_for_part(main._selected_component("hero", "engine", i)) > 0.0:
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	var engine_index := _first_engine(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._start_editor_module_binding_flow(1, main._selected_component("hero", "module", module_index))
	main._complete_pending_module_binding_with_selection(unit_bp, [limb_a])
	main._set_pending_module_attack_key(1)
	main._refresh_unit_editor_power_allocation_dock()
	if main.editor_power_dock_view == null or main.editor_power_dock_view.entries.is_empty():
		_fail("Power dock did not show bound module limb allocations after binding.")
	var has_limb := false
	for raw_entry in main.editor_power_dock_view.entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "limb":
			has_limb = true
	if not has_limb:
		_fail("Power dock entries did not include bound limb sliders.")
	print("MODULE_BINDING_POWER_ALLOCATION_BRIDGE_PROBE ok entries=%d" % main.editor_power_dock_view.entries.size())
	quit()
