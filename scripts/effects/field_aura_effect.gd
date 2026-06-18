class_name FieldAuraEffect
extends Node2D

var owner_id := 1
var field_kind := "gravity"
var radius_units := 0.6
var strength := 1.0
var pulse := 0.0

func setup(next_owner: int, next_kind: String, next_radius: float, next_strength: float = 1.0) -> void:
	owner_id = next_owner
	field_kind = next_kind
	radius_units = maxf(0.1, next_radius)
	strength = maxf(0.1, next_strength)
	queue_redraw()

func update_screen(screen_position: Vector2, is_visible_in_view: bool, delta: float) -> void:
	position = screen_position
	visible = is_visible_in_view
	pulse = fmod(pulse + delta * (0.75 + strength * 0.12), 1.0)
	queue_redraw()

func _draw() -> void:
	var radius_px := 34.0 + radius_units * 92.0
	var color := _field_color()
	var soft := Color(color.r, color.g, color.b, 0.08 + minf(0.2, strength * 0.035))
	draw_circle(Vector2.ZERO, radius_px, soft)
	draw_arc(Vector2.ZERO, radius_px, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.48), 2.0)
	draw_arc(Vector2.ZERO, radius_px * (0.62 + pulse * 0.22), 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.24), 2.0)
	if field_kind.begins_with("gravity"):
		_draw_gravity_vector_field(radius_px, color)
		return
	match field_kind:
		"coolant":
			for i in range(10):
				var angle := TAU * float(i) / 10.0 + pulse * TAU * 0.18
				var p0 := Vector2(cos(angle), sin(angle)) * radius_px * 0.24
				var p1 := Vector2(cos(angle), sin(angle)) * radius_px * 0.88
				draw_line(p0, p1, Color(0.42, 1.0, 0.92, 0.22), 2.0)
		"heat":
			for i in range(13):
				var angle := TAU * float(i) / 13.0 - pulse * TAU * 0.3
				var dist := radius_px * (0.2 + float((i * 5) % 9) / 12.0)
				var p := Vector2(cos(angle), sin(angle)) * dist
				draw_circle(p, 4.0 + float(i % 3) * 2.0, Color(1.0, 0.35, 0.06, 0.18 + strength * 0.012))
			draw_arc(Vector2.ZERO, radius_px * 0.78, PI * 0.1, PI * 1.42, 30, Color(1.0, 0.72, 0.16, 0.32), 5.0)
		"gravity":
			for i in range(8):
				var angle := TAU * float(i) / 8.0 + pulse * TAU * 0.12
				var outer := Vector2(cos(angle), sin(angle)) * radius_px * 0.86
				var inner := Vector2(cos(angle), sin(angle)) * radius_px * 0.34
				draw_line(outer, inner, Color(color.r, color.g, color.b, 0.34), 3.0)
				_draw_arrow_tip(inner, -outer.normalized(), Color(color.r, color.g, color.b, 0.58), 8.0)
		"repulsion":
			for i in range(8):
				var angle := TAU * float(i) / 8.0 - pulse * TAU * 0.2
				var inner := Vector2(cos(angle), sin(angle)) * radius_px * 0.3
				var outer := Vector2(cos(angle), sin(angle)) * radius_px * 0.9
				draw_line(inner, outer, Color(color.r, color.g, color.b, 0.34), 3.0)
				_draw_arrow_tip(outer, outer.normalized(), Color(color.r, color.g, color.b, 0.58), 8.0)
		"siphon":
			for i in range(3):
				var r := radius_px * (0.32 + float(i) * 0.22 + pulse * 0.04)
				draw_arc(Vector2.ZERO, r, pulse * TAU + float(i), pulse * TAU + float(i) + PI * 1.35, 34, Color(1.0, 0.86, 0.18, 0.36), 4.0)
		"cage":
			for i in range(4):
				var start := -PI * 0.15 + float(i) * PI * 0.5 + pulse * 0.08
				draw_arc(Vector2.ZERO, radius_px * (0.86 + float(i % 2) * 0.08), start, start + PI * 0.42, 28, Color(0.52, 0.92, 1.0, 0.44), 5.0)
			for i in range(10):
				var angle := TAU * float(i) / 10.0
				var p0 := Vector2(cos(angle), sin(angle)) * radius_px * 0.72
				var p1 := Vector2(cos(angle + 0.08), sin(angle + 0.08)) * radius_px * 0.96
				draw_line(p0, p1, Color(0.95, 0.98, 1.0, 0.22), 2.0)
		"hack":
			for i in range(6):
				var y := -radius_px * 0.65 + float(i) * radius_px * 0.26
				var x0 := -radius_px * 0.78
				var x1 := radius_px * 0.78
				var phase := pulse * TAU + float(i) * 0.7
				draw_polyline(PackedVector2Array([Vector2(x0, y), Vector2(x0 * 0.35, y + sin(phase) * 12.0), Vector2(x1 * 0.25, y - cos(phase) * 10.0), Vector2(x1, y)]), Color(0.44, 1.0, 0.46, 0.34), 2.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-38.0, -6.0), "BREACH", HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color(0.58, 1.0, 0.62, 0.72))
		"jam":
			for i in range(9):
				var angle := TAU * float(i) / 9.0 + pulse * TAU * 0.31
				var p0 := Vector2(cos(angle), sin(angle)) * radius_px * 0.18
				var p1 := Vector2(cos(angle + sin(pulse * TAU + float(i)) * 0.35), sin(angle)) * radius_px * 0.92
				draw_line(p0, p1, Color(0.82, 0.72, 1.0, 0.28), 3.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-30.0, -6.0), "JAM", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, Color(0.88, 0.78, 1.0, 0.78))
		"support_ammo":
			for i in range(6):
				var angle := TAU * float(i) / 6.0 + pulse * TAU * 0.12
				var p := Vector2(cos(angle), sin(angle)) * radius_px * 0.62
				draw_rect(Rect2(p - Vector2(8.0, 4.0), Vector2(16.0, 8.0)), Color(0.92, 0.98, 1.0, 0.34), true)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-34.0, -6.0), "AMMO", HORIZONTAL_ALIGNMENT_CENTER, 68.0, 11, Color(0.92, 0.98, 1.0, 0.76))
		"support_repair":
			for i in range(4):
				var r := radius_px * (0.24 + float(i) * 0.16)
				draw_arc(Vector2.ZERO, r, -PI * 0.25 + pulse, PI * 1.2 + pulse, 30, Color(0.42, 1.0, 0.62, 0.32), 3.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-38.0, -6.0), "REPAIR", HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color(0.58, 1.0, 0.68, 0.76))
		"support_buff":
			for i in range(7):
				var angle := TAU * float(i) / 7.0 - pulse * TAU * 0.18
				var p0 := Vector2(cos(angle), sin(angle)) * radius_px * 0.28
				var p1 := Vector2(cos(angle), sin(angle)) * radius_px * 0.82
				draw_line(p0, p1, Color(1.0, 0.38, 0.58, 0.3), 2.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-28.0, -6.0), "BUFF", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 11, Color(1.0, 0.48, 0.62, 0.76))
		"support_armor":
			draw_rect(Rect2(Vector2(-radius_px * 0.88, -radius_px * 0.34), Vector2(radius_px * 1.76, radius_px * 0.68)), Color(0.36, 0.78, 1.0, 0.12), true)
			for i in range(4):
				var y := -radius_px * 0.28 + float(i) * radius_px * 0.18
				draw_line(Vector2(-radius_px * 0.82, y), Vector2(radius_px * 0.82, y), Color(0.46, 0.92, 1.0, 0.34), 2.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-36.0, -6.0), "ARMOR", HORIZONTAL_ALIGNMENT_CENTER, 72.0, 11, Color(0.62, 0.94, 1.0, 0.8))
		"speed_lane":
			draw_rect(Rect2(Vector2(-radius_px * 0.92, -radius_px * 0.18), Vector2(radius_px * 1.84, radius_px * 0.36)), Color(0.98, 0.86, 0.18, 0.11), true)
			for i in range(7):
				var y := -radius_px * 0.14 + float(i) * radius_px * 0.046
				var offset := fmod(pulse * radius_px * 0.72 + float(i) * 19.0, radius_px * 0.44)
				draw_line(Vector2(-radius_px * 0.78 + offset, y), Vector2(-radius_px * 0.38 + offset, y), Color(1.0, 0.9, 0.28, 0.42), 3.0)
				draw_line(Vector2(radius_px * 0.28 + offset * 0.6, y), Vector2(radius_px * 0.64 + offset * 0.6, y), Color(0.36, 0.95, 1.0, 0.3), 2.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-34.0, -6.0), "RAIL", HORIZONTAL_ALIGNMENT_CENTER, 68.0, 11, Color(1.0, 0.9, 0.35, 0.82))
		"one_way_shield":
			var alpha := 0.16 + sin(pulse * TAU) * 0.04
			draw_rect(Rect2(Vector2(-radius_px * 0.9, -radius_px * 0.16), Vector2(radius_px * 1.8, radius_px * 0.32)), Color(0.36, 0.86, 1.0, alpha), true)
			draw_line(Vector2(-radius_px * 0.92, -radius_px * 0.18), Vector2(radius_px * 0.92, -radius_px * 0.18), Color(0.74, 0.96, 1.0, 0.58), 3.0)
			draw_line(Vector2(-radius_px * 0.92, radius_px * 0.18), Vector2(radius_px * 0.92, radius_px * 0.18), Color(0.74, 0.96, 1.0, 0.58), 3.0)
			for i in range(5):
				var x := -radius_px * 0.62 + float(i) * radius_px * 0.31 + sin(pulse * TAU + float(i)) * 4.0
				draw_line(Vector2(x, -radius_px * 0.14), Vector2(x + radius_px * 0.12, 0.0), Color(0.96, 1.0, 1.0, 0.52), 2.0)
				draw_line(Vector2(x + radius_px * 0.12, 0.0), Vector2(x, radius_px * 0.14), Color(0.96, 1.0, 1.0, 0.52), 2.0)
			draw_string(ThemeDB.get_fallback_font(), Vector2(-46.0, -6.0), "ONE-WAY", HORIZONTAL_ALIGNMENT_CENTER, 92.0, 10, Color(0.86, 0.98, 1.0, 0.82))

func _draw_gravity_vector_field(radius_px: float, color: Color) -> void:
	var mode := field_kind
	if mode.begins_with("gravity_"):
		mode = mode.substr(8)
	elif mode == "gravity":
		mode = "inward"
	if mode in ["inward", "outward"]:
		for i in range(8):
			var angle := TAU * float(i) / 8.0 + pulse * TAU * 0.12
			var outer := Vector2(cos(angle), sin(angle)) * radius_px * 0.86
			var inner := Vector2(cos(angle), sin(angle)) * radius_px * 0.34
			if mode == "outward":
				draw_line(inner, outer, Color(color.r, color.g, color.b, 0.34), 3.0)
				_draw_arrow_tip(outer, outer.normalized(), Color(color.r, color.g, color.b, 0.58), 8.0)
			else:
				draw_line(outer, inner, Color(color.r, color.g, color.b, 0.34), 3.0)
				_draw_arrow_tip(inner, -outer.normalized(), Color(color.r, color.g, color.b, 0.58), 8.0)
		return
	var dir := _gravity_visual_direction(mode)
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	for i in range(7):
		var side_ratio := -0.78 + float(i) * 0.26
		var phase_offset := fmod(pulse + float(i) * 0.13, 1.0) - 0.5
		var center := side * side_ratio * radius_px + dir * phase_offset * radius_px * 0.72
		var p0 := center - dir * radius_px * 0.28
		var p1 := center + dir * radius_px * 0.28
		draw_line(p0, p1, Color(color.r, color.g, color.b, 0.22 + strength * 0.018), 4.0)
		_draw_arrow_tip(p1, dir, Color(color.r, color.g, color.b, 0.54), 9.0)
	draw_string(ThemeDB.get_fallback_font(), Vector2(-56.0, -6.0), "VECTOR", HORIZONTAL_ALIGNMENT_CENTER, 112.0, 11, Color(color.r, color.g, color.b, 0.76))

func _gravity_visual_direction(mode: String) -> Vector2:
	match mode:
		"right":
			return Vector2.RIGHT
		"left":
			return Vector2.LEFT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
		"up_right":
			return Vector2(1.0, -1.0).normalized()
		"up_left":
			return Vector2(-1.0, -1.0).normalized()
		"down_right":
			return Vector2(1.0, 1.0).normalized()
		"down_left":
			return Vector2(-1.0, 1.0).normalized()
		"forward":
			return Vector2.RIGHT if owner_id == 1 else Vector2.LEFT
		"back":
			return Vector2.LEFT if owner_id == 1 else Vector2.RIGHT
	return Vector2.ZERO

func _draw_arrow_tip(pos: Vector2, dir: Vector2, color: Color, size_value: float) -> void:
	if dir.length() <= 0.01:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	draw_colored_polygon(PackedVector2Array([pos, pos - n * size_value + side * size_value * 0.55, pos - n * size_value - side * size_value * 0.55]), color)

func _field_color() -> Color:
	if field_kind.begins_with("gravity"):
		return Color(0.62, 0.48, 1.0, 1.0)
	match field_kind:
		"coolant":
			return Color(0.18, 0.92, 1.0, 1.0)
		"heat":
			return Color(1.0, 0.32, 0.08, 1.0)
		"gravity":
			return Color(0.62, 0.48, 1.0, 1.0)
		"repulsion":
			return Color(1.0, 0.22, 0.62, 1.0)
		"siphon":
			return Color(1.0, 0.78, 0.12, 1.0)
		"cage":
			return Color(0.42, 0.82, 1.0, 1.0)
		"hack":
			return Color(0.34, 1.0, 0.42, 1.0)
		"jam":
			return Color(0.78, 0.56, 1.0, 1.0)
		"support_ammo":
			return Color(0.86, 0.96, 1.0, 1.0)
		"support_repair":
			return Color(0.34, 1.0, 0.54, 1.0)
		"support_buff":
			return Color(1.0, 0.34, 0.52, 1.0)
		"support_armor":
			return Color(0.36, 0.82, 1.0, 1.0)
		"speed_lane":
			return Color(1.0, 0.86, 0.18, 1.0)
		"one_way_shield":
			return Color(0.52, 0.92, 1.0, 1.0)
	return Color(0.72, 0.92, 1.0, 1.0)
