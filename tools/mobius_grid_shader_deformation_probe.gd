extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["screen_scale"] = 720.0 / MainScene.VIEW_HEIGHT
	config["depth_contrast"] = 1.12
	config["surface_ridge_warp_amplitude"] = 0.125
	config["surface_twist_shear_strength"] = 0.075
	config["surface_twist_warp_strength"] = 0.032
	var camera := Vector2(2.0, 0.0)
	var state := {"twist_phase": 0.72, "ridge_phase": 0.34, "ridge_angle_phase": 0.12, "pivot_influence": 0.0}
	var near_uv := Vector2.ZERO
	var far_uv := Vector2.ZERO
	var near_depth := -1.0
	var far_depth := 2.0
	var max_warp := 0.0
	for y in range(2, 19):
		for x in range(2, 19):
			var uv := Vector2(float(x) / 20.0, float(y) / 20.0)
			var sample := MobiusWorld.surface_sample_coord_from_screen_uv(uv, camera, config, state)
			var depth := float(sample.get("depth01", 0.5))
			if depth > near_depth:
				near_depth = depth
				near_uv = uv
			if depth < far_depth:
				far_depth = depth
				far_uv = uv
			max_warp = maxf(max_warp, absf(float(sample.get("u_shear", 0.0))) + absf(float(sample.get("v_warp", 0.0))))
	var params := MobiusWorld.surface_shader_parameters(camera, config, state)
	var normal: Vector2 = Vector2(params.get("ridge_normal", Vector2(0.707, 0.707))).normalized()
	var epsilon := 0.008
	var near_a: Vector2 = MobiusWorld.surface_sample_coord_from_screen_uv(near_uv - normal * epsilon, camera, config, state).get("grid_coord", Vector2.ZERO)
	var near_b: Vector2 = MobiusWorld.surface_sample_coord_from_screen_uv(near_uv + normal * epsilon, camera, config, state).get("grid_coord", Vector2.ZERO)
	var far_a: Vector2 = MobiusWorld.surface_sample_coord_from_screen_uv(far_uv - normal * epsilon, camera, config, state).get("grid_coord", Vector2.ZERO)
	var far_b: Vector2 = MobiusWorld.surface_sample_coord_from_screen_uv(far_uv + normal * epsilon, camera, config, state).get("grid_coord", Vector2.ZERO)
	var near_frequency := near_a.distance_to(near_b)
	var far_frequency := far_a.distance_to(far_b)
	if near_depth <= far_depth + 0.25 or near_frequency >= far_frequency:
		_fail("Ridge should sample fewer source grid cells than a valley, so apparent cells grow near the viewer; depth=%.3f/%.3f frequency=%.3f/%.3f." % [near_depth, far_depth, near_frequency, far_frequency])
		return
	if max_warp <= 0.0005:
		_fail("Surface sampling should include twist-driven shear/warp so the displayed grid is not axis-aligned rectangles.")
		return
	print("MOBIUS_GRID_SHADER_DEFORMATION_PROBE ok depth=%.3f/%.3f frequency=%.3f/%.3f warp=%.4f" % [near_depth, far_depth, near_frequency, far_frequency, max_warp])
	quit()
