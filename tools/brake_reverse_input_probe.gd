extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter(boost_momentum: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BRAKE_PROBE",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
			"mass": 10.0,
			"body_move_speed": 4.0,
			"thruster_acceleration": 4.0,
			"thruster_momentum": 40.0,
			"boost_momentum": boost_momentum,
			"boost_duration": 0.5,
			"turn_speed": 2.0,
			"thruster_cone_degrees": 180.0,
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.facing_angle = 0.0
	fighter.velocity = Vector2.RIGHT * 3.0
	return fighter


func _init() -> void:
	var fighter = _make_fighter(80.0)
	fighter.move_by(Vector2.LEFT, 0.1, 24.0)
	if fighter.velocity.x >= 3.0:
		_fail("Reverse input did not brake current velocity.")
		return
	if fighter.velocity.x < -0.001:
		_fail("Brake reversed the unit instead of clamping at zero.")
		return
	var strong = _make_fighter(600.0)
	strong.move_by(Vector2.LEFT, 0.5, 24.0)
	if strong.velocity.length() > 0.001:
		_fail("Strong boost brake should clamp speed to zero.")
		return
	var no_boost = _make_fighter(0.0)
	var before: Vector2 = no_boost.velocity
	no_boost.move_by(Vector2.LEFT, 0.1, 24.0)
	if no_boost.velocity.distance_to(before) > 0.001:
		_fail("No boost momentum should not apply strong reverse brake.")
		return
	print("BRAKE_REVERSE_INPUT_PROBE reduced=%.3f strong=%.3f" % [fighter.velocity.length(), strong.velocity.length()])
	quit()
