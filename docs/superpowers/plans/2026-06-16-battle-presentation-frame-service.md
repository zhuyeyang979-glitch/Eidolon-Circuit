# Battle Presentation Frame Service

## Goal

Add a pure presentation-frame planning boundary so `scripts/main.gd` no longer owns the policy for motion snapshot camera state and render-frame refresh order directly.

## Priority

P5 service-boundary cleanup. This is a low-risk presentation staging step after `BattleRuntimeFacade` phase 2.

## Steps

1. Add `scripts/services/battle_presentation_frame_service.gd` as a pure `RefCounted` service.
2. Bind it into `BattleRuntimeFacade`.
3. Route motion snapshot camera-state updates and render-frame plan retrieval through `_battle_runtime_facade()`.
4. Keep all node, unit, UI, VFX, and screen-position side effects in `main.gd`.
5. Add contract coverage for the service, facade, and main-controller boundary.

## Non-Goals

- Do not move `_render_battle_frame()` wholesale.
- Do not move `_refresh_unit_screen_positions()`, `_update_battle_ui()`, or unit `capture_motion_snapshot()` calls into a service.
- Do not change interpolation math or visual behavior.

## Verification

- `tools/battle_presentation_frame_service_contract_probe.gd`
- `tools/battle_runtime_facade_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Battle motion/interpolation/runtime smoke probes.
