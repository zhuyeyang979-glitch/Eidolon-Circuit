extends Control
class_name BattleActionDiagnosticsView


var model: Dictionary = {}
var last_signature := ""


func set_model(next_model: Dictionary) -> void:
	var signature := str(next_model)
	if signature == last_signature:
		return
	last_signature = signature
	model = next_model.duplicate(true)
	queue_redraw()


func clear_model() -> void:
	last_signature = ""
	model = {}
	queue_redraw()


func text() -> String:
	if model.is_empty():
		return ""
	var lines: Array[String] = []
	var unit_rows: Array = Array(model.get("unit_rows", []))
	lines.append(String(model.get("title", "BATTLE ACTION DIAGNOSTICS")))
	lines.append("units:%d active_units:%d actions:%d shown:%d omitted:%d" % [
		int(model.get("unit_count", 0)),
		int(model.get("active_action_unit_count", 0)),
		int(model.get("active_action_count", 0)),
		int(model.get("displayed_unit_count", unit_rows.size())),
		int(model.get("omitted_unit_count", 0)),
	])
	lines.append("flags feint:%s contact_speed:%s phase:%.2f earliest:%.2f" % [
		str(bool(model.get("has_feint_retarget", false))),
		str(bool(model.get("has_runtime_contact_speed", false))),
		float(model.get("latest_phase", 0.0)),
		float(model.get("earliest_timer", 0.0)),
	])
	lines.append("profiles %s" % _counts_line(Dictionary(model.get("profile_counts", {}))))
	lines.append("phases %s" % _counts_line(Dictionary(model.get("phase_label_counts", {}))))
	lines.append("gates %s cancel:%d cooldown:%d" % [
		_counts_line(Dictionary(model.get("gate_reason_counts", {}))),
		int(model.get("cancel_ready_unit_count", 0)),
		int(model.get("cooldown_blocked_unit_count", 0)),
	])
	lines.append("cmds ai:%s cond:%s mm:%s fire:%d role:%d" % [
		_counts_line(Dictionary(model.get("ai_kind_counts", {}))),
		_counts_line(Dictionary(model.get("source_condition_counts", {}))),
		_counts_line(Dictionary(model.get("movement_mode_counts", {}))),
		int(model.get("fire_cooling_unit_count", 0)),
		int(model.get("role_switch_configured_unit_count", 0)),
	])
	lines.append("projectiles behavior:%s targets:%s pending:%d locks:%d signal_units:%d targeted_units:%d" % [
		_counts_line(Dictionary(model.get("projectile_behavior_counts", {}))),
		_counts_line(Dictionary(model.get("projectile_target_role_counts", {}))),
		int(model.get("projectile_pending_count", 0)),
		int(model.get("projectile_locked_target_count", 0)),
		int(model.get("projectile_signal_unit_count", 0)),
		int(model.get("projectile_targeted_unit_count", 0)),
	])
	var hardware_state_counts: Dictionary = Dictionary(model.get("hardware_fault_state_counts", {}))
	if not hardware_state_counts.is_empty() or int(model.get("hardware_faulted_unit_count", 0)) > 0 or int(model.get("hardware_destroyed_unit_count", 0)) > 0:
		lines.append("hardware states %s" % _counts_line(hardware_state_counts))
		lines.append("hardware faulted_units:%d destroyed_units:%d" % [
			int(model.get("hardware_faulted_unit_count", 0)),
			int(model.get("hardware_destroyed_unit_count", 0)),
		])
	for raw_row in unit_rows:
		if not (raw_row is Dictionary):
			continue
		var row: Dictionary = raw_row
		var actions: Array = Array(row.get("actions", []))
		lines.append("unit P%d %s %s active:%d state:%s shown:%d omitted:%d" % [
			int(row.get("owner", 0)),
			String(row.get("role", "")),
			String(row.get("name", "")),
			int(row.get("active_count", 0)),
			String(row.get("active_part_state", "")),
			int(row.get("displayed_action_count", actions.size())),
			int(row.get("omitted_action_count", 0)),
		])
		var gate: Dictionary = Dictionary(row.get("gate_diagnostics", {}))
		lines.append("  gate ready:%s reason:%s cd:%.2f stagger:%.2f cancel:%s phase:%.2f power:%.2f same:%s last:%s" % [
			str(bool(gate.get("ready", false))),
			String(gate.get("reason", "")),
			float(gate.get("cooldown", 0.0)),
			float(gate.get("stagger", 0.0)),
			str(bool(gate.get("cancel_ready", false))),
			float(gate.get("cancel_phase", 1.0)),
			float(gate.get("cancel_power", 0.0)),
			str(bool(gate.get("same_module_decelerated", true))),
			String(gate.get("last_gate_reason", "")),
		])
		var command: Dictionary = Dictionary(row.get("command_diagnostics", {}))
		lines.append("  cmd ai:%s cond:%s move:%s fire:%.2f step:%d/%d mm:%s gate:%s role:%s target:%s" % [
			String(command.get("ai_kind", "")),
			String(command.get("source_condition", "")),
			String(command.get("source_move_kind", "")),
			float(command.get("fire_timer", 0.0)),
			int(command.get("sequence_step", 0)),
			int(command.get("sequence_size", 0)),
			String(command.get("movement_mode", "")),
			String(command.get("movement_gate_reason", "")),
			str(bool(command.get("role_switch_configured", false))),
			String(command.get("role_switch_target", "")),
		])
		if _command_has_source_code_diagnostics(command):
			lines.append("  source src:%s src_name:%s src_reason:%s" % [
				String(command.get("source_code_entry_id", "")),
				String(command.get("source_code_name", "")),
				String(command.get("source_code_rejection_reason", "")),
			])
		var projectile: Dictionary = Dictionary(row.get("projectile_diagnostics", {}))
		lines.append("  proj signal:%.2f pending:%d incoming:%d locks:%d targeted:%d beh:%s targets:%s err:%s" % [
			float(projectile.get("projectile_signal", 0.0)),
			int(projectile.get("pending_projectile_count", 0)),
			int(projectile.get("incoming_projectile_count", 0)),
			int(projectile.get("locked_target_count", 0)),
			int(projectile.get("targeted_by_count", 0)),
			_counts_line(Dictionary(projectile.get("behavior_counts", {}))),
			_counts_line(Dictionary(projectile.get("target_role_counts", {}))),
			String(projectile.get("last_source_error", "")),
		])
		var hardware: Dictionary = Dictionary(row.get("hardware_fault_diagnostics", {}))
		var affected_nodes: Array = Array(hardware.get("affected_nodes", []))
		for node_index in range(mini(2, affected_nodes.size())):
			if not (affected_nodes[node_index] is Dictionary):
				continue
			var node: Dictionary = affected_nodes[node_index]
			lines.append("  hardware FAULT / 故障 node:%s state:%s seq:%d" % [
				str(node.get("hardware_node_id", "")),
				String(node.get("state", "")),
				int(node.get("transition_sequence", 0)),
			])
			lines.append("    part:%s capacity:%.2f" % [
				String(node.get("name", "")),
				float(node.get("runtime_momentum_capacity", 0.0)),
			])
		if affected_nodes.size() > 2:
			lines.append("    affected_omitted:%d" % (affected_nodes.size() - 2))
		var latest_transition: Dictionary = Dictionary(hardware.get("latest_transition", {}))
		if not latest_transition.is_empty():
			lines.append("  transition node:%s %s>%s seq:%d" % [
				str(latest_transition.get("target_hardware_node_id", "")),
				String(latest_transition.get("pre_state", "")),
				String(latest_transition.get("post_state", "")),
				int(latest_transition.get("transition_sequence", 0)),
			])
			lines.append("    momentum raw:%.2f path:%.2f capped:%.2f capacity:%.2f" % [
				float(latest_transition.get("raw_momentum", 0.0)),
				float(latest_transition.get("path_capped_momentum", 0.0)),
				float(latest_transition.get("hardware_capped_momentum", 0.0)),
				float(latest_transition.get("runtime_momentum_capacity", 0.0)),
			])
		for raw_action in actions:
			if not (raw_action is Dictionary):
				continue
			var action: Dictionary = raw_action
			lines.append("  action %s key:%d nodes:%s profile:%s phase:%s %.2f pose:%.2f target:%.2f variant:%s cmd:%s speed:%.2f/%.2f hit:%s soul:%s combo:%s" % [
				String(action.get("profile", "")),
				int(action.get("attack_key", -1)),
				_nodes_line(Array(action.get("target_nodes", []))),
				String(action.get("profile", "")),
				String(action.get("phase_label", "")),
				float(action.get("phase", 0.0)),
				float(action.get("pose_t", 0.0)),
				float(action.get("target_t", 0.0)),
				String(action.get("variant_key", "")),
				String(action.get("command_variant", "")),
				float(action.get("runtime_contact_speed", 0.0)),
				float(action.get("joint_actuation_speed", 0.0)),
				str(bool(action.get("module_variant_hit_confirmed", false))),
				str(bool(action.get("soul_echo_refund_applied", false))),
				str(bool(action.get("combo_balance_refund_applied", false))),
			])
	for raw_warning in Array(model.get("warnings", [])):
		lines.append("warn %s" % String(raw_warning))
	return "\n".join(lines)


func _draw() -> void:
	if not visible:
		return
	var body := text()
	if body == "":
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.005, 0.012, 0.018, 0.82), true)
	draw_rect(rect, Color(0.35, 0.92, 1.0, 0.42), false, 1.2)
	var font := ThemeDB.get_fallback_font()
	var y := 18.0
	for raw_line in body.split("\n"):
		draw_string(font, Vector2(10.0, y), String(raw_line), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 10, Color(0.78, 0.95, 1.0, 0.94))
		y += 14.0
		if y > size.y - 8.0:
			break


func _counts_line(counts: Dictionary) -> String:
	if counts.is_empty():
		return "-"
	var keys := counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for raw_key in keys:
		var key := String(raw_key)
		parts.append("%s:%d" % [key, int(counts.get(key, 0))])
	return ", ".join(parts)


func _command_has_source_code_diagnostics(command: Dictionary) -> bool:
	return String(command.get("source_code_entry_id", "")) != "" or String(command.get("source_code_name", "")) != "" or String(command.get("source_code_rejection_reason", "")) != ""


func _nodes_line(nodes: Array) -> String:
	if nodes.is_empty():
		return "-"
	var parts: Array[String] = []
	for raw_node in nodes:
		parts.append(str(int(raw_node)))
	return "/".join(parts)
