extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_actor_command_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleActorCommandServiceScript := preload("res://scripts/services/battle_actor_command_service.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleActorCommandService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleActorCommandService",
		"extends RefCounted",
		"deploy_tick_plan",
		"summon_gate_intent",
		"auto_summon_intent",
		"ai_battle_original_player_is_ai",
		"ai_battle_roster_prepare_intent",
		"ai_battle_entry_repair_intent",
		"matchup_sortie_selection_intent",
		"ai_battle_seat_selection_intent",
		"scout_sortie_side_selection_intent",
		"scout_ai_team_button_intent",
		"team_color_index",
		"team_color_preset",
		"team_color_select_intent",
		"team_color_name",
		"valid_roster_entry",
		"sortie_loadout_plan",
		"sortie_after_delete_plan",
		"sortie_initial_cost_plan",
		"sortie_toggle_plan",
		"sortie_starter_plan",
		"sortie_active_index_plan",
		"sortie_position",
		"team_sortie_order",
		"starter_sortie_entry",
		"sortie_role_counts",
		"sortie_has_required_roles",
		"ai_sortie_score",
		"entry_is_selected",
		"sortie_entry_battle_legality",
		"all_roster_order",
		"roster_unit_total",
		"default_sortie_loadout",
		"default_summon_pair_bindings",
		"summon_pair_bindings_plan",
		"summon_pair_clear_intent",
		"summon_pair_cycle_intent",
		"portal_index_from_vector",
		"puppet_condition",
		"puppet_move_intent",
		"puppet_attack_intent",
		"barrier_logic_intents",
		"command_diagnostics",
	]:
		if service_source.find(token) < 0:
			_fail("BattleActorCommandService missing token: %s" % token)
			return
	for forbidden in [
		"Input.",
		"FileAccess",
		"DirAccess",
		"JSON.parse_string",
		"extends Node",
		"extends Control",
		"Control.new",
		"active_units",
		"all_units",
		"UnitScene",
		"GpuCollisionPipeline",
		"Fighter",
		"_create_unit",
		"_resolve_attack",
		"take_hit",
		"queue_free",
		"Time.",
		"randf",
		"randi",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("BattleActorCommandService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleActorCommandService = preload(\"res://scripts/services/battle_actor_command_service.gd\")",
		"var battle_actor_command_service: BattleActorCommandService",
		"battle_actor_command_service = BattleActorCommandService.new()",
		"func _battle_actor_command_service() -> BattleActorCommandService",
		"_battle_actor_command_service().deploy_tick_plan",
		"_battle_actor_command_service().summon_gate_intent",
		"_battle_actor_command_service().auto_summon_intent",
		"_battle_actor_command_service().ai_battle_original_player_is_ai",
		"_battle_actor_command_service().ai_battle_roster_prepare_intent",
		"_battle_actor_command_service().ai_battle_entry_repair_intent",
		"_battle_actor_command_service().matchup_sortie_selection_intent",
		"_battle_actor_command_service().ai_battle_seat_selection_intent",
		"_battle_actor_command_service().scout_sortie_side_selection_intent",
		"_battle_actor_command_service().scout_ai_team_button_intent",
		"_battle_actor_command_service().team_color_index",
		"_battle_actor_command_service().team_color_preset",
		"_battle_actor_command_service().team_color_select_intent",
		"_battle_actor_command_service().team_color_name",
		"_battle_actor_command_service().valid_roster_entry",
		"_battle_actor_command_service().sortie_loadout_plan",
		"_battle_actor_command_service().sortie_after_delete_plan",
		"_battle_actor_command_service().sortie_initial_cost_plan",
		"_battle_actor_command_service().sortie_toggle_plan",
		"_battle_actor_command_service().sortie_starter_plan",
		"_battle_actor_command_service().sortie_active_index_plan",
		"_battle_actor_command_service().sortie_position",
		"_battle_actor_command_service().team_sortie_order",
		"_battle_actor_command_service().starter_sortie_entry",
		"_battle_actor_command_service().sortie_role_counts",
		"_battle_actor_command_service().sortie_has_required_roles",
		"_battle_actor_command_service().ai_sortie_score",
		"_battle_actor_command_service().entry_is_selected",
		"_battle_actor_command_service().sortie_entry_battle_legality",
		"_battle_actor_command_service().all_roster_order",
		"_battle_actor_command_service().roster_unit_total",
		"_battle_actor_command_service().default_sortie_loadout",
		"_battle_actor_command_service().default_summon_pair_bindings",
		"_battle_actor_command_service().summon_pair_bindings_plan",
		"_battle_actor_command_service().summon_pair_clear_intent",
		"_battle_actor_command_service().summon_pair_cycle_intent",
		"_battle_actor_command_service().portal_index_from_vector",
		"_battle_actor_command_service().puppet_condition",
		"_battle_actor_command_service().puppet_move_intent",
		"_battle_actor_command_service().puppet_attack_intent",
		"_battle_actor_command_service().barrier_logic_intents",
		"_battle_actor_command_service().command_diagnostics",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle actor command service token: %s" % token)
			return
	for stale_token in [
		"func _pair_key(",
		"func _pair_used_by_other(",
	]:
		if main_source.find(stale_token) >= 0:
			_fail("main.gd should not retain stale summon-pair helper: %s" % stale_token)
			return
	var service = BattleActorCommandServiceScript.new()
	_check_deploy(service)
	_check_summon(service)
	_check_auto_summon(service)
	_check_ai_battle_original_player(service)
	_check_ai_battle_roster_prepare(service)
	_check_ai_battle_entry_repair(service)
	_check_matchup_sortie_selection(service)
	_check_ai_battle_seat_selection(service)
	_check_scout_sortie_side_selection(service)
	_check_scout_ai_team_button(service)
	_check_team_color_selection(service)
	_check_team_color_select_intent(service)
	_check_team_color_name(service)
	_check_valid_roster_entry(service)
	_check_sortie_loadout_plan(service)
	_check_sortie_after_delete_plan(service)
	_check_sortie_initial_cost_plan(service)
	_check_sortie_toggle_plan(service)
	_check_sortie_starter_plan(service)
	_check_sortie_active_index_plan(service)
	_check_sortie_position(service)
	_check_team_sortie_order(service)
	_check_starter_sortie_entry(service)
	_check_sortie_role_counts(service)
	_check_ai_sortie_score(service)
	_check_entry_is_selected(service)
	_check_sortie_entry_battle_legality(service)
	_check_all_roster_order(service)
	_check_roster_unit_total(service)
	_check_default_sortie_loadout(service)
	_check_default_summon_pair_bindings(service)
	_check_summon_pair_bindings(service)
	_check_summon_pair_clear(service)
	_check_summon_pair_cycle(service)
	_check_portal_index(service)
	_check_puppet_condition(service)
	_check_puppet_move(service)
	_check_puppet_attack(service)
	_check_barrier_logic(service)
	_check_command_diagnostics(service)
	if not failures.is_empty():
		print("BATTLE_ACTOR_COMMAND_SERVICE_CONTRACT_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_ACTOR_COMMAND_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_deploy(service) -> void:
	var plans: Array = service.deploy_tick_plan([
		{"player_id": 1, "role_key": "hero", "timer": 0.5},
		{"player_id": 2, "role_key": "barrier", "timer": 0.1},
		{"player_id": 1, "role_key": "puppet", "timer": 0.0},
	], 0.2)
	if plans.size() != 2:
		_fail("deploy_tick_plan should skip inactive timers: %s" % str(plans))
		return
	_assert_eq(String(Dictionary(plans[0]).get("role_key", "")), "hero", "deploy role")
	_assert_close(float(Dictionary(plans[0]).get("timer_after", 0.0)), 0.3, "deploy wait timer")
	if bool(Dictionary(plans[0]).get("finish", true)):
		_fail("hero deploy should keep waiting.")
	if not bool(Dictionary(plans[1]).get("finish", false)) or float(Dictionary(plans[1]).get("timer_after", 1.0)) != 0.0:
		_fail("barrier deploy should finish and clamp timer: %s" % str(plans[1]))


func _check_summon(service) -> void:
	if String(service.summon_gate_intent({"role_key": "puppet", "puppet_group_live": true}).get("reason", "")) != "puppet_online":
		_fail("summon gate should reject live puppet group.")
	if String(service.summon_gate_intent({"role_key": "hero", "existing_live": true}).get("reason", "")) != "already_online":
		_fail("summon gate should reject live role.")
	if String(service.summon_gate_intent({"role_key": "hero", "pending": true}).get("reason", "")) != "already_pending":
		_fail("summon gate should reject pending role.")
	if String(service.summon_gate_intent({"role_key": "barrier", "barrier_blocked": true}).get("reason", "")) != "barrier_blocked":
		_fail("summon gate should reject blocked barrier.")
	if String(service.summon_gate_intent({"role_key": "hero", "free": false, "resource": 4.0, "deploy_cost": 8.0}).get("reason", "")) != "resource_short":
		_fail("summon gate should reject short resource.")
	if not bool(service.summon_gate_intent({"role_key": "hero", "free": true, "resource": 0.0, "deploy_cost": 8.0}).get("accepted", false)):
		_fail("summon gate should accept free summon.")


func _check_auto_summon(service) -> void:
	var timer_intent: Dictionary = service.auto_summon_intent({
		"delta": 0.5,
		"auto_timer": 0.2,
		"idle_timer": 0.1,
		"has_live_mech": false,
		"has_pending_mech": false,
		"hero_live": true,
		"hero_has_soul": true,
		"now": 20.0,
		"last_attack_time": 8.0,
		"idle_seconds": 10.0,
	})
	var intents: Array = Array(timer_intent.get("intents", []))
	if intents.size() != 2 or String(Dictionary(intents[0]).get("reason", "")) != "no_mech" or String(Dictionary(intents[1]).get("reason", "")) != "soul_idle":
		_fail("auto_summon_intent should expose no-mech and soul-idle triggers: %s" % str(timer_intent))
	var candidate: Dictionary = service.auto_summon_intent({"candidates": [
		{"role": "hero", "index": 0, "valid": true, "role_allowed": true, "available": false, "affordable": true},
		{"role": "puppet", "index": 2, "valid": true, "role_allowed": true, "available": true, "affordable": true},
	]})
	if not bool(candidate.get("found", false)) or String(candidate.get("role_key", "")) != "puppet" or int(candidate.get("unit_index", -1)) != 2:
		_fail("auto_summon_intent should pick first valid affordable candidate: %s" % str(candidate))


func _check_ai_battle_original_player(service) -> void:
	_assert_eq(service.ai_battle_original_player_is_ai(1, 1), false, "AI battle seat 1 should leave player 1 human-controlled")
	_assert_eq(service.ai_battle_original_player_is_ai(1, 2), true, "AI battle seat 1 should keep original player 2 AI-controlled")
	_assert_eq(service.ai_battle_original_player_is_ai(2, 1), false, "AI battle seat 2 should leave player 1 non-AI under the current original-player rule")
	_assert_eq(service.ai_battle_original_player_is_ai(2, 2), true, "AI battle seat 2 should keep original player 2 AI-controlled")
	_assert_eq(service.ai_battle_original_player_is_ai(3, 1), true, "AI battle watch seat should AI-control player 1")
	_assert_eq(service.ai_battle_original_player_is_ai(3, 2), true, "AI battle watch seat should AI-control player 2")
	_assert_eq(service.ai_battle_original_player_is_ai(4, 3), false, "Unknown non-watch seats should only AI-control original player 2")


func _check_ai_battle_roster_prepare(service) -> void:
	var ai_unlocked: Dictionary = service.ai_battle_roster_prepare_intent({
		"ai_controlled": true,
		"roster_empty": false,
		"manual_locked": false,
	})
	_assert_eq(bool(ai_unlocked.get("auto_generate", false)), true, "AI unlocked roster should auto-generate")
	_assert_eq(bool(ai_unlocked.get("legalize", false)), true, "AI unlocked roster should legalize")
	_assert_eq(bool(ai_unlocked.get("force_generate", false)), true, "AI unlocked roster should force generation")
	_assert_eq(String(ai_unlocked.get("template_choice", "")), "random", "AI unlocked roster should request random template")
	var ai_locked: Dictionary = service.ai_battle_roster_prepare_intent({
		"ai_controlled": true,
		"roster_empty": false,
		"manual_locked": true,
	})
	_assert_eq(bool(ai_locked.get("auto_generate", true)), false, "AI locked non-empty roster should not auto-generate")
	_assert_eq(bool(ai_locked.get("legalize", false)), true, "AI locked non-empty roster should still legalize")
	_assert_eq(bool(ai_locked.get("force_generate", true)), false, "AI locked non-empty roster should not force generation")
	var empty_unlocked: Dictionary = service.ai_battle_roster_prepare_intent({
		"ai_controlled": false,
		"roster_empty": true,
		"manual_locked": false,
	})
	_assert_eq(bool(empty_unlocked.get("auto_generate", false)), true, "Empty unlocked roster should auto-generate")
	_assert_eq(bool(empty_unlocked.get("legalize", false)), true, "Empty unlocked roster should legalize")
	_assert_eq(bool(empty_unlocked.get("force_generate", false)), true, "Empty unlocked roster should force generation")
	var empty_locked_ai: Dictionary = service.ai_battle_roster_prepare_intent({
		"ai_controlled": true,
		"roster_empty": true,
		"manual_locked": true,
	})
	_assert_eq(bool(empty_locked_ai.get("auto_generate", true)), false, "Locked AI empty roster should preserve manual template choice")
	_assert_eq(bool(empty_locked_ai.get("legalize", false)), true, "Locked AI empty roster should still legalize")
	_assert_eq(bool(empty_locked_ai.get("force_generate", false)), true, "Locked AI empty roster should force generation because roster is empty")
	var inactive: Dictionary = service.ai_battle_roster_prepare_intent({
		"ai_controlled": false,
		"roster_empty": false,
		"manual_locked": false,
	})
	_assert_eq(bool(inactive.get("auto_generate", true)), false, "Human non-empty roster should not auto-generate")
	_assert_eq(bool(inactive.get("legalize", true)), false, "Human non-empty roster should not legalize")


func _check_ai_battle_entry_repair(service) -> void:
	var valid: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": true,
		"mode_is_ai": true,
		"ai_controlled": true,
		"manual_locked": false,
		"template_choice": "locked_template",
	})
	_assert_eq(bool(valid.get("repair", true)), false, "Valid battle entry summary should not request repair")
	var not_ai_mode: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": false,
		"mode_is_ai": false,
		"ai_controlled": true,
		"manual_locked": false,
		"template_choice": "locked_template",
	})
	_assert_eq(bool(not_ai_mode.get("repair", true)), false, "Non-AI mode should not repair invalid AI entry")
	var human_seat: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": false,
		"mode_is_ai": true,
		"ai_controlled": false,
		"manual_locked": false,
		"template_choice": "locked_template",
	})
	_assert_eq(bool(human_seat.get("repair", true)), false, "Human-controlled AI mode seat should not repair")
	var unlocked: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": false,
		"mode_is_ai": true,
		"ai_controlled": true,
		"manual_locked": false,
		"template_choice": "teamedit_generated",
	})
	_assert_eq(bool(unlocked.get("repair", false)), true, "Invalid AI-controlled entry should request repair")
	_assert_eq(bool(unlocked.get("force_generate", false)), true, "Repair should force generation")
	_assert_eq(String(unlocked.get("template_choice", "")), "random", "Unlocked repair should request random template")
	var locked: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": false,
		"mode_is_ai": true,
		"ai_controlled": true,
		"manual_locked": true,
		"template_choice": "locked_template",
	})
	_assert_eq(bool(locked.get("repair", false)), true, "Locked invalid AI-controlled entry should still repair")
	_assert_eq(String(locked.get("template_choice", "")), "locked_template", "Locked repair should preserve current template")
	var locked_default: Dictionary = service.ai_battle_entry_repair_intent({
		"summary_valid": false,
		"mode_is_ai": true,
		"ai_controlled": true,
		"manual_locked": true,
	})
	_assert_eq(String(locked_default.get("template_choice", "")), "teamedit_generated", "Locked repair should fallback to teamedit generated template")


func _check_matchup_sortie_selection(service) -> void:
	var ai_plan: Dictionary = service.matchup_sortie_selection_intent({"ai_controlled": true})
	_assert_eq(String(ai_plan.get("action", "")), "ai_loadout", "AI-controlled matchup should build AI loadout")
	_assert_eq(bool(ai_plan.get("build_ai_loadout", false)), true, "AI-controlled matchup should request loadout build")
	_assert_eq(bool(ai_plan.get("normalize_initial", false)), true, "AI-controlled matchup should request initial normalization")
	_assert_eq(bool(ai_plan.get("clear_loadout", true)), false, "AI-controlled matchup should not clear loadout")
	_assert_eq(bool(ai_plan.get("ensure_bindings", false)), true, "AI-controlled matchup should still ensure summon bindings")
	var human_plan: Dictionary = service.matchup_sortie_selection_intent({"ai_controlled": false})
	_assert_eq(String(human_plan.get("action", "")), "clear", "Human-controlled matchup should clear pending sortie selection")
	_assert_eq(bool(human_plan.get("build_ai_loadout", true)), false, "Human-controlled matchup should not build AI loadout")
	_assert_eq(bool(human_plan.get("normalize_initial", true)), false, "Human-controlled matchup should not normalize empty loadout")
	_assert_eq(bool(human_plan.get("clear_loadout", false)), true, "Human-controlled matchup should clear loadout")
	_assert_eq(int(human_plan.get("initial_slot", -1)), 0, "Human-controlled matchup should reset initial slot")
	_assert_eq(bool(human_plan.get("ensure_bindings", false)), true, "Human-controlled matchup should still ensure summon bindings")


func _check_ai_battle_seat_selection(service) -> void:
	var training: Dictionary = service.ai_battle_seat_selection_intent({
		"requested_seat": 0,
		"mode_is_training": true,
		"p1_manual_locked": false,
	})
	_assert_eq(int(training.get("seat", -1)), 1, "Seat selection should clamp low requested seat")
	_assert_eq(bool(training.get("training_seat_confirmed", false)), true, "Training seat selection should confirm training seat")
	_assert_eq(bool(training.get("configure_training_sides", false)), true, "Training seat selection should request side configuration")
	_assert_eq(bool(training.get("set_scout_sortie_player", true)), false, "Training seat selection should not change scout sortie side")
	var watch_unlocked: Dictionary = service.ai_battle_seat_selection_intent({
		"requested_seat": 3,
		"mode_is_training": false,
		"p1_manual_locked": false,
	})
	_assert_eq(int(watch_unlocked.get("seat", -1)), 3, "Seat selection should preserve watch seat")
	_assert_eq(bool(watch_unlocked.get("set_scout_sortie_player", false)), true, "Unlocked watch seat should select P1 scout side")
	_assert_eq(int(watch_unlocked.get("scout_sortie_player_id", -1)), 1, "Unlocked watch seat should select P1")
	var watch_locked: Dictionary = service.ai_battle_seat_selection_intent({
		"requested_seat": 3,
		"mode_is_training": false,
		"p1_manual_locked": true,
	})
	_assert_eq(bool(watch_locked.get("set_scout_sortie_player", true)), false, "Locked watch seat should preserve scout side")
	var p2_right: Dictionary = service.ai_battle_seat_selection_intent({
		"requested_seat": 2,
		"mode_is_training": false,
		"p1_manual_locked": true,
	})
	_assert_eq(int(p2_right.get("seat", -1)), 2, "Seat selection should preserve P2 right seat")
	_assert_eq(bool(p2_right.get("set_scout_sortie_player", false)), true, "P2 right seat should select P1 scout side")
	_assert_eq(int(p2_right.get("scout_sortie_player_id", -1)), 1, "P2 right seat should select P1")
	var p1_left: Dictionary = service.ai_battle_seat_selection_intent({
		"requested_seat": 5,
		"mode_is_training": false,
		"p1_manual_locked": false,
	})
	_assert_eq(int(p1_left.get("seat", -1)), 3, "Seat selection should clamp high requested seat")
	_assert_eq(bool(p1_left.get("update_scout_ui", false)), true, "Seat selection should request scout UI refresh")


func _check_scout_sortie_side_selection(service) -> void:
	var roster_order := [
		{"role": "hero", "index": 1, "payload": {"color": "red"}},
		{"role": "puppet", "index": 0},
	]
	var high: Dictionary = service.scout_sortie_side_selection_intent(4, roster_order)
	_assert_eq(int(high.get("scout_sortie_player_id", -1)), 2, "Scout sortie side should clamp high player id")
	_assert_eq(int(high.get("scout_selected_player_id", -1)), 2, "Scout sortie side should mirror selected player id")
	_assert_eq(bool(high.get("set_selected_entry", false)), true, "Scout sortie side should select first roster entry")
	_assert_eq(_entry_text([Dictionary(high.get("selected_entry", {}))]), "hero:1", "Scout sortie side should return first roster entry")
	Dictionary(Dictionary(high.get("selected_entry", {})).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(roster_order[0]).get("payload", {})).get("color", "")), "red", "Scout sortie side should duplicate selected entry")
	var low_empty: Dictionary = service.scout_sortie_side_selection_intent(-3, [])
	_assert_eq(int(low_empty.get("scout_sortie_player_id", -1)), 1, "Scout sortie side should clamp low player id")
	_assert_eq(bool(low_empty.get("set_selected_entry", true)), false, "Scout sortie side should not replace selected entry when roster is empty")
	_assert_eq(bool(low_empty.get("update_scout_ui", false)), true, "Scout sortie side should request scout UI refresh")


func _check_scout_ai_team_button(service) -> void:
	var template_order := ["teamedit_generated", "rush", "wall"]
	var edit: Dictionary = service.scout_ai_team_button_intent(-4, "edit", true, "rush", template_order)
	_assert_eq(int(edit.get("player_id", -1)), 1, "Scout AI team button should clamp low player id")
	_assert_eq(String(edit.get("action", "")), "edit", "Scout AI team edit button should route to editor")
	_assert_eq(bool(edit.get("show_editor", false)), true, "Scout AI team edit button should request editor")
	_assert_eq(bool(edit.get("generate_team", true)), false, "Scout AI team edit button should not generate")
	var cycle: Dictionary = service.scout_ai_team_button_intent(2, "cycle", false, "rush", template_order)
	_assert_eq(int(cycle.get("player_id", -1)), 2, "Scout AI team cycle should preserve player id")
	_assert_eq(String(cycle.get("action", "")), "generate", "Scout AI team cycle should generate")
	_assert_eq(String(cycle.get("template_key", "")), "wall", "Scout AI team cycle should select next template")
	_assert_eq(bool(cycle.get("lock_after", false)), true, "Scout AI team cycle should lock generated template")
	_assert_eq(bool(cycle.get("set_template_choice", true)), false, "Scout AI team cycle should leave template writeback to generation")
	var wrapped: Dictionary = service.scout_ai_team_button_intent(5, "cycle", false, "wall", template_order)
	_assert_eq(int(wrapped.get("player_id", -1)), 2, "Scout AI team cycle should clamp high player id")
	_assert_eq(String(wrapped.get("template_key", "")), "teamedit_generated", "Scout AI team cycle should wrap template order")
	var unknown: Dictionary = service.scout_ai_team_button_intent(1, "cycle", false, "missing", template_order)
	_assert_eq(String(unknown.get("template_key", "")), "rush", "Scout AI team cycle should mirror existing unknown-key fallback")
	var random: Dictionary = service.scout_ai_team_button_intent(9, "random", false, "wall", template_order)
	_assert_eq(int(random.get("player_id", -1)), 2, "Scout AI team random should clamp player id")
	_assert_eq(String(random.get("action", "")), "generate", "Scout AI team random should generate")
	_assert_eq(String(random.get("template_key", "")), "random", "Scout AI team random should request random template")
	_assert_eq(bool(random.get("set_template_choice", false)), true, "Scout AI team random should request template choice writeback")
	_assert_eq(String(random.get("template_choice", "")), "random", "Scout AI team random should write random template choice")
	_assert_eq(bool(random.get("lock_after", true)), false, "Scout AI team random should preserve lock-after flag")


func _check_team_color_selection(service) -> void:
	var presets := [
		{"name": "Blue", "payload": {"color": "blue"}},
		{"name": "Red", "payload": {"color": "red"}},
		{"name": "Gold", "payload": {"color": "gold"}},
	]
	var color_indices := {1: 0, 2: 99, 3: -1}
	var custom_colors := {
		1: {"name": "Custom P1", "payload": {"color": "cyan"}},
		3: {"name": "Custom P3", "payload": {"color": "violet"}},
	}
	_assert_eq(service.team_color_index(1, color_indices, presets.size()), 0, "Team color index should preserve P1 preset")
	_assert_eq(service.team_color_index(2, color_indices, presets.size()), 2, "Team color index should clamp high preset")
	_assert_eq(service.team_color_index(3, color_indices, presets.size()), -1, "Team color index should preserve custom sentinel")
	_assert_eq(service.team_color_index(4, color_indices, presets.size()), 1, "Team color index should fallback non-P1 players to preset 1")
	var clamped_preset: Dictionary = service.team_color_preset(2, color_indices, custom_colors, presets)
	_assert_eq(String(clamped_preset.get("name", "")), "Gold", "Team color preset should use clamped preset")
	Dictionary(Dictionary(clamped_preset.get("payload", {})))["color"] = "white"
	_assert_eq(String(Dictionary(Dictionary(presets[2]).get("payload", {})).get("color", "")), "gold", "Team color preset should duplicate preset data")
	var custom: Dictionary = service.team_color_preset(3, color_indices, custom_colors, presets)
	_assert_eq(String(custom.get("name", "")), "Custom P3", "Team color preset should use player's custom colors")
	Dictionary(Dictionary(custom.get("payload", {})))["color"] = "black"
	_assert_eq(String(Dictionary(Dictionary(custom_colors[3]).get("payload", {})).get("color", "")), "violet", "Team color preset should duplicate custom color data")
	var fallback_custom: Dictionary = service.team_color_preset(2, {2: -1}, custom_colors, presets)
	_assert_eq(String(fallback_custom.get("name", "")), "Custom P1", "Team color preset should fallback missing custom player to P1 custom colors")


func _check_team_color_select_intent(service) -> void:
	var scout: Dictionary = service.team_color_select_intent(5, 9, 3, false)
	_assert_eq(int(scout.get("player_id", -1)), 2, "Team color select should clamp high player id")
	_assert_eq(int(scout.get("color_index", -1)), 2, "Team color select should clamp high color index")
	_assert_eq(bool(scout.get("set_manual_lock", true)), false, "Scout team color select should not set manual lock")
	_assert_eq(bool(scout.get("update_ui", false)), true, "Team color select should request UI refresh")
	var editor: Dictionary = service.team_color_select_intent(-4, -2, 3, true)
	_assert_eq(int(editor.get("player_id", -1)), 1, "Team color select should clamp low player id")
	_assert_eq(int(editor.get("color_index", -1)), 0, "Team color select should clamp low color index")
	_assert_eq(bool(editor.get("set_manual_lock", false)), true, "Editor team color select should set manual lock")
	_assert_eq(bool(editor.get("manual_locked", false)), true, "Editor team color select should lock manual AI team")
	var empty: Dictionary = service.team_color_select_intent(1, 2, 0, true)
	_assert_eq(int(empty.get("color_index", 99)), -1, "Team color select should use custom sentinel when no presets exist")


func _check_team_color_name(service) -> void:
	var bilingual := {"name": "蓝队", "name_en": "Blue"}
	_assert_eq(service.team_color_name(bilingual, true), "蓝队", "Team color name should prefer zh name in zh UI")
	_assert_eq(service.team_color_name(bilingual, false), "Blue", "Team color name should prefer English name in en UI")
	_assert_eq(service.team_color_name({"name_en": "Amber"}, true), "Amber", "Team color name should fallback to English name in zh UI")
	_assert_eq(service.team_color_name({"name": "琥珀"}, false), "琥珀", "Team color name should fallback to zh name in en UI")
	_assert_eq(service.team_color_name({}, true), "自定义", "Team color name should default zh custom label")
	_assert_eq(service.team_color_name({}, false), "CUSTOM", "Team color name should default English custom label")


func _check_valid_roster_entry(service) -> void:
	var roster_sizes := {"hero": 2, "puppet": 1, "barrier": 0}
	var roles := ["hero", "puppet", "barrier"]
	_assert_eq(service.valid_roster_entry({"role": "hero", "index": 1}, roster_sizes, roles), true, "valid roster entry should accept in-range role/index")
	_assert_eq(service.valid_roster_entry({"role": "puppet", "index": "0"}, roster_sizes, roles), true, "valid roster entry should coerce string index")
	_assert_eq(service.valid_roster_entry({"role": "scout", "index": 0}, roster_sizes, roles), false, "valid roster entry should reject unknown role")
	_assert_eq(service.valid_roster_entry({"role": "hero", "index": -1}, roster_sizes, roles), false, "valid roster entry should reject negative index")
	_assert_eq(service.valid_roster_entry({"role": "hero", "index": 2}, roster_sizes, roles), false, "valid roster entry should reject index at roster size")
	_assert_eq(service.valid_roster_entry({"role": "barrier", "index": 0}, roster_sizes, roles), false, "valid roster entry should reject zero-sized roster")
	_assert_eq(service.valid_roster_entry({}, roster_sizes, roles), false, "valid roster entry should reject empty entry")


func _check_sortie_loadout_plan(service) -> void:
	var raw_loadout := [
		{"role": "hero", "index": 1, "payload": {"color": "red"}},
		{"role": "hero", "index": 1},
		{"role": "puppet", "index": 3},
		"invalid",
		{"role": "barrier", "index": 0},
		{"role": "scout", "index": 0},
		{"role": "puppet", "index": 1},
	]
	var plan: Dictionary = service.sortie_loadout_plan(
		raw_loadout,
		{"hero": 2, "puppet": 2, "barrier": 1},
		["hero", "puppet", "barrier"],
		3,
		99
	)
	var loadout: Array = Array(plan.get("loadout", []))
	_assert_eq(_entry_text(loadout), "hero:1|barrier:0|puppet:1", "sortie loadout plan should filter invalid entries and skip duplicates")
	_assert_eq(int(plan.get("initial_slot", -1)), 2, "sortie loadout plan should clamp high initial slot")
	Dictionary(Dictionary(loadout[0]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(raw_loadout[0]).get("payload", {})).get("color", "")), "red", "sortie loadout plan should duplicate nested entry data")
	var capped: Dictionary = service.sortie_loadout_plan(raw_loadout, {"hero": 2, "puppet": 2, "barrier": 1}, ["hero", "puppet", "barrier"], 1, -4)
	_assert_eq(_entry_text(Array(capped.get("loadout", []))), "hero:1", "sortie loadout plan should apply sortie cap")
	_assert_eq(int(capped.get("initial_slot", -1)), 0, "sortie loadout plan should clamp low initial slot")
	var empty: Dictionary = service.sortie_loadout_plan([{"role": "hero", "index": 0}], {"hero": 0}, ["hero"], 3, 4)
	_assert_eq(Array(empty.get("loadout", [])).size(), 0, "sortie loadout plan should drop entries outside roster size")
	_assert_eq(int(empty.get("initial_slot", -1)), 0, "sortie loadout plan should use zero initial slot for empty loadout")
	var zero_cap: Dictionary = service.sortie_loadout_plan([{"role": "hero", "index": 0}], {"hero": 1}, ["hero"], 0, 0)
	_assert_eq(Array(zero_cap.get("loadout", [])).size(), 0, "sortie loadout plan should keep zero cap empty even with valid entries")
	_assert_eq(int(zero_cap.get("initial_slot", -1)), 0, "sortie loadout plan should keep zero cap initial slot at zero")


func _check_sortie_after_delete_plan(service) -> void:
	var raw_loadout := [
		{"role": "hero", "index": 0, "payload": {"color": "red"}},
		{"role": "hero", "index": 1},
		{"role": "hero", "index": 2},
		{"role": "puppet", "index": 1},
		{"role": "barrier", "index": 2},
		{"role": "hero", "index": 2},
		"invalid",
	]
	var plan: Dictionary = service.sortie_after_delete_plan(
		raw_loadout,
		{"hero": 2, "puppet": 2, "barrier": 2},
		["hero", "puppet", "barrier"],
		3,
		99,
		"hero",
		1
	)
	var loadout: Array = Array(plan.get("loadout", []))
	_assert_eq(_entry_text(loadout), "hero:0|hero:1|puppet:1", "sortie after delete should drop deleted entry, shift later same-role indices, filter invalid entries, and skip duplicates")
	_assert_eq(int(plan.get("initial_slot", -1)), 2, "sortie after delete should clamp high initial slot")
	Dictionary(Dictionary(loadout[0]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(raw_loadout[0]).get("payload", {})).get("color", "")), "red", "sortie after delete should duplicate nested entry data")
	var capped: Dictionary = service.sortie_after_delete_plan(raw_loadout, {"hero": 2, "puppet": 2, "barrier": 2}, ["hero", "puppet", "barrier"], 1, -4, "hero", 1)
	_assert_eq(_entry_text(Array(capped.get("loadout", []))), "hero:0", "sortie after delete should apply sortie cap")
	_assert_eq(int(capped.get("initial_slot", -1)), 0, "sortie after delete should clamp low initial slot")
	var zero: Dictionary = service.sortie_after_delete_plan(raw_loadout, {"hero": 2}, ["hero"], 0, 3, "hero", 1)
	_assert_eq(Array(zero.get("loadout", [])).size(), 0, "sortie after delete should handle zero cap")
	_assert_eq(int(zero.get("initial_slot", -1)), 0, "sortie after delete should use zero initial slot for empty loadout")


func _check_sortie_initial_cost_plan(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0},
		{"role": "puppet", "index": 1},
		{"role": "barrier", "index": 0},
	]
	var keep_current: Dictionary = service.sortie_initial_cost_plan(loadout, 1, [false, true, true])
	_assert_eq(bool(keep_current.get("found", false)), true, "sortie initial cost should accept valid current starter")
	_assert_eq(int(keep_current.get("initial_slot", -1)), 1, "sortie initial cost should keep valid current starter slot")
	var clamp_high: Dictionary = service.sortie_initial_cost_plan(loadout, 99, [false, false, true])
	_assert_eq(bool(clamp_high.get("found", false)), true, "sortie initial cost should clamp high current slot before checking")
	_assert_eq(int(clamp_high.get("initial_slot", -1)), 2, "sortie initial cost should use clamped valid high slot")
	var first_valid: Dictionary = service.sortie_initial_cost_plan(loadout, 2, [true, false, false])
	_assert_eq(bool(first_valid.get("found", false)), true, "sortie initial cost should search for first valid starter")
	_assert_eq(int(first_valid.get("initial_slot", -1)), 0, "sortie initial cost should select first valid fallback slot")
	var none_valid: Dictionary = service.sortie_initial_cost_plan(loadout, -4, [false])
	_assert_eq(bool(none_valid.get("found", true)), false, "sortie initial cost should report no starter when no flag is valid")
	_assert_eq(int(none_valid.get("initial_slot", -1)), 0, "sortie initial cost should still return clamped slot for diagnostics")
	var empty: Dictionary = service.sortie_initial_cost_plan([], 3, [true])
	_assert_eq(bool(empty.get("found", true)), false, "sortie initial cost should reject empty loadout")
	_assert_eq(int(empty.get("initial_slot", -1)), 0, "sortie initial cost should return zero for empty loadout")


func _check_sortie_toggle_plan(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0, "payload": {"color": "red"}},
		{"role": "puppet", "index": 1},
		{"role": "barrier", "index": 0},
	]
	var remove: Dictionary = service.sortie_toggle_plan(loadout, {"role": "puppet", "index": 1}, 1, 3, 99)
	_assert_eq(String(remove.get("action", "")), "remove", "sortie toggle should report remove action")
	_assert_eq(_entry_text(Array(remove.get("loadout", []))), "hero:0|barrier:0", "sortie toggle should remove selected slot")
	_assert_eq(int(remove.get("initial_slot", -1)), 1, "sortie toggle should clamp high initial slot after removal")
	var add: Dictionary = service.sortie_toggle_plan([{"role": "hero", "index": 0}], {"role": "barrier", "index": 0, "payload": {"color": "green"}}, -1, 3, -4)
	var added_loadout: Array = Array(add.get("loadout", []))
	_assert_eq(String(add.get("action", "")), "add", "sortie toggle should report add action")
	_assert_eq(_entry_text(added_loadout), "hero:0|barrier:0", "sortie toggle should append missing entry")
	_assert_eq(int(add.get("initial_slot", -1)), -4, "sortie toggle should preserve initial slot on add")
	Dictionary(Dictionary(added_loadout[1]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(add.get("entry", {})).get("payload", {})).get("color", "")), "green", "sortie toggle should duplicate nested added entry")
	var full: Dictionary = service.sortie_toggle_plan(loadout, {"role": "hero", "index": 2}, -1, 3, 0)
	_assert_eq(String(full.get("action", "")), "full", "sortie toggle should report full action")
	_assert_eq(_entry_text(Array(full.get("loadout", []))), "hero:0|puppet:1|barrier:0", "sortie toggle full action should preserve loadout")
	var remove_last: Dictionary = service.sortie_toggle_plan([{"role": "hero", "index": 0}], {"role": "hero", "index": 0}, 0, 3, 0)
	_assert_eq(Array(remove_last.get("loadout", [])).size(), 0, "sortie toggle should remove last slot")
	_assert_eq(int(remove_last.get("initial_slot", -1)), 0, "sortie toggle should zero initial slot for empty loadout")


func _check_sortie_starter_plan(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0},
		{"role": "puppet", "index": 1},
	]
	var existing: Dictionary = service.sortie_starter_plan(loadout, {"role": "puppet", "index": 1}, 1, 3)
	_assert_eq(String(existing.get("action", "")), "set", "sortie starter should set existing slot")
	_assert_eq(_entry_text(Array(existing.get("loadout", []))), "hero:0|puppet:1", "sortie starter should preserve existing loadout")
	_assert_eq(int(existing.get("initial_slot", -1)), 1, "sortie starter should point to existing slot")
	_assert_eq(String(existing.get("initial_role", "")), "puppet", "sortie starter should set initial role")
	var append: Dictionary = service.sortie_starter_plan([{"role": "hero", "index": 0}], {"role": "barrier", "index": 0, "payload": {"color": "green"}}, -1, 3)
	var appended_loadout: Array = Array(append.get("loadout", []))
	_assert_eq(String(append.get("action", "")), "append", "sortie starter should append missing entry under cap")
	_assert_eq(_entry_text(appended_loadout), "hero:0|barrier:0", "sortie starter should append entry")
	_assert_eq(int(append.get("initial_slot", -1)), 1, "sortie starter should point to appended slot")
	_assert_eq(String(append.get("initial_role", "")), "barrier", "sortie starter should set appended role")
	Dictionary(Dictionary(appended_loadout[1]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(append.get("entry", {})).get("payload", {})).get("color", "")), "green", "sortie starter should duplicate nested appended entry")
	var full: Dictionary = service.sortie_starter_plan(loadout, {"role": "barrier", "index": 0}, -1, 2)
	_assert_eq(String(full.get("action", "")), "full", "sortie starter should report full no-op")
	_assert_eq(_entry_text(Array(full.get("loadout", []))), "hero:0|puppet:1", "sortie starter full should preserve loadout")


func _check_sortie_active_index_plan(service) -> void:
	var invalid: Dictionary = service.sortie_active_index_plan({"role": "puppet", "index": 1}, false)
	_assert_eq(String(invalid.get("action", "")), "none", "sortie active index plan should ignore invalid roster entry")
	var valid: Dictionary = service.sortie_active_index_plan({"role": "puppet", "index": "2"}, true)
	_assert_eq(String(valid.get("action", "")), "set", "sortie active index plan should report set action")
	_assert_eq(String(valid.get("role_key", "")), "puppet", "sortie active index plan should preserve role")
	_assert_eq(int(valid.get("unit_index", -1)), 2, "sortie active index plan should coerce index")
	_assert_eq(String(valid.get("initial_role", "")), "puppet", "sortie active index plan should set initial role")
	var defaults: Dictionary = service.sortie_active_index_plan({}, true)
	_assert_eq(String(defaults.get("role_key", "")), "hero", "sortie active index plan should default missing role to hero")
	_assert_eq(int(defaults.get("unit_index", -1)), 0, "sortie active index plan should default missing index to zero")


func _check_sortie_position(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0},
		"invalid",
		{"role": "puppet", "index": "2"},
		{"role": "barrier", "index": 0},
		{"role": "hero", "index": 0},
	]
	_assert_eq(int(service.sortie_position(loadout, "hero", 0)), 0, "sortie position should return first matching slot")
	_assert_eq(int(service.sortie_position(loadout, "puppet", 2)), 2, "sortie position should coerce entry index to int")
	_assert_eq(int(service.sortie_position(loadout, "barrier", 0)), 3, "sortie position should find later slot")
	_assert_eq(int(service.sortie_position(loadout, "hero", 1)), -1, "sortie position should return -1 for missing unit")
	_assert_eq(int(service.sortie_position(loadout, "scout", 0)), -1, "sortie position should return -1 for missing role")
	_assert_eq(int(service.sortie_position([], "hero", 0)), -1, "sortie position should handle empty loadout")


func _check_team_sortie_order(service) -> void:
	var raw_loadout := [
		{"role": "hero", "index": 0, "payload": {"color": "red"}},
		{"role": "scout", "index": 0},
		"invalid",
		{"role": "puppet", "index": 3},
		{"role": "barrier", "index": 0},
		{"role": "puppet", "index": 1},
	]
	var order: Array = service.team_sortie_order(raw_loadout, {"hero": 1, "puppet": 2, "barrier": 1}, ["hero", "puppet", "barrier"], 2)
	_assert_eq(_entry_text(order), "hero:0|barrier:0", "team sortie order should filter invalid entries and follow sortie cap")
	Dictionary(Dictionary(order[0]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(raw_loadout[0]).get("payload", {})).get("color", "")), "red", "team sortie order should duplicate nested entry data")
	var over_cap: Array = service.team_sortie_order(raw_loadout, {"hero": 1, "puppet": 2, "barrier": 1}, ["hero", "puppet", "barrier"], 5)
	_assert_eq(_entry_text(over_cap), "hero:0|barrier:0|puppet:1", "team sortie order should include valid entries up to available loadout")
	var zero: Array = service.team_sortie_order(raw_loadout, {"hero": 1}, ["hero"], 0)
	_assert_eq(zero.size(), 0, "team sortie order should handle zero cap")


func _check_starter_sortie_entry(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0, "payload": {"color": "red"}},
		{"role": "barrier", "index": 1},
		{"role": "puppet", "index": 2},
	]
	var selected_high: Dictionary = service.starter_sortie_entry(loadout, 99, "hero", {"hero": 4})
	_assert_eq(_entry_text([selected_high]), "puppet:2", "starter sortie entry should clamp high initial slot")
	var selected_low: Dictionary = service.starter_sortie_entry(loadout, -3, "hero", {"hero": 4})
	_assert_eq(_entry_text([selected_low]), "hero:0", "starter sortie entry should clamp low initial slot")
	Dictionary(selected_low.get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(loadout[0]).get("payload", {})).get("color", "")), "red", "starter sortie entry should duplicate nested loadout entry")
	var fallback: Dictionary = service.starter_sortie_entry([], 0, "puppet", {"hero": 4, "puppet": 3})
	_assert_eq(_entry_text([fallback]), "puppet:3", "starter sortie entry should fall back to active index for role")
	var missing_fallback: Dictionary = service.starter_sortie_entry([], 0, "barrier", {"hero": 4})
	_assert_eq(_entry_text([missing_fallback]), "barrier:0", "starter sortie entry should default missing active role index to zero")


func _check_sortie_role_counts(service) -> void:
	var loadout := [
		{"role": "hero", "index": 0},
		{"role": "puppet", "index": 1},
		{"role": "hero", "index": 2},
		{"role": "scout", "index": 0},
		"invalid",
	]
	var counts: Dictionary = service.sortie_role_counts(loadout, ["hero", "puppet", "barrier"])
	_assert_eq(int(counts.get("hero", -1)), 2, "sortie role counts should count heroes")
	_assert_eq(int(counts.get("puppet", -1)), 1, "sortie role counts should count puppets")
	_assert_eq(int(counts.get("barrier", -1)), 0, "sortie role counts should include missing required role as zero")
	_assert_eq(counts.has("scout"), false, "sortie role counts should ignore roles outside role order")
	_assert_eq(service.sortie_has_required_roles(loadout, ["hero", "puppet", "barrier"]), false, "sortie required roles should reject missing role")
	var full_loadout := [{"role": "hero"}, {"role": "puppet"}, {"role": "barrier"}]
	_assert_eq(service.sortie_has_required_roles(full_loadout, ["hero", "puppet", "barrier"]), true, "sortie required roles should accept one of each role")
	_assert_eq(service.sortie_has_required_roles([], ["hero"]), false, "sortie required roles should reject empty loadout")


func _check_ai_sortie_score(service) -> void:
	var hero_stats := {
		"health": 100,
		"normal_damage": 2,
		"active_damage": 3,
		"armor_damage": 4,
		"speed": 1.5,
		"data_security": 2.0,
		"deploy_cost": 10,
		"cost": 20,
	}
	_assert_close(service.ai_sortie_score({"role": "hero"}, hero_stats, false), 199.8, "AI sortie score should apply base and hero bonus")
	_assert_close(service.ai_sortie_score({"role": "hero"}, hero_stats, true), 446.8, "AI sortie score should apply starter bonus")
	_assert_close(service.ai_sortie_score({"role": "puppet"}, {"group_count": 3, "data_security": 0.0}, false), 88.0, "AI sortie score should apply puppet group bonus")
	_assert_close(service.ai_sortie_score({"role": "barrier"}, {"aura_range": 1.25, "pulse_interval": 0.5, "data_security": 0.0}, false), 102.5, "AI sortie score should apply barrier aura and pulse terms")


func _check_entry_is_selected(service) -> void:
	var selected := [
		{"role": "puppet", "index": 0},
		"invalid",
		{"role": "hero", "index": 1},
	]
	_assert_eq(service.entry_is_selected({"role": "hero", "index": "1"}, selected), true, "entry selected should match role/index with integer coercion")
	_assert_eq(service.entry_is_selected({"role": "barrier", "index": 0}, selected), false, "entry selected should reject missing role/index")
	_assert_eq(service.entry_is_selected({"role": "puppet", "index": 2}, selected), false, "entry selected should reject missing index")
	_assert_eq(service.entry_is_selected({"index": 0}, [{"role": "hero", "index": 0}]), true, "entry selected should preserve default hero role behavior")


func _check_sortie_entry_battle_legality(service) -> void:
	var valid_context := {
		"valid_roster": true,
		"require_starter_cost": true,
		"starter_cost_valid": true,
		"role_key": "hero",
		"stats": {"length": 4.5, "joint_momentum_note": "", "slot_payload_note": "", "drive_note": "", "stiffness_note": ""},
		"role_uses_body_board": true,
		"module_material_valid": true,
		"topology_note": "OK",
	}
	_assert_eq(service.sortie_entry_battle_legality(valid_context), true, "sortie entry legality should accept valid context")
	var invalid_roster := valid_context.duplicate(true)
	invalid_roster["valid_roster"] = false
	_assert_eq(service.sortie_entry_battle_legality(invalid_roster), false, "sortie entry legality should reject invalid roster entries")
	var starter_fail := valid_context.duplicate(true)
	starter_fail["starter_cost_valid"] = false
	_assert_eq(service.sortie_entry_battle_legality(starter_fail), false, "sortie entry legality should enforce required starter cost")
	var starter_ignored := starter_fail.duplicate(true)
	starter_ignored["require_starter_cost"] = false
	_assert_eq(service.sortie_entry_battle_legality(starter_ignored), true, "sortie entry legality should ignore starter cost when not required")
	var long_unit := valid_context.duplicate(true)
	long_unit["stats"] = {"length": 4.51}
	_assert_eq(service.sortie_entry_battle_legality(long_unit), false, "sortie entry legality should reject over-length units")
	var bad_material := valid_context.duplicate(true)
	bad_material["module_material_valid"] = false
	_assert_eq(service.sortie_entry_battle_legality(bad_material), false, "sortie entry legality should reject invalid body-board material groups")
	var non_body_material := bad_material.duplicate(true)
	non_body_material["role_uses_body_board"] = false
	_assert_eq(service.sortie_entry_battle_legality(non_body_material), true, "sortie entry legality should ignore material groups for non-body-board roles")
	var bad_topology := valid_context.duplicate(true)
	bad_topology["topology_note"] = "INVALID missing torso"
	_assert_eq(service.sortie_entry_battle_legality(bad_topology), false, "sortie entry legality should reject invalid topology notes")
	var bad_note := valid_context.duplicate(true)
	bad_note["stats"] = {"length": 1.0, "drive_note": "INVALID drive"}
	_assert_eq(service.sortie_entry_battle_legality(bad_note), false, "sortie entry legality should reject invalid stat notes")
	var barrier_ignored_note := valid_context.duplicate(true)
	barrier_ignored_note["role_key"] = "barrier"
	barrier_ignored_note["stats"] = {"length": 1.0, "slot_payload_note": "INVALID payload", "drive_note": "INVALID drive"}
	_assert_eq(service.sortie_entry_battle_legality(barrier_ignored_note), true, "sortie entry legality should ignore barrier slot-payload and drive notes")


func _check_all_roster_order(service) -> void:
	var order: Array = service.all_roster_order({"hero": 2, "puppet": 1, "barrier": 3}, ["hero", "puppet", "barrier"])
	_assert_eq(_entry_text(order), "hero:0|puppet:0|barrier:0|hero:1|barrier:1|barrier:2", "all roster order should interleave by unit index then role order")
	var empty: Array = service.all_roster_order({}, ["hero"])
	_assert_eq(empty.size(), 0, "all roster order should handle empty roster sizes")
	var non_positive: Array = service.all_roster_order({"hero": 0, "puppet": -1}, ["hero", "puppet"])
	_assert_eq(non_positive.size(), 0, "all roster order should ignore non-positive roster sizes")


func _check_roster_unit_total(service) -> void:
	_assert_eq(service.roster_unit_total({"hero": 2, "puppet": 1, "barrier": 3}, ["hero", "puppet", "barrier"]), 6, "roster unit total should sum supplied role sizes")
	_assert_eq(service.roster_unit_total({"hero": 2, "extra": 99}, ["hero", "puppet"]), 2, "roster unit total should ignore roles outside role order")
	_assert_eq(service.roster_unit_total({"hero": -2, "puppet": 0}, ["hero", "puppet"]), 0, "roster unit total should clamp non-positive sizes")
	_assert_eq(service.roster_unit_total({}, ["hero"]), 0, "roster unit total should handle empty roster sizes")


func _check_default_sortie_loadout(service) -> void:
	var order := [
		{"role": "hero", "index": 0, "payload": {"color": "red"}},
		{"role": "puppet", "index": 0},
		{"role": "barrier", "index": 0},
	]
	var loadout: Array = service.default_sortie_loadout(order, 2)
	_assert_eq(_entry_text(loadout), "hero:0|puppet:0", "default sortie loadout should take the first entries up to cap")
	Dictionary(Dictionary(loadout[0]).get("payload", {}))["color"] = "blue"
	_assert_eq(String(Dictionary(Dictionary(order[0]).get("payload", {})).get("color", "")), "red", "default sortie loadout should duplicate nested entry data")
	var over_cap: Array = service.default_sortie_loadout(order, 5)
	_assert_eq(_entry_text(over_cap), "hero:0|puppet:0|barrier:0", "default sortie loadout should clamp to roster order size")
	var zero: Array = service.default_sortie_loadout(order, 0)
	_assert_eq(zero.size(), 0, "default sortie loadout should handle zero cap")
	var negative: Array = service.default_sortie_loadout(order, -4)
	_assert_eq(negative.size(), 0, "default sortie loadout should handle negative cap")


func _check_default_summon_pair_bindings(service) -> void:
	var defaults := [[1, 2], [3, 4], [5, 6]]
	var bindings: Array = service.default_summon_pair_bindings(defaults, 2)
	_assert_eq(bindings.size(), 2, "default summon pair bindings should follow sortie cap")
	_assert_eq(_array_text(Array(bindings[0])), "1,2", "default summon pair bindings first slot")
	_assert_eq(_array_text(Array(bindings[1])), "3,4", "default summon pair bindings second slot")
	Array(bindings[0])[0] = 99
	_assert_eq(_array_text(Array(defaults[0])), "1,2", "default summon pair bindings should duplicate slot arrays")
	var over_cap: Array = service.default_summon_pair_bindings(defaults, 5)
	_assert_eq(over_cap.size(), 3, "default summon pair bindings should clamp to available defaults")
	var zero: Array = service.default_summon_pair_bindings(defaults, 0)
	_assert_eq(zero.size(), 0, "default summon pair bindings should handle zero cap")


func _check_summon_pair_bindings(service) -> void:
	var fixed: Array = service.summon_pair_bindings_plan(
		[
			[3, 1],
			[1, 1],
			["8", "2"],
			"invalid",
			[9, 10],
			[],
		],
		[
			[1, 2],
			[3, 4],
			[5, 6],
			[2, 4],
			[1, 6],
		],
		6,
		6
	)
	_assert_eq(fixed.size(), 6, "summon pair plan size follows sortie cap")
	_assert_eq(_array_text(Array(fixed[0])), "1,3", "summon pair plan sorts raw pair")
	_assert_eq(_array_text(Array(fixed[1])), "", "summon pair plan drops duplicate key pair")
	_assert_eq(_array_text(Array(fixed[2])), "2,6", "summon pair plan clamps raw pair to attack count")
	_assert_eq(_array_text(Array(fixed[3])), "2,4", "summon pair plan falls back for invalid raw entry")
	_assert_eq(_array_text(Array(fixed[4])), "", "summon pair plan drops pair that clamps to same key")
	_assert_eq(_array_text(Array(fixed[5])), "", "summon pair plan preserves explicit empty raw pair")
	var defaults_only: Array = service.summon_pair_bindings_plan([], [[4, 2], [6, 5], [7, 8]], 2, 8)
	_assert_eq(_array_text(Array(defaults_only[0])), "2,4", "summon pair plan normalizes default slot")
	_assert_eq(_array_text(Array(defaults_only[1])), "5,6", "summon pair plan normalizes second default slot")
	var empty: Array = service.summon_pair_bindings_plan([], [[1, 2]], 0, 6)
	_assert_eq(empty.size(), 0, "summon pair plan handles zero cap")


func _check_summon_pair_clear(service) -> void:
	var clear: Dictionary = service.summon_pair_clear_intent([[1, 2], [3, 4], [5, 6]], 1)
	_assert_eq(String(clear.get("action", "")), "clear", "summon pair clear action")
	var cleared_bindings: Array = Array(clear.get("bindings", []))
	_assert_eq(_array_text(Array(cleared_bindings[0])), "1,2", "summon pair clear preserves previous slots")
	_assert_eq(_array_text(Array(cleared_bindings[1])), "", "summon pair clear clears selected slot")
	_assert_eq(_array_text(Array(cleared_bindings[2])), "5,6", "summon pair clear preserves later slots")
	Array(cleared_bindings[0])[0] = 99
	var original := [[1, 2], [3, 4]]
	var original_clear: Dictionary = service.summon_pair_clear_intent(original, 0)
	Array(Array(original_clear.get("bindings", []))[1])[0] = 88
	_assert_eq(_array_text(Array(original[1])), "3,4", "summon pair clear should duplicate nested binding arrays")
	var invalid_low: Dictionary = service.summon_pair_clear_intent([[1, 2]], -1)
	_assert_eq(String(invalid_low.get("action", "")), "none", "summon pair clear rejects low slot")
	_assert_eq(_array_text(Array(Array(invalid_low.get("bindings", []))[0])), "1,2", "summon pair clear low no-op preserves bindings")
	var invalid_high: Dictionary = service.summon_pair_clear_intent([[1, 2]], 4)
	_assert_eq(String(invalid_high.get("action", "")), "none", "summon pair clear rejects high slot")


func _check_summon_pair_cycle(service) -> void:
	var defaults := [[1, 2], [3, 4], [5, 6], [2, 4]]
	var forward: Dictionary = service.summon_pair_cycle_intent(
		[[1, 2], [3, 4], []],
		0,
		1,
		defaults,
		6
	)
	_assert_eq(String(forward.get("action", "")), "set", "summon pair cycle forward action")
	_assert_eq(int(forward.get("candidate_index", -1)), 2, "summon pair cycle skips occupied forward default")
	_assert_eq(_array_text(Array(forward.get("pair", []))), "5,6", "summon pair cycle forward pair")
	var next_bindings: Array = Array(forward.get("bindings", []))
	_assert_eq(_array_text(Array(next_bindings[0])), "5,6", "summon pair cycle returns updated bindings")
	_assert_eq(_array_text(Array(next_bindings[1])), "3,4", "summon pair cycle preserves other slots")

	var backward: Dictionary = service.summon_pair_cycle_intent(
		[[5, 6], [3, 4], []],
		0,
		-1,
		defaults,
		6
	)
	_assert_eq(String(backward.get("action", "")), "set", "summon pair cycle backward action")
	_assert_eq(int(backward.get("candidate_index", -1)), 0, "summon pair cycle skips occupied backward default")
	_assert_eq(_array_text(Array(backward.get("pair", []))), "1,2", "summon pair cycle backward pair")

	var missing_current: Dictionary = service.summon_pair_cycle_intent(
		[[4, 6], [3, 4]],
		0,
		1,
		defaults,
		6
	)
	_assert_eq(int(missing_current.get("candidate_index", -1)), 2, "summon pair cycle starts after default zero when current key is missing")
	_assert_eq(_array_text(Array(missing_current.get("pair", []))), "5,6", "summon pair cycle chooses first free default after missing current")

	var none: Dictionary = service.summon_pair_cycle_intent(
		[[], [1, 2], [3, 4], [5, 6], [2, 4]],
		0,
		1,
		defaults,
		6
	)
	_assert_eq(String(none.get("action", "")), "none", "summon pair cycle reports no free binding")
	_assert_eq(_array_text(Array(Array(none.get("bindings", []))[0])), "", "summon pair cycle no-op preserves bindings")


func _check_portal_index(service) -> void:
	_assert_eq(int(service.portal_index_from_vector(Vector2.ZERO, 99, 8)), 7, "neutral portal clamps high fallback")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.1, 0.1), -4, 8)), 0, "weak vector clamps low fallback")
	_assert_eq(int(service.portal_index_from_vector(Vector2(-0.6, -0.6), 4, 8)), 0, "up-left vector selects portal 0")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.0, -0.7), 4, 8)), 1, "up vector selects portal 1")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.7, -0.7), 4, 8)), 2, "up-right vector selects portal 2")
	_assert_eq(int(service.portal_index_from_vector(Vector2(-0.7, 0.0), 4, 8)), 3, "left vector selects portal 3")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.7, 0.0), 4, 8)), 4, "right vector selects portal 4")
	_assert_eq(int(service.portal_index_from_vector(Vector2(-0.7, 0.7), 4, 8)), 5, "down-left vector selects portal 5")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.0, 0.7), 4, 8)), 6, "down vector selects portal 6")
	_assert_eq(int(service.portal_index_from_vector(Vector2(0.7, 0.7), 4, 8)), 7, "down-right vector selects portal 7")
	_assert_eq(int(service.portal_index_from_vector(Vector2.RIGHT, 2, 0)), 0, "empty portal count falls back to zero safely")


func _check_puppet_condition(service) -> void:
	_assert_eq(service.puppet_condition({"uses_heat": true, "heat": 80.0, "heat_capacity": 100.0, "hero_live": true}), "self_overheat", "overheat condition")
	_assert_eq(service.puppet_condition({"hero_live": false}), "hero_absent", "hero absent condition")
	_assert_eq(service.puppet_condition({"hero_live": true, "target_live": true, "target_projectile_signal": 0.4}), "enemy_shooting", "projectile signal condition")
	_assert_eq(service.puppet_condition({"hero_live": true, "delta_ring": 2.0, "hold_range": 0.8}), "enemy_far", "enemy far condition")
	_assert_eq(service.puppet_condition({"hero_live": true, "delta_ring": 0.2, "target_radius": 0.2}), "enemy_close", "enemy close condition")
	_assert_eq(service.puppet_condition({"hero_live": true, "delta_ring": 0.7, "target_radius": 0.2, "hold_range": 0.8}), "default", "default condition")


func _check_puppet_move(service) -> void:
	var base_context := {
		"unit": {"live": true, "ring": 5.0, "lane": 0.0, "facing": 1, "phase": 0.0, "stats": {"ai": "ranged_pack", "hold_range": 1.2}},
		"target": {"live": true, "ring": 5.4, "lane": 0.2, "stats": {}},
		"hero": {"live": true, "ring": 4.0, "lane": 0.0},
		"unit_index": 1,
		"group_size": 3,
		"delta": 0.1,
		"delta_ring": 0.4,
		"delta_lane": 0.2,
		"ring_length": 20.0,
		"battle_half_height": 4.0,
	}
	var ranged: Dictionary = service.puppet_move_intent(base_context)
	_assert_vec_close(ranged.get("move", Vector2.ZERO), Vector2(-1.0, 0.1), "ranged pack close move")
	if float(ranged.get("phase", 0.0)) <= 0.0:
		_fail("puppet_move_intent should advance phase.")
	var formation_context := base_context.duplicate(true)
	Dictionary(formation_context["unit"])["stats"] = {"ai": "formation_xi", "hold_range": 1.2, "flank_width": 0.86}
	formation_context["unit_index"] = 7
	var formation: Dictionary = service.puppet_move_intent(formation_context)
	if (formation.get("move", Vector2.ZERO) as Vector2).length() <= 0.01:
		_fail("formation_xi should produce movement intent: %s" % str(formation))
	var source_context := base_context.duplicate(true)
	source_context["source_rule"] = {"move": "retreat"}
	var retreat: Dictionary = service.puppet_move_intent(source_context)
	_assert_vec_close(retreat.get("move", Vector2.ZERO), Vector2(-1.0, -0.28).limit_length(1.0), "source retreat override")


func _check_puppet_attack(service) -> void:
	var groups := [
		{"_attack_index": 0, "projectile": false, "damage_type": "blunt", "_reach_by_action": {"normal": 0.2}},
		{"_attack_index": 1, "projectile": true, "damage_type": "bullet", "_reach_by_action": {"normal": 2.5}},
	]
	var jammed: Dictionary = service.puppet_attack_intent({"jammed_timer": 0.4})
	if String(jammed.get("action", "")) != "set_timer" or absf(float(jammed.get("fire_timer", 0.0)) - 0.28) > 0.001:
		_fail("jammed puppet attack should set fire timer: %s" % str(jammed))
	var disabled: Dictionary = service.puppet_attack_intent({
		"delta": 1.0,
		"sequence": ["normal"],
		"modules": [0],
		"default_modules": [0],
		"groups": groups,
		"disabled_modules": [0],
		"attack_group_count": 2,
	})
	if String(disabled.get("action", "")) != "advance_step":
		_fail("disabled module should advance puppet sequence: %s" % str(disabled))
	var fire: Dictionary = service.puppet_attack_intent({
		"delta": 1.0,
		"delta_ring": 1.2,
		"delta_lane": 0.0,
		"ai_kind": "line",
		"sequence": ["normal"],
		"modules": [0, 1],
		"default_modules": [0, 1],
		"groups": groups,
		"source_attack_preference": "ranged_first",
		"attack_group_count": 2,
		"battle_half_height": 4.0,
	})
	if String(fire.get("action", "")) != "fire" or int(fire.get("attack_index", -1)) != 1:
		_fail("puppet attack should select reachable projectile module: %s" % str(fire))


func _check_barrier_logic(service) -> void:
	_assert_actions(service.barrier_logic_intents({"logic": "heat_well"}), ["heat_well_enemies"], "heat well")
	_assert_actions(service.barrier_logic_intents({"logic": "coolant_veil"}), ["coolant_veil_allies"], "coolant veil")
	_assert_actions(service.barrier_logic_intents({"logic": "drag_net"}), ["drag_net_enemies"], "drag net")
	_assert_actions(service.barrier_logic_intents({"logic": "damage_amp"}), ["damage_amp_allies"], "damage amp")
	_assert_actions(service.barrier_logic_intents({"logic": "structure_only"}), [], "structure only")
	_assert_actions(service.barrier_logic_intents({"logic": "riposte_mirror", "enemy_inside": true, "pulse_timer": 0.1, "delta": 0.2}), ["set_pulse_timer", "pulse"], "riposte pulse")
	_assert_actions(service.barrier_logic_intents({"logic": "galaxy_castle", "pulse_timer": 0.5, "delta": 0.1}), ["damage_amp_allies", "galaxy_castle_enemies", "set_pulse_timer"], "galaxy castle")


func _check_command_diagnostics(service) -> void:
	var defaults: Dictionary = service.command_diagnostics({})
	if String(defaults.get("ai_kind", "missing")) != "" or float(defaults.get("fire_timer", -1.0)) != 0.0:
		_fail("command_diagnostics defaults should be safe: %s" % str(defaults))
		return
	if int(defaults.get("sequence_step", -1)) != 0 or int(defaults.get("sequence_size", -1)) != 0:
		_fail("command_diagnostics should clamp missing sequence values: %s" % str(defaults))
		return
	if bool(defaults.get("role_switch_configured", true)) or String(defaults.get("role_switch_target", "missing")) != "":
		_fail("command_diagnostics should not invent role switch config: %s" % str(defaults))
		return
	var model: Dictionary = service.command_diagnostics({
		"ai_kind": "formation_xi",
		"source_condition": "enemy_far",
		"source_rule": {"move": "kite"},
		"source_attack_preference": "ranged_first",
		"fire_timer": -0.5,
		"sequence_step": -3,
		"sequence": ["normal", "armor"],
		"movement_mode": "drive",
		"movement_gate_reason": "braking",
		"role_switch": "hero",
	})
	if String(model.get("ai_kind", "")) != "formation_xi" or String(model.get("source_condition", "")) != "enemy_far":
		_fail("command_diagnostics should expose AI/source condition: %s" % str(model))
		return
	if String(model.get("source_move_kind", "")) != "kite" or String(model.get("source_attack_preference", "")) != "ranged_first":
		_fail("command_diagnostics should expose source move/preference: %s" % str(model))
		return
	if float(model.get("fire_timer", 1.0)) != 0.0 or int(model.get("sequence_step", 99)) != 0 or int(model.get("sequence_size", 0)) != 2:
		_fail("command_diagnostics should clamp timer/step and infer sequence size: %s" % str(model))
		return
	if String(model.get("movement_mode", "")) != "drive" or String(model.get("movement_gate_reason", "")) != "braking":
		_fail("command_diagnostics should expose movement facts: %s" % str(model))
		return
	if not bool(model.get("role_switch_configured", false)) or String(model.get("role_switch_target", "")) != "hero":
		_fail("command_diagnostics should expose role switch config: %s" % str(model))
		return


func _assert_actions(intents: Array, expected: Array, label: String) -> void:
	var actual: Array = []
	for raw_intent in intents:
		if raw_intent is Dictionary:
			actual.append(String(Dictionary(raw_intent).get("action", "")))
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _array_text(values: Array) -> String:
	var pieces: Array = []
	for value in values:
		pieces.append(String.num_int64(int(value)))
	return ",".join(pieces)


func _entry_text(loadout: Array) -> String:
	var pieces: Array = []
	for raw_entry in loadout:
		var entry: Dictionary = raw_entry if raw_entry is Dictionary else {}
		pieces.append("%s:%d" % [String(entry.get("role", "")), int(entry.get("index", -1))])
	return "|".join(pieces)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.001:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])


func _assert_vec_close(actual_value, expected: Vector2, label: String) -> void:
	var actual: Vector2 = actual_value if actual_value is Vector2 else Vector2.INF
	if actual.distance_to(expected) > 0.01:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
