class_name CoinPickupEffect
extends Node2D

var owner_id := 1
var value := 100
var ttl := 6.0
var max_ttl := 6.0
var pulse := 0.0
var collected := false

func setup(next_owner: int, next_value: int, lifetime: float) -> void:
	owner_id = next_owner
	value = next_value
	ttl = maxf(0.2, lifetime)
	max_ttl = ttl
	queue_redraw()

func update_screen(screen_position: Vector2, is_visible_in_view: bool, delta: float) -> void:
	if collected:
		return
	position = screen_position
	visible = is_visible_in_view
	ttl -= delta
	pulse = fmod(pulse + delta * 2.4, 1.0)
	queue_redraw()

func collect() -> void:
	collected = true
	queue_free()

func expired() -> bool:
	return collected or ttl <= 0.0

func _draw() -> void:
	var ratio := clampf(ttl / maxf(0.1, max_ttl), 0.0, 1.0)
	var wobble := sin(pulse * TAU) * 3.0
	var color := Color(1.0, 0.82, 0.18, 0.92 * ratio)
	draw_circle(Vector2(0.0, wobble), 13.0, Color(1.0, 0.68, 0.05, 0.22 * ratio))
	draw_circle(Vector2(0.0, wobble), 8.0, color)
	draw_arc(Vector2(0.0, wobble), 11.0, 0.0, TAU, 28, Color(1.0, 0.98, 0.55, 0.78 * ratio), 2.0)
	draw_string(ThemeDB.get_fallback_font(), Vector2(-12.0, -18.0 + wobble), "+%d" % value, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 9, Color(1.0, 0.94, 0.45, ratio))
