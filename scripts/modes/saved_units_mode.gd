extends RefCounted
class_name SavedUnitsMode

const MODE_KEY := "saved_units"
const DEFAULT_FILTER := "all"

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


func filter_intent(filter_key: String) -> Dictionary:
	var resolved_filter := filter_key.strip_edges()
	if resolved_filter == "":
		resolved_filter = DEFAULT_FILTER
	return {
		"handled": true,
		"kind": "filter",
		"filter_key": resolved_filter,
		"reset_page": true,
		"clear_selection": true,
		"clear_hover": true,
		"clear_detail": true,
		"bound": is_bound(),
	}


func card_select_intent(card_index: int, page: int, page_size: int, entry_count: int) -> Dictionary:
	var safe_page_size := maxi(1, page_size)
	var absolute_index := page * safe_page_size + card_index
	return {
		"handled": absolute_index >= 0 and absolute_index < entry_count,
		"kind": "select_card",
		"card_index": card_index,
		"absolute_index": absolute_index,
		"bound": is_bound(),
	}


func card_pointer_intent(pointer_button: String, card_index: int, page: int, page_size: int, entry_count: int) -> Dictionary:
	var select_intent := card_select_intent(card_index, page, page_size, entry_count)
	var resolved_button := pointer_button.strip_edges()
	match resolved_button:
		"left":
			select_intent["kind"] = "select_card"
			select_intent["pointer_button"] = resolved_button
			return select_intent
		"right":
			select_intent["kind"] = "toggle_card"
			select_intent["pointer_button"] = resolved_button
			return select_intent
	select_intent["handled"] = false
	select_intent["kind"] = "ignore"
	select_intent["pointer_button"] = resolved_button
	return select_intent


func input_intent(action_name: String, selected_index: int, entry_count: int, page_size: int, delete_panel_visible: bool = false) -> Dictionary:
	var resolved_action := action_name.strip_edges()
	match resolved_action:
		"menu_back":
			return {
				"handled": true,
				"kind": "cancel_delete" if delete_panel_visible else "show_options",
				"input_action": resolved_action,
				"bound": is_bound(),
			}
		"menu_up":
			return _selection_input_intent(-1, selected_index, entry_count, page_size, resolved_action, true)
		"menu_down":
			return _selection_input_intent(1, selected_index, entry_count, page_size, resolved_action, false)
	return {
		"handled": false,
		"kind": "ignore",
		"input_action": resolved_action,
		"bound": is_bound(),
	}


func action_intent(action_key: String, selected_index: int, entry_count: int, selected_count: int, team_index: int, team_count: int) -> Dictionary:
	var resolved_action := action_key.strip_edges()
	var intent := {
		"handled": false,
		"kind": "ignore",
		"action_key": resolved_action,
		"selected_index": selected_index,
		"entry_count": entry_count,
		"selected_count": selected_count,
		"team_index": team_index,
		"team_count": team_count,
		"bound": is_bound(),
	}
	match resolved_action:
		"prev", "next", "clear", "toggle":
			intent["handled"] = true
			intent["kind"] = "selection_state"
		"edit", "train_one":
			intent["handled"] = selected_index >= 0 and selected_index < entry_count
			intent["kind"] = "selected_entry"
		"train_selected":
			intent["handled"] = true
			intent["kind"] = "selected_entries"
		"delete_selected":
			intent["handled"] = true
			intent["kind"] = "delete_selected"
		"save_puppet_group":
			intent["handled"] = true
			intent["kind"] = "save_puppet_group"
		"save_team":
			intent["handled"] = true
			intent["kind"] = "save_team"
		"team_prev", "team_next":
			intent["handled"] = team_count > 0
			intent["kind"] = "team_cycle"
		"load_team", "delete_team":
			intent["handled"] = team_index >= 0 and team_index < team_count
			intent["kind"] = "team_entry"
	return intent


func _selection_input_intent(delta: int, selected_index: int, entry_count: int, page_size: int, action_name: String, allow_empty: bool) -> Dictionary:
	if entry_count <= 0:
		return {
			"handled": allow_empty,
			"kind": "select_index",
			"input_action": action_name,
			"selected_index": 0,
			"page": 0,
			"bound": is_bound(),
		}
	var safe_page_size := maxi(1, page_size)
	var next_index := selected_index + delta
	if delta < 0:
		next_index = maxi(0, next_index)
	else:
		next_index = clampi(next_index, 0, entry_count - 1)
	return {
		"handled": true,
		"kind": "select_index",
		"input_action": action_name,
		"selected_index": next_index,
		"page": int(floor(float(next_index) / float(safe_page_size))),
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
