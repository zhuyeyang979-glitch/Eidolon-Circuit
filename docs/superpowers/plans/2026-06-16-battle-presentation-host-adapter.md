# Battle Presentation Host Adapter

## Goal

Make the presentation applier depend on an explicit host adapter interface instead of raw `main.gd` private method names.

## Priority

P5 service-boundary cleanup. This follows `BattlePresentationApplier` and removes its transitional dependency on host method strings.

## Steps

1. Add `scripts/battle/battle_presentation_host_adapter.gd` as a small callback-backed adapter.
2. Bind existing `main.gd` presentation refresh methods through `_battle_presentation_host_callbacks()`.
3. Route `_render_battle_frame()` through `_battle_presentation_applier().apply_render_frame(_battle_presentation_host_adapter(), plan)`.
4. Update the applier contract probe to assert adapter-style method calls and forbid `main.gd` private method names in the applier.
5. Add a host adapter contract probe for callback binding, empty callback safety, and `main.gd` integration tokens.
6. Update maintainability docs and the main controller boundary probe.

## Non-Goals

- Do not move Mobius, parallax, unit screen position, aim line, diagnostics, or battle UI implementations out of `main.gd` in this phase.
- Do not put presentation side effects into `BattleRuntimeFacade`; it remains a pure plan/model boundary.
- Do not change render interpolation, simulation timing, or battle UI behavior.

## Verification

- `tools/battle_presentation_host_adapter_contract_probe.gd`
- `tools/battle_presentation_applier_contract_probe.gd`
- `tools/battle_presentation_frame_service_contract_probe.gd`
- `tools/battle_runtime_facade_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Battle motion/interpolation/runtime smoke probes.
