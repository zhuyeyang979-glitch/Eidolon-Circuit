extends SceneTree

const TeamLegalityService := preload("res://scripts/services/team_legality_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _entry(entry_id: String, role_key: String, cost: int = 100, deploy_cost: int = 100, length: float = 2.0, legal: bool = true) -> Dictionary:
	return {
		"entry_id": entry_id,
		"role": role_key,
		"cost": cost,
		"deploy_cost": deploy_cost,
		"length": length,
		"legal": legal,
		"illegal_note": "" if legal else "INVALID: probe unit.",
	}


func _has_code(report: Dictionary, key: String, code: String) -> bool:
	return Array(report.get(key, [])).has(code)


func _init() -> void:
	var service := TeamLegalityService.new()
	var profile := service.active_profile()
	if String(profile.get("rule_id", "")) != "light_5_pick_3_v1":
		_fail("Active rule profile should be light_5_pick_3_v1: %s" % str(profile))
	if int(profile.get("roster_size", 0)) != 5 or int(profile.get("sortie_size", 0)) != 3:
		_fail("Active profile should define 5 pick 3: %s" % str(profile))

	var legacy_light := service.profile_for_saved_payload({"match_format": "light", "roster_cap": 5, "sortie_cap": 3})
	if String(legacy_light.get("rule_id", "")) != "light_5_pick_3_v1":
		_fail("Legacy light payload should resolve to the active profile.")
	if not service.profile_for_saved_payload({"match_format": "standard", "roster_cap": 10, "sortie_cap": 6}).is_empty():
		_fail("Legacy standard payload should remain unsupported during the initial model.")

	var empty := service.audit(profile, [])
	if not bool(empty.get("draft_valid", false)) or bool(empty.get("roster_ready", true)):
		_fail("Empty draft should remain editable but not roster-ready: %s" % str(empty))
	if not _has_code(empty, "roster_blocking_codes", "roster_count"):
		_fail("Empty draft should report roster_count.")

	var roster := [
		_entry("hero-a", "hero", 220, 160, 3.7),
		_entry("hero-b", "hero", 210, 180, 3.0),
		_entry("puppet-a", "puppet", 180, 120, 2.7),
		_entry("puppet-b", "puppet", 170, 110, 2.2),
		_entry("barrier-a", "barrier", 260, 190, 4.2),
	]
	var ready := service.audit(profile, roster)
	if not bool(ready.get("roster_ready", false)):
		_fail("Balanced five-unit roster should be ready: %s" % str(ready))
	if bool(ready.get("sortie_ready", true)) or bool(ready.get("battle_ready", true)):
		_fail("Roster without a sortie should not be sortie- or battle-ready.")

	var sortie := [roster[0], roster[2], roster[4]]
	var battle := service.audit(profile, roster, sortie, roster[0])
	if not bool(battle.get("roster_ready", false)) or not bool(battle.get("sortie_ready", false)) or not bool(battle.get("battle_ready", false)):
		_fail("H/P/B sortie with an eligible starter should be battle-ready: %s" % str(battle))

	var missing_barrier := roster.duplicate(true)
	missing_barrier[4] = _entry("hero-c", "hero")
	var missing_report := service.audit(profile, missing_barrier)
	if bool(missing_report.get("roster_ready", true)) or not _has_code(missing_report, "roster_blocking_codes", "roster_missing_role:barrier"):
		_fail("Formal roster should require a barrier: %s" % str(missing_report))

	var over_budget := roster.duplicate(true)
	over_budget[0]["cost"] = 1600
	var budget_report := service.audit(profile, over_budget)
	if bool(budget_report.get("draft_valid", true)) or not _has_code(budget_report, "roster_blocking_codes", "team_budget"):
		_fail("Over-budget roster should be rejected: %s" % str(budget_report))

	var duplicate := roster.duplicate(true)
	duplicate[4]["entry_id"] = "hero-a"
	var duplicate_report := service.audit(profile, duplicate)
	if bool(duplicate_report.get("draft_valid", true)) or not _has_code(duplicate_report, "roster_blocking_codes", "duplicate_roster_entry"):
		_fail("Duplicate roster entries should be rejected: %s" % str(duplicate_report))

	var illegal := roster.duplicate(true)
	illegal[1]["legal"] = false
	illegal[1]["illegal_note"] = "INVALID: broken probe unit."
	var illegal_report := service.audit(profile, illegal)
	if bool(illegal_report.get("draft_valid", true)) or not _has_code(illegal_report, "roster_blocking_codes", "illegal_roster_unit"):
		_fail("Illegal units should block the roster: %s" % str(illegal_report))

	var too_many_long := roster.duplicate(true)
	too_many_long[1]["length"] = 3.8
	var length_report := service.audit(profile, too_many_long)
	if bool(length_report.get("roster_ready", true)) or not _has_code(length_report, "roster_blocking_codes", "length_band:3.5"):
		_fail("Length-band overflow should block roster readiness: %s" % str(length_report))

	var wrong_sortie := [roster[0], roster[1], roster[2]]
	var wrong_sortie_report := service.audit(profile, roster, wrong_sortie, roster[0])
	if bool(wrong_sortie_report.get("sortie_ready", true)) or not _has_code(wrong_sortie_report, "sortie_blocking_codes", "sortie_missing_role:barrier"):
		_fail("Sortie should require exactly one of each role: %s" % str(wrong_sortie_report))

	var outsider := _entry("barrier-outsider", "barrier")
	var outsider_report := service.audit(profile, roster, [roster[0], roster[2], outsider], roster[0])
	if bool(outsider_report.get("sortie_ready", true)) or not _has_code(outsider_report, "sortie_blocking_codes", "sortie_not_in_roster"):
		_fail("Sortie entries must belong to the roster: %s" % str(outsider_report))

	var expensive_starter: Dictionary = Dictionary(roster[0]).duplicate(true)
	expensive_starter["deploy_cost"] = 201
	var starter_report := service.audit(profile, roster, sortie, expensive_starter)
	if bool(starter_report.get("battle_ready", true)) or not _has_code(starter_report, "battle_blocking_codes", "starter_deploy_cost"):
		_fail("Starter above deploy cap should block battle entry: %s" % str(starter_report))

	if failed:
		quit(1)
		return
	print("TEAM_LEGALITY_SERVICE_PROBE ok")
	quit(0)
