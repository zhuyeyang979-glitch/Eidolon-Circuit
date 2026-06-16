# Engine Momentum Allocation Panel Boundary Extraction

## Goal

Move `EngineMomentumAllocationPanelView` out of `scripts/main.gd` into a dedicated editor view script while preserving the detailed drive allocation panel contract.

## Priority

P3 editor view cleanup after the compact power dock. The panel is larger, but its interface is still a clear view boundary: `set_allocation_data`, public entry/edit helpers, and signals back to `main.gd`.

## Steps

1. Extract the inline class to `scripts/views/editor/engine_momentum_allocation_panel_view.gd` with `class_name EngineMomentumAllocationPanelView`.
2. Add the required `AssemblyBoardRenderer` preload inside the extracted view.
3. Preload the new script from `scripts/main.gd` and remove the inline class body.
4. Update extraction and inline-class guard probes.
5. Verify with focused extraction probes plus power allocation panel probes that touch sliders, close/equalize, numeric input, heat bars, and panel visibility.
