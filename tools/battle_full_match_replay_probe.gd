extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"
const SERVICE_PATH := "res://scripts/services/battle_input_service.gd"
const MainScene := preload("res://scripts/main.gd")
const BattleInputServiceScript := preload("res://scripts/services/battle_input_service.gd")
const StarSoulBPServiceScript := preload("res://scripts/services/star_soul_bp_service.gd")

const REPLAY_SEED := 20260629
const FIXTURE_MATCH_SECONDS := 2.0
const FIXTURE_FRAME_COUNT := 300

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
	if not _source_contract_ready():
		_finish()
		return
	var service = BattleInputServiceScript.new()
	if not _verify_full_input_frame(service):
		_finish()
		return
	var action_names: Array = service.battle_action_names(["p1", "p2"], MainScene.ATTACK_GROUP_COUNT)
	var serialized_frames := _serialized_fixture_frames(service, action_names)
	var start_payload: Dictionary = service.battle_start_payload(MainScene.MODE_PVP, 1, REPLAY_SEED, action_names, {
		"simulation_hz": int(roundf(MainScene.BATTLE_SIMULATION_FPS)),
		"remote_input_slots": [
			{"player_id": 1, "prefix": "p1", "source": "local", "slot_id": "local-p1"},
			{"player_id": 2, "prefix": "p2", "source": "local", "slot_id": "local-p2"},
		],
	})
	var draft_payload := _star_soul_draft_payload()
	if not _expect(bool(draft_payload.get("valid", false)), "Replay fixture Star Soul draft should be valid: %s" % str(draft_payload)):
		_finish()
		return
	var first := _run_match(service, start_payload, serialized_frames, draft_payload, "full_match_replay_a")
	var second := _run_match(service, start_payload, serialized_frames, draft_payload, "full_match_replay_b")
	if first.is_empty() or second.is_empty():
		_finish()
		return
	_expect(first == second, "Full-match replay snapshots should match.\nfirst=%s\nsecond=%s" % [str(first), str(second)])
	_finish()


func _source_contract_ready() -> bool:
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"func capture_input_frame",
		"func action_pressed",
		"func action_strength",
		"\"strengths\"",
	]:
		if not service_source.contains(token):
			_fail("BattleInputService missing full-frame replay token: %s" % token)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"func _begin_battle_from_start_payload",
		"func _tick_battle_with_input_frame",
		"func _battle_action_pressed",
		"func _battle_action_strength",
		"Callable(self, \"_begin_battle_from_start_payload\").bind(canonical_payload, true, nav_reason)",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing full-match replay token: %s" % token)
	if main_source.count("Input.is_action_pressed(") != 1:
		_fail("main.gd battle runtime should access held physical input only through its one service fallback, count=%d." % main_source.count("Input.is_action_pressed("))
	if main_source.count("Input.get_action_strength(") != 1:
		_fail("main.gd battle runtime should access physical action strength only through its one service fallback, count=%d." % main_source.count("Input.get_action_strength("))
	return failures.is_empty()


func _verify_full_input_frame(service) -> bool:
	var action_names := ["p1_left", "p1_right", "p1_cool"]
	var frame_a := {
		"pressed": {"p1_right": true},
		"released": {"p1_left": true},
		"strengths": {"p1_cool": 1.0, "p1_right": 0.75, "unregistered": 0.5},
	}
	var frame_b := {
		"strengths": {"unregistered": 0.5, "p1_right": 0.75, "p1_cool": 1.0},
		"released": {"p1_left": true},
		"pressed": {"p1_right": true},
	}
	var serialized_a: String = service.serialize_input_frame(frame_a, action_names)
	var serialized_b: String = service.serialize_input_frame(frame_b, action_names)
	if not _expect(serialized_a == serialized_b, "Full input-frame JSON should ignore strength Dictionary insertion order: a=%s b=%s" % [serialized_a, serialized_b]):
		return false
	var restored: Dictionary = service.deserialize_input_frame(serialized_a)
	var first_step: Dictionary = service.consume_edges_once(restored, true)
	var held_step: Dictionary = service.consume_edges_once(restored, false)
	if not _expect(service.action_pressed("p1_right", first_step, Callable(self, "_false_pressed")) and service.action_pressed("p1_right", held_step, Callable(self, "_false_pressed")), "Restored held input should remain active after edge consumption."):
		return false
	if not _expect(is_equal_approx(float(service.action_strength("p1_right", held_step, Callable(self, "_zero_strength"))), 0.75), "Restored analog strength should remain 0.75: %s" % str(restored)):
		return false
	if not _expect(is_equal_approx(float(service.action_strength("p1_cool", held_step, Callable(self, "_zero_strength"))), 1.0), "Restored cooling hold should remain active: %s" % str(restored)):
		return false
	return _expect(not service.action_pressed("unregistered", held_step, Callable(self, "_false_pressed")), "Unregistered held input should be filtered by the action allowlist.")


func _serialized_fixture_frames(service, action_names: Array) -> Array:
	var frames: Array = []
	for frame_index in range(FIXTURE_FRAME_COUNT):
		var strengths := {}
		if frame_index < 60:
			strengths = {"p1_right": 0.75, "p2_left": 0.5}
		elif frame_index < 120:
			strengths = {"p1_down": 0.5, "p2_up": 0.25}
		else:
			strengths = {"p1_cool": 1.0, "p2_cool": 1.0}
		var pressed := {}
		var released := {}
		if frame_index == 30:
			pressed["p1_portal"] = true
		if frame_index == 31:
			released["p1_portal"] = true
		if frame_index == 90:
			pressed["p2_portal"] = true
		if frame_index == 91:
			released["p2_portal"] = true
		frames.append(service.serialize_input_frame({
			"pressed": pressed,
			"released": released,
			"strengths": strengths,
		}, action_names))
	return frames


func _star_soul_draft_payload() -> Dictionary:
	var service = StarSoulBPServiceScript.new()
	var draft := [
		{"player": 1, "star_soul_id": "defense_tower_a"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
		{"player": 1, "star_soul_id": "cart_a"},
		{"player": 2, "star_soul_id": "coward_a"},
	]
	return service.build_spawn_queue(draft, 1, 2, {
		"pool_ids": service.catalog_by_id().keys(),
		"announce_seconds": 0.25,
	})


func _run_match(service, start_payload: Dictionary, serialized_frames: Array, draft_payload: Dictionary, reason: String) -> Dictionary:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	main.star_soul_battle_draft_payload = draft_payload.duplicate(true)
	main._begin_battle_from_start_payload(start_payload, true, reason)
	main.match_time_remaining = FIXTURE_MATCH_SECONDS
	for player_id in [1, 2]:
		var hero = Dictionary(main.active_units.get(player_id, {})).get("hero", null)
		if hero != null and is_instance_valid(hero):
			hero.heat = 80.0
	for serialized_frame in serialized_frames:
		if main.game_over:
			break
		var frame: Dictionary = service.deserialize_input_frame(String(serialized_frame))
		main._tick_battle_with_input_frame(MainScene.BATTLE_SIMULATION_DELTA, frame)
	if not _expect(main.game_over, "%s should reach full timeout resolution within %d replay frames; remaining=%.4f" % [reason, serialized_frames.size(), float(main.match_time_remaining)]):
		_dispose_main(main)
		return {}
	if not _expect(String(main.post_battle_review_reason) == "timeout" and int(main.post_battle_review_winner_id) > 0, "%s should produce a timeout winner: winner=%d reason=%s" % [reason, int(main.post_battle_review_winner_id), String(main.post_battle_review_reason)]):
		_dispose_main(main)
		return {}
	if not _expect(int(main.battle_replay_seed) == REPLAY_SEED, "%s should retain replay seed %d, got %d." % [reason, REPLAY_SEED, int(main.battle_replay_seed)]):
		_dispose_main(main)
		return {}
	if not _expect(not Array(main.active_star_soul_units).is_empty(), "%s should include a live Star Soul before timeout resolution." % reason):
		_dispose_main(main)
		return {}
	if not _expect(int(main.portal_index.get(1, 3)) != 3 and int(main.portal_index.get(2, 4)) != 4, "%s should consume both replayed portal edges: %s" % [reason, str(main.portal_index)]):
		_dispose_main(main)
		return {}
	for player_id in [1, 2]:
		var hero = Dictionary(main.active_units.get(player_id, {})).get("hero", null)
		if not _expect(hero != null and is_instance_valid(hero) and float(hero.heat) < 80.0 and float(hero.cooling_exposed_timer) > 0.0, "%s P%d should consume held cooling strength; hero=%s" % [reason, player_id, str(hero)]):
			_dispose_main(main)
			return {}
	var snapshot := _match_snapshot(main)
	_dispose_main(main)
	return snapshot


func _match_snapshot(main) -> Dictionary:
	var unit_rows: Array = []
	for unit in Array(main.all_units):
		if unit == null or not is_instance_valid(unit):
			continue
		unit_rows.append({
			"owner": int(unit.owner_id),
			"role": String(unit.role),
			"name": String(unit.unit_name),
			"health": int(unit.health),
			"ring": snappedf(float(unit.ring_pos), 0.0001),
			"lane": snappedf(float(unit.lane), 0.0001),
			"velocity_x": snappedf(float(unit.velocity.x), 0.0001),
			"velocity_y": snappedf(float(unit.velocity.y), 0.0001),
			"heat": snappedf(float(unit.heat), 0.0001),
			"cooling_exposed_timer": snappedf(float(unit.cooling_exposed_timer), 0.0001),
			"star_soul_id": String(unit.get_meta("star_soul_id", "")),
		})
	unit_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return "%d:%s:%s" % [int(a.get("owner", 0)), str(a.get("role", "")), str(a.get("name", ""))] < "%d:%s:%s" % [int(b.get("owner", 0)), str(b.get("role", "")), str(b.get("name", ""))]
	)
	return {
		"winner": int(main.post_battle_review_winner_id),
		"reason": String(main.post_battle_review_reason),
		"replay_seed": int(main.battle_replay_seed),
		"steps": int(main.battle_simulation_step_count),
		"remaining": snappedf(float(main.match_time_remaining), 0.0001),
		"resource": {1: snappedf(float(main.runtime_resource.get(1, 0.0)), 0.0001), 2: snappedf(float(main.runtime_resource.get(2, 0.0)), 0.0001)},
		"vp": {1: int(main.victory_points.get(1, 0)), 2: int(main.victory_points.get(2, 0))},
		"portal": {1: int(main.portal_index.get(1, 0)), 2: int(main.portal_index.get(2, 0))},
		"star_soul_runtime": Dictionary(main.star_soul_runtime_state).duplicate(true),
		"units": unit_rows,
	}


func _dispose_main(main) -> void:
	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.queue_free()


func _false_pressed(_action_name: String) -> bool:
	return false


func _zero_strength(_action_name: String) -> float:
	return 0.0


func _finish() -> void:
	if not failures.is_empty():
		print("BATTLE_FULL_MATCH_REPLAY_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BATTLE_FULL_MATCH_REPLAY_PROBE ok")
	quit(0)
