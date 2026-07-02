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
	var action_plans: Dictionary = UILifecycleService.editor_action_presentations(
		["assembly_guide_prev", "load_unit", "duplicate", "copy_selection"],
		barrier_visibility_plan,
		{
			"barrier_screen_board": true,
			"orientation_choice_active": false,
			"selected_handedness_active": false,
			"sort_menu_open": false,
			"clipboard_busy": false,
			"has_selection": true,
			"has_topology_clipboard": false,
		},
		{"zh": false, "load_mode": "unit", "unit_page_actions_enabled": false}
	)
	var batch_guide_plan: Dictionary = Dictionary(action_plans.get("assembly_guide_prev", {}))
	var batch_unit_plan: Dictionary = Dictionary(action_plans.get("load_unit", {}))
	var batch_duplicate_plan: Dictionary = Dictionary(action_plans.get("duplicate", {}))
	var batch_copy_plan: Dictionary = Dictionary(action_plans.get("copy_selection", {}))
	if bool(batch_guide_plan.get("managed", true)) or not bool(batch_unit_plan.get("visible", false)) or not bool(batch_duplicate_plan.get("visible", false)):
		_fail("UILifecycleService action presentation batch should preserve unmanaged and visible action plans.")
		return
	_assert_vector(batch_unit_plan, "position", Vector2(936.0, 126.0), "batch first unit action presentation")
	_assert_vector(batch_duplicate_plan, "position", Vector2(1072.0, 126.0), "batch second unit action presentation")
	if bool(batch_copy_plan.get("visible", true)):
		_fail("UILifecycleService action presentation batch should derive hidden canvas visibility from the barrier state.")
		return
	var assembly_lifecycle_service := UILifecycleService.new()
	if not assembly_lifecycle_service.has_method("editor_assembly_guide_presentation"):
		_fail("UILifecycleService should expose editor assembly-guide presentation planning.")
		return
	var assembly_model := {
		"key": "connection",
		"short_label": "连接",
		"tooltip_text": "连接提示",
		"tutorial_text": "连接教程",
		"instruction": "连接说明",
		"can_prev": true,
		"can_next": true,
	}
	var blocked_assembly_plan: Dictionary = assembly_lifecycle_service.call("editor_assembly_guide_presentation", true, assembly_model, false, true)
	var assembly_label: Dictionary = Dictionary(blocked_assembly_plan.get("guide_label", {}))
	var assembly_tutorial_panel: Dictionary = Dictionary(blocked_assembly_plan.get("tutorial_panel", {}))
	var assembly_tutorial_label: Dictionary = Dictionary(blocked_assembly_plan.get("tutorial_label", {}))
	if not bool(assembly_label.get("visible", false)) or String(assembly_label.get("text", "")) != "推荐 连接" or String(assembly_label.get("tooltip", "")) != "连接提示":
		_fail("UILifecycleService assembly-guide label presentation contract failed.")
		return
	_assert_vector(assembly_label, "position", Vector2(936.0, 118.0), "assembly-guide label presentation")
	_assert_vector(assembly_label, "size", Vector2(160.0, 22.0), "assembly-guide label presentation")
	_assert_color(assembly_label, "modulate", Color(1.0, 0.88, 0.30, 1.0), "assembly-guide label presentation")
	if not bool(assembly_tutorial_panel.get("visible", false)) or not bool(assembly_tutorial_label.get("visible", false)) or String(assembly_tutorial_label.get("text", "")) != "连接教程" or String(assembly_tutorial_label.get("tooltip", "")) != "连接说明":
		_fail("UILifecycleService assembly-guide tutorial presentation contract failed.")
		return
	_assert_vector(assembly_tutorial_panel, "position", Vector2(194.0, 102.0), "assembly-guide panel presentation")
	_assert_vector(assembly_tutorial_label, "position", Vector2(320.0, 108.0), "assembly-guide tutorial presentation")
	var assembly_actions: Dictionary = Dictionary(blocked_assembly_plan.get("actions", {}))
	var prev_assembly_action: Dictionary = Dictionary(assembly_actions.get("assembly_guide_prev", {}))
	var apply_assembly_action: Dictionary = Dictionary(assembly_actions.get("assembly_guide_apply", {}))
	var next_assembly_action: Dictionary = Dictionary(assembly_actions.get("assembly_guide_next", {}))
	if String(prev_assembly_action.get("text", "")) != "<" or bool(prev_assembly_action.get("disabled", true)):
		_fail("UILifecycleService assembly-guide prev action contract failed.")
		return
	if String(apply_assembly_action.get("text", "")) != "前往" or bool(apply_assembly_action.get("disabled", true)):
		_fail("UILifecycleService assembly-guide apply action contract failed.")
		return
	if String(next_assembly_action.get("text", "")) != ">" or not bool(next_assembly_action.get("disabled", false)) or String(next_assembly_action.get("tooltip", "")) != "先通过连接评估":
		_fail("UILifecycleService assembly-guide connection gate contract failed.")
		return
	_assert_vector(prev_assembly_action, "position", Vector2(1100.0, 118.0), "assembly-guide prev action")
	_assert_vector(apply_assembly_action, "size", Vector2(48.0, 22.0), "assembly-guide apply action")
	_assert_color(next_assembly_action, "modulate", Color(0.54, 0.62, 0.68, 0.7), "assembly-guide gated next action")
	var passed_assembly_plan: Dictionary = assembly_lifecycle_service.call("editor_assembly_guide_presentation", true, assembly_model, true, false)
	var passed_next_action: Dictionary = Dictionary(Dictionary(passed_assembly_plan.get("actions", {})).get("assembly_guide_next", {}))
	if bool(passed_next_action.get("disabled", true)) or String(passed_next_action.get("tooltip", "")) != "Next recommended step":
		_fail("UILifecycleService assembly-guide next action should unlock after connection evaluation.")
		return
	var hidden_assembly_plan: Dictionary = assembly_lifecycle_service.call("editor_assembly_guide_presentation", false, assembly_model, true, false)
	var hidden_actions: Dictionary = Dictionary(hidden_assembly_plan.get("actions", {}))
	if bool(Dictionary(hidden_assembly_plan.get("guide_label", {})).get("visible", true)) or bool(Dictionary(hidden_assembly_plan.get("tutorial_panel", {})).get("visible", true)) or bool(Dictionary(hidden_actions.get("assembly_guide_next", {})).get("visible", true)) or not bool(Dictionary(hidden_actions.get("assembly_guide_next", {})).get("disabled", false)):
		_fail("UILifecycleService hidden assembly-guide presentation contract failed.")
		return
	if not assembly_lifecycle_service.has_method("editor_board_zoom_presentation"):
		_fail("UILifecycleService should expose editor board-zoom presentation planning.")
		return
	var min_zoom_plan: Dictionary = assembly_lifecycle_service.call("editor_board_zoom_presentation", 0.35, 0.35, 2.0, true)
	var min_zoom_label: Dictionary = Dictionary(min_zoom_plan.get("label", {}))
	var min_zoom_actions: Dictionary = Dictionary(min_zoom_plan.get("actions", {}))
	var min_zoom_out: Dictionary = Dictionary(min_zoom_actions.get("board_zoom_out", {}))
	var min_zoom_in: Dictionary = Dictionary(min_zoom_actions.get("board_zoom_in", {}))
	var min_zoom_reset: Dictionary = Dictionary(min_zoom_actions.get("board_zoom_reset", {}))
	if String(min_zoom_label.get("text", "")) != "35%" or String(min_zoom_out.get("text", "")) != "-" or not bool(min_zoom_out.get("disabled", false)):
		_fail("UILifecycleService min board-zoom presentation contract failed.")
		return
	if String(min_zoom_in.get("text", "")) != "+" or bool(min_zoom_in.get("disabled", true)):
		_fail("UILifecycleService board-zoom in action should be enabled above min.")
		return
	if String(min_zoom_reset.get("text", "")) != "重置":
		_fail("UILifecycleService board-zoom reset zh text failed.")
		return
	var max_zoom_plan: Dictionary = assembly_lifecycle_service.call("editor_board_zoom_presentation", 2.0, 0.35, 2.0, false)
	var max_zoom_actions: Dictionary = Dictionary(max_zoom_plan.get("actions", {}))
	var max_zoom_in: Dictionary = Dictionary(max_zoom_actions.get("board_zoom_in", {}))
	var max_zoom_reset: Dictionary = Dictionary(max_zoom_actions.get("board_zoom_reset", {}))
	if String(Dictionary(max_zoom_plan.get("label", {})).get("text", "")) != "200%" or not bool(max_zoom_in.get("disabled", false)) or String(max_zoom_reset.get("text", "")) != "RESET":
		_fail("UILifecycleService max board-zoom presentation contract failed.")
		return
	var mid_zoom_plan: Dictionary = assembly_lifecycle_service.call("editor_board_zoom_presentation", 1.25, 0.35, 2.0, false)
	var mid_zoom_actions: Dictionary = Dictionary(mid_zoom_plan.get("actions", {}))
	if String(Dictionary(mid_zoom_plan.get("label", {})).get("text", "")) != "125%" or bool(Dictionary(mid_zoom_actions.get("board_zoom_out", {})).get("disabled", true)) or bool(Dictionary(mid_zoom_actions.get("board_zoom_in", {})).get("disabled", true)):
		_fail("UILifecycleService middle board-zoom presentation contract failed.")
		return
	if not assembly_lifecycle_service.has_method("editor_orientation_popup_presentation"):
		_fail("UILifecycleService should expose editor orientation popup presentation planning.")
		return
	var hidden_orientation_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_popup_presentation", false, false, Vector2(600.0, 70.0), Vector2(700.0, 400.0), true)
	if bool(Dictionary(hidden_orientation_plan.get("panel", {})).get("visible", true)):
		_fail("UILifecycleService hidden orientation popup contract failed.")
		return
	var invalid_orientation_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_popup_presentation", true, false, Vector2(600.0, 70.0), Vector2(700.0, 400.0), true)
	if bool(Dictionary(invalid_orientation_plan.get("panel", {})).get("visible", true)):
		_fail("UILifecycleService invalid orientation popup contract failed.")
		return
	var orientation_popup_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_popup_presentation", true, true, Vector2(600.0, 70.0), Vector2(700.0, 400.0), true)
	var orientation_panel: Dictionary = Dictionary(orientation_popup_plan.get("panel", {}))
	var orientation_label: Dictionary = Dictionary(orientation_popup_plan.get("label", {}))
	var orientation_buttons: Dictionary = Dictionary(orientation_popup_plan.get("buttons", {}))
	var orientation_left: Dictionary = Dictionary(orientation_buttons.get("left", {}))
	var orientation_right: Dictionary = Dictionary(orientation_buttons.get("right", {}))
	var orientation_cancel: Dictionary = Dictionary(orientation_buttons.get("cancel", {}))
	if not bool(orientation_panel.get("visible", false)) or not bool(orientation_panel.get("move_to_front", false)):
		_fail("UILifecycleService visible orientation popup panel contract failed.")
		return
	_assert_vector(orientation_panel, "position", Vector2(432.0, 90.0), "orientation popup panel presentation")
	_assert_vector(orientation_panel, "size", Vector2(256.0, 86.0), "orientation popup panel presentation")
	_assert_color(orientation_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), "orientation popup panel presentation")
	if String(orientation_label.get("text", "")) != "选择镰刀侧挂刃朝向" or String(orientation_left.get("text", "")) != "左侧挂刃" or String(orientation_right.get("text", "")) != "右侧挂刃" or String(orientation_cancel.get("text", "")) != "稍后":
		_fail("UILifecycleService zh orientation popup copy contract failed.")
		return
	if bool(orientation_left.get("disabled", true)) or bool(orientation_right.get("disabled", true)) or bool(orientation_cancel.get("disabled", true)):
		_fail("UILifecycleService orientation popup buttons should be enabled.")
		return
	var english_orientation_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_popup_presentation", true, true, Vector2(-80.0, 500.0), Vector2(900.0, 560.0), false)
	var english_orientation_panel: Dictionary = Dictionary(english_orientation_plan.get("panel", {}))
	var english_orientation_buttons: Dictionary = Dictionary(english_orientation_plan.get("buttons", {}))
	if String(Dictionary(english_orientation_plan.get("label", {})).get("text", "")) != "Choose scythe blade side" or String(Dictionary(english_orientation_buttons.get("cancel", {})).get("text", "")) != "LATER":
		_fail("UILifecycleService en orientation popup copy contract failed.")
		return
	_assert_vector(english_orientation_panel, "position", Vector2(12.0, 462.0), "orientation popup clamped presentation")
	if not assembly_lifecycle_service.has_method("editor_orientation_action_buttons_presentation"):
		_fail("UILifecycleService should expose editor orientation action button presentation planning.")
		return
	var orientation_action_choice_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_action_buttons_presentation", true, false, true)
	var orientation_action_choice_left: Dictionary = Dictionary(orientation_action_choice_plan.get("set_handedness_left", {}))
	var orientation_action_choice_right: Dictionary = Dictionary(orientation_action_choice_plan.get("set_handedness_right", {}))
	var orientation_action_choice_flip: Dictionary = Dictionary(orientation_action_choice_plan.get("flip_handedness", {}))
	if not bool(orientation_action_choice_left.get("visible", false)) or bool(orientation_action_choice_left.get("disabled", true)) or String(orientation_action_choice_left.get("text", "")) != "左挂刃" or not bool(orientation_action_choice_left.get("move_to_front", false)):
		_fail("UILifecycleService orientation choice left action presentation failed.")
		return
	if not bool(orientation_action_choice_right.get("visible", false)) or bool(orientation_action_choice_right.get("disabled", true)) or String(orientation_action_choice_right.get("text", "")) != "右挂刃" or not bool(orientation_action_choice_right.get("move_to_front", false)):
		_fail("UILifecycleService orientation choice right action presentation failed.")
		return
	if bool(orientation_action_choice_flip.get("visible", true)) or not bool(orientation_action_choice_flip.get("disabled", false)):
		_fail("UILifecycleService should hide flip action during explicit orientation choice.")
		return
	_assert_vector(orientation_action_choice_left, "position", Vector2(776.0, 688.0), "orientation left action presentation")
	_assert_vector(orientation_action_choice_right, "position", Vector2(846.0, 688.0), "orientation right action presentation")
	_assert_vector(orientation_action_choice_left, "size", Vector2(66.0, 24.0), "orientation left action presentation")
	_assert_color(orientation_action_choice_left, "modulate", Color(0.42, 1.0, 0.82, 1.0), "orientation visible action presentation")
	var orientation_action_flip_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_action_buttons_presentation", false, true, false)
	var orientation_action_flip: Dictionary = Dictionary(orientation_action_flip_plan.get("flip_handedness", {}))
	var orientation_action_hidden_left: Dictionary = Dictionary(orientation_action_flip_plan.get("set_handedness_left", {}))
	if not bool(orientation_action_flip.get("visible", false)) or bool(orientation_action_flip.get("disabled", true)) or String(orientation_action_flip.get("text", "")) != "FLIP SIDE" or not bool(orientation_action_flip.get("move_to_front", false)):
		_fail("UILifecycleService selected flip orientation action presentation failed.")
		return
	if bool(orientation_action_hidden_left.get("visible", true)) or not bool(orientation_action_hidden_left.get("disabled", false)):
		_fail("UILifecycleService should hide left orientation action outside orientation choice.")
		return
	_assert_vector(orientation_action_flip, "position", Vector2(776.0, 688.0), "orientation flip action presentation")
	var orientation_action_hidden_plan: Dictionary = assembly_lifecycle_service.call("editor_orientation_action_buttons_presentation", false, false, true)
	if bool(Dictionary(orientation_action_hidden_plan.get("set_handedness_left", {})).get("visible", true)) or bool(Dictionary(orientation_action_hidden_plan.get("set_handedness_right", {})).get("visible", true)) or bool(Dictionary(orientation_action_hidden_plan.get("flip_handedness", {})).get("visible", true)):
		_fail("UILifecycleService should hide all orientation action buttons when inactive.")
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
	var save_canvas_build_spec: Dictionary = _spec_with_key(board_primary_specs, "save_canvas")
	var training_import_build_spec: Dictionary = _spec_with_key(board_primary_specs, "training_import")
	var open_saved_units_build_spec: Dictionary = _spec_with_key(board_primary_specs, "open_saved_units")
	if String(save_canvas_build_spec.get("name", "")) != "BoardPrimarysave_canvas":
		_fail("UILifecycleService save canvas board-primary identity failed.")
		return
	if String(training_import_build_spec.get("name", "")) != "BoardPrimarytraining_import" or String(open_saved_units_build_spec.get("name", "")) != "BoardPrimaryopen_saved_units":
		_fail("UILifecycleService board-primary identity failed.")
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
	var part_library_build_specs: Dictionary = UILifecycleService.editor_part_library_build_specs(["torso", "limb", "terminal_weapon", "software"], 3, 5)
	var group_build_specs: Array = Array(part_library_build_specs.get("group_buttons", []))
	var slot_build_specs: Array = Array(part_library_build_specs.get("slot_buttons", []))
	var filter_build_specs: Array = Array(part_library_build_specs.get("filter_buttons", []))
	if group_build_specs.size() != 4 or slot_build_specs.size() != 3 or filter_build_specs.size() != 5:
		_fail("UILifecycleService part-library build spec counts failed.")
		return
	var terminal_group_spec: Dictionary = Dictionary(group_build_specs[2])
	if String(terminal_group_spec.get("key", "")) != "terminal_weapon" or String(terminal_group_spec.get("name", "")) != "PartGroupterminal_weapon":
		_fail("UILifecycleService part-group build spec identity failed.")
		return
	_assert_vector(terminal_group_spec, "position", Vector2(1116.0, 146.0), "part-group build spec")
	_assert_vector(terminal_group_spec, "size", Vector2(84.0, 24.0), "part-group build spec")
	var third_slot_spec: Dictionary = Dictionary(slot_build_specs[2])
	if int(third_slot_spec.get("index", -1)) != 2 or String(third_slot_spec.get("name", "")) != "Slot2":
		_fail("UILifecycleService slot build spec identity failed.")
		return
	_assert_vector(third_slot_spec, "position", Vector2(936.0, 234.0), "slot build spec")
	_assert_vector(third_slot_spec, "size", Vector2(130.0, 24.0), "slot build spec")
	var fifth_filter_spec: Dictionary = Dictionary(filter_build_specs[4])
	if int(fifth_filter_spec.get("index", -1)) != 4 or String(fifth_filter_spec.get("name", "")) != "PartFilter4":
		_fail("UILifecycleService filter build spec identity failed.")
		return
	_assert_vector(fifth_filter_spec, "position", Vector2(936.0, 228.0), "filter build spec")
	_assert_vector(fifth_filter_spec, "size", Vector2(64.0, 22.0), "filter build spec")
	var ammo_size_build_specs: Dictionary = UILifecycleService.editor_ammo_size_build_specs(5)
	var ammo_title_build_spec: Dictionary = Dictionary(ammo_size_build_specs.get("title", {}))
	var ammo_slider_build_spec: Dictionary = Dictionary(ammo_size_build_specs.get("slider", {}))
	var ammo_value_build_spec: Dictionary = Dictionary(ammo_size_build_specs.get("value", {}))
	var ammo_tick_build_specs: Array = Array(ammo_size_build_specs.get("ticks", []))
	if String(ammo_title_build_spec.get("name", "")) != "AmmoSizeTitle" or String(ammo_slider_build_spec.get("name", "")) != "AmmoSizeSlider" or String(ammo_value_build_spec.get("name", "")) != "AmmoSizeValue":
		_fail("UILifecycleService ammo-size build spec identity failed.")
		return
	_assert_vector(ammo_title_build_spec, "position", Vector2(936.0, 258.0), "ammo title build spec")
	_assert_vector(ammo_title_build_spec, "size", Vector2(72.0, 18.0), "ammo title build spec")
	_assert_vector(ammo_slider_build_spec, "position", Vector2(1010.0, 257.0), "ammo slider build spec")
	_assert_vector(ammo_slider_build_spec, "size", Vector2(176.0, 22.0), "ammo slider build spec")
	if float(ammo_slider_build_spec.get("min_value", 0.0)) != 1.0 or float(ammo_slider_build_spec.get("max_value", 0.0)) != 5.0 or float(ammo_slider_build_spec.get("step", 0.0)) != 1.0:
		_fail("UILifecycleService ammo slider range build spec failed.")
		return
	_assert_vector(ammo_value_build_spec, "position", Vector2(1190.0, 258.0), "ammo value build spec")
	if ammo_tick_build_specs.size() != 5:
		_fail("UILifecycleService ammo tick build spec count failed.")
		return
	var fifth_ammo_tick_build_spec: Dictionary = Dictionary(ammo_tick_build_specs[4])
	if int(fifth_ammo_tick_build_spec.get("index", -1)) != 4 or String(fifth_ammo_tick_build_spec.get("name", "")) != "AmmoSizeTick4":
		_fail("UILifecycleService ammo tick build spec identity failed.")
		return
	_assert_vector(fifth_ammo_tick_build_spec, "position", Vector2(1178.0, 278.0), "ammo tick build spec")
	_assert_vector(fifth_ammo_tick_build_spec, "size", Vector2(34.0, 14.0), "ammo tick build spec")
	var role_load_build_specs: Dictionary = UILifecycleService.editor_role_load_build_specs(["hero", "offense"], 3)
	var role_button_build_specs: Array = Array(role_load_build_specs.get("role_buttons", []))
	var load_card_build_specs: Array = Array(role_load_build_specs.get("load_cards", []))
	if role_button_build_specs.size() != 2 or load_card_build_specs.size() != 3:
		_fail("UILifecycleService role/load build spec counts failed.")
		return
	var first_role_button_build_spec: Dictionary = Dictionary(role_button_build_specs[0])
	var second_role_button_build_spec: Dictionary = Dictionary(role_button_build_specs[1])
	if String(first_role_button_build_spec.get("key", "")) != "hero" or String(first_role_button_build_spec.get("name", "")) != "Rolehero":
		_fail("UILifecycleService role button build spec identity failed.")
		return
	_assert_vector(first_role_button_build_spec, "position", Vector2(936.0, 156.0), "role button build spec")
	_assert_vector(first_role_button_build_spec, "size", Vector2(86.0, 32.0), "role button build spec")
	_assert_vector(second_role_button_build_spec, "position", Vector2(1028.0, 156.0), "role button build spec")
	var third_load_card_build_spec: Dictionary = Dictionary(load_card_build_specs[2])
	if int(third_load_card_build_spec.get("index", -1)) != 2 or String(third_load_card_build_spec.get("name", "")) != "LoadCard2":
		_fail("UILifecycleService load card build spec identity failed.")
		return
	_assert_vector(third_load_card_build_spec, "position", Vector2(936.0, 288.0), "load card build spec")
	_assert_vector(third_load_card_build_spec, "size", Vector2(270.0, 30.0), "load card build spec")
	var load_card_ui_lifecycle_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/services/ui_lifecycle_service.gd"))
	if not load_card_ui_lifecycle_source.contains("static func editor_load_card_buttons_presentation("):
		_fail("UILifecycleService should expose editor load card button presentation planning.")
		return
	var load_card_ui_lifecycle_service := UILifecycleService.new()
	var load_card_plan: Dictionary = load_card_ui_lifecycle_service.call("editor_load_card_buttons_presentation", true, 1, 2, 14, [
		{"visible": false, "actual_index": 9},
		{"visible": true, "kind": "empty", "actual_index": 0, "text": "01 H  EMPTY  $0"},
		{"visible": true, "kind": "builtin", "actual_index": 1, "text": "P02 H#1  Ace  $120"},
		{"visible": true, "kind": "library", "actual_index": 2, "text": "U03 P#2  Spark  $80"},
		{"visible": true, "kind": "unit", "actual_index": 3, "text": "U04 B#3  Wall  $50", "selected": true},
	], false)
	var load_prev_plan: Dictionary = Dictionary(load_card_plan.get("prev", {}))
	var load_next_plan: Dictionary = Dictionary(load_card_plan.get("next", {}))
	var load_page_plan: Dictionary = Dictionary(load_card_plan.get("page", {}))
	if String(load_prev_plan.get("text", "")) != "<" or bool(load_prev_plan.get("disabled", true)) or String(load_next_plan.get("text", "")) != ">" or bool(load_next_plan.get("disabled", true)):
		_fail("UILifecycleService load card nav presentation failed.")
		return
	if String(load_page_plan.get("text", "")) != "P 2/3  14":
		_fail("UILifecycleService load card page presentation failed.")
		return
	_assert_vector(load_page_plan, "position", Vector2(966.0, 654.0), "load card page presentation")
	_assert_vector(load_page_plan, "size", Vector2(210.0, 22.0), "load card page presentation")
	var load_card_plans: Array = Array(load_card_plan.get("cards", []))
	if load_card_plans.size() != 5:
		_fail("UILifecycleService load card presentation count failed.")
		return
	var hidden_load_card_plan: Dictionary = Dictionary(load_card_plans[0])
	var empty_load_card_plan: Dictionary = Dictionary(load_card_plans[1])
	var builtin_load_card_plan: Dictionary = Dictionary(load_card_plans[2])
	var library_load_card_plan: Dictionary = Dictionary(load_card_plans[3])
	var selected_load_card_plan: Dictionary = Dictionary(load_card_plans[4])
	if bool(hidden_load_card_plan.get("visible", true)) or not bool(hidden_load_card_plan.get("disabled", false)) or String(hidden_load_card_plan.get("text", "x")) != "":
		_fail("UILifecycleService hidden load card presentation failed.")
		return
	if String(empty_load_card_plan.get("text", "")) != "01 H  EMPTY  $0":
		_fail("UILifecycleService empty load card presentation failed.")
		return
	_assert_vector(empty_load_card_plan, "position", Vector2(936.0, 258.0), "empty load card presentation")
	_assert_color(empty_load_card_plan, "modulate", Color(0.58, 0.64, 0.68, 0.76), "empty load card presentation")
	_assert_vector(builtin_load_card_plan, "position", Vector2(936.0, 318.0), "builtin load card presentation")
	_assert_color(builtin_load_card_plan, "modulate", Color(0.74, 1.0, 0.48, 1.0), "builtin load card presentation")
	_assert_vector(library_load_card_plan, "position", Vector2(936.0, 352.0), "library load card presentation")
	_assert_color(library_load_card_plan, "modulate", Color(0.38, 0.96, 1.0, 1.0), "library load card presentation")
	_assert_color(selected_load_card_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "selected load card presentation")
	var hidden_load_card_plan_set: Dictionary = load_card_ui_lifecycle_service.call("editor_load_card_buttons_presentation", false, 0, 0, 0, [{"visible": true, "kind": "unit", "text": "stale"}], true)
	var hidden_load_cards: Array = Array(hidden_load_card_plan_set.get("cards", []))
	if hidden_load_cards.size() != 1 or bool(Dictionary(hidden_load_cards[0]).get("visible", true)) or String(Dictionary(hidden_load_card_plan_set.get("prev", {})).get("text", "x")) != "":
		_fail("UILifecycleService hidden load card mode presentation failed.")
		return
	var info_surface_build_specs: Dictionary = UILifecycleService.editor_info_surface_build_specs()
	var info_unit_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("unit", {}))
	var info_summary_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("summary", {}))
	var info_stats_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("stats", {}))
	var info_detail_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("detail", {}))
	var info_battle_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("battle_preview", {}))
	var info_component_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("component_art", {}))
	var info_structure_view_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("structure_reference_view", {}))
	var info_structure_label_build_spec: Dictionary = Dictionary(info_surface_build_specs.get("structure_reference_label", {}))
	if String(info_unit_build_spec.get("name", "")) != "UnitLabel" or String(info_summary_build_spec.get("name", "")) != "Summary" or String(info_stats_build_spec.get("name", "")) != "Stats" or String(info_detail_build_spec.get("name", "")) != "Detail":
		_fail("UILifecycleService info label build spec identity failed.")
		return
	_assert_vector(info_unit_build_spec, "position", Vector2(936.0, 198.0), "info unit build spec")
	_assert_vector(info_unit_build_spec, "size", Vector2(270.0, 48.0), "info unit build spec")
	_assert_vector(info_unit_build_spec, "visible_position", Vector2(936.0, 186.0), "info unit build spec")
	_assert_vector(info_unit_build_spec, "visible_size", Vector2(270.0, 52.0), "info unit build spec")
	_assert_vector(info_summary_build_spec, "position", Vector2(936.0, 454.0), "info summary build spec")
	_assert_vector(info_summary_build_spec, "visible_position", Vector2(936.0, 586.0), "info summary build spec")
	_assert_vector(info_summary_build_spec, "visible_size", Vector2(270.0, 88.0), "info summary build spec")
	_assert_vector(info_stats_build_spec, "position", Vector2(936.0, 484.0), "info stats build spec")
	_assert_vector(info_detail_build_spec, "position", Vector2(936.0, 548.0), "info detail build spec")
	if String(info_battle_build_spec.get("name", "")) != "BattleArtPreview" or String(info_structure_view_build_spec.get("name", "")) != "StructureReferencePreview" or String(info_structure_label_build_spec.get("name", "")) != "StructureReferenceLabel":
		_fail("UILifecycleService info preview build spec identity failed.")
		return
	_assert_vector(info_battle_build_spec, "position", Vector2(936.0, 278.0), "info battle preview build spec")
	_assert_vector(info_battle_build_spec, "size", Vector2(270.0, 118.0), "info battle preview build spec")
	_assert_vector(info_component_build_spec, "position", Vector2(936.0, 406.0), "info component art build spec")
	_assert_vector(info_component_build_spec, "size", Vector2(270.0, 68.0), "info component art build spec")
	_assert_vector(info_structure_view_build_spec, "position", Vector2(936.0, 146.0), "info structure preview build spec")
	_assert_vector(info_structure_view_build_spec, "size", Vector2(270.0, 112.0), "info structure preview build spec")
	_assert_vector(info_structure_label_build_spec, "position", Vector2(936.0, 260.0), "info structure label build spec")
	_assert_vector(info_structure_label_build_spec, "size", Vector2(270.0, 18.0), "info structure label build spec")
	var roster_overview_build_specs: Dictionary = UILifecycleService.editor_roster_overview_build_specs(5)
	var roster_title_build_spec: Dictionary = Dictionary(roster_overview_build_specs.get("title", {}))
	var roster_page_build_spec: Dictionary = Dictionary(roster_overview_build_specs.get("page", {}))
	var roster_prev_build_spec: Dictionary = Dictionary(roster_overview_build_specs.get("prev", {}))
	var roster_next_build_spec: Dictionary = Dictionary(roster_overview_build_specs.get("next", {}))
	var roster_slot_build_specs: Array = Array(roster_overview_build_specs.get("slots", []))
	if String(roster_title_build_spec.get("name", "")) != "RosterOverviewTitle" or String(roster_page_build_spec.get("name", "")) != "RosterOverviewPage":
		_fail("UILifecycleService roster overview label build spec identity failed.")
		return
	if String(roster_prev_build_spec.get("name", "")) != "EditorRosterPrev" or String(roster_next_build_spec.get("name", "")) != "EditorRosterNext":
		_fail("UILifecycleService roster overview nav build spec identity failed.")
		return
	if roster_slot_build_specs.size() != 5:
		_fail("UILifecycleService roster overview slot build spec count failed.")
		return
	_assert_vector(roster_title_build_spec, "position", Vector2(236.0, 46.0), "roster title build spec")
	_assert_vector(roster_title_build_spec, "size", Vector2(112.0, 22.0), "roster title build spec")
	_assert_vector(roster_page_build_spec, "position", Vector2(792.0, 46.0), "roster page build spec")
	_assert_vector(roster_prev_build_spec, "position", Vector2(846.0, 44.0), "roster prev build spec")
	_assert_vector(roster_next_build_spec, "position", Vector2(870.0, 44.0), "roster next build spec")
	var fourth_roster_slot_build_spec: Dictionary = Dictionary(roster_slot_build_specs[3])
	if int(fourth_roster_slot_build_spec.get("index", -1)) != 3 or String(fourth_roster_slot_build_spec.get("name", "")) != "EditorRosterSlot3":
		_fail("UILifecycleService roster slot build spec identity failed.")
		return
	_assert_vector(fourth_roster_slot_build_spec, "position", Vector2(608.0, 44.0), "roster slot build spec")
	_assert_vector(fourth_roster_slot_build_spec, "size", Vector2(82.0, 26.0), "roster slot build spec")
	_assert_vector(fourth_roster_slot_build_spec, "thumb_position", Vector2(611.0, 47.0), "roster thumb build spec")
	_assert_vector(fourth_roster_slot_build_spec, "thumb_size", Vector2(20.0, 20.0), "roster thumb build spec")
	var roster_ui_lifecycle_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/services/ui_lifecycle_service.gd"))
	if not roster_ui_lifecycle_source.contains("static func editor_roster_overview_presentation("):
		_fail("UILifecycleService should expose editor roster overview presentation planning.")
		return
	var roster_ui_lifecycle_service := UILifecycleService.new()
	var roster_overview_plan: Dictionary = roster_ui_lifecycle_service.call("editor_roster_overview_presentation", "barrier", 1, 2, [
		{"visible": false, "actual_index": 4},
		{"visible": true, "kind": "empty", "actual_index": 2, "role_short": "B"},
		{"visible": true, "kind": "unit", "unit_index": 4, "role_short": "H", "cost": 120, "blank": true, "selected": false},
		{"visible": true, "kind": "unit", "unit_index": 0, "role_short": "P", "cost": 90, "blank": false, "selected": true},
	], false)
	if String(Dictionary(roster_overview_plan.get("title", {})).get("text", "")) != "BARRIER GROUP" or String(Dictionary(roster_overview_plan.get("page", {})).get("text", "")) != "2/3":
		_fail("UILifecycleService roster overview title/page presentation failed.")
		return
	if not bool(Dictionary(roster_overview_plan.get("prev", {})).get("visible", false)) or bool(Dictionary(roster_overview_plan.get("prev", {})).get("disabled", true)) or bool(Dictionary(roster_overview_plan.get("next", {})).get("disabled", true)):
		_fail("UILifecycleService roster overview nav presentation failed.")
		return
	var roster_slot_plans: Array = Array(roster_overview_plan.get("slots", []))
	if roster_slot_plans.size() != 4:
		_fail("UILifecycleService roster overview slot presentation count failed.")
		return
	var hidden_roster_slot_plan: Dictionary = Dictionary(roster_slot_plans[0])
	var empty_roster_slot_plan: Dictionary = Dictionary(roster_slot_plans[1])
	var blank_roster_slot_plan: Dictionary = Dictionary(roster_slot_plans[2])
	var selected_roster_slot_plan: Dictionary = Dictionary(roster_slot_plans[3])
	if bool(hidden_roster_slot_plan.get("visible", true)) or not bool(hidden_roster_slot_plan.get("disabled", false)) or String(hidden_roster_slot_plan.get("text", "x")) != "":
		_fail("UILifecycleService hidden roster slot presentation failed.")
		return
	if bool(Dictionary(hidden_roster_slot_plan.get("thumb", {})).get("visible", true)) or String(Dictionary(hidden_roster_slot_plan.get("thumb", {})).get("status", "")) != "reserve":
		_fail("UILifecycleService hidden roster thumb presentation failed.")
		return
	if String(empty_roster_slot_plan.get("text", "")) != "03 +B":
		_fail("UILifecycleService empty roster slot presentation failed.")
		return
	_assert_color(empty_roster_slot_plan, "modulate", Color(0.58, 0.64, 0.68, 0.76), "empty roster slot presentation")
	if String(blank_roster_slot_plan.get("text", "")) != "05 H 120 BLK" or String(Dictionary(blank_roster_slot_plan.get("thumb", {})).get("status", "")) != "reserve":
		_fail("UILifecycleService blank roster slot presentation failed.")
		return
	if String(selected_roster_slot_plan.get("text", "")) != "01 P 90" or String(Dictionary(selected_roster_slot_plan.get("thumb", {})).get("status", "")) != "pending":
		_fail("UILifecycleService selected roster slot presentation failed.")
		return
	_assert_color(selected_roster_slot_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "selected roster slot presentation")
	var color_build_specs: Dictionary = UILifecycleService.editor_color_controls_build_specs(4)
	var color_panel_build_spec: Dictionary = Dictionary(color_build_specs.get("panel", {}))
	var color_label_build_spec: Dictionary = Dictionary(color_build_specs.get("label", {}))
	var color_button_build_specs: Array = Array(color_build_specs.get("buttons", []))
	var color_primary_picker_build_spec: Dictionary = Dictionary(color_build_specs.get("primary_picker", {}))
	var color_accent_picker_build_spec: Dictionary = Dictionary(color_build_specs.get("accent_picker", {}))
	if String(color_panel_build_spec.get("name", "")) != "EditorColorPalettePanel" or String(color_label_build_spec.get("name", "")) != "EditorColorLabel":
		_fail("UILifecycleService color build spec panel/label identity failed.")
		return
	if color_button_build_specs.size() != 4:
		_fail("UILifecycleService color button build spec count failed.")
		return
	if String(color_primary_picker_build_spec.get("name", "")) != "EditorPrimaryColorPicker" or String(color_accent_picker_build_spec.get("name", "")) != "EditorAccentColorPicker":
		_fail("UILifecycleService color picker build spec identity failed.")
		return
	_assert_vector(color_panel_build_spec, "position", Vector2(932.0, 146.0), "color panel build spec")
	_assert_vector(color_panel_build_spec, "size", Vector2(278.0, 274.0), "color panel build spec")
	_assert_vector(color_label_build_spec, "position", Vector2(944.0, 158.0), "color label build spec")
	_assert_vector(color_label_build_spec, "size", Vector2(254.0, 24.0), "color label build spec")
	var third_color_button_build_spec: Dictionary = Dictionary(color_button_build_specs[2])
	if int(third_color_button_build_spec.get("index", -1)) != 2 or String(third_color_button_build_spec.get("name", "")) != "EditorColorButton2":
		_fail("UILifecycleService color button build spec identity failed.")
		return
	_assert_vector(third_color_button_build_spec, "position", Vector2(944.0, 248.0), "color button build spec")
	_assert_vector(third_color_button_build_spec, "size", Vector2(118.0, 46.0), "color button build spec")
	_assert_vector(color_primary_picker_build_spec, "position", Vector2(944.0, 370.0), "primary color picker build spec")
	_assert_vector(color_accent_picker_build_spec, "position", Vector2(1072.0, 370.0), "accent color picker build spec")
	var ui_lifecycle_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/services/ui_lifecycle_service.gd"))
	if not ui_lifecycle_source.contains("static func editor_catalog_card_build_specs("):
		_fail("UILifecycleService should expose editor catalog card build specs.")
		return
	var ui_lifecycle_service := UILifecycleService.new()
	var catalog_card_build_specs: Array = ui_lifecycle_service.call("editor_catalog_card_build_specs", 8)
	if catalog_card_build_specs.size() != 8:
		_fail("UILifecycleService catalog card build spec count failed.")
		return
	var first_catalog_card_build_spec: Dictionary = Dictionary(catalog_card_build_specs[0])
	var eighth_catalog_card_build_spec: Dictionary = Dictionary(catalog_card_build_specs[7])
	if int(first_catalog_card_build_spec.get("index", -1)) != 0 or String(first_catalog_card_build_spec.get("name", "")) != "CatalogCard0":
		_fail("UILifecycleService catalog card build spec identity failed.")
		return
	if int(eighth_catalog_card_build_spec.get("index", -1)) != 7 or String(eighth_catalog_card_build_spec.get("name", "")) != "CatalogCard7":
		_fail("UILifecycleService catalog card build spec tail identity failed.")
		return
	_assert_vector(first_catalog_card_build_spec, "position", Vector2(936.0, 354.0), "catalog card build spec")
	_assert_vector(first_catalog_card_build_spec, "size", Vector2(130.0, 72.0), "catalog card build spec")
	_assert_vector(eighth_catalog_card_build_spec, "position", Vector2(1072.0, 576.0), "catalog card build spec")
	if not ui_lifecycle_source.contains("static func editor_template_drawer_build_specs("):
		_fail("UILifecycleService should expose editor template drawer build specs.")
		return
	var template_drawer_build_specs: Dictionary = ui_lifecycle_service.call("editor_template_drawer_build_specs", ["scout", "guard", "assault"], ["wall", "lens"])
	var template_panel_build_spec: Dictionary = Dictionary(template_drawer_build_specs.get("panel", {}))
	var template_title_build_spec: Dictionary = Dictionary(template_drawer_build_specs.get("title", {}))
	var archetype_button_build_specs: Array = Array(template_drawer_build_specs.get("archetype_buttons", []))
	var barrier_template_button_build_specs: Array = Array(template_drawer_build_specs.get("barrier_template_buttons", []))
	if String(template_panel_build_spec.get("name", "")) != "TemplateSubmenuPanel" or String(template_title_build_spec.get("name", "")) != "TemplateTitle":
		_fail("UILifecycleService template drawer panel/title identity failed.")
		return
	if archetype_button_build_specs.size() != 3 or barrier_template_button_build_specs.size() != 2:
		_fail("UILifecycleService template drawer button counts failed.")
		return
	_assert_vector(template_panel_build_spec, "position", Vector2(932.0, 180.0), "template drawer panel build spec")
	_assert_vector(template_panel_build_spec, "size", Vector2(278.0, 336.0), "template drawer panel build spec")
	_assert_vector(template_title_build_spec, "position", Vector2(936.0, 374.0), "template drawer title build spec")
	_assert_vector(template_title_build_spec, "size", Vector2(270.0, 20.0), "template drawer title build spec")
	var third_archetype_button_build_spec: Dictionary = Dictionary(archetype_button_build_specs[2])
	var second_barrier_button_build_spec: Dictionary = Dictionary(barrier_template_button_build_specs[1])
	if String(third_archetype_button_build_spec.get("key", "")) != "assault" or String(third_archetype_button_build_spec.get("name", "")) != "TemplateArchetypeassault":
		_fail("UILifecycleService archetype template button identity failed.")
		return
	if String(second_barrier_button_build_spec.get("key", "")) != "lens" or String(second_barrier_button_build_spec.get("name", "")) != "BarrierTemplatelens":
		_fail("UILifecycleService barrier template button identity failed.")
		return
	_assert_vector(third_archetype_button_build_spec, "position", Vector2(940.0, 216.0), "archetype template button build spec")
	_assert_vector(third_archetype_button_build_spec, "size", Vector2(126.0, 24.0), "archetype template button build spec")
	_assert_vector(second_barrier_button_build_spec, "position", Vector2(1074.0, 188.0), "barrier template button build spec")
	if not ui_lifecycle_source.contains("static func editor_template_drawer_presentation("):
		_fail("UILifecycleService should expose editor template drawer presentation planning.")
		return
	var template_drawer_plan: Dictionary = ui_lifecycle_service.call("editor_template_drawer_presentation", true, "duelist", true, "assault", ["scout", "guard", "assault"], ["wall", "lens"], "预组单位库", true, true)
	var template_drawer_panel: Dictionary = Dictionary(template_drawer_plan.get("panel", {}))
	var template_drawer_label: Dictionary = Dictionary(template_drawer_plan.get("label", {}))
	var template_drawer_buttons: Array = Array(template_drawer_plan.get("buttons", []))
	var template_drawer_toggle: Dictionary = Dictionary(template_drawer_plan.get("toggle", {}))
	if not bool(template_drawer_panel.get("visible", false)) or not bool(template_drawer_label.get("visible", false)):
		_fail("UILifecycleService template drawer visible presentation contract failed.")
		return
	_assert_vector(template_drawer_panel, "position", Vector2(932.0, 398.0), "template drawer presentation panel")
	_assert_vector(template_drawer_panel, "size", Vector2(278.0, 92.0), "template drawer presentation panel")
	_assert_vector(template_drawer_label, "position", Vector2(936.0, 374.0), "template drawer presentation label")
	_assert_vector(template_drawer_label, "size", Vector2(270.0, 20.0), "template drawer presentation label")
	if String(template_drawer_label.get("text", "")) != "预组单位库" or template_drawer_buttons.size() != 5:
		_fail("UILifecycleService template drawer label/count presentation contract failed.")
		return
	var template_first_button: Dictionary = Dictionary(template_drawer_buttons[0])
	var template_selected_button: Dictionary = Dictionary(template_drawer_buttons[2])
	var template_hidden_barrier_button: Dictionary = Dictionary(template_drawer_buttons[3])
	if not bool(template_first_button.get("visible", false)) or bool(template_first_button.get("disabled", true)) or not bool(template_selected_button.get("visible", false)) or bool(template_selected_button.get("disabled", true)):
		_fail("UILifecycleService archetype template button visibility contract failed.")
		return
	_assert_vector(template_first_button, "position", Vector2(940.0, 406.0), "template drawer first button presentation")
	_assert_vector(template_selected_button, "position", Vector2(940.0, 434.0), "template drawer selected button presentation")
	_assert_color(template_selected_button, "modulate", Color(0.32, 0.95, 1.0, 1.0), "selected template drawer button presentation")
	if bool(template_hidden_barrier_button.get("visible", true)) or not bool(template_hidden_barrier_button.get("disabled", false)):
		_fail("UILifecycleService template drawer hidden barrier button contract failed.")
		return
	if bool(template_drawer_toggle.get("visible", true)) or String(template_drawer_toggle.get("text", "")) != "关闭模板":
		_fail("UILifecycleService template drawer toggle zh contract failed.")
		return
	_assert_color(template_drawer_toggle, "modulate", Color(1.0, 0.88, 0.28, 1.0), "template drawer toggle presentation")
	var barrier_drawer_plan: Dictionary = ui_lifecycle_service.call("editor_template_drawer_presentation", true, "barrier", false, "", ["scout", "guard", "assault"], ["wall", "lens"], "Barrier presets", false, false)
	var barrier_drawer_buttons: Array = Array(barrier_drawer_plan.get("buttons", []))
	if not bool(Dictionary(barrier_drawer_plan.get("panel", {})).get("visible", false)) or bool(Dictionary(barrier_drawer_buttons[0]).get("visible", true)) or not bool(Dictionary(barrier_drawer_buttons[3]).get("visible", false)):
		_fail("UILifecycleService barrier template drawer visibility contract failed.")
		return
	_assert_vector(Dictionary(barrier_drawer_buttons[3]), "position", Vector2(940.0, 406.0), "barrier template drawer button presentation")
	if String(Dictionary(barrier_drawer_plan.get("toggle", {})).get("text", "")) != "IMPORT TEMPLATE":
		_fail("UILifecycleService template drawer toggle en contract failed.")
		return
	var hidden_drawer_plan: Dictionary = ui_lifecycle_service.call("editor_template_drawer_presentation", false, "duelist", true, "assault", ["scout", "guard", "assault"], ["wall", "lens"], "预组单位库", false, true)
	if bool(Dictionary(hidden_drawer_plan.get("panel", {})).get("visible", true)) or bool(Dictionary(hidden_drawer_plan.get("label", {})).get("visible", true)) or bool(Dictionary(Array(hidden_drawer_plan.get("buttons", []))[0]).get("visible", true)):
		_fail("UILifecycleService hidden template drawer presentation contract failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_shop_surface_build_specs("):
		_fail("UILifecycleService should expose editor shop surface build specs.")
		return
	var shop_surface_build_specs: Dictionary = ui_lifecycle_service.call("editor_shop_surface_build_specs", ["left_claw", "right_claw", "rear"])
	var shop_title_build_spec: Dictionary = Dictionary(shop_surface_build_specs.get("title", {}))
	var shop_hint_build_spec: Dictionary = Dictionary(shop_surface_build_specs.get("hint", {}))
	var shop_pending_build_spec: Dictionary = Dictionary(shop_surface_build_specs.get("pending", {}))
	var shop_backdrop_build_spec: Dictionary = Dictionary(shop_surface_build_specs.get("backdrop", {}))
	var shop_button_build_specs: Array = Array(shop_surface_build_specs.get("buttons", []))
	if String(shop_title_build_spec.get("name", "")) != "ShopTitle" or String(shop_hint_build_spec.get("name", "")) != "ShopHint" or String(shop_pending_build_spec.get("name", "")) != "ShopPending":
		_fail("UILifecycleService shop label build spec identity failed.")
		return
	if String(shop_backdrop_build_spec.get("name", "")) != "ShopCardArtBackdrop":
		_fail("UILifecycleService shop backdrop build spec identity failed.")
		return
	if shop_button_build_specs.size() != 3:
		_fail("UILifecycleService shop button build spec count failed.")
		return
	_assert_vector(shop_title_build_spec, "position", Vector2(936.0, 146.0), "shop title build spec")
	_assert_vector(shop_hint_build_spec, "position", Vector2(936.0, 170.0), "shop hint build spec")
	_assert_vector(shop_pending_build_spec, "position", Vector2(936.0, 214.0), "shop pending build spec")
	_assert_vector(shop_backdrop_build_spec, "position", Vector2(936.0, 252.0), "shop backdrop build spec")
	_assert_vector(shop_backdrop_build_spec, "size", Vector2(270.0, 338.0), "shop backdrop build spec")
	var third_shop_button_build_spec: Dictionary = Dictionary(shop_button_build_specs[2])
	if int(third_shop_button_build_spec.get("index", -1)) != 2 or String(third_shop_button_build_spec.get("key", "")) != "rear" or String(third_shop_button_build_spec.get("name", "")) != "ShopButtonrear":
		_fail("UILifecycleService shop button build spec identity failed.")
		return
	_assert_vector(third_shop_button_build_spec, "position", Vector2(936.0, 420.0), "shop button build spec")
	_assert_vector(third_shop_button_build_spec, "size", Vector2(270.0, 76.0), "shop button build spec")
	if not ui_lifecycle_source.contains("static func editor_sort_menu_build_specs("):
		_fail("UILifecycleService should expose editor sort menu build specs.")
		return
	var sort_menu_build_specs: Dictionary = ui_lifecycle_service.call("editor_sort_menu_build_specs", ["cost", "mass", "name", "slot"])
	var sort_panel_build_spec: Dictionary = Dictionary(sort_menu_build_specs.get("panel", {}))
	var sort_option_build_specs: Array = Array(sort_menu_build_specs.get("options", []))
	var catalog_title_build_spec: Dictionary = Dictionary(sort_menu_build_specs.get("catalog_title", {}))
	var catalog_page_build_spec: Dictionary = Dictionary(sort_menu_build_specs.get("catalog_page", {}))
	if String(sort_panel_build_spec.get("name", "")) != "EditorSortSubmenu":
		_fail("UILifecycleService sort panel build spec identity failed.")
		return
	if sort_option_build_specs.size() != 4:
		_fail("UILifecycleService sort option build spec count failed.")
		return
	if String(catalog_title_build_spec.get("name", "")) != "CatalogTitle" or String(catalog_page_build_spec.get("name", "")) != "CatalogPage":
		_fail("UILifecycleService catalog header build spec identity failed.")
		return
	_assert_vector(sort_panel_build_spec, "position", Vector2(932.0, 318.0), "sort panel build spec")
	_assert_vector(sort_panel_build_spec, "size", Vector2(278.0, 112.0), "sort panel build spec")
	var fourth_sort_option_build_spec: Dictionary = Dictionary(sort_option_build_specs[3])
	if int(fourth_sort_option_build_spec.get("index", -1)) != 3 or String(fourth_sort_option_build_spec.get("key", "")) != "slot" or String(fourth_sort_option_build_spec.get("name", "")) != "SortOption3":
		_fail("UILifecycleService sort option build spec identity failed.")
		return
	_assert_vector(fourth_sort_option_build_spec, "position", Vector2(940.0, 354.0), "sort option build spec")
	_assert_vector(fourth_sort_option_build_spec, "size", Vector2(82.0, 24.0), "sort option build spec")
	_assert_vector(catalog_title_build_spec, "position", Vector2(936.0, 330.0), "catalog title build spec")
	_assert_vector(catalog_page_build_spec, "position", Vector2(1110.0, 330.0), "catalog page build spec")
	if not ui_lifecycle_source.contains("static func editor_body_part_button_build_specs("):
		_fail("UILifecycleService should expose editor body part button build specs.")
		return
	var body_part_build_specs: Array = ui_lifecycle_service.call("editor_body_part_button_build_specs", ["left_claw", "right_claw", "front_left_leg"])
	if body_part_build_specs.size() != 3:
		_fail("UILifecycleService body part button build spec count failed.")
		return
	var first_body_part_build_spec: Dictionary = Dictionary(body_part_build_specs[0])
	var third_body_part_build_spec: Dictionary = Dictionary(body_part_build_specs[2])
	if String(first_body_part_build_spec.get("key", "")) != "left_claw" or String(first_body_part_build_spec.get("name", "")) != "EditorBodyPartleft_claw":
		_fail("UILifecycleService body part button identity failed.")
		return
	if String(third_body_part_build_spec.get("key", "")) != "front_left_leg" or String(third_body_part_build_spec.get("name", "")) != "EditorBodyPartfront_left_leg":
		_fail("UILifecycleService body part button tail identity failed.")
		return
	_assert_vector(first_body_part_build_spec, "position", Vector2(128.0, 178.0), "body part button build spec")
	_assert_vector(first_body_part_build_spec, "size", Vector2(132.0, 44.0), "body part button build spec")
	_assert_vector(third_body_part_build_spec, "position", Vector2(172.0, 328.0), "body part button build spec")
	if not ui_lifecycle_source.contains("static func editor_body_board_button_presentation("):
		_fail("UILifecycleService should expose editor body-board button presentation planning.")
		return
	var selected_illegal_body_button_plan: Dictionary = ui_lifecycle_service.call("editor_body_board_button_presentation", true, false, false, true, true, "左爪")
	if not bool(selected_illegal_body_button_plan.get("visible", false)) or bool(selected_illegal_body_button_plan.get("disabled", true)) or String(selected_illegal_body_button_plan.get("text", "")) != "> ! 左爪":
		_fail("UILifecycleService selected illegal body-board button presentation failed.")
		return
	var custom_body_button_plan: Dictionary = ui_lifecycle_service.call("editor_body_board_button_presentation", true, true, false, true, false, "LEFT CLAW")
	if bool(custom_body_button_plan.get("visible", true)) or bool(custom_body_button_plan.get("disabled", true)) or String(custom_body_button_plan.get("text", "")) != "> LEFT CLAW":
		_fail("UILifecycleService custom body-board button presentation failed.")
		return
	var barrier_body_button_plan: Dictionary = ui_lifecycle_service.call("editor_body_board_button_presentation", true, false, true, false, false, "LEFT CLAW")
	if bool(barrier_body_button_plan.get("visible", true)) or bool(barrier_body_button_plan.get("disabled", true)) or String(barrier_body_button_plan.get("text", "")) != "LEFT CLAW":
		_fail("UILifecycleService barrier body-board button presentation failed.")
		return
	var inactive_body_button_plan: Dictionary = ui_lifecycle_service.call("editor_body_board_button_presentation", false, false, false, true, true, "LEFT CLAW")
	if bool(inactive_body_button_plan.get("visible", true)) or not bool(inactive_body_button_plan.get("disabled", false)) or String(inactive_body_button_plan.get("text", "")) != "LEFT CLAW":
		_fail("UILifecycleService inactive body-board button presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_body_shop_slot_button_presentation("):
		_fail("UILifecycleService should expose editor body shop-slot button presentation planning.")
		return
	if not ui_lifecycle_service.has_method("editor_body_shop_slot_text_presentation"):
		_fail("UILifecycleService should expose editor body shop-slot text presentation planning.")
		return
	var inactive_shop_slot_text_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_text_presentation", false, "muscle", "核心", "", 0, 0.0, 1, 0, false, false, "", true)
	if String(inactive_shop_slot_text_plan.get("text", "")) != "核心 零件库：仅机甲":
		_fail("UILifecycleService inactive body shop-slot text failed.")
		return
	var zh_shop_slot_text_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_text_presentation", true, "muscle", "肌肉", "SCYTHE BLADE", 120, 0.45, 1, 0, true, true, "当前节点 ", true)
	if String(zh_shop_slot_text_plan.get("text", "")) != "待放置 当前节点 购买武器/核心硬件\nSCYTHE BLADE\n价格120 | 长 0.45 / 接口 1\n武器多为单接口；核心决定插槽":
		_fail("UILifecycleService zh body shop-slot text failed.")
		return
	var module_shop_slot_text_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_text_presentation", true, "module", "MODULE", "Hook Return", 60, 0.0, 0, 2, true, false, "NODE ", false)
	if String(module_shop_slot_text_plan.get("text", "")) != "NODE INSTALL ACTION MODULE\nHook Return\nCOST 60 | software x2 / no volume\nNo volume; select node, then bind part/key":
		_fail("UILifecycleService en module shop-slot text failed.")
		return
	var inactive_shop_slot_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_button_presentation", false, "核心 零件库：仅机甲", "CORE BODY", false, false)
	if not bool(inactive_shop_slot_plan.get("disabled", false)) or String(inactive_shop_slot_plan.get("text", "")) != "核心 零件库：仅机甲" or inactive_shop_slot_plan.has("modulate"):
		_fail("UILifecycleService inactive body shop-slot button presentation failed.")
		return
	var pending_shop_slot_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_button_presentation", true, "核心 零件库：仅机甲", "PENDING CORE", true, false)
	if bool(pending_shop_slot_plan.get("disabled", true)) or String(pending_shop_slot_plan.get("text", "")) != "PENDING CORE":
		_fail("UILifecycleService pending body shop-slot button text/disabled failed.")
		return
	_assert_color(pending_shop_slot_plan, "modulate", Color(1.0, 0.86, 0.28, 1.0), "pending body shop-slot button presentation")
	var selected_shop_slot_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_button_presentation", true, "核心 零件库：仅机甲", "NODE CORE", false, true)
	_assert_color(selected_shop_slot_plan, "modulate", Color(0.42, 0.98, 1.0, 1.0), "selected body shop-slot button presentation")
	var default_shop_slot_plan: Dictionary = ui_lifecycle_service.call("editor_body_shop_slot_button_presentation", true, "核心 零件库：仅机甲", "CORE BODY", false, false)
	_assert_color(default_shop_slot_plan, "modulate", Color(0.9, 0.94, 0.98, 1.0), "default body shop-slot button presentation")
	if not ui_lifecycle_source.contains("static func editor_edit_side_button_presentation("):
		_fail("UILifecycleService should expose editor edit-side button presentation planning.")
		return
	var edit_side_p1_zh_plan: Dictionary = ui_lifecycle_service.call("editor_edit_side_button_presentation", 1, true)
	if String(edit_side_p1_zh_plan.get("text", "")) != "编辑 P1":
		_fail("UILifecycleService P1 Chinese edit-side button text failed.")
		return
	_assert_color(edit_side_p1_zh_plan, "modulate", Color(0.35, 0.95, 1.0, 1.0), "P1 edit-side button presentation")
	var edit_side_p2_en_plan: Dictionary = ui_lifecycle_service.call("editor_edit_side_button_presentation", 2, false)
	if String(edit_side_p2_en_plan.get("text", "")) != "EDIT P2":
		_fail("UILifecycleService P2 English edit-side button text failed.")
		return
	_assert_color(edit_side_p2_en_plan, "modulate", Color(1.0, 0.34, 0.48, 1.0), "P2 edit-side button presentation")
	if not ui_lifecycle_source.contains("static func editor_module_binding_button_build_specs("):
		_fail("UILifecycleService should expose editor module binding button build specs.")
		return
	var module_binding_build_specs: Dictionary = ui_lifecycle_service.call("editor_module_binding_button_build_specs", 3, 240, 380)
	var module_key_button_build_specs: Array = Array(module_binding_build_specs.get("key_buttons", []))
	var module_side_button_build_specs: Array = Array(module_binding_build_specs.get("side_buttons", []))
	var module_button_build_specs: Array = Array(module_binding_build_specs.get("buttons", []))
	if module_key_button_build_specs.size() != 3 or module_side_button_build_specs.size() != 2:
		_fail("UILifecycleService module binding button build spec counts failed.")
		return
	if module_button_build_specs.size() != 5:
		_fail("UILifecycleService module binding merged button build spec count failed.")
		return
	var first_module_key_button_build_spec: Dictionary = Dictionary(module_key_button_build_specs[0])
	var third_module_key_button_build_spec: Dictionary = Dictionary(module_key_button_build_specs[2])
	var right_module_side_button_build_spec: Dictionary = Dictionary(module_side_button_build_specs[1])
	if String(first_module_key_button_build_spec.get("key", "")) != "bind_key_1" or String(first_module_key_button_build_spec.get("name", "")) != "ModuleBindKey1":
		_fail("UILifecycleService module binding key identity failed.")
		return
	if String(right_module_side_button_build_spec.get("key", "")) != "bind_side_right" or String(right_module_side_button_build_spec.get("side", "")) != "right" or String(right_module_side_button_build_spec.get("name", "")) != "ModuleBindSideRight":
		_fail("UILifecycleService module binding side identity failed.")
		return
	_assert_vector(first_module_key_button_build_spec, "position", Vector2(286.0, 618.0), "module binding key build spec")
	_assert_vector(third_module_key_button_build_spec, "position", Vector2(398.0, 618.0), "module binding key build spec")
	_assert_vector(first_module_key_button_build_spec, "size", Vector2(50.0, 24.0), "module binding key build spec")
	_assert_vector(right_module_side_button_build_spec, "position", Vector2(936.0, 618.0), "module binding side build spec")
	_assert_vector(right_module_side_button_build_spec, "size", Vector2(132.0, 28.0), "module binding side build spec")
	if int(first_module_key_button_build_spec.get("z_index", -1)) != 240 or int(right_module_side_button_build_spec.get("z_index", -1)) != 380:
		_fail("UILifecycleService module binding z-index build spec failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_module_binding_tryout_button_presentation("):
		_fail("UILifecycleService should expose editor module binding tryout button presentation planning.")
		return
	var module_tryout_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_tryout_button_presentation", 2, true, false, true, "K", true, 240)
	_assert_vector(module_tryout_plan, "position", Vector2(342.0, 618.0), "module binding tryout button presentation")
	_assert_vector(module_tryout_plan, "size", Vector2(50.0, 24.0), "module binding tryout button presentation")
	if not bool(module_tryout_plan.get("visible", false)) or bool(module_tryout_plan.get("disabled", true)) or String(module_tryout_plan.get("text", "")) != "试2 K":
		_fail("UILifecycleService module binding active tryout text/state failed.")
		return
	if String(module_tryout_plan.get("tooltip", "")) != "试用攻击键 2（无伤害、不耗弹、不发热）" or int(module_tryout_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_STOP or int(module_tryout_plan.get("z_index", -1)) != 240 or not bool(module_tryout_plan.get("move_to_front", false)):
		_fail("UILifecycleService module binding active tryout metadata failed.")
		return
	_assert_color(module_tryout_plan, "modulate", Color(0.42, 1.0, 0.76, 0.96), "active module binding tryout button presentation")
	var module_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_tryout_button_presentation", 1, false, false, true, "J", false, 240)
	if bool(module_hidden_plan.get("visible", true)) or not bool(module_hidden_plan.get("disabled", false)) or String(module_hidden_plan.get("text", "")) != "1 J":
		_fail("UILifecycleService module binding inactive tryout text/state failed.")
		return
	if String(module_hidden_plan.get("tooltip", "")) != "Bind to attack key 1 (keyboard J)" or bool(module_hidden_plan.get("move_to_front", true)):
		_fail("UILifecycleService module binding inactive tryout metadata failed.")
		return
	_assert_color(module_hidden_plan, "modulate", Color(0.58, 0.82, 1.0, 0.92), "inactive module binding tryout button presentation")
	if not ui_lifecycle_source.contains("static func editor_module_binding_side_idle_presentation("):
		_fail("UILifecycleService should expose editor module binding side idle presentation planning.")
		return
	var module_side_idle_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_side_idle_presentation")
	if bool(module_side_idle_plan.get("visible", true)) or not bool(module_side_idle_plan.get("disabled", false)):
		_fail("UILifecycleService module binding side idle presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_module_binding_overlay_side_presentation("):
		_fail("UILifecycleService should expose editor module binding overlay side presentation planning.")
		return
	var module_overlay_side_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_overlay_side_presentation", true, Rect2(Vector2(12.0, 34.0), Vector2(88.0, 26.0)), "左侧", true, true, 380)
	_assert_vector(module_overlay_side_plan, "position", Vector2(12.0, 34.0), "module binding overlay side presentation")
	_assert_vector(module_overlay_side_plan, "size", Vector2(88.0, 26.0), "module binding overlay side presentation")
	if not bool(module_overlay_side_plan.get("visible", false)) or bool(module_overlay_side_plan.get("disabled", true)) or String(module_overlay_side_plan.get("text", "")) != "左侧":
		_fail("UILifecycleService module binding overlay side text/state failed.")
		return
	if String(module_overlay_side_plan.get("tooltip", "")) != "选择左侧后再绑定攻击键" or int(module_overlay_side_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_STOP or int(module_overlay_side_plan.get("z_index", -1)) != 380 or not bool(module_overlay_side_plan.get("move_to_front", false)):
		_fail("UILifecycleService module binding overlay side metadata failed.")
		return
	_assert_color(module_overlay_side_plan, "modulate", Color(1.0, 0.86, 0.22, 1.0), "selected module binding overlay side presentation")
	var hidden_overlay_side_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_overlay_side_presentation", false, Rect2(), "LEFT", false, false, 380)
	if bool(hidden_overlay_side_plan.get("visible", true)) or not bool(hidden_overlay_side_plan.get("disabled", false)) or hidden_overlay_side_plan.has("position"):
		_fail("UILifecycleService hidden module binding overlay side presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_module_binding_overlay_key_presentation("):
		_fail("UILifecycleService should expose editor module binding overlay key presentation planning.")
		return
	var module_overlay_key_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_overlay_key_presentation", true, 3, Rect2(Vector2(44.0, 72.0), Vector2(58.0, 24.0)), "L", true, false, 380)
	_assert_vector(module_overlay_key_plan, "position", Vector2(44.0, 72.0), "module binding overlay key presentation")
	_assert_vector(module_overlay_key_plan, "size", Vector2(58.0, 24.0), "module binding overlay key presentation")
	if not bool(module_overlay_key_plan.get("visible", false)) or bool(module_overlay_key_plan.get("disabled", true)) or String(module_overlay_key_plan.get("text", "")) != "3 L":
		_fail("UILifecycleService module binding overlay key text/state failed.")
		return
	if String(module_overlay_key_plan.get("tooltip", "")) != "Bind to attack key 3 (keyboard L)" or int(module_overlay_key_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_STOP or int(module_overlay_key_plan.get("z_index", -1)) != 380 or not bool(module_overlay_key_plan.get("move_to_front", false)):
		_fail("UILifecycleService module binding overlay key metadata failed.")
		return
	_assert_color(module_overlay_key_plan, "modulate", Color(1.0, 0.86, 0.22, 1.0), "selected module binding overlay key presentation")
	var hidden_overlay_key_plan: Dictionary = ui_lifecycle_service.call("editor_module_binding_overlay_key_presentation", false, 1, Rect2(), "J", false, true, 380)
	if bool(hidden_overlay_key_plan.get("visible", true)) or not bool(hidden_overlay_key_plan.get("disabled", false)) or hidden_overlay_key_plan.has("position"):
		_fail("UILifecycleService hidden module binding overlay key presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_sort_action_button_build_specs("):
		_fail("UILifecycleService should expose editor sort action button build specs.")
		return
	var sort_action_button_build_specs: Array = ui_lifecycle_service.call("editor_sort_action_button_build_specs")
	if sort_action_button_build_specs.size() != 3:
		_fail("UILifecycleService sort action button build spec count failed.")
		return
	var prev_sort_action_build_spec: Dictionary = Dictionary(sort_action_button_build_specs[0])
	var key_sort_action_build_spec: Dictionary = Dictionary(sort_action_button_build_specs[1])
	var dir_sort_action_build_spec: Dictionary = Dictionary(sort_action_button_build_specs[2])
	if String(prev_sort_action_build_spec.get("key", "")) != "sort_prev" or String(prev_sort_action_build_spec.get("intent", "")) != "cycle":
		_fail("UILifecycleService sort previous action identity failed.")
		return
	if int(prev_sort_action_build_spec.get("delta", 0)) != -1:
		_fail("UILifecycleService sort previous delta failed.")
		return
	if String(key_sort_action_build_spec.get("key", "")) != "sort_key" or String(key_sort_action_build_spec.get("intent", "")) != "toggle_menu":
		_fail("UILifecycleService sort key action identity failed.")
		return
	if String(dir_sort_action_build_spec.get("key", "")) != "sort_dir" or String(dir_sort_action_build_spec.get("intent", "")) != "toggle_direction":
		_fail("UILifecycleService sort direction action identity failed.")
		return
	_assert_vector(prev_sort_action_build_spec, "position", Vector2(936.0, 294.0), "sort action button build spec")
	_assert_vector(prev_sort_action_build_spec, "size", Vector2(24.0, 22.0), "sort action button build spec")
	_assert_vector(key_sort_action_build_spec, "size", Vector2(160.0, 22.0), "sort action button build spec")
	_assert_vector(dir_sort_action_build_spec, "position", Vector2(1100.0, 294.0), "sort action button build spec")
	if not ui_lifecycle_source.contains("static func editor_save_unit_dialog_build_specs("):
		_fail("UILifecycleService should expose editor save-unit dialog build specs.")
		return
	var save_unit_dialog_build_specs: Dictionary = ui_lifecycle_service.call("editor_save_unit_dialog_build_specs", ["hero", "offense", "barrier"])
	var save_unit_panel_build_spec: Dictionary = Dictionary(save_unit_dialog_build_specs.get("panel", {}))
	var save_unit_title_build_spec: Dictionary = Dictionary(save_unit_dialog_build_specs.get("title", {}))
	var save_unit_name_edit_build_spec: Dictionary = Dictionary(save_unit_dialog_build_specs.get("name_edit", {}))
	var save_unit_role_label_build_spec: Dictionary = Dictionary(save_unit_dialog_build_specs.get("role_label", {}))
	var save_unit_role_button_build_specs: Array = Array(save_unit_dialog_build_specs.get("role_buttons", []))
	var save_unit_action_button_build_specs: Array = Array(save_unit_dialog_build_specs.get("action_buttons", []))
	if String(save_unit_panel_build_spec.get("name", "")) != "SaveUnitNamePanel" or String(save_unit_title_build_spec.get("name", "")) != "SaveUnitNameLabel":
		_fail("UILifecycleService save-unit panel/title identity failed.")
		return
	if String(save_unit_name_edit_build_spec.get("name", "")) != "SaveUnitNameEdit" or String(save_unit_role_label_build_spec.get("name", "")) != "SaveUnitRoleLabel":
		_fail("UILifecycleService save-unit input/role label identity failed.")
		return
	if save_unit_role_button_build_specs.size() != 3 or save_unit_action_button_build_specs.size() != 3:
		_fail("UILifecycleService save-unit role/action button counts failed.")
		return
	_assert_vector(save_unit_panel_build_spec, "position", Vector2(390.0, 188.0), "save-unit panel build spec")
	_assert_vector(save_unit_panel_build_spec, "size", Vector2(474.0, 236.0), "save-unit panel build spec")
	_assert_vector(save_unit_title_build_spec, "position", Vector2(18.0, 14.0), "save-unit title build spec")
	_assert_vector(save_unit_name_edit_build_spec, "position", Vector2(18.0, 48.0), "save-unit name edit build spec")
	var third_save_unit_role_button_build_spec: Dictionary = Dictionary(save_unit_role_button_build_specs[2])
	var save_as_action_button_build_spec: Dictionary = Dictionary(save_unit_action_button_build_specs[1])
	if String(third_save_unit_role_button_build_spec.get("key", "")) != "barrier" or String(third_save_unit_role_button_build_spec.get("name", "")) != "SaveUnitRolebarrier":
		_fail("UILifecycleService save-unit role button identity failed.")
		return
	if String(save_as_action_button_build_spec.get("name", "")) != "save_name_save_as" or String(save_as_action_button_build_spec.get("action", "")) != "save_as":
		_fail("UILifecycleService save-unit action button identity failed.")
		return
	_assert_vector(third_save_unit_role_button_build_spec, "position", Vector2(314.0, 114.0), "save-unit role button build spec")
	_assert_vector(save_as_action_button_build_spec, "position", Vector2(168.0, 170.0), "save-unit action button build spec")
	if not ui_lifecycle_source.contains("static func editor_save_unit_name_panel_presentation("):
		_fail("UILifecycleService should expose editor save-unit name panel presentation planning.")
		return
	var visible_save_name_panel_plan: Dictionary = ui_lifecycle_service.call("editor_save_unit_name_panel_presentation", true)
	_assert_vector(visible_save_name_panel_plan, "position", Vector2(390.0, 188.0), "save-unit name panel presentation")
	_assert_vector(visible_save_name_panel_plan, "size", Vector2(474.0, 236.0), "save-unit name panel presentation")
	if not bool(visible_save_name_panel_plan.get("visible", false)) or not bool(visible_save_name_panel_plan.get("move_to_front", false)) or int(visible_save_name_panel_plan.get("z_index", -1)) != 295:
		_fail("UILifecycleService visible save-unit name panel presentation failed.")
		return
	var hidden_save_name_panel_plan: Dictionary = ui_lifecycle_service.call("editor_save_unit_name_panel_presentation", false)
	if bool(hidden_save_name_panel_plan.get("visible", true)) or bool(hidden_save_name_panel_plan.get("move_to_front", false)) or int(hidden_save_name_panel_plan.get("z_index", -1)) != 295:
		_fail("UILifecycleService hidden save-unit name panel presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_orientation_popup_build_specs("):
		_fail("UILifecycleService should expose editor orientation popup build specs.")
		return
	var orientation_popup_build_specs: Dictionary = ui_lifecycle_service.call("editor_orientation_popup_build_specs")
	var orientation_panel_build_spec: Dictionary = Dictionary(orientation_popup_build_specs.get("panel", {}))
	var orientation_label_build_spec: Dictionary = Dictionary(orientation_popup_build_specs.get("label", {}))
	var orientation_button_build_specs: Array = Array(orientation_popup_build_specs.get("buttons", []))
	if String(orientation_panel_build_spec.get("name", "")) != "ScytheSideMountChoicePopup" or String(orientation_label_build_spec.get("name", "")) != "ScytheSideMountChoiceLabel":
		_fail("UILifecycleService orientation popup panel/label identity failed.")
		return
	if orientation_button_build_specs.size() != 3:
		_fail("UILifecycleService orientation popup button count failed.")
		return
	var left_orientation_button_build_spec: Dictionary = Dictionary(orientation_button_build_specs[0])
	var right_orientation_button_build_spec: Dictionary = Dictionary(orientation_button_build_specs[1])
	var cancel_orientation_button_build_spec: Dictionary = Dictionary(orientation_button_build_specs[2])
	if String(left_orientation_button_build_spec.get("key", "")) != "left" or String(left_orientation_button_build_spec.get("name", "")) != "ScytheSideMountLeftButton":
		_fail("UILifecycleService orientation popup left button identity failed.")
		return
	if String(right_orientation_button_build_spec.get("key", "")) != "right" or String(right_orientation_button_build_spec.get("name", "")) != "ScytheSideMountRightButton":
		_fail("UILifecycleService orientation popup right button identity failed.")
		return
	if String(cancel_orientation_button_build_spec.get("key", "")) != "cancel" or String(cancel_orientation_button_build_spec.get("name", "")) != "ScytheSideMountLaterButton":
		_fail("UILifecycleService orientation popup cancel button identity failed.")
		return
	if int(orientation_panel_build_spec.get("z_index", -1)) != 272:
		_fail("UILifecycleService orientation popup z-index failed.")
		return
	_assert_vector(orientation_panel_build_spec, "size", Vector2(256.0, 86.0), "orientation popup panel build spec")
	_assert_vector(orientation_label_build_spec, "position", Vector2(10.0, 6.0), "orientation popup label build spec")
	_assert_vector(orientation_label_build_spec, "size", Vector2(236.0, 28.0), "orientation popup label build spec")
	_assert_vector(left_orientation_button_build_spec, "position", Vector2(10.0, 42.0), "orientation popup button build spec")
	_assert_vector(right_orientation_button_build_spec, "position", Vector2(102.0, 42.0), "orientation popup button build spec")
	_assert_vector(cancel_orientation_button_build_spec, "size", Vector2(52.0, 28.0), "orientation popup button build spec")
	if not ui_lifecycle_source.contains("static func editor_dashboard_controls_build_specs("):
		_fail("UILifecycleService should expose editor dashboard controls build specs.")
		return
	var dashboard_control_build_specs: Dictionary = ui_lifecycle_service.call("editor_dashboard_controls_build_specs")
	var power_dock_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("power_dock", {}))
	var board_title_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("board_title", {}))
	var board_hint_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("board_hint", {}))
	var legacy_power_button_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("legacy_power_button", {}))
	var torso_detail_button_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("torso_detail_button", {}))
	var legacy_power_summary_build_spec: Dictionary = Dictionary(dashboard_control_build_specs.get("legacy_power_summary", {}))
	if String(power_dock_build_spec.get("name", "")) != "UnitEditorPowerAllocationDock" or String(board_title_build_spec.get("name", "")) != "BoardTitle":
		_fail("UILifecycleService dashboard power dock/board title identity failed.")
		return
	if String(board_hint_build_spec.get("name", "")) != "BoardHint" or String(legacy_power_button_build_spec.get("name", "")) != "DashboardPowerAllocationButton":
		_fail("UILifecycleService dashboard hint/legacy button identity failed.")
		return
	if String(torso_detail_button_build_spec.get("name", "")) != "DashboardTorsoDetailButton" or String(legacy_power_summary_build_spec.get("name", "")) != "DashboardPowerAllocationSummary":
		_fail("UILifecycleService dashboard torso/summary identity failed.")
		return
	if int(power_dock_build_spec.get("z_index", -1)) != 254:
		_fail("UILifecycleService dashboard power dock z-index failed.")
		return
	_assert_vector(power_dock_build_spec, "position", Vector2(190.0, 24.0), "dashboard power dock build spec")
	_assert_vector(power_dock_build_spec, "size", Vector2(726.0, 132.0), "dashboard power dock build spec")
	_assert_vector(board_hint_build_spec, "position", Vector2(296.0, 72.0), "dashboard board hint build spec")
	_assert_vector(board_hint_build_spec, "size", Vector2(620.0, 18.0), "dashboard board hint build spec")
	_assert_vector(legacy_power_button_build_spec, "position", Vector2(52.0, 108.0), "dashboard legacy power button build spec")
	_assert_vector(legacy_power_button_build_spec, "size", Vector2(82.0, 24.0), "dashboard legacy power button build spec")
	_assert_vector(torso_detail_button_build_spec, "position", Vector2(228.0, 108.0), "dashboard torso detail button build spec")
	_assert_vector(torso_detail_button_build_spec, "size", Vector2(86.0, 24.0), "dashboard torso detail button build spec")
	_assert_vector(legacy_power_summary_build_spec, "position", Vector2(140.0, 109.0), "dashboard legacy summary build spec")
	_assert_vector(legacy_power_summary_build_spec, "size", Vector2(82.0, 22.0), "dashboard legacy summary build spec")
	if not ui_lifecycle_source.contains("static func editor_canvas_zoom_chrome_build_specs("):
		_fail("UILifecycleService should expose editor canvas/zoom chrome build specs.")
		return
	var canvas_zoom_chrome_build_specs: Dictionary = ui_lifecycle_service.call("editor_canvas_zoom_chrome_build_specs")
	var canvas_tools_title_build_spec: Dictionary = Dictionary(canvas_zoom_chrome_build_specs.get("canvas_tools_title", {}))
	var canvas_note_build_spec: Dictionary = Dictionary(canvas_zoom_chrome_build_specs.get("canvas_note", {}))
	var board_zoom_title_build_spec: Dictionary = Dictionary(canvas_zoom_chrome_build_specs.get("board_zoom_title", {}))
	var board_zoom_value_build_spec: Dictionary = Dictionary(canvas_zoom_chrome_build_specs.get("board_zoom_value", {}))
	if String(canvas_tools_title_build_spec.get("name", "")) != "CanvasToolsTitle" or String(canvas_note_build_spec.get("name", "")) != "CanvasTopologyText":
		_fail("UILifecycleService canvas chrome label identity failed.")
		return
	if String(board_zoom_title_build_spec.get("name", "")) != "BoardZoomTitle" or String(board_zoom_value_build_spec.get("name", "")) != "BoardZoomValue":
		_fail("UILifecycleService board zoom label identity failed.")
		return
	if String(board_zoom_value_build_spec.get("text", "")) != "100%":
		_fail("UILifecycleService board zoom default text failed.")
		return
	_assert_vector(canvas_tools_title_build_spec, "position", Vector2.ZERO, "canvas tools title build spec")
	_assert_vector(canvas_note_build_spec, "size", Vector2.ZERO, "canvas note build spec")
	_assert_vector(board_zoom_title_build_spec, "position", Vector2.ZERO, "board zoom title build spec")
	_assert_vector(board_zoom_value_build_spec, "position", Vector2(72.0, 656.0), "board zoom value build spec")
	_assert_vector(board_zoom_value_build_spec, "size", Vector2(54.0, 18.0), "board zoom value build spec")
	if not ui_lifecycle_source.contains("static func editor_shell_chrome_build_specs("):
		_fail("UILifecycleService should expose editor shell chrome build specs.")
		return
	var shell_chrome_build_specs: Dictionary = ui_lifecycle_service.call("editor_shell_chrome_build_specs")
	var editor_title_build_spec: Dictionary = Dictionary(shell_chrome_build_specs.get("title", {}))
	var editor_help_build_spec: Dictionary = Dictionary(shell_chrome_build_specs.get("help", {}))
	var editor_back_button_build_spec: Dictionary = Dictionary(shell_chrome_build_specs.get("back_button", {}))
	if String(editor_title_build_spec.get("name", "")) != "EditorTitle" or String(editor_help_build_spec.get("name", "")) != "EditorHelp":
		_fail("UILifecycleService editor shell label identity failed.")
		return
	if String(editor_back_button_build_spec.get("name", "")) != "EditorBackButton" or String(editor_back_button_build_spec.get("text", "")) != "选项":
		_fail("UILifecycleService editor shell back button identity failed.")
		return
	if String(editor_back_button_build_spec.get("token", "")) != "editor_options_button":
		_fail("UILifecycleService editor shell token contract failed.")
		return
	_assert_vector(editor_title_build_spec, "position", Vector2.ZERO, "editor title build spec")
	_assert_vector(editor_title_build_spec, "size", Vector2.ZERO, "editor title build spec")
	_assert_vector(editor_help_build_spec, "position", Vector2.ZERO, "editor help build spec")
	_assert_vector(editor_help_build_spec, "size", Vector2.ZERO, "editor help build spec")
	if not ui_lifecycle_source.contains("static func editor_auxiliary_chrome_build_specs("):
		_fail("UILifecycleService should expose editor auxiliary chrome build specs.")
		return
	var auxiliary_chrome_build_specs: Dictionary = ui_lifecycle_service.call("editor_auxiliary_chrome_build_specs")
	var assembly_guide_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("assembly_guide", {}))
	var legality_status_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("legality_status", {}))
	var tutorial_panel_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("assembly_tutorial_panel", {}))
	var tutorial_label_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("assembly_tutorial_label", {}))
	var perf_overlay_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("perf_overlay", {}))
	var save_feedback_build_spec: Dictionary = Dictionary(auxiliary_chrome_build_specs.get("save_feedback", {}))
	if String(assembly_guide_build_spec.get("name", "")) != "AssemblyGuideLabel" or String(legality_status_build_spec.get("name", "")) != "LegalityStatus":
		_fail("UILifecycleService auxiliary guide/status identity failed.")
		return
	if String(tutorial_panel_build_spec.get("name", "")) != "AssemblyTutorialPanel" or String(tutorial_label_build_spec.get("name", "")) != "AssemblyTutorialLabel":
		_fail("UILifecycleService auxiliary tutorial identity failed.")
		return
	if String(perf_overlay_build_spec.get("name", "")) != "TeamEditPerfOverlay" or String(save_feedback_build_spec.get("name", "")) != "SaveUnitFeedback":
		_fail("UILifecycleService auxiliary overlay/feedback identity failed.")
		return
	if int(tutorial_panel_build_spec.get("z_index", -1)) != 340 or int(tutorial_label_build_spec.get("z_index", -1)) != 341:
		_fail("UILifecycleService auxiliary tutorial z-index failed.")
		return
	if int(perf_overlay_build_spec.get("z_index", -1)) != 330 or int(save_feedback_build_spec.get("z_index", -1)) != 300:
		_fail("UILifecycleService auxiliary overlay/feedback z-index failed.")
		return
	_assert_vector(assembly_guide_build_spec, "position", Vector2(936.0, 118.0), "assembly guide build spec")
	_assert_vector(assembly_guide_build_spec, "size", Vector2(160.0, 22.0), "assembly guide build spec")
	_assert_vector(legality_status_build_spec, "position", Vector2(18.0, 616.0), "legality status build spec")
	_assert_vector(legality_status_build_spec, "size", Vector2(244.0, 32.0), "legality status build spec")
	_assert_vector(tutorial_panel_build_spec, "position", Vector2(194.0, 102.0), "assembly tutorial panel build spec")
	_assert_vector(tutorial_panel_build_spec, "size", Vector2(706.0, 66.0), "assembly tutorial panel build spec")
	_assert_vector(tutorial_label_build_spec, "position", Vector2(320.0, 108.0), "assembly tutorial label build spec")
	_assert_vector(tutorial_label_build_spec, "size", Vector2(568.0, 60.0), "assembly tutorial label build spec")
	_assert_vector(perf_overlay_build_spec, "position", Vector2(42.0, 86.0), "perf overlay build spec")
	_assert_vector(save_feedback_build_spec, "size", Vector2(622.0, 26.0), "save feedback build spec")
	if not ui_lifecycle_source.contains("static func editor_perf_overlay_presentation("):
		_fail("UILifecycleService should expose editor perf overlay presentation planning.")
		return
	var perf_overlay_visible_plan: Dictionary = ui_lifecycle_service.call("editor_perf_overlay_presentation", true, "TeamEdit PERF\nCPU tick: 1.25ms")
	_assert_vector(perf_overlay_visible_plan, "position", Vector2(42.0, 86.0), "perf overlay presentation")
	_assert_vector(perf_overlay_visible_plan, "size", Vector2(330.0, 180.0), "perf overlay presentation")
	if not bool(perf_overlay_visible_plan.get("visible", false)) or String(perf_overlay_visible_plan.get("text", "")) != "TeamEdit PERF\nCPU tick: 1.25ms":
		_fail("UILifecycleService visible perf overlay presentation visibility/text failed.")
		return
	if int(perf_overlay_visible_plan.get("z_index", -1)) != 330 or int(perf_overlay_visible_plan.get("autowrap_mode", -1)) != TextServer.AUTOWRAP_WORD_SMART:
		_fail("UILifecycleService visible perf overlay presentation z-index/autowrap failed.")
		return
	var perf_overlay_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_perf_overlay_presentation", false, "")
	if bool(perf_overlay_hidden_plan.get("visible", true)) or int(perf_overlay_hidden_plan.get("z_index", -1)) != 330 or int(perf_overlay_hidden_plan.get("autowrap_mode", -1)) != TextServer.AUTOWRAP_WORD_SMART:
		_fail("UILifecycleService hidden perf overlay presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_save_unit_feedback_presentation("):
		_fail("UILifecycleService should expose editor save-unit feedback presentation planning.")
		return
	var save_feedback_plan: Dictionary = ui_lifecycle_service.call("editor_save_unit_feedback_presentation")
	_assert_vector(save_feedback_plan, "position", Vector2(270.0, 654.0), "save feedback presentation")
	_assert_vector(save_feedback_plan, "size", Vector2(622.0, 26.0), "save feedback presentation")
	if int(save_feedback_plan.get("autowrap_mode", -1)) != TextServer.AUTOWRAP_OFF or not bool(save_feedback_plan.get("clip_text", false)) or int(save_feedback_plan.get("text_overrun_behavior", -1)) != TextServer.OVERRUN_TRIM_ELLIPSIS:
		_fail("UILifecycleService save-unit feedback text layout presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_overlay_view_build_specs("):
		_fail("UILifecycleService should expose editor overlay view build specs.")
		return
	var overlay_view_build_specs: Dictionary = ui_lifecycle_service.call("editor_overlay_view_build_specs")
	var stats_rail_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("stats_rail", {}))
	var hover_popup_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("hover_popup", {}))
	var unit_hover_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("unit_hover", {}))
	var torso_detail_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("torso_detail", {}))
	var engine_allocation_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("engine_allocation", {}))
	var drag_ghost_build_spec: Dictionary = Dictionary(overlay_view_build_specs.get("drag_ghost", {}))
	if String(stats_rail_build_spec.get("name", "")) != "EditorStatsRail" or String(hover_popup_build_spec.get("name", "")) != "EditorPartHoverPopup":
		_fail("UILifecycleService overlay stats/hover identity failed.")
		return
	if String(unit_hover_build_spec.get("name", "")) != "EditorUnitHoverPreview" or String(torso_detail_build_spec.get("name", "")) != "EditorTorsoDetail":
		_fail("UILifecycleService overlay unit/torso identity failed.")
		return
	if String(engine_allocation_build_spec.get("name", "")) != "EngineMomentumAllocationPanel" or String(drag_ghost_build_spec.get("name", "")) != "EditorPartDragGhost":
		_fail("UILifecycleService overlay engine/drag identity failed.")
		return
	if int(hover_popup_build_spec.get("z_index", -1)) != 260 or int(unit_hover_build_spec.get("z_index", -1)) != 255:
		_fail("UILifecycleService hover overlay z-index failed.")
		return
	if int(torso_detail_build_spec.get("z_index", -1)) != 285 or int(engine_allocation_build_spec.get("z_index", -1)) != 290 or int(drag_ghost_build_spec.get("z_index", -1)) != 250:
		_fail("UILifecycleService detail overlay z-index failed.")
		return
	if not bool(engine_allocation_build_spec.get("mirror_board_rect", false)):
		_fail("UILifecycleService engine allocation should preserve board-rect mirroring intent.")
		return
	if not ui_lifecycle_source.contains("static func editor_stats_rail_view_presentation("):
		_fail("UILifecycleService should expose editor stats rail view presentation planning.")
		return
	var stats_rail_visible_plan: Dictionary = ui_lifecycle_service.call("editor_stats_rail_view_presentation", true)
	_assert_vector(stats_rail_visible_plan, "position", Vector2(18.0, 104.0), "stats rail presentation")
	_assert_vector(stats_rail_visible_plan, "size", Vector2(164.0, 508.0), "stats rail presentation")
	if not bool(stats_rail_visible_plan.get("visible", false)) or int(stats_rail_visible_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_STOP:
		_fail("UILifecycleService visible stats rail presentation failed.")
		return
	var stats_rail_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_stats_rail_view_presentation", false)
	if bool(stats_rail_hidden_plan.get("visible", true)) or int(stats_rail_hidden_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_STOP:
		_fail("UILifecycleService hidden stats rail presentation failed.")
		return
	if not ui_lifecycle_source.contains("static func editor_drag_ghost_view_presentation("):
		_fail("UILifecycleService should expose editor drag ghost view presentation planning.")
		return
	var drag_ghost_visible_plan: Dictionary = ui_lifecycle_service.call("editor_drag_ghost_view_presentation", true, Vector2(120.0, 88.0), true)
	_assert_vector(drag_ghost_visible_plan, "position", Vector2(120.0, 88.0), "drag ghost presentation")
	if not bool(drag_ghost_visible_plan.get("visible", false)) or not bool(drag_ghost_visible_plan.get("move_to_front", false)):
		_fail("UILifecycleService visible drag ghost presentation visibility/front-order failed.")
		return
	if int(drag_ghost_visible_plan.get("z_index", -1)) != 250 or int(drag_ghost_visible_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_IGNORE:
		_fail("UILifecycleService visible drag ghost presentation z-index/mouse-filter failed.")
		return
	_assert_color(drag_ghost_visible_plan, "modulate", Color(1.0, 1.0, 1.0, 0.55), "drag ghost presentation")
	var drag_ghost_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_drag_ghost_view_presentation", false, Vector2.INF, false)
	if bool(drag_ghost_hidden_plan.get("visible", true)) or bool(drag_ghost_hidden_plan.get("move_to_front", false)):
		_fail("UILifecycleService hidden drag ghost presentation failed.")
		return
	if int(drag_ghost_hidden_plan.get("z_index", -1)) != 250 or int(drag_ghost_hidden_plan.get("mouse_filter", -1)) != Control.MOUSE_FILTER_IGNORE:
		_fail("UILifecycleService hidden drag ghost presentation z-index/mouse-filter failed.")
		return
	_assert_vector(stats_rail_build_spec, "position", Vector2(18.0, 104.0), "stats rail build spec")
	_assert_vector(stats_rail_build_spec, "size", Vector2(164.0, 508.0), "stats rail build spec")
	_assert_vector(hover_popup_build_spec, "position", Vector2(410.0, 124.0), "hover popup build spec")
	_assert_vector(hover_popup_build_spec, "size", Vector2(466.0, 500.0), "hover popup build spec")
	if not ui_lifecycle_source.contains("static func editor_part_hover_popup_presentation("):
		_fail("UILifecycleService should expose editor part hover popup presentation planning.")
		return
	var hover_popup_visible_plan: Dictionary = ui_lifecycle_service.call("editor_part_hover_popup_presentation", true, false, false, Vector2.INF)
	_assert_vector(hover_popup_visible_plan, "position", Vector2(410.0, 124.0), "part hover popup presentation")
	_assert_vector(hover_popup_visible_plan, "size", Vector2(466.0, 500.0), "part hover popup presentation")
	if not bool(hover_popup_visible_plan.get("visible", false)) or not bool(hover_popup_visible_plan.get("move_to_front", false)) or int(hover_popup_visible_plan.get("z_index", -1)) != 260:
		_fail("UILifecycleService visible part hover popup presentation failed.")
		return
	var hover_popup_pinned_plan: Dictionary = ui_lifecycle_service.call("editor_part_hover_popup_presentation", true, true, true, Vector2(720.0, 96.0))
	_assert_vector(hover_popup_pinned_plan, "position", Vector2(720.0, 96.0), "pinned part hover popup presentation")
	_assert_vector(hover_popup_pinned_plan, "size", Vector2(506.0, 560.0), "pinned part hover popup presentation")
	if int(hover_popup_pinned_plan.get("z_index", -1)) != 340:
		_fail("UILifecycleService pinned part hover popup z-index failed.")
		return
	var hover_popup_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_part_hover_popup_presentation", false, false, false, Vector2.INF)
	if bool(hover_popup_hidden_plan.get("visible", true)) or bool(hover_popup_hidden_plan.get("move_to_front", false)) or int(hover_popup_hidden_plan.get("z_index", -1)) != 260:
		_fail("UILifecycleService hidden part hover popup presentation failed.")
		return
	_assert_vector(unit_hover_build_spec, "position", Vector2(410.0, 118.0), "unit hover build spec")
	_assert_vector(unit_hover_build_spec, "size", Vector2(466.0, 500.0), "unit hover build spec")
	if not ui_lifecycle_source.contains("static func editor_unit_hover_view_presentation("):
		_fail("UILifecycleService should expose editor unit hover view presentation planning.")
		return
	var unit_hover_visible_plan: Dictionary = ui_lifecycle_service.call("editor_unit_hover_view_presentation", true)
	_assert_vector(unit_hover_visible_plan, "position", Vector2(410.0, 118.0), "unit hover presentation")
	_assert_vector(unit_hover_visible_plan, "size", Vector2(466.0, 500.0), "unit hover presentation")
	if not bool(unit_hover_visible_plan.get("visible", false)) or not bool(unit_hover_visible_plan.get("move_to_front", false)) or int(unit_hover_visible_plan.get("z_index", -1)) != 255:
		_fail("UILifecycleService visible unit hover presentation failed.")
		return
	var unit_hover_hidden_plan: Dictionary = ui_lifecycle_service.call("editor_unit_hover_view_presentation", false)
	if bool(unit_hover_hidden_plan.get("visible", true)) or bool(unit_hover_hidden_plan.get("move_to_front", false)):
		_fail("UILifecycleService hidden unit hover presentation failed.")
		return
	_assert_vector(torso_detail_build_spec, "position", Vector2(18.0, 338.0), "torso detail build spec")
	_assert_vector(torso_detail_build_spec, "size", Vector2(888.0, 346.0), "torso detail build spec")
	Dictionary(Array(build_specs.get("canvas_tools", []))[0])["key"] = "mutated"
	var fresh_build_specs: Dictionary = UILifecycleService.editor_action_build_specs()
	if String(Dictionary(Array(fresh_build_specs.get("canvas_tools", []))[0]).get("key", "")) != "blank_canvas":
		_fail("UILifecycleService should return fresh editor action build specs.")
		return
	var panel_role_plan: Dictionary = UILifecycleService.editor_panel_role_chrome_presentation(
		"parts",
		"barrier",
		true,
		["load", "parts", "mystery"],
		["pilot", "barrier"],
		["pilot", "barrier"],
		{"pilot": "驾驶", "barrier": "屏障"},
		true
	)
	var panel_buttons: Dictionary = Dictionary(panel_role_plan.get("panel_buttons", {}))
	var load_panel_button: Dictionary = Dictionary(panel_buttons.get("load", {}))
	var parts_panel_button: Dictionary = Dictionary(panel_buttons.get("parts", {}))
	var mystery_panel_button: Dictionary = Dictionary(panel_buttons.get("mystery", {}))
	if String(load_panel_button.get("text", "")) != "单位库" or String(parts_panel_button.get("text", "")) != "零件库" or String(mystery_panel_button.get("text", "")) != "MYSTERY":
		_fail("UILifecycleService panel chrome text contract failed.")
		return
	_assert_color(parts_panel_button, "modulate", Color(0.35, 0.95, 1.0, 1.0), "active panel chrome")
	_assert_color(load_panel_button, "modulate", Color(0.86, 0.9, 0.94, 1.0), "inactive panel chrome")
	var role_buttons: Dictionary = Dictionary(panel_role_plan.get("role_buttons", {}))
	var barrier_role_button: Dictionary = Dictionary(role_buttons.get("barrier", {}))
	if bool(barrier_role_button.get("visible", true)) or not bool(barrier_role_button.get("disabled", false)) or String(barrier_role_button.get("text", "")) != "身份:屏障":
		_fail("UILifecycleService role chrome hidden/text contract failed.")
		return
	_assert_vector(barrier_role_button, "position", Vector2(1028.0, 118.0), "role chrome presentation")
	_assert_vector(barrier_role_button, "size", Vector2(86.0, 24.0), "role chrome presentation")
	_assert_color(barrier_role_button, "modulate", Color(0.35, 0.95, 1.0, 1.0), "selected role chrome")
	var hidden_panel_role_plan: Dictionary = UILifecycleService.editor_panel_role_chrome_presentation("load", "pilot", false, ["load"], ["pilot"], ["pilot"], {"pilot": "PILOT"}, false)
	var hidden_pilot_button: Dictionary = Dictionary(Dictionary(hidden_panel_role_plan.get("role_buttons", {})).get("pilot", {}))
	if String(hidden_pilot_button.get("text", "")) != "ROLE:PILOT":
		_fail("UILifecycleService english role chrome text failed.")
		return
	_assert_vector(hidden_pilot_button, "position", Vector2(936.0, 212.0), "hidden role chrome presentation")
	_assert_vector(hidden_pilot_button, "size", Vector2(86.0, 32.0), "hidden role chrome presentation")
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
	var slot_button_plan: Dictionary = UILifecycleService.editor_slot_button_presentation()
	if bool(slot_button_plan.get("visible", true)) or not bool(slot_button_plan.get("disabled", false)):
		_fail("UILifecycleService slot button presentation should keep legacy slot buttons hidden.")
		return
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
	_assert_vector(Dictionary(stats_info_plan.get("stats", {})), "position", Vector2(936.0, 484.0), "info stats presentation")
	_assert_vector(Dictionary(stats_info_plan.get("detail", {})), "size", Vector2(270.0, 72.0), "info detail presentation")
	_assert_vector(Dictionary(stats_info_plan.get("battle_preview", {})), "position", Vector2(936.0, 278.0), "info battle preview presentation")
	_assert_vector(Dictionary(stats_info_plan.get("component_art", {})), "size", Vector2(270.0, 68.0), "info component art presentation")
	if not bool(Dictionary(stats_info_plan.get("structure_reference_view", {})).get("visible", false)) or bool(Dictionary(stats_info_plan.get("structure_reference_label", {})).get("visible", true)):
		_fail("UILifecycleService structure reference preservation contract failed.")
		return
	_assert_vector(Dictionary(stats_info_plan.get("structure_reference_view", {})), "position", Vector2(936.0, 146.0), "info structure view presentation")
	_assert_vector(Dictionary(stats_info_plan.get("structure_reference_label", {})), "size", Vector2(270.0, 18.0), "info structure label presentation")
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
	var picker_colors: Dictionary = Dictionary(color_plan.get("picker_colors", {}))
	_assert_color(picker_colors, "primary", Color(0.0, 1.0, 0.0, 1.0), "color picker sync colors")
	_assert_color(picker_colors, "accent", Color(0.0, 0.0, 0.0, 1.0), "color picker sync colors")
	var hidden_color_plan: Dictionary = UILifecycleService.editor_color_controls_presentation(false, 1, "Azure", 0, color_presets, 1, false)
	if bool(Dictionary(hidden_color_plan.get("panel", {})).get("visible", true)) or not bool(Dictionary(Array(hidden_color_plan.get("buttons", []))[0]).get("disabled", false)) or bool(Dictionary(hidden_color_plan.get("primary_picker", {})).get("visible", true)):
		_fail("UILifecycleService hidden color controls contract failed.")
		return
	var section_chrome_plan: Dictionary = UILifecycleService.editor_section_chrome_presentation(true, true, true, true)
	var section_labels: Dictionary = Dictionary(section_chrome_plan.get("labels", {}))
	var catalog_label: Dictionary = Dictionary(section_labels.get("catalog", {}))
	var shop_label: Dictionary = Dictionary(section_labels.get("shop", {}))
	var template_label: Dictionary = Dictionary(section_labels.get("template", {}))
	if not bool(catalog_label.get("visible", false)) or String(catalog_label.get("text", "")) != "零件卡片":
		_fail("UILifecycleService catalog section chrome contract failed.")
		return
	if bool(shop_label.get("visible", true)) or String(shop_label.get("text", "")) != "零件库：悬停显示完整卡片":
		_fail("UILifecycleService shop section chrome contract failed.")
		return
	if not bool(template_label.get("visible", false)):
		_fail("UILifecycleService template section visibility contract failed.")
		return
	var template_toggle: Dictionary = Dictionary(section_chrome_plan.get("template_toggle", {}))
	if bool(template_toggle.get("visible", true)) or String(template_toggle.get("text", "")) != "模板抽屉":
		_fail("UILifecycleService template toggle chrome contract failed.")
		return
	if not bool(section_chrome_plan.get("template_drawer_visible", false)):
		_fail("UILifecycleService template drawer open visibility contract failed.")
		return
	var hidden_section_chrome_plan: Dictionary = UILifecycleService.editor_section_chrome_presentation(false, true, false, false)
	var hidden_labels: Dictionary = Dictionary(hidden_section_chrome_plan.get("labels", {}))
	if bool(Dictionary(hidden_labels.get("catalog", {})).get("visible", true)) or String(Dictionary(hidden_labels.get("catalog", {})).get("text", "")) != "PART CARDS" or bool(Dictionary(hidden_labels.get("template", {})).get("visible", true)):
		_fail("UILifecycleService hidden section chrome contract failed.")
		return
	var catalog_shop_plan: Dictionary = UILifecycleService.editor_catalog_shop_surface_presentation(true, false, false, true, [true, false, true], ["core", "limb"])
	var catalog_buttons: Array = Array(catalog_shop_plan.get("catalog_buttons", []))
	if catalog_buttons.size() != 3 or not bool(Dictionary(catalog_buttons[0]).get("visible", false)) or bool(Dictionary(catalog_buttons[1]).get("visible", true)) or not bool(Dictionary(catalog_buttons[2]).get("visible", false)):
		_fail("UILifecycleService catalog button surface contract failed.")
		return
	var shop_buttons: Dictionary = Dictionary(catalog_shop_plan.get("shop_buttons", {}))
	var core_shop_button: Dictionary = Dictionary(shop_buttons.get("core", {}))
	if bool(core_shop_button.get("visible", true)) or not bool(core_shop_button.get("disabled", false)):
		_fail("UILifecycleService hidden shop button surface contract failed.")
		return
	if bool(Dictionary(catalog_shop_plan.get("shop_backdrop", {})).get("visible", true)):
		_fail("UILifecycleService hidden shop backdrop contract failed.")
		return
	if bool(catalog_shop_plan.get("clear_catalog_hover", true)) or not bool(catalog_shop_plan.get("clear_unit_hover", false)):
		_fail("UILifecycleService hover clear surface contract failed.")
		return
	var open_shop_plan: Dictionary = UILifecycleService.editor_catalog_shop_surface_presentation(false, true, true, true, [true, false], ["core"])
	if bool(Dictionary(Array(open_shop_plan.get("catalog_buttons", []))[0]).get("visible", true)) or not bool(Dictionary(Dictionary(open_shop_plan.get("shop_buttons", {})).get("core", {})).get("visible", false)) or bool(Dictionary(Dictionary(open_shop_plan.get("shop_buttons", {})).get("core", {})).get("disabled", true)) or not bool(Dictionary(open_shop_plan.get("shop_backdrop", {})).get("visible", false)) or bool(open_shop_plan.get("clear_catalog_hover", true)) or bool(open_shop_plan.get("clear_unit_hover", true)):
		_fail("UILifecycleService open shop surface contract failed.")
		return
	var blocked_shop_plan: Dictionary = UILifecycleService.editor_catalog_shop_surface_presentation(false, true, false, false, [true], ["core"])
	if bool(Dictionary(Dictionary(blocked_shop_plan.get("shop_buttons", {})).get("core", {})).get("visible", true)) or not bool(Dictionary(Dictionary(blocked_shop_plan.get("shop_buttons", {})).get("core", {})).get("disabled", false)):
		_fail("UILifecycleService body-disabled shop surface contract failed.")
		return
	if not assembly_lifecycle_service.has_method("editor_board_hint_presentation"):
		_fail("UILifecycleService should expose editor board hint presentation planning.")
		return
	var custom_hint_plan: Dictionary = assembly_lifecycle_service.call("editor_board_hint_presentation", "custom", {
		"short_node_label": "LEFT SCYTHE",
		"node_number": 2,
		"node_count": 4,
		"module_count": 3,
		"selected_summary": "mass ok",
		"pending_canvas_name": "爪刃",
		"pending_payload_name": "核心软件",
		"orientation_choice_active": true,
	}, true)
	if String(custom_hint_plan.get("text", "")) != "规则正常  LEFT SCYTHE 2/4  模块x3  mass ok  待放置: 爪刃  待安装: 核心软件  选侧挂刃: 左/右":
		_fail("UILifecycleService custom board hint contract failed.")
		return
	var invalid_custom_hint_plan: Dictionary = assembly_lifecycle_service.call("editor_board_hint_presentation", "custom", {
		"topology_invalid": true,
		"short_node_label": "NODE",
		"node_number": 1,
		"node_count": 1,
		"module_count": 1,
		"selected_handedness_active": true,
		"selected_side": "right",
	}, false)
	if String(invalid_custom_hint_plan.get("text", "")) != "INVALID TOPOLOGY  NODE 1/1  MODx1  side:RIGHT":
		_fail("UILifecycleService invalid custom board hint contract failed.")
		return
	var barrier_hint_plan: Dictionary = assembly_lifecycle_service.call("editor_board_hint_presentation", "barrier", {
		"tile_count": 3,
		"material_slots": 5,
		"width": 2.0,
		"height": 1.5,
		"pending_canvas_name": "屏障",
		"pending_payload_name": "插件",
	}, true)
	if String(barrier_hint_plan.get("text", "")) != "以太屏幕蓝图 3/5  2.0x1.5  待放置:屏障  待安装:插件":
		_fail("UILifecycleService barrier board hint contract failed.")
		return
	var body_hint_plan: Dictionary = assembly_lifecycle_service.call("editor_board_hint_presentation", "body", {}, false)
	if String(body_hint_plan.get("text", "")) != "FREE CANVAS READY: drag parts in; double-click core for details, single-click to drag.":
		_fail("UILifecycleService body board hint contract failed.")
		return
	var inactive_hint_plan: Dictionary = assembly_lifecycle_service.call("editor_board_hint_presentation", "inactive", {}, true)
	if String(inactive_hint_plan.get("text", "")) != "机体画布未启用":
		_fail("UILifecycleService inactive board hint contract failed.")
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
