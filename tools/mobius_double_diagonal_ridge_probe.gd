extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _config() -> Dictionary:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["screen_scale"] = 720.0 / MainScene.VIEW_HEIGHT
	config["local_rectangular_projection"] = false
	config["twist_visual_enabled"] = true
	config["twist_wave_amplitude"] = 0.0
	config["twist_pivot_influence"] = 0.0
	config["ridge_period"] = 1.92
	config["ridge_width"] = 1.0
	config["depth_contrast"] = 1.0
	return config


func _coord_from_plane(plane: Vector2, config: Dictionary) -> Vector2:
	var screen_scale := float(config.get("screen_scale", 720.0 / MainScene.VIEW_HEIGHT))
	var half_width_units := 1280.0 / screen_scale * 0.5
	var half_height_units := MainScene.VIEW_HEIGHT * 0.5
	return Vector2(plane.x * half_width_units, plane.y * half_height_units)


func _frame_for_plane(plane: Vector2, config: Dictionary, state: Dictionary) -> Dictionary:
	return MobiusWorld.frame_at(_coord_from_plane(plane, config), Vector2.ZERO, config, state)


func _init() -> void:
	var config := _config()
	var state := {
		"twist_phase": 0.0,
		"ridge_phase": 0.0,
		"ridge_angle_phase": 0.0,
		"twist_amplitude": 0.0,
		"pivot_influence": 0.0,
	}
	var center := MobiusWorld.frame_at(Vector2.ZERO, Vector2.ZERO, config, state)
	var normal: Vector2 = center.get("ridge_normal", Vector2(0.707, 0.707))
	var tangent := Vector2(-normal.y, normal.x)
	var ridge_offset := float(config.get("ridge_period", 1.92)) * 0.5
	var ridge_a := -normal * ridge_offset
	var ridge_b := normal * ridge_offset
	var a_depth := float(_frame_for_plane(ridge_a, config, state).get("ridge_depth", 0.0))
	var b_depth := float(_frame_for_plane(ridge_b, config, state).get("ridge_depth", 0.0))
	var valley_depth := float(_frame_for_plane(Vector2.ZERO, config, state).get("ridge_depth", 1.0))
	if a_depth < 0.96 or b_depth < 0.96:
		_fail("Both diagonal ridge lines should be nearest/highest; depth=%.3f/%.3f." % [a_depth, b_depth])
		return
	if valley_depth > 0.08:
		_fail("The midpoint between the two ridges should be a far valley; depth=%.3f." % valley_depth)
		return
	var a0 := _frame_for_plane(ridge_a + tangent * 0.42, config, state)
	var a1 := _frame_for_plane(ridge_a - tangent * 0.42, config, state)
	var b0 := _frame_for_plane(ridge_b + tangent * 0.42, config, state)
	var b1 := _frame_for_plane(ridge_b - tangent * 0.42, config, state)
	for raw in [a0, a1, b0, b1]:
		var frame: Dictionary = raw
		if float(frame.get("ridge_distance01", 1.0)) > 0.025:
			_fail("Ridge samples should remain on parallel equal-height lines.")
			return
	var ridge_spacing := ridge_a.distance_to(ridge_b)
	if absf(ridge_spacing - float(config.get("ridge_period", 1.92))) > 0.03:
		_fail("Two ridge lines should be parallel and evenly separated; spacing=%.3f." % ridge_spacing)
		return
	print("MOBIUS_DOUBLE_DIAGONAL_RIDGE_PROBE ok depths=%.3f/%.3f valley=%.3f spacing=%.3f" % [a_depth, b_depth, valley_depth, ridge_spacing])
	quit()
