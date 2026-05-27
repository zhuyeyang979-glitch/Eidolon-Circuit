# Eidolon Circuit Local Development Status

Last updated: 2026-05-27 17:31 JST

This file is the local execution board while Linear is being used by another project. The checked-in backlog remains `docs/development_backlog.md`; this file records the current local baseline and the next safe implementation order.

## Current Baseline

- Project root: `E:\New project`
- Branch: `safety/eidolon-health-audit-20260525-004915`
- HEAD: `e4ab183`
- Git remote: `origin https://github.com/zhuyeyang979-glitch/Eidolon-Circuit.git`
- Worktree state at baseline: clean
- Godot version: `tools/godot-4.6.2/Godot_v4.6.2-stable_win64_console.exe`

## Large File Watch

| File | Lines | Bytes | Local Risk |
| --- | ---: | ---: | --- |
| `scripts/main.gd` | 51650 | 3101256 | Still the primary extraction target. |
| `scripts/fighter.gd` | 4617 | 224371 | Keep as Node shell; move pure heat/movement/action rules out gradually. |
| `scripts/assembly_board_renderer.gd` | 1911 | 107736 | Shared board/runtime art source; avoid duplicate combat visuals. |
| `scripts/part_art.gd` | 746 | 32890 | Good candidate for small visual taxonomy helpers. |
| `scripts/motion_budget.gd` | 40 | 2327 | Small and stable; preserve as canonical motion formula surface. |

## Verification Baseline

- `tools/run_godot_checked.ps1 -Headless -CheckOnly -TimeoutSec 120`: passed.
- Governance mirror probes from `.github/workflows/godot-governance.yml`: all 16 passed.
- Godot ObjectDB leak warnings appeared on some runs; no functional assertion failed.

Passed governance probes:

- `action_profile_registry_completeness_probe`
- `drive_service_contract_probe`
- `unit_validator_single_source_probe`
- `main_file_extraction_contract_probe`
- `runtime_no_legacy_drive_reads_probe`
- `probe_manifest_no_legacy_fixture_probe`
- `drive_budget_teamedit_probe`
- `drive_runtime_movement_probe`
- `action_module_execution_matrix_probe`
- `projectile_profile_whitelist_probe`
- `teamedit_bound_module_tryout_probe`
- `mobius_bullet_readability_probe`
- `battle_controlled_unit_center_on_begin_probe`
- `battle_vfx_budget_probe`
- `ui_layout_probe`
- `text_overflow_probe`

## Local Execution Order

1. `EC-SLIM-002`: Extract Main Inline Views.
2. `EC-SLIM-003`: Split Unit Editor Board and Catalog Controllers.
3. `EC-SLIM-004`: Split Saved Unit and Training Services.
4. `EC-SLIM-005`: Split Battle Runtime Services.
5. `EC-SLIM-006`: Split Fighter Runtime Models.
6. `EC-SLIM-007`: Lock Mobius Visual Boundary.
7. `EC-SLIM-008`: CI, Probe, and Worklog Governance.

## Next Safe Step

`EC-SLIM-002` has started with two low-risk inline views extracted:

- `BackdropView` -> `scripts/views/backdrop_view.gd`
- `SortieThumbView` -> `scripts/views/sortie_thumb_view.gd`

Next safe chunk: extract another low-state inline view from `scripts/main.gd`, keep the legacy symbol/preload path stable, extend `view_extraction_contract_probe`, then rerun `view_extraction_contract_probe`, `main_file_extraction_contract_probe`, `ui_layout_probe`, `text_overflow_probe`, and check-only.
