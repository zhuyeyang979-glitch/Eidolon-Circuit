extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_actor_command_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleActorCommandServiceScript := preload("res://scripts/services/battle_actor_command_service.gd")


func _fail(message: String) -> void:
	push_error(message)
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
		"_battle_actor_command_service().puppet_condition",
		"_battle_actor_command_service().puppet_move_intent",
		"_battle_actor_command_service().puppet_attack_intent",
		"_battle_actor_command_service().barrier_logic_intents",
		"_battle_actor_command_service().command_diagnostics",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle actor command service token: %s" % token)
			return
	var service = BattleActorCommandServiceScript.new()
	_check_deploy(service)
	_check_summon(service)
	_check_auto_summon(service)
	_check_puppet_condition(service)
	_check_puppet_move(service)
	_check_puppet_attack(service)
	_check_barrier_logic(service)
	_check_command_diagnostics(service)
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
