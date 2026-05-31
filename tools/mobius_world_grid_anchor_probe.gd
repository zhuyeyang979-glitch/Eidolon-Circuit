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
	config["local_rectangular_projection"] = true
	config["surface_projection_mode"] = "world_grid"
	config["surface_world_grid_stable"] = true
	config["surface_ridge_warp_amplitude"] = 0.0
	config["surface_twist_shear_strength"] = 0.0
	config["surface_twist_warp_strength"] = 0.0
	return config


func _init() -> void:
	var config := _config()
	var camera_a := Vector2(2.0, -0.25)
	var camera_b := Vector2(2.70, -0.25)
	var coord := Vector2(4.0, 0.35)
	var state_a := {"twist_phase": 0.15, "ridge_phase": 0.10, "ridge_angle_phase": 0.08}
	var state_b := {"twist_phase": 1.45, "ridge_phase": 2.40, "ridge_angle_phase": 1.10}
	var projection_a := MobiusWorld.project_to_screen(coord, camera_a, config, state_a)
	var projection_b := MobiusWorld.project_to_screen(coord, camera_b, config, state_b)
	var pos_a: Vector2 = projection_a.get("position", Vector2.ZERO)
	var pos_b: Vector2 = projection_b.get("position", Vector2.ZERO)
	var expected_dx := -(camera_b.x - camera_a.x) * float(config.get("screen_scale", 1.0))
	var actual_dx := pos_b.x - pos_a.x
	if absf(actual_dx - expected_dx) > 0.5:
		_fail("World grid projection should move a fixed world point by camera delta; expected_dx=%.3f actual_dx=%.3f." % [expected_dx, actual_dx])
		return
	if absf(pos_b.y - pos_a.y) > 0.5:
		_fail("Same-lane camera move should not create screen-locked Y ripple; dy=%.3f." % (pos_b.y - pos_a.y))
		return
	var sample_a := MobiusWorld.surface_sample_coord_from_screen_uv(Vector2(0.5, 0.5), camera_a, config, state_a)
	var sample_b := MobiusWorld.surface_sample_coord_from_screen_uv(Vector2(0.5, 0.5), camera_b, config, state_b)
	var surface_a: Vector2 = sample_a.get("surface_coord", Vector2.ZERO)
	var surface_b: Vector2 = sample_b.get("surface_coord", Vector2.ZERO)
	if absf((surface_b.x - surface_a.x) - (camera_b.x - camera_a.x)) > 0.001:
		_fail("World-grid surface sample should be camera/world anchored, not screen phase anchored; a=%s b=%s." % [str(surface_a), str(surface_b)])
		return
	if absf(float(sample_a.get("u_shear", 1.0))) > 0.0001 or absf(float(sample_b.get("v_warp", 1.0))) > 0.0001:
		_fail("World-grid sampling should not use ridge shear/warp.")
		return
	print("MOBIUS_WORLD_GRID_ANCHOR_PROBE ok dx=%.3f sample_delta=%.3f" % [actual_dx, surface_b.x - surface_a.x])
	quit()
