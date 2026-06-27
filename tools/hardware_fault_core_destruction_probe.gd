extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:core-destruction-target:body0"
const CORE_NODE_ID := 0
const ARM_NODE_ID := 2
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
				"node_index": CORE_NODE_ID,
				"part_kind": "torso",
				"name": "Probe Core",
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
				"name": "Probe Arm",
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
		"runtime_module_bindings": [{
			"attack_key": TARGET_ATTACK_INDEX + 1,
			"construct_body_id": BODY_ID,
			"target_nodes": [CORE_NODE_ID, ARM_NODE_ID],
			"root_index": CORE_NODE_ID,
		}],
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "Core Destruction Probe Hammer",
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


func _has_collider_for_node(unit, node_id: int) -> bool:
	return unit != null and is_instance_valid(unit) and not _collider_for_node(unit, node_id).is_empty()


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
	var attacker = _spawn_unit(main, 1, "Core Destruction Attacker", "core-destruction-attacker", 1.0)
	var target = _spawn_unit(main, 2, "Core Destruction Target", "core-destruction-target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_require(_has_collider_for_node(target, CORE_NODE_ID), "Core hardware node should start with a collider.")
	_require(_has_collider_for_node(target, ARM_NODE_ID), "Downstream hardware node should start with a collider.")
	_apply_core_probe_hit(main, attacker, target)
	_require(int(main.victory_points[1]) == 0, "First core overload should fault without awarding VP.")
	_require(main.active_units[2]["hero"] == target, "First core overload should keep the target deployed.")
	_require(_has_collider_for_node(target, CORE_NODE_ID), "First core overload should keep the core collider.")
	_apply_core_probe_hit(main, attacker, target)
	var intents: Array = main._hardware_fault_destruction_intents()
	_require(intents.size() == 1, "Second core overload should record one destruction intent: %s" % str(intents))
	if not intents.is_empty() and intents[0] is Dictionary:
		_require(String(Dictionary(intents[0]).get("destruction_intent", "")) == "destroy_construct_body", "Core destruction intent should target the construct body.")
	_require(main.active_units[2]["hero"] == null, "Consumed core destruction should detach the target hero.")
	_require(not target.active, "Consumed core destruction should retire the target before frame-end free.")
	_require(not main.all_units.has(target), "Consumed core destruction should remove the target from all_units.")
	_require(int(main.victory_points[1]) == 1, "Core destruction should award one hero-kill VP.")
	_require(not _has_collider_for_node(target, CORE_NODE_ID), "Core destruction should clear the core collider.")
	_require(not _has_collider_for_node(target, ARM_NODE_ID), "Core destruction should clear downstream colliders.")
	if not intents.is_empty() and intents[0] is Dictionary:
		main._consume_hardware_fault_destruction_for_target(target, Dictionary(intents[0]), 1)
	_require(int(main.victory_points[1]) == 1, "Duplicate core destruction consume should not award VP twice.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_CORE_DESTRUCTION_PROBE ok intents=%d vp=%d" % [intents.size(), int(main.victory_points[1])])
	quit(0)
