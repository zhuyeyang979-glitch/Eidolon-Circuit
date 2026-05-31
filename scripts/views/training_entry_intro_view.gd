extends Control
class_name TrainingEntryIntroView

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")


var entries: Array = []
var language := "zh"
var visible_until_msec := 0

func set_entries(next_entries: Array, next_language: String, duration_sec: float = 3.0) -> void:
	entries = next_entries.duplicate(true)
	language = next_language
	visible_until_msec = Time.get_ticks_msec() + int(maxf(0.2, duration_sec) * 1000.0)
	visible = not entries.is_empty()
	set_process(visible)
	queue_redraw()

func clear_intro() -> void:
	entries = []
	visible_until_msec = 0
	visible = false
	set_process(false)
	queue_redraw()

func _process(_delta: float) -> void:
	if visible_until_msec > 0 and Time.get_ticks_msec() >= visible_until_msec:
		clear_intro()

func _draw() -> void:
	if entries.is_empty():
		return
	var font := ThemeDB.get_fallback_font()
	var panel_count := entries.size()
	var panel_width := minf(376.0, (size.x - 72.0) / maxf(1.0, float(panel_count)))
	var panel_height := 126.0
	var total_width := panel_width * float(panel_count) + 16.0 * float(maxi(0, panel_count - 1))
	var start := Vector2(size.x * 0.5 - total_width * 0.5, 92.0)
	for i in range(panel_count):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var rect := Rect2(start + Vector2(float(i) * (panel_width + 16.0), 0.0), Vector2(panel_width, panel_height))
		var player_id := int(entry.get("player_id", i + 1))
		var base := Color(0.24, 0.86, 1.0, 0.92) if player_id == 1 else Color(1.0, 0.28, 0.44, 0.92)
		draw_rect(rect, Color(0.004, 0.012, 0.02, 0.84), true)
		draw_rect(rect, base, false, 1.5)
		var title := String(entry.get("name", "UNIT"))
		var label := String(entry.get("label", "P%d" % player_id))
		draw_string(font, rect.position + Vector2(14.0, 22.0), _trim(label, 18), HORIZONTAL_ALIGNMENT_LEFT, 76.0, 12, Color(base.r, base.g, base.b, 1.0))
		draw_string(font, rect.position + Vector2(86.0, 22.0), _trim(title, 30), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 100.0, 15, Color(0.94, 0.98, 1.0, 1.0))
		var thumb_rect := Rect2(rect.position + Vector2(14.0, 36.0), Vector2(rect.size.x - 28.0, rect.size.y - 50.0))
		_draw_unit_thumbnail(thumb_rect, entry, base)

func _draw_unit_thumbnail(rect: Rect2, entry: Dictionary, base: Color) -> void:
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.24), true)
	draw_rect(rect, Color(base.r, base.g, base.b, 0.28), false, 1.0)
	if bool(entry.get("training_ball_dummy", false)):
		var radius_m := maxf(0.01, float(entry.get("dummy_radius", 0.6)))
		var radius_ratio := clampf(radius_m / 2.0, 0.18, 1.0)
		var visual_radius := minf(rect.size.x, rect.size.y) * lerpf(0.24, 0.44, radius_ratio)
		var center := rect.get_center()
		draw_circle(center, visual_radius, Color(base.r, base.g, base.b, 0.52))
		draw_circle(center + Vector2(-visual_radius * 0.24, -visual_radius * 0.28), visual_radius * 0.34, Color(1.0, 1.0, 1.0, 0.16))
		draw_arc(center, visual_radius, 0.0, TAU, 42, base.lerp(Color.WHITE, 0.26), 2.0)
		draw_arc(center, visual_radius * 0.68, -PI * 0.9, PI * 0.9, 32, Color(base.r, base.g, base.b, 0.42), 1.2)
		draw_line(center + Vector2(-visual_radius, 0.0), center + Vector2(visual_radius, 0.0), Color(1.0, 1.0, 1.0, 0.18), 1.0)
		return
	var segments: Array = Array(entry.get("segments", []))
	if segments.is_empty():
		draw_circle(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.22, Color(base.r, base.g, base.b, 0.78))
		return
	var bounds := _segment_bounds(segments)
	var fit_rect := rect.grow(-10.0)
	var scale := minf(fit_rect.size.x / maxf(0.001, bounds.size.x), fit_rect.size.y / maxf(0.001, bounds.size.y))
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = Dictionary(raw_segment).duplicate(true)
		var a := _segment_local_point(segment, "a_local", "a")
		var b := _segment_local_point(segment, "b_local", "b")
		segment["a"] = fit_rect.get_center() + (a - bounds.get_center()) * scale
		segment["b"] = fit_rect.get_center() + (b - bounds.get_center()) * scale
		segment["radius"] = maxf(2.0, float(segment.get("radius", 0.025)) * scale)
		var part_kind := String(segment.get("part_kind", "limb_muscle"))
		var material := Color(0.45, 0.62, 0.78, 0.9)
		var primary := base.lerp(Color.WHITE, 0.08)
		if part_kind == "torso":
			material = base.lerp(Color(0.42, 0.54, 0.66, 1.0), 0.38)
		AssemblyBoardRenderer.draw_runtime_segment(self, segment, Vector2.ZERO, 0.0, 1.0, material, primary)

func _segment_bounds(segments: Array) -> Rect2:
	var first := true
	var min_point := Vector2.ZERO
	var max_point := Vector2.ZERO
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		var radius := maxf(0.0, float(segment.get("radius", 0.025)))
		for point in _segment_local_bound_points(segment):
			if first:
				min_point = point - Vector2(radius, radius)
				max_point = point + Vector2(radius, radius)
				first = false
			else:
				min_point.x = minf(min_point.x, point.x - radius)
				min_point.y = minf(min_point.y, point.y - radius)
				max_point.x = maxf(max_point.x, point.x + radius)
				max_point.y = maxf(max_point.y, point.y + radius)
	if first:
		return Rect2(Vector2(-1.0, -1.0), Vector2(2.0, 2.0))
	var rect := Rect2(min_point, max_point - min_point)
	if rect.size.x < 0.05:
		rect.size.x = 0.05
	if rect.size.y < 0.05:
		rect.size.y = 0.05
	return rect.grow(maxf(rect.size.x, rect.size.y) * 0.08 + 0.08)

func _segment_local_bound_points(segment: Dictionary) -> Array:
	var points: Array = []
	var polygon = segment.get("polygon_local", [])
	if polygon is Array:
		for raw_point in Array(polygon):
			if raw_point is Vector2:
				points.append(raw_point)
			elif raw_point is Dictionary:
				points.append(Vector2(float(raw_point.get("x", 0.0)), float(raw_point.get("y", 0.0))))
	elif polygon is PackedVector2Array:
		for raw_point in polygon:
			points.append(raw_point)
	if points.is_empty():
		points.append(_segment_local_point(segment, "a_local", "a"))
		points.append(_segment_local_point(segment, "b_local", "b"))
	return points

func _segment_local_point(segment: Dictionary, primary_key: String, fallback_key: String) -> Vector2:
	var value = segment.get(primary_key, segment.get(fallback_key, Vector2.ZERO))
	return value if value is Vector2 else Vector2.ZERO

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
