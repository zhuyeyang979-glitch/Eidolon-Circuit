# Battle Presentation Applier

## Goal

Move the render-frame side-effect call order out of `scripts/main.gd` into a small `BattlePresentationApplier`, while keeping pure render-frame planning in `BattlePresentationFrameService`.

## Priority

P5 service-boundary cleanup. This follows the presentation frame service extraction and makes `_render_battle_frame()` a thin orchestration entry.

## Steps

1. Add `scripts/battle/battle_presentation_applier.gd` as a `RefCounted` side-effect applier.
2. Route `_render_battle_frame()` through `_battle_presentation_applier().apply_render_frame(self, plan)`.
3. Keep `BattleRuntimeFacade` pure by leaving host method calls out of the facade.
4. Add contract coverage with a fake host to verify call order and state toggles.
5. Update maintainability docs and main controller boundary probes.

## Non-Goals

- Do not move battle rules, unit iteration, VFX spawning, hit resolution, or projectile lifecycle into the applier.
- Do not introduce a large host interface until the applier grows enough to justify it.
- Do not change render-frame behavior or interpolation math.

## Verification

- `tools/battle_presentation_applier_contract_probe.gd`
- `tools/battle_presentation_frame_service_contract_probe.gd`
- `tools/battle_runtime_facade_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Battle motion/interpolation/runtime smoke probes.
