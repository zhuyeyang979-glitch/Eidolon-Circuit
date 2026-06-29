extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := _run_replay_case("local_replay_consistency_a")
	var second := _run_replay_case("local_replay_consistency_b")
	if first.is_empty() or second.is_empty():
		_finish()
		return
	if not _expect(String(first.get("payload_json", "")) == String(second.get("payload_json", "")), "Battle start payload JSON should be identical across local replay setup: first=%s second=%s" % [String(first.get("payload_json", "")), String(second.get("payload_json", ""))]):
		_finish()
		return
	if not _expect(Dictionary(first.get("initial", {})) == Dictionary(second.get("initial", {})), "Initial local battle snapshots should match for the same payload.\nfirst=%s\nsecond=%s" % [str(first.get("initial", {})), str(second.get("initial", {}))]):
		_finish()
		return
	if not _expect(Dictionary(first.get("after_ticks", {})) == Dictionary(second.get("after_ticks", {})), "Post-tick local battle snapshots should match for the same payload.\nfirst=%s\nsecond=%s" % [str(first.get("after_ticks", {})), str(second.get("after_ticks", {}))]):
		_finish()
		return
	_finish()


func _run_replay_case(reason: String) -> Dictionary:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	if not _expect(bool(main._team_battle_entry_summary(1).get("valid", false)), "%s P1 roster should be legal." % reason):
		return {}
	if not _expect(bool(main._team_battle_entry_summary(2).get("valid", false)), "%s P2 roster should be legal." % reason):
		return {}
	var payload: Dictionary = main._battle_input_service().battle_start_payload(MainScene.MODE_PVP, 1, 20260629, main._battle_input_action_names(), {
		"simulation_hz": int(roundf(MainScene.BATTLE_SIMULATION_FPS)),
		"remote_input_slots": [
			{"player_id": 1, "prefix": "p1", "source": "local", "slot_id": "local-p1"},
			{"player_id": 2, "prefix": "p2", "source": "local", "slot_id": "local-p2"},
		],
	})
	var payload_json := main._battle_input_service().serialize_battle_start_payload(payload)
	main._begin_battle(String(payload.get("mode", MainScene.MODE_PVP)), true, reason)
	var initial_snapshot := _battle_snapshot(main)
	for _i in range(12):
		main._tick_battle(MainScene.BATTLE_SIMULATION_DELTA)
	var after_tick_snapshot := _battle_snapshot(main)
	root.remove_child(main)
	main.queue_free()
	return {
		"payload_json": payload_json,
		"initial": initial_snapshot,
		"after_ticks": after_tick_snapshot,
	}


func _battle_snapshot(main) -> Dictionary:
	return {
		"game_state": String(main.game_state),
		"battle_mode": String(main.battle_mode),
		"match_time_remaining": _snap_float(float(main.match_time_remaining)),
		"battle_simulation_step_count": int(main.battle_simulation_step_count),
		"last_frame_steps": int(main.battle_simulation_last_frame_steps),
		"runtime_resource": _player_number_map(main.runtime_resource),
		"victory_points": _player_int_map(main.victory_points),
		"portal_index": _player_int_map(main.portal_index),
		"initial_sortie_slot": _player_int_map(main.initial_sortie_slot),
		"initial_role": {1: String(main.initial_role.get(1, "")), 2: String(main.initial_role.get(2, ""))},
		"sortie_loadouts": {1: _entry_array(Array(main.sortie_loadouts.get(1, []))), 2: _entry_array(Array(main.sortie_loadouts.get(2, [])))},
		"active_units": {1: _player_unit_snapshot(main, 1), 2: _player_unit_snapshot(main, 2)},
		"all_units": _all_units_snapshot(main),
	}


func _player_unit_snapshot(main, player_id: int) -> Dictionary:
	var units: Dictionary = main.active_units.get(player_id, {})
	return {
		"hero": _unit_snapshot(units.get("hero", null)),
		"barrier": _unit_snapshot(units.get("barrier", null)),
		"puppet": _unit_array_snapshot(Array(units.get("puppet", []))),
	}


func _all_units_snapshot(main) -> Array:
	return _unit_array_snapshot(Array(main.all_units))


func _unit_array_snapshot(units: Array) -> Array:
	var snapshots: Array = []
	for unit in units:
		var snapshot := _unit_snapshot(unit)
		if not snapshot.is_empty():
			snapshots.append(snapshot)
	snapshots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%d:%s:%s:%s" % [int(a.get("owner_id", 0)), str(a.get("role", "")), str(a.get("name", "")), str(a.get("ring", ""))]
		var b_key := "%d:%s:%s:%s" % [int(b.get("owner_id", 0)), str(b.get("role", "")), str(b.get("name", "")), str(b.get("ring", ""))]
		return a_key < b_key
	)
	return snapshots


func _unit_snapshot(unit) -> Dictionary:
	if unit == null or not is_instance_valid(unit):
		return {}
	var stats: Dictionary = unit.stats if unit.stats is Dictionary else {}
	return {
		"owner_id": int(unit.owner_id),
		"role": String(unit.role),
		"name": String(unit.unit_name),
		"stats_name": String(stats.get("name", "")),
		"health": int(unit.health),
		"max_health": int(unit.max_health),
		"ring": _snap_float(float(unit.ring_pos)),
		"lane": _snap_float(float(unit.lane)),
		"velocity": _snap_vector(unit.velocity),
		"cooling": _snap_float(float(stats.get("cooling", 0.0))),
		"speed": _snap_float(float(stats.get("speed", 0.0))),
		"cost": int(stats.get("cost", 0)),
		"deploy_cost": int(stats.get("deploy_cost", 0)),
	}


func _entry_array(entries: Array) -> Array:
	var result: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = Dictionary(raw_entry)
			result.append({"role": String(entry.get("role", "")), "index": int(entry.get("index", -1))})
	return result


func _player_number_map(values: Dictionary) -> Dictionary:
	return {1: _snap_float(float(values.get(1, 0.0))), 2: _snap_float(float(values.get(2, 0.0)))}


func _player_int_map(values: Dictionary) -> Dictionary:
	return {1: int(values.get(1, 0)), 2: int(values.get(2, 0))}


func _snap_vector(value) -> Dictionary:
	var vector := Vector2(value) if value is Vector2 else Vector2.ZERO
	return {"x": _snap_float(vector.x), "y": _snap_float(vector.y)}


func _snap_float(value: float) -> float:
	return snappedf(value, 0.0001)


func _finish() -> void:
	if not failures.is_empty():
		print("LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok")
	quit(0)
