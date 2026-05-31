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


func _build_two_link_blueprint(main, module_index: int) -> Dictionary:
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
	main._append_component_root_node(nodes, "TARGET_CORE", Vector2(0.5, 0.5), _first_torso(main))
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _min_target_gap(main, attack_collider: Dictionary, target, origin_x: float) -> float:
	var gap := INF
	for raw_collider in target.part_colliders():
		if raw_collider is Dictionary:
			var shifted: Dictionary = main._shift_collider_to_origin(Dictionary(raw_collider), origin_x)
			gap = minf(gap, main._collider_gap(attack_collider, shifted))
	return gap


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
	var attacker_stats := main._compute_unit_stats(1, "hero", -1, _build_two_link_blueprint(main, module_index))
	var target_stats := main._compute_unit_stats(2, "hero", -1, _build_target_blueprint(main))
	var attacker = FighterScene.new()
	var target = FighterScene.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker._ready()
	target._ready()
	attacker.setup_unit({"unit_name": "PRECONTACT_ATTACKER", "owner_id": 1, "role": "hero", "stats": attacker_stats})
	target.setup_unit({"unit_name": "PRECONTACT_TARGET", "owner_id": 2, "role": "hero", "stats": target_stats})
	attacker.deploy(5.0, 0.0)
	target.deploy(7.8, 0.0)
	attacker.facing = 1
	target.facing = -1
	var binding: Dictionary = Array(attacker_stats.get("runtime_module_bindings", []))[0]
	var event: Dictionary = attacker.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Two-Link runtime action did not start.")
	event["direction"] = Vector2.RIGHT
	var action: Dictionary = attacker.runtime_module_actions[0]
	action["timer"] = float(action.get("duration", 0.31)) * 0.72
	attacker.runtime_module_actions[0] = action
	var active_colliders := _active_runtime_colliders(attacker)
	if active_colliders.is_empty():
		_fail("Two-Link runtime action did not expose active contact colliders.")
	var attack_collider: Dictionary = active_colliders[active_colliders.size() - 1]
	var center := main._collider_center(attack_collider)
	target.ring_pos = center.x + 0.9
	target.lane = center.y + 1.25
	var gap := _min_target_gap(main, attack_collider, target, center.x)
	for attempt in range(80):
		if gap > 0.28:
			break
		target.lane += 0.16
		gap = _min_target_gap(main, attack_collider, target, center.x)
	if gap <= 0.0:
		target.lane += 1.5
		gap = _min_target_gap(main, attack_collider, target, center.x)
	if gap <= 0.05:
		_fail("Probe setup failed: visible geometry is too close or touching, gap=%.4f" % gap)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var before_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	var before_hp: int = target.health
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main._resolve_attack(attacker, event)
	main._separate_unit_part_pair(attacker, target, 1.0 / 60.0)
	if target.health != before_hp:
		_fail("Pre-contact runtime attack changed HP from %d to %d." % [before_hp, target.health])
	var after_effects: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	if after_effects != before_effects:
		_fail("Pre-contact runtime attack spawned effects: %d -> %d." % [before_effects, after_effects])
	var message := String(main.battle_message)
	if message != "":
		_fail("Pre-contact runtime attack displayed battle message: %s" % message)
	print("RUNTIME_NO_PRECONTACT_DAMAGE_PROBE gap=%.4f hp=%d" % [gap, target.health])
	quit()
