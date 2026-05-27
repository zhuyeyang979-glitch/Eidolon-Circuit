# Eidolon Circuit Development Backlog

Last updated: 2026-05-27

This backlog is written in a Linear-ready format. The intended Linear epic is:

`Eidolon Circuit Codebase Slimdown 2026-05-27`

Current connector note: the Linear skill is visible in Codex, but callable Linear issue/project tools are not exposed in this session. Until those tools are available, this file is the source backlog. When Linear access is restored, create one Linear epic with the title above and copy each `EC-SLIM-*` item below as an issue.

## EC-SLIM-001 Baseline Code Health Audit

Priority: High

Goal: preserve today's working baseline before any large split.

Implementation:
- Record current branch, clean/dirty state, main file sizes, service/controller list, and CI workflow status.
- Run headless check-only and the GitHub Governance 16-probe mirror.
- Update `WORKLOG_RULEBOOK.md` with the baseline SHA/verification result.

Acceptance:
- `git status --short` is understood before edits.
- `tools/run_godot_checked.ps1 -Headless -CheckOnly -TimeoutSec 120` passes.
- The 16 probes in `.github/workflows/godot-governance.yml` pass locally or failures are logged with exact names.

## EC-SLIM-002 Extract Main Inline Views

Priority: High

Goal: move large nested UI/effect classes out of `scripts/main.gd` without behavior changes.

Implementation:
- Move battle HUD/minimap/sortie/detail views to `scripts/views/`.
- Move editor hover, torso detail, power dock, and assembly board views to `scripts/views/unit_editor/`.
- Move battle visual effect Node2D classes to `scripts/effects/`.
- Keep class names, preloads, and public methods stable so existing call sites remain simple.

Acceptance:
- `main.gd` no longer owns the extracted view class bodies.
- View extraction contract probe verifies required view scripts exist and `main.gd` preloads them.
- `ui_layout_probe`, `text_overflow_probe`, and headed `unit_edit` gate pass.

## EC-SLIM-003 Split Unit Editor Board And Catalog Controllers

Priority: High

Goal: make Unit Editor work easier to extend without touching unrelated battle/menu code.

Implementation:
- Add `UnitEditorBoardController` for board input routing, topology click/drag, torso detail open routing, orientation popup state, and board zoom helpers.
- Add `UnitEditorCatalogController` for catalog filtering, card models, hover model generation, and drag ghost coordination.
- Keep `main.gd` wrappers for existing probes while delegating ownership to controllers.

Acceptance:
- Board/click/pose/scythe/torso-detail focused probes pass.
- New contract probe ensures no new board input helper is added directly to `main.gd` without delegation.

## EC-SLIM-004 Split Saved Unit And Training Services

Priority: High

Goal: isolate save/load, saved-unit strict rejection, Unit 2 compatibility, and training test entry logic.

Implementation:
- Add `SavedUnitLibraryService` for saved-unit indexing, latest-name lookup, overwrite/save-as path selection, schema stamping, and no-silent-delete rules.
- Add `TrainingEntryService` for direct training entry, training dummy lookup/repair, and validation notes.
- Keep `DataRuleService` and `UnitBlueprintValidator` as the data-rule authorities.

Acceptance:
- Saved-unit overwrite/save-as, strict rejection, Unit 2 torso resolution, and training-entry probes pass.
- Save/load helpers in `main.gd` become thin wrappers.

## EC-SLIM-005 Split Battle Runtime Services

Priority: High

Goal: reduce battle tick risk by separating orchestration from pure runtime decisions.

Implementation:
- Add `BattleInputService` for stable gameplay movement input, direction taps, turn-key gun aim, and pause/reserved-key policy.
- Add `ProjectileRuntimeService` for projectile event construction, straight aim rays, first-impact selection, trace payloads, and damage formula.
- Add `RuntimeContactService` for collider sorting, contact keys, material/stiffness/damage-path decisions.

Acceptance:
- Gun activation, projectile, contact, battle movement, and VFX budget probes pass.
- Mobius visual changes cannot affect gameplay ray/collision contract.

## EC-SLIM-006 Split Fighter Runtime Models

Priority: High

Goal: keep `Fighter` as the Node shell while pure gameplay logic moves into testable helpers.

Implementation:
- Add `FighterMovementModel` for move/boost/brake/drive command decisions.
- Add `FighterHeatModel` for heat events, tag relief, manual cooling, and overheat transitions.
- Add `RuntimeModuleActionService` for module action payloads, variants, timing, pose overrides, and completion effects.
- Add `GunActivationService` for gun drive ratios, aim rotation, mobility contracts, and fire events.

Acceptance:
- `fighter.gd` keeps rendering/lifecycle integration but delegates pure rule decisions.
- Heat, movement, module action, gun activation, and check-only probes pass.

## EC-SLIM-007 Lock Mobius Visual Boundary

Priority: Medium

Goal: make the Mobius field easier to tune without risking combat geometry.

Implementation:
- Keep `MobiusWorld` as visual field/projection authority.
- Add a small `MobiusSurfaceConfig` or equivalent helper for shader uniforms, brightness defaults, grid density, and double-ridge parameters.
- Guard the separation between gameplay anchor projection and surface visual depth.

Acceptance:
- Mobius grid/depth/unit-sync/bullet-readability probes pass.
- New contract probe confirms combat geometry does not consume surface warp.

## EC-SLIM-008 CI, Probe, And Worklog Governance

Priority: Medium

Goal: make large refactors safe to continue after this pass.

Implementation:
- Keep `.github/workflows/godot-governance.yml` aligned with the 16-probe headless mirror.
- Keep `tools/probe_manifest.json` as the headed/current/core source.
- Add extraction contract probes for every new service/controller boundary.
- Update `WORKLOG_RULEBOOK.md` after each stage and run `tools/sync_worklog.ps1`.

Acceptance:
- Full headed gate passes after major extraction stages.
- GitHub Actions latest `Godot Governance` run is success after push.
- Worklog mirror sync reports matching SHA256.
