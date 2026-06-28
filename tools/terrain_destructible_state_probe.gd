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


func _deployment_has_action(intents: Array, action: String, feature_id: String) -> bool:
	for raw_intent in intents:
		if not (raw_intent is Dictionary):
			continue
		var intent: Dictionary = raw_intent
		if String(intent.get("action", "")) == action and String(intent.get("feature_id", "")) == feature_id:
			return true
	return false


func _init() -> void:
	var terrain_source := FileAccess.get_file_as_string("res://scripts/services/battle_terrain_service.gd")
	var interaction_source := FileAccess.get_file_as_string("res://scripts/services/barrier_terrain_interaction_service.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"reinforce_terrain_feature",
		"breach_terrain_feature",
		"func _apply_barrier_terrain_arena_state",
	]:
		if not (terrain_source + interaction_source + main_source).contains(token):
			_fail("Destructible terrain state integration missing token: %s" % token)
			return

	_check_pure_intents()
	_check_runtime_snapshot_mutation()
	print("TERRAIN_DESTRUCTIBLE_STATE_PROBE ok")
	quit(0)


func _destructible_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_destructible_state_probe",
		"version": 1,
		"features": [
			{
				"id": "wall-reinforce",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(3.0, 0.0), "radius": 0.4},
				"orientation": Vector2(1.0, 0.0),
				"surface_tags": ["cover"],
				"effect_channels": ["collision", "occlusion"],
				"destructible": true,
				"metadata": {"terrain_hp": 45.0, "max_terrain_hp": 80.0},
			},
			{
				"id": "wall-breach",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(5.0, 0.0), "radius": 0.4},
				"orientation": Vector2(1.0, 0.0),
				"surface_tags": ["cover"],
				"effect_channels": ["collision", "occlusion"],
				"destructible": true,
				"metadata": {"terrain_hp": 50.0, "max_terrain_hp": 70.0},
			},
		],
	})


func _check_pure_intents() -> void:
	var service = BarrierTerrainInteractionServiceScript.new()
	var snapshot := _destructible_snapshot()
	var reinforce: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "reinforce-panel",
			"position": Vector2(3.0, 0.0),
			"radius": 0.18,
			"terrain_policy": {
				"reinforce_kinds": ["wall"],
				"reinforce_amount": 25.0,
			},
		},
	})
	if not _expect(bool(reinforce.get("allowed", false)) and String(reinforce.get("outcome", "")) == "reinforce", "Reinforce placement should be allowed: %s" % str(reinforce)):
		return
	var reinforce_intents: Array = service.terrain_deployment_intents(reinforce)
	if not _expect(_deployment_has_action(reinforce_intents, "reinforce_terrain_feature", "wall-reinforce"), "Reinforce deployment intent missing: %s" % str(reinforce_intents)):
		return

	var breach: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "breach-panel",
			"position": Vector2(5.0, 0.0),
			"radius": 0.18,
			"terrain_policy": {
				"breach_kinds": ["wall"],
				"breach_damage": 80.0,
			},
		},
	})
	if not _expect(bool(breach.get("allowed", false)) and String(breach.get("outcome", "")) == "breach", "Breach placement should be allowed: %s" % str(breach)):
		return
	var breach_intents: Array = service.terrain_deployment_intents(breach)
	if not _expect(_deployment_has_action(breach_intents, "breach_terrain_feature", "wall-breach"), "Breach deployment intent missing: %s" % str(breach_intents)):
		return


func _check_runtime_snapshot_mutation() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _destructible_snapshot()

	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "reinforce-panel",
				"local_ring": -1.0,
				"local_lane": 0.0,
				"radius": 0.12,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"terrain_policy": {
					"reinforce_kinds": ["wall"],
					"reinforce_amount": 25.0,
					"radius": 0.25,
				},
			},
			{
				"index": 1,
				"tile_id": "breach-panel",
				"local_ring": 1.0,
				"local_lane": 0.0,
				"radius": 0.12,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "entry_breach",
				"terrain_policy": {
					"breach_kinds": ["wall"],
					"breach_damage": 80.0,
					"radius": 0.25,
				},
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", stats, "P1 Terrain State Barrier", 4.0, 0.0)
	main._assign_unit_role(barrier, "barrier")

	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_deployment_has_action(state_intents, "reinforce_terrain_feature", "wall-reinforce"), "Runtime state intents should include reinforce: %s" % str(state_intents)):
		return
	if not _expect(_deployment_has_action(state_intents, "breach_terrain_feature", "wall-breach"), "Runtime state intents should include breach: %s" % str(state_intents)):
		return

	var snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	var reinforced := _feature_by_id(snapshot, "wall-reinforce")
	if not _expect(not reinforced.is_empty(), "Reinforced wall should remain in runtime snapshot: %s" % str(snapshot)):
		return
	var reinforced_meta: Dictionary = Dictionary(reinforced.get("metadata", {}))
	if not _expect(float(reinforced_meta.get("terrain_hp", 0.0)) >= 70.0, "Reinforced wall hp should increase: %s" % str(reinforced)):
		return
	if not _expect(Array(reinforced.get("surface_tags", [])).has("reinforced"), "Reinforced wall should get reinforced tag: %s" % str(reinforced)):
		return
	if not _expect(_feature_by_id(snapshot, "wall-breach").is_empty(), "Breached wall should be removed from runtime snapshot: %s" % str(snapshot)):
		return
	var collision_candidates: Array = main._terrain_collision_candidates_for_runtime()
	for raw_candidate in collision_candidates:
		if raw_candidate is Dictionary and String(Dictionary(raw_candidate).get("feature_id", "")) == "wall-breach":
			_fail("Breached terrain should no longer produce collision candidates: %s" % str(collision_candidates))
			return
