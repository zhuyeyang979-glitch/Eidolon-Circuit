class_name MobiusWorld

const DEFAULT_LOOP_LENGTH := 24.0
const DEFAULT_STRIP_WIDTH := 10.0


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
		"pivot": Vector2(loop_length * 0.5, 0.0),
		"target_pivot": Vector2(loop_length * 0.5, 0.0),
		"change_timer": 30.0,
	}


static func advance_twist_state(state: Dictionary, delta: float, config: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var blend_seconds := maxf(0.001, float(config.get("rotation_blend_seconds", 4.0)))
	var interval_min := maxf(0.1, float(config.get("rotation_interval_min", 30.0)))
	var interval_max := maxf(interval_min, float(config.get("rotation_interval_max", 60.0)))
	var base_speed := maxf(0.0, float(config.get("twist_wave_speed", 0.10)))
	var speed_min := base_speed * 0.62
	var speed_max := base_speed * 1.38
	var amp_base := maxf(0.0, float(config.get("twist_wave_amplitude", 0.18)))
	var t := 1.0 - exp(-maxf(0.0, delta) / blend_seconds)
	next["angle"] = 0.0
	next["angular_velocity"] = 0.0
	next["target_angular_velocity"] = 0.0
	next["twist_speed"] = lerpf(float(next.get("twist_speed", base_speed)), float(next.get("target_twist_speed", base_speed)), t)
	next["twist_amplitude"] = lerpf(float(next.get("twist_amplitude", amp_base)), float(next.get("target_twist_amplitude", amp_base)), t)
	next["pivot"] = Vector2(next.get("pivot", Vector2.ZERO)).lerp(Vector2(next.get("target_pivot", Vector2.ZERO)), t)
	next["twist_phase"] = wrapf(float(next.get("twist_phase", 0.0)) + float(next.get("twist_speed", base_speed)) * delta, -TAU, TAU)
	next["change_timer"] = float(next.get("change_timer", interval_min)) - delta
	if float(next["change_timer"]) <= 0.0:
		next["target_twist_speed"] = randf_range(speed_min, speed_max)
		next["target_twist_amplitude"] = randf_range(amp_base * 0.72, amp_base * 1.22)
		next["target_pivot"] = Vector2(float(config.get("loop_length", DEFAULT_LOOP_LENGTH)) * 0.5, 0.0)
		next["change_timer"] = randf_range(interval_min, interval_max)
	return next


static func advance_rotation_state(state: Dictionary, delta: float, config: Dictionary) -> Dictionary:
	return advance_twist_state(state, delta, config)


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
	var phase := TAU * world_s / loop + visual_twist_wave
	var camera_phase := TAU * camera_coord.x / loop + camera_twist_wave
	var loop_depth := clampf(0.5 + cos(phase) * 0.5, 0.0, 1.0)
	var plane01 := Vector2(
		clampf(delta.x / half_width_units, -1.35, 1.35),
		clampf(delta.y / half_height_units, -1.35, 1.35)
	)
	var diagonal_saddle := clampf(plane01.x * plane01.y + visual_twist_wave * 0.16, -1.0, 1.0)
	var diagonal_depth := clampf(0.5 + diagonal_saddle * 0.5, 0.0, 1.0)
	var depth_strength := float(config.get("depth_strength", 0.42))
	var diagonal_weight := clampf(0.28 + plane01.length() / sqrt(2.0) * 0.58, 0.28, 0.86)
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
		"pivot": Vector2(loop * 0.5, 0.0),
		"pivot_delta": Vector2.ZERO,
		"twist_phase": twist_phase,
		"visual_twist_wave": visual_twist_wave,
	}


static func project_to_screen(coord: Vector2, camera_coord: Vector2, config: Dictionary, rotation_state: Dictionary = {}) -> Dictionary:
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
	if bool(config.get("local_rectangular_projection", false)):
		pos = center + Vector2(delta.x * screen_scale, delta.y * screen_scale)
	else:
		var perspective_x := delta.x * screen_scale * (0.78 + visual_scale * 0.22)
		var twist_x := sin(twist) * delta.y * screen_scale * 0.22
		var curve_y := (sin(phase) - sin(camera_phase)) * screen_rect.size.y * 0.14 * depth_strength
		curve_y += diagonal_saddle * screen_rect.size.y * 0.045 * depth_strength
		var perspective_y := delta.y * screen_scale * visual_scale * (0.82 + depth01 * 0.18)
		pos = center + Vector2(perspective_x + twist_x, perspective_y + curve_y)
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
	var span := view_width * 1.22
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
			var edge_softness := boundary_softness(center_v, config)
			var stripe_phase := float(rotation_state.get("twist_phase", 0.0))
			var stripe := 0.5 + 0.5 * sin((s0 / loop) * TAU * 16.0 + float(j) * 0.7 + stripe_phase * 0.55)
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
				"stripe": stripe,
				"center": Vector2((s0 + s1) * 0.5, center_v),
				"z_index": int(round(lerpf(-18.0, 42.0, avg_depth))),
			})
	return samples


static func screen_input_to_local(input_vector: Vector2, _coord: Vector2, _config: Dictionary = {}, _rotation_state: Dictionary = {}) -> Vector2:
	return input_vector
