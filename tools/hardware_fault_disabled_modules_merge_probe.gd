extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:disabled-merge-target:body0"
const AUTHORED_DISABLED_ATTACK_INDEX := 0
const FAULTED_ATTACK_INDEX := 1
const FAULT_NODE_ID := 2

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _spawn_target(main):
	var stats := {
		"unit_id": "disabled-merge-target",
		"health": 1000,
		"max_health": 1000,
		"mass": 40.0,
		"radius": 0.18,
		"length": 0.7,
		"teamedit_runtime_topology": true,
		"disabled_modules": [AUTHORED_DISABLED_ATTACK_INDEX],
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"name": "Disabled Merge Core",
				"a_local": Vector2(-0.14, 0.0),
				"b_local": Vector2(0.14, 0.0),
				"radius": 0.12,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
				"runtime_momentum_capacity": 40.0,
			},
			{
				"node_index": FAULT_NODE_ID,
				"part_kind": "limb_muscle",
				"name": "Disabled Merge Arm",
				"a_local": Vector2(0.14, 0.0),
				"b_local": Vector2(0.44, 0.0),
				"radius": 0.08,
				"construct_body_id": BODY_ID,
				"primary_core_node_id": 0,
				"runtime_momentum_capacity": 10.0,
			},
		],
		"runtime_topology_edges": [
			{"a_node": FAULT_NODE_ID, "a_socket": "root_joint", "b_node": 0, "b_socket": "torso_port:0", "schema": "socket_edge_v1"},
		],
		"runtime_module_bindings": [{
			"attack_key": FAULTED_ATTACK_INDEX + 1,
			"construct_body_id": BODY_ID,
			"target_nodes": [FAULT_NODE_ID],
			"root_index": FAULT_NODE_ID,
		}],
	}
	var unit = main._create_unit(2, "hero", stats, "Disabled Merge Target", 1.4, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(1.4, 0.0)
	return unit


func _spawn_malformed_disabled_target(main):
	var stats := {
		"unit_id": "disabled-merge-malformed-target",
		"health": 1000,
		"max_health": 1000,
		"mass": 40.0,
		"radius": 0.18,
		"length": 0.7,
		"teamedit_runtime_topology": true,
		"disabled_modules": ["not-a-module"],
	}
	var unit = main._create_unit(2, "hero", stats, "Malformed Disabled Merge Target", 1.8, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(1.8, 0.0)
	return unit


func _fault_bound_dependency(main) -> void:
	main.hardware_fault_state_table = {
		BODY_ID: {
			FAULT_NODE_ID: {
				"state": "faulted",
				"runtime_momentum_capacity": 10.0,
				"transition_sequence": 1,
				"primary_core_node_id": 0,
			},
		},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main._reset_hardware_fault_runtime_state()
	var target = _spawn_target(main)
	main.active_units = {
		1: {"hero": null, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var original_disabled: Array = Array(target.stats.get("disabled_modules", [])).duplicate(true)
	var original_bindings: Array = Array(target.stats.get("runtime_module_bindings", [])).duplicate(true)
	_fault_bound_dependency(main)
	var disabled: Array = main._battle_actor_disabled_modules(target)
	_require(disabled.has(AUTHORED_DISABLED_ATTACK_INDEX), "Authored disabled module should remain in battle disabled modules: %s" % str(disabled))
	_require(disabled.has(FAULTED_ATTACK_INDEX), "Hardware-faulted binding should be merged into battle disabled modules: %s" % str(disabled))
	_require(disabled.count(AUTHORED_DISABLED_ATTACK_INDEX) == 1, "Authored disabled module should not be duplicated: %s" % str(disabled))
	_require(disabled.count(FAULTED_ATTACK_INDEX) == 1, "Hardware disabled module should not be duplicated: %s" % str(disabled))
	_require(Array(target.stats.get("disabled_modules", [])) == original_disabled, "Disabled module adapter should not mutate stats.disabled_modules.")
	_require(Array(target.stats.get("runtime_module_bindings", [])) == original_bindings, "Disabled module adapter should not mutate runtime module bindings.")
	var malformed_target = _spawn_malformed_disabled_target(main)
	var malformed_disabled: Array = main._battle_actor_disabled_modules(malformed_target)
	_require(malformed_disabled.is_empty(), "Malformed authored disabled module IDs should not disable attack 0: %s" % str(malformed_disabled))
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_DISABLED_MODULES_MERGE_PROBE ok disabled=%s" % str(disabled))
	quit(0)
