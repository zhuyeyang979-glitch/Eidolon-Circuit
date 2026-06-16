# Battle Runtime Facade Phase 1

## Goal

Create a thin `BattleRuntimeFacade` staging boundary so `scripts/main.gd` enters battle frame orchestration through one runtime facade instead of calling frame-plan methods directly.

## Priority

P5 service-boundary cleanup. The goal is clearer ownership and future upgrade room, not line-count compression.

## Steps

1. Add `scripts/battle/battle_runtime_facade.gd` as a `RefCounted` facade.
2. Bind the existing `BattleFrameOrchestratorService` into the facade.
3. Route frame step, simulation phase, contact pass, and post-step state calls in `main.gd` through `_battle_runtime_facade()`.
4. Add contract coverage that keeps the facade orchestration-only and prevents `main.gd` from bypassing it for those plan methods.
5. Update the maintainability feasibility document with the new boundary decision and next priority.

## Non-Goals

- Do not migrate hit resolution, projectile lifecycle, unit mutation, VFX spawning, or HUD rendering into the facade in this phase.
- Do not reduce `main.gd` line count as a primary success metric.

## Verification

- `tools/battle_runtime_facade_contract_probe.gd`
- `tools/battle_frame_orchestrator_service_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Battle runtime smoke probes for fixed-step timing, motion snapshotting, render interpolation, input edge consumption, and frame budget behavior.
