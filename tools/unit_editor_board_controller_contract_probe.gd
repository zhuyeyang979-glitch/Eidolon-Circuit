extends SceneTree

const CONTROLLER_PATH := "res://scripts/controllers/unit_editor_board_controller.gd"
const MAIN_PATH := "res://scripts/main.gd"
const UnitEditorBoardControllerScript := preload("res://scripts/controllers/unit_editor_board_controller.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _init() -> void:
	if not FileAccess.file_exists(CONTROLLER_PATH):
		_fail("Missing UnitEditorBoardController script.")
	var controller_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(CONTROLLER_PATH))
	for token in [
		"class_name UnitEditorBoardController",
		"route_board_input_event",
		"zoom_input_allowed",
		"node_drag_release_intent",
		"whole_drag_release_intent",
			"selection_box_release_intent",
			"custom_topology_click_intent",
			"selected_node_feedback",
			"clipboard_shortcut_intent",
		"update_pose_drag",
		"update_selection_box",
		"move_selected_nodes",
		"move_single_node",
		"move_whole_unit",
		"torso_hover",
		"finish_pose_drag",
		"finish_selection_box",
		"finish_node_drag",
		"finish_whole_drag",
		"zoom_wheel",
		"barrier_board_click",
		"custom_topology_click",
		"legacy_body_socket_click",
		"copy_selection",
		"cut_selection",
		"paste_selection",
		"selection_no_topology",
		"complete_module_binding",
		"empty_selection",
		"pose_chain_selected",
		"pose_invalid_selection",
		"layout_whole_rigid",
		"layout_connected_hint",
		"layout_loose_group",
		"binding_cancel",
		"binding_complete",
		"binding_invalid",
		"start_selection_box",
		"unlink_edge",
		"unlink_node",
		"right_click_unlink_miss",
		"place_pending_part",
		"open_torso_detail",
		"start_unconnected_drag",
		"start_pose_drag",
		"pose_drag_invalid",
		"start_group_drag",
		"layout_connected_selection_reject",
		"layout_connected_part_reject",
		"start_loose_drag",
		"blank_canvas_select_box",
		"blank_canvas_hint",
		"reject_reason",
		"hint_key",
	]:
		if controller_source.find(token) < 0:
			_fail("UnitEditorBoardController missing token: %s" % token)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const UnitEditorBoardController = preload(\"res://scripts/controllers/unit_editor_board_controller.gd\")",
		"var unit_editor_board_controller: UnitEditorBoardController",
		"unit_editor_board_controller = UnitEditorBoardController.new()",
		"unit_editor_board_controller.route_board_input_event",
		"unit_editor_board_controller.zoom_input_allowed",
		"unit_editor_board_controller.node_drag_release_intent",
		"unit_editor_board_controller.whole_drag_release_intent",
			"unit_editor_board_controller.selection_box_release_intent",
			"unit_editor_board_controller.custom_topology_click_intent",
			"unit_editor_board_controller.selected_node_feedback",
			"unit_editor_board_controller.clipboard_shortcut_intent",
		"_editor_board_input_context",
		"_dispatch_editor_board_input_route",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate board controller boundary token: %s" % token)
	var controller = UnitEditorBoardControllerScript.new()
	var base_context := {
		"role_uses_body_board": true,
		"has_custom_topology": true,
		"is_barrier_without_topology": false,
		"pose_dragging": false,
		"selecting_topology_box": false,
		"dragging_node_index": -1,
		"dragging_selected_nodes": false,
		"dragging_whole_unit": false,
	}
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), base_context, "torso_hover")
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), _with(base_context, {"pose_dragging": true}), "update_pose_drag")
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), _with(base_context, {"selecting_topology_box": true}), "update_selection_box")
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), _with(base_context, {"dragging_node_index": 3}), "move_single_node")
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), _with(base_context, {"dragging_node_index": 3, "dragging_selected_nodes": true}), "move_selected_nodes")
	_assert_action(controller, _motion(Vector2(20.0, 30.0)), _with(base_context, {"dragging_whole_unit": true}), "move_whole_unit")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, false), _with(base_context, {"pose_dragging": true}), "finish_pose_drag")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, false), _with(base_context, {"selecting_topology_box": true}), "finish_selection_box")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, false), _with(base_context, {"dragging_node_index": 2}), "finish_node_drag")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, false), _with(base_context, {"dragging_whole_unit": true}), "finish_whole_drag")
	_assert_action(controller, _button(MOUSE_BUTTON_RIGHT, false), _with(base_context, {"dragging_node_index": 2}), "none")
	_assert_action(controller, _button(MOUSE_BUTTON_WHEEL_UP, true), base_context, "zoom_wheel")
	for busy_context in [
		{"pose_dragging": true},
		{"selecting_topology_box": true},
		{"dragging_node_index": 1},
		{"dragging_whole_unit": true},
	]:
		var next_context := _with(base_context, busy_context)
		if controller.zoom_input_allowed(next_context):
			_fail("zoom_input_allowed should reject busy board context: %s" % str(busy_context))
		_assert_action(controller, _button(MOUSE_BUTTON_WHEEL_UP, true), next_context, "none")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, true), _with(base_context, {"is_barrier_without_topology": true, "role_uses_body_board": false, "has_custom_topology": false}), "barrier_board_click")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, true), base_context, "custom_topology_click")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, true), _with(base_context, {"has_custom_topology": false}), "legacy_body_socket_click")
	_assert_action(controller, _button(MOUSE_BUTTON_LEFT, true), _with(base_context, {"role_uses_body_board": false, "has_custom_topology": false}), "none")
	_assert_action(controller, InputEventKey.new(), base_context, "none")
	_assert_clipboard_shortcut(controller, _key(KEY_C, true), base_context, "copy_selection")
	_assert_clipboard_shortcut(controller, _key(KEY_X, true), base_context, "cut_selection")
	_assert_clipboard_shortcut(controller, _key(KEY_V, true), base_context, "paste_selection")
	_assert_clipboard_shortcut(controller, _key(KEY_C, false), base_context, "none")
	_assert_clipboard_shortcut(controller, _key(KEY_C, true), _with(base_context, {"busy": true}), "none")
	_assert_clipboard_shortcut(controller, _key(KEY_C, true), _with(base_context, {"role_uses_body_board": false}), "none")
	_assert_clipboard_shortcut(controller, _key(KEY_C, true), _with(base_context, {"has_custom_topology": false}), "none")
	_assert_selected_node_feedback(
		controller,
		{
			"valid": true,
			"zh": false,
			"slot_key": "limb_muscle",
			"slot_label": "LIMB MUSCLE",
			"part_name": "TEST LIMB",
			"node_index": 1,
			"node_count": 3,
			"module_count": 0,
			"edge_count": 1,
			"is_torso": false,
			"board_tool": "layout",
		},
		"switch_pose_for_connected",
		"NODE ",
		["SELECTED LIMB MUSCLE", "POSE"]
	)
	_assert_selected_node_feedback(
		controller,
		{
			"valid": true,
			"zh": true,
			"slot_key": "muscle",
			"slot_label": "躯干肌肉",
				"part_name": "CORE",
				"selected_label": "选中",
				"shop_marker": "当前节点 ",
				"action_hints": {"open_torso_detail": "双击详情"},
				"node_index": 0,
			"node_count": 2,
			"module_count": 2,
			"edge_count": 2,
			"is_torso": true,
			"board_tool": "layout",
		},
		"open_torso_detail",
		"当前节点 ",
		["选中 躯干肌肉", "双击详情"]
	)
	_assert_selected_node_feedback(
		controller,
		{
			"valid": true,
			"zh": false,
			"slot_key": "joint",
			"slot_label": "JOINT",
			"part_name": "LOOSE JOINT",
			"node_index": 2,
			"node_count": 3,
			"module_count": 0,
			"edge_count": 0,
			"is_torso": false,
			"board_tool": "layout",
		},
		"drag_loose_part",
		"NODE ",
		["SELECTED JOINT", "drag loose"]
	)
	if controller.has_method("selected_node_feedback"):
		var empty_feedback: Dictionary = controller.selected_node_feedback({"valid": false})
		if bool(empty_feedback.get("valid", true)):
			_fail("selected_node_feedback should mark empty selection invalid, got %s." % str(empty_feedback))
	else:
		_fail("selected_node_feedback method missing.")
	_assert_node_release_intent(
		controller,
		_with(base_context, {
			"dragging_node_index": 2,
			"dragging_selected_nodes": false,
			"selected_topology_nodes": [2],
			"node_click_candidate_index": 2,
			"node_click_moved": false,
			"dragged_node_edge_count": 0,
			"dragged_node_is_torso": false,
			"release_distance_from_click_start": 2.0,
		}),
		{"should_try_magnetic_link": true, "show_detail_after_release": true, "was_group_dragging": false, "released_node_index": 2, "released_group_nodes": [2]}
	)
	_assert_node_release_intent(
		controller,
		_with(base_context, {
			"dragging_node_index": 2,
			"dragging_selected_nodes": false,
			"selected_topology_nodes": [2],
			"node_click_candidate_index": 2,
			"node_click_moved": false,
			"dragged_node_edge_count": 1,
			"dragged_node_is_torso": false,
			"release_distance_from_click_start": 2.0,
		}),
		{"should_try_magnetic_link": false, "show_detail_after_release": true}
	)
	_assert_node_release_intent(
		controller,
		_with(base_context, {
			"dragging_node_index": 1,
			"dragging_selected_nodes": false,
			"node_click_candidate_index": 1,
			"node_click_moved": false,
			"dragged_node_edge_count": 0,
			"dragged_node_is_torso": true,
			"release_distance_from_click_start": 2.0,
		}),
		{"should_try_magnetic_link": true, "show_detail_after_release": false}
	)
	_assert_node_release_intent(
		controller,
		_with(base_context, {
			"dragging_node_index": 1,
			"dragging_selected_nodes": false,
			"node_click_candidate_index": 1,
			"node_click_moved": true,
			"dragged_node_edge_count": 0,
			"dragged_node_is_torso": false,
			"release_distance_from_click_start": 12.0,
		}),
		{"should_try_magnetic_link": true, "show_detail_after_release": false}
	)
	_assert_node_release_intent(
		controller,
		_with(base_context, {
			"dragging_node_index": 4,
			"dragging_selected_nodes": true,
			"selected_topology_nodes": [4, 5, 6],
			"node_click_candidate_index": 4,
			"node_click_moved": true,
			"dragged_node_edge_count": 0,
			"dragged_node_is_torso": false,
			"release_distance_from_click_start": 20.0,
		}),
		{"should_try_magnetic_link": false, "show_detail_after_release": false, "was_group_dragging": true, "released_group_nodes": [4, 5, 6]}
	)
	var whole_intent: Dictionary = controller.whole_drag_release_intent(_with(base_context, {"topology_node_count": 4}))
	if whole_intent.get("changed_nodes", []) != [0, 1, 2, 3]:
		_fail("whole_drag_release_intent should return all topology node indices, got %s." % str(whole_intent))
	_assert_selection_release_intent(
		controller,
		{"has_custom_topology": false, "selected_nodes": [1]},
		{"action": "selection_no_topology", "selected_nodes": []}
	)
	_assert_selection_release_intent(
		controller,
		{"has_custom_topology": true, "selected_nodes": [1, 2], "pending_module_binding": true, "board_tool": "layout"},
		{"action": "complete_module_binding", "selected_nodes": [1, 2]}
	)
	_assert_selection_release_intent(
		controller,
		{"has_custom_topology": true, "selected_nodes": [], "pending_module_binding": false, "board_tool": "layout"},
		{"action": "empty_selection", "selected_nodes": []}
	)
	_assert_selection_release_intent(
		controller,
		{
			"has_custom_topology": true,
			"selected_nodes": [2, 3],
			"pending_module_binding": false,
			"board_tool": "pose",
			"pose_root_index": 2,
			"pose_chain_valid": true,
			"pose_downstream_nodes": [2, 3, 4],
		},
		{"action": "pose_chain_selected", "selected_nodes": [2, 3, 4], "pose_root_index": 2, "pose_downstream_nodes": [2, 3, 4]}
	)
	_assert_selection_release_intent(
		controller,
		{
			"has_custom_topology": true,
			"selected_nodes": [2, 5],
			"pending_module_binding": false,
			"board_tool": "pose",
			"pose_root_index": -1,
			"pose_chain_valid": false,
		},
		{"action": "pose_invalid_selection", "selected_nodes": [2, 5], "pose_root_index": -1, "pose_downstream_nodes": []}
	)
	_assert_selection_release_intent(
		controller,
		{
			"has_custom_topology": true,
			"selected_nodes": [0, 1],
			"pending_module_binding": false,
			"board_tool": "layout",
			"selection_contains_torso": true,
			"expanded_selection_nodes": [0, 1, 2, 3],
		},
		{"action": "layout_whole_rigid", "selected_nodes": [0, 1, 2, 3]}
	)
	_assert_selection_release_intent(
		controller,
		{
			"has_custom_topology": true,
			"selected_nodes": [1, 2],
			"pending_module_binding": false,
			"board_tool": "layout",
			"selection_contains_torso": false,
			"selection_connected_node": true,
		},
		{"action": "layout_connected_hint", "selected_nodes": [1, 2]}
	)
	_assert_selection_release_intent(
		controller,
		{
			"has_custom_topology": true,
			"selected_nodes": [4, 5],
			"pending_module_binding": false,
			"board_tool": "layout",
			"selection_contains_torso": false,
			"selection_connected_node": false,
		},
		{"action": "layout_loose_group", "selected_nodes": [4, 5]}
	)
	var click_base := {
		"button_index": MOUSE_BUTTON_LEFT,
		"double_click": false,
		"pending_module_binding": false,
		"binding_candidate_found": false,
		"binding_candidate_valid": false,
		"has_pending_canvas_part": false,
		"board_tool": "layout",
		"nearest_node_index": -1,
		"nearest_is_torso": false,
		"nearest_unconnected_draggable": false,
		"nearest_edge_count": 0,
		"selected_topology_nodes": [],
		"dragging_selection": false,
		"selection_contains_torso": false,
		"selection_connected_node": false,
		"edge_hit_index": -1,
		"right_clicked_node_index": -1,
		"pose_candidate_valid": false,
		"pose_candidate_root_index": -1,
		"pose_candidate_downstream_count": 0,
		"has_nodes": true,
	}
	_assert_click_intent(controller, _with(click_base, {"pending_module_binding": true, "button_index": MOUSE_BUTTON_RIGHT}), {"action": "binding_cancel"})
	_assert_click_intent(controller, _with(click_base, {"pending_module_binding": true, "binding_candidate_found": true, "binding_candidate_valid": true, "binding_selection": [2, 3]}), {"action": "binding_complete", "binding_selection": [2, 3]})
	_assert_click_intent(controller, _with(click_base, {"pending_module_binding": true, "binding_candidate_found": true, "binding_candidate_valid": false, "binding_candidate_reason": "target is stale"}), {"action": "binding_invalid", "reject_reason": "target is stale", "hint_key": "binding_invalid"})
	_assert_click_intent(controller, _with(click_base, {"pending_module_binding": true, "binding_candidate_found": false}), {"action": "start_selection_box"})
	_assert_click_intent(controller, _with(click_base, {"button_index": MOUSE_BUTTON_RIGHT, "edge_hit_index": 4}), {"action": "unlink_edge", "edge_index": 4})
	_assert_click_intent(controller, _with(click_base, {"button_index": MOUSE_BUTTON_RIGHT, "right_clicked_node_index": 2}), {"action": "unlink_node", "node_index": 2})
	_assert_click_intent(controller, _with(click_base, {"button_index": MOUSE_BUTTON_RIGHT, "right_clicked_node_index": -1}), {"action": "right_click_unlink_miss"})
	_assert_click_intent(controller, _with(click_base, {"has_pending_canvas_part": true}), {"action": "place_pending_part"})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 0, "nearest_is_torso": true, "double_click": true}), {"action": "open_torso_detail", "node_index": 0})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 2, "nearest_unconnected_draggable": true}), {"action": "start_unconnected_drag", "node_index": 2, "source_mode": "layout", "set_node_click_candidate": true})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 2, "nearest_unconnected_draggable": true, "board_tool": "pose"}), {"action": "start_unconnected_drag", "node_index": 2, "source_mode": "pose", "set_node_click_candidate": true})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 2, "board_tool": "pose", "pose_candidate_valid": true, "pose_candidate_root_index": 5}), {"action": "start_pose_drag", "node_index": 2, "pose_root_index": 5, "set_node_click_candidate": true})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 2, "board_tool": "pose", "pose_candidate_valid": false, "pose_candidate_reason": "bad", "pose_candidate_root_index": -1, "pose_candidate_downstream_count": 0}), {"action": "pose_drag_invalid", "node_index": 2, "pose_reject_reason": "bad", "pose_root_index": -1, "pose_downstream_count": 0, "set_node_click_candidate": true, "hint_key": "pose_drag_invalid"})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 1, "dragging_selection": true, "selection_contains_torso": true, "selected_topology_nodes": [0, 1]}), {"action": "start_group_drag", "node_index": 1, "group_nodes": [0, 1], "expand_connected_island": true})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 1, "dragging_selection": true, "selection_connected_node": true, "selected_topology_nodes": [1, 2]}), {"action": "layout_connected_selection_reject", "node_index": 1, "reject_reason": "connected_selection", "hint_key": "layout_connected_selection"})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 1, "dragging_selection": true, "selected_topology_nodes": [1, 2]}), {"action": "start_group_drag", "node_index": 1, "group_nodes": [1, 2], "expand_connected_island": false})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 0, "nearest_is_torso": true}), {"action": "start_group_drag", "node_index": 0, "group_nodes": [0], "expand_connected_island": true})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 3, "nearest_edge_count": 1}), {"action": "layout_connected_part_reject", "node_index": 3, "reject_reason": "connected_part", "hint_key": "layout_connected_part"})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": 4, "nearest_edge_count": 0}), {"action": "start_loose_drag", "node_index": 4})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": -1, "has_nodes": true}), {"action": "blank_canvas_select_box"})
	_assert_click_intent(controller, _with(click_base, {"nearest_node_index": -1, "has_nodes": false}), {"action": "blank_canvas_hint", "hint_key": "blank_canvas"})
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok")
	quit(0)


func _assert_action(controller, event: InputEvent, context: Dictionary, expected: String) -> void:
	var route: Dictionary = controller.route_board_input_event(event, context)
	var action := String(route.get("action", ""))
	if action != expected:
		_fail("Expected board route action %s, got %s for context %s." % [expected, action, str(context)])


func _assert_clipboard_shortcut(controller, event: InputEvent, context: Dictionary, expected: String) -> void:
	var intent: Dictionary = controller.clipboard_shortcut_intent(event, context)
	var action := String(intent.get("action", ""))
	if action != expected:
		_fail("Expected clipboard shortcut action %s, got %s for context %s." % [expected, action, str(context)])


func _assert_selected_node_feedback(controller, context: Dictionary, expected_action_key: String, expected_marker: String, expected_summary_tokens: Array) -> void:
	if not controller.has_method("selected_node_feedback"):
		_fail("selected_node_feedback method missing.")
		return
	var result: Dictionary = controller.selected_node_feedback(context)
	if not bool(result.get("valid", false)):
		_fail("selected_node_feedback should be valid for %s, got %s." % [str(context), str(result)])
	if String(result.get("action_key", "")) != expected_action_key:
		_fail("Expected selected_node_feedback action_key %s, got %s." % [expected_action_key, str(result)])
	if String(result.get("shop_marker", "")) != expected_marker:
		_fail("Expected selected_node_feedback shop marker %s, got %s." % [expected_marker, str(result)])
	var summary := String(result.get("summary", ""))
	for token in expected_summary_tokens:
		if summary.find(String(token)) < 0:
			_fail("selected_node_feedback summary missing token %s in %s." % [String(token), summary])


func _assert_node_release_intent(controller, context: Dictionary, expected: Dictionary) -> void:
	var intent: Dictionary = controller.node_drag_release_intent(context)
	for key in expected.keys():
		var actual = intent.get(key)
		var wanted = expected[key]
		if actual != wanted:
			_fail("Expected release intent %s=%s, got %s in %s." % [String(key), str(wanted), str(actual), str(intent)])


func _assert_selection_release_intent(controller, context: Dictionary, expected: Dictionary) -> void:
	var intent: Dictionary = controller.selection_box_release_intent(context)
	for key in expected.keys():
		var actual = intent.get(key)
		var wanted = expected[key]
		if actual != wanted:
			_fail("Expected selection release intent %s=%s, got %s in %s." % [String(key), str(wanted), str(actual), str(intent)])


func _assert_click_intent(controller, context: Dictionary, expected: Dictionary) -> void:
	var intent: Dictionary = controller.custom_topology_click_intent(context)
	for key in expected.keys():
		var actual = intent.get(key)
		var wanted = expected[key]
		if actual != wanted:
			_fail("Expected click intent %s=%s, got %s in %s." % [String(key), str(wanted), str(actual), str(intent)])


func _with(base: Dictionary, patch: Dictionary) -> Dictionary:
	var result := base.duplicate()
	for key in patch.keys():
		result[key] = patch[key]
	return result


func _motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	return event


func _button(button_index: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	event.position = Vector2(20.0, 30.0)
	return event


func _key(keycode: int, with_ctrl: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	event.ctrl_pressed = with_ctrl
	return event
