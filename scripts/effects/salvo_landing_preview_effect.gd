class_name SalvoLandingPreviewEffect
extends Node2D

var start_point := Vector2.ZERO
var landing_point := Vector2.RIGHT
var hold_ratio := 0.0
var lifetime := 0.0
var max_lifetime := 0.14

func setup(next_start: Vector2, next_landing: Vector2, next_hold_ratio: float) -> void:
	start_point = next_start
	landing_point = next_landing
	hold_ratio = clampf(next_hold_ratio, 0.0, 1.0)
	lifetime = max_lifetime
	queue_redraw()

func refresh(next_start: Vector2, next_landing: Vector2, next_hold_ratio: float) -> void:
	start_point = next_start
	landing_point = next_landing
	hold_ratio = clampf(next_hold_ratio, 0.0, 1.0)
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
	var tint := Color(1.0, 0.42 + hold_ratio * 0.32, 0.08, 0.72 * ratio)
	var arc_mid := start_point.lerp(landing_point, 0.5) + Vector2(0.0, -42.0 - 26.0 * hold_ratio)
	var points := PackedVector2Array([start_point, start_point.lerp(arc_mid, 0.5), arc_mid, arc_mid.lerp(landing_point, 0.5), landing_point])
	draw_polyline(points, Color(tint.r, tint.g, tint.b, 0.28 * ratio), 6.0)
	draw_polyline(points, Color(1.0, 0.92, 0.24, 0.52 * ratio), 2.0)
	var radius := 13.0 + hold_ratio * 11.0
	draw_arc(landing_point, radius, 0.0, TAU, 56, tint, 3.0)
	draw_line(landing_point + Vector2(-radius * 1.35, 0.0), landing_point + Vector2(radius * 1.35, 0.0), Color(1.0, 0.96, 0.52, 0.72 * ratio), 2.0)
	draw_line(landing_point + Vector2(0.0, -radius * 1.35), landing_point + Vector2(0.0, radius * 1.35), Color(1.0, 0.96, 0.52, 0.72 * ratio), 2.0)
	draw_circle(landing_point, 3.4, Color(1.0, 1.0, 1.0, 0.9 * ratio))
