extends Control
class_name SortieThumbView

var entry := {}
var stats := {}
var player_id := 1
var slot_index := 0
var status := "reserve"
var language := "zh"
var flash_until_msec := 0


func set_entry(next_player: int, next_slot: int, next_entry: Dictionary, next_stats: Dictionary, next_status: String, next_language: String) -> void:
	player_id = next_player
	slot_index = next_slot
	entry = next_entry.duplicate(true)
	stats = next_stats.duplicate(true)
	status = next_status
	language = next_language
	queue_redraw()


func trigger_flash() -> void:
	flash_until_msec = Time.get_ticks_msec() + 780
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	if flash_until_msec <= Time.get_ticks_msec():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if entry.is_empty():
		return
	var flashing := flash_until_msec > Time.get_ticks_msec()
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.026) if flashing else 0.0
	var role := String(entry.get("role", "hero"))
	var base := Color(0.24, 0.86, 1.0, 1.0) if player_id == 1 else Color(1.0, 0.28, 0.44, 1.0)
	var bg := Color(0.012, 0.02, 0.028, 0.62)
	if status == "live":
		bg = bg.lerp(base, 0.22)
	elif status == "pending":
		bg = bg.lerp(Color(1.0, 0.82, 0.24, 1.0), 0.2)
	draw_rect(Rect2(Vector2.ZERO, size), bg, true)
	draw_rect(Rect2(Vector2.ZERO, size), base.lerp(Color.WHITE, 0.22 if flashing else 0.0), false, 1.2 + pulse * 2.2)
	_draw_icon(role, size * 0.5 + Vector2(0.0, -3.0), minf(size.x, size.y) * 0.31, base, pulse)
	draw_string(ThemeDB.get_fallback_font(), Vector2(4.0, size.y - 4.0), "%d %s" % [slot_index + 1, _role_short(role)], HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 9, Color(0.9, 0.94, 0.98, 0.92))
	if status == "pending":
		draw_string(ThemeDB.get_fallback_font(), Vector2(4.0, 11.0), "入" if language == "zh" else "IN", HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 9, Color(1.0, 0.9, 0.35, 1.0))


func _role_short(role: String) -> String:
	if language == "zh":
		return {"hero": "英", "puppet": "傀", "barrier": "界"}.get(role, "单")
	return {"hero": "H", "puppet": "P", "barrier": "B"}.get(role, "U")


func _draw_icon(role: String, center: Vector2, radius: float, base: Color, pulse: float) -> void:
	if role == "barrier":
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(base.r, base.g, base.b, 0.24 + pulse * 0.18), true)
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), base, false, 2.0)
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), base, 1.5)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), base, 1.5)
	elif role == "puppet":
		var pts := PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius, 0.0), center + Vector2(0.0, radius), center + Vector2(-radius, 0.0)])
		draw_colored_polygon(pts, base.lerp(Color.WHITE, pulse * 0.22))
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, Color.WHITE, 1.4)
	else:
		draw_circle(center, radius, base.lerp(Color.WHITE, pulse * 0.25))
		draw_circle(center, radius * 0.42, Color(0.0, 0.0, 0.0, 0.64))
		draw_arc(center, radius * 1.18, -PI * 0.78, PI * 0.78, 18, Color.WHITE, 1.3)
