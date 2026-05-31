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
	main.camera_mobius_s = 4.75
	main.camera_center = 4.75
	main.mobius_rotation_state = {"twist_phase": 0.72, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var visual_config: Dictionary = main.mobius_stardust_band_view.config.duplicate(true)
	visual_config["twist_visual_enabled"] = true
	visual_config["local_rectangular_projection"] = false
	visual_config["depth_contrast"] = maxf(1.18, float(visual_config.get("depth_contrast", 1.0)))
	var bands: Array = snapshot.get("bands", [])
	if bands.size() != 2:
		_fail("Projection-only stardust probe requires two bands.")
		return
	var checked := 0
	var width_variation := 0.0
	var alpha_variation := 0.0
	for raw_band in bands:
		var band := Dictionary(raw_band)
		var coords := PackedVector2Array(band.get("surface_coords", PackedVector2Array()))
		var source_widths := PackedFloat32Array(band.get("source_widths", PackedFloat32Array()))
		var source_alphas := PackedFloat32Array(band.get("source_alphas", PackedFloat32Array()))
		var display_widths := PackedFloat32Array(band.get("display_widths", PackedFloat32Array()))
		var display_alphas := PackedFloat32Array(band.get("display_alphas", PackedFloat32Array()))
		var depths := PackedFloat32Array(band.get("depths", PackedFloat32Array()))
		if coords.size() < 48 or source_widths.size() != coords.size() or display_widths.size() != coords.size():
			_fail("Band samples should expose aligned source/display arrays.")
			return
		var base_width := source_widths[0]
		var base_alpha := source_alphas[0]
		var min_width := INF
		var max_width := -INF
		var min_alpha := INF
		var max_alpha := -INF
		var step := maxi(1, coords.size() / 16)
		for i in range(0, coords.size(), step):
			var projection := MobiusWorld.project_to_screen(coords[i], main._mobius_camera_coord(), visual_config, main.mobius_rotation_state)
			var scale := maxf(0.01, float(projection.get("scale", 1.0)))
			var depth := clampf(float(projection.get("depth01", 0.5)), 0.0, 1.0)
			var expected_width := base_width * scale
			var expected_alpha := minf(float(snapshot.get("max_source_alpha_cap", main.mobius_stardust_band_view.stardust_alpha_max)), base_alpha * lerpf(0.52, 1.0, depth))
			if absf(display_widths[i] - expected_width) > 0.01:
				_fail("Display width should be source width times projection scale. expected=%.4f actual=%.4f." % [expected_width, display_widths[i]])
				return
			if absf(display_alphas[i] - expected_alpha) > 0.002:
				_fail("Display alpha should be source alpha times projection depth brightness. expected=%.4f actual=%.4f." % [expected_alpha, display_alphas[i]])
				return
			if absf(depths[i] - depth) > 0.002:
				_fail("Cached stardust depth should match projection depth.")
				return
			min_width = minf(min_width, display_widths[i])
			max_width = maxf(max_width, display_widths[i])
			min_alpha = minf(min_alpha, display_alphas[i])
			max_alpha = maxf(max_alpha, display_alphas[i])
			checked += 1
		width_variation = maxf(width_variation, max_width - min_width)
		alpha_variation = maxf(alpha_variation, max_alpha - min_alpha)
	if width_variation <= 0.05 or alpha_variation <= 0.005:
		_fail("Projection should still create visible width/alpha variation; width=%.4f alpha=%.4f." % [width_variation, alpha_variation])
		return
	var shader_source := FileAccess.get_file_as_string("res://shaders/mobius_strip_surface.gdshader")
	for forbidden in ["ribbon_wave", "nebula", "dust ="]:
		if shader_source.find(forbidden) >= 0:
			_fail("Mobius surface shader should not generate independent cosmic band art via '%s'." % forbidden)
			return
	print("MOBIUS_STARDUST_PROJECTION_ONLY_VARIATION_PROBE ok checked=%d width_delta=%.3f alpha_delta=%.3f" % [
		checked,
		width_variation,
		alpha_variation,
	])
	quit()
