extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_hit_resolution_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleHitResolutionServiceScript := preload("res://scripts/services/battle_hit_resolution_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleHitResolutionService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleHitResolutionService",
		"extends RefCounted",
		"attack_entry_intent",
		"projectile_preflight_intent",
		"apply_event_patch",
		"target_hit_context",
		"momentum_damage_gate_intent",
		"momentum_damage_gate_event_patch",
		"melee_type_adjustments",
		"combo_scaling_intent",
		"damage_intent",
		"damage_stack_intent",
		"part_damage_intent",
		"momentum_response_intent",
		"melee_momentum_stagger_pair",
		"melee_pair_impact_position_intent",
		"post_hit_intents",
		"status_tick_intent",
	]:
		if service_source.find(token) < 0:
			_fail("BattleHitResolutionService missing token: %s" % token)
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
		"GpuCollisionPipeline",
		"Fighter",
		"_resolve_attack",
		"take_hit(",
		"queue_free",
		"Time.",
		"randf",
		"randi",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("BattleHitResolutionService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleHitResolutionService = preload(\"res://scripts/services/battle_hit_resolution_service.gd\")",
		"var battle_hit_resolution_service: BattleHitResolutionService",
		"battle_hit_resolution_service = BattleHitResolutionService.new()",
		"func _battle_hit_resolution_service() -> BattleHitResolutionService",
		"_battle_hit_resolution_service().attack_entry_intent",
		"_battle_hit_resolution_service().projectile_preflight_intent",
		"_battle_hit_resolution_service().apply_event_patch",
		"_battle_hit_resolution_service().target_hit_context",
		"_battle_hit_resolution_service().momentum_damage_gate_intent",
		"_battle_hit_resolution_service().momentum_damage_gate_event_patch",
		"_battle_hit_resolution_service().melee_type_adjustments",
		"_battle_hit_resolution_service().combo_scaling_intent",
		"_battle_hit_resolution_service().damage_stack_intent",
		"_battle_hit_resolution_service().part_damage_intent",
		"_battle_hit_resolution_service().momentum_response_intent",
		"\"kind\": \"melee_momentum_stagger_pair\"",
		"_battle_hit_resolution_service().melee_pair_impact_position_intent({",
		"_battle_hit_resolution_service().post_hit_intents",
		"func _execute_post_hit_intents(",
		"_battle_hit_resolution_service().status_tick_intent",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle hit resolution token: %s" % token)
			return
	var resolve_body := _function_body(main_source, "func _resolve_attack(")
	if resolve_body.is_empty():
		_fail("Unable to locate _resolve_attack body.")
		return
	if resolve_body.contains("if false and _is_laser_telegraph_event"):
		_fail("_resolve_attack should not keep disabled laser telegraph fallback.")
		return
	for stale_fragment in [
		"for key in event_patch.keys()",
		"for key in hit_patch.keys()",
		"event[\"raw_momentum\"] =",
		"event[\"contact_gate_model\"] =",
		"match String(entry_intent.get(\"action\", \"\"))",
		"var preflight := _battle_hit_resolution_service().projectile_preflight_intent({",
		"var event_patch: Dictionary = Dictionary(preflight.get(\"event_patch\", {}))",
		"event = _battle_hit_resolution_service().apply_event_patch(event, event_patch)",
		"match String(preflight.get(\"action\", \"continue\"))",
		"_acquire_missile_lock_target(attacker, event)",
		"event[\"locked_target\"] = missile_target",
		"attacker.set_meta(\"projectile_signal\"",
		"_consume_ammo_for_event(attacker, event)",
		"var attacker_blind := _unit_blind_strength(attacker)",
		"_apply_weapon_recoil_from_momentum(attacker, event)",
		"first_projectile_impact = _first_projectile_impact(attacker, event)",
		"event[\"projectile_impact_position\"] =",
		"_spawn_projectile_trace(attacker, event)",
		"_true_bullet_target_blocked(attacker, locked_target, event)",
		"_true_bullet_unit_before_locked_target(attacker, target, locked_target, event)",
		"_attack_part_hit(attacker, target, event)",
		".target_hit_context(event, hit,",
		"_one_way_shield_intercept(attacker, target, event)",
		"_target_projectile_shield_reflects(target, event)",
		"_reflect_projectile_from_target_shield(target, attacker, event)",
		"_counter_tier_for_hit(target, damage_type)",
		"_rps_multiplier(String(event.get(\"state\", \"normal\")), target.current_state)",
		"_momentum_damage_for_event(attacker, event)",
		"_projectile_raw_damage_for_event(attacker, target, event)",
		"_maybe_detach_barrier_tile_from_momentum",
		"_melee_damage_adjusted(event, damage)",
		"_projectile_material_adjusted_damage(target, event, damage)",
		".momentum_damage_gate_intent({",
		".momentum_damage_gate_event_patch(event, gate_intent, {",
		"_apply_combo_hit_scaling(attacker, target, event, damage)",
		".damage_stack_intent({",
		"_spawn_projectile_hit_vfx_on_target({",
		"_spawn_hit_effect(target, counter_tier, damage_type",
		"_apply_projectile_momentum_stagger(attacker, target, event)",
		"_apply_active_melee_momentum_stagger(attacker, target, event)",
		"_apply_hit_displacement(attacker, target, event, 0, nullified)",
		".post_hit_intents({",
		"_execute_post_hit_intents(attacker, target, event, post_hit_intents",
		"post_hit_result.get(\"killed_units\"",
		"for killed_by_effect in Array(target_outcome.get(\"killed_units\", [])):",
		"if not killed_units.has(killed_by_effect):",
		"if bool(target_outcome.get(\"return_from_resolve\", false)):",
		"if bool(target_outcome.get(\"continue_target\", false)):",
		"if bool(target_outcome.get(\"killed\", false)):",
		"for raw_intent in post_hit_intents:",
		"match String(post_intent.get(\"action\", \"\"))",
	]:
		if resolve_body.contains(stale_fragment):
			_fail("_resolve_attack should delegate event patch application and momentum-gate metadata: %s" % stale_fragment)
			return
	if resolve_body.count("_execute_attack_entry_intent(attacker, event, entry_intent)") != 2:
		_fail("_resolve_attack should dispatch both pre-normalize and post-normalize entry intents through one helper.")
		return
	var entry_dispatch_body := _function_body(main_source, "func _execute_attack_entry_intent")
	if entry_dispatch_body.is_empty():
		_fail("Unable to locate _execute_attack_entry_intent body.")
		return
	for token in [
		"\"return\"",
		"\"mark_executed_return\"",
		"\"fail_missing_gun_source\"",
		"\"clear_projectile_mark_return\"",
		"_mark_unit_attack_executed",
		"_play_module_fail_sfx",
		"_show_battle_message",
		"_clear_projectile_fields_for_runtime_melee",
		"return true",
		"return false",
	]:
		if entry_dispatch_body.find(token) < 0:
			_fail("_execute_attack_entry_intent missing dispatch token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_projectile_preflight(attacker, event)") != 1:
		_fail("_resolve_attack should prepare projectile preflight through one helper.")
		return
	var preflight_preparation_body := _function_body(main_source, "func _prepare_attack_projectile_preflight")
	if preflight_preparation_body.is_empty():
		_fail("Unable to locate _prepare_attack_projectile_preflight body.")
		return
	for token in [
		"_battle_hit_resolution_service().projectile_preflight_intent({",
		"_projectile_behavior_for_data(event)",
		"BULLET_HELL_DEFAULT_SPEED_MULT",
		"STANDARD_MISSILE_EXPLOSION_RADIUS",
		"_is_laser_telegraph_event(event)",
		"_is_true_bullet_event(event)",
		"_is_chemical_projectile_event(event)",
		"_chemical_firework_event(event)",
		"_is_missile_projectile_event(event)",
		"_projectile_consumes_on_first_hit(event)",
		"Dictionary(preflight.get(\"event_patch\", {}))",
		"_battle_hit_resolution_service().apply_event_patch(event, event_patch)",
		"_execute_projectile_preflight_intent(attacker, event, preflight)",
		"\"event\"",
		"\"stop\"",
	]:
		if preflight_preparation_body.find(token) < 0:
			_fail("_prepare_attack_projectile_preflight missing token: %s" % token)
			return
	if preflight_preparation_body.count("_execute_projectile_preflight_intent(attacker, event, preflight)") != 1:
		_fail("_prepare_attack_projectile_preflight should dispatch projectile preflight through one helper.")
		return
	var preflight_dispatch_body := _function_body(main_source, "func _execute_projectile_preflight_intent")
	if preflight_dispatch_body.is_empty():
		_fail("Unable to locate _execute_projectile_preflight_intent body.")
		return
	for token in [
		"\"queue_laser_telegraph\"",
		"\"queue_true_bullet\"",
		"\"queue_chemical\"",
		"\"resolve_chemical_firework\"",
		"\"queue_missile\"",
		"_queue_laser_telegraph",
		"_queue_true_bullet_lock",
		"_prepare_chemical_projectile_event",
		"_queue_chemical_projectile",
		"_resolve_chemical_firework",
		"_queue_missile_projectile",
		"return true",
		"return false",
	]:
		if preflight_dispatch_body.find(token) < 0:
			_fail("_execute_projectile_preflight_intent missing dispatch token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_missile_lock(attacker, event)") != 1:
		_fail("_resolve_attack should prepare missile lock through one helper.")
		return
	var missile_lock_body := _function_body(main_source, "func _prepare_attack_missile_lock")
	if missile_lock_body.is_empty():
		_fail("Unable to locate _prepare_attack_missile_lock body.")
		return
	for token in [
		"_is_missile_projectile_event",
		"_map_line_occluded",
		"_acquire_missile_lock_target",
		"MISSILE: no lock",
		"_show_battle_message",
		"event[\"locked_target\"]",
		"event[\"aim_locked\"]",
		"return true",
		"return false",
	]:
		if missile_lock_body.find(token) < 0:
			_fail("_prepare_attack_missile_lock missing token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_activation(attacker, event)") != 1:
		_fail("_resolve_attack should prepare attack activation through one helper.")
		return
	var attack_activation_body := _function_body(main_source, "func _prepare_attack_activation")
	if attack_activation_body.is_empty():
		_fail("Unable to locate _prepare_attack_activation body.")
		return
	for token in [
		"_event_is_explicit_gun_activation",
		"_clear_projectile_fields_for_runtime_melee",
		"_unit_uses_direct_runtime_topology",
		"_mark_unit_attack_executed",
		"set_aim_pose",
		"_projectile_source_node_for_event",
		"projectile_signal",
		"_consume_ammo_for_event",
		"ammo_consumed",
		"_training_validation_sample_record_shot",
		"_unit_blind_strength",
		"randf_range",
		"return true",
		"return false",
	]:
		if attack_activation_body.find(token) < 0:
			_fail("_prepare_attack_activation missing token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_projectile_impact(attacker, event)") != 1:
		_fail("_resolve_attack should prepare projectile impact through one helper.")
		return
	var projectile_impact_body := _function_body(main_source, "func _prepare_attack_projectile_impact")
	if projectile_impact_body.is_empty():
		_fail("Unable to locate _prepare_attack_projectile_impact body.")
		return
	for token in [
		"_is_true_bullet_event",
		"_queue_true_bullet_lock",
		"_is_chemical_projectile_event",
		"_prepare_chemical_projectile_event",
		"_queue_chemical_projectile",
		"_resolve_chemical_firework",
		"_is_missile_projectile_event",
		"_queue_missile_projectile",
		"_apply_weapon_recoil_from_momentum",
		"_apply_projectile_reflection",
		"_projectile_consumes_on_first_hit",
		"_first_projectile_impact",
		"projectile_impact_position",
		"projectile_impact_target_id",
		"_spawn_projectile_trace",
		"\"stop\"",
		"\"first_projectile_impact\"",
	]:
		if projectile_impact_body.find(token) < 0:
			_fail("_prepare_attack_projectile_impact missing token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_target_contact(attacker, target, event, first_projectile_impact)") != 1:
		_fail("_resolve_attack should prepare each target contact through one helper.")
		return
	var target_contact_body := _function_body(main_source, "func _prepare_attack_target_contact")
	if target_contact_body.is_empty():
		_fail("Unable to locate _prepare_attack_target_contact body.")
		return
	for token in [
		"_is_live_unit(target)",
		"first_projectile_impact.get(\"target\", null)",
		"_is_true_bullet_fired_event",
		"_true_bullet_target_blocked",
		"_true_bullet_unit_before_locked_target",
		"_attack_part_hit",
		"attack_rule_occlusion_recorded",
		"target_hit_context",
		"_one_way_shield_intercept",
		"_target_projectile_shield_reflects",
		"_reflect_projectile_from_target_shield",
		"\"skip\"",
		"\"event\"",
		"\"damage_type\"",
		"\"material_class\"",
	]:
		if target_contact_body.find(token) < 0:
			_fail("_prepare_attack_target_contact missing token: %s" % token)
			return
	if resolve_body.count("_prepare_attack_damage_stack(attacker, target, event, damage_type)") != 1:
		_fail("_resolve_attack should prepare each damage stack through one helper.")
		return
	var damage_stack_body := _function_body(main_source, "func _prepare_attack_damage_stack")
	if damage_stack_body.is_empty():
		_fail("Unable to locate _prepare_attack_damage_stack body.")
		return
	for token in [
		"_counter_tier_for_hit",
		"_rps_multiplier",
		"_vulnerability_multiplier",
		"_outgoing_damage_multiplier",
		"_momentum_damage_for_event",
		"\"low_momentum\"",
		"_projectile_raw_damage_for_event",
		"_maybe_detach_barrier_tile_from_momentum",
		"_melee_damage_adjusted",
		"_projectile_material_adjusted_damage",
		"momentum_damage_gate_intent",
		"momentum_damage_gate_event_patch",
		"_apply_combo_hit_scaling",
		"damage_stack_intent",
		"\"skip\"",
		"\"event\"",
		"\"counter_tier\"",
		"\"nullified\"",
		"\"non_damage\"",
		"\"raw_damage\"",
		"\"damage\"",
		"\"chemical_dot_total\"",
		"\"effect_style\"",
		"\"contact_gate_blocked\"",
	]:
		if damage_stack_body.find(token) < 0:
			_fail("_prepare_attack_damage_stack missing token: %s" % token)
			return
	if resolve_body.count("_resolve_attack_target_outcome(attacker, target, event, damage_type, material_class, damage_stack)") != 1:
		_fail("_resolve_attack should resolve each target outcome through one helper.")
		return
	var target_outcome_body := _function_body(main_source, "func _resolve_attack_target_outcome")
	if target_outcome_body.is_empty():
		_fail("Unable to locate _resolve_attack_target_outcome body.")
		return
	for token in [
		"_spawn_projectile_hit_vfx_on_target",
		"_spawn_hit_effect",
		"\"outcome\": \"blocked\"",
		"_apply_projectile_momentum_stagger",
		"_apply_active_melee_momentum_stagger",
		"_apply_hit_displacement",
		"_apply_hitstop",
		"\"outcome\": \"hit\"",
		"post_hit_intents",
		"_execute_post_hit_intents",
		"\"killed\"",
		"\"continue_target\"",
		"\"killed_units\"",
		"\"return_from_resolve\"",
	]:
		if target_outcome_body.find(token) < 0:
			_fail("_resolve_attack_target_outcome missing token: %s" % token)
			return
	if resolve_body.count("_apply_attack_target_outcome_result(target, target_outcome, killed_units)") != 1:
		_fail("_resolve_attack should apply each target outcome through one killed-unit aggregation helper.")
		return
	var target_outcome_result_body := _function_body(main_source, "func _apply_attack_target_outcome_result")
	if target_outcome_result_body.is_empty():
		_fail("Unable to locate _apply_attack_target_outcome_result body.")
		return
	for token in [
		"Array(target_outcome.get(\"killed_units\", []))",
		"if not next_killed_units.has(killed_by_effect)",
		"next_killed_units.append(killed_by_effect)",
		"return_from_resolve",
		"continue_target",
		"if bool(target_outcome.get(\"killed\", false))",
		"next_killed_units.append(target)",
		"\"killed_units\"",
	]:
		if target_outcome_result_body.find(token) < 0:
			_fail("_apply_attack_target_outcome_result missing token: %s" % token)
			return
	var post_hit_body := _function_body(main_source, "func _execute_post_hit_intents")
	if post_hit_body.is_empty():
		_fail("Unable to locate _execute_post_hit_intents body.")
		return
	for token in [
		"_apply_module_hit_effect",
		"_apply_module_variant_hit_effect",
		"_apply_takeover_status",
		"_apply_explosion_damage",
		"_detonate_suicide_puppet",
		"_register_part_damage",
		"_unit_damage_after_part_absorption",
		"_training_validation_sample_record_hit",
		"_apply_chemical_dot_status",
		"_apply_back_hit_heat",
		"_apply_projectile_momentum_stagger",
		"_apply_active_melee_momentum_stagger",
		"_apply_hit_displacement",
		"return_from_resolve",
		"continue_target",
		"killed_units",
	]:
		if post_hit_body.find(token) < 0:
			_fail("_execute_post_hit_intents missing side-effect dispatch token: %s" % token)
			return
	var melee_pair_body := _function_body(main_source, "func _apply_melee_momentum_stagger_pair")
	if melee_pair_body.is_empty():
		_fail("Unable to locate _apply_melee_momentum_stagger_pair body.")
		return
	for stale_fragment in [
		"var ratio := (gap - required_gap) / maxf(MELEE_STABILITY_THRESHOLD_FLOOR, required_gap)",
		"var duration := clampf(MELEE_STAGGER_BASE_SECONDS + ratio * MELEE_STAGGER_RATIO_SECONDS, 0.0, MELEE_STAGGER_MAX_SECONDS)",
		"var b_near_x: float = a.ring_pos + ab_delta.x",
		"var impact_combat := Vector2(wrapf(lerpf(a.ring_pos, b_near_x, 0.5), 0.0, RING_LENGTH), a.lane + ab_delta.y * 0.5)",
	]:
		if melee_pair_body.contains(stale_fragment):
			_fail("_apply_melee_momentum_stagger_pair should delegate pure stagger math to BattleHitResolutionService: %s" % stale_fragment)
			return
	var service = BattleHitResolutionServiceScript.new()
	_check_entry(service)
	_check_projectile_preflight(service)
	_check_target_context(service)
	_check_damage_and_combo(service)
	_check_melee_type_adjustments(service)
	_check_post_hit(service)
	_check_part_damage(service)
	_check_momentum_response(service)
	_check_status_ticks(service)
	if failed:
		print("BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE failed")
		quit(1)
		return
	print("BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_entry(service) -> void:
	_assert_eq(String(service.attack_entry_intent({"attacker_live": false}).get("action", "")), "return", "dead attacker gate")
	_assert_eq(String(service.attack_entry_intent({"attacker_live": true, "event_empty": true}).get("action", "")), "return", "empty event gate")
	_assert_eq(String(service.attack_entry_intent({"attacker_live": true, "projectile": false, "runtime_topology": true}).get("action", "")), "mark_executed_return", "runtime melee shortcut")
	_assert_eq(String(service.attack_entry_intent({"attacker_live": true, "projectile": true, "explicit_gun_activation": true, "has_gun_source": false}).get("action", "")), "fail_missing_gun_source", "explicit gun source gate")
	_assert_eq(String(service.attack_entry_intent({"attacker_live": true, "projectile": true, "explicit_gun_activation": false, "runtime_topology": true}).get("action", "")), "clear_projectile_mark_return", "runtime projectile clear")
	_assert_eq(String(service.attack_entry_intent({"attacker_live": true, "projectile": true, "explicit_gun_activation": true, "has_gun_source": true}).get("action", "")), "continue", "valid projectile entry")


func _check_projectile_preflight(service) -> void:
	var source_event := {"keep": 1, "replace": 2, "remove": 3, "nested": {"value": 7}}
	var patch_source := {"replace": 9, "added": 4, "erase_remove": true, "erase_keep": false}
	var patched_event: Dictionary = service.apply_event_patch(source_event, patch_source)
	_assert_eq(int(patched_event.get("keep", 0)), 1, "event patch retained field")
	_assert_eq(int(patched_event.get("replace", 0)), 9, "event patch replacement")
	_assert_eq(int(patched_event.get("added", 0)), 4, "event patch added field")
	if patched_event.has("remove") or patched_event.has("erase_remove") or patched_event.has("erase_keep"):
		_fail("Event patch should apply erase controls without retaining control keys: %s" % str(patched_event))
	var patched_nested: Dictionary = Dictionary(patched_event.get("nested", {}))
	patched_nested["value"] = 99
	if int(Dictionary(source_event.get("nested", {})).get("value", 0)) != 7 or int(source_event.get("replace", 0)) != 2 or not patch_source.has("erase_remove"):
		_fail("Event patch should not mutate source dictionaries.")
	var bullet: Dictionary = service.projectile_preflight_intent({
		"event": {"projectile": true, "projectile_style": "bullet"},
		"behavior": "bullet_hell",
		"bullet_hell_default_speed_mult": 2.8,
		"consumes_on_first_hit": true,
	})
	_assert_eq(String(bullet.get("action", "")), "continue", "bullet hell action")
	var bullet_patch: Dictionary = Dictionary(bullet.get("event_patch", {}))
	_assert_eq(String(bullet_patch.get("projectile_style", "")), "bullet_hell", "bullet hell style")
	_assert_close(float(bullet_patch.get("projectile_speed_mult", 0.0)), 2.8, "bullet hell speed")
	if not bool(bullet.get("apply_recoil", false)) or not bool(bullet.get("needs_first_impact", false)) or not bool(bullet.get("spawn_trace", false)):
		_fail("default projectile preflight should request recoil, first impact, and trace: %s" % str(bullet))
	var explosive: Dictionary = service.projectile_preflight_intent({
		"event": {
			"projectile": true,
			"projectile_style": "missile",
			"projectile_speed_mult": 99.0,
			"explosion_damage": 9,
			"explosion_damage_type": "bullet",
		},
		"behavior": "explosive",
		"standard_missile_explosion_radius": 1.3,
	})
	var explosive_patch: Dictionary = Dictionary(explosive.get("event_patch", {}))
	_assert_eq(String(explosive_patch.get("projectile_behavior", "")), "explosive", "explosive behavior")
	_assert_close(float(explosive_patch.get("projectile_speed_mult", 0.0)), 2.4, "explosive speed clamp")
	_assert_close(float(explosive_patch.get("explosion_radius", 0.0)), 1.3, "missile explosion radius")
	if explosive_patch.has("erase_explosion_damage") or explosive_patch.has("erase_explosion_damage_type"):
		_fail("explosive preflight should preserve authored explosion damage payload: %s" % str(explosive_patch))
	_assert_eq(String(service.projectile_preflight_intent({"event": {"projectile": true}, "laser_telegraph": true}).get("action", "")), "queue_laser_telegraph", "laser telegraph route")
	_assert_eq(String(service.projectile_preflight_intent({"event": {"projectile": true}, "true_bullet": true}).get("action", "")), "queue_true_bullet", "true bullet route")
	_assert_eq(String(service.projectile_preflight_intent({"event": {"projectile": true}, "chemical_projectile": true, "chemical_ready": false}).get("action", "")), "queue_chemical", "chemical queue route")
	_assert_eq(String(service.projectile_preflight_intent({"event": {"projectile": true}, "chemical_projectile": true, "chemical_ready": true, "chemical_firework": true, "chemical_firework_expanded": false}).get("action", "")), "resolve_chemical_firework", "chemical firework route")
	_assert_eq(String(service.projectile_preflight_intent({"event": {"projectile": true}, "missile_projectile": true}).get("action", "")), "queue_missile", "missile route")


func _check_target_context(service) -> void:
	var context: Dictionary = service.target_hit_context(
		{"damage_type": "laser", "material_class": "projectile", "attacker_terminal_weapon_kind": "rifle"},
		{"part_index": 2, "part_kind": "limb", "part_name": "ARM", "torso_unit_index": 0, "target_terminal_weapon_kind": "blade", "position": Vector2(3.0, 4.0)},
		{"position": Vector2(1.0, 1.0), "state": "stagger"}
	)
	var patch: Dictionary = Dictionary(context.get("event_patch", {}))
	_assert_eq(int(patch.get("target_part_index", -1)), 2, "target part index")
	_assert_eq(String(patch.get("target_part_kind", "")), "limb", "target part kind")
	_assert_eq(String(patch.get("target_terminal_weapon_kind", "")), "blade", "target terminal kind")
	_assert_eq(String(patch.get("attacker_terminal_weapon_kind", "")), "rifle", "attacker terminal fallback")
	_assert_vec_close(patch.get("hit_position_combat", Vector2.ZERO), Vector2(3.0, 4.0), "hit position")
	_assert_eq(String(context.get("damage_type", "")), "laser", "target damage type")
	_assert_eq(String(context.get("target_state", "")), "stagger", "target state")


func _check_damage_and_combo(service) -> void:
	var gate: Dictionary = service.momentum_damage_gate_intent({
		"raw_momentum": 25.0,
		"momentum": 20.0,
		"damage_coefficient": 2.0,
		"adjustment_coefficient": 1.5,
		"break_value": 59.0,
		"knock_adjustment_coefficient": 2.0,
	})
	_assert_close(float(gate.get("damage_value", 0.0)), 60.0, "momentum gate damage")
	if bool(gate.get("threshold_blocked", true)):
		_fail("Momentum gate should pass when damage exceeds break value: %s" % str(gate))
	_assert_close(float(gate.get("raw_momentum", 0.0)), 25.0, "momentum gate raw momentum")
	_assert_close(float(gate.get("capped_momentum", 0.0)), 20.0, "momentum gate capped momentum")
	_assert_close(float(gate.get("break_gate", 0.0)), 59.0, "momentum gate break gate")
	_assert_close(float(gate.get("knock_momentum", 0.0)), 40.0, "momentum gate knock")
	var gate_event := {"raw_momentum": 25.0, "unrelated": "keep"}
	var gate_patch: Dictionary = service.momentum_damage_gate_event_patch(gate_event, gate)
	_assert_close(float(gate_patch.get("raw_momentum", 0.0)), 25.0, "momentum gate event raw momentum")
	_assert_close(float(gate_patch.get("momentum", 0.0)), 20.0, "momentum gate event momentum")
	_assert_close(float(gate_patch.get("damage_after_break", 0.0)), 60.0, "momentum gate event damage")
	_assert_close(float(gate_patch.get("effective_break_value", 0.0)), 59.0, "momentum gate event break value")
	if bool(gate_patch.get("contact_gate_blocked", true)) or bool(gate_patch.get("threshold_blocked", true)) or String(gate_patch.get("contact_gate_model", "")) != "momentum_damage_gate":
		_fail("Momentum gate event patch should expose pass telemetry: %s" % str(gate_patch))
	var patched_gate_event: Dictionary = service.apply_event_patch(gate_event, gate_patch)
	if String(patched_gate_event.get("unrelated", "")) != "keep" or gate_event.has("contact_gate_model"):
		_fail("Momentum gate event application should preserve unrelated fields and source ownership.")
	var equal_block: Dictionary = service.momentum_damage_gate_intent({
		"momentum": 20.0,
		"damage_coefficient": 2.0,
		"adjustment_coefficient": 1.5,
		"break_value": 60.0,
	})
	if not bool(equal_block.get("threshold_blocked", false)):
		_fail("Momentum gate should block when damage only equals break value: %s" % str(equal_block))
	var below_block: Dictionary = service.momentum_damage_gate_intent({
		"momentum": 9.0,
		"damage_coefficient": 2.0,
		"adjustment_coefficient": 1.0,
		"break_value": 19.0,
	})
	if not bool(below_block.get("threshold_blocked", false)):
		_fail("Momentum gate should block when damage is below break value: %s" % str(below_block))
	var non_damage_knock: Dictionary = service.momentum_damage_gate_intent({
		"momentum": 24.0,
		"damage_coefficient": 99.0,
		"adjustment_coefficient": 99.0,
		"break_value": 999.0,
		"knock_adjustment_coefficient": 1.5,
		"non_damage": true,
	})
	if bool(non_damage_knock.get("threshold_blocked", true)):
		_fail("Non-damage contact should bypass the damage gate: %s" % str(non_damage_knock))
	_assert_close(float(non_damage_knock.get("damage_value", -1.0)), 0.0, "non-damage gate damage")
	_assert_close(float(non_damage_knock.get("knock_momentum", 0.0)), 36.0, "non-damage knock momentum")
	var stab_gate: Dictionary = service.momentum_damage_gate_intent({
		"momentum": 8.0,
		"precomputed_damage": 12.0,
		"break_value": 20.0,
		"break_value_adjustment": 0.5,
	})
	if bool(stab_gate.get("threshold_blocked", true)) or absf(float(stab_gate.get("effective_break_value", 0.0)) - 10.0) > 0.001:
		_fail("Stab gate should use adjusted break value: %s" % str(stab_gate))
	for field in ["raw_momentum", "momentum", "capped_momentum", "damage_coefficient", "adjustment_coefficient", "break_value", "effective_break_value", "break_gate", "knock_momentum"]:
		if not gate.has(field):
			_fail("Momentum gate telemetry missing field %s: %s" % [field, str(gate)])
	var combo: Dictionary = service.combo_scaling_intent({
		"damage": 100,
		"combo_active": true,
		"total_hits": 1,
		"attacker_hits": 2,
		"max_hits": 4,
		"damage_min_mult": 0.4,
		"damage_curve_power": 1.0,
		"knock_max_mult": 1.9,
		"knock_curve_power": 1.0,
	})
	_assert_eq(int(combo.get("total_hits", 0)), 2, "combo total hits")
	_assert_eq(int(combo.get("attacker_hits", 0)), 3, "combo attacker hits")
	_assert_close(float(combo.get("damage_mult", 0.0)), 0.8, "combo damage mult")
	_assert_eq(int(combo.get("damage", 0)), 80, "combo damage")
	if not bool(combo.get("show_message", false)):
		_fail("combo scaling should show message after first hit.")
	var no_combo: Dictionary = service.combo_scaling_intent({"damage": 30, "combo_active": false})
	_assert_eq(int(no_combo.get("damage", 0)), 30, "no combo damage")
	var damage: Dictionary = service.damage_intent({
		"raw_damage": 100.0,
		"multiplier": 1.5,
		"melee_adjusted_damage": 120,
		"material_adjusted_damage": 110,
		"combo_applies": true,
		"combo_damage": 88,
		"chemical_dot_applies": true,
		"chemical_dot_mult": 1.25,
		"chemical_frontload": 0.5,
		"projectile_style": "spray",
	})
	_assert_eq(int(damage.get("chemical_dot_total", 0)), 110, "chemical dot total")
	_assert_eq(int(damage.get("damage", 0)), 44, "chemical frontload damage")
	var non_damage: Dictionary = service.damage_intent({"raw_damage": 100.0, "non_damage": true, "chemical_dot_applies": true})
	_assert_eq(int(non_damage.get("damage", -1)), 0, "non-damage damage")
	_assert_eq(int(non_damage.get("chemical_dot_total", -1)), 0, "non-damage dot")
	var blocked: Dictionary = service.damage_intent({"raw_damage": 10.0, "contact_gate_blocked": true, "projectile_style": "bullet"})
	if not bool(blocked.get("blocked", false)) or String(blocked.get("effect_style", "")) != "threshold":
		_fail("blocked damage intent should expose threshold style: %s" % str(blocked))
	var zero_melee: Dictionary = service.damage_stack_intent({"projectile": false, "raw_damage": 0.0})
	if bool(zero_melee.get("continue_hit", true)) or String(zero_melee.get("reason", "")) != "zero_raw_melee":
		_fail("zero raw melee should stop hit resolution: %s" % str(zero_melee))


func _check_melee_type_adjustments(service) -> void:
	var slash: Dictionary = service.melee_type_adjustments("slash")
	_assert_eq(String(slash.get("internal_damage_type", "")), "tear", "slash internal alias")
	_assert_close(float(slash.get("damage_adjustment", 0.0)), 1.5, "slash damage adjustment")
	_assert_close(float(slash.get("break_value_adjustment", 0.0)), 1.0, "slash break adjustment")
	_assert_close(float(slash.get("knock_adjustment", 0.0)), 1.0, "slash knock adjustment")
	var tear: Dictionary = service.melee_type_adjustments("tear")
	_assert_eq(String(tear.get("player_damage_type", "")), "slash", "tear player alias")
	_assert_close(float(tear.get("damage_adjustment", 0.0)), 1.5, "tear damage adjustment")
	var stab: Dictionary = service.melee_type_adjustments("stab")
	_assert_eq(String(stab.get("internal_damage_type", "")), "pierce", "stab internal alias")
	_assert_close(float(stab.get("damage_adjustment", 0.0)), 1.0, "stab damage adjustment")
	_assert_close(float(stab.get("break_value_adjustment", 0.0)), 0.5, "stab break adjustment")
	var pierce: Dictionary = service.melee_type_adjustments("pierce")
	_assert_eq(String(pierce.get("player_damage_type", "")), "stab", "pierce player alias")
	_assert_close(float(pierce.get("break_value_adjustment", 0.0)), 0.5, "pierce break adjustment")
	var blunt: Dictionary = service.melee_type_adjustments("blunt")
	_assert_close(float(blunt.get("damage_adjustment", 0.0)), 1.0, "blunt damage adjustment")
	_assert_close(float(blunt.get("break_value_adjustment", 0.0)), 1.0, "blunt break adjustment")
	_assert_close(float(blunt.get("knock_adjustment", 0.0)), 2.0, "blunt knock adjustment")


func _check_post_hit(service) -> void:
	_assert_actions(service.post_hit_intents({"projectile": true, "blocked": true}), ["projectile_stagger", "hit_displacement", "hitstop", "continue_target"], "blocked projectile actions")
	_assert_actions(service.post_hit_intents({
		"projectile": true,
		"explosion_radius": 0.8,
		"damage": 42,
		"chemical_dot_total": 12,
		"back_hit": true,
	}), [
		"module_hit_effect",
		"module_variant_hit_effect",
		"takeover_status",
		"explosion",
		"part_damage",
		"hitstop",
		"take_hit",
		"chemical_dot",
		"back_hit_heat",
		"projectile_stagger",
		"hit_displacement",
	], "normal projectile post-hit actions")
	_assert_actions(service.post_hit_intents({"non_damage": true}), ["module_hit_effect", "module_variant_hit_effect", "takeover_status", "continue_target"], "non-damage post-hit actions")


func _check_part_damage(service) -> void:
	_assert_eq(String(service.part_damage_intent({
		"mode": "route",
		"target_valid": true,
		"target_mech": true,
		"projectile": true,
		"damage_type": "tear",
	}).get("reason", "")), "not_tear_part_damage", "projectile part damage no-op")
	var limb_route: Dictionary = service.part_damage_intent({
		"mode": "route",
		"target_valid": true,
		"target_mech": true,
		"projectile": false,
		"damage_type": "tear",
		"raw_index": 3,
		"part_kind": "limb",
		"attack_group_count": 4,
	})
	_assert_eq(String(limb_route.get("action", "")), "route_limb", "limb route")
	_assert_eq(int(limb_route.get("attack_index", -1)), 3, "limb attack index")
	var terminal_route: Dictionary = service.part_damage_intent({
		"mode": "route",
		"target_valid": true,
		"target_mech": true,
		"damage_type": "tear",
		"raw_index": 9,
		"part_kind": "terminal",
		"attack_group_count": 4,
	})
	_assert_eq(String(terminal_route.get("action", "")), "route_terminal", "terminal route")
	_assert_eq(int(terminal_route.get("attack_index", -1)), 3, "terminal clamp index")
	_assert_eq(String(service.part_damage_intent({
		"mode": "route",
		"target_valid": true,
		"target_mech": true,
		"damage_type": "tear",
		"part_kind": "torso",
		"torso_index": 2,
	}).get("action", "")), "route_torso", "torso route")
	var update: Dictionary = service.part_damage_intent({
		"mode": "hp",
		"part_kind": "limb",
		"part_key": "1",
		"max_hp": 100.0,
		"current_hp": 80.0,
		"damage": 30,
		"counter_tier": 1,
	})
	_assert_eq(String(update.get("action", "")), "update", "limb hp update")
	_assert_close(float(update.get("next_hp", 0.0)), 47.6, "limb next hp")
	if float(update.get("flash_timer", 0.0)) <= 0.0:
		_fail("large limb hit should request flash: %s" % str(update))
	var terminal_break: Dictionary = service.part_damage_intent({
		"mode": "hp",
		"part_kind": "terminal",
		"part_key": "2:terminal",
		"max_hp": 24.0,
		"current_hp": 5.0,
		"damage": 8,
		"counter_tier": 0,
	})
	_assert_eq(String(terminal_break.get("action", "")), "break", "terminal break")
	_assert_close(float(terminal_break.get("flash_timer", 0.0)), 0.48, "terminal break flash")
	var torso_break: Dictionary = service.part_damage_intent({
		"mode": "hp",
		"part_kind": "torso",
		"max_hp": 30.0,
		"current_hp": 4.0,
		"damage": 8,
	})
	if String(torso_break.get("action", "")) != "break" or not bool(torso_break.get("fracture", false)):
		_fail("torso break should request fracture intent: %s" % str(torso_break))
	_assert_eq(String(service.part_damage_intent({
		"mode": "hp",
		"part_kind": "limb",
		"max_hp": 20.0,
		"already_broken": true,
	}).get("reason", "")), "already_broken", "already broken no-op")


func _check_momentum_response(service) -> void:
	var projectile: Dictionary = service.momentum_response_intent({
		"kind": "projectile_stagger",
		"projectile": true,
		"target_mech": true,
		"projectile_momentum": 120.0,
		"min_momentum": 20.0,
		"threshold": 60.0,
		"threshold_floor": 12.0,
		"base_seconds": 0.1,
		"ratio_seconds": 0.2,
		"max_seconds": 0.9,
		"gate_seconds": 0.18,
		"now": 2.0,
	})
	_assert_eq(String(projectile.get("action", "")), "apply_projectile_stagger", "projectile stagger action")
	_assert_close(float(projectile.get("duration", 0.0)), 0.3, "projectile stagger duration")
	_assert_close(float(projectile.get("gate_until", 0.0)), 2.18, "projectile stagger gate")
	_assert_eq(String(service.momentum_response_intent({
		"kind": "projectile_stagger",
		"projectile": true,
		"target_mech": true,
		"combo_active": true,
	}).get("reason", "")), "combo_active", "projectile combo gate")
	var melee_pair: Dictionary = service.momentum_response_intent({
		"kind": "active_melee_stagger",
		"projectile": false,
		"attacker_mech": true,
		"target_mech": true,
		"attacker_momentum": 50.0,
		"target_momentum": 12.0,
		"crush_stagger_mult": 1.5,
	})
	_assert_close(float(melee_pair.get("attacker_momentum", 0.0)), 75.0, "active melee crush mult")
	var stagger_pair: Dictionary = service.momentum_response_intent({
		"kind": "melee_momentum_stagger_pair",
		"unit_a_mech": true,
		"unit_b_mech": true,
		"momentum_a": 180.0,
		"momentum_b": 20.0,
		"combo_active": false,
		"threshold": 28.0,
		"source": "attack",
		"min_momentum": 18.0,
		"passive_contact_stagger_min_mult": 1.75,
		"threshold_floor": 28.0,
		"base_seconds": 0.045,
		"ratio_seconds": 0.11,
		"max_seconds": 0.56,
		"gate_seconds": 0.32,
		"gate_until": 0.0,
		"now": 2.0,
	})
	_assert_eq(String(stagger_pair.get("action", "")), "apply_melee_pair_stagger", "melee pair stagger action")
	_assert_eq(String(stagger_pair.get("staggered_side", "")), "b", "melee pair stagger side")
	_assert_eq(String(stagger_pair.get("source_attacker_side", "")), "a", "melee pair source side")
	_assert_close(float(stagger_pair.get("gap", 0.0)), 160.0, "melee pair stagger gap")
	_assert_close(float(stagger_pair.get("required_gap", 0.0)), 28.0, "melee pair required gap")
	_assert_close(float(stagger_pair.get("duration", 0.0)), 0.56, "melee pair stagger duration")
	_assert_close(float(stagger_pair.get("gate_until", 0.0)), 2.32, "melee pair stagger gate")
	_assert_close(float(stagger_pair.get("ripple_scale", 0.0)), 1.0, "melee pair ripple scale")
	var wrap_impact: Dictionary = service.melee_pair_impact_position_intent({
		"a_position": Vector2(9.0, 1.0),
		"ab_delta": Vector2(3.0, -2.0),
		"ring_length": 10.0,
	})
	_assert_eq(String(wrap_impact.get("action", "")), "resolve_melee_pair_impact_position", "melee pair impact action")
	_assert_vec_close(wrap_impact.get("position", Vector2.ZERO), Vector2(0.5, 0.0), "melee pair wrapped impact")
	var direct_impact: Dictionary = service.melee_pair_impact_position_intent({
		"a_position": Vector2(2.0, -0.5),
		"ab_delta": Vector2(4.0, 1.0),
		"ring_length": 10.0,
	})
	_assert_vec_close(direct_impact.get("position", Vector2.ZERO), Vector2(4.0, 0.0), "melee pair direct impact")
	_assert_eq(String(service.momentum_response_intent({
		"kind": "melee_momentum_stagger_pair",
		"unit_a_mech": true,
		"unit_b_mech": true,
		"momentum_a": 42.0,
		"momentum_b": 12.0,
		"threshold": 20.0,
		"source": "collision",
		"min_momentum": 18.0,
		"passive_contact_stagger_min_mult": 1.75,
	}).get("reason", "")), "below_required_gap", "melee pair collision gap gate")
	_assert_eq(String(service.momentum_response_intent({
		"kind": "melee_momentum_stagger_pair",
		"unit_a_mech": true,
		"unit_b_mech": true,
		"momentum_a": 120.0,
		"momentum_b": 10.0,
		"threshold": 20.0,
		"gate_until": 3.0,
		"now": 2.0,
	}).get("reason", "")), "gate_active", "melee pair stagger gate active")
	var direct: Dictionary = service.momentum_response_intent({
		"kind": "hit_displacement_direct",
		"event_momentum": 100.0,
		"projectile": true,
		"target_mass": 10.0,
		"attacker_mass": 5.0,
		"combo_knock_mult": 1.2,
		"combo_knock_max_mult": 1.9,
	})
	_assert_eq(String(direct.get("action", "")), "apply_direct_displacement", "direct displacement action")
	_assert_close(float(direct.get("target_velocity_impulse", 0.0)), 9.84, "direct target impulse")
	var projectile_push: Dictionary = service.momentum_response_intent({
		"kind": "hit_displacement_projectile",
		"base_knock": 0.08,
		"projectile_space_impulse_mult": 1.5,
		"damage_for_knock": 40.0,
		"combo_knock_mult": 1.0,
		"target_anchor": 0.5,
		"target_impulse_mult": 2.0,
	})
	_assert_eq(String(projectile_push.get("action", "")), "apply_projectile_displacement", "projectile displacement action")
	if float(projectile_push.get("target_velocity_impulse", 0.0)) <= 0.0:
		_fail("projectile displacement should include target velocity impulse: %s" % str(projectile_push))
	var melee: Dictionary = service.momentum_response_intent({
		"kind": "hit_displacement_melee",
		"attacker_mass": 4.0,
		"target_mass": 12.0,
		"attacker_anchor": 0.25,
		"target_anchor": 0.1,
		"damage_type": "blunt",
		"base_knock": 0.1,
		"damage_for_knock": 20.0,
		"melee_space_impulse_mult": 1.1,
		"combo_knock_mult": 1.0,
		"attacker_impulse_mult": 1.0,
		"target_impulse_mult": 1.0,
	})
	_assert_eq(String(melee.get("action", "")), "apply_melee_displacement", "melee displacement action")
	if float(melee.get("attacker_move", 0.0)) <= 0.0 or float(melee.get("target_move", 0.0)) <= 0.0:
		_fail("melee displacement should include moves: %s" % str(melee))


func _check_status_ticks(service) -> void:
	var apply_dot: Dictionary = service.status_tick_intent({
		"kind": "apply_chemical_dot",
		"duration": 3.0,
		"total_damage": 12,
		"current_dps": 1.0,
		"current_timer": 2.0,
		"bank": 0.25,
	})
	_assert_close(float(apply_dot.get("duration", 0.0)), 3.0, "apply dot duration")
	_assert_close(float(apply_dot.get("dps", 0.0)), 5.0, "apply dot dps")
	_assert_close(float(apply_dot.get("timer", 0.0)), 3.0, "apply dot timer")
	var dot_tick: Dictionary = service.status_tick_intent({
		"kind": "chemical_dot",
		"timer": 1.0,
		"dps": 8.0,
		"bank": 0.5,
		"fx_timer": 0.1,
		"delta": 0.25,
	})
	if not bool(dot_tick.get("active", false)) or int(dot_tick.get("damage", 0)) != 2 or not bool(dot_tick.get("spawn_fx", false)):
		_fail("chemical dot tick should emit damage and fx intent: %s" % str(dot_tick))
	_assert_close(float(dot_tick.get("bank", 0.0)), 0.5, "dot tick bank")
	var dot_end: Dictionary = service.status_tick_intent({"kind": "chemical_dot", "timer": 0.1, "dps": 10.0, "delta": 0.2})
	if bool(dot_end.get("active", true)) or float(dot_end.get("dps", -1.0)) != 0.0:
		_fail("chemical dot expiry should clear state: %s" % str(dot_end))
	var apply_takeover: Dictionary = service.status_tick_intent({"kind": "apply_takeover", "owner": 2, "required": 0.2, "dps": 3.0, "current_timer": 0.4})
	_assert_eq(int(apply_takeover.get("owner", 0)), 2, "takeover owner")
	_assert_close(float(apply_takeover.get("required", 0.0)), 0.75, "takeover required clamp")
	_assert_close(float(apply_takeover.get("timer", 0.0)), 0.4, "takeover timer")
	var same_owner: Dictionary = service.status_tick_intent({"kind": "takeover", "owner": 2, "unit_owner": 2})
	if bool(same_owner.get("active", true)) or String(same_owner.get("reason", "")) != "same_owner":
		_fail("takeover should clear same-owner status: %s" % str(same_owner))
	var takeover: Dictionary = service.status_tick_intent({"kind": "takeover", "owner": 2, "unit_owner": 1, "required": 0.75, "timer": 0.7, "dps": 12.0, "bank": 0.2, "delta": 0.1})
	if not bool(takeover.get("active", false)) or not bool(takeover.get("complete", false)) or int(takeover.get("damage", 0)) != 1:
		_fail("takeover tick should damage and complete: %s" % str(takeover))
	_assert_close(float(takeover.get("bank", 0.0)), 0.4, "takeover bank")


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


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
	if actual.distance_to(expected) > 0.001:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
