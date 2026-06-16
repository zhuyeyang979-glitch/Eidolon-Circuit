# Torso Detail Panel Boundary Extraction

## Goal

Move `TorsoDetailPanelView` out of `scripts/main.gd` into a dedicated editor view script while preserving torso payload management and module-binding UI contracts.

## Priority

P3 editor view cleanup. This is the last non-assembly editor panel still inline after extracting stats, hover previews, unit detail, and power allocation views.

## Steps

1. Extract the inline class to `scripts/views/editor/torso_detail_panel_view.gd` with `class_name TorsoDetailPanelView`.
2. Preload the extracted script from `scripts/main.gd` and remove the inline class body.
3. Update extraction and inline-class guard probes.
4. Verify with torso/module-binding probes that call `_binding_key_rect`, `_binding_action_side_rect`, close, hover, and payload interactions.
