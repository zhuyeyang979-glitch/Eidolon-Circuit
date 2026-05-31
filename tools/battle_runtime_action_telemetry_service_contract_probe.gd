extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const BattleRuntimeActionTelemetryService := preload("res://scripts/services/battle_runtime_action_telemetry_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_runtime_action_telemetry_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleRuntimeActionTelemetryService.")
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
		"queue_free",
		"_spawn_",
		"take_hit",
		"TopologyPoseResolver",
		"FighterScene",
	]:
		if source.contains(forbidden):
			_fail("BattleRuntimeActionTelemetryService contains forbidden token: %s" % forbidden)
			return
	var service := BattleRuntimeActionTelemetryService.new()
	var action_a := {
		"profile": "two_link_forward_snap",
		"phase_label": "startup",
		"timer": 0.3,
		"duration": 0.6,
		"phase": 0.5,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"remaining_ratio": 0.5,
		"startup_ratio": 0.35,
		"pose_t": 0.8,
		"target_t": 0.7,
		"pose_scale": 0.8,
		"variant_key": "balance_string",
		"command_variant": "normal_sweep",
		"runtime_contact_speed": 5.2,
		"joint_actuation_speed": 4.8,
		"soul_echo_refund_applied": true,
		"combo_balance_refund_applied": true,
	}
	var action_b := {
		"profile": "rapier_feint_thrust",
		"phase_label": "recovery",
		"timer": 0.5,
		"duration": 1.0,
		"phase": 0.5,
		"target_nodes": [6],
		"variant_key": "feint_thrust",
		"feint_retarget_allowed": true,
	}
	var telemetry := service.battle_action_telemetry([
		{
			"id": 11,
			"live": true,
			"owner": 1,
			"role": "hero",
			"name": "Left",
			"action_telemetry": {
				"active_count": 1,
				"actions": [action_a],
				"active_module_key": "runtime:1:two_link",
				"active_module_part_index": 4,
				"active_part_state": "normal",
				"active_part_timer": 0.3,
				"active_part_duration": 0.62,
				"earliest_timer": 0.3,
				"latest_phase": 0.52,
				"has_runtime_contact_speed": true,
				"gate_diagnostics": {
					"ready": false,
					"reason": "cooldown",
					"cooldown": 0.4,
					"stagger": 0.0,
					"active_module_key": "runtime:1:two_link",
					"active_module_part_index": 4,
					"same_module_decelerated": true,
					"cancel_ready": false,
					"cancel_phase": 1.0,
					"cancel_power": 0.0,
					"last_gate_reason": "cooldown",
				},
			},
			"command_diagnostics": {
				"ai_kind": "line",
				"source_condition": "default",
				"source_move_kind": "hold",
				"source_attack_preference": "ranged_first",
				"fire_timer": 0.0,
				"sequence_step": 2,
				"sequence_size": 3,
				"movement_mode": "drive",
				"movement_gate_reason": "",
				"role_switch_configured": true,
				"role_switch_target": "hero",
			},
		},
		{
			"id": 12,
			"live": true,
			"owner": 2,
			"role": "puppet",
			"name": "Right",
			"action_telemetry": {
				"active_count": 1,
				"actions": [action_b],
				"active_module_key": "runtime:2:feint",
				"active_module_part_index": 6,
				"earliest_timer": 0.5,
				"latest_phase": 0.8,
				"has_feint_retarget": true,
				"gate_diagnostics": {
					"ready": true,
					"reason": "peak_cancel",
					"cooldown": 0.2,
					"active_module_key": "runtime:2:feint",
					"active_module_part_index": 6,
					"same_module_decelerated": false,
					"cancel_ready": true,
					"cancel_phase": 0.5,
					"cancel_power": 0.9,
					"last_gate_reason": "",
				},
			},
			"command_diagnostics": {
				"ai_kind": "formation_xi",
				"source_condition": "enemy_far",
				"source_move_kind": "kite",
				"fire_timer": 0.35,
				"sequence_step": 1,
				"sequence_size": 2,
				"movement_mode": "brake",
				"movement_gate_reason": "braking",
			},
		},
		{"id": 13, "live": false, "action_telemetry": {"active_count": 1, "actions": [action_a]}},
		"bad",
	])
	if int(telemetry.get("unit_count", 0)) != 2 or int(telemetry.get("active_action_unit_count", 0)) != 2 or int(telemetry.get("active_action_count", 0)) != 2:
		_fail("Battle action telemetry aggregate counts mismatch: %s" % str(telemetry))
		return
	if not bool(telemetry.get("has_runtime_contact_speed", false)) or not bool(telemetry.get("has_feint_retarget", false)):
		_fail("Battle action telemetry aggregate flags mismatch: %s" % str(telemetry))
		return
	var gate_reason_counts: Dictionary = Dictionary(telemetry.get("gate_reason_counts", {}))
	if int(gate_reason_counts.get("cooldown", 0)) != 1 or int(gate_reason_counts.get("peak_cancel", 0)) != 1:
		_fail("Battle action telemetry gate reason counts mismatch: %s" % str(gate_reason_counts))
		return
	if int(telemetry.get("cancel_ready_unit_count", 0)) != 1 or int(telemetry.get("cooldown_blocked_unit_count", 0)) != 1:
		_fail("Battle action telemetry gate aggregate counts mismatch: %s" % str(telemetry))
		return
	var ai_kind_counts: Dictionary = Dictionary(telemetry.get("ai_kind_counts", {}))
	if int(ai_kind_counts.get("line", 0)) != 1 or int(ai_kind_counts.get("formation_xi", 0)) != 1:
		_fail("Battle action telemetry AI kind counts mismatch: %s" % str(ai_kind_counts))
		return
	var source_condition_counts: Dictionary = Dictionary(telemetry.get("source_condition_counts", {}))
	if int(source_condition_counts.get("default", 0)) != 1 or int(source_condition_counts.get("enemy_far", 0)) != 1:
		_fail("Battle action telemetry source condition counts mismatch: %s" % str(source_condition_counts))
		return
	var movement_mode_counts: Dictionary = Dictionary(telemetry.get("movement_mode_counts", {}))
	if int(movement_mode_counts.get("drive", 0)) != 1 or int(movement_mode_counts.get("brake", 0)) != 1:
		_fail("Battle action telemetry movement mode counts mismatch: %s" % str(movement_mode_counts))
		return
	if int(telemetry.get("fire_cooling_unit_count", 0)) != 1 or int(telemetry.get("role_switch_configured_unit_count", 0)) != 1:
		_fail("Battle action telemetry command aggregate counts mismatch: %s" % str(telemetry))
		return
	if absf(float(telemetry.get("earliest_timer", 0.0)) - 0.3) > 0.001 or absf(float(telemetry.get("latest_phase", 0.0)) - 0.8) > 0.001:
		_fail("Battle action telemetry timing mismatch: %s" % str(telemetry))
		return
	var profile_counts: Dictionary = Dictionary(telemetry.get("profile_counts", {}))
	if int(profile_counts.get("two_link_forward_snap", 0)) != 1 or int(profile_counts.get("rapier_feint_thrust", 0)) != 1:
		_fail("Battle action telemetry profile counts mismatch: %s" % str(profile_counts))
		return
	var phase_counts: Dictionary = Dictionary(telemetry.get("phase_label_counts", {}))
	if int(phase_counts.get("startup", 0)) != 1 or int(phase_counts.get("recovery", 0)) != 1:
		_fail("Battle action telemetry phase counts mismatch: %s" % str(phase_counts))
		return
	var diagnostics := service.battle_action_diagnostics_model(telemetry, {"max_units": 3, "max_actions_per_unit": 1})
	if int(diagnostics.get("unit_count", 0)) != 2 or int(diagnostics.get("active_action_count", 0)) != 2:
		_fail("Battle action diagnostics counts mismatch: %s" % str(diagnostics))
		return
	if not bool(diagnostics.get("has_runtime_contact_speed", false)) or not bool(diagnostics.get("has_feint_retarget", false)):
		_fail("Battle action diagnostics flags mismatch: %s" % str(diagnostics))
		return
	var diagnostics_gate_counts: Dictionary = Dictionary(diagnostics.get("gate_reason_counts", {}))
	if int(diagnostics_gate_counts.get("cooldown", 0)) != 1 or int(diagnostics_gate_counts.get("peak_cancel", 0)) != 1:
		_fail("Battle action diagnostics gate reason counts mismatch: %s" % str(diagnostics_gate_counts))
		return
	if int(diagnostics.get("cancel_ready_unit_count", 0)) != 1 or int(diagnostics.get("cooldown_blocked_unit_count", 0)) != 1:
		_fail("Battle action diagnostics gate aggregate mismatch: %s" % str(diagnostics))
		return
	var diagnostic_ai_counts: Dictionary = Dictionary(diagnostics.get("ai_kind_counts", {}))
	if int(diagnostic_ai_counts.get("line", 0)) != 1 or int(diagnostic_ai_counts.get("formation_xi", 0)) != 1:
		_fail("Battle action diagnostics AI counts mismatch: %s" % str(diagnostic_ai_counts))
		return
	if int(diagnostics.get("fire_cooling_unit_count", 0)) != 1 or int(diagnostics.get("role_switch_configured_unit_count", 0)) != 1:
		_fail("Battle action diagnostics command aggregate mismatch: %s" % str(diagnostics))
		return
	var unit_rows: Array = Array(diagnostics.get("unit_rows", []))
	if unit_rows.size() != 2:
		_fail("Battle action diagnostics should keep two live unit rows: %s" % str(unit_rows))
		return
	var first_row: Dictionary = Dictionary(unit_rows[0])
	var first_actions: Array = Array(first_row.get("actions", []))
	if String(first_row.get("name", "")) != "Left" or first_actions.size() != 1 or String(Dictionary(first_actions[0]).get("profile", "")) != "two_link_forward_snap":
		_fail("Battle action diagnostics sorted/action row mismatch: %s" % str(unit_rows))
		return
	var first_gate: Dictionary = Dictionary(first_row.get("gate_diagnostics", {}))
	if String(first_gate.get("reason", "")) != "cooldown" or bool(first_gate.get("ready", true)) or absf(float(first_gate.get("cooldown", 0.0)) - 0.4) > 0.001:
		_fail("Battle action diagnostics gate row mismatch: %s" % str(first_gate))
		return
	var first_command: Dictionary = Dictionary(first_row.get("command_diagnostics", {}))
	if String(first_command.get("ai_kind", "")) != "line" or String(first_command.get("source_condition", "")) != "default":
		_fail("Battle action diagnostics command row mismatch: %s" % str(first_command))
		return
	if String(first_command.get("source_move_kind", "")) != "hold" or String(first_command.get("movement_mode", "")) != "drive":
		_fail("Battle action diagnostics command source/movement mismatch: %s" % str(first_command))
		return
	if int(first_command.get("sequence_step", 0)) != 2 or int(first_command.get("sequence_size", 0)) != 3:
		_fail("Battle action diagnostics command sequence mismatch: %s" % str(first_command))
		return
	if not bool(first_command.get("role_switch_configured", false)) or String(first_command.get("role_switch_target", "")) != "hero":
		_fail("Battle action diagnostics role switch mismatch: %s" % str(first_command))
		return
	var first_action: Dictionary = Dictionary(first_actions[0])
	var diagnostic_nodes: Array = Array(first_action.get("target_nodes", []))
	if int(first_action.get("attack_key", -1)) != 1 or diagnostic_nodes.size() != 2 or int(diagnostic_nodes[0]) != 1 or int(diagnostic_nodes[1]) != 2:
		_fail("Battle action diagnostics enriched identity mismatch: %s" % str(first_action))
		return
	if String(first_action.get("variant_key", "")) != "balance_string" or String(first_action.get("command_variant", "")) != "normal_sweep":
		_fail("Battle action diagnostics enriched variant mismatch: %s" % str(first_action))
		return
	if absf(float(first_action.get("pose_t", 0.0)) - 0.8) > 0.001 or absf(float(first_action.get("target_t", 0.0)) - 0.7) > 0.001:
		_fail("Battle action diagnostics pose scalars mismatch: %s" % str(first_action))
		return
	if absf(float(first_action.get("runtime_contact_speed", 0.0)) - 5.2) > 0.001 or absf(float(first_action.get("joint_actuation_speed", 0.0)) - 4.8) > 0.001:
		_fail("Battle action diagnostics speed scalars mismatch: %s" % str(first_action))
		return
	if not bool(first_action.get("soul_echo_refund_applied", false)) or not bool(first_action.get("combo_balance_refund_applied", false)):
		_fail("Battle action diagnostics refund flags mismatch: %s" % str(first_action))
		return
	var warning_model := service.battle_action_diagnostics_model({
		"unit_count": 2,
		"active_action_unit_count": 2,
		"active_action_count": 2,
		"units": [
			{"live": true, "name": "Broken", "owner": 1, "role": "hero", "active_count": 1, "actions": ["bad"]},
			{"live": true, "name": "Malformed", "owner": 1, "role": "hero", "active_count": 1, "actions": [{
				"profile": "",
				"phase_label": "startup",
				"target_nodes": [1, "bad"],
				"timer": 1.5,
				"duration": 1.0,
				"phase": 0.1,
			}]},
		],
	})
	var warnings: Array = Array(warning_model.get("warnings", []))
	if warnings.is_empty():
		_fail("Battle action diagnostics should report malformed active rows: %s" % str(warning_model))
		return
	for required_warning in [
		"non_dictionary_action:Broken",
		"active_unit_without_action:Broken",
		"empty_profile:Malformed",
		"invalid_target_nodes:Malformed",
		"timer_exceeds_duration:Malformed",
		"phase_timer_mismatch:Malformed",
	]:
		if not warnings.has(required_warning):
			_fail("Battle action diagnostics missing warning %s: %s" % [required_warning, str(warnings)])
			return
	var empty_target_model := service.battle_action_diagnostics_model({
		"unit_count": 1,
		"active_action_unit_count": 1,
		"active_action_count": 1,
		"units": [{"name": "EmptyNodes", "owner": 1, "role": "hero", "active_count": 1, "actions": [{"profile": "ok", "duration": 0.0, "target_nodes": []}]}],
	})
	var empty_target_warnings: Array = Array(empty_target_model.get("warnings", []))
	if not empty_target_warnings.has("empty_target_nodes:EmptyNodes") or not empty_target_warnings.has("non_positive_duration:EmptyNodes"):
		_fail("Battle action diagnostics should warn on empty target nodes and non-positive duration: %s" % str(empty_target_warnings))
		return
	var empty_model := service.battle_action_diagnostics_model({"units": []})
	if int(empty_model.get("active_action_count", 1)) != 0 or not Array(empty_model.get("unit_rows", [])).is_empty():
		_fail("Battle action diagnostics empty model mismatch: %s" % str(empty_model))
		return
	var missing_diagnostics := service.battle_action_telemetry([{"id": 90, "live": true, "action_telemetry": {"actions": []}}])
	if not Dictionary(missing_diagnostics.get("gate_reason_counts", {})).is_empty():
		_fail("Battle action telemetry should not invent gate reason counts for missing diagnostics.")
		return
	if int(missing_diagnostics.get("fire_cooling_unit_count", 1)) != 0 or int(missing_diagnostics.get("role_switch_configured_unit_count", 1)) != 0:
		_fail("Battle action telemetry should not invent command aggregate counts: %s" % str(missing_diagnostics))
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_runtime_action_telemetry_service.gd",
		"BattleRuntimeActionTelemetryService.new",
		"battle_runtime_action_telemetry_service.battle_action_telemetry",
		"battle_action_diagnostics_model",
		"_battle_runtime_action_telemetry_unit_snapshot",
		"_battle_runtime_action_telemetry_snapshot",
		"_battle_command_diagnostics_unit_snapshot",
		"runtime_action_telemetry_snapshot",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleRuntimeActionTelemetryService boundary token: %s" % token)
			return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"unit_name": "Battle Telemetry Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {"health": 100, "mass": 10.0, "ai": "line", "source_rules": {"default": {"move": "hold"}}, "source_attack_preference": "ranged_first", "sequence": ["normal", "armor"], "role_switch": "puppet"},
	})
	fighter.deploy(1.0, 0.0)
	fighter.runtime_module_actions = [{
		"profile": "two_link_forward_snap",
		"state": "normal",
		"attack_key": 1,
		"target_nodes": [1, 2],
		"timer": 0.31,
		"duration": 0.62,
		"startup_ratio": 0.35,
		"runtime_contact_speed": 4.8,
	}]
	fighter.set_meta("source_condition", "default")
	fighter.set_meta("fire_timer", 0.18)
	fighter.set_meta("sequence_step", 1)
	fighter.set_meta("last_move_command_mode", "drive")
	main.all_units = [fighter]
	var main_snapshot := main._battle_runtime_action_telemetry_snapshot()
	if int(main_snapshot.get("unit_count", 0)) != 1 or int(main_snapshot.get("active_action_count", 0)) != 1:
		_fail("main battle runtime action telemetry wrapper mismatch: %s" % str(main_snapshot))
		return
	if not bool(main_snapshot.get("has_runtime_contact_speed", false)):
		_fail("main battle runtime action telemetry should expose contact speed flag: %s" % str(main_snapshot))
		return
	if int(main_snapshot.get("fire_cooling_unit_count", 0)) != 1 or int(main_snapshot.get("role_switch_configured_unit_count", 0)) != 1:
		_fail("main battle runtime action telemetry should expose command diagnostics aggregates: %s" % str(main_snapshot))
		return
	var main_units: Array = Array(main_snapshot.get("units", []))
	var main_command: Dictionary = Dictionary(Dictionary(main_units[0]).get("command_diagnostics", {}))
	if String(main_command.get("ai_kind", "")) != "line" or String(main_command.get("source_move_kind", "")) != "hold" or String(main_command.get("role_switch_target", "")) != "puppet":
		_fail("main battle runtime action telemetry command diagnostics mismatch: %s" % str(main_command))
		return
	print("BATTLE_RUNTIME_ACTION_TELEMETRY_SERVICE_CONTRACT_PROBE ok actions=%d" % int(main_snapshot.get("active_action_count", 0)))
	quit(0)
