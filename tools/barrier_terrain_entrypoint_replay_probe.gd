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


func _base_barrier_stats() -> Dictionary:
	return {
		"cost": 0,
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"structural_mass": 10.0,
		"energy": 0.0,
		"power_load": 0.0,
		"length": 0.0,
		"radius": 0.2,
		"resistances": {
			"bullet": 1.0,
			"chemical": 1.0,
			"laser": 1.0,
			"blunt": 1.0,
			"pierce": 1.0,
			"tear": 1.0,
		},
	}


func _placement_digest(placement: Dictionary) -> Dictionary:
	var orientation = placement.get("orientation", Vector2.ZERO)
	var orientation_value := Vector2.ZERO
	if orientation is Vector2:
		orientation_value = orientation
	return {
		"allowed": bool(placement.get("allowed", false)),
		"outcome": String(placement.get("outcome", "")),
		"reason": String(placement.get("reason", "")),
		"tile_id": String(placement.get("tile_id", "")),
		"feature_id": String(placement.get("feature_id", "")),
		"terrain_kind": String(placement.get("terrain_kind", "")),
		"anchor_id": String(placement.get("anchor_id", "")),
		"orientation": [snappedf(orientation_value.x, 0.001), snappedf(orientation_value.y, 0.001)],
	}


func _deployment_digest(intent: Dictionary) -> Dictionary:
	return {
		"action": String(intent.get("action", "")),
		"tile_id": String(intent.get("tile_id", "")),
		"feature_id": String(intent.get("feature_id", "")),
		"terrain_kind": String(intent.get("terrain_kind", "")),
		"anchor_id": String(intent.get("anchor_id", "")),
	}


func _entrypoint_digest(placements: Array, deployments: Array) -> Dictionary:
	var placement_rows: Array = []
	for raw_placement in placements:
		if raw_placement is Dictionary:
			placement_rows.append(_placement_digest(Dictionary(raw_placement)))
	var deployment_rows: Array = []
	for raw_intent in deployments:
		if raw_intent is Dictionary:
			deployment_rows.append(_deployment_digest(Dictionary(raw_intent)))
	return {
		"placements": placement_rows,
		"deployments": deployment_rows,
	}


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _barrier_terrain_editor_preview",
		"func _apply_barrier_tile_stats",
		"func _apply_barrier_terrain_deployment",
		"_barrier_terrain_interaction_service().barrier_placement_intent",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing barrier terrain entrypoint replay token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()

	var terrain_service = BattleTerrainService.new()
	var snapshot: Dictionary = terrain_service.arena_snapshot({
		"arena_id": "barrier_terrain_entrypoint_replay_probe",
		"version": 1,
		"features": [
			{
				"id": "wall-alpha",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(3.25, 0.9), "radius": 0.42},
				"orientation": Vector2(0.0, 1.0),
				"surface_tags": ["cover", "midfield"],
				"effect_channels": ["collision", "occlusion"],
				"anchor_points": [
					{"id": "anchor-a", "position": Vector2(3.25, 0.9), "normal": Vector2(0.0, 1.0), "supports": ["barrier_panel"]},
				],
			},
		],
	})
	main.battle_terrain_runtime_snapshot = snapshot.duplicate(true)

	var panel_index := main._component_index_by_exact_name("barrier", "muscle", "VAULT DIVIDEND BULKHEAD")
	if panel_index < 0:
		_fail("Missing barrier panel fixture for entrypoint replay probe.")
		return
	var terrain_policy := {
		"attach_kinds": ["wall"],
		"anchor_support": "barrier_panel",
		"inherit_orientation": true,
	}
	var unit_bp := {
		"role": "barrier",
		"name": "Replay Terrain Barrier",
		"muscle": panel_index,
		"barrier_tiles": [
			{
				"tile_id": "shared-tile",
				"pos": Vector2(0.5, 0.5),
				"muscle": panel_index,
				"terrain_policy": terrain_policy.duplicate(true),
			},
		],
	}
	var before_blueprint := str(unit_bp)

	var editor_preview_a: Dictionary = main._barrier_terrain_editor_preview(unit_bp, {"snapshot": snapshot, "preview_origin": Vector2(3.25, 0.9)})
	var editor_preview_b: Dictionary = main._barrier_terrain_editor_preview(unit_bp, {"snapshot": snapshot, "preview_origin": Vector2(3.25, 0.9)})
	if not _expect(str(unit_bp) == before_blueprint, "Editor replay preview should not mutate blueprint."):
		return
	var editor_digest_a := _entrypoint_digest(Array(editor_preview_a.get("placement_intents", [])), Array(editor_preview_a.get("deployment_intents", [])))
	var editor_digest_b := _entrypoint_digest(Array(editor_preview_b.get("placement_intents", [])), Array(editor_preview_b.get("deployment_intents", [])))
	if not _expect(editor_digest_a == editor_digest_b, "Repeated editor previews should be identical: a=%s b=%s" % [str(editor_digest_a), str(editor_digest_b)]):
		return

	var stats_a := _base_barrier_stats()
	main._apply_barrier_tile_stats(stats_a, "barrier", unit_bp)
	var barrier_a = main._create_unit(1, "barrier", stats_a, "P1 Replay Barrier A", 3.25, 0.9)
	main._assign_unit_role(barrier_a, "barrier")
	var runtime_digest_a := _entrypoint_digest(
		Array(barrier_a.get_meta("barrier_terrain_placement_intents", [])),
		Array(barrier_a.get_meta("barrier_terrain_deployment_intents", []))
	)
	main._clear_all_units()

	var stats_b := _base_barrier_stats()
	main._apply_barrier_tile_stats(stats_b, "barrier", unit_bp)
	var barrier_b = main._create_unit(1, "barrier", stats_b, "P1 Replay Barrier B", 3.25, 0.9)
	main._assign_unit_role(barrier_b, "barrier")
	var runtime_digest_b := _entrypoint_digest(
		Array(barrier_b.get_meta("barrier_terrain_placement_intents", [])),
		Array(barrier_b.get_meta("barrier_terrain_deployment_intents", []))
	)
	if not _expect(runtime_digest_a == runtime_digest_b, "Repeated runtime deployments should be identical: a=%s b=%s" % [str(runtime_digest_a), str(runtime_digest_b)]):
		return
	if not _expect(editor_digest_a == runtime_digest_a, "Editor preview and battle runtime should resolve identical terrain intents: editor=%s runtime=%s" % [str(editor_digest_a), str(runtime_digest_a)]):
		return

	print("BARRIER_TERRAIN_ENTRYPOINT_REPLAY_PROBE ok placements=%d deployments=%d" % [
		Array(runtime_digest_a.get("placements", [])).size(),
		Array(runtime_digest_a.get("deployments", [])).size(),
	])
	quit(0)
