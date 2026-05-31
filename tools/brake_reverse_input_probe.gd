extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter(boost_momentum: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var drive_demand := 40.0
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BRAKE_PROBE",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
			"mass": 10.0,
			"thruster_drive_demand": drive_demand,
			"thruster_effective_drive_demand": drive_demand,
			"thruster_boost_extra_demand": boost_momentum,
			"thruster_boost_peak_demand": drive_demand + boost_momentum,
			"thruster_effective_boost_peak_demand": drive_demand + boost_momentum,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": drive_demand,
			"body_move_speed": 4.0,
			"move_speed": 4.0,
			"thruster_acceleration": 4.0,
			"thruster_momentum": 40.0,
			"boost_momentum": boost_momentum,
			"boost_total_momentum": drive_demand + boost_momentum,
			"boost_speed": (drive_demand + boost_momentum) / 10.0,
			"boost_duration": 0.5,
			"brake_power": (drive_demand + boost_momentum) / 10.0,
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
		_fail("Reverse input did not reduce current forward velocity.")
		return
	var strong = _make_fighter(600.0)
	strong.move_by(Vector2.LEFT, 0.1, 24.0)
	if strong.velocity.length() > 0.001:
		_fail("Strong reverse brake should stop before reverse movement, got %.3f." % strong.velocity.length())
		return
	if not bool(strong.brake_reverse_requires_repress):
		_fail("Brake-to-stop should require release/repress before reverse drive.")
		return
	strong.move_by(Vector2.LEFT, 0.1, 24.0)
	if strong.velocity.x < -0.001:
		_fail("Holding reverse through brake stop should not immediately enter reverse drive.")
		return
	strong.note_movement_input_released()
	strong.move_by(Vector2.LEFT, 0.1, 24.0)
	if strong.velocity.x >= -0.001:
		_fail("Release and re-press should allow ordinary reverse movement.")
		return
	var no_boost = _make_fighter(0.0)
	var before: Vector2 = no_boost.velocity
	no_boost.move_by(Vector2.LEFT, 0.1, 24.0)
	if no_boost.velocity.x >= before.x:
		_fail("Ordinary brake/reverse movement should use drive/brake chain even with no boost momentum.")
		return
	print("BRAKE_REVERSE_INPUT_PROBE reduced=%.3f strong=%.3f" % [fighter.velocity.length(), strong.velocity.length()])
	quit()
