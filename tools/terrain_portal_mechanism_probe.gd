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


func _approx(actual: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(actual - expected) <= tolerance


func _has_action(intents: Array, action: String, feature_id: String) -> bool:
	for raw_intent in intents:
		if not (raw_intent is Dictionary):
			continue
		var intent: Dictionary = raw_intent
		if String(intent.get("action", "")) == action and String(intent.get("feature_id", "")) == feature_id:
			return true
	return false


func _portal_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_portal_mechanism_probe",
		"version": 1,
		"features": [
			{
				"id": "probe-fold-gate",
				"name": "PROBE FOLD GATE",
				"kind": "portal",
				"collider": {"shape": "circle", "center": Vector2(7.0, 0.5), "radius": 0.45},
				"orientation": Vector2(1.0, 0.0),
				"surface_tags": ["portal", "scripted_mechanism"],
				"effect_channels": ["portal", "scripted_mechanism"],
				"metadata": {
					"portal_index": 0,
					"portal_name": "PROBE FOLD GATE",
					"portal_ring": 13.75,
					"portal_lane": -1.25,
					"owner_scope": "owner",
				},
			},
		],
	})


func _check_pure_portal_intent() -> void:
	var service = BarrierTerrainInteractionServiceScript.new()
	var placement: Dictionary = service.barrier_placement_intent({
		"snapshot": _portal_snapshot(),
		"tile": {
			"tile_id": "portal-trigger",
			"position": Vector2(7.0, 0.5),
			"radius": 0.18,
			"terrain_policy": {
				"portal_kinds": ["portal"],
			},
		},
	})
	if not _expect(bool(placement.get("allowed", false)) and String(placement.get("outcome", "")) == "portal", "Portal placement should be allowed: %s" % str(placement)):
		return
	var deployment_intents: Array = service.terrain_deployment_intents(placement)
	if not _expect(_has_action(deployment_intents, "activate_terrain_portal", "probe-fold-gate"), "Portal deployment intent missing: %s" % str(deployment_intents)):
		return


func _check_runtime_portal_override() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main.ui_language = MainScene.UI_LANGUAGE_EN
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _portal_snapshot()
	main.portal_index = {1: 0, 2: 4}
	main.player_camera_centers = {1: 2.0, 2: 18.0}
	main.player_camera_lanes = {1: 0.25, 2: 0.0}

	var before_spawn: Dictionary = main._spawn_for_selected_portal(1, "hero", {"radius": 0.2})
	if not _expect(not _approx(float(before_spawn.get("ring", 0.0)), 13.75) or not _approx(float(before_spawn.get("lane", 0.0)), -1.25), "Default portal should not already use terrain target: %s" % str(before_spawn)):
		return

	var stats := {
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.2,
		"barrier_map_tiles": [
			{
				"index": 0,
				"tile_id": "portal-trigger",
				"local_ring": 0.0,
				"local_lane": 0.0,
				"radius": 0.14,
				"length": 0.28,
				"orientation": "horizontal",
				"shape": "barrier_tile",
				"material_class": "barrier_wall",
				"terrain_policy": {
					"portal_kinds": ["portal"],
					"radius": 0.25,
				},
			},
		],
	}
	var barrier = main._create_unit(1, "barrier", stats, "P1 Portal Trigger Barrier", 7.0, 0.5)
	main._assign_unit_role(barrier, "barrier")

	var deployment_intents: Array = Array(barrier.get_meta("barrier_terrain_deployment_intents", []))
	if not _expect(_has_action(deployment_intents, "activate_terrain_portal", "probe-fold-gate"), "Runtime barrier should record portal deployment intent: %s" % str(deployment_intents)):
		return
	var state_intents: Array = Array(barrier.get_meta("barrier_terrain_arena_state_intents", []))
	if not _expect(_has_action(state_intents, "activate_terrain_portal", "probe-fold-gate"), "Runtime barrier should record portal state intent: %s" % str(state_intents)):
		return

	var resolved_portal: Dictionary = main._portal_for_player_index(1, 0)
	if not _expect(bool(resolved_portal.get("terrain_portal_active", false)) and String(resolved_portal.get("name", "")) == "PROBE FOLD GATE", "Resolved portal should use terrain override: %s" % str(resolved_portal)):
		return
	var p2_portal: Dictionary = main._portal_for_player_index(2, 0)
	if not _expect(not bool(p2_portal.get("terrain_portal_active", false)), "Owner-scoped terrain portal should not affect P2: %s" % str(p2_portal)):
		return

	var after_spawn: Dictionary = main._spawn_for_selected_portal(1, "hero", {"radius": 0.2})
	if not _expect(_approx(float(after_spawn.get("ring", 0.0)), 13.75) and _approx(float(after_spawn.get("lane", 0.0)), -1.25) and String(after_spawn.get("reason", "")) == "terrain_portal", "Terrain portal spawn should use absolute map target: %s" % str(after_spawn)):
		return
	var hud_snapshot: Dictionary = main._battle_hud_player_snapshot(1)
	if not _expect(String(hud_snapshot.get("portal_name", "")) == "PROBE FOLD GATE", "HUD should surface terrain portal name: %s" % str(hud_snapshot)):
		return
	var feedback := main._summon_portal_feedback_text(1, "direct")
	if not _expect(feedback.contains("PROBE FOLD GATE"), "Portal feedback should surface terrain portal name: %s" % feedback):
		return


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"terrain_portal_overrides",
		"_portal_for_player_index",
		"activate_terrain_portal",
		"_activate_terrain_portal_override",
	]:
		if not source.contains(token):
			_fail("main.gd missing terrain portal runtime token: %s" % token)
			return
	_check_pure_portal_intent()
	_check_runtime_portal_override()
	print("TERRAIN_PORTAL_MECHANISM_PROBE ok")
	quit(0)
