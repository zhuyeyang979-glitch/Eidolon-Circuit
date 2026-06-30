extends RefCounted
class_name UILifecycleService

const EDITOR_UNIT_ACTION_KEYS := ["load_unit"]
const EDITOR_UNIT_MANAGEMENT_ACTION_KEYS := ["duplicate", "delete"]
const EDITOR_ASSEMBLY_GUIDE_ACTION_KEYS := ["assembly_guide_prev", "assembly_guide_apply", "assembly_guide_next"]
const EDITOR_BOARD_PRIMARY_ACTION_KEYS := ["save_canvas", "training_import", "open_saved_units"]
const EDITOR_UNIT_PAGE_ACTION_KEYS := ["prev_unit", "next_unit"]
const EDITOR_CANVAS_ACTION_KEYS := ["blank_canvas", "board_tool_layout", "board_tool_pose", "add_node", "link_node", "auto_connect", "evaluate_connection", "restore_suggested_connection", "copy_selection", "cut_selection", "paste_selection", "delete_selected_part", "undo_canvas", "clear_canvas", "toggle_barrier_grid", "board_zoom_out", "board_zoom_in", "board_zoom_reset"]
const EDITOR_ORIENTATION_ACTION_KEYS := ["set_handedness_left", "set_handedness_right", "flip_handedness"]
const EDITOR_BARRIER_HIDDEN_CANVAS_ACTION_KEYS := ["board_tool_layout", "board_tool_pose", "add_node", "link_node", "auto_connect", "evaluate_connection", "restore_suggested_connection", "copy_selection", "cut_selection", "paste_selection"]
const EDITOR_CLIPBOARD_ACTION_KEYS := ["copy_selection", "cut_selection", "paste_selection"]
const EDITOR_ZOOM_ACTION_KEYS := ["board_zoom_out", "board_zoom_in", "board_zoom_reset"]


static func trim_dictionary_cache(cache: Dictionary, max_entries: int) -> int:
	var removed := 0
	while cache.size() > max_entries:
		var keys := cache.keys()
		if keys.is_empty():
			break
		cache.erase(keys[0])
		removed += 1
	return removed


static func node_descendant_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	for child in node.get_children():
		count += 1
		if child is Node:
			count += node_descendant_count(child)
	return count


static func visible_control_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is Control:
		var control: Control = node
		if control.visible:
			count += 1
	for child in node.get_children():
		if child is Node:
			count += visible_control_count(child)
	return count


static func layer_snapshot(layers: Dictionary) -> Dictionary:
	var layer_counts := {}
	var layer_visible_controls := {}
	for key in layers.keys():
		var layer = layers[key]
		layer_counts[key] = node_descendant_count(layer)
		layer_visible_controls[key] = visible_control_count(layer)
	return {
		"nodes": layer_counts,
		"visible_controls": layer_visible_controls,
	}


static func _button_spec(key: String, text: String, position: Vector2, size: Vector2) -> Dictionary:
	return {
		"key": key,
		"text": text,
		"position": position,
		"size": size,
	}


static func editor_action_build_specs() -> Dictionary:
	var panel_buttons := [
		_button_spec("load", "单位库", Vector2(936.0, 86.0), Vector2(132.0, 30.0)),
		_button_spec("parts", "零件库", Vector2(1072.0, 86.0), Vector2(132.0, 30.0)),
	]
	var assembly_guide_actions := [
		_button_spec("assembly_guide_prev", "<", Vector2(1100.0, 118.0), Vector2(24.0, 22.0)),
		_button_spec("assembly_guide_apply", "前往", Vector2(1128.0, 118.0), Vector2(48.0, 22.0)),
		_button_spec("assembly_guide_next", ">", Vector2(1180.0, 118.0), Vector2(26.0, 22.0)),
	]
	var unit_action_keys := [
		["edit_side", "编辑P1"],
		["load_unit", "单位库"],
		["load_team", "队伍编成"],
		["add_to_team", "加入队伍"],
		["import_team", "导入队伍"],
		["export_team", "导出队伍"],
		["clear_team", "清空队伍"],
		["toggle_match_format", "规则10/6"],
		["prev_unit", "< 单位"],
		["next_unit", "单位 >"],
		["duplicate", "复制"],
		["delete", "删除"],
		["initial", "首发"],
		["sortie_toggle", "出战"],
		["sortie_up", "前移"],
		["sortie_down", "后移"],
		["bind_prev", "绑定<"],
		["bind_next", "绑定>"],
		["bind_clear", "解绑"],
		["copy_ai", "复制电脑"],
	]
	var unit_actions := []
	for i in range(unit_action_keys.size()):
		unit_actions.append(_button_spec(
			String(unit_action_keys[i][0]),
			String(unit_action_keys[i][1]),
			Vector2(936.0 + float(i % 3) * 90.0, 294.0 + float(floori(float(i) / 3.0)) * 30.0),
			Vector2(84.0, 26.0)
		))
	var board_primary_actions := [
		_button_spec("save_canvas", "保存为单位", Vector2(352.0, 652.0), Vector2(146.0, 28.0)),
		_button_spec("training_import", "训练测试", Vector2(508.0, 652.0), Vector2(146.0, 28.0)),
		_button_spec("open_saved_units", "已保存单位", Vector2(664.0, 652.0), Vector2(146.0, 28.0)),
	]
	var canvas_tool_keys := [
		["blank_canvas", "空白画布"],
		["board_tool_layout", "布局"],
		["board_tool_pose", "姿态"],
		["add_node", "+ 节点"],
		["link_node", "连接上个"],
		["auto_connect", "自动连接"],
		["evaluate_connection", "评估连接"],
		["restore_suggested_connection", "恢复建议"],
		["copy_selection", "复制"],
		["cut_selection", "剪切"],
		["paste_selection", "粘贴"],
		["delete_selected_part", "删选中"],
		["undo_canvas", "退一步"],
		["clear_canvas", "全部删除"],
		["toggle_barrier_grid", "辅助线"],
		["set_handedness_left", "左挂刃"],
		["set_handedness_right", "右挂刃"],
		["flip_handedness", "翻侧刃"],
	]
	var canvas_tools := []
	for i in range(canvas_tool_keys.size()):
		canvas_tools.append(_button_spec(
			String(canvas_tool_keys[i][0]),
			String(canvas_tool_keys[i][1]),
			Vector2(20.0 + float(i) * 76.0, 688.0),
			Vector2(72.0, 24.0)
		))
	var board_zoom_actions := [
		_button_spec("board_zoom_out", "-", Vector2(24.0, 652.0), Vector2(42.0, 24.0)),
		_button_spec("board_zoom_in", "+", Vector2(132.0, 652.0), Vector2(42.0, 24.0)),
		_button_spec("board_zoom_reset", "重置", Vector2(182.0, 652.0), Vector2(70.0, 24.0)),
	]
	var catalog_page_actions := [
		_button_spec("prev_catalog", "<", Vector2(936.0, 654.0), Vector2(24.0, 22.0)),
		_button_spec("next_catalog", ">", Vector2(1182.0, 654.0), Vector2(24.0, 22.0)),
	]
	var sort_actions := [
		_button_spec("sort_prev", "<", Vector2(936.0, 294.0), Vector2(24.0, 22.0)),
		_button_spec("sort_key", "排序", Vector2(936.0, 294.0), Vector2(160.0, 22.0)),
		_button_spec("sort_dir", "升序", Vector2(1100.0, 294.0), Vector2(106.0, 22.0)),
	]
	return {
		"panel_buttons": panel_buttons,
		"assembly_guide_actions": assembly_guide_actions,
		"unit_actions": unit_actions,
		"board_primary_actions": board_primary_actions,
		"canvas_tools": canvas_tools,
		"board_zoom_actions": board_zoom_actions,
		"catalog_page_actions": catalog_page_actions,
		"sort_actions": sort_actions,
		"template_toggle": _button_spec("toggle_templates", "导入模板", Vector2(936.0, 146.0), Vector2(270.0, 26.0)),
	}


static func editor_part_group_button_presentation(group_key: String, group_order: Array, active_group: String, parts_visible: bool, text: String) -> Dictionary:
	var key := String(group_key)
	var group_index := group_order.find(key)
	if group_index < 0:
		group_index = 0
	return {
		"visible": parts_visible,
		"disabled": not parts_visible,
		"position": Vector2(936.0 + float(group_index % 3) * 90.0, 146.0 + float(floori(float(group_index) / 3.0)) * 26.0),
		"size": Vector2(84.0, 24.0),
		"text": String(text),
		"modulate": Color(1.0, 0.86, 0.28, 1.0) if key == String(active_group) else Color(0.84, 0.9, 0.94, 1.0),
	}


static func editor_part_filter_button_presentation(button_index: int, filter_options: Array, part_group_mode: String, active_filter: String, parts_visible: bool, text: String) -> Dictionary:
	var terminal_weapon := String(part_group_mode) == "terminal_weapon"
	var filter_columns := 5 if terminal_weapon else 3
	var filter_width := 52.0 if terminal_weapon else 84.0
	var filter_step_x := 56.0 if terminal_weapon else 90.0
	var filter_step_y := 24.0 if terminal_weapon else 26.0
	var visible := parts_visible and button_index >= 0 and button_index < filter_options.size()
	var filter_key := ""
	if visible and filter_options[button_index] is Dictionary:
		filter_key = String(Dictionary(filter_options[button_index]).get("key", "all"))
	return {
		"visible": visible,
		"disabled": not visible,
		"position": Vector2(936.0 + float(button_index % filter_columns) * filter_step_x, 204.0 + float(floori(float(button_index) / float(filter_columns))) * filter_step_y),
		"size": Vector2(filter_width, 22.0),
		"text": String(text),
		"modulate": Color(1.0, 0.86, 0.28, 1.0) if filter_key == String(active_filter) else Color(0.84, 0.9, 0.94, 1.0),
	}


static func editor_ammo_size_control_presentation(ammo_slider_visible: bool, ammo_size_rank: int, zh: bool, value_text: String, tick_labels: Array) -> Dictionary:
	var title_plan := {
		"visible": ammo_slider_visible,
		"position": Vector2(936.0, 258.0),
		"size": Vector2(72.0, 18.0),
		"text": "弹药尺寸" if zh else "AMMO SIZE",
	}
	var slider_plan := {
		"visible": ammo_slider_visible,
		"editable": ammo_slider_visible,
		"position": Vector2(1010.0, 257.0),
		"size": Vector2(176.0, 22.0),
		"value": float(ammo_size_rank),
		"tooltip": "安装弹药时选择弹仓尺寸；弹数、价格、质量和槽位体积同步增加。" if zh else "Choose ammo bay size at install time; ammo count, cost, mass, and slot volume scale together.",
	}
	var value_plan := {
		"visible": ammo_slider_visible,
		"position": Vector2(1190.0, 258.0),
		"size": Vector2(54.0, 18.0),
		"text": String(value_text),
	}
	var tick_plans := []
	for i in range(tick_labels.size()):
		var rank := i + 1
		tick_plans.append({
			"visible": ammo_slider_visible,
			"position": Vector2(1002.0 + float(i) * 44.0, 278.0),
			"size": Vector2(34.0, 14.0),
			"text": String(tick_labels[i]),
			"modulate": Color(1.0, 0.86, 0.28, 1.0) if rank == ammo_size_rank else Color(0.76, 0.9, 1.0, 0.72),
		})
	return {
		"title": title_plan,
		"slider": slider_plan,
		"value": value_plan,
		"ticks": tick_plans,
	}


static func editor_sort_controls_presentation(parts_visible: bool, sort_menu_open: bool, available_sort_keys: Array, current_sort_key: String, sort_ascending: bool, sort_key_order: Array, sort_names: Dictionary, zh: bool) -> Dictionary:
	var normalized_sort_key := String(current_sort_key)
	if available_sort_keys.is_empty():
		available_sort_keys = [normalized_sort_key]
	if not available_sort_keys.has(normalized_sort_key):
		normalized_sort_key = String(available_sort_keys[0])
	var panel_visible := parts_visible and sort_menu_open
	var sort_rows := int(ceilf(float(maxi(1, available_sort_keys.size())) / 3.0))
	var option_plans := []
	var visible_sort_index := 0
	for i in range(sort_key_order.size()):
		var option_key := String(sort_key_order[i])
		var option_visible := panel_visible and available_sort_keys.has(option_key)
		var option_plan := {
			"key": option_key,
			"visible": option_visible,
			"disabled": not option_visible,
			"text": String(sort_names.get(option_key, option_key.to_upper())),
			"modulate": Color(1.0, 0.86, 0.28, 1.0) if option_key == normalized_sort_key else Color(0.84, 0.9, 0.94, 1.0),
			"move_to_front": option_visible,
		}
		if option_visible:
			option_plan["position"] = Vector2(940.0 + float(visible_sort_index % 3) * 88.0, 326.0 + float(floori(float(visible_sort_index) / 3.0)) * 28.0)
			visible_sort_index += 1
		option_plans.append(option_plan)
	return {
		"sort_key": normalized_sort_key,
		"sort_key_text": ("排序：%s" if zh else "SORT: %s") % String(sort_names.get(normalized_sort_key, normalized_sort_key.to_upper())),
		"sort_dir_text": ("正序 ↑" if sort_ascending else "反序 ↓") if zh else ("ASC ↑" if sort_ascending else "DESC ↓"),
		"panel": {
			"visible": panel_visible,
			"size": Vector2(278.0, 16.0 + float(sort_rows) * 28.0),
			"move_to_front": panel_visible,
		},
		"options": option_plans,
		"sort_dir_move_to_front": panel_visible,
	}


static func editor_panel_visibility_plan(panel_mode: String, load_mode: String, body_board_enabled: bool, barrier_screen_board: bool, has_custom_topology: bool, part_group_mode: String, part_filter_mode: String, roster_count: int) -> Dictionary:
	var normalized_load_mode := String(load_mode)
	if normalized_load_mode == "team":
		normalized_load_mode = "unit"
	var mode := String(panel_mode)
	var load_visible := mode == "load"
	var parts_visible := mode == "parts"
	var custom_board_enabled := body_board_enabled and has_custom_topology and not barrier_screen_board
	var unit_action_keys := EDITOR_UNIT_ACTION_KEYS.duplicate()
	if normalized_load_mode == "unit":
		unit_action_keys.append_array(EDITOR_UNIT_MANAGEMENT_ACTION_KEYS)
	return {
		"mode": mode,
		"load_mode": normalized_load_mode,
		"load_visible": load_visible,
		"unit_visible": load_visible,
		"parts_visible": parts_visible,
		"shop_visible": false,
		"template_visible": load_visible,
		"color_visible": false,
		"stats_visible": false,
		"custom_board_enabled": custom_board_enabled,
		"ammo_slider_visible": parts_visible and String(part_filter_mode) == "ammo",
		"part_group_mode": String(part_group_mode),
		"unit_action_keys": unit_action_keys,
		"assembly_guide_action_keys": EDITOR_ASSEMBLY_GUIDE_ACTION_KEYS.duplicate(),
		"board_primary_action_keys": EDITOR_BOARD_PRIMARY_ACTION_KEYS.duplicate(),
		"unit_page_action_keys": EDITOR_UNIT_PAGE_ACTION_KEYS.duplicate(),
		"canvas_action_keys": EDITOR_CANVAS_ACTION_KEYS.duplicate(),
		"orientation_action_keys": EDITOR_ORIENTATION_ACTION_KEYS.duplicate(),
		"unit_page_actions_enabled": roster_count > 1,
	}


static func editor_action_state(action_key: String, visibility_plan: Dictionary, barrier_screen_board: bool, orientation_choice_active: bool, selected_handedness_active: bool, sort_menu_open: bool, clipboard_busy: bool, has_selection: bool, has_topology_clipboard: bool) -> Dictionary:
	var key := String(action_key)
	var assembly_guide_action_keys: Array = Array(visibility_plan.get("assembly_guide_action_keys", []))
	var board_primary_action_keys: Array = Array(visibility_plan.get("board_primary_action_keys", []))
	var unit_page_action_keys: Array = Array(visibility_plan.get("unit_page_action_keys", []))
	var canvas_action_keys: Array = Array(visibility_plan.get("canvas_action_keys", []))
	var orientation_action_keys: Array = Array(visibility_plan.get("orientation_action_keys", []))
	var state := {
		"kind": "unit",
		"managed": true,
		"manage_disabled": true,
		"visible": false,
		"disabled": true,
		"index": -1,
	}
	if assembly_guide_action_keys.has(key):
		state["kind"] = "assembly_guide"
		state["managed"] = false
		return state
	if board_primary_action_keys.has(key):
		state["kind"] = "board_primary"
		state["visible"] = true
		state["disabled"] = false
		state["index"] = board_primary_action_keys.find(key)
		return state
	if unit_page_action_keys.has(key):
		state["kind"] = "unit_page"
		state["visible"] = true
		state["disabled"] = not bool(visibility_plan.get("unit_page_actions_enabled", false))
		state["index"] = unit_page_action_keys.find(key)
		return state
	if canvas_action_keys.has(key):
		state["kind"] = "canvas"
		var visible := true
		if EDITOR_BARRIER_HIDDEN_CANVAS_ACTION_KEYS.has(key):
			visible = not barrier_screen_board
		elif key == "toggle_barrier_grid":
			visible = barrier_screen_board
		state["visible"] = visible
		state["disabled"] = not visible
		state["index"] = -1 if EDITOR_ZOOM_ACTION_KEYS.has(key) else canvas_action_keys.find(key)
		if EDITOR_CLIPBOARD_ACTION_KEYS.has(key):
			state["disabled"] = clipboard_busy or (key in ["copy_selection", "cut_selection"] and not has_selection) or (key == "paste_selection" and not has_topology_clipboard)
		return state
	if orientation_action_keys.has(key):
		state["kind"] = "orientation"
		var visible := orientation_choice_active if key in ["set_handedness_left", "set_handedness_right"] else selected_handedness_active and not orientation_choice_active
		state["visible"] = visible
		state["disabled"] = not visible
		return state
	if key == "toggle_templates":
		state["kind"] = "hidden"
		state["manage_disabled"] = false
		return state
	if key == "sort_prev":
		state["kind"] = "hidden"
		return state
	if key == "sort_dir":
		state["kind"] = "sort_dir"
		state["visible"] = bool(visibility_plan.get("parts_visible", false)) and sort_menu_open
		state["disabled"] = not bool(state["visible"])
		return state
	if key in ["prev_catalog", "next_catalog"]:
		state["kind"] = "catalog_page"
		state["visible"] = bool(visibility_plan.get("parts_visible", false)) or bool(visibility_plan.get("load_visible", false))
		state["disabled"] = not bool(state["visible"])
		return state
	if key == "sort_key":
		state["kind"] = "sort_key"
		state["visible"] = bool(visibility_plan.get("parts_visible", false))
		state["disabled"] = not bool(state["visible"])
		return state
	var unit_action_keys: Array = Array(visibility_plan.get("unit_action_keys", []))
	state["visible"] = bool(visibility_plan.get("unit_visible", false)) and unit_action_keys.has(key)
	state["disabled"] = not bool(state["visible"])
	return state


static func editor_action_presentation(action_key: String, action_state: Dictionary, visible_unit_action_index: int, context: Dictionary) -> Dictionary:
	var key := String(action_key)
	var kind := String(action_state.get("kind", "unit"))
	var visible := bool(action_state.get("visible", false))
	var disabled := bool(action_state.get("disabled", true))
	var zh := bool(context.get("zh", false))
	var plan := {
		"kind": kind,
		"managed": bool(action_state.get("managed", true)),
		"visible": visible,
		"disabled": disabled,
		"manage_disabled": bool(action_state.get("manage_disabled", true)),
		"advance_unit_action_index": false,
	}
	if not bool(plan.get("managed", true)):
		return plan
	if kind == "board_primary":
		plan["position"] = Vector2(352.0 + float(action_state.get("index", 0)) * 156.0, 596.0)
		plan["size"] = Vector2(146.0, 28.0)
		if key == "save_canvas":
			plan["text"] = "保存为单位" if zh else "SAVE UNIT"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0)
		elif key == "training_import":
			plan["text"] = "训练测试" if zh else "TEST"
			plan["modulate"] = Color(0.86, 0.68, 1.0, 1.0)
		else:
			plan["text"] = "已保存单位" if zh else "SAVED"
			plan["modulate"] = Color(0.74, 0.92, 1.0, 1.0)
	elif kind == "unit_page":
		if key == "prev_unit":
			plan["position"] = Vector2(270.0, 596.0)
			plan["text"] = "< 单位" if zh else "< UNIT"
		else:
			plan["position"] = Vector2(818.0, 596.0)
			plan["text"] = "单位 >" if zh else "UNIT >"
		plan["size"] = Vector2(74.0, 28.0)
		var unit_page_enabled := bool(context.get("unit_page_actions_enabled", not disabled))
		plan["modulate"] = Color(0.78, 0.94, 1.0, 1.0) if unit_page_enabled else Color(0.54, 0.62, 0.68, 0.7)
	elif kind == "canvas":
		var canvas_index := int(action_state.get("index", -1))
		if canvas_index >= 0:
			plan["position"] = Vector2(20.0 + float(canvas_index) * 76.0, 688.0)
			plan["size"] = Vector2(72.0, 24.0)
		if key in ["copy_selection", "cut_selection", "paste_selection"]:
			if key == "copy_selection":
				plan["text"] = "复制" if zh else "COPY"
			elif key == "cut_selection":
				plan["text"] = "剪切" if zh else "CUT"
			else:
				plan["text"] = "粘贴" if zh else "PASTE"
			plan["tooltip"] = "框选后可在单位页之间复制/剪切/粘贴" if zh else "Box-select nodes, then copy/cut/paste across unit pages."
			plan["modulate"] = Color(0.42, 1.0, 0.82, 1.0) if not disabled else Color(0.62, 0.7, 0.76, 0.72)
		if key == "board_tool_layout":
			plan["text"] = "布局" if zh else "LAYOUT"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0) if String(context.get("board_tool", "")) == "layout" else Color(0.78, 0.9, 1.0, 0.82)
		elif key == "board_tool_pose":
			plan["text"] = "姿态" if zh else "POSE"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0) if String(context.get("board_tool", "")) == "pose" else Color(0.78, 0.9, 1.0, 0.82)
		elif key == "auto_connect":
			plan["text"] = "自动连接" if zh else "AUTO"
			plan["tooltip"] = "按当前部件位置生成最合理的安全连接。" if zh else "Create safe suggested links for the current parts."
			plan["modulate"] = Color(0.42, 1.0, 0.82, 1.0)
		elif key == "evaluate_connection":
			plan["text"] = "评估连接" if zh else "EVAL"
			plan["tooltip"] = "检查连接是否可以进入入场姿态。" if zh else "Check whether connection is ready for entry pose."
			plan["modulate"] = context.get("connection_state_color", Color(0.82, 0.9, 1.0, 0.82))
		elif key == "restore_suggested_connection":
			plan["text"] = "恢复建议" if zh else "RESTORE"
			plan["tooltip"] = "重新应用系统建议的安全连接。" if zh else "Reapply the system's safe suggested links."
			plan["modulate"] = Color(0.78, 0.9, 1.0, 0.82)
		elif key == "toggle_barrier_grid":
			plan["text"] = "辅助线" if zh else "GRID"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0) if bool(context.get("barrier_grid_enabled", false)) else Color(0.78, 0.9, 1.0, 0.72)
	elif kind == "orientation":
		var x_pos := 776.0
		if key == "set_handedness_right":
			x_pos = 846.0
		plan["position"] = Vector2(x_pos, 688.0)
		plan["size"] = Vector2(66.0, 24.0)
		if key == "set_handedness_left":
			plan["text"] = "左挂刃" if zh else "LEFT"
		elif key == "set_handedness_right":
			plan["text"] = "右挂刃" if zh else "RIGHT"
		else:
			plan["text"] = "翻侧刃" if zh else "FLIP SIDE"
		plan["modulate"] = Color(0.42, 1.0, 0.82, 1.0) if visible else Color(0.78, 0.9, 1.0, 0.72)
	elif kind == "unit" and visible:
		plan["position"] = Vector2(936.0 + float(visible_unit_action_index % 2) * 136.0, 126.0 + float(floori(float(visible_unit_action_index) / 2.0)) * 30.0)
		plan["size"] = Vector2(130.0, 26.0)
		var load_mode := String(context.get("load_mode", "unit"))
		if key == "load_team":
			plan["text"] = "队伍编成" if zh else "TEAM"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0) if load_mode == "team" else Color(0.84, 0.9, 0.94, 1.0)
		elif key == "load_unit":
			plan["text"] = "单位库" if zh else "UNITS"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0) if load_mode == "unit" else Color(0.84, 0.9, 0.94, 1.0)
		elif key == "save_canvas":
			plan["text"] = "保存单位" if zh else "SAVE UNIT"
			plan["modulate"] = Color(1.0, 0.86, 0.28, 1.0)
		elif key == "open_saved_units":
			plan["text"] = "已存单位" if zh else "SAVED"
			plan["modulate"] = Color(0.74, 0.92, 1.0, 1.0)
		elif key == "add_to_team":
			plan["text"] = "加入队伍" if zh else "ADD TEAM"
			plan["modulate"] = Color(0.38, 0.96, 1.0, 1.0)
		elif key == "training_import":
			plan["text"] = "训练导入" if zh else "TRAIN"
			plan["modulate"] = Color(0.86, 0.68, 1.0, 1.0)
		elif key == "toggle_match_format":
			plan["text"] = String(context.get("match_format_text", ""))
			plan["modulate"] = Color(0.32, 0.96, 1.0, 1.0)
		else:
			plan["modulate"] = Color(0.84, 0.9, 0.94, 1.0)
		plan["advance_unit_action_index"] = true
	return plan
