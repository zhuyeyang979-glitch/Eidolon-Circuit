# Editor Hover Popup Boundary Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Continue P3 by moving `EditorPartHoverPopupView` out of `scripts/main.gd`.

**Architecture:** Keep `main.gd` as the editor composition root. Move the hover/pinned part popup `Control` to `scripts/views/editor/`, preserving `close_requested`, `set_part()`, `clear_card()`, and preview icon behavior through a legacy `main.gd` preload.

**Tech Stack:** Godot 4.6.2 GDScript, extracted `PartPreviewIconView`, `PartArt`, `AssemblyBoardRenderer`, headless probes under `tools/`.

---

## File Structure

- Create `scripts/views/editor/editor_part_hover_popup_view.gd`
  - Publishes `class_name EditorPartHoverPopupView`.
  - Owns hover card state, pinned close handling, scroll behavior, metric tile drawing, and preview icon synchronization.

- Modify `scripts/main.gd`
  - Add `const EditorPartHoverPopupView = preload("res://scripts/views/editor/editor_part_hover_popup_view.gd")`.
  - Remove the inline `class EditorPartHoverPopupView` body.

- Modify probes
  - `tools/view_extraction_contract_probe.gd`
  - `tools/main_inline_class_guard_probe.gd`
  - `tools/preview_sync_not_in_draw_probe.gd`

## Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/preview_sync_not_in_draw_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
```
