extends RefCounted
class_name AppModeHost

const MODE_MENU := "menu"
const MODE_TEAM_EDIT := "team_edit"
const MODE_SAVED_UNITS := "saved_units"
const MODE_TRAINING := "training"
const MODE_BATTLE := "battle"
const MODE_SETTINGS := "settings"

const PAGE_MENU := "menu"
const PAGE_EDITOR := "editor"
const PAGE_SAVED_UNITS := "saved_units"
const PAGE_SCOUT := "scout"
const PAGE_SETTINGS := "settings"
const PAGE_BATTLE := "battle"

const VALID_MODE_KEYS := [
	MODE_MENU,
	MODE_TEAM_EDIT,
	MODE_SAVED_UNITS,
	MODE_TRAINING,
	MODE_BATTLE,
	MODE_SETTINGS,
]

const PAGE_MODE_KEYS := {
	PAGE_MENU: MODE_MENU,
	PAGE_EDITOR: MODE_TEAM_EDIT,
	PAGE_SAVED_UNITS: MODE_SAVED_UNITS,
	PAGE_SETTINGS: MODE_SETTINGS,
	PAGE_BATTLE: MODE_BATTLE,
}

var current_mode_key := ""
var previous_mode_key := ""
var transition_count := 0
var transition_log: Array = []


func valid_mode_keys() -> Array:
	return VALID_MODE_KEYS.duplicate()


func is_valid_mode_key(mode_key: String) -> bool:
	return VALID_MODE_KEYS.has(mode_key)


func normalized_payload(payload: Dictionary) -> Dictionary:
	var next_payload := payload.duplicate(true)
	if next_payload.has("mode"):
		next_payload["mode"] = String(next_payload.get("mode", "")).strip_edges()
	return next_payload


func mode_key_for_page(page_key: String, payload: Dictionary = {}) -> String:
	var page := page_key.strip_edges()
	var page_payload := normalized_payload(payload)
	var page_mode := String(page_payload.get("mode", ""))
	if page == PAGE_SCOUT:
		if page_mode == MODE_TRAINING:
			return MODE_TRAINING
		if page_mode != "":
			return MODE_BATTLE
	if page == PAGE_BATTLE and page_mode == MODE_TRAINING:
		return MODE_TRAINING
	return String(PAGE_MODE_KEYS.get(page, ""))


func transition_intent(target_mode_key: String, request_reason: String = "", payload: Dictionary = {}) -> Dictionary:
	var target_key := target_mode_key.strip_edges()
	var resolved_reason := request_reason.strip_edges()
	var resolved_payload := normalized_payload(payload)
	if target_key == "":
		return {
			"accepted": false,
			"reject_reason": "empty_mode_key",
			"target_mode_key": target_key,
		}
	if not is_valid_mode_key(target_key):
		return {
			"accepted": false,
			"reject_reason": "unknown_mode_key",
			"target_mode_key": target_key,
		}
	return {
		"accepted": true,
		"noop": target_key == current_mode_key,
		"previous_mode_key": current_mode_key,
		"target_mode_key": target_key,
		"request_reason": resolved_reason,
		"payload": resolved_payload,
	}


func commit_transition(intent: Dictionary) -> bool:
	if not bool(intent.get("accepted", false)):
		return false
	if bool(intent.get("noop", false)):
		return true
	var target_key := String(intent.get("target_mode_key", ""))
	if not is_valid_mode_key(target_key):
		return false
	previous_mode_key = current_mode_key
	current_mode_key = target_key
	transition_count += 1
	transition_log.append({
		"from": previous_mode_key,
		"to": current_mode_key,
		"reason": String(intent.get("request_reason", "")),
	})
	return true


func reset(initial_mode_key: String = "") -> bool:
	if initial_mode_key != "" and not is_valid_mode_key(initial_mode_key):
		return false
	current_mode_key = initial_mode_key
	previous_mode_key = ""
	transition_count = 0
	transition_log.clear()
	return true
