extends RefCounted
class_name AssemblyTemplateOverlayRenderer


func overlay_panel_rect(canvas_size: Vector2) -> Rect2:
	var panel_width := clampf(canvas_size.x * 0.64, 420.0, 604.0)
	if canvas_size.x < 520.0:
		panel_width = maxf(280.0, canvas_size.x - 24.0)
	var panel_height := 218.0
	var panel_y := clampf(82.0, 16.0, maxf(16.0, canvas_size.y - panel_height - 48.0))
	var panel_x := clampf((canvas_size.x - panel_width) * 0.5, 12.0, maxf(12.0, canvas_size.x - panel_width - 12.0))
	return Rect2(Vector2(panel_x, panel_y), Vector2(panel_width, panel_height))


func collapsed_panel_rect(canvas_size: Vector2) -> Rect2:
	var panel_width := clampf(canvas_size.x * 0.34, 252.0, 336.0)
	if canvas_size.x < 420.0:
		panel_width = maxf(220.0, canvas_size.x - 24.0)
	var panel_height := 38.0
	var expanded := overlay_panel_rect(canvas_size)
	var panel_x := clampf(expanded.position.x + expanded.size.x - panel_width, 12.0, maxf(12.0, canvas_size.x - panel_width - 12.0))
	return Rect2(Vector2(panel_x, expanded.position.y), Vector2(panel_width, panel_height))


func toggle_button_rect(canvas_size: Vector2, collapsed: bool = false) -> Rect2:
	var panel := collapsed_panel_rect(canvas_size) if collapsed else overlay_panel_rect(canvas_size)
	return Rect2(panel.position + Vector2(panel.size.x - 36.0, 6.0), Vector2(26.0, 22.0))


func draw_overlay(canvas: CanvasItem, canvas_size: Vector2, model: Dictionary, zh: bool) -> void:
	if model.is_empty():
		return
	var collapsed := bool(model.get("collapsed", false))
	var panel := collapsed_panel_rect(canvas_size) if collapsed else overlay_panel_rect(canvas_size)
	var status := String(model.get("status", "ok"))
	var status_color := _status_color(status)
	canvas.draw_rect(panel, Color(0.015, 0.035, 0.052, 0.68 if not collapsed else 0.78), true)
	canvas.draw_rect(panel, Color(status_color.r, status_color.g, status_color.b, 0.58), false, 1.5)
	var font := ThemeDB.get_fallback_font()
	var toggle_rect := toggle_button_rect(canvas_size, collapsed)
	_draw_toggle_button(canvas, toggle_rect, collapsed, status_color)
	if collapsed:
		_draw_collapsed_overlay(canvas, panel, model, zh, status_color, toggle_rect)
		return
	canvas.draw_line(panel.position + Vector2(8.0, 27.0), panel.position + Vector2(panel.size.x - 8.0, 27.0), Color(0.38, 0.9, 1.0, 0.18), 1.0)
	canvas.draw_string(font, panel.position + Vector2(14.0, 19.0), String(model.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.58, 13, Color(0.88, 0.97, 1.0, 0.96))
	var status_label := "可用" if zh else "READY"
	if status == "warn":
		status_label = "待处理" if zh else "CHECK"
	elif status == "missing":
		status_label = "缺核心" if zh else "NO CORE"
	canvas.draw_string(font, panel.position + Vector2(panel.size.x - 108.0, 19.0), status_label, HORIZONTAL_ALIGNMENT_RIGHT, 64.0, 12, status_color)
	var schema_rect := Rect2(panel.position + Vector2(14.0, 40.0), Vector2(128.0, 108.0))
	canvas.draw_rect(schema_rect, Color(0.03, 0.08, 0.11, 0.44), true)
	canvas.draw_rect(schema_rect, Color(0.28, 0.86, 1.0, 0.2), false, 1.0)
	var slots: Array = Array(model.get("slots", []))
	_draw_schema(canvas, schema_rect, slots)
	var grid_x := schema_rect.position.x + schema_rect.size.x + 14.0
	var grid_width := panel.position.x + panel.size.x - grid_x - 14.0
	var cell_gap := 8.0
	var cell_w := maxf(86.0, (grid_width - cell_gap * 2.0) / 3.0)
	var cell_h := 38.0
	for i in range(mini(slots.size(), 6)):
		if not (slots[i] is Dictionary):
			continue
		var col := i % 3
		var row := int(floori(float(i) / 3.0))
		var rect := Rect2(Vector2(grid_x + col * (cell_w + cell_gap), panel.position.y + 40.0 + row * (cell_h + 8.0)), Vector2(cell_w, cell_h))
		_draw_slot(canvas, rect, slots[i])
	_draw_warnings(canvas, panel, model, zh)


func _draw_collapsed_overlay(canvas: CanvasItem, panel: Rect2, model: Dictionary, zh: bool, status_color: Color, toggle_rect: Rect2) -> void:
	var font := ThemeDB.get_fallback_font()
	var status_label := "可用" if zh else "READY"
	var status := String(model.get("status", "ok"))
	if status == "warn":
		status_label = "待处理" if zh else "CHECK"
	elif status == "missing":
		status_label = "缺核心" if zh else "NO CORE"
	var warning_count := maxi(0, int(model.get("warning_count", Array(model.get("warnings", [])).size())))
	var title := "组装模板" if zh else "Assembly"
	var summary := "%s  %s %d" % [status_label, "待处理" if zh else "pending", warning_count]
	canvas.draw_string(font, panel.position + Vector2(12.0, 22.0), title, HORIZONTAL_ALIGNMENT_LEFT, 84.0, 12, Color(0.88, 0.97, 1.0, 0.94))
	canvas.draw_circle(panel.position + Vector2(102.0, 17.0), 3.0, status_color)
	canvas.draw_string(font, panel.position + Vector2(112.0, 22.0), summary, HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, toggle_rect.position.x - panel.position.x - 120.0), 11, Color(0.84, 0.94, 1.0, 0.82))


func _draw_toggle_button(canvas: CanvasItem, rect: Rect2, collapsed: bool, status_color: Color) -> void:
	canvas.draw_rect(rect, Color(0.02, 0.05, 0.07, 0.72), true)
	canvas.draw_rect(rect, Color(status_color.r, status_color.g, status_color.b, 0.52), false, 1.0)
	var center := rect.position + rect.size * 0.5
	var left := center + Vector2(-6.0, 1.0 if collapsed else -1.0)
	var right := center + Vector2(6.0, 1.0 if collapsed else -1.0)
	var tip := center + Vector2(0.0, 6.0 if collapsed else -6.0)
	canvas.draw_line(left, tip, status_color, 1.8)
	canvas.draw_line(tip, right, status_color, 1.8)


func _draw_warnings(canvas: CanvasItem, panel: Rect2, model: Dictionary, zh: bool) -> void:
	var font := ThemeDB.get_fallback_font()
	var warnings: Array = Array(model.get("warnings", []))
	var warning_y := 156.0
	var warning_title := "待处理" if zh else "Pending"
	canvas.draw_string(font, panel.position + Vector2(14.0, warning_y + 10.0), warning_title, HORIZONTAL_ALIGNMENT_LEFT, 68.0, 10, Color(0.78, 0.9, 1.0, 0.68))
	if warnings.is_empty():
		canvas.draw_string(font, panel.position + Vector2(88.0, warning_y + 10.0), "全部已安排" if zh else "All placed", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 102.0, 10, Color(0.32, 1.0, 0.72, 0.82))
		return
	var warning_limit := mini(warnings.size(), 3)
	for i in range(warning_limit):
		if not (warnings[i] is Dictionary):
			continue
		var warning: Dictionary = warnings[i]
		var dot_color := _status_color(String(warning.get("state", "warn")))
		var y := warning_y + 9.0 + i * 15.0
		canvas.draw_circle(panel.position + Vector2(96.0, y - 3.5), 2.6, dot_color)
		var line := "%s: %s" % [
			_trim(String(warning.get("label", "")), 8),
			_trim(String(warning.get("detail", "")), 28),
		]
		canvas.draw_string(font, panel.position + Vector2(104.0, y), line, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 118.0, 10, Color(0.92, 0.96, 1.0, 0.84))
	var hidden_count := maxi(0, int(model.get("warning_count", warnings.size())) - warning_limit)
	if hidden_count > 0:
		canvas.draw_string(font, panel.position + Vector2(panel.size.x - 54.0, panel.position.y + panel.size.y - 12.0), "+%d" % hidden_count, HORIZONTAL_ALIGNMENT_RIGHT, 42.0, 10, Color(1.0, 0.78, 0.22, 0.9))


func _draw_schema(canvas: CanvasItem, rect: Rect2, slots: Array) -> void:
	var slot_state := {}
	var slot_value := {}
	for raw_slot in slots:
		if not (raw_slot is Dictionary):
			continue
		var slot: Dictionary = raw_slot
		var key := String(slot.get("key", ""))
		slot_state[key] = String(slot.get("state", "empty"))
		slot_value[key] = String(slot.get("value", "0"))
	var core_color := _status_color(String(slot_state.get("core", "missing")))
	var limb_color := _status_color(String(slot_state.get("limb", "empty")))
	var weapon_color := _status_color(String(slot_state.get("weapon", "empty")))
	var plugin_color := _status_color(String(slot_state.get("plugin", "empty")))
	var software_color := _status_color(String(slot_state.get("software", "empty")))
	var center := rect.position + rect.size * Vector2(0.5, 0.52)
	var side := minf(rect.size.x, rect.size.y)
	var radius := maxf(10.0, side * 0.16)
	canvas.draw_circle(center, radius + 5.0, Color(core_color.r, core_color.g, core_color.b, 0.14))
	canvas.draw_circle(center, radius, Color(0.03, 0.07, 0.09, 0.92))
	canvas.draw_arc(center, radius + 1.5, 0.0, TAU, 30, core_color, 2.0)
	var arms := [
		Vector2(-1.0, -0.15),
		Vector2(1.0, -0.15),
		Vector2(-0.75, 0.82),
		Vector2(0.75, 0.82),
	]
	var limb_count := int(String(slot_value.get("limb", "0")).to_int())
	var weapon_count := int(String(slot_value.get("weapon", "0")).to_int())
	for i in range(arms.size()):
		var arm: Vector2 = arms[i]
		var dir := arm.normalized()
		var a := center + dir * (radius + 4.0)
		var b := center + dir * (side * 0.33)
		var active_limb := i < maxi(0, limb_count)
		var line_color: Color = limb_color if active_limb else Color(0.28, 0.42, 0.48, 0.46)
		canvas.draw_line(a, b, Color(line_color.r, line_color.g, line_color.b, 0.72), 2.0 if active_limb else 1.2)
		canvas.draw_circle(b, 4.3, Color(line_color.r, line_color.g, line_color.b, 0.22))
		canvas.draw_arc(b, 5.6, 0.0, TAU, 16, line_color, 1.3)
		if i < maxi(0, weapon_count):
			var tip := b + dir * 10.0
			canvas.draw_line(b, tip, weapon_color, 2.2)
			canvas.draw_circle(tip, 3.4, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.78))
	for i in range(mini(3, maxi(0, int(String(slot_value.get("plugin", "0")).to_int())))):
		var p := rect.position + Vector2(10.0 + i * 12.0, rect.size.y - 13.0)
		canvas.draw_rect(Rect2(p, Vector2(8.0, 8.0)), Color(plugin_color.r, plugin_color.g, plugin_color.b, 0.22), true)
		canvas.draw_rect(Rect2(p, Vector2(8.0, 8.0)), plugin_color, false, 1.0)
	for i in range(mini(3, maxi(0, int(String(slot_value.get("software", "0")).to_int())))):
		var p := rect.position + Vector2(rect.size.x - 18.0 - i * 12.0, 7.0)
		canvas.draw_circle(p, 3.8, Color(software_color.r, software_color.g, software_color.b, 0.65))


func _draw_slot(canvas: CanvasItem, rect: Rect2, slot: Dictionary) -> void:
	var state := String(slot.get("state", "empty"))
	var color := _status_color(state)
	canvas.draw_rect(rect, Color(0.03, 0.07, 0.1, 0.74), true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.42), false, 1.1)
	canvas.draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), Color(color.r, color.g, color.b, 0.82), true)
	var font := ThemeDB.get_fallback_font()
	var label := _trim(String(slot.get("label", "")), 8)
	var value := _trim(String(slot.get("value", "")), 6)
	canvas.draw_string(font, rect.position + Vector2(8.0, 15.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 34.0, 10, Color(0.78, 0.9, 1.0, 0.84))
	canvas.draw_string(font, rect.position + Vector2(rect.size.x - 28.0, 29.0), value, HORIZONTAL_ALIGNMENT_RIGHT, 24.0, 13, color)


func _status_color(state: String) -> Color:
	match state:
		"ok":
			return Color(0.25, 1.0, 0.72, 0.92)
		"missing":
			return Color(1.0, 0.2, 0.12, 0.94)
		"warn":
			return Color(1.0, 0.78, 0.22, 0.94)
		"empty":
			return Color(0.52, 0.66, 0.72, 0.78)
	return Color(0.42, 0.86, 1.0, 0.88)


func _trim(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "."
