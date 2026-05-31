extends RefCounted
class_name BattleRuntimeLifecycleService


func runtime_count(snapshot: Dictionary) -> int:
	if snapshot.has("battle_runtime_count"):
		return max(0, int(snapshot.get("battle_runtime_count", 0)))
	var count := 0
	for key in [
		"unit_count",
		"pending_laser_shots",
		"pending_true_bullet_shots",
		"pending_chemical_projectiles",
		"pending_missile_projectiles",
		"active_web_tethers",
		"active_web_swings",
	]:
		count += max(0, int(snapshot.get(key, 0)))
	return count


func snapshot_summary(snapshot: Dictionary) -> Dictionary:
	return {
		"battle_runtime_count": runtime_count(snapshot),
		"battle_effect_children": max(0, int(snapshot.get("battle_effect_children", 0))),
		"unit_count": max(0, int(snapshot.get("unit_count", 0))),
		"pending_projectiles": max(0, int(snapshot.get("pending_laser_shots", 0))) \
			+ max(0, int(snapshot.get("pending_true_bullet_shots", 0))) \
			+ max(0, int(snapshot.get("pending_chemical_projectiles", 0))) \
			+ max(0, int(snapshot.get("pending_missile_projectiles", 0))),
		"active_web_runtime": max(0, int(snapshot.get("active_web_tethers", 0))) \
			+ max(0, int(snapshot.get("active_web_swings", 0))),
	}


func cleanup_intent(snapshot: Dictionary, preserve_for_return: bool = false) -> Dictionary:
	var summary := snapshot_summary(snapshot)
	if preserve_for_return:
		return {
			"preserve": true,
			"clear_runtime": false,
			"summary": summary,
			"categories": [],
			"reason": "preserve_for_return",
		}
	return {
		"preserve": false,
		"clear_runtime": true,
		"hide_runtime_menu": true,
		"hide_aim_lines": true,
		"clear_attack_command_windows": true,
		"clear_units": true,
		"clear_presentation_state": true,
		"clear_input_edges": true,
		"clear_aim_state": true,
		"clear_gun_state": true,
		"summary": summary,
		"categories": [
			"units",
			"effects",
			"pending_projectiles",
			"web_runtime",
			"aim_state",
			"input_edges",
			"gun_state",
		],
		"reason": "exit_battle",
	}


func kill_flow_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_valid", true)):
		return {"action": "ignore", "actions": []}
	var victim_id := int(context.get("victim_id", 0))
	var killer_id := int(context.get("killer_id", 0))
	var battle_mode := String(context.get("battle_mode", ""))
	var training_mode := bool(context.get("training_mode", battle_mode == "training"))
	var game_over := bool(context.get("game_over", false))
	var victim_live_count: int = maxi(0, int(context.get("victim_live_count", 0)))
	var killer_valid := _valid_player_id(killer_id)
	if bool(context.get("temporary_fracture", false)):
		return {
			"action": "temporary_fracture_death",
			"actions": ["detach", "message", "end_battle", "free"],
			"message_key": "fracture_puppet_destroyed",
			"end_battle": (not game_over and victim_live_count == 0 and not training_mode and killer_valid),
			"winner_id": killer_id,
		}
	var stage := String(context.get("stage", "initial"))
	if stage != "post_detach":
		var actions: Array = []
		if bool(context.get("can_betray", false)):
			actions.append("try_betrayal")
		if bool(context.get("can_retreat", false)):
			actions.append("try_retreat")
		if bool(context.get("is_repair_station", false)):
			actions.append("destroy_docked_units")
		if bool(context.get("is_escape_pod", false)):
			actions.append("escape_pod_destroyed")
		elif bool(context.get("has_escape_pod", false)):
			actions.append("launch_escape_pod")
		actions.append("destroy_economy")
		actions.append("cleanup_fracture_puppets")
		actions.append("detach")
		actions.append("post_detach")
		actions.append("free")
		return {
			"action": "normal_death",
			"actions": actions,
			"escape_action": "destroyed" if bool(context.get("is_escape_pod", false)) else ("launch" if bool(context.get("has_escape_pod", false)) else "none"),
			"destroy_docked": bool(context.get("is_repair_station", false)),
			"apply_economy": true,
			"cleanup_fracture": true,
			"detach": true,
			"free": true,
		}
	var role := String(context.get("killed_role", ""))
	var hero_live := bool(context.get("hero_live", false))
	var win_points: int = maxi(1, int(context.get("win_points", 1)))
	var current_vp := int(context.get("killer_victory_points", 0))
	var actions: Array = []
	var messages: Array = []
	var vp_delta := 0
	var resource_deltas: Array = []
	var training_respawn_timer := 0.0
	var end_battle := false
	if training_mode and victim_id == 2 and role == "hero":
		training_respawn_timer = float(context.get("training_respawn_timer", 1.1))
		actions.append("training_respawn")
		messages.append({"key": "training_dummy_respawn", "duration": 1.0})
	elif role == "hero":
		if killer_valid:
			vp_delta = 1
			actions.append("victory_point")
		if _valid_player_id(victim_id):
			resource_deltas.append({
				"player_id": victim_id,
				"delta": float(context.get("hero_kill_reward", 0.0)),
				"reason": "hero_kill_reward",
			})
		messages.append({"key": "hero_down", "duration": 1.6})
		end_battle = killer_valid and current_vp + vp_delta >= win_points
	else:
		if not hero_live:
			if killer_valid:
				vp_delta = 1
				actions.append("victory_point")
			messages.append({"key": "hero_absent_destroyed", "duration": 1.1})
			end_battle = killer_valid and current_vp + vp_delta >= win_points
		else:
			messages.append({"key": "destroyed", "duration": 0.8})
	if not game_over and not end_battle and victim_live_count == 0 and not training_mode and killer_valid:
		end_battle = true
	return {
		"action": "post_detach_resolution",
		"actions": actions,
		"messages": messages,
		"victory_point_delta": vp_delta,
		"resource_deltas": resource_deltas,
		"training_respawn_timer": training_respawn_timer,
		"end_battle": end_battle,
		"winner_id": killer_id,
	}


func destroy_economy_intents(context: Dictionary) -> Array:
	var intents: Array = []
	var victim_id := int(context.get("victim_id", 0))
	var killer_id := int(context.get("killer_id", 0))
	var bounty: int = maxi(0, int(context.get("bounty_reward", 0)))
	if bounty > 0 and _valid_player_id(killer_id) and killer_id != victim_id:
		intents.append({
			"kind": "resource_delta",
			"player_id": killer_id,
			"delta": float(bounty),
			"message_key": "crown_bounty",
			"message_value": bounty,
			"duration": 0.72,
		})
	var refund: int = maxi(0, int(context.get("insured_refund", 0)))
	if refund > 0 and _valid_player_id(victim_id):
		intents.append({
			"kind": "resource_delta",
			"player_id": victim_id,
			"delta": float(refund),
			"message_key": "insured_refund",
			"message_value": refund,
			"duration": 0.72,
		})
	var penalty: int = maxi(0, int(context.get("owner_destroy_penalty", 0)))
	if penalty > 0 and _valid_player_id(victim_id):
		var current_resource: float = maxf(0.0, float(context.get("victim_resource", 0.0)))
		var paid: float = minf(current_resource, float(penalty))
		intents.append({
			"kind": "resource_delta",
			"player_id": victim_id,
			"delta": -paid,
			"message_key": "owner_destroy_penalty",
			"message_value": int(paid),
			"duration": 0.72,
		})
	return intents


func pirate_betrayal_intent(context: Dictionary) -> Dictionary:
	if String(context.get("role", "")) != "puppet":
		return {"betray": false, "chance": 0.0}
	var killer_id := int(context.get("killer_id", 0))
	var chance: float = clampf(float(context.get("betrayal_chance", 0.0)), 0.0, 1.0)
	var security: float = clampf(float(context.get("data_security", 1.0)), 0.25, 3.6)
	chance = clampf(chance / security, 0.0, 1.0)
	var roll := float(context.get("betrayal_roll", 1.0))
	var betray: bool = chance > 0.0 and roll <= chance and _valid_player_id(killer_id)
	return {
		"betray": betray,
		"chance": chance,
		"new_owner": killer_id,
		"reason": "BOOTLEG REBOOT",
		"full_restore": true,
	}


func retreat_start_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_valid", true)):
		return {"start": false, "reason": "invalid"}
	if not bool(context.get("retreat_on_defeat", false)):
		return {"start": false, "reason": "disabled"}
	if not bool(context.get("is_mech", false)):
		return {"start": false, "reason": "not_mech"}
	if bool(context.get("already_retreating", false)):
		return {"start": false, "reason": "already_retreating"}
	var owner := int(context.get("owner", 0))
	var role := String(context.get("role", ""))
	var base_rate: float = maxf(1.0, float(context.get("retreat_repair_rate", 5.0)))
	var dock_rate: float = maxf(0.0, float(context.get("dock_rate", 0.0)))
	var max_health: float = maxf(1.0, float(context.get("max_health", 1.0)))
	var repair_time_mult := float(context.get("repair_time_mult", 1.0))
	var repair_time: float = clampf(max_health / maxf(1.0, base_rate + dock_rate) * repair_time_mult, 2.2, 22.0)
	return {
		"start": true,
		"owner": owner,
		"role": role,
		"timer": repair_time,
		"health": 1,
		"active": false,
		"visible": false,
		"meta": {"retreating": true},
		"message_key": "retreat_start",
		"duration": 1.0,
	}


func retreat_repair_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_valid", true)):
		return {"action": "remove", "reason": "unit_invalid"}
	if bool(context.get("has_dock", false)) and not bool(context.get("dock_valid", true)):
		return {"action": "destroy", "reason": "dock_invalid"}
	var next_timer: float = maxf(0.0, float(context.get("timer", 0.0)) - maxf(0.0, float(context.get("delta", 0.0))))
	if next_timer > 0.0:
		return {"action": "update", "timer": next_timer}
	if bool(context.get("restore_available", true)):
		return {"action": "restore", "timer": 0.0}
	return {"action": "retry", "timer": float(context.get("retry_timer", 0.45))}


func escape_pod_spawn_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("unit_valid", true)):
		return {"spawn": false, "reason": "invalid"}
	var owner := int(context.get("owner", 0))
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var carried: int = clampi(int(stats.get("escape_module_slots", 1)), 1, 6)
	var speed: float = maxf(0.22, float(stats.get("escape_speed", 0.95)))
	var ring_length: float = maxf(0.01, float(context.get("ring_length", 1.0)))
	var half_height: float = maxf(0.0, float(context.get("battle_half_height", 0.0)))
	var ring_pos := float(context.get("ring_pos", 0.0))
	var lane := float(context.get("lane", 0.0))
	var facing := float(context.get("facing", 1.0))
	var target_ring := wrapf(ring_pos + float(stats.get("escape_target_ring_delta", 2.8)) * facing, 0.0, ring_length)
	var target_lane: float = clampf(float(stats.get("escape_target_lane", lane)), -half_height, half_height)
	var pod_stats := {
		"role": "puppet",
		"name": "Escape Pod",
		"health": 10 + carried * 5,
		"mass": 2.0 + float(carried),
		"power": 8.0 + speed * 6.0,
		"energy": 4.0,
		"length": 0.18,
		"radius": 0.045 + float(carried) * 0.012,
		"speed": speed,
		"acceleration": 4.4 + speed,
		"drag": 1.6,
		"heat_capacity": 24.0,
		"cooling": 6.0,
		"shape": "drone_core",
		"damage_type": "blunt",
		"material_class": "escape_pod",
		"resistances": {"bullet": 1.1, "chemical": 1.12, "laser": 1.08, "blunt": 1.16, "pierce": 1.08, "tear": 1.1},
		"counter_tiers": {"bullet": 0, "chemical": 0, "laser": 0, "blunt": 0, "pierce": 0, "tear": 0},
		"primary_color": context.get("primary_color", Color.WHITE),
		"accent_color": Color(1.0, 0.88, 0.28, 1.0),
	}
	return {
		"spawn": true,
		"owner": owner,
		"role": "puppet",
		"stats": pod_stats,
		"name": "P%d ESCAPE POD" % owner,
		"ring_pos": ring_pos,
		"lane": lane,
		"meta": {
			"escape_pod": true,
			"carried_modules": carried,
			"escape_speed": speed,
			"escape_target_ring": target_ring,
			"escape_target_lane": target_lane,
		},
		"message_key": "escape_pod_launch",
		"duration": 0.95,
	}


func escape_pod_tick_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("pod_live", true)):
		return {"action": "skip"}
	var delta_vec: Vector2 = context.get("delta_vec", Vector2.ZERO)
	if delta_vec.length() <= float(context.get("secure_distance", 0.06)):
		return {
			"action": "secure",
			"carried_modules": int(context.get("carried_modules", 0)),
			"message_key": "escape_pod_secured",
			"duration": 0.75,
		}
	var speed: float = maxf(0.12, float(context.get("speed", 1.0)))
	var dir := delta_vec.normalized()
	return {
		"action": "move",
		"velocity": Vector2(dir.x, dir.y * 0.7) * speed,
		"facing": 1 if dir.x >= 0.0 else -1,
		"trail_rate": 5.5,
	}


func fracture_cleanup_intent(context: Dictionary) -> Dictionary:
	var parent_id := String(context.get("parent_id", ""))
	var candidates: Array = Array(context.get("candidates", []))
	var remove_indices: Array = []
	var keep_indices: Array = []
	for i in range(candidates.size()):
		var candidate: Dictionary = Dictionary(candidates[i])
		var remove := bool(candidate.get("valid", false)) \
			and bool(candidate.get("temporary_fracture", false)) \
			and String(candidate.get("fracture_parent_id", "")) == parent_id
		if remove:
			remove_indices.append(i)
		else:
			keep_indices.append(i)
	return {
		"remove_indices": remove_indices,
		"keep_indices": keep_indices,
		"removed_count": remove_indices.size(),
	}


func torso_fracture_brood_intent(context: Dictionary) -> Dictionary:
	var torso_count := int(context.get("torso_count", 0))
	if torso_count < 2:
		return {"action": "none", "spawn_indices": []}
	if not bool(context.get("has_fracture_brood_module", false)):
		return {"action": "none", "spawn_indices": []}
	var torso_index := int(context.get("torso_index", -1))
	if torso_index < 0 or torso_index >= torso_count:
		return {"action": "none", "spawn_indices": []}
	var broken: Dictionary = Dictionary(context.get("broken", {})).duplicate(true)
	var torso_hp: Dictionary = Dictionary(context.get("torso_hp", {})).duplicate(true)
	var anchor: int = clampi(int(context.get("anchor", -1)), 0, torso_count - 1)
	var max_part_hp: float = maxf(0.0, float(context.get("max_part_hp", 0.0)))
	var contact_unit_hp_min: float = maxf(0.0, float(context.get("contact_unit_hp_min", 0.0)))
	var spawn_indices: Array = []
	var target_is_soul_hero: bool = String(context.get("role", "")) == "hero" \
		and bool(context.get("has_soul", false)) \
		and torso_index == anchor
	if target_is_soul_hero:
		broken.erase(str(anchor))
		torso_hp[str(anchor)] = maxf(contact_unit_hp_min, max_part_hp * 0.35)
		for i in range(torso_count):
			if i == anchor:
				continue
			var key := str(i)
			if bool(broken.get(key, false)):
				continue
			broken[key] = true
			spawn_indices.append(i)
	else:
		spawn_indices.append(torso_index)
	return {
		"action": "spawn" if not spawn_indices.is_empty() else ("protect" if target_is_soul_hero else "none"),
		"spawn_indices": spawn_indices,
		"broken": broken,
		"torso_hp": torso_hp,
		"soul_anchor": anchor if target_is_soul_hero else -1,
		"soul_anchor_protected": target_is_soul_hero,
	}


func _valid_player_id(player_id: int) -> bool:
	return player_id == 1 or player_id == 2
