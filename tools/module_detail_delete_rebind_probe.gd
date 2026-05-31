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


func _build_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _bind_first_valid_candidate(main, key_value: int) -> void:
	var candidate_index := -1
	for i in range(main.editor_torso_detail_view.binding_candidates.size()):
		var candidate: Dictionary = main.editor_torso_detail_view.binding_candidates[i]
		if bool(candidate.get("valid", false)):
			candidate_index = i
			break
	if candidate_index < 0:
		_fail("No legal torso-detail candidate available.")
		return
	main._select_torso_detail_binding_candidate(candidate_index)
	main._select_torso_detail_binding_key(key_value)


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
	var unit_bp := _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main.editor_open_torso_node_index = 0
	main._refresh_torso_detail_view()
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	_bind_first_valid_candidate(main, 1)
	if Array(unit_bp.get("module_bindings", [])).size() != 1:
		_fail("Initial binding was not written.")
	main._rebind_torso_payload_at(0)
	if main.editor_pending_module_binding.is_empty() or not main.editor_torso_detail_view.binding_mode:
		_fail("Rebind did not keep torso detail in binding mode.")
	if not Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Rebind did not clear previous binding.")
	_bind_first_valid_candidate(main, 2)
	var rebound: Array = Array(unit_bp.get("module_bindings", []))
	if rebound.size() != 1 or int(Dictionary(rebound[0]).get("attack_key", 0)) != 2:
		_fail("Rebind did not write new key 2.")
	main._remove_torso_payload_at(0)
	if not Array(unit_bp.get("slot_payloads", [])).is_empty():
		_fail("Delete did not remove module payload.")
	if not Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Delete did not remove module binding.")
	if failed:
		quit(1)
		return
	print("MODULE_DETAIL_DELETE_REBIND_PROBE ok")
	quit()
