class_name EditorStatsRailView
extends Control

var entries: Array = []
var header := ""
var status_note := ""
var preview_active := false
var ui_language := "zh"
var scroll_offset := 0.0
var last_stats_signature := ""

func set_stats(next_entries: Array, next_header: String, next_status: String, next_preview_active: bool, next_language: String) -> void:
	var signature := "%s|%s|%s|%s|%s" % [next_header, next_status, str(next_preview_active), next_language, _entries_signature(next_entries)]
	if signature == last_stats_signature:
		return
	last_stats_signature = signature
	entries = next_entries.duplicate(true)
	header = next_header
	status_note = next_status
	preview_active = next_preview_active
	ui_language = next_language
	scroll_offset = clampf(scroll_offset, 0.0, _max_scroll_for_entries())
	queue_redraw()

func _entries_signature(next_entries: Array) -> String:
	var bits: Array = [str(next_entries.size())]
	for i in range(mini(next_entries.size(), 28)):
		if not (next_entries[i] is Dictionary):
			bits.append("_")
			continue
		var entry: Dictionary = next_entries[i]
		bits.append("%s:%s:%s:%s:%s:%s:%s:%s" % [
			String(entry.get("kind", "")),
			String(entry.get("label", "")),
			String(entry.get("section", "")),
			String(entry.get("value_text", "")),
			str(snappedf(float(entry.get("value", 0.0)), 0.01)),
			str(snappedf(float(entry.get("preview", float(entry.get("value", 0.0)))), 0.01)),
			str(bool(entry.get("illegal", false))),
			str(bool(entry.get("pinned", false))),
		])
	return "|".join(bits)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
		scroll_offset = clampf(scroll_offset + direction * 42.0, 0.0, _max_scroll_for_entries())
		queue_redraw()
		accept_event()

func _draw() -> void:
	if not visible:
		return
	var font := ThemeDB.get_fallback_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.006, 0.014, 0.021, 0.88), true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), Color(0.26, 0.86, 1.0, 0.42), false, 1.4)
	draw_string(font, Vector2(10.0, 20.0), _trim(header, 18), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 14, Color(0.92, 0.98, 1.0, 1.0))
	var status_color := Color(1.0, 0.32, 0.22, 1.0) if status_note.begins_with("!") else Color(0.6, 1.0, 0.74, 1.0)
	var status_rect := Rect2(Vector2(9.0, 27.0), Vector2(size.x - 18.0, 18.0))
	draw_rect(status_rect, Color(status_color.r, status_color.g, status_color.b, 0.12), true)
	draw_rect(status_rect, Color(status_color.r, status_color.g, status_color.b, 0.42), false, 1.0)
	draw_string(font, status_rect.position + Vector2(5.0, 13.0), _trim(status_note, 22), HORIZONTAL_ALIGNMENT_LEFT, status_rect.size.x - 10.0, 10, status_color)
	var pinned_entries: Array = []
	var normal_entries: Array = []
	for entry in entries:
		if not (entry is Dictionary):
			continue
		if bool(Dictionary(entry).get("pinned", false)):
			pinned_entries.append(entry)
		else:
			normal_entries.append(entry)
	var y := 54.0
	for entry in pinned_entries:
		_draw_entry(font, entry, y)
		y += _entry_height(entry)
	if not pinned_entries.is_empty():
		draw_line(Vector2(10.0, y - 7.0), Vector2(size.x - 10.0, y - 7.0), Color(0.28, 0.88, 1.0, 0.28), 1.0)
	var normal_start_y := y
	var visible_bottom := size.y - 30.0
	y -= scroll_offset
	for entry in normal_entries:
		var entry_height := _entry_height(entry)
		if y + entry_height >= normal_start_y and y <= visible_bottom:
			_draw_entry(font, entry, y)
		y += entry_height
	_draw_scrollbar(normal_start_y, _entries_height(normal_entries))

func _max_scroll_for_entries() -> float:
	var pinned_count := 0
	var normal_height := 0.0
	for entry in entries:
		if not (entry is Dictionary):
			continue
		if bool(Dictionary(entry).get("pinned", false)):
			pinned_count += 1
		else:
			normal_height += _entry_height(entry)
	var normal_start := 54.0 + float(pinned_count) * 42.0 + (0.0 if pinned_count == 0 else 0.0)
	var viewport_height := maxf(20.0, size.y - 30.0 - normal_start)
	return maxf(0.0, normal_height - viewport_height)

func _draw_scrollbar(normal_start_y: float, normal_height: float) -> void:
	var max_scroll := _max_scroll_for_entries()
	if max_scroll <= 0.1 or normal_height <= 0.0:
		return
	var track := Rect2(Vector2(size.x - 8.0, normal_start_y), Vector2(3.0, maxf(24.0, size.y - 34.0 - normal_start_y)))
	draw_rect(track, Color(0.28, 0.88, 1.0, 0.18), true)
	var thumb_h := clampf(track.size.y * track.size.y / maxf(track.size.y, normal_height), 18.0, track.size.y)
	var t := clampf(scroll_offset / max_scroll, 0.0, 1.0)
	var thumb := Rect2(Vector2(track.position.x - 1.0, track.position.y + (track.size.y - thumb_h) * t), Vector2(5.0, thumb_h))
	draw_rect(thumb, Color(0.28, 0.88, 1.0, 0.72), true)

func _draw_entry(font: Font, entry: Dictionary, y: float) -> void:
	if String(entry.get("kind", "")) == "section":
		_draw_section_entry(font, entry, y)
		return
	if String(entry.get("kind", "")) == "balance":
		_draw_balance_entry(font, entry, y)
		return
	var label := String(entry.get("label", ""))
	var value := float(entry.get("value", 0.0))
	var preview := float(entry.get("preview", value))
	var max_value := maxf(1.0, float(entry.get("max_value", maxf(absf(value), absf(preview)) * 1.2)))
	var unit := String(entry.get("unit", ""))
	var illegal := bool(entry.get("illegal", false))
	var base := Color(1.0, 0.22, 0.18, 1.0) if illegal else Color(0.28, 0.92, 1.0, 1.0)
	var label_color := Color(1.0, 0.44, 0.32, 1.0) if illegal else Color(0.84, 0.92, 0.96, 1.0)
	var value_text := _format_value(value, unit)
	var diff := preview - value
	var diff_text := ""
	if preview_active and absf(diff) >= 0.01:
		diff_text = "  %+0.1f%s" % [diff, unit]
	draw_string(font, Vector2(10.0, y + 11.0), _trim(label, 12), HORIZONTAL_ALIGNMENT_LEFT, 78.0, 10, label_color)
	draw_string(font, Vector2(84.0, y + 11.0), _trim("%s%s" % [value_text, diff_text], 17), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 94.0, 10, Color(1.0, 0.88, 0.34, 1.0) if preview_active and diff_text != "" else Color(0.88, 0.94, 0.98, 1.0))
	var bar_rect := Rect2(Vector2(10.0, y + 18.0), Vector2(size.x - 20.0, 12.0))
	draw_rect(bar_rect, Color(0.0, 0.0, 0.0, 0.42), true)
	var ratio := clampf(value / max_value, 0.0, 1.0)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), base.darkened(0.08), true)
	draw_rect(bar_rect, Color(0.44, 0.58, 0.66, 0.58), false, 1.0)
	if preview_active:
		var preview_ratio := clampf(preview / max_value, 0.0, 1.0)
		var current_x := bar_rect.position.x + bar_rect.size.x * ratio
		var preview_x := bar_rect.position.x + bar_rect.size.x * preview_ratio
		var change_color := Color(1.0, 0.92, 0.22, 0.95) if preview >= value else Color(0.42, 0.72, 1.0, 0.95)
		_draw_dashed_line(Vector2(current_x, bar_rect.position.y + bar_rect.size.y + 3.0), Vector2(preview_x, bar_rect.position.y + bar_rect.size.y + 3.0), change_color, 1.6)
		_draw_dashed_line(Vector2(preview_x, bar_rect.position.y - 2.0), Vector2(preview_x, bar_rect.position.y + bar_rect.size.y + 4.0), change_color, 1.4)
	if illegal:
		draw_rect(Rect2(Vector2(6.0, y - 2.0), Vector2(size.x - 12.0, 36.0)), Color(1.0, 0.1, 0.06, 0.12), true)

func _draw_section_entry(font: Font, entry: Dictionary, y: float) -> void:
	var label := String(entry.get("label", ""))
	var color: Color = entry.get("color", Color(0.36, 0.88, 1.0, 0.86))
	var line_y := y + 15.0
	draw_line(Vector2(10.0, line_y), Vector2(size.x - 10.0, line_y), Color(color.r, color.g, color.b, 0.22), 1.0)
	draw_rect(Rect2(Vector2(10.0, y + 4.0), Vector2(62.0, 17.0)), Color(0.004, 0.014, 0.022, 0.88), true)
	draw_string(font, Vector2(14.0, y + 17.0), _trim(label, 10), HORIZONTAL_ALIGNMENT_LEFT, 76.0, 9, color)

func _draw_balance_entry(font: Font, entry: Dictionary, y: float) -> void:
	var label := String(entry.get("label", ""))
	var supply := float(entry.get("supply", 0.0))
	var demand := float(entry.get("demand", 0.0))
	var preview_supply := float(entry.get("preview_supply", supply))
	var preview_demand := float(entry.get("preview_demand", demand))
	var unit := String(entry.get("unit", ""))
	var margin := supply - demand
	var preview_margin := preview_supply - preview_demand
	var illegal := bool(entry.get("illegal", false)) or margin < 0.0 or (preview_active and preview_margin < 0.0)
	var max_value := maxf(1.0, float(entry.get("max_value", maxf(maxf(supply, demand), maxf(preview_supply, preview_demand)) * 1.18)))
	var supply_label := String(entry.get("supply_label", "供"))
	var demand_label := String(entry.get("demand_label", "需"))
	var surplus_label := String(entry.get("surplus_label", "余量"))
	var shortage_label := String(entry.get("shortage_label", "不足"))
	var label_color := Color(1.0, 0.44, 0.32, 1.0) if illegal else Color(0.84, 0.92, 0.96, 1.0)
	var margin_text := ("%s%s" % [surplus_label, _format_signed_value(margin, unit)]) if margin >= 0.0 else ("%s%s" % [shortage_label, _format_signed_value(margin, unit)])
	var value_text := "%s%s %s%s %s" % [supply_label, _format_value(supply, unit), demand_label, _format_value(demand, unit), margin_text]
	if preview_active and absf(preview_margin - margin) >= 0.01:
		var delta_label := surplus_label if preview_margin >= 0.0 else shortage_label
		value_text = "%s%s→%s" % [delta_label, _format_signed_value(margin, unit), _format_signed_value(preview_margin, unit)]
	draw_string(font, Vector2(10.0, y + 11.0), _trim(label, 12), HORIZONTAL_ALIGNMENT_LEFT, 78.0, 10, label_color)
	draw_string(font, Vector2(84.0, y + 11.0), _trim(value_text, 26), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 94.0, 10, Color(1.0, 0.36, 0.24, 1.0) if illegal else Color(0.88, 0.94, 0.98, 1.0))
	var bar_rect := Rect2(Vector2(10.0, y + 18.0), Vector2(size.x - 20.0, 12.0))
	draw_rect(bar_rect, Color(0.0, 0.0, 0.0, 0.42), true)
	var demand_ratio := clampf(demand / max_value, 0.0, 1.0)
	var supply_ratio := clampf(supply / max_value, 0.0, 1.0)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * demand_ratio, bar_rect.size.y)), Color(1.0, 0.46, 0.16, 0.36), true)
	var supply_color := Color(0.18, 0.95, 0.72, 0.92) if margin >= 0.0 else Color(1.0, 0.18, 0.12, 0.86)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * supply_ratio, bar_rect.size.y)), supply_color, true)
	var demand_x := bar_rect.position.x + bar_rect.size.x * demand_ratio
	draw_line(Vector2(demand_x, bar_rect.position.y - 2.0), Vector2(demand_x, bar_rect.position.y + bar_rect.size.y + 3.0), Color(1.0, 0.86, 0.24, 0.92), 1.5)
	draw_rect(bar_rect, Color(0.44, 0.58, 0.66, 0.58), false, 1.0)
	if preview_active:
		var preview_supply_ratio := clampf(preview_supply / max_value, 0.0, 1.0)
		var current_x := bar_rect.position.x + bar_rect.size.x * supply_ratio
		var preview_x := bar_rect.position.x + bar_rect.size.x * preview_supply_ratio
		var change_color := Color(1.0, 0.92, 0.22, 0.95) if preview_margin >= margin else Color(0.42, 0.72, 1.0, 0.95)
		_draw_dashed_line(Vector2(current_x, bar_rect.position.y + bar_rect.size.y + 3.0), Vector2(preview_x, bar_rect.position.y + bar_rect.size.y + 3.0), change_color, 1.6)
		_draw_dashed_line(Vector2(preview_x, bar_rect.position.y - 2.0), Vector2(preview_x, bar_rect.position.y + bar_rect.size.y + 4.0), change_color, 1.4)
	if illegal:
		draw_rect(Rect2(Vector2(6.0, y - 2.0), Vector2(size.x - 12.0, 36.0)), Color(1.0, 0.1, 0.06, 0.12), true)

func _entry_height(entry: Dictionary) -> float:
	if String(entry.get("kind", "")) == "section":
		return 24.0
	return 42.0

func _entries_height(source_entries: Array) -> float:
	var total := 0.0
	for raw_entry in source_entries:
		if raw_entry is Dictionary:
			total += _entry_height(raw_entry)
	return total

func _format_value(value: float, unit: String) -> String:
	if unit == "m":
		return "%.2f%s" % [value, unit]
	if unit == "x":
		return "%.2f%s" % [value, unit]
	return "%.0f%s" % [value, unit]

func _format_signed_value(value: float, unit: String) -> String:
	if unit == "m":
		return "%+.2f%s" % [value, unit]
	if unit == "x":
		return "%+.2f%s" % [value, unit]
	return "%+.0f%s" % [value, unit]

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var delta := to - from
	var length := delta.length()
	if length <= 0.01:
		draw_circle(from, width, color)
		return
	var dir := delta / length
	var cursor := 0.0
	while cursor < length:
		var next := minf(cursor + 5.0, length)
		draw_line(from + dir * cursor, from + dir * next, color, width)
		cursor += 9.0

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
