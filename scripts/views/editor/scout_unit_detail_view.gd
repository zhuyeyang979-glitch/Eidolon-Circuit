class_name ScoutUnitDetailView
extends Control


signal close_requested(suppress_token: String)

var player_id := 1
var entry := {}
var stats := {}
var detail_text := ""
var language := "zh"
var close_button_enabled := false
var suppress_token := ""

func set_unit(next_player: int, next_entry: Dictionary, next_stats: Dictionary, next_detail_text: String, next_language: String) -> void:
	player_id = next_player
	entry = next_entry.duplicate(true)
	stats = next_stats.duplicate(true)
	detail_text = next_detail_text
	language = next_language
	queue_redraw()

func clear(message: String) -> void:
	entry = {}
	stats = {}
	detail_text = message
	queue_redraw()

func set_close_button_enabled(enabled: bool, next_suppress_token: String = "") -> void:
	close_button_enabled = enabled
	suppress_token = next_suppress_token
	mouse_filter = Control.MOUSE_FILTER_STOP if close_button_enabled else Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _close_rect() -> Rect2:
	return Rect2(Vector2(maxf(8.0, size.x - 38.0), 8.0), Vector2(28.0, 22.0))

func _gui_input(event: InputEvent) -> void:
	if not close_button_enabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			close_requested.emit(suppress_token)
			accept_event()
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and _close_rect().grow(5.0).has_point(mouse_event.position):
			close_requested.emit(suppress_token)
			accept_event()
			return

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.006, 0.012, 0.018, 0.96), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.28, 0.88, 1.0, 0.18), false, 1.2)
	var font := ThemeDB.get_fallback_font()
	if close_button_enabled:
		var close_rect := _close_rect()
		draw_rect(close_rect, Color(0.09, 0.12, 0.15, 0.94), true)
		draw_rect(close_rect, Color(0.65, 0.92, 1.0, 0.42), false, 1.0)
		draw_string(font, close_rect.position + Vector2(0.0, 16.0), "X", HORIZONTAL_ALIGNMENT_CENTER, close_rect.size.x, 13, Color(0.94, 0.98, 1.0, 0.96))
	if entry.is_empty():
		draw_string(font, Vector2(14.0, 28.0), detail_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 15, Color(0.86, 0.92, 0.98, 0.9))
		return
	var role := String(entry.get("role", "hero"))
	var unit_index := int(entry.get("index", 0))
	var title := "%s #%d  %s" % [_role_label(role), unit_index + 1, String(stats.get("name", ""))]
	var base := Color(0.24, 0.86, 1.0, 1.0) if player_id == 1 else Color(1.0, 0.28, 0.44, 1.0)
	draw_string(font, Vector2(18.0, 28.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 17, Color(0.94, 0.98, 1.0, 1.0))
	_draw_role_icon(Rect2(Vector2(18.0, 42.0), Vector2(92.0, 76.0)), role, base)
	var headline_x := 128.0
	draw_string(font, Vector2(headline_x, 58.0), "%s %d   %s %d   %s %.1fs" % [_label("造价", "COST"), int(stats.get("cost", 0)), _label("入场", "DEPLOY"), int(stats.get("deploy_cost", 0)), _label("等待", "WAIT"), float(stats.get("deploy_wait", 0.0))], HORIZONTAL_ALIGNMENT_LEFT, size.x - headline_x - 16.0, 13, Color(0.9, 0.96, 1.0, 0.94))
	draw_string(font, Vector2(headline_x, 82.0), "%s %.0f   %s %.2f   %s %.2f" % [_label("质量", "MASS"), float(stats.get("mass", 0.0)), _label("长度", "LENGTH"), float(stats.get("length", 0.0)), _label("信息安全", "SEC"), float(stats.get("data_security", 0.0))], HORIZONTAL_ALIGNMENT_LEFT, size.x - headline_x - 16.0, 13, Color(0.76, 0.86, 0.92, 0.92))
	var y := 138.0
	var bars := _bar_specs(role)
	for spec in bars:
		var row: Dictionary = spec
		_draw_bar(Vector2(18.0, y), size.x - 42.0, String(row.get("label", "")), float(row.get("value", 0.0)), float(row.get("max", 1.0)), row.get("color", base))
		y += 25.0
	y += 8.0
	draw_line(Vector2(18.0, y), Vector2(size.x - 18.0, y), Color(0.4, 0.92, 1.0, 0.18), 1.0)
	y += 22.0
	var notes := _compact_notes()
	for note in notes:
		if y > size.y - 16.0:
			break
		draw_string(font, Vector2(18.0, y), String(note), HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 11, Color(0.8, 0.88, 0.94, 0.86))
		y += 18.0

func _draw_bar(pos: Vector2, width: float, label: String, value: float, max_value: float, color: Color) -> void:
	var font := ThemeDB.get_fallback_font()
	var label_width := 96.0
	var value_width := 74.0
	var bar_rect := Rect2(pos + Vector2(label_width, 4.0), Vector2(maxf(60.0, width - label_width - value_width), 11.0))
	var ratio := clampf(value / maxf(0.001, max_value), 0.0, 1.0)
	draw_string(font, pos + Vector2(0.0, 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_width - 8.0, 11, Color(0.86, 0.92, 0.96, 0.92))
	draw_rect(bar_rect, Color(0.02, 0.028, 0.036, 0.92), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), color, true)
	draw_rect(bar_rect, Color(0.72, 0.88, 0.96, 0.26), false, 1.0)
	draw_string(font, pos + Vector2(width - value_width, 14.0), _value_text(value), HORIZONTAL_ALIGNMENT_RIGHT, value_width, 11, Color(0.92, 0.96, 1.0, 0.92))

func _bar_specs(role: String) -> Array:
	var max_damage := maxf(1.0, maxf(float(stats.get("normal_damage", 0.0)), maxf(float(stats.get("armor_damage", 0.0)), float(stats.get("active_damage", 0.0)))))
	var ammo = stats.get("ammo_capacity", {})
	var ammo_total := 0.0
	if ammo is Dictionary:
		ammo_total = float(int(ammo.get("bullet", 0)) + int(ammo.get("chemical", 0)) + int(ammo.get("laser", 0)) + int(ammo.get("explosive", 0)) + int(ammo.get("web", 0)))
	var rows: Array = [
		{"label": _label("生命", "HP"), "value": float(stats.get("health", 0.0)), "max": 900.0, "color": Color(0.16, 0.86, 0.62, 0.95)},
		{"label": _label("护盾", "SHIELD"), "value": float(stats.get("electronic_armor_max", stats.get("shield_max", 0.0))), "max": 420.0, "color": Color(0.34, 0.88, 1.0, 0.95)},
		{"label": _label("质量", "MASS"), "value": float(stats.get("mass", 0.0)), "max": 260.0, "color": Color(0.84, 0.82, 0.76, 0.95)},
		{"label": _label("速度", "SPEED"), "value": float(stats.get("speed", 0.0)), "max": 5.0, "color": Color(0.28, 0.78, 1.0, 0.95)},
		{"label": _label("加速度", "ACCEL"), "value": float(stats.get("acceleration", 0.0)), "max": 8.0, "color": Color(0.44, 0.92, 1.0, 0.95)},
		{"label": _label("转向", "TURN"), "value": float(stats.get("turn_speed", 0.0)), "max": 6.0, "color": Color(0.72, 0.62, 1.0, 0.95)},
		{"label": _label("散热/秒", "COOL/s"), "value": float(stats.get("cooling", 0.0)), "max": 45.0, "color": Color(0.3, 1.0, 0.78, 0.95)},
		{"label": _label("伤害", "DAMAGE"), "value": max_damage, "max": 220.0, "color": Color(1.0, 0.56, 0.26, 0.95)},
		{"label": _label("射程", "RANGE"), "value": maxf(float(stats.get("normal_range", 0.0)), float(stats.get("projectile_range", 0.0))), "max": 8.0, "color": Color(1.0, 0.82, 0.28, 0.95)},
		{"label": _label("弹药", "AMMO"), "value": ammo_total, "max": 180.0, "color": Color(0.92, 0.9, 0.58, 0.95)},
		{"label": _label("稳定", "STABLE"), "value": float(stats.get("melee_stability", stats.get("recoil_stabilization", 0.0))), "max": 140.0, "color": Color(0.9, 0.96, 1.0, 0.95)},
		{"label": _label("数据安全", "SECURITY"), "value": float(stats.get("data_security", 0.0)), "max": 4.0, "color": Color(0.92, 0.62, 1.0, 0.95)},
	]
	if role == "hero":
		rows.insert(7, {"label": _label("热池", "HEAT POOL"), "value": float(stats.get("heat_capacity", 0.0)), "max": 260.0, "color": Color(1.0, 0.22, 0.12, 0.95)})
	return rows

func _compact_notes() -> Array:
	var result: Array = []
	for raw_line in detail_text.split("\n", false):
		var line := String(raw_line).strip_edges()
		if line == "":
			continue
		if line.begins_with(_role_label(String(entry.get("role", "hero")))) or line.begins_with("造价") or line.begins_with("COST") or line.begins_with("生命"):
			continue
		result.append(line)
		if result.size() >= 10:
			break
	return result

func _draw_role_icon(rect: Rect2, role: String, base: Color) -> void:
	draw_rect(rect, Color(0.012, 0.02, 0.028, 0.92), true)
	draw_rect(rect, base, false, 1.2)
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.32
	if role == "barrier":
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(base.r, base.g, base.b, 0.24), true)
		draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), base, false, 2.0)
		draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), base, 1.5)
		draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), base, 1.5)
		var tile_count := mini(12, Array(stats.get("barrier_map_tiles", [])).size())
		for i in range(tile_count):
			var x := i % 4
			var y := i / 4
			var tile_rect := Rect2(center + Vector2(-radius * 0.72 + float(x) * radius * 0.48, -radius * 0.54 + float(y) * radius * 0.42), Vector2(radius * 0.26, radius * 0.22))
			draw_rect(tile_rect, base.lerp(Color.WHITE, 0.24), true)
			draw_rect(tile_rect, Color(0.02, 0.05, 0.07, 0.82), false, 1.0)
	elif role == "puppet":
		_draw_unit_topology_thumb(center, radius, base, true)
	else:
		_draw_unit_topology_thumb(center, radius, base, false)

func _draw_unit_topology_thumb(center: Vector2, radius: float, base: Color, puppet_shape: bool) -> void:
	var runtime_segments: Array = stats.get("runtime_topology_segments", [])
	var group_count := clampi(maxi(2, runtime_segments.size() - 1) if not runtime_segments.is_empty() else int(stats.get("group_count", 4)), 2, 8)
	var shape := String(stats.get("torso_visual_shape", stats.get("shape", "core"))).to_lower()
	var body_radius := radius * (0.38 if puppet_shape else 0.46)
	var sides := 6
	if shape.contains("tank"):
		sides = 4
	elif shape.contains("snake") or shape.contains("centipede"):
		sides = 8
	elif shape.contains("human") or shape.contains("dog"):
		sides = 5
	for i in range(group_count):
		var angle := -PI * 0.5 + TAU * float(i) / float(group_count)
		var dir := Vector2(cos(angle), sin(angle))
		var joint_pos := center + dir * radius * 0.56
		var tip_pos := center + dir * radius * 0.9
		draw_line(center + dir * body_radius * 0.78, joint_pos, Color(0.28, 0.92, 1.0, 0.78), 3.0)
		draw_circle(joint_pos, maxf(2.4, radius * 0.085), Color(1.0, 0.86, 0.22, 0.95))
		draw_line(joint_pos, tip_pos, base.lerp(Color.WHITE, 0.18), 4.0)
		draw_circle(tip_pos, maxf(2.0, radius * 0.07), Color(0.04, 0.08, 0.1, 0.9))
	var pts := PackedVector2Array()
	for i in range(sides):
		var angle := -PI * 0.5 + TAU * float(i) / float(sides)
		var squash := Vector2(cos(angle) * body_radius * 1.18, sin(angle) * body_radius * (0.72 if shape.contains("tank") else 0.95))
		pts.append(center + squash)
	draw_colored_polygon(pts, base)
	pts.append(pts[0])
	draw_polyline(pts, Color.WHITE, 1.4)
	draw_circle(center, body_radius * 0.34, Color(0.0, 0.0, 0.0, 0.62))

func _role_label(role: String) -> String:
	if language == "zh":
		return {"hero": "英雄", "puppet": "傀儡", "barrier": "结界"}.get(role, "单位")
	return {"hero": "Hero", "puppet": "Puppet", "barrier": "Barrier"}.get(role, "Unit")

func _label(zh: String, en: String) -> String:
	return zh if language == "zh" else en

func _value_text(value: float) -> String:
	if absf(value) >= 100.0:
		return "%d" % int(round(value))
	if absf(value) >= 10.0:
		return "%.1f" % value
	return "%.2f" % value
