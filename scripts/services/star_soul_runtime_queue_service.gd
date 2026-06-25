extends RefCounted
class_name StarSoulRuntimeQueueService

const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")


func initial_state(draft_payload: Dictionary, catalog_by_id: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	if not bool(draft_payload.get("valid", false)):
		return {
			"valid": false,
			"errors": Array(draft_payload.get("errors", ["invalid_draft_payload"])).duplicate(),
			"phase": "invalid",
			"queue": [],
		}
	var queue := _valid_queue(Array(draft_payload.get("queue", [])))
	var state := {
		"valid": true,
		"errors": [],
		"queue": queue,
		"catalog_by_id": _duplicate_catalog(catalog_by_id),
		"next_index": 0,
		"phase": "complete" if queue.is_empty() else "announcing",
		"countdown": 0.0,
		"pending_entry": {},
		"active_entry": {},
		"vp_by_player": {1: 0, 2: 0},
		"history": [],
		"spawn_serial": 0,
		"replay_seed": int(options.get("replay_seed", 0)),
	}
	return _announce_next(state)


func tick(raw_state: Dictionary, delta: float) -> Dictionary:
	var state := _normalized_state(raw_state)
	if String(state.get("phase", "")) != "announcing":
		return _intent("tick", false, state)
	var countdown := maxf(0.0, float(state.get("countdown", 0.0)) - maxf(0.0, delta))
	state["countdown"] = countdown
	if countdown > 0.0:
		return _intent("announce_tick", false, state)
	state["phase"] = "spawn_ready"
	state["spawn_intent"] = _spawn_intent_for(state)
	return _intent("spawn_ready", true, state)


func spawn_committed(raw_state: Dictionary, runtime_id: String = "") -> Dictionary:
	var state := _normalized_state(raw_state)
	if String(state.get("phase", "")) != "spawn_ready":
		return _intent("no_spawn_ready", false, state)
	if not Dictionary(state.get("active_entry", {})).is_empty():
		return _intent("active_star_soul_exists", false, state)
	var pending: Dictionary = Dictionary(state.get("pending_entry", {})).duplicate(true)
	if pending.is_empty():
		return _intent("missing_pending_entry", false, state)
	var spawn_serial := int(state.get("spawn_serial", 0)) + 1
	pending["runtime_id"] = runtime_id if runtime_id.strip_edges() != "" else "star_soul_%03d" % spawn_serial
	pending["spawn_serial"] = spawn_serial
	pending["vp"] = _vp_for_entry(pending, Dictionary(state.get("catalog_by_id", {})))
	state["spawn_serial"] = spawn_serial
	state["active_entry"] = pending
	state["pending_entry"] = {}
	state.erase("spawn_intent")
	state["phase"] = "active"
	state["countdown"] = 0.0
	return _intent("spawn_committed", true, state)


func active_exit(raw_state: Dictionary, exit_reason: String, runtime_id: String = "") -> Dictionary:
	var state := _normalized_state(raw_state)
	var active: Dictionary = Dictionary(state.get("active_entry", {})).duplicate(true)
	if active.is_empty():
		return _intent("no_active_star_soul", false, state)
	if runtime_id.strip_edges() != "" and String(active.get("runtime_id", "")) != runtime_id:
		return _intent("runtime_id_mismatch", false, state)
	var reason := exit_reason.strip_edges()
	if reason == "":
		reason = "unknown"
	var rule_service = StarSoulBPServiceScript.new()
	var award: Dictionary = rule_service.vp_award_for_exit(int(active.get("owner", 1)), int(active.get("vp", 0)), reason)
	var vp_by_player: Dictionary = Dictionary(state.get("vp_by_player", {1: 0, 2: 0})).duplicate(true)
	if bool(award.get("award", false)):
		var player := int(award.get("player", 0))
		vp_by_player[player] = int(vp_by_player.get(player, 0)) + int(award.get("vp", 0))
	state["vp_by_player"] = {1: int(vp_by_player.get(1, 0)), 2: int(vp_by_player.get(2, 0))}
	var history: Array = Array(state.get("history", [])).duplicate(true)
	history.append({
		"sequence_index": int(active.get("sequence_index", history.size())),
		"owner": int(active.get("owner", 1)),
		"star_soul_id": String(active.get("star_soul_id", "")),
		"runtime_id": String(active.get("runtime_id", "")),
		"exit_reason": reason,
		"vp_award": award,
	})
	state["history"] = history
	state["active_entry"] = {}
	state["next_index"] = int(active.get("sequence_index", int(state.get("next_index", 0)))) + 1
	state.erase("spawn_intent")
	return _intent("active_exit", true, _announce_next(state))


func current_announcement(raw_state: Dictionary) -> Dictionary:
	var state := _normalized_state(raw_state)
	if String(state.get("phase", "")) != "announcing":
		return {"action": "none"}
	var pending: Dictionary = Dictionary(state.get("pending_entry", {})).duplicate(true)
	if pending.is_empty():
		return {"action": "none"}
	pending["action"] = "announce"
	pending["countdown"] = float(state.get("countdown", 0.0))
	return pending


func _announce_next(raw_state: Dictionary) -> Dictionary:
	var state := raw_state.duplicate(true)
	var queue: Array = Array(state.get("queue", []))
	var next_index := int(state.get("next_index", 0))
	state["active_entry"] = Dictionary(state.get("active_entry", {}))
	state.erase("spawn_intent")
	if next_index < 0 or next_index >= queue.size():
		state["phase"] = "complete"
		state["pending_entry"] = {}
		state["countdown"] = 0.0
		return state
	var entry: Dictionary = Dictionary(queue[next_index]).duplicate(true)
	entry["vp"] = _vp_for_entry(entry, Dictionary(state.get("catalog_by_id", {})))
	state["phase"] = "announcing"
	state["pending_entry"] = entry
	state["countdown"] = maxf(0.0, float(entry.get("announce_seconds", 10.0)))
	return state


func _spawn_intent_for(state: Dictionary) -> Dictionary:
	var pending: Dictionary = Dictionary(state.get("pending_entry", {})).duplicate(true)
	return {
		"action": "spawn_star_soul",
		"entry": pending,
		"sequence_index": int(pending.get("sequence_index", int(state.get("next_index", 0)))),
		"star_soul_id": String(pending.get("star_soul_id", "")),
		"owner": int(pending.get("owner", 1)),
		"vp": _vp_for_entry(pending, Dictionary(state.get("catalog_by_id", {}))),
	}


func _intent(reason: String, changed: bool, state: Dictionary) -> Dictionary:
	return {
		"reason": reason,
		"changed": changed,
		"state": state,
	}


func _normalized_state(raw_state: Dictionary) -> Dictionary:
	var state := raw_state.duplicate(true)
	state["queue"] = _valid_queue(Array(state.get("queue", [])))
	state["catalog_by_id"] = _duplicate_catalog(Dictionary(state.get("catalog_by_id", {})))
	state["vp_by_player"] = {
		1: int(Dictionary(state.get("vp_by_player", {})).get(1, Dictionary(state.get("vp_by_player", {})).get("1", 0))),
		2: int(Dictionary(state.get("vp_by_player", {})).get(2, Dictionary(state.get("vp_by_player", {})).get("2", 0))),
	}
	state["history"] = Array(state.get("history", [])).duplicate(true)
	state["pending_entry"] = Dictionary(state.get("pending_entry", {})).duplicate(true)
	state["active_entry"] = Dictionary(state.get("active_entry", {})).duplicate(true)
	return state


func _valid_queue(raw_queue: Array) -> Array:
	var result: Array = []
	for index in range(raw_queue.size()):
		if not (raw_queue[index] is Dictionary):
			continue
		var entry := Dictionary(raw_queue[index]).duplicate(true)
		var star_soul_id := String(entry.get("star_soul_id", "")).strip_edges()
		if star_soul_id == "":
			continue
		entry["star_soul_id"] = star_soul_id
		entry["owner"] = 2 if int(entry.get("owner", 1)) == 2 else 1
		entry["opponent"] = 1 if int(entry.get("owner", 1)) == 2 else 2
		entry["sequence_index"] = int(entry.get("sequence_index", result.size()))
		entry["announce_seconds"] = maxf(0.0, float(entry.get("announce_seconds", 10.0)))
		result.append(entry)
	return result


func _duplicate_catalog(catalog_by_id: Dictionary) -> Dictionary:
	var result := {}
	for key in catalog_by_id.keys():
		var entry = catalog_by_id[key]
		if entry is Dictionary:
			result[str(key)] = Dictionary(entry).duplicate(true)
	return result


func _vp_for_entry(entry: Dictionary, catalog_by_id: Dictionary) -> int:
	if entry.has("vp"):
		return maxi(0, int(entry.get("vp", 0)))
	var star_soul_id := String(entry.get("star_soul_id", ""))
	var catalog_entry: Dictionary = Dictionary(catalog_by_id.get(star_soul_id, {}))
	return maxi(0, int(catalog_entry.get("vp", 0)))
