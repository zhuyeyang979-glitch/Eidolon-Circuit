extends RefCounted
class_name BattleRuntimeActionTelemetryService


func battle_action_telemetry(unit_snapshots: Array) -> Dictionary:
	var units: Array = []
	var profile_counts: Dictionary = {}
	var phase_label_counts: Dictionary = {}
	var active_action_count := 0
	var active_action_unit_count := 0
	var earliest_timer := INF
	var latest_phase := 0.0
	var has_feint_retarget := false
	var has_runtime_contact_speed := false
	var gate_reason_counts: Dictionary = {}
	var cancel_ready_unit_count := 0
	var cooldown_blocked_unit_count := 0
	var ai_kind_counts: Dictionary = {}
	var source_condition_counts: Dictionary = {}
	var movement_mode_counts: Dictionary = {}
	var fire_cooling_unit_count := 0
	var role_switch_configured_unit_count := 0
	for raw_unit in unit_snapshots:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		if not bool(unit.get("live", false)):
			continue
		var telemetry: Dictionary = Dictionary(unit.get("action_telemetry", {}))
		var gate_diagnostics := _normalized_gate_diagnostics(telemetry.get("gate_diagnostics", {}))
		var command_diagnostics := _normalized_command_diagnostics(unit.get("command_diagnostics", telemetry.get("command_diagnostics", {})))
		var gate_reason := String(gate_diagnostics.get("reason", ""))
		if gate_reason != "":
			gate_reason_counts[gate_reason] = int(gate_reason_counts.get(gate_reason, 0)) + 1
		if bool(gate_diagnostics.get("cancel_ready", false)):
			cancel_ready_unit_count += 1
		if gate_reason == "cooldown":
			cooldown_blocked_unit_count += 1
		var ai_kind := String(command_diagnostics.get("ai_kind", ""))
		if ai_kind != "":
			ai_kind_counts[ai_kind] = int(ai_kind_counts.get(ai_kind, 0)) + 1
		var source_condition := String(command_diagnostics.get("source_condition", ""))
		if source_condition != "":
			source_condition_counts[source_condition] = int(source_condition_counts.get(source_condition, 0)) + 1
		var movement_mode := String(command_diagnostics.get("movement_mode", ""))
		if movement_mode != "":
			movement_mode_counts[movement_mode] = int(movement_mode_counts.get(movement_mode, 0)) + 1
		if float(command_diagnostics.get("fire_timer", 0.0)) > 0.0:
			fire_cooling_unit_count += 1
		if bool(command_diagnostics.get("role_switch_configured", false)):
			role_switch_configured_unit_count += 1
		var actions: Array = Array(telemetry.get("actions", []))
		var active_count: int = max(0, int(telemetry.get("active_count", actions.size())))
		var unit_summary: Dictionary = {
			"id": int(unit.get("id", -1)),
			"owner": int(unit.get("owner", 0)),
			"role": String(unit.get("role", "")),
			"name": String(unit.get("name", "")),
			"active_count": active_count,
			"active_module_key": String(telemetry.get("active_module_key", "")),
			"active_module_part_index": int(telemetry.get("active_module_part_index", -1)),
			"active_part_state": String(telemetry.get("active_part_state", "")),
			"active_part_timer": maxf(0.0, float(telemetry.get("active_part_timer", 0.0))),
			"active_part_duration": maxf(0.0, float(telemetry.get("active_part_duration", 0.0))),
			"earliest_timer": maxf(0.0, float(telemetry.get("earliest_timer", 0.0))),
			"latest_phase": clampf(float(telemetry.get("latest_phase", 0.0)), 0.0, 1.0),
			"has_feint_retarget": bool(telemetry.get("has_feint_retarget", false)),
			"has_runtime_contact_speed": bool(telemetry.get("has_runtime_contact_speed", false)),
			"gate_diagnostics": gate_diagnostics,
			"command_diagnostics": command_diagnostics,
			"actions": actions.duplicate(true),
		}
		units.append(unit_summary)
		if active_count > 0:
			active_action_unit_count += 1
			active_action_count += active_count
			earliest_timer = minf(earliest_timer, float(unit_summary.get("earliest_timer", 0.0)))
			latest_phase = maxf(latest_phase, float(unit_summary.get("latest_phase", 0.0)))
			has_feint_retarget = has_feint_retarget or bool(unit_summary.get("has_feint_retarget", false))
			has_runtime_contact_speed = has_runtime_contact_speed or bool(unit_summary.get("has_runtime_contact_speed", false))
		for raw_action in actions:
			if not (raw_action is Dictionary):
				continue
			var action: Dictionary = raw_action
			var profile: String = String(action.get("profile", ""))
			if profile != "":
				profile_counts[profile] = int(profile_counts.get(profile, 0)) + 1
			var phase_label: String = String(action.get("phase_label", ""))
			if phase_label != "":
				phase_label_counts[phase_label] = int(phase_label_counts.get(phase_label, 0)) + 1
	return {
		"unit_count": units.size(),
		"active_action_unit_count": active_action_unit_count,
		"active_action_count": active_action_count,
		"units": units,
		"profile_counts": profile_counts,
		"phase_label_counts": phase_label_counts,
		"gate_reason_counts": gate_reason_counts,
		"cancel_ready_unit_count": cancel_ready_unit_count,
		"cooldown_blocked_unit_count": cooldown_blocked_unit_count,
		"ai_kind_counts": ai_kind_counts,
		"source_condition_counts": source_condition_counts,
		"movement_mode_counts": movement_mode_counts,
		"fire_cooling_unit_count": fire_cooling_unit_count,
		"role_switch_configured_unit_count": role_switch_configured_unit_count,
		"earliest_timer": 0.0 if active_action_count == 0 else earliest_timer,
		"latest_phase": latest_phase,
		"has_feint_retarget": has_feint_retarget,
		"has_runtime_contact_speed": has_runtime_contact_speed,
	}


func battle_action_diagnostics_model(telemetry: Dictionary, options: Dictionary = {}) -> Dictionary:
	var unit_rows: Array = []
	var warnings: Array = []
	var max_units := maxi(0, int(options.get("max_units", 5)))
	var max_actions_per_unit := maxi(0, int(options.get("max_actions_per_unit", 2)))
	var units: Array = Array(telemetry.get("units", []))
	var sorted_units := _sorted_unit_summaries(units)
	for raw_unit in sorted_units:
		if unit_rows.size() >= max_units:
			break
		if not (raw_unit is Dictionary):
			warnings.append("non_dictionary_unit")
			continue
		var unit: Dictionary = raw_unit
		var actions: Array = Array(unit.get("actions", []))
		var action_rows: Array = []
		var gate_diagnostics := _normalized_gate_diagnostics(unit.get("gate_diagnostics", {}))
		var command_diagnostics := _normalized_command_diagnostics(unit.get("command_diagnostics", {}))
		for raw_action in actions:
			if action_rows.size() >= max_actions_per_unit:
				break
			if not (raw_action is Dictionary):
				warnings.append("non_dictionary_action:%s" % String(unit.get("name", "")))
				continue
			var action: Dictionary = raw_action
			var target_nodes := _diagnostic_target_nodes(action.get("target_nodes", []))
			var profile := String(action.get("profile", ""))
			var timer := maxf(0.0, float(action.get("timer", 0.0)))
			var raw_duration := float(action.get("duration", 0.0))
			var duration := maxf(0.0, raw_duration)
			var phase := clampf(float(action.get("phase", 0.0)), 0.0, 1.0)
			var unit_label := _diagnostic_unit_label(unit)
			if profile == "":
				warnings.append("empty_profile:%s" % unit_label)
			if target_nodes.is_empty():
				warnings.append("empty_target_nodes:%s" % unit_label)
			if _target_nodes_have_invalid_entries(action.get("target_nodes", [])):
				warnings.append("invalid_target_nodes:%s" % unit_label)
			if raw_duration <= 0.0:
				warnings.append("non_positive_duration:%s" % unit_label)
			elif timer > duration + 0.001:
				warnings.append("timer_exceeds_duration:%s" % unit_label)
			if duration > 0.0:
				var expected_phase := clampf(1.0 - timer / maxf(0.001, duration), 0.0, 1.0)
				if absf(expected_phase - phase) > 0.08:
					warnings.append("phase_timer_mismatch:%s" % unit_label)
			action_rows.append({
				"index": int(action.get("index", -1)),
				"profile": profile,
				"state": String(action.get("state", "")),
				"attack_key": int(action.get("attack_key", -1)),
				"target_nodes": target_nodes,
				"phase_label": String(action.get("phase_label", "")),
				"timer": timer,
				"duration": duration,
				"remaining_ratio": clampf(float(action.get("remaining_ratio", 0.0)), 0.0, 1.0),
				"phase": phase,
				"startup_ratio": clampf(float(action.get("startup_ratio", 0.0)), 0.0, 1.0),
				"pose_t": clampf(float(action.get("pose_t", 0.0)), 0.0, 1.0),
				"target_t": clampf(float(action.get("target_t", 0.0)), 0.0, 1.0),
				"pose_scale": clampf(float(action.get("pose_scale", 0.0)), 0.0, 1.0),
				"variant_key": String(action.get("variant_key", action.get("module_variant_key", ""))),
				"command_variant": String(action.get("command_variant", "")),
				"runtime_contact_speed": maxf(0.0, float(action.get("runtime_contact_speed", 0.0))),
				"joint_actuation_speed": maxf(0.0, float(action.get("joint_actuation_speed", 0.0))),
				"feint_ghost_visible": bool(action.get("feint_ghost_visible", false)),
				"feint_retarget_allowed": bool(action.get("feint_retarget_allowed", false)),
				"soul_echo_refund_applied": bool(action.get("soul_echo_refund_applied", false)),
				"combo_balance_refund_applied": bool(action.get("combo_balance_refund_applied", false)),
				"module_variant_hit_confirmed": bool(action.get("module_variant_hit_confirmed", false)),
				"runtime_contact_damage_mult": maxf(0.0, float(action.get("runtime_contact_damage_mult", 0.0))),
				"whiff_recovery_mult": maxf(0.0, float(action.get("whiff_recovery_mult", 0.0))),
			})
		if int(unit.get("active_count", 0)) > 0 and action_rows.is_empty():
			warnings.append("active_unit_without_action:%s" % String(unit.get("name", unit.get("id", ""))))
		unit_rows.append({
			"id": int(unit.get("id", -1)),
			"owner": int(unit.get("owner", 0)),
			"role": String(unit.get("role", "")),
			"name": String(unit.get("name", "")),
			"active_count": maxi(0, int(unit.get("active_count", 0))),
			"active_module_key": String(unit.get("active_module_key", "")),
			"active_part_state": String(unit.get("active_part_state", "")),
			"active_part_timer": maxf(0.0, float(unit.get("active_part_timer", 0.0))),
			"active_part_duration": maxf(0.0, float(unit.get("active_part_duration", 0.0))),
			"gate_diagnostics": gate_diagnostics,
			"command_diagnostics": command_diagnostics,
			"actions": action_rows,
		})
	return {
		"title": String(options.get("title", "BATTLE ACTION DIAGNOSTICS")),
		"unit_count": maxi(0, int(telemetry.get("unit_count", units.size()))),
		"active_action_unit_count": maxi(0, int(telemetry.get("active_action_unit_count", 0))),
		"active_action_count": maxi(0, int(telemetry.get("active_action_count", 0))),
		"profile_counts": Dictionary(telemetry.get("profile_counts", {})).duplicate(true),
		"phase_label_counts": Dictionary(telemetry.get("phase_label_counts", {})).duplicate(true),
		"gate_reason_counts": Dictionary(telemetry.get("gate_reason_counts", {})).duplicate(true),
		"cancel_ready_unit_count": maxi(0, int(telemetry.get("cancel_ready_unit_count", 0))),
		"cooldown_blocked_unit_count": maxi(0, int(telemetry.get("cooldown_blocked_unit_count", 0))),
		"ai_kind_counts": Dictionary(telemetry.get("ai_kind_counts", {})).duplicate(true),
		"source_condition_counts": Dictionary(telemetry.get("source_condition_counts", {})).duplicate(true),
		"movement_mode_counts": Dictionary(telemetry.get("movement_mode_counts", {})).duplicate(true),
		"fire_cooling_unit_count": maxi(0, int(telemetry.get("fire_cooling_unit_count", 0))),
		"role_switch_configured_unit_count": maxi(0, int(telemetry.get("role_switch_configured_unit_count", 0))),
		"earliest_timer": maxf(0.0, float(telemetry.get("earliest_timer", 0.0))),
		"latest_phase": clampf(float(telemetry.get("latest_phase", 0.0)), 0.0, 1.0),
		"has_feint_retarget": bool(telemetry.get("has_feint_retarget", false)),
		"has_runtime_contact_speed": bool(telemetry.get("has_runtime_contact_speed", false)),
		"unit_rows": unit_rows,
		"warnings": warnings,
	}


func _sorted_unit_summaries(units: Array) -> Array:
	var sorted := units.duplicate(true)
	sorted.sort_custom(Callable(self, "_compare_unit_summaries"))
	return sorted


func _compare_unit_summaries(a, b) -> bool:
	var unit_a: Dictionary = a if a is Dictionary else {}
	var unit_b: Dictionary = b if b is Dictionary else {}
	var active_a := int(unit_a.get("active_count", 0))
	var active_b := int(unit_b.get("active_count", 0))
	if active_a != active_b:
		return active_a > active_b
	var owner_a := int(unit_a.get("owner", 0))
	var owner_b := int(unit_b.get("owner", 0))
	if owner_a != owner_b:
		return owner_a < owner_b
	var role_a := String(unit_a.get("role", ""))
	var role_b := String(unit_b.get("role", ""))
	if role_a != role_b:
		return role_a < role_b
	return String(unit_a.get("name", "")) < String(unit_b.get("name", ""))


func _diagnostic_unit_label(unit: Dictionary) -> String:
	var name := String(unit.get("name", ""))
	if name != "":
		return name
	return String(unit.get("id", ""))


func _diagnostic_target_nodes(raw_nodes) -> Array:
	var nodes: Array = []
	if not (raw_nodes is Array):
		return nodes
	for raw_node in Array(raw_nodes):
		if raw_node is int or raw_node is float:
			nodes.append(int(raw_node))
	return nodes


func _target_nodes_have_invalid_entries(raw_nodes) -> bool:
	if not (raw_nodes is Array):
		return true
	for raw_node in Array(raw_nodes):
		if not (raw_node is int or raw_node is float):
			return true
	return false


func _normalized_gate_diagnostics(raw_gate) -> Dictionary:
	var gate: Dictionary = raw_gate if raw_gate is Dictionary else {}
	return {
		"ready": bool(gate.get("ready", false)),
		"reason": String(gate.get("reason", "")),
		"cooldown": maxf(0.0, float(gate.get("cooldown", 0.0))),
		"stagger": maxf(0.0, float(gate.get("stagger", 0.0))),
		"active_module_key": String(gate.get("active_module_key", "")),
		"active_module_part_index": int(gate.get("active_module_part_index", -1)),
		"same_module_decelerated": bool(gate.get("same_module_decelerated", true)),
		"cancel_ready": bool(gate.get("cancel_ready", false)),
		"cancel_phase": clampf(float(gate.get("cancel_phase", 1.0)), 0.0, 1.0),
		"cancel_power": maxf(0.0, float(gate.get("cancel_power", 0.0))),
		"last_gate_reason": String(gate.get("last_gate_reason", "")),
	}


func _normalized_command_diagnostics(raw_command) -> Dictionary:
	var command: Dictionary = raw_command if raw_command is Dictionary else {}
	return {
		"ai_kind": String(command.get("ai_kind", "")),
		"source_condition": String(command.get("source_condition", "")),
		"source_move_kind": String(command.get("source_move_kind", "")),
		"source_attack_preference": String(command.get("source_attack_preference", "")),
		"fire_timer": maxf(0.0, float(command.get("fire_timer", 0.0))),
		"sequence_step": maxi(0, int(command.get("sequence_step", 0))),
		"sequence_size": maxi(0, int(command.get("sequence_size", 0))),
		"movement_mode": String(command.get("movement_mode", "")),
		"movement_gate_reason": String(command.get("movement_gate_reason", "")),
		"role_switch_configured": bool(command.get("role_switch_configured", false)),
		"role_switch_target": String(command.get("role_switch_target", "")),
	}
