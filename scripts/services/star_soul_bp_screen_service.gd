extends RefCounted
class_name StarSoulBPScreenService

const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")

const DEFAULT_PICKS_PER_PLAYER := 10


func initial_model(first_player: int = 1, picks_per_player: int = DEFAULT_PICKS_PER_PLAYER, catalog: Array = [], options: Dictionary = {}) -> Dictionary:
	var rule_service = StarSoulBPServiceScript.new()
	var source_catalog := catalog if not catalog.is_empty() else rule_service.base_catalog()
	var model := {
		"first_player": _safe_player(first_player),
		"picks_per_player": maxi(0, picks_per_player),
		"catalog_entries": _normalize_catalog(source_catalog),
		"draft_picks": [],
		"turn_index": 0,
		"confirmed_by_player": {1: false, 2: false},
		"announce_seconds": float(options.get("announce_seconds", rule_service.DEFAULT_ANNOUNCE_SECONDS)),
		"per_player_order": Dictionary(options.get("per_player_order", {})).duplicate(true),
		"errors": [],
	}
	return screen_model(model)


func screen_model(raw_model: Dictionary) -> Dictionary:
	var model := raw_model.duplicate(true)
	var rule_service = StarSoulBPServiceScript.new()
	var first_player := _safe_player(int(model.get("first_player", 1)))
	var picks_per_player := maxi(0, int(model.get("picks_per_player", DEFAULT_PICKS_PER_PLAYER)))
	var turns := rule_service.draft_turns(first_player, picks_per_player)
	var draft_picks := _valid_pick_rows(Array(model.get("draft_picks", [])))
	if draft_picks.size() > turns.size():
		draft_picks = draft_picks.slice(0, turns.size())
	var turn_index := clampi(int(model.get("turn_index", draft_picks.size())), 0, turns.size())
	turn_index = max(turn_index, draft_picks.size())
	var unavailable_ids := _picked_lookup(draft_picks)
	var catalog_entries := _normalize_catalog(Array(model.get("catalog_entries", [])))
	var shared_pool := _shared_pool_entries(catalog_entries, unavailable_ids)
	var picked_entries := _picked_entries_by_player(draft_picks, catalog_entries)
	var confirmed_by_player := _confirmed_by_player(Dictionary(model.get("confirmed_by_player", {})))
	var confirm_ready := {
		1: Array(picked_entries.get(1, [])).size() >= picks_per_player,
		2: Array(picked_entries.get(2, [])).size() >= picks_per_player,
	}
	var all_picks_complete := draft_picks.size() >= turns.size()
	var complete := all_picks_complete and bool(confirmed_by_player.get(1, false)) and bool(confirmed_by_player.get(2, false))
	var result := {
		"first_player": first_player,
		"picks_per_player": picks_per_player,
		"turns": turns,
		"turn_index": turn_index,
		"current_turn": turns[turn_index] if turn_index < turns.size() else {},
		"catalog_entries": catalog_entries,
		"shared_pool": shared_pool,
		"available_ids": _available_ids(shared_pool),
		"unavailable_ids": unavailable_ids.keys(),
		"draft_picks": draft_picks,
		"picked_entries_by_player": picked_entries,
		"confirmed_by_player": confirmed_by_player,
		"confirm_ready_by_player": confirm_ready,
		"status": _status_for(all_picks_complete, complete),
		"complete": complete,
		"errors": Array(model.get("errors", [])).duplicate(),
		"announce_seconds": float(model.get("announce_seconds", rule_service.DEFAULT_ANNOUNCE_SECONDS)),
		"per_player_order": Dictionary(model.get("per_player_order", {})).duplicate(true),
	}
	if complete:
		result["draft_payload"] = _draft_payload(result)
	return result


func pick_intent(raw_model: Dictionary, player: int, star_soul_id: String) -> Dictionary:
	var model := screen_model(raw_model)
	var current_turn: Dictionary = Dictionary(model.get("current_turn", {}))
	if current_turn.is_empty():
		return _intent(false, "draft_complete", model)
	if int(current_turn.get("player", 0)) != _safe_player(player):
		return _intent(false, "not_current_player", model)
	var id := star_soul_id.strip_edges()
	if id == "":
		return _intent(false, "missing_star_soul_id", model)
	if not _catalog_lookup(Array(model.get("catalog_entries", []))).has(id):
		return _intent(false, "unknown_star_soul", model)
	if _picked_lookup(Array(model.get("draft_picks", []))).has(id):
		return _intent(false, "already_picked", model)
	var next_model := model.duplicate(true)
	var draft_picks: Array = Array(next_model.get("draft_picks", [])).duplicate(true)
	draft_picks.append({
		"turn": int(current_turn.get("turn", draft_picks.size())),
		"player": _safe_player(player),
		"pick_index": int(current_turn.get("pick_index", 0)),
		"star_soul_id": id,
	})
	next_model["draft_picks"] = draft_picks
	next_model["turn_index"] = draft_picks.size()
	next_model["confirmed_by_player"] = {1: false, 2: false}
	return _intent(true, "picked", screen_model(next_model))


func undo_intent(raw_model: Dictionary, player: int) -> Dictionary:
	var model := screen_model(raw_model)
	if bool(model.get("complete", false)):
		return _intent(false, "draft_complete", model)
	var draft_picks: Array = Array(model.get("draft_picks", [])).duplicate(true)
	if draft_picks.is_empty():
		return _intent(false, "nothing_to_undo", model)
	var last_pick: Dictionary = Dictionary(draft_picks[draft_picks.size() - 1])
	if int(last_pick.get("player", 0)) != _safe_player(player):
		return _intent(false, "last_pick_belongs_to_other_player", model)
	draft_picks.remove_at(draft_picks.size() - 1)
	var next_model := model.duplicate(true)
	next_model["draft_picks"] = draft_picks
	next_model["turn_index"] = draft_picks.size()
	next_model["confirmed_by_player"] = {1: false, 2: false}
	return _intent(true, "undone", screen_model(next_model))


func confirm_intent(raw_model: Dictionary, player: int) -> Dictionary:
	var model := screen_model(raw_model)
	var safe_player := _safe_player(player)
	var ready_by_player: Dictionary = Dictionary(model.get("confirm_ready_by_player", {}))
	if not bool(ready_by_player.get(safe_player, false)):
		return _intent(false, "player_not_ready", model)
	var confirmed_by_player: Dictionary = Dictionary(model.get("confirmed_by_player", {})).duplicate(true)
	confirmed_by_player[safe_player] = true
	var next_model := model.duplicate(true)
	next_model["confirmed_by_player"] = confirmed_by_player
	return _intent(true, "confirmed", screen_model(next_model))


func timeout_pick_intent(raw_model: Dictionary) -> Dictionary:
	var model := screen_model(raw_model)
	var current_turn: Dictionary = Dictionary(model.get("current_turn", {}))
	if current_turn.is_empty():
		return _intent(false, "draft_complete", model)
	var available_ids := Array(model.get("available_ids", []))
	if available_ids.is_empty():
		return _intent(false, "no_available_star_soul", model)
	var picked := pick_intent(model, int(current_turn.get("player", 1)), str(available_ids[0]))
	picked["reason"] = "timeout_auto_pick" if bool(picked.get("accepted", false)) else picked.get("reason", "timeout_failed")
	return picked


func _draft_payload(model: Dictionary) -> Dictionary:
	var rule_service = StarSoulBPServiceScript.new()
	var options := {
		"pool_ids": _catalog_lookup(Array(model.get("catalog_entries", []))).keys(),
		"announce_seconds": float(model.get("announce_seconds", rule_service.DEFAULT_ANNOUNCE_SECONDS)),
		"per_player_order": Dictionary(model.get("per_player_order", {})),
	}
	return rule_service.build_spawn_queue(
		Array(model.get("draft_picks", [])),
		int(model.get("first_player", 1)),
		int(model.get("picks_per_player", DEFAULT_PICKS_PER_PLAYER)),
		options
	)


func _intent(accepted: bool, reason: String, model: Dictionary) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"model": model,
	}


func _normalize_catalog(catalog: Array) -> Array:
	var result: Array = []
	var seen := {}
	for raw_entry in catalog:
		if not (raw_entry is Dictionary):
			continue
		var entry := Dictionary(raw_entry).duplicate(true)
		var id := str(entry.get("id", "")).strip_edges()
		if id == "" or bool(seen.get(id, false)):
			continue
		entry["id"] = id
		seen[id] = true
		result.append(entry)
	return result


func _valid_pick_rows(raw_picks: Array) -> Array:
	var result: Array = []
	for raw_pick in raw_picks:
		if not (raw_pick is Dictionary):
			continue
		var pick := Dictionary(raw_pick).duplicate(true)
		var player := int(pick.get("player", 0))
		var id := str(pick.get("star_soul_id", pick.get("id", ""))).strip_edges()
		if (player != 1 and player != 2) or id == "":
			continue
		pick["player"] = player
		pick["star_soul_id"] = id
		result.append(pick)
	return result


func _shared_pool_entries(catalog_entries: Array, unavailable_ids: Dictionary) -> Array:
	var result: Array = []
	for raw_entry in catalog_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry := Dictionary(raw_entry).duplicate(true)
		var id := str(entry.get("id", ""))
		entry["available"] = not bool(unavailable_ids.get(id, false))
		entry["unavailable"] = bool(unavailable_ids.get(id, false))
		result.append(entry)
	return result


func _picked_entries_by_player(draft_picks: Array, catalog_entries: Array) -> Dictionary:
	var catalog_by_id := _catalog_lookup(catalog_entries)
	var result := {1: [], 2: []}
	for raw_pick in draft_picks:
		if not (raw_pick is Dictionary):
			continue
		var pick: Dictionary = raw_pick
		var player := _safe_player(int(pick.get("player", 1)))
		var id := str(pick.get("star_soul_id", ""))
		var entry: Dictionary = Dictionary(catalog_by_id.get(id, {})).duplicate(true)
		entry["id"] = id
		entry["player"] = player
		entry["turn"] = int(pick.get("turn", Array(result[player]).size()))
		Array(result[player]).append(entry)
	return result


func _catalog_lookup(catalog_entries: Array) -> Dictionary:
	var result := {}
	for raw_entry in catalog_entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var id := str(entry.get("id", "")).strip_edges()
			if id != "":
				result[id] = entry
	return result


func _picked_lookup(draft_picks: Array) -> Dictionary:
	var result := {}
	for raw_pick in draft_picks:
		if raw_pick is Dictionary:
			var id := str(Dictionary(raw_pick).get("star_soul_id", "")).strip_edges()
			if id != "":
				result[id] = true
	return result


func _available_ids(shared_pool: Array) -> Array:
	var result: Array = []
	for raw_entry in shared_pool:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			if bool(entry.get("available", false)):
				result.append(str(entry.get("id", "")))
	return result


func _confirmed_by_player(raw_confirmed: Dictionary) -> Dictionary:
	return {
		1: bool(raw_confirmed.get(1, raw_confirmed.get("1", false))),
		2: bool(raw_confirmed.get(2, raw_confirmed.get("2", false))),
	}


func _status_for(all_picks_complete: bool, complete: bool) -> String:
	if complete:
		return "complete"
	if all_picks_complete:
		return "ready_to_confirm"
	return "drafting"


func _safe_player(player: int) -> int:
	return 2 if player == 2 else 1
