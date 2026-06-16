class_name EditorPartHoverPopupView
extends Control

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")
const PartArt = preload("res://scripts/part_art.gd")
const PartPreviewIconView = preload("res://scripts/views/catalog/part_preview_icon_view.gd")

signal close_requested(suppress_token: String)

var slot_key := ""
var part := {}
var title := ""
var subtitle := ""
var detail_lines: Array = []
var stat_entries: Array = []
var ui_language := "zh"
var last_part_signature := ""
var preview_icon: PartPreviewIconView
var pinned := false
var suppress_token := ""
var detail_scroll_offset := 0.0

func _ready() -> void:
	_ensure_preview_icon()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_preview_icon()
		detail_scroll_offset = clampf(detail_scroll_offset, 0.0, _max_detail_scroll())

func set_part(next_slot: String, next_part: Dictionary, next_title: String, next_subtitle: String, next_lines: Array, next_language: String, next_stat_entries: Array = [], next_pinned: bool = false, next_suppress_token: String = "") -> void:
	_ensure_preview_icon()
	var signature := "%s|%s|%s|%s|%s|%d|%d|%s|%s|%s|%s|%s" % [
		next_slot,
		next_language,
		next_title,
		next_subtitle,
		String(next_part.get("name", "")),
		next_lines.size(),
		next_stat_entries.size(),
		String(next_part.get("size_tier", next_part.get("size_class", next_part.get("slot_volume_tier", "")))),
		String(next_part.get("shape", "")),
		String(next_part.get("damage_type", next_part.get("projectile_damage_type", ""))),
		str(next_pinned),
		next_suppress_token,
	]
	if visible and signature == last_part_signature:
		return
	last_part_signature = signature
	slot_key = next_slot
	part = next_part
	title = next_title
	subtitle = next_subtitle
	detail_lines = next_lines.duplicate(true)
	stat_entries = next_stat_entries.duplicate(true)
	ui_language = next_language
	pinned = next_pinned
	suppress_token = next_suppress_token
	detail_scroll_offset = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP if pinned else Control.MOUSE_FILTER_IGNORE
	visible = true
	_sync_preview_icon(true)
	queue_redraw()

func clear_card() -> void:
	if not visible and last_part_signature == "":
		return
	last_part_signature = ""
	visible = false
	pinned = false
	suppress_token = ""
	detail_scroll_offset = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview_icon != null:
		preview_icon.visible = false
		preview_icon.clear_preview()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not pinned:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _detail_rect().has_point(mouse_event.position):
				var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				detail_scroll_offset = clampf(detail_scroll_offset + direction * 34.0, 0.0, _max_detail_scroll())
				queue_redraw()
				accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			close_requested.emit(suppress_token)
			accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and _close_rect().has_point(mouse_event.position):
			close_requested.emit(suppress_token)
			accept_event()
			return

func _ensure_preview_icon() -> void:
	if preview_icon != null:
		return
	preview_icon = PartPreviewIconView.new()
	preview_icon.name = "HoverPartPreviewIcon"
	add_child(preview_icon)
	_sync_preview_icon(true)

func _hover_art_rect() -> Rect2:
	return Rect2(Vector2(18.0, 62.0), Vector2(size.x - 36.0, 112.0))

func _close_rect() -> Rect2:
	return Rect2(Vector2(size.x - 34.0, 10.0), Vector2(22.0, 22.0))

func _detail_rect() -> Rect2:
	return Rect2(Vector2(18.0, 328.0), Vector2(size.x - 36.0, size.y - 346.0))

func _max_detail_scroll() -> float:
	var line_height := 17.0
	var content_h := float(detail_lines.size()) * line_height + 12.0
	return maxf(0.0, content_h - maxf(12.0, _detail_rect().size.y - 18.0))

func _sync_preview_icon(force_redraw: bool = false) -> void:
	if preview_icon == null:
		return
	var art_rect := _hover_art_rect()
	preview_icon.position = art_rect.position
	preview_icon.size = art_rect.size
	preview_icon.visible = visible and not part.is_empty() and slot_key != ""
	if preview_icon.visible:
		var signature := "%s|%s|%s|%s|%s|%s" % [
			slot_key,
			String(part.get("name", "")),
			PartArt.normalized_size_tier(part),
			String(part.get("shape", "")),
			String(part.get("material_visual", part.get("material_class", ""))),
			String(part.get("damage_type", part.get("projectile_damage_type", ""))),
		]
		preview_icon.set_preview(slot_key, part, false, 0.0, signature)
		if force_redraw:
			preview_icon.queue_redraw()
	else:
		preview_icon.clear_preview()

func _draw() -> void:
	if not visible:
		return
	var font := ThemeDB.get_fallback_font()
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.004, 0.01, 0.018, 0.96), true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), _slot_color().lerp(Color.WHITE, 0.18), false, 2.0)
	var title_width := size.x - 36.0 - (32.0 if pinned else 0.0)
	draw_string(font, Vector2(18.0, 27.0), _trim(title, 36), HORIZONTAL_ALIGNMENT_LEFT, title_width, 17, Color(0.95, 0.98, 1.0, 1.0))
	draw_string(font, Vector2(18.0, 48.0), _trim(subtitle, 54), HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 10, Color(1.0, 0.86, 0.26, 1.0))
	if pinned:
		draw_rect(_close_rect(), Color(0.22, 0.035, 0.04, 0.96), true)
		draw_rect(_close_rect(), Color(1.0, 0.34, 0.24, 0.9), false, 1.0)
		draw_string(font, _close_rect().position + Vector2(3.0, 16.0), "X", HORIZONTAL_ALIGNMENT_CENTER, _close_rect().size.x - 6.0, 11, Color(1.0, 0.86, 0.8, 1.0))
	var art_rect := Rect2(Vector2(18.0, 62.0), Vector2(size.x - 36.0, 112.0))
	draw_rect(art_rect, Color(0.008, 0.018, 0.03, 0.94), true)
	draw_rect(art_rect, Color(0.24, 0.4, 0.52, 0.54), false, 1.0)
	var stat_rect := Rect2(Vector2(18.0, 184.0), Vector2(size.x - 36.0, 132.0))
	draw_rect(stat_rect, Color(0.0, 0.0, 0.0, 0.26), true)
	draw_rect(stat_rect, Color(0.34, 0.58, 0.72, 0.34), false, 1.0)
	_draw_metric_tiles(font, stat_rect)
	var data_rect := _detail_rect()
	draw_rect(data_rect, Color(0.0, 0.0, 0.0, 0.34), true)
	draw_rect(data_rect, Color(0.34, 0.58, 0.72, 0.22), false, 1.0)
	if pinned and _max_detail_scroll() > 0.1:
		var track := Rect2(Vector2(data_rect.end.x - 6.0, data_rect.position.y + 4.0), Vector2(3.0, data_rect.size.y - 8.0))
		var thumb_h := clampf(track.size.y * (track.size.y / maxf(track.size.y, track.size.y + _max_detail_scroll())), 18.0, track.size.y)
		var thumb_y := track.position.y + (track.size.y - thumb_h) * (detail_scroll_offset / maxf(0.001, _max_detail_scroll()))
		draw_rect(track, Color(0.2, 0.28, 0.32, 0.45), true)
		draw_rect(Rect2(Vector2(track.position.x, thumb_y), Vector2(track.size.x, thumb_h)), _slot_color().lerp(Color.WHITE, 0.18), true)
	var y := data_rect.position.y + 17.0 - detail_scroll_offset
	for line in detail_lines:
		if y < data_rect.position.y + 8.0:
			y += 17.0
			continue
		if y > data_rect.end.y - 6.0:
			break
		var line_text := String(line)
		var line_color := Color(1.0, 0.36, 0.24, 1.0) if line_text.begins_with("!") else Color(0.82, 0.9, 0.96, 1.0)
		if line_text.begins_with("#"):
			var chip_text := line_text.substr(1).strip_edges()
			var chip_w := minf(data_rect.size.x - 20.0, maxf(88.0, float(chip_text.length()) * 7.2 + 18.0))
			var chip_rect := Rect2(Vector2(data_rect.position.x + 10.0, y - 12.0), Vector2(chip_w, 18.0))
			draw_rect(chip_rect, _slot_color().lerp(Color(0.02, 0.05, 0.07, 1.0), 0.56), true)
			draw_rect(chip_rect, _slot_color().lerp(Color.WHITE, 0.26), false, 1.0)
			draw_string(font, chip_rect.position + Vector2(8.0, 13.0), _trim(chip_text, 38), HORIZONTAL_ALIGNMENT_LEFT, chip_rect.size.x - 14.0, 10, Color(0.9, 0.98, 1.0, 0.96))
		else:
			draw_string(font, Vector2(data_rect.position.x + 10.0, y), _trim(line_text, 62), HORIZONTAL_ALIGNMENT_LEFT, data_rect.size.x - 20.0, 11, line_color)
		y += 17.0

func _draw_metric_tiles(font: Font, rect: Rect2) -> void:
	var columns := 4
	var rows := 2
	var cell_w := rect.size.x / float(columns)
	var cell_h := rect.size.y / float(rows)
	for i in range(mini(stat_entries.size(), columns * rows)):
		var entry: Dictionary = stat_entries[i]
		var col := i % columns
		var row := floori(float(i) / float(columns))
		var cell := Rect2(rect.position + Vector2(float(col) * cell_w + 5.0, float(row) * cell_h + 6.0), Vector2(cell_w - 10.0, cell_h - 11.0))
		_draw_metric_tile(font, cell, entry)

func _draw_metric_tile(font: Font, rect: Rect2, entry: Dictionary) -> void:
	var label := String(entry.get("label", ""))
	var value := float(entry.get("value", 0.0))
	var max_value := maxf(1.0, float(entry.get("max_value", absf(value) * 1.2)))
	var unit := String(entry.get("unit", ""))
	var color: Color = entry.get("color", _slot_color())
	var icon := String(entry.get("icon", ""))
	var value_text := _format_value(value, unit)
	draw_rect(rect, Color(0.01, 0.02, 0.032, 0.86), true)
	var border_color := color.lerp(Color.WHITE, 0.2)
	border_color.a = 0.38
	draw_rect(rect, border_color, false, 1.0)
	_draw_metric_icon(icon, rect.position + Vector2(15.0, 18.0), 10.0, color)
	draw_string(font, rect.position + Vector2(31.0, 15.0), _trim(label, 9), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 35.0, 9, Color(0.82, 0.9, 0.96, 1.0))
	value_text = String(entry.get("value_text", value_text))
	draw_string(font, rect.position + Vector2(31.0, 31.0), _trim(value_text, 10), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 35.0, 12, Color(1.0, 0.9, 0.34, 1.0))
	var bar_rect := Rect2(rect.position + Vector2(7.0, rect.size.y - 8.0), Vector2(rect.size.x - 14.0, 4.0))
	draw_rect(bar_rect, Color(0.0, 0.0, 0.0, 0.5), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(value / max_value, 0.0, 1.0), bar_rect.size.y)), color, true)
	draw_rect(bar_rect, Color(0.58, 0.72, 0.84, 0.45), false, 1.0)

func _draw_metric_icon(icon: String, center: Vector2, radius: float, color: Color) -> void:
	var dark := Color(0.0, 0.0, 0.0, 0.58)
	draw_circle(center, radius, dark)
	match icon:
		"cost":
			draw_circle(center, radius * 0.72, color)
			draw_arc(center, radius * 0.44, 0.0, TAU, 20, Color(0.02, 0.04, 0.06, 0.9), 1.4)
		"mass":
			draw_colored_polygon([center + Vector2(-radius * 0.7, radius * 0.6), center + Vector2(radius * 0.7, radius * 0.6), center + Vector2(radius * 0.42, -radius * 0.62), center + Vector2(-radius * 0.42, -radius * 0.62)], color)
		"hp":
			draw_line(center + Vector2(-radius * 0.72, 0.0), center + Vector2(radius * 0.72, 0.0), color, 3.0)
			draw_line(center + Vector2(0.0, -radius * 0.72), center + Vector2(0.0, radius * 0.72), color, 3.0)
		"range", "length":
			draw_line(center + Vector2(-radius * 0.82, 0.0), center + Vector2(radius * 0.82, 0.0), color, 2.2)
			draw_line(center + Vector2(radius * 0.82, 0.0), center + Vector2(radius * 0.48, -radius * 0.28), color, 2.2)
			draw_line(center + Vector2(radius * 0.82, 0.0), center + Vector2(radius * 0.48, radius * 0.28), color, 2.2)
		"port":
			for a in [0.0, PI * 0.5, PI, PI * 1.5]:
				draw_circle(center + Vector2(cos(a), sin(a)) * radius * 0.58, radius * 0.2, color)
		"slot":
			draw_rect(Rect2(center - Vector2(radius * 0.62, radius * 0.48), Vector2(radius * 1.24, radius * 0.96)), color, false, 2.0)
		"heat":
			draw_colored_polygon([center + Vector2(0.0, -radius * 0.84), center + Vector2(radius * 0.58, radius * 0.18), center + Vector2(0.0, radius * 0.78), center + Vector2(-radius * 0.5, radius * 0.08)], color)
		"power":
			draw_line(center + Vector2(-radius * 0.32, radius * 0.78), center + Vector2(radius * 0.16, -radius * 0.08), color, 3.0)
			draw_line(center + Vector2(radius * 0.16, -radius * 0.08), center + Vector2(-radius * 0.08, -radius * 0.08), color, 3.0)
			draw_line(center + Vector2(-radius * 0.08, -radius * 0.08), center + Vector2(radius * 0.34, -radius * 0.78), color, 3.0)
		"ammo":
			draw_rect(Rect2(center + Vector2(-radius * 0.28, -radius * 0.72), Vector2(radius * 0.56, radius * 1.34)), color, true)
			draw_colored_polygon([center + Vector2(-radius * 0.28, -radius * 0.72), center + Vector2(radius * 0.28, -radius * 0.72), center + Vector2(0.0, -radius)], color.lerp(Color.WHITE, 0.25))
		"cool":
			for a in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
				draw_line(center, center + Vector2(cos(a), sin(a)) * radius * 0.82, color, 2.0)
			draw_circle(center, radius * 0.22, color)
		"boost":
			draw_colored_polygon([center + Vector2(-radius * 0.8, -radius * 0.42), center + Vector2(radius * 0.72, 0.0), center + Vector2(-radius * 0.8, radius * 0.42)], color)
		"action":
			draw_arc(center, radius * 0.68, -PI * 0.75, PI * 0.72, 24, color, 2.4)
			draw_line(center + Vector2(radius * 0.58, radius * 0.44), center + Vector2(radius * 0.84, radius * 0.16), color, 2.4)
		"input":
			draw_string(ThemeDB.get_fallback_font(), center + Vector2(-radius * 0.38, radius * 0.42), "X", HORIZONTAL_ALIGNMENT_CENTER, radius * 0.8, int(radius * 1.2), color)
		"joint_ball":
			draw_circle(center, radius * 0.54, color)
			draw_circle(center, radius * 0.2, dark)
		"joint_linear":
			draw_line(center + Vector2(-radius * 0.72, -radius * 0.22), center + Vector2(radius * 0.72, -radius * 0.22), color, 2.0)
			draw_line(center + Vector2(-radius * 0.72, radius * 0.22), center + Vector2(radius * 0.72, radius * 0.22), color, 2.0)
			draw_rect(Rect2(center + Vector2(-radius * 0.18, -radius * 0.44), Vector2(radius * 0.42, radius * 0.88)), color, true)
		"joint_hybrid":
			draw_circle(center + Vector2(-radius * 0.24, 0.0), radius * 0.36, color)
			draw_line(center + Vector2(-radius * 0.02, 0.0), center + Vector2(radius * 0.74, 0.0), color, 2.2)
			draw_rect(Rect2(center + Vector2(radius * 0.18, -radius * 0.22), Vector2(radius * 0.42, radius * 0.44)), color, true)
		"weapon_blade":
			draw_colored_polygon([center + Vector2(-radius * 0.7, radius * 0.46), center + Vector2(radius * 0.82, -radius * 0.18), center + Vector2(radius * 0.36, radius * 0.5)], color)
			draw_line(center + Vector2(-radius * 0.64, radius * 0.58), center + Vector2(-radius * 0.18, radius * 0.78), color, 2.0)
		"weapon_blunt":
			draw_line(center + Vector2(-radius * 0.62, radius * 0.62), center + Vector2(radius * 0.48, -radius * 0.48), color, 2.4)
			draw_rect(Rect2(center + Vector2(radius * 0.14, -radius * 0.74), Vector2(radius * 0.58, radius * 0.44)), color, true)
		"weapon_gun":
			draw_rect(Rect2(center + Vector2(-radius * 0.7, -radius * 0.2), Vector2(radius * 1.2, radius * 0.4)), color, true)
			draw_line(center + Vector2(radius * 0.44, 0.0), center + Vector2(radius * 0.86, 0.0), color, 2.0)
			draw_line(center + Vector2(-radius * 0.24, radius * 0.2), center + Vector2(-radius * 0.04, radius * 0.72), color, 2.0)
		"weapon_shield":
			draw_colored_polygon([center + Vector2(0.0, -radius * 0.86), center + Vector2(radius * 0.66, -radius * 0.32), center + Vector2(radius * 0.46, radius * 0.54), center + Vector2(0.0, radius * 0.86), center + Vector2(-radius * 0.46, radius * 0.54), center + Vector2(-radius * 0.66, -radius * 0.32)], color)
			draw_line(center + Vector2(0.0, -radius * 0.54), center + Vector2(0.0, radius * 0.46), dark, 1.6)
		"weapon_hammer":
			draw_line(center + Vector2(-radius * 0.56, radius * 0.7), center + Vector2(radius * 0.36, -radius * 0.22), color, 2.6)
			draw_rect(Rect2(center + Vector2(radius * 0.04, -radius * 0.76), Vector2(radius * 0.76, radius * 0.42)), color, true)
		"contact":
			draw_circle(center + Vector2(-radius * 0.26, 0.0), radius * 0.34, color)
			draw_circle(center + Vector2(radius * 0.3, 0.0), radius * 0.34, color.lerp(Color.WHITE, 0.2))
		"projectile":
			draw_line(center + Vector2(-radius * 0.72, radius * 0.34), center + Vector2(radius * 0.72, -radius * 0.34), color, 2.2)
			draw_line(center + Vector2(radius * 0.72, -radius * 0.34), center + Vector2(radius * 0.32, -radius * 0.42), color, 2.2)
			draw_line(center + Vector2(radius * 0.72, -radius * 0.34), center + Vector2(radius * 0.54, radius * 0.04), color, 2.2)
		_:
			draw_circle(center, radius * 0.56, color)

func _format_value(value: float, unit: String) -> String:
	if unit == "m" or unit == "x":
		return "%.2f%s" % [value, unit]
	if unit == "%":
		return "%.0f%%" % value
	return "%.0f%s" % [value, unit]

func _draw_large_art(rect: Rect2) -> void:
	if not AssemblyBoardRenderer.draw_part_preview(self, rect, slot_key, part, false, 0.0):
		draw_rect(rect.grow(-6.0), _slot_color().darkened(0.25), true)
		draw_rect(rect.grow(-6.0), _slot_color().lerp(Color.WHITE, 0.3), false, 1.5)

func _slot_color() -> Color:
	match slot_key:
		"special":
			return Color(1.0, 0.82, 0.22, 1.0)
		"joint":
			return Color(0.24, 0.82, 1.0, 1.0)
		"limb_muscle":
			return Color(0.76, 0.9, 1.0, 1.0)
		"booster":
			return Color(1.0, 0.42, 0.12, 1.0)
		"engine":
			return Color(0.58, 0.42, 1.0, 1.0)
		"cooling":
			return Color(0.28, 0.96, 0.72, 1.0)
		"module":
			return Color(0.92, 0.94, 1.0, 1.0)
	return _damage_color(String(part.get("projectile_damage_type", part.get("damage_type", ""))))

func _damage_color(damage_type: String) -> Color:
	match damage_type:
		"bullet":
			return Color(1.0, 0.16, 0.1, 1.0)
		"chemical":
			return Color(0.95, 0.92, 0.18, 1.0)
		"laser":
			return Color(0.18, 0.84, 1.0, 1.0)
		"pierce":
			return Color(0.88, 0.24, 1.0, 1.0)
		"tear":
			return Color(0.16, 1.0, 0.62, 1.0)
		"explosive":
			return Color(1.0, 0.48, 0.14, 1.0)
	return Color(0.78, 0.84, 0.9, 1.0)

func _booster_flame_color() -> Color:
	var flame := String(part.get("flame_color", "")).to_lower()
	var style := String(part.get("thruster_family", "")).to_lower()
	if flame.contains("red") or style.contains("burst") or style.contains("overburn"):
		return Color(1.0, 0.16, 0.08, 0.92)
	if flame.contains("yellow") or style.contains("sustain"):
		return Color(1.0, 0.86, 0.18, 0.92)
	return Color(0.24, 0.72, 1.0, 0.92)

func _draw_triangle(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(3):
		var angle := rotation + TAU * float(i) / 3.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

func _saddle_polygon(center: Vector2, axis: Vector2, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var pts := PackedVector2Array()
	for local in PartArt.torso_hull_local_points(part, length, front_width, rear_width):
		var p: Vector2 = local
		pts.append(center + forward * p.x + right * p.y)
	return pts

func _saddle_port_positions(center: Vector2, axis: Vector2, port_count: int, length: float, front_width: float, rear_width: float) -> Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var positions: Array = []
	for local in PartArt.torso_hull_port_local_offsets(part, port_count, length, front_width, rear_width):
		var p: Vector2 = local
		positions.append(center + forward * p.x + right * p.y)
	return positions

func _regular_polygon(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(maxi(3, sides)):
		var angle := -PI * 0.5 + TAU * float(i) / float(maxi(3, sides))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
