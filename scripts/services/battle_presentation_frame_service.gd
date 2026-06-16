extends RefCounted
class_name BattlePresentationFrameService

const CAPTURE_BEFORE_STEP := "before_step"
const CAPTURE_AFTER_STEP := "after_step"


func motion_snapshot_state(phase: String, camera_coord: Vector2, snapshot_state: Dictionary) -> Dictionary:
	var initialized := bool(snapshot_state.get("initialized", false))
	var previous_coord := _vector2_or(snapshot_state.get("previous_coord", camera_coord), camera_coord)
	var current_coord := _vector2_or(snapshot_state.get("current_coord", camera_coord), camera_coord)
	var before_step := phase == CAPTURE_BEFORE_STEP
	if not initialized:
		previous_coord = camera_coord
		current_coord = camera_coord
		initialized = true
	elif before_step:
		previous_coord = current_coord
	else:
		current_coord = camera_coord
	return {
		"phase": phase,
		"capture_units": true,
		"unit_before_step": before_step,
		"camera_previous_coord": previous_coord,
		"camera_current_coord": current_coord,
		"camera_snapshot_initialized": initialized,
	}


func render_frame_plan(frame_delta: float, interpolation_alpha: float, options: Dictionary = {}) -> Dictionary:
	return {
		"presentation_active": true,
		"presentation_alpha": interpolation_alpha,
		"frame_delta": frame_delta,
		"interpolation_alpha": interpolation_alpha,
		"refresh_mobius_surface": true,
		"update_parallax_background": true,
		"refresh_unit_screen_positions": true,
		"update_aim_lines": true,
		"update_combat_geometry_debug_overlay": true,
		"update_battle_action_diagnostics_overlay": bool(options.get("diagnostics_overlay_enabled", false)),
		"update_battle_ui": true,
		"presentation_active_after": false,
	}


func _vector2_or(value, fallback: Vector2) -> Vector2:
	return value if value is Vector2 else fallback
