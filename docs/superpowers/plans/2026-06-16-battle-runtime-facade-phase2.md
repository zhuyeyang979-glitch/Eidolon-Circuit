# Battle Runtime Facade Phase 2

## Goal

Route battle lifecycle intents and action telemetry models through `BattleRuntimeFacade` so `scripts/main.gd` has one battle-runtime decision boundary for pure plan/model calls.

## Priority

P5 service-boundary cleanup. This phase improves navigability and upgrade safety without moving side-effect-heavy rendering or unit mutation code.

## Steps

1. Bind `BattleRuntimeLifecycleService` and `BattleRuntimeActionTelemetryService` into `BattleRuntimeFacade`.
2. Add facade methods that delegate existing cleanup, snapshot, kill-flow, economy, escape-pod, retreat, fracture, projectile-diagnostics, and action-telemetry methods.
3. Route `main.gd` lifecycle and telemetry call sites through `_battle_runtime_facade()`.
4. Update contract probes to require facade entry and reject direct service bypasses.
5. Update maintainability docs and ADR notes with the second-stage boundary decision.

## Non-Goals

- Do not move `_render_battle_frame()`, motion snapshot capture, VFX spawning, `queue_free`, or `take_hit` flows into the facade.
- Do not change lifecycle or telemetry behavior; this is a boundary reroute only.

## Verification

- `tools/battle_runtime_facade_contract_probe.gd`
- `tools/battle_runtime_lifecycle_service_contract_probe.gd`
- `tools/battle_runtime_action_telemetry_service_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Battle runtime smoke probes for fixed-step timing, input edge consumption, frame budget, and combat behavior.
