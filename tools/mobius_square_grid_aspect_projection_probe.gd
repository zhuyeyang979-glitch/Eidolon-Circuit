extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_config() -> Dictionary:
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
	config["ridge_period"] = 1.92
	return config


func _screen(coord: Vector2, config: Dictionary, state: Dictionary) -> Vector2:
	return Vector2(MobiusWorld.project_to_screen(coord, Vector2.ZERO, config, state).get("position", Vector2.ZERO))


func _init() -> void:
	var flat_config := _base_config()
	flat_config["near_scale"] = 1.0
	flat_config["far_scale"] = 1.0
	flat_config["depth_strength"] = 0.0
	flat_config["surface_perspective_strength"] = 0.0
	flat_config["surface_twist_shear_strength"] = 0.0
	flat_config["surface_ridge_lift_strength"] = 0.0
	flat_config["twist_wave_amplitude"] = 0.0
	var state := {
		"twist_phase": 0.0,
		"ridge_phase": 0.0,
		"ridge_angle_phase": 0.0,
		"twist_amplitude": 0.0,
		"pivot_influence": 0.0,
	}
	var origin := _screen(Vector2.ZERO, flat_config, state)
	var x_step := _screen(Vector2(1.0, 0.0), flat_config, state).distance_to(origin)
	var y_step := _screen(Vector2(0.0, 1.0), flat_config, state).distance_to(origin)
	if absf(x_step - y_step) > 0.01:
		_fail("Flat visual surface projection should preserve square grid aspect; x=%.3f y=%.3f." % [x_step, y_step])
		return
	var twist_config := _base_config()
	twist_config["twist_wave_amplitude"] = 0.24
	twist_config["depth_strength"] = 0.42
	twist_config["surface_perspective_strength"] = 0.36
	twist_config["surface_twist_shear_strength"] = 0.16
	twist_config["surface_ridge_lift_strength"] = 0.20
	var twist_state := {
		"twist_phase": 0.42,
		"ridge_phase": 0.27,
		"ridge_angle_phase": 0.18,
		"twist_amplitude": 0.24,
		"pivot_influence": 0.0,
	}
	var center := _screen(Vector2.ZERO, twist_config, twist_state)
	var dx := _screen(Vector2(0.65, 0.0), twist_config, twist_state).distance_to(center)
	var dy := _screen(Vector2(0.0, 0.65), twist_config, twist_state).distance_to(center)
	var ratio := dy / maxf(0.001, dx)
	if ratio > 1.32:
		_fail("Twisted projection should not globally stretch grid Y over X; ratio=%.3f x=%.3f y=%.3f." % [ratio, dx, dy])
		return
	print("MOBIUS_SQUARE_GRID_ASPECT_PROJECTION_PROBE ok flat=%.3f/%.3f twist_ratio=%.3f" % [x_step, y_step, ratio])
	quit()
