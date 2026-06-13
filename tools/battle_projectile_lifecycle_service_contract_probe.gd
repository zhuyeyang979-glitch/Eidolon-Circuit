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
		"explosion_request_intent",
		"explosion_center_position",
		"explosion_initial_effect_anchor_intent",
		"explosion_target_candidate_intent",
		"explosion_damage_intent",
		"projectile_hit_block_intent",
		"projectile_reflector_candidate_intent",
		"projectile_reflection_intent",
		"target_projectile_shield_reflects",
		"target_shield_reflection_intent",
		"target_shield_reflected_target_intent",
		"projectile_source_node_for_event",
		"projectile_event_has_gun_source",
		"runtime_melee_projectile_clear_intent",
		"runtime_gun_pose_clear_node",
		"group_uses_true_bullet",
		"true_bullet_event_pending",
		"true_bullet_event_fired",
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
		"_battle_projectile_lifecycle_service().explosion_request_intent({",
		"_battle_projectile_lifecycle_service().explosion_center_position({",
		"_battle_projectile_lifecycle_service().explosion_initial_effect_anchor_intent({",
		"_battle_projectile_lifecycle_service().explosion_target_candidate_intent({",
		"_battle_projectile_lifecycle_service().explosion_damage_intent",
		"_battle_projectile_lifecycle_service().projectile_hit_block_intent({",
		"_battle_projectile_lifecycle_service().projectile_reflector_candidate_intent({",
		"_battle_projectile_lifecycle_service().projectile_reflection_intent",
		"_battle_projectile_lifecycle_service().target_projectile_shield_reflects({",
		"_battle_projectile_lifecycle_service().target_shield_reflection_intent",
		"_battle_projectile_lifecycle_service().target_shield_reflected_target_intent({",
		"_battle_projectile_lifecycle_service().projectile_source_node_for_event",
		"_battle_projectile_lifecycle_service().projectile_event_has_gun_source",
		"_battle_projectile_lifecycle_service().runtime_melee_projectile_clear_intent",
		"_battle_projectile_lifecycle_service().runtime_gun_pose_clear_node",
		"_battle_projectile_lifecycle_service().group_uses_true_bullet",
		"_battle_projectile_lifecycle_service().true_bullet_event_pending",
		"_battle_projectile_lifecycle_service().true_bullet_event_fired",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate projectile lifecycle token: %s" % token)
			return
	if main_source.count("_battle_projectile_lifecycle_service().projectile_hit_block_intent({") != 2:
		_fail("main.gd should delegate both explosion and target-shield hit blocking to projectile_hit_block_intent.")
		return
	var stale_target_shield_reflects := "func _target_projectile_shield_reflects(target, event: Dictionary) -> bool:\n\tif not _is_live_unit(target):\n\t\treturn false\n\tif float(target.get_meta(\"projectile_shield_timer\", 0.0)) <= 0.0:\n\t\treturn false\n\tvar damage_type := String(event.get(\"damage_type\", \"bullet\"))\n\tvar reflect_types: Array = target.get_meta(\"projectile_shield_types\", target.stats.get(\"reflect_types\", []))\n\treturn reflect_types.is_empty() or reflect_types.has(damage_type)"
	if main_source.find(stale_target_shield_reflects) >= 0:
		_fail("main.gd should not keep duplicate target projectile shield reflection rules.")
		return
	var stale_reflector_candidate_filter := "if reflector == attacker or not _is_live_unit(reflector) or not bool(reflector.stats.get(\"reflect_projectiles\", false)):\n\t\t\tcontinue\n\t\tvar reflect_types: Array = reflector.stats.get(\"reflect_types\", [])\n\t\tif not reflect_types.is_empty() and not reflect_types.has(damage_type):\n\t\t\tcontinue"
	if main_source.find(stale_reflector_candidate_filter) >= 0:
		_fail("main.gd should not keep duplicate projectile reflector candidate rules.")
		return
	var stale_target_shield_reflected_target_filter := "if reflected_target == attacker or reflected_target == target or not _is_live_unit(reflected_target):\n\t\t\tcontinue\n\t\tvar reflected_delta := _mobius_delta_vec_between(target, reflected_target, 1.25)\n\t\tvar distance := absf(reflected_delta.x)\n\t\tvar lane_distance := absf(reflected_delta.y)\n\t\tvar target_radius := float(reflected_target.stats.get(\"radius\", 0.2))\n\t\tif distance > float(event_copy[\"range\"]) + target_radius or lane_distance > float(event_copy[\"lane_range\"]) + target_radius * 0.6:\n\t\t\tcontinue\n\t\tvar target_vector := reflected_delta\n\t\tif target_vector.length() > 0.01 and reflected_dir.dot(target_vector.normalized()) < 0.24:\n\t\t\tcontinue"
	if main_source.find(stale_target_shield_reflected_target_filter) >= 0:
		_fail("main.gd should not keep duplicate target shield reflected-target rules.")
		return
	var stale_explosion_candidate_filter := "if not _is_live_unit(target) or target == primary_target:\n\t\t\tcontinue"
	if main_source.find(stale_explosion_candidate_filter) >= 0:
		_fail("main.gd should not keep duplicate explosion target candidate rules.")
		return
	var stale_explosion_request_parser := "var radius := maxf(0.08, float(event.get(\"explosion_radius\", 0.0)))\n\tvar damage := int(event.get(\"explosion_damage\", 0))\n\tif damage <= 0:\n\t\treturn killed_units\n\tvar damage_type := String(event.get(\"explosion_damage_type\", event.get(\"damage_type\", \"blunt\")))"
	if main_source.find(stale_explosion_request_parser) >= 0:
		_fail("main.gd should not keep duplicate explosion request parsing rules.")
		return
	var stale_explosion_center_selection := "var center_ring: float = attacker.ring_pos\n\tvar center_lane: float = attacker.lane\n\tif primary_target != null and is_instance_valid(primary_target):\n\t\tcenter_ring = primary_target.ring_pos\n\t\tcenter_lane = primary_target.lane"
	if main_source.find(stale_explosion_center_selection) >= 0:
		_fail("main.gd should not keep duplicate explosion center selection rules.")
		return
	var stale_explosion_initial_effect_anchor := "_spawn_hit_effect(primary_target if primary_target != null and is_instance_valid(primary_target) else attacker, 2, damage_type, false, String(event.get(\"explosion_style\", \"blast\")))"
	if main_source.find(stale_explosion_initial_effect_anchor) >= 0:
		_fail("main.gd should not keep duplicate explosion initial effect anchor rules.")
		return
	var stale_explosion_hit_block := "final_damage = _projectile_material_adjusted_damage(target, event_copy, final_damage)\n\t\tvar blocked := final_damage <= 0 or bool(event_copy.get(\"contact_gate_blocked\", false))"
	if main_source.find(stale_explosion_hit_block) >= 0:
		_fail("main.gd should not keep duplicate explosion hit block rules.")
		return
	var stale_target_shield_hit_block := "final_damage = _projectile_material_adjusted_damage(reflected_target, event_copy, final_damage)\n\t\tvar blocked := final_damage <= 0 or bool(event_copy.get(\"contact_gate_blocked\", false))"
	if main_source.find(stale_target_shield_hit_block) >= 0:
		_fail("main.gd should not keep duplicate target shield reflected-hit block rules.")
		return
	var service = BattleProjectileLifecycleServiceScript.new()
	_check_chemical_tick(service)
	_check_missile_tick(service)
	_check_firework(service)
	_check_web(service)
	_check_explosion(service)
	_check_reflection(service)
	_check_projectile_source_node(service)
	_check_projectile_gun_source(service)
	_check_runtime_melee_projectile_clear(service)
	_check_runtime_gun_pose_clear_node(service)
	_check_true_bullet_classification(service)
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
	_assert_eq(String(service.explosion_request_intent({
		"event": {"explosion_damage": 0},
	}).get("reason", "")), "no_damage", "explosion request damage gate")
	var request: Dictionary = service.explosion_request_intent({
		"event": {
			"explosion_radius": 0.01,
			"explosion_damage": 7,
			"damage_type": "laser",
			"explosion_style": "plasma",
		},
	})
	_assert_bool(request.get("applies", false), true, "explosion request include")
	_assert_close(float(request.get("radius", 0.0)), 0.08, "explosion request radius clamp")
	_assert_eq(int(request.get("damage", 0)), 7, "explosion request damage")
	_assert_eq(String(request.get("damage_type", "")), "laser", "explosion request fallback type")
	_assert_eq(String(request.get("explosion_style", "")), "plasma", "explosion request style")
	_assert_eq(String(service.explosion_request_intent({
		"event": {
			"explosion_damage": 3,
			"damage_type": "laser",
			"explosion_damage_type": "chemical",
		},
	}).get("damage_type", "")), "chemical", "explosion request explicit type")
	var attacker_center: Dictionary = service.explosion_center_position({
		"attacker_position": Vector2(1.2, -0.3),
		"primary_target_valid": false,
		"primary_target_position": Vector2(4.0, 0.7),
	})
	_assert_vec_close(attacker_center.get("position", Vector2.ZERO), Vector2(1.2, -0.3), "explosion center attacker fallback")
	_assert_eq(String(attacker_center.get("source", "")), "attacker", "explosion center attacker source")
	var primary_center: Dictionary = service.explosion_center_position({
		"attacker_position": Vector2(1.2, -0.3),
		"primary_target_valid": true,
		"primary_target_position": Vector2(4.0, 0.7),
	})
	_assert_vec_close(primary_center.get("position", Vector2.ZERO), Vector2(4.0, 0.7), "explosion center primary")
	_assert_eq(String(primary_center.get("source", "")), "primary_target", "explosion center primary source")
	_assert_eq(String(service.explosion_initial_effect_anchor_intent({
		"primary_target_valid": false,
	}).get("source", "")), "attacker", "explosion initial effect attacker anchor")
	_assert_eq(String(service.explosion_initial_effect_anchor_intent({
		"primary_target_valid": true,
	}).get("source", "")), "primary_target", "explosion initial effect primary anchor")
	_assert_eq(String(service.explosion_target_candidate_intent({
		"target_live": false,
		"is_primary_target": false,
	}).get("reason", "")), "target_gone", "explosion target live gate")
	_assert_eq(String(service.explosion_target_candidate_intent({
		"target_live": true,
		"is_primary_target": true,
	}).get("reason", "")), "primary_target", "explosion target primary gate")
	_assert_bool(service.explosion_target_candidate_intent({
		"target_live": true,
		"is_primary_target": false,
	}).get("include", false), true, "explosion target include")
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
	var no_damage_block: Dictionary = service.projectile_hit_block_intent({
		"final_damage": 0,
		"contact_gate_blocked": false,
	})
	_assert_bool(no_damage_block.get("blocked", false), true, "projectile no-damage block")
	_assert_eq(String(no_damage_block.get("reason", "")), "no_damage", "projectile no-damage block reason")
	var contact_block: Dictionary = service.projectile_hit_block_intent({
		"final_damage": 7,
		"contact_gate_blocked": true,
	})
	_assert_bool(contact_block.get("blocked", false), true, "projectile contact-gate block")
	_assert_eq(String(contact_block.get("reason", "")), "contact_gate_blocked", "projectile contact-gate block reason")
	var pass_block: Dictionary = service.projectile_hit_block_intent({
		"final_damage": 7,
		"contact_gate_blocked": false,
	})
	_assert_bool(pass_block.get("blocked", true), false, "projectile hit should pass")
	_assert_eq(String(pass_block.get("reason", "")), "ok", "projectile hit pass reason")


func _check_reflection(service) -> void:
	_assert_bool(service.projectile_reflector_candidate_intent({
		"is_self": true,
		"reflector_live": true,
		"reflect_projectiles": true,
		"reflect_types": [],
		"damage_type": "bullet",
	}).get("include", true), false, "projectile reflector self gate")
	_assert_eq(String(service.projectile_reflector_candidate_intent({
		"reflector_live": false,
		"reflect_projectiles": true,
		"reflect_types": [],
		"damage_type": "bullet",
	}).get("reason", "")), "reflector_gone", "projectile reflector live gate")
	_assert_eq(String(service.projectile_reflector_candidate_intent({
		"reflector_live": true,
		"reflect_projectiles": false,
		"reflect_types": [],
		"damage_type": "bullet",
	}).get("reason", "")), "reflection_disabled", "projectile reflector enabled gate")
	_assert_bool(service.projectile_reflector_candidate_intent({
		"reflector_live": true,
		"reflect_projectiles": true,
		"reflect_types": [],
		"damage_type": "chemical",
	}).get("include", false), true, "projectile reflector empty allowlist")
	_assert_bool(service.projectile_reflector_candidate_intent({
		"reflector_live": true,
		"reflect_projectiles": true,
		"reflect_types": ["bullet", "laser"],
		"damage_type": "chemical",
	}).get("include", true), false, "projectile reflector type gate")
	_assert_bool(service.projectile_reflector_candidate_intent({
		"reflector_live": true,
		"reflect_projectiles": true,
		"reflect_types": ["bullet", "laser"],
		"damage_type": "laser",
	}).get("include", false), true, "projectile reflector matching type")
	_assert_bool(service.target_projectile_shield_reflects({
		"target_live": false,
		"shield_timer": 1.0,
		"damage_type": "bullet",
		"reflect_types": [],
	}), false, "dead target shield reflection gate")
	_assert_bool(service.target_projectile_shield_reflects({
		"target_live": true,
		"shield_timer": 0.0,
		"damage_type": "bullet",
		"reflect_types": [],
	}), false, "expired target shield reflection gate")
	_assert_bool(service.target_projectile_shield_reflects({
		"target_live": true,
		"shield_timer": 0.5,
		"damage_type": "laser",
		"reflect_types": [],
	}), true, "empty target shield type allowlist")
	_assert_bool(service.target_projectile_shield_reflects({
		"target_live": true,
		"shield_timer": 0.5,
		"damage_type": "laser",
		"reflect_types": ["bullet", "laser"],
	}), true, "matching target shield type")
	_assert_bool(service.target_projectile_shield_reflects({
		"target_live": true,
		"shield_timer": 0.5,
		"damage_type": "chemical",
		"reflect_types": ["bullet", "laser"],
	}), false, "non-matching target shield type")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": true,
		"is_source_target": false,
		"reflected_target_live": true,
	}).get("reason", "")), "attacker", "shield reflected target attacker gate")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": true,
		"reflected_target_live": true,
	}).get("reason", "")), "source_target", "shield reflected target source gate")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": false,
		"reflected_target_live": false,
	}).get("reason", "")), "target_gone", "shield reflected target live gate")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": false,
		"reflected_target_live": true,
		"range": 1.0,
		"lane_range": 0.2,
		"target_radius": 0.2,
		"reflected_delta": Vector2(1.3, 0.0),
		"reflected_direction": Vector2.RIGHT,
	}).get("reason", "")), "out_of_range", "shield reflected target distance gate")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": false,
		"reflected_target_live": true,
		"range": 1.0,
		"lane_range": 0.2,
		"target_radius": 0.2,
		"reflected_delta": Vector2(0.4, 0.5),
		"reflected_direction": Vector2.RIGHT,
	}).get("reason", "")), "out_of_lane", "shield reflected target lane gate")
	_assert_eq(String(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": false,
		"reflected_target_live": true,
		"range": 1.0,
		"lane_range": 0.2,
		"target_radius": 0.2,
		"reflected_delta": Vector2(-0.4, 0.0),
		"reflected_direction": Vector2.RIGHT,
	}).get("reason", "")), "direction_rejected", "shield reflected target direction gate")
	_assert_bool(service.target_shield_reflected_target_intent({
		"is_attacker": false,
		"is_source_target": false,
		"reflected_target_live": true,
		"range": 1.0,
		"lane_range": 0.2,
		"target_radius": 0.2,
		"reflected_delta": Vector2(0.6, 0.08),
		"reflected_direction": Vector2.RIGHT,
	}).get("include", false), true, "shield reflected target include")
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


func _check_projectile_source_node(service) -> void:
	_assert_eq(service.projectile_source_node_for_event({"source_gun_node": 8, "source_node_index": 4, "muscle_node": 2}, 0), 8, "source gun node should win")
	_assert_eq(service.projectile_source_node_for_event({"source_node_index": 4, "muscle_node": 2}, 0), 4, "source node index should fallback second")
	_assert_eq(service.projectile_source_node_for_event({"muscle_node": 2}, 0), 2, "muscle node should fallback third")
	_assert_eq(service.projectile_source_node_for_event({}, 7), 7, "fallback source node should be used")


func _check_projectile_gun_source(service) -> void:
	_assert_bool(service.projectile_event_has_gun_source({"projectile": false}), true, "non-projectile events should not require gun source")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "collision_group": {"projectile": true, "material_class": "gun"}}), false, "projectile events should require a muscle node")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "muscle_node": 1, "collision_group": "bad"}), false, "projectile events should reject non-dictionary groups")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "muscle_node": 1, "collision_group": {"projectile": false, "projectile_only": false, "material_class": "gun"}}), false, "projectile events should require projectile group flags")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "muscle_node": 1, "collision_group": {"projectile": true, "material_class": "MISSILE_LAUNCHER"}}), true, "projectile events should accept gun material classes")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "muscle_node": 1, "collision_group": {"projectile_only": true, "shape": "heavy_cannon"}}), true, "projectile events should accept gun shapes")
	_assert_bool(service.projectile_event_has_gun_source({"projectile": true, "muscle_node": 1, "collision_group": {"projectile": true, "material_class": "blade", "shape": "edge"}}), false, "projectile events should reject non-gun groups")


func _check_runtime_melee_projectile_clear(service) -> void:
	var intent: Dictionary = service.runtime_melee_projectile_clear_intent({
		"projectile": true,
		"projectile_only": true,
		"projectile_style": "missile",
		"projectile_behavior": "explosive",
		"travel_path": "homing",
		"projectile_damage_type": "bullet",
		"damage": 12,
	})
	var set_patch: Dictionary = Dictionary(intent.get("set", {}))
	_assert_bool(set_patch.get("projectile", true), false, "runtime melee clear should disable projectile")
	_assert_bool(set_patch.get("projectile_only", true), false, "runtime melee clear should disable projectile-only")
	_assert_bool(set_patch.get("runtime_melee_contact", false), true, "runtime melee clear should mark runtime melee contact")
	_assert_eq(Array(intent.get("erase", [])), ["projectile_style", "projectile_behavior", "travel_path", "projectile_damage_type"], "runtime melee clear erase list")


func _check_runtime_gun_pose_clear_node(service) -> void:
	_assert_eq(service.runtime_gun_pose_clear_node({"source_gun_node": 8, "binding": {"target_nodes": [2, 3]}}, -1), 8, "runtime gun pose clear should prefer explicit source node")
	_assert_eq(service.runtime_gun_pose_clear_node({"binding": {"target_nodes": [2, 3, 5]}}, -1), 5, "runtime gun pose clear should use binding target tail")
	_assert_eq(service.runtime_gun_pose_clear_node({"target_nodes": [4, 7]}, -1), 7, "runtime gun pose clear should use direct target tail")
	_assert_eq(service.runtime_gun_pose_clear_node({"binding": {"target_nodes": []}, "target_nodes": [9]}, -1), 9, "runtime gun pose clear should fall through empty binding targets")
	_assert_eq(service.runtime_gun_pose_clear_node({}, -1), -1, "runtime gun pose clear should preserve fallback for empty payload")


func _check_true_bullet_classification(service) -> void:
	_assert_bool(service.group_uses_true_bullet({"projectile": true}, "true_bullet"), true, "true bullet group should classify with projectile flag")
	_assert_bool(service.group_uses_true_bullet({"projectile": false}, "true_bullet"), false, "true bullet group should require projectile flag")
	_assert_bool(service.group_uses_true_bullet({"projectile": true}, "bullet_hell"), false, "true bullet group should require true bullet behavior")
	_assert_bool(service.true_bullet_event_pending({"projectile": true}, "true_bullet"), true, "pending true bullet event should classify before fire")
	_assert_bool(service.true_bullet_event_pending({"projectile": true, "true_bullet_ready": true}, "true_bullet"), false, "pending true bullet event should reject fired events")
	_assert_bool(service.true_bullet_event_pending({"projectile": true, "non_damage": true}, "true_bullet"), false, "pending true bullet event should reject non-damage events")
	_assert_bool(service.true_bullet_event_pending({"projectile": false}, "true_bullet"), false, "pending true bullet event should require projectile flag")
	_assert_bool(service.true_bullet_event_pending({"projectile": true}, "bullet_hell"), false, "pending true bullet event should require true bullet behavior")
	_assert_bool(service.true_bullet_event_fired({"projectile": true, "true_bullet_ready": true}, "true_bullet"), true, "fired true bullet event should classify ready projectiles")
	_assert_bool(service.true_bullet_event_fired({"projectile": true, "true_bullet_ready": false}, "true_bullet"), false, "fired true bullet event should require ready flag")
	_assert_bool(service.true_bullet_event_fired({"projectile": false, "true_bullet_ready": true}, "true_bullet"), false, "fired true bullet event should require projectile flag")
	_assert_bool(service.true_bullet_event_fired({"projectile": true, "true_bullet_ready": true}, "bullet_hell"), false, "fired true bullet event should require true bullet behavior")


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
