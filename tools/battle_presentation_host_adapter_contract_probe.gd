extends SceneTree

const ADAPTER_PATH := "res://scripts/battle/battle_presentation_host_adapter.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattlePresentationHostAdapterScript := preload("res://scripts/battle/battle_presentation_host_adapter.gd")


class CallbackReceiver:
	extends RefCounted

	var active := false
	var alpha := 0.0
	var calls: Array = []

	func set_active(next_active: bool) -> void:
		active = next_active
		calls.append("active:%s" % str(next_active))

	func set_alpha(next_alpha: float) -> void:
		alpha = next_alpha
		calls.append("alpha:%.3f" % next_alpha)

	func refresh_mobius() -> void:
		calls.append("mobius")

	func update_parallax() -> void:
		calls.append("parallax")

	func refresh_units(interpolation_alpha: float, frame_delta: float) -> void:
		calls.append("units:%.3f:%.3f" % [interpolation_alpha, frame_delta])

	func update_aim(frame_delta: float) -> void:
		calls.append("aim:%.3f" % frame_delta)

	func update_geometry() -> void:
		calls.append("geometry")

	func update_diagnostics() -> void:
		calls.append("diagnostics")

	func update_ui() -> void:
		calls.append("ui")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(ADAPTER_PATH):
		_fail("Missing BattlePresentationHostAdapter script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(ADAPTER_PATH))
	for token in [
		"class_name BattlePresentationHostAdapter",
		"extends RefCounted",
		"func bind(callbacks: Dictionary) -> void",
		"func begin_presentation_frame(active: bool, alpha: float) -> void",
		"func finish_presentation_frame(active_after: bool) -> void",
		"func refresh_mobius_surface() -> void",
		"func update_parallax_background() -> void",
		"func refresh_unit_screen_positions(interpolation_alpha: float, frame_delta: float) -> void",
		"func update_aim_lines(frame_delta: float) -> void",
		"func update_combat_geometry_debug_overlay() -> void",
		"func update_battle_action_diagnostics_overlay() -> void",
		"func update_battle_ui() -> void",
		"set_presentation_active",
		"set_presentation_alpha",
		"refresh_mobius_surface",
		"update_parallax_background",
		"refresh_unit_screen_positions",
		"update_aim_lines",
		"update_combat_geometry_debug_overlay",
		"update_battle_action_diagnostics_overlay",
		"update_battle_ui",
	]:
		if source.find(token) < 0:
			_fail("BattlePresentationHostAdapter missing token: %s" % token)
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
		"_set_battle_presentation_active",
		"_set_battle_presentation_alpha",
		"_refresh_mobius_surface_view",
		"_update_parallax_background",
		"_refresh_unit_screen_positions",
		"_update_aim_lines",
		"_update_combat_geometry_debug_overlay",
		"_update_battle_action_diagnostics_overlay",
		"_update_battle_ui",
	]:
		if source.find(forbidden) >= 0:
			_fail("BattlePresentationHostAdapter should stay host-interface-only; found forbidden token: %s" % forbidden)
			return
	var adapter = BattlePresentationHostAdapterScript.new()
	var receiver := CallbackReceiver.new()
	adapter.bind({
		"set_presentation_active": Callable(receiver, "set_active"),
		"set_presentation_alpha": Callable(receiver, "set_alpha"),
		"refresh_mobius_surface": Callable(receiver, "refresh_mobius"),
		"update_parallax_background": Callable(receiver, "update_parallax"),
		"refresh_unit_screen_positions": Callable(receiver, "refresh_units"),
		"update_aim_lines": Callable(receiver, "update_aim"),
		"update_combat_geometry_debug_overlay": Callable(receiver, "update_geometry"),
		"update_battle_action_diagnostics_overlay": Callable(receiver, "update_diagnostics"),
		"update_battle_ui": Callable(receiver, "update_ui"),
	})
	adapter.begin_presentation_frame(true, 0.75)
	adapter.refresh_mobius_surface()
	adapter.update_parallax_background()
	adapter.refresh_unit_screen_positions(0.75, 0.016)
	adapter.update_aim_lines(0.016)
	adapter.update_combat_geometry_debug_overlay()
	adapter.update_battle_action_diagnostics_overlay()
	adapter.update_battle_ui()
	adapter.finish_presentation_frame(false)
	_assert_eq(receiver.active, false, "active after")
	_assert_close(receiver.alpha, 0.75, "alpha")
	_assert_eq(receiver.calls, [
		"active:true",
		"alpha:0.750",
		"mobius",
		"parallax",
		"units:0.750:0.016",
		"aim:0.016",
		"geometry",
		"diagnostics",
		"ui",
		"active:false",
	], "adapter callback order")
	var sparse_adapter = BattlePresentationHostAdapterScript.new()
	sparse_adapter.bind({})
	sparse_adapter.begin_presentation_frame(true, 0.25)
	sparse_adapter.refresh_mobius_surface()
	sparse_adapter.update_battle_ui()
	sparse_adapter.finish_presentation_frame(false)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattlePresentationHostAdapter = preload(\"res://scripts/battle/battle_presentation_host_adapter.gd\")",
		"var battle_presentation_host_adapter: BattlePresentationHostAdapter",
		"battle_presentation_host_adapter = BattlePresentationHostAdapter.new()",
		"battle_presentation_host_adapter.bind(_battle_presentation_host_callbacks())",
		"func _battle_presentation_host_adapter() -> BattlePresentationHostAdapter",
		"func _battle_presentation_host_callbacks() -> Dictionary",
		"Callable(self, \"_set_battle_presentation_active\")",
		"Callable(self, \"_set_battle_presentation_alpha\")",
		"Callable(self, \"_refresh_mobius_surface_view\")",
		"Callable(self, \"_update_parallax_background\")",
		"Callable(self, \"_refresh_unit_screen_positions\")",
		"Callable(self, \"_update_aim_lines\")",
		"Callable(self, \"_update_combat_geometry_debug_overlay\")",
		"Callable(self, \"_update_battle_action_diagnostics_overlay\")",
		"Callable(self, \"_update_battle_ui\")",
		"_battle_presentation_applier().apply_render_frame(_battle_presentation_host_adapter(), plan)",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing BattlePresentationHostAdapter boundary token: %s" % token)
			return
	print("BATTLE_PRESENTATION_HOST_ADAPTER_CONTRACT_PROBE ok")
	quit(0)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.0001:
		_fail("%s expected %.4f, got %.4f." % [label, expected, actual])
