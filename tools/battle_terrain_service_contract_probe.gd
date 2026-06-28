extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_terrain_service.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _expect_eq(actual, expected, message: String) -> bool:
	if actual != expected:
		_fail("%s expected=%s actual=%s" % [message, str(expected), str(actual)])
		return false
	return true


func _expect_close(actual: float, expected: float, message: String, tolerance: float = 0.001) -> bool:
	if absf(actual - expected) > tolerance:
		_fail("%s expected=%.4f actual=%.4f" % [message, expected, actual])
		return false
	return true


func _init() -> void:
	var source := FileAccess.get_file_as_string(SERVICE_PATH)
	if source.is_empty():
		_fail("BattleTerrainService is missing.")
		return
	for token in [
		"func normalize_feature",
		"func arena_snapshot",
		"func features_with_tag",
		"func features_for_kind",
		"func features_overlapping_point",
		"func placement_query",
		"func combined_occlusion_candidates",
		"func combined_collision_candidates",
	]:
		if not source.contains(token):
			_fail("BattleTerrainService missing boundary token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "Fighter", "take_hit", "queue_free", "randf", "randi", "Time"]:
		if source.contains(forbidden):
			_fail("BattleTerrainService contains forbidden runtime token: %s" % forbidden)
			return

	var script = load(SERVICE_PATH)
	if script == null:
		_fail("Unable to load BattleTerrainService.")
		return
	var service = script.new()

	var wall: Dictionary = service.normalize_feature({
		"id": "wall-alpha",
		"kind": "WALL",
		"collider": {"shape": "circle", "center": Vector2(2.0, 0.0), "radius": 0.5},
		"orientation": Vector2(0.0, 2.0),
		"surface_tags": ["Stone", "cover", "stone", ""],
		"owner_id": 2,
		"destructible": true,
		"anchor_points": [
			{"id": "socket-a", "position": Vector2(2.0, 0.5), "normal": Vector2(0.0, 4.0), "supports": ["Barrier_Panel", "barrier_panel"]},
		],
		"effect_channels": ["Collision", "occlusion", "collision"],
	}, 0)
	if not _expect_eq(String(wall.get("feature_id", "")), "wall-alpha", "feature id"):
		return
	if not _expect_eq(String(wall.get("terrain_kind", "")), "wall", "terrain kind"):
		return
	if not _expect_eq(Array(wall.get("surface_tags", [])), ["cover", "stone"], "surface tags normalized"):
		return
	if not _expect_eq(int(wall.get("owner_id", 0)), 2, "owner id"):
		return
	if not _expect(bool(wall.get("destructible", false)), "destructible flag"):
		return
	if not _expect_eq(Array(wall.get("effect_channels", [])), ["collision", "occlusion"], "effect channels normalized"):
		return
	if not _expect_close(Vector2(wall.get("orientation", Vector2.ZERO)).length(), 1.0, "orientation normalized"):
		return
	var anchors: Array = Array(wall.get("anchor_points", []))
	if not _expect_eq(anchors.size(), 1, "anchor count"):
		return
	var anchor := Dictionary(anchors[0])
	if not _expect_eq(String(anchor.get("anchor_id", "")), "socket-a", "anchor id"):
		return
	if not _expect_eq(Array(anchor.get("supports", [])), ["barrier_panel"], "anchor supports normalized"):
		return
	if not _expect_close(Vector2(anchor.get("normal", Vector2.ZERO)).length(), 1.0, "anchor normal normalized"):
		return

	var gap: Dictionary = service.normalize_feature({
		"terrain_kind": "gap",
		"collider": {"shape": "circle", "center": Vector2(5.0, 0.0), "radius": 0.4},
		"surface_tags": "void",
		"effect_channels": "traversal",
	}, 4)
	if not _expect_eq(String(gap.get("feature_id", "")), "terrain_004", "fallback feature id"):
		return
	if not _expect_eq(Array(gap.get("surface_tags", [])), ["void"], "single tag normalized"):
		return

	var snapshot: Dictionary = service.arena_snapshot({
		"arena_id": "mobius_test",
		"version": 7,
		"features": [wall, gap],
	})
	if not _expect_eq(String(snapshot.get("arena_id", "")), "mobius_test", "snapshot arena id"):
		return
	if not _expect_eq(int(snapshot.get("version", 0)), 7, "snapshot version"):
		return
	if not _expect_eq(Array(snapshot.get("features", [])).size(), 2, "snapshot feature count"):
		return
	if not _expect_eq(Array(service.features_with_tag(snapshot, "stone")).size(), 1, "tag query"):
		return
	if not _expect_eq(Array(service.features_for_kind(snapshot, "gap")).size(), 1, "kind query"):
		return
	if not _expect_eq(Array(service.features_overlapping_point(snapshot, Vector2(2.1, 0.0), 0.05)).size(), 1, "overlap query"):
		return

	var blocked: Dictionary = service.placement_query({
		"snapshot": snapshot,
		"position": Vector2(2.0, 0.0),
		"radius": 0.1,
		"blocked_kinds": ["wall"],
	})
	if not _expect_eq(String(blocked.get("outcome", "")), "blocked", "blocked placement outcome"):
		return
	if not _expect_eq(String(blocked.get("feature_id", "")), "wall-alpha", "blocked feature id"):
		return
	if not _expect(String(blocked.get("reason", "")).begins_with("blocked_"), "blocked reason should be stable and readable: %s" % str(blocked)):
		return

	var attach: Dictionary = service.placement_query({
		"snapshot": snapshot,
		"position": Vector2(2.0, 0.4),
		"radius": 0.05,
		"attach_kinds": ["wall"],
	})
	if not _expect_eq(String(attach.get("outcome", "")), "attach", "attach placement outcome"):
		return
	if not _expect_eq(String(attach.get("anchor_id", "")), "socket-a", "attach anchor id"):
		return

	var bridge: Dictionary = service.placement_query({
		"snapshot": snapshot,
		"position": Vector2(5.0, 0.0),
		"radius": 0.05,
		"bridge_kinds": ["gap"],
	})
	if not _expect_eq(String(bridge.get("outcome", "")), "bridge", "bridge placement outcome"):
		return

	var free: Dictionary = service.placement_query({
		"snapshot": snapshot,
		"position": Vector2(8.0, 0.0),
		"radius": 0.05,
		"blocked_kinds": ["wall"],
		"attach_kinds": ["wall"],
		"bridge_kinds": ["gap"],
	})
	if not _expect_eq(String(free.get("outcome", "")), "free", "free placement outcome"):
		return

	var candidates: Array = service.combined_occlusion_candidates(snapshot, [
		{"source": "barrier", "kind": "solid", "feature_id": "barrier-panel"},
	])
	if not _expect_eq(candidates.size(), 2, "combined occlusion candidate count"):
		return
	var terrain_candidate := Dictionary(candidates[0])
	if not _expect_eq(String(terrain_candidate.get("source", "")), "terrain", "terrain candidate source"):
		return
	if not _expect_eq(String(terrain_candidate.get("feature_id", "")), "wall-alpha", "terrain candidate feature id"):
		return
	var collision_candidates: Array = service.combined_collision_candidates(snapshot, [
		{"source": "static", "feature_id": "scripted-lock"},
	])
	if not _expect_eq(collision_candidates.size(), 2, "combined collision candidate count"):
		return
	var terrain_collision_candidate := Dictionary(collision_candidates[0])
	if not _expect_eq(String(terrain_collision_candidate.get("source", "")), "terrain", "terrain collision candidate source"):
		return
	if not _expect_eq(String(terrain_collision_candidate.get("feature_id", "")), "wall-alpha", "terrain collision candidate feature id"):
		return
	if not _expect_eq(Array(terrain_collision_candidate.get("surface_tags", [])), ["cover", "stone"], "terrain collision candidate tags"):
		return
	if failed:
		quit(1)
		return
	print("BATTLE_TERRAIN_SERVICE_CONTRACT_PROBE ok")
	quit(0)
