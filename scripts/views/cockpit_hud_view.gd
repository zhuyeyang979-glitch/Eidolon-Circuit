extends Control
class_name CockpitHudView


func _draw() -> void:
	var cyan := Color(0.24, 0.88, 1.0, 0.22)
	var red := Color(1.0, 0.22, 0.34, 0.2)
	var gold := Color(1.0, 0.82, 0.22, 0.26)
	_draw_corner(Vector2(22.0, 14.0), 1.0, 1.0, cyan)
	_draw_corner(Vector2(size.x - 22.0, 14.0), -1.0, 1.0, red)
	_draw_corner(Vector2(22.0, size.y - 14.0), 1.0, -1.0, Color(1.0, 0.16, 0.08, 0.24))
	_draw_corner(Vector2(size.x - 22.0, size.y - 14.0), -1.0, -1.0, Color(1.0, 0.16, 0.08, 0.24))
	draw_line(Vector2(size.x * 0.5 - 110.0, 24.0), Vector2(size.x * 0.5 + 110.0, 24.0), gold, 2.0)
	draw_line(Vector2(size.x * 0.5 - 64.0, 64.0), Vector2(size.x * 0.5 + 64.0, 64.0), Color(0.9, 0.96, 1.0, 0.14), 1.0)
	for i in range(7):
		var offset := float(i) * 18.0
		draw_line(Vector2(size.x * 0.5 - 170.0 - offset, 36.0), Vector2(size.x * 0.5 - 156.0 - offset, 50.0), cyan, 1.0)
		draw_line(Vector2(size.x * 0.5 + 170.0 + offset, 36.0), Vector2(size.x * 0.5 + 156.0 + offset, 50.0), red, 1.0)
	draw_rect(Rect2(Vector2(68.0, 96.0), Vector2(size.x - 136.0, size.y - 192.0)), Color(0.76, 0.9, 1.0, 0.055), false, 2.0)


func _draw_corner(origin: Vector2, sx: float, sy: float, color: Color) -> void:
	draw_line(origin, origin + Vector2(190.0 * sx, 0.0), color, 3.0)
	draw_line(origin, origin + Vector2(0.0, 126.0 * sy), color, 3.0)
	draw_line(origin + Vector2(190.0 * sx, 0.0), origin + Vector2(226.0 * sx, 28.0 * sy), color, 2.0)
	draw_line(origin + Vector2(0.0, 126.0 * sy), origin + Vector2(32.0 * sx, 160.0 * sy), color, 2.0)
