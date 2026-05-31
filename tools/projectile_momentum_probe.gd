extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, unit_name: String, ring: float, lane: float, overrides: Dictionary):
	var stats: Dictionary = main._compute_unit_stats(owner, role_key, 0).duplicate(true)
	for key in overrides.keys():
		stats[key] = overrides[key]
	var unit = main._create_unit(owner, role_key, stats, unit_name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _catalog_part(slot_key: String, name: String) -> Dictionary:
	for raw_part in MainScene.COMMON_CATALOG[slot_key]:
		if raw_part is Dictionary and String(Dictionary(raw_part).get("name", "")) == name:
			return Dictionary(raw_part)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var true_bullet_momentum := main._projectile_momentum_for_event({
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"damage_type": "bullet",
	})
	var bullet_hell_momentum := main._projectile_momentum_for_event({
		"projectile": true,
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"damage_type": "bullet",
	})
	var laser_momentum := main._projectile_momentum_for_event({
		"projectile": true,
		"projectile_style": "beam",
		"damage_type": "laser",
	})
	var chemical_momentum := main._projectile_momentum_for_event({
		"projectile": true,
		"projectile_style": "spray",
		"damage_type": "chemical",
	})
	var explosive_momentum := main._projectile_momentum_for_event({
		"projectile": true,
		"projectile_behavior": "explosive",
		"projectile_style": "explosive",
		"damage_type": "bullet",
	})
	if true_bullet_momentum <= bullet_hell_momentum or bullet_hell_momentum <= laser_momentum:
		_fail("Projectile momentum order should be true bullet > bullet hell > laser.")
	if bullet_hell_momentum <= chemical_momentum:
		_fail("Bullet hell should have more immediate momentum than chemical splash.")
	if explosive_momentum <= bullet_hell_momentum:
		_fail("Explosive projectile should be a high-momentum ranged impact.")
	var bullet_speed := main._projectile_collision_speed_for_event({
		"projectile": true,
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"damage_type": "bullet",
	})
	var bullet_mass := main._projectile_mass_for_event({
		"projectile": true,
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"damage_type": "bullet",
	}, bullet_speed)
	if absf(bullet_mass * bullet_speed - bullet_hell_momentum) > 0.75:
		_fail("Projectile momentum should be derived from projectile mass times collision speed.")

	var cannon := _catalog_part("muscle", "REDLINE BREACH SHELL CANNON")
	if cannon.is_empty():
		_fail("Explosive terminal weapon is missing from muscle catalog.")
	if String(cannon.get("projectile_behavior", "")) != "explosive" or float(cannon.get("explosion_radius", 0.0)) < 0.5:
		_fail("Explosive cannon should declare explosive behavior and a wide blast radius.")
	if float(cannon.get("projectile_momentum", 0.0)) < explosive_momentum:
		_fail("Explosive cannon should carry explicit high projectile momentum.")

	var completed_group := main._complete_attack_group_physics({
		"name": "Probe Explosive Group",
		"projectile": true,
		"projectile_behavior": "explosive",
		"projectile_style": "explosive",
		"damage_type": "bullet",
		"explosion_radius": 0.82,
		"damage": 17,
	}, {"stiffness": 160.0, "mass": 34.0})
	if float(completed_group.get("projectile_momentum", 0.0)) < explosive_momentum:
		_fail("Completed projectile attack groups should auto-fill projectile momentum.")

	var blast_attacker = _spawn_unit(main, 1, "hero", "Explosive Probe Shooter", 1.0, 0.0, {
		"health": 160,
		"mass": 34.0,
		"radius": 0.18,
	})
	var blast_primary = _spawn_unit(main, 2, "hero", "Explosive Probe Primary", 1.55, 0.0, {
		"health": 160,
		"mass": 22.0,
		"radius": 0.18,
		"melee_stability_threshold": 18.0,
		"electronic_armor_max": 0.0,
	})
	var blast_secondary = _spawn_unit(main, 2, "puppet", "Explosive Probe Splash", 1.68, 0.28, {
		"health": 160,
		"mass": 22.0,
		"radius": 0.18,
		"melee_stability_threshold": 18.0,
		"electronic_armor_max": 0.0,
	})
	var blast_neighbor = _spawn_unit(main, 2, "puppet", "Explosive Probe Neighbor", 1.78, 0.08, {
		"health": 160,
		"mass": 22.0,
		"radius": 0.18,
		"melee_stability_threshold": 18.0,
		"electronic_armor_max": 0.0,
	})
	var blast_primary_before := int(blast_primary.health)
	var blast_secondary_before := int(blast_secondary.health)
	var blast_neighbor_before := int(blast_neighbor.health)
	var naked_event := {
		"owner_id": 1,
		"state": "normal",
		"projectile": true,
		"projectile_behavior": "explosive",
		"projectile_style": "explosive",
		"damage": 40,
		"damage_type": "bullet",
		"range": 1.05,
		"lane_range": 0.3,
		"direction": Vector2.RIGHT,
	}
	main._resolve_attack(blast_attacker, naked_event)
	if int(naked_event.get("projectile_impact_target_id", 0)) != 0 or int(blast_primary.health) != blast_primary_before:
		_fail("Projectile events without a gun terminal source must be rejected.")
	var cannon_group := cannon.duplicate(true)
	cannon_group["lane_bias"] = 0.0
	cannon_group["joint_length"] = 0.02
	cannon_group["muscle_length"] = 0.02
	cannon_group["terminal_length"] = 0.08
	cannon_group["terminal_radius"] = 0.14
	var blast_event := {
		"owner_id": 1,
		"state": "normal",
		"module_action_profile": "gun_activate",
		"gun_activation": true,
		"projectile": true,
		"projectile_behavior": "explosive",
		"projectile_style": "explosive",
		"damage": 40,
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"range": 1.05,
		"lane_range": 0.3,
		"direction": Vector2.RIGHT,
		"material_class": "projectile",
		"explosion_radius": 0.82,
		"explosion_damage": 28,
		"explosion_damage_type": "bullet",
		"explosion_style": "explosive",
		"muscle_node": 0,
		"collision_group": cannon_group,
	}
	main._resolve_attack(blast_attacker, blast_event)
	var impact_id := int(blast_event.get("projectile_impact_target_id", 0))
	var blast_direct_ok := impact_id != 0
	var blast_splash_ok := false
	for entry in [
		{"unit": blast_primary, "before": blast_primary_before},
		{"unit": blast_secondary, "before": blast_secondary_before},
		{"unit": blast_neighbor, "before": blast_neighbor_before},
	]:
		var unit = entry["unit"]
		if int(unit.get_instance_id()) == impact_id:
			continue
		if int(unit.health) < int(entry["before"]):
			blast_splash_ok = true
	var blast_stagger_ok := float(blast_primary.get_meta("melee_stagger_timer", 0.0)) > 0.05 or float(blast_secondary.get_meta("melee_stagger_timer", 0.0)) > 0.05 or float(blast_neighbor.get_meta("melee_stagger_timer", 0.0)) > 0.05
	if not blast_direct_ok or not blast_splash_ok or not blast_stagger_ok:
		print("EXPLOSIVE_DEBUG impact=%d ids=%d/%d/%d hp=%d,%d,%d -> %d,%d,%d splash=%s stagger=%.3f/%.3f/%.3f" % [
			impact_id,
			int(blast_primary.get_instance_id()),
			int(blast_secondary.get_instance_id()),
			int(blast_neighbor.get_instance_id()),
			blast_primary_before,
			blast_secondary_before,
			blast_neighbor_before,
			int(blast_primary.health),
			int(blast_secondary.health),
			int(blast_neighbor.health),
			str(blast_splash_ok),
			float(blast_primary.get_meta("melee_stagger_timer", 0.0)),
			float(blast_secondary.get_meta("melee_stagger_timer", 0.0)),
			float(blast_neighbor.get_meta("melee_stagger_timer", 0.0)),
		])
		_fail("Explosive projectile should deal direct damage, wide splash damage, and projectile momentum stagger.")
	main._clear_all_units()

	var attacker = _spawn_unit(main, 1, "hero", "Projectile Probe Shooter", 1.0, 0.0, {
		"health": 140,
		"mass": 30.0,
		"radius": 0.18,
	})
	var target = _spawn_unit(main, 2, "hero", "Low Stability Projectile Target", 1.55, 0.0, {
		"health": 140,
		"mass": 20.0,
		"radius": 0.18,
		"melee_stability_threshold": 20.0,
	})
	main._apply_projectile_momentum_stagger(attacker, target, {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"damage_type": "bullet",
		"direction": Vector2.RIGHT,
	})
	var true_bullet_stagger := float(target.get_meta("melee_stagger_timer", 0.0))
	if true_bullet_stagger <= 0.05:
		_fail("High-momentum true bullet should cause ranged hard-stun against low stability.")
	var approach_event := {
		"projectile": true,
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"damage_type": "bullet",
		"direction": Vector2.RIGHT,
		"projectile_mass": 2.0,
		"projectile_collision_speed": 10.0,
	}
	target.velocity = Vector2.LEFT * 4.0
	var approach_momentum := main._projectile_collision_momentum(attacker, target, approach_event.duplicate(true))
	target.velocity = Vector2.RIGHT * 4.0
	var recede_momentum := main._projectile_collision_momentum(attacker, target, approach_event.duplicate(true))
	if approach_momentum <= recede_momentum * 1.8:
		_fail("Projectile collision momentum should use relative closing speed: approaching target must take more momentum than receding target.")

	var stable_target = _spawn_unit(main, 2, "hero", "Stable Projectile Target", 2.0, 0.0, {
		"health": 140,
		"mass": 44.0,
		"radius": 0.2,
		"melee_stability_threshold": 180.0,
	})
	main._apply_projectile_momentum_stagger(attacker, stable_target, {
		"projectile": true,
		"projectile_behavior": "laser",
		"projectile_style": "beam",
		"damage_type": "laser",
		"direction": Vector2.RIGHT,
	})
	var laser_stagger := float(stable_target.get_meta("melee_stagger_timer", 0.0))
	if laser_stagger > 0.01:
		_fail("Low-momentum laser should not stagger a stable target.")

	print("PROJECTILE_MOMENTUM true=%.0f bullet_hell=%.0f laser=%.0f chemical=%.0f explosive=%.0f mass=%.2f speed=%.1f approach=%.1f recede=%.1f true_stagger=%.3f laser_stagger=%.3f cannon=%.0f" % [
		true_bullet_momentum,
		bullet_hell_momentum,
		laser_momentum,
		chemical_momentum,
		explosive_momentum,
		bullet_mass,
		bullet_speed,
		approach_momentum,
		recede_momentum,
		true_bullet_stagger,
		laser_stagger,
		float(cannon.get("projectile_momentum", 0.0)),
	])
	quit()
