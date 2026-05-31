extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const FighterActionModel := preload("res://scripts/services/fighter_action_model.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({"unit_name": "ACTION_MODEL", "owner_id": 7, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/fighter_action_model.gd")
	if source.is_empty():
		_fail("Unable to read FighterActionModel.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "queue_free", "_spawn_", "take_hit", "add_heat_event", "Time.get_ticks_msec"]:
		if source.contains(forbidden):
			_fail("FighterActionModel contains forbidden token: %s" % forbidden)
			return
	var model := FighterActionModel.new()
	var blocked := model.action_gate_intent({"active": true, "health": 100, "action_cooldown": 0.2})
	if bool(blocked.get("allowed", true)) or String(blocked.get("reason", "")) != "cooldown":
		_fail("action_gate_intent should block cooldown: %s" % str(blocked))
		return
	var armor := model.basic_action_intent({
		"active": true,
		"health": 100,
		"action_kind": "armor",
		"role": "hero",
		"overheated": true,
		"owner_id": 3,
		"source_name": "Probe",
		"stats": {"armor_duration": 0.5, "armor_cooldown": 0.4, "armor_damage": 9},
	})
	if not bool(armor.get("allowed", false)) or absf(float(armor.get("action_cooldown", 0.0)) - 0.58) > 0.001 or int(Dictionary(armor.get("event", {})).get("damage", 0)) != 9:
		_fail("basic_action_intent armor mismatch: %s" % str(armor))
		return
	var runtime_gate := model.runtime_module_gate_intent({"has_runtime_topology": true, "active": true, "health": 10, "action_cooldown": 0.0})
	if not bool(runtime_gate.get("allowed", false)):
		_fail("runtime_module_gate_intent should allow ready runtime action: %s" % str(runtime_gate))
		return
	var same_module := model.module_action_gate_intent({
		"active": true,
		"health": 10,
		"module_key": "A",
		"active_module_key": "A",
		"action_cooldown": 0.0,
		"same_module_decelerated": false,
		"allow_same_frame_pair": false,
	})
	if bool(same_module.get("allowed", true)) or String(same_module.get("reason", "")) != "same_module_decelerating":
		_fail("module_action_gate_intent should block same-module deceleration: %s" % str(same_module))
		return
	var cancel := model.module_action_gate_intent({
		"active": true,
		"health": 10,
		"module_key": "B",
		"active_module_key": "A",
		"action_cooldown": 0.4,
		"peak_cancel_ready": true,
		"phase": 0.5,
		"power": 0.9,
	})
	if not bool(cancel.get("allowed", false)) or not bool(cancel.get("cancel", false)):
		_fail("module_action_gate_intent should allow peak cancel: %s" % str(cancel))
		return
	var ready_diag := model.runtime_gate_diagnostics({"active": true, "health": 10, "action_cooldown": 0.0})
	if not bool(ready_diag.get("ready", false)) or String(ready_diag.get("reason", "")) != "ready":
		_fail("runtime_gate_diagnostics should report ready state: %s" % str(ready_diag))
		return
	var inactive_diag := model.runtime_gate_diagnostics({"active": false, "health": 10})
	if bool(inactive_diag.get("ready", true)) or String(inactive_diag.get("reason", "")) != "inactive":
		_fail("runtime_gate_diagnostics should report inactive: %s" % str(inactive_diag))
		return
	var stagger_diag := model.runtime_gate_diagnostics({"active": true, "health": 10, "melee_stagger_timer": 0.2})
	if bool(stagger_diag.get("ready", true)) or String(stagger_diag.get("reason", "")) != "stagger":
		_fail("runtime_gate_diagnostics should report stagger: %s" % str(stagger_diag))
		return
	var cooldown_diag := model.runtime_gate_diagnostics({"active": true, "health": 10, "action_cooldown": 0.4, "last_gate_reason": "cooldown"})
	if bool(cooldown_diag.get("ready", true)) or String(cooldown_diag.get("reason", "")) != "cooldown" or absf(float(cooldown_diag.get("cooldown", 0.0)) - 0.4) > 0.001 or String(cooldown_diag.get("last_gate_reason", "")) != "cooldown":
		_fail("runtime_gate_diagnostics should report cooldown and last reason: %s" % str(cooldown_diag))
		return
	var same_module_diag := model.runtime_gate_diagnostics({"active": true, "health": 10, "active_module_key": "A", "active_module_part_index": 2, "same_module_decelerated": false})
	if not bool(same_module_diag.get("ready", false)) or bool(same_module_diag.get("same_module_decelerated", true)) or int(same_module_diag.get("active_module_part_index", -1)) != 2:
		_fail("runtime_gate_diagnostics should expose same-module deceleration facts without blocking generic readiness: %s" % str(same_module_diag))
		return
	var cancel_diag := model.runtime_gate_diagnostics({"active": true, "health": 10, "action_cooldown": 0.4, "cancel_ready": true, "cancel_phase": 0.5, "cancel_power": 0.9})
	if not bool(cancel_diag.get("ready", false)) or String(cancel_diag.get("reason", "")) != "peak_cancel" or not bool(cancel_diag.get("cancel_ready", false)) or absf(float(cancel_diag.get("cancel_phase", 0.0)) - 0.5) > 0.001:
		_fail("runtime_gate_diagnostics should report peak cancel readiness: %s" % str(cancel_diag))
		return
	var body := model.whole_body_action_state_intent("active", 0.02)
	if String(body.get("current_state", "")) != "active" or absf(float(body.get("state_timer", 0.0)) - 0.08) > 0.001:
		_fail("whole_body_action_state_intent should clamp active state timer: %s" % str(body))
		return
	var timing := model.two_link_timing_intent({
		"module_part": {"duration": 0.62, "startup_ratio": 1.0 / 3.0},
		"binding": {},
		"motion_budget": {"duration": 2.25, "contact_speed": 0.9, "chain_length": 1.2},
		"fallback_duration": 0.62,
		"swing_arc_degrees": 180.0,
	})
	if absf(float(timing.get("duration", 0.0)) - 0.62) > 0.001 or absf(float(timing.get("startup_ratio", 0.0)) - (1.0 / 3.0)) > 0.001 or float(timing.get("joint_actuation_speed", 0.0)) <= 0.0:
		_fail("two_link_timing_intent should preserve authored duration/startup and compute speed: %s" % str(timing))
		return
	var phase_action := {"duration": 1.0, "timer": 0.75, "startup_ratio": 0.25}
	if absf(model.runtime_action_phase(phase_action) - 0.25) > 0.001 or model.runtime_action_phase_label(phase_action) != "startup":
		_fail("runtime action phase/startup label mismatch.")
		return
	var startup_curve := model.runtime_action_curve_intent({"duration": 1.0, "timer": 0.875, "startup_ratio": 0.25}, 1.0 / 3.0)
	if not bool(startup_curve.get("in_startup", false)) or absf(float(startup_curve.get("startup_t", 0.0)) - 0.707106) > 0.002 or absf(float(startup_curve.get("pose_t", 0.0)) - float(startup_curve.get("target_t", 0.0))) > 0.001:
		_fail("runtime_action_curve_intent startup scalar mismatch: %s" % str(startup_curve))
		return
	var recovery_curve := model.runtime_action_curve_intent({"duration": 1.0, "timer": 0.375, "startup_ratio": 0.25}, 1.0 / 3.0)
	if bool(recovery_curve.get("in_startup", true)) or absf(float(recovery_curve.get("recovery_t", 0.0)) - 0.707106) > 0.002 or absf(float(recovery_curve.get("target_t", 0.0)) - 0.292893) > 0.002 or absf(float(recovery_curve.get("pose_t", 0.0)) - 0.707106) > 0.002:
		_fail("runtime_action_curve_intent recovery scalar mismatch: %s" % str(recovery_curve))
		return
	var crush_pose := model.runtime_action_variant_pose_intent({"duration": 1.0, "timer": 0.375, "startup_ratio": 0.25, "module_variant_key": "crush_windup"}, 1.0 / 3.0)
	if absf(float(crush_pose.get("pose_scale", 0.0)) - pow(float(crush_pose.get("pose_t", 0.0)), 1.35)) > 0.001:
		_fail("runtime_action_variant_pose_intent crush pose mismatch: %s" % str(crush_pose))
		return
	var feint_pose := model.runtime_action_variant_pose_intent({"duration": 1.0, "timer": 0.94, "startup_ratio": 0.25, "module_variant_key": "feint_thrust", "feint_ghost_phase": 0.5}, 1.0 / 3.0)
	if not bool(feint_pose.get("feint_ghost_visible", false)) or not bool(feint_pose.get("feint_retarget_allowed", false)) or absf(float(feint_pose.get("pose_scale", 0.0)) - float(feint_pose.get("pose_t", 0.0)) * 0.42) > 0.001:
		_fail("runtime_action_variant_pose_intent feint startup mismatch: %s" % str(feint_pose))
		return
	if absf(model.runtime_action_startup_ratio({"startup_ratio": 1.2}, 1.0 / 3.0) - 0.95) > 0.001:
		_fail("runtime_action_startup_ratio should clamp high values.")
		return
	var tick := model.tick_runtime_action_intent({"duration": 0.4, "timer": 0.1}, 0.2)
	if not bool(tick.get("finished", false)) or float(Dictionary(tick.get("action", {})).get("timer", -1.0)) != 0.0:
		_fail("tick_runtime_action_intent should decrement and finish: %s" % str(tick))
		return
	var collision_recovery := model.force_runtime_recovery_intent({"duration": 1.0, "timer": 0.8, "startup_ratio": 0.35}, 1.0 / 3.0, true)
	if not bool(collision_recovery.get("changed", false)) or absf(float(Dictionary(collision_recovery.get("action", {})).get("timer", 0.0)) - 0.65) > 0.001:
		_fail("force_runtime_recovery_intent should enter recovery during startup: %s" % str(collision_recovery))
		return
	var late_collision := model.force_runtime_recovery_intent({"duration": 1.0, "timer": 0.2, "startup_ratio": 0.35}, 1.0 / 3.0, true)
	if bool(late_collision.get("changed", true)):
		_fail("force_runtime_recovery_intent should leave recovery phase unchanged: %s" % str(late_collision))
		return
	var gpu_recovery := model.force_runtime_recovery_intent({"duration": 1.0, "timer": 0.9, "startup_ratio": 0.4}, 1.0 / 3.0, false)
	if not bool(gpu_recovery.get("changed", false)) or absf(float(Dictionary(gpu_recovery.get("action", {})).get("timer", 0.0)) - 0.6) > 0.001:
		_fail("force_runtime_recovery_intent should clamp GPU recovery regardless of phase: %s" % str(gpu_recovery))
		return
	var fighter = _fighter({"normal_duration": 0.25, "normal_cooldown": 0.5, "normal_damage": 13})
	var event: Dictionary = fighter.begin_action("normal")
	if event.is_empty() or int(event.get("damage", 0)) != 13 or absf(float(fighter.action_cooldown) - 0.5) > 0.001:
		_fail("Fighter begin_action should consume action model, event=%s cooldown=%.3f" % [str(event), float(fighter.action_cooldown)])
		return
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"scripts/services/fighter_action_model.gd",
		"FighterActionModel.new",
		"func _action_model()",
		"_action_model().basic_action_intent",
		"_action_model().runtime_module_gate_intent",
		"_action_model().module_action_gate_intent",
		"_action_model().runtime_gate_diagnostics",
		"_action_model().two_link_timing_intent",
		"_action_model().whole_body_action_state_intent",
		"_action_model().runtime_action_phase(action)",
		"_action_model().runtime_action_startup_ratio(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"_action_model().runtime_action_phase_label(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"_action_model().runtime_action_curve_intent(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"_action_model().runtime_action_variant_pose_intent(action, TWO_LINK_DEFAULT_STARTUP_RATIO)",
		"_action_model().tick_runtime_action_intent",
		"_action_model().force_runtime_recovery_intent",
		"post_tick_action",
	]:
		if not fighter_source.contains(token):
			_fail("fighter.gd missing FighterActionModel boundary token: %s" % token)
			return
	print("FIGHTER_ACTION_MODEL_CONTRACT_PROBE ok cooldown=%.2f two_link=%.2f" % [float(fighter.action_cooldown), float(timing.get("duration", 0.0))])
	quit(0)
