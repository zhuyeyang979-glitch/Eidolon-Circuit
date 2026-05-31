extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "DriveRuntime", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var new_stats := {
		"health": 100,
		"mass": 12.0,
		"move_speed": 3.0,
		"move_acceleration": 30.0,
		"move_momentum": 36.0,
		"boost_momentum": 84.0,
		"boost_speed": 7.0,
		"boost_duration": 0.2,
		"thruster_boost_extra_demand": 12.0,
		"brake_power": 4.0,
		"boost_angle_degrees": 360.0,
	}
	var fighter = _fighter(new_stats)
	fighter.move_by(Vector2.RIGHT, 0.2, 100.0)
	fighter.tick(0.2, 100.0)
	if fighter.velocity.length() <= 0.01:
		_fail("Fighter did not move from new drive stats.")
	var before_boost: float = fighter.velocity.length()
	if not fighter.boost(Vector2.RIGHT, 100.0):
		_fail("Fighter could not boost from new drive stats.")
	fighter.tick(0.1, 100.0)
	if fighter.velocity.length() <= before_boost:
		_fail("Boost did not increase velocity from boost_momentum/boost_speed.")
	print("DRIVE_RUNTIME_MOVEMENT_PROBE ok speed=%.3f boost=%.3f" % [before_boost, fighter.velocity.length()])
	quit()
