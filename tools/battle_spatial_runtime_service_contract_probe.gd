extends SceneTree

const BattleSpatialRuntimeService := preload("res://scripts/services/battle_spatial_runtime_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _approx(a: float, b: float, tolerance: float = 0.001) -> bool:
	return absf(a - b) <= tolerance


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_spatial_runtime_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleSpatialRuntimeService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "Fighter", "GpuCollisionPipeline", "_create_unit", "queue_free", "take_hit", "take_damage", "apply_damage", "apply_heat", "_spawn_hit_effect", "_play_sfx", "randf", "randi", "Time"]:
		if source.contains(forbidden):
			_fail("BattleSpatialRuntimeService contains forbidden token: %s" % forbidden)
			return
	var service := BattleSpatialRuntimeService.new()

	var alpha := service.camera_follow_alpha(0.5, 4.0)
	if not _expect(_approx(alpha, 1.0 - exp(-2.0)), "camera follow alpha mismatch: %s" % str(alpha)):
		return
	var focus := service.player_camera_focus_intent({
		"hero": {"live": false},
		"friendly": {"live": true, "coord": Vector2(6.0, 2.0)},
		"enemy_hero": {"live": true, "coord": Vector2(9.0, -1.0)},
		"fallback_center": 1.0,
		"fallback_lane": 0.0,
		"lane_limit": 1.5,
	})
	if not _expect(String(focus.get("source", "")) == "friendly" and _approx(float(focus.get("center", 0.0)), 6.0) and _approx(float(focus.get("lane", 0.0)), 1.5), "player camera focus mismatch: %s" % str(focus)):
		return
	var spectator := service.spectator_camera_focus_intent({
		"left": {"live": true, "coord": Vector2(23.0, 0.6), "ring": 23.0, "lane": 0.6},
		"right": {"live": true, "coord": Vector2(1.0, -0.2), "ring": 1.0, "lane": -0.2},
		"mobius_enabled": false,
		"ring_delta": 2.0,
		"ring_length": 24.0,
		"fallback_center": 0.0,
		"fallback_lane": 0.0,
		"lane_limit": 2.0,
	})
	if not _expect(_approx(float(spectator.get("center", 0.0)), 0.0) and _approx(float(spectator.get("lane", 0.0)), 0.2), "spectator mid focus mismatch: %s" % str(spectator)):
		return
	var camera_plan := service.camera_update_intent({
		"follow_alpha": 0.5,
		"mobius_enabled": false,
		"ring_length": 24.0,
		"lane_limit": 2.0,
		"snap_to_targets": false,
		"seat": 3,
		"spectator_view_mode": BattleSpatialRuntimeService.SPECTATOR_VIEW_MID,
		"p1_current": {"center": 0.0, "lane": 0.0},
		"p2_current": {"center": 10.0, "lane": 0.0},
		"p1_target": {"center": 2.0, "lane": 1.0, "horizontal_delta": 2.0},
		"p2_target": {"center": 8.0, "lane": -1.0, "horizontal_delta": -2.0},
		"spectator_current": {"center": 23.0, "lane": 0.0},
		"spectator_focus": {"center": 1.0, "lane": 1.0},
		"spectator_horizontal_delta": 2.0,
	})
	if not _expect(_approx(float(camera_plan.get("camera_center", 0.0)), 0.0) and _approx(float(camera_plan.get("camera_lane_center", 0.0)), 0.5), "camera update spectator route mismatch: %s" % str(camera_plan)):
		return
	var snap_plan := service.camera_update_intent({
		"follow_alpha": 0.1,
		"mobius_enabled": false,
		"ring_length": 24.0,
		"lane_limit": 2.0,
		"snap_to_targets": true,
		"seat": 2,
		"p1_current": {"center": 0.0, "lane": 0.0},
		"p2_current": {"center": 0.0, "lane": 0.0},
		"p1_target": {"center": 3.0, "lane": 0.7},
		"p2_target": {"center": 7.0, "lane": -0.7},
	})
	if not _expect(_approx(float(snap_plan.get("camera_center", 0.0)), 7.0) and _approx(float(snap_plan.get("camera_lane_center", 0.0)), -0.7), "camera update seat snap mismatch: %s" % str(snap_plan)):
		return
	var projection := service.screen_projection_intent({
		"mobius_enabled": false,
		"ring": 7.0,
		"lane": 1.0,
		"camera_center": 6.0,
		"camera_lane": 0.25,
		"ring_delta": 1.0,
		"screen_scale": 100.0,
		"arena_width": 800.0,
		"view_height": 4.5,
		"arena_center": Vector2(500.0, 300.0),
	})
	if not _expect(projection.get("position", Vector2.ZERO) == Vector2(600.0, 375.0) and bool(projection.get("visible", false)), "plane projection mismatch: %s" % str(projection)):
		return
	var mobius_projection := service.screen_projection_intent({
		"mobius_enabled": true,
		"ring": 1.0,
		"lane": 0.8,
		"lifted_s": 25.0,
		"lifted_lane": -0.8,
	})
	if not _expect(String(mobius_projection.get("mode", "")) == "mobius" and mobius_projection.get("coord", Vector2.ZERO) == Vector2(25.0, -0.8), "mobius projection should preserve lifted lane: %s" % str(mobius_projection)):
		return
	var visibility := service.world_point_visibility_intent({"delta": Vector2(3.0, 2.0), "screen_scale": 100.0, "arena_width": 800.0, "view_height": 4.5, "margin_mult": 1.0})
	if not _expect(bool(visibility.get("visible", false)), "visibility should accept in-margin point: %s" % str(visibility)):
		return
	var hidden := service.world_point_visibility_intent({"delta": Vector2(5.0, 0.0), "screen_scale": 100.0, "arena_width": 800.0, "view_height": 4.5, "margin_mult": 1.0})
	if not _expect(not bool(hidden.get("visible", true)), "visibility should reject out-of-margin point: %s" % str(hidden)):
		return
	var barrier_spawn := service.portal_spawn_intent({"role_key": "barrier", "camera_center": 4.0, "camera_lane": 0.25, "lane_limit": 1.0})
	if not _expect(_approx(float(barrier_spawn.get("ring", 0.0)), 4.0) and _approx(float(barrier_spawn.get("lane", 0.0)), 0.25), "barrier portal spawn mismatch: %s" % str(barrier_spawn)):
		return
	var large_spawn := service.portal_spawn_intent({"role_key": "hero", "portal": {"delta": -2.0, "lane": 0.8}, "radius": 0.7, "camera_center": 6.0, "camera_lane": 0.4, "ring_length": 24.0, "lane_limit": 1.0})
	if not _expect(_approx(float(large_spawn.get("ring", 0.0)), 3.0) and _approx(float(large_spawn.get("lane", 0.0)), 0.4), "large mech portal fallback mismatch: %s" % str(large_spawn)):
		return
	var short_input := service.surface_input_intent({"mobius_enabled": true, "readable_input": Vector2(0.01, 0.0), "surface_input": Vector2.RIGHT})
	if not _expect(short_input.get("input", Vector2.ZERO) == Vector2(0.01, 0.0), "short surface input should use readable input: %s" % str(short_input)):
		return
	var vertical_input := service.surface_input_intent({"mobius_enabled": true, "readable_input": Vector2(0.0, 1.0), "surface_input": Vector2(1.0, -0.2).normalized()})
	if not _expect(float(Vector2(vertical_input.get("input", Vector2.ZERO)).y) > 0.0 and String(vertical_input.get("reason", "")) == "vertical_preserved", "vertical surface input mismatch: %s" % str(vertical_input)):
		return

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_spatial_runtime_service.gd",
		"BattleSpatialRuntimeService.new",
		"_battle_spatial_runtime_service().camera_follow_alpha",
		"_battle_spatial_runtime_service().player_camera_focus_intent",
		"_battle_spatial_runtime_service().spectator_camera_focus_intent",
		"_battle_spatial_runtime_service().camera_update_intent",
		"_battle_spatial_runtime_service().screen_projection_intent",
		"_battle_spatial_runtime_service().world_point_visibility_intent",
		"_battle_spatial_runtime_service().portal_spawn_intent",
		"_battle_spatial_runtime_service().surface_input_intent",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleSpatialRuntimeService boundary token: %s" % token)
			return
	print("BATTLE_SPATIAL_RUNTIME_SERVICE_CONTRACT_PROBE ok")
	quit(0)
