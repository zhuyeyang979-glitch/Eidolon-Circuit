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
	var RuleScript = load(RULE_SERVICE_PATH)
	_require(RuleScript != null, "Cannot load StarSoulBPService script.")
	if failed:
		quit(1)
		return
	var service = ServiceScript.new()
	var rule_service = RuleScript.new()
	var standard_model: Dictionary = service.initial_model(1)
	_require(int(standard_model.get("picks_per_player", 0)) == 10, "Default BP screen model should use ten picks per player.")
	_require(Array(standard_model.get("turns", [])).size() == 20, "Default BP screen model should expose twenty turns.")
	_require(Array(standard_model.get("available_ids", [])).size() >= 20, "Default BP screen model should expose enough shared-pool entries for standard BP.")
	while not Dictionary(standard_model.get("current_turn", {})).is_empty():
		var current_turn: Dictionary = Dictionary(standard_model.get("current_turn", {}))
		var available_ids: Array = Array(standard_model.get("available_ids", []))
		_require(not available_ids.is_empty(), "Standard BP should not exhaust the shared pool before all twenty picks.")
		if available_ids.is_empty():
			break
		var picked: Dictionary = service.pick_intent(standard_model, int(current_turn.get("player", 1)), String(available_ids[0]))
		_require(bool(picked.get("accepted", false)), "Standard BP default pick should be accepted: %s" % str(picked))
		standard_model = Dictionary(picked.get("model", {}))
	_require(Array(standard_model.get("draft_picks", [])).size() == 20, "Standard BP screen flow should collect twenty picks.")
	_require(Array(standard_model.get("available_ids", [])).is_empty(), "Standard BP screen flow should consume the shared pool when the base catalog has twenty entries.")
	_require(String(standard_model.get("status", "")) == "ready_to_confirm", "Standard BP screen flow should be ready to confirm after twenty picks.")
	_require(bool(Dictionary(standard_model.get("confirm_ready_by_player", {})).get(1, false)) and bool(Dictionary(standard_model.get("confirm_ready_by_player", {})).get(2, false)), "Both players should be confirm-ready after ten picks each.")
	for player in [1, 2]:
		var confirmed: Dictionary = service.confirm_intent(standard_model, player)
		_require(bool(confirmed.get("accepted", false)), "Standard BP confirmation should be accepted for P%d." % player)
		standard_model = Dictionary(confirmed.get("model", {}))
	_require(bool(standard_model.get("complete", false)), "Standard BP screen flow should complete after both confirmations.")
	var standard_payload: Dictionary = Dictionary(standard_model.get("draft_payload", {}))
	_require(bool(standard_payload.get("valid", false)), "Standard BP screen flow should produce a valid draft payload: %s" % str(standard_payload))
	_require(Array(standard_payload.get("queue", [])).size() == 20, "Standard BP payload should contain twenty queued Star Souls.")
	_require(_queue_owners(Array(standard_payload.get("queue", []))).slice(0, 6) == [1, 2, 1, 2, 1, 2], "Standard BP payload should alternate owners from first player.")
	_require(Array(rule_service.base_catalog()).size() == 20, "Base Star Soul catalog should currently contain the standard twenty entries.")

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
