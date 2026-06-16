# Mobius View Boundary Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Start the `main.gd` maintainability refactor by moving the low-coupling Mobius visual view classes out of `scripts/main.gd` while keeping runtime behavior unchanged.

**Architecture:** Keep `scripts/main.gd` as the composition root that creates the Mobius surface nodes, assigns the shader material, and calls `set_world()`. Move only the view class bodies to `scripts/views/`, with stable `class_name`s and public methods. Extend existing view extraction and inline-class guard probes so future work cannot reintroduce these class bodies into `main.gd`.

**Tech Stack:** Godot 4.6.2 GDScript, `Control` views, `MobiusWorld`, existing headless probes under `tools/`, and the EC-SLIM view extraction policy.

---

## File Structure

- Create `scripts/views/mobius_strip_surface_view.gd`
  - Publishes `class_name MobiusStripSurfaceView`.
  - Owns surface texture state, world-grid drawing, lane guide drawing, linear elevation overlay drawing, and base stardust snapshot fields.

- Create `scripts/views/mobius_stardust_band_view.gd`
  - Publishes `class_name MobiusStardustBandView`.
  - Extends `res://scripts/views/mobius_strip_surface_view.gd`.
  - Owns surface-attached stardust band cache/draw behavior.

- Modify `scripts/main.gd`
  - Add preloads for both Mobius view scripts near existing view preloads.
  - Remove both inline class bodies.
  - Keep `mobius_strip_surface_view = MobiusStripSurfaceView.new()` and `mobius_stardust_band_view = MobiusStardustBandView.new()` unchanged.

- Modify `tools/view_extraction_contract_probe.gd`
  - Require the two new view files.
  - Require key behavior tokens.
  - Require `main.gd` preloads.
  - Forbid inline class bodies.
  - Instantiate both views and verify representative `set_world()`/`stardust_band_snapshot()` state.

- Modify `tools/main_inline_class_guard_probe.gd`
  - Move both Mobius view classes from `ALLOWED_INLINE_CLASSES` to `EXTRACTED_INLINE_CLASSES`.

---

### Task 1: Add RED Contract Coverage

**Files:**
- Modify: `tools/view_extraction_contract_probe.gd`
- Modify: `tools/main_inline_class_guard_probe.gd`

- [ ] **Step 1: Add Mobius view source checks**

Add constants:

```gdscript
const MOBIUS_STRIP_SURFACE_VIEW_PATH := "res://scripts/views/mobius_strip_surface_view.gd"
const MOBIUS_STARDUST_BAND_VIEW_PATH := "res://scripts/views/mobius_stardust_band_view.gd"
```

Require source tokens:

```gdscript
class_name MobiusStripSurfaceView
set_surface_texture
set_world
_draw_world_grid_surface
linear_elevation_visual_enabled
stardust_band_snapshot

class_name MobiusStardustBandView
extends "res://scripts/views/mobius_strip_surface_view.gd"
_draw_stardust_surface_bands
surface_attached
source_widths
display_widths
```

- [ ] **Step 2: Add runtime checks**

Instantiate both views with `load(path).new()`.

For `MobiusStripSurfaceView`, call:

```gdscript
surface.set_world({
	"enabled": true,
	"surface_projection_mode": "world_grid",
	"surface_grid_cell_px": 56.0,
	"surface_lane_guides_enabled": true,
	"linear_elevation_visual_enabled": true,
	"screen_scale": 100.0,
	"screen_rect": Rect2(Vector2.ZERO, Vector2(320.0, 180.0)),
}, {"twist_phase": 0.0}, Vector2(1.5, 0.0))
```

Check snapshot mode, lane-guide flag, linear-elevation flag, and surface draw rect.

For `MobiusStardustBandView`, call:

```gdscript
stardust.set_world({
	"enabled": true,
	"stardust_band_enabled": true,
	"surface_segments": 48,
	"view_width": 7.2,
	"screen_scale": 100.0,
	"stardust_particle_budget": 8,
}, {"twist_phase": 0.2}, Vector2.ZERO)
```

Check `band_count == 2`, `surface_attached == true`, and non-empty source/display width arrays.

- [ ] **Step 3: Update inline guard**

Move these names to `EXTRACTED_INLINE_CLASSES`:

```gdscript
"MobiusStripSurfaceView",
"MobiusStardustBandView",
```

- [ ] **Step 4: Verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: both fail because the scripts do not exist yet and the classes remain inline.

---

### Task 2: Extract Mobius View Classes

**Files:**
- Create: `scripts/views/mobius_strip_surface_view.gd`
- Create: `scripts/views/mobius_stardust_band_view.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Move `MobiusStripSurfaceView`**

Create `scripts/views/mobius_strip_surface_view.gd` with:

```gdscript
class_name MobiusStripSurfaceView
extends Control

const MobiusWorld = preload("res://scripts/mobius_world.gd")
```

Then move the existing class body fields and methods unchanged.

- [ ] **Step 2: Move `MobiusStardustBandView`**

Create `scripts/views/mobius_stardust_band_view.gd` with:

```gdscript
class_name MobiusStardustBandView
extends "res://scripts/views/mobius_strip_surface_view.gd"
```

Then move the existing class body fields and methods unchanged.

- [ ] **Step 3: Add main preloads**

Add near existing view preloads:

```gdscript
const MobiusStripSurfaceView = preload("res://scripts/views/mobius_strip_surface_view.gd")
const MobiusStardustBandView = preload("res://scripts/views/mobius_stardust_band_view.gd")
```

- [ ] **Step 4: Remove inline class bodies**

Delete only `class MobiusStripSurfaceView` and `class MobiusStardustBandView` from `scripts/main.gd`.

---

### Task 3: Verify Behavior

**Files:**
- Test: `tools/view_extraction_contract_probe.gd`
- Test: `tools/main_inline_class_guard_probe.gd`
- Test: Mobius focused probes

- [ ] **Step 1: Run extraction probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: both exit `0`.

- [ ] **Step 2: Run Mobius focused probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/mobius_surface_full_rect_coverage_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/mobius_stardust_twist_inversion_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/mobius_background_continuity_probe.gd
```

Expected: all exit `0`.

- [ ] **Step 3: Run adjacent gates**

```bash
git diff --check
jq empty tools/probe_manifest.json
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
```

Expected: all exit `0`; known ObjectDB warnings may still print on some Godot probes.

## Self-Review

- Spec coverage: Covers P1 first batch from `docs/main_gd_maintainability_feasibility.md`.
- Placeholder scan: No `TBD`, open TODO, or unspecified verification command remains.
- Type consistency: Class names and public methods match existing `main.gd` usage and Mobius probes.
