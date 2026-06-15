# Training Validation Advisory Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a non-blocking training validation report that explains design intent, risks, counters, and optional suggestions without producing a fixed strength score.

**Architecture:** Add a pure `TrainingValidationReportService` that consumes normalized unit, team, and runtime facts and returns advisory entries. Keep `main.gd` responsible for converting current training caches into normalized facts and displaying the report on the training config detail panel. Hard legality gates remain owned by the existing training/team legality paths.

**Tech Stack:** Godot 4 GDScript, headless probes under `tools/`.

---

## Rule Contract

- The report is advisory only: `blocking == false`, every entry has `advisory_only == true`, and no report entry may use `INVALID` as its kind.
- The report must not expose a single fixed `strength_score`, `power_score`, or total rating.
- The report uses four player-facing kinds:
  - `OBSERVE`: what the design appears to do.
  - `RISK`: where the design may fail under pressure.
  - `COUNTER`: what opposing style may stress it.
  - `SUGGEST`: conditional direction, phrased as "if your goal is X, consider Y."
- The service may infer an intent, but player-selected intent can override inference later.

## Task 1: Pure Training Validation Report Service

**Files:**
- Create: `tools/training_validation_report_service_probe.gd`
- Create: `scripts/services/training_validation_report_service.gd`
- Modify: `tools/probe_manifest.json`

- [x] Write a failing probe that preloads `TrainingValidationReportService`, checks advisory-only reports, verifies observe/risk/counter/suggest entries, verifies runtime heat/ammo/miss data affects risk notes, and rejects fixed strength-score keys.
- [x] Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_validation_report_service_probe.gd
```

Expected before implementation: FAIL because the service file does not exist.

- [x] Implement:

```gdscript
func report(context: Dictionary) -> Dictionary
func report_text(report_data: Dictionary, language: String = "zh") -> String
```

- [x] Re-run the probe and expect `TRAINING_VALIDATION_REPORT_SERVICE_PROBE ok`.

## Task 2: Training Config Integration

**Files:**
- Create: `tools/training_validation_report_main_probe.gd`
- Modify: `scripts/main.gd`
- Modify: `tools/probe_manifest.json`

- [x] Write a failing probe that starts the training config page, checks that `main.gd` owns a `training_validation_report_service`, checks `_training_validation_report_for_current_training()` returns advisory-only entries, and checks the Scout detail panel shows the report text.
- [x] Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_validation_report_main_probe.gd
```

Expected before wiring: FAIL because `main.gd` does not expose the report helper or detail-panel report.

- [x] Wire `main.gd` to preload/init the service, normalize `training_test_roster_cache` plus `training_test_loadout_cache`, and render the advisory report in the training config detail panel.
- [x] Re-run the probe and expect `TRAINING_VALIDATION_REPORT_MAIN_PROBE ok`.

## Task 3: Verification

- [x] Run focused probes:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_validation_report_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_validation_report_main_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_config_start_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/training_ball_dummy_radius_ui_probe.gd
```

- [x] Run UI and parse checks:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

- [x] Run `git diff --check`.
