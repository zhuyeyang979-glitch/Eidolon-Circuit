extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_action_event_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleActionEventServiceScript := preload("res://scripts/services/battle_action_event_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleActionEventService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleActionEventService",
		"extends RefCounted",
		"begin_module_action_intent",
		"command_window_route_intent",
		"module_event_patch",
		"runtime_direct_module_event_patch",
		"control_event_fields_patch",
		"module_variant_event_patch",
		"module_effect_event_patch",
		"gun_activation_event_patch",
	]:
		if service_source.find(token) < 0:
			_fail("BattleActionEventService missing token: %s" % token)
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
			_fail("BattleActionEventService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleActionEventService = preload(\"res://scripts/services/battle_action_event_service.gd\")",
		"var battle_action_event_service: BattleActionEventService",
		"battle_action_event_service = BattleActionEventService.new()",
		"func _battle_action_event_service() -> BattleActionEventService",
		"_battle_action_event_service().begin_module_action_intent",
		"_battle_action_event_service().gun_activation_event_patch",
		"_battle_action_event_service().module_event_patch",
		"_battle_action_event_service().runtime_direct_module_event_patch",
		"_battle_action_event_service().command_window_route_intent",
		"_battle_action_event_service().control_event_fields_patch",
		"_battle_action_event_service().module_variant_event_patch",
		"_battle_action_event_service().module_effect_event_patch",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle action event token: %s" % token)
			return
	var service = BattleActionEventServiceScript.new()
	_check_begin_and_window(service)
	_check_module_event(service)
	_check_field_patch_helpers(service)
	_check_runtime_direct(service)
	_check_gun_activation(service)
	print("BATTLE_ACTION_EVENT_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_begin_and_window(service) -> void:
	_assert_eq(String(service.begin_module_action_intent({"unit_live": false}).get("action", "")), "none", "dead unit begin")
	var begin: Dictionary = service.begin_module_action_intent({
		"unit_live": true,
		"module_key": "module:2",
		"attack_index": 2,
		"requires_joint_pair": true,
	})
	_assert_eq(String(begin.get("action", "")), "begin", "begin action")
	_assert_eq(String(begin.get("module_key", "")), "module:2", "begin module key")
	if not bool(begin.get("requires_joint_pair", false)):
		_fail("Begin intent should preserve joint-pair requirement: %s" % str(begin))
	_assert_eq(String(service.command_window_route_intent({"has_window": false}).get("action", "")), "none", "missing window")
	var route: Dictionary = service.command_window_route_intent({"has_window": true, "attack_index": 1, "action_state": "active"})
	_assert_eq(String(route.get("action", "")), "fire", "window route action")
	_assert_eq(int(route.get("attack_index", -1)), 1, "window attack index")
	_assert_eq(String(route.get("action_state", "")), "active", "window state")


func _check_module_event(service) -> void:
	var intent: Dictionary = service.module_event_patch({
		"event": {"state": "armor", "damage": 10, "range": 0.4, "lane_range": 0.2, "recoil": 0.1},
		"group": {
			"name": "RIFLE",
			"armor_damage_override": 14,
			"damage_mult": 1.5,
			"range_mult": 2.0,
			"lane_mult": 1.25,
			"recoil_mult": 0.5,
			"projectile": true,
			"projectile_damage_type": "bullet",
			"projectile_style": "missile",
			"projectile_behavior": "explosive",
			"projectile_range": 2.4,
		},
		"stats": {"pierce_range_bonus": 0.3},
		"direction": Vector2.RIGHT,
		"attack_index": 0,
		"attack_group_fallback": ["A"],
		"projectile": true,
		"projectile_behavior": "explosive",
		"laser_visible_range": 3.5,
		"constants": {"bullet_hell_default_speed_mult": 2.8},
	})
	var event: Dictionary = Dictionary(intent.get("event", {}))
	_assert_eq(String(event.get("group_name", "")), "RIFLE", "module group name")
	_assert_eq(int(event.get("damage", 0)), 25, "module missile damage")
	_assert_close(float(event.get("range", 0.0)), 3.2, "module missile range")
	_assert_close(float(event.get("lane_range", 0.0)), 0.43, "module missile lane")
	_assert_eq(String(event.get("material_class", "")), "projectile", "module projectile material")
	_assert_eq(String(event.get("projectile_style", "")), "missile", "module projectile style")
	_assert_eq(String(intent.get("state_key", "")), "armor", "module state key")
	_assert_close(float(intent.get("base_damage", 0.0)), 14.0, "module base damage")


func _check_field_patch_helpers(service) -> void:
	var control: Dictionary = service.control_event_fields_patch({"damage": 5}, {
		"non_damage": true,
		"web_strength": 0.7,
		"missile_lock_range": 3.4,
	})
	if not bool(control.get("non_damage", false)) or int(control.get("damage", -1)) != 0:
		_fail("Control patch should zero non-damage events: %s" % str(control))
	_assert_close(float(control.get("web_strength", 0.0)), 0.7, "control web strength")
	_assert_close(float(control.get("missile_lock_range", 0.0)), 3.4, "control missile range")
	var variant: Dictionary = service.module_variant_event_patch({"knock": 0.2}, {
		"module_variant_key": "vise_close",
		"module_visual_family": "vise",
		"module_variant_label": "Vise",
		"clamp_pin_seconds": 0.4,
		"clamp_velocity_mult": 0.5,
		"clamp_knock_mult": 0.25,
	})
	_assert_eq(String(variant.get("module_variant_key", "")), "vise_close", "variant key")
	_assert_close(float(variant.get("knock", 0.0)), 0.05, "variant clamp knock")
	_assert_close(float(variant.get("clamp_pin_seconds", 0.0)), 0.4, "variant clamp pin")
	var effect: Dictionary = service.module_effect_event_patch({"damage": 10, "range": 0.2, "lane_range": 0.1}, {
		"module_effect": "web_tether",
		"module_range": 1.6,
		"module_lane_range": 0.35,
		"projectile_style": "web",
		"module_damage_mult": 2.0,
	})
	if not bool(effect.get("projectile", false)) or not bool(effect.get("non_damage", false)) or int(effect.get("damage", -1)) != 0:
		_fail("Web tether module effect should become non-damage projectile: %s" % str(effect))
	_assert_close(float(effect.get("range", 0.0)), 1.6, "effect range")
	_assert_eq(String(effect.get("projectile_style", "")), "web", "effect projectile style")
	var chaos: Dictionary = service.module_effect_event_patch({"damage": 10, "range": 0.3, "lane_range": 0.1}, {"module_effect": "chaos_shot"})
	_assert_eq(String(chaos.get("travel_path", "")), "instant_line", "chaos travel")
	_assert_eq(int(chaos.get("damage", 0)), 8, "chaos damage")


func _check_runtime_direct(service) -> void:
	var intent: Dictionary = service.runtime_direct_module_event_patch({
		"event": {"state": "active", "damage": 8},
		"module_part": {"name": "HAMMER", "damage_type": "blunt", "material_class": "weapon", "fixed_output_momentum": 22.0},
		"direction": Vector2.LEFT,
		"action_state": "active",
		"weapon_damage_coeff": 3.2,
	})
	var event: Dictionary = Dictionary(intent.get("event", {}))
	_assert_eq(String(event.get("group_name", "")), "HAMMER", "runtime group name")
	_assert_eq(String(event.get("damage_type", "")), "blunt", "runtime damage type")
	_assert_close(float(event.get("weapon_damage_coeff", 0.0)), 3.2, "runtime weapon coeff")
	_assert_close(float(event.get("fixed_output_momentum", 0.0)), 22.0, "runtime momentum")
	if not bool(event.get("runtime_direct_module", false)):
		_fail("Runtime direct event should be marked: %s" % str(event))
	_assert_eq(String(intent.get("state_label", "")), "ACTIVE", "runtime state label")


func _check_gun_activation(service) -> void:
	var base := {
		"projectile": true,
		"range": 1.0,
		"lane_range": 0.1,
		"module_variant_key": "explosive_arc_salvo",
		"salvo_arc_min_range": 1.0,
		"salvo_arc_max_range": 4.0,
		"salvo_hold_range_seconds": 1.0,
	}
	var grenade: Dictionary = service.gun_activation_event_patch({
		"event": base,
		"group": {"gun_kind": "grenade_launcher", "ammo_kind": "explosive", "projectile_width_m": 0.2, "normal_damage": 10},
		"spec": {"semantic": "hold_grenade_arc", "projectile_damage_type": "explosion", "projectile_style": "explosive", "projectile_behavior": "explosive", "travel_path": "arc_u", "default_range": 2.65, "default_width": 0.18},
		"state": {"hold_time": 0.5},
		"gun_kind": "grenade_launcher",
		"ammo_kind": "explosive",
		"gun_projectile_damage_mult": 4.0,
		"gun_projectile_damage_mult_current": 2.0,
		"constants": {"true_bullet_default_lock_seconds": 1.0},
	})
	var grenade_event: Dictionary = Dictionary(grenade.get("event", {}))
	_assert_eq(String(grenade_event.get("travel_path", "")), "arc_u", "grenade travel")
	_assert_close(float(grenade_event.get("range", 0.0)), 2.5, "grenade hold range")
	_assert_close(float(grenade_event.get("salvo_hold_ratio", 0.0)), 0.5, "grenade hold ratio")
	if not bool(grenade_event.get("salvo_landing_marker", false)):
		_fail("Grenade salvo should request landing marker: %s" % str(grenade_event))
	var web: Dictionary = service.gun_activation_event_patch({
		"event": {"projectile": true},
		"group": {"gun_kind": "web_gun", "ammo_kind": "web", "projectile_width_m": 0.08},
		"spec": {"semantic": "release_web", "projectile_damage_type": "blunt", "projectile_style": "web", "projectile_behavior": "web_tether", "travel_path": "tether", "default_range": 4.4, "default_width": 0.08},
		"gun_kind": "web_gun",
		"ammo_kind": "web",
		"constants": {"standard_web_tether_range_m": 4.4, "standard_web_tether_strength": 0.34, "standard_web_tether_break_force": 1.08, "standard_web_tether_duration": 1.6},
	})
	var web_event: Dictionary = Dictionary(web.get("event", {}))
	if not bool(web_event.get("non_damage", false)) or String(web_event.get("projectile_style", "")) != "web":
		_fail("Web activation should become non-damage web event: %s" % str(web_event))
	_assert_close(float(web_event.get("range", 0.0)), 4.4, "web range")
	var missile: Dictionary = service.gun_activation_event_patch({
		"event": {"projectile": true},
		"group": {"gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_width_m": 0.22},
		"module_part": {"missile_occlusion_grace": 0.4},
		"spec": {"semantic": "release_missile_lock", "projectile_damage_type": "bullet", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "default_range": 3.4, "default_width": 0.22},
		"gun_kind": "missile_launcher",
		"ammo_kind": "explosive",
		"constants": {"standard_missile_range_m": 3.4, "standard_missile_speed_mult": 1.05, "standard_missile_projectile_momentum": 92.0, "standard_missile_explosion_radius": 0.64},
	})
	var missile_event: Dictionary = Dictionary(missile.get("event", {}))
	_assert_eq(String(missile_event.get("projectile_style", "")), "missile", "missile style")
	_assert_close(float(missile_event.get("missile_occlusion_grace", 0.0)), 0.4, "missile grace")
	_assert_eq(String(missile_event.get("missile_lock_priority", "")), "screen_hero_first", "missile priority")


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String, epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])
