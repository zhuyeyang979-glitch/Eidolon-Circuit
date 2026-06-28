extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleActorCommandServiceScript := preload("res://scripts/services/battle_actor_command_service.gd")
const BattleTerrainServiceScript := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, extra_stats: Dictionary = {}):
	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 12.0,
		"radius": 0.18,
		"speed": 1.0,
		"cooling": 20.0,
		"teamedit_runtime_topology": false,
	}
	for key in extra_stats.keys():
		stats[key] = extra_stats[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _init() -> void:
	var terrain_source := FileAccess.get_file_as_string("res://scripts/services/battle_terrain_service.gd")
	var command_source := FileAccess.get_file_as_string("res://scripts/services/battle_actor_command_service.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func traversal_query",
		"bridge_terrain_gap",
		"terrain_path_plan",
	]:
		if not (terrain_source + command_source + main_source).contains(token):
			_fail("Terrain path planning integration missing token: %s" % token)
			return

	_check_pure_traversal_query()
	_check_puppet_path_plan_runtime()
	print("TERRAIN_PATH_PLANNING_PROBE ok")
	quit(0)


func _terrain_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_path_planning_probe",
		"version": 1,
		"features": [
			{
				"id": "north-gap",
				"kind": "gap",
				"collider": {"shape": "circle", "center": Vector2(4.0, 1.0), "radius": 0.42},
				"orientation": Vector2(1.0, 0.0),
				"surface_tags": ["gap", "route", "bridgeable"],
				"effect_channels": ["traversal"],
			},
		],
	})


func _check_pure_traversal_query() -> void:
	var service = BattleTerrainServiceScript.new()
	var snapshot := _terrain_snapshot()
	var blocked: Dictionary = service.traversal_query({
		"snapshot": snapshot,
		"start": Vector2(3.0, 1.0),
		"target": Vector2(5.0, 1.0),
		"radius": 0.1,
		"ring_length": 12.0,
	})
	if not _expect(String(blocked.get("mode", "")) == "blocked", "Unbridged gap should block traversal: %s" % str(blocked)):
		return
	if not _expect(bool(blocked.get("blocked", false)), "Unbridged gap should set blocked=true: %s" % str(blocked)):
		return
	if not _expect(String(blocked.get("feature_id", "")) == "north-gap", "Blocked path should identify gap: %s" % str(blocked)):
		return
	if not _expect(blocked.get("recommended_direction", Vector2.ZERO) is Vector2 and Vector2(blocked.get("recommended_direction", Vector2.ZERO)).length() > 0.1, "Blocked path should expose detour direction: %s" % str(blocked)):
		return

	var bridged: Dictionary = service.traversal_query({
		"snapshot": snapshot,
		"start": Vector2(3.0, 1.0),
		"target": Vector2(5.0, 1.0),
		"radius": 0.1,
		"ring_length": 12.0,
		"bridge_intents": [
			{"action": "bridge_terrain_gap", "feature_id": "north-gap", "tile_id": "bridge-panel"},
		],
	})
	if not _expect(String(bridged.get("mode", "")) == "bridged", "Bridge intent should open traversal gap: %s" % str(bridged)):
		return
	if not _expect(not bool(bridged.get("blocked", true)), "Bridged gap should not block traversal: %s" % str(bridged)):
		return
	if not _expect(bool(bridged.get("bridge_active", false)), "Bridged gap should report bridge_active: %s" % str(bridged)):
		return


func _check_puppet_path_plan_runtime() -> void:
	var command_service = BattleActorCommandServiceScript.new()
	var blocked_intent: Dictionary = command_service.puppet_move_intent({
		"unit": {"live": true, "ring": 3.0, "lane": 1.0, "facing": 1, "stats": {"ai": "line", "source_rules": {"default": {"move": "approach"}}, "move_speed": 1.0}},
		"target": {"live": true, "ring": 5.0, "lane": 1.0, "stats": {}},
		"delta": 0.1,
		"delta_ring": 2.0,
		"delta_lane": 0.0,
		"ring_length": 12.0,
		"battle_half_height": 3.0,
		"source_rule": {"move": "approach"},
		"terrain_path_plan": {"mode": "blocked", "blocked": true, "feature_id": "north-gap", "terrain_kind": "gap", "recommended_direction": Vector2(0.0, 1.0)},
	})
	if not _expect(String(blocked_intent.get("terrain_path_mode", "")) == "blocked", "Puppet move intent should echo blocked terrain path: %s" % str(blocked_intent)):
		return
	if not _expect(Vector2(blocked_intent.get("move", Vector2.ZERO)).y > 0.2, "Blocked terrain path should steer puppet toward detour: %s" % str(blocked_intent)):
		return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _terrain_snapshot()
	var puppet = _spawn_unit(main, 1, "puppet", "Terrain Path Puppet", 3.0, 1.0, {
		"ai": "line",
		"source_rules": {"default": {"move": "approach", "modules": [0], "states": ["normal"]}},
		"hold_range": 0.5,
		"source_keep_range": 0.5,
	})
	var target = _spawn_unit(main, 2, "hero", "Terrain Path Target", 5.0, 1.0)
	var condition := "default"
	var blocked_move: Vector2 = main._puppet_move_vector(puppet, target, 1, 0, 1, 0.1, condition)
	var blocked_plan: Dictionary = Dictionary(puppet.get_meta("terrain_path_plan", {}))
	if not _expect(String(blocked_plan.get("mode", "")) == "blocked", "Runtime puppet should remember blocked terrain path: %s move=%s" % [str(blocked_plan), str(blocked_move)]):
		return
	if not _expect(blocked_move.y > 0.2, "Runtime puppet should detour around unbridged gap, move=%s plan=%s" % [str(blocked_move), str(blocked_plan)]):
		return

	var barrier_stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "bridge-panel",
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.08,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"terrain_policy": {"bridge_kinds": ["gap"], "radius": 0.5},
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", barrier_stats, "P1 Bridge Barrier", 4.0, 1.0)
	main._assign_unit_role(barrier, "barrier")
	var bridged_move: Vector2 = main._puppet_move_vector(puppet, target, 1, 0, 1, 0.1, condition)
	var bridged_plan: Dictionary = Dictionary(puppet.get_meta("terrain_path_plan", {}))
	if not _expect(String(bridged_plan.get("mode", "")) == "bridged", "Runtime bridge barrier should open terrain path: %s move=%s" % [str(bridged_plan), str(bridged_move)]):
		return
	if not _expect(bridged_move.x > 0.5 and absf(bridged_move.y) < 0.3, "Bridged terrain path should let puppet approach across gap, move=%s plan=%s" % [str(bridged_move), str(bridged_plan)]):
		return
