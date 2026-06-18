extends SceneTree

const FACADE_PATH := "res://scripts/battle/battle_runtime_facade.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BattleRuntimeFacadeScript := preload("res://scripts/battle/battle_runtime_facade.gd")
const BattleFrameOrchestratorServiceScript := preload("res://scripts/services/battle_frame_orchestrator_service.gd")
const BattleRuntimeLifecycleServiceScript := preload("res://scripts/services/battle_runtime_lifecycle_service.gd")
const BattleRuntimeActionTelemetryServiceScript := preload("res://scripts/services/battle_runtime_action_telemetry_service.gd")
const BattlePresentationFrameServiceScript := preload("res://scripts/services/battle_presentation_frame_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(FACADE_PATH):
		_fail("Missing BattleRuntimeFacade script.")
		return
	var facade_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(FACADE_PATH))
	for token in [
			"class_name BattleRuntimeFacade",
			"extends RefCounted",
			"func bind(orchestrator: BattleFrameOrchestratorService)",
			"func bind_runtime_lifecycle(service: BattleRuntimeLifecycleService)",
			"func bind_action_telemetry(service: BattleRuntimeActionTelemetryService)",
			"func bind_presentation_frame(service)",
			"func frame_step_plan",
			"func simulation_phase_plan",
			"func contact_pass_plan",
			"func post_step_state",
			"func snapshot_summary",
			"func cleanup_intent",
			"func kill_flow_intent",
			"func destroy_economy_intents",
			"func pirate_betrayal_intent",
			"func retreat_start_intent",
			"func retreat_repair_tick_intent",
			"func escape_pod_spawn_intent",
			"func escape_pod_tick_intent",
			"func fracture_cleanup_intent",
			"func torso_fracture_brood_intent",
			"func projectile_target_diagnostics",
			"func battle_action_telemetry",
			"func battle_action_diagnostics_model",
			"func motion_snapshot_state",
			"func render_frame_plan",
			"func _frame_orchestrator() -> BattleFrameOrchestratorService",
			"func _runtime_lifecycle() -> BattleRuntimeLifecycleService",
			"func _action_telemetry() -> BattleRuntimeActionTelemetryService",
			"func _presentation_frame()",
			"_frame_orchestrator().frame_step_plan",
			"_frame_orchestrator().simulation_phase_plan",
			"_frame_orchestrator().contact_pass_plan",
			"_frame_orchestrator().post_step_state",
			"_runtime_lifecycle().cleanup_intent",
			"_runtime_lifecycle().kill_flow_intent",
			"_runtime_lifecycle().escape_pod_tick_intent",
			"_runtime_lifecycle().torso_fracture_brood_intent",
			"_action_telemetry().battle_action_telemetry",
			"_action_telemetry().battle_action_diagnostics_model",
			"_presentation_frame().motion_snapshot_state",
			"_presentation_frame().render_frame_plan",
		]:
		if facade_source.find(token) < 0:
			_fail("BattleRuntimeFacade missing token: %s" % token)
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
		"take_hit",
		"queue_free",
		"_spawn_hit_effect",
		"_spawn_escape_pod_trail",
		"_update_battle_ui",
	]:
		if facade_source.find(forbidden) >= 0:
			_fail("BattleRuntimeFacade should stay orchestration-only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const BattleRuntimeFacade = preload(\"res://scripts/battle/battle_runtime_facade.gd\")",
		"var battle_runtime_facade: BattleRuntimeFacade",
			"battle_runtime_facade = BattleRuntimeFacade.new()",
			"battle_runtime_facade.bind(battle_frame_orchestrator_service)",
			"battle_runtime_facade.bind_runtime_lifecycle(battle_runtime_lifecycle_service)",
			"battle_runtime_facade.bind_action_telemetry(battle_runtime_action_telemetry_service)",
			"battle_runtime_facade.bind_presentation_frame(battle_presentation_frame_service)",
			"func _battle_runtime_facade() -> BattleRuntimeFacade",
			"_battle_runtime_facade().frame_step_plan",
			"_battle_runtime_facade().simulation_phase_plan",
			"_battle_runtime_facade().contact_pass_plan",
			"_battle_runtime_facade().post_step_state",
			"_battle_runtime_facade().cleanup_intent",
			"_battle_runtime_facade().snapshot_summary",
			"_battle_runtime_facade().kill_flow_intent",
			"_battle_runtime_facade().destroy_economy_intents",
			"_battle_runtime_facade().pirate_betrayal_intent",
			"_battle_runtime_facade().retreat_start_intent",
			"_battle_runtime_facade().retreat_repair_tick_intent",
			"_battle_runtime_facade().escape_pod_spawn_intent",
			"_battle_runtime_facade().escape_pod_tick_intent",
			"_battle_runtime_facade().fracture_cleanup_intent",
			"_battle_runtime_facade().torso_fracture_brood_intent",
			"_battle_runtime_facade().projectile_target_diagnostics",
			"_battle_runtime_facade().battle_action_telemetry",
			"_battle_runtime_facade().battle_action_diagnostics_model",
			"_battle_runtime_facade().motion_snapshot_state",
			"_battle_runtime_facade().render_frame_plan",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should enter battle runtime through facade token: %s" % token)
			return
	for forbidden in [
		"_battle_frame_orchestrator_service().frame_step_plan",
			"_battle_frame_orchestrator_service().simulation_phase_plan",
			"_battle_frame_orchestrator_service().contact_pass_plan",
			"_battle_frame_orchestrator_service().post_step_state",
			"battle_runtime_lifecycle_service.cleanup_intent",
			"battle_runtime_lifecycle_service.snapshot_summary",
			"_battle_runtime_lifecycle_service().kill_flow_intent",
			"_battle_runtime_lifecycle_service().destroy_economy_intents",
			"_battle_runtime_lifecycle_service().pirate_betrayal_intent",
			"_battle_runtime_lifecycle_service().retreat_start_intent",
			"_battle_runtime_lifecycle_service().retreat_repair_tick_intent",
			"_battle_runtime_lifecycle_service().escape_pod_spawn_intent",
			"_battle_runtime_lifecycle_service().escape_pod_tick_intent",
			"_battle_runtime_lifecycle_service().fracture_cleanup_intent",
			"_battle_runtime_lifecycle_service().torso_fracture_brood_intent",
			"battle_runtime_action_telemetry_service.battle_action_telemetry",
			"_battle_runtime_action_telemetry_service().battle_action_diagnostics_model",
			"_battle_runtime_action_telemetry_service().projectile_target_diagnostics",
			"battle_presentation_frame_service.motion_snapshot_state",
			"battle_presentation_frame_service.render_frame_plan",
			"_battle_presentation_frame_service().motion_snapshot_state",
			"_battle_presentation_frame_service().render_frame_plan",
	]:
		if main_source.find(forbidden) >= 0:
			_fail("main.gd should not bypass BattleRuntimeFacade token: %s" % forbidden)
			return
	var orchestrator = BattleFrameOrchestratorServiceScript.new()
	var lifecycle = BattleRuntimeLifecycleServiceScript.new()
	var telemetry_service = BattleRuntimeActionTelemetryServiceScript.new()
	var presentation_service = BattlePresentationFrameServiceScript.new()
	var facade = BattleRuntimeFacadeScript.new()
	facade.bind(orchestrator)
	facade.bind_runtime_lifecycle(lifecycle)
	facade.bind_action_telemetry(telemetry_service)
	facade.bind_presentation_frame(presentation_service)
	var constants := {"step_delta": 0.01, "max_steps": 3, "max_frame_delta": 0.25}
	_assert_dict_eq(facade.frame_step_plan(0.05, 0.0, constants), orchestrator.frame_step_plan(0.05, 0.0, constants), "frame plan")
	_assert_dict_eq(facade.simulation_phase_plan({"match_time_remaining": 60.0}), orchestrator.simulation_phase_plan({"match_time_remaining": 60.0}), "phase plan")
	_assert_dict_eq(facade.contact_pass_plan({"delta": 0.01, "live_subject_count": 2, "has_runtime_subject": true, "gpu_available": true}), orchestrator.contact_pass_plan({"delta": 0.01, "live_subject_count": 2, "has_runtime_subject": true, "gpu_available": true}), "contact plan")
	_assert_dict_eq(facade.post_step_state({"steps": 2, "step_delta": 0.01, "accumulator": 0.004}), orchestrator.post_step_state({"steps": 2, "step_delta": 0.01, "accumulator": 0.004}), "post-step state")
	var snapshot := {"unit_count": 2, "pending_laser_shots": 1, "pending_true_bullet_shots": 1, "battle_effect_children": 3}
	_assert_dict_eq(facade.snapshot_summary(snapshot), lifecycle.snapshot_summary(snapshot), "snapshot summary")
	_assert_dict_eq(facade.cleanup_intent(snapshot, false), lifecycle.cleanup_intent(snapshot, false), "cleanup intent")
	_assert_dict_eq(facade.kill_flow_intent({"stage": "post_detach", "victim_id": 2, "killer_id": 1, "killed_role": "hero", "killer_victory_points": 0, "win_points": 2}), lifecycle.kill_flow_intent({"stage": "post_detach", "victim_id": 2, "killer_id": 1, "killed_role": "hero", "killer_victory_points": 0, "win_points": 2}), "kill flow intent")
	_assert_array_eq(facade.destroy_economy_intents({"victim_id": 2, "killer_id": 1, "bounty_reward": 5}), lifecycle.destroy_economy_intents({"victim_id": 2, "killer_id": 1, "bounty_reward": 5}), "destroy economy intents")
	_assert_dict_eq(facade.escape_pod_tick_intent({"pod_live": true, "delta_vec": Vector2(0.01, 0.01), "carried_modules": 1}), lifecycle.escape_pod_tick_intent({"pod_live": true, "delta_vec": Vector2(0.01, 0.01), "carried_modules": 1}), "escape pod tick")
	var projectile_facts := [{"attacker_id": 10, "target_id": 20, "target_live": true, "target_role": "hero", "event": {"projectile_style": "beam"}, "fallback_behavior": "laser"}]
	_assert_dict_eq(facade.projectile_target_diagnostics({"id": 10, "projectile_signal": 0.5}, projectile_facts), telemetry_service.projectile_target_diagnostics({"id": 10, "projectile_signal": 0.5}, projectile_facts), "projectile diagnostics")
	var telemetry := facade.battle_action_telemetry([{"id": 10, "live": true, "action_telemetry": {"actions": []}}])
	_assert_dict_eq(telemetry, telemetry_service.battle_action_telemetry([{"id": 10, "live": true, "action_telemetry": {"actions": []}}]), "battle action telemetry")
	_assert_dict_eq(facade.battle_action_diagnostics_model(telemetry, {"max_units": 1}), telemetry_service.battle_action_diagnostics_model(telemetry, {"max_units": 1}), "battle diagnostics model")
	_assert_dict_eq(facade.motion_snapshot_state(BattlePresentationFrameServiceScript.CAPTURE_BEFORE_STEP, Vector2(2.0, 3.0), {}), presentation_service.motion_snapshot_state(BattlePresentationFrameServiceScript.CAPTURE_BEFORE_STEP, Vector2(2.0, 3.0), {}), "motion snapshot state")
	_assert_dict_eq(facade.render_frame_plan(0.01, 0.5, {"diagnostics_overlay_enabled": true}), presentation_service.render_frame_plan(0.01, 0.5, {"diagnostics_overlay_enabled": true}), "render frame plan")
	var fallback_facade = BattleRuntimeFacadeScript.new()
	var fallback_plan: Dictionary = fallback_facade.frame_step_plan(0.0, 0.0, constants)
	if bool(fallback_plan.get("game_over", true)) or int(fallback_plan.get("steps", -1)) != 0:
		_fail("BattleRuntimeFacade fallback orchestrator should remain usable: %s" % str(fallback_plan))
		return
	print("BATTLE_RUNTIME_FACADE_CONTRACT_PROBE ok")
	quit(0)


func _assert_dict_eq(actual: Dictionary, expected: Dictionary, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_array_eq(actual: Array, expected: Array, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
