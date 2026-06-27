extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const BODY_ID := "p2:hero:0:body0"
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


func _require_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) <= 0.001:
		return
	_fail("%s expected %.3f got %.3f" % [label, expected, actual])


func _spawn_unit(main, owner: int, name: String, ring: float):
	var stats := {
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


func _state_for(main, body_id: String, node_id: int) -> Dictionary:
	var table: Dictionary = main._hardware_fault_live_state_table()
	var body = table.get(body_id, {})
	if not (body is Dictionary):
		return {}
	var entry = Dictionary(body).get(node_id, Dictionary(body).get(str(node_id), {}))
	return Dictionary(entry) if entry is Dictionary else {}


func _latest_breakdown(main) -> Dictionary:
	_require(not main.battle_attack_rule_log.is_empty(), "Hardware fault live hit should record attack telemetry.")
	if main.battle_attack_rule_log.is_empty():
		return {}
	var entry: Dictionary = Dictionary(main.battle_attack_rule_log.back())
	return Dictionary(entry.get("breakdown", {}))


func _apply_probe_hit(main, attacker, target, attacker_collider: Dictionary, target_collider: Dictionary) -> void:
	main._apply_runtime_contact_damage(
		attacker,
		attacker_collider,
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
	main.battle_attack_rule_log.clear()
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
	main._reset_hardware_fault_runtime_state()
	var attacker = _spawn_unit(main, 1, "Hardware Fault Live Attacker", 1.0)
	var target = _spawn_unit(main, 2, "Hardware Fault Live Target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var attacker_collider := {
		"name": "Fault Probe Hammer",
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
	var target_collider := {
		"name": "Fault Probe Arm",
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
	_require(not main._battle_actor_disabled_modules(target).has(TARGET_ATTACK_INDEX), "Target action should start enabled before any overload.")
	var hp_before := int(target.health)
	_apply_probe_hit(main, attacker, target, attacker_collider, target_collider)
	var hp_after_first := int(target.health)
	_require(hp_after_first < hp_before, "First hardware fault live hit should deal capped damage.")
	var first_state := _state_for(main, BODY_ID, TARGET_NODE_ID)
	_require(String(first_state.get("state", "")) == "faulted", "First overload should fault target hardware: %s" % str(first_state))
	_require(main._battle_actor_disabled_modules(target).has(TARGET_ATTACK_INDEX), "Faulted dependency should disable its bound action.")
	var first_breakdown := _latest_breakdown(main)
	_require_close(float(first_breakdown.get("raw_momentum", 0.0)), 80.0, "Raw momentum")
	_require_close(float(first_breakdown.get("path_capped_momentum", 0.0)), 60.0, "Path-capped momentum")
	_require_close(float(first_breakdown.get("hardware_capped_momentum", 0.0)), 10.0, "Hardware-capped momentum")
	_require_close(float(first_breakdown.get("runtime_momentum_capacity", 0.0)), 10.0, "Runtime hardware capacity")
	_require_close(float(first_breakdown.get("capped_momentum", 0.0)), 10.0, "Damage telemetry capped momentum")
	_require(String(first_breakdown.get("hardware_fault_pre_state", "")) == "normal", "First breakdown should show normal pre-state: %s" % str(first_breakdown))
	_require(String(first_breakdown.get("hardware_fault_post_state", "")) == "faulted", "First breakdown should show faulted post-state: %s" % str(first_breakdown))
	_apply_probe_hit(main, attacker, target, attacker_collider, target_collider)
	var second_state := _state_for(main, BODY_ID, TARGET_NODE_ID)
	_require(String(second_state.get("state", "")) == "destroyed", "Second overload should destroy target hardware: %s" % str(second_state))
	var events: Array = main._hardware_fault_transition_events()
	_require(events.size() == 2, "Two overload hits should create two transition events: %s" % str(events))
	if events.size() >= 2:
		var first_event: Dictionary = Dictionary(events[0])
		var second_event: Dictionary = Dictionary(events[1])
		_require(String(first_event.get("pre_state", "")) == "normal" and String(first_event.get("post_state", "")) == "faulted", "First event should be normal->faulted: %s" % str(first_event))
		_require(String(second_event.get("pre_state", "")) == "faulted" and String(second_event.get("post_state", "")) == "destroyed", "Second event should be faulted->destroyed: %s" % str(second_event))
		_require(int(first_event.get("contact_sequence", 0)) < int(second_event.get("contact_sequence", 0)), "Transition events should preserve contact order: %s" % str(events))
	var intents: Array = main._hardware_fault_destruction_intents()
	_require(intents.size() == 1, "Destroyed non-core hardware should queue one destruction intent: %s" % str(intents))
	if not intents.is_empty():
		var intent: Dictionary = Dictionary(intents[0])
		_require(String(intent.get("destruction_intent", "")) == "destroy_hardware", "Non-core destruction intent should destroy hardware: %s" % str(intent))
		_require(String(intent.get("construct_body_id", "")) == BODY_ID, "Destruction intent should preserve body id: %s" % str(intent))
		_require(int(intent.get("hardware_node_id", -1)) == TARGET_NODE_ID, "Destruction intent should preserve hardware node id: %s" % str(intent))
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_LIVE_ADAPTER_PROBE ok hp_delta=%d events=%d" % [
		hp_before - int(target.health),
		events.size(),
	])
	quit(0)
