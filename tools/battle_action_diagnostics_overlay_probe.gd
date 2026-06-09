extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const BattleActionDiagnosticsView := preload("res://scripts/views/battle_action_diagnostics_view.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)
	quit(1)


func _init() -> void:
	var view_source := FileAccess.get_file_as_string("res://scripts/views/battle_action_diagnostics_view.gd")
	if view_source.is_empty() or not view_source.contains("class_name BattleActionDiagnosticsView"):
		_fail("BattleActionDiagnosticsView should exist and publish its class name.")
		return
	for required in ["set_model", "clear_model", "func text", "_counts_line"]:
		if not view_source.contains(required):
			_fail("BattleActionDiagnosticsView missing behavior token: %s" % required)
			return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"scripts/views/battle_action_diagnostics_view.gd",
		"BattleActionDiagnosticsView.new",
		"battle_action_diagnostics_overlay_enabled",
		"_set_battle_action_diagnostics_overlay_enabled",
		"_battle_action_diagnostics_overlay_text",
		"_update_battle_action_diagnostics_overlay",
		"_battle_action_diagnostics_model",
	]:
		if not main_source.contains(required):
			_fail("main.gd missing battle action diagnostics overlay token: %s" % required)
			return
	var standalone_view := BattleActionDiagnosticsView.new()
	standalone_view.set_model({
		"title": "BATTLE ACTION DIAGNOSTICS",
		"unit_count": 1,
		"active_action_unit_count": 1,
		"active_action_count": 1,
		"profile_counts": {"two_link_forward_snap": 1},
		"phase_label_counts": {"startup": 1},
		"gate_reason_counts": {"cooldown": 1},
		"cancel_ready_unit_count": 0,
		"cooldown_blocked_unit_count": 1,
		"ai_kind_counts": {"line": 1},
		"source_condition_counts": {"default": 1},
		"movement_mode_counts": {"drive": 1},
		"fire_cooling_unit_count": 1,
		"role_switch_configured_unit_count": 1,
		"projectile_behavior_counts": {"true_bullet": 1, "explosive": 1},
		"projectile_target_role_counts": {"hero": 2},
		"projectile_pending_count": 2,
		"projectile_locked_target_count": 2,
		"projectile_signal_unit_count": 1,
		"projectile_targeted_unit_count": 1,
		"has_feint_retarget": false,
		"has_runtime_contact_speed": true,
		"unit_rows": [{
			"owner": 1,
			"role": "hero",
			"name": "Standalone",
			"active_count": 1,
			"active_part_state": "normal",
			"gate_diagnostics": {
				"ready": false,
				"reason": "cooldown",
				"cooldown": 0.22,
				"stagger": 0.0,
				"cancel_ready": false,
				"cancel_phase": 1.0,
				"cancel_power": 0.0,
				"same_module_decelerated": true,
				"last_gate_reason": "cooldown",
			},
			"command_diagnostics": {
				"ai_kind": "line",
				"source_condition": "default",
				"source_move_kind": "hold",
				"source_attack_preference": "ranged_first",
				"fire_timer": 0.18,
				"sequence_step": 1,
				"sequence_size": 2,
				"movement_mode": "drive",
				"movement_gate_reason": "",
				"role_switch_configured": true,
				"role_switch_target": "puppet",
			},
			"projectile_diagnostics": {
				"projectile_signal": 0.44,
				"pending_projectile_count": 2,
				"incoming_projectile_count": 0,
				"locked_target_count": 2,
				"targeted_by_count": 0,
				"behavior_counts": {"true_bullet": 1, "explosive": 1},
				"target_role_counts": {"hero": 2},
				"last_source_error": "",
			},
			"actions": [{
				"profile": "two_link_forward_snap",
				"phase_label": "startup",
				"attack_key": 3,
				"target_nodes": [4, 5],
				"phase": 0.25,
				"pose_t": 0.8,
				"target_t": 0.7,
				"variant_key": "balance_string",
				"command_variant": "normal_sweep",
				"runtime_contact_speed": 4.4,
				"joint_actuation_speed": 3.3,
				"soul_echo_refund_applied": true,
				"combo_balance_refund_applied": true,
			}],
		}],
	})
	var standalone_text := standalone_view.text()
	if not standalone_text.contains("unit P1 hero Standalone") or not standalone_text.contains("profile:two_link_forward_snap"):
		_fail("BattleActionDiagnosticsView text did not include unit/action rows: %s" % standalone_text)
		return
	for required in ["key:3", "nodes:4/5", "pose:", "target:", "variant:balance_string", "cmd:normal_sweep", "speed:", "soul:true", "combo:true"]:
		if not standalone_text.contains(required):
			_fail("BattleActionDiagnosticsView text missing enriched token %s: %s" % [required, standalone_text])
			return
	for required in ["gates cooldown:1", "gate ready:false", "reason:cooldown", "cd:0.22", "cancel:false", "last:cooldown"]:
		if not standalone_text.contains(required):
			_fail("BattleActionDiagnosticsView text missing gate token %s: %s" % [required, standalone_text])
			return
	for required in ["cmds ai:line:1", "cond:default:1", "mm:drive:1", "cmd ai:line", "cond:default", "move:hold", "fire:0.18", "step:1/2", "mm:drive", "role:true", "target:puppet"]:
		if not standalone_text.contains(required):
			_fail("BattleActionDiagnosticsView text missing command token %s: %s" % [required, standalone_text])
			return
	for required in ["projectiles behavior:explosive:1, true_bullet:1", "targets:hero:2", "pending:2", "locks:2", "signal_units:1", "targeted_units:1", "proj signal:0.44", "pending:2", "incoming:0", "locks:2", "targeted:0", "beh:explosive:1, true_bullet:1", "targets:hero:2"]:
		if not standalone_text.contains(required):
			_fail("BattleActionDiagnosticsView text missing projectile token %s: %s" % [required, standalone_text])
			return
	standalone_view.free()
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.battle_action_diagnostics_view == null:
		_fail("main should build BattleActionDiagnosticsView.")
		return
	if main.battle_action_diagnostics_view.visible:
		_fail("Battle action diagnostics overlay should default hidden.")
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"unit_name": "Overlay Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {"health": 100, "mass": 10.0, "ai": "line", "source_rules": {"default": {"move": "hold"}}, "sequence": ["normal", "armor"], "source_attack_preference": "ranged_first", "role_switch": "puppet"},
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
		"module_variant_key": "balance_string",
		"command_variant": "normal_sweep",
		"runtime_contact_speed": 4.8,
		"joint_actuation_speed": 4.2,
		"soul_echo_refund_applied": true,
	}]
	fighter.active_module_key = "runtime:1:two_link_forward_snap"
	fighter.active_module_part_index = 0
	fighter.action_cooldown = 0.22
	fighter.set_meta("last_module_gate_reason", "cooldown")
	fighter.set_meta("source_condition", "default")
	fighter.set_meta("fire_timer", 0.18)
	fighter.set_meta("sequence_step", 1)
	fighter.set_meta("last_move_command_mode", "drive")
	fighter.set_meta("projectile_signal", 0.44)
	var target = FighterScene.new()
	root.add_child(target)
	target.setup_unit({
		"unit_name": "Overlay Target",
		"owner_id": 2,
		"role": "hero",
		"stats": {"health": 100, "mass": 10.0},
	})
	target.deploy(2.0, 0.0)
	main.pending_true_bullet_shots = [{
		"attacker": fighter,
		"target": target,
		"event": {"projectile": true, "projectile_behavior": "true_bullet", "aim_locked": true},
		"timer": 0.25,
	}]
	main.pending_missile_projectiles = [{
		"attacker": fighter,
		"target": target,
		"event": {"projectile": true, "projectile_behavior": "explosive", "projectile_style": "missile", "aim_locked": true},
		"timer": 0.6,
	}]
	main.all_units = [fighter, target]
	main._set_battle_action_diagnostics_overlay_enabled(true)
	if not main.battle_action_diagnostics_view.visible:
		_fail("Battle action diagnostics overlay should become visible when enabled.")
		return
	var text := main._battle_action_diagnostics_overlay_text()
	for required in ["units:", "action", "profile:two_link_forward_snap", "phase:", "unit P1 hero Overlay Probe", "key:1", "nodes:1/2", "pose:", "target:", "variant:balance_string", "cmd:normal_sweep", "speed:", "soul:true", "gate", "reason:cooldown", "cd:0.22", "cancel:false", "last:cooldown", "cmds", "cmd ai:line", "cond:default", "fire:0.18", "step:1/2", "mm:drive", "role:true", "target:puppet", "projectiles", "behavior:explosive:1, true_bullet:1", "targets:hero:2", "proj signal:0.44", "pending:2", "locks:2"]:
		if not text.contains(required):
			_fail("Battle action diagnostics overlay text missing token %s: %s" % [required, text])
			return
	main._set_battle_action_diagnostics_overlay_enabled(false)
	if main.battle_action_diagnostics_view.visible:
		_fail("Battle action diagnostics overlay should hide when disabled.")
		return
	if main.battle_action_diagnostics_view.text() != "":
		_fail("Battle action diagnostics overlay should clear text when disabled.")
		return
	if not failures.is_empty():
		print("BATTLE_ACTION_DIAGNOSTICS_OVERLAY_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_ACTION_DIAGNOSTICS_OVERLAY_PROBE ok text_lines=%d" % text.split("\n").size())
	quit(0)
