# Unit Editor Power Dock Boundary Extraction

## Goal

Move `UnitEditorPowerDockView` out of `scripts/main.gd` into a dedicated editor view script while preserving the compact power allocation dock used in Unit Edit.

## Priority

P3 editor view cleanup. The dock is smaller and less coupled than the full `EngineMomentumAllocationPanelView`, so it is the next safest extraction after `ScoutUnitDetailView`.

## Steps

1. Extract the inline class to `scripts/views/editor/unit_editor_power_dock_view.gd` with `class_name UnitEditorPowerDockView`.
2. Preload the new script from `scripts/main.gd` and remove the inline class body.
3. Update `tools/view_extraction_contract_probe.gd` with source, preload, no-inline, and runtime state checks.
4. Move `UnitEditorPowerDockView` from the inline guard allowlist to the extracted-class list.
5. Update source-scanning power dock probes to inspect the extracted file.
6. Verify with extraction probes, power dock probes, and project check-only.
