extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _unit(profile: String, angle: float = 360.0):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "MovementProfileProbe",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"body_move_speed": 4.0,
			"thruster_acceleration": 4.0,
			"boost_momentum": 48.0,
			"boost_speed": 4.0,
			"boost_duration": 0.3,
			"boost_cooldown": 0.5,
			"movement_profile": profile,
			"boost_angle_degrees": angle,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	return unit


func _init() -> void:
	var omni = _unit("omni")
	omni.move_by(Vector2.UP, 0.2, 32.0)
	omni.tick(0.2, 32.0)
	if absf(omni.lane) <= 0.001:
		_fail("Omni thruster should allow side/up movement.")
	var car = _unit("car")
	car.move_by(Vector2.UP, 0.2, 32.0)
	car.tick(0.2, 32.0)
	if absf(car.lane) > 0.001:
		_fail("Car thruster should not side-drive.")
	car.move_by(Vector2.RIGHT, 0.2, 32.0)
	car.tick(0.2, 32.0)
	if car.ring_pos <= 0.001:
		_fail("Car thruster should drive forward.")
	var vector = _unit("vector", 90.0)
	vector.move_by(Vector2.UP, 0.2, 32.0)
	vector.tick(0.2, 32.0)
	if vector.lane > 0.01:
		_fail("Vector profile should not accept pure side movement outside cone.")
	vector.move_by(Vector2.RIGHT, 0.2, 32.0)
	vector.tick(0.2, 32.0)
	if vector.ring_pos <= 0.001:
		_fail("Vector profile should accept forward movement.")
	print("MOVEMENT_PROFILE_PROBE ok")
	quit()
