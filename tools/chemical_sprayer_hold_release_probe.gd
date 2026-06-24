extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, name: String, ring: float, lane: float):
	var stats := {
		"health": 120,
		"max_health": 120,
		"mass": 40.0,
		"radius": 0.18,
		"ammo_capacity": {"chemical": 12},
		"teamedit_runtime_topology": false,
	}
	var unit = main._create_unit(owner, "hero", stats, name, ring, lane)
	main._assign_unit_role(unit, "hero")
	unit.deploy(ring, lane)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "Sprayer", 1.0, 0.0)
	var target = _spawn_unit(main, 2, "Target", 1.9, 0.0)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var event := {
		"owner_id": 1,
		"module_action_profile": "gun_activate",
		"gun_activation": true,
		"projectile": true,
		"projectile_only": true,
		"gun_kind": "sprayer",
		"ammo_kind": "chemical",
		"muscle_node": 0,
		"damage_type": "chemical",
		"projectile_damage_type": "chemical",
		"projectile_style": "spray",
		"projectile_behavior": "chemical_line",
		"travel_path": "straight",
		"projectile_momentum": 999.0,
		"projectile_mass": 999.0,
		"projectile_damage_coeff": MainScene.PART_DAMAGE_COEFF_TERMINAL_MELEE * MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_DAMAGE_MULT,
		"chemical_frontload": MainScene.STANDARD_CHEMICAL_SPRAYER_INSTANT_DAMAGE_MULT / MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_DAMAGE_MULT,
		"chemical_dot_mult": 1.0,
		"chemical_dot_duration": MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_SECONDS,
		"chemical_dot_no_stack": true,
		"range": 1.6,
		"lane_range": MainScene.STANDARD_CHEMICAL_SPRAYER_WIDTH_M * 0.5,
		"direction": Vector2.RIGHT,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "gun", "shape": "sprayer_nozzle"},
	}
	var before_ammo := main._current_ammo(attacker, "chemical")
	var before_hp := int(target.health)
	main._resolve_attack(attacker, event)
	if main.pending_chemical_projectiles.size() != 1:
		_fail("Sprayer hold should queue a chemical projectile.")
	if main._current_ammo(attacker, "chemical") != before_ammo - 1:
		_fail("Sprayer firing should consume exactly one chemical ammo.")
	main._update_chemical_projectiles(2.0)
	if int(target.health) >= before_hp:
		_fail("Queued sprayer projectile should eventually damage the target.")
	if float(target.get_meta("chemical_dot_timer", 0.0)) <= 0.0:
		_fail("Chemical sprayer impact should apply continuing DoT status.")
	if main.battle_attack_rule_log.is_empty():
		_fail("Chemical sprayer impact should record attack telemetry.")
	var latest: Dictionary = Dictionary(main.battle_attack_rule_log.back())
	var breakdown: Dictionary = Dictionary(latest.get("breakdown", {}))
	if absf(float(breakdown.get("momentum", 0.0)) - 1.0) > 0.001:
		_fail("Chemical runtime momentum should stay fixed at 1 despite explicit overrides: %s" % str(breakdown))
	var ammo_after_fire := main._current_ammo(attacker, "chemical")
	# Releasing a sprayer does not fire a delayed sniper shot.
	main.gun_activation_state[1] = {"gun_kind": "sprayer"}
	main._release_runtime_gun_activation(1)
	if main._current_ammo(attacker, "chemical") != ammo_after_fire:
		_fail("Releasing a sprayer should not consume extra ammo.")
	print("CHEMICAL_SPRAYER_HOLD_RELEASE_PROBE ok ammo=%d->%d hp=%d->%d" % [before_ammo, ammo_after_fire, before_hp, int(target.health)])
	quit()
