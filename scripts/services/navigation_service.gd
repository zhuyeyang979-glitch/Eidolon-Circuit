extends RefCounted
class_name NavigationService

var _current_page := ""
var _previous_page := ""
var _return_target := ""
var _pending_transition := {}
var _last_transition := {}
var _history: Array = []


func return_target_for(target_page: String, explicit_return_target: String = "") -> String:
	if explicit_return_target != "":
		return explicit_return_target
	var current := current_page()
	match target_page:
		"settings":
			if current != "" and current != "settings" and current != "loading":
				return current
		"saved_units":
			return "editor" if current == "editor" else "menu"
	return ""


func begin_transition(to_page: String, reason: String, return_target: String = "", payload: Dictionary = {}) -> Dictionary:
	var transition := {
		"phase": "begin",
		"from_page": _current_page,
		"to_page": to_page,
		"reason": reason,
		"return_target": return_target,
		"payload": payload.duplicate(true),
	}
	_pending_transition = transition.duplicate(true)
	_record_transition(transition)
	return transition


func commit_transition(to_page: String, reason: String = "", payload: Dictionary = {}) -> Dictionary:
	var transition_reason := reason
	var transition_payload := payload.duplicate(true)
	var transition_return_target := ""
	var transition_from_page := _current_page
	var consumes_pending := false
	if not _pending_transition.is_empty() and String(_pending_transition.get("to_page", "")) == to_page:
		transition_from_page = String(_pending_transition.get("from_page", transition_from_page))
		if transition_reason == "":
			transition_reason = String(_pending_transition.get("reason", ""))
		var pending_return_target := String(_pending_transition.get("return_target", ""))
		if pending_return_target != "":
			transition_return_target = pending_return_target
		var pending_payload: Dictionary = Dictionary(_pending_transition.get("payload", {})).duplicate(true)
		for key in transition_payload.keys():
			pending_payload[key] = transition_payload[key]
		transition_payload = pending_payload
		consumes_pending = true
	elif to_page != "loading":
		_pending_transition = {}
	if transition_reason == "":
		transition_reason = "navigation:%s" % to_page
	_previous_page = _current_page
	_current_page = to_page
	if transition_return_target != "":
		_return_target = transition_return_target
	elif ["menu", "editor", "scout", "battle"].has(to_page):
		_return_target = ""
	var transition := {
		"phase": "commit",
		"from_page": transition_from_page,
		"previous_page": _previous_page,
		"to_page": to_page,
		"reason": transition_reason,
		"return_target": _return_target,
		"payload": transition_payload,
	}
	_record_transition(transition)
	if consumes_pending:
		_pending_transition = {}
	return transition


func current_page() -> String:
	return _current_page


func previous_page() -> String:
	return _previous_page


func return_target() -> String:
	return _return_target


func resolve_option_action(action_key: String, current_subroute: String = "") -> Dictionary:
	match action_key:
		"close":
			return {"action": "close"}
		"help":
			return {"action": "show_help", "context": _current_page}
		"main_menu":
			return {"action": "navigate_menu", "to_page": "menu", "reason": "page_options_main_menu"}
		"settings":
			return {"action": "navigate_settings", "to_page": "settings", "reason": "page_options_settings", "return_target": _current_page}
		"back":
			if _current_page == "settings" and current_subroute != "" and current_subroute != "root":
				return {"action": "settings_root", "reason": "page_options_back_settings_root"}
			if _return_target != "":
				return {"action": "navigate_return_target", "to_page": _return_target, "reason": "page_options_back"}
			return {"action": "navigate_menu", "to_page": "menu", "reason": "page_options_back_menu"}
	return {"action": "close"}


func resolve_target_navigation(target_page: String, reason: String = "navigation_return") -> Dictionary:
	match target_page:
		"editor":
			return {"action": "navigate_editor_preserve", "to_page": "editor", "reason": reason}
		"saved_units":
			return {"action": "navigate_saved_units", "to_page": "saved_units", "reason": reason}
		"settings":
			return {"action": "navigate_settings", "to_page": "settings", "reason": reason}
		"scout":
			return {"action": "navigate_scout", "to_page": "scout", "reason": reason}
		"battle":
			return {"action": "navigate_battle_preserve", "to_page": "battle", "reason": reason}
	return {"action": "navigate_menu", "to_page": "menu", "reason": reason}


func snapshot() -> Dictionary:
	return {
		"current_page": _current_page,
		"previous_page": _previous_page,
		"return_target": _return_target,
		"pending_transition": _pending_transition.duplicate(true),
		"last_transition": _last_transition.duplicate(true),
		"history_size": _history.size(),
	}


func _record_transition(transition: Dictionary) -> void:
	_last_transition = transition.duplicate(true)
	_history.append(_last_transition)
	if _history.size() > 64:
		_history.pop_front()
