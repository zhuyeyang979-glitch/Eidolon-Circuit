extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const MainScene := preload("res://scripts/main.gd")
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")
const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")

const REPLAY_SEED := 20260629
const MATCH_SECONDS := 6.0
const FRAME_COUNT := 780
const CHECKPOINT_INTERVAL := 120

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _source_contract_ready():
		_finish()
		return
	var service = BattleInputServiceScript.new()
	if not _verify_checkpoint_diagnostics(service):
		_finish()
		return
	var action_names: Array = service.battle_action_names(["p1", "p2"], MainScene.ATTACK_GROUP_COUNT)
	var start_payload: Dictionary = service.battle_start_payload(MainScene.MODE_PVP, 1, REPLAY_SEED, action_names, {
		"simulation_hz": int(roundf(MainScene.BATTLE_SIMULATION_FPS)),
	})
	var draft_payload := _star_soul_draft_payload()
	var base_frames := _serialized_frames(service, action_names, false)
	var mutated_frames := _serialized_frames(service, action_names, true)
	var first := _run_match(service, start_payload, draft_payload, base_frames, "attack_replay_a")
	if first.is_empty():
		_finish()
		return
	var second := _run_match(service, start_payload, draft_payload, base_frames, "attack_replay_b")
	if second.is_empty():
		_finish()
		return
	var identical: Dictionary = service.first_replay_desync(Array(first.get("checkpoints", [])), Array(second.get("checkpoints", [])))
	if not _expect(bool(identical.get("matched", false)), "Identical attack-heavy replays should match: %s" % str(identical)):
		_finish()
		return
	if not _expect(Dictionary(first.get("terminal", {})) == Dictionary(second.get("terminal", {})), "Identical attack-heavy terminal snapshots should match.\nfirst=%s\nsecond=%s" % [str(first.get("terminal", {})), str(second.get("terminal", {}))]):
		_finish()
		return
	var mutated := _run_match(service, start_payload, draft_payload, mutated_frames, "attack_replay_mutated")
	if mutated.is_empty():
		_finish()
		return
	var desync: Dictionary = service.first_replay_desync(Array(first.get("checkpoints", [])), Array(mutated.get("checkpoints", [])))
	if not _expect(not bool(desync.get("matched", true)) and String(desync.get("reason", "")) == "checkpoint_mismatch", "Mutated replay should report checkpoint_mismatch: %s" % str(desync)):
		_finish()
		return
	if not _expect(int(desync.get("index", -1)) >= 0 and int(desync.get("expected_step", 0)) >= CHECKPOINT_INTERVAL, "Desync report should identify the first divergent checkpoint: %s" % str(desync)):
		_finish()
		return
	print("BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=%d desync_step=%d" % [Array(first.get("checkpoints", [])).size(), int(desync.get("expected_step", 0))])
	_finish()


func _source_contract_ready() -> bool:
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"func replay_checkpoint",
		"func replay_checkpoint_digest",
		"func first_replay_desync",
		"sha256_text",
	]:
		if not service_source.contains(token):
			_fail("BattleInputService missing replay diagnostic token: %s" % token)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"var battle_simulation_time_seconds",
		"battle_simulation_time_seconds += delta",
		"func _battle_replay_checkpoint_state",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing deterministic replay token: %s" % token)
	for function_name in [
		"_handle_direction_taps",
		"_open_attack_command_window",
		"_update_anti_stall_summons",
		"_mark_unit_attack_executed",
		"_mark_active_melee_contact_suppression",
		"_active_melee_contact_damage_suppressed",
		"_cleanup_active_melee_contact_suppression",
		"_open_stagger_combo",
		"_refresh_stagger_combo",
		"_apply_projectile_momentum_stagger",
		"_apply_melee_momentum_stagger_pair",
		"_melee_module_repeat_info",
	]:
		var block := _function_block(main_source, function_name)
		if block.is_empty():
			_fail("main.gd missing audited battle-time function: %s" % function_name)
		elif block.contains("Time.get_ticks_msec"):
			_fail("%s should use fixed-step battle time instead of wall clock." % function_name)
	return failures.is_empty()


func _function_block(source: String, function_name: String) -> String:
	var start := source.find("func %s(" % function_name)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + 6)
	return source.substr(start) if next < 0 else source.substr(start, next - start)


func _verify_checkpoint_diagnostics(service) -> bool:
	var state_a := {
		"units": [{"health": 80, "position": Vector2(1.25, -0.5)}],
		"resource": {2: 41.0, 1: 36.0},
	}
	var state_b := {
		"resource": {1: 36.0, 2: 41.0},
		"units": [{"position": Vector2(1.25, -0.5), "health": 80}],
	}
	var checkpoint_a: Dictionary = service.replay_checkpoint(120, 1.0, state_a)
	var checkpoint_b: Dictionary = service.replay_checkpoint(120, 1.0, state_b)
	if not _expect(String(checkpoint_a.get("digest", "")) == String(checkpoint_b.get("digest", "")), "Checkpoint digest should ignore Dictionary insertion order: a=%s b=%s" % [str(checkpoint_a), str(checkpoint_b)]):
		return false
	var changed_state := state_b.duplicate(true)
	changed_state["resource"][1] = 36.5
	var checkpoint_changed: Dictionary = service.replay_checkpoint(120, 1.0, changed_state)
	if not _expect(String(checkpoint_a.get("digest", "")) != String(checkpoint_changed.get("digest", "")), "Checkpoint digest should change with authoritative state."):
		return false
	var report: Dictionary = service.first_replay_desync([checkpoint_a], [checkpoint_changed])
	if not _expect(not bool(report.get("matched", true)) and int(report.get("index", -1)) == 0 and int(report.get("expected_step", 0)) == 120, "Synthetic desync should identify checkpoint zero: %s" % str(report)):
		return false
	var time_changed: Dictionary = service.replay_checkpoint(120, 1.1, state_a)
	var time_report: Dictionary = service.first_replay_desync([checkpoint_a], [time_changed])
	return _expect(not bool(time_report.get("matched", true)) and is_equal_approx(float(time_report.get("expected_time", 0.0)), 1.0) and is_equal_approx(float(time_report.get("actual_time", 0.0)), 1.1), "Checkpoint diagnostics should report simulation-time divergence: %s" % str(time_report))


func _serialized_frames(service, action_names: Array, mutate: bool) -> Array:
	var result: Array = []
	for frame_index in range(FRAME_COUNT):
		var cycle := frame_index % 120
		var strengths := {}
		if cycle < 30:
			strengths["p1_right"] = 0.72
			strengths["p2_left"] = 0.68
		elif cycle < 60:
			strengths["p1_up"] = 0.54
			strengths["p2_down"] = 0.5
		elif cycle < 90:
			strengths["p1_left"] = 0.64
			strengths["p2_right"] = 0.6
		else:
			strengths["p1_down"] = 0.46
			strengths["p2_up"] = 0.42
		if cycle >= 8 and cycle < 24:
			strengths["p1_attack_1"] = 1.0
		if cycle >= 38 and cycle < 54:
			strengths["p2_attack_1"] = 1.0
		if cycle >= 62 and cycle < 72:
			strengths["p1_face_right"] = 1.0
			strengths["p2_face_left"] = 1.0
		var pressed := {}
		var released := {}
		if cycle == 8:
			pressed["p1_attack_1"] = true
		if cycle == 24:
			released["p1_attack_1"] = true
		if cycle == 38:
			pressed["p2_attack_1"] = true
		if cycle == 54:
			released["p2_attack_1"] = true
		if cycle == 70:
			pressed["p1_portal"] = true
		if cycle == 71:
			released["p1_portal"] = true
		if cycle == 100:
			pressed["p2_portal"] = true
		if cycle == 101:
			released["p2_portal"] = true
		if cycle == 74 or cycle == 84:
			pressed["p1_left"] = true
		if cycle == 75 or cycle == 85:
			released["p1_left"] = true
		if cycle == 76 or cycle == 86:
			pressed["p2_right"] = true
		if cycle == 77 or cycle == 87:
			released["p2_right"] = true
		if mutate and frame_index == 333:
			pressed["p1_portal"] = true
		if mutate and frame_index == 334:
			released["p1_portal"] = true
		result.append(service.serialize_input_frame({
			"pressed": pressed,
			"released": released,
			"strengths": strengths,
		}, action_names))
	return result


func _star_soul_draft_payload() -> Dictionary:
	var service = StarSoulBPServiceScript.new()
	return service.build_spawn_queue([
		{"player": 1, "star_soul_id": "defense_tower_a"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
		{"player": 1, "star_soul_id": "cart_a"},
		{"player": 2, "star_soul_id": "coward_a"},
	], 1, 2, {
		"pool_ids": service.catalog_by_id().keys(),
		"announce_seconds": 0.25,
	})


func _run_match(service, start_payload: Dictionary, draft_payload: Dictionary, serialized_frames: Array, reason: String) -> Dictionary:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	main.star_soul_battle_draft_payload = draft_payload.duplicate(true)
	main._begin_battle_from_start_payload(start_payload, true, reason)
	if not _install_attack_fixture(main):
		_dispose_main(main)
		return {}
	main.match_time_remaining = MATCH_SECONDS
	var checkpoints: Array = []
	for serialized_frame in serialized_frames:
		if main.game_over:
			break
		main._tick_battle_with_input_frame(MainScene.BATTLE_SIMULATION_DELTA, service.deserialize_input_frame(String(serialized_frame)))
		if int(main.battle_simulation_step_count) > 0 and int(main.battle_simulation_step_count) % CHECKPOINT_INTERVAL == 0:
			checkpoints.append(service.replay_checkpoint(int(main.battle_simulation_step_count), float(main.battle_simulation_time_seconds), main._battle_replay_checkpoint_state()))
	if not _expect(main.game_over and String(main.post_battle_review_reason) == "timeout", "%s should complete through timeout: step=%d remaining=%.4f" % [reason, int(main.battle_simulation_step_count), float(main.match_time_remaining)]):
		_dispose_main(main)
		return {}
	if checkpoints.is_empty() or int(Dictionary(checkpoints[checkpoints.size() - 1]).get("step", -1)) != int(main.battle_simulation_step_count):
		checkpoints.append(service.replay_checkpoint(int(main.battle_simulation_step_count), float(main.battle_simulation_time_seconds), main._battle_replay_checkpoint_state()))
	var attacks := _attack_execution_count(main)
	if not _expect(attacks >= 4, "%s should execute repeated attack inputs, got %d. diagnostics=%s" % [reason, attacks, str(_attack_diagnostics(main))]):
		_dispose_main(main)
		return {}
	var result := {
		"checkpoints": checkpoints,
		"terminal": main._battle_replay_checkpoint_state(),
		"attack_executions": attacks,
	}
	_dispose_main(main)
	return result


func _attack_execution_count(main) -> int:
	return int(main.battle_attack_execution_count)


func _install_attack_fixture(main) -> bool:
	var module_index := _two_link_module_index(main)
	if module_index < 0:
		_fail("Attack replay fixture requires the two_link_forward_snap module.")
		return false
	var blueprint := _attack_fixture_blueprint(main, module_index)
	main._clear_all_units()
	main.active_units = {
		1: {"hero": null, "barrier": null, "puppet": []},
		2: {"hero": null, "barrier": null, "puppet": []},
	}
	var positions := {1: Vector2(MainScene.RING_LENGTH * 0.5 - 0.38, 0.0), 2: Vector2(MainScene.RING_LENGTH * 0.5 + 0.38, 0.0)}
	for player_id in [1, 2]:
		var stats: Dictionary = main._compute_unit_stats(player_id, "hero", -1, blueprint)
		var bindings: Array = Array(stats.get("runtime_module_bindings", []))
		if bindings.size() != 1 or String(Dictionary(bindings[0]).get("module_action_profile", "")) != "two_link_forward_snap":
			_fail("P%d attack replay fixture did not produce a legal two-link binding: %s" % [player_id, str(bindings)])
			return false
		var point: Vector2 = positions[player_id]
		var hero = main._create_unit(player_id, "hero", stats, "Replay Attacker %d" % player_id, point.x, point.y)
		main._assign_unit_role(hero, "hero")
		if hero.has_method("set_facing_immediate"):
			hero.set_facing_immediate(1 if player_id == 1 else -1)
	return true


func _two_link_module_index(main) -> int:
	for index in range(main._catalog_for("hero", "module").size()):
		var module: Dictionary = Dictionary(main._catalog_for("hero", "module")[index])
		if String(module.get("module_action_profile", "")) == "two_link_forward_snap":
			return index
	return -1


func _first_torso_index(main) -> int:
	for index in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", index)):
			return index
	return -1


func _attack_fixture_blueprint(main, module_index: int) -> Dictionary:
	var blueprint: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso_index(main))
	var limb_a: int = main._append_directed_component_node("hero", blueprint, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", blueprint, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	blueprint["role"] = "hero"
	blueprint["blank_canvas"] = false
	blueprint["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	blueprint["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	blueprint["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", blueprint)
	return blueprint


func _attack_diagnostics(main) -> Dictionary:
	var players := {}
	for player_id in [1, 2]:
		var hero = Dictionary(main.active_units.get(player_id, {})).get("hero", null)
		if hero == null or not is_instance_valid(hero):
			players[player_id] = {"hero": "missing"}
			continue
		var bindings: Array = []
		for raw_binding in Array(hero.stats.get("runtime_module_bindings", [])):
			if raw_binding is Dictionary:
				bindings.append({
					"attack_key": int(Dictionary(raw_binding).get("attack_key", -1)),
					"profile": String(Dictionary(raw_binding).get("module_action_profile", "")),
					"runtime_valid": bool(Dictionary(raw_binding).get("runtime_valid", true)),
				})
		players[player_id] = {
			"direct_topology": bool(hero.stats.get("teamedit_runtime_topology", false)),
			"bindings": bindings,
			"last_gate": String(hero.get_meta("last_module_gate_reason", "")),
			"last_attack_time": float(hero.get_meta("last_attack_time", 0.0)),
			"windows": Dictionary(main.attack_command_windows.get(player_id, {})),
			"gun_state": Dictionary(main.gun_activation_state.get(player_id, {})).keys(),
			"melee_state": Dictionary(main.held_melee_activation_state.get(player_id, {})).keys(),
			"feedback": Dictionary(main.battle_attack_feedback_events.get(player_id, {})),
		}
	return {
		"players": players,
		"attack_log_count": Array(main.battle_attack_rule_log).size(),
		"command_log_count": Array(main.battle_command_log).size(),
	}


func _dispose_main(main) -> void:
	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.queue_free()


func _finish() -> void:
	if not failures.is_empty():
		print("BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok")
	quit(0)
