extends Control
class_name BattleMinimapView

var panel_alpha := 0.23
var map_alpha := 0.18
var grid_alpha := 0.16
var border_alpha := 0.38
var ring_length := 24.0
var half_height := 5.0
var view_width_units := 7.2
var view_height_units := 5.2
var camera_ring := 0.0
var camera_lane := 0.0
var unit_points: Array = []


func set_world(next_units: Array, next_camera_ring: float, next_camera_lane: float) -> void:
	unit_points = next_units.duplicate(true)
	camera_ring = next_camera_ring
	camera_lane = next_camera_lane
	queue_redraw()


func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, Color(0.006, 0.011, 0.017, panel_alpha), true)
	draw_rect(panel, Color(0.22, 0.9, 1.0, border_alpha), false, 2.0)
	var map_rect := Rect2(Vector2(12.0, 14.0), size - Vector2(24.0, 28.0))
	draw_rect(map_rect, Color(0.018, 0.028, 0.04, map_alpha), true)
	draw_rect(map_rect, Color(0.62, 0.86, 1.0, border_alpha), false, 1.5)
	for i in range(1, 4):
		var x := map_rect.position.x + map_rect.size.x * float(i) / 4.0
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), Color(0.62, 0.86, 1.0, grid_alpha), 1.0)
	for i in range(1, 3):
		var y := map_rect.position.y + map_rect.size.y * float(i) / 3.0
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), Color(0.62, 0.86, 1.0, grid_alpha), 1.0)
	_draw_boundary_band(map_rect)
	_draw_camera_window(map_rect)
	for point in unit_points:
		if point is Dictionary:
			_draw_unit_marker(map_rect, point)
	for x in [map_rect.position.x, map_rect.end.x]:
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), Color(1.0, 0.82, 0.25, border_alpha), 2.0)


func _draw_boundary_band(map_rect: Rect2) -> void:
	draw_rect(Rect2(map_rect.position, Vector2(map_rect.size.x, 5.0)), Color(0.32, 0.86, 1.0, 0.28), true)
	draw_rect(Rect2(Vector2(map_rect.position.x, map_rect.end.y - 5.0), Vector2(map_rect.size.x, 5.0)), Color(1.0, 0.22, 0.36, 0.28), true)
	var near_top := clampf((camera_lane + half_height) / maxf(0.001, view_height_units * 0.5), 0.0, 1.0)
	var near_bottom := clampf((half_height - camera_lane) / maxf(0.001, view_height_units * 0.5), 0.0, 1.0)
	if near_top < 1.0:
		draw_rect(Rect2(map_rect.position, Vector2(map_rect.size.x, 9.0)), Color(0.32, 0.86, 1.0, (1.0 - near_top) * 0.44), true)
	if near_bottom < 1.0:
		draw_rect(Rect2(Vector2(map_rect.position.x, map_rect.end.y - 9.0), Vector2(map_rect.size.x, 9.0)), Color(1.0, 0.22, 0.36, (1.0 - near_bottom) * 0.44), true)


func _draw_camera_window(map_rect: Rect2) -> void:
	var half_w := view_width_units * 0.5 / maxf(0.001, ring_length) * map_rect.size.x
	var half_h := view_height_units * 0.5 / maxf(0.001, half_height * 2.0) * map_rect.size.y
	var center := _map_point(map_rect, camera_ring, camera_lane)
	var top := clampf(center.y - half_h, map_rect.position.y, map_rect.end.y)
	var bottom := clampf(center.y + half_h, map_rect.position.y, map_rect.end.y)
	var x0 := center.x - half_w
	var x1 := center.x + half_w
	var color := Color(0.92, 1.0, 1.0, 0.58)
	if x0 < map_rect.position.x:
		draw_rect(Rect2(Vector2(map_rect.position.x, top), Vector2(x1 - map_rect.position.x, bottom - top)), Color(0.22, 0.9, 1.0, 0.06), true)
		draw_rect(Rect2(Vector2(map_rect.end.x + x0 - map_rect.position.x, top), Vector2(map_rect.end.x - (map_rect.end.x + x0 - map_rect.position.x), bottom - top)), Color(0.22, 0.9, 1.0, 0.06), true)
		draw_rect(Rect2(Vector2(map_rect.position.x, top), Vector2(x1 - map_rect.position.x, bottom - top)), color, false, 1.0)
		draw_rect(Rect2(Vector2(map_rect.end.x + x0 - map_rect.position.x, top), Vector2(map_rect.end.x - (map_rect.end.x + x0 - map_rect.position.x), bottom - top)), color, false, 1.0)
	elif x1 > map_rect.end.x:
		draw_rect(Rect2(Vector2(x0, top), Vector2(map_rect.end.x - x0, bottom - top)), Color(0.22, 0.9, 1.0, 0.06), true)
		draw_rect(Rect2(Vector2(map_rect.position.x, top), Vector2(x1 - map_rect.end.x, bottom - top)), Color(0.22, 0.9, 1.0, 0.06), true)
		draw_rect(Rect2(Vector2(x0, top), Vector2(map_rect.end.x - x0, bottom - top)), color, false, 1.0)
		draw_rect(Rect2(Vector2(map_rect.position.x, top), Vector2(x1 - map_rect.end.x, bottom - top)), color, false, 1.0)
	else:
		var window := Rect2(Vector2(x0, top), Vector2(x1 - x0, bottom - top))
		draw_rect(window, Color(0.22, 0.9, 1.0, 0.06), true)
		draw_rect(window, color, false, 1.0)


func _draw_unit_marker(map_rect: Rect2, point: Dictionary) -> void:
	var owner := int(point.get("owner", 0))
	var role := String(point.get("role", "unit"))
	var pos := _map_point(map_rect, float(point.get("ring", 0.0)), float(point.get("lane", 0.0)))
	var base_color := Color(0.2, 0.9, 1.0, 0.96) if owner == 1 else Color(1.0, 0.24, 0.38, 0.96)
	if role == "barrier" or role == "barrier_piece":
		base_color = base_color.lerp(Color(1.0, 0.82, 0.22, 1.0), 0.28)
	var radius := clampf(3.2 + float(point.get("radius", 0.18)) * 3.2, 3.0, 8.0)
	if role == "hero":
		draw_circle(pos, radius + 2.0, Color(base_color.r, base_color.g, base_color.b, 0.18))
		draw_circle(pos, radius, base_color)
		draw_circle(pos, maxf(1.5, radius * 0.42), Color.WHITE)
	elif role == "barrier" or role == "barrier_piece":
		draw_rect(Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(base_color.r, base_color.g, base_color.b, 0.72), true)
	else:
		var pts := PackedVector2Array([
			pos + Vector2(0.0, -radius),
			pos + Vector2(radius, 0.0),
			pos + Vector2(0.0, radius),
			pos + Vector2(-radius, 0.0),
		])
		draw_colored_polygon(pts, base_color)


func _map_point(map_rect: Rect2, ring_value: float, lane_value: float) -> Vector2:
	var x := map_rect.position.x + fposmod(ring_value, ring_length) / maxf(0.001, ring_length) * map_rect.size.x
	var y := map_rect.position.y + clampf((lane_value + half_height) / maxf(0.001, half_height * 2.0), 0.0, 1.0) * map_rect.size.y
	return Vector2(x, y)
