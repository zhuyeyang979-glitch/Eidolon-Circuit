extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const FighterActionModel := preload("res://scripts/services/fighter_action_model.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/fighter_action_model.gd")
	if source.is_empty():
		_fail("Unable to read FighterActionModel.")
		return
	for required in [
		"func runtime_action_summary",
		"func runtime_action_telemetry",
		"func runtime_gate_diagnostics",
		"runtime_action_variant_pose_intent",
		"\"active_count\"",
		"\"actions\"",
		"\"gate_diagnostics\"",
		"\"latest_phase\"",
		"\"has_feint_retarget\"",
		"\"has_runtime_contact_speed\"",
	]:
		if not source.contains(required):
			_fail("FighterActionModel missing telemetry token: %s" % required)
			return
	var model := FighterActionModel.new()
	var action := {
		"profile": "rapier_feint_thrust",
		"state": "normal",
		"attack_key": 2,
		"target_nodes": [4, 5],
		"timer": 0.94,
		"duration": 1.0,
		"startup_ratio": 0.25,
		"module_variant_key": "feint_thrust",
		"feint_ghost_phase": 0.5,
		"runtime_contact_speed": 3.2,
		"joint_actuation_speed": 2.8,
		"command_variant": "probe_lunge",
		"soul_echo_refund_applied": true,
		"combo_balance_refund_applied": true,
		"module_variant_hit_confirmed": true,
		"runtime_contact_damage_mult": 1.24,
		"whiff_recovery_mult": 1.25,
	}
	var summary := model.runtime_action_summary(action, 1.0 / 3.0, 7)
	if int(summary.get("index", -1)) != 7 or String(summary.get("profile", "")) != "rapier_feint_thrust" or int(summary.get("attack_key", -1)) != 2:
		_fail("runtime_action_summary identity fields mismatch: %s" % str(summary))
		return
	var target_nodes: Array = Array(summary.get("target_nodes", []))
	if target_nodes.size() != 2 or int(target_nodes[0]) != 4 or int(target_nodes[1]) != 5:
		_fail("runtime_action_summary target nodes mismatch: %s" % str(summary))
		return
	if absf(float(summary.get("phase", 0.0)) - 0.06) > 0.001 or String(summary.get("phase_label", "")) != "startup":
		_fail("runtime_action_summary phase mismatch: %s" % str(summary))
		return
	if absf(float(summary.get("remaining_ratio", 0.0)) - 0.94) > 0.001 or absf(float(summary.get("startup_ratio", 0.0)) - 0.25) > 0.001:
		_fail("runtime_action_summary timing ratios mismatch: %s" % str(summary))
		return
	if float(summary.get("pose_t", 0.0)) <= 0.0 or float(summary.get("target_t", 0.0)) <= 0.0 or float(summary.get("pose_scale", 0.0)) <= 0.0:
		_fail("runtime_action_summary pose scalars missing: %s" % str(summary))
		return
	if not bool(summary.get("feint_ghost_visible", false)) or not bool(summary.get("feint_retarget_allowed", false)):
		_fail("runtime_action_summary should expose feint startup telemetry: %s" % str(summary))
		return
	if String(summary.get("variant_key", "")) != "feint_thrust" or String(summary.get("command_variant", "")) != "probe_lunge":
		_fail("runtime_action_summary variant fields mismatch: %s" % str(summary))
		return
	if absf(float(summary.get("runtime_contact_speed", 0.0)) - 3.2) > 0.001 or absf(float(summary.get("joint_actuation_speed", 0.0)) - 2.8) > 0.001:
		_fail("runtime_action_summary speed fields mismatch: %s" % str(summary))
		return
	if not bool(summary.get("soul_echo_refund_applied", false)) or not bool(summary.get("combo_balance_refund_applied", false)) or not bool(summary.get("module_variant_hit_confirmed", false)):
		_fail("runtime_action_summary refund/hit flags mismatch: %s" % str(summary))
		return
	if absf(float(summary.get("runtime_contact_damage_mult", 0.0)) - 1.24) > 0.001 or absf(float(summary.get("whiff_recovery_mult", 0.0)) - 1.25) > 0.001:
		_fail("runtime_action_summary crush scalar fields mismatch: %s" % str(summary))
		return
	var default_summary := model.runtime_action_summary({"profile": "default_probe"}, 1.0 / 3.0, 0)
	if bool(default_summary.get("soul_echo_refund_applied", true)) or bool(default_summary.get("combo_balance_refund_applied", true)) or bool(default_summary.get("module_variant_hit_confirmed", true)):
		_fail("runtime_action_summary should default read-only flags to false: %s" % str(default_summary))
		return
	if float(default_summary.get("runtime_contact_damage_mult", -1.0)) != 0.0 or float(default_summary.get("whiff_recovery_mult", -1.0)) != 0.0:
		_fail("runtime_action_summary should default optional crush scalars to zero: %s" % str(default_summary))
		return
	var telemetry := model.runtime_action_telemetry([action, "bad"], {
		"active_module_key": "runtime:2:rapier_feint_thrust",
		"active_module_part_index": 1,
		"active_part_state": "normal",
		"active_part_timer": 0.4,
		"active_part_duration": 1.0,
		"gate_diagnostics": {
			"ready": false,
			"reason": "cooldown",
			"cooldown": 0.4,
			"stagger": 0.0,
			"active_module_key": "runtime:2:rapier_feint_thrust",
			"active_module_part_index": 1,
			"same_module_decelerated": false,
			"cancel_ready": true,
			"cancel_phase": 0.5,
			"cancel_power": 0.9,
			"last_gate_reason": "cooldown",
		},
	}, 1.0 / 3.0)
	if int(telemetry.get("active_count", 0)) != 1 or Array(telemetry.get("actions", [])).size() != 1:
		_fail("runtime_action_telemetry should ignore non-dictionary actions: %s" % str(telemetry))
		return
	if not bool(telemetry.get("has_feint_retarget", false)) or not bool(telemetry.get("has_runtime_contact_speed", false)):
		_fail("runtime_action_telemetry aggregate flags mismatch: %s" % str(telemetry))
		return
	var model_gate: Dictionary = Dictionary(telemetry.get("gate_diagnostics", {}))
	if String(model_gate.get("reason", "")) != "cooldown" or not bool(model_gate.get("cancel_ready", false)) or bool(model_gate.get("same_module_decelerated", true)):
		_fail("runtime_action_telemetry should carry gate diagnostics: %s" % str(telemetry))
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"unit_name": "Telemetry Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {"health": 100, "mass": 10.0},
	})
	fighter.deploy(1.0, 0.0)
	fighter.runtime_module_actions = [action.duplicate(true)]
	fighter.active_module_key = "runtime:2:rapier_feint_thrust"
	fighter.active_module_part_index = 1
	fighter.action_cooldown = 0.33
	fighter.melee_stagger_timer = 0.0
	fighter.limb_drive_timers = [0.0, 0.5]
	fighter.limb_drive_durations = [1.0, 1.0]
	fighter.limb_swing_velocities = [0.0, 0.5]
	fighter.limb_linear_velocities = [Vector2.ZERO, Vector2(0.1, 0.0)]
	fighter.set_meta("last_module_gate_reason", "cooldown")
	var fighter_snapshot := fighter.runtime_action_telemetry_snapshot()
	if int(fighter_snapshot.get("active_count", 0)) != 1 or String(fighter_snapshot.get("active_module_key", "")) != "runtime:2:rapier_feint_thrust":
		_fail("Fighter telemetry wrapper mismatch: %s" % str(fighter_snapshot))
		return
	var fighter_gate: Dictionary = Dictionary(fighter_snapshot.get("gate_diagnostics", {}))
	if String(fighter_gate.get("reason", "")) != "peak_cancel" or not bool(fighter_gate.get("ready", false)) or not bool(fighter_gate.get("cancel_ready", false)):
		_fail("Fighter telemetry should expose peak-cancel gate diagnostics: %s" % str(fighter_snapshot))
		return
	if bool(fighter_gate.get("same_module_decelerated", true)) or String(fighter_gate.get("last_gate_reason", "")) != "cooldown":
		_fail("Fighter telemetry should expose same-module and last reason diagnostics: %s" % str(fighter_gate))
		return
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"func runtime_action_telemetry_snapshot",
		"func _runtime_gate_diagnostics_snapshot",
		"_action_model().runtime_action_telemetry",
		"_action_model().runtime_gate_diagnostics",
		"runtime_module_actions",
		"active_module_key",
	]:
		if not fighter_source.contains(token):
			_fail("fighter.gd missing telemetry wrapper token: %s" % token)
			return
	print("FIGHTER_ACTION_TELEMETRY_PROBE ok actions=%d phase=%.3f" % [int(telemetry.get("active_count", 0)), float(summary.get("phase", 0.0))])
	quit(0)
