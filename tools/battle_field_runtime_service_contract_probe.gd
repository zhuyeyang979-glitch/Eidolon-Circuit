extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_field_runtime_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleFieldRuntimeServiceScript := preload("res://scripts/services/battle_field_runtime_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleFieldRuntimeService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleFieldRuntimeService",
		"extends RefCounted",
		"lease_intent",
		"annuity_intent",
		"support_aura_model",
		"support_target_intent",
		"speed_lane_intent",
		"coin_generator_intent",
		"field_coin_update_intent",
		"signal_jammer_intent",
		"barrier_utility_intents",
		"field_effect_intent",
		"trap_trigger_intent",
		"trap_fire_intents",
		"hatchery_intent",
		"hatchling_stats_intent",
	]:
		if service_source.find(token) < 0:
			_fail("BattleFieldRuntimeService missing token: %s" % token)
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
			_fail("BattleFieldRuntimeService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleFieldRuntimeService = preload(\"res://scripts/services/battle_field_runtime_service.gd\")",
		"var battle_field_runtime_service: BattleFieldRuntimeService",
		"battle_field_runtime_service = BattleFieldRuntimeService.new()",
		"func _battle_field_runtime_service() -> BattleFieldRuntimeService",
		"_battle_field_runtime_service().lease_intent",
		"_battle_field_runtime_service().annuity_intent",
		"_battle_field_runtime_service().support_aura_model",
		"_battle_field_runtime_service().support_target_intent",
		"_battle_field_runtime_service().speed_lane_intent",
		"_battle_field_runtime_service().coin_generator_intent",
		"_battle_field_runtime_service().field_coin_update_intent",
		"_battle_field_runtime_service().signal_jammer_intent",
		"_battle_field_runtime_service().barrier_utility_intents",
		"_battle_field_runtime_service().field_effect_intent",
		"_battle_field_runtime_service().trap_trigger_intent",
		"_battle_field_runtime_service().trap_fire_intents",
		"_battle_field_runtime_service().hatchery_intent",
		"_battle_field_runtime_service().hatchling_stats_intent",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle field runtime token: %s" % token)
			return
	var service = BattleFieldRuntimeServiceScript.new()
	_check_resource_intents(service)
	_check_support_intents(service)
	_check_speed_coin_jam(service)
	_check_barrier_fields(service)
	_check_trap_hatchery(service)
	print("BATTLE_FIELD_RUNTIME_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_resource_intents(service) -> void:
	var lease: Dictionary = service.lease_intent({"delta": 0.5, "lease_rate": 20.0, "resource": 4.0, "lease_heat_penalty": 6.0, "warn_timer": 0.1})
	_assert_close(float(lease.get("owed", 0.0)), 10.0, "lease owed")
	_assert_close(float(lease.get("paid", 0.0)), 4.0, "lease paid")
	_assert_close(float(lease.get("resource_after", -1.0)), 0.0, "lease resource")
	_assert_close(float(lease.get("heat_penalty", 0.0)), 3.0, "lease heat")
	if not bool(lease.get("show_warning", false)):
		_fail("lease should show warning when timer elapses.")
	var annuity: Dictionary = service.annuity_intent({"delta": 0.25, "annuity_rate": 8.0, "timer": 0.1})
	_assert_close(float(annuity.get("resource_gain", 0.0)), 2.0, "annuity gain")
	if not bool(annuity.get("spawn_tick_vfx", false)):
		_fail("annuity should spawn tick vfx when timer elapses.")


func _check_support_intents(service) -> void:
	var aura: Dictionary = service.support_aura_model({"kind": "repair", "stats": {"support_radius": 0.7, "support_rate": 12.0}})
	_assert_eq(String(aura.get("aura_kind", "")), "support_repair", "support aura kind")
	_assert_close(float(aura.get("radius", 0.0)), 0.7, "support radius")
	var ammo: Dictionary = service.support_target_intent({
		"kind": "ammo",
		"stats": {"support_ammo_type": "laser", "support_amount": 3, "support_refill_seconds": 1.0},
		"target_role": "hero",
		"target_is_mech": true,
		"progress": 0.75,
		"delta": 0.3,
	})
	if not bool(ammo.get("ready", false)) or int(ammo.get("amount", 0)) != 3 or String(ammo.get("ammo_type", "")) != "laser":
		_fail("support ammo intent should expose ready refill payload: %s" % str(ammo))
	var armor: Dictionary = service.support_target_intent({"kind": "armor", "stats": {"platform_armor_hp": 24.0}, "target_role": "barrier", "target_is_mech": false, "delta": 0.1})
	_assert_close(float(armor.get("armor_hp", 0.0)), 24.0, "armor hp")
	if bool(service.support_target_intent({"kind": "ammo", "target_role": "software", "target_is_mech": false, "check_only": true}).get("can_affect", true)):
		_fail("support ammo should not affect non-combat software role.")


func _check_speed_coin_jam(service) -> void:
	var speed: Dictionary = service.speed_lane_intent({
		"stats": {"speed_lane_mult": 2.0, "speed_lane_pull": 0.4},
		"delta": 0.1,
		"velocity": Vector2(0.5, 0.2),
		"facing": 1.0,
		"unit_speed": 1.0,
	})
	if not (speed.get("velocity", Vector2.ZERO) is Vector2) or float(speed.get("mult", 0.0)) < 2.0:
		_fail("speed lane intent should produce velocity and multiplier: %s" % str(speed))
	var coin_wait: Dictionary = service.coin_generator_intent({"delta": 0.25, "interval": 2.0, "timer": 1.0})
	if bool(coin_wait.get("spawn", true)) or absf(float(coin_wait.get("timer", 0.0)) - 0.75) > 0.001:
		_fail("coin generator should wait before interval: %s" % str(coin_wait))
	var coin_spawn: Dictionary = service.coin_generator_intent({"delta": 1.1, "interval": 2.0, "timer": 0.5})
	if not bool(coin_spawn.get("spawn", false)) or absf(float(coin_spawn.get("timer", 0.0)) - 2.0) > 0.001:
		_fail("coin generator should spawn and reset interval: %s" % str(coin_spawn))
	var collect: Dictionary = service.field_coin_update_intent({"collector_present": true, "collector_owner": 2, "value": 120})
	if String(collect.get("action", "")) != "collect" or int(collect.get("owner", 0)) != 2 or int(collect.get("value", 0)) != 120:
		_fail("field coin collect intent malformed: %s" % str(collect))
	var jam: Dictionary = service.signal_jammer_intent({"delta": 0.4, "progress": 0.7, "required": 1.0, "duration": 1.5})
	if not bool(jam.get("jammed", false)) or float(jam.get("progress", -1.0)) != 0.0:
		_fail("signal jammer should complete and reset progress: %s" % str(jam))


func _check_barrier_fields(service) -> void:
	var utility: Array = service.barrier_utility_intents({"stats": {"is_gravity_field": true, "is_hatchery": true, "is_cage_wall": true}})
	_assert_actions(utility, ["gravity", "hatchery", "cage"], "utility action order")
	var heat: Dictionary = service.field_effect_intent({"kind": "heat", "stats": {"heat_field_rate": 18.0}, "delta": 0.5, "target_cooling": 45.0})
	_assert_close(float(heat.get("heat_delta", 0.0)), 6.12, "heat field delta")
	var siphon: Dictionary = service.field_effect_intent({"kind": "resource_siphon", "stats": {"siphon_rate": 60.0}, "delta": 0.25, "enemy_resource": 8.0})
	_assert_close(float(siphon.get("amount", 0.0)), 8.0, "siphon amount")
	var repulse: Dictionary = service.field_effect_intent({"kind": "repulsion", "stats": {"repulsion_force": 0.5, "repulsion_radius": 1.0}, "delta": 0.2, "direction": Vector2(0.4, 0.2)})
	if (repulse.get("velocity_delta", Vector2.ZERO) as Vector2).length() <= 0.0:
		_fail("repulsion should emit velocity delta: %s" % str(repulse))


func _check_trap_hatchery(service) -> void:
	var trap_gate: Dictionary = service.trap_trigger_intent({"jammed": false, "cooldown": 0.0, "link_matches": true, "targets_count": 2, "command_matched": true})
	if not bool(trap_gate.get("trigger", false)):
		_fail("trap trigger should accept ready trap: %s" % str(trap_gate))
	var trap_fire: Dictionary = service.trap_fire_intents({
		"stats": {"trap_effect": "spring_launch", "trap_power": 0.5, "trap_damage": 9, "trap_damage_type": "blunt", "trap_cooldown": 4.0},
		"targets_count": 1,
		"target_deltas": [Vector2(0.2, 0.0)],
		"launch_direction": Vector2.RIGHT,
	})
	_assert_close(float(trap_fire.get("cooldown", 0.0)), 4.0, "trap cooldown")
	var target_intents: Array = Array(trap_fire.get("target_intents", []))
	if target_intents.size() != 1 or Array(Dictionary(target_intents[0]).get("actions", [])).size() < 3:
		_fail("trap fire should emit per-target actions: %s" % str(trap_fire))
	var hatch_wait: Dictionary = service.hatchery_intent({"limit": 2, "hatchlings": 1, "interval": 3.0, "timer": 1.0, "delta": 0.25})
	if String(hatch_wait.get("action", "")) != "wait":
		_fail("hatchery should wait while timer remains: %s" % str(hatch_wait))
	var hatch_spawn: Dictionary = service.hatchery_intent({"limit": 2, "hatchlings": 1, "interval": 3.0, "timer": 0.1, "delta": 0.25})
	if String(hatch_spawn.get("action", "")) != "spawn" or int(hatch_spawn.get("hatchling_index", 0)) != 2:
		_fail("hatchery should spawn at elapsed timer: %s" % str(hatch_spawn))
	var hatch_stats: Dictionary = service.hatchling_stats_intent({"stats": {"hatch_profile": "rifle", "hatch_ai": "line"}, "primary_color": Color.RED, "accent_color": Color.BLUE})
	if bool(hatch_stats.get("projectile", false)) != true or String(hatch_stats.get("ai", "")) != "line":
		_fail("hatchling stats should keep rifle profile fields: %s" % str(hatch_stats))


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
