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


func _module_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_unit(main, module_index: int, third: bool = false) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	if third:
		main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "C", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _prime_pending(main, module_index: int) -> void:
	main.editor_pending_module_binding = {"payload_index": 0, "module_index": module_index, "attack_key": 0, "target_selected": false}


func _assert_selects_root(main, unit_bp: Dictionary, module_index: int, selected: Array, expected_root: int, label: String) -> void:
	main.editor_working_blueprint = unit_bp
	_prime_pending(main, module_index)
	main._complete_pending_module_binding_with_selection(unit_bp, selected)
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("%s did not select a valid target." % label)
	if int(main.editor_pending_module_binding.get("root_index", -1)) != expected_root:
		_fail("%s resolved root %d, expected %d." % [label, int(main.editor_pending_module_binding.get("root_index", -1)), expected_root])
	var target_nodes: Array = main.editor_pending_module_binding.get("target_nodes", [])
	if target_nodes.size() != 2 or int(target_nodes[0]) != expected_root:
		_fail("%s did not resolve exactly the two-link chain." % label)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"
	var module_index := _module_index(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_unit(main, module_index)
	_assert_selects_root(main, unit_bp, module_index, [1], 1, "proximal click")
	_assert_selects_root(main, unit_bp, module_index, [2], 1, "distal click")
	_assert_selects_root(main, unit_bp, module_index, [1, 2], 1, "box select")
	var illegal := _build_unit(main, module_index, true)
	main.editor_working_blueprint = illegal
	_prime_pending(main, module_index)
	main._complete_pending_module_binding_with_selection(illegal, [1])
	if bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Three-segment chain should not be accepted as Two-Link target.")
	if failed:
		quit(1)
		return
	print("TWO_LINK_TARGET_SELECTION_UI_PROBE ok")
	quit()
