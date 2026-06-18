extends RefCounted
class_name BattleRuntimeFacade

const BattleFrameOrchestratorService = preload("res://scripts/services/battle_frame_orchestrator_service.gd")
const BattleRuntimeLifecycleService = preload("res://scripts/services/battle_runtime_lifecycle_service.gd")
const BattleRuntimeActionTelemetryService = preload("res://scripts/services/battle_runtime_action_telemetry_service.gd")
const BattlePresentationFrameServiceScript = preload("res://scripts/services/battle_presentation_frame_service.gd")

var frame_orchestrator: BattleFrameOrchestratorService
var runtime_lifecycle: BattleRuntimeLifecycleService
var action_telemetry: BattleRuntimeActionTelemetryService
var presentation_frame


func bind(orchestrator: BattleFrameOrchestratorService) -> void:
	frame_orchestrator = orchestrator


func bind_runtime_lifecycle(service: BattleRuntimeLifecycleService) -> void:
	runtime_lifecycle = service


func bind_action_telemetry(service: BattleRuntimeActionTelemetryService) -> void:
	action_telemetry = service


func bind_presentation_frame(service) -> void:
	presentation_frame = service


func frame_step_plan(delta: float, accumulator: float, constants: Dictionary) -> Dictionary:
	return _frame_orchestrator().frame_step_plan(delta, accumulator, constants)


func simulation_phase_plan(context: Dictionary) -> Dictionary:
	return _frame_orchestrator().simulation_phase_plan(context)


func contact_pass_plan(context: Dictionary) -> Dictionary:
	return _frame_orchestrator().contact_pass_plan(context)


func post_step_state(context: Dictionary) -> Dictionary:
	return _frame_orchestrator().post_step_state(context)


func runtime_count(snapshot: Dictionary) -> int:
	return _runtime_lifecycle().runtime_count(snapshot)


func snapshot_summary(snapshot: Dictionary) -> Dictionary:
	return _runtime_lifecycle().snapshot_summary(snapshot)


func cleanup_intent(snapshot: Dictionary, preserve_for_return: bool = false) -> Dictionary:
	return _runtime_lifecycle().cleanup_intent(snapshot, preserve_for_return)


func kill_flow_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().kill_flow_intent(context)


func destroy_economy_intents(context: Dictionary) -> Array:
	return _runtime_lifecycle().destroy_economy_intents(context)


func pirate_betrayal_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().pirate_betrayal_intent(context)


func retreat_start_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().retreat_start_intent(context)


func retreat_repair_tick_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().retreat_repair_tick_intent(context)


func escape_pod_spawn_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().escape_pod_spawn_intent(context)


func escape_pod_tick_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().escape_pod_tick_intent(context)


func fracture_cleanup_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().fracture_cleanup_intent(context)


func torso_fracture_brood_intent(context: Dictionary) -> Dictionary:
	return _runtime_lifecycle().torso_fracture_brood_intent(context)


func projectile_target_diagnostics(unit_facts: Dictionary, projectile_facts: Array) -> Dictionary:
	return _action_telemetry().projectile_target_diagnostics(unit_facts, projectile_facts)


func battle_action_telemetry(unit_snapshots: Array) -> Dictionary:
	return _action_telemetry().battle_action_telemetry(unit_snapshots)


func battle_action_diagnostics_model(telemetry: Dictionary, options: Dictionary = {}) -> Dictionary:
	return _action_telemetry().battle_action_diagnostics_model(telemetry, options)


func motion_snapshot_state(phase: String, camera_coord: Vector2, snapshot_state: Dictionary) -> Dictionary:
	return _presentation_frame().motion_snapshot_state(phase, camera_coord, snapshot_state)


func render_frame_plan(frame_delta: float, interpolation_alpha: float, options: Dictionary = {}) -> Dictionary:
	return _presentation_frame().render_frame_plan(frame_delta, interpolation_alpha, options)


func _frame_orchestrator() -> BattleFrameOrchestratorService:
	if frame_orchestrator == null:
		frame_orchestrator = BattleFrameOrchestratorService.new()
	return frame_orchestrator


func _runtime_lifecycle() -> BattleRuntimeLifecycleService:
	if runtime_lifecycle == null:
		runtime_lifecycle = BattleRuntimeLifecycleService.new()
	return runtime_lifecycle


func _action_telemetry() -> BattleRuntimeActionTelemetryService:
	if action_telemetry == null:
		action_telemetry = BattleRuntimeActionTelemetryService.new()
	return action_telemetry


func _presentation_frame():
	if presentation_frame == null:
		presentation_frame = BattlePresentationFrameServiceScript.new()
	return presentation_frame
