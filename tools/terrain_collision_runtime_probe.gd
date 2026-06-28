extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainService := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, stats_extra: Dictionary = {}):
	var stats := {
		"health": 140,
		"max_health": 140,
		"mass": 24.0,
		"radius": 0.20,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _distance_to(point: Vector2, center: Vector2) -> float:
	return point.distance_to(center)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _separate_unit_from_terrain",
		"combined_collision_candidates",
		"terrain_collision_feature_id",
		"terrain_collision_kind",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing terrain collision integration token: %s" % token)
			return

	var terrain_source := FileAccess.get_file_as_string("res://scripts/services/battle_terrain_service.gd")
	if not terrain_source.contains("func combined_collision_candidates"):
		_fail("BattleTerrainService missing combined collision candidates.")
		return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	var terrain_center := Vector2(5.0, 0.0)
	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "terrain_collision_runtime_probe",
		"version": 1,
		"features": [
			{
				"id": "terrain-collision-wall",
				"name": "TERRAIN COLLISION WALL",
				"kind": "wall",
				"collider": {"shape": "circle", "center": terrain_center, "radius": 0.32},
				"effect_channels": ["collision"],
				"surface_tags": ["solid"],
			},
		],
	})
	var unit = _spawn_unit(main, 1, "hero", "TERRAIN COLLISION HERO", 5.12, 0.0)
	main.active_units = {1: {"hero": unit, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	var before := Vector2(float(unit.ring_pos), float(unit.lane))
	var before_distance := _distance_to(before, terrain_center)
	main._resolve_unit_body_spacing(1.0 / 60.0)
	var after := Vector2(float(unit.ring_pos), float(unit.lane))
	var after_distance := _distance_to(after, terrain_center)
	if after_distance <= before_distance + 0.04:
		_fail("Terrain collision should push unit away from terrain: before=%.3f after=%.3f before_pos=%s after_pos=%s" % [before_distance, after_distance, str(before), str(after)])
		return
	if String(unit.get_meta("terrain_collision_feature_id", "")) != "terrain-collision-wall":
		_fail("Unit should record terrain collision feature id: %s" % String(unit.get_meta("terrain_collision_feature_id", "")))
		return
	if String(unit.get_meta("terrain_collision_kind", "")) != "wall":
		_fail("Unit should record terrain collision kind: %s" % String(unit.get_meta("terrain_collision_kind", "")))
		return

	print("TERRAIN_COLLISION_RUNTIME_PROBE ok before=%.3f after=%.3f feature=%s" % [
		before_distance,
		after_distance,
		String(unit.get_meta("terrain_collision_feature_id", "")),
	])
	quit(0)
