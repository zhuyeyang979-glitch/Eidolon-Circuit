extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainService := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, stats_extra: Dictionary = {}):
	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.14,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _source_target_awareness_facts",
		"sight_occlusion_kind",
		"sight_blocker_source",
		"sight_terrain_feature_id",
		"sight_terrain_kind",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing terrain awareness metadata token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	var puppet = _spawn_unit(main, 1, "puppet", "TERRAIN AWARENESS PUPPET", 5.0, 0.0, {"source_target_policy": "hero_low_hp_ranged"})
	var target = _spawn_unit(main, 2, "hero", "TERRAIN AWARENESS TARGET", 6.4, 0.0)
	main.active_units = {1: {"hero": null, "barrier": null, "puppet": [puppet]}, 2: {"hero": target, "barrier": null, "puppet": []}}

	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "terrain_awareness_metadata_probe_empty",
		"version": 1,
		"features": [],
	})
	var clear_facts: Dictionary = main._source_target_awareness_facts(puppet, target, 1, "hero_low_hp_ranged")
	var clear_score := main._source_target_score(puppet, target, 1, "hero_low_hp_ranged")
	_assert_eq(bool(clear_facts.get("sight_blocked", true)), false, "clear sight should not be blocked")
	_assert_eq(String(clear_facts.get("sight_blocker_source", "missing")), "", "clear sight source should be empty")
	_assert_eq(String(clear_facts.get("sight_terrain_feature_id", "missing")), "", "clear sight terrain id should be empty")

	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "terrain_awareness_metadata_probe",
		"version": 1,
		"features": [
			{
				"id": "terrain-awareness-wall",
				"name": "TERRAIN AWARENESS WALL",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(5.7, 0.0), "radius": 0.22},
				"effect_channels": ["collision", "occlusion"],
				"surface_tags": ["cover"],
			},
		],
	})
	var blocked_facts: Dictionary = main._source_target_awareness_facts(puppet, target, 1, "hero_low_hp_ranged")
	var blocked_score := main._source_target_score(puppet, target, 1, "hero_low_hp_ranged")
	_assert_eq(bool(blocked_facts.get("sight_blocked", false)), true, "terrain sight should be blocked")
	_assert_eq(String(blocked_facts.get("sight_occlusion_kind", "")), MainScene.MAP_OCCLUSION_SOLID, "terrain sight occlusion kind")
	_assert_eq(String(blocked_facts.get("sight_blocker_source", "")), "terrain", "terrain sight source")
	_assert_eq(String(blocked_facts.get("sight_terrain_feature_id", "")), "terrain-awareness-wall", "terrain sight feature id")
	_assert_eq(String(blocked_facts.get("sight_terrain_kind", "")), "wall", "terrain sight kind")
	if blocked_score >= clear_score - 60.0:
		_fail("Terrain awareness score should keep map occlusion penalty: clear=%.2f blocked=%.2f" % [clear_score, blocked_score])

	print("TERRAIN_AWARENESS_METADATA_PROBE ok clear=%.2f blocked=%.2f source=%s feature=%s" % [
		clear_score,
		blocked_score,
		String(blocked_facts.get("sight_blocker_source", "")),
		String(blocked_facts.get("sight_terrain_feature_id", "")),
	])
	quit(0)
