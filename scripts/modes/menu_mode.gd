extends RefCounted
class_name MenuMode

const MODE_KEY := "menu"

var owner_root: Node
var menu_controller
var menu_view
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}


func bind(root_node: Node, controller, view) -> void:
	owner_root = root_node
	menu_controller = controller
	menu_view = view


func is_bound() -> bool:
	return owner_root != null and menu_controller != null and menu_view != null


func mode_key() -> String:
	return MODE_KEY


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


func show_intent(preloaded: bool, loading_queued: bool, reason: String = "menu", payload: Dictionary = {}) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": reason,
		"payload": payload.duplicate(true),
		"preloaded": preloaded,
		"loading_queued": loading_queued,
		"should_apply": not loading_queued,
		"bound": is_bound(),
	}


func update_main_menu(language: String, ai_battle_seat: int, match_format_short: String, team_status: String = "") -> bool:
	if menu_controller == null or menu_view == null:
		return false
	menu_view.update_main_menu(menu_controller.main_menu_model(language, ai_battle_seat, match_format_short, team_status))
	return true


func move_selection(delta: int, fallback_index: int, fallback_count: int) -> Dictionary:
	if menu_controller != null:
		return {
			"handled": true,
			"selected_index": menu_controller.move_selection(delta),
			"used_controller": true,
		}
	var count := maxi(1, fallback_count)
	return {
		"handled": fallback_count > 0,
		"selected_index": wrapi(fallback_index + delta, 0, count),
		"used_controller": false,
	}


func select_index(index: int, fallback_count: int) -> Dictionary:
	if menu_controller != null:
		return {
			"handled": true,
			"selected_index": menu_controller.select_index(index),
			"used_controller": true,
		}
	var count := maxi(1, fallback_count)
	return {
		"handled": fallback_count > 0,
		"selected_index": clampi(index, 0, count - 1),
		"used_controller": false,
	}


func main_menu_action(index: int) -> Dictionary:
	if menu_controller != null:
		return menu_controller.main_menu_action(index)
	return {"action": "", "index": index}


func input_action_intent(action_name: String, fallback_index: int, fallback_count: int) -> Dictionary:
	match action_name:
		"menu_up":
			var up_intent := move_selection(-1, fallback_index, fallback_count)
			up_intent["kind"] = "selection"
			up_intent["input_action"] = action_name
			return up_intent
		"menu_down":
			var down_intent := move_selection(1, fallback_index, fallback_count)
			down_intent["kind"] = "selection"
			down_intent["input_action"] = action_name
			return down_intent
		"menu_confirm":
			return {
				"handled": menu_controller != null or fallback_count > 0,
				"kind": "activate",
				"input_action": action_name,
				"index": fallback_index,
			}
	return {
		"handled": false,
		"kind": "",
		"input_action": action_name,
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
