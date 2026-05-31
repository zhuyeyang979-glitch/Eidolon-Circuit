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


func _patch_delta(with_mesh: Image, without_mesh: Image, center: Vector2, radius: int) -> Dictionary:
	var width := mini(with_mesh.get_width(), without_mesh.get_width())
	var height := mini(with_mesh.get_height(), without_mesh.get_height())
	var total := 0.0
	var maximum := 0.0
	var samples := 0
	var cx := int(round(center.x))
	var cy := int(round(center.y))
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue
			var delta := _color_delta(with_mesh.get_pixel(x, y), without_mesh.get_pixel(x, y))
			total += delta
			maximum = maxf(maximum, delta)
			samples += 1
	return {
		"average": total / float(maxi(1, samples)),
		"maximum": maximum,
		"samples": samples,
	}


func _global_delta(with_mesh: Image, without_mesh: Image) -> Dictionary:
	var width := mini(with_mesh.get_width(), without_mesh.get_width())
	var height := mini(with_mesh.get_height(), without_mesh.get_height())
	var changed := 0
	var total := 0.0
	for y in range(0, height, 4):
		for x in range(0, width, 4):
			var delta := _color_delta(with_mesh.get_pixel(x, y), without_mesh.get_pixel(x, y))
			if delta > 0.0015:
				changed += 1
				total += delta
	return {"changed": changed, "average_changed": total / float(maxi(1, changed))}


func _texture_max_alpha() -> float:
	var bytes := FileAccess.get_file_as_bytes(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return 1.0
	var maximum := 0.0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			maximum = maxf(maximum, image.get_pixel(x, y).a)
	return maximum


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
		_fail("Training battle loadouts should be available for unit occlusion verification.")
		return
	main._begin_battle(MainScene.MODE_TRAINING, true, "mobius_surface_mesh_occlusion_probe")
	if main.loading_controller != null:
		main.loading_controller.active = false
	main.camera_mobius_s = 0.5
	main.camera_center = 0.5
	main.mobius_rotation_state = {"twist_phase": 0.38, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var training_player := 1
	var hero = null
	if main.active_units.has(training_player) and Dictionary(main.active_units[training_player]).has("hero"):
		hero = Dictionary(main.active_units[training_player]).get("hero")
	if hero == null or not is_instance_valid(hero):
		_fail("Training hero is missing for mesh occlusion verification.")
		return
	if main.mobius_stardust_band_view != null:
		main.mobius_stardust_band_view.visible = false
	var with_mesh := await _capture_viewport_image(main)
	var hero_position: Vector2 = hero.position
	var texture_size: Vector2 = main.mobius_surface_texture.get_size()
	main.mobius_strip_surface_view.set_surface_texture(_transparent_texture(Vector2i(int(texture_size.x), int(texture_size.y))))
	main.mobius_strip_surface_view.queue_redraw()
	var without_mesh := await _capture_viewport_image(main)
	if with_mesh == null or without_mesh == null:
		var surface_z: int = int(main.mobius_strip_surface_view.z_index)
		var hero_z: int = int(hero.z_index) if hero is CanvasItem else 0
		var max_alpha: float = _texture_max_alpha()
		if surface_z >= hero_z:
			_fail("Mobius mesh surface should draw behind units in headless fallback; surface_z=%d hero_z=%d." % [surface_z, hero_z])
			return
		if max_alpha > 0.24:
			_fail("Mobius mesh texture alpha is too strong for headless occlusion fallback; max_alpha=%.4f." % max_alpha)
			return
		print("MOBIUS_SURFACE_MESH_NOT_OCCLUDING_UNITS_PROBE ok headless_fallback surface_z=%d hero_z=%d max_alpha=%.4f" % [surface_z, hero_z, max_alpha])
		quit()
		return
	var local: Dictionary = _patch_delta(with_mesh, without_mesh, hero_position, 20)
	var global: Dictionary = _global_delta(with_mesh, without_mesh)
	var local_average := float(local.get("average", 0.0))
	var local_maximum := float(local.get("maximum", 0.0))
	var changed := int(global.get("changed", 0))
	if changed < 1500:
		_fail("Mobius mesh should still be globally visible while checking unit occlusion; changed=%d." % changed)
		return
	if local_average > 0.060 or local_maximum > 0.36:
		_fail("Mobius mesh should not visually overpower the controlled unit; local_avg=%.5f local_max=%.5f hero=%s changed=%d." % [local_average, local_maximum, str(hero_position), changed])
		return
	print("MOBIUS_SURFACE_MESH_NOT_OCCLUDING_UNITS_PROBE ok changed=%d local_avg=%.5f local_max=%.5f" % [changed, local_average, local_maximum])
	quit()
