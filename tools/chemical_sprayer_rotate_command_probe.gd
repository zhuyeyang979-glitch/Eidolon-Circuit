extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main):
	var unit = main._create_unit(1, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"teamedit_runtime_topology": false,
	}, "Sprayer Aim Probe", 0.0, 0.0)
	main._assign_unit_role(unit, "hero")
	unit.facing = 1
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var unit = _spawn_unit(main)
	var rotate_speed := main._unit2_turn_speed_reference()
	var start := Vector2.UP
	var right_turn := main._gun_activation_rotated_direction(unit, start, Vector2.RIGHT, rotate_speed, 0.25)
	if wrapf(right_turn.angle() - start.angle(), -PI, PI) <= 0.0:
		_fail("Chemical sprayer 6 should rotate with a stable right turn sign.")
	var left_turn := main._gun_activation_rotated_direction(unit, start, Vector2.LEFT, rotate_speed, 0.25)
	if wrapf(left_turn.angle() - start.angle(), -PI, PI) >= 0.0:
		_fail("Chemical sprayer 4 should rotate with a stable left turn sign.")
	print("CHEMICAL_SPRAYER_ROTATE_COMMAND_PROBE ok speed=%.2f" % rotate_speed)
	quit()
