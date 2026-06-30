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
