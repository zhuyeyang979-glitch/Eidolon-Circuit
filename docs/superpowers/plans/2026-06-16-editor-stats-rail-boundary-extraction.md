# Editor Stats Rail Boundary Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Start P3 by moving the low-coupling `EditorStatsRailView` out of `scripts/main.gd`.

**Architecture:** Keep `main.gd` as the TeamEdit composition root. Move only the stats rail `Control` drawing/scrolling class to `scripts/views/editor/`, preserving the legacy class name through a `main.gd` preload.

**Tech Stack:** Godot 4.6.2 GDScript, headless probes under `tools/`, existing inline class guard.

---

## File Structure

- Create `scripts/views/editor/editor_stats_rail_view.gd`
  - Publishes `class_name EditorStatsRailView`.
  - Owns stats entries, preview diff state, mouse wheel scroll, section/balance entry drawing, and value formatting.

- Modify `scripts/main.gd`
  - Add `const EditorStatsRailView = preload("res://scripts/views/editor/editor_stats_rail_view.gd")`.
  - Remove the inline `class EditorStatsRailView` body.
  - Keep existing `EditorStatsRailView.new()` call sites unchanged.

- Modify probes
  - `tools/view_extraction_contract_probe.gd`
  - `tools/main_inline_class_guard_probe.gd`

## Tasks

- [ ] Add RED contract coverage for the extracted stats rail view.
- [ ] Verify RED by running extraction and inline guard probes.
- [ ] Extract the class body to `scripts/views/editor/editor_stats_rail_view.gd`.
- [ ] Add the `main.gd` preload and remove the inline body.
- [ ] Run focused and project-level verification.

## Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
```
