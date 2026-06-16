extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_presentation_frame_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const FACADE_PATH := "res://scripts/battle/battle_runtime_facade.gd"
const BattlePresentationFrameServiceScript := preload("res://scripts/services/battle_presentation_frame_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattlePresentationFrameService script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattlePresentationFrameService",
		"extends RefCounted",
		"const CAPTURE_BEFORE_STEP",
		"const CAPTURE_AFTER_STEP",
		"func motion_snapshot_state",
		"func render_frame_plan",
	]:
		if source.find(token) < 0:
			_fail("BattlePresentationFrameService missing token: %s" % token)
			return
	for forbidden in [
		"Input.",
		"FileAccess",
		"DirAccess",
		"JSON.parse_string",
		"extends Node",
		"extends Control",
		"Control.new",
		"active_units",
		"all_units",
		"capture_motion_snapshot",
		"apply_interpolated_presentation",
		"_refresh_unit_screen_positions",
		"_update_battle_ui",
		"queue_free",
		"take_hit",
	]:
		if source.find(forbidden) >= 0:
			_fail("BattlePresentationFrameService should stay pure; found forbidden token: %s" % forbidden)
			return
	var service = BattlePresentationFrameServiceScript.new()
	var first_before: Dictionary = service.motion_snapshot_state(BattlePresentationFrameServiceScript.CAPTURE_BEFORE_STEP, Vector2(2.0, 3.0), {})
	_assert_eq(bool(first_before.get("capture_units", false)), true, "first before captures units")
	_assert_eq(bool(first_before.get("unit_before_step", false)), true, "first before unit flag")
	_assert_eq(first_before.get("camera_previous_coord", Vector2.ZERO), Vector2(2.0, 3.0), "first before previous")
	_assert_eq(first_before.get("camera_current_coord", Vector2.ZERO), Vector2(2.0, 3.0), "first before current")
	_assert_eq(bool(first_before.get("camera_snapshot_initialized", false)), true, "first before initialized")
	var second_before: Dictionary = service.motion_snapshot_state(BattlePresentationFrameServiceScript.CAPTURE_BEFORE_STEP, Vector2(9.0, 9.0), {
		"initialized": true,
		"previous_coord": Vector2(1.0, 1.0),
		"current_coord": Vector2(4.0, 5.0),
	})
	_assert_eq(second_before.get("camera_previous_coord", Vector2.ZERO), Vector2(4.0, 5.0), "second before previous")
	_assert_eq(second_before.get("camera_current_coord", Vector2.ZERO), Vector2(4.0, 5.0), "second before current stays")
	var after: Dictionary = service.motion_snapshot_state(BattlePresentationFrameServiceScript.CAPTURE_AFTER_STEP, Vector2(7.0, 8.0), {
		"initialized": true,
		"previous_coord": Vector2(4.0, 5.0),
		"current_coord": Vector2(4.0, 5.0),
	})
	_assert_eq(bool(after.get("unit_before_step", true)), false, "after unit flag")
	_assert_eq(after.get("camera_previous_coord", Vector2.ZERO), Vector2(4.0, 5.0), "after previous")
	_assert_eq(after.get("camera_current_coord", Vector2.ZERO), Vector2(7.0, 8.0), "after current")
	var render_plan: Dictionary = service.render_frame_plan(0.012, 0.65, {"diagnostics_overlay_enabled": true})
	for flag in [
		"presentation_active",
		"refresh_mobius_surface",
		"update_parallax_background",
		"refresh_unit_screen_positions",
		"update_aim_lines",
		"update_combat_geometry_debug_overlay",
		"update_battle_action_diagnostics_overlay",
		"update_battle_ui",
	]:
		_assert_eq(bool(render_plan.get(flag, false)), true, "render flag %s" % flag)
	_assert_eq(bool(render_plan.get("presentation_active_after", true)), false, "render active after")
	_assert_close(float(render_plan.get("frame_delta", 0.0)), 0.012, "render frame delta")
	_assert_close(float(render_plan.get("interpolation_alpha", 0.0)), 0.65, "render alpha")
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattlePresentationFrameService = preload(\"res://scripts/services/battle_presentation_frame_service.gd\")",
		"var battle_presentation_frame_service: BattlePresentationFrameService",
		"battle_presentation_frame_service = BattlePresentationFrameService.new()",
		"battle_runtime_facade.bind_presentation_frame(battle_presentation_frame_service)",
		"func _battle_presentation_frame_service() -> BattlePresentationFrameService",
		"_battle_runtime_facade().motion_snapshot_state",
		"_battle_runtime_facade().render_frame_plan",
		"_battle_camera_snapshot_state",
		"_apply_battle_camera_snapshot_state",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing BattlePresentationFrameService boundary token: %s" % token)
			return
	for forbidden_main in [
		"battle_presentation_frame_service.motion_snapshot_state",
		"battle_presentation_frame_service.render_frame_plan",
		"_battle_presentation_frame_service().motion_snapshot_state",
		"_battle_presentation_frame_service().render_frame_plan",
	]:
		if main_source.find(forbidden_main) >= 0:
			_fail("main.gd should enter presentation frame through BattleRuntimeFacade token: %s" % forbidden_main)
			return
	var facade_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(FACADE_PATH))
	for token in [
		"func bind_presentation_frame(service)",
		"func motion_snapshot_state",
		"func render_frame_plan",
		"_presentation_frame().motion_snapshot_state",
		"_presentation_frame().render_frame_plan",
	]:
		if facade_source.find(token) < 0:
			_fail("BattleRuntimeFacade missing presentation frame token: %s" % token)
			return
	print("BATTLE_PRESENTATION_FRAME_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.0001:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])
