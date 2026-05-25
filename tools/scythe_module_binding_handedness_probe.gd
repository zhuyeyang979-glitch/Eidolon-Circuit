extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main: Node) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _scythe_index(main: Node) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _scythe_module_index(main: Node) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(main._selected_component("hero", "module", i).get("module_action_profile", "")) == "scythe_hook_return":
			return i
	return -1


func _build_bound_unit(main: Node, side: String) -> Dictionary:
	var module_index := _scythe_module_index(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", 0, Vector2.RIGHT)
	var scythe: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "%s SCYTHE" % side.to_upper(), "muscle", _scythe_index(main), Vector2.RIGHT)
	var node: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	node["visual_handedness"] = side
	nodes[scythe] = node
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var candidate: Dictionary = main._torso_detail_binding_candidate_for_node(unit_bp, 0, module_part, scythe)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Scythe module candidate should be valid for %s side: %s" % [side, String(candidate.get("reason", ""))])
		return {}
	main._start_editor_module_binding_flow(0, module_part)
	if not main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [scythe]))):
		_fail("Could not select scythe binding target for %s side." % side)
		return {}
	main.editor_pending_module_binding["attack_key"] = 1
	if not main._finalize_pending_module_binding_after_key(unit_bp):
		_fail("Could not finalize scythe binding for %s side." % side)
		return {}
	return unit_bp


func _assert_runtime_action(main: Node, unit_bp: Dictionary, side: String) -> void:
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var runtime_bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if runtime_bindings.is_empty():
		_fail("Runtime binding missing for %s scythe." % side)
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "%s Scythe" % side, "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var binding: Dictionary = runtime_bindings[0]
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Scythe module did not start for %s side." % side)
		return
	if bool(event.get("projectile", false)):
		_fail("Scythe module produced projectile for %s side." % side)
		return
	var target_nodes: Array = Array(binding.get("target_nodes", []))
	var target := int(target_nodes[target_nodes.size() - 1]) if not target_nodes.is_empty() else -1
	var segment: Dictionary = fighter._runtime_segment_source_by_node(target)
	if String(segment.get("visual_handedness", "")) != side:
		_fail("Runtime scythe segment lost %s handedness." % side)
		return
	fighter.queue_free()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if _scythe_index(main) < 0 or _scythe_module_index(main) < 0:
		_fail("Scythe terminal or scythe module missing.")
		return
	for side in ["left", "right"]:
		var unit_bp := _build_bound_unit(main, side)
		if unit_bp.is_empty():
			return
		_assert_runtime_action(main, unit_bp, side)
	print("SCYTHE_MODULE_BINDING_HANDEDNESS_PROBE ok")
	quit()
