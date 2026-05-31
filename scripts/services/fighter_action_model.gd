extends RefCounted
class_name FighterActionModel

const STATE_NORMAL := "normal"
const STATE_ARMOR := "armor"
const STATE_ACTIVE := "active"


func state_key_for(action_kind: String) -> String:
	return action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL


func action_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("active", false)) or int(context.get("health", 0)) <= 0:
		return {"allowed": false, "reason": "inactive"}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "stagger"}
	if float(context.get("action_cooldown", 0.0)) > 0.0:
		return {"allowed": false, "reason": "cooldown"}
	return {"allowed": true, "reason": "ready"}


func basic_action_intent(context: Dictionary) -> Dictionary:
	var gate := action_gate_intent(context)
	if not bool(gate.get("allowed", false)):
		return gate
	var stats: Dictionary = Dictionary(context.get("stats", {}))
	var action_kind := String(context.get("action_kind", STATE_NORMAL))
	var role := String(context.get("role", ""))
	var cooldown_mult := 1.45 if bool(context.get("overheated", false)) and role == "hero" else 1.0
	var owner_id := int(context.get("owner_id", 0))
	var source_name := String(context.get("source_name", ""))
	if action_kind == STATE_ARMOR:
		var armor_duration := float(stats.get("armor_duration", 0.48))
		var armor_cooldown := float(stats.get("armor_cooldown", 0.34)) * cooldown_mult
		return {
			"allowed": true,
			"current_state": STATE_ARMOR,
			"state_timer": armor_duration,
			"action_cooldown": armor_cooldown,
			"message": "%s armored" % source_name,
			"event": {
				"owner_id": owner_id,
				"state": STATE_ARMOR,
				"damage": int(stats.get("armor_damage", 7)),
				"range": float(stats.get("armor_range", 0.24)),
				"lane_range": float(stats.get("armor_lane_range", 0.2)),
				"knock": float(stats.get("armor_knock", 0.05)),
				"damage_type": String(stats.get("damage_type", "blunt")),
				"material_class": String(stats.get("material_class", "weapon")),
				"recoil": float(stats.get("recoil", 0.05)),
				"source_name": source_name,
			},
		}
	var attack_state := STATE_ACTIVE if action_kind == STATE_ACTIVE else STATE_NORMAL
	return {
		"allowed": true,
		"current_state": attack_state,
		"state_timer": float(stats.get("%s_duration" % attack_state, 0.22)),
		"action_cooldown": float(stats.get("%s_cooldown" % attack_state, 0.38)) * cooldown_mult,
		"event": {
			"owner_id": owner_id,
			"state": attack_state,
			"damage": int(stats.get("%s_damage" % attack_state, 12)),
			"range": float(stats.get("%s_range" % attack_state, 0.48)),
			"lane_range": float(stats.get("%s_lane_range" % attack_state, 0.28)),
			"knock": float(stats.get("%s_knock" % attack_state, 0.12)),
			"damage_type": String(stats.get("damage_type", "blunt")),
			"material_class": String(stats.get("material_class", "weapon")),
			"recoil": float(stats.get("recoil", 0.06)),
			"source_name": source_name,
		},
	}


func runtime_module_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("has_runtime_topology", false)) or not bool(context.get("active", false)) or int(context.get("health", 0)) <= 0:
		return {"allowed": false, "reason": "inactive"}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "stagger"}
	if float(context.get("action_cooldown", 0.0)) > 0.0:
		return {"allowed": false, "reason": "cooldown"}
	return {"allowed": true, "reason": "ready"}


func module_action_gate_intent(context: Dictionary) -> Dictionary:
	if not bool(context.get("active", false)) or int(context.get("health", 0)) <= 0:
		return {"allowed": false, "reason": "inactive"}
	if float(context.get("melee_stagger_timer", 0.0)) > 0.0:
		return {"allowed": false, "reason": "stagger"}
	var module_key := String(context.get("module_key", ""))
	var action_cooldown := float(context.get("action_cooldown", 0.0))
	var active_module_key := String(context.get("active_module_key", ""))
	if module_key == "":
		return {"allowed": action_cooldown <= 0.0, "reason": "cooldown"}
	if active_module_key == module_key:
		var paired_instant := bool(context.get("allow_same_frame_pair", false)) and float(context.get("now", 0.0)) - float(context.get("active_module_started_at", 0.0)) <= 0.055
		if not paired_instant and not bool(context.get("same_module_decelerated", false)):
			return {"allowed": false, "reason": "same_module_decelerating", "previous_key": active_module_key}
		if action_cooldown > 0.0 and not paired_instant:
			return {"allowed": false, "reason": "same_module_cooldown", "previous_key": active_module_key}
		return {"allowed": true, "reason": "same_module_ready", "previous_key": active_module_key}
	if action_cooldown <= 0.0:
		return {"allowed": true, "reason": "free", "previous_key": active_module_key}
	if bool(context.get("peak_cancel_ready", false)):
		return {
			"allowed": true,
			"cancel": true,
			"reason": "peak_cancel",
			"previous_key": active_module_key,
			"phase": float(context.get("phase", 1.0)),
			"power": float(context.get("power", 0.0)),
		}
	return {"allowed": false, "reason": "cooldown", "previous_key": active_module_key}


func runtime_gate_diagnostics(context: Dictionary) -> Dictionary:
	var cooldown := maxf(0.0, float(context.get("action_cooldown", 0.0)))
	var stagger := maxf(0.0, float(context.get("melee_stagger_timer", 0.0)))
	var active_module_key := String(context.get("active_module_key", ""))
	var same_module_decelerated := bool(context.get("same_module_decelerated", true))
	var cancel_ready := bool(context.get("cancel_ready", false))
	var reason := "ready"
	var ready := true
	if not bool(context.get("active", false)) or int(context.get("health", 0)) <= 0:
		ready = false
		reason = "inactive"
	elif stagger > 0.0:
		ready = false
		reason = "stagger"
	elif cancel_ready:
		reason = "peak_cancel"
	elif cooldown > 0.0:
		ready = false
		reason = "cooldown"
	return {
		"ready": ready,
		"reason": reason,
		"cooldown": cooldown,
		"stagger": stagger,
		"active_module_key": active_module_key,
		"active_module_part_index": int(context.get("active_module_part_index", -1)),
		"same_module_decelerated": same_module_decelerated,
		"cancel_ready": cancel_ready,
		"cancel_phase": clampf(float(context.get("cancel_phase", 1.0)), 0.0, 1.0),
		"cancel_power": maxf(0.0, float(context.get("cancel_power", 0.0))),
		"last_gate_reason": String(context.get("last_gate_reason", "")),
	}


func whole_body_action_state_intent(state_key: String, duration: float) -> Dictionary:
	if state_key in [STATE_ARMOR, STATE_ACTIVE]:
		return {"current_state": state_key, "state_timer": maxf(0.08, duration)}
	return {"current_state": STATE_NORMAL, "state_timer": 0.0}


func runtime_action_duration(action: Dictionary) -> float:
	return maxf(0.001, float(action.get("duration", 0.62)))


func runtime_action_phase(action: Dictionary) -> float:
	var duration := runtime_action_duration(action)
	return clampf(1.0 - float(action.get("timer", 0.0)) / duration, 0.0, 1.0)


func runtime_action_startup_ratio(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0) -> float:
	return clampf(float(action.get("startup_ratio", default_startup_ratio)), 0.05, 0.95)


func runtime_action_phase_label(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0) -> String:
	return "startup" if runtime_action_phase(action) <= runtime_action_startup_ratio(action, default_startup_ratio) else "recovery"


func runtime_action_curve_intent(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0) -> Dictionary:
	var phase := runtime_action_phase(action)
	var startup_ratio := runtime_action_startup_ratio(action, default_startup_ratio)
	var in_startup := phase <= startup_ratio
	var startup_t := 1.0
	var recovery_t := 0.0
	var recovery_cos_t := 1.0
	if in_startup:
		startup_t = sin((phase / maxf(0.001, startup_ratio)) * PI * 0.5)
		recovery_t = 0.0
		recovery_cos_t = 1.0
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		var recovery_phase := clampf((phase - startup_ratio) / recovery_span, 0.0, 1.0)
		startup_t = 1.0
		recovery_t = sin(recovery_phase * PI * 0.5)
		recovery_cos_t = cos(recovery_phase * PI * 0.5)
	var pose_t := startup_t if in_startup else recovery_cos_t
	var target_t := startup_t if in_startup else 1.0 - recovery_t
	return {
		"phase": phase,
		"startup_ratio": startup_ratio,
		"phase_label": "startup" if in_startup else "recovery",
		"in_startup": in_startup,
		"startup_t": clampf(startup_t, 0.0, 1.0),
		"recovery_t": clampf(recovery_t, 0.0, 1.0),
		"recovery_cos_t": clampf(recovery_cos_t, 0.0, 1.0),
		"pose_t": clampf(pose_t, 0.0, 1.0),
		"target_t": clampf(target_t, 0.0, 1.0),
	}


func runtime_action_variant_pose_intent(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0) -> Dictionary:
	var curve := runtime_action_curve_intent(action, default_startup_ratio)
	var phase := float(curve.get("phase", 0.0))
	var startup_ratio := float(curve.get("startup_ratio", default_startup_ratio))
	var pose_t := float(curve.get("pose_t", 0.0))
	var variant_key := String(action.get("module_variant_key", ""))
	var pose_scale := pose_t
	var feint_ghost_visible := false
	var feint_retarget_allowed := false
	if variant_key == "crush_windup":
		pose_scale = pow(pose_t, 1.35)
	elif variant_key == "feint_thrust":
		var ghost_phase := clampf(float(action.get("feint_ghost_phase", 0.42)), 0.12, 0.84)
		feint_ghost_visible = phase <= startup_ratio * ghost_phase
		feint_retarget_allowed = bool(curve.get("in_startup", false))
		pose_scale = pose_t * 0.42 if feint_ghost_visible else pose_t
	curve["variant_key"] = variant_key
	curve["pose_scale"] = clampf(pose_scale, 0.0, 1.0)
	curve["feint_ghost_visible"] = feint_ghost_visible
	curve["feint_retarget_allowed"] = feint_retarget_allowed
	return curve


func runtime_action_recovery_timer(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0) -> float:
	var duration := runtime_action_duration(action)
	return duration * (1.0 - runtime_action_startup_ratio(action, default_startup_ratio))


func tick_runtime_action_intent(action: Dictionary, delta: float) -> Dictionary:
	var updated := action.duplicate(true)
	updated["timer"] = maxf(0.0, float(updated.get("timer", 0.0)) - delta)
	return {
		"action": updated,
		"finished": float(updated.get("timer", 0.0)) <= 0.0,
		"timer": float(updated.get("timer", 0.0)),
		"phase": runtime_action_phase(updated),
	}


func force_runtime_recovery_intent(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0, require_startup: bool = true) -> Dictionary:
	var updated := action.duplicate(true)
	var startup_ratio := runtime_action_startup_ratio(updated, default_startup_ratio)
	if require_startup and runtime_action_phase(updated) >= startup_ratio:
		return {"changed": false, "action": updated, "timer": float(updated.get("timer", runtime_action_duration(updated)))}
	var duration := runtime_action_duration(updated)
	var current_timer := float(updated.get("timer", duration))
	var recovery_timer := duration * (1.0 - startup_ratio)
	var next_timer := minf(current_timer, recovery_timer)
	if absf(next_timer - current_timer) <= 0.000001:
		return {"changed": false, "action": updated, "timer": next_timer}
	updated["timer"] = next_timer
	return {"changed": true, "action": updated, "timer": next_timer, "phase": runtime_action_phase(updated)}


func runtime_action_summary(action: Dictionary, default_startup_ratio: float = 1.0 / 3.0, index: int = -1) -> Dictionary:
	var curve := runtime_action_variant_pose_intent(action, default_startup_ratio)
	var timer := maxf(0.0, float(action.get("timer", 0.0)))
	var duration := runtime_action_duration(action)
	var target_nodes: Array = Array(action.get("target_nodes", []))
	return {
		"index": index,
		"profile": String(action.get("profile", "")),
		"state": String(action.get("state", STATE_NORMAL)),
		"attack_key": int(action.get("attack_key", -1)),
		"target_nodes": target_nodes.duplicate(),
		"timer": timer,
		"duration": duration,
		"remaining_ratio": clampf(timer / duration, 0.0, 1.0),
		"phase": float(curve.get("phase", 0.0)),
		"phase_label": String(curve.get("phase_label", "")),
		"startup_ratio": float(curve.get("startup_ratio", default_startup_ratio)),
		"pose_t": float(curve.get("pose_t", 0.0)),
		"target_t": float(curve.get("target_t", 0.0)),
		"pose_scale": float(curve.get("pose_scale", curve.get("pose_t", 0.0))),
		"variant_key": String(action.get("module_variant_key", "")),
		"command_variant": String(action.get("command_variant", "")),
		"runtime_contact_speed": maxf(0.0, float(action.get("runtime_contact_speed", action.get("joint_actuation_speed", 0.0)))),
		"joint_actuation_speed": maxf(0.0, float(action.get("joint_actuation_speed", 0.0))),
		"feint_ghost_visible": bool(curve.get("feint_ghost_visible", false)),
		"feint_retarget_allowed": bool(curve.get("feint_retarget_allowed", false)),
		"soul_echo_refund_applied": bool(action.get("soul_echo_refund_applied", false)),
		"combo_balance_refund_applied": bool(action.get("combo_balance_refund_applied", false)),
		"module_variant_hit_confirmed": bool(action.get("module_variant_hit_confirmed", false)),
		"runtime_contact_damage_mult": maxf(0.0, float(action.get("runtime_contact_damage_mult", 0.0))),
		"whiff_recovery_mult": maxf(0.0, float(action.get("whiff_recovery_mult", 0.0))),
	}


func runtime_action_telemetry(actions: Array, context: Dictionary = {}, default_startup_ratio: float = 1.0 / 3.0) -> Dictionary:
	var summaries: Array = []
	var active_count := 0
	var earliest_timer := INF
	var latest_phase := 0.0
	var has_feint_retarget := false
	var has_runtime_contact_speed := false
	for i in range(actions.size()):
		if not (actions[i] is Dictionary):
			continue
		var summary := runtime_action_summary(Dictionary(actions[i]), default_startup_ratio, i)
		summaries.append(summary)
		active_count += 1
		earliest_timer = minf(earliest_timer, float(summary.get("timer", 0.0)))
		latest_phase = maxf(latest_phase, float(summary.get("phase", 0.0)))
		has_feint_retarget = has_feint_retarget or bool(summary.get("feint_retarget_allowed", false))
		has_runtime_contact_speed = has_runtime_contact_speed or float(summary.get("runtime_contact_speed", 0.0)) > 0.0
	return {
		"active_count": active_count,
		"actions": summaries,
		"active_module_key": String(context.get("active_module_key", "")),
		"active_module_part_index": int(context.get("active_module_part_index", -1)),
		"active_part_state": String(context.get("active_part_state", STATE_NORMAL)),
		"active_part_timer": maxf(0.0, float(context.get("active_part_timer", 0.0))),
		"active_part_duration": maxf(0.0, float(context.get("active_part_duration", 0.0))),
		"gate_diagnostics": Dictionary(context.get("gate_diagnostics", {})).duplicate(true),
		"earliest_timer": 0.0 if active_count == 0 else earliest_timer,
		"latest_phase": latest_phase,
		"has_feint_retarget": has_feint_retarget,
		"has_runtime_contact_speed": has_runtime_contact_speed,
	}


func cooldown_from_part(module_part: Dictionary, binding: Dictionary, duration: float, fallback_mult: float) -> float:
	return maxf(0.12, float(module_part.get("cooldown", binding.get("cooldown", duration * fallback_mult))))


func two_link_timing_intent(context: Dictionary) -> Dictionary:
	var module_part: Dictionary = Dictionary(context.get("module_part", {}))
	var binding: Dictionary = Dictionary(context.get("binding", {}))
	var motion_budget: Dictionary = Dictionary(context.get("motion_budget", {}))
	var fallback_duration := maxf(0.001, float(context.get("fallback_duration", 0.62)))
	var authored_duration := maxf(0.12, float(module_part.get("runtime_action_duration", module_part.get("duration", fallback_duration))))
	var duration := authored_duration
	var cooldown := cooldown_from_part(module_part, binding, duration, 0.72)
	var startup_ratio := clampf(float(module_part.get("startup_ratio", module_part.get("two_link_straight_phase", float(context.get("default_startup_ratio", 1.0 / 3.0))))), 0.05, 0.95)
	var budget_duration := maxf(0.001, float(motion_budget.get("duration", duration)))
	var contact_distance := maxf(0.0, float(motion_budget.get("contact_speed", 0.0)) * budget_duration)
	var swing_arc_degrees := maxf(0.0, float(context.get("swing_arc_degrees", 180.0)))
	if contact_distance <= 0.001:
		contact_distance = maxf(0.05, float(motion_budget.get("chain_length", 0.0))) * deg_to_rad(swing_arc_degrees)
	var effective_contact_distance := contact_distance * startup_ratio
	var joint_actuation_speed := effective_contact_distance / maxf(0.001, duration)
	return {
		"duration": duration,
		"runtime_action_base_duration": duration,
		"cooldown": cooldown,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"budget_duration": budget_duration,
		"contact_distance": contact_distance,
		"runtime_contact_distance": effective_contact_distance,
		"joint_actuation_speed": joint_actuation_speed,
	}
