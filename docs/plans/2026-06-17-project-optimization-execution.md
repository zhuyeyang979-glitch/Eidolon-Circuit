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
- Policy decided: `assets/concepts/` keeps curated tracked baselines; local drafts go under ignored scratch folders.
- Policy decided: tracked `assets/generated/*.png.import` files stay in Git with their runtime atlases.

**Steps:**
1. Add headless contract coverage for `PartIdentity` so the new helper is not only covered by headed screenshot probes.
2. Add headless contract coverage for assembly template model generation.
3. Register contract probes in `tools/probe_manifest.json`.
4. Leave local-only concept art drafts unstaged unless they satisfy `docs/resource_policy.md`.

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
2. Keep curated `assets/concepts/` baselines in Git, keep local drafts in ignored scratch folders, and revisit Git LFS only when the size triggers in `docs/resource_policy.md` are met.
3. Keep generated screenshot probes listed as headed/manual validation, not as the only automated proof.

## Completion Gate

The first optimization batch is complete when:

- `main.gd` no longer owns assembly template model construction.
- `PartIdentity` and assembly template logic both have headless contract probes.
- Probe manifest JSON is valid and includes the new contract probes.
- Godot check-only and targeted probes pass.
- Large local-only concept drafts remain explicitly unstaged unless they satisfy `docs/resource_policy.md`.

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
- Moved torso-slot payload direct stat merges for ammo, electronic armor, escape pods, and spare weapons into `UnitStatsService.apply_torso_payload_direct_stats()`, keeping slot counts, internal-slot status, and note formatting in `main.gd` for now.
- Moved final torso-slot payload summary application into `UnitStatsService.apply_torso_payload_summary()`, including payload/ammo mass finalization, slot/software cap notes, barrier internal note formatting, and ammo note formatting; `main.gd` still owns payload traversal, catalog lookups, and internal-slot status lookup.
- Moved torso-slot payload summary entry accumulation into `UnitStatsService.record_torso_payload_summary_entry()`, so `main.gd` now records sampled payload/software/ammo facts through a single service API instead of repeating counter/mass/volume increments in each branch.
- Moved torso-slot special payload classification for ether/soul/code into `UnitStatsService.apply_torso_special_payload_logic_stats()`, so `main.gd` now consumes a pure intent for ether callbacks, hero soul callbacks, and code AI/group stats instead of owning that kind switch inline.
- Moved soul heat-capacity stat and note application into `UnitStatsService.apply_soul_heat_capacity_stats()`, leaving `main.gd` to orchestrate only when hero soul callbacks should run.
- Moved internal payload base stat accumulation into `UnitStatsService.apply_internal_payload_base_stats()`, leaving `main.gd` to orchestrate only cooling defaults/profile, engine momentum, and booster drive helper calls.
- Moved torso-slot module payload logic-field copying into `UnitStatsService.apply_torso_module_payload_logic_stats()`, so `main.gd` no longer owns the inline command/module/fracture/morph/combine/identity allowlist for action-module payload stats.
- Moved payload slot-key normalization, generic volume-rank value normalization, and torso-slot payload route planning into `UnitStatsService`. `main.gd` now asks `UnitStatsService.torso_payload_processing_plan()` how to count, directly apply, or internally merge each payload entry, while still owning catalog lookup and soul/ether/helper callbacks.
- Moved exact part slot-volume rank thresholds into `UnitStatsService.part_slot_volume_rank()`, including explicit slot tiers, shield thresholds, engine/cooling/booster thresholds, footprint tiers, and limb footprint reduction. `main.gd` now keeps only the adapter context for size-tier rank and booster boost momentum.
- Moved payload slot-volume rank selection into `UnitStatsService.payload_slot_volume_rank()`, including ammo tier selection, precomputed-rank overrides, and fallback slot rank lookup. `main.gd` now keeps only the adapter context for exact size-tier and booster boost-momentum facts.
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

Follow-up verification for the internal payload merge-plan extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_internal_payload_merge_plan()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
```

Follow-up verification for the ether payload stat extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_ether_payload_stats()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
ETHER_HEAT_ECONOMY_PROBE ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
BARRIER_PANEL_PROBE ok
```

Follow-up verification for the soul-bonus stat extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.apply_soul_bonus_stats()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
SOUL_OATH_ACTIVATION_PROBE ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
SOURCE_CODE_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
BARRIER_PANEL_PROBE ok
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=4.100 max_ms=12.252
```

Follow-up verification for the payload context extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.part_payload_context()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok installed=S
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
ETHER_HEAT_ECONOMY_PROBE ok
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.886 max_ms=4.063
```

Follow-up verification for the payload slot-volume rank extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.payload_slot_volume_rank()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
INTERNAL_SLOT_SIZE_PROBE ok profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
ETHER_HEAT_ECONOMY_PROBE ok
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.767 max_ms=4.582
```

Follow-up verification for the part size-tier rule extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.normalize_size_tier_label()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
UNIT_EDITOR_TOPOLOGY_SOCKET_SIZE_GATE_PROBE ok
CATALOG_CARD_SIZE_BADGE_PROBE ok badges=muscle:M,limb_muscle:S,booster:XS,engine:XS,cooling:XS,module:S
PART_IDENTITY_CONTRACT_PROBE ok
INTERNAL_SLOT_SIZE_PROBE profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok
TORSO_SIZE_MASS_PROBE torsos=44 masses={ "XS": 6.0, "S": 12.0, "M": 24.0, "L": 48.0, "XL": 96.0 }
PART_SIZE_VISUAL_PROBE xs=0.65 m=1.00 xl=1.82 badge=XL
UNIT_EDITOR_SOCKET_SIZE_REJECTION_PROBE ok
TERMINAL_WEAPON_SIZE_PROBE melee=0.260 ranged=0.476 extent=0.161
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
ETHER_HEAT_ECONOMY_PROBE ok
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.762 max_ms=5.247
```

Follow-up verification for the thruster momentum rule extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.economy_median_mass_for_rank()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
BOOST_FORMULA_ALLOCATION_PLUS_EXTRA_PROBE ok total=300.0 speed=6.00
BOOST_FORMULA_V3_PROBE ok
THRUSTER_MOMENTUM_RANGE_PROBE ok
THRUSTER_GRADIENT_CATALOG_PROBE ok boosters=24 families=6 ranks=5
THRUSTER_GRADIENT_V3_PROBE ok families=6
THRUSTER_DUAL_GRADIENT_PROBE ok checked=24 families=6
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok move 1.51->4.53 boost 6.48->14.27 brake 3.56->7.84
THRUSTER_DUAL_ALLOCATION_RANGE_PROBE ok checked=24 boosted=24
THRUSTER_DUAL_SLIDER_WRITEBACK_PROBE ok drive=67.9 boost=102.0
THRUSTER_HOVER_BOOST_TERMS_PROBE ok
THRUSTER_SAME_POWER_CHAIN_PROBE ok move=2.40 boost=6.40 turn=2.62
ENGINE_THRUSTER_COOLING_ECONOMY_PROBE ok
ENGINE_THRUSTER_LIMB_BUDGET_PROBE ok required=80.0
INTERNAL_SLOT_SIZE_PROBE profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.787 max_ms=2.759
```

Follow-up verification for the payload catalog selection extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.payload_catalog_selection()
UNIT_STATS_SERVICE_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
Godot --check-only --quit-after 1: pass
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
INTERNAL_SLOT_SIZE_PROBE profiles=5 explicit=[5, 2, 2, 2, 2, 2]
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_EDITOR_ENGINE_ALLOCATION_SERVICE_CONTRACT_PROBE ok
UNIT_EDITOR_ASSEMBLY_TEMPLATE_SERVICE_CONTRACT_PROBE ok
SOURCE_CODE_PRIORITY_MAIN_RUNTIME_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
MODULE_PAYLOAD_REBIND_KEEPS_MODULE_PROBE ok
SINGLE_BOOSTER_PER_TORSO_INSTALL_PROBE ok payloads=1
PAYLOAD_REQUIRES_TORSO_INSTALL_PROBE ok payloads=3
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.922 max_ms=4.204
```

Follow-up verification for the torso capacity rule extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.component_is_torso()
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
UNIT_STATS_SERVICE_CONTRACT_PROBE ok speed=1.428 puppet_cost=75
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
TORSO_SLOT_CAPACITY_CONTRACT_PROBE raw=3/6 base=4/6 helper=5/7 ok
TORSO_SLOT_CAPACITY_PLUS_ONE_PROBE ok torsos=41
INTERNAL_SLOT_SIZE_PROBE profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok hard=INVALID: idle mass 60% exceeds 55%; connect or remove non-functional material. blank=INVALID: blank topology needs at least one material node.
UNIT_EDITOR_ENGINE_ALLOCATION_SERVICE_CONTRACT_PROBE ok
SOURCE_CODE_PRIORITY_MAIN_RUNTIME_PROBE ok
SOUL_OATH_ACTIVATION_PROBE ok
ETHER_HEAT_ECONOMY_PROBE ok
MODULE_PAYLOAD_REBIND_KEEPS_MODULE_PROBE ok
SINGLE_BOOSTER_PER_TORSO_INSTALL_PROBE ok payloads=1
PAYLOAD_REQUIRES_TORSO_INSTALL_PROBE ok payloads=3
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.787 max_ms=3.604 frames=160 warmup=20 fixture=generated_training_starter
```

Follow-up verification for the internal payload concrete callback extraction:

```text
RED: unit_stats_service_contract_probe failed on missing UnitStatsService.cooling_tags_for_part()
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
UNIT_STATS_SERVICE_CONTRACT_PROBE ok speed=1.428 puppet_cost=75
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
ENGINE_MOMENTUM_UNIFICATION_PROBE ok output=38.2 heat_coeff=0.050
ENGINE_PHILOSOPHY_PROBE ok command=1.18 ranged_heat_coeff=0.045 booster_speed=1.18
ENGINE_RUNTIME_STAT_MERGE_PROBE ok ranged=1.24 booster=1.22 support=1844.7
ENGINE_OUTPUT_CURRENT_X3_PROBE ok raw=38.16 scaled=343.44
ENGINE_OUTPUT_EFFECTIVE_SCALE_PROBE ok current_multiplier=9x raw=38.16 scaled=343.44
THERMAL_CHAIN_V3_PROBE ok
COOLER_POOL_DOUBLE_PROBE ok pool=1998.0 rate=500.0
BOOST_HEAT_INDEPENDENT_FROM_DRIVE_ALLOCATION_PROBE ok low=6.00 high=10.00 heat=8.0
BOOST_PEAK_NO_IDLE_HEAT_PROBE ok idle=0.600 peak=100.0
BOOST_FORMULA_ALLOCATION_PLUS_EXTRA_PROBE ok total=300.0 speed=6.00
BOOST_FORMULA_V3_PROBE ok
THRUSTER_DUAL_MOTION_FORMULA_PROBE ok move 1.51->4.53 boost 6.48->14.27 brake 3.56->7.84
THRUSTER_DUAL_ALLOCATION_RANGE_PROBE ok checked=24 boosted=24
THRUSTER_DUAL_SLIDER_WRITEBACK_PROBE ok drive=67.9 boost=102.0
INTERNAL_SLOT_SIZE_PROBE profiles=5 explicit=[5, 2, 2, 2, 2, 2]
AMMO_INSTALL_SIZE_PAYLOAD_PROBE tier=S total=36 ok
SHIELD_PAYLOAD_SLOT_VOLUME_PROBE ok ranks={ "SHIELD VEIL PATCH": 2.0, "SHIELD DUEL HALO": 3.0, "SHIELD SIEGE MANTLE": 4.0, "SHIELD TITAN DOME": 5.0 } installed=S
EDITOR_COST_ACCOUNTING_PROBE node_cost=117 engine_cost=14 team_cost=234
ENGINE_POWER_ALLOCATION_OPEN_PROBE ok detail_open=true dock_visible=true entries=4 pool=343.4
POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=20.917
UNIT_BUILD_RULE_TRAINING_GATE_PROBE ok hard=INVALID: idle mass 60% exceeds 55%; connect or remove non-functional material. blank=INVALID: blank topology needs at least one material node.
PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=259 sections=8
BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=1.838 max_ms=4.681 frames=160 warmup=20 fixture=generated_training_starter
```

Follow-up verification for the editor panel visibility plan extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_panel_visibility_plan()
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
LIFECYCLE_SERVICES_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
AMMO_SIZE_UI_PROBE entries=5 tier=M ok
UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
```

`UILifecycleService.editor_panel_visibility_plan()` now owns the pure editor mode normalization, visibility flags, custom-board and ammo-slider gates, unit-page state, and editor action-key groups. `main.gd` remains responsible for localized labels and concrete control mutation. The separately identified `editor_canvas_probe` reliability issue is resolved in the follow-up below.

Follow-up verification for the editor action-state extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_action_state()
jq empty tools/probe_manifest.json: pass
git diff --check: pass
Godot --check-only --quit-after 1: pass
LIFECYCLE_SERVICES_CONTRACT_PROBE ok
MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=0 limb=1 weapon=2
UNIT_EDITOR_CLIPBOARD_PROBE ok
BARRIER_EDITOR_SCREEN_PROBE rect=636.9x460.0 tl=0 center=25 br=49
SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
AMMO_SIZE_UI_PROBE entries=5 tier=M ok
UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
```

`UILifecycleService.editor_action_state()` now owns action classification plus visibility and disabled-state decisions for board-primary, unit-page, canvas, clipboard, orientation, sort, catalog-page, and unit actions. `main.gd` samples clipboard state once per panel refresh and retains control positioning, localization, tooltips, colors, and scene-tree mutation.

Follow-up verification for the editor canvas probe contract:

```text
RED: editor_canvas_probe reported a 94.34px roundtrip drift but still exited 0
RED: core manifest membership check returned false
GREEN: EDITOR_CANVAS_PROBE roundtrip=0.00 nodes=2 edges=1 fixed=0.000
GREEN: core manifest membership check returned true
```

The stale probe mixed a board-local input with `_topology_position_to_board()`, which returns a global point. Its diagnostic offset was exactly the board global origin `(8,94)`, while the hard-coded input was also 16px outside the valid topology square and was correctly clamped. The probe now derives a valid board-local point from a topology reference, verifies the local-input/local-rendering roundtrip, returns immediately from every failure branch, exits explicitly with `0` only on success, and is registered in the manifest `core` set.

Follow-up verification for the power-allocation duration estimate probe:

```text
RED: power_allocation_panel_duration_estimate_probe emitted two monotonicity errors but exited 0
RED: core manifest membership check returned false
GREEN: POWER_ALLOCATION_PANEL_DURATION_ESTIMATE_PROBE ok base=0.300 slow=1.979 high=0.990 heavy=2.969 capped=6.000
GREEN: core manifest membership check returned true
```

The stale fixture multiplied driven mass by 20 before comparing allocation and mass sensitivity, which put every comparison on `MotionBudget`'s intentional 6-second ceiling. The probe now uses a non-saturated 2x-mass fixture for monotonicity, verifies the 6-second ceiling separately, returns immediately from every failure branch, exits explicitly with `0` only on success, and is registered in the manifest `core` set.

Follow-up verification for the thruster and Boost-panel probe contracts:

```text
RED: thruster_fixed_drive_demand_probe and thruster_dual_budget_legality_probe read scrubbed legacy demand fields and exited 0 after errors
RED: thruster_philosophy_probe compared cross-size averages and legacy recoil cancellation, then exited 1
RED: power_allocation_panel_boost_dash_probe read a closed detail view, emitted five errors, and exited 0
GREEN: THRUSTER_FIXED_DRIVE_DEMAND_PROBE ok demand=22.6 total=56.6
GREEN: THRUSTER_DUAL_BUDGET_LEGALITY_PROBE ok required=169.9 drive=67.9 boost=102.0
GREEN: THRUSTER_PHILOSOPHY_PROBE ok cruise=148.8 sustain_dur=1.00 overburn_ratio=3.08 counter_brake=2.00
GREEN: POWER_ALLOCATION_PANEL_BOOST_DASH_PROBE ok fixed=22.6 extra=34.0 peak=56.6
```

The demand probes now verify canonical `drive_demand_total` output and the absence of scrubbed legacy keys. The philosophy probe verifies explicit family-default tradeoffs plus catalog mass identity instead of comparing unequal size mixes. The Boost dash probe uses the real engine-payload detail-open path and terminates on every failure. All four probes are registered in the manifest `core` set.

Follow-up headed visual verification:

```text
PART_IDENTITY_LANGUAGE_SCREENSHOT res://assets/concepts/parts/image2_individual/part_identity_language_v1.png
ASSEMBLY_TEMPLATE_MODEL status=warn slots=6 warnings=4
ASSEMBLY_TEMPLATE_SCREENSHOT res://assets/concepts/parts/image2_individual/unit_editor_assembly_template_overlay_v1.png
```

Both manual-visual probes were run twice on macOS Godot `4.6.2.stable.official.71f334935` with the Metal Forward+ renderer. Manual inspection confirmed the part-identity language screenshot remains readable for catalog cards, hover detail, and partial/unknown battle previews; the assembly-template overlay shows all six slots and four pending warnings without text overflow or blocking the board. The generated screenshots were restored to the tracked baseline afterward because the assembly-template capture includes dynamic frame timing and is not a stable pixel baseline.

Follow-up resource policy decision:

```text
assets/concepts tracked files=133 size=79M
assets/generated tracked files=20 size=18M
untracked assets/concepts/assets/generated changes=0
```

`docs/resource_policy.md` now keeps existing curated concept baselines and runtime generated atlases in Git, keeps tracked `assets/generated/*.png.import` files with their source PNGs, and reserves ignored `_local`, `_incoming`, and `_scratch` folders for future local-only art iterations. Git LFS is deferred until a concrete size trigger is reached instead of partially migrating this branch.

Follow-up editor action presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_action_presentation()
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=0 limb=1 weapon=2
GREEN: BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
```

`UILifecycleService.editor_action_presentation()` now owns the pure button presentation plan for board-primary, unit-page, canvas/clipboard, orientation, and unit actions. `scripts/main.gd` still owns the actual `Control` mutation, but `_apply_editor_panel_visibility()` no longer carries the long action-kind presentation branch.

Follow-up editor action build spec extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_action_build_specs()
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=0 limb=1 weapon=2
GREEN: BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_action_build_specs()` now owns the pure button creation specs for panel, assembly-guide, unit action, board-primary, canvas tool, board zoom, and catalog page controls. `_build_editor_ui()` remains the scene-tree builder and signal wiring surface.

Follow-up sort/template action build spec extraction:

```text
RED: lifecycle_services_contract_probe failed because sort/template build specs were not covered yet
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

The sort action controls and template drawer toggle now use the same `UILifecycleService.editor_action_build_specs()` source as the other editor action buttons. The three UI layout probes exited `0` but emitted Godot exit-time RID/ObjectDB warnings; keep watching those warnings in later headed/manual verification.

Follow-up part library group/filter presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_part_group_button_presentation()
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_part_group_button_presentation()` and `UILifecycleService.editor_part_filter_button_presentation()` now own the pure group/filter button visibility, disabled-state, layout, and selected-color plans. `_apply_editor_panel_visibility()` keeps localized labels and scene-tree mutation. The catalog UI probes exited `0` but emitted the known Godot exit-time RID/ObjectDB warnings.

Follow-up ammo-size control presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_ammo_size_control_presentation()
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: AMMO_SIZE_SLIDER_PROBE base=18 ranks=XS..XL ui=ok
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_ammo_size_control_presentation()` now owns the pure ammo-size title, slider, value label, and tick label presentation plan. `_apply_editor_panel_visibility()` still supplies localized value/tick text and mutates the actual controls. The UI probes exited `0` but emitted the known Godot exit-time RID/ObjectDB warnings.

Follow-up sort controls presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_sort_controls_presentation()
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_sort_controls_presentation()` now owns the pure sort key normalization, sort button labels, sort panel shape, and sort option visibility/layout/color plan. `_apply_editor_panel_visibility()` remains the scene-tree adapter and only applies the returned presentation plan. The UI probes exited `0` but emitted the known Godot exit-time RID/ObjectDB warnings.

Follow-up editor info panel presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_info_panel_presentation()
RED: main_file_extraction_contract_probe reported missing UILifecycleService.editor_info_panel_presentation delegation and old local info-panel formulas
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_info_panel_presentation()` now owns the pure right-side info panel visibility/layout plan for unit, summary, stats/detail, component art, battle preview, structure reference preservation, catalog page label, and catalog title. `_apply_editor_panel_visibility()` remains the scene-tree adapter and still owns save-feedback layout. The main extraction probe also now returns immediately on missing delegated tokens so failure output cannot fall through to an `ok` line.

Follow-up editor shop feedback presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_shop_feedback_presentation()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_shop_feedback_presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_shop_feedback_presentation()` now owns the pure shop hint and pending-feedback copy/color plan for payload pending, canvas pending, and empty states. `_apply_editor_panel_visibility()` remains the scene-tree adapter and supplies only `pending_kind` plus the already localized payload/canvas detail. The main extraction probe now rejects the old inline shop hint/pending text and pending-color formulas in `main.gd`.

Follow-up editor color controls presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_color_controls_presentation()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_color_controls_presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: BATTLE_ACTOR_COMMAND_SERVICE_CONTRACT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_color_controls_presentation()` now owns the pure editor color controls visibility/text/selected-swatch plan for the palette panel, title, preset buttons, and primary/accent picker labels. `_apply_editor_panel_visibility()` remains the scene-tree adapter and still synchronizes the live picker colors from current team state. The main extraction probe now rejects the old inline color label, selected-button, and picker-text formulas in `main.gd`.

Follow-up editor section chrome presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_section_chrome_presentation()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_section_chrome_presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_section_chrome_presentation()` now owns the pure section-label copy/visibility, hidden template-toggle copy/visibility, and default template drawer visibility plan. `_apply_editor_panel_visibility()` remains the scene-tree adapter and still calls `_layout_editor_template_drawer()` with the planned drawer visibility. The main extraction probe now rejects the old inline section-label and template-toggle formulas in `main.gd`.

Follow-up editor catalog/shop surface presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_catalog_shop_surface_presentation()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_catalog_shop_surface_presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_catalog_shop_surface_presentation()` now owns the pure catalog-card retained visibility, shop button visibility/disabled state, shop backdrop visibility, and catalog/unit hover-clearing triggers. `_apply_editor_panel_visibility()` remains the scene-tree adapter: it gathers current catalog-button visibility facts, applies the returned button/backdrop plans, keeps `_update_editor_load_card_buttons()` local, and performs hover-clearing side effects only when requested by the plan. The main extraction probe now rejects the old inline catalog/shop/backdrop/hover formulas in `main.gd`.

Follow-up editor panel/role chrome presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_panel_role_chrome_presentation()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_panel_role_chrome_presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_panel_role_chrome_presentation()` now owns the pure editor panel button text/selected-color plan and hidden role button visibility/disabled/layout/text/selected-color plan. `_apply_editor_panel_visibility()` remains the scene-tree adapter: it supplies `_role_short()` labels as plain data and applies the returned button plans. The main extraction probe now rejects the old inline panel/role chrome formulas in `main.gd`.

Follow-up editor part-library build specs extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_part_library_build_specs()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_part_library_build_specs delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_part_library_build_specs()` now owns the pure identity, position, and size data for editor part-group, build-slot, and part-filter buttons. `_build_editor_ui()` remains the scene-tree adapter: it creates concrete `Button` nodes, connects selection signals, and stores the node references from the returned specs. The main extraction probe now rejects the old inline group/slot/filter layout formulas in `main.gd`.

Remaining items after this batch:

- Continue editor UI extraction with `_build_editor_ui` and the remaining action presentation/control-mutation sections of `_apply_editor_panel_visibility`, then continue `_resolve_attack` and `_refresh_editor_visual_views` extraction.
