extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainService := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"BattleTerrainService",
		"BarrierTerrainInteractionService",
		"func _battle_terrain_runtime_snapshot",
		"func _apply_barrier_terrain_deployment",
		"_barrier_terrain_interaction_service().barrier_placement_intent",
		"_barrier_terrain_interaction_service().terrain_deployment_intents",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing barrier terrain runtime integration token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "runtime_barrier_terrain_probe",
		"version": 1,
		"features": [
			{
				"id": "wall-alpha",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(3.25, 0.9), "radius": 0.42},
				"orientation": Vector2(0.0, 1.0),
				"surface_tags": ["cover"],
				"effect_channels": ["collision", "occlusion"],
				"anchor_points": [
					{"id": "anchor-a", "position": Vector2(3.25, 0.9), "normal": Vector2(0.0, 1.0), "supports": ["barrier_panel"]},
				],
			},
		],
	})

	var stats := {
		"name": "Runtime Terrain Barrier",
		"health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.08,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"name": "Runtime Terrain Tile",
				"terrain_policy": {
					"attach_kinds": ["wall"],
					"anchor_support": "barrier_panel",
					"inherit_orientation": true,
				},
			},
		],
	}
	var stats_before := str(stats)
	var barrier = main._create_unit(1, "barrier", stats, "P1 Terrain Barrier", 3.25, 0.9)
	main._assign_unit_role(barrier, "barrier")
	if not main._is_live_unit(barrier):
		_fail("Runtime terrain barrier was not created.")
		return
	if not _expect(str(stats) == stats_before, "_create_unit should not mutate caller barrier stats"):
		return

	var placements: Array = Array(barrier.get_meta("barrier_terrain_placement_intents", []))
	if not _expect(placements.size() == 1, "barrier should record one terrain placement intent: %s" % str(placements)):
		return
	var placement := Dictionary(placements[0])
	if not _expect(bool(placement.get("allowed", false)) and String(placement.get("outcome", "")) == "attach", "placement should attach: %s" % str(placement)):
		return
	if not _expect(String(placement.get("feature_id", "")) == "wall-alpha" and String(placement.get("anchor_id", "")) == "anchor-a", "placement should identify terrain feature/anchor: %s" % str(placement)):
		return
	if not _expect(Vector2(placement.get("orientation", Vector2.ZERO)) == Vector2(0.0, 1.0), "placement should inherit terrain orientation: %s" % str(placement)):
		return

	var deployment_intents: Array = Array(barrier.get_meta("barrier_terrain_deployment_intents", []))
	if not _expect(deployment_intents.size() == 2, "barrier should record attach and orientation deployment intents: %s" % str(deployment_intents)):
		return
	if not _expect(String(Dictionary(deployment_intents[0]).get("action", "")) == "attach_to_terrain", "first deployment intent should attach: %s" % str(deployment_intents)):
		return
	if not _expect(String(Dictionary(deployment_intents[1]).get("action", "")) == "inherit_terrain_orientation", "second deployment intent should inherit orientation: %s" % str(deployment_intents)):
		return
	if not _expect(Array(barrier.get_meta("barrier_terrain_blocked_tiles", [])).is_empty(), "attached barrier should not record blocked tiles"):
		return

	print("BARRIER_TERRAIN_RUNTIME_INTEGRATION_PROBE intents=%d feature=%s" % [
		deployment_intents.size(),
		String(placement.get("feature_id", "")),
	])
	quit(0)
