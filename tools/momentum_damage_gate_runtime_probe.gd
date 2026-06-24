extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _spawn_unit(main, owner: int, name: String, ring: float):
	var stats := {
		"health": 180,
		"max_health": 180,
		"mass": 40.0,
		"radius": 0.18,
		"teamedit_runtime_topology": false,
		"electronic_armor_max": 0.0,
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, 0.0)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_attack_rule_log.clear()
	var attacker = _spawn_unit(main, 1, "Telemetry Attacker", 1.0)
	var target = _spawn_unit(main, 2, "Telemetry Target", 1.4)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var attacker_collider := {
		"name": "Telemetry Hammer",
		"part_kind": "terminal",
		"part_index": 0,
		"node_index": 0,
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
		"name": "Telemetry Core",
		"part_kind": "torso",
		"part_index": 0,
		"node_index": 0,
		"torso_unit_index": 0,
		"stiffness_momentum": 100.0,
		"path_stiffness_momentum": 100.0,
	}
	var hp_before := int(target.health)
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
	if int(target.health) >= hp_before:
		_fail("Runtime melee contact should deal damage.")
	if main.battle_attack_rule_log.is_empty():
		_fail("Runtime melee contact should record attack telemetry.")
	var entry: Dictionary = Dictionary(main.battle_attack_rule_log.back())
	var breakdown: Dictionary = Dictionary(entry.get("breakdown", {}))
	for field in [
		"raw_momentum",
		"momentum",
		"capped_momentum",
		"damage_coefficient",
		"adjustment_coefficient",
		"break_value",
		"effective_break_value",
		"break_gate",
		"knock_momentum",
		"final_damage",
	]:
		if not breakdown.has(field):
			_fail("Runtime melee breakdown missing %s: %s" % [field, str(breakdown)])
	if absf(float(breakdown.get("raw_momentum", 0.0)) - 80.0) > 0.001:
		_fail("Runtime melee telemetry should retain raw momentum 80: %s" % str(breakdown))
	if absf(float(breakdown.get("capped_momentum", 0.0)) - 60.0) > 0.001:
		_fail("Runtime melee telemetry should expose path-capped momentum 60: %s" % str(breakdown))
	if absf(float(breakdown.get("break_gate", 0.0)) - float(breakdown.get("effective_break_value", -1.0))) > 0.001:
		_fail("Runtime melee break_gate should equal effective break value: %s" % str(breakdown))
	if bool(breakdown.get("threshold_blocked", true)):
		_fail("Runtime melee telemetry should report a passed damage gate: %s" % str(breakdown))
	if failed:
		quit(1)
		return
	print("MOMENTUM_DAMAGE_GATE_RUNTIME_PROBE ok damage=%d momentum=%.1f break=%.2f" % [
		hp_before - int(target.health),
		float(breakdown.get("momentum", 0.0)),
		float(breakdown.get("effective_break_value", 0.0)),
	])
	quit(0)
