class_name MobiusStripSurfaceView
extends Control

const MobiusWorld = preload("res://scripts/mobius_world.gd")


var config := {}
var rotation_state := {}
var camera_coord := Vector2.ZERO
var surface_texture: Texture2D
var surface_field_kind := "square_grid_field"
var surface_grid_cell_px := 56.0
var surface_lane_guides_enabled := false
var stardust_band_enabled := false
var stardust_alpha_max := 0.28
var stardust_width_min := 2.0
var stardust_width_max := 11.0
var stardust_particle_budget := 96
var stardust_last_points := PackedVector2Array()
var stardust_last_widths := PackedFloat32Array()
var stardust_last_alphas := PackedFloat32Array()
var stardust_last_particle_count := 0
var stardust_last_visible := false
var stardust_last_max_alpha := 0.0
var surface_render_mode := "full_rect_inverse_sample"
var last_surface_draw_rect := Rect2()
var world_grid_last_anchor_coord := Vector2.ZERO
var world_grid_last_cell_world := 0.0
var world_grid_last_line_count := 0
var linear_elevation_visual_enabled := false
var linear_elevation_band_count := 0
var linear_elevation_contour_count := 0
var linear_elevation_last_drawn_band_count := 0
var linear_elevation_last_drawn_contour_count := 0
var linear_elevation_last_sample_count := 0
var linear_elevation_last_alpha_span := 0.0
var linear_elevation_last_width_span := 0.0

func set_surface_texture(texture: Texture2D) -> void:
	surface_texture = texture
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		shader_material.set_shader_parameter("surface_texture", surface_texture)
		shader_material.set_shader_parameter("surface_texture_enabled", surface_texture != null)
	queue_redraw()

func set_world(next_config: Dictionary, next_rotation_state: Dictionary, next_camera_coord: Vector2) -> void:
	config = next_config.duplicate(true)
	config["twist_visual_enabled"] = true
	surface_render_mode = String(config.get("surface_projection_mode", "full_rect_inverse_sample"))
	last_surface_draw_rect = config.get("screen_rect", Rect2(Vector2.ZERO, size))
	surface_field_kind = String(config.get("surface_field_kind", surface_field_kind))
	surface_grid_cell_px = maxf(1.0, float(config.get("surface_grid_cell_px", surface_grid_cell_px)))
	surface_lane_guides_enabled = bool(config.get("surface_lane_guides_enabled", surface_lane_guides_enabled))
	linear_elevation_visual_enabled = bool(config.get("linear_elevation_visual_enabled", linear_elevation_visual_enabled))
	linear_elevation_band_count = clampi(int(config.get("linear_elevation_band_count", 9)), 0, 18) if linear_elevation_visual_enabled else 0
	linear_elevation_contour_count = clampi(int(config.get("linear_elevation_contour_count", 7)), 0, 14) if linear_elevation_visual_enabled else 0
	linear_elevation_last_drawn_band_count = 0
	linear_elevation_last_drawn_contour_count = 0
	linear_elevation_last_sample_count = 0
	linear_elevation_last_alpha_span = maxf(0.0, float(config.get("linear_elevation_high_alpha", 0.135)) - float(config.get("linear_elevation_low_alpha", 0.026))) if linear_elevation_visual_enabled else 0.0
	linear_elevation_last_width_span = maxf(0.0, float(config.get("linear_elevation_high_width", 2.25)) - float(config.get("linear_elevation_low_width", 0.85))) if linear_elevation_visual_enabled else 0.0
	stardust_band_enabled = bool(config.get("stardust_band_enabled", stardust_band_enabled))
	stardust_alpha_max = clampf(float(config.get("stardust_alpha_max", stardust_alpha_max)), 0.0, 0.32)
	stardust_width_min = maxf(0.1, float(config.get("stardust_width_min", stardust_width_min)))
	stardust_width_max = maxf(stardust_width_min, float(config.get("stardust_width_max", stardust_width_max)))
	stardust_particle_budget = clampi(int(config.get("stardust_particle_budget", stardust_particle_budget)), 0, 240)
	rotation_state = next_rotation_state.duplicate(true)
	camera_coord = next_camera_coord
	if surface_render_mode == "world_grid":
		var world_grid_screen_scale := maxf(1.0, float(config.get("screen_scale", 1.0)))
		world_grid_last_anchor_coord = camera_coord
		world_grid_last_cell_world = maxf(0.10, surface_grid_cell_px / world_grid_screen_scale)
		world_grid_last_line_count = 0
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		var shader_parameters := MobiusWorld.surface_shader_parameters(camera_coord, config, rotation_state)
		shader_material.set_shader_parameter("twist_phase", float(rotation_state.get("twist_phase", rotation_state.get("angle", 0.0))))
		shader_material.set_shader_parameter("depth_contrast", float(config.get("depth_contrast", 1.0)))
		shader_material.set_shader_parameter("edge_fog", float(config.get("edge_fog_width", config.get("boundary_fog_width", 0.75))))
		shader_material.set_shader_parameter("cosmic_mix", float(config.get("cosmic_mix", 0.035)))
		shader_material.set_shader_parameter("camera_surface_coord", shader_parameters.get("camera_surface_coord", Vector2.ZERO))
		shader_material.set_shader_parameter("surface_view_world_size", shader_parameters.get("surface_view_world_size", Vector2(7.2, 5.2)))
		shader_material.set_shader_parameter("loop_length", float(shader_parameters.get("loop_length", 24.0)))
		shader_material.set_shader_parameter("grid_cell_world", float(shader_parameters.get("grid_cell_world", 0.16)))
		shader_material.set_shader_parameter("ridge_normal", shader_parameters.get("ridge_normal", Vector2(0.707, 0.707)))
		shader_material.set_shader_parameter("ridge_pivot_bias", shader_parameters.get("ridge_pivot_bias", Vector2.ZERO))
		shader_material.set_shader_parameter("ridge_period", float(shader_parameters.get("ridge_period", 1.92)))
		shader_material.set_shader_parameter("ridge_width", float(shader_parameters.get("ridge_width", 1.0)))
		shader_material.set_shader_parameter("ridge_offset", float(shader_parameters.get("ridge_offset", 0.96)))
		shader_material.set_shader_parameter("ridge_warp_amplitude", float(shader_parameters.get("ridge_warp_amplitude", 0.125)))
		shader_material.set_shader_parameter("twist_uv_shear", float(shader_parameters.get("twist_shear_strength", 0.17)))
		shader_material.set_shader_parameter("twist_uv_warp", float(shader_parameters.get("twist_warp_strength", 0.035)))
		shader_material.set_shader_parameter("far_brightness", float(shader_parameters.get("far_brightness", 0.62)))
		shader_material.set_shader_parameter("near_brightness", float(shader_parameters.get("near_brightness", 1.10)))
		shader_material.set_shader_parameter("grid_far_brightness", float(shader_parameters.get("grid_far_brightness", shader_parameters.get("far_brightness", 0.52))))
		shader_material.set_shader_parameter("grid_near_brightness", float(shader_parameters.get("grid_near_brightness", shader_parameters.get("near_brightness", 0.88))))
		shader_material.set_shader_parameter("surface_alpha_gain", float(config.get("surface_alpha_gain", 1.0)))
		shader_material.set_shader_parameter("surface_alpha_max", float(config.get("surface_alpha_max", 0.18)))
		shader_material.set_shader_parameter("surface_color_gain", float(config.get("surface_color_gain", 1.0)))
		shader_material.set_shader_parameter("surface_texture", surface_texture)
		shader_material.set_shader_parameter("surface_texture_enabled", surface_texture != null)
	_update_stardust_band_cache()
	queue_redraw()

func _draw() -> void:
	if not bool(config.get("enabled", true)):
		_reset_stardust_band_cache()
		return
	last_surface_draw_rect = config.get("screen_rect", Rect2(Vector2.ZERO, size))
	if surface_render_mode == "world_grid":
		_draw_world_grid_surface()
		return
	if surface_texture != null:
		draw_texture_rect(surface_texture, last_surface_draw_rect, false, Color.WHITE)
	else:
		draw_rect(last_surface_draw_rect, Color(0.22, 0.62, 0.92, 0.18), true)
	if not surface_lane_guides_enabled:
		return
	var half_width := MobiusWorld.strip_half_width(config)
	var surface_segments := clampi(int(config.get("surface_segments", 96)), 16, 160)
	var view_width := maxf(1.0, float(config.get("view_width", 7.2)))
	var span := view_width * 1.22
	for raw_lane_ratio in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		var lane_ratio := float(raw_lane_ratio)
		if absf(lane_ratio) >= 0.9 and not bool(config.get("show_surface_boundary_guides", true)):
			continue
		var points := PackedVector2Array()
		for i in range(surface_segments + 1):
			var t := float(i) / float(surface_segments)
			var s := camera_coord.x + lerpf(-span, span, t)
			var v := half_width * lane_ratio
			var projection := MobiusWorld.project_to_screen(Vector2(s, v), camera_coord, config, rotation_state)
			points.append(projection.get("position", Vector2.ZERO))
		var alpha := 0.22 if absf(lane_ratio) < 0.9 else 0.34
		var edge_softness := MobiusWorld.boundary_softness(half_width * lane_ratio, config)
		draw_polyline(points, Color(0.72, 0.94, 1.0, alpha * (0.28 + edge_softness * 0.72)), 1.2 if absf(lane_ratio) < 0.9 else 3.6, true)

func _world_grid_projection_config() -> Dictionary:
	var draw_config := config.duplicate(true)
	draw_config["surface_projection_mode"] = "world_grid"
	draw_config["surface_world_grid_stable"] = true
	draw_config["local_rectangular_projection"] = true
	draw_config["twist_visual_enabled"] = false
	draw_config["surface_ridge_lift_strength"] = 0.0
	draw_config["surface_ridge_warp_amplitude"] = 0.0
	draw_config["surface_twist_shear_strength"] = 0.0
	draw_config["surface_twist_warp_strength"] = 0.0
	return draw_config

func _project_world_grid_polyline(coords: PackedVector2Array, draw_config: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	for coord in coords:
		var projection := MobiusWorld.project_to_screen(coord, camera_coord, draw_config, rotation_state)
		var pos: Vector2 = projection.get("position", Vector2.ZERO)
		if is_finite(pos.x) and is_finite(pos.y):
			points.append(pos)
	return points

func _draw_world_grid_polyline(coords: PackedVector2Array, draw_config: Dictionary, color: Color, width: float) -> void:
	var points := _project_world_grid_polyline(coords, draw_config)
	if points.size() >= 2:
		draw_polyline(points, color, width, true)
		world_grid_last_line_count += 1

func _linear_elevation_color(height01: float) -> Color:
	var low_color: Color = config.get("linear_elevation_low_color", Color(0.08, 0.16, 0.22, 1.0))
	var high_color: Color = config.get("linear_elevation_high_color", Color(0.95, 0.72, 0.24, 1.0))
	return low_color.lerp(high_color, clampf(height01, 0.0, 1.0))

func _draw_linear_elevation_overlay(draw_config: Dictionary, span_s: float, half_width: float, segment_count_s: int) -> void:
	linear_elevation_last_drawn_band_count = 0
	linear_elevation_last_drawn_contour_count = 0
	linear_elevation_last_sample_count = 0
	if not linear_elevation_visual_enabled:
		return
	var band_count := clampi(linear_elevation_band_count, 3, 18)
	var contour_count := clampi(linear_elevation_contour_count, 3, 14)
	var low_alpha := clampf(float(config.get("linear_elevation_low_alpha", 0.026)), 0.0, 0.12)
	var high_alpha := clampf(float(config.get("linear_elevation_high_alpha", 0.135)), low_alpha, 0.20)
	var low_width := maxf(0.2, float(config.get("linear_elevation_low_width", 0.85)))
	var high_width := maxf(low_width, float(config.get("linear_elevation_high_width", 2.25)))
	linear_elevation_last_alpha_span = high_alpha - low_alpha
	linear_elevation_last_width_span = high_width - low_width
	for band_index in range(band_count):
		var start_t := float(band_index) / float(band_count)
		var end_t := float(band_index + 1) / float(band_count)
		var height01 := (start_t + end_t) * 0.5
		var lane_start := lerpf(-half_width, half_width, start_t)
		var lane_end := lerpf(-half_width, half_width, end_t)
		var polygon := PackedVector2Array()
		for sample_index in range(segment_count_s + 1):
			var ratio := float(sample_index) / float(segment_count_s)
			var coord := Vector2(lerpf(camera_coord.x - span_s, camera_coord.x + span_s, ratio), lane_start)
			var projection := MobiusWorld.project_to_screen(coord, camera_coord, draw_config, rotation_state)
			polygon.append(projection.get("position", Vector2.ZERO))
		for sample_index in range(segment_count_s, -1, -1):
			var ratio := float(sample_index) / float(segment_count_s)
			var coord := Vector2(lerpf(camera_coord.x - span_s, camera_coord.x + span_s, ratio), lane_end)
			var projection := MobiusWorld.project_to_screen(coord, camera_coord, draw_config, rotation_state)
			polygon.append(projection.get("position", Vector2.ZERO))
		if polygon.size() >= 4:
			var band_color := _linear_elevation_color(height01)
			band_color.a = lerpf(low_alpha, high_alpha, height01)
			draw_colored_polygon(polygon, band_color)
			linear_elevation_last_drawn_band_count += 1
			linear_elevation_last_sample_count += polygon.size()
	var dash_count := clampi(int(config.get("linear_elevation_dash_count", 14)), 6, 30)
	var dash_ratio := clampf(float(config.get("linear_elevation_dash_ratio", 0.56)), 0.30, 0.82)
	for contour_index in range(contour_count):
		var height01 := (float(contour_index) + 0.5) / float(contour_count)
		var lane_v := lerpf(-half_width, half_width, height01)
		var contour_color := _linear_elevation_color(height01)
		contour_color.a = lerpf(low_alpha * 1.35, high_alpha * 1.22, height01)
		var width := lerpf(low_width, high_width, height01)
		for dash_index in range(dash_count):
			if (dash_index + contour_index) % 5 == 3:
				continue
			var dash_start := float(dash_index) / float(dash_count)
			var dash_end := minf(dash_start + dash_ratio / float(dash_count), 1.0)
			var coords := PackedVector2Array()
			for sample_index in range(4):
				var sample_ratio := float(sample_index) / 3.0
				var t := lerpf(dash_start, dash_end, sample_ratio)
				coords.append(Vector2(lerpf(camera_coord.x - span_s, camera_coord.x + span_s, t), lane_v))
			var points := _project_world_grid_polyline(coords, draw_config)
			if points.size() >= 2:
				draw_polyline(points, contour_color, width, true)
				linear_elevation_last_drawn_contour_count += 1
				linear_elevation_last_sample_count += points.size()

func _draw_world_grid_surface() -> void:
	world_grid_last_line_count = 0
	var draw_config := _world_grid_projection_config()
	var screen_scale := maxf(1.0, float(draw_config.get("screen_scale", 1.0)))
	var view_world_width := last_surface_draw_rect.size.x / screen_scale
	var view_world_height := float(draw_config.get("view_height", last_surface_draw_rect.size.y / screen_scale))
	var half_width := MobiusWorld.strip_half_width(draw_config)
	var span_s := view_world_width * 0.5 + maxf(1.0, view_world_width * 0.18)
	var span_v := minf(half_width, view_world_height * 0.5 + 0.65)
	var grid_cell_world := maxf(0.10, float(draw_config.get("surface_grid_cell_px", surface_grid_cell_px)) / screen_scale)
	world_grid_last_anchor_coord = camera_coord
	world_grid_last_cell_world = grid_cell_world
	draw_rect(last_surface_draw_rect, Color(0.018, 0.027, 0.038, 0.90), true)
	draw_rect(last_surface_draw_rect, Color(0.10, 0.19, 0.24, 0.18), false, 1.0, true)
	var s_start: float = floor((camera_coord.x - span_s) / grid_cell_world) * grid_cell_world
	var s_end: float = camera_coord.x + span_s
	var v_start: float = floor((camera_coord.y - span_v) / grid_cell_world) * grid_cell_world
	var v_end: float = camera_coord.y + span_v
	var segment_count_s := clampi(int(ceil((span_s * 2.0) / maxf(grid_cell_world, 0.001))) * 2, 18, 140)
	var segment_count_v := clampi(int(ceil((span_v * 2.0) / maxf(grid_cell_world, 0.001))) * 2, 8, 80)
	_draw_linear_elevation_overlay(draw_config, span_s, half_width, segment_count_s)
	var s: float = s_start
	while s <= s_end + 0.001:
		var coords := PackedVector2Array()
		for i in range(segment_count_v + 1):
			var t := float(i) / float(segment_count_v)
			coords.append(Vector2(s, clampf(lerpf(-span_v, span_v, t) + camera_coord.y, -half_width, half_width)))
		var major := absf(fposmod(s, grid_cell_world * 4.0)) < grid_cell_world * 0.08
		_draw_world_grid_polyline(coords, draw_config, Color(0.42, 0.78, 0.88, 0.18 if major else 0.10), 1.15 if major else 0.72)
		s += grid_cell_world
	var v: float = v_start
	while v <= v_end + 0.001:
		var clamped_v := clampf(v, -half_width, half_width)
		var coords := PackedVector2Array()
		for i in range(segment_count_s + 1):
			var t := float(i) / float(segment_count_s)
			coords.append(Vector2(lerpf(camera_coord.x - span_s, camera_coord.x + span_s, t), clamped_v))
		var center_line := absf(clamped_v) <= grid_cell_world * 0.12
		var boundary_line := absf(absf(clamped_v) - half_width) <= grid_cell_world * 0.65
		var alpha := 0.18 if center_line else 0.11
		var width := 1.35 if center_line else 0.78
		if boundary_line:
			alpha = 0.30
			width = 2.0
		_draw_world_grid_polyline(coords, draw_config, Color(0.50, 0.86, 0.94, alpha), width)
		v += grid_cell_world
	for lane_ratio in [-1.0, 0.0, 1.0]:
		var lane_v := half_width * float(lane_ratio)
		var coords := PackedVector2Array()
		for i in range(segment_count_s + 1):
			var t := float(i) / float(segment_count_s)
			coords.append(Vector2(lerpf(camera_coord.x - span_s, camera_coord.x + span_s, t), lane_v))
		var line_color := Color(0.76, 0.96, 1.0, 0.22 if absf(lane_ratio) < 0.5 else 0.32)
		_draw_world_grid_polyline(coords, draw_config, line_color, 1.55 if absf(lane_ratio) < 0.5 else 2.4)

func _sort_surface_sample(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("avg_depth", 0.0)) < float(b.get("avg_depth", 0.0))

func _reset_stardust_band_cache() -> void:
	stardust_last_points = PackedVector2Array()
	stardust_last_widths = PackedFloat32Array()
	stardust_last_alphas = PackedFloat32Array()
	stardust_last_particle_count = 0
	stardust_last_visible = false
	stardust_last_max_alpha = 0.0

func _update_stardust_band_cache() -> void:
	_reset_stardust_band_cache()
	if not stardust_band_enabled or not bool(config.get("enabled", true)):
		return
	var loop := maxf(0.001, float(config.get("loop_length", 24.0)))
	var surface_segments := clampi(int(config.get("surface_segments", 96)), 32, 128)
	var view_width := maxf(1.0, float(config.get("view_width", 7.2)))
	var span := view_width * 1.22
	var twist_phase := float(rotation_state.get("twist_phase", rotation_state.get("angle", 0.0)))
	for i in range(surface_segments + 1):
		var t := float(i) / float(surface_segments)
		var s := camera_coord.x + lerpf(-span, span, t)
		var projection := MobiusWorld.project_to_screen(Vector2(s, 0.0), camera_coord, config, rotation_state)
		var pos: Vector2 = projection.get("position", Vector2.ZERO)
		var depth01 := float(projection.get("depth01", 0.5))
		var phase := TAU * s / loop
		var visual_wave := sin(phase + twist_phase) + sin(phase * 0.43 - twist_phase * 0.7) * 0.42
		var arc_lift := -94.0 * sin(t * PI)
		var twist_lift := visual_wave * 42.0 + sin(t * TAU * 1.7 + twist_phase * 0.8) * 22.0
		var depth_lift := (depth01 - 0.5) * 58.0
		var x_waver := sin(phase * 0.62 + twist_phase * 1.1) * 12.0 * (0.35 + depth01)
		pos += Vector2(x_waver, arc_lift + twist_lift + depth_lift)
		var width_ratio := clampf(0.22 + depth01 * 0.48 + (0.5 + 0.5 * sin(phase * 1.23 + twist_phase)) * 0.30, 0.0, 1.0)
		var width := lerpf(stardust_width_min, stardust_width_max, width_ratio)
		var alpha := stardust_alpha_max * clampf(0.42 + depth01 * 0.42 + (0.5 + 0.5 * sin(phase * 0.77 - twist_phase)) * 0.16, 0.0, 1.0)
		stardust_last_points.append(pos)
		stardust_last_widths.append(width)
		stardust_last_alphas.append(alpha)
		stardust_last_max_alpha = maxf(stardust_last_max_alpha, alpha)
	stardust_last_visible = stardust_last_points.size() >= 2
	stardust_last_particle_count = stardust_particle_budget if stardust_last_visible else 0

func _draw_stardust_band() -> void:
	if not stardust_last_visible or stardust_last_points.size() < 2:
		return
	for i in range(stardust_last_points.size() - 1):
		var p0 := stardust_last_points[i]
		var p1 := stardust_last_points[i + 1]
		var width := (stardust_last_widths[i] + stardust_last_widths[i + 1]) * 0.5
		var alpha := minf(stardust_alpha_max, (stardust_last_alphas[i] + stardust_last_alphas[i + 1]) * 0.5)
		draw_line(p0, p1, Color(0.30, 0.72, 1.0, minf(0.34, alpha * 3.25)), width, true)
		draw_line(p0, p1, Color(0.92, 0.98, 1.0, minf(0.44, alpha * 4.0)), maxf(1.2, width * 0.30), true)
	var count := mini(stardust_particle_budget, 96)
	var twist_phase := float(rotation_state.get("twist_phase", rotation_state.get("angle", 0.0)))
	for i in range(count):
		var ratio := (float(i) + 0.5) / float(maxi(1, count))
		var index := clampi(int(round(ratio * float(stardust_last_points.size() - 1))), 0, stardust_last_points.size() - 1)
		var prev_index := maxi(0, index - 1)
		var next_index := mini(stardust_last_points.size() - 1, index + 1)
		var tangent := (stardust_last_points[next_index] - stardust_last_points[prev_index]).normalized()
		if tangent.length() <= 0.001:
			tangent = Vector2.RIGHT
		var normal := Vector2(-tangent.y, tangent.x)
		var width := stardust_last_widths[index]
		var jitter := normal * sin(ratio * TAU * 19.0 + twist_phase * 1.7) * width * 0.72
		var along := tangent * sin(ratio * TAU * 11.0 - twist_phase) * width * 0.42
		var p := stardust_last_points[index] + jitter + along
		var pulse := 0.5 + 0.5 * sin(ratio * TAU * 7.0 + twist_phase * 1.3)
		var radius := 0.75 + pulse * 1.9
		var alpha := minf(0.32, stardust_last_alphas[index] * (1.5 + pulse * 0.85))
		draw_circle(p, radius + 1.1, Color(0.36, 0.78, 1.0, alpha * 0.58))
		draw_circle(p, radius, Color(0.92, 0.98, 1.0, alpha))

func stardust_band_snapshot() -> Dictionary:
	return {
		"enabled": stardust_band_enabled,
		"visible": stardust_last_visible,
		"points": stardust_last_points,
		"widths": stardust_last_widths,
		"alphas": stardust_last_alphas,
		"particle_count": stardust_last_particle_count,
		"max_alpha": stardust_last_max_alpha,
		"lane_guides_enabled": surface_lane_guides_enabled,
		"surface_field_kind": surface_field_kind,
		"surface_grid_cell_px": surface_grid_cell_px,
		"surface_texture_path": String(surface_texture.get_meta("runtime_source_path", "")) if surface_texture != null else "",
		"local_rectangular_projection": bool(config.get("local_rectangular_projection", false)),
		"surface_render_mode": surface_render_mode,
		"surface_draw_rect": last_surface_draw_rect,
		"world_grid_anchor_coord": world_grid_last_anchor_coord,
		"world_grid_cell_world": world_grid_last_cell_world,
		"world_grid_line_count": world_grid_last_line_count,
		"linear_elevation_visual_enabled": linear_elevation_visual_enabled,
		"linear_elevation_band_count": linear_elevation_band_count,
		"linear_elevation_contour_count": linear_elevation_contour_count,
		"linear_elevation_drawn_band_count": linear_elevation_last_drawn_band_count,
		"linear_elevation_drawn_contour_count": linear_elevation_last_drawn_contour_count,
		"linear_elevation_sample_count": linear_elevation_last_sample_count,
		"linear_elevation_alpha_span": linear_elevation_last_alpha_span,
		"linear_elevation_width_span": linear_elevation_last_width_span,
		"linear_elevation_mode": String(config.get("linear_elevation_mode", "lane_height_gradient")),
		"surface_alpha_gain": float(config.get("surface_alpha_gain", 1.0)),
		"surface_alpha_max": float(config.get("surface_alpha_max", 0.18)),
		"surface_color_gain": float(config.get("surface_color_gain", 1.0)),
		"grid_far_brightness": float(config.get("grid_far_brightness", config.get("surface_far_brightness", 0.52))),
		"grid_near_brightness": float(config.get("grid_near_brightness", config.get("surface_near_brightness", 0.88))),
		"unit_surface_far_brightness": float(config.get("unit_surface_far_brightness", 0.96)),
		"unit_surface_near_brightness": float(config.get("unit_surface_near_brightness", 1.12)),
		"z_index": z_index,
	}
