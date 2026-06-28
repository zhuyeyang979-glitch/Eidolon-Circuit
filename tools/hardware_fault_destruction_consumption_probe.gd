extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:destructible-target:body0"
const TARGET_NODE_ID := 2
const CHILD_NODE_ID := 3
const TARGET_ATTACK_INDEX := 1
const CHILD_ATTACK_INDEX := 2

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
				"node_index": 0,
				"part_kind": "torso",
				"name": "Probe Core",
				"a_local": Vector2(-0.14, 0.0),
				"b_local": Vector2(0.14, 0.0),
				"radius": 0.12,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
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
			{
				"node_index": CHILD_NODE_ID,
				"part_kind": "terminal",
				"name": "Probe Hand",
				"a_local": Vector2(0.44, 0.0),
				"b_local": Vector2(0.62, 0.0),
				"radius": 0.06,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
				"runtime_momentum_capacity": 10.0,
				"stiffness_momentum": 80.0,
				"path_stiffness_momentum": 80.0,
			},
		],
		"runtime_topology_edges": [
			{"a_node": TARGET_NODE_ID, "a_socket": "root_joint", "b_node": 0, "b_socket": "torso_port:0", "schema": "socket_edge_v1"},
			{"a_node": CHILD_NODE_ID, "a_socket": "root_joint", "b_node": TARGET_NODE_ID, "b_socket": "distal", "schema": "socket_edge_v1"},
		],
		"runtime_module_bindings": [
			{
				"attack_key": TARGET_ATTACK_INDEX + 1,
				"construct_body_id": BODY_ID,
				"target_nodes": [TARGET_NODE_ID, CHILD_NODE_ID],
				"root_index": TARGET_NODE_ID,
			},
			{
				"attack_key": CHILD_ATTACK_INDEX + 1,
				"construct_body_id": BODY_ID,
				"target_nodes": [CHILD_NODE_ID],
				"root_index": CHILD_NODE_ID,
			},
		],
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "Destruction Probe Hammer",
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
	return not _collider_for_node(unit, node_id).is_empty()


func _apply_probe_hit(main, attacker, target) -> void:
	var target_collider := _collider_for_node(target, TARGET_NODE_ID)
	_require(not target_collider.is_empty(), "Target collider node %d should be available before hit." % TARGET_NODE_ID)
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
	var attacker = _spawn_unit(main, 1, "Destruction Attacker", "destruction-attacker", 1.0)
	var target = _spawn_unit(main, 2, "Destruction Target", "destructible-target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_require(_has_collider_for_node(target, TARGET_NODE_ID), "Target hardware node should start with a collider.")
	_require(_has_collider_for_node(target, CHILD_NODE_ID), "Child hardware node should start with a collider.")
	_require(not main._battle_actor_disabled_modules(target).has(CHILD_ATTACK_INDEX), "Child-only action should start enabled before its branch is destroyed.")
	_apply_probe_hit(main, attacker, target)
	_require(_has_collider_for_node(target, TARGET_NODE_ID), "First overload should fault but keep the target collider.")
	_apply_probe_hit(main, attacker, target)
	var intents: Array = main._hardware_fault_destruction_intents()
	_require(intents.size() == 1, "Second overload should still record one destruction intent: %s" % str(intents))
	_require(not _has_collider_for_node(target, TARGET_NODE_ID), "Consumed destroy_hardware intent should remove the target collider.")
	_require(not _has_collider_for_node(target, CHILD_NODE_ID), "Destroyed branch should remove downstream child colliders.")
	_require(main._battle_actor_disabled_modules(target).has(TARGET_ATTACK_INDEX), "Destroyed hardware dependency should keep the bound action disabled.")
	_require(main._battle_actor_disabled_modules(target).has(CHILD_ATTACK_INDEX), "Destroyed downstream dependency should keep a child-only action disabled.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_DESTRUCTION_CONSUMPTION_PROBE ok intents=%d" % intents.size())
	quit(0)
