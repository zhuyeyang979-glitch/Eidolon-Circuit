extends RefCounted
class_name BattleHitResolutionService


func attack_entry_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("attacker_live", false)) or bool(context.get("event_empty", false)):
		return {"action": "return", "reason": "invalid"}
	var projectile := bool(context.get("projectile", false))
	if not projectile and bool(context.get("runtime_topology", false)):
		return {"action": "mark_executed_return", "reason": "runtime_topology_melee"}
	if projectile and bool(context.get("explicit_gun_activation", false)) and not bool(context.get("has_gun_source", false)):
		return {"action": "fail_missing_gun_source", "reason": "missing_gun_source"}
	if projectile and not bool(context.get("explicit_gun_activation", false)) and bool(context.get("runtime_topology", false)):
		return {"action": "clear_projectile_mark_return", "reason": "runtime_melee_projectile_fields"}
	return {"action": "continue", "reason": "ok"}


func projectile_preflight_intent(context: Dictionary) -> Dictionary:
	var event := _dict(context.get("event", {})).duplicate(true)
	if not bool(event.get("projectile", false)):
		return {"action": "continue", "event_patch": {}}
	var patch: Dictionary = {}
	var behavior := String(context.get("behavior", event.get("projectile_behavior", "")))
	if behavior == "bullet_hell":
		patch["projectile_behavior"] = "bullet_hell"
		if String(event.get("projectile_style", "bullet")) in ["", "bullet"]:
			patch["projectile_style"] = "bullet_hell"
		patch["projectile_speed_mult"] = float(event.get("projectile_speed_mult", context.get("bullet_hell_default_speed_mult", 2.8)))
	elif behavior == "explosive":
		patch["projectile_behavior"] = "explosive"
		if String(event.get("projectile_style", "")) in ["", "bullet"]:
			patch["projectile_style"] = "explosive"
		var speed_mult := clampf(float(event.get("projectile_speed_mult", 1.6)), 0.45, 2.4)
		patch["projectile_speed_mult"] = speed_mult
		var style := String(patch.get("projectile_style", event.get("projectile_style", "")))
		patch["explosion_radius"] = maxf(float(event.get("explosion_radius", 0.0)), float(context.get("standard_missile_explosion_radius", 0.0)) if style == "missile" else 0.58)
		patch["erase_explosion_damage"] = true
		patch["erase_explosion_damage_type"] = true
		if String(event.get("explosion_style", "")) == "":
			patch["explosion_style"] = style if style != "" else "explosive"
	if bool(context.get("laser_telegraph", false)):
		return {"action": "queue_laser_telegraph", "event_patch": patch}
	if bool(context.get("true_bullet", false)):
		return {"action": "queue_true_bullet", "event_patch": patch}
	if bool(context.get("chemical_projectile", false)):
		if not bool(context.get("chemical_ready", false)):
			return {"action": "queue_chemical", "event_patch": patch}
		if bool(context.get("chemical_firework", false)) and not bool(context.get("chemical_firework_expanded", false)):
			return {"action": "resolve_chemical_firework", "event_patch": patch}
	if bool(context.get("missile_projectile", false)):
		return {"action": "queue_missile", "event_patch": patch}
	return {
		"action": "continue",
		"event_patch": patch,
		"apply_recoil": true,
		"apply_reflection": true,
		"needs_first_impact": bool(context.get("consumes_on_first_hit", false)),
		"spawn_trace": not bool(context.get("projectile_trace_spawned", false)),
	}


func target_hit_context(event: Dictionary, hit: Dictionary, target_snapshot: Dictionary = {}) -> Dictionary:
	var patch := {
		"target_part_index": int(hit.get("part_index", -1)),
		"target_part_kind": String(hit.get("part_kind", "core")),
		"target_part_name": String(hit.get("part_name", "CORE")),
		"target_torso_unit_index": int(hit.get("torso_unit_index", -1)),
		"target_terminal_weapon_kind": String(hit.get("target_terminal_weapon_kind", "")),
		"attacker_part_kind": String(hit.get("attacker_part_kind", event.get("attacker_part_kind", ""))),
		"attacker_terminal_weapon_kind": String(hit.get("attacker_terminal_weapon_kind", event.get("attacker_terminal_weapon_kind", ""))),
		"attacker_runtime_topology": bool(hit.get("attacker_runtime_topology", event.get("attacker_runtime_topology", false))),
		"hit_position_combat": hit.get("position", target_snapshot.get("position", Vector2.ZERO)),
	}
	return {
		"event_patch": patch,
		"damage_type": String(event.get("damage_type", "blunt")),
		"material_class": String(event.get("material_class", "weapon")),
		"non_damage": bool(event.get("non_damage", false)),
		"projectile_style": String(event.get("projectile_style", "")),
		"target_state": String(target_snapshot.get("state", "")),
	}


func momentum_damage_gate_intent(context: Dictionary) -> Dictionary:
	var momentum := maxf(0.0, float(context.get("momentum", 0.0)))
	var raw_momentum := maxf(momentum, float(context.get("raw_momentum", momentum)))
	var damage_coefficient := maxf(0.0, float(context.get("damage_coefficient", context.get("damage_coeff", 1.0))))
	var adjustment_coefficient := maxf(0.0, float(context.get("adjustment_coefficient", context.get("damage_adjustment_coefficient", 1.0))))
	var non_damage := bool(context.get("non_damage", false))
	var damage_value := 0.0
	if not non_damage:
		damage_value = maxf(0.0, float(context.get("precomputed_damage", momentum * damage_coefficient * adjustment_coefficient)))
	var break_value := maxf(0.0, float(context.get("break_value", context.get("break_threshold", 0.0))))
	var break_value_adjustment := maxf(0.0, float(context.get("break_value_adjustment", context.get("break_adjustment_coefficient", 1.0))))
	var effective_break_value := break_value * break_value_adjustment
	var threshold_blocked := false
	if not non_damage and not bool(context.get("skip_break_gate", false)):
		threshold_blocked = damage_value <= effective_break_value
	var knock_adjustment := maxf(0.0, float(context.get("knock_adjustment_coefficient", context.get("knock_adjustment", 1.0))))
	return {
		"formula": "momentum_damage_gate",
		"raw_momentum": raw_momentum,
		"momentum": momentum,
		"capped_momentum": momentum,
		"damage_coefficient": damage_coefficient,
		"adjustment_coefficient": adjustment_coefficient,
		"damage_value": damage_value,
		"damage": int(roundf(damage_value)),
		"break_value": break_value,
		"break_value_adjustment": break_value_adjustment,
		"effective_break_value": effective_break_value,
		"break_gate": effective_break_value,
		"threshold_blocked": threshold_blocked,
		"blocked": threshold_blocked,
		"knock_adjustment_coefficient": knock_adjustment,
		"knock_momentum": momentum * knock_adjustment,
		"non_damage": non_damage,
	}


func melee_type_adjustments(damage_type: String) -> Dictionary:
	var key := damage_type.strip_edges().to_lower()
	match key:
		"tear", "slash":
			return {
				"internal_damage_type": "tear",
				"player_damage_type": "slash",
				"damage_adjustment": 1.5,
				"break_value_adjustment": 1.0,
				"knock_adjustment": 1.0,
			}
		"pierce", "stab":
			return {
				"internal_damage_type": "pierce",
				"player_damage_type": "stab",
				"damage_adjustment": 1.0,
				"break_value_adjustment": 0.5,
				"knock_adjustment": 1.0,
			}
		"blunt":
			return {
				"internal_damage_type": "blunt",
				"player_damage_type": "blunt",
				"damage_adjustment": 1.0,
				"break_value_adjustment": 1.0,
				"knock_adjustment": 2.0,
			}
	return {
		"internal_damage_type": key,
		"player_damage_type": key,
		"damage_adjustment": 1.0,
		"break_value_adjustment": 1.0,
		"knock_adjustment": 1.0,
	}


func combo_scaling_intent(context: Dictionary) -> Dictionary:
	if int(context.get("damage", 0)) <= 0 or not bool(context.get("combo_active", false)):
		return {
			"applies": false,
			"damage": int(context.get("damage", 0)),
			"damage_mult": 1.0,
			"knock_mult": 1.0,
		}
	var total_hits := int(context.get("total_hits", 0)) + 1
	var attacker_hits := int(context.get("attacker_hits", 0)) + 1
	var max_hits := maxi(1, int(context.get("max_hits", 1)))
	var scaled_index := clampi(total_hits, 1, max_hits)
	var damage_mult := _combo_damage_multiplier(
		scaled_index,
		max_hits,
		float(context.get("damage_min_mult", 1.0)),
		float(context.get("damage_curve_power", 1.0))
	)
	var knock_mult := _combo_knock_multiplier(
		scaled_index,
		max_hits,
		float(context.get("knock_max_mult", 1.0)),
		float(context.get("knock_curve_power", 1.0))
	)
	return {
		"applies": true,
		"damage": maxi(1, int(roundf(float(context.get("damage", 0)) * damage_mult))),
		"total_hits": total_hits,
		"attacker_hits": attacker_hits,
		"damage_mult": damage_mult,
		"knock_mult": knock_mult,
		"show_message": total_hits >= 2,
	}


func damage_intent(context: Dictionary) -> Dictionary:
	return damage_stack_intent(context)


func damage_stack_intent(context: Dictionary) -> Dictionary:
	var non_damage := bool(context.get("non_damage", false))
	var nullified := bool(context.get("nullified", false))
	var contact_gate_blocked := bool(context.get("contact_gate_blocked", false))
	var damage := 0
	var raw_damage := float(context.get("raw_damage", 0.0))
	if not bool(context.get("projectile", true)) and raw_damage <= 0.001 and not non_damage:
		return {
			"continue_hit": false,
			"reason": "zero_raw_melee",
			"damage": 0,
			"chemical_dot_total": 0,
			"blocked": false,
			"non_damage": non_damage,
		}
	if not non_damage and not contact_gate_blocked:
		damage = max(1, int(roundf(raw_damage * float(context.get("multiplier", 1.0)))))
		damage = int(context.get("melee_adjusted_damage", damage))
		damage = int(context.get("material_adjusted_damage", damage))
		if bool(context.get("combo_applies", false)):
			damage = int(context.get("combo_damage", damage))
	var chemical_dot_total := 0
	if not non_damage and not nullified and not contact_gate_blocked and bool(context.get("chemical_dot_applies", false)):
		chemical_dot_total = maxi(1, int(roundf(float(damage) * float(context.get("chemical_dot_mult", 1.0)))))
		damage = maxi(1, int(roundf(float(damage) * clampf(float(context.get("chemical_frontload", 0.5)), 0.18, 0.82))))
	return {
		"damage": damage,
		"chemical_dot_total": chemical_dot_total,
		"effect_style": "threshold" if contact_gate_blocked else String(context.get("projectile_style", "")),
		"blocked": contact_gate_blocked,
		"non_damage": non_damage,
		"continue_hit": true,
	}


func part_damage_intent(context: Dictionary) -> Dictionary:
	match String(context.get("mode", "route")):
		"route":
			if not bool(context.get("target_valid", true)) or not bool(context.get("target_mech", false)):
				return {"action": "none", "reason": "invalid_target"}
			if bool(context.get("projectile", false)) or String(context.get("damage_type", "")) != "tear":
				return {"action": "none", "reason": "not_tear_part_damage"}
			var part_kind := String(context.get("part_kind", "core"))
			if part_kind == "torso":
				return {
					"action": "route_torso",
					"torso_index": int(context.get("torso_index", -1)),
				}
			var raw_index := int(context.get("raw_index", -1))
			if raw_index < 0:
				return {"action": "none", "reason": "missing_part_index"}
			var attack_index := clampi(raw_index, 0, maxi(0, int(context.get("attack_group_count", 1)) - 1))
			if part_kind == "terminal":
				return {
					"action": "route_terminal",
					"attack_index": attack_index,
					"part_key": "%d:terminal" % attack_index,
				}
			return {
				"action": "route_limb",
				"attack_index": attack_index,
				"part_key": str(attack_index),
			}
		"hp":
			var max_hp := maxf(0.0, float(context.get("max_hp", 0.0)))
			if max_hp <= 0.0:
				return {"action": "none", "reason": "missing_max_hp"}
			if bool(context.get("already_broken", false)):
				return {"action": "none", "reason": "already_broken"}
			var damage := maxf(1.0, float(context.get("damage", 0.0)) * (1.0 + float(context.get("counter_tier", 0)) * 0.08))
			var current_hp := float(context.get("current_hp", max_hp))
			var next_hp := current_hp - damage
			var kind := String(context.get("part_kind", "limb"))
			var break_flash := 0.55
			var hit_flash := 0.2
			var hit_threshold := 10.0
			match kind:
				"terminal":
					break_flash = 0.48
					hit_flash = 0.18
					hit_threshold = maxf(8.0, max_hp * 0.28)
				"torso":
					break_flash = 0.55
					hit_flash = 0.22
					hit_threshold = maxf(10.0, max_hp * 0.24)
				_:
					break_flash = 0.55
					hit_flash = 0.2
					hit_threshold = maxf(10.0, max_hp * 0.24)
			return {
				"action": "break" if next_hp <= 0.0 else "update",
				"part_kind": kind,
				"part_key": String(context.get("part_key", "")),
				"next_hp": next_hp,
				"damage_to_part": damage,
				"flash_timer": break_flash if next_hp <= 0.0 else (hit_flash if float(context.get("damage", 0.0)) >= hit_threshold else 0.0),
				"fracture": kind == "torso" and next_hp <= 0.0,
			}
	return {"action": "none", "reason": "unknown_mode"}


func melee_pair_impact_position_intent(context: Dictionary) -> Dictionary:
	var a_position: Vector2 = context.get("a_position", Vector2.ZERO) if context.get("a_position", Vector2.ZERO) is Vector2 else Vector2.ZERO
	var ab_delta: Vector2 = context.get("ab_delta", Vector2.ZERO) if context.get("ab_delta", Vector2.ZERO) is Vector2 else Vector2.ZERO
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var b_near_x := a_position.x + ab_delta.x
	return {
		"action": "resolve_melee_pair_impact_position",
		"position": Vector2(wrapf(lerpf(a_position.x, b_near_x, 0.5), 0.0, ring_length), a_position.y + ab_delta.y * 0.5),
	}


func momentum_response_intent(context: Dictionary) -> Dictionary:
	match String(context.get("kind", "")):
		"projectile_stagger":
			if not bool(context.get("projectile", false)) or not bool(context.get("target_mech", false)):
				return {"action": "none", "reason": "invalid_projectile_stagger"}
			if bool(context.get("combo_active", false)):
				return {"action": "none", "reason": "combo_active"}
			var projectile_momentum := float(context.get("projectile_momentum", 0.0))
			var min_momentum := float(context.get("min_momentum", 0.0))
			if projectile_momentum < min_momentum:
				return {"action": "none", "reason": "below_min_momentum"}
			var threshold := maxf(0.0, float(context.get("threshold", 0.0)))
			var gap := projectile_momentum - threshold
			if gap <= 0.0:
				return {"action": "none", "reason": "below_threshold", "gap": gap}
			var now := float(context.get("now", 0.0))
			if now < float(context.get("gate_until", 0.0)):
				return {"action": "none", "reason": "gate_active"}
			var ratio := gap / maxf(float(context.get("threshold_floor", 1.0)), threshold)
			var duration := clampf(
				float(context.get("base_seconds", 0.0)) + ratio * float(context.get("ratio_seconds", 0.0)),
				0.0,
				float(context.get("max_seconds", 0.0))
			)
			if duration <= 0.025:
				return {"action": "none", "reason": "short_duration", "duration": duration}
			var impulse := clampf((projectile_momentum - threshold) * 0.0028, 0.025, 0.42)
			return {
				"action": "apply_projectile_stagger",
				"duration": duration,
				"gap": gap,
				"threshold": threshold,
				"gate_until": now + float(context.get("gate_seconds", 0.0)),
				"impulse": impulse,
				"ripple_scale": clampf(duration / maxf(0.1, float(context.get("max_seconds", 0.0))), 0.75, 1.35),
			}
		"active_melee_stagger":
			if bool(context.get("projectile", false)) or not bool(context.get("attacker_mech", false)) or not bool(context.get("target_mech", false)):
				return {"action": "none", "reason": "invalid_active_melee"}
			if bool(context.get("combo_active", false)):
				return {"action": "none", "reason": "combo_active"}
			return {
				"action": "apply_melee_pair",
				"attacker_momentum": maxf(0.0, float(context.get("attacker_momentum", 0.0))) * maxf(0.1, float(context.get("crush_stagger_mult", 1.0))),
				"target_momentum": maxf(0.0, float(context.get("target_momentum", 0.0))),
				"source": String(context.get("source", "attack")),
			}
		"melee_momentum_stagger_pair":
			if not bool(context.get("unit_a_mech", false)) or not bool(context.get("unit_b_mech", false)):
				return {"action": "none", "reason": "invalid_pair"}
			var momentum_a := float(context.get("momentum_a", 0.0))
			var momentum_b := float(context.get("momentum_b", 0.0))
			var gap := absf(momentum_a - momentum_b)
			var min_momentum := float(context.get("min_momentum", 0.0))
			if gap < min_momentum:
				return {"action": "none", "reason": "below_min_momentum", "gap": gap}
			var staggered_side := "a" if momentum_a < momentum_b else "b"
			if bool(context.get("combo_active", false)):
				return {"action": "none", "reason": "combo_active", "gap": gap, "staggered_side": staggered_side}
			var threshold := float(context.get("threshold", 0.0))
			var required_gap := threshold
			if String(context.get("source", "")) == "collision":
				required_gap = maxf(required_gap, min_momentum * float(context.get("passive_contact_stagger_min_mult", 1.0)))
			if gap <= required_gap:
				return {"action": "none", "reason": "below_required_gap", "gap": gap, "required_gap": required_gap, "staggered_side": staggered_side}
			var now := float(context.get("now", 0.0))
			if now < float(context.get("gate_until", 0.0)):
				return {"action": "none", "reason": "gate_active", "gap": gap, "required_gap": required_gap, "staggered_side": staggered_side}
			var ratio := (gap - required_gap) / maxf(float(context.get("threshold_floor", 1.0)), required_gap)
			var duration := clampf(
				float(context.get("base_seconds", 0.0)) + ratio * float(context.get("ratio_seconds", 0.0)),
				0.0,
				float(context.get("max_seconds", 0.0))
			)
			if duration <= 0.03:
				return {"action": "none", "reason": "short_duration", "duration": duration, "gap": gap, "required_gap": required_gap, "staggered_side": staggered_side}
			return {
				"action": "apply_melee_pair_stagger",
				"staggered_side": staggered_side,
				"source_attacker_side": "b" if staggered_side == "a" else "a",
				"gap": gap,
				"required_gap": required_gap,
				"threshold": threshold,
				"duration": duration,
				"gate_until": now + float(context.get("gate_seconds", 0.0)),
				"max_momentum": maxf(momentum_a, momentum_b),
				"ripple_scale": clampf(duration / maxf(0.1, float(context.get("max_seconds", 0.0))), 0.8, 1.45),
			}
		"hit_displacement_direct":
			var event_momentum := maxf(float(context.get("event_momentum", 0.0)), float(context.get("fallback_momentum", 0.0)))
			var transfer := event_momentum * (0.82 if bool(context.get("projectile", false)) else 0.58)
			transfer *= maxf(0.0, float(context.get("knock_adjustment_coefficient", 1.0)))
			if bool(context.get("nullified", false)):
				transfer *= 0.35
			transfer *= clampf(float(context.get("combo_knock_mult", 1.0)), 1.0, minf(float(context.get("combo_knock_max_mult", 1.0)), 1.65))
			if transfer <= 0.001:
				return {"action": "none", "reason": "no_transfer"}
			return {
				"action": "apply_direct_displacement",
				"direct_transfer": transfer,
				"target_velocity_impulse": transfer / maxf(1.0, float(context.get("target_mass", 1.0))),
				"attacker_velocity_impulse": transfer / maxf(1.0, float(context.get("attacker_mass", 1.0))),
			}
		"hit_displacement_projectile":
			var projectile_push := float(context.get("base_knock", 0.08)) * float(context.get("projectile_space_impulse_mult", 1.0)) * (0.82 if bool(context.get("nullified", false)) else 1.0)
			projectile_push *= maxf(0.0, float(context.get("knock_adjustment_coefficient", 1.0)))
			projectile_push *= 1.0 + clampf(float(context.get("damage_for_knock", 0.0)) / 80.0, 0.0, 0.45)
			projectile_push *= float(context.get("combo_knock_mult", 1.0))
			var target_anchor := clampf(float(context.get("target_anchor", 0.0)), 0.0, 1.0)
			return {
				"action": "apply_projectile_displacement",
				"projectile_push": projectile_push,
				"target_displacement": projectile_push * (1.0 - target_anchor * 0.28),
				"target_velocity_impulse": projectile_push * 1.65 * float(context.get("target_impulse_mult", 1.0)),
			}
		"hit_displacement_melee":
			var attacker_mass := maxf(1.0, float(context.get("attacker_mass", 1.0)))
			var target_mass := maxf(1.0, float(context.get("target_mass", 1.0)))
			var total_mass := attacker_mass + target_mass
			var attacker_share := clampf(target_mass / total_mass, 0.1, 0.9)
			var target_share := clampf(attacker_mass / total_mass, 0.1, 0.9)
			var attacker_anchor := clampf(float(context.get("attacker_anchor", 0.0)), 0.0, 1.0)
			var target_anchor := clampf(float(context.get("target_anchor", 0.0)), 0.0, 1.0)
			var impact_scale := 0.38 if bool(context.get("nullified", false)) else 1.0
			var knock_adjustment := maxf(0.0, float(context.get("knock_adjustment_coefficient", 1.0)))
			var space_impulse := maxf(0.22, float(context.get("base_knock", 0.08)) * 2.8 + float(context.get("damage_for_knock", 0.0)) * 0.006 + float(context.get("part_radius", 0.0)))
			space_impulse *= float(context.get("melee_space_impulse_mult", 1.0)) * knock_adjustment * impact_scale * float(context.get("combo_knock_mult", 1.0))
			var attacker_move := space_impulse * attacker_share * (1.0 - attacker_anchor)
			var target_move := space_impulse * target_share * (1.0 - target_anchor * 0.36)
			return {
				"action": "apply_melee_displacement",
				"space_impulse": space_impulse,
				"attacker_move": attacker_move,
				"target_move": target_move,
				"requested_attacker_velocity_impulse": attacker_move * 2.2 * float(context.get("attacker_impulse_mult", 1.0)),
				"target_velocity_impulse": target_move * 2.55 * float(context.get("target_impulse_mult", 1.0)),
				"attacker_flash": 0.13 + attacker_anchor * 0.1,
				"target_flash": 0.06 + target_anchor * 0.04,
				"target_anchor": target_anchor,
			}
	return {"action": "none", "reason": "unknown_kind"}


func post_hit_intents(context: Dictionary) -> Array:
	var intents: Array = []
	var projectile := bool(context.get("projectile", false))
	var blocked := bool(context.get("blocked", false))
	var non_damage := bool(context.get("non_damage", false))
	var nullified := bool(context.get("nullified", false))
	if blocked:
		intents.append({"action": "projectile_stagger" if projectile else "active_melee_stagger"})
		intents.append({"action": "hit_displacement"})
		intents.append({"action": "hitstop", "damage": 0})
		intents.append({"action": "continue_target"})
		return intents
	intents.append({"action": "module_hit_effect"})
	intents.append({"action": "module_variant_hit_effect"})
	intents.append({"action": "takeover_status"})
	if not nullified and float(context.get("explosion_radius", 0.0)) > 0.0:
		intents.append({"action": "explosion"})
	if non_damage:
		intents.append({"action": "continue_target"})
		return intents
	if bool(context.get("suicide_on_hit", false)):
		intents.append({"action": "suicide"})
		return intents
	if not nullified:
		intents.append({"action": "part_damage"})
	intents.append({"action": "hitstop", "damage": int(context.get("damage", 0))})
	intents.append({"action": "take_hit"})
	if int(context.get("chemical_dot_total", 0)) > 0:
		intents.append({"action": "chemical_dot"})
	if not nullified and bool(context.get("back_hit", false)):
		intents.append({"action": "back_hit_heat"})
	intents.append({"action": "projectile_stagger" if projectile else "active_melee_stagger"})
	intents.append({"action": "hit_displacement"})
	return intents


func status_tick_intent(context: Dictionary) -> Dictionary:
	match String(context.get("kind", "")):
		"apply_chemical_dot":
			var duration := clampf(float(context.get("duration", 1.0)), 0.6, 6.0)
			var total_damage := maxi(0, int(context.get("total_damage", 0)))
			var dps := float(total_damage) / maxf(0.001, duration)
			var current_dps := maxf(0.0, float(context.get("current_dps", 0.0)))
			return {
				"kind": "apply_chemical_dot",
				"duration": duration,
				"dps": maxf(current_dps, dps) if bool(context.get("no_stack", false)) else current_dps + dps,
				"timer": maxf(float(context.get("current_timer", 0.0)), duration),
				"bank": float(context.get("bank", 0.0)),
				"fx_timer": 0.05,
			}
		"chemical_dot":
			var timer := maxf(0.0, float(context.get("timer", 0.0)) - float(context.get("delta", 0.0)))
			if timer <= 0.0:
				return {"kind": "chemical_dot", "active": false, "timer": 0.0, "dps": 0.0, "bank": 0.0}
			var dps_tick := maxf(0.0, float(context.get("dps", 0.0)))
			var bank := float(context.get("bank", 0.0)) + dps_tick * float(context.get("delta", 0.0))
			var damage := 0
			if bank >= 1.0:
				damage = int(floorf(bank))
				bank -= float(damage)
			var fx_timer := maxf(0.0, float(context.get("fx_timer", 0.0)) - float(context.get("delta", 0.0)))
			var spawn_fx := damage > 0 and fx_timer <= 0.0
			return {"kind": "chemical_dot", "active": true, "timer": timer, "dps": dps_tick, "bank": bank, "damage": damage, "fx_timer": 0.24 if spawn_fx else fx_timer, "spawn_fx": spawn_fx}
		"apply_takeover":
			return {
				"kind": "apply_takeover",
				"owner": int(context.get("owner", 0)),
				"required": maxf(0.75, float(context.get("required", 4.0))),
				"dps": maxf(0.0, float(context.get("dps", 0.0))),
				"damage_type": String(context.get("damage_type", "laser")),
				"timer": maxf(float(context.get("current_timer", 0.0)), 0.12),
				"warning_timer": 0.55,
			}
		"takeover":
			var owner := int(context.get("owner", 0))
			if owner == int(context.get("unit_owner", owner)):
				return {"kind": "takeover", "active": false, "timer": 0.0, "reason": "same_owner"}
			var progress := maxf(0.0, float(context.get("timer", 0.0))) + float(context.get("delta", 0.0))
			var takeover_bank := float(context.get("bank", 0.0)) + maxf(0.0, float(context.get("dps", 0.0))) * float(context.get("delta", 0.0))
			var takeover_damage := 0
			if takeover_bank >= 1.0:
				takeover_damage = int(floorf(takeover_bank))
				takeover_bank -= float(takeover_damage)
			return {
				"kind": "takeover",
				"active": true,
				"owner": owner,
				"timer": progress,
				"warning_timer": maxf(float(context.get("warning_timer", 0.0)), 0.12),
				"bank": takeover_bank,
				"damage": takeover_damage,
				"damage_type": String(context.get("damage_type", "laser")),
				"complete": progress >= maxf(0.75, float(context.get("required", 4.0))),
			}
	return {"kind": String(context.get("kind", "")), "active": false}


func _combo_damage_multiplier(hit_index: int, max_hits: int, min_mult: float, curve_power: float) -> float:
	if hit_index <= 1:
		return 1.0
	var t := clampf(float(hit_index - 1) / float(maxi(1, max_hits - 1)), 0.0, 1.0)
	return lerpf(1.0, min_mult, pow(t, curve_power))


func _combo_knock_multiplier(hit_index: int, max_hits: int, max_mult: float, curve_power: float) -> float:
	if hit_index <= 1:
		return 1.0
	var t := clampf(float(hit_index - 1) / float(maxi(1, max_hits - 1)), 0.0, 1.0)
	return lerpf(1.0, max_mult, pow(t, curve_power))


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}
