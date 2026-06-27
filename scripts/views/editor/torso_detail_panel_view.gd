class_name TorsoDetailPanelView
extends Control


signal payload_dropped(slot_key: String, part_index: int, slot_kind: String, slot_index: int)
signal payload_hovered(slot_kind: String, slot_index: int, payload_index: int)
signal payload_hover_cleared()
signal engine_allocation_requested(payload_index: int)
signal remove_payload(payload_index: int)
signal rebind_payload(payload_index: int)
signal source_priority_move(payload_index: int, direction: int)
signal source_priority_reset()
signal binding_candidate_selected(candidate_index: int)
signal binding_action_side_selected(side: String)
signal binding_key_selected(key_value: int)
signal binding_cancel_requested()
signal close_requested()

var ui_language := "zh"
var title := ""
var subtitle := ""
var plugin_capacity := 0
var software_capacity := 0
var plugin_entries: Array = []
var software_entries: Array = []
var selected_kind := ""
var selected_index := -1
var dragging_payload_index := -1
var plugin_scroll := 0.0
var software_scroll := 0.0
var dragging_scroll_kind := ""
var dragging_scroll_grab_y := 0.0
var hovered_kind := ""
var hovered_index := -1
var binding_mode := false
var binding_title := ""
var binding_subtitle := ""
var binding_candidates: Array = []
var binding_selected_index := -1
var binding_key_ready := false
var binding_action_side_required := false
var binding_action_side := ""
var binding_scroll := 0.0
var last_detail_signature := ""
var last_binding_signature := ""

func set_detail(next_title: String, next_subtitle: String, next_plugins: Array, next_plugin_capacity: int, next_software: Array, next_software_capacity: int, next_selected_kind: String, next_selected_index: int, next_language: String) -> void:
	var signature := "%s|%s|%d|%d|%s|%d|%s|%s|%s" % [
		next_title,
		next_subtitle,
		next_plugin_capacity,
		next_software_capacity,
		next_selected_kind,
		next_selected_index,
		next_language,
		_entries_signature(next_plugins),
		_entries_signature(next_software),
	]
	if visible and signature == last_detail_signature:
		return
	last_detail_signature = signature
	title = next_title
	subtitle = next_subtitle
	plugin_entries = next_plugins.duplicate(true)
	software_entries = next_software.duplicate(true)
	plugin_capacity = maxi(0, next_plugin_capacity)
	software_capacity = maxi(0, next_software_capacity)
	selected_kind = next_selected_kind
	selected_index = next_selected_index
	ui_language = next_language
	visible = true
	_clamp_scroll_offsets()
	queue_redraw()

func set_binding_state(active: bool, next_title: String = "", next_subtitle: String = "", next_candidates: Array = [], next_selected_index: int = -1, next_key_ready: bool = false, next_action_side_required: bool = false, next_action_side: String = "") -> void:
	var next_candidates_signature := _candidates_signature(next_candidates)
	var reset_scroll := active != binding_mode or next_title != binding_title or next_candidates_signature != _candidates_signature(binding_candidates)
	var signature := "%s|%s|%s|%d|%s|%s|%s|%s" % [str(active), next_title, next_subtitle, next_selected_index, str(next_key_ready), str(next_action_side_required), next_action_side, next_candidates_signature]
	if signature == last_binding_signature:
		return
	last_binding_signature = signature
	binding_mode = active
	binding_title = next_title
	binding_subtitle = next_subtitle
	binding_candidates = next_candidates.duplicate(true)
	binding_selected_index = next_selected_index
	binding_key_ready = next_key_ready
	binding_action_side_required = next_action_side_required
	binding_action_side = next_action_side
	binding_scroll = 0.0 if reset_scroll else clampf(binding_scroll, 0.0, _binding_max_scroll())
	queue_redraw()

func _entries_signature(entries: Array) -> String:
	var bits: Array = [str(entries.size())]
	for i in range(mini(entries.size(), 18)):
		if not (entries[i] is Dictionary):
			bits.append("_")
			continue
		var entry: Dictionary = entries[i]
		bits.append("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			str(int(entry.get("payload_index", -1))),
			String(entry.get("kind", "")),
			String(entry.get("name", "")),
			String(entry.get("line", "")),
			String(entry.get("slot_size_label", "")),
			str(bool(entry.get("empty", false))),
			str(bool(entry.get("can_rebind", false))),
			str(bool(entry.get("binding_invalid", false))),
			str(bool(entry.get("source_code_priority", false))),
			str(int(entry.get("source_priority", -1))),
			str(bool(entry.get("source_priority_can_up", false))),
			str(bool(entry.get("source_priority_can_down", false))),
			String(entry.get("source_priority_label", "")),
		])
	return "|".join(bits)

func _candidates_signature(candidates: Array) -> String:
	var bits: Array = [str(candidates.size())]
	for i in range(mini(candidates.size(), 24)):
		if not (candidates[i] is Dictionary):
			bits.append("_")
			continue
		var candidate: Dictionary = candidates[i]
		bits.append("%s:%s:%s:%s:%s" % [
			str(int(candidate.get("root_index", -1))),
			String(candidate.get("label", "")),
			String(candidate.get("note", "")),
			str(bool(candidate.get("valid", false))),
			str(Array(candidate.get("nodes", [])).size()),
		])
	return "|".join(bits)

func _can_drop_data(at_position: Vector2, data) -> bool:
	if not (data is Dictionary):
		return false
	if String(Dictionary(data).get("kind", "")) != "editor_catalog_part":
		return false
	return _slot_kind_at_position(at_position) != ""

func _drop_data(at_position: Vector2, data) -> void:
	if not (data is Dictionary):
		return
	var payload := Dictionary(data)
	var hit := _slot_hit(at_position)
	var action := String(hit.get("action", "none"))
	if action in ["delete", "rebind", "source_priority_up", "source_priority_down"]:
		return
	var kind := String(hit.get("kind", _slot_kind_at_position(at_position)))
	if kind == "":
		return
	payload_dropped.emit(String(payload.get("slot", "")), int(payload.get("index", -1)), kind, int(hit.get("index", -1)))

func _get_drag_data(at_position: Vector2):
	var hit := _slot_hit(at_position)
	var action := String(hit.get("action", "none"))
	if hit.is_empty() or action in ["delete", "rebind", "source_priority_up", "source_priority_down"]:
		return null
	var entry := _entry_for_slot(String(hit.get("kind", "")), int(hit.get("index", -1)))
	var payload_index := int(entry.get("payload_index", -1))
	if payload_index < 0:
		return null
	dragging_payload_index = payload_index
	selected_kind = String(hit.get("kind", ""))
	selected_index = int(hit.get("index", -1))
	var preview := Label.new()
	preview.text = _label("拔下 ", "UNPLUG ") + _trim(String(entry.get("name", "")), 18)
	preview.add_theme_color_override("font_color", Color(0.86, 1.0, 1.0, 0.96))
	preview.add_theme_font_size_override("font_size", 12)
	set_drag_preview(preview)
	queue_redraw()
	return {"kind": "torso_detail_payload", "payload_index": payload_index}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and dragging_payload_index >= 0:
		dragging_payload_index = -1
		queue_redraw()
	if what == NOTIFICATION_MOUSE_EXIT:
		_clear_payload_hover()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if dragging_scroll_kind != "":
			var motion_event := event as InputEventMouseMotion
			_drag_scrollbar_to(dragging_scroll_kind, motion_event.position.y - dragging_scroll_grab_y)
			accept_event()
		else:
			_update_payload_hover((event as InputEventMouseMotion).position)
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and dragging_scroll_kind != "":
			dragging_scroll_kind = ""
			accept_event()
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if binding_mode:
			var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			binding_scroll = clampf(binding_scroll + direction * 30.0, 0.0, _binding_max_scroll())
			queue_redraw()
			accept_event()
			return
		var scroll_kind := _slot_kind_at_position(mouse_event.position)
		if scroll_kind != "":
			var direction := -1.0 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			_scroll_group(scroll_kind, direction * 34.0)
			accept_event()
		return
	if binding_mode:
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			binding_cancel_requested.emit()
			accept_event()
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _binding_cancel_rect().has_point(mouse_event.position):
				binding_cancel_requested.emit()
				accept_event()
				return
			if binding_action_side_required:
				for side in ["left", "right"]:
					if _binding_action_side_rect(side).has_point(mouse_event.position):
						binding_action_side_selected.emit(side)
						accept_event()
						return
			for key_value in range(1, 7):
				if binding_key_ready and _binding_key_rect(key_value).has_point(mouse_event.position):
					binding_key_selected.emit(key_value)
					accept_event()
					return
			var candidate_index := _binding_candidate_index_at(mouse_event.position)
			if candidate_index >= 0:
				binding_candidate_selected.emit(candidate_index)
				accept_event()
				return
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		var scrollbar_kind := _scrollbar_kind_at_position(mouse_event.position)
		if scrollbar_kind != "":
			dragging_scroll_kind = scrollbar_kind
			var thumb_rect := _scrollbar_thumb_rect(scrollbar_kind)
			dragging_scroll_grab_y = clampf(mouse_event.position.y - thumb_rect.position.y, 0.0, thumb_rect.size.y)
			_drag_scrollbar_to(scrollbar_kind, mouse_event.position.y - dragging_scroll_grab_y)
			accept_event()
			return
	if _close_rect().has_point(mouse_event.position):
		close_requested.emit()
		accept_event()
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and _source_priority_reset_rect().has_point(mouse_event.position) and _has_source_priority_entries():
		source_priority_reset.emit()
		accept_event()
		return
	var hit := _slot_hit(mouse_event.position)
	if hit.is_empty():
		return
	var action := String(hit.get("action", "none"))
	if action == "source_priority_up" or action == "source_priority_down":
		source_priority_move.emit(int(hit.get("payload_index", -1)), -1 if action == "source_priority_up" else 1)
		accept_event()
		queue_redraw()
		return
	if action == "rebind":
		var hit_kind := String(hit.get("kind", ""))
		var hit_index := int(hit.get("index", -1))
		var rebind_entry := _entry_for_slot(hit_kind, hit_index)
		var rebind_index := int(rebind_entry.get("payload_index", -1))
		if rebind_index >= 0:
			rebind_payload.emit(rebind_index)
		accept_event()
		queue_redraw()
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT or action == "delete":
		var hit_kind := String(hit.get("kind", ""))
		var hit_index := int(hit.get("index", -1))
		var entry := _entry_for_slot(hit_kind, hit_index)
		var payload_index := int(entry.get("payload_index", -1))
		if payload_index >= 0:
			remove_payload.emit(payload_index)
		accept_event()
		queue_redraw()
		return
	selected_kind = String(hit.get("kind", ""))
	selected_index = int(hit.get("index", -1))
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and action == "engine_allocation":
		var entry := _entry_for_slot(selected_kind, selected_index)
		var payload_index := int(entry.get("payload_index", -1))
		if payload_index >= 0:
			engine_allocation_requested.emit(payload_index)
		accept_event()
		queue_redraw()
		return
	accept_event()
	queue_redraw()

func _update_payload_hover(pos: Vector2) -> void:
	var hit := _slot_hit(pos)
	var action := String(hit.get("action", "none"))
	if hit.is_empty() or action in ["delete", "rebind", "source_priority_up", "source_priority_down"]:
		_clear_payload_hover()
		return
	var kind := String(hit.get("kind", ""))
	var index := int(hit.get("index", -1))
	var entry := _entry_for_slot(kind, index)
	var payload_index := int(entry.get("payload_index", -1))
	if payload_index < 0:
		_clear_payload_hover()
		return
	if hovered_kind == kind and hovered_index == index:
		return
	hovered_kind = kind
	hovered_index = index
	payload_hovered.emit(kind, index, payload_index)

func _clear_payload_hover() -> void:
	if hovered_kind == "" and hovered_index < 0:
		return
	hovered_kind = ""
	hovered_index = -1
	payload_hover_cleared.emit()

func _draw() -> void:
	if not visible:
		return
	var font := ThemeDB.get_fallback_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.011, 0.018, 0.97), true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), Color(0.28, 0.9, 1.0, 0.42), false, 1.5)
	draw_string(font, Vector2(14.0, 22.0), _trim(title, 30), HORIZONTAL_ALIGNMENT_LEFT, size.x - 54.0, 14, Color(0.94, 0.98, 1.0, 1.0))
	draw_string(font, Vector2(14.0, 40.0), _trim(subtitle, 48), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 10, Color(1.0, 0.86, 0.28, 0.94))
	draw_rect(_close_rect(), Color(0.22, 0.04, 0.05, 0.92), true)
	draw_rect(_close_rect(), Color(1.0, 0.32, 0.22, 0.86), false, 1.0)
	draw_string(font, _close_rect().position + Vector2(6.0, 15.0), "X", HORIZONTAL_ALIGNMENT_CENTER, _close_rect().size.x - 12.0, 12, Color(1.0, 0.82, 0.76, 1.0))
	if _has_source_priority_entries():
		var reset_rect := _source_priority_reset_rect()
		draw_rect(reset_rect, Color(0.08, 0.12, 0.18, 0.94), true)
		draw_rect(reset_rect, Color(0.72, 0.46, 1.0, 0.86), false, 1.0)
		draw_string(font, reset_rect.position + Vector2(2.0, 13.0), _label("重置", "RST"), HORIZONTAL_ALIGNMENT_CENTER, reset_rect.size.x - 4.0, 9, Color(0.9, 0.84, 1.0, 1.0))
	_draw_slot_group("plugin", _plugin_group_rect(), plugin_entries, plugin_capacity, Color(0.24, 1.0, 0.72, 1.0), _label("机内插件槽", "INTERNAL PLUGINS"))
	_draw_slot_group("software", _software_group_rect(), software_entries, software_capacity, Color(0.72, 0.46, 1.0, 1.0), _label("软件槽", "SOFTWARE SLOTS"))
	if binding_mode:
		_draw_binding_panel()
	var hint := _label("拖入安装；左键选中；右键或点 X 删除；插件无碰撞体积。", "Drag to install; left select; right-click or X deletes; plugins have no collision volume.")
	draw_string(font, Vector2(12.0, size.y - 10.0), _trim(hint, 70), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 10, Color(0.78, 0.9, 1.0, 0.74))

func _draw_slot_group(kind: String, rect: Rect2, entries: Array, capacity: int, color: Color, heading: String) -> void:
	var font := ThemeDB.get_fallback_font()
	draw_rect(rect, Color(0.006, 0.02, 0.027, 0.9), true)
	draw_rect(rect, color.darkened(0.12), false, 1.4)
	draw_string(font, rect.position + Vector2(10.0, 17.0), "%s %d/%d" % [heading, _occupied_entry_count(entries), capacity], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 12, color.lerp(Color.WHITE, 0.18))
	var max_slots := maxi(capacity, entries.size())
	if max_slots <= 0:
		draw_string(font, rect.position + Vector2(10.0, 44.0), _label("此躯干没有该类插槽", "No slots of this type"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 11, Color(0.8, 0.86, 0.9, 0.72))
		return
	var content_rect := _group_content_rect(kind)
	for i in range(max_slots):
		var slot_rect := _slot_rect(kind, i)
		if slot_rect.end.y < content_rect.position.y or slot_rect.position.y > content_rect.end.y:
			continue
		var entry: Dictionary = entries[i] if i < entries.size() and entries[i] is Dictionary else {}
		var occupied := not entry.is_empty() and not bool(entry.get("empty", false))
		var selected := kind == selected_kind and i == selected_index
		var bg := Color(color.r * 0.12, color.g * 0.16, color.b * 0.16, 0.88)
		if selected:
			bg = color.darkened(0.52)
		if i >= capacity:
			bg = Color(0.22, 0.05, 0.05, 0.82)
		draw_rect(slot_rect, bg, true)
		draw_rect(slot_rect, color if i < capacity else Color(1.0, 0.22, 0.18, 0.82), false, 1.0)
		var slot_size_label := String(entry.get("slot_size_label", ""))
		if slot_size_label != "" and slot_size_label != "-":
			var badge_rect := Rect2(slot_rect.position + Vector2(5.0, 5.0), Vector2(26.0, 16.0))
			draw_rect(badge_rect, Color(color.r, color.g, color.b, 0.2), true)
			draw_rect(badge_rect, color.lerp(Color.WHITE, 0.12), false, 1.0)
			draw_string(font, badge_rect.position + Vector2(2.0, 12.0), slot_size_label, HORIZONTAL_ALIGNMENT_CENTER, badge_rect.size.x - 4.0, 9, color.lerp(Color.WHITE, 0.2))
		if occupied:
			var icon_rect := Rect2(slot_rect.position + Vector2(5.0, 5.0), Vector2(26.0, slot_rect.size.y - 10.0))
			if slot_size_label != "" and slot_size_label != "-":
				icon_rect.position.x += 30.0
			_draw_payload_icon(icon_rect, entry, color)
			var text_x := 36.0 if slot_size_label == "" or slot_size_label == "-" else 66.0
			var has_source_priority := bool(entry.get("source_code_priority", false))
			var action_width := 40.0
			if has_source_priority:
				action_width = 90.0
			if bool(entry.get("can_rebind", false)):
				action_width = maxf(action_width, 138.0 if has_source_priority else 92.0)
			var line_color := Color(0.76, 0.86, 0.94, 0.88)
			if bool(entry.get("binding_invalid", false)):
				line_color = Color(1.0, 0.38, 0.28, 0.95)
				draw_rect(slot_rect.grow(-1.0), Color(1.0, 0.16, 0.1, 0.34), false, 1.3)
			draw_string(font, slot_rect.position + Vector2(text_x, 15.0), _trim(String(entry.get("name", "")), 18), HORIZONTAL_ALIGNMENT_LEFT, slot_rect.size.x - text_x - action_width, 10, Color(0.92, 0.98, 1.0, 0.95))
			draw_string(font, slot_rect.position + Vector2(text_x, 30.0), _trim(String(entry.get("line", "")), 24), HORIZONTAL_ALIGNMENT_LEFT, slot_rect.size.x - text_x - action_width, 8, line_color)
			if has_source_priority:
				_draw_source_priority_button(_priority_up_rect_for_slot(slot_rect), "^", bool(entry.get("source_priority_can_up", false)), color)
				_draw_source_priority_button(_priority_down_rect_for_slot(slot_rect), "v", bool(entry.get("source_priority_can_down", false)), color)
			if bool(entry.get("can_rebind", false)):
				var rebind_rect := _rebind_rect_for_slot(slot_rect, has_source_priority)
				draw_rect(rebind_rect, Color(0.08, 0.18, 0.32, 0.9), true)
				draw_rect(rebind_rect, Color(0.42, 0.9, 1.0, 0.72), false, 1.0)
				draw_string(font, rebind_rect.position + Vector2(2.0, 13.0), _trim(String(entry.get("rebind_label", _label("重绑", "BIND"))), 5), HORIZONTAL_ALIGNMENT_CENTER, rebind_rect.size.x - 4.0, 9, Color(0.82, 0.96, 1.0, 1.0))
			var remove_rect := _remove_rect_for_slot(slot_rect)
			draw_rect(remove_rect, Color(0.42, 0.04, 0.04, 0.86), true)
			draw_string(font, remove_rect.position + Vector2(2.0, 13.0), _label("删", "DEL"), HORIZONTAL_ALIGNMENT_CENTER, remove_rect.size.x - 4.0, 9, Color(1.0, 0.74, 0.66, 1.0))
		else:
			var empty_x := 36.0 if slot_size_label == "" or slot_size_label == "-" else 66.0
			var empty_label := _label("空槽", "EMPTY")
			if slot_size_label != "" and slot_size_label != "-":
				empty_label = _label("空槽 <=%s" % slot_size_label, "EMPTY <=%s" % slot_size_label)
			draw_string(font, slot_rect.position + Vector2(empty_x, 22.0), empty_label, HORIZONTAL_ALIGNMENT_LEFT, slot_rect.size.x - empty_x - 8.0, 10, Color(0.78, 0.88, 0.94, 0.62))
	_draw_scrollbar(kind, rect, max_slots, color)

func _draw_payload_icon(rect: Rect2, entry: Dictionary, fallback: Color) -> void:
	var center := rect.get_center()
	var kind := String(entry.get("kind", "payload"))
	var color: Color = entry.get("color", fallback)
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.42), true)
	match kind:
		"engine":
			draw_circle(center, rect.size.y * 0.32, color.darkened(0.35))
			draw_circle(center, rect.size.y * 0.16, color.lerp(Color.WHITE, 0.28))
			draw_arc(center, rect.size.y * 0.42, 0.0, TAU, 24, Color.WHITE.lerp(color, 0.16), 2.0)
		"cooling":
			for i in range(4):
				var x := rect.position.x + 5.0 + float(i) * rect.size.x * 0.2
				draw_rect(Rect2(Vector2(x, rect.position.y + 5.0), Vector2(3.0, rect.size.y - 10.0)), color, true)
			draw_line(center - Vector2(rect.size.x * 0.34, 0.0), center + Vector2(rect.size.x * 0.34, 0.0), Color.WHITE.lerp(color, 0.16), 2.0)
		"booster":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-8.0, -10.0), center + Vector2(10.0, 0.0), center + Vector2(-8.0, 10.0)]), color)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9.0, -6.0), center + Vector2(-18.0, 0.0), center + Vector2(-9.0, 6.0)]), Color(1.0, 0.48, 0.16, 0.72))
		"ammo":
			draw_rect(Rect2(center - Vector2(8.0, 11.0), Vector2(16.0, 22.0)), color.darkened(0.2), true)
			draw_line(center + Vector2(-8.0, -3.0), center + Vector2(8.0, -3.0), Color.WHITE, 1.0)
		"electronic_armor":
			draw_arc(center, rect.size.y * 0.36, -2.6, 2.6, 26, color, 3.0)
			draw_circle(center, rect.size.y * 0.12, color.lerp(Color.WHITE, 0.32))
		"special":
			for i in range(5):
				var angle := -PI * 0.5 + TAU * float(i) / 5.0
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * rect.size.y * 0.34, color, 2.0)
			draw_circle(center, rect.size.y * 0.13, Color.WHITE.lerp(color, 0.18))
		"module":
			draw_rect(Rect2(center - Vector2(10.0, 8.0), Vector2(20.0, 16.0)), color.darkened(0.28), true)
			draw_rect(Rect2(center - Vector2(7.0, 5.0), Vector2(14.0, 10.0)), color, true)
			draw_line(center + Vector2(-13.0, 0.0), center + Vector2(13.0, 0.0), Color.WHITE.lerp(color, 0.2), 1.0)
		_:
			draw_circle(center, rect.size.y * 0.3, color)
	draw_rect(rect, Color(0.82, 0.94, 1.0, 0.28), false, 1.0)

func _slot_hit(pos: Vector2) -> Dictionary:
	for kind in ["plugin", "software"]:
		if not _group_content_rect(kind).has_point(pos):
			continue
		var entries := plugin_entries if kind == "plugin" else software_entries
		var capacity := plugin_capacity if kind == "plugin" else software_capacity
		for i in range(maxi(capacity, entries.size())):
			var slot_rect := _slot_rect(kind, i)
			var entry := _entry_for_slot(kind, i)
			if entry.is_empty():
				continue
			var has_source_priority := bool(entry.get("source_code_priority", false))
			if has_source_priority and bool(entry.get("source_priority_can_up", false)) and _priority_up_rect_for_slot(slot_rect).has_point(pos):
				return {"kind": kind, "index": i, "action": "source_priority_up", "payload_index": int(entry.get("payload_index", -1))}
			if has_source_priority and bool(entry.get("source_priority_can_down", false)) and _priority_down_rect_for_slot(slot_rect).has_point(pos):
				return {"kind": kind, "index": i, "action": "source_priority_down", "payload_index": int(entry.get("payload_index", -1))}
			if _remove_rect_for_slot(slot_rect).has_point(pos):
				return {"kind": kind, "index": i, "action": "delete", "payload_index": int(entry.get("payload_index", -1))}
			if bool(entry.get("can_rebind", false)) and _rebind_rect_for_slot(slot_rect, has_source_priority).has_point(pos):
				return {"kind": kind, "index": i, "action": "rebind", "payload_index": int(entry.get("payload_index", -1))}
	for kind in ["plugin", "software"]:
		if not _group_content_rect(kind).has_point(pos):
			continue
		var entries := plugin_entries if kind == "plugin" else software_entries
		var capacity := plugin_capacity if kind == "plugin" else software_capacity
		for i in range(maxi(capacity, entries.size())):
			var slot_rect := _slot_rect(kind, i)
			if slot_rect.has_point(pos):
				var entry := _entry_for_slot(kind, i)
				var action := "select"
				if not entry.is_empty() and String(entry.get("kind", "")) == "engine":
					action = "engine_allocation"
				return {"kind": kind, "index": i, "action": action, "payload_index": int(entry.get("payload_index", -1))}
	return {}

func _entry_for_slot(kind: String, index: int) -> Dictionary:
	var entries := plugin_entries if kind == "plugin" else software_entries
	if index >= 0 and index < entries.size() and entries[index] is Dictionary:
		var entry: Dictionary = entries[index]
		return {} if bool(entry.get("empty", false)) else entry
	return {}

func _occupied_entry_count(entries: Array) -> int:
	var count := 0
	for entry in entries:
		if entry is Dictionary and not bool(Dictionary(entry).get("empty", false)):
			count += 1
	return count

func _slot_kind_at_position(pos: Vector2) -> String:
	if _plugin_group_rect().has_point(pos):
		return "plugin"
	if _software_group_rect().has_point(pos):
		return "software"
	return ""

func _plugin_group_rect() -> Rect2:
	return Rect2(Vector2(10.0, 56.0), Vector2(size.x * 0.5 - 15.0, size.y - 82.0))

func _software_group_rect() -> Rect2:
	return Rect2(Vector2(size.x * 0.5 + 5.0, 56.0), Vector2(size.x * 0.5 - 15.0, size.y - 82.0))

func _slot_rect(kind: String, index: int) -> Rect2:
	var group_rect := _plugin_group_rect() if kind == "plugin" else _software_group_rect()
	var y := group_rect.position.y + 26.0 + float(index) * 42.0 - _scroll_offset(kind)
	return Rect2(group_rect.position + Vector2(8.0, y - group_rect.position.y), Vector2(group_rect.size.x - 16.0, 36.0))

func _group_content_rect(kind: String) -> Rect2:
	var group_rect := _plugin_group_rect() if kind == "plugin" else _software_group_rect()
	return Rect2(group_rect.position + Vector2(8.0, 24.0), Vector2(group_rect.size.x - 16.0, group_rect.size.y - 30.0))

func _scroll_offset(kind: String) -> float:
	return plugin_scroll if kind == "plugin" else software_scroll

func _scroll_group(kind: String, delta: float) -> void:
	if kind == "plugin":
		plugin_scroll = clampf(plugin_scroll + delta, 0.0, _max_scroll("plugin"))
	elif kind == "software":
		software_scroll = clampf(software_scroll + delta, 0.0, _max_scroll("software"))
	queue_redraw()

func _max_scroll(kind: String) -> float:
	var entries := plugin_entries if kind == "plugin" else software_entries
	var capacity := plugin_capacity if kind == "plugin" else software_capacity
	var max_slots := maxi(capacity, entries.size())
	var content_height := float(max_slots) * 42.0
	return maxf(0.0, content_height - _group_content_rect(kind).size.y)

func _clamp_scroll_offsets() -> void:
	plugin_scroll = clampf(plugin_scroll, 0.0, _max_scroll("plugin"))
	software_scroll = clampf(software_scroll, 0.0, _max_scroll("software"))

func _draw_scrollbar(kind: String, rect: Rect2, _max_slots: int, color: Color) -> void:
	var max_scroll := _max_scroll(kind)
	if max_scroll <= 0.1:
		return
	var track := _scrollbar_track_rect(kind)
	draw_rect(track, Color(color.r, color.g, color.b, 0.18), true)
	var thumb := _scrollbar_thumb_rect(kind)
	draw_rect(thumb, Color(color.r, color.g, color.b, 0.78), true)

func _scrollbar_track_rect(kind: String) -> Rect2:
	var group_rect := _plugin_group_rect() if kind == "plugin" else _software_group_rect()
	var content_rect := _group_content_rect(kind)
	return Rect2(Vector2(group_rect.end.x - 8.0, content_rect.position.y), Vector2(3.0, content_rect.size.y))

func _scrollbar_thumb_rect(kind: String) -> Rect2:
	var track := _scrollbar_track_rect(kind)
	var entries := plugin_entries if kind == "plugin" else software_entries
	var capacity := plugin_capacity if kind == "plugin" else software_capacity
	var max_slots := maxi(capacity, entries.size())
	var total_height := maxf(1.0, float(max_slots) * 42.0)
	var thumb_height := clampf(track.size.y / total_height * track.size.y, 18.0, track.size.y)
	var max_scroll := _max_scroll(kind)
	var scroll_t := 0.0 if max_scroll <= 0.1 else _scroll_offset(kind) / max_scroll
	return Rect2(Vector2(track.position.x - 1.0, track.position.y + (track.size.y - thumb_height) * scroll_t), Vector2(5.0, thumb_height))

func _scrollbar_kind_at_position(pos: Vector2) -> String:
	for kind in ["plugin", "software"]:
		if _max_scroll(kind) <= 0.1:
			continue
		if _scrollbar_track_rect(kind).grow(5.0).has_point(pos) or _scrollbar_thumb_rect(kind).grow(5.0).has_point(pos):
			return kind
	return ""

func _drag_scrollbar_to(kind: String, thumb_top_y: float) -> void:
	var max_scroll := _max_scroll(kind)
	if max_scroll <= 0.1:
		return
	var track := _scrollbar_track_rect(kind)
	var thumb := _scrollbar_thumb_rect(kind)
	var movable := maxf(1.0, track.size.y - thumb.size.y)
	var t := clampf((thumb_top_y - track.position.y) / movable, 0.0, 1.0)
	if kind == "plugin":
		plugin_scroll = t * max_scroll
	elif kind == "software":
		software_scroll = t * max_scroll
	queue_redraw()

func _remove_rect_for_slot(slot_rect: Rect2) -> Rect2:
	return Rect2(Vector2(slot_rect.end.x - 33.0, slot_rect.position.y + 6.0), Vector2(26.0, 20.0))

func _rebind_rect_for_slot(slot_rect: Rect2, has_source_priority: bool = false) -> Rect2:
	var offset := 130.0 if has_source_priority else 82.0
	return Rect2(Vector2(slot_rect.end.x - offset, slot_rect.position.y + 6.0), Vector2(44.0, 20.0))

func _priority_up_rect_for_slot(slot_rect: Rect2) -> Rect2:
	return Rect2(Vector2(slot_rect.end.x - 82.0, slot_rect.position.y + 6.0), Vector2(20.0, 20.0))

func _priority_down_rect_for_slot(slot_rect: Rect2) -> Rect2:
	return Rect2(Vector2(slot_rect.end.x - 58.0, slot_rect.position.y + 6.0), Vector2(20.0, 20.0))

func _source_priority_reset_rect() -> Rect2:
	var rect := _software_group_rect()
	return Rect2(Vector2(rect.end.x - 46.0, rect.position.y + 5.0), Vector2(34.0, 18.0))

func _has_source_priority_entries() -> bool:
	for raw_entry in software_entries:
		if raw_entry is Dictionary and bool(Dictionary(raw_entry).get("source_code_priority", false)):
			return true
	return false

func _draw_source_priority_button(rect: Rect2, label: String, enabled: bool, color: Color) -> void:
	var font := ThemeDB.get_fallback_font()
	var bg := Color(color.r, color.g, color.b, 0.28) if enabled else Color(0.08, 0.09, 0.1, 0.72)
	var fg := Color(0.92, 0.88, 1.0, 1.0) if enabled else Color(0.54, 0.58, 0.62, 0.72)
	draw_rect(rect, bg, true)
	draw_rect(rect, color.lerp(Color.WHITE, 0.18) if enabled else Color(0.22, 0.24, 0.26, 0.7), false, 1.0)
	draw_string(font, rect.position + Vector2(2.0, 14.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 4.0, 11, fg)

func _close_rect() -> Rect2:
	return Rect2(Vector2(size.x - 34.0, 8.0), Vector2(24.0, 22.0))

func _binding_panel_rect() -> Rect2:
	return Rect2(Vector2(10.0, 56.0), Vector2(size.x - 20.0, size.y - 82.0))

func _binding_cancel_rect() -> Rect2:
	var rect := _binding_panel_rect()
	return Rect2(Vector2(rect.end.x - 82.0, rect.position.y + 10.0), Vector2(70.0, 24.0))

func _binding_list_rect() -> Rect2:
	var rect := _binding_panel_rect()
	return Rect2(rect.position + Vector2(12.0, 48.0), Vector2(rect.size.x - 24.0, rect.size.y - 132.0))

func _binding_key_rect(key_value: int) -> Rect2:
	var rect := _binding_panel_rect()
	var columns := 3
	var width := minf(72.0, (rect.size.x - 40.0) / float(columns))
	var gap := 8.0
	var total := width * float(columns) + gap * float(columns - 1)
	var index := clampi(key_value - 1, 0, 5)
	var column := index % columns
	var row := index / columns
	var x := rect.get_center().x - total * 0.5 + float(column) * (width + gap)
	var y := rect.end.y - 70.0 + float(row) * 32.0
	return Rect2(Vector2(x, y), Vector2(width, 26.0))

func _binding_action_side_rect(side: String) -> Rect2:
	var rect := _binding_panel_rect()
	var width := 132.0
	var gap := 12.0
	var total := width * 2.0 + gap
	var index := 0 if side == "left" else 1
	var x := rect.get_center().x - total * 0.5 + float(index) * (width + gap)
	var y := rect.end.y - 70.0
	return Rect2(Vector2(x, y), Vector2(width, 28.0))

func _binding_candidate_rect(index: int) -> Rect2:
	var list_rect := _binding_list_rect()
	var y := list_rect.position.y + float(index) * 32.0 - binding_scroll
	return Rect2(Vector2(list_rect.position.x, y), Vector2(list_rect.size.x, 28.0))

func _binding_max_scroll() -> float:
	var list_height := maxf(0.0, float(binding_candidates.size()) * 32.0)
	return maxf(0.0, list_height - _binding_list_rect().size.y)

func _binding_candidate_index_at(pos: Vector2) -> int:
	var list_rect := _binding_list_rect()
	if not list_rect.has_point(pos):
		return -1
	for i in range(binding_candidates.size()):
		if _binding_candidate_rect(i).has_point(pos):
			return i
	return -1

func _draw_binding_panel() -> void:
	var font := ThemeDB.get_fallback_font()
	var rect := _binding_panel_rect()
	draw_rect(rect, Color(0.006, 0.018, 0.028, 0.98), true)
	draw_rect(rect, Color(0.42, 0.9, 1.0, 0.82), false, 1.4)
	draw_string(font, rect.position + Vector2(12.0, 18.0), _trim(binding_title, 48), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108.0, 13, Color(0.92, 0.98, 1.0, 1.0))
	draw_string(font, rect.position + Vector2(12.0, 36.0), _trim(binding_subtitle, 72), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108.0, 10, Color(1.0, 0.86, 0.32, 0.92))
	draw_rect(_binding_cancel_rect(), Color(0.18, 0.05, 0.06, 0.92), true)
	draw_rect(_binding_cancel_rect(), Color(1.0, 0.34, 0.24, 0.78), false, 1.0)
	draw_string(font, _binding_cancel_rect().position + Vector2(4.0, 16.0), _label("取消", "CANCEL"), HORIZONTAL_ALIGNMENT_CENTER, _binding_cancel_rect().size.x - 8.0, 10, Color(1.0, 0.82, 0.72, 1.0))
	var list_rect := _binding_list_rect()
	draw_rect(list_rect, Color(0.0, 0.0, 0.0, 0.22), true)
	for i in range(binding_candidates.size()):
		var row := _binding_candidate_rect(i)
		if row.end.y < list_rect.position.y or row.position.y > list_rect.end.y:
			continue
		var candidate: Dictionary = binding_candidates[i]
		var valid := bool(candidate.get("valid", false))
		var selected := i == binding_selected_index
		var color := Color(0.34, 0.95, 1.0, 0.88) if valid else Color(1.0, 0.28, 0.22, 0.72)
		var bg := Color(color.r * 0.12, color.g * 0.14, color.b * 0.16, 0.82)
		if selected:
			bg = Color(0.12, 0.28, 0.36, 0.96)
		draw_rect(row, bg, true)
		draw_rect(row, color, false, 1.0)
		var nodes_label := String(candidate.get("nodes_label", ""))
		var drive := float(candidate.get("required_drive", 0.0))
		var label_text := String(candidate.get("label", ""))
		if nodes_label != "":
			label_text += "  N%s" % nodes_label
		var note_text := String(candidate.get("note", ""))
		if drive > 0.0:
			note_text += ("  动力%.0f" if ui_language == "zh" else "  PWR%.0f") % drive
		draw_string(font, row.position + Vector2(8.0, 17.0), _trim(label_text, 34), HORIZONTAL_ALIGNMENT_LEFT, row.size.x * 0.52, 10, Color(0.92, 0.98, 1.0, 0.95) if valid else Color(1.0, 0.76, 0.72, 0.9))
		draw_string(font, row.position + Vector2(row.size.x * 0.54, 17.0), _trim(note_text, 34), HORIZONTAL_ALIGNMENT_LEFT, row.size.x * 0.44, 9, Color(0.78, 0.9, 0.96, 0.85) if valid else Color(1.0, 0.58, 0.48, 0.85))
	if binding_candidates.is_empty():
		draw_string(font, list_rect.position + Vector2(10.0, 28.0), _label("没有可绑定目标。", "No bindable target."), HORIZONTAL_ALIGNMENT_LEFT, list_rect.size.x - 20.0, 12, Color(1.0, 0.54, 0.42, 0.9))
	if _binding_max_scroll() > 0.1:
		var track := Rect2(Vector2(list_rect.end.x - 6.0, list_rect.position.y + 2.0), Vector2(4.0, list_rect.size.y - 4.0))
		var total_height := maxf(1.0, float(binding_candidates.size()) * 32.0)
		var thumb_height := clampf(track.size.y / total_height * track.size.y, 18.0, track.size.y)
		var scroll_t := binding_scroll / maxf(1.0, _binding_max_scroll())
		var thumb := Rect2(Vector2(track.position.x - 1.0, track.position.y + (track.size.y - thumb_height) * scroll_t), Vector2(6.0, thumb_height))
		draw_rect(track, Color(0.42, 0.9, 1.0, 0.16), true)
		draw_rect(thumb, Color(0.42, 0.9, 1.0, 0.76), true)
	var key_hint := _label("选择攻击键", "PICK ATTACK KEY") if binding_key_ready else _label("先点合法部位", "PICK TARGET FIRST")
	if binding_action_side_required:
		key_hint = _label("先选择动作侧", "PICK ACTION SIDE") if binding_action_side == "" else _label("动作侧已选，选择攻击键", "ACTION SIDE SET, PICK KEY")
	draw_string(font, Vector2(rect.position.x + 14.0, rect.end.y - 77.0), key_hint, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 9, Color(0.72, 0.92, 1.0, 0.86) if binding_key_ready else Color(0.8, 0.72, 0.62, 0.72))
	if binding_action_side_required:
		for side in ["left", "right"]:
			var side_rect := _binding_action_side_rect(side)
			var selected_side: bool = binding_action_side == side
			var side_color: Color = Color(0.45, 1.0, 0.78, 0.96) if selected_side else Color(0.34, 0.66, 0.92, 0.9)
			draw_rect(side_rect, Color(side_color.r * 0.14, side_color.g * 0.14, side_color.b * 0.16, 0.94), true)
			draw_rect(side_rect, side_color, false, 1.0 if not selected_side else 2.0)
			var side_label: String = _label("左侧动作", "LEFT ACTION") if side == "left" else _label("右侧动作", "RIGHT ACTION")
			draw_string(font, side_rect.position + Vector2(4.0, 18.0), side_label, HORIZONTAL_ALIGNMENT_CENTER, side_rect.size.x - 8.0, 10, Color(0.9, 1.0, 0.96, 1.0))
		if binding_action_side == "":
			return
	for key_value in range(1, 7):
		var key_rect := _binding_key_rect(key_value)
		var key_color := Color(0.36, 0.92, 1.0, 0.95) if binding_key_ready else Color(0.28, 0.32, 0.36, 0.78)
		draw_rect(key_rect, Color(key_color.r * 0.16, key_color.g * 0.16, key_color.b * 0.18, 0.9), true)
		draw_rect(key_rect, key_color, false, 1.0)
		draw_string(font, key_rect.position + Vector2(3.0, 17.0), "%d %s" % [key_value, ["U", "I", "O", "J", "K", "L"][key_value - 1]], HORIZONTAL_ALIGNMENT_CENTER, key_rect.size.x - 6.0, 10, Color(0.9, 0.98, 1.0, 1.0) if binding_key_ready else Color(0.62, 0.68, 0.72, 0.82))

func _label(zh: String, en: String) -> String:
	return zh if ui_language == "zh" else en

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
