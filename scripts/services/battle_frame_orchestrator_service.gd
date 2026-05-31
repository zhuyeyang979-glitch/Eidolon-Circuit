extends RefCounted
class_name BattleFrameOrchestratorService

const PHASE_IDENTITY_FREEZE := "identity_freeze"
const PHASE_HITSTOP := "hitstop"
const PHASE_RESOURCE_ECONOMY := "resource_economy"
const PHASE_MATCH_TIMER := "match_timer"
const PHASE_MESSAGE_TIMER := "message_timer"
const PHASE_DEPLOYS := "deploys"
const PHASE_FIELD_SYSTEMS := "field_systems"
const PHASE_PROJECTILES_WEB := "projectiles_web"
const PHASE_INPUT := "input"
const PHASE_AI_TRAINING := "ai_training"
const PHASE_SUMMONS_PUPPETS_BARRIERS := "summons_puppets_barriers"
const PHASE_UNIT_PHYSICS := "unit_physics"
const PHASE_CAMERA_MOBIUS := "camera_mobius"


func frame_step_plan(delta: float, accumulator: float, constants: Dictionary) -> Dictionary:
	if bool(constants.get("game_over", false)):
		return {
			"game_over": true,
			"frame_delta": clampf(delta, 0.0, float(constants.get("max_frame_delta", 0.25))),
			"steps": 0,
			"accumulator_before": accumulator,
			"accumulator_after": accumulator,
			"render_alpha": 0.0,
			"truncate_accumulator": false,
		}
	var max_frame_delta := float(constants.get("max_frame_delta", 0.25))
	var step_delta := maxf(0.000001, float(constants.get("step_delta", 1.0 / 120.0)))
	var max_steps := maxi(1, int(constants.get("max_steps", 8)))
	var frame_delta := clampf(delta, 0.0, max_frame_delta)
	var next_accumulator := accumulator + frame_delta
	var steps := 0
	while next_accumulator + 0.0000001 >= step_delta and steps < max_steps:
		next_accumulator -= step_delta
		steps += 1
	var truncate := steps >= max_steps and next_accumulator >= step_delta
	if truncate:
		next_accumulator = fmod(next_accumulator, step_delta)
	return {
		"game_over": false,
		"frame_delta": frame_delta,
		"steps": steps,
		"accumulator_before": accumulator,
		"accumulator_after": next_accumulator,
		"render_alpha": clampf(next_accumulator / step_delta, 0.0, 1.0),
		"truncate_accumulator": truncate,
	}


func simulation_phase_plan(context: Dictionary) -> Dictionary:
	if bool(context.get("identity_transfer_active", false)):
		return {
			"early_exit": PHASE_IDENTITY_FREEZE,
			"phases": [PHASE_IDENTITY_FREEZE],
		}
	if float(context.get("hitstop_timer", 0.0)) > 0.0:
		return {
			"early_exit": PHASE_HITSTOP,
			"phases": [PHASE_HITSTOP],
		}
	if float(context.get("match_time_remaining", 0.0)) <= 0.0:
		return {
			"early_exit": PHASE_MATCH_TIMER,
			"phases": [PHASE_RESOURCE_ECONOMY, PHASE_MATCH_TIMER],
		}
	return {
		"early_exit": "",
		"phases": [
			PHASE_RESOURCE_ECONOMY,
			PHASE_MATCH_TIMER,
			PHASE_MESSAGE_TIMER,
			PHASE_DEPLOYS,
			PHASE_FIELD_SYSTEMS,
			PHASE_PROJECTILES_WEB,
			PHASE_INPUT,
			PHASE_AI_TRAINING,
			PHASE_SUMMONS_PUPPETS_BARRIERS,
			PHASE_UNIT_PHYSICS,
			PHASE_CAMERA_MOBIUS,
		],
	}


func contact_pass_plan(context: Dictionary) -> Dictionary:
	var delta := float(context.get("delta", 0.0))
	var live_count := int(context.get("live_subject_count", 0))
	var has_runtime := bool(context.get("has_runtime_subject", false))
	var gpu_available := bool(context.get("gpu_available", false))
	return {
		"should_process": delta > 0.0,
		"reset_counters": delta > 0.0,
		"cleanup_suppression": delta > 0.0,
		"gpu_runtime_contact": delta > 0.0 and has_runtime and gpu_available,
		"warn_gpu_unavailable": delta > 0.0 and has_runtime and not gpu_available,
		"cpu_pair_spacing": delta > 0.0 and live_count >= 2,
		"cleanup_active_pairs": delta > 0.0,
	}


func post_step_state(context: Dictionary) -> Dictionary:
	var steps := int(context.get("steps", 0))
	var step_delta := maxf(0.000001, float(context.get("step_delta", 1.0 / 120.0)))
	var accumulator := float(context.get("accumulator", 0.0))
	return {
		"last_frame_steps": steps,
		"step_count_increment": steps,
		"render_alpha": clampf(accumulator / step_delta, 0.0, 1.0),
	}
