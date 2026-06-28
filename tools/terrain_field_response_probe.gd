extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleFieldRuntimeServiceScript := preload("res://scripts/services/battle_field_runtime_service.gd")
const BattleTerrainServiceScript := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _expect_close(actual: float, expected: float, message: String, epsilon: float = 0.001) -> bool:
	return _expect(absf(actual - expected) <= epsilon, "%s expected %.4f got %.4f" % [message, expected, actual])


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
	var service_source := FileAccess.get_file_as_string("res://scripts/services/battle_field_runtime_service.gd")
	for token in [
		"terrain_response",
		"terrain_features",
		"surface_tags",
		"route_connected",
	]:
		if not service_source.contains(token):
			_fail("BattleFieldRuntimeService missing terrain field response token: %s" % token)
			return

	var service = BattleFieldRuntimeServiceScript.new()
	_check_pure_field_responses(service)
	_check_runtime_gravity_surface_vector()
	print("TERRAIN_FIELD_RESPONSE_PROBE ok")
	quit(0)


func _check_pure_field_responses(service) -> void:
	var terrain_feature := {
		"feature_id": "terrain-route-vector",
		"terrain_kind": "floor",
		"orientation": Vector2(0.0, 1.0),
		"surface_tags": ["route", "gravity_vector", "gravity_amp", "coolant_amp"],
	}
	var gravity: Dictionary = service.field_effect_intent({
		"kind": "gravity",
		"stats": {"gravity_force": 0.4, "gravity_radius": 0.7, "gravity_direction": "right"},
		"delta": 0.5,
		"terrain_features": [terrain_feature],
	})
	if not _expect(String(gravity.get("mode", "")) == "terrain_surface", "Gravity should follow terrain surface vector: %s" % str(gravity)):
		return
	if not _expect(gravity.get("direction_vector", Vector2.ZERO) is Vector2, "Gravity should expose terrain direction vector: %s" % str(gravity)):
		return
	if not _expect_close(Vector2(gravity.get("direction_vector", Vector2.ZERO)).y, 1.0, "Gravity terrain direction y"):
		return
	if not _expect(float(gravity.get("force", 0.0)) > 0.4, "Gravity terrain amp should increase force: %s" % str(gravity)):
		return
	var gravity_response: Dictionary = Dictionary(gravity.get("terrain_response", {}))
	if not _expect(String(gravity_response.get("feature_id", "")) == "terrain-route-vector", "Gravity should report terrain response feature: %s" % str(gravity_response)):
		return

	var coolant_base: Dictionary = service.field_effect_intent({"kind": "coolant", "stats": {"coolant_boost": 20.0, "coolant_radius": 0.6}, "delta": 0.5})
	var coolant_amp: Dictionary = service.field_effect_intent({"kind": "coolant", "stats": {"coolant_boost": 20.0, "coolant_radius": 0.6}, "delta": 0.5, "terrain_features": [terrain_feature]})
	if not _expect(float(coolant_amp.get("heat_delta", 0.0)) > float(coolant_base.get("heat_delta", 0.0)), "Coolant terrain tag should amplify cooling: base=%s amp=%s" % [str(coolant_base), str(coolant_amp)]):
		return

	var coolant_floor := {
		"feature_id": "coolant-floor",
		"terrain_kind": "floor",
		"orientation": Vector2.RIGHT,
		"surface_tags": ["coolant", "heat_damp"],
	}
	var heat_base: Dictionary = service.field_effect_intent({"kind": "heat", "stats": {"heat_field_rate": 18.0, "heat_field_radius": 0.6}, "delta": 0.5, "target_cooling": 45.0})
	var heat_damped: Dictionary = service.field_effect_intent({"kind": "heat", "stats": {"heat_field_rate": 18.0, "heat_field_radius": 0.6}, "delta": 0.5, "target_cooling": 45.0, "terrain_features": [coolant_floor]})
	if not _expect(float(heat_damped.get("heat_delta", 0.0)) < float(heat_base.get("heat_delta", 0.0)), "Coolant terrain should damp heat field: base=%s damped=%s" % [str(heat_base), str(heat_damped)]):
		return

	var speed_base: Dictionary = service.speed_lane_intent({"stats": {"speed_lane_mult": 1.5, "speed_lane_pull": 0.36}, "delta": 0.1, "velocity": Vector2(0.4, 0.0), "unit_speed": 1.0})
	var speed_route: Dictionary = service.speed_lane_intent({"stats": {"speed_lane_mult": 1.5, "speed_lane_pull": 0.36}, "delta": 0.1, "velocity": Vector2(0.4, 0.0), "unit_speed": 1.0, "terrain_features": [terrain_feature]})
	if not _expect(bool(speed_route.get("route_connected", false)), "Speed lane should report route connection: %s" % str(speed_route)):
		return
	if not _expect(float(speed_route.get("mult", 0.0)) > float(speed_base.get("mult", 0.0)), "Speed route terrain should boost lane mult: base=%s route=%s" % [str(speed_base), str(speed_route)]):
		return


func _check_runtime_gravity_surface_vector() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainServiceScript.new()
	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "terrain_field_response_probe",
		"version": 1,
		"features": [
			{
				"id": "gravity-route-floor",
				"kind": "floor",
				"collider": {"shape": "circle", "center": Vector2(3.25, 0.9), "radius": 0.55},
				"orientation": Vector2(0.0, 1.0),
				"surface_tags": ["route", "gravity_vector", "gravity_amp"],
				"effect_channels": ["field"],
			},
		],
	})
	var barrier_stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"is_gravity_field": true,
		"gravity_force": 0.4,
		"gravity_direction": "right",
		"gravity_radius": 0.8,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "gravity-tile",
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.08,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "gravity_field",
				"effect_tags": ["gravity"],
				"field_radius": 0.8,
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", barrier_stats, "P1 Terrain Gravity Barrier", 3.25, 0.9)
	main._assign_unit_role(barrier, "barrier")
	var target = _spawn_unit(main, 2, "hero", "Terrain Gravity Target", 3.25, 1.05)
	target.velocity = Vector2.ZERO
	main._apply_gravity_field(barrier, 1, 1.0)
	var response: Dictionary = Dictionary(barrier.get_meta("terrain_field_response_gravity", {}))
	if not _expect(String(response.get("feature_id", "")) == "gravity-route-floor", "Runtime gravity should remember terrain field response: %s" % str(response)):
		return
	if not _expect(target.velocity.y > absf(target.velocity.x), "Runtime gravity should follow terrain surface vector, velocity=%s" % str(target.velocity)):
		return
