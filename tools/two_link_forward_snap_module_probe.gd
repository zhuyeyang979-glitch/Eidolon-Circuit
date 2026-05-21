extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


class FakeHero:
	extends RefCounted
	var owner_id := 1
	func forward_vector() -> Vector2:
		return Vector2.RIGHT


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_module(main) -> int:
	var catalog: Array = main._catalog_for("hero", "module")
	for i in range(catalog.size()):
		if String(Dictionary(catalog[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _first_terminal(main, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle") and bool(predicate.call(part)):
			return i
	return -1


func _build_unit(main, second_slot: String = "limb_muscle", second_index: int = 0, add_third: bool = false) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var module_index := _first_module(main)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	nodes[limb_a]["module"] = module_index
	nodes[limb_a]["modules"] = [module_index]
	nodes[limb_a]["attack_key"] = 1
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", second_slot, second_index, Vector2.RIGHT)
	if add_third:
		main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_b, "C", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _first_attack_node(main, unit_bp: Dictionary) -> Dictionary:
	var nodes: Array = main._component_topology_attack_nodes("hero", unit_bp, true)
	if nodes.is_empty():
		return {}
	return Dictionary(nodes[0])


func _reason(main, unit_bp: Dictionary) -> String:
	var module_part: Dictionary = main._selected_component("hero", "module", _first_module(main))
	return main._module_execution_invalid_reason(module_part, _first_attack_node(main, unit_bp), "hero", unit_bp)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _first_module(main)
	if module_index < 0:
		_fail("Two-Link Forward Snap module profile not found.")
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	if not String(module_part.get("name", "")).contains("TWO-LINK FORWARD SNAP"):
		_fail("PAIR BITE catalog slot was not converted to Two-Link Forward Snap.")
	if String(module_part.get("module_target_kind", "")) != "two_link_rotating_limb":
		_fail("Two-Link module target kind is wrong.")
	var fake := FakeHero.new()
	if main._two_link_forward_snap_attack_state(1, fake, Vector2.RIGHT) != "armor":
		_fail("Forward+attack should map to armor for Two-Link.")
	if main._two_link_forward_snap_attack_state(1, fake, Vector2.LEFT) != "active":
		_fail("Rear+attack should map to active for Two-Link.")
	if main._two_link_forward_snap_attack_state(1, fake, Vector2.DOWN) != "normal":
		_fail("Local-down+attack should not map to active for Two-Link.")
	var legal := _build_unit(main)
	var legal_reason := _reason(main, legal)
	if legal_reason != "":
		_fail("Legal two-link limb was rejected: %s" % legal_reason)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, legal)
	var runtime_bindings: Array = stats.get("runtime_module_bindings", [])
	if runtime_bindings.is_empty() or String(Dictionary(runtime_bindings[0]).get("module_action_profile", "")) != "two_link_forward_snap":
		_fail("Legal two-link unit did not generate the expected runtime binding.")
	var single := _build_unit(main)
	var single_topology: Dictionary = single.get("custom_topology", {})
	var single_edges: Array = single_topology.get("edges", [])
	if single_edges.size() > 1:
		single_edges.resize(1)
	single_topology["edges"] = single_edges
	single["custom_topology"] = single_topology
	if not _reason(main, single).contains("exactly two"):
		_fail("Single-segment limb was not rejected as exactly-two requirement.")
	if not _reason(main, _build_unit(main, "limb_muscle", 0, true)).contains("exactly two"):
		_fail("Three-segment limb was not rejected.")
	var gun_index := _first_terminal(main, func(part: Dictionary) -> bool: return bool(part.get("projectile", false)))
	var gun_reason := _reason(main, _build_unit(main, "muscle", gun_index)) if gun_index >= 0 else ""
	if gun_index >= 0 and gun_reason != "":
		_fail("Projectile gun terminal should be accepted as a melee terminal for Two-Link: %s" % gun_reason)
	var linear_index := _first_terminal(main, func(part: Dictionary) -> bool: return String(part.get("damage_type", "")).to_lower() in ["pierce", "blunt"] and not bool(part.get("projectile", false)))
	if linear_index >= 0 and not _reason(main, _build_unit(main, "muscle", linear_index)).contains("rotating"):
		_fail("Linear terminal weapon was not rejected.")
	if failed:
		quit(1)
		return
	print("TWO_LINK_FORWARD_SNAP_MODULE_PROBE ok module=%d" % module_index)
	quit()
