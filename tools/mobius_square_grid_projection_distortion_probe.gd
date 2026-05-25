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
	config["enabled"] = true
	config["screen_scale"] = MainScene.ARENA_HEIGHT / MainScene.VIEW_HEIGHT
	config["local_rectangular_projection"] = false
	config["twist_visual_enabled"] = true
	config["twist_wave_amplitude"] = 0.0
	config["twist_pivot_influence"] = 0.0
	config["depth_strength"] = 0.58
	config["depth_contrast"] = 1.22
	config["near_scale"] = 1.24
	config["far_scale"] = 0.68
	return config


func _projection(coord: Vector2, camera: Vector2, config: Dictionary, state: Dictionary) -> Dictionary:
	return MobiusWorld.project_to_screen(coord, camera, config, state)


func _init() -> void:
	var config := _surface_config()
	var camera := Vector2.ZERO
	var state := {
		"twist_phase": 0.0,
		"twist_speed": 0.0,
		"twist_amplitude": 0.0,
		"pivot": Vector2.ZERO,
		"diagonal_phase": 0.0,
	}
	var ds := 2.6
	var dv := 2.0
	var top_right := _projection(Vector2(ds, dv), camera, config, state)
	var bottom_left := _projection(Vector2(-ds, -dv), camera, config, state)
	var top_left := _projection(Vector2(-ds, dv), camera, config, state)
	var bottom_right := _projection(Vector2(ds, -dv), camera, config, state)
	var near_mean := (float(top_right.get("scale", 1.0)) + float(bottom_left.get("scale", 1.0))) * 0.5
	var far_mean := (float(top_left.get("scale", 1.0)) + float(bottom_right.get("scale", 1.0))) * 0.5
	var near_pair_delta := absf(float(top_right.get("scale", 1.0)) - float(bottom_left.get("scale", 1.0)))
	var far_pair_delta := absf(float(top_left.get("scale", 1.0)) - float(bottom_right.get("scale", 1.0)))
	if near_pair_delta > 0.075 or far_pair_delta > 0.075:
		_fail("Same diagonal corners should share comparable projection scale; near_delta=%.4f far_delta=%.4f." % [near_pair_delta, far_pair_delta])
		return
	if near_mean <= far_mean + 0.12:
		_fail("One diagonal should read nearer/larger than the other; near=%.4f far=%.4f." % [near_mean, far_mean])
		return
	var tr_pos: Vector2 = top_right.get("position", Vector2.ZERO)
	var bl_pos: Vector2 = bottom_left.get("position", Vector2.ZERO)
	var tl_pos: Vector2 = top_left.get("position", Vector2.ZERO)
	var br_pos: Vector2 = bottom_right.get("position", Vector2.ZERO)
	var near_diagonal := tr_pos.distance_to(bl_pos)
	var far_diagonal := tl_pos.distance_to(br_pos)
	var right_height := tr_pos.distance_to(br_pos)
	var left_height := tl_pos.distance_to(bl_pos)
	if absf(near_diagonal - far_diagonal) < 60.0:
		_fail("Projected square grid should visibly compress one diagonal and enlarge the other; near_diag=%.2f far_diag=%.2f." % [near_diagonal, far_diagonal])
		return
	if absf(right_height - left_height) < 24.0:
		_fail("Projected square grid should shear under the Mobius surface projection; right=%.2f left=%.2f." % [right_height, left_height])
		return
	var rectangular_config := config.duplicate(true)
	rectangular_config["local_rectangular_projection"] = true
	var rect_top := _projection(Vector2(0.0, dv), camera, rectangular_config, state)
	var rect_bottom := _projection(Vector2(0.0, -dv), camera, rectangular_config, state)
	var rect_height := Vector2(rect_top.get("position", Vector2.ZERO)).distance_to(Vector2(rect_bottom.get("position", Vector2.ZERO)))
	if rect_height <= 0.0:
		_fail("Rectangular gameplay projection sanity check failed.")
		return
	print("MOBIUS_SQUARE_GRID_PROJECTION_DISTORTION_PROBE ok near=%.3f far=%.3f diagonals=%.1f/%.1f heights=%.1f/%.1f" % [near_mean, far_mean, near_diagonal, far_diagonal, right_height, left_height])
	quit()
