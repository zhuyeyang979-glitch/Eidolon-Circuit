class_name UnitEditorPowerDockView
extends Control


signal allocation_changed(entry_id: String, ratio: float)
signal allocation_drag_finished(entry_id: String)
signal open_requested()

var ui_language := "zh"
var title := ""
var subtitle := ""
var engine_output := 0.0
var used_ratio := 0.0
var entries: Array = []
var empty_note := ""
var dragging_entry_id := ""
var scroll_offset := 0.0
var last_signature := ""
var last_emitted_ratios := {}

func set_empty(note: String, next_language: String) -> void:
	var signature := "empty|%s|%s" % [next_language, note]
	if signature == last_signature:
		return
	last_signature = signature
	ui_language = next_language
	title = _label("动力预算", "DRIVE BUDGET")
	subtitle = ""
	engine_output = 0.0
	used_ratio = 0.0
	entries = []
	empty_note = note
	scroll_offset = 0.0
	visible = true
	queue_redraw()

func set_allocation_data(next_data: Dictionary, next_language: String) -> void:
	var next_entries := Array(next_data.get("entries", []))
	var signature := "%s|%s|%s|%.2f|%.3f|%s" % [
		next_language,
		String(next_data.get("title", "")),
		String(next_data.get("subtitle", "")),
		float(next_data.get("engine_output", 0.0)),
		float(next_data.get("used_ratio", 0.0)),
		_entries_signature(next_entries),
	]
	if signature == last_signature:
		return
	last_signature = signature
	ui_language = next_language
	title = String(next_data.get("title", _label("动力预算", "DRIVE BUDGET")))
	subtitle = String(next_data.get("subtitle", ""))
	engine_output = maxf(0.0, float(next_data.get("engine_output", 0.0)))
	used_ratio = maxf(0.0, float(next_data.get("used_ratio", 0.0)))
	entries = next_entries.duplicate(true)
	empty_note = ""
	scroll_offset = clampf(scroll_offset, 0.0, _max_scroll())
	visible = true
	queue_redraw()

func _entries_signature(next_entries: Array) -> String:
	var bits: Array = [str(next_entries.size())]
	for i in range(mini(next_entries.size(), 32)):
		if not (next_entries[i] is Dictionary):
			bits.append("_")
			continue
		var entry: Dictionary = next_entries[i]
		bits.append("%s:%s:%.3f:%.1f:%s:%s" % [
			String(entry.get("id", "")),
			String(entry.get("label", "")),
			float(entry.get("ratio", 0.0)),
			float(entry.get("momentum", 0.0)),
			String(entry.get("line", "")),
			str(bool(entry.get("disabled", false))),
		])
	return "|".join(bits)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging_entry_id != "":
		_emit_slider_change(dragging_entry_id, (event as InputEventMouseMotion).position)
		accept_event()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
		scroll_offset = clampf(scroll_offset + direction * 36.0, 0.0, _max_scroll())
		queue_redraw()
		accept_event()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		if dragging_entry_id != "":
			var finished_id := dragging_entry_id
			dragging_entry_id = ""
			allocation_drag_finished.emit(finished_id)
			accept_event()
		return
	if _open_rect().has_point(mouse_event.position):
		open_requested.emit()
		accept_event()
		return
	for i in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		if bool(entry.get("disabled", false)) or bool(entry.get("readonly", false)):
			continue
		var entry_id := String(entry.get("id", ""))
		if entry_id == "":
			continue
		if _entry_slider_rect(i).grow(7.0).has_point(mouse_event.position):
			dragging_entry_id = entry_id
			_emit_slider_change(entry_id, mouse_event.position)
			accept_event()
			return

func _emit_slider_change(entry_id: String, pos: Vector2) -> void:
	var index := _entry_index_for_id(entry_id)
	if index < 0:
		return
	var entry: Dictionary = entries[index] if entries[index] is Dictionary else {}
	var rect := _entry_slider_rect(index)
	var local_ratio := clampf((pos.x - rect.position.x) / maxf(1.0, rect.size.x), 0.0, 1.0)
	var ratio := local_ratio
	if _entry_uses_range_slider(entry):
		var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
		var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
		if max_momentum > min_momentum:
			var momentum := min_momentum + (max_momentum - min_momentum) * local_ratio
			ratio = momentum / maxf(1.0, engine_output)
	if last_emitted_ratios.has(entry_id) and absf(float(last_emitted_ratios[entry_id]) - ratio) < 0.004:
		return
	last_emitted_ratios[entry_id] = ratio
	allocation_changed.emit(entry_id, ratio)

func _draw() -> void:
	if not visible:
		return
	var font := ThemeDB.get_fallback_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.012, 0.018, 0.88), true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), Color(0.36, 0.92, 1.0, 0.52), false, 1.3)
	draw_string(font, Vector2(10.0, 18.0), _trim(title, 20), HORIZONTAL_ALIGNMENT_LEFT, 170.0, 13, Color(1.0, 0.92, 0.42, 1.0))
	if empty_note != "":
		draw_string(font, Vector2(190.0, 18.0), _trim(empty_note, 56), HORIZONTAL_ALIGNMENT_LEFT, size.x - 260.0, 11, Color(0.82, 0.92, 1.0, 0.88))
		_draw_open_button(font)
		return
	var usage := _label("池 %.0f  已用 %.0f%%", "POOL %.0f  USED %.0f%%") % [engine_output, used_ratio * 100.0]
	draw_string(font, Vector2(178.0, 18.0), usage, HORIZONTAL_ALIGNMENT_LEFT, 170.0, 10, Color(0.78, 0.9, 1.0, 0.9))
	draw_string(font, Vector2(352.0, 18.0), _trim(subtitle, 58), HORIZONTAL_ALIGNMENT_LEFT, maxf(90.0, size.x - 430.0), 9, Color(0.68, 0.82, 0.92, 0.78))
	_draw_rows(font)
	_draw_open_button(font)

func _draw_rows(font: Font) -> void:
	var clip_rect := _rows_clip_rect()
	draw_rect(clip_rect, Color(0.0, 0.0, 0.0, 0.24), true)
	for i in range(entries.size()):
		var row := _entry_row_rect(i)
		if not row.intersects(clip_rect):
			continue
		_draw_entry_row(font, i, row)
	if _max_scroll() > 0.5:
		var thumb_h := maxf(18.0, clip_rect.size.y * clip_rect.size.y / maxf(clip_rect.size.y + _max_scroll(), 1.0))
		var thumb_y := clip_rect.position.y + (clip_rect.size.y - thumb_h) * (scroll_offset / maxf(_max_scroll(), 1.0))
		draw_rect(Rect2(Vector2(size.x - 10.0, thumb_y), Vector2(4.0, thumb_h)), Color(0.6, 0.92, 1.0, 0.56), true)

func _draw_entry_row(font: Font, index: int, row: Rect2) -> void:
	var entry: Dictionary = entries[index] if entries[index] is Dictionary else {}
	if entry.is_empty():
		return
	var color: Color = entry.get("color", Color(0.42, 0.86, 1.0, 1.0))
	var disabled := bool(entry.get("disabled", false))
	var readonly := bool(entry.get("readonly", false))
	var over := bool(entry.get("over_budget", false)) or used_ratio > 1.0001
	var ratio := _entry_slider_fill_ratio(entry)
	var bg := Color(0.016, 0.032, 0.044, 0.94)
	if disabled:
		bg = Color(0.026, 0.028, 0.032, 0.82)
	draw_rect(row, bg, true)
	draw_rect(row, Color(0.48, 0.55, 0.62, 0.42) if disabled else Color(color.r, color.g, color.b, 0.42 if readonly else 0.64), false, 1.0)
	var icon_text := _entry_kind_short_label(entry)
	var icon_color := Color(0.58, 0.62, 0.68, 0.8) if disabled else color
	draw_circle(row.position + Vector2(14.0, row.size.y * 0.5), 8.0, Color(icon_color.r, icon_color.g, icon_color.b, 0.32))
	draw_string(font, row.position + Vector2(7.0, 17.0), icon_text, HORIZONTAL_ALIGNMENT_CENTER, 14.0, 10, icon_color)
	draw_string(font, row.position + Vector2(28.0, 14.0), _trim(String(entry.get("label", "")), 18), HORIZONTAL_ALIGNMENT_LEFT, 138.0, 10, Color(0.72, 0.76, 0.8, 0.88) if disabled else Color(0.92, 0.98, 1.0, 0.96))
	draw_string(font, row.position + Vector2(28.0, 28.0), _trim(String(entry.get("line", "")), 24), HORIZONTAL_ALIGNMENT_LEFT, 170.0, 8, Color(0.64, 0.72, 0.78, 0.72) if disabled else Color(0.72, 0.84, 0.94, 0.78))
	var slider_rect := _entry_slider_rect(index)
	draw_rect(slider_rect, Color(0.008, 0.016, 0.022, 0.96), true)
	draw_rect(Rect2(slider_rect.position, Vector2(slider_rect.size.x * ratio, slider_rect.size.y)), Color(0.24, 0.28, 0.32, 0.46) if disabled else (Color(color.r, color.g, color.b, 0.34) if readonly else (Color(1.0, 0.2, 0.12, 0.72) if over else Color(color.r, color.g, color.b, 0.68))), true)
	draw_rect(slider_rect, Color(0.5, 0.56, 0.62, 0.6) if disabled else (Color(1.0, 0.22, 0.14, 0.9) if over else Color(color.r, color.g, color.b, 0.9)), false, 1.0)
	var knob := Vector2(slider_rect.position.x + slider_rect.size.x * ratio, slider_rect.position.y + slider_rect.size.y * 0.5)
	if not readonly:
		draw_circle(knob, 6.0, Color(0.62, 0.68, 0.72, 0.86) if disabled else Color(1.0, 0.94, 0.7, 1.0))
	var value_text := ("固定 %.0f" if ui_language == "zh" else "REQ %.0f") % float(entry.get("momentum", 0.0)) if readonly else "%.0f" % float(entry.get("momentum", 0.0))
	if disabled:
		value_text += "  " + _label("先装引擎", "NEED ENGINE")
	draw_string(font, row.position + Vector2(row.size.x - 112.0, 17.0), value_text, HORIZONTAL_ALIGNMENT_RIGHT, 104.0, 10, Color(0.72, 0.76, 0.8, 0.86) if disabled else Color(1.0, 0.86, 0.42, 0.96))

func _entry_row_rect(index: int) -> Rect2:
	return Rect2(Vector2(10.0, 34.0 + float(index) * 38.0 - scroll_offset), Vector2(size.x - 22.0, 34.0))

func _entry_slider_rect(index: int) -> Rect2:
	var row := _entry_row_rect(index)
	return Rect2(row.position + Vector2(220.0, 9.0), Vector2(maxf(80.0, row.size.x - 342.0), 16.0))

func _rows_clip_rect() -> Rect2:
	return Rect2(Vector2(8.0, 32.0), Vector2(size.x - 18.0, size.y - 40.0))

func _max_scroll() -> float:
	return maxf(0.0, float(entries.size()) * 38.0 - _rows_clip_rect().size.y)

func _open_rect() -> Rect2:
	return Rect2(Vector2(size.x - 60.0, 8.0), Vector2(50.0, 22.0))

func _draw_open_button(font: Font) -> void:
	var rect := _open_rect()
	draw_rect(rect, Color(0.08, 0.14, 0.18, 0.92), true)
	draw_rect(rect, Color(0.44, 0.92, 1.0, 0.72), false, 1.0)
	draw_string(font, rect.position + Vector2(4.0, 14.0), _label("详细", "MORE"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 9, Color(0.9, 0.98, 1.0, 1.0))

func _entry_index_for_id(entry_id: String) -> int:
	for i in range(entries.size()):
		if entries[i] is Dictionary and String(Dictionary(entries[i]).get("id", "")) == entry_id:
			return i
	return -1

func _entry_uses_range_slider(entry: Dictionary) -> bool:
	if bool(entry.get("readonly", false)):
		return false
	if not entry.has("min_momentum") and not entry.has("max_momentum"):
		return false
	var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
	var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
	return max_momentum > min_momentum

func _entry_slider_fill_ratio(entry: Dictionary) -> float:
	if not _entry_uses_range_slider(entry):
		return clampf(float(entry.get("ratio", 0.0)), 0.0, 1.0)
	var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
	var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
	var momentum := maxf(0.0, float(entry.get("momentum", 0.0)))
	return clampf((momentum - min_momentum) / maxf(0.001, max_momentum - min_momentum), 0.0, 1.0)

func _entry_kind_short_label(entry: Dictionary) -> String:
	match String(entry.get("kind", "")):
		"limb":
			return "肢" if ui_language == "zh" else "L"
		"booster_drive":
			return "推" if ui_language == "zh" else "M"
		"booster_boost_brake":
			return "增" if ui_language == "zh" else "B"
		_:
			return "需" if ui_language == "zh" else "R"

func _label(zh: String, en: String) -> String:
	return zh if ui_language == "zh" else en

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
