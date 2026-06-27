extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _cleanup(path: String) -> void:
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main._current_roster_cap() != 5 or main._current_sortie_cap() != 3:
		_fail("Initial model should expose only 5 pick 3.")
		return
	if String(main._team_rule_profile().get("rule_id", "")) != "light_5_pick_3_v1":
		_fail("Main should expose the active light_5_pick_3_v1 profile.")
		return
	var battle_summary: Dictionary = main._team_battle_entry_summary(1)
	if not battle_summary.has("audit") or String(battle_summary.get("rule_id", "")) != "light_5_pick_3_v1":
		_fail("Battle entry summary should expose the unified team legality audit.")
		return

	var one_entry := {
		"role": "hero",
		"path": "probe://incomplete-hero",
		"unit_name": "Incomplete Hero",
		"blueprint": main._make_editor_blank_blueprint("hero"),
	}
	var incomplete_path: String = main._save_team_from_saved_unit_selection("Incomplete Probe Team", [one_entry])
	if incomplete_path != "":
		_cleanup(incomplete_path)
		_fail("Incomplete roster should not be saved as a formal team.")
		return
	var incomplete_export_path := "user://saved_teams/probe_incomplete_export.json"
	if main._export_editor_team(incomplete_export_path) != "" or FileAccess.file_exists(incomplete_export_path):
		_cleanup(incomplete_export_path)
		_fail("TeamEdit export should not persist an incomplete formal team.")
		return
	main._legalize_ai_player_roster(1, true)
	var generated_audit: Dictionary = main._team_legality_live_roster_audit(1)
	if not bool(generated_audit.get("roster_ready", false)):
		var hero_bp: Dictionary = main._blueprint_for(1, "hero", 0)
		var direct_repair: Dictionary = hero_bp.duplicate(true)
		main._ensure_ai_execution_binding("hero", direct_repair)
		_fail("AI roster legalization should produce a formal five-unit roster: audit=%s entries=%s hero_topology=%s hero_payloads=%s hero_saved_bindings=%s hero_bindings=%s direct_payloads=%s direct_bindings=%s" % [str(generated_audit), str(main._team_legality_live_entries(1, main._all_roster_order(1))), str(hero_bp.get("custom_topology", {})), str(hero_bp.get("slot_payloads", [])), str(hero_bp.get("module_bindings", [])), str(main._runtime_module_bindings_for_blueprint("hero", hero_bp)), str(direct_repair.get("slot_payloads", [])), str(direct_repair.get("module_bindings", []))])
		return
	var generated_battle: Dictionary = main._team_battle_entry_summary(1)
	if not bool(generated_battle.get("valid", false)):
		_fail("AI roster legalization should also choose a legal three-unit sortie and starter: %s" % str(generated_battle))
		return

	var unsupported_path := "user://saved_teams/probe_unsupported_standard_team.json"
	main._ensure_saved_teams_dir()
	var unsupported_payload := {
		"schema_version": MainScene.SAVED_TEAM_SCHEMA_VERSION,
		"team_name": "Unsupported Standard Probe",
		"match_format": "standard",
		"roster_cap": 10,
		"sortie_cap": 6,
		"slots": [],
	}
	for _i in range(10):
		unsupported_payload["slots"].append({"empty": true})
	var file := FileAccess.open(unsupported_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not create unsupported-team fixture.")
		return
	file.store_string(JSON.stringify(unsupported_payload, "\t"))
	file.close()
	if main._load_saved_team_to_current_roster(unsupported_path):
		_cleanup(unsupported_path)
		_fail("Unsupported 10/6 team should not load into the active roster.")
		return
	if not FileAccess.file_exists(unsupported_path):
		_fail("Unsupported current-schema team should be preserved on disk.")
		return
	_cleanup(unsupported_path)

	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"const TeamLegalityService = preload(\"res://scripts/services/team_legality_service.gd\")",
		"var team_legality_service: TeamLegalityService",
		"team_legality_service = TeamLegalityService.new()",
		"func _team_rule_profile() -> Dictionary",
		"\"rule_id\": String(_team_rule_profile().get(\"rule_id\", \"\"))",
	]:
		if source.find(token) < 0:
			_fail("Main team legality integration missing token: %s" % token)
			return
	var has_team_audit_call := source.find("team_legality_service.audit") >= 0 or source.find("_team_legality_service().audit") >= 0
	if not has_team_audit_call:
		_fail("Main team legality integration missing team legality audit call.")
		return
	print("TEAM_LEGALITY_MAIN_INTEGRATION_PROBE ok")
	quit(0)
