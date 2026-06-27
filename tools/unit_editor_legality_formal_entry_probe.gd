extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _cleanup(path: String) -> void:
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _team_payload_from_player(main, player_id: int, team_name: String) -> Dictionary:
	return {
		"schema_version": MainScene.SAVED_TEAM_SCHEMA_VERSION,
		"team_name": team_name,
		"rule_id": String(main._team_rule_profile().get("rule_id", "")),
		"match_format": "light",
		"roster_cap": int(main._current_roster_cap()),
		"sortie_cap": int(main._current_sortie_cap()),
		"slots": main._team_export_slots(player_id),
	}


func _write_payload(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write saved-team fixture: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _corrupt_first_puppet_source_code(payload: Dictionary) -> Dictionary:
	var next_payload := payload.duplicate(true)
	var slots: Array = Array(next_payload.get("slots", [])).duplicate(true)
	for i in range(slots.size()):
		if not (slots[i] is Dictionary):
			continue
		var slot: Dictionary = Dictionary(slots[i]).duplicate(true)
		if String(slot.get("role", "")) != "puppet" or not (slot.get("blueprint", {}) is Dictionary):
			continue
		var bp: Dictionary = Dictionary(slot.get("blueprint", {})).duplicate(true)
		bp["special"] = -1
		var payloads: Array = []
		for raw_payload in Array(bp.get("slot_payloads", [])):
			if not (raw_payload is Dictionary):
				continue
			var slot_payload: Dictionary = Dictionary(raw_payload)
			if slot_payload.has("special") or String(slot_payload.get("slot", "")) == "special" or String(slot_payload.get("kind", "")) in ["code", "source_code"]:
				continue
			payloads.append(slot_payload)
		bp["slot_payloads"] = payloads
		slot["blueprint"] = bp
		slots[i] = slot
		next_payload["slots"] = slots
		return next_payload
	_fail("Fixture roster did not include a puppet slot to corrupt.")
	return next_payload


func _first_puppet_entry(main, player_id: int) -> Dictionary:
	for raw_entry in main._team_sortie_order(player_id):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("role", "")) == "puppet":
			return Dictionary(raw_entry)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	var legal_summary: Dictionary = main._team_battle_entry_summary(1)
	_require(bool(legal_summary.get("valid", false)), "Legalized P1 roster should start battle-ready: %s" % str(legal_summary))
	if failed:
		quit(1)
		return

	var valid_payload := _team_payload_from_player(main, 1, "Formal Entry Valid Fixture")
	var illegal_payload := _corrupt_first_puppet_source_code(valid_payload)
	var illegal_path := "user://saved_teams/probe_formal_entry_illegal_team.json"
	main._ensure_saved_teams_dir()
	_write_payload(illegal_path, illegal_payload)
	if failed:
		_cleanup(illegal_path)
		quit(1)
		return
	_require(not main._load_saved_team_to_current_roster(illegal_path), "Saved-team load should reject puppet_source_code_missing.")
	_require(not main._import_editor_team(illegal_path), "Editor team import should reject puppet_source_code_missing.")
	_cleanup(illegal_path)
	if failed:
		quit(1)
		return

	root.remove_child(main)
	main.queue_free()
	main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	_require(bool(main._team_battle_entry_summary(1).get("valid", false)), "P1 should be battle-ready before PVP scout.")
	_require(bool(main._team_battle_entry_summary(2).get("valid", false)), "P2 should be battle-ready before PVP scout.")
	var p1_loadout: Array = main._team_sortie_order(1).duplicate(true)
	var p2_loadout: Array = main._team_sortie_order(2).duplicate(true)
	main.pending_battle_mode = MainScene.MODE_PVP
	main._start_battle(MainScene.MODE_PVP, true)
	main.sortie_loadouts[1] = p1_loadout
	main.sortie_loadouts[2] = p2_loadout
	main._normalize_initial_sortie_for_cost(1)
	main._normalize_initial_sortie_for_cost(2)
	main._try_begin_battle_from_scout()
	_require(bool(main.star_soul_bp_active), "Legal PVP scout confirmation should open Star Soul BP before battle. state=%s p1=%s p2=%s l1=%s l2=%s hint=%s" % [
		String(main.game_state),
		str(main._team_battle_entry_summary(1)),
		str(main._team_battle_entry_summary(2)),
		str(main._team_sortie_order(1)),
		str(main._team_sortie_order(2)),
		main.scout_hint_label.text if main.scout_hint_label != null else "",
	])
	var puppet_entry := _first_puppet_entry(main, 1)
	_require(not puppet_entry.is_empty(), "P1 sortie should include a puppet entry.")
	if failed:
		quit(1)
		return
	var puppet_index := int(puppet_entry.get("index", 0))
	var corrupted_puppet: Dictionary = Dictionary(main.blueprints[1]["puppet"][puppet_index]).duplicate(true)
	corrupted_puppet["special"] = -1
	var remaining_payloads: Array = []
	for raw_payload in Array(corrupted_puppet.get("slot_payloads", [])):
		if not (raw_payload is Dictionary):
			continue
		var slot_payload: Dictionary = Dictionary(raw_payload)
		if slot_payload.has("special") or String(slot_payload.get("slot", "")) == "special" or String(slot_payload.get("kind", "")) in ["code", "source_code"]:
			continue
		remaining_payloads.append(slot_payload)
	corrupted_puppet["slot_payloads"] = remaining_payloads
	main.blueprints[1]["puppet"][puppet_index] = corrupted_puppet
	main.ai_roster_stats_cache.clear()
	var invalid_summary: Dictionary = main._team_battle_entry_summary(1)
	_require(not bool(invalid_summary.get("valid", true)), "Corrupted P1 sortie should be battle-invalid before BP completion: %s" % str(invalid_summary))
	main.star_soul_bp_model["draft_payload"] = {"valid": true, "probe": "formal_entry_recheck"}
	main._complete_star_soul_bp()
	_require(main.game_state != MainScene.STATE_BATTLE, "Star Soul BP completion should recheck and block illegal PVP battle entry.")
	_require(not bool(main.star_soul_bp_active), "Blocked BP completion should close the BP overlay.")

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_FORMAL_ENTRY_PROBE ok")
	quit(0)
