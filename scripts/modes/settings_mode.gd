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
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": {"category": resolved_category},
		"category_key": resolved_category,
		"preloaded": preloaded,
		"return_target": return_target,
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


func input_intent(action_name: String, category_key: String, selected_index: int, item_count: int, rebind_action: String = "") -> Dictionary:
	var resolved_action := action_name.strip_edges()
	var resolved_category := category_key.strip_edges()
	if resolved_category == "":
		resolved_category = "root"
	var resolved_rebind_action := rebind_action.strip_edges()
	if resolved_rebind_action != "":
		if resolved_action == "menu_back":
			return {
				"handled": true,
				"kind": "cancel_rebind",
				"input_action": resolved_action,
				"category_key": resolved_category,
				"rebind_action": resolved_rebind_action,
				"bound": is_bound(),
			}
		return {
			"handled": false,
			"kind": "ignore",
			"input_action": resolved_action,
			"category_key": resolved_category,
			"rebind_action": resolved_rebind_action,
			"bound": is_bound(),
		}
	match resolved_action:
		"menu_back":
			if resolved_category != "root":
				return {
					"handled": true,
					"kind": "show_category",
					"input_action": resolved_action,
					"category_key": "root",
					"bound": is_bound(),
				}
			return {
				"handled": true,
				"kind": "show_menu",
				"input_action": resolved_action,
				"category_key": resolved_category,
				"bound": is_bound(),
			}
		"menu_confirm", "p1_left", "p1_right":
			var activate_intent := activation_intent(selected_index, item_count)
			activate_intent["input_action"] = resolved_action
			return activate_intent
		"menu_up":
			return _selection_intent(-1, selected_index, item_count, resolved_action, resolved_category)
		"menu_down":
			return _selection_intent(1, selected_index, item_count, resolved_action, resolved_category)
	return {
		"handled": false,
		"kind": "ignore",
		"input_action": resolved_action,
		"category_key": resolved_category,
		"bound": is_bound(),
	}


func activation_intent(index: int, item_count: int) -> Dictionary:
	if item_count <= 0:
		return {
			"handled": false,
			"kind": "activate",
			"index": index,
			"bound": is_bound(),
		}
	return {
		"handled": true,
		"kind": "activate",
		"index": clampi(index, 0, item_count - 1),
		"bound": is_bound(),
	}


func _selection_intent(delta: int, selected_index: int, item_count: int, action_name: String, category_key: String) -> Dictionary:
	if item_count <= 0:
		return {
			"handled": false,
			"kind": "select",
			"input_action": action_name,
			"category_key": category_key,
			"selected_index": 0,
			"bound": is_bound(),
		}
	return {
		"handled": true,
		"kind": "select",
		"input_action": action_name,
		"category_key": category_key,
		"selected_index": wrapi(selected_index + delta, 0, item_count),
		"bound": is_bound(),
	}


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
