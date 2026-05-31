extends SceneTree

const BattleRuntimeLifecycleService := preload("res://scripts/services/battle_runtime_lifecycle_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_runtime_lifecycle_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleRuntimeLifecycleService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "UnitScene", "GpuCollisionPipeline", "Fighter", "_create_unit", "_end_battle", "take_hit", "queue_free", "randf", "randi", "Time", "BattleContactVfxPool"]:
		if source.contains(forbidden):
			_fail("BattleRuntimeLifecycleService contains forbidden token: %s" % forbidden)
			return
	var service := BattleRuntimeLifecycleService.new()
	var snapshot := {
		"unit_count": 3,
		"pending_laser_shots": 2,
		"pending_true_bullet_shots": 1,
		"pending_chemical_projectiles": 4,
		"pending_missile_projectiles": 5,
		"active_web_tethers": 6,
		"active_web_swings": 7,
		"battle_effect_children": 8,
	}
	var expected_count := 28
	if service.runtime_count(snapshot) != expected_count:
		_fail("runtime_count mismatch: %d" % service.runtime_count(snapshot))
		return
	var summary := service.snapshot_summary(snapshot)
	if int(summary.get("battle_runtime_count", 0)) != expected_count or int(summary.get("pending_projectiles", 0)) != 12:
		_fail("snapshot_summary mismatch: %s" % str(summary))
		return
	var preserved := service.cleanup_intent(snapshot, true)
	if not bool(preserved.get("preserve", false)) or bool(preserved.get("clear_runtime", true)):
		_fail("preserve cleanup intent should not clear runtime: %s" % str(preserved))
		return
	var cleanup := service.cleanup_intent(snapshot, false)
	if bool(cleanup.get("preserve", true)) or not bool(cleanup.get("clear_runtime", false)):
		_fail("exit cleanup intent should clear runtime: %s" % str(cleanup))
		return
	for required_flag in ["hide_runtime_menu", "hide_aim_lines", "clear_units", "clear_input_edges", "clear_gun_state"]:
		if not bool(cleanup.get(required_flag, false)):
			_fail("cleanup intent missing flag %s: %s" % [required_flag, str(cleanup)])
			return
	var categories: Array = Array(cleanup.get("categories", []))
	for category in ["units", "effects", "pending_projectiles", "web_runtime", "aim_state"]:
		if not categories.has(category):
			_fail("cleanup intent missing category %s: %s" % [category, str(categories)])
			return
	var temp_death := service.kill_flow_intent({
		"temporary_fracture": true,
		"victim_id": 2,
		"killer_id": 1,
		"victim_live_count": 0,
		"training_mode": false,
		"game_over": false,
	})
	if String(temp_death.get("action", "")) != "temporary_fracture_death" or not bool(temp_death.get("end_battle", false)):
		_fail("temporary fracture death intent mismatch: %s" % str(temp_death))
		return
	var normal_death := service.kill_flow_intent({
		"victim_id": 2,
		"killer_id": 1,
		"killed_role": "puppet",
		"can_betray": true,
		"can_retreat": true,
		"is_repair_station": true,
		"has_escape_pod": true,
	})
	var normal_actions: Array = Array(normal_death.get("actions", []))
	for action in ["try_betrayal", "try_retreat", "destroy_docked_units", "launch_escape_pod", "destroy_economy", "cleanup_fracture_puppets", "detach", "post_detach", "free"]:
		if not normal_actions.has(action):
			_fail("normal death intent missing action %s: %s" % [action, str(normal_death)])
			return
	if String(normal_death.get("escape_action", "")) != "launch":
		_fail("normal death escape action mismatch: %s" % str(normal_death))
		return
	var hero_down := service.kill_flow_intent({
		"stage": "post_detach",
		"victim_id": 2,
		"killer_id": 1,
		"killed_role": "hero",
		"killer_victory_points": 1,
		"win_points": 2,
		"hero_kill_reward": 100.0,
		"victim_live_count": 1,
	})
	if int(hero_down.get("victory_point_delta", 0)) != 1 or not bool(hero_down.get("end_battle", false)):
		_fail("hero down intent mismatch: %s" % str(hero_down))
		return
	var hero_resources: Array = Array(hero_down.get("resource_deltas", []))
	if hero_resources.size() != 1 or int(Dictionary(hero_resources[0]).get("player_id", 0)) != 2 or float(Dictionary(hero_resources[0]).get("delta", 0.0)) != 100.0:
		_fail("hero down resource intent mismatch: %s" % str(hero_resources))
		return
	var absent_hero := service.kill_flow_intent({
		"stage": "post_detach",
		"victim_id": 2,
		"killer_id": 1,
		"killed_role": "puppet",
		"hero_live": false,
		"killer_victory_points": 0,
		"win_points": 3,
		"victim_live_count": 2,
	})
	if int(absent_hero.get("victory_point_delta", 0)) != 1 or bool(absent_hero.get("end_battle", false)):
		_fail("hero absent VP intent mismatch: %s" % str(absent_hero))
		return
	var training_respawn := service.kill_flow_intent({
		"stage": "post_detach",
		"victim_id": 2,
		"killer_id": 1,
		"killed_role": "hero",
		"training_mode": true,
		"training_respawn_timer": 1.1,
	})
	if absf(float(training_respawn.get("training_respawn_timer", 0.0)) - 1.1) > 0.001 or bool(training_respawn.get("end_battle", true)):
		_fail("training respawn intent mismatch: %s" % str(training_respawn))
		return
	var all_dead := service.kill_flow_intent({
		"stage": "post_detach",
		"victim_id": 2,
		"killer_id": 1,
		"killed_role": "puppet",
		"hero_live": true,
		"victim_live_count": 0,
		"training_mode": false,
		"game_over": false,
	})
	if not bool(all_dead.get("end_battle", false)):
		_fail("all dead battle end intent mismatch: %s" % str(all_dead))
		return
	var economy := service.destroy_economy_intents({
		"victim_id": 2,
		"killer_id": 1,
		"bounty_reward": 84,
		"insured_refund": 12,
		"owner_destroy_penalty": 30,
		"victim_resource": 19.0,
	})
	if economy.size() != 3:
		_fail("destroy economy intent count mismatch: %s" % str(economy))
		return
	if float(Dictionary(economy[0]).get("delta", 0.0)) != 84.0 or float(Dictionary(economy[1]).get("delta", 0.0)) != 12.0 or float(Dictionary(economy[2]).get("delta", 0.0)) != -19.0:
		_fail("destroy economy deltas mismatch: %s" % str(economy))
		return
	var betrayal := service.pirate_betrayal_intent({
		"role": "puppet",
		"killer_id": 1,
		"betrayal_chance": 0.5,
		"data_security": 0.5,
		"betrayal_roll": 0.7,
	})
	if not bool(betrayal.get("betray", false)) or int(betrayal.get("new_owner", 0)) != 1:
		_fail("pirate betrayal intent mismatch: %s" % str(betrayal))
		return
	var no_betrayal := service.pirate_betrayal_intent({
		"role": "hero",
		"killer_id": 1,
		"betrayal_chance": 1.0,
		"data_security": 1.0,
		"betrayal_roll": 0.0,
	})
	if bool(no_betrayal.get("betray", false)):
		_fail("non-puppet betrayal should be false: %s" % str(no_betrayal))
		return
	var retreat := service.retreat_start_intent({
		"unit_valid": true,
		"retreat_on_defeat": true,
		"is_mech": true,
		"already_retreating": false,
		"owner": 2,
		"role": "hero",
		"max_health": 100.0,
		"retreat_repair_rate": 10.0,
		"dock_rate": 30.0,
		"repair_time_mult": 1.0,
	})
	if not bool(retreat.get("start", false)) or absf(float(retreat.get("timer", 0.0)) - 2.5) > 0.001:
		_fail("retreat start intent mismatch: %s" % str(retreat))
		return
	var retreat_tick := service.retreat_repair_tick_intent({"unit_valid": true, "timer": 0.2, "delta": 0.25, "restore_available": false, "retry_timer": 0.45})
	if String(retreat_tick.get("action", "")) != "retry" or absf(float(retreat_tick.get("timer", 0.0)) - 0.45) > 0.001:
		_fail("retreat retry intent mismatch: %s" % str(retreat_tick))
		return
	var retreat_restore := service.retreat_repair_tick_intent({"unit_valid": true, "timer": 0.2, "delta": 0.25, "restore_available": true})
	if String(retreat_restore.get("action", "")) != "restore":
		_fail("retreat restore intent mismatch: %s" % str(retreat_restore))
		return
	var pod_spawn := service.escape_pod_spawn_intent({
		"unit_valid": true,
		"owner": 2,
		"stats": {"escape_module_slots": 3, "escape_speed": 1.4, "escape_target_ring_delta": 3.5, "escape_target_lane": 0.4},
		"ring_pos": 9.0,
		"lane": 0.1,
		"facing": 1.0,
		"ring_length": 10.0,
		"battle_half_height": 1.0,
	})
	var pod_meta: Dictionary = pod_spawn.get("meta", {})
	var pod_stats: Dictionary = pod_spawn.get("stats", {})
	if not bool(pod_spawn.get("spawn", false)) or int(pod_meta.get("carried_modules", 0)) != 3 or int(pod_stats.get("health", 0)) != 25:
		_fail("escape pod spawn intent mismatch: %s" % str(pod_spawn))
		return
	var pod_secure := service.escape_pod_tick_intent({"pod_live": true, "delta_vec": Vector2(0.02, 0.01), "carried_modules": 3})
	if String(pod_secure.get("action", "")) != "secure" or int(pod_secure.get("carried_modules", 0)) != 3:
		_fail("escape pod secure intent mismatch: %s" % str(pod_secure))
		return
	var pod_move := service.escape_pod_tick_intent({"pod_live": true, "delta_vec": Vector2(1.0, 1.0), "speed": 2.0})
	if String(pod_move.get("action", "")) != "move" or int(pod_move.get("facing", 0)) != 1:
		_fail("escape pod move intent mismatch: %s" % str(pod_move))
		return
	var cleanup_fragments := service.fracture_cleanup_intent({
		"parent_id": "p1",
		"candidates": [
			{"valid": true, "temporary_fracture": true, "fracture_parent_id": "p1"},
			{"valid": true, "temporary_fracture": true, "fracture_parent_id": "other"},
			{"valid": true, "temporary_fracture": false, "fracture_parent_id": "p1"},
		],
	})
	if int(cleanup_fragments.get("removed_count", 0)) != 1 or not Array(cleanup_fragments.get("remove_indices", [])).has(0):
		_fail("fracture cleanup intent mismatch: %s" % str(cleanup_fragments))
		return
	var brood := service.torso_fracture_brood_intent({
		"torso_count": 4,
		"has_fracture_brood_module": true,
		"torso_index": 1,
		"anchor": 1,
		"role": "hero",
		"has_soul": true,
		"broken": {},
		"torso_hp": {},
		"max_part_hp": 40.0,
		"contact_unit_hp_min": 6.0,
	})
	var spawn_indices: Array = Array(brood.get("spawn_indices", []))
	if not bool(brood.get("soul_anchor_protected", false)) or spawn_indices != [0, 2, 3] or absf(float(Dictionary(brood.get("torso_hp", {})).get("1", 0.0)) - 14.0) > 0.001:
		_fail("torso fracture brood intent mismatch: %s" % str(brood))
		return
	var protected_only := service.torso_fracture_brood_intent({
		"torso_count": 2,
		"has_fracture_brood_module": true,
		"torso_index": 0,
		"anchor": 0,
		"role": "hero",
		"has_soul": true,
		"broken": {"1": true},
		"torso_hp": {},
		"max_part_hp": 40.0,
		"contact_unit_hp_min": 6.0,
	})
	if String(protected_only.get("action", "")) != "protect" or not bool(protected_only.get("soul_anchor_protected", false)):
		_fail("torso fracture soul protect-only intent mismatch: %s" % str(protected_only))
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_runtime_lifecycle_service.gd",
		"BattleRuntimeLifecycleService.new",
		"battle_runtime_lifecycle_service.cleanup_intent",
		"battle_runtime_lifecycle_service.snapshot_summary",
		"_battle_runtime_lifecycle_service().kill_flow_intent",
		"_battle_runtime_lifecycle_service().destroy_economy_intents",
		"_battle_runtime_lifecycle_service().pirate_betrayal_intent",
		"_battle_runtime_lifecycle_service().retreat_start_intent",
		"_battle_runtime_lifecycle_service().retreat_repair_tick_intent",
		"_battle_runtime_lifecycle_service().escape_pod_spawn_intent",
		"_battle_runtime_lifecycle_service().escape_pod_tick_intent",
		"_battle_runtime_lifecycle_service().fracture_cleanup_intent",
		"_battle_runtime_lifecycle_service().torso_fracture_brood_intent",
		"_battle_runtime_lifecycle_snapshot",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleRuntimeLifecycleService boundary token: %s" % token)
			return
	print("BATTLE_RUNTIME_LIFECYCLE_SERVICE_CONTRACT_PROBE ok")
	quit(0)
