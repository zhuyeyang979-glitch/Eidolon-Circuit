extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:non-primary-core-target:body0"
const PRIMARY_CORE_NODE_ID := 0
const SECONDARY_CORE_NODE_ID := 4
const CHILD_NODE_ID := 5
const TARGET_ATTACK_INDEX := 1

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
		"teamedit_runtime_topology": true,
		"electronic_armor_max": 0.0,
		"runtime_topology_segments": [
			{
				"node_index": PRIMARY_CORE_NODE_ID,
				"part_kind": "torso",
				"name": "Probe Primary Core",
				"a_local": Vector2(-0.14, 0.0),
				"b_local": Vector2(0.14, 0.0),
				"radius": 0.12,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": PRIMARY_CORE_NODE_ID,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 100.0,
				"path_stiffness_momentum": 100.0,
			},
			{
				"node_index": SECONDARY_CORE_NODE_ID,
				"part_kind": "torso",
				"name": "Probe Secondary Core-Like Hardware",
				"a_local": Vector2(0.14, 0.0),
				"b_local": Vector2(0.46, 0.0),
				"radius": 0.1,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": PRIMARY_CORE_NODE_ID,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 100.0,
				"path_stiffness_momentum": 100.0,
			},
			{
				"node_index": CHILD_NODE_ID,
				"part_kind": "terminal",
				"name": "Probe Secondary Branch Tool",
				"a_local": Vector2(0.46, 0.0),
				"b_local": Vector2(0.66, 0.0),
				"radius": 0.06,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": PRIMARY_CORE_NODE_ID,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 80.0,
				"path_stiffness_momentum": 80.0,
			},
		],
		"runtime_topology_edges": [
			{"a_node": SECONDARY_CORE_NODE_ID, "a_socket": "root_joint", "b_node": PRIMARY_CORE_NODE_ID, "b_socket": "torso_port:0", "schema": "socket_edge_v1"},
			{"a_node": CHILD_NODE_ID, "a_socket": "root_joint", "b_node": SECONDARY_CORE_NODE_ID, "b_socket": "distal", "schema": "socket_edge_v1"},
		],
		"runtime_module_bindings": [{
			"attack_key": TARGET_ATTACK_INDEX + 1,
			"construct_body_id": BODY_ID,
			"target_nodes": [SECONDARY_CORE_NODE_ID, CHILD_NODE_ID],
			"root_index": SECONDARY_CORE_NODE_ID,
		}],
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "Non-Primary Core Probe Hammer",
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
	if unit == null or not is_instance_valid(unit):
		return {}
	for raw_collider in unit.part_colliders():
		if raw_collider is Dictionary and int(Dictionary(raw_collider).get("node_index", -1)) == node_id:
			return Dictionary(raw_collider)
	return {}


func _has_collider_for_node(unit, node_id: int) -> bool:
	return not _collider_for_node(unit, node_id).is_empty()


func _apply_secondary_core_probe_hit(main, attacker, target) -> void:
	var target_collider := _collider_for_node(target, SECONDARY_CORE_NODE_ID)
	_require(not target_collider.is_empty(), "Secondary core-like collider should be available before hit.")
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
	main.battle_mode = MainScene.MODE_PVP
	main.victory_points = {1: 0, 2: 0}
	main.game_over = false
	var attacker = _spawn_unit(main, 1, "Non-Primary Core Attacker", "non-primary-core-attacker", 1.0)
	var target = _spawn_unit(main, 2, "Non-Primary Core Target", "non-primary-core-target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_require(_has_collider_for_node(target, PRIMARY_CORE_NODE_ID), "Primary core collider should start present.")
	_require(_has_collider_for_node(target, SECONDARY_CORE_NODE_ID), "Secondary core-like hardware collider should start present.")
	_require(_has_collider_for_node(target, CHILD_NODE_ID), "Secondary branch child collider should start present.")
	_apply_secondary_core_probe_hit(main, attacker, target)
	_require(int(main.victory_points[1]) == 0, "First secondary-core overload should not award VP.")
	_require(main.active_units[2]["hero"] == target, "First secondary-core overload should keep the target deployed.")
	_require(_has_collider_for_node(target, SECONDARY_CORE_NODE_ID), "First secondary-core overload should fault but keep its collider.")
	_apply_secondary_core_probe_hit(main, attacker, target)
	var intents: Array = main._hardware_fault_destruction_intents()
	_require(intents.size() == 1, "Second secondary-core overload should record one destruction intent: %s" % str(intents))
	if not intents.is_empty() and intents[0] is Dictionary:
		_require(String(Dictionary(intents[0]).get("destruction_intent", "")) == "destroy_hardware", "Non-primary core-like hardware should emit destroy_hardware, not destroy_construct_body.")
		_require(int(Dictionary(intents[0]).get("hardware_node_id", -1)) == SECONDARY_CORE_NODE_ID, "Destruction intent should target the secondary core-like node.")
	_require(main.active_units[2]["hero"] == target, "Consumed non-primary core destruction should keep the target hero deployed.")
	_require(target.active, "Consumed non-primary core destruction should not retire the target.")
	_require(main.all_units.has(target), "Consumed non-primary core destruction should not remove the target from all_units.")
	_require(int(main.victory_points[1]) == 0, "Non-primary core-like hardware destruction should not award hero-kill VP.")
	_require(_has_collider_for_node(target, PRIMARY_CORE_NODE_ID), "Non-primary core-like hardware destruction should keep the primary core collider.")
	_require(not _has_collider_for_node(target, SECONDARY_CORE_NODE_ID), "Non-primary core-like hardware destruction should remove the secondary core-like collider.")
	_require(not _has_collider_for_node(target, CHILD_NODE_ID), "Destroyed secondary branch should remove downstream child colliders.")
	_require(main._battle_actor_disabled_modules(target).has(TARGET_ATTACK_INDEX), "Destroyed secondary branch dependency should keep the bound action disabled.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_NON_PRIMARY_CORE_DESTRUCTION_PROBE ok intents=%d vp=%d" % [intents.size(), int(main.victory_points[1])])
	quit(0)
