# Assembly Board View Boundary Extraction

## Goal

Move the retained assembly-board renderer cluster out of `scripts/main.gd` into a dedicated editor view script while preserving custom-board drawing, retained component items, edge/socket overlays, and drag/drop interaction contracts.

## Priority

P2/P3 bridge. This is the largest remaining inline view cluster in `main.gd`; extracting it completes the current inline-class cleanup and makes future board renderer upgrades safer.

## Steps

1. Extract `AssemblyBoardRenderLayer`, `AssemblyBoardRenderComponentItem`, `AssemblyBoardRenderItem`, and `AssemblyBoardView` to `scripts/views/editor/assembly_board_view.gd` with `class_name AssemblyBoardView`.
2. Preload the extracted view from `scripts/main.gd` and remove the inline class cluster.
3. Update extraction, inline-class, GPU-render-path, and retained-board probes so they assert the new boundary instead of scanning `main.gd`.
4. Verify retained custom-board creation, dirty item updates, no-root-redraw behavior, and project parse checks.
