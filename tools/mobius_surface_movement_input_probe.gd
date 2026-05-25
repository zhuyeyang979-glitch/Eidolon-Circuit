extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 40,
			"mass": 12.0,
			"teamedit_runtime_topology": false,
			"move_speed": 4.0,
			"body_move_speed": 4.0,
			"move_acceleration": 20.0,
			"thruster_acceleration": 20.0,
		},
	})
	unit.deploy(6.2, 1.4)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main.mobius_enabled = true
	main.camera_mobius_s = 5.8
	main.camera_lane_center = 0.3
	main.mobius_rotation_state = {"angle": 1.35, "pivot": Vector2(8.0, -2.0)}
	var unit = _make_unit()
	var screen_right := Vector2.RIGHT
	var raw := GameplayTransform.screen_input_to_gameplay_motion(screen_right)
	var surface := main._mobius_surface_input_for_unit(unit, screen_right)
	if surface.length() <= 0.01:
		_fail("Surface input should preserve movement magnitude.")
	if surface.distance_to(raw) <= 0.02:
		_fail("Movement input should be projected onto the local Mobius surface frame, got unchanged %s." % str(surface))
	main.mobius_rotation_state = {"angle": 1.43, "pivot": Vector2(8.1, -1.9)}
	var surface_next := main._mobius_surface_input_for_unit(unit, screen_right)
	if surface_next.distance_to(surface) > 0.001:
		_fail("Visual Mobius rotation should not rotate gameplay input; delta %.3f" % surface_next.distance_to(surface))
	unit.move_by(surface, 0.18, MainScene.RING_LENGTH)
	unit.tick(0.18, MainScene.RING_LENGTH)
	if absf(unit.mobius_s - unit.ring_pos) < 0.001 and unit.mobius_s > MainScene.RING_LENGTH:
		_fail("Authoritative movement must stay on lifted Mobius coordinates, with ring_pos only as compatibility.")
	print("MOBIUS_SURFACE_MOVEMENT_INPUT_PROBE ok surface=%s next_delta=%.3f" % [str(surface), surface_next.distance_to(surface)])
	quit()
