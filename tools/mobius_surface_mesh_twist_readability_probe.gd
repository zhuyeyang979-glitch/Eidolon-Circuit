extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


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


func _transparent_texture(size: Vector2i) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	return ImageTexture.create_from_image(image)


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


func _color_delta(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


func _image_delta(with_mesh: Image, without_mesh: Image) -> Dictionary:
	var width := mini(with_mesh.get_width(), without_mesh.get_width())
	var height := mini(with_mesh.get_height(), without_mesh.get_height())
	var changed := 0
	var total := 0.0
	var maximum := 0.0
	for y in range(0, height, 3):
		for x in range(0, width, 3):
			var delta := _color_delta(with_mesh.get_pixel(x, y), without_mesh.get_pixel(x, y))
			if delta > 0.0015:
				changed += 1
				total += delta
				maximum = maxf(maximum, delta)
	return {
		"changed": changed,
		"average_changed": total / float(maxi(1, changed)),
		"maximum": maximum,
	}


func _texture_delta_fallback() -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return {"changed": 0, "average_changed": 0.0, "maximum": 0.0}
	var changed := 0
	var total := 0.0
	var maximum := 0.0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var alpha := image.get_pixel(x, y).a
			maximum = maxf(maximum, alpha)
			if alpha > 0.008:
				changed += 1
				total += alpha
	return {
		"changed": changed,
		"average_changed": total / float(maxi(1, changed)),
		"maximum": maximum,
	}


func _surface_y_variance(main) -> Dictionary:
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	var config: Dictionary = main.mobius_strip_surface_view.config
	var camera: Vector2 = main._mobius_camera_coord()
	var points := PackedVector2Array()
	for lane in [-0.42, 0.42]:
		for i in range(65):
			var t := float(i) / 64.0
			var s := camera.x + lerpf(-MainScene.VIEW_WIDTH * 1.2, MainScene.VIEW_WIDTH * 1.2, t)
			var v := MainScene.BATTLE_HALF_HEIGHT * float(lane)
			var projection: Dictionary = MobiusWorld.project_to_screen(Vector2(s, v), camera, config, main.mobius_rotation_state)
			points.append(projection.get("position", Vector2.ZERO))
	var min_y := INF
	var max_y := -INF
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return {
		"y_range": max_y - min_y,
		"rectangular": bool(snapshot.get("local_rectangular_projection", true)),
	}


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
		_fail("Training battle loadouts should be available for mesh render verification.")
		return
	main._begin_battle(MainScene.MODE_TRAINING, true, "mobius_surface_mesh_twist_probe")
	if main.loading_controller != null:
		main.loading_controller.active = false
	main.camera_mobius_s = 4.2
	main.camera_center = 4.2
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.84, "angle": 0.0}
	main._refresh_mobius_surface_view()
	if main.mobius_stardust_band_view != null:
		main.mobius_stardust_band_view.visible = false
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius battlefield should use the world-grid surface, got %s." % String(surface_snapshot.get("surface_render_mode", "")))
		return
	if not bool(surface_snapshot.get("local_rectangular_projection", false)):
		_fail("Mobius world-grid surface should share the gameplay camera projection.")
		return
	if main.mobius_strip_surface_view.surface_texture != null:
		_fail("Mobius world-grid surface should not depend on the old screen-locked mesh texture.")
		return
	var variance: Dictionary = _surface_y_variance(main)
	var y_range := float(variance.get("y_range", 0.0))
	if y_range < 160.0:
		_fail("Mobius world-grid reference should span readable battlefield lanes; y_range=%.2f." % y_range)
		return
	var grid_cell_world := float(surface_snapshot.get("world_grid_cell_world", 0.0))
	if grid_cell_world <= 0.0:
		_fail("Mobius world-grid surface should expose a stable world cell size.")
		return
	print("MOBIUS_SURFACE_MESH_TWIST_READABILITY_PROBE ok mode=world_grid y_range=%.2f cell=%.3f" % [y_range, grid_cell_world])
	quit()
