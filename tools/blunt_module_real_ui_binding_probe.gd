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


func _first_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not bool(part.get("is_torso", false)):
			return i
	return -1


func _first_terminal(main, flag: String) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if flag == "blunt_gauntlet" and String(part.get("name", "")) != MainScene.STANDARD_GAUNTLET_NAME:
			continue
		if bool(part.get(flag, false)):
			return i
	return -1


func _first_module(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return i
	return -1


func _build_unit(main, terminal_index: int, module_index: int, label: String) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", _first_limb(main), Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, label, "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _runtime_binding(main, unit_bp: Dictionary) -> Dictionary:
	var bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if bindings.size() != 1:
		_fail("Expected one runtime binding, got %d." % bindings.size())
	return Dictionary(bindings[0])


func _assert_real_ui_binding(main, profile: String, flag: String, expected_kind: String, label: String) -> void:
	var module_index := _first_module(main, profile)
	var terminal_index := _first_terminal(main, flag)
	if module_index < 0 or terminal_index < 0:
		_fail("%s module or %s terminal missing." % [profile, flag])
	var unit_bp := _build_unit(main, terminal_index, module_index, label)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	var limb_index := 1
	var terminal_node := 2
	var terminal_candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, terminal_node)
	if terminal_candidate.is_empty() or not bool(terminal_candidate.get("valid", false)):
		_fail("%s terminal click did not produce a valid candidate: %s" % [profile, str(terminal_candidate)])
	if int(terminal_candidate.get("root_index", -1)) != terminal_node:
		_fail("%s terminal candidate root mismatch: %s" % [profile, str(terminal_candidate)])
	if String(terminal_candidate.get("target_kind", "")) != expected_kind:
		_fail("%s target kind mismatch: %s" % [profile, str(terminal_candidate)])
	var limb_candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, limb_index)
	if limb_candidate.is_empty() or not bool(limb_candidate.get("valid", false)):
		_fail("%s adjacent limb click did not resolve to terminal candidate: %s" % [profile, str(limb_candidate)])
	if int(limb_candidate.get("root_index", -1)) != terminal_node:
		_fail("%s adjacent limb candidate should root at terminal node: %s" % [profile, str(limb_candidate)])
	main._complete_pending_module_binding_with_selection(unit_bp, Array(limb_candidate.get("selection", [])))
	main._set_pending_module_attack_key(1)
	var saved_bindings: Array = Array(unit_bp.get("module_bindings", []))
	if saved_bindings.size() != 1:
		_fail("%s UI flow did not save exactly one binding." % profile)
	var saved: Dictionary = Dictionary(saved_bindings[0])
	if String(saved.get("target_kind", "")) != expected_kind or Array(saved.get("target_nodes", [])) != [terminal_node]:
		_fail("%s saved binding target mismatch: %s" % [profile, str(saved)])
	nodes = Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []))
	if not (nodes[terminal_node] is Dictionary):
		_fail("%s terminal node missing after binding." % profile)
	var terminal_node_data: Dictionary = Dictionary(nodes[terminal_node])
	if not Array(terminal_node_data.get("modules", [])).has(module_index):
		_fail("%s did not attach module index to terminal node." % profile)
	var runtime := _runtime_binding(main, unit_bp)
	if not bool(runtime.get("runtime_valid", false)):
		_fail("%s runtime binding invalid: %s" % [profile, String(runtime.get("binding_valid_note", ""))])
	if String(runtime.get("module_action_profile", "")) != profile or Array(runtime.get("target_nodes", [])) != [terminal_node]:
		_fail("%s runtime binding target/profile mismatch: %s" % [profile, str(runtime)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	_assert_real_ui_binding(main, "blunt_gauntlet_extend_swing", "blunt_gauntlet", "gauntlet_terminal", "GAUNTLET")
	_assert_real_ui_binding(main, "blunt_shield_guard_bash", "blunt_shield", "shield_terminal", "SHIELD")
	_assert_real_ui_binding(main, "blunt_hammer_windup_slam", "blunt_hammer", "hammer_terminal", "HAMMER")
	print("BLUNT_MODULE_REAL_UI_BINDING_PROBE ok")
	quit()
