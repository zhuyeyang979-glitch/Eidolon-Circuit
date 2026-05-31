extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BRAKE",
		"stats": {
			"mass": 10.0,
			"health": 100,
			"max_health": 100,
			"brake_power": 40.0,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.apply_projectile_recoil(Vector2.RIGHT, 40.0)
	var start_speed: float = fighter.velocity.length()
	for i in range(10):
		fighter.tick(0.1, MainScene.RING_LENGTH)
	if fighter.velocity.length() >= start_speed:
		_fail("Normal brake chain should reduce projectile recoil speed, got start %.3f end %.3f" % [start_speed, fighter.velocity.length()])
	if fighter.body_sway_velocity.length() > 0.001 or absf(fighter.body_swing_velocity) > 0.001:
		_fail("Projectile recoil braking should not use visual shake/swing.")
	print("GUN_RECOIL_BRAKE_PROBE ok start=%.3f end=%.3f" % [start_speed, fighter.velocity.length()])
	quit()
