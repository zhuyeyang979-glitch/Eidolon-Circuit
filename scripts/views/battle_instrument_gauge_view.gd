extends Control
class_name BattleInstrumentGaugeView

var speed := 0.0
var speed_max := 1.0
var ammo_breakdown := {}
var ui_lang := "zh"


func set_values(next_speed: float, next_speed_max: float, next_ammo_breakdown: Dictionary, next_lang: String) -> void:
	speed = maxf(0.0, next_speed)
	speed_max = maxf(0.1, next_speed_max)
	ammo_breakdown = next_ammo_breakdown.duplicate(true)
	ui_lang = next_lang
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var panel_color := Color(0.012, 0.018, 0.024, 0.46)
	var border_color := Color(0.26, 0.92, 1.0, 0.34)
	draw_rect(rect, panel_color, true)
	draw_rect(rect, border_color, false, 1.5)
	var center := Vector2(size.x * 0.5, size.y * 0.54)
	var radius := minf(size.x * 0.34, size.y * 0.62)
	var start_angle := deg_to_rad(210.0)
	var end_angle := deg_to_rad(330.0)
	draw_arc(center, radius, start_angle, end_angle, 48, Color(0.7, 0.88, 1.0, 0.22), 5.0, true)
	var speed_ratio := clampf(speed / speed_max, 0.0, 1.0)
	var speed_angle := lerpf(start_angle, end_angle, speed_ratio)
	_draw_needle(center, radius * 0.9, speed_angle, Color(0.28, 0.95, 1.0, 0.9), 3.0)
	draw_circle(center, 5.0, Color(0.92, 1.0, 1.0, 0.82))
	var ammo_info := _dominant_ammo_info()
	var ammo_current := int(ammo_info.get("current", 0))
	var ammo_max := int(ammo_info.get("capacity", 0))
	var ammo_kind := String(ammo_info.get("kind", ""))
	var ammo_rect := Rect2(Vector2(48.0, size.y - 20.0), Vector2(size.x - 72.0, 7.0))
	_draw_ammo_icon(ammo_kind, Rect2(Vector2(16.0, size.y - 28.0), Vector2(24.0, 24.0)), 0.72)
	_draw_ammo_segments(ammo_rect, ammo_current, ammo_max, ammo_kind)
	var font := get_theme_default_font()
	var label := "速 %.1f  弹 %d/%d" % [speed, ammo_current, ammo_max] if ui_lang == "zh" else "SPD %.1f  AMMO %d/%d" % [speed, ammo_current, ammo_max]
	draw_string(font, Vector2(18.0, 17.0), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 12, Color(0.86, 0.95, 1.0, 0.84))


func _draw_needle(center: Vector2, length: float, angle: float, color: Color, width: float) -> void:
	var tip := center + Vector2(cos(angle), sin(angle)) * length
	draw_line(center, tip, color, width, true)


func _dominant_ammo_info() -> Dictionary:
	var best_kind := ""
	var best_capacity := 0
	var best_current := 0
	for kind in ammo_breakdown.keys():
		var entry = ammo_breakdown.get(kind, {})
		if not (entry is Dictionary):
			continue
		var capacity := int(entry.get("capacity", 0))
		if capacity > best_capacity:
			best_capacity = capacity
			best_current = int(entry.get("current", 0))
			best_kind = String(kind)
	return {"kind": best_kind, "current": best_current, "capacity": best_capacity}


func _ammo_color(ammo_kind: String, alpha: float) -> Color:
	match ammo_kind:
		"bullet":
			return Color(1.0, 0.72, 0.28, alpha)
		"laser":
			return Color(0.18, 0.92, 1.0, alpha)
		"chemical":
			return Color(0.34, 1.0, 0.42, alpha)
		"explosive":
			return Color(1.0, 0.34, 0.16, alpha)
		"web":
			return Color(0.9, 0.95, 1.0, alpha)
	return Color(0.86, 0.92, 1.0, alpha)


func _draw_ammo_segments(rect: Rect2, current: int, capacity: int, ammo_kind: String) -> void:
	var gap := 2.0
	var segment_count := 10
	var segment_w := (rect.size.x - gap * float(segment_count - 1)) / float(segment_count)
	var filled := 0 if capacity <= 0 else int(ceil(clampf(float(current) / float(capacity), 0.0, 1.0) * float(segment_count)))
	for i in range(segment_count):
		var slot := Rect2(rect.position + Vector2(float(i) * (segment_w + gap), 0.0), Vector2(segment_w, rect.size.y))
		draw_rect(slot, Color(0.7, 0.82, 0.9, 0.14), true)
		if i < filled:
			draw_rect(slot.grow(-0.7), _ammo_color(ammo_kind, 0.62), true)
		draw_rect(slot, Color(0.86, 0.95, 1.0, 0.22), false, 0.8)


func _draw_ammo_icon(ammo_kind: String, rect: Rect2, alpha: float) -> void:
	var c := _ammo_color(ammo_kind, alpha)
	var center := rect.get_center()
	match ammo_kind:
		"bullet":
			var body := Rect2(rect.position + Vector2(rect.size.x * 0.34, rect.size.y * 0.26), Vector2(rect.size.x * 0.24, rect.size.y * 0.52))
			draw_rect(body, c, true)
			var tip := PackedVector2Array([
				Vector2(body.position.x, body.position.y),
				Vector2(body.end.x, body.position.y),
				Vector2(center.x, rect.position.y + rect.size.y * 0.08),
			])
			draw_colored_polygon(tip, c)
			draw_line(Vector2(center.x, body.end.y), Vector2(center.x, rect.end.y - rect.size.y * 0.08), Color(1.0, 0.95, 0.62, alpha * 0.9), 2.0)
		"laser":
			draw_line(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.76), rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.18), c, 3.0, true)
			draw_line(rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.52), rect.position + Vector2(rect.size.x * 0.66, rect.size.y * 0.52), Color(c.r, c.g, c.b, alpha * 0.48), 2.0, true)
		"chemical":
			var pts := PackedVector2Array([
				center + Vector2(0.0, -rect.size.y * 0.36),
				center + Vector2(rect.size.x * 0.28, rect.size.y * 0.08),
				center + Vector2(rect.size.x * 0.1, rect.size.y * 0.34),
				center + Vector2(-rect.size.x * 0.24, rect.size.y * 0.2),
			])
			draw_colored_polygon(pts, c)
			draw_circle(center + Vector2(rect.size.x * 0.12, rect.size.y * 0.12), rect.size.x * 0.08, Color.WHITE)
		"explosive":
			var burst := PackedVector2Array([
				center + Vector2(0.0, -rect.size.y * 0.42),
				center + Vector2(rect.size.x * 0.16, -rect.size.y * 0.1),
				center + Vector2(rect.size.x * 0.42, 0.0),
				center + Vector2(rect.size.x * 0.14, rect.size.y * 0.12),
				center + Vector2(0.0, rect.size.y * 0.42),
				center + Vector2(-rect.size.x * 0.14, rect.size.y * 0.12),
				center + Vector2(-rect.size.x * 0.42, 0.0),
				center + Vector2(-rect.size.x * 0.16, -rect.size.y * 0.1),
			])
			draw_colored_polygon(burst, c)
		"web":
			for i in range(6):
				var a := TAU * float(i) / 6.0
				draw_line(center, center + Vector2(cos(a), sin(a)) * rect.size.x * 0.4, c, 1.2, true)
			draw_arc(center, rect.size.x * 0.22, 0.0, TAU, 24, c, 1.0, true)
			draw_arc(center, rect.size.x * 0.36, 0.0, TAU, 24, Color(c.r, c.g, c.b, alpha * 0.6), 1.0, true)
		_:
			draw_circle(center, rect.size.x * 0.28, c)
