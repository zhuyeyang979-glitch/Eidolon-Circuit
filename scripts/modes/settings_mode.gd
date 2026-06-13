extends RefCounted
class_name SettingsMode

const MODE_KEY := "settings"

var owner_root: Node
var settings_controller
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}
var last_category_context := {}


func bind(root_node: Node, controller) -> void:
	owner_root = root_node
	settings_controller = controller


func is_bound() -> bool:
	return owner_root != null and settings_controller != null


func mode_key() -> String:
	return MODE_KEY


func show_intent(category_key: String, preloaded: bool, return_target: String, loading_queued: bool, reason: String = "settings") -> Dictionary:
	var resolved_category := category_key.strip_edges()
	if resolved_category == "":
		resolved_category = "root"
	var resolved_reason := reason.strip_edges()
	if resolved_reason == "":
		resolved_reason = MODE_KEY
	var resolved_return_target := return_target.strip_edges()
	return {
		"mode_key": MODE_KEY,
		"reason": resolved_reason,
		"payload": {"category": resolved_category},
		"category_key": resolved_category,
		"preloaded": preloaded,
		"return_target": resolved_return_target,
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
	return true


func category_intent(category_key: String) -> Dictionary:
	var resolved_category := category_key.strip_edges()
	if resolved_category == "":
		resolved_category = "root"
	return {
		"handled": true,
		"category_key": resolved_category,
		"reset_index": true,
		"clear_rebind": true,
		"bound": is_bound(),
	}


func commit_category(intent: Dictionary) -> bool:
	if not bool(intent.get("handled", false)):
		return false
	last_category_context = intent.duplicate(true)
	if settings_controller != null:
		settings_controller.mark_dirty("settings_category")
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
