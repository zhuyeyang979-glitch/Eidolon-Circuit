extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main):
	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.12,
		"teamedit_runtime_topology": false,
	}
	var unit = main._create_unit(1, "hero", stats, "Probe", 0.0, 0.0)
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
	var toward_front := main._gun_activation_rotated_direction(unit, start, Vector2.RIGHT, rotate_speed, 0.25)
	if toward_front.dot(Vector2.RIGHT) <= start.dot(Vector2.RIGHT):
		_fail("Holding local 6 should rotate the gun direction toward the unit front.")
	var toward_rear := main._gun_activation_rotated_direction(unit, start, Vector2.LEFT, rotate_speed, 0.25)
	if toward_rear.dot(Vector2.LEFT) <= start.dot(Vector2.LEFT):
		_fail("Holding local 4 should rotate the gun direction toward the unit rear.")
	var unchanged := main._gun_activation_rotated_direction(unit, start, Vector2.UP, rotate_speed, 0.25)
	if unchanged.distance_to(start) > 0.001:
		_fail("Perpendicular command should not rotate the Gun Activate aim direction.")
	print("GUN_ACTIVATE_ROTATE_COMMAND_PROBE ok speed=%.2f" % rotate_speed)
	quit()
