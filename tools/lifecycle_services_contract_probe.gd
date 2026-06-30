extends SceneTree

const LoadingLifecycleService := preload("res://scripts/services/loading_lifecycle_service.gd")
const UILifecycleService := preload("res://scripts/services/ui_lifecycle_service.gd")
const LoadingTask := preload("res://scripts/services/loading_task.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_vector(plan: Dictionary, key: String, expected: Vector2, label: String) -> void:
	var value: Vector2 = plan.get(key, Vector2(-999.0, -999.0))
	if not value.is_equal_approx(expected):
		_fail("%s expected %s=%s, got %s." % [label, key, expected, value])


func _assert_color(plan: Dictionary, key: String, expected: Color, label: String) -> void:
	var value: Color = plan.get(key, Color(-1.0, -1.0, -1.0, -1.0))
	if not is_equal_approx(value.r, expected.r) or not is_equal_approx(value.g, expected.g) or not is_equal_approx(value.b, expected.b) or not is_equal_approx(value.a, expected.a):
		_fail("%s expected %s=%s, got %s." % [label, key, expected, value])


func _spec_with_key(specs: Array, key: String) -> Dictionary:
	for raw_spec in specs:
		if raw_spec is Dictionary and String(Dictionary(raw_spec).get("key", "")) == key:
			return Dictionary(raw_spec)
	return {}


func _init() -> void:
	var cache := {"a": 1, "b": 2, "c": 3}
	var removed := UILifecycleService.trim_dictionary_cache(cache, 1)
	if removed != 2 or cache.size() != 1:
		_fail("UILifecycleService did not trim dictionary cache.")
		return
	var root_node := Control.new()
	var child_node := Control.new()
	root_node.add_child(child_node)
	if UILifecycleService.node_descendant_count(root_node) != 1 or UILifecycleService.visible_control_count(root_node) != 2:
		_fail("UILifecycleService node/control counting contract failed.")
		return
	root_node.queue_free()
	var visibility_plan := UILifecycleService.editor_panel_visibility_plan("parts", "team", true, false, true, "terminal_weapon", "ammo", 2)
	if String(visibility_plan.get("load_mode", "")) != "unit":
		_fail("UILifecycleService should normalize legacy team load mode.")
		return
	if not bool(visibility_plan.get("parts_visible", false)) or bool(visibility_plan.get("load_visible", false)):
		_fail("UILifecycleService panel visibility mode contract failed.")
		return
	if not bool(visibility_plan.get("custom_board_enabled", false)) or not bool(visibility_plan.get("ammo_slider_visible", false)):
		_fail("UILifecycleService editor board/slider visibility contract failed.")
		return
	if not bool(visibility_plan.get("unit_page_actions_enabled", false)):
		_fail("UILifecycleService should enable unit paging for multi-unit rosters.")
		return
	if not Array(visibility_plan.get("canvas_action_keys", [])).has("restore_suggested_connection"):
		_fail("UILifecycleService should preserve canvas action key ordering payload.")
		return
	var barrier_visibility_plan := UILifecycleService.editor_panel_visibility_plan("load", "unit", true, true, true, "all", "all", 1)
	if bool(barrier_visibility_plan.get("custom_board_enabled", true)):
		_fail("UILifecycleService should disable custom topology board on screen barriers.")
		return
	if not bool(barrier_visibility_plan.get("template_visible", false)) or bool(barrier_visibility_plan.get("unit_page_actions_enabled", true)):
		_fail("UILifecycleService load panel visibility contract failed.")
		return
	var hidden_barrier_canvas_action := UILifecycleService.editor_action_state("board_tool_layout", visibility_plan, true, false, false, false, false, false, false)
	var visible_barrier_grid_action := UILifecycleService.editor_action_state("toggle_barrier_grid", visibility_plan, true, false, false, false, false, false, false)
	if bool(hidden_barrier_canvas_action.get("visible", true)) or not bool(hidden_barrier_canvas_action.get("disabled", false)):
		_fail("UILifecycleService should hide regular canvas actions on screen barriers.")
		return
	if not bool(visible_barrier_grid_action.get("visible", false)) or bool(visible_barrier_grid_action.get("disabled", true)):
		_fail("UILifecycleService should expose the barrier grid action on screen barriers.")
		return
	var disabled_copy_action := UILifecycleService.editor_action_state("copy_selection", visibility_plan, false, false, false, false, false, false, false)
	var enabled_copy_action := UILifecycleService.editor_action_state("copy_selection", visibility_plan, false, false, false, false, false, true, false)
	if not bool(disabled_copy_action.get("disabled", false)) or bool(enabled_copy_action.get("disabled", true)):
		_fail("UILifecycleService clipboard action state contract failed.")
		return
	var orientation_choice_action := UILifecycleService.editor_action_state("set_handedness_left", visibility_plan, false, true, true, false, false, false, false)
	var hidden_flip_action := UILifecycleService.editor_action_state("flip_handedness", visibility_plan, false, true, true, false, false, false, false)
	var selected_flip_action := UILifecycleService.editor_action_state("flip_handedness", visibility_plan, false, false, true, false, false, false, false)
	if not bool(orientation_choice_action.get("visible", false)) or bool(hidden_flip_action.get("visible", true)) or not bool(selected_flip_action.get("visible", false)):
		_fail("UILifecycleService orientation action state contract failed.")
		return
	var open_sort_action := UILifecycleService.editor_action_state("sort_dir", visibility_plan, false, false, false, true, false, false, false)
	var load_page_action := UILifecycleService.editor_action_state("prev_catalog", barrier_visibility_plan, true, false, false, false, false, false, false)
	if not bool(open_sort_action.get("visible", false)) or not bool(load_page_action.get("visible", false)):
		_fail("UILifecycleService sort/catalog action state contract failed.")
		return
	var board_primary_plan: Dictionary = UILifecycleService.editor_action_presentation(
		"save_canvas",
		UILifecycleService.editor_action_state("save_canvas", visibility_plan, false, false, false, false, false, false, false),
		0,
		{"zh": false, "load_mode": "unit", "board_tool": "layout", "connection_state_color": Color(0.2, 0.4, 0.6, 1.0), "barrier_grid_enabled": false, "unit_page_actions_enabled": true}
	)
	if String(board_primary_plan.get("text", "")) != "SAVE UNIT" or not bool(board_primary_plan.get("visible", false)) or bool(board_primary_plan.get("disabled", true)):
		_fail("UILifecycleService board-primary action presentation contract failed.")
		return
	_assert_vector(board_primary_plan, "position", Vector2(352.0, 596.0), "board-primary presentation")
	_assert_vector(board_primary_plan, "size", Vector2(146.0, 28.0), "board-primary presentation")
	_assert_color(board_primary_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "board-primary presentation")
	var clipboard_plan: Dictionary = UILifecycleService.editor_action_presentation(
		"copy_selection",
		enabled_copy_action,
		0,
		{"zh": true, "load_mode": "unit", "board_tool": "layout", "connection_state_color": Color(0.2, 0.4, 0.6, 1.0), "barrier_grid_enabled": false, "unit_page_actions_enabled": true}
	)
	if String(clipboard_plan.get("text", "")) != "复制" or String(clipboard_plan.get("tooltip", "")).find("复制/剪切/粘贴") < 0:
		_fail("UILifecycleService clipboard action presentation contract failed.")
		return
	_assert_vector(clipboard_plan, "position", Vector2(628.0, 688.0), "clipboard presentation")
	_assert_vector(clipboard_plan, "size", Vector2(72.0, 24.0), "clipboard presentation")
	_assert_color(clipboard_plan, "modulate", Color(0.42, 1.0, 0.82, 1.0), "clipboard presentation")
	var orientation_plan: Dictionary = UILifecycleService.editor_action_presentation(
		"set_handedness_right",
		UILifecycleService.editor_action_state("set_handedness_right", visibility_plan, false, true, false, false, false, false, false),
		0,
		{"zh": false, "load_mode": "unit", "board_tool": "layout", "connection_state_color": Color(0.2, 0.4, 0.6, 1.0), "barrier_grid_enabled": false, "unit_page_actions_enabled": true}
	)
	if String(orientation_plan.get("text", "")) != "RIGHT":
		_fail("UILifecycleService orientation action presentation contract failed.")
		return
	_assert_vector(orientation_plan, "position", Vector2(846.0, 688.0), "orientation presentation")
	_assert_vector(orientation_plan, "size", Vector2(66.0, 24.0), "orientation presentation")
	var unit_plan: Dictionary = UILifecycleService.editor_action_presentation(
		"load_unit",
		UILifecycleService.editor_action_state("load_unit", barrier_visibility_plan, false, false, false, false, false, false, false),
		1,
		{"zh": false, "load_mode": "unit", "board_tool": "layout", "connection_state_color": Color(0.2, 0.4, 0.6, 1.0), "barrier_grid_enabled": false, "unit_page_actions_enabled": true}
	)
	if String(unit_plan.get("text", "")) != "UNITS" or not bool(unit_plan.get("advance_unit_action_index", false)):
		_fail("UILifecycleService unit action presentation contract failed.")
		return
	_assert_vector(unit_plan, "position", Vector2(1072.0, 126.0), "unit action presentation")
	_assert_vector(unit_plan, "size", Vector2(130.0, 26.0), "unit action presentation")
	var guide_plan: Dictionary = UILifecycleService.editor_action_presentation(
		"assembly_guide_prev",
		UILifecycleService.editor_action_state("assembly_guide_prev", visibility_plan, false, false, false, false, false, false, false),
		0,
		{"zh": false}
	)
	if bool(guide_plan.get("managed", true)):
		_fail("UILifecycleService should leave assembly-guide action presentation unmanaged.")
		return
	var build_specs: Dictionary = UILifecycleService.editor_action_build_specs()
	var panel_specs: Array = Array(build_specs.get("panel_buttons", []))
	var guide_specs: Array = Array(build_specs.get("assembly_guide_actions", []))
	var unit_specs: Array = Array(build_specs.get("unit_actions", []))
	var board_primary_specs: Array = Array(build_specs.get("board_primary_actions", []))
	var canvas_specs: Array = Array(build_specs.get("canvas_tools", []))
	var zoom_specs: Array = Array(build_specs.get("board_zoom_actions", []))
	var page_specs: Array = Array(build_specs.get("catalog_page_actions", []))
	var sort_specs: Array = Array(build_specs.get("sort_actions", []))
	var template_spec: Dictionary = Dictionary(build_specs.get("template_toggle", {}))
	if panel_specs.size() != 2 or guide_specs.size() != 3 or unit_specs.size() != 20 or board_primary_specs.size() != 3 or canvas_specs.size() != 18 or zoom_specs.size() != 3 or page_specs.size() != 2 or sort_specs.size() != 3:
		_fail("UILifecycleService editor action build spec counts changed unexpectedly.")
		return
	var load_panel_spec := _spec_with_key(panel_specs, "load")
	if String(load_panel_spec.get("text", "")) != "单位库":
		_fail("UILifecycleService panel build spec contract failed.")
		return
	_assert_vector(load_panel_spec, "position", Vector2(936.0, 86.0), "panel build spec")
	_assert_vector(load_panel_spec, "size", Vector2(132.0, 30.0), "panel build spec")
	var copy_spec := _spec_with_key(canvas_specs, "copy_selection")
	if String(copy_spec.get("text", "")) != "复制":
		_fail("UILifecycleService canvas build spec contract failed.")
		return
	_assert_vector(copy_spec, "position", Vector2(628.0, 688.0), "canvas build spec")
	var reset_zoom_spec := _spec_with_key(zoom_specs, "board_zoom_reset")
	if String(reset_zoom_spec.get("text", "")) != "重置":
		_fail("UILifecycleService zoom build spec contract failed.")
		return
	_assert_vector(reset_zoom_spec, "size", Vector2(70.0, 24.0), "zoom build spec")
	var next_page_spec := _spec_with_key(page_specs, "next_catalog")
	_assert_vector(next_page_spec, "position", Vector2(1182.0, 654.0), "catalog page build spec")
	var sort_key_spec := _spec_with_key(sort_specs, "sort_key")
	if String(sort_key_spec.get("text", "")) != "排序":
		_fail("UILifecycleService sort build spec contract failed.")
		return
	_assert_vector(sort_key_spec, "position", Vector2(936.0, 294.0), "sort build spec")
	_assert_vector(sort_key_spec, "size", Vector2(160.0, 22.0), "sort build spec")
	if String(template_spec.get("key", "")) != "toggle_templates" or String(template_spec.get("text", "")) != "导入模板":
		_fail("UILifecycleService template toggle build spec contract failed.")
		return
	_assert_vector(template_spec, "position", Vector2(936.0, 146.0), "template toggle build spec")
	_assert_vector(template_spec, "size", Vector2(270.0, 26.0), "template toggle build spec")
	Dictionary(Array(build_specs.get("canvas_tools", []))[0])["key"] = "mutated"
	var fresh_build_specs: Dictionary = UILifecycleService.editor_action_build_specs()
	if String(Dictionary(Array(fresh_build_specs.get("canvas_tools", []))[0]).get("key", "")) != "blank_canvas":
		_fail("UILifecycleService should return fresh editor action build specs.")
		return
	var group_plan: Dictionary = UILifecycleService.editor_part_group_button_presentation("terminal_weapon", ["torso", "limb", "terminal_weapon", "software"], "terminal_weapon", true, "武器")
	if not bool(group_plan.get("visible", false)) or bool(group_plan.get("disabled", true)) or String(group_plan.get("text", "")) != "武器":
		_fail("UILifecycleService part group presentation visibility contract failed.")
		return
	_assert_vector(group_plan, "position", Vector2(1116.0, 146.0), "part group presentation")
	_assert_vector(group_plan, "size", Vector2(84.0, 24.0), "part group presentation")
	_assert_color(group_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "part group presentation")
	var hidden_group_plan: Dictionary = UILifecycleService.editor_part_group_button_presentation("unknown", ["torso"], "torso", false, "UNKNOWN")
	if bool(hidden_group_plan.get("visible", true)) or not bool(hidden_group_plan.get("disabled", false)):
		_fail("UILifecycleService part group hidden presentation contract failed.")
		return
	_assert_vector(hidden_group_plan, "position", Vector2(936.0, 146.0), "hidden part group presentation")
	var filter_options := [{"key": "weapon_all"}, {"key": "terminal_melee"}, {"key": "ammo"}, {"key": "gun"}, {"key": "beam"}, {"key": "spray"}]
	var filter_plan: Dictionary = UILifecycleService.editor_part_filter_button_presentation(5, filter_options, "terminal_weapon", "ammo", true, "喷射")
	if not bool(filter_plan.get("visible", false)) or bool(filter_plan.get("disabled", true)) or String(filter_plan.get("text", "")) != "喷射":
		_fail("UILifecycleService part filter presentation visibility contract failed.")
		return
	_assert_vector(filter_plan, "position", Vector2(936.0, 228.0), "part filter presentation")
	_assert_vector(filter_plan, "size", Vector2(52.0, 22.0), "part filter presentation")
	_assert_color(filter_plan, "modulate", Color(0.84, 0.9, 0.94, 1.0), "part filter presentation")
	var active_filter_plan: Dictionary = UILifecycleService.editor_part_filter_button_presentation(2, filter_options, "terminal_weapon", "ammo", true, "弹药")
	_assert_color(active_filter_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "active part filter presentation")
	var hidden_filter_plan: Dictionary = UILifecycleService.editor_part_filter_button_presentation(9, filter_options, "torso", "all", true, "")
	if bool(hidden_filter_plan.get("visible", true)) or not bool(hidden_filter_plan.get("disabled", false)):
		_fail("UILifecycleService part filter hidden presentation contract failed.")
		return
	_assert_vector(hidden_filter_plan, "size", Vector2(84.0, 22.0), "hidden part filter presentation")
	var ammo_plan: Dictionary = UILifecycleService.editor_ammo_size_control_presentation(true, 3, true, "M x4", ["XS", "S", "M", "L", "XL"])
	var ammo_title: Dictionary = Dictionary(ammo_plan.get("title", {}))
	var ammo_slider: Dictionary = Dictionary(ammo_plan.get("slider", {}))
	var ammo_value: Dictionary = Dictionary(ammo_plan.get("value", {}))
	var ammo_ticks: Array = Array(ammo_plan.get("ticks", []))
	if not bool(ammo_title.get("visible", false)) or String(ammo_title.get("text", "")) != "弹药尺寸":
		_fail("UILifecycleService ammo title presentation contract failed.")
		return
	_assert_vector(ammo_title, "position", Vector2(936.0, 258.0), "ammo title presentation")
	if not bool(ammo_slider.get("editable", false)) or int(roundf(float(ammo_slider.get("value", 0.0)))) != 3:
		_fail("UILifecycleService ammo slider presentation contract failed.")
		return
	_assert_vector(ammo_slider, "position", Vector2(1010.0, 257.0), "ammo slider presentation")
	_assert_vector(ammo_value, "position", Vector2(1190.0, 258.0), "ammo value presentation")
	if ammo_ticks.size() != 5:
		_fail("UILifecycleService ammo tick presentation count failed.")
		return
	var selected_tick: Dictionary = Dictionary(ammo_ticks[2])
	if String(selected_tick.get("text", "")) != "M":
		_fail("UILifecycleService ammo tick text contract failed.")
		return
	_assert_vector(selected_tick, "position", Vector2(1090.0, 278.0), "ammo tick presentation")
	_assert_color(selected_tick, "modulate", Color(1.0, 0.86, 0.28, 1.0), "ammo selected tick presentation")
	var hidden_ammo_plan: Dictionary = UILifecycleService.editor_ammo_size_control_presentation(false, 1, false, "XS x1", ["XS"])
	if bool(Dictionary(hidden_ammo_plan.get("slider", {})).get("visible", true)) or bool(Dictionary(hidden_ammo_plan.get("slider", {})).get("editable", true)):
		_fail("UILifecycleService hidden ammo presentation contract failed.")
		return
	var sort_plan: Dictionary = UILifecycleService.editor_sort_controls_presentation(
		true,
		true,
		["cost", "mass", "range"],
		"hp",
		false,
		["cost", "hp", "mass", "range"],
		{"cost": "Cost", "hp": "HP", "mass": "Mass", "range": "Range"},
		false
	)
	if String(sort_plan.get("sort_key", "")) != "cost":
		_fail("UILifecycleService should normalize unavailable sort keys to the first available key.")
		return
	if String(sort_plan.get("sort_key_text", "")) != "SORT: Cost" or String(sort_plan.get("sort_dir_text", "")) != "DESC ↓":
		_fail("UILifecycleService sort control text contract failed.")
		return
	var sort_panel_plan: Dictionary = Dictionary(sort_plan.get("panel", {}))
	if not bool(sort_panel_plan.get("visible", false)):
		_fail("UILifecycleService sort panel visibility contract failed.")
		return
	_assert_vector(sort_panel_plan, "size", Vector2(278.0, 44.0), "sort panel presentation")
	var sort_options: Array = Array(sort_plan.get("options", []))
	if sort_options.size() != 4:
		_fail("UILifecycleService sort option plan count failed.")
		return
	var cost_option: Dictionary = Dictionary(sort_options[0])
	var hp_option: Dictionary = Dictionary(sort_options[1])
	var mass_option: Dictionary = Dictionary(sort_options[2])
	var range_option: Dictionary = Dictionary(sort_options[3])
	if not bool(cost_option.get("visible", false)) or bool(hp_option.get("visible", true)) or not bool(mass_option.get("visible", false)) or not bool(range_option.get("visible", false)):
		_fail("UILifecycleService sort option visibility contract failed.")
		return
	_assert_vector(cost_option, "position", Vector2(940.0, 326.0), "sort cost option presentation")
	_assert_vector(mass_option, "position", Vector2(1028.0, 326.0), "sort mass option presentation")
	_assert_vector(range_option, "position", Vector2(1116.0, 326.0), "sort range option presentation")
	_assert_color(cost_option, "modulate", Color(1.0, 0.86, 0.28, 1.0), "active sort option presentation")
	_assert_color(mass_option, "modulate", Color(0.84, 0.9, 0.94, 1.0), "inactive sort option presentation")
	var hidden_sort_plan: Dictionary = UILifecycleService.editor_sort_controls_presentation(false, true, ["cost"], "cost", true, ["cost"], {"cost": "花费"}, true)
	if bool(Dictionary(hidden_sort_plan.get("panel", {})).get("visible", true)) or bool(Dictionary(Array(hidden_sort_plan.get("options", []))[0]).get("visible", true)):
		_fail("UILifecycleService hidden sort controls contract failed.")
		return
	var info_plan: Dictionary = UILifecycleService.editor_info_panel_presentation(true, false, true, false, false, true, true, true)
	var info_unit: Dictionary = Dictionary(info_plan.get("unit", {}))
	var info_summary: Dictionary = Dictionary(info_plan.get("summary", {}))
	var info_stats: Dictionary = Dictionary(info_plan.get("stats", {}))
	var info_component: Dictionary = Dictionary(info_plan.get("component_art", {}))
	var info_structure_view: Dictionary = Dictionary(info_plan.get("structure_reference_view", {}))
	var info_catalog_page: Dictionary = Dictionary(info_plan.get("catalog_page", {}))
	var info_catalog_title: Dictionary = Dictionary(info_plan.get("catalog_title", {}))
	if not bool(info_unit.get("visible", false)) or String(info_unit.get("text", "")) != "单位库":
		_fail("UILifecycleService info unit presentation contract failed.")
		return
	_assert_vector(info_unit, "position", Vector2(936.0, 186.0), "info unit presentation")
	_assert_vector(info_unit, "size", Vector2(270.0, 52.0), "info unit presentation")
	if not bool(info_summary.get("visible", false)) or bool(info_stats.get("visible", true)) or bool(info_component.get("visible", true)) or bool(info_structure_view.get("visible", true)):
		_fail("UILifecycleService info visibility split contract failed.")
		return
	_assert_vector(info_summary, "position", Vector2(936.0, 586.0), "info summary presentation")
	_assert_vector(info_summary, "size", Vector2(270.0, 88.0), "info summary presentation")
	if not bool(info_catalog_page.get("visible", false)) or not bool(info_catalog_title.get("visible", false)):
		_fail("UILifecycleService catalog info visibility contract failed.")
		return
	var stats_info_plan: Dictionary = UILifecycleService.editor_info_panel_presentation(false, true, false, true, false, true, false, false)
	if not bool(Dictionary(stats_info_plan.get("stats", {})).get("visible", false)) or not bool(Dictionary(stats_info_plan.get("detail", {})).get("visible", false)) or not bool(Dictionary(stats_info_plan.get("battle_preview", {})).get("visible", false)):
		_fail("UILifecycleService stats info presentation contract failed.")
		return
	if not bool(Dictionary(stats_info_plan.get("structure_reference_view", {})).get("visible", false)) or bool(Dictionary(stats_info_plan.get("structure_reference_label", {})).get("visible", true)):
		_fail("UILifecycleService structure reference preservation contract failed.")
		return
	var load_info_plan: Dictionary = UILifecycleService.editor_info_panel_presentation(true, false, false, true, true, false, false, false)
	if String(Dictionary(load_info_plan.get("unit", {})).get("text", "")) != "UNITS" or not bool(Dictionary(load_info_plan.get("catalog_page", {})).get("visible", false)) or bool(Dictionary(load_info_plan.get("catalog_title", {})).get("visible", true)):
		_fail("UILifecycleService load info presentation contract failed.")
		return
	var payload_shop_plan: Dictionary = UILifecycleService.editor_shop_feedback_presentation(true, "payload", "Install payload in core slot.", false)
	var payload_hint: Dictionary = Dictionary(payload_shop_plan.get("hint", {}))
	var payload_pending: Dictionary = Dictionary(payload_shop_plan.get("pending", {}))
	if not bool(payload_hint.get("visible", false)) or String(payload_hint.get("text", "")).find("Flow:") != 0:
		_fail("UILifecycleService shop hint presentation contract failed.")
		return
	if String(payload_pending.get("text", "")) != "Install payload in core slot.":
		_fail("UILifecycleService payload pending presentation text failed.")
		return
	_assert_color(payload_pending, "modulate", Color(1.0, 0.78, 0.30, 1.0), "payload pending presentation")
	var canvas_shop_plan: Dictionary = UILifecycleService.editor_shop_feedback_presentation(true, "canvas", "爪刃", true)
	var canvas_pending: Dictionary = Dictionary(canvas_shop_plan.get("pending", {}))
	if String(canvas_pending.get("text", "")) != "待放置：爪刃":
		_fail("UILifecycleService canvas pending presentation text failed.")
		return
	_assert_color(canvas_pending, "modulate", Color(1.0, 0.86, 0.24, 1.0), "canvas pending presentation")
	var empty_shop_plan: Dictionary = UILifecycleService.editor_shop_feedback_presentation(false, "none", "", false)
	if bool(Dictionary(empty_shop_plan.get("hint", {})).get("visible", true)) or bool(Dictionary(empty_shop_plan.get("pending", {})).get("visible", true)):
		_fail("UILifecycleService hidden shop feedback visibility failed.")
		return
	if String(Dictionary(empty_shop_plan.get("pending", {})).get("text", "")).find("No pending physical part") != 0:
		_fail("UILifecycleService empty shop pending text failed.")
		return
	var color_presets := [
		{"name": "红", "name_en": "Red", "primary": Color(1.0, 0.0, 0.0, 1.0), "accent": Color(0.0, 0.0, 1.0, 1.0)},
		{"name": "蓝", "name_en": "Blue", "primary": Color(0.0, 1.0, 0.0, 1.0), "accent": Color(0.0, 0.0, 0.0, 1.0)},
	]
	var color_plan: Dictionary = UILifecycleService.editor_color_controls_presentation(true, 2, "Crimson", 1, color_presets, 2, true)
	if not bool(Dictionary(color_plan.get("panel", {})).get("visible", false)):
		_fail("UILifecycleService color panel visibility contract failed.")
		return
	var color_label: Dictionary = Dictionary(color_plan.get("label", {}))
	if not bool(color_label.get("visible", false)) or String(color_label.get("text", "")) != "P2 队伍颜色：Crimson":
		_fail("UILifecycleService color label presentation contract failed.")
		return
	var color_buttons: Array = Array(color_plan.get("buttons", []))
	if color_buttons.size() != 2:
		_fail("UILifecycleService color button count failed.")
		return
	var selected_color_button: Dictionary = Dictionary(color_buttons[1])
	if String(selected_color_button.get("text", "")) != "已选 蓝\n主色/辅色" or bool(selected_color_button.get("disabled", true)):
		_fail("UILifecycleService selected color button presentation failed.")
		return
	_assert_color(selected_color_button, "modulate", Color(0.0, 0.66, 0.0, 1.0), "selected color button presentation")
	var primary_picker: Dictionary = Dictionary(color_plan.get("primary_picker", {}))
	var accent_picker: Dictionary = Dictionary(color_plan.get("accent_picker", {}))
	if String(primary_picker.get("text", "")) != "主色" or String(accent_picker.get("text", "")) != "辅色":
		_fail("UILifecycleService color picker text contract failed.")
		return
	var hidden_color_plan: Dictionary = UILifecycleService.editor_color_controls_presentation(false, 1, "Azure", 0, color_presets, 1, false)
	if bool(Dictionary(hidden_color_plan.get("panel", {})).get("visible", true)) or not bool(Dictionary(Array(hidden_color_plan.get("buttons", []))[0]).get("disabled", false)) or bool(Dictionary(hidden_color_plan.get("primary_picker", {})).get("visible", true)):
		_fail("UILifecycleService hidden color controls contract failed.")
		return

	var task := LoadingTask.create("idle", "Idle", 1.0, Callable(), LoadingTask.PHASE_IDLE, false, true)
	var prepared := LoadingLifecycleService.prepare_task(task, "editor", 4)
	if prepared.target_page != "editor" or prepared.generation_id != 4:
		_fail("LoadingLifecycleService did not stamp target/generation.")
		return
	var queued := LoadingLifecycleService.queue_deferred_idle_tasks([], [prepared, prepared.to_dictionary()], "editor", 4, "editor")
	if Array(queued.get("tasks", [])).size() != 1 or int(queued.get("deduped", 0)) != 1:
		_fail("LoadingLifecycleService did not dedupe deferred idle tasks.")
		return
	var pruned := LoadingLifecycleService.prune_idle_tasks(Array(queued.get("tasks", [])), "menu", 5, "editor")
	if not Array(pruned.get("tasks", [])).is_empty() or int(pruned.get("cancelled", 0)) != 1:
		_fail("LoadingLifecycleService did not cancel stale target tasks.")
		return

	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"LoadingLifecycleService.queue_deferred_idle_tasks",
		"LoadingLifecycleService.prune_idle_tasks",
		"UILifecycleService.layer_snapshot",
		"UILifecycleService.trim_dictionary_cache",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate lifecycle glue to service token: %s" % token)
			return
	print("LIFECYCLE_SERVICES_CONTRACT_PROBE ok")
	quit(0)
