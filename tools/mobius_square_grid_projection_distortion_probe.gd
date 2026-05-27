extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _surface_config() -> Dictionary:
	var config := MobiusWorld.default_config(
		MainScene.RING_LENGTH,
		MainScene.BATTLE_HALF_HEIGHT * 2.0,
		MainScene.VIEW_WIDTH,
		MainScene.VIEW_HEIGHT,
		Rect2(Vector2(MainScene.ARENA_LEFT, MainScene.ARENA_TOP), Vector2(MainScene.ARENA_WIDTH, MainScene.ARENA_HEIGHT))
	)
	config["screen_scale"] = MainScene.ARENA_HEIGHT / MainScene.VIEW_HEIGHT
	config["local_rectangular_projection"] = false
	config["twist_visual_enabled"] = true
	config["twist_wave_amplitude"] = 0.18
	config["twist_pivot_influence"] = 0.0
	config["depth_strength"] = 0.52
	config["depth_contrast"] = 1.18
	config["ridge_period"] = 1.92
	config["surface_perspective_strength"] = 0.36
	return config


func _coord_from_plane(plane: Vector2, config: Dictionary) -> Vector2:
	var screen_scale := float(config.get("screen_scale", MainScene.ARENA_HEIGHT / MainScene.VIEW_HEIGHT))
	return Vector2(plane.x * (MainScene.ARENA_WIDTH / screen_scale * 0.5), plane.y * (MainScene.VIEW_HEIGHT * 0.5))


func _frame_for_plane(plane: Vector2, config: Dictionary, state: Dictionary) -> Dictionary:
	return MobiusWorld.frame_at(_coord_from_plane(plane, config), Vector2.ZERO, config, state)


func _project_for_plane(plane: Vector2, config: Dictionary, state: Dictionary) -> Dictionary:
	return MobiusWorld.project_to_screen(_coord_from_plane(plane, config), Vector2.ZERO, config, state)


func _init() -> void:
	var config := _surface_config()
	var state := {
		"twist_phase": 0.36,
		"ridge_phase": 0.0,
		"ridge_angle_phase": 0.0,
		"twist_amplitude": 0.18,
		"pivot_influence": 0.0,
	}
	var center := _frame_for_plane(Vector2.ZERO, config, state)
	var normal: Vector2 = center.get("ridge_normal", Vector2(0.707, 0.707))
	var ridge_offset := float(config.get("ridge_period", 1.92)) * 0.5
	var ridge_a := _project_for_plane(-normal * ridge_offset, config, state)
	var ridge_b := _project_for_plane(normal * ridge_offset, config, state)
	var valley := _project_for_plane(Vector2.ZERO, config, state)
	var ridge_scale := (float(ridge_a.get("scale", 0.0)) + float(ridge_b.get("scale", 0.0))) * 0.5
	var valley_scale := float(valley.get("scale", 1.0))
	if ridge_scale <= valley_scale + 0.18:
		_fail("Parallel ridge lines should project larger/brighter than their midpoint valley; ridge=%.3f valley=%.3f." % [ridge_scale, valley_scale])
		return
	var tangent := Vector2(-normal.y, normal.x)
	var line_a0 := _project_for_plane(-normal * ridge_offset + tangent * 0.55, config, state)
	var line_a1 := _project_for_plane(-normal * ridge_offset - tangent * 0.55, config, state)
	var line_b0 := _project_for_plane(normal * ridge_offset + tangent * 0.55, config, state)
	var line_b1 := _project_for_plane(normal * ridge_offset - tangent * 0.55, config, state)
	var slope_a := (Vector2(line_a1.get("position", Vector2.ZERO)) - Vector2(line_a0.get("position", Vector2.ZERO))).normalized()
	var slope_b := (Vector2(line_b1.get("position", Vector2.ZERO)) - Vector2(line_b0.get("position", Vector2.ZERO))).normalized()
	if absf(slope_a.cross(slope_b)) > 0.08:
		_fail("The two high lines should stay parallel after projection; cross=%.4f." % absf(slope_a.cross(slope_b)))
		return
	var valley_pos: Vector2 = valley.get("position", Vector2.ZERO)
	var ridge_mid := (Vector2(ridge_a.get("position", Vector2.ZERO)) + Vector2(ridge_b.get("position", Vector2.ZERO))) * 0.5
	if valley_pos.distance_to(ridge_mid) > 140.0:
		_fail("The valley should sit between the two projected ridge lines; offset=%.2f." % valley_pos.distance_to(ridge_mid))
		return
	print("MOBIUS_SQUARE_GRID_PROJECTION_DISTORTION_PROBE ok ridge=%.3f valley=%.3f parallel_cross=%.4f" % [ridge_scale, valley_scale, absf(slope_a.cross(slope_b))])
	quit()
