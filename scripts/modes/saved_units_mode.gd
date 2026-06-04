extends RefCounted
class_name SavedUnitsMode

const MODE_KEY := "saved_units"

var owner_root: Node
var saved_units_controller
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}
var last_cleanup_context := {}


func bind(root_node: Node, controller) -> void:
	owner_root = root_node
	saved_units_controller = controller


func is_bound() -> bool:
	return owner_root != null and saved_units_controller != null


func mode_key() -> String:
	return MODE_KEY


func show_intent(focus_path: String, return_context: String, defer_disk_scan: bool, preloaded: bool, loading_queued: bool, reason: String = "saved_units") -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": {"focus_path": focus_path},
		"focus_path": focus_path,
		"return_context": return_context,
		"defer_disk_scan": defer_disk_scan,
		"preloaded": preloaded,
		"loading_queued": loading_queued,
		"should_apply": not loading_queued,
		"bound": is_bound(),
	}


func enter_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": payload.duplicate(true),
		"bound": is_bound(),
	}


func commit_enter(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	enter_count += 1
	last_enter_context = intent.duplicate(true)
	if saved_units_controller != null:
		saved_units_controller.mark_dirty("saved_units_enter")
	return true


func cleanup_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": payload.duplicate(true),
		"clear_hover": true,
		"clear_focus": true,
		"clear_detail": true,
		"clear_pending_delete": true,
		"bound": is_bound(),
	}


func commit_cleanup(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	last_cleanup_context = intent.duplicate(true)
	if saved_units_controller != null:
		saved_units_controller.mark_dirty("saved_units_cleanup")
	return true


func exit_intent(reason: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": payload.duplicate(true),
		"bound": is_bound(),
	}


func commit_exit(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	exit_count += 1
	last_exit_context = intent.duplicate(true)
	return true
