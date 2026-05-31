extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, facing_sign: int):
	var unit = main._create_unit(1, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"teamedit_runtime_topology": false,
	}, "Gun Turn Sign Probe", 0.0, 0.0)
	main._assign_unit_role(unit, "hero")
	if unit.has_method("set_facing_immediate"):
		unit.set_facing_immediate(facing_sign)
	else:
		unit.facing = facing_sign
	return unit


func _assert_turn(main, unit, start: Vector2, input_dir: Vector2, expected_sign: int, label: String) -> void:
	var result: Vector2 = main._gun_activation_rotated_direction(unit, start, input_dir, 2.0, 0.1)
	var delta := wrapf(result.angle() - start.angle(), -PI, PI)
	if expected_sign < 0 and delta >= -0.0001:
		_fail("%s should rotate left/counter sign, got delta %.4f" % [label, delta])
	if expected_sign > 0 and delta <= 0.0001:
		_fail("%s should rotate right/positive sign, got delta %.4f" % [label, delta])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	for facing_sign in [1, -1]:
		var unit = _spawn_unit(main, facing_sign)
		var start := main._unit_forward_vector(unit)
		_assert_turn(main, unit, start, Vector2.LEFT, -1, "4X facing %d" % facing_sign)
		_assert_turn(main, unit, start, Vector2.RIGHT, 1, "6X facing %d" % facing_sign)
	print("GUN_ACTIVATION_LOCAL_4_6_DIRECTION_PROBE ok")
	quit()
