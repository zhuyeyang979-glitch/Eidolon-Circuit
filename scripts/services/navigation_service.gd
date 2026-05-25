extends RefCounted
class_name NavigationService

const PAGE_MENU := "menu"
const PAGE_EDITOR := "editor"
const PAGE_SAVED_UNITS := "saved_units"
const PAGE_SCOUT := "scout"
const PAGE_SETTINGS := "settings"
const PAGE_BATTLE := "battle"
const PAGE_LOADING := "loading"

const ACTION_CLOSE := "close"
const ACTION_SHOW_HELP := "show_help"
const ACTION_SETTINGS_ROOT := "settings_root"
const ACTION_NAVIGATE_MENU := "navigate_menu"
const ACTION_NAVIGATE_SETTINGS := "navigate_settings"
const ACTION_NAVIGATE_RETURN_TARGET := "navigate_return_target"
const ACTION_NAVIGATE_EDITOR_PRESERVE := "navigate_editor_preserve"
const ACTION_NAVIGATE_SAVED_UNITS := "navigate_saved_units"
const ACTION_NAVIGATE_SCOUT := "navigate_scout"
const ACTION_NAVIGATE_BATTLE_PRESERVE := "navigate_battle_preserve"

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
		PAGE_SETTINGS:
			if current != "" and current != PAGE_SETTINGS and current != PAGE_LOADING:
				return current
		PAGE_SAVED_UNITS:
			return PAGE_EDITOR if current == PAGE_EDITOR else PAGE_MENU
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
	elif to_page != PAGE_LOADING:
		_pending_transition = {}
	if transition_reason == "":
		transition_reason = "navigation:%s" % to_page
	_previous_page = _current_page
	_current_page = to_page
	if transition_return_target != "":
		_return_target = transition_return_target
	elif [PAGE_MENU, PAGE_EDITOR, PAGE_SCOUT, PAGE_BATTLE].has(to_page):
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
			return route_action(ACTION_CLOSE)
		"help":
			return route_action(ACTION_SHOW_HELP, "", "", _current_page)
		"main_menu":
			return route_action(ACTION_NAVIGATE_MENU, PAGE_MENU, "page_options_main_menu")
		"settings":
			return route_action(ACTION_NAVIGATE_SETTINGS, PAGE_SETTINGS, "page_options_settings", "", _current_page)
		"back":
			if _current_page == PAGE_SETTINGS and current_subroute != "" and current_subroute != "root":
				return route_action(ACTION_SETTINGS_ROOT, "", "page_options_back_settings_root")
			if _return_target != "":
				return route_action(ACTION_NAVIGATE_RETURN_TARGET, _return_target, "page_options_back")
			return route_action(ACTION_NAVIGATE_MENU, PAGE_MENU, "page_options_back_menu")
	return route_action(ACTION_CLOSE)


func resolve_target_navigation(target_page: String, reason: String = "navigation_return") -> Dictionary:
	match target_page:
		PAGE_EDITOR:
			return route_action(ACTION_NAVIGATE_EDITOR_PRESERVE, PAGE_EDITOR, reason)
		PAGE_SAVED_UNITS:
			return route_action(ACTION_NAVIGATE_SAVED_UNITS, PAGE_SAVED_UNITS, reason)
		PAGE_SETTINGS:
			return route_action(ACTION_NAVIGATE_SETTINGS, PAGE_SETTINGS, reason)
		PAGE_SCOUT:
			return route_action(ACTION_NAVIGATE_SCOUT, PAGE_SCOUT, reason)
		PAGE_BATTLE:
			return route_action(ACTION_NAVIGATE_BATTLE_PRESERVE, PAGE_BATTLE, reason)
	return route_action(ACTION_NAVIGATE_MENU, PAGE_MENU, reason)


static func route_action(action: String, to_page: String = "", reason: String = "", context: String = "", return_target_value: String = "", payload: Dictionary = {}) -> Dictionary:
	var result := {
		"action": action,
		"to_page": to_page,
		"reason": reason,
		"context": context,
		"return_target": return_target_value,
		"payload": payload.duplicate(true),
	}
	return result


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
