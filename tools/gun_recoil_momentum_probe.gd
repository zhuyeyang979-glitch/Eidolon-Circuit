extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "RECOIL",
		"stats": {
			"mass": 10.0,
			"health": 100,
			"max_health": 100,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
		},
	})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var fighter = _make_fighter()
	fighter.apply_projectile_recoil(Vector2.RIGHT, 50.0)
	if fighter.velocity.distance_to(Vector2(-5.0, 0.0)) > 0.001:
		_fail("Projectile recoil should apply -projectile_momentum / mass to the whole unit, got %s" % [fighter.velocity])
	if fighter.body_sway_velocity.length() > 0.001 or absf(fighter.body_swing_velocity) > 0.001:
		_fail("Projectile recoil should not inject visual sway/swing.")
	print("GUN_RECOIL_MOMENTUM_PROBE ok velocity=%s" % [fighter.velocity])
	quit()
