extends RefCounted
class_name BattleActorCommandService


func deploy_tick_plan(pending_roles: Array, delta: float) -> Array:
	var plans: Array = []
	for raw_entry in pending_roles:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var timer := float(entry.get("timer", 0.0))
		if timer <= 0.0:
			continue
		var next_timer := timer - delta
		plans.append({
			"player_id": int(entry.get("player_id", 0)),
			"role_key": String(entry.get("role_key", "")),
			"timer_before": timer,
			"timer_after": maxf(0.0, next_timer),
			"update_preview": true,
			"finish": next_timer <= 0.0,
		})
	return plans


func summon_gate_intent(context: Dictionary) -> Dictionary:
	var role_key := String(context.get("role_key", "hero"))
	if role_key == "puppet" and bool(context.get("puppet_group_live", false)):
		return {"accepted": false, "reason": "puppet_online", "illegal_feedback": true}
	if role_key != "puppet" and bool(context.get("existing_live", false)):
		return {"accepted": false, "reason": "already_online", "illegal_feedback": true}
	if bool(context.get("pending", false)):
		return {"accepted": false, "reason": "already_pending", "illegal_feedback": true}
	if bool(context.get("barrier_blocked", false)):
		return {"accepted": false, "reason": "barrier_blocked", "illegal_feedback": true}
	if not bool(context.get("free", false)) and float(context.get("resource", 0.0)) < float(context.get("deploy_cost", 0.0)):
		return {"accepted": false, "reason": "resource_short", "message": true, "illegal_sfx": bool(context.get("alarm", true))}
	return {"accepted": true, "reason": "accepted"}


func auto_summon_intent(context: Dictionary) -> Dictionary:
	if context.has("candidates"):
		for raw_candidate in Array(context.get("candidates", [])):
			if not (raw_candidate is Dictionary):
				continue
			var candidate: Dictionary = raw_candidate
			if not bool(candidate.get("valid", false)):
				continue
			if not bool(candidate.get("role_allowed", false)):
				continue
			if not bool(candidate.get("available", false)):
				continue
			if not bool(candidate.get("affordable", false)):
				continue
			return {
				"found": true,
				"role_key": String(candidate.get("role", "hero")),
				"unit_index": int(candidate.get("index", 0)),
				"candidate": candidate.duplicate(true),
			}
		return {"found": false}

	var auto_timer := maxf(0.0, float(context.get("auto_timer", 0.0)) - float(context.get("delta", 0.0)))
	var idle_timer := maxf(0.0, float(context.get("idle_timer", 0.0)) - float(context.get("delta", 0.0)))
	var intents: Array = []
	if not bool(context.get("has_live_mech", false)) and not bool(context.get("has_pending_mech", false)) and auto_timer <= 0.0:
		intents.append({"reason": "no_mech", "role_filter": ["hero", "puppet"], "reset_timer": "auto"})
	if bool(context.get("hero_live", false)) and bool(context.get("hero_has_soul", false)) and idle_timer <= 0.0:
		var idle_age := float(context.get("now", 0.0)) - float(context.get("last_attack_time", context.get("now", 0.0)))
		if idle_age >= float(context.get("idle_seconds", 10.0)):
			intents.append({"reason": "soul_idle", "role_filter": ["puppet"], "reset_timer": "idle", "touch_last_attack_on_success": true})
	return {
		"auto_timer": auto_timer,
		"idle_timer": idle_timer,
		"intents": intents,
	}


func puppet_condition(context: Dictionary) -> String:
	if bool(context.get("uses_heat", false)):
		var heat_capacity := maxf(1.0, float(context.get("heat_capacity", 100.0)))
		if bool(context.get("overheated", false)) or float(context.get("heat", 0.0)) >= heat_capacity * 0.78:
			return "self_overheat"
	if not bool(context.get("hero_live", false)):
		return "hero_absent"
	if bool(context.get("target_live", false)) and float(context.get("target_projectile_signal", 0.0)) > 0.0:
		return "enemy_shooting"
	var delta_ring_abs := absf(float(context.get("delta_ring", 0.0)))
	if delta_ring_abs > float(context.get("hold_range", 0.82)) + 0.38:
		return "enemy_far"
	if delta_ring_abs < 0.36 + float(context.get("target_radius", 0.2)) * 0.4:
		return "enemy_close"
	return "default"


func puppet_move_intent(context: Dictionary) -> Dictionary:
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var stats: Dictionary = Dictionary(unit.get("stats", {}))
	var delta := float(context.get("delta", 0.0))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var delta_ring := float(context.get("delta_ring", 0.0))
	var delta_lane := float(context.get("delta_lane", 0.0))
	var target_vec := Vector2(delta_ring, delta_lane)
	var move := target_vec.normalized() if target_vec.length() > 0.01 else Vector2(float(unit.get("facing", 1.0)), 0.0)
	var ai_kind := String(stats.get("ai", "line"))
	var phase := float(unit.get("phase", 0.0)) + delta * (1.8 + float(unit_index) * 0.17)

	if float(context.get("blind_strength", 0.0)) > 0.08:
		var blind_escape: Vector2 = context.get("blind_escape_vector", Vector2.ZERO) if context.get("blind_escape_vector", Vector2.ZERO) is Vector2 else Vector2.ZERO
		return {"move": (blind_escape + Vector2(-signf(delta_ring) * 0.22, 0.0)).limit_length(1.0), "phase": phase, "ai_kind": ai_kind}

	if ai_kind == "drone_cloud":
		var orbit := float(stats.get("orbit_radius", 1.02))
		var angle := phase * 1.55 + TAU * float(unit_index) / maxf(1.0, float(group_size))
		var anchor := _live_or_fallback(Dictionary(context.get("hero", {})), target)
		var desired_ring := wrapf(float(anchor.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
		var desired_lane := clampf(float(anchor.get("lane", 0.0)) + sin(angle) * orbit * 0.72, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		if absf(delta_ring) < float(stats.get("hold_range", 1.2)):
			move += Vector2(signf(delta_ring) * 0.35, clampf(delta_lane * 0.8, -0.5, 0.5))
	elif ai_kind == "figure8":
		move = Vector2(sin(phase), sin(phase * 2.0))
		if absf(delta_ring) > 1.4:
			move.x += signf(delta_ring) * 0.8
	elif ai_kind == "volley":
		move.y = clampf(delta_lane * 1.4, -0.8, 0.8)
		if absf(delta_ring) < float(stats.get("hold_range", 0.9)):
			move.x = -signf(delta_ring) * 0.45
	elif ai_kind == "ranged_pack" or ai_kind == "siege_battery":
		var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.2)))
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		if absf(delta_ring) < keep_range * 0.72:
			move = Vector2(-signf(delta_ring), clampf(-delta_lane * 1.2 + side * 0.34, -1.0, 1.0))
		elif absf(delta_ring) > keep_range * 1.18:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.1 + side * 0.22, -1.0, 1.0))
		else:
			move = Vector2(side * 0.18, clampf(delta_lane * 1.3 + sin(phase + float(unit_index)) * 0.35, -1.0, 1.0))
	elif ai_kind == "execution_swarm":
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		move = Vector2(signf(delta_ring), clampf(delta_lane * 1.75 + side * 0.45, -1.0, 1.0))
		if absf(delta_ring) < 0.48:
			move.x = side * 0.28
	elif ai_kind == "interceptor_screen":
		var own_hero := Dictionary(context.get("hero", {}))
		if _snap_live(own_hero):
			var hero_to_target := _ring_delta(float(own_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
			var screen_offset := (float(unit_index) - float(group_size - 1) * 0.5) * 0.24
			var desired_ring := wrapf(float(own_hero.get("ring", 0.0)) + hero_to_target * 0.38, 0.0, ring_length)
			var desired_lane := clampf(lerpf(float(own_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.46) + screen_offset, -half_height, half_height)
			move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		else:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
	elif ai_kind == "vanguard_cover":
		var guard_anchor := Dictionary(context.get("guard_anchor", {}))
		if _snap_live(guard_anchor):
			var anchor_to_target := _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
			var screen_offset := (float(unit_index) - float(group_size - 1) * 0.5) * 0.2
			var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + anchor_to_target * 0.48, 0.0, ring_length)
			var desired_lane := clampf(lerpf(float(guard_anchor.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.5) + screen_offset, -half_height, half_height)
			move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.6, -1.0, 1.0))
			if absf(delta_ring) < float(stats.get("hold_range", 0.74)):
				move += Vector2(signf(delta_ring) * 0.28, clampf(delta_lane * 0.9, -0.45, 0.45))
		else:
			move = Vector2(signf(delta_ring), clampf(delta_lane * 1.45, -1.0, 1.0))
	elif ai_kind == "guard_orbit":
		var guard_hero := Dictionary(context.get("hero", {}))
		var anchor_ring := float(unit.get("ring", 0.0))
		var anchor_lane := float(unit.get("lane", 0.0))
		if _snap_live(guard_hero):
			var orbit := float(stats.get("orbit_radius", 0.42))
			var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
			anchor_ring = wrapf(float(guard_hero.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
			anchor_lane = clampf(float(guard_hero.get("lane", 0.0)) + sin(angle) * orbit * 0.8, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), anchor_ring, ring_length)), clampf((anchor_lane - float(unit.get("lane", 0.0))) * 2.4, -1.0, 1.0))
		if absf(delta_ring) < 0.72:
			move += Vector2(signf(delta_ring) * 0.45, clampf(delta_lane * 1.2, -0.5, 0.5))
	elif ai_kind == "pincer":
		var side := -1.0 if unit_index % 2 == 0 else 1.0
		var flank := float(stats.get("flank_width", 0.66)) * side
		move = Vector2(signf(delta_ring), clampf((float(target.get("lane", 0.0)) + flank - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
		if absf(delta_ring) < 0.72:
			move.x = -side * 0.35
	elif ai_kind == "screen_wall":
		var screen_hero := Dictionary(context.get("hero", {}))
		var anchor_ring := float(unit.get("ring", 0.0))
		var anchor_lane := float(unit.get("lane", 0.0))
		if _snap_live(screen_hero):
			anchor_ring = wrapf(float(screen_hero.get("ring", 0.0)) + _ring_delta(float(screen_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length) * 0.42, 0.0, ring_length)
			var spread := (float(unit_index) - float(group_size - 1) * 0.5) * 0.28
			anchor_lane = clampf(lerpf(float(screen_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.5) + spread, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), anchor_ring, ring_length)), clampf((anchor_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
	elif ai_kind == "formation_xi":
		var formation_hero := Dictionary(context.get("hero", {}))
		var rows := [-0.72, -0.42, -0.14, 0.14, 0.42, 0.72]
		var columns := [-0.82, -0.46, 0.0, 0.46, 0.82]
		var col := unit_index % columns.size()
		var row := int(floor(float(unit_index) / float(columns.size()))) % rows.size()
		var anchor_ring := float(target.get("ring", 0.0)) - signf(delta_ring) * float(stats.get("hold_range", 1.2))
		var anchor_lane := float(target.get("lane", 0.0))
		if _snap_live(formation_hero):
			anchor_ring = lerpf(float(formation_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), 0.55)
			anchor_lane = float(formation_hero.get("lane", 0.0)) * 0.42 + float(target.get("lane", 0.0)) * 0.58
		var desired_ring := wrapf(anchor_ring + float(columns[col]) * float(stats.get("flank_width", 0.86)), 0.0, ring_length)
		var desired_lane := clampf(anchor_lane + float(rows[row]) * 0.54, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.15, -1.0, 1.0))
		if absf(delta_ring) < 0.44:
			move += Vector2(-signf(delta_ring) * 0.22, clampf(delta_lane * 0.52, -0.4, 0.4))
	elif ai_kind == "mine_dance":
		var orbit := float(stats.get("orbit_radius", 0.62))
		var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
		var desired_ring := wrapf(float(target.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
		var desired_lane := clampf(float(target.get("lane", 0.0)) + sin(angle) * orbit, -half_height, half_height)
		move = Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.1, -1.0, 1.0))

	var source_rule: Dictionary = Dictionary(context.get("source_rule", {}))
	if not source_rule.is_empty():
		move = _source_move_vector(context, phase, String(source_rule.get("move", "approach")))
	return {"move": move.limit_length(1.0), "phase": phase, "ai_kind": ai_kind}


func puppet_attack_intent(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var delta_ring := float(context.get("delta_ring", 0.0))
	var delta_lane := float(context.get("delta_lane", 0.0))
	var ai_kind := String(context.get("ai_kind", "line"))
	if bool(context.get("role_switch", false)) and (not bool(context.get("hero_live", false)) or absf(delta_ring) <= float(context.get("switch_trigger_range", 0.62))):
		return {"action": "role_switch"}
	if float(context.get("jammed_timer", 0.0)) > 0.0:
		return {"action": "set_timer", "fire_timer": 0.28, "reason": "jammed"}
	var unit_index := int(context.get("unit_index", 0))
	var cadence := _puppet_cadence(ai_kind, unit_index)
	var current_fire_timer := float(context.get("fire_timer", cadence))
	if not bool(context.get("has_fire_timer", true)):
		current_fire_timer = cadence
	var fire_timer := maxf(0.0, current_fire_timer - delta)
	if fire_timer > 0.0:
		return {"action": "cooldown", "fire_timer": fire_timer}
	var sequence: Array = Array(context.get("sequence", ["normal"]))
	if sequence.is_empty():
		sequence = ["normal"]
	var default_modules: Array = Array(context.get("default_modules", []))
	var modules: Array = Array(context.get("modules", default_modules))
	if modules.is_empty():
		modules = default_modules
	if modules.is_empty():
		return {"action": "set_timer", "fire_timer": 0.36 + cadence, "reason": "no_modules"}
	var step := int(context.get("sequence_step", 0))
	var action_kind := String(sequence[step % sequence.size()])
	var groups: Array = Array(context.get("groups", []))
	var attack_count := maxi(1, int(context.get("attack_group_count", groups.size())))
	var disabled_modules: Array = Array(context.get("disabled_modules", []))
	var preference := String(context.get("source_attack_preference", ""))
	var attack_index := _source_attack_index_for_step(groups, modules, step, preference, disabled_modules, attack_count)
	var group := _group_by_index(groups, attack_index)
	if _is_disabled(disabled_modules, attack_index):
		return {"action": "advance_step", "sequence_step": step + 1, "fire_timer": 0.36 + cadence, "reason": "disabled"}
	if not _puppet_attack_reaches(group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
		for raw_candidate in modules:
			var candidate_index := clampi(int(raw_candidate), 0, attack_count - 1)
			if _is_disabled(disabled_modules, candidate_index):
				continue
			var candidate_group := _group_by_index(groups, candidate_index)
			if _puppet_attack_reaches(candidate_group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
				attack_index = candidate_index
				group = candidate_group
				break
	if _puppet_attack_reaches(group, action_kind, ai_kind, delta_ring, delta_lane, float(context.get("battle_half_height", 1.0))):
		return {
			"action": "fire",
			"attack_index": attack_index,
			"action_kind": action_kind,
			"sequence_step": step + 1,
			"fire_timer": 0.42 + cadence,
			"cadence": cadence,
			"group": group.duplicate(true),
		}
	return {"action": "none", "fire_timer": fire_timer}


func barrier_logic_intents(context: Dictionary) -> Array:
	var logic := String(context.get("logic", "pulse"))
	var delta := float(context.get("delta", 0.0))
	var pulse_timer := maxf(0.0, float(context.get("pulse_timer", 0.0)) - delta)
	var enemy_inside := bool(context.get("enemy_inside", false))
	match logic:
		"heat_well":
			return [{"action": "heat_well_enemies"}]
		"caustic_field":
			return [{"action": "caustic_field_enemies"}]
		"coolant_veil":
			return [{"action": "coolant_veil_allies"}]
		"drag_net":
			return [{"action": "drag_net_enemies"}]
		"damage_amp":
			return [{"action": "damage_amp_allies", "mult_default": 1.2}]
		"riposte_mirror":
			if enemy_inside and pulse_timer <= 0.0:
				return [{"action": "set_pulse_timer", "timer": float(context.get("pulse_interval", 1.05))}, {"action": "pulse"}]
			return [{"action": "set_pulse_timer", "timer": pulse_timer}]
		"galaxy_castle":
			var intents: Array = [
				{"action": "damage_amp_allies", "mult_default": 1.12},
				{"action": "galaxy_castle_enemies"},
			]
			if pulse_timer <= 0.0:
				intents.append({"action": "set_pulse_timer", "timer": float(context.get("pulse_interval", 0.8))})
				intents.append({"action": "pulse"})
			else:
				intents.append({"action": "set_pulse_timer", "timer": pulse_timer})
			return intents
		"gravity_vector", "structure_only":
			return []
	return [{"action": "pulse"}]


func command_diagnostics(context: Dictionary) -> Dictionary:
	var raw_source_rule = context.get("source_rule", {})
	var source_rule: Dictionary = raw_source_rule if raw_source_rule is Dictionary else {}
	var role_switch_target := String(context.get("role_switch_target", context.get("role_switch", "")))
	return {
		"ai_kind": String(context.get("ai_kind", "")),
		"source_condition": String(context.get("source_condition", "")),
		"source_move_kind": String(context.get("source_move_kind", source_rule.get("move", ""))),
		"source_attack_preference": String(context.get("source_attack_preference", "")),
		"fire_timer": maxf(0.0, float(context.get("fire_timer", 0.0))),
		"sequence_step": maxi(0, int(context.get("sequence_step", 0))),
		"sequence_size": maxi(0, int(context.get("sequence_size", Array(context.get("sequence", [])).size()))),
		"movement_mode": String(context.get("movement_mode", "")),
		"movement_gate_reason": String(context.get("movement_gate_reason", "")),
		"role_switch_configured": bool(context.get("role_switch_configured", role_switch_target != "")),
		"role_switch_target": role_switch_target,
	}


func _source_move_vector(context: Dictionary, phase: float, move_kind: String) -> Vector2:
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var stats: Dictionary = Dictionary(unit.get("stats", {}))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var delta_ring := _ring_delta(float(unit.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
	var delta_lane := float(target.get("lane", 0.0)) - float(unit.get("lane", 0.0))
	match move_kind:
		"retreat":
			return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.4, -1.0, 1.0))
		"kite":
			var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.1)))
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			if absf(delta_ring) < keep_range:
				return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.25 + side * 0.32, -1.0, 1.0))
			return Vector2(side * 0.18, clampf(delta_lane * 1.05 + sin(phase + float(unit_index)) * 0.42, -1.0, 1.0))
		"keep_range":
			var keep_range := float(stats.get("source_keep_range", stats.get("hold_range", 1.2)))
			if absf(delta_ring) < keep_range * 0.74:
				return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.15, -1.0, 1.0))
			if absf(delta_ring) > keep_range * 1.2:
				return Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
			return Vector2(0.0, clampf(delta_lane * 1.45 + sin(phase + float(unit_index)) * 0.32, -1.0, 1.0))
		"screen":
			var own_hero := Dictionary(context.get("hero", {}))
			if _snap_live(own_hero):
				var hero_to_target := _ring_delta(float(own_hero.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
				var spread := (float(unit_index) - float(group_size - 1) * 0.5) * 0.22
				var desired_ring := wrapf(float(own_hero.get("ring", 0.0)) + hero_to_target * 0.38, 0.0, ring_length)
				var desired_lane := clampf(lerpf(float(own_hero.get("lane", 0.0)), float(target.get("lane", 0.0)), 0.46) + spread, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.2, -1.0, 1.0))
		"intercept":
			return _guard_anchor_move(context, 0.56, 0.52, 0.18, 2.7, Vector2(signf(delta_ring), clampf(delta_lane * 1.45, -1.0, 1.0)))
		"cover_group":
			var guard_anchor := Dictionary(context.get("guard_anchor", {}))
			if _snap_live(guard_anchor):
				var orbit := float(stats.get("orbit_radius", 0.46))
				var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
				var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + cos(angle) * orbit + _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length) * 0.22, 0.0, ring_length)
				var desired_lane := clampf(float(guard_anchor.get("lane", 0.0)) + sin(angle) * orbit * 0.8 + (float(target.get("lane", 0.0)) - float(guard_anchor.get("lane", 0.0))) * 0.22, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.3, -1.0, 1.0))
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.1, -1.0, 1.0))
		"cover_retreat":
			var guard_anchor := Dictionary(context.get("guard_anchor", {}))
			if _snap_live(guard_anchor):
				var away_from_target := -signf(_ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length))
				var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + away_from_target * 0.28, 0.0, ring_length)
				var desired_lane := clampf(float(guard_anchor.get("lane", 0.0)) - signf(float(target.get("lane", 0.0)) - float(guard_anchor.get("lane", 0.0))) * 0.22, -half_height, half_height)
				return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
			return Vector2(-signf(delta_ring), clampf(-delta_lane * 1.2, -1.0, 1.0))
		"hunt":
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			return Vector2(signf(delta_ring), clampf(delta_lane * 1.7 + side * 0.38, -1.0, 1.0))
		"hold":
			return Vector2(0.0, clampf(delta_lane * 1.2, -0.7, 0.7))
		"orbit":
			var orbit := float(stats.get("orbit_radius", 0.54))
			var angle := phase + TAU * float(unit_index) / maxf(1.0, float(group_size))
			var desired_ring := wrapf(float(target.get("ring", 0.0)) + cos(angle) * orbit, 0.0, ring_length)
			var desired_lane := clampf(float(target.get("lane", 0.0)) + sin(angle) * orbit, -half_height, half_height)
			return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
		"flank":
			var side := -1.0 if unit_index % 2 == 0 else 1.0
			var lane_goal := clampf(float(target.get("lane", 0.0)) + side * float(stats.get("flank_width", 0.58)), -half_height, half_height)
			return Vector2(signf(delta_ring), clampf((lane_goal - float(unit.get("lane", 0.0))) * 2.0, -1.0, 1.0))
	return Vector2(signf(delta_ring), clampf(delta_lane * 2.0, -1.0, 1.0))


func _guard_anchor_move(context: Dictionary, ring_factor: float, lane_lerp: float, spread_mult: float, lane_gain: float, fallback: Vector2) -> Vector2:
	var guard_anchor := Dictionary(context.get("guard_anchor", {}))
	if not _snap_live(guard_anchor):
		return fallback
	var unit: Dictionary = Dictionary(context.get("unit", {}))
	var target: Dictionary = Dictionary(context.get("target", {}))
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var half_height := maxf(0.001, float(context.get("battle_half_height", 1.0)))
	var unit_index := int(context.get("unit_index", 0))
	var group_size := maxi(1, int(context.get("group_size", 1)))
	var anchor_to_target := _ring_delta(float(guard_anchor.get("ring", 0.0)), float(target.get("ring", 0.0)), ring_length)
	var spread := (float(unit_index) - float(group_size - 1) * 0.5) * spread_mult
	var desired_ring := wrapf(float(guard_anchor.get("ring", 0.0)) + anchor_to_target * ring_factor, 0.0, ring_length)
	var desired_lane := clampf(lerpf(float(guard_anchor.get("lane", 0.0)), float(target.get("lane", 0.0)), lane_lerp) + spread, -half_height, half_height)
	return Vector2(signf(_ring_delta(float(unit.get("ring", 0.0)), desired_ring, ring_length)), clampf((desired_lane - float(unit.get("lane", 0.0))) * lane_gain, -1.0, 1.0))


func _source_attack_index_for_step(groups: Array, modules: Array, step: int, preference: String, disabled_modules: Array, attack_count: int) -> int:
	if modules.is_empty():
		return 0
	var fallback := clampi(int(modules[step % modules.size()]), 0, attack_count - 1)
	if preference == "":
		return fallback
	var ordered: Array = []
	for offset in range(modules.size()):
		ordered.append(clampi(int(modules[(step + offset) % modules.size()]), 0, attack_count - 1))
	if preference in ["ranged_first", "finish_first"]:
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if bool(group.get("projectile", false)) and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	if preference == "melee_first":
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if not bool(group.get("projectile", false)) and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	if preference == "intercept_first":
		for attack_index in ordered:
			var group := _group_by_index(groups, int(attack_index))
			if (String(group.get("damage_type", "blunt")) == "blunt" or String(group.get("skill_state", "")) == "armor") and not _is_disabled(disabled_modules, int(attack_index)):
				return int(attack_index)
	for attack_index in ordered:
		if not _is_disabled(disabled_modules, int(attack_index)):
			return int(attack_index)
	return fallback


func _puppet_attack_reaches(group: Dictionary, action_kind: String, ai_kind: String, delta_ring: float, delta_lane: float, battle_half_height: float) -> bool:
	var reach_by_action: Dictionary = Dictionary(group.get("_reach_by_action", {}))
	var range_limit := float(reach_by_action.get(action_kind, group.get("_ai_reach", 0.0)))
	var lane_limit := 0.38
	if bool(group.get("projectile", false)):
		lane_limit = maxf(lane_limit, battle_half_height * 2.0)
	if ai_kind in ["volley", "mine_dance"]:
		range_limit += 0.42
	if ai_kind == "drone_cloud":
		range_limit += 0.72
		lane_limit += 0.16
	if ai_kind == "screen_wall" and action_kind == "armor":
		lane_limit += 0.24
	return absf(delta_ring) <= range_limit and absf(delta_lane) <= lane_limit


func _group_by_index(groups: Array, attack_index: int) -> Dictionary:
	for raw_group in groups:
		if raw_group is Dictionary:
			var group: Dictionary = raw_group
			if int(group.get("_attack_index", -1)) == attack_index:
				return group
	if attack_index >= 0 and attack_index < groups.size() and groups[attack_index] is Dictionary:
		return Dictionary(groups[attack_index])
	return {"_attack_index": attack_index}


func _is_disabled(disabled_modules: Array, attack_index: int) -> bool:
	return disabled_modules.has(attack_index) or disabled_modules.has(str(attack_index))


func _puppet_cadence(ai_kind: String, unit_index: int) -> float:
	if ai_kind == "volley":
		return 0.18 * float(unit_index)
	if ai_kind == "pincer":
		return 0.08 if unit_index % 2 == 0 else 0.0
	if ai_kind == "mine_dance":
		return 0.32
	return 0.0


func _live_or_fallback(snapshot: Dictionary, fallback: Dictionary) -> Dictionary:
	return snapshot if _snap_live(snapshot) else fallback


func _snap_live(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("live", false))


func _ring_delta(from_value: float, to_value: float, ring_length: float) -> float:
	return fposmod(to_value - from_value + ring_length * 0.5, ring_length) - ring_length * 0.5
