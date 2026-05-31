extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
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


func _first_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _segment_axis(segment: Dictionary) -> Vector2:
	var a: Vector2 = segment.get("a", Vector2.ZERO)
	var b: Vector2 = segment.get("b", Vector2.ZERO)
	var axis := b - a
	return axis.normalized() if axis.length() > 0.001 else Vector2.ZERO


func _build_two_link_unit(main, module_index: int) -> Dictionary:
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
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _segments_at_phase(fighter, binding: Dictionary, phase: float) -> Array:
	fighter.runtime_module_actions.clear()
	fighter.action_cooldown = 0.0
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Runtime Two-Link action did not start: %s" % String(fighter.get_meta("last_module_gate_reason", "unknown")))
		return []
	var duration := maxf(0.001, float(fighter.runtime_module_actions[0].get("duration", 0.62)))
	var action: Dictionary = fighter.runtime_module_actions[0]
	action["timer"] = duration * (1.0 - clampf(phase, 0.0, 1.0))
	fighter.runtime_module_actions[0] = action
	return fighter._runtime_topology_world_segments(false, true)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _first_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
		quit(1)
		return
	var unit_bp := _build_two_link_unit(main, module_index)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	if not Array(stats.get("attack_groups", [])).is_empty():
		_fail("Two-Link TeamEdit unit should not generate attack_groups.")
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.size() != 1:
		_fail("Two-Link runtime binding missing.")
		quit(1)
		return
	var binding: Dictionary = bindings[0]
	if not bool(binding.get("runtime_valid", false)):
		_fail("Two-Link runtime binding invalid: %s" % String(binding.get("binding_valid_note", "")))
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "TwoLink", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var straight_segments := _segments_at_phase(fighter, binding, 0.28)
	if straight_segments.size() < 2:
		_fail("Two-Link did not produce two runtime segments.")
		quit(1)
		return
	var forward := Vector2.RIGHT
	if _segment_axis(straight_segments[0]).dot(forward) < 0.72 or _segment_axis(straight_segments[1]).dot(forward) < 0.72:
		_fail("Straight phase did not align both segments forward.")
	var return_segments := _segments_at_phase(fighter, binding, 0.78)
	if _segment_axis(return_segments[0]).dot(Vector2.LEFT) < 0.62:
		_fail("Return phase did not rotate proximal segment backward.")
	if _segment_axis(return_segments[1]).dot(forward) < 0.72:
		_fail("Return phase did not keep distal segment forward.")
	if failed:
		quit(1)
		return
	print("TWO_LINK_FORWARD_SNAP_COMBAT_POSE_PROBE runtime ok")
	quit()
