extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:stable-target:body0"
const TARGET_NODE_ID := 2
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
		"teamedit_runtime_topology": false,
		"electronic_armor_max": 0.0,
		"runtime_module_bindings": [{
			"attack_key": TARGET_ATTACK_INDEX + 1,
			"construct_body_id": BODY_ID,
			"target_nodes": [TARGET_NODE_ID],
			"root_index": TARGET_NODE_ID,
		}],
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _attacker_collider() -> Dictionary:
	return {
		"name": "Replay Probe Hammer",
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


func _target_collider() -> Dictionary:
	return {
		"name": "Replay Probe Arm",
		"part_kind": "limb_muscle",
		"part_index": TARGET_ATTACK_INDEX,
		"node_index": TARGET_NODE_ID,
		"hardware_node_id": TARGET_NODE_ID,
		"construct_body_id": BODY_ID,
		"primary_core_node_id": 0,
		"torso_unit_index": 0,
		"runtime_momentum_capacity": 10.0,
		"stiffness_momentum": 100.0,
		"path_stiffness_momentum": 100.0,
		"break_coeff": 0.1,
	}


func _apply_probe_hit(main, attacker, target) -> void:
	main._apply_runtime_contact_damage(
		attacker,
		_attacker_collider(),
		target,
		_target_collider(),
		Vector2.RIGHT,
		80.0,
		Vector2(1.2, 0.0),
		"active_melee"
	)


func _replay_relevant_breakdowns(main) -> Array:
	var rows: Array = []
	for raw_entry in main.battle_attack_rule_log:
		if not (raw_entry is Dictionary):
			continue
		var breakdown: Dictionary = Dictionary(Dictionary(raw_entry).get("breakdown", {}))
		rows.append({
			"raw_momentum": float(breakdown.get("raw_momentum", 0.0)),
			"path_capped_momentum": float(breakdown.get("path_capped_momentum", 0.0)),
			"hardware_capped_momentum": float(breakdown.get("hardware_capped_momentum", 0.0)),
			"runtime_momentum_capacity": float(breakdown.get("runtime_momentum_capacity", 0.0)),
			"hardware_fault_pre_state": String(breakdown.get("hardware_fault_pre_state", "")),
			"hardware_fault_post_state": String(breakdown.get("hardware_fault_post_state", "")),
			"hardware_fault_transition": String(breakdown.get("hardware_fault_transition", "")),
			"hardware_fault_destruction_intent": String(breakdown.get("hardware_fault_destruction_intent", "")),
		})
	return rows


func _run_live_sequence(main) -> Dictionary:
	main._clear_all_units()
	main._reset_hardware_fault_runtime_state()
	main.battle_attack_rule_log.clear()
	var attacker = _spawn_unit(main, 1, "Replay Attacker", "stable-attacker", 1.0)
	var target = _spawn_unit(main, 2, "Replay Target", "stable-target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_apply_probe_hit(main, attacker, target)
	_apply_probe_hit(main, attacker, target)
	return {
		"state_table": main._hardware_fault_live_state_table(),
		"transition_events": main._hardware_fault_transition_events(),
		"destruction_intents": main._hardware_fault_destruction_intents(),
		"breakdowns": _replay_relevant_breakdowns(main),
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for method_name in [
		"_reset_hardware_fault_runtime_state",
		"_hardware_fault_live_state_table",
		"_hardware_fault_transition_events",
		"_hardware_fault_destruction_intents",
	]:
		_require(main.has_method(method_name), "Main should expose live hardware fault adapter method %s." % method_name)
	if failed:
		quit(1)
		return
	var first := _run_live_sequence(main)
	var second := _run_live_sequence(main)
	_require(first == second, "Identical live hardware fault sequences should replay identically.\nfirst=%s\nsecond=%s" % [str(first), str(second)])
	var events: Array = Array(first.get("transition_events", []))
	_require(events.size() == 2, "Replay fixture should produce two transition events: %s" % str(events))
	if not events.is_empty():
		var first_event: Dictionary = Dictionary(events[0])
		_require(String(first_event.get("attacker_actor_id", "")) == "p1:hero:stable-attacker", "Replay event should use stable attacker actor id, got %s" % str(first_event))
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_LIVE_REPLAY_PROBE ok events=%d" % events.size())
	quit(0)
