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
	config["near_scale"] = 1.22
	config["far_scale"] = 0.70
	config["depth_contrast"] = 1.0
	return config


func _coord_from_plane(plane: Vector2, config: Dictionary) -> Vector2:
	var screen_scale := float(config.get("screen_scale", 720.0 / MainScene.VIEW_HEIGHT))
	return Vector2(plane.x * (1280.0 / screen_scale * 0.5), plane.y * (MainScene.VIEW_HEIGHT * 0.5))


func _frame(plane: Vector2, config: Dictionary, state: Dictionary) -> Dictionary:
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
	var center := _frame(Vector2.ZERO, config, state)
	var normal: Vector2 = center.get("ridge_normal", Vector2(0.707, 0.707))
	var ridge := -normal * (float(config.get("ridge_period", 1.92)) * 0.5)
	var near := _frame(ridge, config, state)
	var left := _frame(ridge - normal * 0.42, config, state)
	var right := _frame(ridge + normal * 0.42, config, state)
	var far := _frame(ridge + normal * 0.86, config, state)
	var left_depth := float(left.get("ridge_depth", 0.0))
	var right_depth := float(right.get("ridge_depth", 0.0))
	var left_scale := float(left.get("scale", 0.0))
	var right_scale := float(right.get("scale", 0.0))
	if absf(left_depth - right_depth) > 0.025:
		_fail("Ridge falloff should be symmetric in depth; left=%.4f right=%.4f." % [left_depth, right_depth])
		return
	if absf(left_scale - right_scale) > 0.025:
		_fail("Ridge falloff should be symmetric in scale; left=%.4f right=%.4f." % [left_scale, right_scale])
		return
	if float(near.get("ridge_depth", 0.0)) <= left_depth + 0.12:
		_fail("Ridge line should remain brighter/nearer than offset samples.")
		return
	if float(far.get("ridge_depth", 1.0)) >= left_depth - 0.12:
		_fail("Samples farther from a ridge should continue descending; near_offset=%.4f far=%.4f." % [left_depth, float(far.get("ridge_depth", 0.0))])
		return
	print("MOBIUS_RIDGE_SYMMETRIC_FALLOFF_PROBE ok ridge=%.3f offset=%.3f far=%.3f scale=%.3f/%.3f" % [
		float(near.get("ridge_depth", 0.0)),
		left_depth,
		float(far.get("ridge_depth", 0.0)),
		left_scale,
		right_scale,
	])
	quit()
