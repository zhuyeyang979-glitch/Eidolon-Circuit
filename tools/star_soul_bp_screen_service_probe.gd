extends SceneTree

const SERVICE_PATH := "res://scripts/services/star_soul_bp_screen_service.gd"
const RULE_SERVICE_PATH := "res://scripts/services/star_soul_bp_service.gd"

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(SERVICE_PATH), "Missing StarSoulBPScreenService script.")
	_require(FileAccess.file_exists(RULE_SERVICE_PATH), "Missing StarSoulBPService script.")
	if failed:
		quit(1)
		return

	var ServiceScript = load(SERVICE_PATH)
	_require(ServiceScript != null, "Cannot load StarSoulBPScreenService script.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()
	var catalog := [
		{"id": "defense_tower_a", "family": "defense_tower", "vp": 1},
		{"id": "punishment_tower_a", "family": "punishment_tower", "vp": 1},
		{"id": "cart_a", "family": "cart", "vp": 1},
		{"id": "wandering_giant_a", "family": "wandering_giant", "vp": 1},
		{"id": "loyalist_a", "family": "loyalist", "vp": 1},
	]
	var model: Dictionary = service.initial_model(2, 2, catalog)
	_require(String(model.get("status", "")) == "drafting", "Fresh model should be drafting.")
	_require(int(Dictionary(model.get("current_turn", {})).get("player", 0)) == 2, "BP first player should take the first pick.")
	_require(Array(model.get("available_ids", [])).has("defense_tower_a"), "Fresh shared pool should expose available IDs.")
	_require(Array(model.get("unavailable_ids", [])).is_empty(), "Fresh model should not have unavailable Star Souls.")

	var p2_pick: Dictionary = service.pick_intent(model, 2, "defense_tower_a")
	_require(bool(p2_pick.get("accepted", false)), "P2 first pick should be accepted: %s" % str(p2_pick))
	model = p2_pick.get("model", {})
	_require(int(Dictionary(model.get("current_turn", {})).get("player", 0)) == 1, "Turn should advance to P1 after P2 pick.")
	_require(Array(model.get("unavailable_ids", [])).has("defense_tower_a"), "Picked Star Soul should leave the shared pool.")
	_require(not _pool_entry_available(model, "defense_tower_a"), "Picked Star Soul should be disabled in the screen pool.")

	var duplicate: Dictionary = service.pick_intent(model, 1, "defense_tower_a")
	_require(not bool(duplicate.get("accepted", true)), "Duplicate shared-pool pick should be rejected.")
	_require(String(duplicate.get("reason", "")) == "already_picked", "Duplicate rejection should be explicit.")
	var wrong_player: Dictionary = service.pick_intent(model, 2, "punishment_tower_a")
	_require(not bool(wrong_player.get("accepted", true)), "Wrong-turn pick should be rejected.")
	_require(String(wrong_player.get("reason", "")) == "not_current_player", "Wrong-turn rejection should be explicit.")

	var p1_pick: Dictionary = service.pick_intent(model, 1, "punishment_tower_a")
	_require(bool(p1_pick.get("accepted", false)), "P1 pick should be accepted.")
	model = p1_pick.get("model", {})
	var undo_wrong: Dictionary = service.undo_intent(model, 2)
	_require(not bool(undo_wrong.get("accepted", true)), "A player should not undo the other player's last pick.")
	var undo_p1: Dictionary = service.undo_intent(model, 1)
	_require(bool(undo_p1.get("accepted", false)), "Last picker should be able to undo before confirmation.")
	model = undo_p1.get("model", {})
	_require(_pool_entry_available(model, "punishment_tower_a"), "Undo should restore the Star Soul to the shared pool.")
	_require(int(Dictionary(model.get("current_turn", {})).get("player", 0)) == 1, "Undo should restore the same player's turn.")

	var confirm_early: Dictionary = service.confirm_intent(model, 1)
	_require(not bool(confirm_early.get("accepted", true)), "Player cannot confirm before finishing all BP picks.")
	_require(String(confirm_early.get("reason", "")) == "player_not_ready", "Early confirm should be rejected by readiness.")

	for action in [
		[1, "punishment_tower_a"],
		[2, "cart_a"],
		[1, "wandering_giant_a"],
	]:
		var intent: Dictionary = service.pick_intent(model, int(action[0]), String(action[1]))
		_require(bool(intent.get("accepted", false)), "Expected pick to be accepted: %s" % str(action))
		model = intent.get("model", {})
	_require(String(model.get("status", "")) == "ready_to_confirm", "Model should be ready to confirm after both players finish picks.")
	_require(bool(Dictionary(model.get("confirm_ready_by_player", {})).get(1, false)), "P1 should be confirm-ready.")
	_require(bool(Dictionary(model.get("confirm_ready_by_player", {})).get(2, false)), "P2 should be confirm-ready.")

	var p2_confirm: Dictionary = service.confirm_intent(model, 2)
	_require(bool(p2_confirm.get("accepted", false)), "P2 confirm should be accepted.")
	model = p2_confirm.get("model", {})
	_require(not bool(model.get("complete", false)), "Draft should wait for both players to confirm.")
	var p1_confirm: Dictionary = service.confirm_intent(model, 1)
	_require(bool(p1_confirm.get("accepted", false)), "P1 confirm should be accepted.")
	model = p1_confirm.get("model", {})
	_require(bool(model.get("complete", false)), "Draft should complete after both players confirm.")
	_require(String(model.get("status", "")) == "complete", "Complete draft should expose complete status.")
	var payload: Dictionary = Dictionary(model.get("draft_payload", {}))
	_require(bool(payload.get("valid", false)), "Complete BP model should produce a valid draft payload: %s" % str(payload))
	_require(_queue_owners(Array(payload.get("queue", []))) == [2, 1, 2, 1], "Draft payload should preserve alternating owner queue.")

	var timeout_model: Dictionary = service.initial_model(1, 1, catalog)
	var timeout_pick: Dictionary = service.timeout_pick_intent(timeout_model)
	_require(bool(timeout_pick.get("accepted", false)), "Timeout fallback should auto-pick first available Star Soul.")
	_require(String(timeout_pick.get("reason", "")) == "timeout_auto_pick", "Timeout fallback should report timeout_auto_pick.")
	_require(Array(Dictionary(timeout_pick.get("model", {})).get("unavailable_ids", [])).has("defense_tower_a"), "Timeout pick should consume the shared-pool entry.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_BP_SCREEN_SERVICE_PROBE ok picks=%s" % str(_pick_ids(Array(model.get("draft_picks", [])))))
	quit(0)


func _pool_entry_available(model: Dictionary, star_soul_id: String) -> bool:
	for raw_entry in Array(model.get("shared_pool", [])):
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			if String(entry.get("id", "")) == star_soul_id:
				return bool(entry.get("available", false))
	return false


func _queue_owners(queue: Array) -> Array:
	var result: Array = []
	for raw_entry in queue:
		if raw_entry is Dictionary:
			result.append(int(Dictionary(raw_entry).get("owner", 0)))
	return result


func _pick_ids(picks: Array) -> Array:
	var result: Array = []
	for raw_pick in picks:
		if raw_pick is Dictionary:
			result.append(String(Dictionary(raw_pick).get("star_soul_id", "")))
	return result


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
