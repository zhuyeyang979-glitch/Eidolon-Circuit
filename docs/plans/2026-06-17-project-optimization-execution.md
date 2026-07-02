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

Follow-up editor ammo-size build specs extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_ammo_size_build_specs()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_ammo_size_build_specs delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: AMMO_SIZE_SLIDER_PROBE base=18 ranks=XS..XL ui=ok
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_ammo_size_build_specs()` now owns the pure identity, position, size, and slider-range data for the ammo-size title, slider, value label, and ticks. `_build_editor_ui()` remains the scene-tree adapter: it creates and styles concrete controls, connects the slider signal, and stores node references. `editor_ammo_size_control_presentation()` now reuses the same build specs so creation and refresh cannot drift apart. The main extraction probe rejects the old inline ammo-size creation formulas in `main.gd`.

Follow-up editor role/load build specs extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_role_load_build_specs()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_role_load_build_specs delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
KNOWN BASELINE FAILURE: PREBUILT_HERO_PRESETS_PROBE failed all three presets with socket_part_too_large in both the worktree and a fresh archive of baseline d54fe76
```

`UILifecycleService.editor_role_load_build_specs()` now owns pure identity, position, and size data for editor role buttons and saved-unit load cards. `_build_editor_ui()` remains the scene-tree adapter and retains all concrete node construction, signal wiring, and reference ownership. `editor_panel_role_chrome_presentation()` reuses the role build specs for horizontal placement and width while continuing to own mode-dependent vertical placement and height. The main extraction probe rejects the old inline role/load creation formulas in `main.gd`.

Follow-up editor info-surface build specs extraction:

```text
RED: lifecycle_services_contract_probe failed on missing UILifecycleService.editor_info_surface_build_specs()
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_info_surface_build_specs delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: TEAMEDIT_DASHBOARD_SLIDER_FULL_REFRESH_PROBE ok full=1 ui=0
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
```

`UILifecycleService.editor_info_surface_build_specs()` now owns pure identity, initial position/size, and visible-state position/size data for the editor unit, summary, stats, detail, battle-preview, component-art, and structure-reference surfaces. `_build_editor_ui()` remains responsible for concrete node construction, styling, texture behavior, mouse behavior, and stored references. `editor_info_panel_presentation()` reuses the build specs, and `_apply_editor_panel_visibility()` explicitly applies the returned fixed layouts along with visibility. The separate initial and visible layouts for unit/summary labels preserve existing behavior while removing duplicated formulas.

Follow-up editor Control plan adapter extraction:

```text
RED: editor_control_plan_adapter_probe failed because _apply_editor_control_plan() did not exist
RED: main_file_extraction_contract_probe failed because main.gd did not provide or adopt the shared adapter
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=10 noops=7
RED: editor_control_plan_adapter_probe failed because disabled-preservation argument did not exist
RED: main_file_extraction_contract_probe rejected the remaining direct action-button mutation block
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: TEAMEDIT_DASHBOARD_SLIDER_FULL_REFRESH_PROBE ok full=1 ui=0
GREEN: AMMO_SIZE_SLIDER_PROBE base=18 ranks=XS..XL ui=ok
GREEN: AMMO_SIZE_UI_PROBE entries=5 tier=M ok
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: EDITOR_CANVAS_PROBE roundtrip=0.00 nodes=2 edges=1 fixed=0.000
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: TEAMEDIT_DASHBOARD_SLIDER_FRAME_BUDGET_PROBE ok
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
KNOWN BASELINE FAILURE: editor_property_write_budget_probe and teamedit_property_write_budget_probe report repeat_write=54; fresh archives report 53 at 9e66eb2 and 54 at d381248
```

`main.gd` now owns a single `_apply_editor_control_plan()` scene-tree adapter over its existing guarded setters. It applies plan keys only when present, ignores presentation metadata, handles sliders through guarded editable/value setters, and optionally preserves externally managed button-disabled state. `_apply_editor_panel_visibility()` uses it across 26 plan-consumption sites without moving picker synchronization, hover clearing, conditional Unit/Summary geometry, or sort ordering side effects into the generic helper. The adapter has a dedicated core probe in `tools/probe_manifest.json`, and the extraction contract rejects representative returns to direct plan-property mutation.

Follow-up battle hit event-patch extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed on missing BattleHitResolutionService.apply_event_patch()
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: MOMENTUM_DAMAGE_GATE_RUNTIME_PROBE ok damage=11 momentum=60.0 break=0.50
GREEN: MELEE_DAMAGE_TYPE_RULE_PROBE ok
GREEN: PROJECTILE_PROFILE_WHITELIST_PROBE ok
GREEN: MISSILE_LOCK_INVALID_NO_AMMO_PROBE ok
GREEN: TERRAIN_OCCLUSION_RUNTIME_PROBE ok feature=terrain-wall-alpha kind=solid
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`BattleHitResolutionService.apply_event_patch()` now owns event-patch copying, replacement, and `erase_*` control handling for projectile preflight and target-hit contexts without mutating the source dictionaries. `BattleHitResolutionService.momentum_damage_gate_event_patch()` owns the pure event telemetry patch for raw/capped momentum, coefficients, break values, and gate result metadata. `_resolve_attack()` applies those patches through the service and keeps world-state mutation, hit iteration, shield interception, damage side effects, combo scaling, and nullification gating local. The extraction contract now requires the new delegation tokens and rejects the stale inline patch loops and direct momentum metadata assignments.

Follow-up post-hit side-effect dispatch extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed on missing func _execute_post_hit_intents(
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: MOMENTUM_DAMAGE_GATE_RUNTIME_PROBE ok damage=11 momentum=60.0 break=0.50
GREEN: MELEE_DAMAGE_TYPE_RULE_PROBE ok
GREEN: PROJECTILE_PROFILE_WHITELIST_PROBE ok
GREEN: MISSILE_LOCK_INVALID_NO_AMMO_PROBE ok
GREEN: TERRAIN_OCCLUSION_RUNTIME_PROBE ok feature=terrain-wall-alpha kind=solid
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_execute_post_hit_intents()` now owns the imperative dispatch for post-hit module effects, variant effects, takeover status, explosions, suicide returns, part damage, hitstop, health damage, validation hit sampling, chemical DOT, back-hit heat, projectile/active-melee stagger, and displacement. `_resolve_attack()` delegates the `post_hit_intents` array, merges effect-killed units, preserves the suicide early return, and keeps the target-loop `continue` and final kill-list handling explicit. The extraction contract rejects the old inline post-hit intent loop inside `_resolve_attack()` and requires the helper to retain the side-effect dispatch tokens.

Follow-up editor visual refresh barrier snapshot extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _editor_barrier_screen_board_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE ok
GREEN: BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
```

`_editor_barrier_screen_board_snapshot()` now owns the barrier screen-board snapshot construction for terrain preview, board dimensions, zoom/offset/grid-guide state, revision key, and per-tile visual payloads. `_refresh_editor_visual_views()` delegates only that branch, while cache hit/rebuild routing, custom-board dynamic-field application, `assembly_board_view.set_board()`, and side-panel refreshes remain in the orchestration function. The visual-refresh probe now resolves the exact `_refresh_editor_visual_views(` signature, requires the helper, and rejects the stale inline barrier snapshot fragments.

Follow-up editor visual refresh shallow topology snapshot extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _editor_shallow_topology_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0
GREEN: BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE ok
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
```

`_editor_shallow_topology_snapshot()` now owns the shallow node/edge copy path for custom topology boards, including the shallow snapshot counter and board distance-scale initialization. `_refresh_editor_visual_views()` delegates that setup and keeps the later visual stats fill, node enrichment, edge-state construction, cache writes, dynamic-field application, and board submission in place. The visual-refresh probe now requires the helper and rejects the old inline `source_nodes_raw`, `source_edges_raw`, `shallow_nodes`, and `shallow_edges` fragments from `_refresh_editor_visual_views()`.

Follow-up editor visual refresh topology edge-state extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _editor_topology_edge_state_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
NOTE: exploratory torso_edge_port_probe was not counted; it currently fails on missing AssemblyBoardView._saddle_world_polygon()
```

`_editor_topology_edge_state_snapshot()` now owns the custom topology endpoint-conflict query, socket-gap/material-error edge validation, edge-state payload construction, and illegal-node marking. `_refresh_editor_visual_views()` delegates that pass and keeps display-node generation, socket/material marker generation, cache writes, dynamic-field application, and board submission explicit. The visual-refresh probe now requires the helper and rejects the old inline endpoint/edge-state loop fragments from `_refresh_editor_visual_views()`.

Follow-up editor visual refresh custom-board cache extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _cache_editor_custom_board_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
```

`_cache_editor_custom_board_snapshot()` now owns the custom board revision key assignment, base/current snapshot cache writes, build-time telemetry, and rebuild counters. `_refresh_editor_visual_views()` delegates the cache mutation and keeps marker assignment, dynamic-field application, and final board submission local. The visual-refresh probe now requires the helper and rejects direct custom-board cache-write fragments from `_refresh_editor_visual_views()`.

Follow-up editor visual refresh board submission extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _submit_editor_visual_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0
GREEN: TEAMEDIT_ASSEMBLY_FRAME_BUDGET_PROBE ok p95=1.06ms max=1.06ms catalog_delta=0 hot=teamedit.visual_refresh
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
```

`_submit_editor_visual_snapshot()` now owns the final board revision lookup, `assembly_board_view.set_board()` call, orientation popup refresh, optional torso/engine side-panel refresh, and hot-path profiler record/close. `_refresh_editor_visual_views()` delegates final submission after custom dynamic fields are applied, and the visual-refresh probe rejects the old direct board submission/profiler fragments from the orchestration function.

Follow-up editor visual refresh topology node enrichment extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed on missing _editor_enriched_topology_nodes_snapshot helper
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0 delta=34.987px
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
GREEN: MODULE_BINDING_GROUP_HALO_VISUAL_PROBE ok groups=2
GREEN: SCYTHE_MOUNT_SIDE_BOARD_RUNTIME_PROBE ok node=2
GREEN: THREE_ROOT_LIMB_ATTACH_PROBE ok nodes=4 edges=3 ports=3
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
KNOWN BASELINE: editor_material_highlight_probe still reports different-material hover as legal_socket on current code and on clean cca7eda with copied Godot import cache
```

`_editor_enriched_topology_nodes_snapshot()` now owns the custom topology node enrichment pass, including component and legacy node length/radius/mass/material/handedness/projectile/momentum/module/torso-port/downstream-radius metadata. `_refresh_editor_visual_views()` delegates that pass and keeps only the surrounding custom-board orchestration. `_refresh_editor_visual_views()` is now 70 lines, and the visual-refresh probe rejects old inline node-enrichment fragments from the orchestration function.

Follow-up editor roster overview build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_roster_overview_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_roster_overview_build_specs static API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: git diff --check
KNOWN BASELINE: editor_roster_overview_probe still reports empty-slot click as changing blank canvas mode on current code and on clean f3708a5 with copied Godot import cache
```

`UILifecycleService.editor_roster_overview_build_specs()` now owns pure identity/layout/size specs for the roster overview labels, prev/next buttons, five slot buttons, and thumbnail overlays. `_build_editor_ui()` consumes those specs while keeping concrete node construction, signal wiring, hidden defaults, and stored references local. `_build_editor_ui()` is now 689 lines, and the extraction probe rejects old inline roster overview formulas.

Follow-up editor color controls build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_color_controls_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_color_controls_build_specs static API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_color_controls_build_specs()` now owns pure identity/layout/size specs for the color palette panel, title label, swatch buttons, and primary/accent pickers. `_build_editor_ui()` consumes those specs while keeping concrete node construction, preset text lookup, picker signal wiring, and stored references local. `_build_editor_ui()` is now 697 lines, and the extraction probe rejects old inline color control formulas.

Follow-up editor catalog-card build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_catalog_card_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_catalog_card_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_catalog_card_build_specs()` now owns pure identity/layout/size specs for the eight catalog-card buttons. `_build_editor_ui()` consumes those specs while keeping concrete `PartCatalogCardButton` construction, art-sheet initialization, signal wiring, and stored references local. `_build_editor_ui()` is now 700 lines, and the extraction probe rejects old inline catalog-card layout formulas.

Follow-up editor template-drawer build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_template_drawer_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_template_drawer_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: UNIT_EDITOR_ASSEMBLY_TEMPLATE_SERVICE_CONTRACT_PROBE ok
GREEN: ASSEMBLY_TEMPLATE_OVERLAY_RENDERER_CONTRACT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_template_drawer_build_specs()` now owns pure identity/layout/size specs for the template drawer panel/title, archetype template buttons, and barrier template buttons. `_build_editor_ui()` consumes those specs while keeping concrete button construction, template text lookup, signal wiring, and stored references local. `_build_editor_ui()` is now 709 lines, and the extraction probe rejects old inline template-drawer layout formulas.

Follow-up editor shop-surface build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_shop_surface_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_shop_surface_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: BARRIER_CATALOG_SCREEN_PLACE_PROBE ok pending=muscle/212 cell=22 drag=212 grid=false zoom=1.40
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_shop_surface_build_specs()` now owns pure identity/layout/size specs for the shop title, hint, pending label, optional card-art backdrop, and body-slot shop buttons. `_build_editor_ui()` consumes those specs while keeping generated texture loading, concrete control construction, signal wiring, and stored references local. `_build_editor_ui()` is now 716 lines, and the extraction probe rejects old inline shop-surface layout formulas.

Follow-up editor sort-menu build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_sort_menu_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_sort_menu_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_sort_menu_build_specs()` now owns pure identity/layout/size specs for the sort submenu panel, sort option buttons, catalog title, and catalog page label. `_build_editor_ui()` consumes those specs while keeping concrete control construction, sort signal wiring, visibility defaults, and stored references local. `_build_editor_ui()` is now 722 lines, and the extraction probe rejects old inline sort-menu layout formulas.

Follow-up editor body-part button build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_body_part_button_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_body_part_button_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=0 limb=1 weapon=2
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_body_part_button_build_specs()` now owns pure identity/layout/size specs for the six editor body-part buttons. `_build_editor_ui()` consumes those specs while keeping localized text, concrete button construction, signal wiring, and stored references local. `_build_editor_ui()` is now 718 lines, and the extraction probe rejects old inline body-position/button-size formulas.

Follow-up editor module-binding button build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_module_binding_button_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_module_binding_button_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: MODULE_BINDING_KEY_GRID_REAL_UI_PROBE ok rows=2 limbs=2
GREEN: MODULE_BINDING_SIDE_ACTION_TOP_LAYER_PROBE ok
GREEN: MODULE_BINDING_KEY_BUTTONS_REAL_CLICK_PROBE ok
GREEN: MODULE_BINDING_KEY_BUTTONS_TOP_LAYER_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_module_binding_button_build_specs()` now owns pure identity/action-key/layout/z-index specs for module binding key buttons and side-action buttons. `_build_editor_ui()` consumes the merged button specs while keeping side-label localization, concrete button construction, signal wiring, and action-button references local. `_build_editor_ui()` is now 710 lines, and the extraction probe rejects old inline module-binding key/side button formulas.

Follow-up editor sort-action button build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_sort_action_button_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_sort_action_button_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_sort_action_button_build_specs()` now owns pure identity/text/layout/click-intent specs for the three sort action buttons. `_build_editor_ui()` consumes those specs in one loop while keeping concrete button construction, signal wiring, and action-button references local. `_build_editor_ui()` is now 700 lines, and the extraction probe rejects the old inline `sort_prev` / `sort_key` / `sort_dir` construction and signal-wiring formulas.

Follow-up editor save-unit dialog build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_save_unit_dialog_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_save_unit_dialog_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: TEAMEDIT_SAVE_UNIT_REAL_UI_PROBE ok
GREEN: TEAMEDIT_SAVE_COMPLEX_UNIT_REAL_UI_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_save_unit_dialog_build_specs()` now owns pure identity/layout/action specs for the save-unit dialog panel, title, name edit, role label, role buttons, and save/cancel action buttons. `_build_editor_ui()` consumes those specs while keeping placeholder localization, role-name localization, concrete control construction, signal wiring, and save-unit references local. `_build_editor_ui()` is now 705 lines, and the extraction probe rejects old inline save-unit panel/title/role/action layout formulas.

Follow-up editor orientation popup build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_orientation_popup_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_orientation_popup_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: SCYTHE_MAGNETIC_LINK_ORIENTATION_POPUP_PROBE ok
GREEN: SCYTHE_MANUAL_LINK_ORIENTATION_POPUP_PROBE ok
GREEN: SCYTHE_CATALOG_DROP_LINK_ORIENTATION_POPUP_PROBE ok
GREEN: MODULE_BINDING_KEY_BUTTONS_TOP_LAYER_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_orientation_popup_build_specs()` now owns pure identity/layout/z-index specs for the side-mount orientation popup panel, label, and left/right/cancel buttons. `_build_editor_ui()` consumes those specs while keeping concrete control construction, localized runtime text refresh, signal wiring, and orientation-popup references local. `_build_editor_ui()` is now 704 lines, and the extraction probe rejects old inline side-mount popup panel/label/button layout formulas.

Follow-up editor dashboard controls build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_dashboard_controls_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_dashboard_controls_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_NO_POWER_TOPBAR_PROBE ok dock_pos=(190.0, 24.0)
GREEN: UNIT_EDITOR_POWER_BUDGET_NO_DUPLICATE_PROBE ok
GREEN: UNIT_EDITOR_TORSO_DETAIL_BUTTON_PROBE ok
GREEN: ENGINE_POWER_ALLOCATION_OPEN_PROBE ok
GREEN: POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_dashboard_controls_build_specs()` now owns pure identity/layout/z-index specs for the power allocation dock, board title/hint, legacy power budget button, torso detail button, and legacy power summary. `_build_editor_ui()` consumes those specs while keeping concrete control construction, visibility/disabled defaults, colors, signal wiring, and dashboard references local. `_build_editor_ui()` is now 711 lines, and the extraction probe rejects old inline dashboard/topbar layout formulas.

Follow-up editor canvas/zoom chrome build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_canvas_zoom_chrome_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_canvas_zoom_chrome_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_NO_HEADER_HELP_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_canvas_zoom_chrome_build_specs()` now owns pure identity/layout/default-text specs for the canvas tools title, canvas topology note, board zoom title, and board zoom value label. `_build_editor_ui()` consumes those specs while keeping label construction, colors, alignment, autowrap, visibility defaults, and zoom button wiring local. `_build_editor_ui()` is now 716 lines, and the extraction probe rejects old inline canvas/zoom chrome label formulas.

Follow-up editor auxiliary chrome build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_auxiliary_chrome_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_auxiliary_chrome_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok
GREEN: UNIT_EDITOR_CENTER_LAYOUT_DENSITY_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_TRAINING_ILLEGAL_FEEDBACK_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_NO_HEADER_HELP_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_auxiliary_chrome_build_specs()` now owns pure identity/layout/z-index specs for the assembly guide, legality status, assembly tutorial panel/label, performance overlay, and save feedback label. `_build_editor_ui()` consumes those specs while keeping colors, autowrap, visibility defaults, runtime tutorial/status text, signal wiring, and feedback relayout local. `_build_editor_ui()` is now 724 lines, and the extraction probe rejects old inline auxiliary chrome formulas.

Follow-up editor overlay view build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_overlay_view_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_overlay_view_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: VIEW_EXTRACTION_CONTRACT_PROBE ok views=27
GREEN: UNIT_EDITOR_TORSO_DETAIL_BUTTON_PROBE ok
GREEN: ENGINE_POWER_ALLOCATION_OPEN_PROBE ok
GREEN: POWER_ALLOCATION_CLICK_PART_HOVER_PROBE ok
GREEN: EDITOR_PART_DETAIL_GLOBAL_CLOSE_BUTTON_PROBE ok
GREEN: EDITOR_PART_DETAIL_CLICK_OUTSIDE_CLOSE_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_overlay_view_build_specs()` now owns pure identity/layout/z-index specs for the stats rail, part-hover popup, unit-hover preview, torso-detail panel, engine-allocation panel, and drag ghost. `_build_editor_ui()` consumes those specs while keeping concrete view construction, mouse filters, visibility defaults, signal wiring, board-rect mirroring, and runtime drag-ghost z-index refresh local. `_build_editor_ui()` is now 735 lines, and the extraction probe rejects old inline overlay view initialization formulas without blocking runtime drag-ghost z-index refresh.

Follow-up editor shell chrome build specs extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_shell_chrome_build_specs delegation
RED: lifecycle_services_contract_probe failed on missing editor_shell_chrome_build_specs service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: OPTIONS_MENU_UNIFICATION_PROBE ok
GREEN: UNIT_EDITOR_NO_HEADER_HELP_PROBE ok
GREEN: UNIT_EDITOR_RENAME_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_shell_chrome_build_specs()` now owns pure identity/default-text/token specs for the hidden editor title/help labels and the options/back button. `_build_editor_ui()` consumes those specs while keeping label creation, hidden defaults, focus mode, token application, and options-menu signal wiring local. `_build_editor_ui()` is now 743 lines, and the extraction probe rejects old inline shell chrome formulas while preserving the literal `editor_options_button` token path for `screen_layout_token_coverage_probe`.

Follow-up editor board-primary action identity specs extraction:

```text
RED: main_file_extraction_contract_probe failed on inline BoardPrimary%s node-name formula
RED: lifecycle_services_contract_probe failed on missing board-primary action identity specs
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: TEAMEDIT_SAVE_UNIT_BUTTON_PROBE ok
GREEN: SAVED_UNITS_RETURN_TARGET_PROBE ok
GREEN: TEAMEDIT_SAVE_UNIT_REAL_UI_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_action_build_specs()` now owns pure board-primary button identity specs for `save_canvas`, `training_import`, and `open_saved_units`. `_build_editor_ui()` consumes those names while keeping concrete button creation, text, geometry, focus mode, signal wiring, and action-button registration local. `_build_editor_ui()` is now 744 lines, and the extraction probe rejects the old inline `BoardPrimary%s` node-name formula.

Follow-up editor part-filter control-plan adapter extraction:

```text
RED: main_file_extraction_contract_probe failed on direct filter-button _set_*_if_changed mutations
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`_apply_editor_panel_visibility()` now consumes `UILifecycleService.editor_part_filter_button_presentation()` through `_apply_editor_control_plan()` instead of directly mutating filter button visibility, disabled state, geometry, text, and modulate values. `_apply_editor_panel_visibility()` is now 330 lines, and the extraction probe rejects the stale direct filter-button mutation calls.

Follow-up editor sort-control adapter extraction:

```text
RED: main_file_extraction_contract_probe failed on direct sort-control _set_*_if_changed mutations
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`_apply_editor_panel_visibility()` now applies `UILifecycleService.editor_sort_controls_presentation()` plans through `_apply_editor_control_plan()` for sort key text, sort direction text, the sort submenu panel, and sort option buttons. `_apply_editor_panel_visibility()` is now 316 lines, and the extraction probe rejects the stale direct sort-control mutation calls while keeping catalog-sort state persistence and sort-dir front-order refresh local.

Follow-up editor info-panel adapter extraction:

```text
RED: main_file_extraction_contract_probe failed on direct info-panel _set_*_if_changed mutations
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: UNIT_EDITOR_TORSO_DETAIL_BUTTON_PROBE ok torso=0 second=1
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`_apply_editor_panel_visibility()` now applies `UILifecycleService.editor_info_panel_presentation()` plans through `_apply_editor_control_plan()` for the unit label, summary label, catalog page label, and catalog title visibility. `_apply_editor_panel_visibility()` is now 309 lines, and the extraction probe rejects the stale direct info-panel mutation calls while keeping save-feedback relayout and the existing stats/detail/art/reference consumers local.

Follow-up editor sort-dir front-order adapter extraction:

```text
RED: main_file_extraction_contract_probe failed on direct sort_dir_front.move_to_front()
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=6 gun_options=10
GREEN: WEAPON_SUBCATEGORY_FILTER_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`_apply_editor_panel_visibility()` now applies the `sort_dir_move_to_front` decision from `UILifecycleService.editor_sort_controls_presentation()` through `_apply_editor_control_plan()` instead of directly calling `sort_dir_front.move_to_front()`. `_apply_editor_panel_visibility()` remains 309 lines, and the extraction probe rejects the stale direct front-order mutation.

Follow-up editor slot-button hidden presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_slot_button_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_slot_button_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok
GREEN: EDITOR_SCROLL_REGIONS_PROBE ok
GREEN: EDITOR_CATALOG_REVISION_CACHE_PROBE ok skips=1
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_slot_button_presentation()` now owns the pure hidden/disabled plan for legacy editor slot buttons. `_apply_editor_panel_visibility()` applies that plan through `_apply_editor_control_plan()` instead of carrying local `slot_visible` state and direct visible/disabled mutations; the function is now 307 lines.

Follow-up editor color-picker sync plan extraction:

```text
RED: main_file_extraction_contract_probe emitted the expected stale direct picker color assignment error
RED: lifecycle_services_contract_probe emitted the expected missing picker_colors error
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: SCREEN_LAYOUT_TOKEN_COVERAGE_PROBE ok
GREEN: BATTLE_ACTOR_COMMAND_SERVICE_CONTRACT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
NOT COUNTED: teamedit_property_write_budget_probe remains red at repeat_write=56 in the existing parts-panel scenario
```

`UILifecycleService.editor_color_controls_presentation()` now returns `picker_colors` alongside the visible/text/button plan. `_apply_editor_panel_visibility()` passes the current team colors into the service and consumes the returned picker sync values under the existing `editor_color_picker_sync` guard instead of directly assigning `_team_primary_color()` / `_team_accent_color()` to the picker controls.

Follow-up editor assembly-guide presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_assembly_guide_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_assembly_guide_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok
GREEN: UNIT_EDITOR_ASSEMBLY_GUIDE_SERVICE_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_assembly_guide_presentation()` now owns the pure label/tutorial/action-button plans for the editor assembly guide, including the connection-evaluation gate for the next button. `_refresh_editor_assembly_guide_ui()` still obtains the current guide model from `UnitEditorAssemblyGuideService`, then applies the returned plans through `_apply_editor_control_plan()` instead of carrying local position/text/tooltip/modulate mutations.

Follow-up editor board-zoom presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_board_zoom_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_board_zoom_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0 delta=34.987px
GREEN: BOARD_ZOOM_NO_POWER_ALLOCATION_POPUP_PROBE ok zoom=1.254
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_board_zoom_presentation()` now owns the pure zoom label and zoom action button text/disabled plans. `_refresh_editor_board_zoom_ui()` consumes that plan through `_apply_editor_control_plan()` instead of directly mutating the zoom label and buttons.

Follow-up editor orientation-popup presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_orientation_popup_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_orientation_popup_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: SCYTHE_MAGNETIC_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1
GREEN: SCYTHE_CATALOG_DROP_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1 gap=0.000000 side=left
GREEN: SCYTHE_MANUAL_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1
GREEN: SCYTHE_DRAG_PRESERVES_ORIENTATION_CHOICE_PROBE ok node=0 side=right
GREEN: ASYMMETRIC_WEAPON_ORIENTATION_CHOICE_PROBE ok scythe=SCYTHE BLADE
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_orientation_popup_presentation()` now owns the pure hidden/invalid/visible side-mount orientation popup plan, including popup clamp bounds, localized label/button text, enabled button state, panel size, and move-to-front intent. `_refresh_editor_orientation_popup()` keeps active-choice detection, node lookup, and socket anchor calculation local, then applies the returned panel/label/button plans through `_apply_editor_control_plan()`.

Follow-up editor template-drawer presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_template_drawer_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_template_drawer_presentation service API
RED: lifecycle_services_contract_probe failed on template drawer open visibility being overwritten by section chrome
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: UNIT_EDITOR_ASSEMBLY_TEMPLATE_SERVICE_CONTRACT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_template_drawer_presentation()` now owns the pure runtime drawer panel, title, archetype/barrier template button, selected archetype color, and hidden toggle-button plans. `_layout_editor_template_drawer()` consumes that plan through `_apply_editor_control_plan()` and receives the current blueprint from both editor refresh call sites, so `_apply_editor_panel_visibility()` no longer overwrites the selected archetype highlight or hides an opened template drawer. A new `unit_editor_template_drawer_runtime_probe` locks the opened hero/barrier drawer behavior into the probe manifest.

Follow-up editor body-board button presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_body_board_button_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_body_board_button_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_body_board_button_presentation()` now owns the pure visible/disabled/text plan for legacy body-board part buttons, including selected and illegal markers. `_update_editor_board_ui()` keeps local blueprint labels and illegal-part lookup, then applies each body-part plan through `_apply_editor_control_plan()` instead of mutating the buttons directly.

Follow-up editor body shop-slot button presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_body_shop_slot_button_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_body_shop_slot_button_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_body_shop_slot_button_presentation()` now owns the pure disabled/text/modulate plan for legacy body-board shop-slot buttons, including inactive mech-only copy, pending placement highlight, selected-node highlight, and default tint. `_update_editor_board_ui()` keeps local slot, component, volume, pending, and selected-marker text construction, then applies the returned plan through `_apply_editor_control_plan()`.

Follow-up editor edit-side button presentation extraction:

```text
RED: main_file_extraction_contract_probe failed on missing UILifecycleService.editor_edit_side_button_presentation delegation
RED: lifecycle_services_contract_probe failed on missing editor_edit_side_button_presentation service API
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=11 noops=7
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_edit_side_button_presentation()` now owns the pure text/modulate plan for the editor side-switch action, including localized `P%d` copy and player-specific tint. `_update_editor_ui()` keeps the action-button lookup, then applies the returned plan through `_apply_editor_control_plan()` instead of mutating the button directly.

Follow-up editor module-binding tryout button presentation extraction:

```text
RED: editor_control_plan_adapter_probe failed because _apply_editor_control_plan() did not apply mouse_filter/z_index
RED: lifecycle_services_contract_probe failed on missing editor_module_binding_tryout_button_presentation service API
RED: main_file_extraction_contract_probe failed on missing module-binding tryout presentation delegation
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=13 noops=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`_apply_editor_control_plan()` now applies `mouse_filter` and `z_index` plan keys with guarded write/no-op accounting. `UILifecycleService.editor_module_binding_tryout_button_presentation()` owns the pure runtime layout, visibility, disabled state, localized try/bind copy, tooltip, color, z-index, mouse-filter, and front-order plan for module-binding attack-key tryout buttons. `UILifecycleService.editor_module_binding_side_idle_presentation()` owns the hidden/disabled idle state for side-binding buttons when the overlay is not active. `_refresh_editor_module_binding_buttons()` now keeps only binding-state discovery and applies those returned plans.

Follow-up editor module-binding overlay button presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_module_binding_overlay_side_presentation service API
RED: main_file_extraction_contract_probe failed on missing module-binding overlay presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=13 noops=9
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_module_binding_overlay_side_presentation()` and `UILifecycleService.editor_module_binding_overlay_key_presentation()` now own the pure visible/disabled/layout/text/tooltip/color/mouse-filter/z-index/front-order plans for active module-binding overlay buttons, plus hidden plans when side choice or attack-key choice is unavailable. `_layout_module_binding_key_overlay()` keeps overlay-state checks, parent-space rect conversion, current selection lookups, and the existing hover/engine-panel side effects, then applies the returned plans through `_apply_editor_control_plan()`.

Follow-up editor roster overview presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_roster_overview_presentation service API
RED: main_file_extraction_contract_probe failed on missing roster overview presentation delegation
RED: editor_roster_overview_probe failed because clicking an empty overview slot left blank work-canvas mode
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=13 noops=9
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_BOARD_CONTROLLER_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_roster_overview_presentation()` now owns the pure title/page/nav/slot-button/thumb-visibility plan for the editor roster overview, including localized role titles, page text, nav disabled state, hidden-slot clearing, empty-slot copy, blank canvas suffixes, selected tint, and thumb status. `_update_editor_roster_overview()` keeps roster entry lookup, stats computation, and `SortieThumbView.set_entry()` payload construction, then applies the returned plans through `_apply_editor_control_plan()`. `_select_editor_roster_overview_slot()` now preserves blank work-canvas mode when clicking an empty overview slot and shows the pinned empty-slot preview instead of creating a roster page.

Follow-up editor load card button presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_load_card_buttons_presentation service API
RED: main_file_extraction_contract_probe failed on missing load-card presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=13 noops=9
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
```

`UILifecycleService.editor_load_card_buttons_presentation()` now owns the pure prev/next, page-label, card visibility, disabled, layout, text passthrough, and tint plan for editor load-card buttons. `_update_editor_load_card_buttons()` keeps load-entry lookup, page clamping, stats calculation, role/cost/name copy, and final localized card text construction, then applies returned plans through `_apply_editor_control_plan()`. The extraction preserves the load panel's existing page label placement, empty/team top-row placement, preset/library/selected tinting, and hidden-card clearing.

Follow-up editor save-unit feedback presentation extraction:

```text
RED: editor_control_plan_adapter_probe failed because _apply_editor_control_plan() did not apply Label text layout properties
RED: lifecycle_services_contract_probe failed on missing editor_save_unit_feedback_presentation service API
RED: main_file_extraction_contract_probe failed on missing save-unit feedback presentation delegation
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: TEAMEDIT_UI_SIMPLIFIED_CONTROLS_PROBE ok summary_lines=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
```

`_apply_editor_control_plan()` now applies Label text-layout keys (`autowrap_mode`, `clip_text`, and `text_overrun_behavior`) with guarded write/no-op accounting. `UILifecycleService.editor_save_unit_feedback_presentation()` owns the pure position, size, wrapping, clipping, and overrun plan for the editor save-unit feedback label. `_layout_editor_save_unit_feedback()` now applies that service plan instead of directly mutating the label.

Follow-up editor unit-hover view presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_unit_hover_view_presentation service API
RED: main_file_extraction_contract_probe failed on missing unit-hover view presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
```

`UILifecycleService.editor_unit_hover_view_presentation()` now owns the pure visible/hidden, position, size, z-index, and front-order plan for the editor unit hover preview view, using the existing unit-hover overlay build spec as its source of truth. `_show_editor_library_unit_hover()`, `_show_editor_empty_slot_hover()`, `_show_editor_unit_hover()`, and `_clear_editor_unit_hover_card()` now apply that plan through `_apply_editor_control_plan()` while keeping detail-token, close-button, and preview-content updates in `main.gd`.

Follow-up editor part-hover popup presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_part_hover_popup_presentation service API
RED: main_file_extraction_contract_probe failed on missing part-hover popup presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_part_hover_popup_presentation()` now owns the pure visible/hidden, default/pinned/module size, z-index, optional position override, and front-order plan for the editor part hover popup. `_show_editor_part_hover()`, `_hover_torso_detail_payload()`, `_clear_editor_hover_card()`, and the dirty-hover flush path now apply service-backed or adapter-backed presentation plans while keeping dynamic pinned/torso positioning, hover content assembly, drag-ghost ordering, and stat-rail refresh in `main.gd`.

Follow-up editor drag-ghost view presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_drag_ghost_view_presentation service API
RED: main_file_extraction_contract_probe failed on missing drag-ghost view presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: EDITOR_DRAG_PREVIEW_PROBE ghost_size=(88.0, 62.0) nodes=1 alpha=0.55
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_drag_ghost_view_presentation()` now owns the pure visible/hidden, mouse-filter, tint alpha, z-index, optional position, and front-order plan for the editor drag ghost view. `_show_editor_drag_ghost()`, `_update_editor_drag_ghost_position()`, `_hide_editor_drag_ghost()`, drag-ghost initialization in `_build_editor_ui()`, and the hover-front ordering path now apply that plan while keeping card content setup, mouse-centered position calculation, and redraw scheduling in `main.gd`.

Follow-up editor stats-rail view presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_stats_rail_view_presentation service API
RED: main_file_extraction_contract_probe failed on missing stats-rail view presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: EDITOR_STATS_REVISION_CACHE_PROBE ok compute=1 hit=1 miss=1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_stats_rail_view_presentation()` now owns the pure visible/hidden, position, size, and mouse-filter plan for the editor stats rail view. Stats rail construction in `_build_editor_ui()` and refresh visibility in `_refresh_editor_stats_rail()` now apply that plan while keeping stat entry assembly, header selection, legality-note generation, `set_stats()`, and engine-allocation summary refresh in `main.gd`.

Follow-up editor perf-overlay presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_perf_overlay_presentation service API
RED: main_file_extraction_contract_probe failed on missing perf-overlay presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: TEAMEDIT_LIVE_PERF_OVERLAY_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_perf_overlay_presentation()` now owns the pure visible/hidden, text, position, size, z-index, and word-wrap plan for the TeamEdit performance overlay. `_set_editor_perf_overlay_enabled()`, `_update_editor_perf_overlay()`, and perf-overlay construction in `_build_editor_ui()` now apply that plan while keeping diagnostics text generation and sampling state in `main.gd`.

Follow-up editor save-unit name panel presentation extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_save_unit_name_panel_presentation service API
RED: main_file_extraction_contract_probe failed on missing save-unit name panel presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: TEAMEDIT_SAVE_UNIT_BUTTON_PROBE ok path=user://saved_units/probe_saved_units_jump.json
GREEN: TEAMEDIT_SAVE_UNIT_REAL_UI_PROBE ok path=user://saved_units/Real_UI_Save_Probe_6032_1782914163.json
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_LOAD_HOVER_PROBE hover_keeps_unit=0 preview=true page=1/1 entries=4
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: jq empty tools/probe_manifest.json
GREEN: git diff --check
```

`UILifecycleService.editor_save_unit_name_panel_presentation()` now owns the pure visible/hidden, position, size, z-index, and front-order plan for the save-unit name dialog panel. `_show_save_unit_name_dialog()`, `_hide_save_unit_name_dialog()`, and save-unit panel construction in `_build_editor_ui()` now apply that plan while keeping localized title/input/button text, focus selection, role-button state, and save/confirm behavior in `main.gd`.

Follow-up editor action presentation batch extraction:

```text
RED: lifecycle_services_contract_probe failed on missing editor_action_presentations service API
RED: main_file_extraction_contract_probe failed on missing batch action-presentation delegation
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=false writes=16 noops=12
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
```

`UILifecycleService.editor_action_presentations()` now owns the full action-key iteration, per-action state derivation, presentation-plan construction, and visible unit-action index advancement. `_apply_editor_panel_visibility()` supplies pure state and localization context, then only looks up and applies each returned plan. The batch contract preserves unmanaged assembly-guide actions, normalized unit-management visibility, barrier-hidden canvas actions, and deterministic two-column unit-action ordering.

Follow-up attack-entry side-effect dispatch extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still dispatched both entry intents inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: BATTLE_ACTION_EVENT_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok
GREEN: PROJECTILE_RUNTIME_SERVICE_CONTRACT_PROBE ok
GREEN: GUN_ACTIVATION_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_START_PAYLOAD_PROBE ok
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_FULL_MATCH_REPLAY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_execute_attack_entry_intent()` now owns the imperative dispatch for invalid-entry return, runtime-topology execution marking, missing-gun-source feedback, and runtime-melee projectile-field clearing. `_resolve_attack()` delegates both the pre-normalization and post-normalization intents through that helper while preserving the original gate order. The extraction probe now resolves the exact `func _resolve_attack(` signature instead of accidentally matching `_resolve_attack_command_window()`, requires both helper calls, and rejects renewed inline entry dispatch.

Follow-up projectile-preflight side-effect dispatch extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still dispatched projectile preflight actions inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok
GREEN: PROJECTILE_RUNTIME_SERVICE_CONTRACT_PROBE ok
GREEN: LASER_BEAM_RUNTIME_FIRE_PROBE ok ammo=7->6 target_hp=100.0
GREEN: MISSILE_LOCK_RUNTIME_FIRE_PROBE ok
GREEN: CHEMICAL_SPRAYER_FIRST_CONTACT_PROBE ok blocker=140->129 rear=140->140
GREEN: HARDWARE_FAULT_TRUE_BULLET_QUEUE_DEPENDENCY_PROBE ok
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_execute_projectile_preflight_intent()` now owns the imperative dispatch for queued laser telegraphs, true-bullet locks, chemical projectiles, chemical fireworks, and missiles. `_resolve_attack()` applies the pure service event patch, delegates exactly one preflight action, and keeps the ready/expanded chemical projectile continuation path explicit for normal target resolution. The extraction contract requires all five side-effect routes and rejects renewed inline preflight matching.

Follow-up attack missile-lock preparation extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still acquired and wrote missile locks inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MISSILE_LOCK_RUNTIME_FIRE_PROBE ok
GREEN: MISSILE_LOCK_INVALID_NO_AMMO_PROBE ok
GREEN: MISSILE_OCCLUSION_BREAK_LOCK_PROBE ok
GREEN: MISSILE_LOCK_PRIORITY_NEAR_PROBE ok
GREEN: MISSILE_LOCK_PRIORITY_FAR_PROBE ok
GREEN: MISSILE_LOCK_PRIORITY_SCREEN_ROLE_PROBE ok
GREEN: MISSILE_LOCK_BARRIER_SUPPORT_PROBE ok
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_prepare_attack_missile_lock()` now owns existing-lock reuse, occlusion-triggered target reacquisition, no-lock feedback, and `locked_target` / `aim_locked` event mutation. `_resolve_attack()` consumes the helper as one continue/stop gate before projectile activation setup. The extraction contract rejects direct missile target acquisition and lock-field writes in `_resolve_attack()` while requiring the helper's non-missile, no-target, and successful-lock paths.

Follow-up attack activation preparation extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still applied projectile signal, ammo, and blind-direction activation inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: GUN_ACTIVATION_SERVICE_CONTRACT_PROBE ok
GREEN: LASER_AMMO_HEAT_PROBE ok ammo=7->6 heat=0.0->1.0
GREEN: MISSILE_AMMO_HEAT_PROBE ok ammo=2 heat=34.0
GREEN: CHEMICAL_HEAT_PROBE queued=true impact=true dot=true boost_motion=true straight_cooling=true hp=120->105->64 heat=44.00
GREEN: RUNTIME_MELEE_NEVER_PROJECTILE_GATE_PROBE message=''
GREEN: MELEE_PROJECTILE_GATE_PROBE ok
GREEN: GUN_ACTIVATION_MOVE_WHILE_FIRE_ALL_PROFILES_PROBE ok count=7
GREEN: TRAINING_VALIDATION_RUNTIME_SAMPLE_PROBE ok
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_prepare_attack_activation()` now owns compatibility projectile-field clearing, direct-runtime early completion, projectile aim pose, signal metadata, ammo consumption, shot validation sampling, attack-executed marking, and unlocked blind-direction perturbation. `_resolve_attack()` consumes one continue/stop gate after missile-lock preparation and before pure projectile preflight planning. The extraction contract rejects direct ammo/signal/blind activation in `_resolve_attack()` and requires the helper's original side-effect ordering and return paths.

Follow-up attack projectile-impact preparation extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still routed compatibility projectiles and prepared first-impact metadata inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok
GREEN: PROJECTILE_RUNTIME_SERVICE_CONTRACT_PROBE ok
GREEN: gpu_projectile_first_obstruction_probe ok first=1.100 second=2.100
GREEN: MAP_OCCLUSION_PROJECTILE_INTEGRATION_PROBE ok
GREEN: PROJECTILE_TRACE_AIM_LINE_SAME_ORIGIN_PROBE ok origin=(764.0616, 317.7231)
GREEN: PROJECTILE_TRACE_NO_REWRAP_LANE_FLIP_PROBE ok
GREEN: CHEMICAL_SPRAYER_FIRST_CONTACT_PROBE ok blocker=140->129 rear=140->140
GREEN: MISSILE_LOCK_RUNTIME_FIRE_PROBE ok
GREEN: LASER_BEAM_RUNTIME_FIRE_PROBE ok ammo=7->6 target_hp=100.0
GREEN: HARDWARE_FAULT_TRUE_BULLET_QUEUE_DEPENDENCY_PROBE ok
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_prepare_attack_projectile_impact()` now owns the compatibility true-bullet, chemical-projectile, chemical-firework, and missile routing gates, followed by projectile recoil/reflection, first-obstruction impact metadata, and trace spawning for attacks that continue synchronously. `_resolve_attack()` consumes only the returned stop flag and first-impact dictionary before entering target resolution. The extraction contract rejects renewed inline projectile-impact preparation while requiring the original compatibility-route and first-contact ordering.

Follow-up attack target-contact preparation extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still filtered true-bullet targets and resolved target contact inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: BATTLE_IMPACT_QUERY_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_TARGET_ACQUISITION_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok
GREEN: MAP_OCCLUSION_PROJECTILE_INTEGRATION_PROBE ok
GREEN: TERRAIN_OCCLUSION_RUNTIME_PROBE ok feature=terrain-wall-alpha kind=solid
GREEN: MAP_OCCLUSION_KIND_PROBE ok
GREEN: SHIELD_PROBE absorb_ok hp=100 shield=20.0 bar_width=165.0
GREEN: ATTACK_RULE_EXPLANATION_PROBE failed=false
GREEN: HARDWARE_FAULT_TRUE_BULLET_QUEUE_DEPENDENCY_PROBE ok
GREEN: MOBIUS_LOCAL_EUCLIDEAN_COMBAT_PATCH_PROBE ok shifted=(24.18, 1.0) distance=0.305
GREEN: gpu_projectile_first_obstruction_probe ok first=1.100 second=2.100
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_prepare_attack_target_contact()` now owns live-target and first-impact filtering, true-bullet lock/obstruction filtering, direct-runtime or CPU part-hit selection, one-time map-occlusion recording, target-hit event patching, one-way shield interception, and projectile shield reflection. `_resolve_attack()` applies the returned event, skips rejected contacts, and carries only the resolved damage/material classifications into the existing damage stack. The extraction contract rejects renewed inline target-contact routing and requires every preserved contact gate.

Follow-up attack damage-stack preparation extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still prepared counter, raw damage, momentum gate, combo, and damage-stack inputs inline
RED: no_old_threshold_gate_probe required the obsolete one-line stiffness-cap implementation
RED: part_damage_coeff_probe reported stale limb/melee coefficients but reset its failure exit code with a final quit()
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MOMENTUM_DAMAGE_GATE_RUNTIME_PROBE ok damage=11 momentum=60.0 break=0.50
GREEN: PROJECTILE_DAMAGE_FORMULA_PROBE ok raw=80.0 allocated=300.0 sniper=10.0
GREEN: MODULE_DAMAGE_FROM_RUNTIME_CONTEXT_PROBE ok
GREEN: PART_DAMAGE_COEFF_PROBE ok
GREEN: RUNTIME_CONTACT_SERVICE_CONTRACT_PROBE ok
GREEN: MELEE_DAMAGE_TYPE_RULE_PROBE ok
GREEN: RUNTIME_CONTACT_DAMAGE_PROBE hp_delta=332 target_v=9.600
GREEN: RUNTIME_NO_PRECONTACT_DAMAGE_PROBE gap=2.0844 hp=150
GREEN: CONTACT_NORMAL_MOMENTUM_PROBE tangent=0 normal=138
GREEN: CHEMICAL_DOT_PROBE ok dps=6.00 hp=160->153
GREEN: CHEMICAL_HEAT_PROBE queued=true impact=true dot=true boost_motion=true straight_cooling=true hp=120->105->64 heat=44.00
GREEN: CHEMICAL_SPRAYER_FIRST_CONTACT_PROBE ok blocker=140->129 rear=140->140
GREEN: GUN_DAMAGE_MULTIPLIER_FROM_ALLOCATION_PROBE ok current=6.00 max=15.00
GREEN: NO_OLD_THRESHOLD_GATE_PROBE ok
GREEN: BARRIER_TERRAIN_DESTRUCTION_INVALIDATION_PROBE ok remaining=1 placements=1 deployments=1
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_prepare_attack_damage_stack()` now owns counter lookup, outgoing multipliers, melee/projectile raw damage, low-momentum rejection, momentum-driven barrier detachment, material adjustment, momentum-gate event patching, combo scaling, and final damage-stack intent resolution. `_resolve_attack()` reapplies the returned event and carries only the resolved VFX/post-hit fields. The extraction contract rejects renewed inline damage-stack preparation and requires every early-exit path and output field.

The stale threshold probe now verifies the current two-stage path-stiffness and optional hardware cap instead of an obsolete equivalent expression. The part-coefficient probe now follows the runtime service's authoritative limb/melee values (`1.8` / `3.2`) and latches any assertion failure so a trailing success quit cannot produce a false-green result.

Follow-up attack target-outcome dispatch extraction:

```text
RED: battle_hit_resolution_service_contract_probe failed because _resolve_attack still spawned hit VFX and dispatched blocked/post-hit outcomes inline
GREEN: BATTLE_HIT_RESOLUTION_SERVICE_CONTRACT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: SNIPER_HIT_VFX_ON_TARGET_PROBE ok effects=2
GREEN: BATTLE_VFX_BUDGET_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_VFX_BUDGET_PROBE ok accepted=40 dropped=160
GREEN: ATTACK_RULE_EXPLANATION_PROBE failed=false
GREEN: MOMENTUM_DAMAGE_GATE_RUNTIME_PROBE ok damage=11 momentum=60.0 break=0.50
GREEN: PART_DAMAGE_COEFF_PROBE ok
GREEN: CHEMICAL_DOT_PROBE ok dps=6.00 hp=160->153
GREEN: CHEMICAL_HEAT_PROBE queued=true impact=true dot=true boost_motion=true straight_cooling=true hp=120->105->64 heat=44.00
GREEN: PROJECTILE_RUNTIME_SERVICE_CONTRACT_PROBE ok
GREEN: BATTLE_PROJECTILE_LIFECYCLE_SERVICE_CONTRACT_PROBE ok
GREEN: RUNTIME_CONTACT_DAMAGE_PROBE hp_delta=332 target_v=9.600
GREEN: LOCAL_BATTLE_REPLAY_CONSISTENCY_PROBE ok
GREEN: BATTLE_FULL_MATCH_REPLAY_PROBE ok
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE checkpoints=6 desync_step=360
GREEN: BATTLE_ATTACK_HEAVY_REPLAY_DESYNC_PROBE ok
```

`_resolve_attack_target_outcome()` now owns damage-stack field consumption, projectile/melee hit VFX, contact-gate blocked feedback and stagger/displacement/hitstop, successful-hit rule recording, post-hit intent planning, and post-hit side-effect execution. `_resolve_attack()` now retains only attack-level gates plus per-target contact, damage-stack, outcome-control, and killed-unit aggregation. The extraction contract rejects renewed inline outcome dispatch and requires all four killed/continue/return result fields.

Follow-up editor custom-board snapshot assembly extraction:

```text
RED: editor_visual_refresh_no_deep_snapshot_probe failed because _refresh_editor_visual_views still assembled custom topology snapshots inline
RED: editor_material_highlight_probe failed with stale legal_socket after changing hover material because the probe did not latch failure exits and the cached dynamic revision omitted preview state
GREEN: EDITOR_VISUAL_REFRESH_NO_DEEP_SNAPSHOT_PROBE ok
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: EDITOR_RENDER_CACHE_PROBE ok apply=1 noop=0 skip=2 submit=2
GREEN: ASSEMBLY_BOARD_SET_BOARD_NOOP_PROBE ok apply=1 noop=0 skip=2
GREEN: POSE_DRAG_NO_FULL_REFRESH_PROBE ok visual_delta=0 catalog_delta=0
GREEN: TEAMEDIT_POSE_EDIT_FRAME_BUDGET_PROBE ok root_redraw=0 component_updates=0
GREEN: TEAMEDIT_ASSEMBLY_FRAME_BUDGET_PROBE ok p95=0.61ms max=0.61ms catalog_delta=0 hot=teamedit.visual_refresh
GREEN: TEAMEDIT_HOVER_FRAME_BUDGET_PROBE ok refreshes=2 rebuilds=1
GREEN: MODULE_BINDING_GROUP_HALO_VISUAL_PROBE ok groups=2
GREEN: EDITOR_MATERIAL_HIGHLIGHT_PROBE same=metal diff=chain same_state=legal_socket diff_state=illegal_material
GREEN: BOARD_ZOOM_SOCKET_FOLLOW_PROBE ok marker=0:torso_port:0 delta=34.987px
GREEN: BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE ok
GREEN: ASSEMBLY_TEMPLATE_PROBE skipped headless
```

`_editor_custom_board_snapshot()` now owns the custom topology snapshot assembly pipeline: shallow snapshot creation, optional stats computation, visual stats fields, topology node enrichment, art-position display-node mapping, edge-state validation, socket/material marker generation, and cache writes. `_refresh_editor_visual_views()` now chooses cache/custom/barrier branches and keeps dynamic overlay plus final submission orchestration.

The dynamic board overlay now recomputes `material_highlights` on cached custom snapshots and both visual-refresh and board-dynamic revision keys include hover/drag preview state. `editor_material_highlight_probe` now latches assertion failures so stale hover material states cannot produce a false-green result.

Follow-up editor orientation action button presentation extraction:

```text
RED: lifecycle_services_contract_probe failed because UILifecycleService did not expose editor_orientation_action_buttons_presentation
RED: main_file_extraction_contract_probe failed because _refresh_editor_orientation_buttons still mutated action buttons inline
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: ASYMMETRIC_WEAPON_ORIENTATION_CHOICE_PROBE ok scythe=SCYTHE BLADE
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: SCYTHE_CATALOG_DROP_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1 gap=0.000000 side=left
GREEN: SCYTHE_MANUAL_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1
GREEN: SCYTHE_MAGNETIC_LINK_ORIENTATION_POPUP_PROBE ok scythe=2 parent=1
GREEN: SCYTHE_HANDEDNESS_BOARD_RUNTIME_PROBE ok node=1
GREEN: SCYTHE_MODULE_BINDING_HANDEDNESS_PROBE ok
GREEN: SCYTHE_MODULE_BINDING_MOUNT_SIDE_PROBE ok
GREEN: SCYTHE_MOUNT_SIDE_BOARD_RUNTIME_PROBE ok node=2
GREEN: SCYTHE_SIDE_CHOICE_DOES_NOT_MOVE_SOCKET_PROBE ok scythe=2
GREEN: SCYTHE_DRAG_PRESERVES_ORIENTATION_CHOICE_PROBE ok node=0 side=right
GREEN: SCYTHE_LINK_VISUAL_PARENT_AXIS_PROBE ok scythe=2
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_NO_TEAM_ROLE_CONTROLS_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
```

`UILifecycleService.editor_orientation_action_buttons_presentation()` now owns the pure visible/disabled/text/position/size/modulate/front-order plan for left/right/flip side-mounted blade orientation actions. `_refresh_editor_orientation_buttons()` still owns active-state detection and applies those plans through `_apply_editor_control_plan()` before refreshing the popup.

The same verification pass exposed a stale side-mount alias conflict: legacy `visual_handedness`-only paths could be masked by a default `visual_mount_side`. `_topology_node_visual_handedness()` now resolves conflicting aliases by preserving the explicit non-default side, so old `visual_handedness` data and new `visual_mount_side` data both survive board enrichment, runtime segments, and renderer conversion.

Follow-up editor board hint presentation extraction:

```text
RED: lifecycle_services_contract_probe failed because UILifecycleService did not expose editor_board_hint_presentation
RED: main_file_extraction_contract_probe failed because _update_editor_board_ui still set board hint text inline
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE ok
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
```

`UILifecycleService.editor_board_hint_presentation()` now owns the pure board hint text plan for custom topology boards, ether-screen barrier boards, enabled free-canvas boards, and inactive body-board states. `_update_editor_board_ui()` keeps the underlying state sampling local, including topology/action/material validity, pending placement/install labels, selected node summary, side-mount choice state, tile counts, and board dimensions, then applies the returned label plan through `_apply_editor_control_plan()`.

Follow-up editor body shop-slot text extraction:

```text
RED: lifecycle_services_contract_probe failed because UILifecycleService did not expose editor_body_shop_slot_text_presentation
RED: main_file_extraction_contract_probe failed because _update_editor_board_ui still assembled shop-slot text inline
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
```

`UILifecycleService.editor_body_shop_slot_text_presentation()` now owns the pure inactive/active shop-slot button text assembly, including localized buy/install titles, part cost lines, length/interface or software volume notes, pending placement markers, selected-node prefixes, and per-slot rule copy. `_update_editor_board_ui()` still owns catalog selection, selected topology-node lookup, and module counts, then feeds the returned text into the existing body shop-slot button presentation plan.

Follow-up editor board UI revision key extraction:

```text
RED: lifecycle_services_contract_probe failed because UILifecycleService did not expose editor_board_ui_revision_key
RED: main_file_extraction_contract_probe failed because _update_editor_board_ui still assembled board/catalog revision keys inline
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: Godot --check-only --script res://scripts/services/ui_lifecycle_service.gd --quit-after 1
GREEN: EDITOR_BOARD_SNAPSHOT_INCREMENTAL_PROBE ok rebuilds=1 dynamic=4
GREEN: EDITOR_BOARD_MODEL_INCREMENTAL_PROBE ok shallow=1 skip=1
GREEN: EDITOR_BOARD_SNAPSHOT_LAZY_PROBE ok hits=0 skips=2 rebuild=0
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
```

`UILifecycleService.editor_board_ui_revision_key()` and `editor_catalog_domain_revision_key()` now own the pure stable serialization of board-UI and catalog-domain invalidation keys. `_update_editor_board_ui()` keeps all source-state sampling local, including selected catalog indices, custom-board dynamic revision, pending placement/install state, sort state, barrier grid state, and catalog source signatures, then compares the returned keys against the existing caches.

Follow-up editor action button creation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor action button creation
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
```

`_add_editor_action_button_from_spec()` now owns the concrete Button construction, default sizing, optional node-name application, `_editor_action` signal wiring, scene-tree insertion, and `editor_action_buttons` registration for ordinary editor action specs. `_build_editor_ui()` reuses it for assembly-guide, unit, board-primary, canvas-tool, board-zoom, template-toggle, and catalog-page actions while keeping special-case controls such as sort action intent buttons, module-binding overlays, save-dialog buttons, and orientation-popup buttons local.

Follow-up editor button build-spec property adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor button build spec property application
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
```

`_apply_editor_button_build_spec()` now owns the concrete Button property application for build specs, including optional name/text, position, size, focus mode, visibility, disabled state, z-index, and mouse filter. `_add_editor_action_button_from_spec()` reuses the same adapter, and `_build_editor_ui()` now consumes it for role buttons, part-group buttons, legacy slot buttons, part-filter buttons, and saved-unit load cards while keeping each section's signal wiring, hover routing, and reference registration local.

Follow-up editor panel/save/roster build-spec adapter adoption:

```text
RED: main_file_extraction_contract_probe failed because _build_editor_ui should reuse the editor button build spec property helper
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
```

`_build_editor_ui()` now also applies `_apply_editor_button_build_spec()` to editor panel buttons, save-unit role buttons, save-unit action buttons, roster page buttons, and roster slot buttons. Those sections still keep their local signal wiring, disabled/hidden initialization, hover routing, and stored-reference ownership.

Follow-up editor dashboard/template/shop/sort/color build-spec adapter adoption:

```text
RED: main_file_extraction_contract_probe failed because _build_editor_ui should reuse the editor button build spec property helper
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: BOUND_MODULE_TRYOUT_UI_PROBE ok
GREEN: UNIT_EDITOR_TORSO_DETAIL_BUTTON_PROBE ok torso=0 second=1
GREEN: CATALOG_CARD_TEXT_READABILITY_PROBE ok title=11 line=9 plate=0.62 rev=2
GREEN: UNIT_EDITOR_POWER_DOCK_MOVED_UP_PROBE ok dock=[P: (190.0, 24.0), S: (726.0, 132.0)] rail=[P: (18.0, 104.0), S: (164.0, 508.0)]
GREEN: UNIT_EDITOR_LEGACY_POWER_TABLE_REMOVED_PROBE ok non_explicit_detail_closed=true dock_entries=4
GREEN: UNIT_EDITOR_POWER_ALLOCATION_TOPBAR_PROBE ok dock_entries=4
GREEN: UNIT_EDITOR_NO_POWER_TOPBAR_PROBE ok dock_pos=(190.0, 24.0)
```

`_build_editor_ui()` now also applies `_apply_editor_button_build_spec()` to orientation popup buttons, legacy dashboard power and torso-detail buttons, body-part buttons, module-binding buttons, archetype and barrier-template buttons, shop-slot buttons, sort action/option buttons, team color buttons and pickers, and part catalog cards. Local signal wiring, special initial hidden/disabled state, hover routing, and reference dictionaries remain local to their sections. The older `engine_allocation_dashboard_visible_probe.gd` still asserts the retired legacy dashboard power button should be visible, so current power-dock probes are the authoritative verification path for that surface.

Follow-up editor action button presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor action button presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: UNIT_EDITOR_CLIPBOARD_PROBE ok
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
GREEN: BOUND_MODULE_TRYOUT_UI_PROBE ok
```

`_refresh_editor_action_button_presentations()` now owns the main scene-tree adapter for editor action button presentation plans: it gathers the local clipboard, selection, orientation, board-tool, grid, match-format, and connection-color context, requests one `UILifecycleService.editor_action_presentations()` plan, and applies each managed action button plan through `_apply_editor_control_plan()`. `_apply_editor_panel_visibility()` now delegates that full action-button presentation section with a single call, leaving the remaining sort, info, shop, color, catalog, and section surfaces as the next extraction targets.

Follow-up editor sort controls presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor sort controls presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: CATALOG_CARD_TEXT_READABILITY_PROBE ok title=11 line=9 plate=0.62 rev=2
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: EDITOR_BOARD_ZOOM_PROBE node=0 zoom=1.00 label=100% hover=0
GREEN: SCYTHE_INSTALL_ORIENTATION_UI_PROBE ok node=0
```

`_refresh_editor_sort_controls_presentation()` now owns the main scene-tree adapter for editor sort controls: it normalizes `editor_catalog_sort_key`, applies sort-key and sort-direction button text, applies sort submenu and option button plans, preserves the sort-dir front-order plan, and keeps the adjacent board-zoom and orientation-popup refresh hooks in the same order as before. `_apply_editor_panel_visibility()` now delegates the full sort controls section with a single call.

Follow-up editor info panel presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor info panel presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
```

`_refresh_editor_info_panel_presentation()` now owns the main scene-tree adapter for editor info surfaces: it requests one `UILifecycleService.editor_info_panel_presentation()` plan, applies unit/summary/stats/detail/art/structure/catalog label plans, preserves structure-reference visibility inputs, and keeps save-feedback relayout local to the adapter. `_apply_editor_panel_visibility()` now delegates the full info panel section with a single call.

Follow-up editor shop feedback presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor shop feedback presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: CATALOG_CARD_TEXT_READABILITY_PROBE ok title=11 line=9 plate=0.62 rev=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
```

`_refresh_editor_shop_feedback_presentation()` now owns the main scene-tree adapter for editor shop feedback: it preserves the payload-pending before canvas-pending priority, computes the localized pending detail, requests one `UILifecycleService.editor_shop_feedback_presentation()` plan, and applies the hint/pending label plans through `_apply_editor_control_plan()`. `_apply_editor_panel_visibility()` now delegates the full shop feedback section with a single call.

Follow-up editor color controls presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor color controls presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: CATALOG_CARD_TEXT_READABILITY_PROBE ok title=11 line=9 plate=0.62 rev=2
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
```

`_refresh_editor_color_controls_presentation()` now owns the main scene-tree adapter for editor color controls: it requests one `UILifecycleService.editor_color_controls_presentation()` plan, applies the palette panel/title/button/picker plans through `_apply_editor_control_plan()`, and keeps the existing guarded picker-color synchronization local to the adapter. `_apply_editor_panel_visibility()` now delegates the full color controls section with a single call.

Follow-up editor catalog/shop surface presentation adapter extraction:

```text
RED: main_file_extraction_contract_probe failed because main.gd should centralize editor catalog/shop surface presentation application
GREEN: Godot --check-only --script res://scripts/main.gd --quit-after 1
GREEN: MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=9
GREEN: LIFECYCLE_SERVICES_CONTRACT_PROBE ok
GREEN: PART_LIBRARY_UI_PROBE groups=["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"] weapon=3 equipment=5 software=7 dashboard=40
GREEN: UNIT_EDITOR_PAGINATION_LAYOUT_PROBE ok unit=1 page=0 catalog=1 load=0 feedback=[P: (270.0, 654.0), S: (622.0, 26.0)]
GREEN: UNIT_EDITOR_TEMPLATE_DRAWER_RUNTIME_PROBE ok selected=octopus barrier=BarrierTemplatepin_wall
GREEN: UNIT_EDITOR_FULLSCREEN_LAYOUT_PROBE ok board=(908.0, 548.0) dock=(726.0, 132.0)
GREEN: CATALOG_CARD_TEXT_READABILITY_PROBE ok title=11 line=9 plate=0.62 rev=2
GREEN: EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=0 team_cost=0 roster_cost=0 buttons=5
```

`_refresh_editor_catalog_shop_surface_presentation()` now owns the main scene-tree adapter for editor catalog/shop surfaces: it gathers retained catalog-button visibility facts, requests one `UILifecycleService.editor_catalog_shop_surface_presentation()` plan, applies catalog/shop/backdrop plans through `_apply_editor_control_plan()`, preserves the load-card button refresh, and keeps hover-clearing side effects gated by the service plan. `_apply_editor_panel_visibility()` now delegates the full catalog/shop surface section with a single call.

Remaining items after this batch:

- Continue editor UI extraction with `_build_editor_ui` and the remaining action presentation/control-mutation sections of `_apply_editor_panel_visibility`, then continue `_resolve_attack` and `_refresh_editor_visual_views` extraction.
