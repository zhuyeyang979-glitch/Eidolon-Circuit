class_name BlindZoneEffect
extends Node2D

var owner_id := 1
var ring_pos := 0.0
var lane := 0.0
var radius_units := 0.6
var strength := 0.5
var remaining := 1.0
var duration := 1.0

func setup(next_owner: int, next_ring: float, next_lane: float, next_radius: float, next_duration: float, next_strength: float) -> void:
	owner_id = next_owner
	ring_pos = next_ring
	lane = next_lane
	radius_units = next_radius
	duration = maxf(0.1, next_duration)
	remaining = duration
	strength = clampf(next_strength, 0.0, 1.0)
	queue_redraw()

func tick_zone(delta: float, screen_position: Vector2, is_visible_in_view: bool) -> void:
	remaining -= delta
	position = screen_position
	visible = is_visible_in_view and remaining > 0.0
	queue_redraw()
	if remaining <= 0.0:
		queue_free()

func is_alive() -> bool:
	return remaining > 0.0

func _draw() -> void:
	var ratio := clampf(remaining / duration, 0.0, 1.0)
	var inv := 1.0 - ratio
	var radius_px := 44.0 + radius_units * 92.0
	draw_circle(Vector2.ZERO, radius_px, Color(0.0, 0.0, 0.02, 0.36 + strength * 0.34))
	draw_circle(Vector2.ZERO, radius_px * 0.58, Color(0.0, 0.0, 0.0, 0.42 + strength * 0.22))
	for i in range(18):
		var angle := TAU * float(i) / 18.0 + inv * 0.6
		var p0 := Vector2(cos(angle), sin(angle)) * radius_px * 0.18
		var p1 := Vector2(cos(angle), sin(angle)) * radius_px * (0.72 + float(i % 4) * 0.05)
		draw_line(p1, p0, Color(0.18, 0.28, 0.72, 0.18 + strength * 0.16), 3.0)
	var owner_color := Color(0.28, 0.9, 1.0, 0.7) if owner_id == 1 else Color(1.0, 0.26, 0.42, 0.7)
	draw_arc(Vector2.ZERO, radius_px, 0.0, TAU, 48, owner_color, 2.0)
	draw_string(ThemeDB.get_fallback_font(), Vector2(-42.0, -radius_px - 8.0), "OWNER VISIBLE", HORIZONTAL_ALIGNMENT_LEFT, 120.0, 10, Color(owner_color.r, owner_color.g, owner_color.b, ratio))
