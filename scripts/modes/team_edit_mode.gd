extends RefCounted
class_name TeamEditMode

const MODE_KEY := "team_edit"

var owner_root: Node
var team_edit_controller
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}
var last_cleanup_context := {}


func bind(root_node: Node, controller) -> void:
	owner_root = root_node
	team_edit_controller = controller


func is_bound() -> bool:
	return owner_root != null and team_edit_controller != null


func mode_key() -> String:
	return MODE_KEY


func show_intent(preloaded: bool, loading_queued: bool, preserve_canvas: bool = false, reason: String = "") -> Dictionary:
	var resolved_reason := reason.strip_edges()
	if resolved_reason == "":
		resolved_reason = "teamedit_preserve" if preserve_canvas else "teamedit"
	return {
		"mode_key": MODE_KEY,
		"reason": resolved_reason,
		"payload": {"preserve_canvas": preserve_canvas} if preserve_canvas else {},
		"preloaded": preloaded,
		"loading_queued": loading_queued,
		"should_apply": not loading_queued,
		"preserve_canvas": preserve_canvas,
		"reset_board_view": not preserve_canvas,
		"reset_working_canvas": not preserve_canvas,
		"apply_role_catalog_defaults": true,
		"clear_clipboard": true,
		"reset_last_mouse": true,
		"bound": is_bound(),
	}


func enter_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason.strip_edges(),
		"payload": payload.duplicate(true),
		"bound": is_bound(),
	}


func commit_enter(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	enter_count += 1
	last_enter_context = intent.duplicate(true)
	if team_edit_controller != null:
		team_edit_controller.mark_dirty(1, "teamedit_enter")
	return true


func cleanup_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason.strip_edges(),
		"payload": payload.duplicate(true),
		"clear_hover_cards": true,
		"close_detail_panels": true,
		"clear_bindings": true,
		"clear_drag_state": true,
		"clear_placement_state": true,
		"clear_clipboard": true,
		"clear_preview_caches": true,
		"reset_last_mouse": true,
		"bound": is_bound(),
	}


func commit_cleanup(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	last_cleanup_context = intent.duplicate(true)
	if team_edit_controller != null:
		team_edit_controller.mark_dirty(1, "teamedit_cleanup")
	return true


func exit_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason.strip_edges(),
		"payload": payload.duplicate(true),
		"bound": is_bound(),
	}


func commit_exit(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	exit_count += 1
	last_exit_context = intent.duplicate(true)
	return true
