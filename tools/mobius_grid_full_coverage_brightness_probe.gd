extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _load_grid_image() -> Image:
	var bytes := FileAccess.get_file_as_bytes(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		_fail("Could not load Mobius grid texture.")
		return null
	return image


func _mean_line_alpha(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), 32):
		for x in range(0, image.get_width(), 128):
			total += image.get_pixel(x, y).a
			count += 1
	return total / float(maxi(1, count))


func _sample_column(samples: Array, x: float, top: float, bottom: float) -> int:
	var hits := 0
	for raw_sample in samples:
		var sample: Dictionary = raw_sample
		var poly := PackedVector2Array(sample.get("poly", PackedVector2Array()))
		if poly.size() < 4:
			continue
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for point in poly:
			min_x = minf(min_x, point.x)
			max_x = maxf(max_x, point.x)
			min_y = minf(min_y, point.y)
			max_y = maxf(max_y, point.y)
		if x >= min_x and x <= max_x and max_y >= top and min_y <= bottom and float(sample.get("edge_softness", 0.0)) > 0.01:
			hits += 1
	return hits


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 2.5
	main.camera_center = 2.5
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {
		"twist_phase": 0.41,
		"ridge_phase": 0.2,
		"ridge_angle_phase": 0.16,
		"twist_amplitude": 0.22,
		"pivot_influence": 0.0,
	}
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible for coverage.")
		return
	var config: Dictionary = main.mobius_strip_surface_view.config
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius surface should use world-grid rendering, got %s." % String(snapshot.get("surface_render_mode", "")))
		return
	var draw_rect: Rect2 = snapshot.get("surface_draw_rect", Rect2())
	var arena_rect := Rect2(Vector2(MainScene.ARENA_LEFT, MainScene.ARENA_TOP), Vector2(MainScene.ARENA_WIDTH, MainScene.ARENA_HEIGHT))
	if not draw_rect.encloses(arena_rect):
		_fail("Full-rect surface must cover all arena edges including the top; rect=%s arena=%s." % [str(draw_rect), str(arena_rect)])
		return
	var top_left: Dictionary = MobiusWorld.surface_sample_coord_from_screen_uv(Vector2(0.0, 0.0), main._mobius_camera_coord(), config, main.mobius_rotation_state)
	var top_right: Dictionary = MobiusWorld.surface_sample_coord_from_screen_uv(Vector2(1.0, 0.0), main._mobius_camera_coord(), config, main.mobius_rotation_state)
	if not top_left.has("surface_coord") or not top_right.has("surface_coord"):
		_fail("Full-rect surface should provide inverse samples at the top edge.")
		return
	var image := _load_grid_image()
	if image == null:
		return
	var mean_alpha := _mean_line_alpha(image)
	if mean_alpha < 0.16:
		_fail("Mobius grid source line alpha should be bright enough to read; got %.4f." % mean_alpha)
		return
	if float(config.get("surface_grid_cell_px", 0.0)) < 56.0:
		_fail("Mobius quiet grid should use larger displayed cells; got %.1f." % float(config.get("surface_grid_cell_px", 0.0)))
		return
	if float(config.get("surface_alpha_gain", 0.0)) < 0.88 or float(config.get("surface_alpha_gain", 99.0)) > 0.96 or float(config.get("surface_alpha_max", 0.0)) < 0.15 or float(config.get("surface_alpha_max", 99.0)) > 0.17:
		_fail("Mobius world-grid material should be quiet but readable; gain=%.2f max=%.2f." % [float(config.get("surface_alpha_gain", 0.0)), float(config.get("surface_alpha_max", 0.0))])
		return
	if float(config.get("grid_far_brightness", 0.0)) < 0.50:
		_fail("Mobius grid valley/far brightness floor should not disappear; got %.2f." % float(config.get("grid_far_brightness", 0.0)))
		return
	if float(config.get("grid_near_brightness", 1.0)) >= float(config.get("unit_surface_far_brightness", 0.0)):
		_fail("Mobius grid should not outshine foreground units; grid_near=%.2f unit_far=%.2f." % [float(config.get("grid_near_brightness", 0.0)), float(config.get("unit_surface_far_brightness", 0.0))])
		return
	print("MOBIUS_GRID_FULL_COVERAGE_BRIGHTNESS_PROBE ok mode=world_grid rect=%s alpha=%.4f" % [str(draw_rect), mean_alpha])
	quit()
