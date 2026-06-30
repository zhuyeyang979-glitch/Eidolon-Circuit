# Project Optimization Execution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn the current project progress audit into concrete maintainability improvements while preserving behavior and verification coverage.

**Architecture:** Keep `scripts/main.gd` as the composition root and compatibility surface. Move pure editor model-building and shared identity language into focused services/helpers with contract probes before deeper UI or runtime migrations.

**Tech Stack:** Godot 4.6 GDScript, headless `tools/*_probe.gd` scripts, `tools/probe_manifest.json`, existing modular-monolith architecture documents.

---

## Priority Order

### P0: Current-Change Hygiene

**Files:**
- Track/verify: `scripts/part_identity.gd`
- Track/verify: `tools/part_identity_contract_probe.gd`
- Track/verify: `tools/unit_editor_assembly_template_service_contract_probe.gd`
- Decide later: `assets/concepts/`
- Decide later: `assets/generated/*.png.import`

**Steps:**
1. Add headless contract coverage for `PartIdentity` so the new helper is not only covered by headed screenshot probes.
2. Add headless contract coverage for assembly template model generation.
3. Register contract probes in `tools/probe_manifest.json`.
4. Leave large concept art assets unstaged until a resource policy is chosen.

**Verification:**
```bash
jq empty tools/probe_manifest.json
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/part_identity_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_template_service_contract_probe.gd
```

### P1: Extract Assembly Template Model

**Files:**
- Create: `scripts/services/unit_editor_assembly_template_service.gd`
- Modify: `scripts/main.gd`
- Test: `tools/unit_editor_assembly_template_service_contract_probe.gd`

**Steps:**
1. Move `_editor_assembly_template_model` counting, warning, slot, summary, and signature generation into `UnitEditorAssemblyTemplateService`.
2. Keep `main.gd` as adapter by passing existing topology, payload, and module-binding helpers through a callback dictionary.
3. Keep board snapshot keys unchanged: `assembly_template_model` and `assembly_template_signature`.
4. Add source guards proving the long helper functions are no longer in `main.gd`.

**Verification:**
```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_template_service_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

### P2: Follow-Up View Split

**Files:**
- Candidate: `scripts/views/editor/assembly_board_view.gd`

**Steps:**
1. After the service extraction is stable, move assembly template overlay drawing into a focused renderer/helper.
2. Keep `AssemblyBoardView` responsible for retained-layer submission and board snapshot ownership.
3. Preserve existing visual output and retained signatures.

**Verification:**
```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/view_extraction_contract_probe.gd
```

### P3: Documentation and Resource Policy

**Files:**
- Modify later: `docs/reports/2026-06-13-gameplay-design-optimization-summary.md`
- Modify later: `docs/reports/2026-06-13-gameplay-design-optimization-summary-zh.md`

**Steps:**
1. Update ObjectDB leak wording from "known non-blocking warning" to "not reproduced in latest targeted headless probes; continue watching".
2. Decide whether `assets/concepts/` belongs in Git, Git LFS, or local-only reference storage.
3. Keep generated screenshot probes listed as headed/manual validation, not as the only automated proof.

## Completion Gate

The first optimization batch is complete when:

- `main.gd` no longer owns assembly template model construction.
- `PartIdentity` and assembly template logic both have headless contract probes.
- Probe manifest JSON is valid and includes the new contract probes.
- Godot check-only and targeted probes pass.
- Large concept assets remain explicitly unstaged unless a resource policy is chosen.

## 2026-06-17 Execution Log

Completed in the first optimization batch:

- Created `scripts/services/unit_editor_assembly_template_service.gd`.
- Created `scripts/services/unit_editor_engine_allocation_service.gd`.
- Created `scripts/views/editor/assembly_template_overlay_renderer.gd`.
- Replaced the long `main.gd` assembly-template helper block with `_editor_assembly_template_callbacks()` and a thin `_editor_assembly_template_model()` service delegation.
- Replaced the long `main.gd` engine allocation model block with `_unit_editor_engine_allocation_callbacks()` and a thin `_engine_momentum_allocation_data()` service delegation.
- Moved `_compute_unit_stats` default stats schema, base motion envelope, role deploy profile, and manufacturer discount post-processing into `UnitStatsService`, leaving `main.gd` as the orchestration surface for topology, soul, thermal, and runtime modifier callbacks.
- Moved `_compute_unit_stats` part logic field copy lists and torso/ether/puppet-only gating into `UnitStatsService.copy_part_logic_stats()`, so the giant allowlist/blocklist no longer lives inline in `main.gd`.
- Moved `_compute_unit_stats` combat/projectile/lock/data-security field copy rules into `UnitStatsService.copy_part_combat_stats()`.
- Moved the top-level `_compute_unit_stats` part payload field copy rules for ammo capacity, electronic armor, material class, connection counts, and capacity limits into `UnitStatsService.copy_part_payload_stats()`, keeping torso-slot payload branch aggregation in `main.gd` for now.
- Moved torso-slot payload direct stat merges for ammo, electronic armor, escape pods, and spare weapons into `UnitStatsService.apply_torso_payload_direct_stats()`, keeping slot counts, payload volume ranks, internal-slot status, and note formatting in `main.gd` for now.
- Moved final torso-slot payload summary application into `UnitStatsService.apply_torso_payload_summary()`, including payload/ammo mass finalization, slot/software cap notes, barrier internal note formatting, and ammo note formatting; `main.gd` still owns payload traversal, catalog lookups, volume-rank sampling, and internal-slot status lookup.
- Moved torso-slot payload summary entry accumulation into `UnitStatsService.record_torso_payload_summary_entry()`, so `main.gd` now records sampled payload/software/ammo facts through a single service API instead of repeating counter/mass/volume increments in each branch.
- Moved torso-slot special payload classification for ether/soul/code into `UnitStatsService.apply_torso_special_payload_logic_stats()`, so `main.gd` now consumes a pure intent for ether callbacks, hero soul callbacks, and code AI/group stats instead of owning that kind switch inline.
- Moved soul heat-capacity stat and note application into `UnitStatsService.apply_soul_heat_capacity_stats()`, leaving `main.gd` to orchestrate only when hero soul callbacks should run.
- Moved internal payload base stat accumulation into `UnitStatsService.apply_internal_payload_base_stats()`, leaving `main.gd` to orchestrate only cooling defaults/profile, engine momentum, and booster drive helper calls.
- Moved torso-slot module payload logic-field copying into `UnitStatsService.apply_torso_module_payload_logic_stats()`, so `main.gd` no longer owns the inline command/module/fracture/morph/combine/identity allowlist for action-module payload stats.
- Moved payload slot-key normalization, generic volume-rank value normalization, and torso-slot payload route planning into `UnitStatsService`. `main.gd` now asks `UnitStatsService.torso_payload_processing_plan()` how to count, directly apply, or internally merge each payload entry, while still owning catalog lookup, precise volume-rank sampling, and soul/ether/helper callbacks.
- Moved exact part slot-volume rank thresholds into `UnitStatsService.part_slot_volume_rank()`, including explicit slot tiers, shield thresholds, engine/cooling/booster thresholds, footprint tiers, and limb footprint reduction. `main.gd` now keeps only the adapter context for size-tier rank and booster boost momentum.
- Replaced the long `AssemblyBoardView` assembly-template overlay drawing helpers with a one-line renderer delegation.
- Added `tools/part_identity_contract_probe.gd`.
- Added `tools/unit_editor_assembly_template_service_contract_probe.gd`.
- Added `tools/assembly_template_overlay_renderer_contract_probe.gd`.
- Added `tools/unit_editor_engine_allocation_service_contract_probe.gd`.
- Added `tools/unit_stats_service_contract_probe.gd`.
- Strengthened `tools/unit_stats_service_contract_probe.gd` so `UnitStatsService.base_stats()` now guards default constants, context metadata, editor colors, manufacturer-count duplication, and per-call dictionary/array ownership; the same probe now guards `copy_part_payload_stats()` ammo normalization/mass, shield aggregation, material metadata, capacity context behavior, torso payload direct stat merges for ammo/shield/escape/spare payloads, torso payload summary-entry accumulation, special payload intent classification, soul heat-capacity notes, internal payload base stat accumulation, module payload logic-field copying, and torso payload summary note/cap decisions.
- Updated `tools/main_file_extraction_contract_probe.gd` to include `UnitStatsService`, `UnitEditorAssemblyTemplateService`, and `UnitEditorEngineAllocationService`.
- Updated engine allocation regression probes to use the current `booster_drive` / `booster_boost_brake` entry IDs and public panel-open path.
- Updated `tools/probe_manifest.json` with the new headless contract probes and manual/headed visual probe entries.
- Updated local status/report wording for the ObjectDB warning based on the latest targeted verification.

Verification results captured during implementation:

```text
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
PART_IDENTITY_CONTRACT_PROBE ok
UNIT_EDITOR_ASSEMBLY_TEMPLATE_SERVICE_CONTRACT_PROBE ok
ASSEMBLY_TEMPLATE_OVERLAY_RENDERER_CONTRACT_PROBE ok
UNIT_EDITOR_ENGINE_ALLOCATION_SERVICE_CONTRACT_PROBE ok
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
HEADED_GATE_MANIFEST_SOURCE_PROBE ok
HEADED_GATE_MANIFEST_ALIGNMENT_PROBE ok groups=3
EDITOR_COST_ACCOUNTING_PROBE ok
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok
SOURCE_CODE_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
BARRIER_PANEL_PROBE ok
PROJECTILE_PROFILE_WHITELIST_PROBE ok
LEGACY_POWER_SYMBOL_ABSENCE_PROBE ok
AUDIO_LIFECYCLE_CONTRACT_PROBE ok
PART_PREVIEW_BOARD_ART_IDENTITY_PROBE ok
UNIT_EDITOR_ASSEMBLY_GUIDE_SERVICE_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok
ENGINE_POWER_ALLOCATION_SCOPE_PROBE ok
POWER_ALLOCATION_EQUALIZE_PERCENT_ALL_ENTRIES_PROBE ok
ASSEMBLY_TEMPLATE_PROBE skipped headless
PART_IDENTITY_LANGUAGE_PROBE skipped headless
```

Follow-up verification for the torso payload direct stat merge, special/module logic, and summary extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_torso_payload_direct_stats()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_torso_payload_summary()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.record_torso_payload_summary_entry()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_torso_special_payload_logic_stats()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_soul_heat_capacity_stats()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_internal_payload_base_stats()
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_torso_module_payload_logic_stats()
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok
SOURCE_CODE_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok
BARRIER_PANEL_PROBE ok
PROJECTILE_PROFILE_WHITELIST_PROBE ok
LEGACY_POWER_SYMBOL_ABSENCE_PROBE ok
```

Follow-up verification for the torso payload processing-plan extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.torso_payload_processing_plan()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok
SOURCE_CODE_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
BARRIER_PANEL_PROBE ok
PROJECTILE_PROFILE_WHITELIST_PROBE ok
LEGACY_POWER_SYMBOL_ABSENCE_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
```

Follow-up verification for the slot-volume rank formula extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.part_slot_volume_rank()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
SOURCE_CODE_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
BARRIER_PANEL_PROBE ok
PROJECTILE_PROFILE_WHITELIST_PROBE ok
LEGACY_POWER_SYMBOL_ABSENCE_PROBE ok
```

Follow-up verification for the internal slot planner extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.internal_slot_accepts_payload()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok installed=S
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
```

Follow-up verification for the torso payload plan executor extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_torso_payload_plan()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
SOURCE_CODE_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
```

Remaining items after this batch:

- Run a headed/manual visual check for `part_identity_language_probe` and `unit_editor_assembly_template_probe` when a display session is available.
- Decide whether `assets/concepts/` is Git-tracked, Git LFS-managed, or local-reference-only.
- Continue deeper `main.gd` extraction with the remaining `_compute_unit_stats` payload catalog lookup, adapter context derivation for size-tier/booster/torso-capacity facts, internal payload merge callbacks, ether/soul-bonus callbacks, `_build_editor_ui`, `_apply_editor_panel_visibility`, `_resolve_attack`, and `_refresh_editor_visual_views`.
- `power_allocation_panel_duration_estimate_probe` is not registered in the manifest and still prints stale assertion errors before exiting `0`; do not use it as completion evidence until its expectations are reviewed.
