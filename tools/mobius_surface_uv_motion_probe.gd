extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_uv_for_camera(camera_coord: Vector2, config: Dictionary, state: Dictionary) -> Vector2:
	var samples := MobiusWorld.surface_sample_grid(camera_coord, config, state)
	if samples.is_empty():
		return Vector2.INF
	var sample: Dictionary = samples[0]
	var uvs: PackedVector2Array = sample.get("uvs", PackedVector2Array())
	if uvs.is_empty():
		return Vector2.INF
	return uvs[0]


func _init() -> void:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	)
	config["surface_segments"] = 24
	config["width_segments"] = 5
	var state := {"twist_phase": 0.2}
	var uv0 := _first_uv_for_camera(Vector2(0.0, 0.0), config, state)
	var uv1 := _first_uv_for_camera(Vector2(1.5, 0.0), config, state)
	if not uv0.is_finite() or not uv1.is_finite():
		_fail("Surface samples should include UV coordinates.")
		return
	var expected_delta := 1.5 / MainScene.RING_LENGTH
	var actual_delta := uv1.x - uv0.x
	if absf(actual_delta - expected_delta) > 0.01:
		_fail("Surface U should move with lifted mobius_s; expected %.3f got %.3f" % [expected_delta, actual_delta])
		return
	var uv_wrap := _first_uv_for_camera(Vector2(MainScene.RING_LENGTH + 0.5, 0.0), config, state)
	var wrap_samples := MobiusWorld.surface_sample_grid(Vector2(MainScene.RING_LENGTH + 0.5, 0.0), config, state)
	var found_lifted_u := false
	for raw_sample in wrap_samples:
		var sample: Dictionary = raw_sample
		var uvs: PackedVector2Array = sample.get("uvs", PackedVector2Array())
		for uv in uvs:
			if uv.x > 1.0:
				found_lifted_u = true
				break
		if found_lifted_u:
			break
	if not found_lifted_u:
		_fail("Surface U should stay continuous across one loop instead of pre-wrapping to 0..1.")
		return
	if uv0.y < -0.001 or uv0.y > 1.001:
		_fail("Surface V should be normalized within the strip width.")
		return
	print("MOBIUS_SURFACE_UV_MOTION_PROBE ok u0=%.3f u1=%.3f wrap=%.3f" % [uv0.x, uv1.x, uv_wrap.x])
	quit()
