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


static func _button_spec(key: String, text: String, position: Vector2, size: Vector2, name: String = "") -> Dictionary:
	var spec := {
		"key": key,
		"text": text,
		"position": position,
		"size": size,
	}
	if name != "":
		spec["name"] = name
	return spec


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
		_button_spec("save_canvas", "保存为单位", Vector2(352.0, 652.0), Vector2(146.0, 28.0), "BoardPrimarysave_canvas"),
		_button_spec("training_import", "训练测试", Vector2(508.0, 652.0), Vector2(146.0, 28.0), "BoardPrimarytraining_import"),
		_button_spec("open_saved_units", "已保存单位", Vector2(664.0, 652.0), Vector2(146.0, 28.0), "BoardPrimaryopen_saved_units"),
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


static func editor_part_library_build_specs(group_order: Array, build_slot_count: int, filter_button_count: int) -> Dictionary:
	var group_buttons := []
	for i in range(group_order.size()):
		var group_key := String(group_order[i])
		group_buttons.append({
			"key": group_key,
			"name": "PartGroup%s" % group_key,
			"position": Vector2(936.0 + float(i % 3) * 90.0, 146.0 + float(floori(float(i) / 3.0)) * 26.0),
			"size": Vector2(84.0, 24.0),
		})
	var slot_buttons := []
	for i in range(build_slot_count):
		slot_buttons.append({
			"index": i,
			"name": "Slot%d" % i,
			"position": Vector2(936.0 + float(i % 2) * 136.0, 206.0 + float(floori(float(i) / 2.0)) * 28.0),
			"size": Vector2(130.0, 24.0),
		})
	var filter_buttons := []
	for i in range(filter_button_count):
		filter_buttons.append({
			"index": i,
			"name": "PartFilter%d" % i,
			"position": Vector2(936.0 + float(i % 4) * 68.0, 204.0 + float(floori(float(i) / 4.0)) * 24.0),
			"size": Vector2(64.0, 22.0),
		})
	return {
		"group_buttons": group_buttons,
		"slot_buttons": slot_buttons,
		"filter_buttons": filter_buttons,
	}


static func editor_ammo_size_build_specs(tick_count: int) -> Dictionary:
	var ticks := []
	for i in range(maxi(0, tick_count)):
		ticks.append({
			"index": i,
			"name": "AmmoSizeTick%d" % i,
			"position": Vector2(1002.0 + float(i) * 44.0, 278.0),
			"size": Vector2(34.0, 14.0),
		})
	return {
		"title": {
			"name": "AmmoSizeTitle",
			"position": Vector2(936.0, 258.0),
			"size": Vector2(72.0, 18.0),
		},
		"slider": {
			"name": "AmmoSizeSlider",
			"position": Vector2(1010.0, 257.0),
			"size": Vector2(176.0, 22.0),
			"min_value": 1.0,
			"max_value": 5.0,
			"step": 1.0,
		},
		"value": {
			"name": "AmmoSizeValue",
			"position": Vector2(1190.0, 258.0),
			"size": Vector2(54.0, 18.0),
		},
		"ticks": ticks,
	}


static func editor_role_load_build_specs(role_order: Array, load_card_count: int) -> Dictionary:
	var role_buttons := []
	for i in range(role_order.size()):
		var role_key := String(role_order[i])
		role_buttons.append({
			"key": role_key,
			"name": "Role%s" % role_key,
			"position": Vector2(936.0 + float(i) * 92.0, 156.0),
			"size": Vector2(86.0, 32.0),
		})
	var load_cards := []
	for i in range(maxi(0, load_card_count)):
		load_cards.append({
			"index": i,
			"name": "LoadCard%d" % i,
			"position": Vector2(936.0, 220.0 + float(i) * 34.0),
			"size": Vector2(270.0, 30.0),
		})
	return {
		"role_buttons": role_buttons,
		"load_cards": load_cards,
	}


static func editor_info_surface_build_specs() -> Dictionary:
	return {
		"unit": {
			"name": "UnitLabel",
			"position": Vector2(936.0, 198.0),
			"size": Vector2(270.0, 48.0),
			"visible_position": Vector2(936.0, 186.0),
			"visible_size": Vector2(270.0, 52.0),
		},
		"summary": {
			"name": "Summary",
			"position": Vector2(936.0, 454.0),
			"size": Vector2(270.0, 112.0),
			"visible_position": Vector2(936.0, 586.0),
			"visible_size": Vector2(270.0, 88.0),
		},
		"stats": {
			"name": "Stats",
			"position": Vector2(936.0, 484.0),
			"size": Vector2(270.0, 56.0),
		},
		"detail": {
			"name": "Detail",
			"position": Vector2(936.0, 548.0),
			"size": Vector2(270.0, 72.0),
		},
		"battle_preview": {
			"name": "BattleArtPreview",
			"position": Vector2(936.0, 278.0),
			"size": Vector2(270.0, 118.0),
		},
		"component_art": {
			"position": Vector2(936.0, 406.0),
			"size": Vector2(270.0, 68.0),
		},
		"structure_reference_view": {
			"name": "StructureReferencePreview",
			"position": Vector2(936.0, 146.0),
			"size": Vector2(270.0, 112.0),
		},
		"structure_reference_label": {
			"name": "StructureReferenceLabel",
			"position": Vector2(936.0, 260.0),
			"size": Vector2(270.0, 18.0),
		},
	}


static func editor_roster_overview_build_specs(slot_count: int) -> Dictionary:
	var slots := []
	for i in range(maxi(0, slot_count)):
		var slot_position := Vector2(350.0 + float(i) * 86.0, 44.0)
		slots.append({
			"index": i,
			"name": "EditorRosterSlot%d" % i,
			"position": slot_position,
			"size": Vector2(82.0, 26.0),
			"thumb_position": slot_position + Vector2(3.0, 3.0),
			"thumb_size": Vector2(20.0, 20.0),
		})
	var prev_spec := _button_spec("roster_prev", "<", Vector2(846.0, 44.0), Vector2(22.0, 24.0))
	prev_spec["name"] = "EditorRosterPrev"
	var next_spec := _button_spec("roster_next", ">", Vector2(870.0, 44.0), Vector2(22.0, 24.0))
	next_spec["name"] = "EditorRosterNext"
	return {
		"title": {
			"name": "RosterOverviewTitle",
			"text": "队伍总览",
			"position": Vector2(236.0, 46.0),
			"size": Vector2(112.0, 22.0),
		},
		"page": {
			"name": "RosterOverviewPage",
			"text": "",
			"position": Vector2(792.0, 46.0),
			"size": Vector2(52.0, 22.0),
		},
		"prev": prev_spec,
		"next": next_spec,
		"slots": slots,
	}


static func editor_color_controls_build_specs(button_count: int) -> Dictionary:
	var buttons := []
	for i in range(maxi(0, button_count)):
		buttons.append({
			"index": i,
			"name": "EditorColorButton%d" % i,
			"position": Vector2(944.0 + float(i % 2) * 128.0, 190.0 + float(floori(float(i) / 2.0)) * 58.0),
			"size": Vector2(118.0, 46.0),
		})
	return {
		"panel": {
			"name": "EditorColorPalettePanel",
			"position": Vector2(932.0, 146.0),
			"size": Vector2(278.0, 274.0),
		},
		"label": {
			"name": "EditorColorLabel",
			"text": "队伍颜色",
			"position": Vector2(944.0, 158.0),
			"size": Vector2(254.0, 24.0),
		},
		"buttons": buttons,
		"primary_picker": {
			"name": "EditorPrimaryColorPicker",
			"text": "主色",
			"position": Vector2(944.0, 370.0),
			"size": Vector2(118.0, 34.0),
		},
		"accent_picker": {
			"name": "EditorAccentColorPicker",
			"text": "辅色",
			"position": Vector2(1072.0, 370.0),
			"size": Vector2(118.0, 34.0),
		},
	}


static func editor_catalog_card_build_specs(card_count: int) -> Array:
	var cards := []
	for i in range(maxi(0, card_count)):
		cards.append({
			"index": i,
			"name": "CatalogCard%d" % i,
			"position": Vector2(936.0 + float(i % 2) * 136.0, 354.0 + float(floori(float(i) / 2.0)) * 74.0),
			"size": Vector2(130.0, 72.0),
		})
	return cards


static func editor_template_drawer_build_specs(archetype_order: Array, barrier_template_order: Array) -> Dictionary:
	var archetype_buttons := []
	for i in range(archetype_order.size()):
		var archetype_key := String(archetype_order[i])
		archetype_buttons.append({
			"index": i,
			"key": archetype_key,
			"name": "TemplateArchetype%s" % archetype_key,
			"position": Vector2(940.0 + float(i % 2) * 134.0, 188.0 + float(floori(float(i) / 2.0)) * 28.0),
			"size": Vector2(126.0, 24.0),
		})
	var barrier_template_buttons := []
	for i in range(barrier_template_order.size()):
		var barrier_key := String(barrier_template_order[i])
		barrier_template_buttons.append({
			"index": i,
			"key": barrier_key,
			"name": "BarrierTemplate%s" % barrier_key,
			"position": Vector2(940.0 + float(i % 2) * 134.0, 188.0 + float(floori(float(i) / 2.0)) * 28.0),
			"size": Vector2(126.0, 24.0),
		})
	return {
		"panel": {
			"name": "TemplateSubmenuPanel",
			"position": Vector2(932.0, 180.0),
			"size": Vector2(278.0, 336.0),
		},
		"title": {
			"name": "TemplateTitle",
			"text": "预组单位库",
			"position": Vector2(936.0, 374.0),
			"size": Vector2(270.0, 20.0),
		},
		"archetype_buttons": archetype_buttons,
		"barrier_template_buttons": barrier_template_buttons,
	}


static func editor_shop_surface_build_specs(slot_order: Array) -> Dictionary:
	var buttons := []
	for i in range(slot_order.size()):
		var slot_key := String(slot_order[i])
		buttons.append({
			"index": i,
			"key": slot_key,
			"name": "ShopButton%s" % slot_key,
			"position": Vector2(936.0, 252.0 + float(i) * 84.0),
			"size": Vector2(270.0, 76.0),
		})
	return {
		"title": {
			"name": "ShopTitle",
			"text": "零件面板",
			"position": Vector2(936.0, 146.0),
			"size": Vector2(270.0, 20.0),
		},
		"hint": {
			"name": "ShopHint",
			"text": "流程：选择类型 -> 拖卡片进画布 -> 磁吸贴合",
			"position": Vector2(936.0, 170.0),
			"size": Vector2(270.0, 42.0),
		},
		"pending": {
			"name": "ShopPending",
			"text": "",
			"position": Vector2(936.0, 214.0),
			"size": Vector2(270.0, 34.0),
		},
		"backdrop": {
			"name": "ShopCardArtBackdrop",
			"position": Vector2(936.0, 252.0),
			"size": Vector2(270.0, 338.0),
		},
		"buttons": buttons,
	}


static func editor_sort_menu_build_specs(sort_key_order: Array) -> Dictionary:
	var options := []
	for i in range(sort_key_order.size()):
		var sort_key := String(sort_key_order[i])
		options.append({
			"index": i,
			"key": sort_key,
			"name": "SortOption%d" % i,
			"position": Vector2(940.0 + float(i % 3) * 88.0, 326.0 + float(floori(float(i) / 3.0)) * 28.0),
			"size": Vector2(82.0, 24.0),
			"z_index": 61,
		})
	return {
		"panel": {
			"name": "EditorSortSubmenu",
			"position": Vector2(932.0, 318.0),
			"size": Vector2(278.0, 112.0),
			"z_index": 60,
		},
		"options": options,
		"catalog_title": {
			"name": "CatalogTitle",
			"text": "零件卡片",
			"position": Vector2(936.0, 330.0),
			"size": Vector2(168.0, 20.0),
		},
		"catalog_page": {
			"name": "CatalogPage",
			"text": "",
			"position": Vector2(1110.0, 330.0),
			"size": Vector2(96.0, 20.0),
		},
	}


static func editor_body_part_button_build_specs(body_part_order: Array) -> Array:
	var body_positions := {
		"left_claw": Vector2(128.0, 178.0),
		"right_claw": Vector2(704.0, 178.0),
		"front_left_leg": Vector2(172.0, 328.0),
		"front_right_leg": Vector2(660.0, 328.0),
		"rear_left_leg": Vector2(276.0, 468.0),
		"rear_right_leg": Vector2(556.0, 468.0),
	}
	var buttons := []
	for raw_part_key in body_part_order:
		var part_key := String(raw_part_key)
		buttons.append({
			"key": part_key,
			"name": "EditorBodyPart%s" % part_key,
			"position": body_positions.get(part_key, Vector2.ZERO),
			"size": Vector2(132.0, 44.0),
		})
	return buttons


static func editor_module_binding_button_build_specs(attack_group_count: int, key_z_index: int, side_z_index: int) -> Dictionary:
	var key_buttons := []
	for key_index in range(1, maxi(0, attack_group_count) + 1):
		key_buttons.append({
			"index": key_index,
			"key": "bind_key_%d" % key_index,
			"name": "ModuleBindKey%d" % key_index,
			"text": "键%d" % key_index,
			"position": Vector2(286.0 + float(key_index - 1) * 56.0, 618.0),
			"size": Vector2(50.0, 24.0),
			"z_index": key_z_index,
		})
	var side_buttons := []
	for side_key in ["left", "right"]:
		side_buttons.append({
			"key": "bind_side_%s" % side_key,
			"side": side_key,
			"name": "ModuleBindSide%s" % side_key.capitalize(),
			"position": Vector2(936.0, 618.0),
			"size": Vector2(132.0, 28.0),
			"z_index": side_z_index,
		})
	return {
		"key_buttons": key_buttons,
		"side_buttons": side_buttons,
		"buttons": key_buttons + side_buttons,
	}


static func editor_sort_action_button_build_specs() -> Array:
	var buttons := []
	for raw_spec in Array(editor_action_build_specs().get("sort_actions", [])):
		var spec: Dictionary = Dictionary(raw_spec).duplicate(true)
		match String(spec.get("key", "")):
			"sort_prev":
				spec["intent"] = "cycle"
				spec["delta"] = -1
			"sort_key":
				spec["intent"] = "toggle_menu"
			"sort_dir":
				spec["intent"] = "toggle_direction"
		buttons.append(spec)
	return buttons


static func editor_save_unit_dialog_build_specs(role_order: Array) -> Dictionary:
	var role_buttons := []
	for i in range(role_order.size()):
		var role_key := String(role_order[i])
		role_buttons.append({
			"index": i,
			"key": role_key,
			"name": "SaveUnitRole%s" % role_key,
			"position": Vector2(18.0 + float(i) * 148.0, 114.0),
			"size": Vector2(136.0, 28.0),
		})
	var action_buttons := [
		{"name": "save_name_stay", "text": "保存", "action": "save", "position": Vector2(18.0, 170.0), "size": Vector2(136.0, 30.0)},
		{"name": "save_name_save_as", "text": "另存为", "action": "save_as", "position": Vector2(168.0, 170.0), "size": Vector2(136.0, 30.0)},
		{"name": "save_name_cancel", "text": "取消", "action": "cancel", "position": Vector2(318.0, 170.0), "size": Vector2(136.0, 30.0)},
	]
	return {
		"panel": {"name": "SaveUnitNamePanel", "position": Vector2(390.0, 188.0), "size": Vector2(474.0, 236.0), "z_index": 295},
		"title": {"name": "SaveUnitNameLabel", "text": "保存为单位", "position": Vector2(18.0, 14.0), "size": Vector2(438.0, 24.0)},
		"name_edit": {"name": "SaveUnitNameEdit", "position": Vector2(18.0, 48.0), "size": Vector2(438.0, 30.0)},
		"role_label": {"name": "SaveUnitRoleLabel", "text": "单位类型", "position": Vector2(18.0, 92.0), "size": Vector2(438.0, 18.0)},
		"role_buttons": role_buttons,
		"action_buttons": action_buttons,
	}


static func editor_orientation_popup_build_specs() -> Dictionary:
	var buttons := [
		{"key": "left", "name": "ScytheSideMountLeftButton", "text": "左侧挂刃", "position": Vector2(10.0, 42.0), "size": Vector2(86.0, 28.0)},
		{"key": "right", "name": "ScytheSideMountRightButton", "text": "右侧挂刃", "position": Vector2(102.0, 42.0), "size": Vector2(86.0, 28.0)},
		{"key": "cancel", "name": "ScytheSideMountLaterButton", "text": "稍后", "position": Vector2(194.0, 42.0), "size": Vector2(52.0, 28.0)},
	]
	return {
		"panel": {"name": "ScytheSideMountChoicePopup", "size": Vector2(256.0, 86.0), "z_index": 272},
		"label": {"name": "ScytheSideMountChoiceLabel", "text": "", "position": Vector2(10.0, 6.0), "size": Vector2(236.0, 28.0)},
		"buttons": buttons,
	}


static func editor_dashboard_controls_build_specs() -> Dictionary:
	return {
		"power_dock": {"name": "UnitEditorPowerAllocationDock", "position": Vector2(190.0, 24.0), "size": Vector2(726.0, 132.0), "z_index": 254},
		"board_title": {"name": "BoardTitle", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"board_hint": {"name": "BoardHint", "text": "", "position": Vector2(296.0, 72.0), "size": Vector2(620.0, 18.0)},
		"legacy_power_button": {"name": "DashboardPowerAllocationButton", "text": "动力预算", "position": Vector2(52.0, 108.0), "size": Vector2(82.0, 24.0)},
		"torso_detail_button": {"name": "DashboardTorsoDetailButton", "text": "核心详情", "position": Vector2(228.0, 108.0), "size": Vector2(86.0, 24.0)},
		"legacy_power_summary": {"name": "DashboardPowerAllocationSummary", "text": "", "position": Vector2(140.0, 109.0), "size": Vector2(82.0, 22.0)},
	}


static func editor_canvas_zoom_chrome_build_specs() -> Dictionary:
	return {
		"canvas_tools_title": {"name": "CanvasToolsTitle", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"canvas_note": {"name": "CanvasTopologyText", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"board_zoom_title": {"name": "BoardZoomTitle", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"board_zoom_value": {"name": "BoardZoomValue", "text": "100%", "position": Vector2(72.0, 656.0), "size": Vector2(54.0, 18.0)},
	}


static func editor_shell_chrome_build_specs() -> Dictionary:
	return {
		"title": {"name": "EditorTitle", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"help": {"name": "EditorHelp", "text": "", "position": Vector2.ZERO, "size": Vector2.ZERO},
		"back_button": {"name": "EditorBackButton", "text": "选项", "token": "editor_options_button"},
	}


static func editor_auxiliary_chrome_build_specs() -> Dictionary:
	return {
		"assembly_guide": {"name": "AssemblyGuideLabel", "text": "", "position": Vector2(936.0, 118.0), "size": Vector2(160.0, 22.0)},
		"legality_status": {"name": "LegalityStatus", "text": "", "position": Vector2(18.0, 616.0), "size": Vector2(244.0, 32.0)},
		"assembly_tutorial_panel": {"name": "AssemblyTutorialPanel", "position": Vector2(194.0, 102.0), "size": Vector2(706.0, 66.0), "z_index": 340},
		"assembly_tutorial_label": {"name": "AssemblyTutorialLabel", "text": "", "position": Vector2(320.0, 108.0), "size": Vector2(568.0, 60.0), "z_index": 341},
		"perf_overlay": {"name": "TeamEditPerfOverlay", "text": "", "position": Vector2(42.0, 86.0), "size": Vector2(330.0, 180.0), "z_index": 330},
		"save_feedback": {"name": "SaveUnitFeedback", "text": "", "position": Vector2(270.0, 654.0), "size": Vector2(622.0, 26.0), "z_index": 300},
	}


static func editor_overlay_view_build_specs() -> Dictionary:
	return {
		"stats_rail": {"name": "EditorStatsRail", "position": Vector2(18.0, 104.0), "size": Vector2(164.0, 508.0)},
		"hover_popup": {"name": "EditorPartHoverPopup", "position": Vector2(410.0, 124.0), "size": Vector2(466.0, 500.0), "z_index": 260},
		"unit_hover": {"name": "EditorUnitHoverPreview", "position": Vector2(410.0, 118.0), "size": Vector2(466.0, 500.0), "z_index": 255},
		"torso_detail": {"name": "EditorTorsoDetail", "position": Vector2(18.0, 338.0), "size": Vector2(888.0, 346.0), "z_index": 285},
		"engine_allocation": {"name": "EngineMomentumAllocationPanel", "mirror_board_rect": true, "z_index": 290},
		"drag_ghost": {"name": "EditorPartDragGhost", "z_index": 250},
	}


static func editor_panel_role_chrome_presentation(mode: String, active_role_key: String, parts_visible: bool, panel_keys: Array, role_keys: Array, role_order: Array, role_short_labels: Dictionary, zh: bool) -> Dictionary:
	var panel_texts := {"load": "单位库", "parts": "零件库"} if zh else {"load": "UNITS", "parts": "PARTS"}
	var panel_buttons := {}
	for raw_panel_key in panel_keys:
		var panel_key := String(raw_panel_key)
		panel_buttons[panel_key] = {
			"text": String(panel_texts.get(panel_key, panel_key.to_upper())),
			"modulate": Color(0.35, 0.95, 1.0, 1.0) if panel_key == String(mode) else Color(0.86, 0.9, 0.94, 1.0),
		}
	var role_build_specs_by_key := {}
	var role_load_build_specs := editor_role_load_build_specs(role_order, 0)
	for raw_role_build_spec in Array(role_load_build_specs.get("role_buttons", [])):
		var role_build_spec := Dictionary(raw_role_build_spec)
		role_build_specs_by_key[String(role_build_spec.get("key", ""))] = role_build_spec
	var role_buttons := {}
	for raw_role_key in role_keys:
		var role_key := String(raw_role_key)
		var role_index := role_order.find(role_key)
		var role_build_spec := Dictionary(role_build_specs_by_key.get(role_key, {}))
		var build_position: Vector2 = role_build_spec.get("position", Vector2(936.0 + float(role_index) * 92.0, 156.0))
		var build_size: Vector2 = role_build_spec.get("size", Vector2(86.0, 32.0))
		role_buttons[role_key] = {
			"visible": false,
			"disabled": true,
			"position": Vector2(build_position.x, 118.0 if parts_visible else 212.0),
			"size": Vector2(build_size.x, 24.0 if parts_visible else build_size.y),
			"text": ("身份:%s" if zh else "ROLE:%s") % String(role_short_labels.get(role_key, role_key.to_upper())),
			"modulate": Color(0.35, 0.95, 1.0, 1.0) if role_key == String(active_role_key) else Color(0.84, 0.9, 0.94, 1.0),
		}
	return {
		"panel_buttons": panel_buttons,
		"role_buttons": role_buttons,
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


static func editor_slot_button_presentation() -> Dictionary:
	return {
		"visible": false,
		"disabled": true,
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
	var build_specs := editor_ammo_size_build_specs(tick_labels.size())
	var title_build_spec := Dictionary(build_specs.get("title", {}))
	var slider_build_spec := Dictionary(build_specs.get("slider", {}))
	var value_build_spec := Dictionary(build_specs.get("value", {}))
	var tick_build_specs: Array = Array(build_specs.get("ticks", []))
	var title_plan := {
		"visible": ammo_slider_visible,
		"position": title_build_spec.get("position", Vector2.ZERO),
		"size": title_build_spec.get("size", Vector2.ZERO),
		"text": "弹药尺寸" if zh else "AMMO SIZE",
	}
	var slider_plan := {
		"visible": ammo_slider_visible,
		"editable": ammo_slider_visible,
		"position": slider_build_spec.get("position", Vector2.ZERO),
		"size": slider_build_spec.get("size", Vector2.ZERO),
		"value": float(ammo_size_rank),
		"tooltip": "安装弹药时选择弹仓尺寸；弹数、价格、质量和槽位体积同步增加。" if zh else "Choose ammo bay size at install time; ammo count, cost, mass, and slot volume scale together.",
	}
	var value_plan := {
		"visible": ammo_slider_visible,
		"position": value_build_spec.get("position", Vector2.ZERO),
		"size": value_build_spec.get("size", Vector2.ZERO),
		"text": String(value_text),
	}
	var tick_plans := []
	for i in range(tick_labels.size()):
		var rank := i + 1
		var tick_build_spec := Dictionary(tick_build_specs[i])
		tick_plans.append({
			"visible": ammo_slider_visible,
			"position": tick_build_spec.get("position", Vector2.ZERO),
			"size": tick_build_spec.get("size", Vector2.ZERO),
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


static func editor_info_panel_presentation(unit_visible: bool, stats_visible: bool, parts_visible: bool, sort_menu_open: bool, load_visible: bool, structure_reference_view_visible: bool, structure_reference_label_visible: bool, zh: bool) -> Dictionary:
	var catalog_visible := (parts_visible and not sort_menu_open) or load_visible
	var catalog_title_visible := parts_visible and not sort_menu_open
	var build_specs := editor_info_surface_build_specs()
	var unit_build_spec := Dictionary(build_specs.get("unit", {}))
	var summary_build_spec := Dictionary(build_specs.get("summary", {}))
	var stats_build_spec := Dictionary(build_specs.get("stats", {}))
	var detail_build_spec := Dictionary(build_specs.get("detail", {}))
	var component_art_build_spec := Dictionary(build_specs.get("component_art", {}))
	var battle_preview_build_spec := Dictionary(build_specs.get("battle_preview", {}))
	var structure_view_build_spec := Dictionary(build_specs.get("structure_reference_view", {}))
	var structure_label_build_spec := Dictionary(build_specs.get("structure_reference_label", {}))
	return {
		"unit": {
			"visible": unit_visible,
			"position": unit_build_spec.get("visible_position", Vector2.ZERO),
			"size": unit_build_spec.get("visible_size", Vector2.ZERO),
			"text": "单位库" if zh else "UNITS",
		},
		"summary": {
			"visible": unit_visible,
			"position": summary_build_spec.get("visible_position", Vector2.ZERO),
			"size": summary_build_spec.get("visible_size", Vector2.ZERO),
		},
		"stats": {
			"visible": stats_visible,
			"position": stats_build_spec.get("position", Vector2.ZERO),
			"size": stats_build_spec.get("size", Vector2.ZERO),
		},
		"detail": {
			"visible": stats_visible,
			"position": detail_build_spec.get("position", Vector2.ZERO),
			"size": detail_build_spec.get("size", Vector2.ZERO),
		},
		"component_art": {
			"visible": stats_visible,
			"position": component_art_build_spec.get("position", Vector2.ZERO),
			"size": component_art_build_spec.get("size", Vector2.ZERO),
		},
		"battle_preview": {
			"visible": stats_visible,
			"position": battle_preview_build_spec.get("position", Vector2.ZERO),
			"size": battle_preview_build_spec.get("size", Vector2.ZERO),
		},
		"structure_reference_view": {
			"visible": structure_reference_view_visible and stats_visible,
			"position": structure_view_build_spec.get("position", Vector2.ZERO),
			"size": structure_view_build_spec.get("size", Vector2.ZERO),
		},
		"structure_reference_label": {
			"visible": structure_reference_label_visible and stats_visible,
			"position": structure_label_build_spec.get("position", Vector2.ZERO),
			"size": structure_label_build_spec.get("size", Vector2.ZERO),
		},
		"catalog_page": {"visible": catalog_visible},
		"catalog_title": {"visible": catalog_title_visible},
	}


static func editor_shop_feedback_presentation(shop_visible: bool, pending_kind: String, pending_detail: String, zh: bool) -> Dictionary:
	var hint_text := "流程：1 选构件类型  2 拖卡片进画布  3 磁吸贴合；引擎/散热/行动模块点击安装。" if zh else "Flow: 1 choose a part type  2 drag a card onto canvas  3 snap it. Engine/cooling/action modules install on click."
	var pending_text := ""
	var pending_modulate := Color(0.72, 0.88, 1.0, 0.78)
	match String(pending_kind):
		"payload":
			pending_text = String(pending_detail)
			pending_modulate = Color(1.0, 0.78, 0.30, 1.0)
		"canvas":
			pending_text = ("待放置：%s" if zh else "PENDING PLACEMENT: %s") % String(pending_detail)
			pending_modulate = Color(1.0, 0.86, 0.24, 1.0)
		_:
			pending_text = "当前没有待放置构件；拖拽或点选肌肉构件后这里会亮起。" if zh else "No pending physical part; drag or choose a muscle component and this line lights up."
	return {
		"hint": {
			"visible": shop_visible,
			"text": hint_text,
		},
		"pending": {
			"visible": shop_visible,
			"text": pending_text,
			"modulate": pending_modulate,
		},
	}


static func editor_color_controls_presentation(color_visible: bool, player_id: int, team_color_name: String, selected_color_index: int, color_presets: Array, button_count: int, zh: bool) -> Dictionary:
	var button_plans := []
	for i in range(button_count):
		var button_plan := {
			"visible": color_visible,
			"disabled": not color_visible,
		}
		if i < color_presets.size() and color_presets[i] is Dictionary:
			var preset: Dictionary = color_presets[i]
			var selected := i == selected_color_index
			var preset_name := String(preset.get("name", preset.get("name_en", "颜色"))) if zh else String(preset.get("name_en", preset.get("name", "COLOR")))
			button_plan["text"] = "%s%s\n主色/辅色" % ["已选 " if selected else "", preset_name] if zh else "%s%s\nPRIMARY/ACCENT" % ["* " if selected else "", preset_name]
			var primary: Color = preset.get("primary", Color.WHITE)
			var accent: Color = preset.get("accent", Color.WHITE)
			button_plan["modulate"] = primary.lerp(accent, 0.34 if selected else 0.12)
		button_plans.append(button_plan)
	return {
		"panel": {"visible": color_visible},
		"label": {
			"visible": color_visible,
			"text": "P%d 队伍颜色：%s" % [player_id, team_color_name] if zh else "P%d TEAM COLOR: %s" % [player_id, team_color_name],
		},
		"buttons": button_plans,
		"primary_picker": {
			"visible": color_visible,
			"disabled": not color_visible,
			"text": "主色" if zh else "PRIMARY",
		},
		"accent_picker": {
			"visible": color_visible,
			"disabled": not color_visible,
			"text": "辅色" if zh else "ACCENT",
		},
		"sync_pickers": color_visible,
	}


static func editor_section_chrome_presentation(parts_visible: bool, template_visible: bool, template_menu_open: bool, zh: bool) -> Dictionary:
	return {
		"labels": {
			"catalog": {
				"visible": parts_visible,
				"text": "零件卡片" if zh else "PART CARDS",
			},
			"shop": {
				"visible": false,
				"text": "零件库：悬停显示完整卡片" if zh else "PARTS: HOVER FOR FULL CARD",
			},
			"template": {
				"visible": template_visible and template_menu_open,
			},
			"_default": {
				"visible": true,
			},
		},
		"template_toggle": {
			"visible": false,
			"text": "模板抽屉" if zh else "TEMPLATE DRAWER",
		},
		"template_drawer_visible": false,
	}


static func editor_catalog_shop_surface_presentation(parts_visible: bool, shop_visible: bool, load_visible: bool, body_board_enabled: bool, catalog_button_visibilities: Array, shop_button_keys: Array) -> Dictionary:
	var catalog_button_plans := []
	for raw_visible in catalog_button_visibilities:
		catalog_button_plans.append({
			"visible": bool(raw_visible) and parts_visible,
		})
	var shop_buttons := {}
	var shop_button_visible := shop_visible and body_board_enabled
	for raw_key in shop_button_keys:
		shop_buttons[String(raw_key)] = {
			"visible": shop_button_visible,
			"disabled": not shop_button_visible,
		}
	return {
		"catalog_buttons": catalog_button_plans,
		"shop_buttons": shop_buttons,
		"shop_backdrop": {
			"visible": shop_visible,
		},
		"clear_catalog_hover": not (parts_visible or shop_visible),
		"clear_unit_hover": not load_visible,
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
