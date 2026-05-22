extends RefCounted
class_name GameStateStore

const DOMAIN_GLOBAL := "global"
const DOMAIN_EDITOR := "editor"
const DOMAIN_BATTLE := "battle"
const DOMAIN_SAVED_UNITS := "saved_units"
const DOMAIN_SETTINGS := "settings"
const DOMAIN_SCOUT := "scout"
const DOMAIN_MENU := "menu"

var app_mode := ""
var mutation_count := 0
var _domains := {}


func _init() -> void:
	for domain in [DOMAIN_GLOBAL, DOMAIN_EDITOR, DOMAIN_BATTLE, DOMAIN_SAVED_UNITS, DOMAIN_SETTINGS, DOMAIN_SCOUT, DOMAIN_MENU]:
		ensure_domain(domain)


func ensure_domain(domain: String) -> Dictionary:
	if not _domains.has(domain):
		_domains[domain] = {
			"revision": 0,
			"dirty_flags": 0,
			"last_mutation_reason": "",
			"mutation_count": 0,
		}
	return _domains[domain]


func set_app_mode(next_mode: String, reason: String = "app_mode") -> void:
	if app_mode == next_mode:
		return
	app_mode = next_mode
	mutate(DOMAIN_GLOBAL, reason, 1)


func mutate(domain: String, reason: String = "", dirty_flags: int = 0) -> int:
	var state := ensure_domain(domain)
	state["revision"] = int(state.get("revision", 0)) + 1
	state["dirty_flags"] = int(state.get("dirty_flags", 0)) | dirty_flags
	state["last_mutation_reason"] = reason
	state["mutation_count"] = int(state.get("mutation_count", 0)) + 1
	mutation_count += 1
	_domains[domain] = state
	return int(state["revision"])


func mark_dirty(domain: String, dirty_flags: int, reason: String = "") -> void:
	var state := ensure_domain(domain)
	state["dirty_flags"] = int(state.get("dirty_flags", 0)) | dirty_flags
	if reason != "":
		state["last_mutation_reason"] = reason
	_domains[domain] = state


func clear_dirty(domain: String, dirty_flags: int = -1) -> void:
	var state := ensure_domain(domain)
	if dirty_flags == -1:
		state["dirty_flags"] = 0
	else:
		state["dirty_flags"] = int(state.get("dirty_flags", 0)) & ~dirty_flags
	_domains[domain] = state


func revision(domain: String) -> int:
	return int(ensure_domain(domain).get("revision", 0))


func dirty_flags(domain: String) -> int:
	return int(ensure_domain(domain).get("dirty_flags", 0))


func last_reason(domain: String) -> String:
	return String(ensure_domain(domain).get("last_mutation_reason", ""))


func domain_summary(domain: String) -> String:
	var state := ensure_domain(domain)
	return "%s:r%d d%d %s" % [
		domain,
		int(state.get("revision", 0)),
		int(state.get("dirty_flags", 0)),
		String(state.get("last_mutation_reason", "")),
	]


func snapshot_summary() -> String:
	var parts := ["mode=%s" % app_mode]
	for domain in [DOMAIN_EDITOR, DOMAIN_BATTLE, DOMAIN_SAVED_UNITS, DOMAIN_SETTINGS, DOMAIN_SCOUT]:
		var state := ensure_domain(domain)
		var dirty := int(state.get("dirty_flags", 0))
		if dirty != 0:
			parts.append("%s:r%d/d%d" % [domain, int(state.get("revision", 0)), dirty])
	return " ".join(parts)
