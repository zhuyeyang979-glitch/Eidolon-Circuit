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


func _array_has_tile_id(items: Array, tile_id: String) -> bool:
	for raw_item in items:
		if raw_item is Dictionary and String(Dictionary(raw_item).get("tile_id", "")) == tile_id:
			return true
	return false


func _array_has_feature_id(items: Array, feature_id: String) -> bool:
	for raw_item in items:
		if raw_item is Dictionary and String(Dictionary(raw_item).get("feature_id", "")) == feature_id:
			return true
	return false


func _tiles_have_index(tiles: Array, tile_index: int) -> bool:
	for raw_tile in tiles:
		if raw_tile is Dictionary and int(Dictionary(raw_tile).get("index", -1)) == tile_index:
			return true
	return false


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _remove_barrier_tile_by_index",
		"func _apply_barrier_terrain_deployment",
		"barrier_terrain_placement_intents",
		"barrier_terrain_deployment_intents",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing barrier terrain invalidation token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	main.battle_terrain_runtime_snapshot = terrain_service.arena_snapshot({
		"arena_id": "barrier_terrain_destruction_invalidation_probe",
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
				"index": 7,
				"tile_id": "attached-tile",
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.08,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"name": "Attached Runtime Terrain Tile",
				"terrain_policy": {
					"attach_kinds": ["wall"],
					"anchor_support": "barrier_panel",
					"inherit_orientation": true,
				},
			},
			{
				"index": 8,
				"tile_id": "free-tile",
				"local_ring": 1.2,
				"local_lane": 0.0,
				"radius": 0.08,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"name": "Remaining Runtime Terrain Tile",
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", stats, "P1 Terrain Barrier", 3.25, 0.9)
	main._assign_unit_role(barrier, "barrier")
	if not _expect(main._is_live_unit(barrier), "Runtime terrain barrier was not created."):
		return

	var placements_before: Array = Array(barrier.get_meta("barrier_terrain_placement_intents", []))
	var deployments_before: Array = Array(barrier.get_meta("barrier_terrain_deployment_intents", []))
	if not _expect(_array_has_tile_id(placements_before, "attached-tile"), "Initial placement should include attached tile: %s" % str(placements_before)):
		return
	if not _expect(_array_has_feature_id(deployments_before, "wall-alpha"), "Initial deployment should include wall-alpha attachment: %s" % str(deployments_before)):
		return

	if not _expect(main._remove_barrier_tile_by_index(barrier, 7), "Removing attached tile should succeed."):
		return
	var remaining_tiles: Array = Array(barrier.stats.get("barrier_map_tiles", []))
	if not _expect(not _tiles_have_index(remaining_tiles, 7), "Removed tile should be absent from barrier map tiles: %s" % str(remaining_tiles)):
		return

	var placements_after: Array = Array(barrier.get_meta("barrier_terrain_placement_intents", []))
	var deployments_after: Array = Array(barrier.get_meta("barrier_terrain_deployment_intents", []))
	if not _expect(not _array_has_tile_id(placements_after, "attached-tile"), "Removed attached tile should be invalidated from placements: %s" % str(placements_after)):
		return
	if not _expect(not _array_has_feature_id(placements_after, "wall-alpha"), "Removed terrain feature should be invalidated from placements: %s" % str(placements_after)):
		return
	if not _expect(not _array_has_tile_id(deployments_after, "attached-tile"), "Removed attached tile should be invalidated from deployment intents: %s" % str(deployments_after)):
		return
	if not _expect(not _array_has_feature_id(deployments_after, "wall-alpha"), "Removed terrain feature should be invalidated from deployment intents: %s" % str(deployments_after)):
		return
	if not _expect(_array_has_tile_id(placements_after, "free-tile"), "Remaining tile should keep refreshed placement metadata: %s" % str(placements_after)):
		return
	if not _expect(String(barrier.get_meta("barrier_terrain_snapshot_arena_id", "")) == "barrier_terrain_destruction_invalidation_probe", "Barrier should keep current terrain snapshot id."):
		return

	print("BARRIER_TERRAIN_DESTRUCTION_INVALIDATION_PROBE ok remaining=%d placements=%d deployments=%d" % [
		remaining_tiles.size(),
		placements_after.size(),
		deployments_after.size(),
	])
	quit(0)
