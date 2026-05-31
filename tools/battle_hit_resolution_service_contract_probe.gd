extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_hit_resolution_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleHitResolutionServiceScript := preload("res://scripts/services/battle_hit_resolution_service.gd")


func _fail(message: String) -> void:
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
		"target_hit_context",
		"combo_scaling_intent",
		"damage_intent",
		"damage_stack_intent",
		"part_damage_intent",
		"momentum_response_intent",
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
		"_battle_hit_resolution_service().target_hit_context",
		"_battle_hit_resolution_service().combo_scaling_intent",
		"_battle_hit_resolution_service().damage_stack_intent",
		"_battle_hit_resolution_service().part_damage_intent",
		"_battle_hit_resolution_service().momentum_response_intent",
		"_battle_hit_resolution_service().post_hit_intents",
		"_battle_hit_resolution_service().status_tick_intent",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle hit resolution token: %s" % token)
			return
	var resolve_body := _function_body(main_source, "func _resolve_attack")
	if resolve_body.is_empty():
		_fail("Unable to locate _resolve_attack body.")
		return
	if resolve_body.contains("if false and _is_laser_telegraph_event"):
		_fail("_resolve_attack should not keep disabled laser telegraph fallback.")
		return
	var service = BattleHitResolutionServiceScript.new()
	_check_entry(service)
	_check_projectile_preflight(service)
	_check_target_context(service)
	_check_damage_and_combo(service)
	_check_post_hit(service)
	_check_part_damage(service)
	_check_momentum_response(service)
	_check_status_ticks(service)
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
		"event": {"projectile": true, "projectile_style": "missile", "projectile_speed_mult": 99.0},
		"behavior": "explosive",
		"standard_missile_explosion_radius": 1.3,
	})
	var explosive_patch: Dictionary = Dictionary(explosive.get("event_patch", {}))
	_assert_eq(String(explosive_patch.get("projectile_behavior", "")), "explosive", "explosive behavior")
	_assert_close(float(explosive_patch.get("projectile_speed_mult", 0.0)), 2.4, "explosive speed clamp")
	_assert_close(float(explosive_patch.get("explosion_radius", 0.0)), 1.3, "missile explosion radius")
	if not bool(explosive_patch.get("erase_explosion_damage", false)) or not bool(explosive_patch.get("erase_explosion_damage_type", false)):
		_fail("explosive preflight should request legacy explosion damage cleanup: %s" % str(explosive_patch))
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


func _check_post_hit(service) -> void:
	_assert_actions(service.post_hit_intents({"projectile": true, "blocked": true}), ["projectile_stagger", "hitstop", "continue_target"], "blocked projectile actions")
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
