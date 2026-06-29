extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainServiceScript := preload("res://scripts/services/battle_terrain_service.gd")
const BarrierTerrainInteractionServiceScript := preload("res://scripts/services/barrier_terrain_interaction_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _feature_by_id(snapshot: Dictionary, feature_id: String) -> Dictionary:
	for raw_feature in Array(snapshot.get("features", [])):
		if raw_feature is Dictionary and String(Dictionary(raw_feature).get("feature_id", "")) == feature_id:
			return Dictionary(raw_feature)
	return {}


func _has_action(intents: Array, action: String, feature_id: String) -> bool:
	for raw_intent in intents:
		if not (raw_intent is Dictionary):
			continue
		var intent: Dictionary = raw_intent
		if String(intent.get("action", "")) == action and String(intent.get("feature_id", "")) == feature_id:
			return true
	return false


func _mechanism_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_mechanism_state_probe",
		"version": 1,
		"features": [
			{
				"id": "collapsed-gap",
				"name": "COLLAPSED GAP",
				"kind": "gap",
				"collider": {"shape": "circle", "center": Vector2(4.5, 0.0), "radius": 0.45},
				"surface_tags": ["gap", "temporary"],
				"effect_channels": ["traversal"],
			},
			{
				"id": "restore-switch",
				"name": "RESTORE SWITCH",
				"kind": "mechanism",
				"collider": {"shape": "circle", "center": Vector2(6.0, 0.0), "radius": 0.45},
				"surface_tags": ["scripted_mechanism"],
				"effect_channels": ["scripted_mechanism"],
				"metadata": {
					"mechanism_effect": "restore_terrain",
					"remove_feature_ids": ["collapsed-gap"],
					"restore_features": [
						{
							"id": "restored-cover",
							"name": "RESTORED COVER",
							"kind": "wall",
							"collider": {"shape": "circle", "center": Vector2(4.5, 0.0), "radius": 0.42},
							"orientation": Vector2(1.0, 0.0),
							"surface_tags": ["cover", "restored"],
							"effect_channels": ["collision", "occlusion"],
						},
					],
				},
			},
		],
	})


func _check_pure_mechanism_intent() -> void:
	var service = BarrierTerrainInteractionServiceScript.new()
	var placement: Dictionary = service.barrier_placement_intent({
		"snapshot": _mechanism_snapshot(),
		"tile": {
			"tile_id": "mechanism-trigger",
			"position": Vector2(6.0, 0.0),
			"radius": 0.18,
			"terrain_policy": {
				"mechanism_kinds": ["mechanism"],
			},
		},
	})
	if not _expect(bool(placement.get("allowed", false)) and String(placement.get("outcome", "")) == "mechanism", "Mechanism placement should be allowed: %s" % str(placement)):
		return
	var deployment_intents: Array = service.terrain_deployment_intents(placement)
	if not _expect(_has_action(deployment_intents, "trigger_arena_mechanism", "restore-switch"), "Mechanism deployment intent missing: %s" % str(deployment_intents)):
		return


func _check_runtime_mechanism_state() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _mechanism_snapshot()

	var before_snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	if not _expect(not _feature_by_id(before_snapshot, "collapsed-gap").is_empty(), "Probe should start with collapsed gap"):
		return
	if not _expect(_feature_by_id(before_snapshot, "restored-cover").is_empty(), "Probe should start without restored cover"):
		return

	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "mechanism-trigger",
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.14,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"terrain_policy": {
					"mechanism_kinds": ["mechanism"],
					"radius": 0.25,
				},
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", stats, "P1 Restore Mechanism Barrier", 6.0, 0.0)
	main._assign_unit_role(barrier, "barrier")

	var deployment_intents: Array = Array(barrier.get_meta("barrier_terrain_deployment_intents", []))
	if not _expect(_has_action(deployment_intents, "trigger_arena_mechanism", "restore-switch"), "Runtime barrier should record mechanism deployment intent: %s" % str(deployment_intents)):
		return
	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_has_action(state_intents, "trigger_arena_mechanism", "restore-switch"), "Runtime barrier should record mechanism state intent: %s" % str(state_intents)):
		return
	var state_intent: Dictionary = Dictionary(state_intents[0])
	if not _expect(Array(state_intent.get("removed_feature_ids", [])).has("collapsed-gap"), "Mechanism state intent should record removed gap: %s" % str(state_intent)):
		return
	if not _expect(Array(state_intent.get("restored_feature_ids", [])).has("restored-cover"), "Mechanism state intent should record restored cover: %s" % str(state_intent)):
		return

	var after_snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	if not _expect(int(after_snapshot.get("version", 0)) == 2, "Mechanism should increment terrain snapshot version: %s" % str(after_snapshot)):
		return
	if not _expect(_feature_by_id(after_snapshot, "collapsed-gap").is_empty(), "Mechanism should remove collapsed gap: %s" % str(after_snapshot)):
		return
	var restored := _feature_by_id(after_snapshot, "restored-cover")
	if not _expect(not restored.is_empty() and String(restored.get("terrain_kind", "")) == "wall", "Mechanism should restore wall terrain: %s" % str(restored)):
		return
	if not _expect(Array(restored.get("surface_tags", [])).has("restored"), "Restored feature should preserve tags: %s" % str(restored)):
		return
	var collision_candidates: Array = main._terrain_collision_candidates_for_runtime()
	var restored_collision := false
	for raw_candidate in collision_candidates:
		if raw_candidate is Dictionary and String(Dictionary(raw_candidate).get("feature_id", "")) == "restored-cover":
			restored_collision = true
			break
	if not _expect(restored_collision, "Restored cover should feed runtime collision candidates: %s" % str(collision_candidates)):
		return


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"_terrain_state_apply_mechanism_intent",
		"_terrain_state_remove_feature_ids",
		"_terrain_state_upsert_features",
		"trigger_arena_mechanism",
	]:
		if not source.contains(token):
			_fail("main.gd missing terrain mechanism runtime token: %s" % token)
			return
	_check_pure_mechanism_intent()
	_check_runtime_mechanism_state()
	print("TERRAIN_MECHANISM_STATE_PROBE ok")
	quit(0)
