extends RefCounted
class_name BattlePresentationHostAdapter

var set_presentation_active_callback := Callable()
var set_presentation_alpha_callback := Callable()
var refresh_mobius_surface_callback := Callable()
var update_parallax_background_callback := Callable()
var refresh_unit_screen_positions_callback := Callable()
var update_aim_lines_callback := Callable()
var update_combat_geometry_debug_overlay_callback := Callable()
var update_battle_action_diagnostics_overlay_callback := Callable()
var update_battle_ui_callback := Callable()


func bind(callbacks: Dictionary) -> void:
	set_presentation_active_callback = callbacks.get("set_presentation_active", Callable())
	set_presentation_alpha_callback = callbacks.get("set_presentation_alpha", Callable())
	refresh_mobius_surface_callback = callbacks.get("refresh_mobius_surface", Callable())
	update_parallax_background_callback = callbacks.get("update_parallax_background", Callable())
	refresh_unit_screen_positions_callback = callbacks.get("refresh_unit_screen_positions", Callable())
	update_aim_lines_callback = callbacks.get("update_aim_lines", Callable())
	update_combat_geometry_debug_overlay_callback = callbacks.get("update_combat_geometry_debug_overlay", Callable())
	update_battle_action_diagnostics_overlay_callback = callbacks.get("update_battle_action_diagnostics_overlay", Callable())
	update_battle_ui_callback = callbacks.get("update_battle_ui", Callable())


func begin_presentation_frame(active: bool, alpha: float) -> void:
	_call(set_presentation_active_callback, [active])
	_call(set_presentation_alpha_callback, [alpha])


func finish_presentation_frame(active_after: bool) -> void:
	_call(set_presentation_active_callback, [active_after])


func refresh_mobius_surface() -> void:
	_call(refresh_mobius_surface_callback)


func update_parallax_background() -> void:
	_call(update_parallax_background_callback)


func refresh_unit_screen_positions(interpolation_alpha: float, frame_delta: float) -> void:
	_call(refresh_unit_screen_positions_callback, [interpolation_alpha, frame_delta])


func update_aim_lines(frame_delta: float) -> void:
	_call(update_aim_lines_callback, [frame_delta])


func update_combat_geometry_debug_overlay() -> void:
	_call(update_combat_geometry_debug_overlay_callback)


func update_battle_action_diagnostics_overlay() -> void:
	_call(update_battle_action_diagnostics_overlay_callback)


func update_battle_ui() -> void:
	_call(update_battle_ui_callback)


func _call(callback: Callable, args: Array = []) -> void:
	if callback.is_valid():
		callback.callv(args)
