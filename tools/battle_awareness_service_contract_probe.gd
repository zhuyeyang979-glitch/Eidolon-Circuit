extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleAwarenessService := preload("res://scripts/services/battle_awareness_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_awareness_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleAwarenessService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "queue_free", "_spawn_", "take_hit"]:
		if source.contains(forbidden):
			_fail("BattleAwarenessService contains forbidden token: %s" % forbidden)
			return
	var service := BattleAwarenessService.new()
	var snapshots := [
		{"id": 1, "live": true, "owner": 1, "role": "hero", "ring": 2.0, "lane": -1.0, "radius": 0.3},
		{"id": 2, "live": true, "owner": 2, "role": "hero", "ring": 4.0, "lane": 1.0, "radius": 0.28},
		{"id": 3, "live": true, "owner": 2, "role": "barrier", "space_debris": false, "barrier_tiles": [{"ring": 6.0, "lane": 0.5, "radius": 0.2, "length": 0.5}]},
		{"id": 4, "live": false, "owner": 1, "role": "puppet"},
	]
	var model := service.minimap_world_model(snapshots, 3.0, -0.25)
	var points: Array = Array(model.get("unit_points", []))
	if points.size() != 3 or float(model.get("camera_ring", 0.0)) != 3.0 or float(model.get("camera_lane", 0.0)) != -0.25:
		_fail("minimap_world_model mismatch: %s" % str(model))
		return
	var barrier_point: Dictionary = Dictionary(points[2])
	if String(barrier_point.get("role", "")) != "barrier_piece" or absf(float(barrier_point.get("radius", 0.0)) - 0.28) > 0.001:
		_fail("Barrier minimap point mismatch: %s" % str(barrier_point))
		return
	var enemies := service.enemy_ids(1, snapshots)
	if enemies != [2, 3]:
		_fail("enemy_ids mismatch: %s" % str(enemies))
		return
	var friendlies := service.friendly_ids(1, snapshots)
	if friendlies != [1]:
		_fail("friendly_ids mismatch: %s" % str(friendlies))
		return
	var first_live := service.first_live_id([
		{"id": 9, "live": true, "temporary": true},
		{"id": 10, "live": true, "temporary": false},
	], true)
	if first_live != 10:
		_fail("first_live_id should prefer non-temporary unit, got %d" % first_live)
		return
	var nearest := service.nearest_candidate_id([{"id": 2, "distance": 3.2}, {"id": 3, "distance": 0.7}])
	if int(nearest.get("id", -1)) != 3:
		_fail("nearest_candidate_id mismatch: %s" % str(nearest))
		return
	var low_hp_score := service.source_target_score({"id": 2, "distance": 2.0, "hp_ratio": 0.1, "role": "puppet", "sight_blocked": false}, "low_hp_first")
	var hero_score := service.source_target_score({"id": 3, "distance": 1.0, "hp_ratio": 0.9, "role": "hero", "sight_blocked": true}, "low_hp_first")
	if low_hp_score <= hero_score:
		_fail("low_hp_first should prefer the low HP target: low=%.3f hero=%.3f" % [low_hp_score, hero_score])
		return
	var close_intent := service.source_target_intent({
		"threat_range": 1.0,
		"close_response": "kite",
		"policy": "hero_siege",
		"candidates": [{"id": 2, "distance": 1.4, "role": "hero"}, {"id": 3, "distance": 0.8, "role": "barrier"}],
	})
	if int(close_intent.get("target_id", -1)) != 3 or String(close_intent.get("reason", "")) != "close_response":
		_fail("close response intent mismatch: %s" % str(close_intent))
		return
	var siege_intent := service.source_target_intent({
		"policy": "hero_siege",
		"candidates": [{"id": 2, "distance": 0.4, "role": "barrier", "hp_ratio": 0.5}, {"id": 3, "distance": 3.0, "role": "hero", "hp_ratio": 1.0}],
	})
	if int(siege_intent.get("target_id", -1)) != 3:
		_fail("hero_siege intent should prefer hero target: %s" % str(siege_intent))
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_awareness_service.gd",
		"BattleAwarenessService.new",
		"battle_awareness_service.minimap_world_model",
		"battle_awareness_service.enemy_ids",
		"battle_awareness_service.nearest_candidate_id",
		"battle_awareness_service.source_target_intent",
		"battle_awareness_service.source_target_score",
		"battle_awareness_service.live_count",
		"battle_awareness_service.first_live_id",
		"_battle_awareness_unit_snapshot",
		"_source_target_candidate_facts",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleAwarenessService boundary token: %s" % token)
			return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.battle_awareness_service == null:
		_fail("main did not instantiate BattleAwarenessService.")
		return
	print("BATTLE_AWARENESS_SERVICE_CONTRACT_PROBE ok points=%d enemies=%s" % [points.size(), str(enemies)])
	quit(0)
