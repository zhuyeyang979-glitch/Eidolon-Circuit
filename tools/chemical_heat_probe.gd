extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _spawn_unit(main, owner: int, role_key: String, unit_name: String, ring: float, lane: float, overrides: Dictionary):
	var stats: Dictionary = main._compute_unit_stats(owner, role_key, 0).duplicate(true)
	for key in overrides.keys():
		stats[key] = overrides[key]
	var unit = main._create_unit(owner, role_key, stats, unit_name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var attacker = _spawn_unit(main, 1, "hero", "Chem Probe Shooter", 1.0, 0.0, {
		"health": 100,
		"radius": 0.16,
	})
	var target = _spawn_unit(main, 2, "hero", "Chem Probe Target", 2.0, 0.0, {
		"health": 120,
		"radius": 0.2,
		"electronic_armor_max": 0.0,
	})
	var event := {
		"owner_id": 1,
		"state": "normal",
		"projectile": true,
		"ammo_consumed": true,
		"muscle_node": 0,
		"damage": 28,
		"damage_type": "chemical",
		"projectile_damage_type": "chemical",
		"projectile_style": "spray",
		"travel_path": "straight",
		"range": 1.6,
		"lane_range": 0.32,
		"direction": Vector2.RIGHT,
	}
	var chem_gun := {
		"name": "PROBE CHEMICAL SPRAYER",
		"projectile": true,
		"projectile_only": true,
		"material_class": "gun",
		"shape": "gun",
		"range": 1.6,
		"lane_range": 0.32,
		"damage_type": "chemical",
		"projectile_damage_type": "chemical",
		"projectile_style": "spray",
		"travel_path": "straight",
	}
	event["collision_group"] = chem_gun
	var before_hp := int(target.health)
	main._resolve_attack(attacker, event)
	var queued_ok: bool = main.pending_chemical_projectiles.size() == 1 and int(target.health) == before_hp
	main._update_chemical_projectiles(2.0)
	var impact_hp := int(target.health)
	var impact_ok: bool = impact_hp < before_hp and float(target.get_meta("chemical_dot_timer", 0.0)) > 0.0
	for i in range(30):
		main._update_unit_status_meta(target, 0.1)
	var dot_ok: bool = int(target.health) < impact_hp

	main._clear_all_units()
	var hot = _spawn_unit(main, 1, "hero", "Heat Probe", 1.0, 0.0, {
		"health": 100,
		"heat_capacity": 24.0,
		"cooling": 12.0,
		"thruster_momentum": 60.0,
		"boost_momentum": 120.0,
		"boost_duration": 0.24,
	})
	var boosted: bool = hot.boost(Vector2.RIGHT, MainScene.RING_LENGTH)
	var boost_motion_ok: bool = boosted and hot.velocity.length() > 0.01

	var coasting = _spawn_unit(main, 1, "hero", "Coast Probe", 1.0, 0.0, {
		"health": 100,
		"heat_capacity": 100.0,
		"cooling": 20.0,
	})
	coasting.heat = 60.0
	coasting.velocity = Vector2(1.2, 0.0)
	coasting.tick(0.5, MainScene.RING_LENGTH)
	var straight_cooling_ok: bool = float(coasting.heat) <= 45.0

	print("CHEMICAL_HEAT_PROBE queued=%s impact=%s dot=%s boost_motion=%s straight_cooling=%s hp=%d->%d->%d heat=%.2f" % [
		str(queued_ok),
		str(impact_ok),
		str(dot_ok),
		str(boost_motion_ok),
		str(straight_cooling_ok),
		before_hp,
		impact_hp,
		int(target.health),
		float(coasting.heat),
	])
	if not queued_ok:
		push_error("Chemical projectile did not queue as slow travel")
	if not impact_ok:
		push_error("Chemical projectile did not resolve impact or apply DoT")
	if not dot_ok:
		push_error("Chemical DoT did not tick damage")
	if not boost_motion_ok:
		push_error("Explicit boost momentum did not move the probe unit")
	if not straight_cooling_ok:
		push_error("Straight inertial movement did not cool like manual cooling")
	quit()
