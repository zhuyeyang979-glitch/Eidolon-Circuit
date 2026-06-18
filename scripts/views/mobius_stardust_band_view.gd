class_name MobiusStardustBandView
extends "res://scripts/views/mobius_strip_surface_view.gd"


var stardust_last_bands: Array = []
var stardust_last_source_widths := PackedFloat32Array()
var stardust_last_source_alphas := PackedFloat32Array()
var stardust_last_display_widths := PackedFloat32Array()
var stardust_last_display_alphas := PackedFloat32Array()
var stardust_last_depths := PackedFloat32Array()

func _reset_stardust_band_cache() -> void:
	super._reset_stardust_band_cache()
	stardust_last_bands = []
	stardust_last_source_widths = PackedFloat32Array()
	stardust_last_source_alphas = PackedFloat32Array()
	stardust_last_display_widths = PackedFloat32Array()
	stardust_last_display_alphas = PackedFloat32Array()
	stardust_last_depths = PackedFloat32Array()

func _update_stardust_band_cache() -> void:
	_reset_stardust_band_cache()
	if not stardust_band_enabled or not bool(config.get("enabled", true)):
		return
	var visual_config := config.duplicate(true)
	visual_config["twist_visual_enabled"] = true
	visual_config["local_rectangular_projection"] = false
	visual_config["depth_contrast"] = maxf(1.18, float(visual_config.get("depth_contrast", 1.0)))
	var half_width := MobiusWorld.strip_half_width(visual_config)
	var surface_segments := clampi(int(visual_config.get("surface_segments", 96)), 48, 144)
	var view_width := maxf(1.0, float(visual_config.get("view_width", 7.2)))
	var span := view_width * 1.28
	var screen_scale := maxf(1.0, float(visual_config.get("screen_scale", 1.0)))
	var source_width := maxf(0.1, float(config.get("stardust_source_width_px", 6.0)))
	var source_alpha := clampf(float(config.get("stardust_source_alpha", 0.115)), 0.0, stardust_alpha_max)
	var source_particle_radius := maxf(0.1, float(config.get("stardust_particle_source_radius_px", 1.15)))
	var source_half_width_units := source_width / screen_scale * 0.5
	var lane_specs := [
		{"name": "upper", "ratio": -0.34},
		{"name": "lower", "ratio": 0.34},
	]
	for band_index in range(lane_specs.size()):
		var lane_spec: Dictionary = lane_specs[band_index]
		var lane_ratio := float(lane_spec.get("ratio", 0.0))
		var band_points := PackedVector2Array()
		var band_widths := PackedFloat32Array()
		var band_alphas := PackedFloat32Array()
		var band_depths := PackedFloat32Array()
		var band_radii := PackedFloat32Array()
		var band_source_widths := PackedFloat32Array()
		var band_source_alphas := PackedFloat32Array()
		var band_coords := PackedVector2Array()
		var particle_points := PackedVector2Array()
		var particle_radii := PackedFloat32Array()
		var particle_alphas := PackedFloat32Array()
		for i in range(surface_segments + 1):
			var t := float(i) / float(surface_segments)
			var s := camera_coord.x + lerpf(-span, span, t)
			var coord := Vector2(s, half_width * lane_ratio)
			var projection := MobiusWorld.project_to_screen(coord, camera_coord, visual_config, rotation_state)
			var pos: Vector2 = projection.get("position", Vector2.ZERO)
			var depth01 := clampf(float(projection.get("depth01", 0.5)), 0.0, 1.0)
			var visual_scale := maxf(0.01, float(projection.get("scale", 1.0)))
			var width := source_width * visual_scale
			var alpha := minf(stardust_alpha_max, source_alpha * lerpf(0.52, 1.0, depth01))
			var radius := source_particle_radius * visual_scale
			band_points.append(pos)
			band_widths.append(width)
			band_alphas.append(alpha)
			band_depths.append(depth01)
			band_radii.append(radius)
			band_source_widths.append(source_width)
			band_source_alphas.append(source_alpha)
			band_coords.append(coord)
			stardust_last_points.append(pos)
			stardust_last_widths.append(width)
			stardust_last_alphas.append(alpha)
			stardust_last_source_widths.append(source_width)
			stardust_last_source_alphas.append(source_alpha)
			stardust_last_display_widths.append(width)
			stardust_last_display_alphas.append(alpha)
			stardust_last_depths.append(depth01)
			stardust_last_max_alpha = maxf(stardust_last_max_alpha, alpha)
		var particle_count := maxi(1, int(floor(float(stardust_particle_budget) / 2.0)))
		for particle_index in range(particle_count):
			var ratio := (float(particle_index) + 0.5) / float(particle_count)
			var s := camera_coord.x + lerpf(-span, span, ratio)
			var source_offset := sin(ratio * TAU * 23.0 + float(band_index) * 1.7) * 0.36
			source_offset += sin(ratio * TAU * 7.0 + float(band_index) * 0.9) * 0.14
			var particle_coord := Vector2(s, half_width * lane_ratio + source_offset * source_half_width_units)
			var particle_projection := MobiusWorld.project_to_screen(particle_coord, camera_coord, visual_config, rotation_state)
			var particle_depth := clampf(float(particle_projection.get("depth01", 0.5)), 0.0, 1.0)
			var particle_scale := maxf(0.01, float(particle_projection.get("scale", 1.0)))
			particle_points.append(particle_projection.get("position", Vector2.ZERO))
			particle_radii.append(source_particle_radius * particle_scale)
			particle_alphas.append(minf(0.16, source_alpha * lerpf(0.40, 0.86, particle_depth)))
		stardust_last_bands.append({
			"name": String(lane_spec.get("name", "band")),
			"lane_ratio": lane_ratio,
			"points": band_points,
			"widths": band_widths,
			"alphas": band_alphas,
			"depths": band_depths,
			"radii": band_radii,
			"source_widths": band_source_widths,
			"source_alphas": band_source_alphas,
			"display_widths": band_widths,
			"display_alphas": band_alphas,
			"particle_points": particle_points,
			"particle_radii": particle_radii,
			"particle_alphas": particle_alphas,
			"surface_coords": band_coords,
		})
	stardust_last_visible = stardust_last_bands.size() == 2 and stardust_last_points.size() >= 4
	stardust_last_particle_count = stardust_particle_budget if stardust_last_visible else 0

func _draw_band_particles(points: PackedVector2Array, alphas: PackedFloat32Array, radii: PackedFloat32Array) -> void:
	if points.is_empty():
		return
	var count := mini(points.size(), mini(alphas.size(), radii.size()))
	for i in range(count):
		var p := points[i]
		var radius := maxf(0.35, radii[i])
		var alpha := minf(0.16, alphas[i])
		draw_circle(p, radius + 1.4, Color(0.38, 0.68, 1.0, alpha * 0.42))
		draw_circle(p, radius, Color(0.88, 0.96, 1.0, alpha))

func _draw_stardust_surface_bands() -> void:
	if not stardust_last_visible:
		return
	for band_index in range(stardust_last_bands.size()):
		var band: Dictionary = stardust_last_bands[band_index]
		var points := PackedVector2Array(band.get("points", PackedVector2Array()))
		var widths := PackedFloat32Array(band.get("widths", PackedFloat32Array()))
		var alphas := PackedFloat32Array(band.get("alphas", PackedFloat32Array()))
		if points.size() < 2:
			continue
		for i in range(points.size() - 1):
			var width := (widths[i] + widths[i + 1]) * 0.5
			var alpha := minf(stardust_alpha_max, (alphas[i] + alphas[i + 1]) * 0.5)
			draw_line(points[i], points[i + 1], Color(0.26, 0.58, 1.0, minf(0.32, alpha * 1.18)), width * 3.05, true)
			draw_line(points[i], points[i + 1], Color(0.58, 0.82, 1.0, minf(0.25, alpha * 0.92)), width * 1.52, true)
			draw_line(points[i], points[i + 1], Color(0.94, 0.98, 1.0, minf(0.18, alpha * 0.58)), maxf(1.0, width * 0.32), true)
		_draw_band_particles(
			PackedVector2Array(band.get("particle_points", PackedVector2Array())),
			PackedFloat32Array(band.get("particle_alphas", PackedFloat32Array())),
			PackedFloat32Array(band.get("particle_radii", PackedFloat32Array()))
		)

func _draw() -> void:
	if not bool(config.get("enabled", true)):
		_reset_stardust_band_cache()
		return
	if not stardust_band_enabled:
		_reset_stardust_band_cache()
		return
	set_meta("draw_count", int(get_meta("draw_count", 0)) + 1)
	_draw_stardust_surface_bands()

func stardust_band_snapshot() -> Dictionary:
	var snapshot := super.stardust_band_snapshot()
	snapshot["bands"] = stardust_last_bands.duplicate(true)
	snapshot["band_count"] = stardust_last_bands.size()
	snapshot["surface_attached"] = true
	snapshot["source_widths"] = stardust_last_source_widths
	snapshot["source_alphas"] = stardust_last_source_alphas
	snapshot["display_widths"] = stardust_last_display_widths
	snapshot["display_alphas"] = stardust_last_display_alphas
	snapshot["depths"] = stardust_last_depths
	return snapshot
