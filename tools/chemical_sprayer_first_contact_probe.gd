extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, name: String, ring: float, lane: float):
	var stats := {
		"health": 140,
		"max_health": 140,
		"mass": 40.0,
		"radius": 0.18,
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
	var blocker = _spawn_unit(main, 2, "Blocker", 2.05, 0.0)
	var rear = _spawn_unit(main, 2, "Rear", 2.45, 0.0)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": blocker, "barrier": null, "puppet": [rear]},
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
		"chemical_projectile_ready": true,
		"projectile_momentum": 8.0,
		"projectile_damage_coeff": MainScene.PART_DAMAGE_COEFF_TERMINAL_MELEE * MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_DAMAGE_MULT,
		"chemical_frontload": MainScene.STANDARD_CHEMICAL_SPRAYER_INSTANT_DAMAGE_MULT / MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_DAMAGE_MULT,
		"chemical_dot_mult": 1.0,
		"chemical_dot_duration": MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_SECONDS,
		"chemical_dot_no_stack": true,
		"range": 1.6,
		"lane_range": MainScene.STANDARD_CHEMICAL_SPRAYER_WIDTH_M * 0.5,
		"direction": Vector2.RIGHT,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "gun", "shape": "sprayer_nozzle"},
		"ammo_consumed": true,
	}
	var blocker_hp := int(blocker.health)
	var rear_hp := int(rear.health)
	main._resolve_attack(attacker, event)
	if int(blocker.health) >= blocker_hp:
		_fail("Chemical sprayer should damage the first obstruction.")
	if int(rear.health) != rear_hp:
		_fail("Chemical sprayer should stop at the first obstruction and not hit the rear target.")
	print("CHEMICAL_SPRAYER_FIRST_CONTACT_PROBE ok blocker=%d->%d rear=%d->%d" % [blocker_hp, int(blocker.health), rear_hp, int(rear.health)])
	quit()
