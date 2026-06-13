extends RefCounted
class_name TrainingMode

const MODE_KEY := "training"
const SCOUT_PAGE := "scout"

var owner_root: Node
var scout_controller
var enter_count := 0
var exit_count := 0
var last_enter_context := {}
var last_exit_context := {}
var last_config_context := {}


func bind(root_node: Node, controller) -> void:
	owner_root = root_node
	scout_controller = controller


func is_bound() -> bool:
	return owner_root != null and scout_controller != null


func mode_key() -> String:
	return MODE_KEY


func config_intent(clear_imports: bool) -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"reason": "training_config",
		"clear_imports": clear_imports,
		"prepare_loadouts": true,
		"handoff_mode": MODE_KEY,
		"bound": is_bound(),
	}


func commit_config(intent: Dictionary) -> bool:
	if String(intent.get("mode_key", "")) != MODE_KEY:
		return false
	last_config_context = intent.duplicate(true)
	if scout_controller != null:
		scout_controller.mark_dirty("training_config")
	return true


func scout_show_intent(preloaded: bool, loading_queued: bool, reason: String = "scout:training") -> Dictionary:
	return {
		"mode_key": MODE_KEY,
		"page_key": SCOUT_PAGE,
		"reason": reason,
		"payload": {"mode": MODE_KEY},
		"preloaded": preloaded,
		"loading_queued": loading_queued,
		"should_apply": not loading_queued,
		"reset_training_seat": true,
		"reset_scout_selection": true,
		"bound": is_bound(),
	}


func begin_from_scout_intent(pending_mode: String, training_seat_confirmed: bool) -> Dictionary:
	var resolved_pending_mode := pending_mode.strip_edges()
	if resolved_pending_mode != MODE_KEY:
		return {
			"handled": false,
			"action": "",
			"pending_mode": resolved_pending_mode,
		}
	if not training_seat_confirmed:
		return {
			"handled": true,
			"action": "require_training_seat",
			"pending_mode": resolved_pending_mode,
			"extend_timer": true,
			"play_alarm": true,
		}
	return {
		"handled": true,
		"action": "configure_and_begin_training",
		"pending_mode": resolved_pending_mode,
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
	if scout_controller != null:
		scout_controller.mark_dirty("training_enter")
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
