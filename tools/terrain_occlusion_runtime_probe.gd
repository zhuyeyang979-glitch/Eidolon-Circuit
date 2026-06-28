extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainService := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, role_key: String, name: String, ring: float, lane: float, stats_extra: Dictionary = {}):
	var stats := {
		"health": 120,
		"max_health": 120,
		"mass": 20.0,
		"radius": 0.14,
		"teamedit_runtime_topology": false,
	}
	for key in stats_extra.keys():
		stats[key] = stats_extra[key]
	var unit = main._create_unit(owner, role_key, stats, name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _projectile_source() -> Dictionary:
	return {
		"projectile": true,
		"projectile_only": true,
		"material_class": "gun",
		"shape": "rifle",
		"gun_kind": "rifle",
		"ammo_kind": "laser",
	}


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"_battle_terrain_service().combined_occlusion_candidates",
		"blocker_source",
		"terrain_feature_id",
		"terrain_kind",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing terrain occlusion integration token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "terrain_occlusion_runtime_probe",
		"version": 1,
		"features": [
			{
				"id": "terrain-wall-alpha",
				"name": "TERRAIN WALL ALPHA",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(6.0, 0.0), "radius": 0.22},
				"effect_channels": ["collision", "occlusion"],
				"surface_tags": ["cover"],
			},
		],
	})

	var attacker = _spawn_unit(main, 1, "hero", "TERRAIN OCCLUSION USER", 5.0, 0.0, {"ammo_capacity": {"laser": 7}})
	var target = _spawn_unit(main, 2, "hero", "TERRAIN COVERED HERO", 7.0, 0.0)
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": target, "barrier": null, "puppet": []}}

	var event := {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "laser_beam_activate",
		"projectile_behavior": "laser",
		"projectile_style": "beam",
		"travel_path": "instant_line",
		"damage_type": "laser",
		"projectile_damage_type": "laser",
		"direction": Vector2.RIGHT,
		"range": 3.0,
		"lane_range": 0.08,
		"collision_group": _projectile_source(),
		"muscle_node": 0,
	}
	var query: Dictionary = main._map_occlusion_query_between(attacker, target, event)
	if String(query.get("kind", "")) != MainScene.MAP_OCCLUSION_SOLID:
		_fail("Terrain wall should produce a solid occlusion query: %s" % str(query))
		return
	if String(query.get("blocker_source", "")) != "terrain":
		_fail("Terrain occlusion query should identify terrain source: %s" % str(query))
		return
	if String(query.get("terrain_feature_id", "")) != "terrain-wall-alpha":
		_fail("Terrain occlusion query should preserve feature id: %s" % str(query))
		return
	if not main._map_line_occluded(attacker, target, event):
		_fail("Terrain wall should occlude line helper.")
		return
	if not main._attack_part_hit(attacker, target, event).is_empty():
		_fail("Laser beam should not hit through terrain occlusion.")
		return
	if String(event.get("map_occlusion_kind", "")) != MainScene.MAP_OCCLUSION_SOLID:
		_fail("Laser event should record solid terrain occlusion: %s" % str(event))
		return
	if String(event.get("map_occlusion_blocker", "")) != "TERRAIN WALL ALPHA":
		_fail("Laser event should record terrain blocker name: %s" % str(event))
		return

	print("TERRAIN_OCCLUSION_RUNTIME_PROBE ok feature=%s kind=%s" % [
		String(query.get("terrain_feature_id", "")),
		String(query.get("kind", "")),
	])
	quit(0)
