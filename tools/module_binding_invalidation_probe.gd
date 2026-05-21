extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_bound_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_bound_unit(main, module_index)
	var entries := main._torso_software_slot_summary(unit_bp, 0)
	if entries.is_empty() or bool(Dictionary(entries[0]).get("binding_invalid", true)):
		_fail("Fresh valid binding was shown invalid.")
	var bindings: Array = unit_bp.get("module_bindings", [])
	Dictionary(bindings[0])["target_nodes"] = [99]
	unit_bp["module_bindings"] = bindings
	var stale_entries := main._torso_software_slot_summary(unit_bp, 0)
	if stale_entries.is_empty() or not bool(Dictionary(stale_entries[0]).get("binding_invalid", false)):
		_fail("Stale target was not red-flagged in torso detail.")
	main._clear_module_binding_for_payload_index(unit_bp, 0, false)
	if Array(unit_bp.get("module_bindings", [])).size() != 0:
		_fail("Clearing a module payload binding did not remove binding.")
	if failed:
		quit(1)
		return
	print("MODULE_BINDING_INVALIDATION_PROBE ok")
	quit()
