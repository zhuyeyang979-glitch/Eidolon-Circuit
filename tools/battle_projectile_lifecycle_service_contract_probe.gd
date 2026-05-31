extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_projectile_lifecycle_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleProjectileLifecycleServiceScript := preload("res://scripts/services/battle_projectile_lifecycle_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleProjectileLifecycleService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleProjectileLifecycleService",
		"extends RefCounted",
		"chemical_projectile_tick_intent",
		"missile_projectile_tick_intent",
		"chemical_firework_pellet_intents",
		"web_tether_tick_intent",
		"web_swing_tick_intent",
		"web_target_candidate_intent",
		"web_impact_candidate_intent",
		"web_impact_selection",
		"web_boundary_anchor_intent",
		"web_fire_intent",
		"explosion_damage_intent",
		"projectile_reflection_intent",
		"target_shield_reflection_intent",
	]:
		if service_source.find(token) < 0:
			_fail("BattleProjectileLifecycleService missing token: %s" % token)
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
			_fail("BattleProjectileLifecycleService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleProjectileLifecycleService = preload(\"res://scripts/services/battle_projectile_lifecycle_service.gd\")",
		"var battle_projectile_lifecycle_service: BattleProjectileLifecycleService",
		"battle_projectile_lifecycle_service = BattleProjectileLifecycleService.new()",
		"func _battle_projectile_lifecycle_service() -> BattleProjectileLifecycleService",
		"_battle_projectile_lifecycle_service().chemical_projectile_tick_intent",
		"_battle_projectile_lifecycle_service().missile_projectile_tick_intent",
		"_battle_projectile_lifecycle_service().chemical_firework_pellet_intents",
		"_battle_projectile_lifecycle_service().web_tether_tick_intent",
		"_battle_projectile_lifecycle_service().web_swing_tick_intent",
		"_battle_projectile_lifecycle_service().web_target_candidate_intent",
		"_battle_projectile_lifecycle_service().web_impact_candidate_intent",
		"_battle_projectile_lifecycle_service().web_impact_selection",
		"_battle_projectile_lifecycle_service().web_boundary_anchor_intent",
		"_battle_projectile_lifecycle_service().web_fire_intent",
		"_battle_projectile_lifecycle_service().explosion_damage_intent",
		"_battle_projectile_lifecycle_service().projectile_reflection_intent",
		"_battle_projectile_lifecycle_service().target_shield_reflection_intent",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate projectile lifecycle token: %s" % token)
			return
	var service = BattleProjectileLifecycleServiceScript.new()
	_check_chemical_tick(service)
	_check_missile_tick(service)
	_check_firework(service)
	_check_web(service)
	_check_explosion(service)
	_check_reflection(service)
	print("BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_chemical_tick(service) -> void:
	_assert_eq(String(service.chemical_projectile_tick_intent({"attacker_live": false}).get("action", "")), "remove", "chemical dead attacker")
	var ready: Dictionary = service.chemical_projectile_tick_intent({"attacker_live": true, "timer": 0.1, "delta": 0.2})
	_assert_eq(String(ready.get("action", "")), "resolve", "chemical ready")
	var patch: Dictionary = Dictionary(ready.get("event_patch", {}))
	if not bool(patch.get("chemical_projectile_ready", false)):
		_fail("Chemical ready intent should patch readiness: %s" % str(ready))
	var update: Dictionary = service.chemical_projectile_tick_intent({"attacker_live": true, "timer": 0.6, "delta": 0.2})
	_assert_eq(String(update.get("action", "")), "update", "chemical update")
	_assert_close(float(update.get("timer", 0.0)), 0.4, "chemical timer")


func _check_missile_tick(service) -> void:
	_assert_eq(String(service.missile_projectile_tick_intent({"attacker_live": false}).get("action", "")), "remove", "missile dead attacker")
	var clear: Dictionary = service.missile_projectile_tick_intent({
		"attacker_live": true,
		"target_live": true,
		"target_occluded": false,
		"current_direction": Vector2.UP,
		"last_direction": Vector2.RIGHT,
		"fallback_direction": Vector2.RIGHT,
		"timer": 0.6,
		"delta": 0.1,
		"occluded_for": 0.3,
		"occlusion_grace": 0.4,
	})
	_assert_eq(String(clear.get("action", "")), "update", "missile clear update")
	_assert_close(float(clear.get("occluded_for", -1.0)), 0.0, "missile clear occlusion")
	_assert_vec_close(clear.get("last_direction", Vector2.ZERO), Vector2.UP, "missile clear direction")
	var lost: Dictionary = service.missile_projectile_tick_intent({
		"attacker_live": true,
		"target_live": true,
		"target_occluded": true,
		"current_direction": Vector2.LEFT,
		"last_direction": Vector2.RIGHT,
		"fallback_direction": Vector2.RIGHT,
		"timer": 0.6,
		"delta": 0.2,
		"occluded_for": 0.35,
		"occlusion_grace": 0.4,
	})
	if not bool(lost.get("target_lost", false)):
		_fail("Missile occlusion should lose target after grace: %s" % str(lost))
	var lost_patch: Dictionary = Dictionary(lost.get("event_patch", {}))
	if not bool(lost_patch.get("erase_locked_target", false)) or bool(lost_patch.get("aim_locked", true)):
		_fail("Missile lost target should erase lock and clear aim: %s" % str(lost_patch))
	var resolve: Dictionary = service.missile_projectile_tick_intent({
		"attacker_live": true,
		"target_live": false,
		"last_direction": Vector2.LEFT,
		"fallback_direction": Vector2.RIGHT,
		"timer": 0.05,
		"delta": 0.1,
	})
	_assert_eq(String(resolve.get("action", "")), "resolve", "missile resolve")
	var resolve_patch: Dictionary = Dictionary(resolve.get("event_patch", {}))
	if not bool(resolve_patch.get("missile_flight_ready", false)) or not bool(resolve_patch.get("projectile_trace_spawned", false)):
		_fail("Missile resolve should patch ready + trace spawned: %s" % str(resolve_patch))


func _check_firework(service) -> void:
	var intents: Array = service.chemical_firework_pellet_intents({
		"event": {"damage": 20, "range": 2.0, "lane_range": 0.5, "direction": Vector2.RIGHT},
		"pellets": 5,
		"spread": 0.5,
		"base_direction": Vector2.RIGHT,
	})
	_assert_eq(intents.size(), 5, "firework pellet count")
	var first: Dictionary = Dictionary(intents[0])
	_assert_eq(String(first.get("action", "")), "resolve_pellet", "firework action")
	var first_event: Dictionary = Dictionary(first.get("event", {}))
	if not bool(first_event.get("chemical_firework_expanded", false)) or String(first_event.get("travel_path", "")) != "straight":
		_fail("Firework pellet should expand into straight chemical event: %s" % str(first_event))
	_assert_eq(int(first_event.get("damage", 0)), 9, "firework pellet damage")
	_assert_close(float(first_event.get("lane_range", 0.0)), 0.31, "firework lane range")
	var clamped: Array = service.chemical_firework_pellet_intents({"event": {}, "pellets": 99})
	_assert_eq(clamped.size(), 11, "firework pellet clamp")


func _check_web(service) -> void:
	_assert_bool(service.web_target_candidate_intent({
		"attacker_live": true,
		"target_live": true,
		"is_self": false,
	}).get("include", false), true, "web target include")
	_assert_bool(service.web_target_candidate_intent({
		"attacker_live": true,
		"target_live": true,
		"is_self": true,
	}).get("include", true), false, "web target self reject")
	_assert_bool(service.web_target_candidate_intent({
		"attacker_live": true,
		"target_live": false,
	}).get("include", true), false, "web target dead reject")
	_assert_bool(service.web_impact_candidate_intent({
		"has_hit": false,
		"projection": 0.1,
	}).get("include", true), false, "web impact no hit reject")
	_assert_bool(service.web_impact_candidate_intent({
		"has_hit": true,
		"projection": -0.02,
	}).get("include", true), false, "web impact behind reject")
	var web_candidate: Dictionary = service.web_impact_candidate_intent({
		"has_hit": true,
		"candidate_index": 3,
		"target_index": 7,
		"projection": 0.42,
		"position": Vector2(1.0, 0.2),
	})
	_assert_bool(web_candidate.get("include", false), true, "web impact include")
	_assert_eq(int(web_candidate.get("candidate_index", -1)), 3, "web impact candidate index")
	var selected: Dictionary = service.web_impact_selection([
		{"include": true, "candidate_index": 0, "target_index": 2, "distance": 0.9},
		{"include": true, "candidate_index": 1, "target_index": 4, "distance": 0.3},
		{"include": false, "candidate_index": 2, "distance": 0.1},
	])
	_assert_bool(selected.get("has_hit", false), true, "web impact selected")
	_assert_eq(int(selected.get("candidate_index", -1)), 1, "web impact nearest candidate")
	_assert_eq(int(selected.get("target_index", -1)), 4, "web impact nearest target")
	_assert_bool(service.web_impact_selection([]).get("has_hit", true), false, "web impact empty")
	var anchor: Dictionary = service.web_boundary_anchor_intent({
		"attacker_live": true,
		"anchor_enabled": true,
		"direction": Vector2(0.6, 0.8),
		"attacker_position": Vector2(9.8, 0.0),
		"range": 2.0,
		"ring_length": 10.0,
		"half_height": 1.0,
	})
	_assert_eq(String(anchor.get("action", "")), "anchor", "web anchor action")
	_assert_vec_close(anchor.get("position", Vector2.ZERO), Vector2(0.55, 1.0), "web anchor wraps")
	_assert_eq(String(anchor.get("boundary", "")), "top", "web anchor boundary")
	_assert_eq(String(service.web_boundary_anchor_intent({
		"attacker_live": true,
		"anchor_enabled": false,
		"direction": Vector2.UP,
	}).get("reason", "")), "disabled", "web anchor disabled")
	_assert_eq(String(service.web_boundary_anchor_intent({
		"attacker_live": true,
		"direction": Vector2.RIGHT,
	}).get("reason", "")), "horizontal", "web anchor horizontal")
	_assert_eq(String(service.web_boundary_anchor_intent({
		"attacker_live": true,
		"direction": Vector2.UP,
		"attacker_position": Vector2.ZERO,
		"range": 0.5,
		"half_height": 1.0,
	}).get("reason", "")), "out_of_range", "web anchor range")
	_assert_eq(String(service.web_fire_intent({"target_hit": true}).get("action", "")), "target_tether", "web target tether")
	var boundary: Dictionary = service.web_fire_intent({"boundary_anchor": true, "anchor_position": Vector2(2.0, 0.5)})
	_assert_eq(String(boundary.get("action", "")), "boundary_swing", "web boundary swing")
	_assert_vec_close(boundary.get("anchor", Vector2.ZERO), Vector2(2.0, 0.5), "web boundary anchor")
	var miss: Dictionary = service.web_fire_intent({
		"direction": Vector2.RIGHT,
		"attacker_position": Vector2(9.8, 0.0),
		"range": 1.0,
		"ring_length": 10.0,
		"half_height": 1.0,
	})
	_assert_eq(String(miss.get("action", "")), "miss_trace", "web miss trace")
	_assert_vec_close(miss.get("miss_position", Vector2.ZERO), Vector2(0.8, 0.0), "web miss wraps")
	var tether: Dictionary = service.web_tether_tick_intent({
		"attacker_live": true,
		"target_live": true,
		"timer": 1.0,
		"delta": 0.2,
		"delta_vec": Vector2(1.0, 0.0),
		"strength": 1.0,
		"break_force": 10.0,
		"attacker_mass": 2.0,
		"target_mass": 6.0,
		"mode": "mass_duel",
		"accel_mult": 1.0,
	})
	_assert_eq(String(tether.get("action", "")), "update", "web tether update")
	_assert_vec_close(tether.get("attacker_velocity_delta", Vector2.ZERO), Vector2(0.15, 0.0), "web tether attacker share")
	_assert_vec_close(tether.get("target_velocity_delta", Vector2.ZERO), Vector2(-0.05, 0.0), "web tether target share")
	_assert_eq(String(service.web_tether_tick_intent({
		"attacker_live": true,
		"target_live": true,
		"timer": 1.0,
		"delta": 0.1,
		"delta_vec": Vector2(3.0, 0.0),
		"strength": 2.0,
		"break_force": 0.5,
	}).get("action", "")), "snap", "web tether snap")
	var swing: Dictionary = service.web_swing_tick_intent({
		"attacker_live": true,
		"timer": 1.0,
		"delta": 0.2,
		"to_anchor": Vector2(1.0, 0.0),
		"strength": 1.0,
		"break_force": 10.0,
		"attacker_velocity": Vector2.ZERO,
		"forward": Vector2.UP,
		"accel_mult": 1.0,
	})
	_assert_eq(String(swing.get("action", "")), "update", "web swing update")
	_assert_vec_close(swing.get("attacker_velocity_delta", Vector2.ZERO), Vector2(0.2, -0.084), "web swing velocity")
	_assert_eq(String(service.web_swing_tick_intent({
		"attacker_live": true,
		"timer": 1.0,
		"delta": 0.1,
		"to_anchor": Vector2(3.0, 0.0),
		"strength": 2.0,
		"break_force": 0.5,
	}).get("action", "")), "snap", "web swing snap")


func _check_explosion(service) -> void:
	var miss: Dictionary = service.explosion_damage_intent({
		"radius": 1.0,
		"target_radius": 0.1,
		"blast_delta": Vector2(3.0, 0.0),
	})
	if bool(miss.get("applies", true)):
		_fail("Explosion should not apply outside radius: %s" % str(miss))
	var hit: Dictionary = service.explosion_damage_intent({
		"radius": 1.0,
		"target_radius": 0.2,
		"blast_delta": Vector2(0.4, 0.2),
		"fallback_direction": Vector2.LEFT,
		"projectile_momentum": 50.0,
		"damage_type": "laser",
		"explosion_style": "plasma",
		"target_position": Vector2(4.0, 0.5),
	})
	if not bool(hit.get("applies", false)):
		_fail("Explosion should apply inside radius: %s" % str(hit))
	_assert_close(float(hit.get("falloff", 0.0)), 0.6625, "explosion falloff")
	_assert_close(float(hit.get("blast_momentum", 0.0)), 33.125, "explosion momentum")
	var patch: Dictionary = Dictionary(hit.get("event_patch", {}))
	_assert_eq(String(patch.get("damage_type", "")), "laser", "explosion damage type")
	if bool(patch.get("projectile", true)):
		_fail("Explosion event patch should disable projectile damage route: %s" % str(patch))
	var stagger: Dictionary = Dictionary(hit.get("stagger_patch", {}))
	_assert_eq(String(stagger.get("projectile_behavior", "")), "explosive", "explosion stagger behavior")
	_assert_eq(String(stagger.get("projectile_style", "")), "plasma", "explosion stagger style")


func _check_reflection(service) -> void:
	var none: Dictionary = service.projectile_reflection_intent({"direction": Vector2.ZERO})
	_assert_eq(String(none.get("action", "")), "none", "reflection no direction")
	var reflect: Dictionary = service.projectile_reflection_intent({
		"direction": Vector2.RIGHT,
		"range": 2.0,
		"lane_range": 0.3,
		"attacker_facing": 1.0,
		"reflections": 1,
		"candidates": [
			{"delta_vec": Vector2(1.0, 0.25), "distance": 1.03, "radius": 0.2, "lane_delta": 0.25, "reflect_bonus_range": 0.5, "reflect_power": 0.4},
			{"delta_vec": Vector2(-1.0, 0.0), "distance": 1.0, "radius": 0.2, "lane_delta": 0.0},
		],
	})
	_assert_eq(String(reflect.get("action", "")), "reflect", "reflection action")
	_assert_eq(int(reflect.get("candidate_index", -1)), 0, "reflection best candidate")
	var reflect_patch: Dictionary = Dictionary(reflect.get("event_patch", {}))
	_assert_close(float(reflect_patch.get("range", 0.0)), 2.5, "reflection range")
	_assert_close(float(reflect_patch.get("lane_range", 0.0)), 0.372, "reflection lane")
	_assert_eq(int(reflect_patch.get("reflections", 0)), 2, "reflection count")
	var shield: Dictionary = service.target_shield_reflection_intent({
		"target_live": true,
		"event": {"damage": 20, "range": 1.2, "lane_range": 0.2, "damage_type": "bullet"},
		"power": 0.5,
		"owner_id": 2,
		"source_name": "A shield",
		"bonus_range": 0.4,
		"fallback_direction": Vector2.LEFT,
		"attacker_delta": Vector2.RIGHT,
	})
	_assert_eq(String(shield.get("action", "")), "reflect", "shield reflection action")
	var shield_patch: Dictionary = Dictionary(shield.get("event_patch", {}))
	_assert_eq(int(shield_patch.get("owner_id", 0)), 2, "shield owner")
	_assert_eq(String(shield_patch.get("source_name", "")), "A shield", "shield source")
	_assert_eq(int(shield_patch.get("damage", 0)), 15, "shield reflected damage")
	_assert_vec_close(shield_patch.get("direction", Vector2.ZERO), Vector2.RIGHT, "shield direction")


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_bool(actual, expected: bool, label: String) -> void:
	if bool(actual) != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String, epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])


func _assert_vec_close(actual, expected: Vector2, label: String, epsilon: float = 0.001) -> void:
	if not actual is Vector2:
		_fail("%s expected Vector2 %s, got %s." % [label, str(expected), str(actual)])
		return
	var actual_vec: Vector2 = actual
	if actual_vec.distance_to(expected) > epsilon:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual_vec)])
