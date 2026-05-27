class_name MobiusWorld

const DEFAULT_LOOP_LENGTH := 24.0
const DEFAULT_STRIP_WIDTH := 10.0


static func _smooth01(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _periodic_distance(value: float, period: float) -> float:
	var safe_period := maxf(0.001, period)
	var wrapped := fposmod(value + safe_period * 0.5, safe_period) - safe_period * 0.5
	return absf(wrapped)


static func strip_half_width(config: Dictionary = {}) -> float:
	return maxf(0.001, float(config.get("strip_width", DEFAULT_STRIP_WIDTH)) * 0.5)


static func twist_angle(s: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> float:
	return PI * s / maxf(0.001, loop_length)


static func local_up_vector(s: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	var angle := twist_angle(s, loop_length)
	return Vector2(sin(angle), cos(angle)).normalized()


static func nearest_lifted_s(reference_s: float, ring_value: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> float:
	var loop := maxf(0.001, loop_length)
	var base := fposmod(ring_value, loop)
	var sheet := roundf((reference_s - base) / loop)
	return base + sheet * loop


static func lift_ring_lane_near(reference_s: float, ring_value: float, lane_value: float, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	var lifted_s := nearest_lifted_s(reference_s, ring_value, loop_length)
	var sheet := int(roundf((lifted_s - fposmod(ring_value, loop_length)) / maxf(0.001, loop_length)))
	var lifted_v := lane_value
	if abs(sheet) % 2 == 1:
		lifted_v = -lifted_v
	return Vector2(lifted_s, lifted_v)


static func normalize_lifted(coord: Vector2, config: Dictionary = {}) -> Vector2:
	return Vector2(coord.x, clampf(coord.y, -strip_half_width(config), strip_half_width(config)))


static func compatible_ring_lane(coord: Vector2, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	return Vector2(fposmod(coord.x, maxf(0.001, loop_length)), coord.y)


static func delta_vec(from_coord: Vector2, to_coord: Vector2, loop_length: float = DEFAULT_LOOP_LENGTH) -> Vector2:
	var loop := maxf(0.001, loop_length)
	var best := Vector2(to_coord.x - from_coord.x, to_coord.y - from_coord.y)
	var best_len_sq := best.length_squared()
	var center_sheet := int(roundf((from_coord.x - to_coord.x) / loop))
	for offset in range(-3, 4):
		var sheet := center_sheet + offset
		var candidate_s := to_coord.x + float(sheet) * loop
		var candidate_v := to_coord.y
		if abs(sheet) % 2 == 1:
			candidate_v = -candidate_v
		var candidate := Vector2(candidate_s - from_coord.x, candidate_v - from_coord.y)
		var candidate_len_sq := candidate.length_squared()
		if candidate_len_sq < best_len_sq:
			best = candidate
			best_len_sq = candidate_len_sq
	return best


static func default_config(loop_length: float, strip_width: float, view_width: float, view_height: float, screen_rect: Rect2) -> Dictionary:
	return {
		"enabled": true,
		"loop_length": maxf(0.001, loop_length),
		"strip_width": maxf(strip_width, sqrt(view_width * view_width + view_height * view_height)),
		"view_width": view_width,
		"view_height": view_height,
		"screen_rect": screen_rect,
		"near_scale": 1.22,
		"far_scale": 0.70,
		"depth_strength": 0.42,
		"parallax_strength": 0.28,
		"surface_segments": 96,
		"width_segments": 7,
		"boundary_fog_width": 0.75,
		"frame_rotation_strength": 0.48,
		"input_frame_strength": 0.34,
		"fairness_radius": 1.35,
		"edge_fog_width": 1.15,
		"surface_detail_density": 1.0,
		"near_alpha": 0.38,
		"far_alpha": 0.18,
		"depth_contrast": 1.0,
		"twist_visual_enabled": false,
		"twist_wave_amplitude": 0.18,
		"twist_wave_speed": 0.10,
		"twist_wave_scale": 1.35,
		"twist_pivot_influence": 0.34,
		"target_twist_pivot_influence": 0.34,
		"ridge_period": 1.92,
		"ridge_width": 1.0,
		"ridge_phase_speed": 0.12,
		"ridge_angle_speed": 0.035,
		"ridge_depth_strength": 1.0,
		"surface_span_multiplier": 1.5,
		"surface_perspective_strength": 0.34,
		"surface_twist_shear_strength": 0.17,
		"surface_ridge_lift_strength": 0.18,
		"surface_ridge_warp_amplitude": 0.125,
		"surface_twist_warp_strength": 0.035,
		"surface_far_brightness": 0.52,
		"surface_near_brightness": 0.88,
		"grid_far_brightness": 0.52,
		"grid_near_brightness": 0.88,
		"unit_surface_far_brightness": 0.96,
		"unit_surface_near_brightness": 1.12,
		"surface_projection_mode": "mobius_visual",
		"surface_grid_cell_px": 56.0,
	}


static func default_rotation_state(loop_length: float = DEFAULT_LOOP_LENGTH) -> Dictionary:
	return {
		"angle": 0.0,
		"angular_velocity": 0.0,
		"target_angular_velocity": 0.0,
		"twist_phase": 0.0,
		"twist_speed": 0.10,
		"target_twist_speed": 0.10,
		"twist_amplitude": 0.18,
		"target_twist_amplitude": 0.18,
		"ridge_phase": 0.0,
		"ridge_speed": 0.12,
		"target_ridge_speed": 0.12,
		"ridge_angle_phase": 0.0,
		"ridge_angle_speed": 0.035,
		"target_ridge_angle_speed": 0.035,
		"pivot": Vector2(loop_length * 0.5, 0.0),
		"target_pivot": Vector2(loop_length * 0.5, 0.0),
		"pivot_influence": 0.34,
		"target_pivot_influence": 0.34,
		"diagonal_phase": 0.0,
		"target_diagonal_phase": 0.0,
		"twist_direction": 1.0,
		"change_timer": 30.0,
	}


static func advance_twist_state(state: Dictionary, delta: float, config: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var blend_seconds := maxf(0.001, float(config.get("rotation_blend_seconds", 4.0)))
	var interval_min := maxf(0.1, float(config.get("rotation_interval_min", 30.0)))
	var interval_max := maxf(interval_min, float(config.get("rotation_interval_max", 60.0)))
	var loop := maxf(0.001, float(config.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var half_width := strip_half_width(config)
	var base_speed := maxf(0.0, float(config.get("twist_wave_speed", 0.10)))
	var speed_min := base_speed * 0.62
	var speed_max := base_speed * 1.38
	var amp_base := maxf(0.0, float(config.get("twist_wave_amplitude", 0.18)))
	var ridge_base_speed := maxf(0.0, float(config.get("ridge_phase_speed", base_speed * 1.2)))
	var ridge_angle_base_speed := maxf(0.0, float(config.get("ridge_angle_speed", 0.035)))
	var pivot_influence_base := clampf(float(config.get("twist_pivot_influence", 0.34)), 0.0, 0.85)
	var t := 1.0 - exp(-maxf(0.0, delta) / blend_seconds)
	next["angle"] = 0.0
	next["angular_velocity"] = 0.0
	next["target_angular_velocity"] = 0.0
	next["twist_speed"] = lerpf(float(next.get("twist_speed", base_speed)), float(next.get("target_twist_speed", base_speed)), t)
	next["twist_amplitude"] = lerpf(float(next.get("twist_amplitude", amp_base)), float(next.get("target_twist_amplitude", amp_base)), t)
	next["ridge_speed"] = lerpf(float(next.get("ridge_speed", ridge_base_speed)), float(next.get("target_ridge_speed", ridge_base_speed)), t)
	next["ridge_angle_speed"] = lerpf(float(next.get("ridge_angle_speed", ridge_angle_base_speed)), float(next.get("target_ridge_angle_speed", ridge_angle_base_speed)), t)
	next["pivot_influence"] = lerpf(float(next.get("pivot_influence", pivot_influence_base)), float(next.get("target_pivot_influence", pivot_influence_base)), t)
	next["pivot"] = Vector2(next.get("pivot", Vector2(loop * 0.5, 0.0))).lerp(Vector2(next.get("target_pivot", Vector2(loop * 0.5, 0.0))), t)
	next["twist_phase"] = wrapf(float(next.get("twist_phase", 0.0)) + float(next.get("twist_speed", base_speed)) * delta, -TAU, TAU)
	next["ridge_phase"] = wrapf(float(next.get("ridge_phase", 0.0)) + float(next.get("ridge_speed", ridge_base_speed)) * delta, -TAU, TAU)
	next["ridge_angle_phase"] = wrapf(float(next.get("ridge_angle_phase", next.get("diagonal_phase", 0.0))) + float(next.get("ridge_angle_speed", ridge_angle_base_speed)) * delta, -TAU, TAU)
	next["diagonal_phase"] = float(next.get("ridge_angle_phase", 0.0))
	next["change_timer"] = float(next.get("change_timer", interval_min)) - delta
	if float(next["change_timer"]) <= 0.0:
		var direction := -1.0 if randf() < 0.5 else 1.0
		next["twist_direction"] = direction
		var target_speed := randf_range(speed_min, speed_max) * direction
		if absf(target_speed - float(next.get("target_twist_speed", base_speed))) < speed_min * 0.18:
			target_speed = -target_speed
			next["twist_direction"] = signf(target_speed)
		next["target_twist_speed"] = target_speed
		next["target_ridge_speed"] = randf_range(ridge_base_speed * 0.70, ridge_base_speed * 1.45) * direction
		next["target_ridge_angle_speed"] = randf_range(ridge_angle_base_speed * 0.55, ridge_angle_base_speed * 1.40) * (-direction if randf() < 0.35 else direction)
		next["target_twist_amplitude"] = randf_range(amp_base * 0.72, amp_base * 1.35)
		next["target_pivot_influence"] = randf_range(pivot_influence_base * 0.66, minf(0.85, pivot_influence_base * 1.28))
		var previous_target := Vector2(next.get("target_pivot", Vector2(loop * 0.5, 0.0)))
		var target_pivot := Vector2(randf_range(0.0, loop), randf_range(-half_width * 0.55, half_width * 0.55))
		if target_pivot.distance_to(previous_target) < maxf(0.25, loop * 0.06):
			target_pivot.x = fposmod(target_pivot.x + loop * 0.37, loop)
			target_pivot.y = clampf(-target_pivot.y + half_width * 0.18, -half_width * 0.55, half_width * 0.55)
		next["target_pivot"] = target_pivot
		next["target_diagonal_phase"] = float(next.get("ridge_angle_phase", 0.0))
		next["change_timer"] = randf_range(interval_min, interval_max)
	return next


static func advance_rotation_state(state: Dictionary, delta: float, config: Dictionary) -> Dictionary:
	return advance_twist_state(state, delta, config)


static func advance_rotation_state_substepped(state: Dictionary, delta: float, config: Dictionary) -> Dictionary:
	var hz := maxf(1.0, float(config.get("mobius_visual_update_hz", config.get("visual_update_hz", 120.0))))
	var max_step := 1.0 / hz
	var remaining := maxf(0.0, delta)
	var next := state.duplicate(true)
	while remaining > 0.000001:
		var step := minf(max_step, remaining)
		next = advance_rotation_state(next, step, config)
		remaining -= step
	return next


static func boundary_softness(v: float, config: Dictionary = {}) -> float:
	var half_width := strip_half_width(config)
	var fog_width := maxf(0.001, float(config.get("edge_fog_width", config.get("boundary_fog_width", 0.75))))
	return clampf((half_width - absf(v)) / fog_width, 0.0, 1.0)


static func frame_at(coord: Vector2, camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
	var loop := maxf(0.001, float(config.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var screen_rect: Rect2 = config.get("screen_rect", Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)))
	var screen_scale := float(config.get("screen_scale", screen_rect.size.y / maxf(0.001, float(config.get("view_height", 5.2)))))
	var delta := delta_vec(camera_coord, coord, loop)
	var world_s := camera_coord.x + delta.x
	var half_width_units := maxf(0.001, screen_rect.size.x / maxf(0.001, screen_scale) * 0.5)
	var half_height_units := maxf(0.001, float(config.get("view_height", DEFAULT_STRIP_WIDTH)) * 0.5)
	var fairness_radius := maxf(0.001, float(config.get("fairness_radius", 1.35)))
	var fairness_blend := clampf(delta.length() / fairness_radius, 0.0, 1.0)
	fairness_blend = fairness_blend * fairness_blend * (3.0 - 2.0 * fairness_blend)
	var visual_axis_angle := 0.0
	var twist_phase := float(rotation_state.get("twist_phase", rotation_state.get("angle", 0.0)))
	var twist_amp := maxf(0.0, float(rotation_state.get("twist_amplitude", config.get("twist_wave_amplitude", 0.18))))
	var twist_scale := maxf(0.1, float(config.get("twist_wave_scale", 1.35)))
	if not bool(config.get("twist_visual_enabled", false)):
		twist_amp = 0.0
	var wave_arg := TAU * world_s / loop * twist_scale + twist_phase
	var camera_wave_arg := TAU * camera_coord.x / loop * twist_scale + twist_phase
	var visual_twist_wave := (sin(wave_arg) + sin(wave_arg * 0.43 - twist_phase * 0.7) * 0.42) * twist_amp
	var camera_twist_wave := (sin(camera_wave_arg) + sin(camera_wave_arg * 0.43 - twist_phase * 0.7) * 0.42) * twist_amp
	var pivot := Vector2(rotation_state.get("pivot", Vector2(loop * 0.5, 0.0)))
	pivot.x = nearest_lifted_s(camera_coord.x, pivot.x, loop)
	var pivot_delta := delta_vec(camera_coord, pivot, loop)
	var pivot_influence := clampf(float(rotation_state.get("pivot_influence", config.get("twist_pivot_influence", 0.34))), 0.0, 0.85)
	var phase := TAU * world_s / loop + visual_twist_wave
	var camera_phase := TAU * camera_coord.x / loop + camera_twist_wave
	var loop_depth := clampf(0.5 + cos(phase) * 0.5, 0.0, 1.0)
	var plane01 := Vector2(
		clampf(delta.x / half_width_units, -1.35, 1.35),
		clampf(delta.y / half_height_units, -1.35, 1.35)
	)
	var pivot_bias := Vector2(
		clampf(-pivot_delta.x / half_width_units, -1.0, 1.0),
		clampf(-pivot_delta.y / half_height_units, -1.0, 1.0)
	) * pivot_influence
	var ridge_phase := float(rotation_state.get("ridge_phase", twist_phase))
	var ridge_angle_phase := float(rotation_state.get("ridge_angle_phase", rotation_state.get("diagonal_phase", 0.0)))
	var diagonal_phase := ridge_angle_phase
	var diagonal_angle := PI * 0.25 + ridge_angle_phase
	var ridge_normal := Vector2(cos(diagonal_angle), sin(diagonal_angle)).normalized()
	var ridge_period := maxf(0.25, float(config.get("ridge_period", 1.92)))
	var ridge_width := clampf(float(config.get("ridge_width", 1.0)), 0.12, 1.0)
	var ridge_offset := ridge_period * 0.5 + ridge_phase / TAU * ridge_period
	var ridge_coord := (plane01 + pivot_bias).dot(ridge_normal) + ridge_offset
	var ridge_distance := _periodic_distance(ridge_coord, ridge_period)
	var ridge_distance01 := clampf(ridge_distance / (ridge_period * 0.5), 0.0, 1.0)
	var ridge_depth := 1.0 - _smooth01(clampf(ridge_distance01 / ridge_width, 0.0, 1.0))
	var diagonal_saddle := clampf(ridge_depth * 2.0 - 1.0, -1.0, 1.0)
	var diagonal_depth := ridge_depth
	var depth_strength := float(config.get("depth_strength", 0.42))
	var diagonal_weight := clampf(float(config.get("ridge_depth_strength", 1.0)), 0.0, 1.0)
	if bool(config.get("local_rectangular_projection", false)):
		diagonal_weight *= lerpf(0.18, 1.0, fairness_blend)
	var depth_contrast := maxf(0.1, float(config.get("depth_contrast", 1.0)))
	var depth01 := clampf(lerpf(loop_depth, diagonal_depth, diagonal_weight), 0.0, 1.0)
	depth01 = clampf(0.5 + (depth01 - 0.5) * depth_contrast, 0.0, 1.0)
	var near_scale := maxf(0.01, float(config.get("near_scale", 1.22)))
	var far_scale := maxf(0.01, float(config.get("far_scale", 0.70)))
	var visual_scale := lerpf(far_scale, near_scale, depth01)
	var twist := twist_angle(world_s, loop) + visual_twist_wave
	var tangent_screen := Vector2(1.0, cos(phase) * 0.14 * depth_strength + cos(wave_arg) * twist_amp * 0.08).normalized()
	var width_screen := Vector2(sin(twist) * 0.28, visual_scale * (0.82 + depth01 * 0.18)).normalized()
	if tangent_screen.length() <= 0.001:
		tangent_screen = Vector2.RIGHT
	if width_screen.length() <= 0.001:
		width_screen = Vector2.DOWN
	return {
		"coord": coord,
		"camera_coord": camera_coord,
		"delta": delta,
		"world_s": world_s,
		"loop": loop,
		"screen_rect": screen_rect,
		"screen_scale": screen_scale,
		"depth01": depth01,
		"scale": visual_scale,
		"z_index": int(round(lerpf(-18.0, 42.0, depth01))),
		"twist_angle": twist,
		"local_up": local_up_vector(world_s, loop),
		"tangent": Vector2(1.0, 0.0),
		"width_axis": Vector2(0.0, 1.0),
		"tangent_screen": tangent_screen,
		"width_screen": width_screen,
		"screen_basis": {"tangent": tangent_screen, "width": width_screen},
		"boundary_softness": boundary_softness(coord.y, config),
		"diagonal_depth": diagonal_depth,
		"diagonal_saddle": diagonal_saddle,
		"loop_depth": loop_depth,
		"phase": phase,
		"camera_phase": camera_phase,
		"visual_axis_angle": visual_axis_angle,
		"fairness_blend": fairness_blend,
		"pivot": pivot,
		"pivot_delta": pivot_delta,
		"diagonal_phase": diagonal_phase,
		"diagonal_angle": diagonal_angle,
		"ridge_phase": ridge_phase,
		"ridge_angle_phase": ridge_angle_phase,
		"ridge_normal": ridge_normal,
		"ridge_period": ridge_period,
		"ridge_width": ridge_width,
		"ridge_offset": ridge_offset,
		"ridge_coord": ridge_coord,
		"ridge_distance": ridge_distance,
		"ridge_distance01": ridge_distance01,
		"ridge_depth": ridge_depth,
		"pivot_bias": pivot_bias,
		"twist_phase": twist_phase,
		"visual_twist_wave": visual_twist_wave,
	}


static func surface_field_at(coord: Vector2, camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
	var surface_config := config.duplicate(true)
	surface_config["local_rectangular_projection"] = false
	var frame := frame_at(coord, camera_coord, surface_config, rotation_state)
	var depth01 := clampf(float(frame.get("depth01", 0.5)), 0.0, 1.0)
	var grid_far_brightness := maxf(0.0, float(config.get("grid_far_brightness", config.get("surface_far_brightness", 0.52))))
	var grid_near_brightness := maxf(grid_far_brightness, float(config.get("grid_near_brightness", config.get("surface_near_brightness", 0.88))))
	var unit_far_brightness := maxf(0.0, float(config.get("unit_surface_far_brightness", 0.96)))
	var unit_near_brightness := maxf(unit_far_brightness, float(config.get("unit_surface_near_brightness", 1.12)))
	var grid_brightness := lerpf(grid_far_brightness, grid_near_brightness, depth01)
	var unit_brightness := lerpf(unit_far_brightness, unit_near_brightness, depth01)
	return {
		"depth01": depth01,
		"surface_depth01": depth01,
		"ridge_depth": float(frame.get("ridge_depth", depth01)),
		"surface_scale": float(frame.get("scale", 1.0)),
		"scale": float(frame.get("scale", 1.0)),
		"brightness": unit_brightness,
		"unit_brightness": unit_brightness,
		"grid_brightness": grid_brightness,
		"z_index": int(frame.get("z_index", 0)),
		"ridge_normal": frame.get("ridge_normal", Vector2(0.707, 0.707)),
		"ridge_period": float(frame.get("ridge_period", 1.92)),
		"ridge_width": float(frame.get("ridge_width", 1.0)),
		"ridge_offset": float(frame.get("ridge_offset", 0.0)),
		"ridge_distance": float(frame.get("ridge_distance", 0.0)),
		"ridge_distance01": float(frame.get("ridge_distance01", 0.0)),
		"pivot_bias": frame.get("pivot_bias", Vector2.ZERO),
		"twist_angle": float(frame.get("twist_angle", 0.0)),
		"twist_phase": float(frame.get("twist_phase", 0.0)),
		"visual_twist_wave": float(frame.get("visual_twist_wave", 0.0)),
		"boundary_softness": float(frame.get("boundary_softness", 1.0)),
		"local_up": frame.get("local_up", Vector2.UP),
	}


static func project_gameplay_anchor_to_screen(coord: Vector2, camera_coord: Vector2, config: Dictionary) -> Dictionary:
	var loop := maxf(0.001, float(config.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var screen_rect: Rect2 = config.get("screen_rect", Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)))
	var screen_scale := float(config.get("screen_scale", screen_rect.size.y / maxf(0.001, float(config.get("view_height", 5.2)))))
	var delta := delta_vec(camera_coord, coord, loop)
	var pos := screen_rect.get_center() + delta * screen_scale
	var margin := maxf(96.0, screen_scale * 0.8)
	var visible := pos.x >= screen_rect.position.x - margin and pos.x <= screen_rect.end.x + margin and pos.y >= screen_rect.position.y - margin and pos.y <= screen_rect.end.y + margin
	return {"position": pos, "visible": visible, "delta": delta}


static func surface_shader_parameters(camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
	var loop := maxf(0.001, float(config.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var screen_rect: Rect2 = config.get("screen_rect", Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)))
	var screen_scale := float(config.get("screen_scale", screen_rect.size.y / maxf(0.001, float(config.get("view_height", 5.2)))))
	var center_field := surface_field_at(camera_coord, camera_coord, config, rotation_state)
	return {
		"camera_surface_coord": camera_coord,
		"surface_view_world_size": Vector2(screen_rect.size.x / maxf(0.001, screen_scale), float(config.get("view_height", 5.2))),
		"loop_length": loop,
		"grid_cell_world": maxf(0.01, float(config.get("surface_grid_cell_px", 32.0)) / maxf(0.001, screen_scale)),
		"ridge_normal": center_field.get("ridge_normal", Vector2(0.707, 0.707)),
		"ridge_period": float(center_field.get("ridge_period", 1.92)),
		"ridge_width": float(center_field.get("ridge_width", 1.0)),
		"ridge_offset": float(center_field.get("ridge_offset", 0.0)),
		"ridge_pivot_bias": center_field.get("pivot_bias", Vector2.ZERO),
		"ridge_warp_amplitude": clampf(float(config.get("surface_ridge_warp_amplitude", 0.125)), 0.0, 0.20),
		"twist_shear_strength": clampf(float(config.get("surface_twist_shear_strength", 0.17)), 0.0, 0.28),
		"twist_warp_strength": clampf(float(config.get("surface_twist_warp_strength", 0.035)), 0.0, 0.12),
		"far_brightness": float(config.get("grid_far_brightness", config.get("surface_far_brightness", 0.52))),
		"near_brightness": float(config.get("grid_near_brightness", config.get("surface_near_brightness", 0.88))),
		"grid_far_brightness": float(config.get("grid_far_brightness", config.get("surface_far_brightness", 0.52))),
		"grid_near_brightness": float(config.get("grid_near_brightness", config.get("surface_near_brightness", 0.88))),
	}


static func surface_sample_coord_from_screen_uv(screen_uv: Vector2, camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
	var params := surface_shader_parameters(camera_coord, config, rotation_state)
	var plane := screen_uv * 2.0 - Vector2.ONE
	var ridge_normal: Vector2 = Vector2(params.get("ridge_normal", Vector2(0.707, 0.707))).normalized()
	var tangent_axis := Vector2(-ridge_normal.y, ridge_normal.x)
	var ridge_period := maxf(0.001, float(params.get("ridge_period", 1.92)))
	var ridge_width := maxf(0.001, float(params.get("ridge_width", 1.0)))
	var ridge_coord := (plane + Vector2(params.get("ridge_pivot_bias", Vector2.ZERO))).dot(ridge_normal) + float(params.get("ridge_offset", 0.0))
	var ridge_distance := _periodic_distance(ridge_coord, ridge_period)
	var ridge_distance01 := clampf(ridge_distance / (ridge_period * 0.5), 0.0, 1.0)
	var ridge_depth := 1.0 - _smooth01(clampf(ridge_distance01 / ridge_width, 0.0, 1.0))
	var depth01 := clampf(0.5 + (ridge_depth - 0.5) * float(config.get("depth_contrast", 1.0)), 0.0, 1.0)
	var ridge_wave := sin(TAU * ridge_coord / ridge_period)
	var sampled_plane := plane - ridge_normal * ridge_wave * float(params.get("ridge_warp_amplitude", 0.125))
	var world_size: Vector2 = params.get("surface_view_world_size", Vector2(7.2, 5.2))
	var preliminary_s := camera_coord.x + sampled_plane.x * world_size.x * 0.5
	var mobius_twist := PI * preliminary_s / maxf(0.001, float(params.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var twist_phase := float(rotation_state.get("twist_phase", rotation_state.get("angle", 0.0)))
	var u_shear := sin(mobius_twist + twist_phase) * ridge_wave * float(params.get("twist_shear_strength", 0.17))
	var v_warp := sin(mobius_twist * 2.0 + twist_phase) * ridge_wave * float(params.get("twist_warp_strength", 0.035))
	sampled_plane += tangent_axis * u_shear + ridge_normal * v_warp
	var surface_coord := camera_coord + sampled_plane * world_size * 0.5
	var grid_cell_world := maxf(0.001, float(params.get("grid_cell_world", 0.16)))
	return {
		"surface_coord": surface_coord,
		"ridge_coord": ridge_coord,
		"ridge_distance01": ridge_distance01,
		"ridge_depth": ridge_depth,
		"depth01": depth01,
		"brightness": lerpf(float(params.get("grid_far_brightness", params.get("far_brightness", 0.52))), float(params.get("grid_near_brightness", params.get("near_brightness", 0.88))), depth01),
		"grid_coord": surface_coord / grid_cell_world,
		"u_shear": u_shear,
		"v_warp": v_warp,
	}


static func project_to_screen(coord: Vector2, camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
	if bool(config.get("local_rectangular_projection", false)):
		var anchor := project_gameplay_anchor_to_screen(coord, camera_coord, config)
		var field := surface_field_at(coord, camera_coord, config, rotation_state)
		for key in anchor.keys():
			field[key] = anchor[key]
		return field
	var frame := frame_at(coord, camera_coord, config, rotation_state)
	var screen_rect: Rect2 = frame.get("screen_rect", Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)))
	var screen_scale := float(frame.get("screen_scale", 1.0))
	var delta: Vector2 = frame.get("delta", Vector2.ZERO)
	var visual_scale := float(frame.get("scale", 1.0))
	var depth01 := float(frame.get("depth01", 0.5))
	var twist := float(frame.get("twist_angle", 0.0))
	var phase := float(frame.get("phase", 0.0))
	var camera_phase := float(frame.get("camera_phase", 0.0))
	var diagonal_saddle := float(frame.get("diagonal_saddle", 0.0))
	var depth_strength := float(config.get("depth_strength", 0.42))
	var center := screen_rect.get_center()
	var pos: Vector2
	var perspective_strength := clampf(float(config.get("surface_perspective_strength", 0.34)), 0.0, 1.0)
	var uniform_scale := lerpf(1.0, visual_scale, perspective_strength)
	var base_pos := Vector2(delta.x, delta.y) * screen_scale * uniform_scale
	var shear_strength := float(config.get("surface_twist_shear_strength", 0.17))
	var lift_strength := float(config.get("surface_ridge_lift_strength", 0.18))
	var twist_x := sin(twist) * delta.y * screen_scale * shear_strength * depth_strength
	var ridge_lift := (depth01 - 0.5) * screen_rect.size.y * lift_strength * depth_strength
	var ridge_normal: Vector2 = frame.get("ridge_normal", Vector2(0.707, 0.707))
	var curve_y := (sin(phase) - sin(camera_phase)) * screen_rect.size.y * 0.045 * depth_strength
	pos = center + base_pos + Vector2(twist_x, curve_y) + ridge_normal * ridge_lift
	var margin := maxf(96.0, screen_scale * 0.8)
	var visible := pos.x >= screen_rect.position.x - margin and pos.x <= screen_rect.end.x + margin and pos.y >= screen_rect.position.y - margin and pos.y <= screen_rect.end.y + margin
	return {
		"position": pos,
		"visible": visible,
		"depth01": depth01,
		"scale": visual_scale,
		"z_index": int(frame.get("z_index", int(round(lerpf(-18.0, 42.0, depth01))))),
		"twist_angle": twist,
		"local_up": frame.get("local_up", Vector2.UP),
		"delta": delta,
		"diagonal_depth": frame.get("diagonal_depth", depth01),
		"boundary_softness": frame.get("boundary_softness", 1.0),
		"tangent_screen": frame.get("tangent_screen", Vector2.RIGHT),
		"width_screen": frame.get("width_screen", Vector2.DOWN),
		"screen_basis": frame.get("screen_basis", {}),
		"pivot": frame.get("pivot", Vector2.ZERO),
		"visual_twist_wave": frame.get("visual_twist_wave", 0.0),
		"ridge_depth": frame.get("ridge_depth", depth01),
		"ridge_distance01": frame.get("ridge_distance01", 0.0),
		"ridge_coord": frame.get("ridge_coord", 0.0),
		"ridge_normal": frame.get("ridge_normal", Vector2(0.707, 0.707)),
		"world_s": frame.get("world_s", coord.x),
	}


static func screen_input_to_surface_motion(input_vector: Vector2, coord: Vector2, camera_coord: Vector2, config: Dictionary = {}, rotation_state: Dictionary = {}) -> Vector2:
	if input_vector.length() <= 0.04:
		return Vector2.ZERO
	var desired := input_vector.normalized()
	var stable_config := config.duplicate(true)
	stable_config["twist_visual_enabled"] = false
	var frame := frame_at(coord, camera_coord, stable_config, rotation_state)
	var tangent_screen: Vector2 = frame.get("tangent_screen", Vector2.RIGHT)
	var width_screen: Vector2 = frame.get("width_screen", Vector2.DOWN)
	var projected := Vector2(desired.dot(tangent_screen), desired.dot(width_screen))
	if projected.length() <= 0.001:
		projected = desired
	else:
		projected = projected.normalized()
	var strength := clampf(float(config.get("input_frame_strength", 0.34)), 0.0, 0.82)
	var mixed := desired.lerp(projected, strength)
	if mixed.length() <= 0.001:
		return Vector2.ZERO
	return mixed.normalized() * clampf(input_vector.length(), 0.0, 1.0)


static func surface_sample_grid(camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Array:
	var loop := maxf(0.001, float(config.get("loop_length", DEFAULT_LOOP_LENGTH)))
	var half_width := strip_half_width(config)
	var detail_density := clampf(float(config.get("surface_detail_density", 1.0)), 0.5, 2.0)
	var surface_segments := clampi(int(round(float(config.get("surface_segments", 96)) * detail_density)), 16, 192)
	var width_segments := clampi(int(config.get("width_segments", 7)), 3, 15)
	var view_width := maxf(1.0, float(config.get("view_width", 7.2)))
	var span := view_width * maxf(1.0, float(config.get("surface_span_multiplier", 1.5)))
	var samples: Array = []
	for i in range(surface_segments):
		var t0 := float(i) / float(surface_segments)
		var t1 := float(i + 1) / float(surface_segments)
		var s0 := camera_coord.x + lerpf(-span, span, t0)
		var s1 := camera_coord.x + lerpf(-span, span, t1)
		for j in range(width_segments):
			var w0 := float(j) / float(width_segments)
			var w1 := float(j + 1) / float(width_segments)
			var v0 := lerpf(-half_width, half_width, w0)
			var v1 := lerpf(-half_width, half_width, w1)
			var p00 := project_to_screen(Vector2(s0, v0), camera_coord, config, rotation_state)
			var p10 := project_to_screen(Vector2(s1, v0), camera_coord, config, rotation_state)
			var p11 := project_to_screen(Vector2(s1, v1), camera_coord, config, rotation_state)
			var p01 := project_to_screen(Vector2(s0, v1), camera_coord, config, rotation_state)
			var avg_depth := (float(p00.get("depth01", 0.5)) + float(p10.get("depth01", 0.5)) + float(p11.get("depth01", 0.5)) + float(p01.get("depth01", 0.5))) * 0.25
			var center_v := (v0 + v1) * 0.5
			var edge_softness := minf(boundary_softness(v0, config), boundary_softness(v1, config))
			var u0 := s0 / loop
			var u1 := s1 / loop
			samples.append({
				"poly": PackedVector2Array([
					p00.get("position", Vector2.ZERO),
					p10.get("position", Vector2.ZERO),
					p11.get("position", Vector2.ZERO),
					p01.get("position", Vector2.ZERO),
				]),
				"uvs": PackedVector2Array([
					Vector2(u0, w0),
					Vector2(u1, w0),
					Vector2(u1, w1),
					Vector2(u0, w1),
				]),
				"avg_depth": avg_depth,
				"edge_softness": edge_softness,
				"stripe": 0.0,
				"surface_kind": "square_grid_field",
				"projection_mode": "mobius_visual",
				"center": Vector2((s0 + s1) * 0.5, center_v),
				"z_index": int(round(lerpf(-18.0, 42.0, avg_depth))),
			})
	return samples


static func screen_input_to_local(input_vector: Vector2, _coord: Vector2, _config: Dictionary = {}, _rotation_state: Dictionary = {}) -> Vector2:
	return input_vector
