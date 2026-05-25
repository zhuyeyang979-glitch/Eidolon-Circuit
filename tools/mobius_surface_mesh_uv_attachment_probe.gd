extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH
	main.camera_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.66, "angle": 0.0}
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible in battle.")
		return
	var texture_path := String(main.mobius_surface_texture.get_meta("runtime_source_path", ""))
	if texture_path != MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH:
		_fail("Mobius surface should load the square-grid field texture, got %s." % texture_path)
		return
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_field_kind", "")) != "square_grid_field":
		_fail("Mobius surface should expose the square-grid field semantics.")
		return
	if bool(surface_snapshot.get("lane_guides_enabled", true)):
		_fail("Mobius surface must not render internal straight lane guides.")
		return
	if bool(surface_snapshot.get("local_rectangular_projection", true)):
		_fail("Mobius visual surface should use true Mobius projection, not rectangular gameplay projection.")
		return
	var gameplay_config: Dictionary = main._mobius_config()
	if not bool(gameplay_config.get("local_rectangular_projection", false)):
		_fail("Gameplay Mobius config should keep rectangular projection for units/projectiles.")
		return
	var samples := MobiusWorld.surface_sample_grid(main._mobius_camera_coord(), main.mobius_strip_surface_view.config, main.mobius_rotation_state)
	var found_flipped_u := false
	var found_visible_poly := false
	var min_y := INF
	var max_y := -INF
	for raw_sample in samples:
		var sample: Dictionary = raw_sample
		var poly := PackedVector2Array(sample.get("poly", PackedVector2Array()))
		var uvs := PackedVector2Array(sample.get("uvs", PackedVector2Array()))
		if poly.size() >= 4:
			found_visible_poly = true
			for point in poly:
				min_y = minf(min_y, point.y)
				max_y = maxf(max_y, point.y)
		for uv in uvs:
			if uv.x > 1.0:
				found_flipped_u = true
				break
	if not found_visible_poly:
		_fail("Mobius visual surface should generate drawable UV quads.")
		return
	if not found_flipped_u:
		_fail("Mobius visual surface UVs should keep lifted U values for half-twist sampling.")
		return
	if max_y - min_y < 120.0:
		_fail("Mobius visual surface projection should visibly curve across the viewport; y_range=%.2f." % (max_y - min_y))
		return
	print("MOBIUS_SURFACE_MESH_UV_ATTACHMENT_PROBE ok square_grid y_range=%.2f texture=%s" % [max_y - min_y, texture_path])
	quit()
