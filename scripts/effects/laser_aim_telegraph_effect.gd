class_name LaserAimTelegraphEffect
extends Node2D

var start_point := Vector2.ZERO
var end_point := Vector2.RIGHT
var lifetime := 0.0
var max_lifetime := 0.48
var beam_color := Color(0.3, 0.92, 1.0, 1.0)

func setup(next_start: Vector2, next_end: Vector2, duration: float, next_color: Color) -> void:
	start_point = next_start
	end_point = next_end
	max_lifetime = maxf(0.08, duration)
	lifetime = max_lifetime
	beam_color = next_color
	queue_redraw()

func set_line(next_start: Vector2, next_end: Vector2) -> void:
	start_point = next_start
	end_point = next_end
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(lifetime / max_lifetime, 0.0, 1.0)
	var charge := 1.0 - ratio
	var dir := (end_point - start_point).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var right := Vector2(-dir.y, dir.x)
	var points := PackedVector2Array()
	var segments := 18
	for i in range(segments):
		var t := float(i) / float(segments - 1)
		var fade := 1.0 - t * 0.78
		var p := start_point.lerp(end_point, t)
		var wobble := sin(charge * TAU * 4.0 + t * TAU * 2.0) * 1.8 * fade
		points.append(p + right * wobble)
	draw_polyline(points, Color(beam_color.r, beam_color.g, beam_color.b, 0.08 + charge * 0.32), 8.0 + charge * 4.0)
	for i in range(points.size() - 1):
		var t0 := float(i) / float(maxi(1, points.size() - 1))
		var alpha := (0.28 + charge * 0.52) * (1.0 - t0 * 0.82)
		draw_line(points[i], points[i + 1], Color(0.82, 0.96, 1.0, alpha), 2.2 + charge * 2.2)
	var pulse_center := start_point.lerp(end_point, clampf(0.18 + charge * 0.74, 0.0, 1.0))
	draw_circle(pulse_center, 8.0 + charge * 12.0, Color(0.86, 0.98, 1.0, 0.18 + charge * 0.28))
	draw_arc(end_point, 16.0 + charge * 10.0, 0.0, TAU, 32, Color(beam_color.r, beam_color.g, beam_color.b, 0.32 + charge * 0.38), 2.0 + charge * 2.0)
