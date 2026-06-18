# Catalog Card Boundary Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Continue P2 by moving the catalog card retained rendering cluster out of `scripts/main.gd` while preserving existing `MainScene.*` compatibility and TeamEdit behavior.

**Architecture:** Keep `main.gd` as the composition root and compatibility facade. Move catalog card text/body cache, retained item, and button classes to `scripts/views/catalog/`. The extracted button still exposes the same public methods and signal. `main.gd` preloads the extracted scripts with the legacy constant names.

**Files:**
- Create `scripts/views/catalog/catalog_card_text_layer.gd`
- Create `scripts/views/catalog/catalog_card_body_texture_render_canvas.gd`
- Create `scripts/views/catalog/catalog_card_body_texture_cache.gd`
- Create `scripts/views/catalog/catalog_card_retained_item.gd`
- Create `scripts/views/catalog/part_catalog_card_button.gd`
- Modify `scripts/main.gd`
- Modify catalog card source probes

## Tasks

- [ ] Add RED contracts to `tools/view_extraction_contract_probe.gd` and `tools/main_inline_class_guard_probe.gd`.
- [ ] Update catalog source probes to read extracted files instead of inline blocks.
- [ ] Extract the five class bodies, adding only required headers and preloads.
- [ ] Keep legacy constants and preload names in `main.gd`.
- [ ] Run extraction, catalog focused, budget, UI, and project gates.

## Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/catalog_card_retained_item_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/catalog_card_redraw_budget_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/catalog_card_text_vector_overlay_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/catalog_card_text_readability_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
```
