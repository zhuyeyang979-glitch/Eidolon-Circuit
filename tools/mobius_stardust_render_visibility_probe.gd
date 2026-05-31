extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _color_distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)


func _average_patch_delta(with_band: Image, without_band: Image, points: PackedVector2Array) -> Dictionary:
	var width := mini(with_band.get_width(), without_band.get_width())
	var height := mini(with_band.get_height(), without_band.get_height())
	if width <= 0 or height <= 0:
		return {"average": 0.0, "maximum": 0.0, "samples": 0}
	var total := 0.0
	var maximum := 0.0
	var samples := 0
	var step := maxi(1, points.size() / 24)
	for i in range(0, points.size(), step):
		var point := points[i]
		var x := clampi(int(round(point.x)), 1, width - 2)
		var y := clampi(int(round(point.y)), 1, height - 2)
		for yy in range(y - 1, y + 2):
			for xx in range(x - 1, x + 2):
				var delta := _color_distance(with_band.get_pixel(xx, yy), without_band.get_pixel(xx, yy))
				total += delta
				maximum = maxf(maximum, delta)
				samples += 1
	return {
		"average": total / float(maxi(1, samples)),
		"maximum": maximum,
		"samples": samples,
	}


func _visible_image_delta(with_band: Image, without_band: Image) -> Dictionary:
	var width := mini(with_band.get_width(), without_band.get_width())
	var height := mini(with_band.get_height(), without_band.get_height())
	var changed := 0
	var total := 0.0
	var maximum := 0.0
	for y in range(0, height, 2):
		for x in range(0, width, 2):
			var delta := _color_distance(with_band.get_pixel(x, y), without_band.get_pixel(x, y))
			if delta > 0.002:
				changed += 1
				total += delta
				maximum = maxf(maximum, delta)
	return {
		"changed": changed,
		"average_changed": total / float(maxi(1, changed)),
		"maximum": maximum,
	}


func _hide_overlay_layers(main) -> void:
	for layer in [main.menu_layer, main.editor_layer, main.saved_units_layer, main.scout_layer, main.settings_layer, main.hud_layer, main.loading_layer]:
		if layer != null:
			layer.visible = false
			for child in layer.get_children():
				if child is CanvasItem:
					child.visible = false


func _capture_viewport_image(main) -> Image:
	_hide_overlay_layers(main)
	await process_frame
	_hide_overlay_layers(main)
	RenderingServer.force_draw()
	await process_frame
	_hide_overlay_layers(main)
	RenderingServer.force_draw()
	var image := root.get_viewport().get_texture().get_image()
	return image.duplicate()


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
	main._begin_battle(MainScene.MODE_TRAINING, true, "mobius_stardust_render_probe")
	if main.loading_controller != null:
		main.loading_controller.active = false
	_hide_overlay_layers(main)
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.mobius_rotation_state = {"twist_phase": 0.72, "angle": 0.0}
	main._refresh_mobius_surface_view()
	if main.mobius_stardust_band_view == null:
		_fail("MobiusStardustBandView is missing.")
		return
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var points := PackedVector2Array(snapshot.get("points", PackedVector2Array()))
	if points.size() < 24:
		_fail("Mobius stardust band needs enough render samples for pixel verification.")
		return
	main.mobius_stardust_band_view.visible = true
	main.mobius_stardust_band_view.queue_redraw()
	var with_band := await _capture_viewport_image(main)
	main.mobius_stardust_band_view.visible = false
	main.mobius_stardust_band_view.queue_redraw()
	var without_band := await _capture_viewport_image(main)
	var delta: Dictionary = _average_patch_delta(with_band, without_band, points)
	var image_delta: Dictionary = _visible_image_delta(with_band, without_band)
	var average := maxf(float(delta.get("average", 0.0)), float(image_delta.get("average_changed", 0.0)))
	var maximum := maxf(float(delta.get("maximum", 0.0)), float(image_delta.get("maximum", 0.0)))
	var changed := int(image_delta.get("changed", 0))
	var overlay_diag := "loading_layer_visible=%s loading_root_visible=%s game_state=%s loading_active=%s" % [
		str(main.loading_layer.visible if main.loading_layer != null else null),
		str(main.loading_layer.get_child(0).visible if main.loading_layer != null and main.loading_layer.get_child_count() > 0 and main.loading_layer.get_child(0) is CanvasItem else null),
		String(main.game_state),
		str(main.loading_controller.active if main.loading_controller != null else null),
	]
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	if changed < 4500 or average < 0.004 or maximum < 0.02:
		_fail("Rendered stardust band is not visibly different enough; changed=%d average=%.5f max=%.5f image=%dx%d draw_count=%d bounds=%s..%s %s." % [
			changed,
			average,
			maximum,
			with_band.get_width(),
			with_band.get_height(),
			int(main.mobius_stardust_band_view.get_meta("draw_count", 0)),
			str(min_point),
			str(max_point),
			overlay_diag,
		])
		return
	print("MOBIUS_STARDUST_RENDER_VISIBILITY_PROBE ok changed=%d average=%.5f max=%.5f samples=%d" % [
		changed,
		average,
		maximum,
		int(delta.get("samples", 0)),
	])
	quit()
