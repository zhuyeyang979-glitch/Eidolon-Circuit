extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _feature_by_id(features: Array, feature_id: String) -> Dictionary:
	for raw_feature in features:
		if raw_feature is Dictionary and String(Dictionary(raw_feature).get("feature_id", "")) == feature_id:
			return Dictionary(raw_feature)
	return {}


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _default_battle_terrain_snapshot_context",
		"mobius_default_arena",
		"mobius_mid_cover_north",
		"mobius_gap_north_route",
		"mobius_midfield_fold_gate",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing authored arena terrain token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	if not _expect(String(snapshot.get("arena_id", "")) == "mobius_default_arena", "default arena id should be authored: %s" % str(snapshot)):
		return
	var features: Array = Array(snapshot.get("features", []))
	if not _expect(features.size() >= 3, "default arena should include authored terrain features: %s" % str(features)):
		return
	var cover := _feature_by_id(features, "mobius_mid_cover_north")
	if not _expect(not cover.is_empty(), "default arena missing north cover feature"):
		return
	if not _expect(String(cover.get("terrain_kind", "")) == "wall", "north cover should be wall terrain"):
		return
	if not _expect(Array(cover.get("effect_channels", [])).has("collision") and Array(cover.get("effect_channels", [])).has("occlusion"), "north cover should feed collision and occlusion"):
		return
	if not _expect(Array(cover.get("anchor_points", [])).size() > 0, "north cover should expose barrier anchor"):
		return
	var gap := _feature_by_id(features, "mobius_gap_north_route")
	if not _expect(not gap.is_empty() and String(gap.get("terrain_kind", "")) == "gap", "default arena should include a gap marker"):
		return
	var portal := _feature_by_id(features, "mobius_midfield_fold_gate")
	if not _expect(not portal.is_empty() and String(portal.get("terrain_kind", "")) == "portal", "default arena should include a portal marker"):
		return
	if not _expect(Array(portal.get("effect_channels", [])).has("portal"), "default portal should expose portal effect channel"):
		return

	var collision_candidates: Array = main._terrain_collision_candidates_for_runtime()
	if not _expect(collision_candidates.size() >= 2, "default authored terrain should produce collision candidates: %s" % str(collision_candidates)):
		return
	var occlusion_candidates: Array = main._battle_terrain_service().combined_occlusion_candidates(snapshot, [])
	if not _expect(occlusion_candidates.size() >= 2, "default authored terrain should produce occlusion candidates: %s" % str(occlusion_candidates)):
		return

	var cover_center: Vector2 = Dictionary(cover.get("collider", {})).get("center", Vector2.ZERO)
	var stats := {
		"name": "Default Arena Anchor Barrier",
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
				"name": "Default Arena Anchor Tile",
				"terrain_policy": {
					"attach_kinds": ["wall"],
					"anchor_support": "barrier_panel",
					"inherit_orientation": true,
				},
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", stats, "P1 Default Arena Barrier", cover_center.x, cover_center.y)
	main._assign_unit_role(barrier, "barrier")
	var placements: Array = Array(barrier.get_meta("barrier_terrain_placement_intents", []))
	if not _expect(placements.size() == 1, "default terrain barrier should record one placement: %s" % str(placements)):
		return
	var placement := Dictionary(placements[0])
	if not _expect(bool(placement.get("allowed", false)) and String(placement.get("feature_id", "")) == "mobius_mid_cover_north", "default terrain should support barrier attach: %s" % str(placement)):
		return

	print("AUTHORED_ARENA_TERRAIN_RUNTIME_PROBE ok features=%d collision=%d occlusion=%d attach=%s" % [
		features.size(),
		collision_candidates.size(),
		occlusion_candidates.size(),
		String(placement.get("feature_id", "")),
	])
	quit(0)
