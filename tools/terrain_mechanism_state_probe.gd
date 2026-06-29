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


func _mutation_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_mechanism_mutation_probe",
		"version": 1,
		"features": [
			{
				"id": "dormant-vent-floor",
				"name": "DORMANT VENT FLOOR",
				"kind": "floor",
				"collider": {"shape": "circle", "center": Vector2(7.25, 0.0), "radius": 0.5},
				"orientation": Vector2(0.0, 1.0),
				"surface_tags": ["floor", "dormant"],
				"effect_channels": ["surface"],
				"metadata": {"speed_mult": 1.0},
			},
			{
				"id": "vent-arm-switch",
				"name": "VENT ARM SWITCH",
				"kind": "mechanism",
				"collider": {"shape": "circle", "center": Vector2(8.0, 0.0), "radius": 0.42},
				"surface_tags": ["scripted_mechanism"],
				"effect_channels": ["scripted_mechanism"],
				"metadata": {
					"mechanism_effect": "arm_terrain_feature",
					"mutate_features": [
						{
							"feature_id": "dormant-vent-floor",
							"add_surface_tags": ["armed", "hazard"],
							"remove_surface_tags": ["dormant"],
							"add_effect_channels": ["hazard"],
							"metadata": {
								"speed_mult": 0.65,
								"heat_rate": 9.0,
								"damage_per_tick": 2,
								"damage_interval": 0.05,
							},
						},
					],
				},
			},
		],
	})


func _resource_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_mechanism_resource_probe",
		"version": 1,
		"features": [
			{
				"id": "resource-switch",
				"name": "RESOURCE SWITCH",
				"kind": "mechanism",
				"collider": {"shape": "circle", "center": Vector2(9.0, 0.0), "radius": 0.42},
				"surface_tags": ["scripted_mechanism", "resource"],
				"effect_channels": ["scripted_mechanism"],
				"metadata": {
					"mechanism_effect": "resource_pulse",
					"resource_delta": 18.0,
					"resource_owner_scope": "all",
				},
			},
		],
	})


func _thermal_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_mechanism_thermal_probe",
		"version": 1,
		"features": [
			{
				"id": "thermal-switch",
				"name": "THERMAL SWITCH",
				"kind": "mechanism",
				"collider": {"shape": "circle", "center": Vector2(10.0, 0.0), "radius": 0.42},
				"surface_tags": ["scripted_mechanism", "thermal"],
				"effect_channels": ["scripted_mechanism"],
				"metadata": {
					"mechanism_effect": "thermal_pulse",
					"heat_delta": 12.0,
					"thermal_owner_scope": "enemy",
				},
			},
		],
	})


func _spawn_hero(main, owner: int, name: String, ring: float, lane: float):
	var stats := {
		"name": name,
		"health": 100,
		"max_health": 100,
		"mass": 12.0,
		"radius": 0.18,
		"heat_capacity": 100.0,
		"speed": 1.0,
	}
	var hero = main._create_unit(owner, "hero", stats, name, ring, lane)
	main._assign_unit_role(hero, "hero")
	return hero


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


func _check_runtime_mechanism_mutation() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _mutation_snapshot()

	var before_snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	var dormant := _feature_by_id(before_snapshot, "dormant-vent-floor")
	if not _expect(not dormant.is_empty(), "Probe should start with dormant vent floor"):
		return
	if not _expect(not Array(dormant.get("surface_tags", [])).has("hazard"), "Dormant vent should start without hazard tag: %s" % str(dormant)):
		return

	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "vent-arm-trigger",
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
	var barrier = main._create_unit(1, "barrier", stats, "P1 Arm Vent Mechanism Barrier", 8.0, 0.0)
	main._assign_unit_role(barrier, "barrier")

	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_has_action(state_intents, "trigger_arena_mechanism", "vent-arm-switch"), "Runtime barrier should record mutation mechanism state intent: %s" % str(state_intents)):
		return
	var state_intent: Dictionary = Dictionary(state_intents[0])
	if not _expect(Array(state_intent.get("mutated_feature_ids", [])).has("dormant-vent-floor"), "Mechanism state intent should record mutated floor: %s" % str(state_intent)):
		return

	var after_snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	if not _expect(int(after_snapshot.get("version", 0)) == 2, "Mutation mechanism should increment terrain snapshot version: %s" % str(after_snapshot)):
		return
	var armed := _feature_by_id(after_snapshot, "dormant-vent-floor")
	if not _expect(not armed.is_empty(), "Mutation mechanism should keep mutated feature: %s" % str(after_snapshot)):
		return
	if not _expect(Array(armed.get("surface_tags", [])).has("armed") and Array(armed.get("surface_tags", [])).has("hazard"), "Mutated feature should gain armed hazard tags: %s" % str(armed)):
		return
	if not _expect(not Array(armed.get("surface_tags", [])).has("dormant"), "Mutated feature should remove dormant tag: %s" % str(armed)):
		return
	if not _expect(Array(armed.get("effect_channels", [])).has("surface") and Array(armed.get("effect_channels", [])).has("hazard"), "Mutated feature should keep surface and gain hazard channels: %s" % str(armed)):
		return
	var armed_metadata: Dictionary = Dictionary(armed.get("metadata", {}))
	if not _expect(float(armed_metadata.get("heat_rate", 0.0)) == 9.0 and int(armed_metadata.get("damage_per_tick", 0)) == 2, "Mutated feature should merge metadata: %s" % str(armed_metadata)):
		return
	var hazard_candidates: Array = main._terrain_hazard_candidates_for_runtime()
	var surface_candidates: Array = main._terrain_surface_candidates_for_runtime()
	if not _expect(_candidate_has_feature(hazard_candidates, "dormant-vent-floor"), "Mutated floor should feed hazard candidates: %s" % str(hazard_candidates)):
		return
	if not _expect(_candidate_has_feature(surface_candidates, "dormant-vent-floor"), "Mutated floor should remain a surface candidate: %s" % str(surface_candidates)):
		return


func _check_runtime_mechanism_resource_pulse() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.runtime_resource = {1: 10.0, 2: 5.0}
	main.battle_terrain_runtime_snapshot = _resource_snapshot()

	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "resource-trigger",
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
	var barrier = main._create_unit(1, "barrier", stats, "P1 Resource Mechanism Barrier", 9.0, 0.0)
	main._assign_unit_role(barrier, "barrier")

	if not _expect(float(main.runtime_resource.get(1, 0.0)) == 28.0, "Resource mechanism should grant P1 resource: %s" % str(main.runtime_resource)):
		return
	if not _expect(float(main.runtime_resource.get(2, 0.0)) == 23.0, "Resource mechanism should grant P2 resource: %s" % str(main.runtime_resource)):
		return
	if not _expect(int(main._battle_terrain_runtime_snapshot().get("version", 0)) == 1, "Resource-only mechanism should not change terrain snapshot version"):
		return
	if not _expect(int(barrier.get_meta("barrier_terrain_snapshot_version_after", 0)) == 1, "Resource-only mechanism should record unchanged snapshot version"):
		return
	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_has_action(state_intents, "trigger_arena_mechanism", "resource-switch"), "Runtime barrier should record resource mechanism state intent: %s" % str(state_intents)):
		return
	var resource_intent: Dictionary = Dictionary(state_intents[0])
	if not _expect(String(resource_intent.get("runtime_effect", "")) == "resource_pulse", "Resource mechanism should record runtime effect: %s" % str(resource_intent)):
		return
	if not _expect(float(resource_intent.get("resource_delta", 0.0)) == 18.0, "Resource mechanism should record delta: %s" % str(resource_intent)):
		return
	if not _expect(Array(resource_intent.get("target_players", [])).has(1) and Array(resource_intent.get("target_players", [])).has(2), "Resource mechanism should record target players: %s" % str(resource_intent)):
		return
	var before: Dictionary = Dictionary(resource_intent.get("resource_before", {}))
	var after: Dictionary = Dictionary(resource_intent.get("resource_after", {}))
	if not _expect(float(before.get(1, 0.0)) == 10.0 and float(after.get(2, 0.0)) == 23.0, "Resource mechanism should record before/after resources: %s" % str(resource_intent)):
		return


func _check_runtime_mechanism_thermal_pulse() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _thermal_snapshot()

	var ally = _spawn_hero(main, 1, "P1 Thermal Ally", 9.5, 0.0)
	ally.heat = 10.0
	var enemy = _spawn_hero(main, 2, "P2 Thermal Enemy", 10.5, 0.0)
	enemy.heat = 20.0
	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "thermal-trigger",
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
	var barrier = main._create_unit(1, "barrier", stats, "P1 Thermal Mechanism Barrier", 10.0, 0.0)
	main._assign_unit_role(barrier, "barrier")

	if not _expect(float(ally.heat) == 10.0, "Thermal mechanism should not heat owner ally: %.2f" % float(ally.heat)):
		return
	if not _expect(float(enemy.heat) == 32.0, "Thermal mechanism should heat enemy hero: %.2f" % float(enemy.heat)):
		return
	if not _expect(int(main._battle_terrain_runtime_snapshot().get("version", 0)) == 1, "Thermal-only mechanism should not change terrain snapshot version"):
		return
	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_has_action(state_intents, "trigger_arena_mechanism", "thermal-switch"), "Runtime barrier should record thermal mechanism state intent: %s" % str(state_intents)):
		return
	var thermal_intent: Dictionary = Dictionary(state_intents[0])
	if not _expect(String(thermal_intent.get("runtime_effect", "")) == "thermal_pulse", "Thermal mechanism should record runtime effect: %s" % str(thermal_intent)):
		return
	if not _expect(float(thermal_intent.get("heat_delta", 0.0)) == 12.0, "Thermal mechanism should record heat delta: %s" % str(thermal_intent)):
		return
	if not _expect(Array(thermal_intent.get("target_players", [])).has(2), "Thermal mechanism should target enemy player: %s" % str(thermal_intent)):
		return
	var affected: Array = Array(thermal_intent.get("affected_units", []))
	if not _expect(affected.size() == 1 and int(Dictionary(affected[0]).get("owner_id", 0)) == 2 and String(Dictionary(affected[0]).get("role", "")) == "hero", "Thermal mechanism should record affected enemy hero only: %s" % str(thermal_intent)):
		return
	var affected_unit: Dictionary = Dictionary(affected[0])
	if not _expect(float(affected_unit.get("heat_before", 0.0)) == 20.0 and float(affected_unit.get("heat_after", 0.0)) == 32.0, "Thermal mechanism should record heat before/after: %s" % str(affected_unit)):
		return


func _candidate_has_feature(candidates: Array, feature_id: String) -> bool:
	for raw_candidate in candidates:
		if raw_candidate is Dictionary and String(Dictionary(raw_candidate).get("feature_id", "")) == feature_id:
			return true
	return false


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"_terrain_state_apply_mechanism_intent",
		"_terrain_state_remove_feature_ids",
		"_terrain_state_upsert_features",
		"_terrain_state_mutate_features",
		"_terrain_mechanism_resource_pulse_intent",
		"_terrain_mechanism_thermal_pulse_intent",
		"trigger_arena_mechanism",
	]:
		if not source.contains(token):
			_fail("main.gd missing terrain mechanism runtime token: %s" % token)
			return
	_check_pure_mechanism_intent()
	_check_runtime_mechanism_state()
	_check_runtime_mechanism_mutation()
	_check_runtime_mechanism_resource_pulse()
	_check_runtime_mechanism_thermal_pulse()
	print("TERRAIN_MECHANISM_STATE_PROBE ok")
	quit(0)
