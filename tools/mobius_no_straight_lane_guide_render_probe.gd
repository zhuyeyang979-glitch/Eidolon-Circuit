extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _hide_overlay_layers(main) -> void:
	for layer in [main.menu_layer, main.editor_layer, main.saved_units_layer, main.scout_layer, main.settings_layer, main.hud_layer, main.loading_layer]:
		if layer != null:
			layer.visible = false
			for child in layer.get_children():
				if child is CanvasItem:
					child.visible = false


func _capture_viewport_image(main) -> Image:
	var display_name := String(DisplayServer.get_name()).to_lower()
	if display_name == "headless" or display_name.find("dummy") >= 0:
		return null
	_hide_overlay_layers(main)
	await process_frame
	_hide_overlay_layers(main)
	RenderingServer.force_draw()
	await process_frame
	_hide_overlay_layers(main)
	RenderingServer.force_draw()
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		return null
	var image := viewport_texture.get_image()
	if image == null:
		return null
	return image.duplicate()


func _horizontal_guide_run_ratio(image: Image, y: int) -> float:
	var width := image.get_width()
	if width <= 0:
		return 0.0
	var longest := 0
	var current := 0
	for x in range(width):
		var c := image.get_pixel(x, clampi(y, 0, image.get_height() - 1))
		var line_like := c.a > 0.55 and c.b > c.r + 0.05 and c.g > c.r + 0.02 and (c.r + c.g + c.b) > 0.34
		if line_like:
			current += 1
			longest = maxi(longest, current)
		else:
			current = 0
	return float(longest) / float(width)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main.mobius_enabled = true
	main.ai_battle_seat = 1
	if not main._prepare_training_battle_loadouts(true):
		_fail("Training battle loadouts should be available for render verification.")
		return
	main._begin_battle(MainScene.MODE_TRAINING, true, "mobius_no_lane_probe")
	if main.loading_controller != null:
		main.loading_controller.active = false
	_hide_overlay_layers(main)
	main.camera_mobius_s = 1.0
	main.camera_center = 1.0
	main.mobius_rotation_state = {"twist_phase": 0.58, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius surface should use world-grid rendering, got %s." % String(surface_snapshot.get("surface_render_mode", "")))
		return
	if not bool(surface_snapshot.get("lane_guides_enabled", false)):
		_fail("Mobius world-grid surface should expose lane and boundary reference lines.")
		return
	if bool(surface_snapshot.get("visible", false)):
		_fail("Mobius surface should not keep an internal stardust/guide cache.")
		return
	var image := await _capture_viewport_image(main)
	var center_ratio := 0.0
	var upper_ratio := 0.0
	var lower_ratio := 0.0
	var worst_ratio := 0.0
	if image != null:
		var center_y := int(round((MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5))
		center_ratio = _horizontal_guide_run_ratio(image, center_y)
		upper_ratio = _horizontal_guide_run_ratio(image, center_y - 128)
		lower_ratio = _horizontal_guide_run_ratio(image, center_y + 128)
		worst_ratio = maxf(center_ratio, maxf(upper_ratio, lower_ratio))
		if worst_ratio > 0.92:
			_fail("World-grid reference line should not become a full-screen solid stripe; run_ratio=%.3f." % worst_ratio)
			return
	print("MOBIUS_NO_STRAIGHT_LANE_GUIDE_RENDER_PROBE ok world_grid run_ratio=%.3f center=%.3f upper=%.3f lower=%.3f" % [
		worst_ratio,
		center_ratio,
		upper_ratio,
		lower_ratio,
	])
	quit()
