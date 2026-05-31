extends RefCounted
class_name UnitEditorBoardController


const ACTION_NONE := "none"
const ACTION_UPDATE_POSE_DRAG := "update_pose_drag"
const ACTION_UPDATE_SELECTION_BOX := "update_selection_box"
const ACTION_MOVE_SELECTED_NODES := "move_selected_nodes"
const ACTION_MOVE_SINGLE_NODE := "move_single_node"
const ACTION_MOVE_WHOLE_UNIT := "move_whole_unit"
const ACTION_TORSO_HOVER := "torso_hover"
const ACTION_FINISH_POSE_DRAG := "finish_pose_drag"
const ACTION_FINISH_SELECTION_BOX := "finish_selection_box"
const ACTION_FINISH_NODE_DRAG := "finish_node_drag"
const ACTION_FINISH_WHOLE_DRAG := "finish_whole_drag"
const ACTION_ZOOM_WHEEL := "zoom_wheel"
const ACTION_BARRIER_BOARD_CLICK := "barrier_board_click"
const ACTION_CUSTOM_TOPOLOGY_CLICK := "custom_topology_click"
const ACTION_LEGACY_BODY_SOCKET_CLICK := "legacy_body_socket_click"
const ACTION_COPY_SELECTION := "copy_selection"
const ACTION_CUT_SELECTION := "cut_selection"
const ACTION_PASTE_SELECTION := "paste_selection"
const SELECTION_NO_TOPOLOGY := "selection_no_topology"
const SELECTION_COMPLETE_MODULE_BINDING := "complete_module_binding"
const SELECTION_EMPTY := "empty_selection"
const SELECTION_POSE_CHAIN_SELECTED := "pose_chain_selected"
const SELECTION_POSE_INVALID := "pose_invalid_selection"
const SELECTION_LAYOUT_WHOLE_RIGID := "layout_whole_rigid"
const SELECTION_LAYOUT_CONNECTED_HINT := "layout_connected_hint"
const SELECTION_LAYOUT_LOOSE_GROUP := "layout_loose_group"
const CLICK_BINDING_CANCEL := "binding_cancel"
const CLICK_BINDING_COMPLETE := "binding_complete"
const CLICK_BINDING_INVALID := "binding_invalid"
const CLICK_START_SELECTION_BOX := "start_selection_box"
const CLICK_UNLINK_EDGE := "unlink_edge"
const CLICK_UNLINK_NODE := "unlink_node"
const CLICK_RIGHT_UNLINK_MISS := "right_click_unlink_miss"
const CLICK_PLACE_PENDING_PART := "place_pending_part"
const CLICK_OPEN_TORSO_DETAIL := "open_torso_detail"
const CLICK_START_UNCONNECTED_DRAG := "start_unconnected_drag"
const CLICK_START_POSE_DRAG := "start_pose_drag"
const CLICK_POSE_DRAG_INVALID := "pose_drag_invalid"
const CLICK_START_GROUP_DRAG := "start_group_drag"
const CLICK_LAYOUT_CONNECTED_SELECTION_REJECT := "layout_connected_selection_reject"
const CLICK_LAYOUT_CONNECTED_PART_REJECT := "layout_connected_part_reject"
const CLICK_START_LOOSE_DRAG := "start_loose_drag"
const CLICK_BLANK_CANVAS_SELECT_BOX := "blank_canvas_select_box"
const CLICK_BLANK_CANVAS_HINT := "blank_canvas_hint"


func route_board_input_event(event: InputEvent, context: Dictionary) -> Dictionary:
	if event is InputEventMouseMotion:
		return {"action": _motion_action(context)}
	if not (event is InputEventMouseButton):
		return {"action": ACTION_NONE}
	var mouse_event := event as InputEventMouseButton
	if mouse_event.pressed:
		return {"action": _press_action(mouse_event, context)}
	return {"action": _release_action(mouse_event, context)}


func clipboard_shortcut_intent(event: InputEvent, context: Dictionary) -> Dictionary:
	if not (event is InputEventKey):
		return {"action": ACTION_NONE}
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return {"action": ACTION_NONE}
	if not (key_event.ctrl_pressed or key_event.meta_pressed):
		return {"action": ACTION_NONE}
	if bool(context.get("busy", false)) or not _can_edit_body_topology(context):
		return {"action": ACTION_NONE}
	var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
	match keycode:
		KEY_C:
			return {"action": ACTION_COPY_SELECTION}
		KEY_X:
			return {"action": ACTION_CUT_SELECTION}
		KEY_V:
			return {"action": ACTION_PASTE_SELECTION}
	return {"action": ACTION_NONE}


func zoom_input_allowed(context: Dictionary) -> bool:
	return not bool(context.get("selecting_topology_box", false)) \
		and int(context.get("dragging_node_index", -1)) < 0 \
		and not bool(context.get("dragging_whole_unit", false)) \
		and not bool(context.get("pose_dragging", false))


func node_drag_release_intent(context: Dictionary) -> Dictionary:
	var released_node_index := int(context.get("dragging_node_index", -1))
	var was_group_dragging := bool(context.get("dragging_selected_nodes", false))
	var released_group_nodes := Array(context.get("selected_topology_nodes", [])).duplicate()
	var should_try_magnetic_link := not was_group_dragging and int(context.get("dragged_node_edge_count", 0)) <= 0 and released_node_index >= 0
	var show_detail_after_release := int(context.get("node_click_candidate_index", -1)) == released_node_index \
		and released_node_index >= 0 \
		and not bool(context.get("dragged_node_is_torso", false)) \
		and not bool(context.get("node_click_moved", false)) \
		and float(context.get("release_distance_from_click_start", INF)) <= 6.0
	return {
		"released_node_index": released_node_index,
		"released_group_nodes": released_group_nodes,
		"was_group_dragging": was_group_dragging,
		"should_try_magnetic_link": should_try_magnetic_link,
		"show_detail_after_release": show_detail_after_release,
	}


func whole_drag_release_intent(context: Dictionary) -> Dictionary:
	var changed_nodes: Array = []
	var count := maxi(0, int(context.get("topology_node_count", 0)))
	for i in range(count):
		changed_nodes.append(i)
	return {"changed_nodes": changed_nodes}


func selection_box_release_intent(context: Dictionary) -> Dictionary:
	var selected_nodes := Array(context.get("selected_nodes", [])).duplicate()
	if not bool(context.get("has_custom_topology", true)):
		return {"action": SELECTION_NO_TOPOLOGY, "selected_nodes": []}
	if bool(context.get("pending_module_binding", false)):
		return {"action": SELECTION_COMPLETE_MODULE_BINDING, "selected_nodes": selected_nodes}
	if selected_nodes.is_empty():
		return {"action": SELECTION_EMPTY, "selected_nodes": []}
	if String(context.get("board_tool", "")) == "pose":
		var pose_root_index := int(context.get("pose_root_index", -1))
		if pose_root_index >= 0 and bool(context.get("pose_chain_valid", false)):
			var downstream_nodes := Array(context.get("pose_downstream_nodes", [])).duplicate()
			return {
				"action": SELECTION_POSE_CHAIN_SELECTED,
				"selected_nodes": downstream_nodes if not downstream_nodes.is_empty() else selected_nodes,
				"pose_root_index": pose_root_index,
				"pose_downstream_nodes": downstream_nodes,
			}
		return {
			"action": SELECTION_POSE_INVALID,
			"selected_nodes": selected_nodes,
			"pose_root_index": pose_root_index,
			"pose_downstream_nodes": [],
		}
	if bool(context.get("selection_contains_torso", false)):
		var expanded_nodes := Array(context.get("expanded_selection_nodes", [])).duplicate()
		return {
			"action": SELECTION_LAYOUT_WHOLE_RIGID,
			"selected_nodes": expanded_nodes if not expanded_nodes.is_empty() else selected_nodes,
		}
	if bool(context.get("selection_connected_node", false)):
		return {"action": SELECTION_LAYOUT_CONNECTED_HINT, "selected_nodes": selected_nodes}
	return {"action": SELECTION_LAYOUT_LOOSE_GROUP, "selected_nodes": selected_nodes}


func custom_topology_click_intent(context: Dictionary) -> Dictionary:
	var button_index := int(context.get("button_index", 0))
	var is_left := button_index == MOUSE_BUTTON_LEFT
	var is_right := button_index == MOUSE_BUTTON_RIGHT
	var nearest_node_index := int(context.get("nearest_node_index", -1))
	var has_nearest := nearest_node_index >= 0
	if bool(context.get("pending_module_binding", false)):
		if is_right:
			return {"action": CLICK_BINDING_CANCEL}
		if is_left:
			if bool(context.get("binding_candidate_found", false)):
				return {
					"action": CLICK_BINDING_COMPLETE if bool(context.get("binding_candidate_valid", false)) else CLICK_BINDING_INVALID,
					"binding_selection": Array(context.get("binding_selection", [])).duplicate(),
				}
			return {"action": CLICK_START_SELECTION_BOX}
	if is_right:
		var edge_index := int(context.get("edge_hit_index", -1))
		if edge_index >= 0:
			return {"action": CLICK_UNLINK_EDGE, "edge_index": edge_index}
		var clicked_node_index := int(context.get("right_clicked_node_index", -1))
		if clicked_node_index >= 0:
			return {"action": CLICK_UNLINK_NODE, "node_index": clicked_node_index}
		return {"action": CLICK_RIGHT_UNLINK_MISS}
	if bool(context.get("has_pending_canvas_part", false)):
		return {"action": CLICK_PLACE_PENDING_PART}
	if has_nearest:
		var should_set_click_candidate := is_left and not (bool(context.get("double_click", false)) and bool(context.get("nearest_is_torso", false)))
		if is_left and bool(context.get("double_click", false)) and bool(context.get("nearest_is_torso", false)):
			return {"action": CLICK_OPEN_TORSO_DETAIL, "node_index": nearest_node_index}
		if is_left \
				and (String(context.get("board_tool", "")) == "pose" or not bool(context.get("dragging_selection", false))) \
				and bool(context.get("nearest_unconnected_draggable", false)):
			return {
				"action": CLICK_START_UNCONNECTED_DRAG,
				"node_index": nearest_node_index,
				"source_mode": "pose" if String(context.get("board_tool", "")) == "pose" else "layout",
				"set_node_click_candidate": should_set_click_candidate,
			}
		if String(context.get("board_tool", "")) == "pose" and is_left:
			if not bool(context.get("pose_candidate_valid", false)):
				return {
					"action": CLICK_POSE_DRAG_INVALID,
					"node_index": nearest_node_index,
					"pose_reject_reason": String(context.get("pose_candidate_reason", "")),
					"pose_root_index": int(context.get("pose_candidate_root_index", -1)),
					"pose_downstream_count": int(context.get("pose_candidate_downstream_count", 0)),
					"set_node_click_candidate": should_set_click_candidate,
				}
			return {
				"action": CLICK_START_POSE_DRAG,
				"node_index": nearest_node_index,
				"pose_root_index": int(context.get("pose_candidate_root_index", -1)),
				"set_node_click_candidate": should_set_click_candidate,
			}
		if bool(context.get("dragging_selection", false)):
			if bool(context.get("selection_contains_torso", false)):
				return {
					"action": CLICK_START_GROUP_DRAG,
					"node_index": nearest_node_index,
					"group_nodes": Array(context.get("selected_topology_nodes", [])).duplicate(),
					"expand_connected_island": true,
					"set_node_click_candidate": should_set_click_candidate,
				}
			if bool(context.get("selection_connected_node", false)):
				return {
					"action": CLICK_LAYOUT_CONNECTED_SELECTION_REJECT,
					"node_index": nearest_node_index,
					"set_node_click_candidate": should_set_click_candidate,
				}
			return {
				"action": CLICK_START_GROUP_DRAG,
				"node_index": nearest_node_index,
				"group_nodes": Array(context.get("selected_topology_nodes", [])).duplicate(),
				"expand_connected_island": false,
				"set_node_click_candidate": should_set_click_candidate,
			}
		if bool(context.get("nearest_is_torso", false)):
			return {
				"action": CLICK_START_GROUP_DRAG,
				"node_index": nearest_node_index,
				"group_nodes": [nearest_node_index],
				"expand_connected_island": true,
				"set_node_click_candidate": should_set_click_candidate,
			}
		if int(context.get("nearest_edge_count", 0)) > 0:
			return {
				"action": CLICK_LAYOUT_CONNECTED_PART_REJECT,
				"node_index": nearest_node_index,
				"set_node_click_candidate": should_set_click_candidate,
			}
		return {
			"action": CLICK_START_LOOSE_DRAG,
			"node_index": nearest_node_index,
			"set_node_click_candidate": should_set_click_candidate,
		}
	if bool(context.get("has_nodes", false)) and is_left:
		return {"action": CLICK_BLANK_CANVAS_SELECT_BOX}
	return {"action": CLICK_BLANK_CANVAS_HINT}


func _motion_action(context: Dictionary) -> String:
	if bool(context.get("pose_dragging", false)) and _can_edit_body_topology(context):
		return ACTION_UPDATE_POSE_DRAG
	if bool(context.get("selecting_topology_box", false)) and _can_edit_body_topology(context):
		return ACTION_UPDATE_SELECTION_BOX
	if int(context.get("dragging_node_index", -1)) >= 0 and _can_edit_body_topology(context):
		return ACTION_MOVE_SELECTED_NODES if bool(context.get("dragging_selected_nodes", false)) else ACTION_MOVE_SINGLE_NODE
	if bool(context.get("dragging_whole_unit", false)) and _can_edit_body_topology(context):
		return ACTION_MOVE_WHOLE_UNIT
	return ACTION_TORSO_HOVER


func _release_action(mouse_event: InputEventMouseButton, context: Dictionary) -> String:
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return ACTION_NONE
	if bool(context.get("pose_dragging", false)):
		return ACTION_FINISH_POSE_DRAG
	if bool(context.get("selecting_topology_box", false)):
		return ACTION_FINISH_SELECTION_BOX
	if int(context.get("dragging_node_index", -1)) >= 0:
		return ACTION_FINISH_NODE_DRAG
	if bool(context.get("dragging_whole_unit", false)):
		return ACTION_FINISH_WHOLE_DRAG
	return ACTION_NONE


func _press_action(mouse_event: InputEventMouseButton, context: Dictionary) -> String:
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return ACTION_ZOOM_WHEEL if zoom_input_allowed(context) else ACTION_NONE
	if bool(context.get("is_barrier_without_topology", false)):
		return ACTION_BARRIER_BOARD_CLICK
	if bool(context.get("role_uses_body_board", false)):
		return ACTION_CUSTOM_TOPOLOGY_CLICK if bool(context.get("has_custom_topology", false)) else ACTION_LEGACY_BODY_SOCKET_CLICK
	return ACTION_NONE


func _can_edit_body_topology(context: Dictionary) -> bool:
	return bool(context.get("role_uses_body_board", false)) and bool(context.get("has_custom_topology", false))
