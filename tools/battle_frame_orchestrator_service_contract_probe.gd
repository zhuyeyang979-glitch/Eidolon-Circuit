extends SceneTree

const SERVICE_PATH := "res://scripts/services/battle_frame_orchestrator_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleFrameOrchestratorServiceScript := preload("res://scripts/services/battle_frame_orchestrator_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing BattleFrameOrchestratorService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name BattleFrameOrchestratorService",
		"extends RefCounted",
		"frame_step_plan",
		"simulation_phase_plan",
		"contact_pass_plan",
		"post_step_state",
		"PHASE_IDENTITY_FREEZE",
		"PHASE_HITSTOP",
		"PHASE_RESOURCE_ECONOMY",
		"PHASE_MATCH_TIMER",
		"PHASE_MESSAGE_TIMER",
		"PHASE_DEPLOYS",
		"PHASE_FIELD_SYSTEMS",
		"PHASE_PROJECTILES_WEB",
		"PHASE_INPUT",
		"PHASE_AI_TRAINING",
		"PHASE_SUMMONS_PUPPETS_BARRIERS",
		"PHASE_UNIT_PHYSICS",
		"PHASE_CAMERA_MOBIUS",
	]:
		if service_source.find(token) < 0:
			_fail("BattleFrameOrchestratorService missing token: %s" % token)
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
		"GpuCollisionPipeline",
		"Fighter",
		"take_hit",
		"queue_free",
		"_spawn_",
		"health",
		"heat",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("BattleFrameOrchestratorService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleFrameOrchestratorService = preload(\"res://scripts/services/battle_frame_orchestrator_service.gd\")",
		"var battle_frame_orchestrator_service: BattleFrameOrchestratorService",
		"battle_frame_orchestrator_service = BattleFrameOrchestratorService.new()",
		"func _battle_frame_orchestrator_service() -> BattleFrameOrchestratorService",
		"_battle_frame_orchestrator_service().frame_step_plan",
		"_battle_frame_orchestrator_service().simulation_phase_plan",
		"_battle_frame_orchestrator_service().contact_pass_plan",
		"_battle_frame_orchestrator_service().post_step_state",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate battle frame orchestrator token: %s" % token)
			return
	var tick_body := _function_body(main_source, "func _tick_battle")
	if tick_body.is_empty():
		_fail("Unable to locate _tick_battle body.")
		return
	for forbidden_tick_token in [
		"while battle_simulation_accumulator",
		"steps < BATTLE_MAX_SIMULATION_STEPS_PER_FRAME",
		"fmod(battle_simulation_accumulator",
	]:
		if tick_body.contains(forbidden_tick_token):
			_fail("_tick_battle should consume orchestrator step plan; found token: %s" % forbidden_tick_token)
			return
	var spacing_body := _function_body(main_source, "func _resolve_unit_body_spacing")
	if spacing_body.is_empty():
		_fail("Unable to locate _resolve_unit_body_spacing body.")
		return
	if not spacing_body.contains("contact_pass_plan") or not spacing_body.contains("gpu_runtime_contact") or not spacing_body.contains("cpu_pair_spacing"):
		_fail("_resolve_unit_body_spacing should dispatch contact pass plan.")
		return
	var service = BattleFrameOrchestratorServiceScript.new()
	_check_frame_step_plan(service)
	_check_phase_plan(service)
	_check_contact_plan(service)
	print("BATTLE_FRAME_ORCHESTRATOR_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_frame_step_plan(service) -> void:
	var constants := {"step_delta": 0.01, "max_steps": 4, "max_frame_delta": 0.25}
	var capped: Dictionary = service.frame_step_plan(0.1, 0.0, constants)
	_assert_eq(int(capped.get("steps", -1)), 4, "max-step clamp")
	if not bool(capped.get("truncate_accumulator", false)):
		_fail("frame_step_plan should report accumulator truncation.")
		return
	if float(capped.get("accumulator_after", 99.0)) >= 0.01:
		_fail("frame_step_plan should truncate accumulator below one step: %s" % str(capped))
		return
	var small: Dictionary = service.frame_step_plan(0.003, 0.002, constants)
	_assert_eq(int(small.get("steps", -1)), 0, "no-step small delta")
	_assert_close(float(small.get("accumulator_after", 0.0)), 0.005, "small accumulator")
	_assert_close(float(small.get("render_alpha", 0.0)), 0.5, "small alpha")
	var exact: Dictionary = service.frame_step_plan(0.02, 0.0, constants)
	_assert_eq(int(exact.get("steps", -1)), 2, "exact two steps")
	_assert_close(float(exact.get("accumulator_after", 0.0)), 0.0, "exact accumulator")
	var over_delta: Dictionary = service.frame_step_plan(1.0, 0.0, {"step_delta": 0.1, "max_steps": 10, "max_frame_delta": 0.25})
	_assert_close(float(over_delta.get("frame_delta", 0.0)), 0.25, "frame delta clamp")
	var game_over: Dictionary = service.frame_step_plan(0.1, 0.03, {"game_over": true, "step_delta": 0.01})
	if not bool(game_over.get("game_over", false)) or int(game_over.get("steps", -1)) != 0:
		_fail("game-over plan should skip simulation steps: %s" % str(game_over))
		return


func _check_phase_plan(service) -> void:
	var identity: Dictionary = service.simulation_phase_plan({"identity_transfer_active": true, "hitstop_timer": 99.0, "match_time_remaining": -1.0})
	_assert_array_eq(Array(identity.get("phases", [])), [service.PHASE_IDENTITY_FREEZE], "identity early phase")
	_assert_eq(String(identity.get("early_exit", "")), service.PHASE_IDENTITY_FREEZE, "identity early exit")
	var hitstop: Dictionary = service.simulation_phase_plan({"hitstop_timer": 0.1, "match_time_remaining": -1.0})
	_assert_array_eq(Array(hitstop.get("phases", [])), [service.PHASE_HITSTOP], "hitstop early phase")
	_assert_eq(String(hitstop.get("early_exit", "")), service.PHASE_HITSTOP, "hitstop early exit")
	var timeout: Dictionary = service.simulation_phase_plan({"match_time_remaining": 0.0})
	_assert_array_eq(Array(timeout.get("phases", [])), [service.PHASE_RESOURCE_ECONOMY, service.PHASE_MATCH_TIMER], "timeout phase prefix")
	_assert_eq(String(timeout.get("early_exit", "")), service.PHASE_MATCH_TIMER, "timeout early exit")
	var normal: Dictionary = service.simulation_phase_plan({"match_time_remaining": 60.0})
	_assert_array_eq(Array(normal.get("phases", [])), [
		service.PHASE_RESOURCE_ECONOMY,
		service.PHASE_MATCH_TIMER,
		service.PHASE_MESSAGE_TIMER,
		service.PHASE_DEPLOYS,
		service.PHASE_FIELD_SYSTEMS,
		service.PHASE_PROJECTILES_WEB,
		service.PHASE_INPUT,
		service.PHASE_AI_TRAINING,
		service.PHASE_SUMMONS_PUPPETS_BARRIERS,
		service.PHASE_UNIT_PHYSICS,
		service.PHASE_CAMERA_MOBIUS,
	], "normal phase order")
	_assert_eq(String(normal.get("early_exit", "")), "", "normal no early exit")


func _check_contact_plan(service) -> void:
	var stopped: Dictionary = service.contact_pass_plan({"delta": 0.0, "live_subject_count": 2, "has_runtime_subject": true, "gpu_available": true})
	if bool(stopped.get("should_process", true)) or bool(stopped.get("gpu_runtime_contact", true)) or bool(stopped.get("cpu_pair_spacing", true)):
		_fail("contact pass should stop for nonpositive delta: %s" % str(stopped))
		return
	var none: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 0, "has_runtime_subject": false, "gpu_available": true})
	if not bool(none.get("should_process", false)) or bool(none.get("gpu_runtime_contact", false)) or bool(none.get("cpu_pair_spacing", false)):
		_fail("contact pass with no live subjects should reset but skip pair work: %s" % str(none))
		return
	if not bool(none.get("cleanup_active_pairs", false)):
		_fail("contact pass should cleanup stale active pairs even when no live subjects.")
		return
	var cpu_only: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 2, "has_runtime_subject": false, "gpu_available": true})
	if bool(cpu_only.get("gpu_runtime_contact", true)) or not bool(cpu_only.get("cpu_pair_spacing", false)):
		_fail("contact pass should keep CPU spacing for non-runtime pairs: %s" % str(cpu_only))
		return
	var gpu: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 2, "has_runtime_subject": true, "gpu_available": true})
	if not bool(gpu.get("gpu_runtime_contact", false)) or not bool(gpu.get("cpu_pair_spacing", false)):
		_fail("contact pass should run GPU runtime contact and CPU pair spacing: %s" % str(gpu))
		return
	var single_runtime: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 1, "has_runtime_subject": true, "gpu_available": true})
	if not bool(single_runtime.get("gpu_runtime_contact", false)) or bool(single_runtime.get("cpu_pair_spacing", true)):
		_fail("contact pass should preserve old runtime GPU attempt while skipping CPU pairs for a single subject: %s" % str(single_runtime))
		return
	var warn: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 2, "has_runtime_subject": true, "gpu_available": false})
	if not bool(warn.get("warn_gpu_unavailable", false)) or bool(warn.get("gpu_runtime_contact", true)):
		_fail("contact pass should warn when runtime topology needs unavailable GPU: %s" % str(warn))
		return
	var single_warn: Dictionary = service.contact_pass_plan({"delta": 0.01, "live_subject_count": 1, "has_runtime_subject": true, "gpu_available": false})
	if not bool(single_warn.get("warn_gpu_unavailable", false)) or bool(single_warn.get("cpu_pair_spacing", true)):
		_fail("contact pass should preserve old runtime GPU warning while skipping CPU pairs for a single subject: %s" % str(single_warn))
		return


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.0001:
		_fail("%s expected %.6f, got %.6f." % [label, expected, actual])


func _assert_array_eq(actual: Array, expected: Array, label: String) -> void:
	if actual.size() != expected.size():
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
		return
	for i in range(expected.size()):
		if actual[i] != expected[i]:
			_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
			return
