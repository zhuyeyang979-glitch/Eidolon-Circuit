class_name ComboRippleEffect
extends Control

var lifetime := 0.0
var max_lifetime := 0.62
var origin := Vector2.ZERO
var tint := Color(0.32, 0.92, 1.0, 1.0)
var strength := 1.0

func setup(next_origin: Vector2, next_tint: Color, next_strength: float = 1.0) -> void:
	origin = next_origin
	tint = next_tint
	strength = clampf(next_strength, 0.65, 1.5)
	lifetime = max_lifetime
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var max_radius := maxf(size.x, size.y) * 1.18
	draw_rect(Rect2(Vector2.ZERO, size), Color(tint.r, tint.g, tint.b, 0.032 * ratio * strength), true)
	for i in range(5):
		var t := clampf(inv + float(i) * 0.065, 0.0, 1.0)
		var radius := max_radius * t
		var alpha := (0.36 - float(i) * 0.045) * ratio * strength
		if radius > 4.0 and alpha > 0.005:
			draw_arc(origin, radius, 0.0, TAU, 118, Color(tint.r, tint.g, tint.b, alpha), 2.0 + float(i) * 0.65)
	draw_circle(origin, 16.0 + inv * 48.0, Color(1.0, 1.0, 1.0, 0.12 * ratio * strength))
