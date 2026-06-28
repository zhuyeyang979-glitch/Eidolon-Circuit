extends RefCounted
class_name BattleSpatialRuntimeService

const SPECTATOR_VIEW_P1 := 0
const SPECTATOR_VIEW_P2 := 1
const SPECTATOR_VIEW_MID := 2


func camera_follow_alpha(delta: float, response_per_second: float) -> float:
	return 1.0 - exp(-maxf(0.0, response_per_second) * maxf(0.0, delta))


func player_camera_focus_intent(context: Dictionary) -> Dictionary:
	var fallback_center := float(context.get("fallback_center", 0.0))
	var fallback_lane := _clamp_lane(float(context.get("fallback_lane", 0.0)), context)
	for key in ["hero", "friendly", "enemy_hero"]:
		var snapshot := _dict(context.get(key, {}))
		if bool(snapshot.get("live", false)):
			var coord := _vec(snapshot.get("coord", Vector2(fallback_center, fallback_lane)))
			return {
				"found": true,
				"source": key,
				"center": coord.x,
				"lane": _clamp_lane(coord.y, context),
			}
	return {
		"found": false,
		"source": "fallback",
		"center": fallback_center,
		"lane": fallback_lane,
	}


func spectator_camera_focus_intent(context: Dictionary) -> Dictionary:
	var left := _dict(context.get("left", {}))
	var right := _dict(context.get("right", {}))
	var fallback_center := float(context.get("fallback_center", 0.0))
	var fallback_lane := _clamp_lane(float(context.get("fallback_lane", 0.0)), context)
	if bool(left.get("live", false)) and bool(right.get("live", false)):
		var left_coord := _vec(left.get("coord", Vector2.ZERO))
		if bool(context.get("mobius_enabled", false)):
			var delta := _vec(context.get("delta", Vector2.ZERO))
			return {
				"found": true,
				"source": "mid",
				"center": left_coord.x + delta.x * 0.5,
				"lane": _clamp_lane(left_coord.y + delta.y * 0.5, context),
			}
		var ring_delta := float(context.get("ring_delta", 0.0))
		var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
		return {
			"found": true,
			"source": "mid",
			"center": wrapf(float(left.get("ring", left_coord.x)) + ring_delta * 0.5, 0.0, ring_length),
			"lane": _clamp_lane((float(left.get("lane", left_coord.y)) + float(right.get("lane", fallback_lane))) * 0.5, context),
		}
	if bool(left.get("live", false)):
		var left_only := _vec(left.get("coord", Vector2(fallback_center, fallback_lane)))
		return {"found": true, "source": "left", "center": left_only.x, "lane": _clamp_lane(left_only.y, context)}
	if bool(right.get("live", false)):
		var right_only := _vec(right.get("coord", Vector2(fallback_center, fallback_lane)))
		return {"found": true, "source": "right", "center": right_only.x, "lane": _clamp_lane(right_only.y, context)}
	return {"found": false, "source": "fallback", "center": fallback_center, "lane": fallback_lane}


func camera_update_intent(context: Dictionary) -> Dictionary:
	var ring_length := maxf(0.001, float(context.get("ring_length", 1.0)))
	var follow_alpha := float(context.get("follow_alpha", 1.0))
	var mobius_enabled := bool(context.get("mobius_enabled", false))
	var snap_to_targets := bool(context.get("snap_to_targets", false))
	var p1_current := _dict(context.get("p1_current", {}))
	var p2_current := _dict(context.get("p2_current", {}))
	var p1_target := _dict(context.get("p1_target", {}))
	var p2_target := _dict(context.get("p2_target", {}))
	var p1 := _next_player_camera(p1_current, p1_target, follow_alpha, snap_to_targets, mobius_enabled, ring_length, context)
	var p2 := _next_player_camera(p2_current, p2_target, follow_alpha, snap_to_targets, mobius_enabled, ring_length, context)
	var spectator_current := _dict(context.get("spectator_current", {}))
	var spectator_focus := _dict(context.get("spectator_focus", {}))
	var spectator := {
		"center": float(spectator_current.get("center", 0.0)),
		"lane": _clamp_lane(float(spectator_current.get("lane", 0.0)), context),
	}
	var camera := p1
	var seat := int(context.get("seat", 1))
	if seat == 2:
		camera = p2
	elif seat == 3:
		var view_mode := int(context.get("spectator_view_mode", SPECTATOR_VIEW_MID))
		if view_mode == SPECTATOR_VIEW_P1:
			spectator = p1
		elif view_mode == SPECTATOR_VIEW_P2:
			spectator = p2
		else:
			var target_center := float(spectator_focus.get("center", spectator.center))
			var target_lane := _clamp_lane(float(spectator_focus.get("lane", spectator.lane)), context)
			var current_center := float(spectator_current.get("center", target_center))
			var next_center := current_center + float(context.get("spectator_horizontal_delta", target_center - current_center)) * follow_alpha
			if not mobius_enabled:
				next_center = wrapf(next_center, 0.0, ring_length)
			spectator = {
				"center": next_center,
				"lane": _clamp_lane(lerpf(float(spectator_current.get("lane", target_lane)), target_lane, follow_alpha), context),
			}
		camera = spectator
	var camera_mobius_s := float(context.get("camera_mobius_s", camera.center))
	var camera_center := float(camera.get("center", 0.0))
	if mobius_enabled:
		camera_mobius_s = camera_center
		camera_center = fposmod(camera_mobius_s, ring_length)
	return {
		"player_camera_centers": {1: float(p1.get("center", 0.0)), 2: float(p2.get("center", 0.0))},
		"player_camera_lanes": {1: float(p1.get("lane", 0.0)), 2: float(p2.get("lane", 0.0))},
		"spectator_camera_center": float(spectator.get("center", 0.0)),
		"spectator_camera_lane": float(spectator.get("lane", 0.0)),
		"camera_center": camera_center,
		"camera_lane_center": _clamp_lane(float(camera.get("lane", 0.0)), context),
		"camera_mobius_s": camera_mobius_s,
		"sync_camera_mobius_from_compat": not mobius_enabled,
	}


func screen_projection_intent(context: Dictionary) -> Dictionary:
	var ring_value := float(context.get("ring", 0.0))
	var lane_value := float(context.get("lane", 0.0))
	if bool(context.get("mobius_enabled", false)):
		return {
			"mode": "mobius",
			"coord": Vector2(float(context.get("lifted_s", ring_value)), float(context.get("lifted_lane", lane_value))),
		}
	var camera_center := float(context.get("camera_center", 0.0))
	var camera_lane := float(context.get("camera_lane", 0.0))
	var delta := float(context.get("ring_delta", ring_value - camera_center))
	var lane_delta := lane_value - camera_lane
	var screen_scale := maxf(0.001, float(context.get("screen_scale", 1.0)))
	var arena_center := _vec(context.get("arena_center", Vector2.ZERO))
	var half_width_units := float(context.get("arena_width", 0.0)) / screen_scale * 0.5
	var half_height_units := float(context.get("view_height", 0.0)) * 0.5
	return {
		"mode": "plane",
		"position": Vector2(arena_center.x + delta * screen_scale, arena_center.y + lane_delta * screen_scale),
		"visible": absf(delta) <= half_width_units * float(context.get("visibility_margin", 1.08)) and absf(lane_delta) <= half_height_units * float(context.get("visibility_margin", 1.08)),
		"delta": Vector2(delta, lane_delta),
	}


func world_point_visibility_intent(context: Dictionary) -> Dictionary:
	var delta_vec := _vec(context.get("delta", Vector2.ZERO))
	if not context.has("delta"):
		delta_vec = Vector2(float(context.get("ring_delta", 0.0)), float(context.get("lane_delta", 0.0)))
	var screen_scale := maxf(0.001, float(context.get("screen_scale", 1.0)))
	var half_width_units := float(context.get("arena_width", 0.0)) / screen_scale * 0.5
	var half_height_units := float(context.get("view_height", 0.0)) * 0.5
	var margin := float(context.get("margin_mult", 1.0))
	return {
		"visible": absf(delta_vec.x) <= half_width_units * margin and absf(delta_vec.y) <= half_height_units * margin,
		"delta": delta_vec,
	}


func portal_spawn_intent(context: Dictionary) -> Dictionary:
	var player_center := float(context.get("camera_center", 0.0))
	var player_lane := _clamp_lane(float(context.get("camera_lane", 0.0)), context)
	if String(context.get("role_key", "")) == "barrier":
		return {"ring": player_center, "lane": player_lane, "reason": "barrier_camera"}
	var portal := _dict(context.get("portal", {}))
	if portal.has("absolute_ring") or portal.has("absolute_lane"):
		return {
			"ring": wrapf(float(portal.get("absolute_ring", player_center)), 0.0, maxf(0.001, float(context.get("ring_length", 1.0)))),
			"lane": _clamp_lane(float(portal.get("absolute_lane", player_lane)), context),
			"reason": String(portal.get("reason", "terrain_portal")),
		}
	var portal_lane := float(portal.get("lane", 0.0))
	var lane_value := _clamp_lane(player_lane + portal_lane * 1.35, context)
	var delta_value := float(portal.get("delta", 0.0))
	if float(context.get("radius", 0.2)) > 0.58 and absf(portal_lane) > 0.5:
		lane_value = player_lane
		delta_value = -3.0 if delta_value < 0.0 else 3.0
	return {
		"ring": wrapf(player_center + delta_value, 0.0, maxf(0.001, float(context.get("ring_length", 1.0)))),
		"lane": lane_value,
		"reason": "portal",
	}


func surface_input_intent(context: Dictionary) -> Dictionary:
	var readable_input := _vec(context.get("readable_input", Vector2.ZERO))
	if not bool(context.get("mobius_enabled", false)) or readable_input.length() <= 0.04:
		return {"input": readable_input, "reason": "readable"}
	var surface_input := _vec(context.get("surface_input", Vector2.ZERO))
	if surface_input.length() <= 0.001:
		return {"input": readable_input, "reason": "surface_empty"}
	if absf(readable_input.y) >= absf(readable_input.x) and absf(readable_input.y) > 0.04:
		if absf(surface_input.y) <= 0.001 or signf(surface_input.y) != signf(readable_input.y):
			surface_input.y = readable_input.y
			surface_input = surface_input.normalized() * clampf(readable_input.length(), 0.0, 1.0)
			return {"input": surface_input, "reason": "vertical_preserved"}
	return {"input": surface_input, "reason": "surface"}


func _next_player_camera(current: Dictionary, target: Dictionary, follow_alpha: float, snap_to_targets: bool, mobius_enabled: bool, ring_length: float, context: Dictionary) -> Dictionary:
	var target_center := float(target.get("center", current.get("center", 0.0)))
	var target_lane := _clamp_lane(float(target.get("lane", current.get("lane", 0.0))), context)
	if snap_to_targets:
		return {
			"center": target_center if mobius_enabled else wrapf(target_center, 0.0, ring_length),
			"lane": target_lane,
		}
	var current_center := float(current.get("center", target_center))
	var horizontal_delta := float(target.get("horizontal_delta", target_center - current_center))
	var next_center := current_center + horizontal_delta * follow_alpha
	return {
		"center": next_center if mobius_enabled else wrapf(next_center, 0.0, ring_length),
		"lane": _clamp_lane(lerpf(float(current.get("lane", target_lane)), target_lane, follow_alpha), context),
	}


func _clamp_lane(lane_value: float, context: Dictionary) -> float:
	var limit := float(context.get("lane_limit", context.get("battle_half_height", INF)))
	if is_inf(limit):
		return lane_value
	return clampf(lane_value, -maxf(0.0, limit), maxf(0.0, limit))


func _vec(value) -> Vector2:
	if value is Vector2:
		return value
	return Vector2.ZERO


func _dict(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
