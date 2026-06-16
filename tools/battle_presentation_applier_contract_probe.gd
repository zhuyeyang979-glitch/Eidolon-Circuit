extends SceneTree

const APPLIER_PATH := "res://scripts/battle/battle_presentation_applier.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattlePresentationApplierScript := preload("res://scripts/battle/battle_presentation_applier.gd")


class FakeHost:
	extends RefCounted

	var battle_presentation_active := false
	var battle_presentation_alpha := 0.0
	var calls: Array = []

	func begin_presentation_frame(active: bool, alpha: float) -> void:
		battle_presentation_active = active
		battle_presentation_alpha = alpha
		calls.append("begin:%s:%.3f" % [str(active), alpha])

	func finish_presentation_frame(active_after: bool) -> void:
		battle_presentation_active = active_after
		calls.append("finish:%s" % str(active_after))

	func refresh_mobius_surface() -> void:
		calls.append("mobius")

	func update_parallax_background() -> void:
		calls.append("parallax")

	func refresh_unit_screen_positions(alpha: float, frame_delta: float) -> void:
		calls.append("units:%.3f:%.3f" % [alpha, frame_delta])

	func update_aim_lines(frame_delta: float) -> void:
		calls.append("aim:%.3f" % frame_delta)

	func update_combat_geometry_debug_overlay() -> void:
		calls.append("geometry")

	func update_battle_action_diagnostics_overlay() -> void:
		calls.append("diagnostics")

	func update_battle_ui() -> void:
		calls.append("ui")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(APPLIER_PATH):
		_fail("Missing BattlePresentationApplier script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(APPLIER_PATH))
	for token in [
		"class_name BattlePresentationApplier",
		"extends RefCounted",
		"func apply_render_frame(host, plan: Dictionary)",
		"host.begin_presentation_frame",
		"host.refresh_mobius_surface",
		"host.update_parallax_background",
		"host.refresh_unit_screen_positions",
		"host.update_aim_lines",
		"host.update_combat_geometry_debug_overlay",
		"host.update_battle_action_diagnostics_overlay",
		"host.update_battle_ui",
		"host.finish_presentation_frame",
		"presentation_active_after",
	]:
		if source.find(token) < 0:
			_fail("BattlePresentationApplier missing token: %s" % token)
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
		"queue_free",
		"take_hit",
		"_spawn_",
		"_refresh_mobius_surface_view",
		"_update_parallax_background",
		"_refresh_unit_screen_positions",
		"_update_aim_lines",
		"_update_combat_geometry_debug_overlay",
		"_update_battle_action_diagnostics_overlay",
		"_update_battle_ui",
		"has_method",
		"callv",
		"host.set(",
	]:
		if source.find(forbidden) >= 0:
			_fail("BattlePresentationApplier should stay presentation-only; found forbidden token: %s" % forbidden)
			return
	var applier = BattlePresentationApplierScript.new()
	var host := FakeHost.new()
	applier.apply_render_frame(host, {
		"presentation_active": true,
		"presentation_alpha": 0.65,
		"frame_delta": 0.012,
		"interpolation_alpha": 0.65,
		"refresh_mobius_surface": true,
		"update_parallax_background": true,
		"refresh_unit_screen_positions": true,
		"update_aim_lines": true,
		"update_combat_geometry_debug_overlay": true,
		"update_battle_action_diagnostics_overlay": true,
		"update_battle_ui": true,
		"presentation_active_after": false,
	})
	_assert_eq(host.battle_presentation_active, false, "presentation active after")
	_assert_close(host.battle_presentation_alpha, 0.65, "presentation alpha")
	_assert_eq(host.calls, [
		"begin:true:0.650",
		"mobius",
		"parallax",
		"units:0.650:0.012",
		"aim:0.012",
		"geometry",
		"diagnostics",
		"ui",
		"finish:false",
	], "call order")
	var disabled_host := FakeHost.new()
	applier.apply_render_frame(disabled_host, {
		"presentation_active": true,
		"presentation_alpha": 0.4,
		"frame_delta": 0.01,
		"interpolation_alpha": 0.4,
		"refresh_mobius_surface": false,
		"update_parallax_background": false,
		"refresh_unit_screen_positions": true,
		"update_aim_lines": false,
		"update_combat_geometry_debug_overlay": false,
		"update_battle_action_diagnostics_overlay": false,
		"update_battle_ui": true,
	})
	_assert_eq(disabled_host.calls, ["begin:true:0.400", "units:0.400:0.010", "ui", "finish:false"], "disabled call order")
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattlePresentationHostAdapter = preload(\"res://scripts/battle/battle_presentation_host_adapter.gd\")",
		"const BattlePresentationApplier = preload(\"res://scripts/battle/battle_presentation_applier.gd\")",
		"var battle_presentation_host_adapter: BattlePresentationHostAdapter",
		"var battle_presentation_applier: BattlePresentationApplier",
		"battle_presentation_host_adapter = BattlePresentationHostAdapter.new()",
		"battle_presentation_host_adapter.bind(_battle_presentation_host_callbacks())",
		"battle_presentation_applier = BattlePresentationApplier.new()",
		"func _battle_presentation_host_adapter() -> BattlePresentationHostAdapter",
		"func _battle_presentation_host_callbacks() -> Dictionary",
		"func _battle_presentation_applier() -> BattlePresentationApplier",
		"Callable(self, \"_refresh_mobius_surface_view\")",
		"Callable(self, \"_update_battle_ui\")",
		"_battle_presentation_applier().apply_render_frame(_battle_presentation_host_adapter(), plan)",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing BattlePresentationApplier boundary token: %s" % token)
			return
	var render_body := _function_body(main_source, "func _render_battle_frame")
	if render_body.is_empty():
		_fail("Unable to locate _render_battle_frame body.")
		return
	for forbidden_render_token in [
		"_refresh_mobius_surface_view",
		"_update_parallax_background",
		"_refresh_unit_screen_positions",
		"_update_aim_lines",
		"_update_combat_geometry_debug_overlay",
		"_update_battle_action_diagnostics_overlay",
		"_update_battle_ui",
		"battle_presentation_active =",
		"battle_presentation_alpha =",
	]:
		if render_body.find(forbidden_render_token) >= 0:
			_fail("_render_battle_frame should delegate presentation side effects to applier; found token: %s" % forbidden_render_token)
			return
	print("BATTLE_PRESENTATION_APPLIER_CONTRACT_PROBE ok")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.0001:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])
