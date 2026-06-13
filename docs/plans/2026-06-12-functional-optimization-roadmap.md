# Functional Optimization Roadmap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve Eidolon Circuit's existing functions, flow stability, feedback, and local verification while preserving the current gameplay, design philosophy, data rules, and battle feel.

**Architecture:** Keep `scripts/main.gd` as the current AppRoot/composition root while moving new decision logic into existing mode owners, controllers, services, views, and `BattleState`. Each optimization must be guarded by focused probes before broader behavior checks.

**Tech Stack:** Godot 4.6.2, GDScript, headless Godot probes under `tools/`, GitHub Actions Windows governance, local macOS Godot verification.

---

## Scope Contract

This roadmap is for function-level tuning and completion only.

Allowed work:

- Improve mode transitions, cleanup, and return flows.
- Improve editor feedback, saved-unit handling, settings flow, training setup, battle HUD readability, diagnostics, and probe coverage.
- Move pure decisions into existing mode/service/controller boundaries.
- Add focused probes and local macOS verification commands.

Not allowed in this roadmap:

- Change the core battle rules, win condition, roster philosophy, topology construction concept, action-module concept, or damage taxonomy.
- Change existing numeric balance unless a later task explicitly documents the reason and matching probes.
- Rewrite the architecture in one pass.
- Add new gameplay systems before current flows are stable.
- Put new feature logic directly into `main.gd` when a mode, controller, service, view, or state owner already exists.

## Current Baseline

Branch:

- `codex/yhzlxp-eidolon-work`

Current architecture anchors:

- App/mode host: `scripts/app/app_mode_host.gd`
- Mode owners: `scripts/modes/*.gd`
- Battle state owner: `scripts/battle/state/battle_state.gd`
- Architecture guide: `docs/architecture_boundaries.md`
- Probe manifest: `tools/probe_manifest.json`

Local Godot command:

```bash
/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --version
```

Expected:

```text
4.6.2.stable.official.71f334935
```

Baseline verification command:

```bash
/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot \
  --headless \
  --path /Volumes/vol1/Eidolon-Circuit-yhzlxp \
  --check-only \
  --quit-after 1
```

Expected:

- Exit code `0`.
- Known ObjectDB leak warning may appear.

## Priority Order

1. P0: Stabilize baseline and local verification.
2. P1: Harden mode transitions and cleanup ownership.
3. P2: Improve Team Edit usability and error feedback.
4. P3: Improve Saved Units and Training handoff stability.
5. P4: Improve Battle readability, diagnostics, and runtime UI stability.
6. P5: Prepare deeper runtime-system migration without behavior changes.

## Global Execution Rules

Every task should follow the same loop:

1. Read the relevant owner file and current wrapper in `scripts/main.gd`.
2. Add or update a focused probe first.
3. Run the probe and confirm the expected failure when adding new behavior coverage.
4. Implement the smallest owner-side decision change.
5. Keep Godot Node side effects in `main.gd` until a later task explicitly moves presentation ownership.
6. Run the focused probe, `--check-only`, and `git diff --check`.
7. Update this roadmap or a follow-up worklog if the priority changes.

Standard verification:

```bash
GODOT=/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot

"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
jq empty tools/probe_manifest.json
```

Focused probe command template:

```bash
GODOT=/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/<probe_name>.gd
```

## P0: Baseline And Verification

Priority: Critical

Goal: make the current synchronized project a trustworthy starting point.

Files:

- Modify only if needed: `tools/probe_manifest.json`
- Reference: `.github/workflows/godot-governance.yml`
- Reference: `docs/architecture_boundaries.md`
- Reference: `docs/local_development_status.md`

Tasks:

1. Record the local Godot path and version in the active worklog or follow-up status note.
2. Keep the macOS command template above as the local replacement for Windows `tools/run_godot_checked.ps1`.
3. Run the new architecture probes:

```bash
GODOT=/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot
for probe in \
  app_root_boundary_probe \
  app_mode_host_contract_probe \
  battle_state_contract_probe \
  battle_mode_contract_probe \
  menu_mode_contract_probe \
  team_edit_mode_contract_probe \
  saved_units_mode_contract_probe \
  settings_mode_contract_probe \
  training_mode_contract_probe
do
  "$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script "res://tools/$probe.gd" || exit $?
done
```

Expected:

- Each probe prints `ok`.
- Exit code `0`.

Acceptance:

- Local `--check-only` passes.
- New boundary probes pass.
- `git diff --check` passes.
- No packed runtime folders such as `Godot/`, `logs/`, `tools/godot-*`, `tools/git-portable/`, or `tools/downloads/` are tracked.

## P1: Mode Transition And Cleanup Stability

Priority: High

Goal: make menu, settings, saved units, team edit, training, and battle transitions predictable without changing screen content or gameplay rules.

Primary files:

- Modify: `scripts/modes/menu_mode.gd`
- Modify: `scripts/modes/team_edit_mode.gd`
- Modify: `scripts/modes/saved_units_mode.gd`
- Modify: `scripts/modes/settings_mode.gd`
- Modify: `scripts/modes/training_mode.gd`
- Modify: `scripts/modes/battle_mode.gd`
- Modify wrappers only: `scripts/main.gd`
- Test: existing mode probes under `tools/*mode*_probe.gd`

Design intent:

- Mode owners should decide transition intent, cleanup intent, and page-local state reset flags.
- `main.gd` should apply Node changes, call existing UI update methods, and preserve wrapper names.
- `AppModeHost` remains the app-level mode transition source.

Tasks:

1. Audit all `_show_*`, `_cleanup_*`, and `_commit_*_mode_*` wrappers in `scripts/main.gd`.
2. For each page, identify state reset decisions that can become intent fields in the matching mode owner.
3. Add assertions to the matching mode contract probe before changing the owner.
4. Move only pure decisions first.
5. Keep cleanup side effects in `main.gd`.
6. Verify each mode probe plus `--check-only`.

First targets:

- Returning from battle to menu should consistently clear or preserve runtime according to `BattleMode.cleanup_intent`.
- Opening saved units with a focus path should keep the focus path and return context in `SavedUnitsMode.show_intent`.
- Switching settings categories should keep rebind cleanup decisions inside `SettingsMode.category_intent`.
- Training entry setup should keep seat-confirmation routing inside `TrainingMode.begin_from_scout_intent`.

Acceptance:

- Existing screen routes still work.
- No new direct transition policy is added to `main.gd` without a mode-owner wrapper.
- Mode probes pass.

## P2: Team Edit Usability And Feedback

Priority: High

Goal: improve the editor's day-to-day usability while preserving component rules, topology constraints, catalog contents, and legality logic.

Primary files:

- Modify: `scripts/modes/team_edit_mode.gd`
- Modify: `scripts/controllers/unit_editor_board_controller.gd`
- Modify: `scripts/controllers/unit_editor_catalog_controller.gd`
- Modify: `scripts/controllers/team_edit_controller.gd`
- Modify wrappers only: `scripts/main.gd`
- Reference: `scripts/services/unit_blueprint_validator.gd`
- Reference: `scripts/services/unit_stats_service.gd`
- Test: board, catalog, layout, text overflow, and team edit probes under `tools/`

Design intent:

- The editor should explain what happened and why without changing the rules.
- Board and catalog controllers should own routing decisions.
- Existing validator and stats services remain rule authorities.
- UI Node creation and SFX can remain in `main.gd` until dedicated editor views exist.

Tasks:

1. Improve invalid-placement feedback by routing reason keys through existing controller or validator outputs.
2. Improve selected socket/part feedback without changing installation behavior.
3. Stabilize catalog filter, page, and hover state across small mode refreshes.
4. Improve save-blocking messages by pointing to the first actionable invalid condition.
5. Add probes for each pure route or message model before applying wrapper changes.

Candidate focused probes:

- `team_edit_mode_contract_probe`
- `unit_editor_board_controller_contract_probe`
- `unit_editor_catalog_controller_contract_probe`
- `text_overflow_probe`
- `ui_layout_probe`

Acceptance:

- Existing unit builds remain legal or illegal for the same reasons as before.
- No save schema changes.
- No new component category or battle behavior.
- Users get clearer feedback when an action fails.

## P3: Saved Units And Training Handoff

Priority: High

Goal: make saved-unit browsing, import, delete, training setup, and fallback repair more reliable and easier to understand.

Primary files:

- Modify: `scripts/modes/saved_units_mode.gd`
- Modify: `scripts/modes/training_mode.gd`
- Modify: `scripts/controllers/saved_units_controller.gd`
- Modify: `scripts/controllers/scout_controller.gd`
- Modify: `scripts/services/saved_unit_library_service.gd`
- Modify: `scripts/services/training_entry_service.gd`
- Modify wrappers only: `scripts/main.gd`
- Test: saved-unit and training probes under `tools/`

Design intent:

- Saved-unit IO side effects stay in `main.gd` until persistence boundaries are created.
- Pure decisions about focus, filtering, selected entry, import readiness, starter fallback, and training seat handoff should live in mode/controller/service owners.
- Strict rejection stays strict. Do not silently migrate invalid saved units.

Tasks:

1. Improve library focus behavior when a focused saved unit is missing or rejected.
2. Improve delete confirmation and post-delete selection repair.
3. Improve training import readiness messages for missing hero, invalid roster, or fallback starter.
4. Keep rejection reasons visible and stable.
5. Add focused probes before changing service/controller behavior.

Candidate focused probes:

- `saved_units_mode_contract_probe`
- `saved_units_controller_contract_probe`
- `saved_unit_library_service_contract_probe`
- `training_mode_contract_probe`
- `training_entry_service_contract_probe`
- `training_import_spawn_role_probe`

Acceptance:

- Invalid saved units remain rejected.
- Valid saved units still load with the same stats and topology.
- Training still starts with the same dummy and hero selection rules.
- Fallback behavior is explicit, not hidden.

## P4: Battle Readability And Runtime UI Stability

Priority: Medium High

Goal: make battle state easier to read and diagnose without changing damage, heat, movement, AI, projectile, contact, or win rules.

Primary files:

- Modify: `scripts/modes/battle_mode.gd`
- Modify: `scripts/battle/state/battle_state.gd`
- Modify: `scripts/services/battle_hud_state_service.gd`
- Modify: `scripts/services/battle_runtime_action_telemetry_service.gd`
- Modify: `scripts/views/battle_action_diagnostics_view.gd`
- Modify: `scripts/views/battle_instrument_gauge_view.gd`
- Modify wrappers only: `scripts/main.gd`
- Test: battle HUD, diagnostics, runtime budget, and combat probes under `tools/`

Design intent:

- Battle systems and services should produce data models and event summaries.
- Views should render existing model data.
- `main.gd` may still own live Nodes, VFX/SFX, active unit arrays, and direct runtime mutation.
- Do not change timing, collision, heat, damage, or action gates.

Tasks:

1. Improve HUD text/model consistency through `BattleHudStateService`.
2. Improve action diagnostics readability through `BattleRuntimeActionTelemetryService` and `BattleActionDiagnosticsView`.
3. Keep battle cleanup and preserve-return behavior visible in `BattleState`.
4. Add probes for any new diagnostics field or HUD model field.
5. Run a focused runtime smoke probe after each battle-facing change.

Candidate focused probes:

- `battle_mode_contract_probe`
- `battle_state_contract_probe`
- `battle_hud_state_service_contract_probe`
- `battle_runtime_action_telemetry_service_contract_probe`
- `battle_action_diagnostics_overlay_probe`
- `battle_runtime_frame_budget_probe`
- `combat_probe`

Acceptance:

- Battle rules and timings are unchanged.
- HUD and diagnostics are easier to read.
- Runtime frame budget probe remains within existing expectations.
- Known ObjectDB leak warning does not count as functional failure if exit code is `0`.

## P5: Prepare Deeper Runtime System Migration

Priority: Medium

Goal: prepare future battle-system extraction while keeping current behavior stable.

Primary files:

- Modify: `scripts/services/battle_frame_orchestrator_service.gd`
- Modify: `scripts/services/battle_input_service.gd`
- Modify: `scripts/services/battle_actor_command_service.gd`
- Modify: `scripts/services/battle_action_event_service.gd`
- Modify: `scripts/services/battle_projectile_lifecycle_service.gd`
- Modify: `scripts/services/runtime_contact_service.gd`
- Modify wrappers only: `scripts/main.gd`
- Test: existing service contract probes under `tools/`

Design intent:

- Do not create a full `battle/systems/` migration until P1 through P4 are stable.
- Continue extracting pure decisions into current services first.
- Only move files into final `battle/systems/` folders when ownership and probes are stable.

Tasks:

1. Identify one pure battle decision still embedded in `main.gd`.
2. Add or extend the matching service contract probe.
3. Move the pure decision into the service.
4. Keep live Node traversal, mutation, VFX/SFX, and Input reads in `main.gd`.
5. Run the focused probe, `combat_probe`, `battle_runtime_frame_budget_probe`, and `--check-only`.

Acceptance:

- No visible gameplay change.
- Service ownership expands only through tested pure decisions.
- `main.gd` shrinks gradually.

## Cross-Cutting Guardrails

### Data And Save Compatibility

- `UnitBlueprintValidator` remains the authority for unit blueprint rejection.
- `DataRuleService` remains the authority for single-source data rules.
- Do not silently migrate old saved units.
- Any user-facing rejection message must preserve strict rejection behavior.

### Input And Battle Feel

- Do not change reserved keys, command-window timing, boost thresholds, gun aim semantics, or module gate behavior unless a later plan explicitly scopes that change.
- Keep current keyboard/controller behavior.
- Keep combat geometry separate from Mobius visual surface tuning.

### UI And Text

- Run `ui_layout_probe` and `text_overflow_probe` after visible UI changes.
- Do not add instructional text blocks inside the game UI unless the existing screen already uses that pattern.
- Favor clearer status labels, error hints, and selection feedback over new screens.

### Performance

- Run `battle_runtime_frame_budget_probe` after battle HUD, diagnostics, VFX, or runtime-loop changes.
- Avoid per-frame dictionary churn in hot paths unless an existing service already uses a model boundary for testing.

## Suggested First Iteration

Start with P1 and P3 before touching battle runtime.

Iteration 1:

1. Extend `saved_units_mode_contract_probe` for focus-path and return-context behavior.
2. Tighten `SavedUnitsMode.show_intent`.
3. Verify saved-unit flow with focused probes and `--check-only`.

Iteration 2:

1. Extend `training_mode_contract_probe` for training-seat confirmation routes.
2. Tighten `TrainingMode.begin_from_scout_intent`.
3. Verify training entry probes and `--check-only`.

Iteration 3:

1. Extend `team_edit_mode_contract_probe` for cleanup/show intent flags.
2. Move one pure editor reset decision from `main.gd` into `TeamEditMode`.
3. Verify team edit probes, layout probes, and `--check-only`.

## Definition Of Done For Any Batch

A batch is complete only when:

- The intended user-facing improvement is described in one sentence.
- The touched ownership boundary is named.
- Focused probes pass.
- Local `--check-only` passes.
- `git diff --check` passes.
- Any unverified runtime risk is explicitly recorded.
- The work does not change core gameplay or design philosophy.

