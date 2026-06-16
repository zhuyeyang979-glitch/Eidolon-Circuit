class_name TrueBulletTargetLockEffect
extends Node2D

var lifetime := 1.0
var max_lifetime := 1.0
var lock_color := Color(1.0, 0.78, 0.28, 1.0)

func setup(duration: float, next_color: Color) -> void:
	max_lifetime = maxf(0.12, duration)
	lifetime = max_lifetime
	lock_color = next_color
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
	var radius := lerpf(54.0, 18.0, charge)
	var alpha := 0.32 + charge * 0.54
	var color := Color(lock_color.r, lock_color.g, lock_color.b, alpha)
	draw_circle(Vector2.ZERO, radius + 10.0 * (1.0 - charge), Color(lock_color.r, lock_color.g, lock_color.b, 0.08 * ratio))
	draw_arc(Vector2.ZERO, radius, -PI * 0.08, PI * 1.62, 40, color, 3.2)
	draw_arc(Vector2.ZERO, radius * 0.72, PI * 0.45, PI * 2.08, 36, Color(1.0, 0.96, 0.72, alpha * 0.72), 1.6)
	draw_line(Vector2(-radius - 8.0, 0.0), Vector2(-10.0, 0.0), color, 2.0)
	draw_line(Vector2(10.0, 0.0), Vector2(radius + 8.0, 0.0), color, 2.0)
	draw_line(Vector2(0.0, -radius - 8.0), Vector2(0.0, -10.0), color, 2.0)
	draw_line(Vector2(0.0, 10.0), Vector2(0.0, radius + 8.0), color, 2.0)
	draw_circle(Vector2.ZERO, 3.0 + charge * 2.5, Color(1.0, 0.98, 0.82, alpha))
