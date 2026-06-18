class_name EngineMomentumAllocationPanelView
extends Control

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")


signal close_requested()
signal equalize_requested()
signal allocation_changed(entry_id: String, ratio: float)
signal allocation_value_submitted(entry_id: String, momentum: float)
signal allocation_drag_finished(entry_id: String)
signal entry_detail_requested(entry_id: String)
signal segment_detail_requested(node_index: int)

var ui_language := "zh"
var title := ""
var subtitle := ""
var engine_name := ""
var torso_name := ""
var engine_output := 0.0
var used_ratio := 0.0
var cooling_pool := 0.0
var engine_heat_load := 0.0
var allocation_heat_used := 0.0
var heat_used := 0.0
var heat_ratio := 0.0
var thermal_margin := 0.0
var entries: Array = []
var segments: Array = []
var allocation_groups: Array = []
var dragging_entry_id := ""
var selected_group_id := ""
var entry_scroll_offset := 0.0
var last_emitted_ratios := {}
var last_allocation_signature := ""
var entry_value_edits := {}
var entry_value_submit_guard := {}

func set_allocation_data(next_data: Dictionary, next_language: String) -> void:
	var display_entries := Array(next_data.get("display_entries", next_data.get("entries", [])))
	var signature := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		next_language,
		String(next_data.get("title", "")),
		String(next_data.get("subtitle", "")),
		String(next_data.get("engine_name", "")),
		str(snappedf(float(next_data.get("engine_output", 0.0)), 0.01)),
		str(snappedf(float(next_data.get("used_ratio", 0.0)), 0.001)),
		str(snappedf(float(next_data.get("cooling_pool", 0.0)), 0.01)),
		str(snappedf(float(next_data.get("heat_used", 0.0)), 0.01)),
		str(snappedf(float(next_data.get("thermal_margin", 0.0)), 0.01)),
		_allocation_entries_signature(display_entries),
		_allocation_groups_signature(Array(next_data.get("allocation_groups", []))),
	]
	if visible and signature == last_allocation_signature:
		return
	last_allocation_signature = signature
	ui_language = next_language
	title = String(next_data.get("title", ""))
	subtitle = String(next_data.get("subtitle", ""))
	engine_name = String(next_data.get("engine_name", ""))
	torso_name = String(next_data.get("torso_name", ""))
	engine_output = maxf(0.0, float(next_data.get("engine_output", 0.0)))
	used_ratio = maxf(0.0, float(next_data.get("used_ratio", 0.0)))
	cooling_pool = maxf(0.0, float(next_data.get("cooling_pool", 0.0)))
	engine_heat_load = maxf(0.0, float(next_data.get("engine_heat_load", 0.0)))
	allocation_heat_used = maxf(0.0, float(next_data.get("allocation_heat_used", 0.0)))
	heat_used = maxf(0.0, float(next_data.get("heat_used", 0.0)))
	heat_ratio = maxf(0.0, float(next_data.get("heat_ratio", 0.0)))
	thermal_margin = float(next_data.get("thermal_margin", cooling_pool - heat_used))
	entries = display_entries.duplicate(true)
	segments = Array(next_data.get("segments", [])).duplicate(true)
	allocation_groups = Array(next_data.get("allocation_groups", [])).duplicate(true)
	entry_scroll_offset = clampf(entry_scroll_offset, 0.0, _entry_max_scroll())
	visible = true
	_sync_entry_value_edits()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_RESIZED:
		_sync_entry_value_edits()

func _allocation_entries_signature(next_entries: Array) -> String:
	var bits: Array = [str(next_entries.size())]
	for i in range(mini(next_entries.size(), 24)):
		if not (next_entries[i] is Dictionary):
			bits.append("_")
			continue
		var entry: Dictionary = next_entries[i]
		bits.append("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			String(entry.get("id", "")),
			String(entry.get("label", "")),
			str(snappedf(float(entry.get("allocated_momentum", entry.get("momentum", 0.0))), 0.01)),
			str(snappedf(float(entry.get("ratio", 0.0)), 0.001)),
			str(snappedf(float(entry.get("min_ratio", 0.0)), 0.001)),
			str(snappedf(float(entry.get("max_ratio", 1.0)), 0.001)),
			str(snappedf(float(entry.get("min_momentum", 0.0)), 0.01)),
			str(snappedf(float(entry.get("max_momentum", 0.0)), 0.01)),
			str(snappedf(float(entry.get("duration_estimate", -1.0)), 0.01)),
			str(snappedf(float(entry.get("boost_peak_ratio", 0.0)), 0.001)),
			str(snappedf(float(entry.get("heat_load", 0.0)), 0.01)),
			str(snappedf(float(entry.get("heat_ratio", 0.0)), 0.001)),
		])
	return "|".join(bits)

func _allocation_groups_signature(next_groups: Array) -> String:
	var bits: Array = [str(next_groups.size())]
	for i in range(mini(next_groups.size(), 24)):
		if not (next_groups[i] is Dictionary):
			bits.append("_")
			continue
		var group: Dictionary = next_groups[i]
		var node_bits: Array = []
		for raw_node in Array(group.get("target_nodes", [])):
			node_bits.append(str(int(raw_node)))
		bits.append("%s:%s:%s" % [
			String(group.get("id", "")),
			String(group.get("label", "")),
			",".join(node_bits),
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
		if _side_rect().has_point(mouse_event.position):
			var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			entry_scroll_offset = clampf(entry_scroll_offset + direction * 42.0, 0.0, _entry_max_scroll())
			_sync_entry_value_edits()
			queue_redraw()
			accept_event()
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		close_requested.emit()
		accept_event()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_event.pressed:
		if dragging_entry_id != "":
			var finished_id := dragging_entry_id
			dragging_entry_id = ""
			allocation_drag_finished.emit(finished_id)
		return
	if _close_rect().has_point(mouse_event.position):
		close_requested.emit()
		accept_event()
		return
	if _equalize_rect().has_point(mouse_event.position):
		equalize_requested.emit()
		accept_event()
		return
	var clicked_group_id := _allocation_group_id_at(mouse_event.position)
	if clicked_group_id != "":
		selected_group_id = clicked_group_id
		queue_redraw()
		var group := _allocation_group_for_id(clicked_group_id)
		var target_nodes: Array = Array(group.get("target_nodes", []))
		if not target_nodes.is_empty():
			segment_detail_requested.emit(int(target_nodes[0]))
		accept_event()
		return
	if _silhouette_rect().has_point(mouse_event.position):
		var segment_node := _segment_node_at(mouse_event.position)
		if segment_node >= 0:
			segment_detail_requested.emit(segment_node)
			accept_event()
			return
	for i in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var entry_id := String(entry.get("id", ""))
		if entry_id == "":
			continue
		if bool(entry.get("disabled", false)) or bool(entry.get("readonly", false)):
			continue
		if _entry_slider_rect(i).grow(6.0).has_point(mouse_event.position):
			_release_focus_from_entry_edits()
			dragging_entry_id = entry_id
			_emit_slider_change(entry_id, mouse_event.position)
			accept_event()
			return
	for i in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var entry_id := String(entry.get("id", ""))
		if entry_id == "":
			continue
		if _entry_row_rect(i).has_point(mouse_event.position) and _side_rect().has_point(mouse_event.position):
			entry_detail_requested.emit(entry_id)
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
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.01, 0.016, 0.97), true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), Color(0.86, 0.72, 0.28, 0.62), false, 1.5)
	draw_string(font, Vector2(16.0, 24.0), _trim(title, 30), HORIZONTAL_ALIGNMENT_LEFT, size.x - 132.0, 16, Color(1.0, 0.96, 0.78, 1.0))
	draw_string(font, Vector2(16.0, 43.0), _trim(subtitle, 70), HORIZONTAL_ALIGNMENT_LEFT, size.x - 132.0, 10, Color(0.8, 0.92, 1.0, 0.82))
	draw_rect(_equalize_rect(), Color(0.13, 0.15, 0.08, 0.92), true)
	draw_rect(_equalize_rect(), Color(1.0, 0.82, 0.28, 0.74), false, 1.0)
	draw_string(font, _equalize_rect().position + Vector2(4.0, 15.0), _label("均衡", "BAL"), HORIZONTAL_ALIGNMENT_CENTER, _equalize_rect().size.x - 8.0, 10, Color(1.0, 0.94, 0.7, 1.0))
	draw_rect(_close_rect(), Color(0.23, 0.04, 0.04, 0.94), true)
	draw_rect(_close_rect(), Color(1.0, 0.32, 0.2, 0.86), false, 1.0)
	draw_string(font, _close_rect().position + Vector2(5.0, 16.0), "X", HORIZONTAL_ALIGNMENT_CENTER, _close_rect().size.x - 10.0, 12, Color(1.0, 0.82, 0.76, 1.0))
	_draw_power_pips(font)
	_draw_silhouette()
	_draw_allocation_group_halos(font)
	_draw_entry_sliders(font)
	var hint := _label("动力预算：推进器推进占常热，Boost刹车是峰值动力提示；绑定肢体按范围可调。", "Drive budget: thruster move uses idle heat; boost-brake is a peak demand hint; bound limbs stay range-limited.")
	draw_string(font, Vector2(18.0, size.y - 13.0), _trim(hint, 78), HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 10, Color(0.82, 0.9, 0.98, 0.72))

func _draw_power_pips(font: Font) -> void:
	var rect := Rect2(Vector2(size.x - 214.0, 16.0), Vector2(118.0, 20.0))
	var pip_count := 12
	for i in range(pip_count):
		var pip_rect := Rect2(rect.position + Vector2(float(i) * 9.5, 0.0), Vector2(7.0, 18.0))
		var threshold := float(i + 1) / float(pip_count)
		var color := Color(0.12, 0.18, 0.2, 0.92)
		if used_ratio > 1.0001 and threshold <= minf(1.0, used_ratio):
			color = Color(1.0, 0.18, 0.1, 0.94)
		elif threshold <= used_ratio:
			color = Color(1.0, 0.78, 0.24, 0.94)
		draw_rect(pip_rect, color, true)
		draw_rect(pip_rect, Color(1.0, 0.94, 0.72, 0.28), false, 1.0)
	var remaining := maxf(0.0, 1.0 - used_ratio)
	var label := _label("已用 %.2f  剩 %.2f", "USED %.2f  LEFT %.2f") % [used_ratio, remaining]
	if used_ratio > 1.0001:
		label = _label("超额 %.2f", "OVER %.2f") % [used_ratio - 1.0]
	draw_string(font, Vector2(size.x - 214.0, 51.0), label, HORIZONTAL_ALIGNMENT_LEFT, 168.0, 10, Color(1.0, 0.78, 0.24, 0.94) if used_ratio <= 1.0001 else Color(1.0, 0.32, 0.22, 0.96))
	var heat_rect := Rect2(Vector2(size.x - 214.0, 62.0), Vector2(168.0, 8.0))
	var safe_cooling := maxf(0.0, cooling_pool)
	var local_heat_ratio := clampf(heat_used / maxf(1.0, safe_cooling), 0.0, 1.6) if safe_cooling > 0.0 else (1.6 if heat_used > 0.0 else 0.0)
	var heat_over := heat_used > safe_cooling + 0.001
	draw_rect(heat_rect, Color(0.035, 0.016, 0.012, 0.94), true)
	draw_rect(Rect2(heat_rect.position, Vector2(heat_rect.size.x * clampf(local_heat_ratio, 0.0, 1.0), heat_rect.size.y)), Color(1.0, 0.24, 0.1, 0.78) if heat_over else Color(1.0, 0.46, 0.14, 0.66), true)
	draw_rect(heat_rect, Color(1.0, 0.18, 0.08, 0.92) if heat_over else Color(1.0, 0.58, 0.22, 0.62), false, 1.0)
	var heat_text := _label("常热负载 %.1f=引擎 %.1f+推进/肢体 %.1f / 热池 %.1f", "IDLE LOAD %.1f=ENG %.1f+MOVE/LIMB %.1f / POOL %.1f") % [
		heat_used,
		engine_heat_load,
		allocation_heat_used,
		safe_cooling,
	]
	if safe_cooling <= 0.0:
		heat_text = _label("常热负载 %.1f=引擎 %.1f+推进/肢体 %.1f / 无热池", "IDLE LOAD %.1f=ENG %.1f+MOVE/LIMB %.1f / NO POOL") % [
			heat_used,
			engine_heat_load,
			allocation_heat_used,
		]
	draw_string(font, heat_rect.position + Vector2(0.0, 20.0), _trim(heat_text, 42), HORIZONTAL_ALIGNMENT_LEFT, heat_rect.size.x + 64.0, 9, Color(1.0, 0.34, 0.18, 0.98) if heat_over else Color(1.0, 0.72, 0.42, 0.92))

func _draw_silhouette() -> void:
	var rect := _silhouette_rect()
	draw_rect(rect, Color(0.006, 0.016, 0.024, 0.92), true)
	draw_rect(rect, Color(0.34, 0.82, 1.0, 0.24), false, 1.0)
	if segments.is_empty():
		var font := ThemeDB.get_fallback_font()
		draw_string(font, rect.position + Vector2(16.0, 34.0), _label("暂无画板剪影", "NO SILHOUETTE"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 12, Color(0.82, 0.9, 0.96, 0.7))
		return
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = Dictionary(raw_segment).duplicate(true)
		var node := AssemblyBoardRenderer.segment_to_component_node(segment)
		node["runtime_action"] = bool(segment.get("runtime_action", false))
		node["runtime_action_state"] = String(segment.get("runtime_action_state", ""))
		var primary := Color(0.72, 0.92, 1.0, 0.92)
		var material := Color(0.46, 0.64, 0.78, 0.9)
		if String(segment.get("part_kind", "")) == "torso":
			material = primary.lerp(material, 0.45).lerp(Color.WHITE, 0.08)
		_draw_aspect_fit_segment(segment, node, material)

func _draw_aspect_fit_segment(segment: Dictionary, node: Dictionary, color: Color) -> void:
	var local_polygon := _segment_visual_polygon_local(segment, node)
	if local_polygon.size() < 3:
		return
	var screen_polygon := PackedVector2Array()
	for local_point in local_polygon:
		screen_polygon.append(_map_local_point(local_point))
	draw_colored_polygon(screen_polygon, color)
	var outline := screen_polygon.duplicate()
	if outline.size() > 0:
		outline.append(outline[0])
	draw_polyline(outline, Color(0.86, 0.98, 1.0, 0.42), 1.0)

func _draw_entry_sliders(font: Font) -> void:
	var side := _side_rect()
	draw_rect(side, Color(0.004, 0.012, 0.018, 0.9), true)
	draw_rect(side, Color(0.36, 0.9, 1.0, 0.26), false, 1.0)
	draw_string(font, side.position + Vector2(10.0, 20.0), _label("动力分配", "DRIVE ALLOC"), HORIZONTAL_ALIGNMENT_LEFT, side.size.x - 20.0, 11, Color(0.88, 0.98, 1.0, 0.92))
	for i in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		if entry.is_empty():
			continue
		var slider_rect := _entry_slider_rect(i)
		if not slider_rect.grow(48.0).intersects(side):
			continue
		var ratio := clampf(float(entry.get("ratio", 0.0)), 0.0, 1.6)
		var local_slider_ratio := _entry_slider_fill_ratio(entry)
		var over := bool(entry.get("over_budget", false)) or used_ratio > 1.0001
		var disabled := bool(entry.get("disabled", false))
		var readonly := bool(entry.get("readonly", false))
		var heat_only := bool(entry.get("heat_only", false))
		var color: Color = entry.get("color", Color(1.0, 0.78, 0.24, 1.0))
		var group_id := String(entry.get("group_id", ""))
		var row_rect := _entry_row_rect(i)
		draw_rect(row_rect, Color(0.016, 0.03, 0.04, 0.94) if not disabled else Color(0.03, 0.032, 0.034, 0.82), true)
		draw_rect(row_rect, Color(1.0, 0.9, 0.34, 0.88) if group_id != "" and group_id == selected_group_id else (Color(color.r, color.g, color.b, 0.44 if readonly else 0.62) if not disabled else Color(0.52, 0.58, 0.62, 0.42)), false, 1.2 if group_id != "" and group_id == selected_group_id else 1.0)
		if String(entry.get("kind", "")) == "limb" and entry.get("anchor_local", null) is Vector2:
			var anchor := _map_local_point(entry.get("anchor_local", Vector2.ZERO))
			draw_line(anchor, slider_rect.position + Vector2(0.0, slider_rect.size.y * 0.5), Color(color.r, color.g, color.b, 0.42), 1.0)
		var entry_kind := String(entry.get("kind", ""))
		if entry_kind.begins_with("booster"):
			_draw_booster_icon(slider_rect.position + Vector2(-22.0, 8.0), color)
		if _entry_uses_range_slider(entry):
			var full_slider := _entry_full_slider_rect(i)
			draw_rect(full_slider, Color(0.006, 0.012, 0.018, 0.94), true)
			draw_rect(full_slider, Color(0.32, 0.44, 0.52, 0.32), false, 1.0)
			draw_line(Vector2(slider_rect.position.x, full_slider.position.y - 3.0), Vector2(slider_rect.position.x, full_slider.position.y + full_slider.size.y + 3.0), Color(color.r, color.g, color.b, 0.58), 1.0)
			draw_line(Vector2(slider_rect.position.x + slider_rect.size.x, full_slider.position.y - 3.0), Vector2(slider_rect.position.x + slider_rect.size.x, full_slider.position.y + full_slider.size.y + 3.0), Color(color.r, color.g, color.b, 0.58), 1.0)
		draw_rect(slider_rect, Color(0.012, 0.022, 0.03, 0.96), true)
		draw_rect(slider_rect, Color(0.5, 0.56, 0.62, 0.6) if disabled else (Color(1.0, 0.22, 0.14, 0.9) if over else color.darkened(0.2)), false, 1.0)
		var fill := Rect2(slider_rect.position, Vector2(slider_rect.size.x * clampf(local_slider_ratio, 0.0, 1.0), slider_rect.size.y))
		draw_rect(fill, Color(0.24, 0.28, 0.32, 0.46) if disabled else (Color(color.r, color.g, color.b, 0.34) if readonly else (Color(1.0, 0.25, 0.12, 0.74) if over else Color(color.r, color.g, color.b, 0.62))), true)
		if entry_kind.begins_with("booster"):
			_draw_boost_peak_hint(slider_rect, entry, color, disabled)
		var knob_x := slider_rect.position.x + slider_rect.size.x * clampf(local_slider_ratio, 0.0, 1.0)
		if not readonly:
			draw_circle(Vector2(knob_x, slider_rect.position.y + slider_rect.size.y * 0.5), 6.0, Color(0.62, 0.68, 0.72, 0.86) if disabled else Color(1.0, 0.94, 0.72, 1.0))
		_draw_entry_heat_bar(font, i, entry, disabled)
		var kind_label := _entry_kind_label(entry)
		draw_string(font, row_rect.position + Vector2(8.0, 17.0), kind_label, HORIZONTAL_ALIGNMENT_LEFT, 42.0, 9, Color(color.r, color.g, color.b, 0.9) if not disabled else Color(0.62, 0.68, 0.72, 0.82))
		var label_width := row_rect.size.x - 56.0
		if _entry_uses_range_slider(entry):
			label_width = maxf(68.0, _entry_value_edit_rect(i).position.x - (row_rect.position.x + 52.0) - 8.0)
		draw_string(font, row_rect.position + Vector2(52.0, 17.0), _trim(String(entry.get("label", "")), 28), HORIZONTAL_ALIGNMENT_LEFT, label_width, 9, Color(0.93, 0.98, 1.0, 0.94) if not disabled else Color(0.72, 0.76, 0.8, 0.86))
		var value_label := ("固定 %.0f" if ui_language == "zh" else "FIXED %.0f") % float(entry.get("momentum", 0.0)) if readonly else "%.2f  %.0f" % [ratio, float(entry.get("momentum", 0.0))]
		if heat_only:
			value_label = _label("引擎常热负载 %.1f", "ENGINE IDLE LOAD %.1f") % float(entry.get("heat_load", 0.0))
		if _entry_uses_range_slider(entry) and not readonly:
			value_label = "%.0f / %.0f-%.0f" % [float(entry.get("momentum", 0.0)), float(entry.get("min_momentum", 0.0)), float(entry.get("max_momentum", 0.0))]
		if disabled:
			value_label += "  " + _label("先装引擎", "NEED ENGINE")
		draw_string(font, row_rect.position + Vector2(8.0, 83.0), value_label, HORIZONTAL_ALIGNMENT_LEFT, 104.0, 9, Color(0.72, 0.76, 0.8, 0.86) if disabled else (Color(1.0, 0.86, 0.46, 0.9) if not over else Color(1.0, 0.36, 0.24, 0.95)))
		var line := String(entry.get("line", ""))
		if line != "":
			draw_string(font, row_rect.position + Vector2(120.0, 83.0), _trim(line, 30), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 128.0, 9, Color(0.76, 0.86, 0.94, 0.72))
		var duration_label := String(entry.get("duration_label", ""))
		if duration_label != "":
			draw_string(font, row_rect.position + Vector2(8.0, 101.0), _trim(duration_label, 48), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 16.0, 9, Color(0.78, 0.9, 0.98, 0.76) if not disabled else Color(0.62, 0.68, 0.72, 0.72))
		elif entry_kind.begins_with("booster"):
			var boost_label := String(entry.get("boost_label", ""))
			if boost_label != "":
				draw_string(font, row_rect.position + Vector2(8.0, 101.0), _trim(boost_label, 48), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 16.0, 9, Color(1.0, 0.72, 0.24, 0.82) if not disabled else Color(0.62, 0.68, 0.72, 0.72))

func _draw_entry_heat_bar(font: Font, index: int, entry: Dictionary, disabled: bool) -> void:
	var heat_rect := _entry_heat_bar_rect(index)
	var heat_load := maxf(0.0, float(entry.get("heat_load", 0.0)))
	var entry_heat_ratio := clampf(float(entry.get("heat_ratio", 0.0)), 0.0, 1.6)
	var heat_over := bool(entry.get("heat_over_budget", false)) or (cooling_pool <= 0.0 and heat_load > 0.0)
	var heat_color: Color = entry.get("heat_color", Color(1.0, 0.42, 0.14, 1.0))
	if disabled:
		heat_color = Color(0.58, 0.52, 0.48, 0.82)
	draw_rect(heat_rect, Color(0.034, 0.018, 0.012, 0.94), true)
	draw_rect(Rect2(heat_rect.position, Vector2(heat_rect.size.x * clampf(entry_heat_ratio, 0.0, 1.0), heat_rect.size.y)), Color(heat_color.r, heat_color.g, heat_color.b, 0.32 if disabled else (0.78 if heat_over else 0.58)), true)
	draw_rect(heat_rect, Color(1.0, 0.18, 0.08, 0.84) if heat_over and not disabled else Color(heat_color.r, heat_color.g, heat_color.b, 0.56), false, 1.0)
	var heat_label := String(entry.get("heat_label", ""))
	if heat_label == "":
		heat_label = _label("常热 %.1f", "IDLE %.1f") % heat_load
	draw_string(font, heat_rect.end + Vector2(6.0, 6.0), _trim(heat_label, 18), HORIZONTAL_ALIGNMENT_LEFT, 102.0, 8, Color(1.0, 0.32, 0.18, 0.96) if heat_over and not disabled else Color(1.0, 0.68, 0.38, 0.86))

func _draw_boost_peak_hint(slider_rect: Rect2, entry: Dictionary, color: Color, disabled: bool) -> void:
	var start_ratio := clampf(float(entry.get("ratio", 0.0)), 0.0, 1.0)
	var peak_ratio := clampf(float(entry.get("boost_peak_ratio", start_ratio)), 0.0, 1.6)
	if peak_ratio <= start_ratio + 0.002:
		return
	var start_x := slider_rect.position.x + slider_rect.size.x * start_ratio
	var end_x := slider_rect.position.x + slider_rect.size.x * minf(1.0, peak_ratio)
	var y := slider_rect.position.y + slider_rect.size.y * 0.5
	var dash_color := Color(1.0, 0.72, 0.22, 0.32) if disabled else Color(1.0, 0.74, 0.2, 0.92)
	var x := start_x + 3.0
	while x < end_x:
		draw_line(Vector2(x, y), Vector2(minf(x + 5.0, end_x), y), dash_color, 2.0)
		x += 9.0
	if peak_ratio > 1.0:
		var overflow_x := slider_rect.position.x + slider_rect.size.x
		draw_line(Vector2(overflow_x, slider_rect.position.y - 3.0), Vector2(overflow_x, slider_rect.position.y + slider_rect.size.y + 3.0), Color(color.r, color.g, color.b, 0.76), 1.4)

func _draw_booster_icon(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7.0, -9.0), center + Vector2(9.0, 0.0), center + Vector2(-7.0, 9.0)]), color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9.0, -5.0), center + Vector2(-17.0, 0.0), center + Vector2(-9.0, 5.0)]), Color(1.0, 0.44, 0.12, 0.66))

func _entry_slider_rect(index: int) -> Rect2:
	var full_rect := _entry_full_slider_rect(index)
	if index >= 0 and index < entries.size() and entries[index] is Dictionary:
		var entry: Dictionary = entries[index]
		if _entry_uses_range_slider(entry):
			var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
			var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
			if engine_output > 0.0 and max_momentum > min_momentum:
				var start_ratio := clampf(min_momentum / maxf(1.0, engine_output), 0.0, 1.0)
				var end_ratio := clampf(max_momentum / maxf(1.0, engine_output), start_ratio, 1.0)
				var range_ratio := maxf(0.0, end_ratio - start_ratio)
				var width := clampf(full_rect.size.x * range_ratio, minf(72.0, full_rect.size.x), full_rect.size.x)
				var x := full_rect.position.x + full_rect.size.x * start_ratio
				if x + width > full_rect.position.x + full_rect.size.x:
					x = full_rect.position.x + full_rect.size.x - width
				return Rect2(Vector2(x, full_rect.position.y), Vector2(width, full_rect.size.y))
	return full_rect

func _entry_full_slider_rect(index: int) -> Rect2:
	var row_rect := _entry_row_rect(index)
	var right_pad := 88.0 if _entry_has_value_edit(index) else 14.0
	return Rect2(row_rect.position + Vector2(12.0, 34.0), Vector2(row_rect.size.x - 12.0 - right_pad, 14.0))

func _entry_heat_bar_rect(index: int) -> Rect2:
	var row_rect := _entry_row_rect(index)
	return Rect2(row_rect.position + Vector2(12.0, 58.0), Vector2(row_rect.size.x - 128.0, 8.0))

func _entry_slider_fill_ratio(entry: Dictionary) -> float:
	if not _entry_uses_range_slider(entry):
		return clampf(float(entry.get("ratio", 0.0)), 0.0, 1.0)
	var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
	var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
	var momentum := maxf(0.0, float(entry.get("momentum", 0.0)))
	if max_momentum <= min_momentum:
		return 0.0
	return clampf((momentum - min_momentum) / maxf(0.001, max_momentum - min_momentum), 0.0, 1.0)

func _entry_row_rect(index: int) -> Rect2:
	var side_rect := _side_rect()
	return Rect2(side_rect.position + Vector2(10.0, 44.0 + float(index) * _entry_row_stride() - entry_scroll_offset), Vector2(side_rect.size.x - 20.0, 112.0))

func _entry_row_stride() -> float:
	return 122.0

func _entry_has_value_edit(index: int) -> bool:
	if index < 0 or index >= entries.size() or not (entries[index] is Dictionary):
		return false
	var entry: Dictionary = entries[index]
	return _entry_uses_range_slider(entry) and not bool(entry.get("readonly", false)) and not bool(entry.get("disabled", false))

func _entry_value_edit_rect(index: int) -> Rect2:
	var row_rect := _entry_row_rect(index)
	return Rect2(row_rect.position + Vector2(row_rect.size.x - 76.0, 6.0), Vector2(68.0, 24.0))

func _entry_index_for_id(entry_id: String) -> int:
	for i in range(entries.size()):
		if entries[i] is Dictionary and String(Dictionary(entries[i]).get("id", "")) == entry_id:
			return i
	return -1

func _silhouette_rect() -> Rect2:
	return Rect2(Vector2(16.0, 70.0), Vector2(size.x - 360.0, size.y - 106.0))

func _side_rect() -> Rect2:
	return Rect2(Vector2(size.x - 330.0, 84.0), Vector2(306.0, size.y - 126.0))

func _entry_max_scroll() -> float:
	return maxf(0.0, 44.0 + float(entries.size()) * _entry_row_stride() - _side_rect().size.y)

func _sync_entry_value_edits() -> void:
	var wanted := {}
	if visible:
		for i in range(entries.size()):
			if not _entry_has_value_edit(i):
				continue
			var row_visible := _entry_row_rect(i).grow(4.0).intersects(_side_rect())
			var entry: Dictionary = entries[i]
			var entry_id := String(entry.get("id", ""))
			if entry_id == "":
				continue
			wanted[entry_id] = true
			var edit: LineEdit = entry_value_edits.get(entry_id, null)
			if edit == null:
				edit = LineEdit.new()
				edit.name = "DriveValue_%s" % entry_id.replace(":", "_")
				edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
				edit.select_all_on_focus = true
				edit.context_menu_enabled = false
				edit.text_submitted.connect(_submit_entry_value_edit.bind(entry_id))
				edit.focus_exited.connect(_submit_entry_value_edit_focus.bind(entry_id))
				add_child(edit)
				entry_value_edits[entry_id] = edit
			edit.visible = row_visible
			edit.editable = true
			edit.placeholder_text = _label("动力", "Drive")
			edit.position = _entry_value_edit_rect(i).position
			edit.size = _entry_value_edit_rect(i).size
			edit.tooltip_text = _label("输入该项动力分配值", "Enter this drive allocation")
			if not edit.has_focus():
				edit.text = _format_entry_momentum_text(float(entry.get("momentum", 0.0)))
	for raw_id in entry_value_edits.keys():
		var edit: LineEdit = entry_value_edits[raw_id]
		if not wanted.has(raw_id):
			edit.visible = false

func _format_entry_momentum_text(value: float) -> String:
	if absf(value - roundf(value)) < 0.01:
		return "%.0f" % value
	return "%.2f" % value

func _submit_entry_value_edit_focus(entry_id: String) -> void:
	if bool(entry_value_submit_guard.get(entry_id, false)):
		entry_value_submit_guard.erase(entry_id)
		return
	if not entry_value_edits.has(entry_id):
		return
	var edit: LineEdit = entry_value_edits[entry_id]
	_submit_entry_value_edit(edit.text, entry_id)

func _submit_entry_value_edit(text_value: String, entry_id: String) -> void:
	var edit: LineEdit = entry_value_edits.get(entry_id, null)
	var current := _entry_momentum_for_id(entry_id)
	if not text_value.is_valid_float():
		if edit != null:
			edit.text = _format_entry_momentum_text(current)
		return
	var requested := maxf(0.0, text_value.to_float())
	if edit != null:
		edit.text = _format_entry_momentum_text(requested)
		if edit.has_focus():
			entry_value_submit_guard[entry_id] = true
		edit.release_focus()
	allocation_value_submitted.emit(entry_id, requested)

func has_focused_value_edit() -> bool:
	for raw_edit in entry_value_edits.values():
		if raw_edit is LineEdit and (raw_edit as LineEdit).visible and (raw_edit as LineEdit).has_focus():
			return true
	return false

func submit_focused_value_edit() -> bool:
	for raw_id in entry_value_edits.keys():
		var edit: LineEdit = entry_value_edits.get(raw_id, null)
		if edit != null and edit.visible and edit.has_focus():
			_submit_entry_value_edit(edit.text, String(raw_id))
			return true
	return false

func _entry_momentum_for_id(entry_id: String) -> float:
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("id", "")) == entry_id:
			return maxf(0.0, float(Dictionary(raw_entry).get("momentum", 0.0)))
	return 0.0

func _entry_uses_range_slider(entry: Dictionary) -> bool:
	if bool(entry.get("readonly", false)):
		return false
	if not entry.has("min_momentum") and not entry.has("max_momentum"):
		return false
	var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
	var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
	return max_momentum > min_momentum

func _entry_kind_label(entry: Dictionary) -> String:
	match String(entry.get("kind", "")):
		"engine_heat":
			return _label("常热", "IDLE")
		"limb":
			return _label("肢体", "LIMB")
		"booster_drive":
			return _label("推进", "MOVE")
		"booster_boost_brake":
			return _label("增幅", "B+B")
		_:
			return _label("需求", "REQ")

func _release_focus_from_entry_edits() -> void:
	for raw_edit in entry_value_edits.values():
		if raw_edit is LineEdit and (raw_edit as LineEdit).has_focus():
			(raw_edit as LineEdit).release_focus()

func _draw_allocation_group_halos(font: Font) -> void:
	for raw_group in allocation_groups:
		if not (raw_group is Dictionary):
			continue
		var group: Dictionary = raw_group
		var bounds := _allocation_group_screen_rect(group)
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			continue
		var selected := String(group.get("id", "")) == selected_group_id
		var color := Color(0.46, 0.62, 1.0, 0.88) if not selected else Color(1.0, 0.9, 0.28, 0.95)
		draw_rect(bounds.grow(8.0), Color(color.r, color.g, color.b, 0.12 if not selected else 0.18), true)
		draw_rect(bounds.grow(8.0), Color(color.r, color.g, color.b, 0.72), false, 2.2 if selected else 1.6)
		draw_rect(bounds.grow(14.0), Color(color.r, color.g, color.b, 0.22), false, 5.0)
		var label := _trim(String(group.get("label", _label("可分配肢体", "POWER LIMB"))), 18)
		var label_rect := Rect2(bounds.position + Vector2(0.0, -22.0), Vector2(maxf(92.0, bounds.size.x), 18.0))
		draw_rect(label_rect, Color(0.004, 0.012, 0.018, 0.84), true)
		draw_rect(label_rect, Color(color.r, color.g, color.b, 0.62), false, 1.0)
		draw_string(font, label_rect.position + Vector2(4.0, 13.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 8.0, 9, Color(0.92, 0.98, 1.0, 0.96))

func _allocation_group_id_at(pos: Vector2) -> String:
	for raw_group in allocation_groups:
		if not (raw_group is Dictionary):
			continue
		var group: Dictionary = raw_group
		if _allocation_group_screen_rect(group).grow(16.0).has_point(pos):
			return String(group.get("id", ""))
	return ""

func _allocation_group_for_id(group_id: String) -> Dictionary:
	for raw_group in allocation_groups:
		if raw_group is Dictionary and String(Dictionary(raw_group).get("id", "")) == group_id:
			return Dictionary(raw_group)
	return {}

func _segment_node_at(pos: Vector2) -> int:
	var best_node := -1
	var best_distance := 999999.0
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		var node_index := int(segment.get("node_index", -1))
		if node_index < 0:
			continue
		var bounds := _segment_screen_rect(segment).grow(10.0)
		if not bounds.has_point(pos):
			continue
		var center := bounds.position + bounds.size * 0.5
		var distance := center.distance_to(pos)
		if distance < best_distance:
			best_distance = distance
			best_node = node_index
	return best_node

func _segment_screen_rect(segment: Dictionary) -> Rect2:
	var first := true
	var min_point := Vector2.ZERO
	var max_point := Vector2.ZERO
	var radius := maxf(6.0, float(segment.get("radius", 0.025)) * _silhouette_scale() + 6.0)
	for local_point in _segment_local_bound_points(segment):
		var point := _map_local_point(local_point)
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
		return Rect2()
	return Rect2(min_point, max_point - min_point)

func _allocation_group_screen_rect(group: Dictionary) -> Rect2:
	var target_nodes: Array = Array(group.get("target_nodes", []))
	if target_nodes.is_empty():
		return Rect2()
	var node_set := {}
	for raw_node in target_nodes:
		node_set[int(raw_node)] = true
	var first := true
	var min_point := Vector2.ZERO
	var max_point := Vector2.ZERO
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		var node_index := int(segment.get("node_index", -9999))
		if not node_set.has(node_index):
			continue
		var radius := maxf(6.0, float(segment.get("radius", 0.025)) * _silhouette_scale() + 8.0)
		for local_point in _segment_local_bound_points(segment):
			var point := _map_local_point(local_point)
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
		return Rect2()
	return Rect2(min_point, max_point - min_point)

func _close_rect() -> Rect2:
	return Rect2(Vector2(size.x - 38.0, 10.0), Vector2(26.0, 24.0))

func _equalize_rect() -> Rect2:
	return Rect2(Vector2(size.x - 92.0, 10.0), Vector2(48.0, 24.0))

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
		for raw_point in _segment_visual_polygon_local(segment):
			points.append(raw_point)
	if points.is_empty():
		points.append(_segment_local_point(segment, "a_local", "a"))
		points.append(_segment_local_point(segment, "b_local", "b"))
	return points

func _segment_visual_polygon_local(segment: Dictionary, node_override: Dictionary = {}) -> PackedVector2Array:
	var a := _segment_local_point(segment, "a_local", "a")
	var b := _segment_local_point(segment, "b_local", "b")
	var axis := b - a
	if axis.length() < 0.001:
		axis = Vector2.RIGHT
	var node := node_override if not node_override.is_empty() else AssemblyBoardRenderer.segment_to_component_node(segment)
	return AssemblyBoardRenderer.component_polygon((a + b) * 0.5, node, axis, maxf(0.001, float(segment.get("radius", 0.025))), maxf(0.001, a.distance_to(b)), false)

func _segment_bounds() -> Rect2:
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

func _silhouette_scale() -> float:
	var bounds := _segment_bounds()
	var rect := _silhouette_rect().grow(-22.0)
	return minf(rect.size.x / maxf(0.01, bounds.size.x), rect.size.y / maxf(0.01, bounds.size.y))

func _map_local_point(point: Vector2) -> Vector2:
	var bounds := _segment_bounds()
	var rect := _silhouette_rect().grow(-22.0)
	var scale := _silhouette_scale()
	return rect.get_center() + (point - bounds.get_center()) * scale

func _segment_local_point(segment: Dictionary, primary_key: String, fallback_key: String) -> Vector2:
	var value = segment.get(primary_key, segment.get(fallback_key, Vector2.ZERO))
	return value if value is Vector2 else Vector2.ZERO

func _label(zh: String, en: String) -> String:
	return zh if ui_language == "zh" else en

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
