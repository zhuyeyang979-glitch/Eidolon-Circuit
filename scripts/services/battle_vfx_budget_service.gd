extends RefCounted
class_name BattleVfxBudgetService

const RESULT_DROP_TOTAL_DISABLED := -3
const RESULT_DROP_KIND_LIMIT := -2
const RESULT_DROP_TOTAL_LIMIT := -1
const RESULT_ACCEPTED := 1
const RESULT_ACCEPTED_PROJECTILE_TRACE := 2
const RESULT_ACCEPTED_HIT_EFFECT := 3


func frame_state(spawn_count: int, projectile_trace_count: int, hit_effect_count: int, drop_count: int) -> Dictionary:
	return {
		"spawn_count": max(0, spawn_count),
		"projectile_trace_count": max(0, projectile_trace_count),
		"hit_effect_count": max(0, hit_effect_count),
		"drop_count": max(0, drop_count),
	}


func reset_frame_state(previous_state: Dictionary = {}) -> Dictionary:
	return {
		"spawn_count": 0,
		"projectile_trace_count": 0,
		"hit_effect_count": 0,
		"drop_count": max(0, int(previous_state.get("drop_count", 0))),
	}


func consume_code(kind: String, spawn_count: int, projectile_trace_count: int, hit_effect_count: int, total_limit: int, projectile_trace_limit: int, hit_effect_limit: int) -> int:
	if total_limit <= 0:
		return RESULT_DROP_TOTAL_DISABLED
	var kind_limit := total_limit
	match kind:
		"projectile_trace":
			kind_limit = projectile_trace_limit
		"hit_effect":
			kind_limit = hit_effect_limit
	if spawn_count >= total_limit:
		return RESULT_DROP_TOTAL_LIMIT
	if kind == "projectile_trace" and projectile_trace_count >= kind_limit:
		return RESULT_DROP_KIND_LIMIT
	if kind == "hit_effect" and hit_effect_count >= kind_limit:
		return RESULT_DROP_KIND_LIMIT
	if kind == "projectile_trace":
		return RESULT_ACCEPTED_PROJECTILE_TRACE
	if kind == "hit_effect":
		return RESULT_ACCEPTED_HIT_EFFECT
	return RESULT_ACCEPTED


func consume_intent(kind: String, frame_state_value: Dictionary, quality_values: Dictionary) -> Dictionary:
	var state := _normalized_frame_state(frame_state_value)
	var total_limit := int(quality_values.get("battle_vfx_budget", 260))
	var kind_limit := total_limit
	match kind:
		"projectile_trace":
			kind_limit = int(quality_values.get("projectile_trace_budget", 120))
		"hit_effect":
			kind_limit = int(quality_values.get("hit_effect_budget", 110))
	var code := consume_code(
		kind,
		int(state.get("spawn_count", 0)),
		int(state.get("projectile_trace_count", 0)),
		int(state.get("hit_effect_count", 0)),
		total_limit,
		int(quality_values.get("projectile_trace_budget", 120)),
		int(quality_values.get("hit_effect_budget", 110))
	)
	if code == RESULT_DROP_TOTAL_DISABLED:
		return _drop_result(state, total_limit, kind_limit, "total_disabled")
	if code == RESULT_DROP_TOTAL_LIMIT:
		return _drop_result(state, total_limit, kind_limit, "total_limit")
	if code == RESULT_DROP_KIND_LIMIT:
		return _drop_result(state, total_limit, kind_limit, "kind_limit")
	state["spawn_count"] = int(state.get("spawn_count", 0)) + 1
	var increment_projectile_trace := code == RESULT_ACCEPTED_PROJECTILE_TRACE
	var increment_hit_effect := code == RESULT_ACCEPTED_HIT_EFFECT
	if increment_projectile_trace:
		state["projectile_trace_count"] = int(state.get("projectile_trace_count", 0)) + 1
	elif increment_hit_effect:
		state["hit_effect_count"] = int(state.get("hit_effect_count", 0)) + 1
	return {
		"accepted": true,
		"state": state,
		"total_limit": total_limit,
		"kind_limit": kind_limit,
		"increment_projectile_trace_total": increment_projectile_trace,
		"increment_hit_effect_total": increment_hit_effect,
		"reason": "accepted",
	}


func _normalized_frame_state(frame_state_value: Dictionary) -> Dictionary:
	return {
		"spawn_count": max(0, int(frame_state_value.get("spawn_count", 0))),
		"projectile_trace_count": max(0, int(frame_state_value.get("projectile_trace_count", 0))),
		"hit_effect_count": max(0, int(frame_state_value.get("hit_effect_count", 0))),
		"drop_count": max(0, int(frame_state_value.get("drop_count", 0))),
	}


func _drop_result(state: Dictionary, total_limit: int, kind_limit: int, reason: String) -> Dictionary:
	state["drop_count"] = int(state.get("drop_count", 0)) + 1
	return {
		"accepted": false,
		"state": state,
		"total_limit": total_limit,
		"kind_limit": kind_limit,
		"increment_projectile_trace_total": false,
		"increment_hit_effect_total": false,
		"reason": reason,
	}
