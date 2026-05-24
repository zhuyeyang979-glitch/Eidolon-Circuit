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
	config["surface_segments"] = 32
	config["width_segments"] = 7
	config["depth_contrast"] = 1.18
	var camera_coord := Vector2.ZERO
	var state := {"angle": 0.35, "pivot": Vector2(4.0, -1.0)}
	var near_projection := MobiusWorld.project_to_screen(Vector2.ZERO, camera_coord, config, state)
	var far_projection := MobiusWorld.project_to_screen(Vector2(MainScene.RING_LENGTH * 0.5, 0.0), camera_coord, config, state)
	if float(near_projection.get("scale", 0.0)) <= float(far_projection.get("scale", 0.0)):
		_fail("Near regions should scale larger than far-facing regions.")
	if int(near_projection.get("z_index", 0)) <= int(far_projection.get("z_index", 0)):
		_fail("Near regions should sort above far-facing regions.")
	var samples := MobiusWorld.surface_sample_grid(camera_coord, config, state)
	if samples.size() < 32:
		_fail("Surface grid should produce sampled ribbon cells for depth sorting.")
	var min_depth := 2.0
	var max_depth := -1.0
	var min_z := 999999
	var max_z := -999999
	var min_soft := 2.0
	var max_soft := -1.0
	for raw_sample in samples:
		var sample: Dictionary = raw_sample
		var depth := float(sample.get("avg_depth", 0.5))
		min_depth = minf(min_depth, depth)
		max_depth = maxf(max_depth, depth)
		min_z = mini(min_z, int(sample.get("z_index", 0)))
		max_z = maxi(max_z, int(sample.get("z_index", 0)))
		var softness := float(sample.get("edge_softness", 1.0))
		min_soft = minf(min_soft, softness)
		max_soft = maxf(max_soft, softness)
	if max_depth - min_depth < 0.15:
		_fail("Surface samples should have varied simulated depth.")
	if max_z <= min_z:
		_fail("Surface samples should have varied z-index ordering.")
	if max_soft - min_soft < 0.25:
		_fail("Surface samples should include soft edge falloff variation.")
	print("MOBIUS_DEPTH_RENDERING_PROBE ok depth %.3f..%.3f z %d..%d" % [min_depth, max_depth, min_z, max_z])
	quit()
