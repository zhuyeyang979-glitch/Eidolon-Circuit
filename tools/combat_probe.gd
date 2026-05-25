extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var module_part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(module_part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_attacker_blueprint(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.38, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
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


func _build_target_blueprint(main) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	main._append_component_root_node(nodes, "TARGET_CORE", Vector2(0.5, 0.5), _first_torso(main))
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _collider_gap(a: Dictionary, b: Dictionary) -> float:
	var a_radius: float = float(a.get("radius", 0.0))
	var b_radius: float = float(b.get("radius", 0.0))
	var a_shape := String(a.get("shape", "circle"))
	var b_shape := String(b.get("shape", "circle"))
	var distance := 0.0
	if a_shape == "capsule" and b_shape == "capsule":
		distance = _segment_segment_distance(a.get("a", Vector2.ZERO), a.get("b", Vector2.ZERO), b.get("a", Vector2.ZERO), b.get("b", Vector2.ZERO))
	elif a_shape == "capsule":
		distance = _point_segment_distance(b.get("center", Vector2.ZERO), a.get("a", Vector2.ZERO), a.get("b", Vector2.ZERO))
	elif b_shape == "capsule":
		distance = _point_segment_distance(a.get("center", Vector2.ZERO), b.get("a", Vector2.ZERO), b.get("b", Vector2.ZERO))
	else:
		distance = Vector2(a.get("center", Vector2.ZERO)).distance_to(Vector2(b.get("center", Vector2.ZERO)))
	return distance - a_radius - b_radius


func _point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _segment_segment_distance(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> float:
	if _segments_intersect(a0, a1, b0, b1):
		return 0.0
	return minf(
		minf(_point_segment_distance(a0, b0, b1), _point_segment_distance(a1, b0, b1)),
		minf(_point_segment_distance(b0, a0, a1), _point_segment_distance(b1, a0, a1))
	)


func _segments_intersect(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> bool:
	var r := a1 - a0
	var s := b1 - b0
	var denom := r.cross(s)
	if absf(denom) <= 0.000001:
		return false
	var u := (b0 - a0).cross(r) / denom
	var t := (b0 - a0).cross(s) / denom
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0


func _min_gap_to_target(main, attack_collider: Dictionary, target) -> float:
	var min_gap := INF
	for raw_collider in target.part_colliders():
		if raw_collider is Dictionary:
			min_gap = minf(min_gap, main._collider_gap(attack_collider, raw_collider))
	return min_gap


func _active_runtime_colliders(unit) -> Array:
	var result: Array = []
	for raw_collider in unit.part_colliders():
		if not (raw_collider is Dictionary):
			continue
		var collider: Dictionary = raw_collider
		if bool(collider.get("independent_damage", false)) and String(collider.get("part_kind", "")) != "torso":
			result.append(collider)
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link runtime module missing.")
		return
	var attacker_bp := _build_attacker_blueprint(main, module_index)
	var target_bp := _build_target_blueprint(main)
	var attacker_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, attacker_bp)
	var target_stats: Dictionary = main._compute_unit_stats(2, "hero", -1, target_bp)
	if not bool(attacker_stats.get("teamedit_runtime_topology", false)):
		_fail("Attacker did not enter TeamEdit runtime topology path.")
		return
	if not Array(attacker_stats.get("attack_groups", [])).is_empty():
		_fail("Runtime attacker still generated legacy attack_groups.")
		return
	if Array(attacker_stats.get("runtime_topology_segments", [])).is_empty():
		_fail("Runtime attacker has no topology segments.")
		return
	var bindings: Array = Array(attacker_stats.get("runtime_module_bindings", []))
	if bindings.size() != 1:
		_fail("Runtime module binding missing.")
		return

	var attacker = FighterScene.new()
	var target = FighterScene.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker._ready()
	target._ready()
	attacker.setup_unit({"unit_name": "Runtime Probe Attacker", "owner_id": 1, "role": "hero", "stats": attacker_stats})
	target.setup_unit({"unit_name": "Runtime Probe Target", "owner_id": 2, "role": "hero", "stats": target_stats})
	attacker.deploy(5.0, 0.0)
	target.deploy(6.02, 0.0)
	attacker.facing = 1
	target.facing = -1
	attacker.velocity = Vector2.RIGHT * 0.8

	var binding: Dictionary = bindings[0]
	var event: Dictionary = attacker.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Runtime module action did not start: %s" % String(attacker.get_meta("last_module_gate_reason", "unknown")))
		return
	event["direction"] = Vector2.RIGHT
	var action: Dictionary = attacker.runtime_module_actions[0]
	action["timer"] = float(action.get("duration", 0.62)) * 0.72
	attacker.runtime_module_actions[0] = action
	var active_colliders := _active_runtime_colliders(attacker)
	if active_colliders.is_empty():
		_fail("Runtime action did not expose active topology contact colliders.")
		return
	var attack_collider: Dictionary = active_colliders[active_colliders.size() - 1]
	var attack_center: Vector2 = main._collider_center(attack_collider)
	target.ring_pos = attack_center.x
	target.lane = attack_center.y
	target.sync_mobius_from_compat(MainScene.RING_LENGTH, true)
	target.velocity = Vector2.ZERO
	var min_gap := _min_gap_to_target(main, attack_collider, target)
	if min_gap > 0.0:
		_fail("Runtime topology attack did not overlap target: min_gap=%.4f." % min_gap)
		return

	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var before_hp: int = target.health
	main._resolve_attack(attacker, event)
	main._separate_unit_part_pair(attacker, target, 1.0 / 60.0)
	var hp_delta: int = before_hp - target.health
	if hp_delta <= 0:
		_fail("Runtime topology contact overlapped but did not damage target.")
		return
	print("COMBAT_PROBE runtime_topology_contact=true hp_delta=%d min_gap=%.4f segments=%d" % [
		hp_delta,
		min_gap,
		Array(attacker_stats.get("runtime_topology_segments", [])).size(),
	])
	quit()
