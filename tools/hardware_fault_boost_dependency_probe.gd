extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:boost-fault-target:body0"
const CORE_NODE_ID := 0
const ARM_NODE_ID := 2
const TARGET_FORWARD := Vector2.LEFT

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _spawn_unit(main, owner: int, name: String, unit_id: String, ring: float):
	var stats := {
		"unit_id": unit_id,
		"health": 1000,
		"max_health": 1000,
		"mass": 40.0,
		"radius": 0.18,
		"length": 0.7,
		"move_speed": 4.0,
		"move_acceleration": 32.0,
		"movement_profile": "vector",
		"thruster_boost_extra_demand": 40.0,
		"boost_momentum": 160.0,
		"boost_total_momentum": 160.0,
		"boost_speed": 8.0,
		"boost_duration": 0.25,
		"boost_cooldown": 0.5,
		"boost_heat": 0.0,
		"boost_angle_degrees": 360.0,
		"teamedit_runtime_topology": true,
		"electronic_armor_max": 0.0,
		"runtime_topology_segments": [
			{
				"node_index": CORE_NODE_ID,
				"part_kind": "torso",
				"name": "Boost Probe Core",
				"a_local": Vector2(-0.14, 0.0),
				"b_local": Vector2(0.14, 0.0),
				"radius": 0.12,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": CORE_NODE_ID,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 100.0,
				"path_stiffness_momentum": 100.0,
			},
			{
				"node_index": ARM_NODE_ID,
				"part_kind": "limb_muscle",
				"name": "Boost Probe Arm",
				"a_local": Vector2(0.14, 0.0),
				"b_local": Vector2(0.44, 0.0),
				"radius": 0.08,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": CORE_NODE_ID,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 100.0,
				"path_stiffness_momentum": 100.0,
			},
		],
		"runtime_topology_edges": [
			{"a_node": ARM_NODE_ID, "a_socket": "root_joint", "b_node": CORE_NODE_ID, "b_socket": "torso_port:0", "schema": "socket_edge_v1"},
		],
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "Boost Probe Hammer",
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


func _apply_core_probe_hit(main, attacker, target) -> void:
	var target_collider := _collider_for_node(target, CORE_NODE_ID)
	_require(not target_collider.is_empty(), "Core collider should be available before hit.")
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


func _state_for(main, node_id: int) -> Dictionary:
	var table: Dictionary = main._hardware_fault_live_state_table()
	var body: Dictionary = Dictionary(table.get(BODY_ID, {}))
	return Dictionary(body.get(node_id, body.get(str(node_id), {})))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main._reset_hardware_fault_runtime_state()
	main.battle_attack_rule_log.clear()
	main.battle_mode = MainScene.MODE_PVP
	var attacker = _spawn_unit(main, 1, "Boost Fault Attacker", "boost-fault-attacker", 1.0)
	var target = _spawn_unit(main, 2, "Boost Fault Target", "boost-fault-target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_require(target.boost(TARGET_FORWARD, MainScene.RING_LENGTH), "Normal primary core should allow boost before a hardware fault.")
	target.boost_cooldown_timer = 0.0
	target.boost_drive_timer = 0.0
	target.boost_drive_duration = 0.0
	target.boost_drive_velocity_remaining = Vector2.ZERO
	_apply_core_probe_hit(main, attacker, target)
	var core_state := _state_for(main, CORE_NODE_ID)
	_require(String(core_state.get("state", "")) == "faulted", "First core overload should fault the primary core: %s" % str(core_state))
	_require(target.active, "First core overload should leave the unit alive.")
	target.boost_cooldown_timer = 0.0
	target.boost_drive_timer = 0.0
	var boosted_after_fault: bool = target.boost(TARGET_FORWARD, MainScene.RING_LENGTH)
	_require(not boosted_after_fault, "Faulted primary core should block boost.")
	_require(target.boost_drive_timer <= 0.001, "Fault-blocked boost should not start the boost timer.")
	_require(String(target.get_meta("movement_gate_reason", "")).contains("hardware_fault"), "Boost gate reason should name hardware fault, got %s." % String(target.get_meta("movement_gate_reason", "")))
	_require(String(target.get_meta("movement_gate_reason", "")).contains("Boost Probe Core"), "Boost gate reason should name the first failed hardware dependency, got %s." % String(target.get_meta("movement_gate_reason", "")))
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_BOOST_DEPENDENCY_PROBE ok state=%s" % String(core_state.get("state", "")))
	quit(0)
