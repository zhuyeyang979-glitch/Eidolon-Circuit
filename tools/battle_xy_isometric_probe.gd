extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.camera_center = 6.0
	main.camera_lane_center = 0.0
	var origin: Vector2 = main._screen_from_ring(6.0, 0.0)["position"]
	var x_step: Vector2 = main._screen_from_ring(7.0, 0.0)["position"]
	var y_step: Vector2 = main._screen_from_ring(6.0, 1.0)["position"]
	var dx := origin.distance_to(x_step)
	var dy := origin.distance_to(y_step)
	if main.mobius_enabled:
		if dx <= 0.01 or dy <= 0.01:
			_fail("Mobius gameplay projection should keep positive screen movement for both axes.")
		var scale := main._battle_world_to_screen_scale()
		if absf(dx - dy) > 0.001 or absf(dx - scale) > 0.001:
			_fail("Mobius gameplay projection should stay locally rectangular: helper=%.4f dx=%.4f dy=%.4f." % [scale, dx, dy])
		var visual_config := main._mobius_config().duplicate(true)
		visual_config["local_rectangular_projection"] = false
		var near_projection := MobiusWorld.project_to_screen(Vector2.ZERO, Vector2.ZERO, visual_config, main.mobius_rotation_state)
		var far_projection := MobiusWorld.project_to_screen(Vector2(MainScene.RING_LENGTH * 0.5, 0.0), Vector2.ZERO, visual_config, main.mobius_rotation_state)
		if absf(float(near_projection.get("scale", 0.0)) - float(far_projection.get("scale", 0.0))) <= 0.01:
			_fail("Mobius visual projection should still expose depth scale variation.")
		print("BATTLE_XY_ISOMETRIC_PROBE mobius gameplay_dx=%.4f gameplay_dy=%.4f visual_scale=%.3f/%.3f" % [dx, dy, float(near_projection.get("scale", 0.0)), float(far_projection.get("scale", 0.0))])
		quit()
		return
	if absf(dx - dy) > 0.001:
		_fail("Battle screen scale is not isometric: dx=%.4f dy=%.4f." % [dx, dy])
	var scale := main._battle_world_to_screen_scale()
	if absf(dx - scale) > 0.001 or absf(dy - scale) > 0.001:
		_fail("Battle scale helper mismatch: helper=%.4f dx=%.4f dy=%.4f." % [scale, dx, dy])
	print("BATTLE_XY_ISOMETRIC_PROBE scale=%.4f" % scale)
	quit()
