extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_action_event_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleActionEventServiceScript := preload("res://scripts/services/battle_action_event_service.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)
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
		"runtime_attack_button_intent",
		"explicit_gun_activation_event",
		"attack_button_command_state_intent",
		"func attack_button_aim_mode(",
		"func hold_activation_initial_delay(",
		"func hold_activation_fire_interval(",
		"func hold_activation_fire_intent(",
		"func held_aim_release_intent(",
		"func command_token_vector(",
		"func latest_command_direction(",
		"func command_text(",
		"command_buffer_record_intent",
		"command_match_intent",
		"func command_skill_action_kind(",
		"func normal_attack_action_kind(",
		"func attack_direction(",
		"func attack_direction_for_group(",
		"func paired_attack_direction(",
		"func runtime_module_direction(",
		"func recoil_countered(",
		"func facing_relative_attack_state(",
		"func two_link_forward_snap_attack_state(",
		"func attack_state_for_group(",
		"func melee_command_attack_intent(",
		"func consume_melee_state_intent(",
		"command_window_route_intent",
		"command_window_resolve_all_intent",
		"command_window_tick_intent",
		"command_window_text_state",
		"command_window_blade_variant",
		"command_window_gauntlet_variant",
		"command_window_blunt_variant",
		"command_window_binding_profile",
		"command_window_should_clear_buffer",
		"command_window_runtime_state",
		"command_window_runtime_variant",
		"command_window_state_for_input",
		"command_window_state_for_binding",
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
		"_battle_action_event_service().runtime_attack_button_intent",
		"_battle_action_event_service().explicit_gun_activation_event",
		"_battle_action_event_service().attack_button_command_state_intent",
		"_battle_action_event_service().attack_button_aim_mode(",
		"_battle_action_event_service().hold_activation_initial_delay(",
		"_battle_action_event_service().hold_activation_fire_interval(",
		"_battle_action_event_service().hold_activation_fire_intent(",
		"_battle_action_event_service().held_aim_release_intent(",
		"_battle_action_event_service().latest_command_direction(",
		"_battle_action_event_service().command_text(",
		"_battle_action_event_service().command_buffer_record_intent",
		"_battle_action_event_service().command_match_intent",
		"_battle_action_event_service().command_skill_action_kind(",
		"_battle_action_event_service().normal_attack_action_kind(",
		"_battle_action_event_service().attack_direction(",
		"_battle_action_event_service().attack_direction_for_group(",
		"_battle_action_event_service().paired_attack_direction(",
		"_battle_action_event_service().runtime_module_direction(",
		"_battle_action_event_service().recoil_countered(",
		"_battle_action_event_service().attack_state_for_group(",
		"_battle_action_event_service().melee_command_attack_intent(",
		"_battle_action_event_service().consume_melee_state_intent(",
		"_battle_action_event_service().gun_activation_event_patch",
		"_battle_action_event_service().module_event_patch",
		"_battle_action_event_service().runtime_direct_module_event_patch",
		"_battle_action_event_service().command_window_route_intent",
		"_battle_action_event_service().command_window_resolve_all_intent",
		"_battle_action_event_service().command_window_tick_intent",
		"_battle_action_event_service().command_window_binding_profile",
		"_battle_action_event_service().command_window_should_clear_buffer",
		"_battle_action_event_service().command_window_runtime_state",
		"_battle_action_event_service().command_window_runtime_variant",
		"_battle_action_event_service().command_window_state_for_input",
		"_battle_action_event_service().command_window_state_for_binding",
		"_battle_action_event_service().control_event_fields_patch",
		"_battle_action_event_service().module_variant_event_patch",
		"_battle_action_event_service().module_effect_event_patch",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle action event token: %s" % token)
			return
	for stale_helper in [
		"func _absolute_command_vector(",
		"func _facing_relative_attack_state(",
		"func _two_link_forward_snap_attack_state(",
		"func _text_matches_any(",
	]:
		if main_source.find(stale_helper) >= 0:
			_fail("main.gd should not keep stale battle action helper: %s" % stale_helper)
			return
	var service = BattleActionEventServiceScript.new()
	_check_begin_and_window(service)
	_check_runtime_attack_button(service)
	_check_explicit_gun_activation_event(service)
	_check_attack_button_command_state(service)
	_check_attack_button_aim_mode(service)
	_check_hold_activation_initial_delay(service)
	_check_hold_activation_fire_interval(service)
	_check_hold_activation_fire(service)
	_check_held_aim_release(service)
	_check_command_direction(service)
	_check_command_text(service)
	_check_command_buffer_record(service)
	_check_command_match(service)
	_check_command_skill_action_kind(service)
	_check_normal_attack_action_kind(service)
	_check_attack_direction(service)
	_check_recoil_counter(service)
	_check_attack_state(service)
	_check_melee_command_intent(service)
	_check_command_window_resolve_all(service)
	_check_command_window_tick(service)
	_check_command_window_text(service)
	_check_command_window_blade_variant(service)
	_check_command_window_gauntlet_variant(service)
	_check_command_window_blunt_variant(service)
	_check_command_window_binding_profile(service)
	_check_command_window_buffer_clear(service)
	_check_command_window_runtime_state(service)
	_check_command_window_runtime_variant(service)
	_check_command_window_state(service)
	_check_module_event(service)
	_check_field_patch_helpers(service)
	_check_runtime_direct(service)
	_check_gun_activation(service)
	if not failures.is_empty():
		print("BATTLE_ACTION_EVENT_SERVICE_CONTRACT_PROBE failed count=%d" % failures.size())
		quit(1)
		return
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


func _check_runtime_attack_button(service) -> void:
	_assert_eq(String(service.runtime_attack_button_intent({"direct_runtime_topology": false}).get("action", "")), "legacy_attack", "non-direct runtime falls through to legacy attack")
	_assert_eq(String(service.runtime_attack_button_intent({"direct_runtime_topology": true, "gun_activation": true, "held_melee_activation": true, "has_attack_window": true, "binding_empty": false}).get("action", "")), "start_gun_activation", "gun activation has first direct-runtime priority")
	_assert_eq(String(service.runtime_attack_button_intent({"direct_runtime_topology": true, "held_melee_activation": true, "has_attack_window": true, "binding_empty": false}).get("action", "")), "start_held_melee_activation", "held melee activation precedes window resolution")
	var resolve: Dictionary = service.runtime_attack_button_intent({"direct_runtime_topology": true, "has_attack_window": true, "binding_empty": false, "attack_index": 2})
	_assert_eq(String(resolve.get("action", "")), "resolve_command_window", "direct runtime resolves matching open window")
	_assert_eq(int(resolve.get("attack_index", -1)), 2, "direct runtime route preserves attack index")
	_assert_eq(String(service.runtime_attack_button_intent({"direct_runtime_topology": true, "binding_empty": true}).get("action", "")), "fail_unbound", "direct runtime empty binding reports fail route")
	_assert_eq(String(service.runtime_attack_button_intent({"direct_runtime_topology": true, "binding_empty": false}).get("action", "")), "open_command_window", "direct runtime valid binding opens command window")


func _check_explicit_gun_activation_event(service) -> void:
	_assert_eq(bool(service.explicit_gun_activation_event({"module_action_profile": "gun_activate"}, true)), true, "known gun profile should be explicit")
	_assert_eq(bool(service.explicit_gun_activation_event({"module_action_profile": "gun_activate", "gun_activation": false}, true)), true, "known profile remains explicit without gun flag")
	_assert_eq(bool(service.explicit_gun_activation_event({"module_action_profile": "unknown", "gun_activation": true}, false)), false, "unknown profile should not be explicit even with gun flag")
	_assert_eq(bool(service.explicit_gun_activation_event({"gun_activation": true}, false)), false, "missing profile should not be explicit")


func _check_attack_button_command_state(service) -> void:
	var passive: Dictionary = service.attack_button_command_state_intent("normal", "")
	_assert_eq(String(passive.get("action", "")), "none", "normal attack button state has no command-state consume route")
	_assert_eq(bool(passive.get("clear_buffer", true)), false, "normal attack button state does not clear buffer")
	_assert_eq(bool(passive.get("consume_melee_state", true)), false, "normal attack button state does not consume melee state")
	var rejected: Dictionary = service.attack_button_command_state_intent("dash", "two_link_forward_snap")
	_assert_eq(String(rejected.get("action", "")), "none", "unsupported attack button state has no command-state consume route")
	var two_link: Dictionary = service.attack_button_command_state_intent("active", "two_link_forward_snap")
	_assert_eq(String(two_link.get("action", "")), "clear_buffer", "two-link active state clears command buffer directly")
	_assert_eq(bool(two_link.get("clear_buffer", false)), true, "two-link active state clear flag")
	_assert_eq(bool(two_link.get("consume_melee_state", true)), false, "two-link active state skips melee consume helper")
	_assert_eq(String(two_link.get("requested_state", "")), "active", "two-link intent preserves requested state")
	var armor_two_link: Dictionary = service.attack_button_command_state_intent("armor", "two_link_forward_snap")
	_assert_eq(String(armor_two_link.get("action", "")), "clear_buffer", "two-link armor state clears command buffer directly")
	var melee: Dictionary = service.attack_button_command_state_intent("armor", "blade_arc_return")
	_assert_eq(String(melee.get("action", "")), "consume_melee_state", "non-two-link armor state routes through melee consume helper")
	_assert_eq(bool(melee.get("clear_buffer", true)), false, "non-two-link armor state leaves clearing to consume helper")
	_assert_eq(bool(melee.get("consume_melee_state", false)), true, "non-two-link armor state consumes melee state")
	_assert_eq(String(melee.get("requested_state", "")), "armor", "melee consume intent preserves requested state")


func _check_attack_button_aim_mode(service) -> void:
	_assert_eq(String(service.attack_button_aim_mode("fixed", false)), "fixed", "fixed aim mode remains fixed")
	_assert_eq(String(service.attack_button_aim_mode("manual", false)), "manual", "manual aim mode remains manual")
	_assert_eq(String(service.attack_button_aim_mode("auto", false)), "auto", "auto aim mode remains auto")
	_assert_eq(String(service.attack_button_aim_mode("", false)), "fixed", "empty aim mode defaults fixed")
	_assert_eq(String(service.attack_button_aim_mode("auto", true)), "manual", "true bullet aim forces manual")
	_assert_eq(String(service.attack_button_aim_mode("fixed", true)), "manual", "true bullet overrides fixed aim")


func _check_hold_activation_initial_delay(service) -> void:
	_assert_close(float(service.hold_activation_initial_delay(false, true, true, true)), 0.0, "non-hold activation has no initial delay")
	_assert_close(float(service.hold_activation_initial_delay(true, false, true, true)), 0.0, "non-projectile activation has no initial delay")
	_assert_close(float(service.hold_activation_initial_delay(true, true, true, false)), 9999.0, "release-to-fire projectile waits for release")
	_assert_close(float(service.hold_activation_initial_delay(true, true, false, true)), 9999.0, "true-bullet projectile waits for lock/release")
	_assert_close(float(service.hold_activation_initial_delay(true, true, false, false)), 0.0, "ordinary hold projectile may fire immediately")


func _check_hold_activation_fire_interval(service) -> void:
	_assert_close(float(service.hold_activation_fire_interval({
		"fire_rate": 4.0,
		"fire_interval": 0.5,
		"damage_type": "laser",
		"laser_aim_time": 0.8,
		"projectile_behavior": "bullet_hell",
		"laser_default_aim_seconds": 0.46,
		"laser_min_aim_seconds": 0.18,
		"laser_max_aim_seconds": 1.1,
	})), 0.25, "hold activation fire rate takes precedence")
	_assert_close(float(service.hold_activation_fire_interval({"fire_rate": 0.01})), 20.0, "hold activation low fire rate keeps existing denominator clamp")
	_assert_close(float(service.hold_activation_fire_interval({"fire_interval": 0.02})), 0.04, "hold activation fire interval clamps to minimum")
	_assert_close(float(service.hold_activation_fire_interval({"fire_interval": 0.35})), 0.35, "hold activation fire interval preserves larger value")
	_assert_close(float(service.hold_activation_fire_interval({
		"damage_type": "laser",
		"laser_aim_time": 0.05,
		"laser_default_aim_seconds": 0.46,
		"laser_min_aim_seconds": 0.18,
		"laser_max_aim_seconds": 1.1,
	})), 0.5, "hold activation laser interval clamps low aim time")
	_assert_close(float(service.hold_activation_fire_interval({
		"damage_type": "laser",
		"laser_aim_time": 2.0,
		"laser_default_aim_seconds": 0.46,
		"laser_min_aim_seconds": 0.18,
		"laser_max_aim_seconds": 1.1,
	})), 1.42, "hold activation laser interval clamps high aim time")
	_assert_close(float(service.hold_activation_fire_interval({
		"damage_type": "chemical",
		"projectile_behavior": "bullet_hell",
	})), 0.2, "hold activation chemical interval precedes projectile behavior")
	_assert_close(float(service.hold_activation_fire_interval({"projectile_behavior": "bullet_hell"})), 0.16, "hold activation bullet hell interval")
	_assert_close(float(service.hold_activation_fire_interval({})), 0.24, "hold activation fallback interval")


func _check_hold_activation_fire(service) -> void:
	var true_bullet: Dictionary = service.hold_activation_fire_intent(true, true, true, 0.25, 0.3, 0.8)
	_assert_eq(String(true_bullet.get("action", "")), "none", "true-bullet held aim does not auto-fire during hold")
	_assert_close(float(true_bullet.get("timer", -1.0)), 0.25, "true-bullet auto-fire preserves timer")
	_assert_eq(bool(true_bullet.get("fire", true)), false, "true-bullet auto-fire fire flag false")
	var not_hold: Dictionary = service.hold_activation_fire_intent(false, false, true, 0.25, 0.3, 0.8)
	_assert_eq(String(not_hold.get("action", "")), "none", "non-hold activation does not auto-fire during hold")
	var not_projectile: Dictionary = service.hold_activation_fire_intent(false, true, false, 0.25, 0.3, 0.8)
	_assert_eq(String(not_projectile.get("action", "")), "none", "non-projectile hold activation does not auto-fire")
	var wait: Dictionary = service.hold_activation_fire_intent(false, true, true, 0.5, 0.125, 0.8)
	_assert_eq(String(wait.get("action", "")), "wait", "hold activation waits while timer remains positive")
	_assert_close(float(wait.get("timer", -1.0)), 0.375, "hold activation wait timer decays")
	_assert_eq(bool(wait.get("fire", true)), false, "hold activation wait fire flag false")
	var fire: Dictionary = service.hold_activation_fire_intent(false, true, true, 0.1, 0.125, 0.8)
	_assert_eq(String(fire.get("action", "")), "fire", "hold activation fires when timer expires")
	_assert_close(float(fire.get("timer", -1.0)), 0.8, "hold activation fire timer resets to interval")
	_assert_eq(bool(fire.get("fire", false)), true, "hold activation fire flag true")


func _check_held_aim_release(service) -> void:
	var release_to_fire: Dictionary = service.held_aim_release_intent(true, true, false)
	_assert_eq(String(release_to_fire.get("action", "")), "fire", "release_to_fire group fires on held aim release")
	_assert_eq(bool(release_to_fire.get("fire", false)), true, "release_to_fire fire flag")
	var tap_fire: Dictionary = service.held_aim_release_intent(false, false, false)
	_assert_eq(String(tap_fire.get("action", "")), "fire", "non-hold activation fires on held aim release")
	_assert_eq(bool(tap_fire.get("fire", false)), true, "non-hold activation fire flag")
	var true_bullet: Dictionary = service.held_aim_release_intent(false, true, true)
	_assert_eq(String(true_bullet.get("action", "")), "fire", "true-bullet held aim fires on release")
	_assert_eq(bool(true_bullet.get("fire", false)), true, "true-bullet release fire flag")
	var hold_only: Dictionary = service.held_aim_release_intent(false, true, false)
	_assert_eq(String(hold_only.get("action", "")), "clear", "hold-only non-release projectile clears without release fire")
	_assert_eq(bool(hold_only.get("fire", true)), false, "hold-only release fire flag false")


func _check_command_direction(service) -> void:
	_assert_vec_close(service.command_token_vector("1"), Vector2(-1.0, 1.0), "command token 1 vector")
	_assert_vec_close(service.command_token_vector("2"), Vector2.DOWN, "command token 2 vector")
	_assert_vec_close(service.command_token_vector("3"), Vector2(1.0, 1.0), "command token 3 vector")
	_assert_vec_close(service.command_token_vector("4"), Vector2.LEFT, "command token 4 vector")
	_assert_vec_close(service.command_token_vector("6"), Vector2.RIGHT, "command token 6 vector")
	_assert_vec_close(service.command_token_vector("7"), Vector2(-1.0, -1.0), "command token 7 vector")
	_assert_vec_close(service.command_token_vector("8"), Vector2.UP, "command token 8 vector")
	_assert_vec_close(service.command_token_vector("9"), Vector2(1.0, -1.0), "command token 9 vector")
	_assert_vec_close(service.command_token_vector("5"), Vector2.ZERO, "command token 5 vector")
	_assert_vec_close(service.latest_command_direction(["2", "5", "6"]), Vector2.RIGHT, "latest command direction skips older tokens")
	_assert_vec_close(service.latest_command_direction(["2", "bad", "5"]), Vector2.DOWN, "latest command direction skips zero tokens")
	_assert_vec_close(service.latest_command_direction(["1"]), Vector2(-1.0, 1.0).normalized(), "latest command direction normalizes diagonal")
	_assert_vec_close(service.latest_command_direction([]), Vector2.ZERO, "empty latest command direction")


func _check_command_text(service) -> void:
	_assert_eq(String(service.command_text(["2", "6", "4", "8"])), "2648", "command text joins tokens")
	_assert_eq(String(service.command_text([2, "6", "x"])), "26x", "command text stringifies tokens")
	_assert_eq(String(service.command_text([])), "", "empty command text")


func _check_command_buffer_record(service) -> void:
	var idle: Dictionary = service.command_buffer_record_intent(["2", "6"], 0.3, 0.1, {})
	_assert_eq(Array(idle.get("buffer", [])).size(), 2, "idle command buffer preserves token count")
	_assert_eq("".join(Array(idle.get("buffer", []))), "26", "idle command buffer preserves tokens")
	_assert_close(float(idle.get("timer", 0.0)), 0.2, "idle command timer decays")
	var expired: Dictionary = service.command_buffer_record_intent(["2", "6"], 0.05, 0.1, {})
	_assert_eq(Array(expired.get("buffer", [])).size(), 0, "expired command buffer clears")
	_assert_close(float(expired.get("timer", 0.0)), 0.0, "expired command timer clamps")
	var added: Dictionary = service.command_buffer_record_intent(["2"], 0.3, 0.1, {"down": true, "right": true, "left": true, "up": true})
	_assert_eq("".join(Array(added.get("buffer", []))), "22648", "command input appends in canonical direction order")
	_assert_close(float(added.get("timer", 0.0)), 0.42, "command input resets timer")
	var reset_then_add: Dictionary = service.command_buffer_record_intent(["4", "4"], 0.01, 0.2, {"right": true})
	_assert_eq("".join(Array(reset_then_add.get("buffer", []))), "6", "expired command buffer clears before same-frame add")
	var capped: Dictionary = service.command_buffer_record_intent(["1", "2", "3", "4", "5", "6", "7"], 0.3, 0.1, {"down": true, "right": true, "left": true, "up": true})
	_assert_eq("".join(Array(capped.get("buffer", []))), "45672648", "command buffer keeps latest eight tokens")


func _check_command_match(service) -> void:
	var relaxed_236: Dictionary = service.command_match_intent("26", "236")
	_assert_eq(bool(relaxed_236.get("matched", false)), true, "236 command accepts relaxed 26")
	_assert_eq(bool(relaxed_236.get("clear_buffer", false)), true, "matched 236 command clears buffer")
	var relaxed_214: Dictionary = service.command_match_intent("124", "214")
	_assert_eq(bool(relaxed_214.get("matched", false)), true, "214 command accepts relaxed 24 suffix")
	var relaxed_full: Dictionary = service.command_match_intent("86246", "632146")
	_assert_eq(bool(relaxed_full.get("matched", false)), true, "632146 command accepts relaxed 6246 suffix")
	var exact: Dictionary = service.command_match_intent("2288", "88")
	_assert_eq(bool(exact.get("matched", false)), true, "generic command accepts exact suffix")
	var miss: Dictionary = service.command_match_intent("236", "214")
	_assert_eq(bool(miss.get("matched", true)), false, "wrong command should miss")
	_assert_eq(bool(miss.get("clear_buffer", true)), false, "missed command should not clear buffer")


func _check_command_skill_action_kind(service) -> void:
	_assert_eq(String(service.command_skill_action_kind("active", {})), "active", "requested active command skill state")
	_assert_eq(String(service.command_skill_action_kind("armor", {"skill_state": "active"})), "armor", "requested armor command skill state")
	_assert_eq(String(service.command_skill_action_kind("normal", {"skill_state": "armor"})), "armor", "non-special request falls back to skill_state")
	_assert_eq(String(service.command_skill_action_kind("normal", {})), "active", "missing skill_state defaults active")
	_assert_eq(String(service.command_skill_action_kind("active", {"module_state": "armor"})), "armor", "module_state armor overrides request")
	_assert_eq(String(service.command_skill_action_kind("armor", {"module_state": "active"})), "active", "module_state active overrides request")
	_assert_eq(String(service.command_skill_action_kind("active", {"module_state": "normal"})), "active", "module_state normal does not override")


func _check_normal_attack_action_kind(service) -> void:
	_assert_eq(String(service.normal_attack_action_kind("active")), "active", "normal attack preserves active request")
	_assert_eq(String(service.normal_attack_action_kind("armor")), "armor", "normal attack preserves armor request")
	_assert_eq(String(service.normal_attack_action_kind("normal")), "normal", "normal attack keeps normal fallback")
	_assert_eq(String(service.normal_attack_action_kind("dash")), "normal", "normal attack rejects unsupported requested state")
	_assert_eq(String(service.normal_attack_action_kind("")), "normal", "normal attack empty request falls back to normal")


func _check_attack_direction(service) -> void:
	_assert_vec_close(service.attack_direction(Vector2(0.3, 0.4), Vector2.LEFT), Vector2(0.6, 0.8), "attack direction normalizes strong input")
	_assert_vec_close(service.attack_direction(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT, "attack direction falls back to forward")
	_assert_vec_close(service.attack_direction(Vector2.ZERO, Vector2.ZERO), Vector2.RIGHT, "attack direction has stable missing-forward fallback")
	var biased: Vector2 = service.attack_direction_for_group(Vector2.ZERO, Vector2.RIGHT, {"lane_bias": 1.0})
	_assert_vec_close(biased, Vector2(1.0, 1.0).normalized(), "group attack direction applies lane bias")
	_assert_vec_close(service.attack_direction_for_group(Vector2.UP, Vector2.RIGHT, {"lane_bias": 1.0}), Vector2.UP, "group attack direction prioritizes strong input")
	_assert_vec_close(service.paired_attack_direction(Vector2.ZERO, Vector2.RIGHT, {"lane_bias": 1.0}, 0, 2), biased, "non-clamp paired direction uses group rule")
	var clamp_a: Vector2 = service.paired_attack_direction(Vector2.ZERO, Vector2.RIGHT, {"paired_motion": "inward_clamp", "lane_bias": 0.0}, 0, 2)
	var clamp_b: Vector2 = service.paired_attack_direction(Vector2.ZERO, Vector2.RIGHT, {"paired_motion": "inward_clamp", "lane_bias": 0.0}, 1, 2)
	if clamp_a.length() < 0.99 or clamp_b.length() < 0.99:
		_fail("Paired clamp directions should stay normalized: %s / %s" % [str(clamp_a), str(clamp_b)])
	if clamp_a.y <= 0.0 or clamp_b.y >= 0.0:
		_fail("Paired clamp directions should mirror when lane bias is missing: %s / %s" % [str(clamp_a), str(clamp_b)])
	_assert_vec_close(service.runtime_module_direction(Vector2(0.18, 0.0), Vector2.LEFT), Vector2.RIGHT, "runtime module direction uses threshold input")
	_assert_vec_close(service.runtime_module_direction(Vector2(0.17, 0.0), Vector2.LEFT), Vector2.LEFT, "runtime module direction falls back below threshold")
	_assert_vec_close(service.runtime_module_direction(Vector2.ZERO, Vector2.ZERO), Vector2.RIGHT, "runtime module direction has stable missing-forward fallback")


func _check_recoil_counter(service) -> void:
	_assert_eq(bool(service.recoil_countered(0.0, Vector2.LEFT, Vector2.RIGHT)), false, "missing boost cannot counter recoil")
	_assert_eq(bool(service.recoil_countered(1.0, Vector2(0.1, 0.0), Vector2.RIGHT)), false, "weak held vector cannot counter recoil")
	_assert_eq(bool(service.recoil_countered(1.0, Vector2.LEFT, Vector2.RIGHT)), true, "held opposite attack counters recoil")
	_assert_eq(bool(service.recoil_countered(1.0, Vector2.RIGHT, Vector2.RIGHT)), false, "held with attack does not counter recoil")
	_assert_eq(bool(service.recoil_countered(1.0, Vector2.LEFT, Vector2.ZERO)), false, "missing attack direction cannot counter recoil")
	_assert_eq(bool(service.recoil_countered(1.0, Vector2(-0.5, 1.0), Vector2.RIGHT)), false, "counter threshold is strict")


func _check_attack_state(service) -> void:
	_assert_eq(String(service.facing_relative_attack_state(Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT)), "armor", "facing-relative forward input")
	_assert_eq(String(service.facing_relative_attack_state(Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT)), "active", "facing-relative rear input")
	_assert_eq(String(service.facing_relative_attack_state(Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT)), "normal", "facing-relative side input")
	_assert_eq(String(service.facing_relative_attack_state(Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT)), "active", "facing-relative latest direction fallback")
	_assert_eq(String(service.facing_relative_attack_state(Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "normal", "facing-relative missing direction")
	_assert_eq(String(service.facing_relative_attack_state(Vector2.RIGHT, Vector2.ZERO, Vector2.ZERO)), "normal", "facing-relative missing forward")
	_assert_eq(String(service.two_link_forward_snap_attack_state(Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT)), "armor", "two-link forward input")
	_assert_eq(String(service.two_link_forward_snap_attack_state(Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT)), "active", "two-link rear input")
	_assert_eq(String(service.two_link_forward_snap_attack_state(Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT)), "normal", "two-link side input")
	_assert_eq(String(service.two_link_forward_snap_attack_state(Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT)), "active", "two-link latest direction fallback")
	_assert_eq(String(service.attack_state_for_group("two_link_forward_snap", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT, "normal")), "armor", "two-link group overrides fallback")
	_assert_eq(String(service.attack_state_for_group("two_link_forward_snap", Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT, "active")), "normal", "two-link group preserves neutral normal")
	_assert_eq(String(service.attack_state_for_group("blade_arc_return", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT, "active")), "active", "non-two-link group preserves fallback")


func _check_melee_command_intent(service) -> void:
	var consumed_armor: Dictionary = service.melee_command_attack_intent(Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT, true)
	_assert_eq(String(consumed_armor.get("attack_state", "")), "armor", "melee command forward state")
	_assert_eq(bool(consumed_armor.get("clear_buffer", false)), true, "consumed armor melee command clears buffer")
	var preview_active: Dictionary = service.melee_command_attack_intent(Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, false)
	_assert_eq(String(preview_active.get("attack_state", "")), "active", "melee command rear state")
	_assert_eq(bool(preview_active.get("clear_buffer", true)), false, "preview melee command does not clear buffer")
	var side_normal: Dictionary = service.melee_command_attack_intent(Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT, true)
	_assert_eq(String(side_normal.get("attack_state", "")), "normal", "melee command side state")
	_assert_eq(bool(side_normal.get("clear_buffer", true)), false, "normal melee command does not clear buffer")
	var latest_active: Dictionary = service.melee_command_attack_intent(Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, true)
	_assert_eq(String(latest_active.get("attack_state", "")), "active", "melee command latest direction fallback")
	_assert_eq(bool(latest_active.get("clear_buffer", false)), true, "latest active melee command clears buffer when consumed")
	var matched: Dictionary = service.consume_melee_state_intent(Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, "active")
	_assert_eq(String(matched.get("attack_state", "")), "active", "consume melee state reports state")
	_assert_eq(bool(matched.get("matched", false)), true, "consume melee state matches requested state")
	_assert_eq(bool(matched.get("clear_buffer", false)), true, "matched consume melee state clears buffer")
	var missed: Dictionary = service.consume_melee_state_intent(Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT, "active")
	_assert_eq(String(missed.get("attack_state", "")), "normal", "missed consume melee state reports actual state")
	_assert_eq(bool(missed.get("matched", true)), false, "consume melee state misses wrong requested state")
	_assert_eq(bool(missed.get("clear_buffer", true)), false, "missed consume melee state does not clear buffer")


func _check_command_window_resolve_all(service) -> void:
	var none: Dictionary = service.command_window_resolve_all_intent([])
	_assert_eq(String(none.get("action", "")), "none", "empty resolve-all action")
	_assert_eq(Array(none.get("entries", [])).size(), 0, "empty resolve-all entries")
	var intent: Dictionary = service.command_window_resolve_all_intent([
		{"window_key": "2", "attack_index": 2, "state": "active"},
		{"window_key": "0", "attack_index": 0, "state": ""},
		{"window_key": "1", "attack_index": 1, "state": "armor"},
	])
	_assert_eq(String(intent.get("action", "")), "fire_all", "resolve-all action")
	var entries: Array = Array(intent.get("entries", []))
	_assert_eq(entries.size(), 2, "resolve-all filters empty states")
	_assert_eq(int(Dictionary(entries[0]).get("attack_index", -1)), 1, "resolve-all sorts first attack")
	_assert_eq(String(Dictionary(entries[0]).get("state", "")), "armor", "resolve-all first state")
	_assert_eq(int(Dictionary(entries[1]).get("attack_index", -1)), 2, "resolve-all sorts second attack")
	var close_keys: Array = Array(intent.get("close_window_keys", []))
	_assert_eq(close_keys.size(), 2, "resolve-all close key count")
	_assert_eq(String(close_keys[0]), "1", "resolve-all first close key")
	_assert_eq(String(close_keys[1]), "2", "resolve-all second close key")


func _check_command_window_tick(service) -> void:
	var idle: Dictionary = service.command_window_tick_intent({"timer": 1.2, "hold_time": 0.3, "attack_index": 1}, false, 0.2, 1.2, 0.5)
	var idle_window: Dictionary = Dictionary(idle.get("window", {}))
	_assert_eq(String(idle.get("action", "")), "keep", "idle tick action")
	_assert_close(float(idle_window.get("timer", 0.0)), 1.0, "idle tick timer")
	_assert_close(float(idle_window.get("hold_time", -1.0)), 0.0, "idle tick hold reset")
	_assert_eq(int(idle_window.get("attack_index", -1)), 1, "idle tick preserves fields")
	var held: Dictionary = service.command_window_tick_intent({"timer": 1.2, "hold_time": 0.2}, true, 0.2, 1.2, 0.5)
	var held_window: Dictionary = Dictionary(held.get("window", {}))
	_assert_eq(String(held.get("action", "")), "keep", "held tick action")
	_assert_close(float(held_window.get("hold_time", 0.0)), 0.4, "held tick hold time")
	var cancel: Dictionary = service.command_window_tick_intent({"timer": 1.2, "hold_time": 0.4}, true, 0.1, 1.2, 0.5)
	_assert_eq(String(cancel.get("action", "")), "cancel", "hold cancel tick action")
	var expire: Dictionary = service.command_window_tick_intent({"timer": 0.08, "hold_time": 0.0}, false, 0.1, 1.2, 0.5)
	_assert_eq(String(expire.get("action", "")), "expire", "expired tick action")
	var fallback: Dictionary = service.command_window_tick_intent({"hold_time": 0.0}, false, 0.2, 1.2, 0.5)
	_assert_close(float(Dictionary(fallback.get("window", {})).get("timer", 0.0)), 1.0, "tick timer fallback")


func _check_command_window_text(service) -> void:
	_assert_eq(String(service.command_window_text_state("blade_simple_4_6", "6")), "armor", "simple blade 6 state")
	_assert_eq(String(service.command_window_text_state("blade_simple_4_6", "4")), "active", "simple blade 4 state")
	_assert_eq(String(service.command_window_text_state("blade_simple_4_6", "236")), "armor", "simple blade suffix 6 state")
	_assert_eq(String(service.command_window_text_state("blade_complex_236_214", "236")), "armor", "complex blade 236 state")
	_assert_eq(String(service.command_window_text_state("blade_complex_236_214", "26")), "armor", "complex blade relaxed 26 state")
	_assert_eq(String(service.command_window_text_state("blade_complex_236_214", "214")), "active", "complex blade 214 state")
	_assert_eq(String(service.command_window_text_state("blade_complex_236_214", "24")), "active", "complex blade relaxed 24 state")
	_assert_eq(String(service.command_window_text_state("blade_complex_236_214", "6")), "", "complex blade bare 6 state")
	_assert_eq(String(service.command_window_text_state("gauntlet_4_6_236_214", "26")), "armor", "gauntlet relaxed 26 state")
	_assert_eq(String(service.command_window_text_state("blunt_terminal_4_6_236_214", "24")), "active", "blunt relaxed 24 state")
	_assert_eq(String(service.command_window_text_state("unsupported", "236")), "", "unsupported text profile state")


func _check_command_window_blade_variant(service) -> void:
	_assert_eq(String(service.command_window_blade_variant("blade_simple_4_6", "6", "normal")), "armor_forward_cut", "simple blade text armor variant")
	_assert_eq(String(service.command_window_blade_variant("blade_simple_4_6", "", "armor")), "armor_forward_cut", "simple blade state armor variant")
	_assert_eq(String(service.command_window_blade_variant("blade_simple_4_6", "4", "normal")), "active_reverse_cut", "simple blade text active variant")
	_assert_eq(String(service.command_window_blade_variant("blade_simple_4_6", "", "active")), "active_reverse_cut", "simple blade state active variant")
	_assert_eq(String(service.command_window_blade_variant("blade_simple_4_6", "", "normal")), "normal_sweep", "simple blade normal variant")
	_assert_eq(String(service.command_window_blade_variant("blade_complex_236_214", "236", "normal")), "armor_special", "complex blade 236 variant")
	_assert_eq(String(service.command_window_blade_variant("blade_complex_236_214", "26", "normal")), "armor_special", "complex blade relaxed 26 variant")
	_assert_eq(String(service.command_window_blade_variant("blade_complex_236_214", "214", "normal")), "active_special", "complex blade 214 variant")
	_assert_eq(String(service.command_window_blade_variant("blade_complex_236_214", "24", "normal")), "active_special", "complex blade relaxed 24 variant")
	_assert_eq(String(service.command_window_blade_variant("blade_complex_236_214", "6", "normal")), "normal_sweep", "complex blade bare 6 variant")
	_assert_eq(String(service.command_window_blade_variant("unsupported", "236", "armor")), "normal_sweep", "unsupported blade variant")


func _check_command_window_gauntlet_variant(service) -> void:
	_assert_eq(String(service.command_window_gauntlet_variant("26", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_inward_extend", "gauntlet relaxed armor text variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "armor", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_inward_extend", "gauntlet armor state variant")
	_assert_eq(String(service.command_window_gauntlet_variant("24", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_outward_extend", "gauntlet relaxed active text variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "active", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_outward_extend", "gauntlet active state variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT)), "normal_inward_swing", "gauntlet forward input variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT)), "normal_outward_swing", "gauntlet back input variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT)), "normal_inward_swing", "gauntlet latest forward variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.UP, Vector2.ZERO, Vector2.RIGHT)), "normal_extend", "gauntlet side input variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "normal_extend", "gauntlet neutral variant")
	_assert_eq(String(service.command_window_gauntlet_variant("", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.ZERO)), "normal_extend", "gauntlet missing forward variant")


func _check_command_window_blunt_variant(service) -> void:
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "26", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_guard_bash", "shield relaxed armor text variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "armor", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_guard_bash", "shield armor state variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "24", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_shoulder_bash", "shield relaxed active text variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "active", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_shoulder_bash", "shield active state variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT)), "normal_forward_bash", "shield forward input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "normal", Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT)), "normal_back_bash", "shield back input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "normal", Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT)), "normal_forward_bash", "shield latest forward variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "normal", Vector2.UP, Vector2.ZERO, Vector2.RIGHT)), "normal_guard", "shield side input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_shield_guard_bash", "", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "normal_guard", "shield neutral variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "236", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_overhead_slam", "hammer armor text variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "armor", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "armor_overhead_slam", "hammer armor state variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "214", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_side_slam", "hammer active text variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "active", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "active_side_slam", "hammer active state variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT)), "normal_forward_slam", "hammer forward input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT)), "normal_back_slam", "hammer back input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT)), "normal_forward_slam", "hammer latest forward variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.UP, Vector2.ZERO, Vector2.RIGHT)), "normal_short_swing", "hammer side input variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT)), "normal_short_swing", "hammer neutral variant")
	_assert_eq(String(service.command_window_blunt_variant("blunt_hammer_windup_slam", "", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.ZERO)), "normal_short_swing", "hammer missing forward variant")


func _check_command_window_binding_profile(service) -> void:
	var fallback: Dictionary = service.command_window_binding_profile({
		"module_part": {
			"module_action_profile": "katana_quickdraw",
			"command_window_profile": "blade_simple_4_6",
		},
	})
	_assert_eq(String(fallback.get("profile", "")), "katana_quickdraw", "binding profile falls back to module part")
	_assert_eq(String(fallback.get("command_profile", "")), "blade_simple_4_6", "binding command profile falls back to module part")
	var override: Dictionary = service.command_window_binding_profile({
		"module_action_profile": "blade_arc_return",
		"command_window_profile": "blade_complex_236_214",
		"module_part": {
			"module_action_profile": "katana_quickdraw",
			"command_window_profile": "blade_simple_4_6",
		},
	})
	_assert_eq(String(override.get("profile", "")), "blade_arc_return", "binding profile top-level override")
	_assert_eq(String(override.get("command_profile", "")), "blade_complex_236_214", "binding command profile top-level override")
	var empty: Dictionary = service.command_window_binding_profile({"module_part": "invalid"})
	_assert_eq(String(empty.get("profile", "missing")), "", "invalid module part profile fallback")
	_assert_eq(String(empty.get("command_profile", "missing")), "", "invalid module part command profile fallback")


func _check_command_window_buffer_clear(service) -> void:
	var profiles := [
		"blunt_gauntlet_extend_swing",
		"blunt_shield_guard_bash",
		"blunt_hammer_windup_slam",
		"blade_arc_return",
		"katana_quickdraw",
		"scythe_hook_return",
		"greatsword_commit_cleave",
		"triple_limb_cross_cut",
		"extend_slash_driver",
	]
	_assert_eq(bool(service.command_window_should_clear_buffer("active", "unknown", profiles)), true, "active state clears command buffer")
	_assert_eq(bool(service.command_window_should_clear_buffer("armor", "unknown", profiles)), true, "armor state clears command buffer")
	_assert_eq(bool(service.command_window_should_clear_buffer("normal", "blunt_gauntlet_extend_swing", profiles)), true, "gauntlet profile clears command buffer")
	_assert_eq(bool(service.command_window_should_clear_buffer("normal", "katana_quickdraw", profiles)), true, "blade profile clears command buffer")
	_assert_eq(bool(service.command_window_should_clear_buffer("normal", "gun_activate", profiles)), false, "gun profile does not clear command buffer")
	_assert_eq(bool(service.command_window_should_clear_buffer("", "unknown", profiles)), false, "empty state unknown profile does not clear command buffer")


func _check_command_window_runtime_state(service) -> void:
	var gauntlet_profiles := ["blunt_gauntlet_extend_swing"]
	var blunt_profiles := ["blunt_shield_guard_bash", "blunt_hammer_windup_slam"]
	var blade_profiles := [
		"blade_arc_return",
		"katana_quickdraw",
		"scythe_hook_return",
		"greatsword_commit_cleave",
		"triple_limb_cross_cut",
		"extend_slash_driver",
	]
	_assert_eq(String(service.command_window_runtime_state("blunt_gauntlet_extend_swing", "", "26", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "armor", "gauntlet runtime armor state")
	_assert_eq(String(service.command_window_runtime_state("blunt_gauntlet_extend_swing", "", "24", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "active", "gauntlet runtime active state")
	_assert_eq(String(service.command_window_runtime_state("blunt_gauntlet_extend_swing", "", "", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "normal", "gauntlet runtime fallback state")
	_assert_eq(String(service.command_window_runtime_state("blunt_shield_guard_bash", "", "24", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "active", "blunt runtime active state")
	_assert_eq(String(service.command_window_runtime_state("blunt_hammer_windup_slam", "", "26", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "armor", "blunt runtime armor state")
	_assert_eq(String(service.command_window_runtime_state("katana_quickdraw", "blade_simple_4_6", "4", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "active", "simple blade runtime active state")
	_assert_eq(String(service.command_window_runtime_state("katana_quickdraw", "blade_simple_4_6", "6", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "armor", "simple blade runtime armor state")
	_assert_eq(String(service.command_window_runtime_state("blade_arc_return", "blade_complex_236_214", "26", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "armor", "complex blade runtime relaxed armor state")
	_assert_eq(String(service.command_window_runtime_state("gun_activate", "blade_complex_236_214", "26", "normal", gauntlet_profiles, blunt_profiles, blade_profiles)), "normal", "non-command profile runtime fallback state")
	_assert_eq(String(service.command_window_runtime_state("katana_quickdraw", "unsupported", "26", "active", gauntlet_profiles, blunt_profiles, blade_profiles)), "active", "unsupported command profile preserves fallback")


func _check_command_window_runtime_variant(service) -> void:
	var gauntlet_profiles := ["blunt_gauntlet_extend_swing"]
	var blunt_profiles := ["blunt_shield_guard_bash", "blunt_hammer_windup_slam"]
	var blade_profiles := [
		"blade_arc_return",
		"katana_quickdraw",
		"scythe_hook_return",
		"greatsword_commit_cleave",
		"triple_limb_cross_cut",
		"extend_slash_driver",
	]
	_assert_eq(String(service.command_window_runtime_variant("blunt_gauntlet_extend_swing", "", "26", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "armor_inward_extend", "runtime gauntlet armor variant")
	_assert_eq(String(service.command_window_runtime_variant("blunt_gauntlet_extend_swing", "", "", "normal", Vector2.RIGHT, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "normal_inward_swing", "runtime gauntlet normal variant")
	_assert_eq(String(service.command_window_runtime_variant("blunt_shield_guard_bash", "", "24", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "active_shoulder_bash", "runtime shield active variant")
	_assert_eq(String(service.command_window_runtime_variant("blunt_hammer_windup_slam", "", "", "normal", Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "normal_back_slam", "runtime hammer back variant")
	_assert_eq(String(service.command_window_runtime_variant("katana_quickdraw", "blade_simple_4_6", "6", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "armor_forward_cut", "runtime simple blade armor variant")
	_assert_eq(String(service.command_window_runtime_variant("blade_arc_return", "blade_complex_236_214", "24", "normal", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "active_special", "runtime complex blade active variant")
	_assert_eq(String(service.command_window_runtime_variant("gun_activate", "blade_complex_236_214", "236", "armor", Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, gauntlet_profiles, blunt_profiles, blade_profiles)), "", "runtime unsupported profile variant")


func _check_command_window_state(service) -> void:
	_assert_eq(String(service.command_window_state_for_input(Vector2.RIGHT, Vector2.RIGHT)), "armor", "forward command state")
	_assert_eq(String(service.command_window_state_for_input(Vector2.LEFT, Vector2.RIGHT)), "active", "back command state")
	_assert_eq(String(service.command_window_state_for_input(Vector2.UP, Vector2.RIGHT)), "", "neutral side command state")
	_assert_eq(String(service.command_window_state_for_input(Vector2.ZERO, Vector2.RIGHT)), "", "empty input command state")
	_assert_eq(String(service.command_window_state_for_input(Vector2.RIGHT, Vector2.ZERO)), "", "empty forward command state")
	var binding := {"module_part": {"command_window_profile": "blade_simple_4_6"}}
	var eligible := ["two_link_4_6", "blade_simple_4_6", "blunt_terminal_4_6_236_214"]
	_assert_eq(String(service.command_window_state_for_binding(binding, Vector2.RIGHT, Vector2.RIGHT, eligible)), "armor", "eligible binding command state")
	_assert_eq(String(service.command_window_state_for_binding(binding, Vector2.LEFT, Vector2.RIGHT, eligible)), "active", "eligible binding back state")
	_assert_eq(String(service.command_window_state_for_binding({"module_part": {"command_window_profile": "gauntlet_4_6_236_214"}}, Vector2.RIGHT, Vector2.RIGHT, eligible)), "", "ineligible binding command state")
	_assert_eq(String(service.command_window_state_for_binding({"module_part": {"command_window_profile": "blade_simple_4_6"}, "command_window_profile": "unsupported"}, Vector2.RIGHT, Vector2.RIGHT, eligible)), "", "top-level command profile override")


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


func _assert_vec_close(actual: Vector2, expected: Vector2, label: String, epsilon: float = 0.001) -> void:
	if actual.distance_to(expected) > epsilon:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
