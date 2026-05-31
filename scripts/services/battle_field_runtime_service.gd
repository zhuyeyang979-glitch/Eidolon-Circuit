extends RefCounted
class_name BattleFieldRuntimeService


func lease_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var lease_rate := float(context.get("lease_rate", 0.0))
	if lease_rate <= 0.0:
		return {"action": "none"}
	var owed := lease_rate * delta
	var available := maxf(0.0, float(context.get("resource", 0.0)))
	var paid := minf(available, owed)
	var warn_timer := maxf(0.0, float(context.get("warn_timer", 0.0)) - delta)
	return {
		"action": "lease",
		"owed": owed,
		"paid": paid,
		"resource_after": available - paid,
		"heat_penalty": float(context.get("lease_heat_penalty", 4.0)) * delta if paid < owed else 0.0,
		"warn_timer": 2.4 if warn_timer <= 0.0 else warn_timer,
		"show_warning": warn_timer <= 0.0,
	}


func annuity_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var rate := float(context.get("annuity_rate", 0.0))
	if rate <= 0.0:
		return {"action": "none"}
	var timer := maxf(0.0, float(context.get("timer", 0.0)) - delta)
	return {
		"action": "annuity",
		"resource_gain": rate * delta,
		"timer": 3.0 if timer <= 0.0 else timer,
		"spawn_tick_vfx": timer <= 0.0,
	}


func support_aura_model(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var kind := String(context.get("kind", stats.get("support_kind", "")))
	if kind == "":
		return {"active": false}
	var radius := maxf(0.1, float(stats.get("support_radius", 0.6)))
	if bool(stats.get("is_support_platform", false)):
		radius = maxf(0.1, maxf(float(stats.get("platform_pair_range", 0.0)), float(stats.get("support_radius", 0.0))))
	return {
		"active": true,
		"kind": kind,
		"radius": radius,
		"aura_kind": _support_aura_kind(kind),
		"visual_strength": _support_visual_strength(kind, stats),
	}


func support_target_intent(context: Dictionary) -> Dictionary:
	var kind := String(context.get("kind", ""))
	if kind == "":
		return {"action": "none", "can_affect": false}
	var target_role := String(context.get("target_role", ""))
	var target_is_mech := bool(context.get("target_is_mech", false))
	var can_affect := target_role in ["hero", "puppet", "barrier"] if kind in ["ammo", "repair", "cooling", "damage_buff", "armor"] else target_is_mech
	if context.has("check_only"):
		return {"action": "check", "can_affect": can_affect}
	if not can_affect:
		return {"action": "none", "can_affect": false}
	var stats := _dict(context.get("stats", {}))
	var delta := float(context.get("delta", 0.0))
	match kind:
		"ammo":
			var ammo_type := String(stats.get("support_ammo_type", "bullet"))
			var progress := float(context.get("progress", 0.0)) + delta
			var needed := maxf(0.1, float(stats.get("support_refill_seconds", 1.0)))
			return {
				"action": "ammo",
				"can_affect": true,
				"ammo_type": ammo_type,
				"amount": maxi(1, int(stats.get("support_amount", 1))),
				"progress": 0.0 if progress >= needed else progress,
				"ready": progress >= needed,
			}
		"repair":
			var missing := maxf(0.0, float(context.get("target_max_health", 0.0)) - float(context.get("target_health", 0.0)))
			return {
				"action": "repair",
				"can_affect": true,
				"amount": mini(int(ceilf(float(stats.get("support_rate", 8.0)) * delta)), int(ceilf(missing))),
				"vfx_rate": 1.8,
			}
		"cooling":
			return {
				"action": "cooling",
				"can_affect": true,
				"heat_delta": float(stats.get("support_rate", stats.get("coolant_boost", 16.0))) * delta,
				"clear_ratio": float(context.get("overheat_clear_ratio", 0.42)),
			}
		"damage_buff":
			return {
				"action": "damage_buff",
				"can_affect": true,
				"damage_type": String(stats.get("support_buff_type", "tear")),
				"mult": maxf(1.0, float(stats.get("support_buff_mult", 1.12))),
				"timer": maxf(0.12, float(stats.get("support_duration", 0.28))),
			}
		"armor":
			return {
				"action": "armor",
				"can_affect": true,
				"timer": 0.18,
				"armor_hp": maxf(1.0, float(stats.get("platform_armor_hp", 16.0))),
			}
	return {"action": "none", "can_affect": can_affect}


func speed_lane_intent(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var delta := float(context.get("delta", 0.0))
	var velocity: Vector2 = context.get("velocity", Vector2.ZERO) if context.get("velocity", Vector2.ZERO) is Vector2 else Vector2.ZERO
	var base_mult := float(stats.get("speed_lane_mult", 1.5))
	var affinity := float(context.get("speed_lane_affinity", 0.0))
	var mult := clampf(base_mult + affinity, 1.0, 3.5)
	var pull := maxf(0.02, float(stats.get("speed_lane_pull", 0.32)))
	var dir_sign := float(context.get("facing", 1.0))
	if bool(stats.get("speed_lane_bidirectional", true)) and absf(velocity.x) > 0.03:
		dir_sign = signf(velocity.x)
	if dir_sign == 0.0:
		dir_sign = 1.0
	var unit_speed := maxf(0.12, float(context.get("unit_speed", 0.8)))
	var base_speed := maxf(absf(velocity.x), unit_speed * 0.55)
	var desired := clampf(base_speed * mult, 0.0, unit_speed * mult + 1.2)
	return {
		"velocity": Vector2(
			move_toward(velocity.x, dir_sign * desired, (pull + desired) * delta * 2.2),
			move_toward(velocity.y, 0.0, pull * delta * 0.45)
		),
		"timer": 0.18,
		"mult": mult,
		"vfx_rate": 3.5,
	}


func coin_generator_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var interval := maxf(0.6, float(context.get("interval", 6.0)))
	var timer := maxf(0.0, float(context.get("timer", interval)) - delta)
	if timer > 0.0:
		return {"action": "wait", "timer": timer, "spawn": false}
	return {"action": "spawn", "timer": interval, "spawn": true}


func field_coin_update_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("valid", true)):
		return {"action": "erase", "reason": "invalid"}
	if bool(context.get("expired", false)):
		return {"action": "erase", "reason": "expired"}
	if bool(context.get("collector_present", false)):
		return {
			"action": "collect",
			"owner": int(context.get("collector_owner", 0)),
			"value": int(context.get("value", 0)),
			"resource_gain": float(context.get("value", 0)),
		}
	return {"action": "keep"}


func signal_jammer_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var progress := float(context.get("progress", 0.0)) + delta
	var required := maxf(0.001, float(context.get("required", 1.0)))
	var duration := maxf(0.2, float(context.get("duration", 1.2)))
	return {
		"action": "jam",
		"progress": 0.0 if progress >= required else progress,
		"jammed": progress >= required,
		"warning_timer": 0.35,
		"duration": duration,
		"trap_cooldown": duration + 0.6,
	}


func barrier_utility_intents(context: Dictionary) -> Array:
	var stats := _dict(context.get("stats", {}))
	var intents: Array = []
	for entry in [
		["is_gravity_field", "gravity"],
		["is_coolant_field", "coolant"],
		["is_heat_field", "heat"],
		["is_repulsion_field", "repulsion"],
		["is_resource_siphon", "resource_siphon"],
		["is_hack_field", "hack"],
		["is_hatchery", "hatchery"],
		["is_cage_wall", "cage"],
	]:
		if bool(stats.get(String(entry[0]), false)):
			intents.append({"action": String(entry[1])})
	return intents


func field_effect_intent(context: Dictionary) -> Dictionary:
	var kind := String(context.get("kind", ""))
	var stats := _dict(context.get("stats", {}))
	var delta := float(context.get("delta", 0.0))
	match kind:
		"gravity":
			var effect := _dict(context.get("effect", {}))
			var mode := String(effect.get("direction", stats.get("gravity_direction", "forward")))
			var radius := maxf(0.1, float(effect.get("radius", stats.get("gravity_radius", 0.7))))
			var force := float(effect.get("force", stats.get("gravity_force", 0.32)))
			return {"active": true, "kind": kind, "radius": radius, "force": force, "mode": mode, "aura_kind": "gravity_%s" % mode if mode != "" else "gravity", "aura_strength": force * 2.0}
		"coolant":
			var coolant_boost := float(stats.get("coolant_boost", 18.0))
			return {"active": true, "kind": kind, "radius": maxf(0.1, float(stats.get("coolant_radius", 0.68))), "aura_kind": "coolant", "aura_strength": coolant_boost / 18.0, "heat_delta": coolant_boost * delta}
		"heat":
			var heat_rate := float(stats.get("heat_field_rate", 18.0))
			var cooling_factor := clampf(1.18 - float(context.get("target_cooling", 0.0)) / 90.0, 0.42, 1.18)
			return {"active": true, "kind": kind, "radius": maxf(0.1, float(stats.get("heat_field_radius", 0.62))), "aura_kind": "heat", "aura_strength": heat_rate / 18.0, "heat_delta": heat_rate * cooling_factor * delta, "vfx_rate": 1.2}
		"repulsion":
			var repulsion_radius := maxf(0.1, float(stats.get("repulsion_radius", 0.68)))
			var repulsion_force := float(stats.get("repulsion_force", 0.46))
			var dir: Vector2 = context.get("direction", Vector2.ZERO) if context.get("direction", Vector2.ZERO) is Vector2 else Vector2.ZERO
			var fallback: Vector2 = context.get("fallback_direction", Vector2.RIGHT) if context.get("fallback_direction", Vector2.RIGHT) is Vector2 else Vector2.RIGHT
			if dir.length() <= 0.01:
				dir = fallback
			var falloff := clampf(1.0 - dir.length() / maxf(0.1, repulsion_radius * 1.4), 0.18, 1.0)
			return {"active": true, "kind": kind, "radius": repulsion_radius, "aura_kind": "repulsion", "aura_strength": repulsion_force * 2.0, "velocity_delta": Vector2(dir.normalized().x, dir.normalized().y * 0.62) * repulsion_force * falloff * delta}
		"resource_siphon":
			var siphon_rate := float(stats.get("siphon_rate", 60.0))
			var amount := minf(maxf(0.0, float(context.get("enemy_resource", 0.0))), siphon_rate * delta)
			return {"active": true, "kind": kind, "radius": maxf(0.1, float(stats.get("siphon_radius", 0.72))), "aura_kind": "siphon", "aura_strength": siphon_rate / 60.0, "amount": amount, "vfx_rate": 2.0}
		"hack":
			var required := maxf(0.5, float(context.get("required", stats.get("hack_seconds", 4.6))))
			var total := float(context.get("progress", 0.0)) + delta
			return {"active": true, "kind": kind, "radius": maxf(0.1, float(stats.get("hack_radius", 0.68))), "aura_kind": "hack", "aura_strength": required, "progress": 0.0 if total >= required else total, "complete": total >= required, "warning_timer": 0.45, "vfx_rate": 1.6}
		"cage":
			var cage_radius := maxf(0.1, float(stats.get("cage_radius", stats.get("radius", 0.4))))
			var repel := float(stats.get("cage_repel", 0.36))
			var cage_delta: Vector2 = context.get("direction", Vector2.ZERO) if context.get("direction", Vector2.ZERO) is Vector2 else Vector2.ZERO
			var push := Vector2(cage_delta.x, cage_delta.y * 1.2)
			if push.length() <= 0.01:
				push = context.get("fallback_direction", Vector2.RIGHT) if context.get("fallback_direction", Vector2.RIGHT) is Vector2 else Vector2.RIGHT
			var timer := maxf(0.0, float(context.get("hit_timer", 0.0)) - delta)
			return {
				"active": true,
				"kind": kind,
				"radius": cage_radius,
				"aura_kind": "cage",
				"aura_strength": maxf(0.5, repel * 2.0),
				"velocity_delta": Vector2(push.normalized().x, push.normalized().y * 0.62) * repel,
				"hit_timer": maxf(0.12, float(stats.get("cage_hit_interval", 0.6))) if timer <= 0.0 else timer,
				"can_hit": timer <= 0.0,
				"damage": int(stats.get("cage_damage", 0)),
				"damage_type": String(stats.get("cage_damage_type", "blunt")),
			}
	return {"active": false, "kind": kind}


func trap_trigger_intent(context: Dictionary) -> Dictionary:
	if bool(context.get("jammed", false)):
		return {"trigger": false, "reason": "jammed"}
	if float(context.get("cooldown", 0.0)) > 0.0:
		return {"trigger": false, "reason": "cooldown"}
	if not bool(context.get("link_matches", true)):
		return {"trigger": false, "reason": "link"}
	if int(context.get("targets_count", 0)) <= 0:
		return {"trigger": false, "reason": "no_targets"}
	if not bool(context.get("command_matched", false)):
		return {"trigger": false, "reason": "command"}
	return {"trigger": true, "reason": "ready"}


func trap_fire_intents(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var effect := String(context.get("effect", stats.get("trap_effect", "acid_rain")))
	var damage_type := String(stats.get("trap_damage_type", stats.get("damage_type", "chemical")))
	var damage := int(stats.get("trap_damage", 0))
	var power := float(stats.get("trap_power", 0.45))
	var launch_direction: Vector2 = context.get("launch_direction", Vector2.RIGHT) if context.get("launch_direction", Vector2.RIGHT) is Vector2 else Vector2.RIGHT
	var target_intents: Array = []
	var target_deltas: Array = Array(context.get("target_deltas", []))
	for index in range(maxi(0, int(context.get("targets_count", target_deltas.size())))):
		var target_delta: Vector2 = target_deltas[index] if index < target_deltas.size() and target_deltas[index] is Vector2 else Vector2.ZERO
		var actions: Array = []
		match effect:
			"acid_rain":
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "spray"})
				actions.append({"action": "heat", "amount": 10.0, "tags": ["external", "chemical"], "reason": "acid_rain_trap"})
			"heat_burst":
				actions.append({"action": "heat", "amount": power, "tags": ["external"], "reason": "heat_burst_trap"})
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "field"})
			"laser_fan":
				actions.append({"action": "damage", "damage_type": "laser", "damage": maxi(damage, 18), "style": "beam"})
			"gravity_burst":
				actions.append({"action": "velocity", "delta": _directed_velocity(-target_delta, power)})
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "field"})
			"repulse_burst":
				actions.append({"action": "velocity", "delta": _directed_velocity(target_delta, power)})
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "field"})
			"web_snare":
				actions.append({"action": "slow", "timer": float(stats.get("trap_slow_duration", 2.2)), "mult": clampf(1.0 - power, 0.25, 0.82)})
				actions.append({"action": "vfx", "damage_type": "blunt", "style": "web"})
			"spring_launch":
				actions.append({"action": "velocity", "delta": Vector2(launch_direction.x, launch_direction.y * 0.62) * power})
				actions.append({"action": "displace", "offset": Vector2(launch_direction.x * 0.06, launch_direction.y * 0.05) * power})
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "field"})
			_:
				actions.append({"action": "damage", "damage_type": damage_type, "damage": damage, "style": "field"})
		target_intents.append({"target_index": index, "actions": actions})
	return {
		"effect": effect,
		"cooldown": maxf(0.4, float(stats.get("trap_cooldown", 5.0))),
		"radius": maxf(0.1, float(stats.get("trap_radius", 0.7))),
		"power": power,
		"target_intents": target_intents,
	}


func hatchery_intent(context: Dictionary) -> Dictionary:
	var limit := int(context.get("limit", 0))
	if limit <= 0:
		return {"action": "none", "reason": "no_limit"}
	var hatchlings := int(context.get("hatchlings", 0))
	if hatchlings >= limit:
		return {"action": "none", "reason": "limit"}
	var interval := float(context.get("interval", 6.0))
	var timer := maxf(0.0, float(context.get("timer", interval)) - float(context.get("delta", 0.0)))
	if timer > 0.0:
		return {"action": "wait", "timer": timer}
	return {"action": "spawn", "timer": interval, "hatchling_index": hatchlings + 1}


func hatchling_stats_intent(context: Dictionary) -> Dictionary:
	var stats := _dict(context.get("stats", {}))
	var profile := String(stats.get("hatch_profile", "snake"))
	return {
		"name": "Snake Hatchling" if profile == "snake" else "Rifle Bit",
		"role": "puppet",
		"health": 28 if profile == "snake" else 18,
		"mass": 5.0 if profile == "snake" else 2.0,
		"power": 18.0,
		"energy": 8.0,
		"length": 0.46 if profile == "snake" else 0.22,
		"radius": 0.09 if profile == "snake" else 0.045,
		"speed": 0.94 if profile == "snake" else 1.24,
		"acceleration": 3.4,
		"drag": 3.7,
		"cooling": 12.0,
		"heat_capacity": 42.0,
		"normal_damage": 7 if profile == "snake" else 5,
		"normal_range": 0.44 if profile == "snake" else 1.45,
		"normal_lane_range": 0.28,
		"normal_heat": 8.0,
		"damage_type": "tear" if profile == "snake" else "bullet",
		"projectile": profile != "snake",
		"projectile_damage_type": "bullet",
		"projectile_style": "bullet_hell",
		"projectile_behavior": "bullet_hell",
		"projectile_range": 1.75,
		"projectile_speed_mult": 2.4,
		"material_class": "weapon",
		"shape": "snake" if profile == "snake" else "drone_core",
		"ai": String(stats.get("hatch_ai", "figure8")),
		"group_count": 1,
		"sequence": ["normal"],
		"primary_color": context.get("primary_color", Color.WHITE),
		"accent_color": context.get("accent_color", Color.WHITE),
	}


func _support_aura_kind(kind: String) -> String:
	match kind:
		"ammo":
			return "support_ammo"
		"repair":
			return "support_repair"
		"cooling":
			return "coolant"
		"damage_buff":
			return "support_buff"
		"armor":
			return "support_armor"
	return "support"


func _support_visual_strength(kind: String, stats: Dictionary) -> float:
	match kind:
		"ammo":
			return maxf(0.5, float(stats.get("support_amount", 1)) * 0.22)
		"repair":
			return maxf(0.5, float(stats.get("support_rate", 1.0)) / 12.0)
		"cooling":
			return maxf(0.5, float(stats.get("support_rate", stats.get("coolant_boost", 12.0))) / 18.0)
		"damage_buff":
			return maxf(0.5, float(stats.get("support_buff_mult", 1.0)))
		"armor":
			return maxf(0.5, float(stats.get("platform_armor_hp", 0.0)) / 18.0)
	return 1.0


func _directed_velocity(direction: Vector2, power: float) -> Vector2:
	if direction.length() <= 0.01:
		return Vector2.ZERO
	return Vector2(direction.normalized().x, direction.normalized().y * 0.62) * power


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}
