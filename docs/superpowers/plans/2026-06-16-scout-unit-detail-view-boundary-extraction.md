# Scout Unit Detail View Boundary Extraction

## Goal

Move `ScoutUnitDetailView` out of `scripts/main.gd` into a dedicated view script while keeping the existing saved-unit detail, scout detail, and editor unit-hover contracts unchanged.

## Priority

P3 editor/scout view cleanup after extracting the editor stats rail and part hover popup. This class is reused by three UI flows and is self-contained enough to extract before the more coupled torso/power/assembly-board views.

## Steps

1. Extract the inline class to `scripts/views/editor/scout_unit_detail_view.gd` with `class_name ScoutUnitDetailView`.
2. Preload the new script from `scripts/main.gd` and remove the inline class body.
3. Extend `tools/view_extraction_contract_probe.gd` to require the new script, preload, no-inline guard, and basic runtime state checks.
4. Move `ScoutUnitDetailView` from the inline allowlist to the extracted-class list in `tools/main_inline_class_guard_probe.gd`.
5. Verify with the focused extraction probes plus project check-only and relevant editor/scout hover probes.
