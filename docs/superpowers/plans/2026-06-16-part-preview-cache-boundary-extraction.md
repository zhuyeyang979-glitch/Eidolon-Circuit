# Part Preview Cache Boundary Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Continue the `main.gd` maintainability refactor by moving the low-coupling part preview texture cache cluster out of `scripts/main.gd` without changing catalog, hover, or editor behavior.

**Architecture:** Keep `scripts/main.gd` as the composition root and legacy compatibility surface. Move the offscreen preview canvas, async texture cache, and preview icon view to `scripts/views/catalog/`. `main.gd` will preload the extracted scripts under the same legacy names so existing code and probes using `MainScene.PartPreviewTextureCache` or `MainScene.PartPreviewIconView` keep working.

**Tech Stack:** Godot 4.6.2 GDScript, `Control` views, `SubViewport` async capture, `AssemblyBoardRenderer`, `PartArt`, existing headless probes under `tools/`.

---

## File Structure

- Create `scripts/views/catalog/part_preview_texture_render_canvas.gd`
  - Publishes `class_name PartPreviewTextureRenderCanvas`.
  - Owns offscreen drawing through `AssemblyBoardRenderer.draw_part_preview`.

- Create `scripts/views/catalog/part_preview_texture_cache.gd`
  - Publishes `class_name PartPreviewTextureCache`.
  - Owns cache keys, pending queue, persistent `SubViewport`, submit/capture lifecycle, LRU pruning, and debug counters.

- Create `scripts/views/catalog/part_preview_icon_view.gd`
  - Publishes `class_name PartPreviewIconView`.
  - Owns preview identity signatures, cache lookup, fallback placeholder drawing, and size badge rendering.

- Modify `scripts/main.gd`
  - Add preloads for the three scripts near existing view preloads.
  - Remove the three inline class bodies.
  - Keep downstream usages unchanged.

- Modify probes
  - `tools/view_extraction_contract_probe.gd` requires files, preloads, no inline bodies, and runtime state checks.
  - `tools/main_inline_class_guard_probe.gd` moves these classes from allowed inline to extracted.
  - Source probes that previously scanned `main.gd` now scan the extracted files.

---

### Task 1: Add RED Contract Coverage

**Files:**
- Modify: `tools/view_extraction_contract_probe.gd`
- Modify: `tools/main_inline_class_guard_probe.gd`
- Modify: `tools/part_catalog_thumbnail_renderer_probe.gd`
- Modify: `tools/part_preview_no_subviewport_per_draw_probe.gd`
- Modify: `tools/part_preview_no_force_draw_probe.gd`
- Modify: `tools/teamedit_gpu_render_path_probe.gd`

- [ ] **Step 1: Require extracted preview scripts**

Add source checks for:

```gdscript
PartPreviewTextureRenderCanvas
PartPreviewTextureCache
PartPreviewIconView
```

Required behavior tokens include `AssemblyBoardRenderer.draw_part_preview`, `request_preview`, `process_queue`, `SubViewport`, `peek_preview`, and `_draw_size_badge`.

- [ ] **Step 2: Require main preload compatibility**

Require these preloads in `main.gd`:

```gdscript
preload("res://scripts/views/catalog/part_preview_texture_render_canvas.gd")
preload("res://scripts/views/catalog/part_preview_texture_cache.gd")
preload("res://scripts/views/catalog/part_preview_icon_view.gd")
```

- [ ] **Step 3: Forbid inline bodies**

Fail if `main.gd` contains:

```gdscript
class PartPreviewTextureRenderCanvas:
class PartPreviewTextureCache:
class PartPreviewIconView:
```

- [ ] **Step 4: Verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: both fail before extraction.

---

### Task 2: Extract Preview Cache Cluster

**Files:**
- Create: `scripts/views/catalog/part_preview_texture_render_canvas.gd`
- Create: `scripts/views/catalog/part_preview_texture_cache.gd`
- Create: `scripts/views/catalog/part_preview_icon_view.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Move `PartPreviewTextureRenderCanvas`**

Add header:

```gdscript
class_name PartPreviewTextureRenderCanvas
extends Control

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")
```

Then move the existing fields and methods unchanged.

- [ ] **Step 2: Move `PartPreviewTextureCache`**

Add header:

```gdscript
class_name PartPreviewTextureCache
extends RefCounted

const PartPreviewTextureRenderCanvas = preload("res://scripts/views/catalog/part_preview_texture_render_canvas.gd")
```

Then move the existing static fields and methods unchanged.

- [ ] **Step 3: Move `PartPreviewIconView`**

Add header:

```gdscript
class_name PartPreviewIconView
extends Control

const PartArt = preload("res://scripts/part_art.gd")
const PartPreviewTextureCache = preload("res://scripts/views/catalog/part_preview_texture_cache.gd")
```

Then move the existing fields and methods unchanged.

- [ ] **Step 4: Add main preloads and remove inline classes**

Add preloads under existing view preloads and delete only the three extracted inline class bodies from `scripts/main.gd`.

---

### Task 3: Verify Behavior

**Files:**
- Test: focused preview/cache probes
- Test: extraction guard probes
- Test: generic project checks

- [ ] **Step 1: Run focused probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/part_catalog_thumbnail_renderer_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/part_preview_no_subviewport_per_draw_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/part_preview_no_force_draw_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/teamedit_gpu_render_path_probe.gd
```

Expected: all exit `0`.

- [ ] **Step 2: Run adjacent runtime probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/catalog_card_size_badge_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/part_preview_async_bake_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_edit_cache_lifecycle_probe.gd
```

Expected: all exit `0`.

- [ ] **Step 3: Run project gates**

```bash
git diff --check
jq empty tools/probe_manifest.json
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

Expected: all exit `0`.

## Self-Review

- Spec coverage: Covers P2a from `docs/main_gd_maintainability_feasibility.md`.
- Placeholder scan: No `TBD`, open TODO, or unspecified verification command remains.
- Type consistency: Extracted class names and public methods match existing `main.gd` usages and `MainScene.*` probe access.
