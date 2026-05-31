class_name ProjectileTraceEffect
extends Node2D

var start_point := Vector2.ZERO
var end_point := Vector2.RIGHT
var damage_type := "bullet"
var projectile_style := "bullet"
var travel_path := "straight"
var projectile_speed_mult := 2.8
var lifetime := 0.0
var max_lifetime := 0.22
var vfx_texture: Texture2D

func setup(next_start: Vector2, next_end: Vector2, next_damage_type: String, next_style: String, next_path: String, next_vfx_texture: Texture2D = null, next_speed_mult: float = 2.8) -> void:
	start_point = next_start
	end_point = next_end
	damage_type = next_damage_type
	projectile_style = next_style
	travel_path = next_path
	projectile_speed_mult = clampf(next_speed_mult, 0.35, 2.4) if next_damage_type == "chemical" else clampf(next_speed_mult, 1.5, 5.0)
	vfx_texture = next_vfx_texture
	max_lifetime = 0.34
	if projectile_style in ["beam", "rail", "chaos"] or travel_path == "instant_line":
		max_lifetime = 0.18
	elif projectile_style == "true_bullet":
		max_lifetime = 0.16
	elif projectile_style == "bullet_hell":
		max_lifetime = clampf(0.92 / projectile_speed_mult, 0.18, 0.62)
	elif projectile_style in ["explosive", "blast"]:
		max_lifetime = 0.5
	elif projectile_style == "missile" or travel_path in ["arc_u", "homing"]:
		max_lifetime = 0.42
	elif projectile_style == "spray" or damage_type == "chemical":
		max_lifetime = clampf(0.92 / maxf(0.35, projectile_speed_mult), 0.62, 1.55)
	lifetime = max_lifetime
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(lifetime / max_lifetime, 0.0, 1.0)
	var inv := 1.0 - ratio
	var color := _trace_color()
	var points := _trace_points(inv)
	if points.size() < 2:
		return
	if projectile_style in ["beam", "rail", "chaos"] or damage_type == "laser":
		var beam_points := _prefix_points(points, clampf(inv * 2.8 + 0.04, 0.04, 1.0))
		draw_polyline(beam_points, Color(color.r, color.g, color.b, 0.22 * ratio), 13.0)
		draw_polyline(beam_points, Color(0.82, 0.96, 1.0, 0.9 * ratio), 4.0)
		draw_polyline(beam_points, Color.WHITE, 1.6)
		_draw_vfx_cell(2, _point_on_points(beam_points, 0.5), Vector2(maxf(46.0, _polyline_length(beam_points)), 54.0), (end_point - start_point).angle(), ratio * 0.62)
		for point in beam_points:
			draw_circle(point, 3.0 + 5.0 * inv, Color(0.86, 0.98, 1.0, 0.32 * ratio))
		return
	if projectile_style == "spray" or damage_type == "chemical":
		if travel_path in ["firework", "burst", "shotgun"]:
			_draw_chemical_firework(points, ratio, inv, color)
			return
		draw_polyline(points, Color(0.46, 1.0, 0.2, 0.42 * ratio), 9.0)
		draw_polyline(points, Color(1.0, 0.92, 0.16, 0.68 * ratio), 3.0)
		_draw_vfx_cell(4, _point_on_points(points, clampf(inv * 1.12, 0.0, 1.0)), Vector2.ONE * 76.0, (end_point - start_point).angle(), ratio * 0.76)
		for i in range(14):
			var t := fmod(float(i) / 14.0 + inv * 0.9, 1.0)
			var p := _point_on_points(points, t)
			var wobble := Vector2(sin(t * TAU * 3.0), cos(t * TAU * 2.0)) * (5.0 + float(i % 3) * 2.5)
			draw_circle(p + wobble, 3.0 + float(i % 4), Color(0.74, 1.0, 0.18, 0.34 * ratio))
		return
	if projectile_style == "web" or projectile_style == "chain":
		draw_polyline(points, Color(0.86, 0.98, 1.0, 0.76 * ratio), 2.8)
		_draw_vfx_cell(14, _point_on_points(points, clampf(inv, 0.0, 1.0)), Vector2.ONE * 48.0, 0.0, ratio * 0.72)
		for i in range(9):
			var t := float(i) / 8.0
			var p := _point_on_points(points, t)
			draw_circle(p, 3.0, Color(0.9, 1.0, 1.0, 0.5 * ratio))
		return
	if projectile_style == "missile":
		draw_polyline(points, Color(1.0, 0.48, 0.08, 0.56 * ratio), 5.0)
		draw_polyline(points, Color(1.0, 0.9, 0.22, 0.38 * ratio), 2.0)
		var head := _point_on_points(points, clampf(inv * 1.35, 0.0, 1.0))
		var dir := (end_point - start_point).normalized()
		if dir.length() <= 0.01:
			dir = Vector2.RIGHT
		var right := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([head + dir * 12.0, head - dir * 8.0 + right * 5.0, head - dir * 8.0 - right * 5.0]), Color(1.0, 0.86, 0.32, 0.9 * ratio))
		draw_circle(head - dir * 14.0, 7.0, Color(1.0, 0.28, 0.04, 0.42 * ratio))
		_draw_vfx_cell(12, head - dir * 10.0, Vector2.ONE * 64.0, dir.angle(), ratio * 0.7)
		return
	if projectile_style in ["explosive", "blast"]:
		draw_polyline(points, Color(1.0, 0.34, 0.04, 0.62 * ratio), 9.0)
		draw_polyline(points, Color(1.0, 0.86, 0.18, 0.58 * ratio), 3.2)
		var shell_t := clampf(inv * 1.08, 0.0, 1.0)
		var head := _point_on_points(points, shell_t)
		var dir := (end_point - start_point).normalized()
		if dir.length() <= 0.01:
			dir = Vector2.RIGHT
		var right := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([
			head + dir * 15.0,
			head - dir * 10.0 + right * 7.0,
			head - dir * 14.0,
			head - dir * 10.0 - right * 7.0,
		]), Color(0.92, 0.22, 0.08, 0.96 * ratio))
		draw_circle(head - dir * 14.0, 10.0 + 8.0 * inv, Color(1.0, 0.5, 0.05, 0.34 * ratio))
		draw_circle(head, 5.5, Color(1.0, 0.95, 0.55, 0.92 * ratio))
		_draw_vfx_cell(12, head - dir * 8.0, Vector2.ONE * 82.0, dir.angle(), ratio * 0.78)
		return
	if projectile_style == "true_bullet":
		var bullet_points := _prefix_points(points, clampf(inv * 3.4 + 0.1, 0.1, 1.0))
		var dir := (end_point - start_point).normalized()
		if dir.length() <= 0.01:
			dir = Vector2.RIGHT
		var head := bullet_points[bullet_points.size() - 1]
		draw_polyline(bullet_points, Color(1.0, 0.82, 0.34, 0.22 * ratio), 8.0)
		draw_polyline(bullet_points, Color(1.0, 0.96, 0.72, 0.84 * ratio), 2.2)
		draw_circle(head, 5.0 + inv * 7.0, Color(1.0, 0.93, 0.56, 0.86 * ratio))
		_draw_vfx_cell(0, head, Vector2.ONE * 52.0, dir.angle(), ratio * 0.84)
		return
	if projectile_style == "bullet_hell":
		var travel := clampf(inv * 1.1, 0.0, 1.0)
		var head := _point_on_points(points, travel)
		var dir := (end_point - start_point).normalized()
		if dir.length() <= 0.01:
			dir = Vector2.RIGHT
		var tail := _point_on_points(points, maxf(0.0, travel - 0.16))
		draw_line(tail, head, Color(1.0, 0.62, 0.16, 0.58 * ratio), 5.0)
		draw_circle(head, 8.0, Color(1.0, 0.5, 0.08, 0.92 * ratio))
		draw_circle(head, 3.2, Color(1.0, 0.98, 0.78, 0.95 * ratio))
		_draw_vfx_cell(0, head, Vector2.ONE * 38.0, dir.angle(), ratio * 0.66)
		return
	draw_polyline(points, Color(1.0, 0.58, 0.12, 0.5 * ratio), 5.0)
	draw_polyline(points, Color(1.0, 0.96, 0.74, 0.88 * ratio), 1.8)
	_draw_vfx_cell(0, _point_on_points(points, clampf(inv * 1.2, 0.0, 1.0)), Vector2.ONE * 46.0, (end_point - start_point).angle(), ratio * 0.78)
	for i in range(5):
		var t := fmod(float(i) / 5.0 + inv * 1.6, 1.0)
		var p := _point_on_points(points, t)
		draw_circle(p, 3.0 + float(i % 2), Color(1.0, 0.78, 0.24, 0.76 * ratio))

func _trace_color() -> Color:
	match damage_type:
		"laser":
			return Color(0.25, 0.82, 1.0, 1.0)
		"chemical":
			return Color(0.72, 1.0, 0.16, 1.0)
		"bullet":
			return Color(1.0, 0.48, 0.1, 1.0)
		"explosive":
			return Color(1.0, 0.36, 0.04, 1.0)
	return Color(0.9, 0.95, 1.0, 1.0)

func _trace_points(inv: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 18
	for i in range(segments):
		var t := float(i) / float(segments - 1)
		var p := start_point.lerp(end_point, t)
		points.append(p)
	return points

func _draw_chemical_firework(points: PackedVector2Array, ratio: float, inv: float, color: Color) -> void:
	var start := points[0]
	var end := points[points.size() - 1]
	var base_dir := (end - start).normalized()
	if base_dir.length() <= 0.01:
		base_dir = Vector2.RIGHT
	var origin := start.lerp(end, clampf(inv * 0.88, 0.0, 1.0))
	for i in range(7):
		var spread := (float(i) - 3.0) * 0.16
		var dir := base_dir.rotated(spread)
		var reach := 42.0 + float(i % 3) * 12.0
		var pellet_head := origin + dir * reach * clampf(inv * 1.15, 0.0, 1.0)
		draw_line(origin, pellet_head, Color(0.46, 1.0, 0.2, 0.22 * ratio), 6.0)
		draw_line(origin, pellet_head, Color(1.0, 0.92, 0.16, 0.46 * ratio), 2.0)
		draw_circle(pellet_head, 4.0 + float(i % 2) * 2.0, Color(color.r, color.g, color.b, 0.48 * ratio))
	_draw_vfx_cell(4, origin, Vector2.ONE * 86.0, base_dir.angle(), ratio * 0.72)

func _draw_vfx_cell(index: int, center: Vector2, draw_size: Vector2, angle: float, alpha: float) -> void:
	if vfx_texture == null:
		return
	var cell := vfx_texture.get_size() / 4.0
	var safe_index := clampi(index, 0, 15)
	var region := Rect2(Vector2(float(safe_index % 4) * cell.x, float(safe_index / 4) * cell.y), cell)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect_region(vfx_texture, Rect2(-draw_size * 0.5, draw_size), region, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _point_on_points(points: PackedVector2Array, t: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled := clampf(t, 0.0, 1.0) * float(points.size() - 1)
	var index := clampi(int(floor(scaled)), 0, points.size() - 2)
	var local_t := scaled - float(index)
	return points[index].lerp(points[index + 1], local_t)

func _prefix_points(points: PackedVector2Array, t: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty():
		return result
	result.append(points[0])
	var scaled := clampf(t, 0.0, 1.0) * float(points.size() - 1)
	var last_full := clampi(int(floor(scaled)), 0, points.size() - 1)
	for i in range(1, last_full + 1):
		result.append(points[i])
	if last_full < points.size() - 1:
		var local_t := scaled - float(last_full)
		result.append(points[last_full].lerp(points[last_full + 1], local_t))
	return result

func _polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total
