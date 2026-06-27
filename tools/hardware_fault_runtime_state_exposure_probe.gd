extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:state-exposure-target:body0"
const TARGET_NODE_ID := 2

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _unit_stats(unit_id: String) -> Dictionary:
	return {
		"unit_id": unit_id,
		"health": 1000,
		"max_health": 1000,
		"mass": 40.0,
		"radius": 0.18,
		"length": 0.7,
		"teamedit_runtime_topology": true,
		"electronic_armor_max": 0.0,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"name": "Probe Core",
				"a_local": Vector2(-0.14, 0.0),
				"b_local": Vector2(0.14, 0.0),
				"radius": 0.12,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
				"runtime_momentum_capacity": 40.0,
			},
			{
				"node_index": TARGET_NODE_ID,
				"part_kind": "limb_muscle",
				"name": "Probe Arm",
				"a_local": Vector2(0.14, 0.0),
				"b_local": Vector2(0.44, 0.0),
				"radius": 0.08,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 100.0,
				"path_stiffness_momentum": 100.0,
			},
		],
		"runtime_topology_edges": [
			{"a_node": TARGET_NODE_ID, "a_socket": "root_joint", "b_node": 0, "b_socket": "torso_port:0", "schema": "socket_edge_v1"},
		],
	}


func _spawn_unit(main, owner: int, name: String, unit_id: String, ring: float):
	var stats := _unit_stats(unit_id)
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "State Exposure Probe Hammer",
		"part_kind": "terminal",
		"part_index": 0,
		"node_index": 1,
		"torso_unit_index": 0,
		"independent_damage": true,
		"terminal_weapon_kind": "melee",
		"damage_type": "blunt",
		"material_class": "weapon",
		"damage_coeff": 2.0,
		"break_coeff": 1.0,
		"stiffness_momentum": 120.0,
		"path_stiffness_momentum": 60.0,
	}


func _collider_for_node(unit, node_id: int) -> Dictionary:
	for raw_collider in unit.part_colliders():
		if raw_collider is Dictionary and int(Dictionary(raw_collider).get("node_index", -1)) == node_id:
			return Dictionary(raw_collider)
	return {}


func _segment_for_node(unit, node_id: int) -> Dictionary:
	for raw_segment in Array(unit.stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -1)) == node_id:
			return Dictionary(raw_segment)
	return {}


func _contains_key(value, key: String) -> bool:
	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has(key):
			return true
		for child_key in dict.keys():
			if _contains_key(dict[child_key], key):
				return true
	elif value is Array:
		for child in Array(value):
			if _contains_key(child, key):
				return true
	return false


func _apply_probe_hit(main, attacker, target) -> void:
	var target_collider := _collider_for_node(target, TARGET_NODE_ID)
	_require(not target_collider.is_empty(), "Target collider should exist before hit.")
	if target_collider.is_empty():
		return
	main._apply_runtime_contact_damage(
		attacker,
		_attacker_collider(),
		target,
		target_collider,
		Vector2.RIGHT,
		80.0,
		Vector2(1.2, 0.0),
		"active_melee"
	)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main._reset_hardware_fault_runtime_state()
	main.battle_attack_rule_log.clear()
	var attacker = _spawn_unit(main, 1, "State Exposure Attacker", "state-exposure-attacker", 1.0)
	var source_stats := _unit_stats("state-exposure-target")
	var original_segments: Array = Array(source_stats.get("runtime_topology_segments", [])).duplicate(true)
	var target = main._create_unit(2, "hero", source_stats, "State Exposure Target", 1.4, 0.0)
	main._assign_unit_role(target, "hero")
	target.deploy(1.4, 0.0)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var initial_collider := _collider_for_node(target, TARGET_NODE_ID)
	_require(String(initial_collider.get("hardware_fault_state", "")) == "normal", "Initial runtime collider should expose normal hardware state: %s" % str(initial_collider))
	_require(String(_segment_for_node(target, TARGET_NODE_ID).get("hardware_fault_state", "")) == "normal", "Initial runtime segment should expose normal hardware state.")
	_apply_probe_hit(main, attacker, target)
	var faulted_collider := _collider_for_node(target, TARGET_NODE_ID)
	var faulted_segment := _segment_for_node(target, TARGET_NODE_ID)
	_require(String(faulted_collider.get("hardware_fault_state", "")) == "faulted", "Faulted runtime collider should stay targetable and expose faulted state: %s" % str(faulted_collider))
	_require(String(faulted_segment.get("hardware_fault_state", "")) == "faulted", "Faulted runtime segment should expose faulted state: %s" % str(faulted_segment))
	_require(int(faulted_collider.get("hardware_fault_transition_sequence", 0)) == 1, "Faulted collider should expose transition sequence 1: %s" % str(faulted_collider))
	_apply_probe_hit(main, attacker, target)
	_require(_collider_for_node(target, TARGET_NODE_ID).is_empty(), "Destroyed runtime hardware should remove its collider.")
	var state_table: Dictionary = main._hardware_fault_live_state_table()
	var target_state = Dictionary(Dictionary(state_table.get(BODY_ID, {})).get(TARGET_NODE_ID, {}))
	_require(String(target_state.get("state", "")) == "destroyed", "Destroyed runtime hardware state should remain inspectable in the live state table: %s" % str(state_table))
	_require(not _contains_key(original_segments, "hardware_fault_state"), "Original runtime segment fixture should not be mutated with hardware fault state: %s" % str(original_segments))
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_RUNTIME_STATE_EXPOSURE_PROBE ok state=%s" % String(target_state.get("state", "")))
	quit(0)
