# Eidolon Circuit Local Development Status

Last updated: 2026-06-28

This file is the local execution board for the active Linear project `Eidolon Circuit Codebase Slimdown 2026-05-27`. The checked-in backlog remains `docs/development_backlog.md`; this file records local baseline and the next safe implementation order between Linear updates.

## Current Baseline

- Project root: `E:\New project`
- Branch: `safety/eidolon-health-audit-20260525-004915`
- HEAD: `e4ab183`
- Git remote: `origin https://github.com/zhuyeyang979-glitch/Eidolon-Circuit.git`
- Worktree state at baseline: clean
- Godot version: `tools/godot-4.6.2/Godot_v4.6.2-stable_win64_console.exe`

## Current Local Delta

- EC-SLIM-006 follow-up: philosophy `muscle` / `limb_muscle` safe-first live backfill.
- Old torso, limb, melee, mapped projectile, and barrier-panel designs now normalize through existing catalog/runtime fields so they can appear in unit edit, save topology, and enter training/battle runtime data.
- Future projectile/control families remain frozen: seeker, MIRV, rotary/barrage/starburst/eclipse/light-sink/homing/area entries and the old dynamic gun/tether/hijack module entrances.
- Rule guard: philosophy muscle backfill must not invent new action profiles, projectile behavior, AI, save schema, input, settings, or HUD. It only exposes existing action/profile/barrier/runtime facts.
- New/updated probes: `philosophy_muscle_live_catalog_probe`, `philosophy_muscle_editor_runtime_probe`, `backfilled_projectile_weapons_live_probe`, `weapon_subcategory_filter_probe`, and `barrier_panel_probe`.

## 2026-06-28 Hardware Fault Runtime Follow-Up

- Added `tools/hardware_fault_visual_overlay_probe.gd` to guard faulted hardware's in-battle visual contract.
- `scripts/fighter.gd` now renders faulted runtime topology segments through the shared assembly-board status overlay with an amber pulse and a compact `!` marker, while normal and destroyed hardware stay out of this visual path.
- The runtime redraw signature includes faulted hardware state and a low-frequency pulse bucket so the overlay can refresh while the unit is otherwise idle.
- Movement and boost hardware-fault gates now preserve the first blocked dependency's stable part name in `movement_gate_reason`, matching the named module-action gate feedback.

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
- Historical Godot ObjectDB leak warnings appeared on some earlier runs; the latest 2026-06-17 targeted macOS headless verification below did not reproduce them.

## 2026-06-17 yhzlxp Optimization Execution Snapshot

- Active branch: `codex/yhzlxp-eidolon-work`.
- Added `docs/plans/2026-06-17-project-optimization-execution.md` as the prioritized execution plan for the current optimization batch.
- Extracted assembly template model construction from `scripts/main.gd` into `scripts/services/unit_editor_assembly_template_service.gd`; `main.gd` now remains the adapter/composition owner for this path.
- Extended `scripts/services/unit_stats_service.gd` beyond stats-cache bookkeeping so it now owns the default stats schema, pure base motion envelope, part logic/combat/payload field copy gating, torso payload direct stat merges for ammo/shield/escape/spare payloads, torso payload summary-entry accumulation, special payload intent classification, soul heat-capacity stat/note application, internal payload base stat accumulation, module payload logic-field copying, torso payload summary note/cap finalization, role deploy profile, and manufacturer discount post-processing for `_compute_unit_stats`.
- Extracted engine allocation data model construction from `scripts/main.gd` into `scripts/services/unit_editor_engine_allocation_service.gd`; `main.gd` now remains the callback adapter for current topology and binding data.
- Extracted assembly template overlay drawing from `scripts/views/editor/assembly_board_view.gd` into `scripts/views/editor/assembly_template_overlay_renderer.gd`; `AssemblyBoardView` now delegates overlay rendering while keeping board snapshot and retained-layer ownership.
- Added headless contract probes: `part_identity_contract_probe` and `unit_editor_assembly_template_service_contract_probe`.
- Added `unit_stats_service_contract_probe`, `unit_editor_engine_allocation_service_contract_probe`, and `assembly_template_overlay_renderer_contract_probe` to guard the new service/view boundaries.
- Registered the new contract probes in `tools/probe_manifest.json`; registered `part_identity_language_probe` and `unit_editor_assembly_template_probe` as manual/headed visual checks because they skip under headless display.
- Verification passed: `jq empty tools/probe_manifest.json`, `git diff --check`, Godot `--check-only`, `part_identity_contract_probe`, `unit_editor_assembly_template_service_contract_probe`, `assembly_template_overlay_renderer_contract_probe`, `unit_editor_engine_allocation_service_contract_probe`, `unit_stats_service_contract_probe`, `main_file_extraction_contract_probe` (`services=9`), `view_extraction_contract_probe`, `headed_gate_manifest_source_probe`, `headed_gate_manifest_alignment_probe`, `engine_momentum_allocation_open_probe`, `power_allocation_panel_heat_live_update_probe`, `engine_momentum_allocation_scope_probe`, `power_allocation_equalize_percent_all_entries_probe`, `audio_lifecycle_contract_probe`, `part_preview_board_art_identity_probe`, and `unit_editor_assembly_guide_service_probe`.
- Additional `_compute_unit_stats` regression probes passed after the `UnitStatsService` extraction: `editor_cost_accounting_probe`, `unit_build_rule_training_gate_probe`, `thruster_dual_motion_formula_probe`, `source_code_probe`, `barrier_panel_probe`, `projectile_profile_whitelist_probe`, and `legacy_power_symbol_absence_probe`.
- Follow-up stats extraction note: torso payload direct stat merges now route through `UnitStatsService.apply_torso_payload_direct_stats()`, sampled payload/software/ammo facts accumulate through `UnitStatsService.record_torso_payload_summary_entry()`, special payload ether/soul/code classification routes through `UnitStatsService.apply_torso_special_payload_logic_stats()`, soul heat-capacity stat/note application routes through `UnitStatsService.apply_soul_heat_capacity_stats()`, internal payload base stat accumulation routes through `UnitStatsService.apply_internal_payload_base_stats()`, module payload command/module/fracture/morph/combine/identity logic-field copying routes through `UnitStatsService.apply_torso_module_payload_logic_stats()`, and final payload/ammo summary note application routes through `UnitStatsService.apply_torso_payload_summary()`; `main.gd` still owns payload traversal, catalog lookups, volume-rank sampling, soul bonus/ether/helper-specific internal payload implementations, and internal-slot status lookup until a later payload model extraction.
- Follow-up verification for the torso payload direct stat merge, summary-entry accumulation, special/module logic-field handling, internal payload base stats, and summary extraction passed: `jq empty tools/probe_manifest.json`, `git diff --check`, Godot `--check-only`, `unit_stats_service_contract_probe`, `main_file_extraction_contract_probe`, `editor_cost_accounting_probe`, `unit_build_rule_training_gate_probe`, `thruster_dual_motion_formula_probe`, `source_code_probe`, `soul_oath_activation_probe`, `ether_heat_economy_probe`, `engine_momentum_allocation_open_probe`, `power_allocation_panel_heat_live_update_probe`, `barrier_panel_probe`, `projectile_profile_whitelist_probe`, and `legacy_power_symbol_absence_probe`.
- The latest targeted Godot outputs did not include ObjectDB leaked-instance warnings. Continue watching future headed/manual runs because older local history recorded them.
- Resource note: `assets/concepts/` remains a large local concept-art set and should stay out of normal code commits until a Git/Git LFS/local-reference policy is chosen.

## 2026-06-18 Progress Recheck Snapshot

- Active branch remains `codex/yhzlxp-eidolon-work`, ahead of `origin/codex/yhzlxp-eidolon-work`; `main` has not been modified directly in this workspace.
- Current `main.gd` size is 52,467 lines. The largest remaining functions are `_build_editor_ui` (681 lines), `_apply_editor_panel_visibility` (399), `_resolve_attack` (380), `_compute_unit_stats` (297), and `_refresh_editor_visual_views` (252).
- Current untracked resource policy item remains unchanged: `assets/concepts/` plus two generated `.png.import` files are local/untracked and should stay out of code commits until Git/Git LFS/local-only handling is decided.
- Latest focused cleanup moved action-module payload logic-field copying from `_apply_torso_slot_payload_stats()` into `UnitStatsService.apply_torso_module_payload_logic_stats()`, moved special payload ether/soul/code classification into `UnitStatsService.apply_torso_special_payload_logic_stats()`, moved soul heat-capacity stat/note application into `UnitStatsService.apply_soul_heat_capacity_stats()`, and moved internal payload base stat accumulation into `UnitStatsService.apply_internal_payload_base_stats()`.
- Minimal boundary verification passed for the latest cleanup: `jq empty tools/probe_manifest.json`, `git diff --check`, `unit_stats_service_contract_probe`, and `main_file_extraction_contract_probe`.
- Optimization priority from this recheck: finish the `_compute_unit_stats` payload model extraction first, then split editor UI construction/visibility into focused view/state builders, then continue runtime `_resolve_attack` event-route extraction, and finally trim editor visual refresh orchestration.

## 2026-06-12 yhzlxp Optimization Baseline

- Active branch: `codex/yhzlxp-eidolon-work`.
- Local macOS Godot: `/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot`.
- Local Godot version: `4.6.2.stable.official.71f334935`.
- `arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1`: passed with the known ObjectDB leak warning.
- P0 architecture probes passed locally: `app_root_boundary_probe`, `app_mode_host_contract_probe`, `battle_state_contract_probe`, `battle_mode_contract_probe`, `menu_mode_contract_probe`, `team_edit_mode_contract_probe`, `saved_units_mode_contract_probe`, `settings_mode_contract_probe`, and `training_mode_contract_probe`.
- Static guards passed: `git diff --check`, `jq empty tools/probe_manifest.json`, and packed runtime folders were not present in the tracked worktree.
- First P1/P3 optimization started: `SavedUnitsMode.show_intent()` now normalizes focus paths and return contexts at the mode boundary so saved-unit page transitions do not preserve accidental edge whitespace in page state or payloads. `tools/saved_units_mode_contract_probe.gd` guards the normalized intent.
- Second P1/P3 optimization: `TrainingMode.begin_from_scout_intent()` now normalizes the pending battle mode before applying the training-seat gate, so accidental edge whitespace cannot bypass the training mode boundary. `tools/training_mode_contract_probe.gd` guards the normalized pending-mode intent.
- Third P1 optimization: `BattleMode` now normalizes battle mode keys before app-mode mapping, show intents, and enter intents, so training battle transitions stay classified as training even if a caller passes edge whitespace. `tools/battle_mode_contract_probe.gd` guards the normalized battle-mode intent.
- Fourth P1 optimization: `SettingsMode.show_intent()` now normalizes settings categories, return targets, and blank transition reasons at the mode boundary, so settings page transitions keep stable routing metadata. `tools/settings_mode_contract_probe.gd` guards the normalized settings show intent.
- Fifth P1 optimization: `TeamEditMode` now normalizes enter, cleanup, and exit reasons at the mode boundary, so editor page transitions and cleanup telemetry do not preserve accidental edge whitespace. `tools/team_edit_mode_contract_probe.gd` guards the normalized Team Edit intent metadata.
- Sixth P1 optimization: `AppModeHost` now normalizes payload `mode` values and transition reasons before page-mode mapping and transition commits, while `MenuMode` normalizes enter, show, and exit reasons. `tools/app_mode_host_contract_probe.gd` and `tools/menu_mode_contract_probe.gd` guard the app/menu boundary metadata.
- First P2 optimization: `UnitEditorBoardController.custom_topology_click_intent()` now routes stable `reject_reason` and `hint_key` metadata for binding failures, pose-drag rejects, connected-selection/connected-part layout rejects, and blank-canvas hints. `main.gd` consumes the intent-provided binding/layout rejection reason while preserving the existing localized UI copy and gameplay rules.
- Fresh RED/GREEN verification passed through `tools/unit_editor_board_controller_contract_probe.gd`: the probe first failed on missing `hint_key`/`reject_reason` fields and then passed after the controller/main update. Adjacent behavior probes passed: `board_connected_part_layout_protection_probe`, `pose_mode_unconnected_part_hint_probe`, `board_unconnected_limb_pose_mode_moves_probe`, and `team_edit_mode_contract_probe`.
- Second P2 optimization: `UnitEditorCatalogController.page_state()` now owns catalog page clamping, max-page calculation, and visible entry range calculation. `main.gd` delegates catalog max-page and catalog-button refresh page bounds through that helper so filter/sort refreshes cannot preserve an out-of-range page in UI state.
- Fresh RED/GREEN verification passed through `tools/unit_editor_catalog_controller_contract_probe.gd`: the probe first failed on missing `page_state` controller/main delegation and then passed after the controller/main update. Adjacent catalog behavior probes passed: `unit_editor_pagination_layout_probe`, `editor_scroll_regions_probe`, `catalog_card_page_swap_budget_probe`, and `teamedit_scroll_frame_budget_probe`.
- Third P2 optimization: `TeamEditController.save_blocking_feedback()` now converts save rejection reasons into stable `action_key`, `field_path`, and localized `action_hint` metadata. `main.gd` keeps the original save rejection reason visible while appending the actionable hint, so strict save validation stays strict and users can see the first condition to fix.
- Fresh RED/GREEN verification passed through `tools/team_edit_controller_contract_probe.gd`: the probe first failed on missing `save_blocking_feedback` controller/main delegation and then passed after the controller/main update. Adjacent save probes passed: `saved_unit_strict_rejection_probe`, `teamedit_save_complex_unit_real_ui_probe`, `saved_unit_postwrite_validation_probe`, `teamedit_save_unit_button_probe`, `teamedit_save_unit_real_ui_probe`, and `unit_editor_training_illegal_feedback_probe`.
- Fourth P2 optimization: `UnitEditorBoardController.selected_node_feedback()` now owns the pure selected-node feedback model for current socket/part state. `main.gd` supplies localized short labels and appends the helper summary to the board hint, while reusing the same metadata for the right-side current-node shop marker.
- Fresh RED/GREEN verification passed through `tools/unit_editor_board_controller_contract_probe.gd`: the probe first failed on missing `selected_node_feedback` controller/main delegation and then passed after the controller/main update. Adjacent board interaction probes passed: `board_click_part_hover_probe`, `power_allocation_click_part_hover_probe`, `board_connected_part_layout_protection_probe`, and `pose_mode_unconnected_part_hint_probe`.
- Fifth P2 optimization: `UnitEditorCatalogController.entry_state_for_card()` now owns pure catalog-card hover resolution. It normalizes the active page, resolves the entry/slot/index for a visible card, returns stable hover metadata, and marks empty or out-of-page card slots as hover-clear states; `main.gd` delegates `_hover_catalog_component()` through that helper while keeping card rendering and hover presentation unchanged.
- Fresh RED/GREEN verification passed through `tools/unit_editor_catalog_controller_contract_probe.gd`: the probe first failed on missing `entry_state_for_card` controller/main delegation and then passed after the controller/main update. Adjacent catalog and hover probes passed: `catalog_card_page_swap_budget_probe`, `teamedit_scroll_frame_budget_probe`, `teamedit_hover_cache_probe`, `teamedit_hover_frame_budget_probe`, `teamedit_hover_no_full_refresh_probe`, `unit_editor_pagination_layout_probe`, `editor_scroll_regions_probe`, and `weapon_subcategory_filter_probe`.
- P2 UI/static verification passed after the Team Edit feedback and catalog hover updates: `unit_editor_board_controller_contract_probe`, `unit_editor_catalog_controller_contract_probe`, `team_edit_mode_contract_probe`, `ui_layout_probe`, `text_overflow_probe`, `--headless --check-only --quit-after 1`, `git diff --check`, and `jq empty tools/probe_manifest.json`.

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

`EC-SLIM-002` has continued with nine low-risk inline views extracted:

- `BackdropView` -> `scripts/views/backdrop_view.gd`
- `SortieThumbView` -> `scripts/views/sortie_thumb_view.gd`
- `CockpitHudView` -> `scripts/views/cockpit_hud_view.gd`
- `BattleInstrumentGaugeView` -> `scripts/views/battle_instrument_gauge_view.gd`
- `BattleMinimapView` -> `scripts/views/battle_minimap_view.gd`
- `BattlePartPreviewView` -> `scripts/views/battle_part_preview_view.gd`
- `TrainingEntryIntroView` -> `scripts/views/training_entry_intro_view.gd`
- `PartDragGhostView` -> `scripts/views/part_drag_ghost_view.gd`
- `ComponentArtView` -> `scripts/views/component_art_view.gd`

The first pure battle effect batch has also been extracted:

- `HitEffect` -> `scripts/effects/hit_effect.gd`
- `ComboRippleEffect` -> `scripts/effects/combo_ripple_effect.gd`
- `ProjectileTraceEffect` -> `scripts/effects/projectile_trace_effect.gd`

`EC-SLIM-002` now also has a guard:

- `tools/main_inline_class_guard_probe.gd` allows only the known deferred inline classes in `main.gd` and blocks reintroducing extracted view/effect classes.

`EC-SLIM-003` has started with the first catalog controller seam:

- `UnitEditorCatalogController` -> `scripts/controllers/unit_editor_catalog_controller.gd`
- `main.gd` still owns card-content and rule callbacks but delegates catalog cache keys, source signatures, raw entry slot traversal, page selection signatures, page cache keys, page model traversal, cache invalidation, catalog group/default-filter mappings, catalog labels, filter option/slot selection, catalog selection-state transitions, available sort key traversal, and catalog entry sorting to the controller.
- `_part_filter_options_for_group()` is the live UI submenu contract; `_all_part_filter_options_for_group()` is the full rule-audit/probe contract for terminal weapon filter coverage.
- `tools/unit_editor_catalog_controller_contract_probe.gd` guards this seam.
- `UnitEditorBoardController` -> `scripts/controllers/unit_editor_board_controller.gd`
- `main.gd` now delegates board input route decisions, drag-release intents, selection-box release classification, and custom topology click classification to the board controller; `_handle_editor_board_input()` is controller-only and no longer carries a shadow fallback. Topology fact calculation, topology mutation, pose/scythe rules, drag execution, and UI refresh still stay in `main.gd`.
- `tools/unit_editor_board_controller_contract_probe.gd` guards the route matrix.

`EC-SLIM-004` has started with the first saved-units controller seam:

- `SavedUnitsController` -> `scripts/controllers/saved_units_controller.gd`
- `main.gd` still owns saved-unit file IO, JSON loading, save/delete operations, stats/legality rules, cache containers, cache trimming, UI construction, training import, hover/detail side effects, and SFX.
- `main.gd` now delegates saved-unit library signatures, filtered-cache keys, pure entry filtering traversal, entry path fallback, focus-path page calculation, absolute card index math, and filter/card selection-state dictionaries to `SavedUnitsController`.
- `tools/saved_units_controller_contract_probe.gd` guards that this seam stays pure and does not gain file IO or UI node dependencies.
- The seam now also covers Saved Units page intents: hover-card state, selected-entry traversal, delete candidates, delete request summaries, selected-path toggles, and `prev/next/clear/toggle` page actions. `main.gd` still owns deletion IO, details, hints, SFX, training import, and edit import.
- `TrainingEntryService` -> `scripts/services/training_entry_service.gd`
- `main.gd` now delegates the training ball dummy pure model: radius clamp/step, sphere volume, volume-scaled mass, stats, entry, and intro segment.
- The service now also owns pure training-entry planning: pending imports, import loadout shape, active-first legal hero selection, starter fallback state, and training seat side assignment. Training start, battle entry, spawn, saved-unit IO, Unit4 repair, starter construction, UI/SFX, and legality validation remain in `main.gd`.
- `tools/training_entry_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `SavedUnitLibraryService` -> `scripts/services/saved_unit_library_service.gd`
- `main.gd` now delegates saved-unit latest-name lookup, overwrite/save-as path resolution, payload shape, and readback status classification. Actual file IO, JSON conversion, schema validation, safe file naming, cache invalidation, and UI feedback remain in `main.gd`.
- The service now also owns the typed loader seam: record signatures, cache refresh intent, payload-to-entry construction, canonical rejected entry construction, and record traversal. `main.gd` still performs disk scans, JSON parse/stringify, schema rejection, entry-pose callback execution, UI feedback, and SFX.
- `tools/saved_unit_library_service_contract_probe.gd` guards that this service stays pure and does not gain IO/UI dependencies.

`EC-SLIM-005` has started with the first battle runtime service seam:

- `BattleInputService` -> `scripts/services/battle_input_service.gd`
- `main.gd` now delegates fixed-step battle input action-name generation, edge-frame capture/consume state, just-pressed/just-released lookup, battle mode route selection, direction-tap detection, movement just-pressed state, and spectator camera input intent to the service.
- Real `Input` reads, pause menu toggles, player movement/turn/attack side effects, spectator camera writes, summon/module execution, rebinding UI, projectile/contact/VFX runtime, and `Fighter` internals remain in `main.gd`.
- `tools/battle_input_service_contract_probe.gd` guards that the service stays pure and does not gain global `Input`, IO, UI, battle menu, summon, or active-unit dependencies.
- `BattleFrameOrchestratorService` -> `scripts/services/battle_frame_orchestrator_service.gd`
- `main.gd` now delegates fixed-step accumulator planning, simulation phase order, early-exit phase selection, render-alpha post-step state, and contact/GPU pass scheduling intent to the service.
- Input sampling, phase side effects, unit/resource/deploy/AI/projectile/contact/camera updates, GPU submit/readback, contact dictionaries, battle end, HP/heat, VFX/SFX, and Node lifecycle remain in `main.gd`.
- `tools/battle_frame_orchestrator_service_contract_probe.gd` guards service purity, phase order, accumulator clamp/truncation behavior, contact-pass intent, and `main.gd` wrapper/dispatch usage.
- `BattleFieldRuntimeService` -> `scripts/services/battle_field_runtime_service.gd`
- `main.gd` now delegates field/support/barrier utility pure decisions: lease/annuity timers, support aura/target intents, speed-lane velocity targets, coin generator and pickup classification, signal jammer progress, barrier utility action selection, gravity/coolant/heat/repulsion/siphon/hack/cage field payloads, trap gate/fire payloads, and hatchery/hatchling stat plans.
- Live Node traversal, Mobius/map-tile target tests, command-buffer consumption, random VFX rolls, resource/velocity/HP/heat/meta writes, unit creation, defect ownership changes, VFX/SFX, messages, and Node lifecycle remain in `main.gd`.
- `tools/battle_field_runtime_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleHitResolutionService` -> `scripts/services/battle_hit_resolution_service.gd`
- `main.gd` now delegates attack entry gates, projectile preflight route classification, target hit field patches, combo multiplier math, damage/frontload/DOT intent, post-hit action ordering, and chemical/takeover status tick planning to the service.
- The service now also owns the deeper hit-application pure pipeline: damage stack continuation, part-damage route/HP intents, projectile/active-melee stagger scalar intents, hit-displacement transfer/impulse scalars, and the post-hit dispatcher order consumed by `_resolve_attack()`.
- Target traversal, hit/GPU/map queries, ammo, blind-fire randomness, HP/heat/meta writes, VFX/SFX, hitstop, displacement, kill handling, reflection, explosion traversal, web runtime, and Node lifecycle remain in `main.gd`.
- `tools/battle_hit_resolution_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleProjectileLifecycleService` -> `scripts/services/battle_projectile_lifecycle_service.gd`
- `main.gd` now delegates delayed chemical projectile timers, missile homing/occlusion lifecycle, chemical firework pellet patching, web tether/swing lifecycle intent, web fire route classification, explosion falloff payloads, and projectile reflection payloads to the service.
- The service also owns Web target candidate gates, Web impact candidate/ranking intent, and boundary swing anchor math; `_field_targets_for()`, `_attack_part_hit()`, GPU impact queries, Mobius context, active tether/swing mutation, VFX/SFX, messages, and traces stay in `main.gd`.
- Live target collection, Mobius/GPU/map queries, pending array mutation, random fallback directions, velocity/HP/heat/meta writes, VFX/SFX, battle messages, hitstop, kill handling, and Node lifecycle remain in `main.gd`.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleActionEventService` -> `scripts/services/battle_action_event_service.gd`
- `main.gd` now delegates attack-event shaping upstream of `_resolve_attack()`: module begin intent, command-window fire routing, runtime-direct module event fields, normal/puppet attack normalization, gun activation projectile defaults, control-event field copying, module-effect event patching, and module-variant field patching.
- Input reads, live unit/gun source queries, aim pose writes, heat/ammo/resource mutation, `Fighter` runtime action writes, VFX/SFX, messages, and `_resolve_attack()` calls remain in `main.gd`.
- `tools/battle_action_event_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleImpactQueryService` -> `scripts/services/battle_impact_query_service.gd`
- `main.gd` now delegates pure impact-query decisions around `_first_projectile_impact()`, `_first_projectile_impact_gpu()`, and `_attack_part_hit()`: projectile direction normalization, true-bullet candidate gates, first-impact ranking, GPU hit ranking, hit slop, directional rejection, and hit payload shaping.
- Live unit traversal, Node validation, collider construction, Mobius/map/GPU queries, geometry math callbacks, HP/heat/meta writes, VFX/SFX, messages, and kill handling remain in `main.gd`.
- `tools/battle_impact_query_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleIdentityRuntimeService` -> `scripts/services/battle_identity_runtime_service.gd`
- `main.gd` now delegates identity-runtime pure decisions: role-switch/soul-cast gates, receiver and role-switch target selection, identity transfer role maps, role-form target/gate/finish shape, morph mode/shape, combine partner selection, combine/separate stat payloads, and separated partner spawn placement.
- Live Node checks, `active_units` slot ownership, role assignment, unit create/detach/free, identity effects, VFX/SFX, messages, UI refresh, and freeze timers remain in `main.gd`.
- `tools/battle_identity_runtime_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleSpatialRuntimeService` -> `scripts/services/battle_spatial_runtime_service.gd`
- `main.gd` now delegates pure battle-space decisions: camera follow alpha, player/spectator focus intent, camera interpolation state, screen projection intent, world-point visibility, portal spawn placement, and Mobius surface-input fallback/sign preservation.
- Live unit traversal, `active_units` reads, `MobiusWorld`/`GameplayTransform` calls, camera state writes, Line2D/effect positioning, map occlusion, VFX/SFX, and battle mutation remain in `main.gd`.
- `tools/battle_spatial_runtime_service_contract_probe.gd` guards purity, wrapper delegation, and lifted Mobius lane preservation for seam-adjacent projectile traces. `battle_xy_isometric_probe` now guards the current split: gameplay projection remains locally rectangular while visual Mobius projection still varies depth/scale.
- `BattleMapOcclusionService` -> `scripts/services/battle_map_occlusion_service.gd`
- `main.gd` now delegates pure map occlusion decisions: occlusion kind classification, path-capsule intent, blocker candidate filtering/ranking, query payload shaping, and line-of-sight boolean helpers.
- Live unit traversal, Mobius deltas, raw collider collection, shifted collider geometry, one-way shield pass rules, blocker Node references, VFX/SFX, HP/heat writes, and battle mutation remain in `main.gd`.
- `tools/battle_map_occlusion_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleTargetAcquisitionService` -> `scripts/services/battle_target_acquisition_service.gd`
- `main.gd` now delegates pure weapon target-acquisition rules: target direction fallback, missile target class classification, class allowlists, true-bullet direct/wrapped candidate selection, missile gate checks, lock scoring, and final target-index selection.
- Live unit traversal, active-slot role fallback, Mobius deltas, hit tests, LOS/occlusion queries, screen visibility, pending true-bullet/missile state, effects, VFX/SFX, messages, and `_resolve_attack()` remain in `main.gd`.
- `tools/battle_target_acquisition_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleActorCommandService` -> `scripts/services/battle_actor_command_service.gd`
- `main.gd` now delegates deploy timer plans, summon gate decisions, auto-summon candidate choice, puppet condition/move/action intents, and barrier logic classification to the service.
- `main.gd` still owns `active_units`/`all_units`, pending deploy snapshots/previews, resource writes, `_create_unit()`, role assignment, module begin calls, `_resolve_attack()`, barrier aura target queries, HP/heat writes, VFX/SFX, battle messages, random/time reads, and Node lifecycle.
- `tools/battle_actor_command_service_contract_probe.gd` guards the pure actor-command seam, and `resource_entry_probe` now uses explicit deploy/ammo/shield fixtures so it no longer depends on mutable default roster slot-zero semantics.
- `ProjectileRuntimeService` -> `scripts/services/projectile_runtime_service.gd`
- `main.gd` now delegates projectile behavior classification, style defaults, speed/mass/momentum state, gun projectile multipliers, raw damage, recoil transfer defaults, heat tags/reasons, chemical/missile queue intents, web trace event shaping, and projectile trace payload shaping to the service.
- Real hit selection, GPU geometry queries, HP/heat writes, web tether state, chemical/missile pending arrays, reflection/explosion handling, VFX/SFX, battle messages, and unit mutation remain in `main.gd`.
- `GpuGeometryService` now exposes a synchronous geometry-query wrapper for immediate hit-confirm paths; ordinary projectile hit queries keep using the deferred path, while web tether uses the synchronous path because it must create tether state on the firing frame and can target both enemies and allies.
- `tools/projectile_runtime_service_contract_probe.gd` guards that the service stays pure and does not gain `Input`, IO, UI node, active-unit, pending-projectile, GPU pipeline, spawn, or damage-application dependencies.
- `RuntimeContactService` -> `scripts/services/runtime_contact_service.gd`
- `main.gd` now delegates runtime collider sorting, socket/pair keys, directed contact keys, torso-proxy classification, material/damage type, contact source, part/path stiffness, break threshold, CPU pair intent, GPU readback intent, and contact damage event payload shaping to the service.
- GPU submission/readback, position correction, recovery/brake calls, HP/heat writes, VFX/SFX, active-pair dictionaries, kill handling, and `Fighter` mutation remain in `main.gd`.
- `tools/runtime_contact_service_contract_probe.gd` guards service purity and wrapper delegation.
- `RuntimeColliderGeometryService` -> `scripts/services/runtime_collider_geometry_service.gd`
- `main.gd` now delegates pure circle/capsule/polygon geometry helpers for centers, radii, bounds, broadphase/precise gaps, hit positions, transforms, polygon containment, and segment distances/intersections to the service while keeping ring/Mobius offset selection in `_shift_collider_to_origin()`.
- `Fighter._runtime_collider_with_bounds()` now uses the same pure geometry service via lazy initialization, so direct probe-created fighters and battle runtime colliders share one bounds kernel.
- `RuntimeColliderBuilderService` -> `scripts/services/runtime_collider_builder_service.gd`
- `Fighter._runtime_cached_part_colliders()` now keeps cache ownership, world segment lookup, active node extraction, polygon generation, attack-index lookup, contact fields, and stiffness defaults in `Fighter`, then delegates pure runtime collider payload assembly to the builder service.
- The builder service owns only collider dictionary assembly: runtime topology flags, independent-vs-torso-proxy damage fields, polygon/capsule shape selection, torso contact fields, default contact shape kind, and stiffness/path-stiffness field filling from precomputed inputs.
- Fighter pose, runtime segment generation, socket anchoring, scythe side-mount geometry, GPU pipeline ownership, contact damage, projectile effects, and save data remain outside this service.
- `tools/runtime_collider_geometry_service_contract_probe.gd` and `tools/runtime_collider_builder_service_contract_probe.gd` guard service purity, wrapper delegation, representative circle/capsule/polygon geometry behavior, and active/passive runtime collider payload semantics.
- Two-Link runtime contact hardening:
- `two_link_forward_snap` now uses its authored base duration (`0.62s` by default) instead of letting `MotionBudget.duration` stretch the action. Motion budget still contributes chain/contact distance diagnostics, while runtime contact speed uses the startup effective distance over the authored duration.
- `two_link_damage_balance_probe` and `unit2_static_two_link_damage_probe` now share deterministic target-torso placement and Mobius sync before contact validation.
- `BattleVfxBudgetService` -> `scripts/services/battle_vfx_budget_service.gd`
- `main.gd` now delegates battle VFX frame reset and budget classification to the service while keeping the public frame/drop counters and spawn-total counters in `main.gd`. Runtime uses the service scalar code path to avoid per-VFX Dictionary allocation; the Dictionary intent API remains for contract testing.
- `BattleRuntimeLifecycleService` -> `scripts/services/battle_runtime_lifecycle_service.gd`
- `main.gd` now delegates battle cleanup and lifecycle snapshot decisions to the service while still owning all side effects: runtime menu hiding, aim-line visibility, `_clear_all_units()`, input-edge clearing, aim/gun state reset, and actual node cleanup.
- The lifecycle seam now also covers death/exit pure decisions: kill-flow ordering, destroy-economy resource intents, pirate betrayal gates, retreat repair timers, escape-pod spawn/tick payloads, fracture-puppet cleanup, and torso fracture brood spawn planning. `main.gd` still owns live Node traversal, random rolls, repair station lookup, Mobius deltas, `_create_unit()`, detach/free, resource/victory/meta writes, VFX/SFX, messages, and `_end_battle()`.
- `tools/battle_vfx_budget_service_contract_probe.gd` and `tools/battle_runtime_lifecycle_service_contract_probe.gd` guard these seams, and `tools/main_controller_boundary_probe.gd` now tracks both services.
- Battle HUD runtime discount hot-path fix:
- `battle_runtime_frame_budget_probe` was failing because `_sortie_discount_status()` recomputed unit stats through `_sortie_entry_label(..., include_cost=true)` during HUD heavy updates. `sortie_price_state` now caches `base_deploy_cost` at battle start, and `_sortie_entry_runtime_discount_label()` formats the same live discount price from cached base cost plus the existing runtime multiplier.
- Latest headed `battle_runtime_frame_budget_probe` passes with `avg_ms=1.715`, `max_ms=2.228` on the current local saved Unit2 fixture.
- `BattleHudStateService` -> `scripts/services/battle_hud_state_service.gd`
- `main.gd` now delegates battle HUD heavy text model assembly to the service through `_battle_hud_text_snapshot()`.
- The service also owns pure HUD bar/gauge model decisions: role health/shield/heat ratios, corner-bar and shield-bar fill geometry, puppet segment layout, controlled-unit speedometer limits, and filtered ammo breakdown.
- Label/ColorRect writes, bar color assignment, minimap updates, gauge drawing, and actual battle state ownership remain in `main.gd`.
- Existing HUD text helpers keep their wrapper names and now delegate pure formatting to the service: `_role_status_text()`, `_unit_status_text()`, `_unit_ammo_display_text()`, `_role_bar_text()`, and `_sortie_entry_runtime_discount_label()`.
- HUD bar/gauge wrappers keep their existing names and consume service models: `_set_corner_bar()`, `_set_shield_corner_bar()`, `_set_puppet_segment_bar()`, `_live_unit_ammo_breakdown()`, and `_update_battle_instrument_gauge()`.
- `tools/battle_hud_state_service_contract_probe.gd` guards the service purity and wrapper delegation.
- `BattleAwarenessService` -> `scripts/services/battle_awareness_service.gd`
- `main.gd` now delegates minimap point normalization, live-unit counting, first-live puppet selection, enemy/friendly id selection, nearest enemy, and source/puppet target scoring to the service.
- Real unit Nodes, `active_units`/`all_units` ownership, Mobius distance, barrier tile world-position callbacks, map occlusion, AI action execution, damage, VFX/SFX, and `BattleMinimapView` drawing remain in `main.gd`.
- `tools/battle_awareness_service_contract_probe.gd` guards the service purity and wrapper delegation.

`EC-SLIM-006` has started with the first Fighter runtime model seam:

- `FighterHeatModel` -> `scripts/services/fighter_heat_model.gd`
- `Fighter` now delegates pure heat capacity/cooling-rate lookup, natural/manual cooling intents, overheat shutdown intent, heat-event tag canonicalization, heat-relief math, heat-resource checks, and heat ratio math to the model.
- `Fighter` still owns Node lifecycle, velocity braking, visual refresh, state-field writes, boost gates, runtime actions, collisions, HP/shield, and VFX/SFX.
- `_heat_model()` lazily initializes the model so direct runtime/probe construction paths that call `setup_unit()` / `boost()` before `_ready()` keep canonical heat behavior.
- `tools/fighter_heat_model_contract_probe.gd` guards the service purity and wrapper delegation.
- `FighterMovementModel` -> `scripts/services/fighter_movement_model.gd`
- `Fighter` now delegates pure thruster cone filtering, bidirectional-thruster classification, speedometer/brake math, reverse-drive gates, movement command classification, movement drive intent, velocity-brake intent, and Boost delta-v/timer/heat/cooldown intent to the model.
- `Fighter` still owns velocity writes, Mobius integration, visual timers, body sway/swing, meta writes, projection guard timestamps, heat application, cooldown fields, contacts, actions, and VFX/SFX.
- `_movement_model()` lazily initializes the model for direct probe/runtime construction paths.
- `tools/fighter_movement_model_contract_probe.gd` guards the service purity and wrapper delegation.
- `_apply_thruster_momentum_stats()` now derives move/Boost/brake stats before applying `DriveSystemService`, restoring the v3 formula probes while keeping `Fighter` runtime on canonical `move_speed`, `move_acceleration`, `boost_speed`, and `brake_power`.
- `FighterTurnModel` -> `scripts/services/fighter_turn_model.gd`
- `Fighter` now delegates pure shortest-arc angle delta, facing request intent, turn command intent, turn-input active/timer intent, turn brake acceleration, and fixed-step turn dynamics intent to the model.
- `Fighter` still owns facing/angle/angular-velocity state writes, sync from angle to facing sign, runtime visuals, gun aim, module actions, contacts, and VFX/SFX.
- `_turn_model()` lazily initializes the model for direct probe/runtime construction paths.
- `tools/fighter_turn_model_contract_probe.gd` guards the service purity and wrapper delegation.
- `FighterActionModel` -> `scripts/services/fighter_action_model.gd`
- `Fighter` now delegates pure basic action gate/event intent, runtime module gate intent, module cancel gate intent, whole-body action state intent, generic cooldown derivation, runtime action phase/progress/timer intent, forced-recovery timer clamping, pose-progress scalar curves, variant pose scalar decisions, and Two-Link authored-duration timing intent to the model.
- `Fighter` still owns state writes, combat signal emission, meta writes, heat application, soul echo/combo side effects, runtime module action arrays, velocity impulses, geometry overrides, contact damage, and VFX/SFX.
- `_action_model()` lazily initializes the model for direct probe/runtime construction paths.
- `tools/fighter_action_model_contract_probe.gd` guards the service purity and wrapper delegation.
- Variant callbacks still run against the substep-start action phase before the model's tick intent writes the substep-end timer, preserving narrow startup windows such as Feint Thrust retargeting.
- Two-Link, gauntlet, blunt terminal, blade/scythe, and generic melee overrides consume `FighterActionModel` curve/variant scalar intents; endpoint writes, socket anchoring, TopologyPoseResolver calls, collider generation, and side-mount geometry remain in `Fighter`.
- `tools/runtime_action_geometry_boundary_probe.gd` is now registered in the manifest and guards that `FighterActionModel` stays scalar-only while runtime geometry ownership remains in `Fighter`.
- `FighterActionModel` now also owns pure runtime action telemetry summaries. `Fighter.runtime_action_telemetry_snapshot()` exposes those summaries for probes/debugging without moving action arrays, geometry, contact, or visual ownership out of `Fighter`.
- `BattleRuntimeActionTelemetryService` -> `scripts/services/battle_runtime_action_telemetry_service.gd`
- `main.gd` now exposes a battle-level read-only action telemetry snapshot by traversing live `all_units`, collecting each `Fighter.runtime_action_telemetry_snapshot()`, and delegating aggregation to the pure service.
- The service only consumes plain dictionaries and returns aggregate counts, profile/phase breakdowns, timing extremes, contact-speed flags, and Feint flags. Live unit ownership, action arrays, geometry, contact, VFX/SFX, and battle mutation remain in `main.gd` / `Fighter`.
- `tools/battle_runtime_action_telemetry_service_contract_probe.gd` guards service purity, wrapper delegation, and a live `Fighter` aggregation smoke path. Focused verification passed with `battle_runtime_frame_budget_probe` at `avg_ms=1.793`, `max_ms=2.431`.
- The telemetry seam now feeds a developer-only battle action diagnostics overlay:
- `BattleRuntimeActionTelemetryService.battle_action_diagnostics_model()` turns the aggregate snapshot into stable display rows, counts, flags, and malformed-row warnings without reading Nodes, input, files, time, or battle state.
- `BattleActionDiagnosticsView` -> `scripts/views/battle_action_diagnostics_view.gd`
- `main.gd` owns the overlay switch and wrappers: `_set_battle_action_diagnostics_overlay_enabled()`, `_battle_action_diagnostics_overlay_text()`, `_update_battle_action_diagnostics_overlay()`, and `_battle_action_diagnostics_model()`. The overlay defaults hidden, is not persisted, and is not bound to player settings or hotkeys.
- `tools/battle_action_diagnostics_overlay_probe.gd` guards the view/wrapper path, and `tools/battle_runtime_action_telemetry_service_contract_probe.gd` now covers diagnostics sorting, empty models, Feint/contact-speed flags, and malformed active rows.
- The diagnostics overlay has been enriched as a read-only EC-SLIM-006 follow-up. `FighterActionModel.runtime_action_summary()` now exposes existing action facts for attack identity, target nodes, timing/pose scalars, variant/command labels, contact/joint speeds, hit-confirm state, Soul Echo, Combo Balance, contact-damage, and whiff-recovery diagnostics.
- `BattleRuntimeActionTelemetryService.battle_action_diagnostics_model()` now carries those fields into action rows and adds warnings for non-dictionary actions, active units without displayable actions, empty profiles, empty/invalid target nodes, non-positive duration, timer overrun, and phase/timer mismatch. The service still only consumes dictionaries, arrays, scalars, and options.
- `BattleActionDiagnosticsView.text()` remains a text-only developer view and now renders compact `key/nodes/profile/phase/pose/target/variant/cmd/speed/hit/soul/combo` action rows.
- The overlay now also carries diagnostics-only module gate state. `FighterActionModel.runtime_gate_diagnostics()` classifies current readiness from scalar context, `Fighter.runtime_action_telemetry_snapshot()` contributes bounded read-only gate facts, and the battle aggregate reports gate reason counts plus cancel-ready/cooldown-blocked unit counts. This does not call `_module_action_gate()`, does not call `_ensure_limb_index()`, and does not write meta or change cancel state.
- The overlay now also carries diagnostics-only AI/module command context. `BattleActorCommandService.command_diagnostics()` normalizes existing stats/meta facts for AI kind, source condition/move, fire timer, sequence, movement mode, and role-switch configuration; `main.gd` owns the live-unit snapshot helper and does not rerun puppet intent selection, module execution, gate checks, or command buffers for diagnosis.
- Latest verification passed: `fighter_action_model_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe`, `fighter_action_telemetry_probe`, `battle_action_diagnostics_overlay_probe`, `crush_windup_whiff_recovery_probe`, `soul_echo_runtime_probe`, `main_controller_boundary_probe`, `battle_runtime_frame_budget_probe` (`avg_ms=1.385`, `max_ms=3.086`), `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `view_extraction_contract_probe`, and `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120`. `git diff --check` only reported the existing `scripts/fighter.gd` CRLF normalization warning.

Catalog/data-rule clarification:

- Electronic shield payloads now have the intended internal torso slot volume contract documented and guarded: no part HP, no combat geometry, no runtime combat volume, but positive derived slot volume from shield pool/coverage/mass.
- `_part_slot_volume_rank()` checks `shield_payload` / `electronic_armor` before generic display `size_tier`, so normalized art/card sizing cannot override the shield slot-volume formula.
- Booster catalog v3 fields `allocated_momentum` and `brake_efficiency` are preserved during catalog legacy-field cleanup while saved-payload legacy rejection remains unchanged.
- `tools/shield_probe.gd` and `tools/shield_payload_slot_volume_probe.gd` guard this split between internal slot volume and battle collision volume.

2026-06-08 continuation:

- Added the narrow diagnostics-only projectile/targeting signal planned by the previous safe chunk.
- `main.gd` now samples pending laser, true-bullet, chemical, and missile queues through `_battle_projectile_target_diagnostics_unit_snapshot()` and passes only plain read-only facts into battle action telemetry.
- `BattleRuntimeActionTelemetryService` now aggregates projectile behavior counts, target-role counts, pending projectile count, locked-target count, projectile-signal unit count, and targeted-unit count without reading Nodes, input, files, time, active-unit arrays, or pending projectile arrays.
- `BattleActionDiagnosticsView` renders the new projectile summary and per-unit projectile rows inside the existing developer-only action diagnostics overlay.
- `main_controller_boundary_probe` exposed a remaining `_handle_editor_board_input()` event-type branch; the handler now delegates mouse-position memory to `_remember_editor_board_event_position()` so the handler body remains controller-only.
- Follow-up architecture tightening: `BattleRuntimeActionTelemetryService.projectile_target_diagnostics()` now owns the pure per-unit projectile/target diagnostic aggregation.
- `main.gd` now only materializes pending projectile queue facts through `_battle_projectile_target_diagnostics_facts()`: attacker id, target id, target live/role, sanitized projectile behavior/style, and fallback behavior. Projectile resolution, target acquisition, damage, queue mutation, and live Node ownership stay in `main.gd` / existing runtime services.
- `tools/battle_runtime_action_telemetry_service_contract_probe.gd` now guards the pure aggregation API, behavior fallback order, target-role counts, incoming/locked counts, scalar fact preservation, and the service's no-pending-queue dependency boundary.
- `tools/battle_runtime_frame_budget_probe.gd` now stays self-contained when local Godot user data does not have a saved Unit2 fixture: it still prefers saved unit `2`, but falls back to the same generated training starter used by the runtime training-entry path.
- `tools/training_import_spawn_role_probe.gd` now uses self-contained legal minimal hero, puppet, and barrier fixtures instead of local saved Unit2 / AI roster state. Its failures are accumulated and used for the final exit code, so invalid fixture or spawn assertions can no longer be hidden by a later `ok` print.
- `tools/probe_exit_status_contract_probe.gd` now guards the current architecture verification chain against probe false positives caused by `quit(1)` being overwritten by a later success `quit(0)`.
- The guarded probes currently include `battle_runtime_action_telemetry_service_contract_probe`, `battle_action_diagnostics_overlay_probe`, `training_import_spawn_role_probe`, `battle_runtime_frame_budget_probe`, `battle_real_training_movement_screen_direction_probe`, and `gun_activation_service_contract_probe`.
- `tools/battle_real_training_movement_screen_direction_probe.gd` now accumulates movement-vector assertion failures before the final success exit, so a failed input case cannot be hidden by the loop's final `ok` print.
- `GunActivationService` -> `scripts/services/gun_activation_service.gd`
- `main.gd` now delegates pure gun activation rules for aim-input mode normalization, activation spec lookup, gun-drive aim-speed scaling, turn-key aim rotation, and initial activation-state payload construction to the service.
- Follow-up binding classification tightening: `GunActivationService` now also owns runtime binding profile extraction, projectile-profile activation classification, and binding-level gun aim-input mode merging. `main.gd` keeps the wrapper names but only supplies the current projectile profile list from `ActionProfileRegistry`.
- Follow-up profile compatibility tightening: `GunActivationService` now owns the pure profile/gun-kind/ammo-kind compatibility decision once `main.gd` has supplied the `ActionProfileRegistry` support result and resolved activation spec. `main.gd` still owns registry lookup and generic-profile resolution.
- Follow-up mobility tightening: `GunActivationService` now filters binding mobility contracts by projectile activation profile and owns the pure direction-boost allowance rule that prefers active state flags over binding mobility contracts. `main.gd` still owns active state lookup and `ActionProfileRegistry` mobility-contract retrieval.
- Follow-up tick-state tightening: `GunActivationService` now owns the pure hold-release gate and tick-state payload update for active gun activation, including hold-time accumulation and the legacy aim-input-mode fallback.
- `main.gd` still owns live unit lookup, runtime gun source/group collection, aim-pose writes, command-window clearing, battle messages, input reads, target locking, projectile event patching, ammo/heat mutation, projectile queues, `_resolve_attack()`, web/missile/true-bullet release side effects, and VFX/SFX.
- `tools/gun_activation_service_contract_probe.gd` guards the service purity, binding classification/aim-mode merging, mobility filtering, direction-boost allowance, profile/gun/ammo compatibility, injected spec constants, generic `gun_activate` wrapper resolution, state-payload initialization, tick-state payloads, hold-release gating, and wrapper delegation in `main.gd`.
- Projectile drive momentum boundary tightening: `main.gd` now delegates the direct `_gun_drive_projectile_momentum_mult()` helper to `ProjectileRuntimeService.gun_drive_projectile_momentum_mult()`, matching the existing event/field sync service path and avoiding a shadow fallback rule in `main.gd`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards that the direct drive-momentum multiplier remains on `ProjectileRuntimeService` and that `main.gd` delegates this direct helper as well as event/field synchronization.
- `HeldMeleeActivationService` -> `scripts/services/held_melee_activation_service.gd`
- `main.gd` now delegates Boot Driver held-melee pure rules for runtime binding classification, input/forward-vector initial state mapping, held activation state payload construction, turn-input normalization, held-state tick payload updates, turn-key reservation, hold-release gating, and held melee event default payload fields to the service.
- Follow-up activation-direction tightening: `HeldMeleeActivationService.activation_direction()` now owns the pure startup direction choice across rotating segment direction, fallback unit forward vector, and input-vector fallback.
- `main.gd` / `Fighter` still own live unit lookup, runtime segment retrieval through `runtime_world_segment_for_node()`, `begin_runtime_module_action()`, action state writes, turn-key `Input` reads, `_battle_action_just_released()` checks, release/update calls, `BattleActionEventService` patching, `_resolve_attack()`, pose restoration, VFX/SFX, and battle messages.
- `tools/held_melee_activation_service_contract_probe.gd` guards the service purity, binding override/fallback behavior, Boot Driver `normal/active/armor` state mapping, startup direction selection, turn-input deadzone/clamp, turn-key reservation, hold-release gating, held event payload defaults, state/tick-payload duplication, and wrapper delegation in `main.gd`; it is registered in `tools/probe_manifest.json` before the Boot Driver probe group.

Verification on macOS Godot `4.6.2.stable.official.71f334935` passed:

- `battle_runtime_action_telemetry_service_contract_probe`
- `battle_action_diagnostics_overlay_probe`
- `projectile_runtime_service_contract_probe`
- `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`)
- `battle_target_acquisition_service_contract_probe`
- `battle_projectile_lifecycle_service_contract_probe`
- `main_controller_boundary_probe`
- `unit_editor_board_controller_contract_probe`
- `combat_probe`
- `ui_layout_probe`
- `text_overflow_probe`
- `--headless --check-only --quit-after 1`
- `git diff --check`

Additional focused follow-up verification passed in the sandboxed macOS run with `HOME` / `XDG_DATA_HOME` / `XDG_CACHE_HOME` pointed at `/private/tmp`:

- `probe_exit_status_contract_probe` (`guarded=7`)
- `held_melee_activation_service_contract_probe`
- `boot_driver_state_mapping_probe`
- `boot_driver_hold_steer_release_probe`
- `boot_driver_binding_probe`
- `boot_driver_melee_no_projectile_probe`
- `blunt_modules_no_projectile_probe`
- `runtime_module_entry_pose_restore_probe`
- `battle_action_event_service_contract_probe`
- `action_module_execution_matrix_probe` (`profiles=11`)
- `gun_activation_service_contract_probe`
- `gun_activation_mobility_contract_probe` (`profiles=6`)
- `gun_activate_native_semantic_dispatch_probe` (`count=7`)
- `gun_activate_rotate_command_probe`
- `gun_activation_move_while_fire_all_profiles_probe` (`count=7`)
- `gun_activation_training_move_fire_probe`
- `gun_activation_direction_boost_while_fire_probe`
- `turn_key_gun_aim_does_not_consume_movement_probe`
- `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`)
- `runtime_gun_event_source_nodes_probe`
- `gun_activation_return_to_torso_normal_probe`
- `gun_activation_local_4_6_direction_probe`
- `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`)
- `battle_action_event_service_contract_probe`
- `headed_gate_manifest_alignment_probe`
- `action_profile_registry_completeness_probe` (`live=32`, `projectile=6`)
- `battle_runtime_action_telemetry_service_contract_probe`
- `battle_action_diagnostics_overlay_probe`
- `projectile_runtime_service_contract_probe`
- `battle_target_acquisition_service_contract_probe`
- `battle_projectile_lifecycle_service_contract_probe`
- `main_controller_boundary_probe`
- `unit_editor_board_controller_contract_probe`
- `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.788`, `max_ms=2.031`)
- `battle_real_training_movement_screen_direction_probe`
- `training_config_start_probe`
- `training_saved_unit_multi_probe` (`loadout=2`)
- `training_import_spawn_role_probe`
- `combat_probe`
- `ui_layout_probe`
- `text_overflow_probe`
- `--headless --check-only --quit-after 1`
- `git diff --check`

Earlier in this follow-up, `battle_runtime_frame_budget_probe` failed before battle startup because no `user://saved_units` entry named `2` exists in the current local Godot app data. The probe has been tightened so that missing personal saved-unit fixtures no longer block runtime frame-budget verification.

Known runtime note: `ui_layout_probe`, `text_overflow_probe`, and headless check-only still print the existing Godot ObjectDB leak warning at process exit; no functional assertion failed.

2026-06-09 focused follow-up:

- `HeldMeleeActivationService.activation_direction()` now covers the Boot Driver startup direction rule without reading live unit Nodes or topology state.
- `main.gd` now materializes only the optional rotating segment dictionary, then delegates direction choice to the service before calling `begin_runtime_module_action()`.
- Fresh RED/GREEN verification for this chunk passed through `tools/held_melee_activation_service_contract_probe.gd`.
- Additional focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `boot_driver_hold_steer_release_probe`, `boot_driver_state_mapping_probe`, `boot_driver_melee_no_projectile_probe`, `battle_action_event_service_contract_probe`, `runtime_module_entry_pose_restore_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `blunt_modules_no_projectile_probe`, `probe_exit_status_contract_probe` (`guarded=7`), `probe_manifest.json` JSON parse, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.657`, `max_ms=5.498`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.

2026-06-09 gun activation follow-up:

- `GunActivationService.should_release_activation()` and `GunActivationService.tick_state_payload()` now own the pure per-frame hold gate and active-state dictionary update for gun activation.
- Follow-up continuous-fire tightening: `GunActivationService.continuous_fire_timer_intent()` now owns the pure fire-timer decrement/reset rule for hold-stream, hold-beam, hold-burst, and grenade-arc activation branches.
- `main.gd` still owns `Input`, live unit validation, aim pose writes, projectile event creation, lock acquisition, firing/release side effects, and battle messages, but no longer mutates the basic gun activation tick dictionary inline.
- `gun_activation_move_while_fire_all_profiles_probe` exposed a same-frame restart regression after the tick extraction: an active gun activation could rotate aim, then the still-fresh attack input restarted the activation and overwrote the rotated state. `_handle_player_battle_input()` now skips attack start/fire processing while `gun_activation_active` is true; release remains handled by `_tick_runtime_gun_activation()` / `_release_runtime_gun_activation()`.
- Fresh RED/GREEN verification for this chunk passed through `tools/gun_activation_service_contract_probe.gd`; the runtime regression was reproduced and then cleared by `gun_activation_move_while_fire_all_profiles_probe` (`count=7`).
- Additional focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activation_mobility_contract_probe` (`profiles=6`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activate_rotate_command_probe` (`speed=2.00`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_direction_boost_while_fire_probe`, `turn_key_gun_aim_does_not_consume_movement_probe`, `runtime_gun_event_source_nodes_probe`, `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `gun_activation_return_to_torso_normal_probe`, `gun_activation_local_4_6_direction_probe`, `probe_exit_status_contract_probe` (`guarded=7`), `probe_manifest.json` JSON parse, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.888`, `max_ms=3.690`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.

2026-06-09 gun activation continuous-fire follow-up:

- `GunActivationService.continuous_fire_timer_intent()` now returns the pure continuous-fire timer intent: whether a fire is due this frame and the next state dictionary with a decremented or reset `fire_timer`.
- `main.gd` still calls `_runtime_gun_activation_fire_once()` and still owns ammo/heat mutation, projectile event execution, aim pose writes, failure clearing, and salvo preview side effects.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`; focused runtime verification passed through `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), and `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`).
- Additional verification passed: `gun_activation_mobility_contract_probe` (`profiles=6`), `gun_activate_rotate_command_probe` (`speed=2.00`), `gun_activation_direction_boost_while_fire_probe`, `turn_key_gun_aim_does_not_consume_movement_probe`, `runtime_gun_event_source_nodes_probe`, `probe_exit_status_contract_probe` (`guarded=7`), `probe_manifest.json` JSON parse, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.912`, `max_ms=6.815`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.

2026-06-09 gun activation release-route follow-up:

- `GunActivationService.release_route_intent()` now owns the pure release-route decision for empty release events, explosive arc salvo release, web tether release, missile-lock release, true-bullet release-lock, and generic cleanup.
- `main.gd` still owns live target checks, missile/true-bullet target acquisition, direction calculation, firing, queueing, aim pose clearing, no-lock messaging, and all projectile side effects.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`; focused release/runtime verification passed through `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), and `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`).
- Additional verification passed: `runtime_gun_event_source_nodes_probe`, `gun_activation_mobility_contract_probe` (`profiles=6`), `gun_activation_direction_boost_while_fire_probe`, `gun_activation_return_to_torso_normal_probe`, `turn_key_gun_aim_does_not_consume_movement_probe`, `probe_exit_status_contract_probe` (`guarded=7`), `probe_manifest.json` JSON parse, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.818`, `max_ms=3.607`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.

2026-06-09 gun activation release-lock patch follow-up:

- `GunActivationService.release_lock_event_patch()` now owns the pure lock-release event patch for missile-lock and true-bullet release routes: aim-lock flag, normalized release direction, and true-bullet lock time fallback.
- `main.gd` still owns live target validation, missile/true-bullet target acquisition, direction calculation inputs, no-lock messaging, `_runtime_gun_activation_fire_once()`, `_queue_true_bullet_lock()`, and aim-pose cleanup.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused release/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_lock_runtime_fire_probe`, `missile_no_sniper_lock_probe`, `projectile_runtime_service_contract_probe`, `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `sniper_delayed_fire_realign_probe`, `sniper_edge_target_lock_probe` (`distance=0.56`), `sniper_hit_vfx_on_target_probe` (`effects=2`), and `sniper_first_obstruction_probe`.

2026-06-09 gun activation tick-route follow-up:

- `GunActivationService.tick_route_intent()` now owns the pure per-frame semantic route for empty events, explosive-arc salvo preview, continuous-fire hold routes, web aim-hold, missile-lock tracking, true-bullet target tracking, and unknown-semantic cleanup.
- `main.gd` still owns live unit validation, pose writes, target acquisition, preview VFX, firing, target/direction state writes, and active-state clearing, but consumes the service route instead of branching directly on activation semantic strings.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `missile_lock_runtime_fire_probe`, and `sniper_edge_target_lock_probe` (`distance=0.56`).

2026-06-09 gun activation aim-pose payload follow-up:

- `GunActivationService.aim_pose_payload()` now owns the pure event-to-aim-pose payload rule for gun activation ticks: source node fallback order, direction fallback, and direction normalization.
- `main.gd` now uses `_set_runtime_gun_activation_aim_pose()` for the repeated held gun activation pose refresh calls; live Node validation and `set_aim_pose()` remain in `main.gd`.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `missile_lock_runtime_fire_probe`, and `sniper_edge_target_lock_probe` (`distance=0.56`).

2026-06-09 gun activation direction follow-up:

- `GunActivationService.activation_direction()` now owns the pure segment-to-direction rule for runtime gun activation: normalized `b - a`, fallback unit-forward direction, and stable right-vector fallback for empty/degenerate inputs.
- `main.gd` still owns live unit validation and `_runtime_gun_segment_for_binding()`; `_runtime_gun_activation_direction()` now delegates only after materializing the segment dictionary.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activation_local_4_6_direction_probe`, `gun_activation_turn_keys_steer_muzzle_probe` (`delta=0.7055`), `gun_activate_rotate_command_probe` (`speed=2.00`), `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), and `gun_activation_move_while_fire_all_profiles_probe` (`count=7`).

2026-06-09 gun activation source-payload follow-up:

- `GunActivationService.runtime_gun_source_payload()` now owns the pure runtime gun source dictionary rule after `main.gd` has already materialized the live segment/group: gun-source classification, source node fields, duplicated target nodes, duplicated segment/group payloads, muzzle combat position, and muzzle direction fallback.
- `main.gd` still owns live unit validation, target-node lookup, `runtime_world_segment_for_node()`, and `runtime_group_for_node()`; `_runtime_gun_source_for_binding()` now delegates only after those live facts have been read.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activation_turn_keys_steer_muzzle_probe` (`delta=0.7055`), `gun_activation_local_4_6_direction_probe`, `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), and `missile_lock_runtime_fire_probe`.

2026-06-09 gun activation group-payload follow-up:

- `GunActivationService.runtime_gun_group_payload()` now owns the pure runtime gun group dictionary normalization after `main.gd` has materialized source group and drive facts: drive allocation fields, projectile/projectile-only flags, gun material fallback, and shape fallback.
- `main.gd` still owns live unit validation, source lookup, drive-info materialization, `_gun_projectile_damage_mult_max_for_data()`, and `_gun_projectile_damage_mult_for_event()` so projectile damage service/data-rule ownership remains unchanged.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), and `projectile_runtime_service_contract_probe`.

2026-06-09 gun activation event-options follow-up:

- `GunActivationService.activation_event_options_payload()` now owns the pure `_true_bullet_event_for_aim()` base-event options payload for runtime gun activation: duplicated runtime target nodes, source node identity, muzzle combat facts, attack key, module/effective profile labels, and gun/ammo metadata.
- `main.gd` still owns live unit validation, source/group materialization, aim-pose writes, `_true_bullet_event_for_aim()`, module variant field copying, `BattleActionEventService.gun_activation_event_patch()`, projectile drive momentum synchronization, target acquisition, firing, queue mutation, and damage-side effects.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `missile_lock_runtime_fire_probe`, `projectile_runtime_service_contract_probe`, `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `sniper_edge_target_lock_probe` (`distance=0.56`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.910`, `max_ms=2.407`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, and `git diff --check`.

2026-06-09 gun activation event-direction follow-up:

- `GunActivationService.activation_event_direction()` now owns the pure runtime gun activation event direction choice: active aim direction first, materialized binding/muzzle direction second, unit forward fallback, then a stable right vector.
- `main.gd` still owns live unit validation, `_runtime_gun_activation_direction()` materialization, unit forward lookup, aim-pose writes, event creation, target acquisition, firing, and projectile side effects.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activation_local_4_6_direction_probe`, `gun_activation_turn_keys_steer_muzzle_probe` (`delta=0.7055`), `gun_activate_rotate_command_probe` (`speed=2.00`), `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), and `--headless --check-only --quit-after 1`.

2026-06-09 gun activation fire-ammo gate follow-up:

- `GunActivationService.fire_ammo_gate()` now owns the pure runtime gun activation pre-fire ammo gate: empty ammo kind and zero capacity are non-gated, positive capacity with zero current ammo blocks firing, and scalar ammo facts are normalized/clamped for diagnostics.
- `main.gd` still owns live unit ammo reads, AMMO EMPTY messaging, `_resolve_attack()`, heat events, ammo consumption side effects, and all projectile runtime mutation.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_ammo_heat_probe` (`ammo=2`, `heat=34.0`), `missile_lock_runtime_fire_probe`, `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `projectile_runtime_service_contract_probe`, `--headless --check-only --quit-after 1`, and `combat_probe`.

2026-06-09 gun activation rotate-speed follow-up:

- `GunActivationService.activation_rotate_speed()` now owns the pure startup aim-rotation speed rule: explicit module `gun_rotate_speed` when positive, default unit turn speed fallback otherwise, then the gun-drive aim-speed multiplier.
- `main.gd` still owns live unit validation, group/source materialization, `_unit2_turn_speed_reference()`, active-state writes, command-window clearing, and startup messaging.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: after fixing the probe's typed local variables, the probe failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_activate_rotate_command_probe` (`speed=2.00`), `gun_activation_turn_keys_steer_muzzle_probe` (`delta=0.7055`), `gun_activation_direction_boost_while_fire_probe` (`heat=6.0`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.071`, `max_ms=3.840`), and `--headless --check-only --quit-after 1`.

2026-06-09 gun activation source-gate follow-up:

- `GunActivationService.activation_source_gate()` now owns the pure startup source gate after `main.gd` has materialized the runtime gun segment: missing source, non-ranged terminal, and ranged non-projectile terminal are rejected with stable reason strings; ranged projectile terminals pass.
- `main.gd` still owns live unit validation, runtime segment lookup, fail SFX, battle message text, group/source materialization, profile/spec checks, state writes, and startup messaging.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_activate_rotate_command_probe` (`speed=2.00`), and `--headless --check-only --quit-after 1`.

2026-06-09 gun activation profile-gate follow-up:

- `GunActivationService.activation_profile_gate()` now owns the pure effective-profile/spec/support gate for runtime gun activation: empty effective profile, empty spec, and registry-unsupported profiles are rejected with stable reason strings; valid effective profile/spec/support triples pass.
- `main.gd` still owns `ActionProfileRegistry` lookups, `_gun_activation_spec()` materialization, user-facing unsupported-gun messages, event construction, state writes, and all runtime side effects.
- `_runtime_gun_activation_event_for()` now uses the same pure gate with an already-materialized effective profile/spec, while `_start_runtime_gun_activation()` passes the registry-supported boolean from `_gun_activation_profile_supports_kind()`.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `projectile_runtime_service_contract_probe`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.068`, `max_ms=4.508`), and `--headless --check-only --quit-after 1`.

2026-06-09 gun activation event-source identity follow-up:

- `GunActivationService.activation_event_source_identity()` now owns the pure runtime gun activation event source identity rule: binding target nodes choose the initial source node, `attack_key - 1` is the fallback, and a materialized `gun_source` can override runtime target nodes and source node identity.
- `main.gd` still owns live unit validation, aim-pose writes, `_runtime_gun_source_for_binding()`, `_true_bullet_event_for_aim()`, action-event patching, projectile drive sync, target acquisition, firing, and queue mutation.
- Fresh RED/GREEN verification passed through `tools/gun_activation_service_contract_probe.gd`: the probe first failed on the missing service method and missing `main.gd` delegation token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_gun_event_source_nodes_probe` (`node=2`), `gun_module_binding_matrix_probe` (`generic=7`, `specialist=5`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_clear_aim_pose_all_semantics_probe` (`cases=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `missile_lock_runtime_fire_probe`, `projectile_runtime_service_contract_probe`, and `--headless --check-only --quit-after 1`.

2026-06-09 activation-state boundary follow-up:

- `GunActivationService.activation_state_active()` and `HeldMeleeActivationService.activation_state_active()` now own the pure active-state predicate for runtime activation dictionaries.
- `main.gd` still owns player-id lookup and state-table storage, but `_runtime_gun_activation_active()` and `_runtime_held_melee_activation_active()` now delegate the non-empty-state rule to their services.
- Fresh RED/GREEN verification passed through `tools/held_melee_activation_service_contract_probe.gd` and `tools/gun_activation_service_contract_probe.gd`: both probes first failed on the missing service method/main delegation token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `boot_driver_state_mapping_probe`, `boot_driver_hold_steer_release_probe`, `boot_driver_melee_no_projectile_probe`, `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `projectile_runtime_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `battle_action_diagnostics_overlay_probe` (`text_lines=17`), `probe_exit_status_contract_probe` (`guarded=7`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.058`, `max_ms=4.723`), `battle_action_event_service_contract_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `gun_activate_native_semantic_dispatch_probe` (`count=7`), `--headless --check-only --quit-after 1`, `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window state boundary follow-up:

- `BattleActionEventService.command_window_state_for_input()` now owns the pure 4/6 direction-to-state rule: forward input maps to `armor`, backward input maps to `active`, neutral/side/missing-forward inputs map to an empty state.
- `BattleActionEventService.command_window_state_for_binding()` now owns the pure binding-profile gate for command-window state resolution after `main.gd` has materialized the unit forward vector.
- `main.gd` still owns command buffers, window dictionaries, `Input`/`Time`, live-unit lookup, command-text matching, runtime command variants, attack start, messages, and `_resolve_attack()`, while `_attack_window_state_from_direction()` and `_attack_window_state_for_binding()` now delegate the 4/6 state rule to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on missing service tokens, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `blade_simple_command_probe`, `blade_complex_command_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `boot_driver_hold_steer_release_probe`, `gun_activate_native_semantic_dispatch_probe` (`count=7`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.293`, `max_ms=23.983`), `--headless --check-only --quit-after 1`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window tick boundary follow-up:

- `BattleActionEventService.command_window_tick_intent()` now owns the pure attack-window tick rule: timer decrement, hold-time accumulation/reset, hold-cancel routing, expiration routing, and timer fallback.
- `main.gd` still owns the command-window map, `Input.is_action_pressed()`, attack action naming, cancel messages, and window insertion/removal, but `_tick_attack_command_windows()` now consumes the service intent instead of mutating timer/hold fields inline.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `blade_simple_command_probe`, `blade_complex_command_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `boot_driver_hold_steer_release_probe`, `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.586`, `max_ms=17.902`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window text-state boundary follow-up:

- `BattleActionEventService.command_window_text_state()` now owns the pure command-text-to-state rule for simple blade, complex blade, gauntlet, and blunt command-window profiles, including relaxed `236`/`26` and `214`/`24` suffix matching.
- `main.gd` still owns command buffers, `_command_text()`, command consumption, runtime command variants, latest direction fallback, unit forward vectors, attack start, and messages, but `_blade_command_text_state()` and `_gauntlet_command_text_state()` now delegate text-state classification to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `blade_simple_command_probe`, `blade_complex_command_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `boot_driver_hold_steer_release_probe`, `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.276`, `max_ms=9.234`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window blade-variant boundary follow-up:

- `BattleActionEventService.command_window_blade_variant()` now owns the pure blade command variant rule for `blade_simple_4_6` and `blade_complex_236_214`: text-state or explicit `action_state` routes to armor/active variants, with `normal_sweep` as the fallback.
- `main.gd` still owns binding profile lookup, command-buffer text materialization, runtime binding mutation, attack start, and non-blade command variants; `_blade_command_variant_for_binding()` now delegates blade variant selection to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `blade_simple_command_probe`, `blade_complex_command_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=2.209`, `max_ms=9.046`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window gauntlet-variant boundary follow-up:

- `BattleActionEventService.command_window_gauntlet_variant()` now owns the pure gauntlet command variant rule: command text or explicit `action_state` routes armor/active variants; input/latest direction relative to the materialized forward vector routes normal inward/outward swings; missing or side input falls back to `normal_extend`.
- `main.gd` still owns binding profile lookup, command-buffer text materialization, latest-direction lookup, unit-forward materialization, runtime binding mutation, attack start, and non-gauntlet command variants; `_gauntlet_command_variant_for_binding()` now delegates gauntlet variant selection to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.517`, `max_ms=19.112`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window blunt-variant boundary follow-up:

- `BattleActionEventService.command_window_blunt_variant()` now owns the pure shield/hammer blunt terminal command variant rule: command text or explicit `action_state` routes armor/active variants; input/latest direction relative to the materialized forward vector routes normal forward/back variants; neutral, side, or missing-forward facts fall back to the profile's normal default.
- `main.gd` still owns module-action profile lookup, command-buffer text materialization, latest-direction lookup, unit-forward materialization, runtime binding mutation, attack start, and non-blunt command variants; `_blunt_terminal_command_variant_for_binding()` now delegates shield/hammer variant selection to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Focused blunt runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `blunt_modules_no_projectile_probe`, `blunt_terminal_runtime_pose_probe`, `shield_guard_bash_runtime_pose_probe`, `hammer_windup_slam_runtime_pose_probe`, `shield_guard_bash_contact_probe`, and `hammer_windup_slam_contact_probe`.
- Additional regression verification passed: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.787`, `max_ms=0.961`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window buffer-clear boundary follow-up:

- `BattleActionEventService.command_window_should_clear_buffer()` now owns the pure command-buffer clear predicate: `active`/`armor` action states always clear, and normal-state clearing is gated by a materialized command-profile allowlist.
- `main.gd` still owns the command buffer table, module profile constants, command-profile allowlist materialization, runtime attack start, and actual `command_buffers[player_id] = []` side effect; `_hero_runtime_module_attack()` now delegates only the clear/no-clear decision to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `blunt_terminal_runtime_pose_probe`, `blunt_modules_no_projectile_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.772`, `max_ms=0.991`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window runtime-state boundary follow-up:

- `BattleActionEventService.command_window_runtime_state()` now owns the pure runtime module state selection rule: materialized runtime profile groups choose the gauntlet, blunt, or blade command-text parser; non-empty text state overrides fallback state; unsupported profiles preserve the fallback.
- `main.gd` still owns command-buffer storage, `_command_text()` materialization, binding/module profile lookup, module profile constants, runtime attack start, variant mutation, and all side effects; `_runtime_module_state_for_binding()` now delegates only the profile/text/fallback state decision to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `blunt_terminal_runtime_pose_probe`, `blunt_modules_no_projectile_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.763`, `max_ms=0.952`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window resolve-all boundary follow-up:

- `BattleActionEventService.command_window_resolve_all_intent()` now owns the pure resolve-all window plan: skip entries with empty states, sort resolved entries by `attack_index`, and return the ordered attack entries plus the window keys that should be closed.
- `main.gd` still owns live hero validation, window table access, per-window binding materialization, direction-to-state calculation, actual window erasure, action cooldown reset, and runtime attack triggering; `_resolve_all_attack_command_windows()` now delegates only the resolved-entry filtering/sorting/close-key plan to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `blunt_terminal_runtime_pose_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.748`, `max_ms=0.866`), `ui_layout_probe`, `text_overflow_probe`, `gun_activation_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 command-window runtime-variant boundary follow-up:

- `BattleActionEventService.command_window_runtime_variant()` now owns the pure runtime command variant selection rule: materialized runtime profile groups choose gauntlet, blunt, or blade variant helpers, while unsupported profiles return an empty variant.
- `main.gd` still owns command-buffer storage, `_command_text()` materialization, latest-direction lookup, unit-forward materialization, runtime profile allowlist materialization, runtime binding mutation, attack start, and all side effects; `_hero_runtime_module_attack()` now delegates only the variant-choice rule to the service.
- Command-window runtime probes now assert through `command_window_runtime_variant()` instead of removed `main.gd` helper APIs, keeping probe coverage aligned with the new service boundary.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service token, then passed after the service/main update.
- Runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `blunt_terminal_runtime_pose_probe`, `blunt_modules_no_projectile_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.292`, `max_ms=14.190`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `held_melee_activation_service_contract_probe`, `gun_activation_service_contract_probe`, `projectile_runtime_service_contract_probe`, `battle_runtime_action_telemetry_service_contract_probe` (`actions=1`), `battle_action_diagnostics_overlay_probe` (`text_lines=17`), `training_import_spawn_role_probe`, `battle_real_training_movement_screen_direction_probe`, `probe_exit_status_contract_probe` (`guarded=7`), `probe_manifest.json` JSON parse, no residual removed command-variant helper calls in `scripts/main.gd` / `tools/*.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 runtime attack-button route boundary follow-up:

- `BattleActionEventService.runtime_attack_button_intent()` now owns the pure direct-runtime attack-button route after `main.gd` has materialized scalar facts: non-direct units fall through to legacy attack, gun activation takes priority, held melee activation follows, matching open command windows resolve, empty bindings fail, and valid direct-runtime bindings open command windows.
- `main.gd` still owns live hero lookup, runtime binding materialization, gun/held-melee binding classification, command-window table reads/writes, input names, SFX/messages, activation startup, command-window open/resolve, legacy group attack, and all attack side effects; `_start_or_fire_attack_button()` now consumes only the service route intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service method/token, then passed after the service/main update.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `gun_activation_service_contract_probe`, `held_melee_activation_service_contract_probe`, `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_training_move_fire_probe` (`moved=0.293`, `ammo=30->27`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `boot_driver_hold_steer_release_probe`, and `boot_driver_state_mapping_probe`.
- Additional regression verification passed: `blunt_terminal_runtime_pose_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.242`, `max_ms=6.491`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, `runtime_attack_button_intent` delegation token search, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-buffer record boundary follow-up:

- `BattleActionEventService.command_buffer_record_intent()` now owns the pure command-buffer record rule after `main.gd` has materialized direction just-pressed booleans: timer decay, timeout clearing, canonical direction-token append order (`2`, `6`, `4`, `8`), timer reset on input, and latest-eight-token trimming.
- `main.gd` still owns `Input` edge reads, player command-buffer/timer storage, direction-tap routing, command-window resolution, command matching/consumption, and all attack side effects; `_record_command_input()` now only gathers input facts and writes back the service intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing service method/token, then passed after the service/main update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `gun_activate_native_semantic_dispatch_probe` (`count=7`), `gun_activation_move_while_fire_all_profiles_probe` (`count=7`), `boot_driver_hold_steer_release_probe`, and `battle_real_training_movement_screen_direction_probe`.
- Additional regression verification passed: `combat_probe`, `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.297`, `max_ms=6.353`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, `command_buffer_record_intent` delegation token search, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-match boundary follow-up:

- `BattleActionEventService.command_match_intent()` now owns pure command suffix/alias matching for exact commands plus relaxed aliases (`236`/`26`, `214`/`24`, and `632146`/`6246`), returning both the match result and clear-buffer intent.
- `main.gd` still owns `_command_text()`, `command_buffers`, actual buffer clearing, command skill/trap/module side effects, and all `Input`/runtime ownership; `_command_matches()` now only delegates the matching rule and clears the live buffer after a matched intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `command_match_intent` token, then passed after the service/main update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `battle_field_runtime_service_contract_probe`, `main_controller_boundary_probe`, and `combat_probe`.
- Additional regression verification passed: `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.862`, `max_ms=2.120`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 attack-direction boundary follow-up:

- `BattleActionEventService.attack_direction()`, `attack_direction_for_group()`, and `paired_attack_direction()` now own the pure attack direction rules after `main.gd` has materialized unit forward vectors: strong input override, forward fallback, lane-bias steering, and paired inward-clamp mirroring.
- `main.gd` still owns live unit validation, `_unit_forward_vector()` materialization, aim/attack state writes, recoil, event construction, target/projectile/damage side effects, and recursive paired attack dispatch; `_attack_direction()`, `_attack_direction_for_group()`, and `_paired_attack_direction()` now only pass plain vector/group facts into the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: after fixing probe-local Vector2 typing, the probe failed on missing service/main delegation tokens, then passed after the service/main update.
- Focused attack/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `combat_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `projectile_runtime_service_contract_probe`, `blunt_terminal_runtime_pose_probe`, `shield_guard_bash_contact_probe`, `hammer_windup_slam_contact_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, and `blade_complex_command_probe`.
- Additional regression verification passed: `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.961`, `max_ms=4.696`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 attack-state boundary follow-up:

- `BattleActionEventService.facing_relative_attack_state()`, `two_link_forward_snap_attack_state()`, and `attack_state_for_group()` now own the pure direction-to-attack-state rules after `main.gd` has materialized current input, latest command direction, unit forward vector, module profile, and fallback state.
- `main.gd` still owns command buffer storage, `_latest_command_direction()`, live-unit/owner lookup, `_unit_forward_vector()`, actual command buffer clearing, attack start routing, aim state writes, and all runtime side effects; `_facing_relative_attack_state()`, `_two_link_forward_snap_attack_state()`, and `_attack_state_for_group()` now only delegate state classification.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on missing service/main delegation tokens, then passed after the service/main update.
- Focused attack-state/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `two_link_forward_snap_module_probe` (`module=76`), `two_link_forward_snap_combat_pose_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe`, `battle_real_training_movement_screen_direction_probe` (exit code 0), `gauntlet_command_window_probe`, `blade_simple_command_probe`, and `blade_complex_command_probe`.
- Additional regression verification passed: `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.399`, `max_ms=7.326`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-direction boundary follow-up:

- `BattleActionEventService.command_token_vector()` and `latest_command_direction()` now own the pure command token-to-vector and latest-direction scan rules for the command buffer.
- `main.gd` still owns the `command_buffers` table, player-id lookup, command record/consume side effects, attack routing, and all runtime ownership; `_absolute_command_vector()` and `_latest_command_direction()` now only delegate pure token/buffer classification to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `command_token_vector` service token, then passed after the service/main update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `two_link_forward_snap_module_probe` (`module=76`), `two_link_forward_snap_combat_pose_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, and `combat_probe`.
- Additional regression verification passed: `action_module_execution_matrix_probe` (`profiles=11`), `battle_real_training_movement_screen_direction_probe` (exit code 0), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.675`, `max_ms=9.282`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-text boundary follow-up:

- `BattleActionEventService.command_text()` now owns the pure command buffer-to-text materialization rule, including stable string conversion for non-string token values.
- `main.gd` still owns the `command_buffers` table, player-id lookup, command record/consume side effects, command matching side effects, command window routing, and all runtime ownership; `_command_text()` now only delegates buffer text materialization to the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `command_text` service token, then exposed the `String(2)` conversion issue in the new mixed-token assertion, and finally passed after `BattleActionEventService.command_text()` used `str(token)`.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `two_link_forward_snap_module_probe` (`module=76`), `combat_probe`, and `action_module_execution_matrix_probe` (`profiles=11`).
- Additional regression verification passed: `battle_real_training_movement_screen_direction_probe` (exit code 0), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.593`, `max_ms=10.733`), `ui_layout_probe` (`hard=0` for zh/en scanned views), `text_overflow_probe` (`count=0` for zh/en scanned views), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 melee-command intent boundary follow-up:

- `BattleActionEventService.melee_command_attack_intent()` and `consume_melee_state_intent()` now own the pure melee command state/clear-buffer intent after `main.gd` has materialized input vector, latest command direction, and unit forward vector.
- `main.gd` still owns live hero lookup, `command_buffers`, player-id routing, and actual buffer mutation; `_melee_command_attack_kind()` and `_consume_melee_state_command()` now only consume the service intent and apply the requested buffer clear when appropriate.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `melee_command_attack_intent` service token, then passed after the service/main delegation update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `two_link_forward_snap_module_probe` (`module=76`), `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_real_training_movement_screen_direction_probe` (exit code 0), and `held_melee_activation_service_contract_probe`.
- Additional regression verification passed: `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.315`, `max_ms=5.250`), `ui_layout_probe` (exit code 0), `text_overflow_probe` (exit code 0), `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 stale battle-action helper cleanup:

- Removed stale `main.gd` pass-through helpers that no longer had call sites after the service boundary extractions: `_absolute_command_vector()`, `_facing_relative_attack_state()`, `_two_link_forward_snap_attack_state()`, and `_text_matches_any()`.
- `tools/battle_action_event_service_contract_probe.gd` now guards against these helper definitions returning to `main.gd`; the service-level APIs and behavior assertions remain on `BattleActionEventService`.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on `func _absolute_command_vector(` still existing in `main.gd`, then passed after the stale helpers were removed.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_complex_command_probe`, `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `action_module_execution_matrix_probe` (`profiles=11`), `--headless --check-only --quit-after 1`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.110`, `max_ms=8.087`).
- Additional static verification passed: no stale helper definitions found in `scripts/main.gd`, `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 recoil-counter boundary and probe-exit guard follow-up:

- `BattleActionEventService.recoil_countered()` now owns the pure recoil counter rule after `main.gd` has materialized boost momentum, held input vector, and attack direction.
- `main.gd` still owns live hero lookup, `active_units`, `Input` vector collection, recoil application, module event mutation, and battle side effects; `_is_recoil_countered()` now only passes scalar/vector facts into the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `recoil_countered` service token, then exposed a hidden probe-exit weakness when an assertion error was followed by a later success `quit(0)`.
- `tools/battle_action_event_service_contract_probe.gd` now aggregates failures before printing success, and `tools/probe_exit_status_contract_probe.gd` now guards it alongside the other failure-aggregation probes (`guarded=8`).
- The incorrect strict-threshold assertion was corrected from a normalized full-left vector to a mixed vector whose normalized dot product stays below the counter threshold.
- Focused runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `probe_exit_status_contract_probe` (`guarded=8`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `action_module_execution_matrix_probe` (`profiles=11`), `--headless --check-only --quit-after 1`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.191`, `max_ms=4.028`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-window binding-profile boundary follow-up:

- `BattleActionEventService.command_window_binding_profile()` now owns the pure runtime binding profile normalization for command-window module action profile and command-window profile fallback.
- `main.gd` still owns runtime binding lookup, command text, latest command direction, unit forward vector, command buffer mutation, `begin_runtime_module_action()`, event patching, recoil, VFX/SFX, and attack resolution; `_runtime_module_state_for_binding()` and `_hero_runtime_module_attack()` now consume the service profile payload instead of repeating nested `module_part` fallback logic.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `command_window_binding_profile` service token, then passed after the service/main delegation update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_complex_command_probe`, `blade_simple_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `probe_exit_status_contract_probe` (`guarded=8`), `--headless --check-only --quit-after 1`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.742`, `max_ms=0.954`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `command_window_binding_profile` token search, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 runtime-module direction boundary follow-up:

- `BattleActionEventService.runtime_module_direction()` now owns the pure direct-runtime module direction choice: strong input vector at the existing `0.18` threshold, otherwise normalized unit-forward fallback, with stable right-vector fallback for missing forward facts.
- `main.gd` still owns live hero lookup, unit-forward materialization, runtime binding mutation, `begin_runtime_module_action()`, event patching, recoil, messages, and attack resolution; `_hero_runtime_module_attack()` now delegates only the Vector2 direction choice.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `runtime_module_direction` service token, then passed after the service/main delegation update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `probe_exit_status_contract_probe` (`guarded=8`), `--headless --check-only --quit-after 1`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.348`, `max_ms=8.972`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `runtime_module_direction` token search, no residual inline `input_vector.normalized() if input_vector.length() >= 0.18` direct-runtime direction rule in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 command-skill action-kind boundary follow-up:

- `BattleActionEventService.command_skill_action_kind()` now owns the pure command-skill action-state choice from requested state, `skill_state`, and `module_state`.
- `main.gd` still owns command matching, live hero lookup, stats source, module effect routing, heat gates, module action begin, event mutation, recoil, and attack resolution; `_hero_command_skill()` only delegates the action-kind choice before beginning the unit module action.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `command_skill_action_kind` service token, then passed after the service/main delegation update.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`.
- Additional static verification passed: `command_skill_action_kind` token search in service/main/probe and no residual inline command-skill action-kind ternary in `scripts/main.gd`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning at exit, but the focused probe above returned exit code 0.

2026-06-09 normal-attack action-kind boundary follow-up:

- `BattleActionEventService.normal_attack_action_kind()` now owns the pure normal-attack requested-state normalization: `active` and `armor` pass through, while unsupported or empty requests fall back to `normal`.
- `main.gd` still owns live hero lookup, direct-runtime routing, attack-group selection, paired attack expansion, trap routing, projectile/event mutation, aim state, recoil, messages, and attack resolution; `_hero_normal_attack()` only delegates action-kind normalization before beginning the unit module action.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `normal_attack_action_kind` service token, then passed after the service/main delegation update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.779`, `max_ms=1.367`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `normal_attack_action_kind` token search, no residual inline `var action_kind := "normal"` action-kind selection in `_hero_normal_attack()`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 attack-button command-state consume boundary follow-up:

- `BattleActionEventService.attack_button_command_state_intent()` now owns the pure attack-button command-state consume route: non-`active`/`armor` states do nothing, `two_link_forward_snap` clears the command buffer directly, and other `active`/`armor` states route through the melee-state consume helper.
- `main.gd` still owns live hero lookup, input vectors, command buffer mutation, `_consume_melee_state_command()` side effects, aim state setup, attack execution, and all runtime state; `_start_or_fire_attack_button()` now only applies the service intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `attack_button_command_state_intent` service token, then passed after the service/main delegation update.
- Focused command/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `gauntlet_command_window_probe`, `blade_simple_command_probe`, `blade_complex_command_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.772`, `max_ms=1.177`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `attack_button_command_state_intent` token search, no residual inline attack-button `requested_state in ["active", "armor"]` branch in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 attack-button aim-mode boundary follow-up:

- `BattleActionEventService.attack_button_aim_mode()` now owns the pure attack-button aim-mode decision: empty fallback modes default to `fixed`, existing `fixed`/`manual`/`auto` modes pass through, and true-bullet attacks force `manual` aim.
- `main.gd` still owns live hero lookup, attack group/stat lookup, `_group_uses_true_bullet()` classification, aim-hold state mutation, lock target setup, input vectors, and attack execution; `_start_or_fire_attack_button()` now delegates only the final aim-mode selection.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `attack_button_aim_mode` service token, then passed after the service/main delegation update.
- Focused aim/projectile/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `projectile_runtime_service_contract_probe`, `direction_key_aim_policy_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.756`, `max_ms=0.949`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `attack_button_aim_mode` token search, no residual inline true-bullet aim-mode override in `_start_or_fire_attack_button()`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 hold-activation fire intent boundary follow-up:

- `BattleActionEventService.hold_activation_fire_intent()` now owns the pure hold-to-activate projectile auto-fire decision: true-bullet, non-hold, and non-projectile paths do nothing; positive timers wait with a decayed timer; expired timers request a fire and reset to the supplied interval.
- `main.gd` still owns true-bullet classification, attack group lookup, held aim state, `aim_hold_fire_timers` mutation, fire interval calculation, and `_hero_normal_attack()` execution; `_update_hold_activation_fire()` now only applies the service intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `hold_activation_fire_intent` service token, then passed after the service/main delegation update.
- Focused aim/projectile/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `projectile_runtime_service_contract_probe`, `direction_key_aim_policy_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.761`, `max_ms=0.952`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `hold_activation_fire_intent` token search, no residual inline true-bullet/hold/projectile early-return timer route in `_update_hold_activation_fire()`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 held-aim release fire boundary follow-up:

- `BattleActionEventService.held_aim_release_intent()` now owns the pure held-aim release fire decision: release-to-fire groups, non-hold actions, and true-bullet aims request a release fire, while hold-only non-true-bullet actions clear the held aim state without firing.
- `main.gd` still owns live hero lookup, locked target/direction selection, attack group lookup, `_group_uses_true_bullet()` classification, aim-state cleanup, and `_hero_normal_attack()` execution; the held-aim release branch now only applies the service intent.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `held_aim_release_intent` service token, then passed after the service/main delegation update.
- Focused aim/projectile/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `projectile_runtime_service_contract_probe`, `direction_key_aim_policy_probe`, `gauntlet_command_window_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.807`, `max_ms=1.694`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `held_aim_release_intent` token search, no residual inline `release_should_fire` expression in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 hold-activation initial-delay boundary follow-up:

- `BattleActionEventService.hold_activation_initial_delay()` now owns the pure held-aim initial timer decision: non-hold and non-projectile actions start at `0.0`, release-to-fire and true-bullet projectile actions wait at `9999.0`, and ordinary hold projectiles can fire immediately.
- `main.gd` still owns attack group lookup, `_group_uses_true_bullet()` classification, aim state mutation, `aim_hold_fire_timers` assignment, and all later held-aim update/fire side effects; `_hold_activation_initial_delay()` now only delegates the scalar facts into the service.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `hold_activation_initial_delay` service token, then passed after the service/main delegation update.
- Focused aim/projectile/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `projectile_runtime_service_contract_probe`, `direction_key_aim_policy_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.753`, `max_ms=1.009`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `hold_activation_initial_delay` token search, no residual inline release-to-fire/true-bullet initial-delay branch in `_hold_activation_initial_delay()`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 hold-activation fire-interval boundary follow-up:

- `BattleActionEventService.hold_activation_fire_interval()` now owns the pure held-aim auto-fire interval rule: explicit `fire_rate` takes precedence, explicit `fire_interval` keeps the existing minimum clamp, laser intervals use the supplied laser aim-time bounds plus the existing post-aim delay, chemical projectiles use `0.2`, bullet-hell projectiles use `0.16`, and the default remains `0.24`.
- `main.gd` still owns attack group lookup, projectile behavior classification through `_projectile_behavior_for_data()`, laser constants, aim state mutation, fire timer mutation, and `_hero_normal_attack()` execution; `_hold_activation_fire_interval()` now only materializes scalar facts and delegates the pure calculation.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `hold_activation_fire_interval` service token, then passed after the service/main delegation update.
- Focused aim/projectile/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_event_service_contract_probe`, `projectile_runtime_service_contract_probe`, `direction_key_aim_policy_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.750`, `max_ms=0.965`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `hold_activation_fire_interval` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 summon portal-index boundary follow-up:

- `BattleActorCommandService.portal_index_from_vector()` now owns the pure summon portal selection rule: weak vectors clamp to the supplied fallback, eight-way directional input maps to the existing portal index layout, and empty portal counts return a stable zero.
- `main.gd` still owns pair-summon input/button state, sortie order, active roster mutation, live role summon, portal data, messaging, and illegal feedback; `_portal_index_from_vector()` now only delegates the vector/fallback/portal-count facts into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `portal_index_from_vector` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.434`, `max_ms=10.587`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `portal_index_from_vector` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 summon pair-binding normalization boundary follow-up:

- `BattleActorCommandService.summon_pair_bindings_plan()` now owns the pure summon pair-binding normalization rule: raw array entries are preferred over defaults, invalid raw entries fall back to defaults, explicit empty raw pairs remain empty, keys clamp to the attack-key range, duplicate-key pairs are dropped, and valid pairs are sorted into a stable low/high order.
- `main.gd` still owns `summon_pair_bindings` storage, current sortie cap/default-slot constants, editor/player selection, UI summary text, and binding mutation; `_ensure_summon_pair_bindings()` now only materializes raw/default/cap facts, delegates the pure plan, and writes the fixed array back for the player.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `summon_pair_bindings_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.781`, `max_ms=1.081`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `summon_pair_bindings_plan` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 summon pair-cycle boundary follow-up:

- `BattleActorCommandService.summon_pair_cycle_intent()` now owns the pure editor summon-pair cycle decision: it finds the current pair in the default list, walks forward/backward with wraparound, skips pairs used by other sortie slots, returns updated bindings for the selected slot, and reports a no-op when no default pair is free.
- `main.gd` still owns editor/player selection, binding-slot lookup, `summon_pair_bindings` mutation, UI summary text, localization, and default-slot constants; `_cycle_current_sortie_binding()` now only materializes current facts, applies the service intent, and keeps the existing UI feedback.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `summon_pair_cycle_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.769`, `max_ms=1.083`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `summon_pair_cycle_intent` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 default summon-pair boundary and stale helper cleanup follow-up:

- `BattleActorCommandService.default_summon_pair_bindings()` now owns the pure default summon-pair binding copy rule: clamp to the current sortie cap and available default slots, duplicate each default pair array, and handle zero cap as an empty binding list.
- `main.gd` still owns current match format/sortie cap, `DEFAULT_SUMMON_PAIR_SLOTS`, `summon_pair_bindings` storage, editor/player selection, UI labels, and binding mutation; `_default_summon_pair_bindings()` now only delegates the pure default-copy plan into the actor-command service.
- Removed stale `main.gd` summon-pair helpers `_pair_key()` and `_pair_used_by_other()` after `summon_pair_cycle_intent()` took ownership of pair keying and duplicate-slot checks; `_pair_label()` remains in `main.gd` because it is UI display text.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the stale `func _pair_key(` helper still existing in `main.gd`, then failed on the missing `default_summon_pair_bindings` service token, and finally passed after the helper cleanup and service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.989`, `max_ms=2.698`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `default_summon_pair_bindings` token search confirmed service/main/probe coverage with stale helper names only in the probe guard, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 summon pair-clear boundary follow-up:

- `BattleActorCommandService.summon_pair_clear_intent()` now owns the pure editor summon-pair clear decision: duplicate the binding list, clear only the selected slot, and report a no-op for out-of-range slot indices while preserving the binding snapshot.
- `main.gd` still owns editor/player selection, binding-slot lookup, `summon_pair_bindings` storage, UI summary text, and localization; `_clear_current_sortie_binding()` now only materializes the current bindings/slot and applies the service intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `summon_pair_clear_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.815`, `max_ms=1.780`), and `probe_exit_status_contract_probe` (`guarded=8`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `summon_pair_clear_intent` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie-loadout normalization boundary and actor-probe exit guard follow-up:

- `BattleActorCommandService.sortie_loadout_plan()` now owns the pure sortie-loadout normalization rule: filter non-dictionary entries, reject roles outside the supplied role order, reject indices outside the supplied roster-size snapshot, skip duplicate role/index refs, clamp to the current sortie cap, deep-copy accepted entries, and clamp the initial sortie slot.
- `main.gd` still owns `blueprints`, `sortie_loadouts`, `initial_sortie_slot`, match-format sortie caps, editor/player state, UI, and all roster mutation; `_ensure_sortie_loadout()` now only materializes the player roster-size snapshot, delegates the pure normalization plan, and writes the returned loadout/initial slot back.
- `tools/battle_actor_command_service_contract_probe.gd` now uses the same failure aggregation pattern as the other guarded probes, and `tools/probe_exit_status_contract_probe.gd` now guards it as the ninth probe.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_loadout_plan` service token, then a zero-cap RED exposed that valid raw entries could slip through when `sortie_cap == 0`; the actor probe also exposed and then fixed a hidden success-override issue where an assertion error could be followed by `quit(0)`.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.624`, `max_ms=10.824`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_loadout_plan` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie-position lookup boundary follow-up:

- `BattleActorCommandService.sortie_position()` now owns the pure sortie-loadout lookup rule: scan the normalized loadout, skip non-dictionary entries, match role/index with stable integer index coercion, return the first matching slot, and return `-1` for missing roles/units or empty loadouts.
- `main.gd` still owns `sortie_loadouts`, `_ensure_sortie_loadout()`, roster validation, editor/player selection, UI state, and all loadout mutation; `_sortie_position()` now only materializes the normalized player loadout and delegates the pure lookup into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_position` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.360`, `max_ms=9.111`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_position` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 roster-entry validation boundary follow-up:

- `BattleActorCommandService.valid_roster_entry()` now owns the pure roster-entry validation rule: accept only roles in the supplied role order, coerce the entry index to an integer, reject negative indices, reject indices outside the supplied roster-size snapshot, and reject zero-sized rosters.
- `BattleActorCommandService.sortie_loadout_plan()` now reuses the same validation rule so loadout normalization and direct roster-entry checks cannot drift.
- `main.gd` still owns `blueprints`, roster storage, player/editor state, UI, and every mutation path; `_valid_roster_entry()` now only materializes the current player roster-size snapshot and delegates the pure validation into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `valid_roster_entry` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.120`, `max_ms=5.761`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `valid_roster_entry` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 default sortie-loadout boundary follow-up:

- `BattleActorCommandService.default_sortie_loadout()` now owns the pure default sortie-loadout copy rule: take the first entries from the supplied roster order up to the current sortie cap, clamp empty/negative caps to an empty loadout, clamp over-large caps to the roster order size, skip non-dictionary entries, and deep-copy accepted entries.
- `main.gd` still owns `blueprints`, `_all_roster_order()`, match-format sortie caps, roster/editor state, UI, and all loadout mutation; `_default_sortie_loadout()` now only materializes the player roster order/current cap and delegates the pure copy plan into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `default_sortie_loadout` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.510`, `max_ms=15.408`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `default_sortie_loadout` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 all roster-order boundary follow-up:

- `BattleActorCommandService.all_roster_order()` now owns the pure roster interleaving rule: clamp non-positive roster sizes to empty, find the maximum roster length from a supplied role order, and emit entries by unit index first and role order second.
- `main.gd` still owns `blueprints`, role roster storage, player existence checks, roster/editor state, UI, and all roster mutation; `_all_roster_order()` now only materializes the player roster-size snapshot and delegates the pure ordering into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `all_roster_order` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.788`, `max_ms=1.082`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `all_roster_order` token search confirmed service/main/probe coverage, no residual `_all_roster_order()` local `max_units` loop in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 roster unit-total boundary follow-up:

- `BattleActorCommandService.roster_unit_total()` now owns the pure roster-size summation rule: sum only roles supplied by the role order, clamp non-positive role sizes to zero, and handle empty roster-size snapshots safely.
- `main.gd` still owns `blueprints`, player existence checks, role roster storage, roster/editor state, UI, and all roster mutation; `_roster_unit_total()` now only materializes the player roster-size snapshot and delegates the pure total into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `roster_unit_total` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.823`, `max_ms=1.271`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `roster_unit_total` token search confirmed service/main/probe coverage, no residual `_roster_unit_total()` local `total += roster.size()` loop in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 team sortie-order boundary follow-up:

- `BattleActorCommandService.team_sortie_order()` now owns the pure team sortie-order filtering rule: skip non-dictionary loadout entries, reuse roster-entry validation, deep-copy accepted entries, clamp zero/negative sortie caps to an empty order, and stop at the supplied sortie cap.
- `main.gd` still owns `sortie_loadouts`, `_ensure_sortie_loadout()`, `blueprints`, player roster-size snapshots, match-format sortie caps, UI, summon state, and all loadout mutation; `_team_sortie_order()` now only materializes those facts and delegates the pure order filtering into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `team_sortie_order` service token; a follow-up zero-cap check then failed until the service returned an empty order before accepting entries when `sortie_cap <= 0`; the final probe passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.760`, `max_ms=0.904`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `team_sortie_order` token search confirmed service/main/probe coverage, no residual local `_team_sortie_order()` filtering loop in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 starter sortie-entry boundary follow-up:

- `BattleActorCommandService.starter_sortie_entry()` now owns the pure starter-entry selection rule: select from the filtered sortie order by clamped initial slot, deep-copy the selected entry, and fall back to the supplied active roster index for the supplied initial role when the sortie order is empty.
- `main.gd` still owns `_team_sortie_order()`, `initial_sortie_slot`, `initial_role`, `active_roster_indices`, player state, UI, and all roster/loadout mutation; `_starter_sortie_entry()` now only materializes those facts and delegates the pure starter selection into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `starter_sortie_entry` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.866`, `max_ms=2.435`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `starter_sortie_entry` token search confirmed service/main/probe coverage, no residual local loadout/active-index selection logic in `_starter_sortie_entry()` in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie role-count and required-role boundary follow-up:

- `BattleActorCommandService.sortie_role_counts()` and `BattleActorCommandService.sortie_has_required_roles()` now own the pure sortie role-counting rules: initialize counts from the supplied role order, ignore non-dictionary entries, ignore roles outside that role order, count accepted roles, and require at least one entry for each supplied role.
- `main.gd` still owns `ROLE_ORDER`, AI roster repair/fill decisions, editor summaries, UI text, and all roster/loadout mutation; `_sortie_role_counts()` and `_sortie_has_required_roles()` now only delegate the pure counting/validation into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_role_counts` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.769`, `max_ms=0.986`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_role_counts`/`sortie_has_required_roles` token search confirmed service/main/probe coverage, no residual local role-counting loop in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 AI sortie-score boundary follow-up:

- `BattleActorCommandService.ai_sortie_score()` now owns the pure AI sortie scoring formula: base health/damage/speed/security/deploy-cost terms, role-specific hero/puppet/barrier bonuses, aura/pulse terms for barriers, and the starter bonus.
- `main.gd` still owns roster iteration, candidate filtering, starter-cost validation, stats cache lookup, AI roster generation/repair decisions, UI, and all roster/loadout mutation; `_ai_sortie_score()` now only materializes the cached stats and delegates the pure formula into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `ai_sortie_score` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.773`, `max_ms=0.996`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `ai_sortie_score` token search confirmed service/main/probe coverage, the scoring formula now only appears in service/probe while `scripts/main.gd` only delegates after stats lookup, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 selected-entry comparison boundary follow-up:

- `BattleActorCommandService.entry_is_selected()` now owns the pure selected-entry comparison rule: build stable role/index refs with the existing default hero/index coercion, skip non-dictionary selected items, and report whether the candidate ref is already present in the selected list.
- `main.gd` still owns AI sortie candidate iteration, role filtering, battle legality checks, score comparison, UI, and all roster/loadout mutation; `_entry_is_selected()` now only delegates the pure comparison into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `entry_is_selected` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.781`, `max_ms=1.063`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `entry_is_selected` token search confirmed service/main/probe coverage, no residual local selected-entry comparison loop in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie after-delete plan boundary follow-up:

- `BattleActorCommandService.sortie_after_delete_plan()` now owns the pure sortie repair rule after a roster deletion: drop the deleted role/index entry, decrement later entries from the same role, validate against the supplied post-delete roster-size snapshot, skip duplicates, clamp to the supplied sortie cap, deep-copy accepted entries, and clamp the initial slot.
- `main.gd` still owns `sortie_loadouts`, `initial_sortie_slot`, post-delete roster snapshots, match-format sortie caps, roster deletion side effects, UI, and all roster/loadout mutation; `_update_sortie_after_delete()` now only materializes those facts, delegates the pure repair plan, and writes back the returned loadout/initial slot.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_after_delete_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.810`, `max_ms=1.882`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_after_delete_plan` token search confirmed service/main/probe coverage, no residual local deleted-entry index remap loop in `_update_sortie_after_delete()` in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie toggle-plan boundary follow-up:

- `BattleActorCommandService.sortie_toggle_plan()` now owns the pure sortie add/remove/full decision: remove an existing slot and clamp the initial slot, append a deep-copied missing entry when under cap, report a full no-op when the sortie is already capped, preserve initial slot on add/full no-ops, and avoid mutating the input loadout/entry.
- `main.gd` still owns roster-entry validation, current sortie/loadout snapshots, `_normalize_initial_sortie_for_cost()`, UI text/localization, manual-lock state, and all roster/loadout mutation; `_toggle_sortie_entry()` now only materializes those facts, applies the service plan, and emits the existing user-facing messages.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_toggle_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.767`, `max_ms=1.011`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_toggle_plan` token search confirmed service/main/probe coverage, no residual local add/remove/full loadout mutation branch in `_toggle_sortie_entry()` in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie starter-plan boundary follow-up:

- `BattleActorCommandService.sortie_starter_plan()` now owns the pure starter-setting plan: set an existing sortie slot as starter, append a deep-copied missing entry when under cap and select that appended slot, report a full no-op when the sortie is capped, and return the initial slot/role facts for `main.gd` to apply.
- `main.gd` still owns roster-entry validation, starter-cost validation, current sortie/loadout snapshots, `sortie_loadouts`, `initial_sortie_slot`, `initial_role`, UI text/localization, and all roster/loadout mutation; `_set_sortie_starter_entry()` now only materializes those facts, applies the service plan, and emits the existing user-facing messages.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_starter_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.875`, `max_ms=5.187`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `sortie_starter_plan` token search confirmed service/main/probe coverage, no residual local append/direct initial-role assignment branch in `_set_sortie_starter_entry()` in `scripts/main.gd`, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 initial sortie cost-plan boundary follow-up:

- `BattleActorCommandService.sortie_initial_cost_plan()` now owns the pure starter-cost slot selection rule: clamp the current initial slot, keep it when the supplied starter-cost flag is valid, otherwise select the first valid supplied flag, and report no starter for empty/no-valid loadouts without mutating the caller's state.
- `main.gd` still owns `_ensure_sortie_loadout()`, `_starter_cost_valid()`, stats lookup, `initial_sortie_slot`, UI, and all roster/loadout mutation; `_normalize_initial_sortie_for_cost()` now only materializes per-slot starter-cost flags, delegates the selection plan, and writes back the selected slot when a valid starter exists.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_initial_cost_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.047`, `max_ms=4.525`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 architecture validation sweep:

- Broad core-service validation passed for battle frame orchestration, field runtime, hit resolution, projectile lifecycle, action events, impact query, identity runtime, spatial runtime, map occlusion, target acquisition, projectile runtime, runtime contact, collider geometry/builder, VFX budget, runtime lifecycle, HUD state, awareness, runtime action telemetry, diagnostics overlay, Fighter heat/movement/turn/action models, runtime action geometry, Fighter action telemetry, unit editor catalog/board controllers, saved-unit controllers/services, and training-entry service contract probes.
- Runtime action/input validation passed for gun activation service, held-melee activation service, gun mobility/training move-fire/move-while-fire/direction-boost/turn-key/source-node probes, Boot Driver state/hold-release/no-projectile probes, blunt no-projectile, gauntlet command-window, blade simple/complex command, real training movement screen-direction, UI layout, and text-overflow probes.
- Project smoke checks remained green: `combat_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe`, `battle_runtime_frame_budget_probe`, `--headless --check-only --quit-after 1`, `probe_exit_status_contract_probe`, `probe_manifest.json` JSON parse, and `git diff --check`.

2026-06-09 sortie entry-legality boundary follow-up:

- `BattleActorCommandService.sortie_entry_battle_legality()` now owns the pure battle-entry legality decision from precomputed facts: valid roster gate, optional starter-cost gate, max length, body-board material grouping, topology note, and stat-note rejection while preserving the barrier slot-payload/drive-note exemptions.
- `main.gd` still owns `_valid_roster_entry()`, `_starter_cost_valid()`, blueprint/stat lookup, `_role_uses_body_board()`, material validation, topology-note construction, and all roster/loadout mutation; `_sortie_entry_is_battle_legal()` now only materializes those facts and delegates the boolean legality decision into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_entry_battle_legality` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.858`, `max_ms=2.897`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 AI battle roster-prepare intent boundary follow-up:

- `BattleActorCommandService.ai_battle_roster_prepare_intent()` now owns the pure AI roster preparation routing rule: decide auto-generation, legalization, force-generation, and random-template request from `ai_controlled`, `roster_empty`, and `manual_locked` facts.
- `main.gd` still owns `_ai_battle_original_player_is_ai()`, roster-size snapshots, `ai_team_manual_lock`, `ai_team_template_choice`, and `_legalize_ai_player_roster()` side effects; `_prepare_ai_battle_rosters()` now only materializes those facts and applies the returned intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `ai_battle_roster_prepare_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.193`, `max_ms=13.978`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 AI battle entry-repair intent boundary follow-up:

- `BattleActorCommandService.ai_battle_entry_repair_intent()` now owns the pure invalid-entry repair routing rule: skip repair when the summary is already valid, when the mode is not AI, or when the seat is not AI-controlled; otherwise force repair and select either `random` or the current locked template.
- `main.gd` still owns `_team_battle_entry_summary()`, `MODE_AI`, `_ai_battle_original_player_is_ai()`, `ai_team_manual_lock`, `ai_team_template_choice`, `_legalize_ai_player_roster()`, and summary recomputation; `_repair_ai_battle_entry_if_needed()` now only materializes those facts and applies the returned repair intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `ai_battle_entry_repair_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.026`, `max_ms=3.873`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 sortie active-index writeback boundary follow-up:

- `BattleActorCommandService.sortie_active_index_plan()` now owns the pure active-roster writeback plan for a selected sortie entry: ignore invalid roster entries and normalize valid role/index facts into `role_key`, `unit_index`, and `initial_role`.
- `main.gd` still owns `_valid_roster_entry()`, `active_roster_indices`, `initial_role`, and all state mutation; `_set_active_index_from_sortie_entry()` now only validates the entry, delegates the writeback plan, and applies the returned fields.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `sortie_active_index_plan` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.837`, `max_ms=1.563`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 AI battle original-player control boundary follow-up:

- `BattleActorCommandService.ai_battle_original_player_is_ai()` now owns the pure AI battle seat/original-player control rule: watch seat AI-controls both original players, while other seats keep original player 2 AI-controlled under the current battle setup.
- `main.gd` still owns `ai_battle_seat`, `MODE_AI`, and all battle/scout UI side effects; `_ai_battle_original_player_is_ai()` now only delegates the seat/player facts into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `ai_battle_original_player_is_ai` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.890`, `max_ms=3.233`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 matchup sortie-selection intent boundary follow-up:

- `BattleActorCommandService.matchup_sortie_selection_intent()` now owns the pure per-player matchup sortie selection writeback plan: AI-controlled players build AI loadouts and normalize starters, while human-controlled players clear pending loadouts and reset the initial slot; both paths keep summon bindings refreshed.
- `main.gd` still owns `_player_sortie_is_ai_controlled()`, `_build_ai_sortie_loadout()`, `_normalize_initial_sortie_for_cost()`, `sortie_loadouts`, `initial_sortie_slot`, and `_ensure_summon_pair_bindings()`; `_prepare_matchup_sortie_selection()` now only materializes the AI-control fact and applies the returned intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `matchup_sortie_selection_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.141`, `max_ms=6.584`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 AI battle seat-selection intent boundary follow-up:

- `BattleActorCommandService.ai_battle_seat_selection_intent()` now owns the pure seat-selection plan: clamp requested seat, mark training-seat confirmation/configuration in training mode, select P1 scout side for unlocked watch/P2-right battle seats, and request scout UI refresh.
- `main.gd` still owns `ai_battle_seat`, `training_seat_confirmed`, `_configure_training_sides_for_seat()`, `scout_sortie_player_id`, scout hint text, and `_update_scout_ui()`; `_select_ai_battle_seat()` now only materializes mode/manual-lock facts and applies the returned intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `ai_battle_seat_selection_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.079`, `max_ms=6.548`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 scout sortie-side selection intent boundary follow-up:

- `BattleActorCommandService.scout_sortie_side_selection_intent()` now owns the pure scout-side selection plan: clamp the requested player id, mirror it into the selected-player id, deep-copy the first available roster entry when present, preserve the current selected entry when the roster is empty, and request a scout UI refresh.
- `main.gd` still owns `_all_roster_order()`, `scout_sortie_player_id`, `scout_selected_player_id`, `scout_selected_entry`, localized hint text, and `_update_scout_ui()`; `_select_scout_sortie_side()` now only materializes the roster order, applies the returned intent, and performs the UI/state writeback.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `scout_sortie_side_selection_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.773`, `max_ms=2.112`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 scout AI team-button intent boundary follow-up:

- `BattleActorCommandService.scout_ai_team_button_intent()` now owns the pure scout AI team-button routing plan: clamp the target player id, route edit buttons to editor intent, cycle through the supplied template order with the existing unknown-key fallback/wrap behavior, lock cycled templates, and request random generation for the default path while preserving the button's lock-after flag.
- `main.gd` still owns `ai_team_template_choice`, `_show_editor_for_player()`, `_generate_ai_team_from_scout()`, roster legalization, scout hint text, and all UI/state side effects; `_handle_scout_ai_team_button()` now only materializes the current template key/order and applies the returned intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `scout_ai_team_button_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.771`, `max_ms=0.917`), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `scout_ai_team_button_intent` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 team color selection boundary follow-up:

- `BattleActorCommandService.team_color_index()` and `BattleActorCommandService.team_color_preset()` now own the pure team-color selection plan: P1/P2 fallback indices, negative custom-color sentinel preservation, preset-index clamping, preset/custom dictionary deep-copy, and missing custom-color fallback to P1 custom colors.
- `main.gd` still owns `team_color_indices`, `team_custom_colors`, `TEAM_COLOR_PRESETS`, color picker/editor state, scout/editor labels, saved payload serialization, unit stat writeback, and all UI/state side effects; `_team_color_index()` and `_team_color_preset()` now only delegate the pure selection into the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `team_color_index` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime/UI verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=2.078`, `max_ms=14.211`), `ui_layout_probe` (zh/en scout/editor overlap/out/hard all zero), `text_overflow_probe` (zh/en scout/editor counts zero), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `team_color_index` / `team_color_preset` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 team color select-intent boundary follow-up:

- `BattleActorCommandService.team_color_select_intent()` now owns the pure color-button selection plan: clamp scout/editor player id, clamp preset button index, preserve the no-preset custom sentinel, report whether editor selection should manually lock the AI team, and request the existing UI refresh.
- `main.gd` still owns `team_color_indices`, `ai_team_manual_lock`, scout/editor labels, color names, editor click SFX, and all UI refresh side effects; `_select_scout_team_color()` and `_select_editor_team_color()` now only apply the returned selection intent.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `team_color_select_intent` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime/UI verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.771`, `max_ms=0.951`), `ui_layout_probe` (zh/en pages overlap/out/hard all zero), `text_overflow_probe` (zh/en pages count zero), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `team_color_select_intent` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 team color-name boundary follow-up:

- `BattleActorCommandService.team_color_name()` now owns the pure team-color display-name fallback rule: prefer localized `name` in zh UI, prefer `name_en` in English UI, fallback across available name fields, and use the existing zh/custom defaults for empty preset dictionaries.
- `main.gd` still owns `_team_color_preset()`, `ui_language`, scout/editor labels, saved payload fields, color button text, and all UI side effects; `_team_color_name()` now only materializes the preset and language fact before delegating the string selection to the actor-command service.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `team_color_name` service token, then passed after the service/main delegation update.
- Focused summon/input/runtime/UI verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_actor_command_service_contract_probe`, `battle_input_service_contract_probe`, `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `--headless --check-only --quit-after 1`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.809`, `max_ms=1.313`), `ui_layout_probe` (zh/en pages overlap/out/hard all zero), `text_overflow_probe` (zh/en pages count zero), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional static verification passed: `probe_manifest.json` JSON parse, `team_color_name` token search confirmed service/main/probe coverage, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but the guarded probes above returned exit code 0.

2026-06-09 wide architecture validation sweep:

- A 54-probe architecture/runtime sweep passed on macOS Godot `4.6.2.stable.official.71f334935` with `WIDE_ARCH_VALIDATION ok count=54`.
- Core service contracts stayed green across battle frame orchestration, field runtime, hit resolution, projectile lifecycle, action events, impact query, identity/spatial/map runtime, target acquisition, projectile runtime, runtime contact, collider geometry/builder, VFX budget, lifecycle, HUD, awareness, runtime action telemetry, diagnostics overlay, Fighter heat/movement/turn/action models, action geometry, and Fighter action telemetry.
- Editor/saved-unit/training/controller architecture contracts stayed green: unit editor catalog/board controllers, saved units controller/library service, training entry service, extraction guards, lifecycle services, legacy-drive read guards, manifest fixture guard, data-rule single source, and reserved-key guards.
- Runtime smoke and UI verification stayed green: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `training_import_spawn_role_probe`, `action_module_execution_matrix_probe` (`profiles=11`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.789`, `max_ms=1.069`), `ui_layout_probe` (zh/en pages overlap/out/hard all zero), `text_overflow_probe` (zh/en pages count zero), and `probe_exit_status_contract_probe` (`guarded=9`).
- Additional project-level gates passed after the sweep: `--headless --check-only --quit-after 1`, `probe_manifest.json` JSON parse, and `git diff --check`.
- Known macOS headless noise remains unchanged: Godot may print the platform CA certificate warning and existing ObjectDB leak warnings at exit, but all guarded probes above returned exit code 0.

2026-06-09 pre-commit architecture audit:

- Dirty worktree grouping remains architecture-aligned: tracked edits are limited to local status docs, `main.gd`, extracted battle/activation/telemetry services, diagnostics view, contract/runtime probes, and `tools/probe_manifest.json`.
- The five untracked files are intentional architecture artifacts: `scripts/services/gun_activation_service.gd`, `scripts/services/held_melee_activation_service.gd`, `tools/gun_activation_service_contract_probe.gd`, `tools/held_melee_activation_service_contract_probe.gd`, and `tools/probe_exit_status_contract_probe.gd`.
- New service/probe coverage audit passed: `main.gd` preloads and lazily instantiates both activation services; the two activation contract probes preload their services; `probe_exit_status_contract_probe.gd` guards both new activation probes plus the other failure-aggregating probes; and `tools/probe_manifest.json` adds only `gun_activation_service_contract_probe`, `held_melee_activation_service_contract_probe`, and `probe_exit_status_contract_probe`.
- Untracked-file reference check found each new file referenced from existing source/docs/probes, so there are no isolated new `.gd` artifacts in the current architecture diff.
- Remaining non-code risk before commit/PR is organizational rather than functional: changes are still unstaged/uncommitted, manual visual review entries in `probe_manifest.json` were not part of the automated sweep, and the full 970-file `tools/` inventory was not exhaustively executed. The automated architecture/runtime gates listed above are current and green.

2026-06-09 final local completion audit:

- Local framework/architecture optimization is complete for this workstream: new runtime activation services, battle actor-command pure-rule boundaries, event/telemetry diagnostics, strengthened probes, manifest entries, and local status documentation are all present in the current worktree.
- Final fresh verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `FINAL_WIDE_ARCH_VALIDATION ok count=54`, `--headless --check-only --quit-after 1`, `probe_manifest.json` JSON parse, and `git diff --check`.
- Runtime evidence remains green under the new architecture: `combat_probe` reported `runtime_topology_contact=true` and `hp_delta=4`, `action_module_execution_matrix_probe` reported `profiles=11`, `battle_runtime_frame_budget_probe` reported `fixture=generated_training_starter`, `avg_ms=0.789`, `max_ms=1.038`, `ui_layout_probe` reported zh/en overlap/out/hard all zero, `text_overflow_probe` reported zh/en counts zero, and `probe_exit_status_contract_probe` reported `guarded=9`.
- GitHub branch-head sync was rechecked after `git fetch`: `HEAD...@{u}` remains `0 0`. The architecture changes are intentionally still local/uncommitted in the current branch until the next user-directed staging/commit/push step.
- Known caveats are non-blocking for the local completion target: macOS headless CA/ObjectDB warnings remain known noise with exit code 0, manual visual review entries remain manual by nature, and the full tools inventory was not exhaustively run because the targeted architecture/runtime validation suite covers the changed seams.

Next safe chunk: continue only with narrow pure-rule extraction where `main.gd` can pass plain scalar/dictionary/vector facts into an existing service. Do not move topology segment mutation, socket anchoring, collider generation, projectile resolution, target acquisition, damage application, queue mutation, or scythe side-mount geometry until a new plan explicitly covers ownership and failure probes.

2026-06-13 P3 saved-units/training handoff optimization:

- `SavedUnitsController.focus_state_for_path()` now owns the pure focus repair model for saved-unit library entry: valid focus selects the correct page/card, rejected focus keeps the rejected entry/detail visible with a stable reason, and missing focus clears stale selection/hover/detail while preserving a notice key for UI feedback.
- `main.gd` now applies the focus state through `_apply_saved_unit_selection_state()` and renders `_apply_saved_unit_focus_notice()` after the library UI refresh, so generic saved-unit refresh text no longer hides missing/rejected focus feedback.
- `SavedUnitsController.post_delete_selection_state()` now repairs selection after confirmed deletes to the closest remaining entry and clears selection only when the library/filter is empty; `_confirm_delete_saved_units()` refreshes the cache and applies this repair instead of always dropping to no selection.
- Training config now tracks `training_readiness_status_key/detail/count`, clears stale training caches on a fresh training-config entry, and surfaces specific readiness messages for imported units, current-roster hero, missing-hero fallback starter, invalid-roster fallback starter, and blocked/empty imports without changing the dedicated ball-dummy training flow.
- New focused probes were added and registered in `tools/probe_manifest.json`: `saved_units_delete_selection_repair_probe` and `training_readiness_feedback_probe`.
- Fresh focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `saved_units_controller_contract_probe`, `saved_units_mode_contract_probe`, `saved_units_return_target_probe`, `saved_units_file_invalidation_probe`, `saved_units_delete_selection_repair_probe`, `training_readiness_feedback_probe`, `training_entry_service_contract_probe`, `training_start_missing_dummy_feedback_probe`, `training_saved_unit_multi_probe`, and `unit_editor_training_illegal_feedback_probe`.
- Project gates passed after the P3 changes: `--headless --check-only --quit-after 1`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known fixture caveat: `editor_training_test_direct_probe` currently fails locally with `No saved training unit named 4 found.` because that probe depends on a user save fixture; the newer default ball-dummy training probes above still pass. Existing macOS headless ObjectDB leak warnings remain non-blocking when exit code is 0.

2026-06-13 P4 battle HUD display consistency optimization:

- `BattleHudStateService` now clamps HUD-only display values for unit health, electronic armor, heat percent, and puppet segment percent before formatting status/bar text. This is a presentation-layer correction only; runtime health, armor, heat, damage, cleanup, and battle timing behavior are unchanged.
- Blank or raw `normal` combat state text now falls back through `terms.normal`; `main.gd` passes the existing localized `normal` UI term into the battle HUD service terms dictionary.
- `tools/battle_hud_state_service_contract_probe.gd` now guards the new edge cases: negative/over-cap health display, negative shield display, heat above 100%, blank normal-state fallback, and puppet segment percent clamping.
- Fresh focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_hud_state_service_contract_probe`, `battle_instrument_gauge_probe`, `battle_action_diagnostics_overlay_probe`, `combat_probe`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.238`, `max_ms=9.672`), `ui_layout_probe`, and `text_overflow_probe`.
- Project gates passed after the P4 HUD display changes: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Command note: standalone `--check-only` without `--script` did not exit locally and was interrupted; the Godot help for 4.6.2 marks `--check-only` as script-oriented, so the recorded passing gate uses `--script res://scripts/main.gd`.

2026-06-13 P4 battle action diagnostics readability optimization:

- `BattleRuntimeActionTelemetryService.battle_action_diagnostics_model()` now reports display-window metadata: `max_units`, `max_actions_per_unit`, `displayed_unit_count`, `omitted_unit_count`, and per-unit `displayed_action_count` / `omitted_action_count`.
- `BattleActionDiagnosticsView.text()` now renders those shown/omitted counts in the summary and unit rows, so the debug overlay no longer silently truncates extra units or actions when the configured display cap is reached.
- The change remains pure diagnostics/UI presentation: telemetry snapshots, runtime action state, projectile queues, damage, contact resolution, and command execution are unchanged.
- Fresh focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_runtime_action_telemetry_service_contract_probe`, `battle_action_diagnostics_overlay_probe`, `combat_probe`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.805`, `max_ms=9.195`), `ui_layout_probe`, and `text_overflow_probe`.
- Project gates passed after the P4 diagnostics changes: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P4 battle cleanup/preserve-return state visibility optimization:

- `BattleState` snapshots now expose cleanup visibility fields: `last_cleanup_preserved`, `last_cleanup_clear_runtime`, `last_preserve_for_return`, `last_cleanup_reason`, and `last_cleanup_categories`.
- Preserve cleanup now records the state phase as `preserved`, while clear cleanup records `cleanup`; `BattleMode.state_snapshot()` therefore makes the preserve-return vs runtime-clear decision explicit after `commit_cleanup()`.
- This is a state-observability change only: actual runtime cleanup remains driven by the existing cleanup intent flags in `main.gd` / lifecycle service, and no unit, projectile, damage, input, or timing behavior was changed.
- Fresh focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_state_contract_probe`, `battle_mode_contract_probe`, `battle_exit_runtime_cleanup_probe`, `combat_probe`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.203`, `max_ms=28.815`).
- Project gates passed after the P4 cleanup visibility changes: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 battle input normalization boundary preparation:

- `BattleInputService` now owns the pure conversion from raw action strengths to movement vectors: `input_vector_from_strengths()` applies the existing 0.08 deadzone and over-length diagonal normalization, while `gun_turn_input_vector_from_strengths()` applies the existing turn-key deadzone and clamps to `[-1, 1]`.
- `main.gd` still owns all live `Input.get_action_strength()` reads and keeps `_input_vector_for()` / `_gun_turn_input_vector_for()` wrapper names intact; the wrappers now pass scalar strengths into `BattleInputService` for normalization.
- This is a P5 migration-prep change only: no key names, input timing, boost threshold, gun aim semantics, movement transform, battle feel, or action behavior was changed.
- Fresh focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_input_service_contract_probe`, `battle_real_training_movement_screen_direction_probe`, `battle_player_input_uses_mobius_surface_probe`, `battle_input_edge_single_consume_probe`, `combat_probe`, and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.026`, `max_ms=3.247`).
- Project gates passed after the P5 input-boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 auto-summon role availability boundary preparation:

- `BattleActorCommandService.auto_summon_role_available()` now owns the pure role-availability decision used by auto-summon candidate building: unknown roles, missing players, pending roles, live non-puppet roles, and live puppet groups are rejected before affordability is considered.
- `main.gd` still owns all live battle state reads in `_role_available_for_auto_summon()`, including `active_units`, pending deploys, and live puppet counts; it now materializes those facts and delegates the boolean decision to the actor-command service.
- This is a P5 migration-prep change only: auto-summon timers, role filters, resource checks, deploy cost discounts, summon side effects, messages, and unit creation behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `auto_summon_role_available` service token, then passed after the service/main delegation update.
- Fresh runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`) and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.764`, `max_ms=0.923`).
- Project gates passed after the P5 auto-summon boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 auto-summon mech presence boundary preparation:

- `BattleActorCommandService.auto_summon_mech_presence()` now owns the pure boolean merge used before anti-stall summon intent creation: a live hero or any live primary puppet counts as `has_live_mech`, while hero or puppet pending deploys count as `has_pending_mech`.
- `main.gd` still owns all live state reads through `_player_has_live_mech()` and `_player_has_pending_mech()`; those wrappers now pass sampled facts into the actor-command service instead of embedding the merge rule directly.
- This is a P5 migration-prep change only: anti-stall cooldowns, idle-soul timing, auto-summon role filters, pending deploy timers, summon acceptance, and unit spawning behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `auto_summon_mech_presence` service token, then passed after the service/main delegation update.
- Fresh runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`) and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.008`, `max_ms=3.820`).
- Project gates passed after the P5 mech-presence boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 source-rules selection boundary preparation:

- `BattleActorCommandService.source_rule_for_condition()` now owns the pure selection rule for battle `source_rules`: prefer an exact condition entry when it is a dictionary, fall back to the `default` dictionary when the condition is missing, and reject malformed rule maps without mutating source data.
- `main.gd` still owns live unit/stat access in `_source_rule_for_condition()` and `_battle_command_diagnostics_source_rule()`; both wrappers now pass plain rule dictionaries into the actor-command service so puppet movement/action and command diagnostics share the same tested selection boundary.
- This is a P5 migration-prep change only: puppet target selection, movement vectors, action cadence, module firing, role switching, diagnostics rendering, damage, and projectile behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `source_rule_for_condition` service token, then passed after the service/main delegation update.
- Fresh runtime/diagnostics verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_diagnostics_overlay_probe` (`text_lines=17`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.857`, `max_ms=2.248`).
- Project gates passed after the P5 source-rules boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 default puppet attack-module boundary preparation:

- `BattleActorCommandService.default_puppet_attack_modules()` now owns the pure fallback ordering for puppet attack modules: prefer the puppet's indexed module when available, skip disabled module markers, and append the remaining enabled attack slots in order.
- `main.gd` still owns live part-disable reads through `_battle_actor_disabled_modules()` and keeps `_default_puppet_attack_modules()` as the wrapper used by puppet actions; the wrapper now passes scalar facts into the actor-command service.
- This is a P5 migration-prep change only: disabled-part detection, sequence rules, source rule overrides, attack reach, cadence, firing, projectile events, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed on the missing `default_puppet_attack_modules` service token, then passed after the service/main delegation update.
- Fresh runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`) and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.045`, `max_ms=3.726`).
- Project gates passed after the P5 default-module boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 stale puppet-command helper cleanup:

- `main.gd` no longer retains the stale helper definitions `_source_attack_index_for_step()`, `_puppet_attack_reaches()`, or `_source_move_vector()` after their behavior became owned by `BattleActorCommandService.puppet_attack_intent()` and `BattleActorCommandService.puppet_move_intent()`.
- `tools/battle_actor_command_service_contract_probe.gd` now guards against those migrated battle actor command helpers reappearing in `main.gd`, matching the P5 goal of shrinking the composition root around tested service boundaries.
- This is a P5 cleanup-only change: puppet movement, attack reach, source movement overrides, attack preference, cadence, module selection, firing, projectile events, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_actor_command_service_contract_probe.gd`: the probe first failed while `main.gd` still contained `_source_attack_index_for_step()`, then passed after the stale helper cleanup.
- Fresh runtime verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`) and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.948`, `max_ms=4.053`).
- Project gates passed after the P5 stale-helper cleanup: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 projectile source-node boundary preparation:

- `BattleProjectileLifecycleService.projectile_source_node_for_event()` now owns the pure source-node fallback rule for projectile events: prefer `source_gun_node`, then `source_node_index`, then `muscle_node`, then the supplied fallback index.
- `main.gd` keeps `_projectile_source_node_for_event()` as the wrapper used by aim pose and runtime gun-pose cleanup, but now delegates the scalar field selection to the projectile lifecycle service.
- This is a P5 migration-prep change only: projectile spawning, muzzle alignment, aim pose application, trace rendering, collision, damage, reflection, and runtime pose cleanup behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_projectile_lifecycle_service_contract_probe.gd`: the probe first failed on the missing `projectile_source_node_for_event` service token, then passed after the service/main delegation update.
- Fresh runtime/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.865`, `max_ms=3.385`).
- Project gates passed after the P5 projectile source-node boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 projectile gun-source boundary preparation:

- `BattleProjectileLifecycleService.projectile_event_has_gun_source()` now owns the pure dictionary gate that determines whether projectile events carry a valid runtime gun source: non-projectiles pass, projectiles require `muscle_node`, a dictionary `collision_group`, projectile/projectile-only group flags, and a gun-class material or shape.
- `main.gd` keeps `_projectile_event_has_gun_source()` as the wrapper used by hit-entry and explicit gun activation checks, but now delegates the field inspection to the projectile lifecycle service.
- This is a P5 migration-prep change only: attack-entry routing, missing-gun-source messages, salvo preview release, runtime contact damage, projectile spawning, collision, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_projectile_lifecycle_service_contract_probe.gd`: the probe first failed on the missing `projectile_event_has_gun_source` service token, then passed after the service/main delegation update.
- `tools/no_old_threshold_gate_probe.gd` now uses the exact `func _force_runtime_collision_recovery(` anchor and returns immediately after `_fail()`, so the probe no longer prints `push_error` noise while still reporting `ok`.
- Fresh runtime/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `salvo_arc_preview_release_fire_probe` (`ammo=2`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.059`, `max_ms=8.214`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 projectile gun-source boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 runtime-melee projectile-clear boundary preparation:

- `BattleProjectileLifecycleService.runtime_melee_projectile_clear_intent()` now owns the pure field-clear plan used when runtime melee events must drop projectile semantics: set `projectile=false`, `projectile_only=false`, `runtime_melee_contact=true`, and erase projectile style/behavior/path/damage-type keys.
- `main.gd` keeps `_clear_projectile_fields_for_runtime_melee()` as the mutation wrapper used by attack-entry and runtime attack normalization; the wrapper now applies the service-provided set/erase intent instead of embedding the field list directly.
- This is a P5 migration-prep change only: runtime melee routing, explicit gun activation gates, missile/boot-driver projectile gating, contact momentum, hit resolution, projectile queues, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_projectile_lifecycle_service_contract_probe.gd`: the probe first failed on the missing `runtime_melee_projectile_clear_intent` service token, then passed after the service/main delegation update.
- Fresh runtime/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_projectile_gate_probe`, `boot_driver_melee_no_projectile_probe`, `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.984`, `max_ms=4.542`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 runtime-melee projectile-clear boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 runtime gun-pose clear-node boundary preparation:

- `BattleProjectileLifecycleService.runtime_gun_pose_clear_node()` now owns the pure node-selection rule used before clearing runtime gun aim pose: prefer explicit projectile source fields, then `binding.target_nodes` tail, then direct `target_nodes` tail, then the provided fallback.
- `main.gd` keeps `_clear_runtime_gun_pose_for_payload()` as the live Node wrapper; it still checks unit validity and calls `clear_aim_pose()`, but delegates payload field selection to the projectile lifecycle service.
- This is a P5 migration-prep change only: aim pose application, runtime gun activation, projectile muzzle alignment, projectile firing, runtime gun-pose cleanup side effects, collision, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_projectile_lifecycle_service_contract_probe.gd`: the probe first failed on the missing `runtime_gun_pose_clear_node` service token, then passed after the service/main delegation update.
- Fresh runtime/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `gun_activation_service_contract_probe`, `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.200`, `max_ms=8.980`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 runtime gun-pose clear-node boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 true-bullet classification boundary preparation:

- `BattleProjectileLifecycleService` now owns the pure true-bullet classification predicates: `group_uses_true_bullet()`, `true_bullet_event_pending()`, and `true_bullet_event_fired()`.
- `main.gd` keeps the existing wrappers `_group_uses_true_bullet()`, `_is_true_bullet_event()`, and `_is_true_bullet_fired_event()`; those wrappers still resolve projectile behavior through the existing runtime behavior helper, then delegate the final dictionary/behavior classification to the projectile lifecycle service.
- This is a P5 migration-prep change only: sniper lock timing, pending true-bullet queue mutation, fired-event resolution, target acquisition, projectile spawning, missile/laser routing, collision, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_projectile_lifecycle_service_contract_probe.gd`: the probe first failed on the missing `group_uses_true_bullet` service token, then passed after the service/main delegation update.
- Fresh true-bullet-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_no_sniper_lock_probe`, `laser_no_sniper_lock_probe`, `sniper_edge_target_lock_probe` (`distance=0.56`), `sniper_first_obstruction_probe` (`target=P2 傀儡 CODE`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.937`, `max_ms=4.051`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 true-bullet classification boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 explicit gun-activation event boundary preparation:

- `BattleActionEventService.explicit_gun_activation_event()` now owns the pure event/profile-known decision used before runtime attack normalization and projectile/melee routing.
- `main.gd` keeps `_event_is_explicit_gun_activation()` as the wrapper and still owns the live gun-activation profile registry lookup through `_gun_activation_profiles().has(profile)`.
- The preserved semantics are intentionally unchanged: a known gun activation profile is explicit even without a `gun_activation` flag, while an unknown or missing profile is not explicit even when `gun_activation=true`.
- This is a P5 migration-prep change only: profile registry contents, gun activation specs, projectile field clearing, missile/laser/salvo routing, runtime melee routing, target acquisition, collision, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/battle_action_event_service_contract_probe.gd`: the probe first failed on the missing `explicit_gun_activation_event` service token, then passed after the service/main delegation update.
- Fresh action/projectile routing verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_projectile_gate_probe`, `laser_projectile_gate_probe`, `salvo_arc_preview_release_fire_probe` (`ammo=2`), `runtime_melee_never_projectile_gate_probe` (`message=''`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.085`, `max_ms=5.609`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 explicit gun-activation event boundary change: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 projectile behavior wrapper cleanup:

- `main.gd` no longer keeps a duplicate projectile behavior parser inside `_projectile_behavior_for_data()`; the wrapper now delegates directly to `ProjectileRuntimeService.projectile_behavior_for_data()`.
- `main.gd` now has `_projectile_runtime_service()` as a lazy getter, matching the existing lazy service wrappers used by battle services and keeping direct test calls safe before the full `_ready()` path initializes every service.
- `tools/projectile_runtime_service_contract_probe.gd` now guards both the lazy getter/delegation path and the absence of the stale behavior parser fragments in `main.gd`.
- This is a P5 migration-prep cleanup only: projectile behavior rules, true-bullet classification, missile/laser/chemical/explosive routing, projectile collision, damage, queues, and runtime spawning behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service()` wrapper, then passed after the lazy getter and `_projectile_behavior_for_data()` delegation update.
- Fresh behavior-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_hit_resolution_service_contract_probe`, `battle_projectile_lifecycle_service_contract_probe`, `missile_no_sniper_lock_probe`, `laser_no_sniper_lock_probe`, `sniper_edge_target_lock_probe` (`distance=0.56`), `sniper_first_obstruction_probe` (`target=P2 傀儡 CODE`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.839`, `max_ms=2.633`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 projectile behavior wrapper cleanup: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Existing verification caveat found while expanding adjacent coverage: `tools/projectile_momentum_probe.gd` currently prints `ERROR: Explosive projectile should deal direct damage, wide splash damage, and projectile momentum stagger.` because `BattleHitResolutionService.projectile_preflight_intent()` intentionally requests `erase_explosion_damage` for explosive projectile preflight, so the probe expectation conflicts with the current hit-resolution contract. This was not changed in the wrapper cleanup and should be handled as a separate design/contract decision before altering explosion damage behavior.

2026-06-13 P5 projectile behavior-key wrapper cleanup:

- `main.gd` no longer keeps a duplicate projectile behavior-key fallback parser inside `_projectile_behavior_key()`; the wrapper now delegates directly to `ProjectileRuntimeService.projectile_behavior_key()`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the `_projectile_behavior_key()` delegation and rejects the old true-bullet/laser behavior-key parser fragments in `main.gd`.
- This is a P5 migration-prep cleanup only: behavior-key rules, projectile default momentum, projectile speed/mass, raw damage coefficients, recoil transfer, true-bullet/missile/laser/chemical routing, collision, and damage behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service().projectile_behavior_key(event)` delegation token, then passed after the `_projectile_behavior_key()` wrapper update.
- Fresh behavior-key-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `missile_no_sniper_lock_probe`, `laser_no_sniper_lock_probe`, `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.044`, `max_ms=4.040`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 projectile behavior-key wrapper cleanup: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 projectile drive/style wrapper cleanup:

- `main.gd` no longer keeps duplicate fallbacks for projectile drive momentum multiplier, projectile drive momentum fields, or projectile style-by-damage mapping; `_gun_drive_projectile_momentum_mult()`, `_projectile_drive_momentum_mult_for_event()`, `_sync_projectile_drive_momentum_fields()`, and `_projectile_style_for_damage()` now delegate to `ProjectileRuntimeService`.
- `main.gd` still owns applying the returned drive momentum fields onto the live event dictionary, while `ProjectileRuntimeService` owns the pure calculation of `projectile_base_momentum`, `projectile_drive_momentum_mult`, and `projectile_effective_momentum`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the drive/style delegation tokens and rejects the old fallback fragments in `main.gd`.
- This is a P5 migration-prep cleanup only: gun-drive ratios, projectile effective momentum fields, style mapping, projectile spawning, muzzle alignment, damage, recoil, and runtime firing behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service().projectile_style_for_damage(damage_type)` delegation token, then passed after the drive/style wrapper update.
- Fresh drive/style-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`), `gun_drive_fire_control_probe` (`gun=40.14`, `melee=59.90`, `aim 0.70->1.23`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.329`, `max_ms=6.106`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 projectile drive/style wrapper cleanup: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.

2026-06-13 P5 projectile physics wrapper cleanup:

- `main.gd` no longer keeps duplicate fallback rules for projectile default momentum, collision speed, or mass; `_projectile_default_momentum_for_event()`, `_projectile_collision_speed_for_event()`, and `_projectile_mass_for_event()` now delegate directly to `ProjectileRuntimeService`.
- Live collision and momentum side effects remain in `main.gd`: `_projectile_collision_momentum()` still owns event field writes such as `projectile_mass`, `projectile_collision_speed`, `projectile_velocity`, and `projectile_momentum_resolved`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the momentum/speed/mass delegation tokens and rejects the old fallback fragments in `main.gd`.
- This is a P5 migration-prep cleanup only: projectile physics constants, explicit momentum handling, speed clamps, mass derivation, collision momentum writes, damage, recoil, hit resolution, and runtime firing behavior are unchanged.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service().projectile_default_momentum_for_event(event, _projectile_runtime_constants())` delegation token, then passed after the physics wrapper update.
- Fresh projectile-physics-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.969`, `max_ms=5.696`), and `no_old_threshold_gate_probe`.
- Project gates passed after the P5 projectile physics wrapper cleanup: `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Existing verification caveat found while expanding adjacent coverage: `tools/gun_momentum_range_matches_melee_probe.gd` currently prints `ERROR: Gun momentum range appears to still have a special low-drive rule: gun 18.88-62.43 melee 31.42-109.14` while exiting with code `0`. The probe checks editor part momentum range helpers (`_limb_momentum_min_for_part()` / `_limb_momentum_max_for_part()`), not the runtime projectile physics wrappers changed here, and should be handled as a separate editor/stat-display contract decision.

2026-06-13 P5 projectile momentum/damage/recoil wrapper cleanup:

- `main.gd` no longer keeps duplicate fallback rules for projectile momentum state, gun projectile damage multipliers, projectile damage coefficient field writes, raw projectile damage from momentum, or default recoil transfer; `_projectile_momentum_for_event()`, `_gun_projectile_damage_mult_max_for_data()`, `_gun_projectile_damage_mult_for_event()`, `_projectile_damage_coeffs_for_event()`, `_projectile_raw_damage_for_event()`, and `_default_recoil_transfer_for_projectile()` now delegate to `ProjectileRuntimeService`.
- `main.gd` still owns live runtime mutation: it applies returned event fields such as `projectile_base_momentum`, `projectile_drive_momentum_mult`, `projectile_effective_momentum`, `gun_projectile_damage_mult_current`, and `gun_projectile_damage_mult`, and it still computes collision momentum before raw damage plus recoil/damage side effects elsewhere.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the momentum/damage/recoil delegation tokens and rejects the stale fallback fragments in `main.gd`.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service().projectile_momentum_state_for_event(event, _projectile_runtime_constants())` delegation token, then passed after the wrapper update.
- Fresh projectile momentum/damage/recoil verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `gun_damage_multiplier_from_allocation_probe` (`current=6.00`, `max=15.00`), `gun_recoil_momentum_probe` (`velocity=(-5.0, 0.0)`), `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`), `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), and `gun_recoil_brake_probe` (`start=4.000`, `end=1.000`).
- Runtime gates passed after the wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.969`, `max_ms=3.953`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile heat wrapper cleanup:

- `main.gd` no longer keeps duplicate fallback rules for projectile heat tags or canonical heat reason strings; `_heat_tags_for_projectile_event()`, `_heat_reason_for_tags()`, and `_heat_reason_for_projectile_event()` now delegate through the lazy `ProjectileRuntimeService` wrapper.
- `main.gd` still owns live heat application, unit heat capacity reads, `add_heat_event()` / `add_heat()` calls, UI refresh side effects, and all runtime projectile damage/queue handling. This change only centralizes pure tag/reason string construction.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the heat delegation tokens and rejects the stale heat tag/reason fallback fragments in `main.gd`.
- Fresh RED/GREEN verification passed through `tools/projectile_runtime_service_contract_probe.gd`: the probe first failed on the missing `_projectile_runtime_service().heat_tags_for_projectile_event(event)` delegation token, then passed after the wrapper update.
- Fresh heat-focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `heat_event_reason_compat_probe` (`canonical=30.0`, `compat=30.0`, `external=40.0`), `heat_event_tag_unification_probe` (`canonical=30.0`, `legacy=30.0`, `repeat=40.0`, `dissipation=27.0`), `heat_event_tag_matrix_probe`, `laser_ammo_heat_probe` (`ammo=7->6`, `heat=0.0->1.0`), `missile_ammo_heat_probe` (`ammo=2`, `heat=34.0`), and `chemical_heat_probe` (`queued=true`, `impact=true`, `dot=true`, `heat=44.00`).
- Runtime gates passed after the heat wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.999`, `max_ms=3.629`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile trace payload wrapper cleanup:

- `main.gd` no longer keeps duplicate fallback rules for web trace event shaping or projectile trace payload shaping; `_web_trace_event()` now delegates to `ProjectileRuntimeService.web_trace_event()`, and `_spawn_projectile_trace()` delegates payload construction to `ProjectileRuntimeService.trace_payload()`.
- `main.gd` still owns live VFX budget checks, projected screen segment generation, `ProjectileTraceEffect` node creation, `effects_root` mutation, launch SFX, and all combat/muzzle projection facts. This change only centralizes the pure trace event/payload dictionaries.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the web trace / trace payload delegation tokens and rejects the stale trace fallback fragments in `main.gd`; `tools/main_controller_boundary_probe.gd` was updated to match the lazy projectile runtime service adapter style.
- Fresh RED/GREEN verification passed: `projectile_runtime_service_contract_probe` and `main_controller_boundary_probe` first failed on the missing `_projectile_runtime_service().web_trace_event(...)` delegation token, then passed after the wrapper update.
- Fresh trace/muzzle verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`, `screen=(740.12, 413.5383)`), `mobius_projectile_trace_projection_probe` (`start=(541.5385, 364.0)`, `end=(649.8461, 467.3846)`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `projectile_trace_no_rewrap_lane_flip_probe`, `projectile_muzzle_complex_unit_real_screen_probe` (`start=(771.9385, 426.0308)`), and `projectile_muzzle_consistency_probe` (`distance=0.0000`).
- Runtime gates passed after the trace payload wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.833`, `max_ms=1.869`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 chemical/missile projectile queue wrapper cleanup:

- `main.gd` no longer keeps duplicate fallback rules for chemical projectile detection, chemical event preparation, chemical firework classification, chemical travel time, chemical queue intent, missile projectile detection, missile travel time, or missile queue intent.
- The wrappers `_is_chemical_projectile_event()`, `_prepare_chemical_projectile_event()`, `_chemical_firework_event()`, `_queue_chemical_projectile()`, `_chemical_projectile_travel_time()`, `_is_missile_projectile_event()`, `_missile_projectile_travel_time()`, and `_queue_missile_projectile()` now delegate their pure decisions through the lazy `ProjectileRuntimeService` wrapper.
- `main.gd` still owns live attacker/target checks, missile target acquisition, direction facts, recoil application, trace spawning, pending chemical/missile arrays, projectile signal metadata, battle messages, occlusion updates, and final attack resolution. This change only centralizes pure event shaping, travel-time math, and queue-intent dictionaries.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the chemical/missile delegation tokens and rejects the stale local fallback fragments, including `_legacy_chemical_queue_intent()`.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `_projectile_runtime_service().is_chemical_projectile_event(event)` delegation token, then passed after the wrapper update.
- Fresh chemical-focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `chemical_heat_probe` (`queued=true`, `impact=true`, `dot=true`, `heat=44.00`), `chemical_dot_probe` (`dps=6.00`, `hp=160->153`), `chemical_sprayer_hold_release_probe` (`ammo=12->11`, `hp=120->117`), `chemical_sprayer_first_contact_probe` (`blocker=140->135`, `rear=140->140`), and `chemical_sprayer_rotate_command_probe` (`speed=2.00`).
- Fresh missile-focused verification passed: `missile_ammo_heat_probe` (`ammo=2`, `heat=34.0`), `missile_projectile_gate_probe`, `missile_no_sniper_lock_probe`, `laser_no_sniper_lock_probe`, `projectile_muzzle_screen_alignment_probe` (`muzzle=(4.016844, 0.503123)`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `missile_lock_runtime_fire_probe`, `missile_homing_speed_dodge_probe` (`travel=1.58`), `missile_occlusion_break_lock_probe`, `missile_lock_activate_binding_probe`, `missile_lock_priority_near_probe`, `missile_lock_priority_far_probe`, `missile_no_proximity_autofire_probe`, and `missile_lock_invalid_no_ammo_probe`.
- Runtime gates passed after the chemical/missile queue wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.913`, `max_ms=2.516`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact scalar wrapper cleanup:

- `main.gd` now has `_runtime_contact_service()` as a lazy getter, matching the other P5 runtime service adapters.
- `main.gd` no longer keeps duplicate fallback rules for runtime contact socket keys, sorted collider order, collider priority, pair keys, directed contact keys, torso-damage proxy detection, damage/break coefficients, part/path stiffness, break threshold, damage type, material class, or contact source. The wrappers now delegate those pure scalar/string decisions to `RuntimeContactService`.
- `main.gd` still owns live unit validity checks, collider size multiplier sampling, active contact suppression state, runtime pair/GPU/damage-intent fallback blocks, velocity response, VFX/SFX, damage application, kill flow, and collision recovery side effects.
- `tools/runtime_contact_service_contract_probe.gd` now guards the lazy getter/scalar delegation tokens and rejects the stale local scalar fallback fragments in `main.gd`; `tools/main_controller_boundary_probe.gd` was updated to match the lazy runtime-contact adapter style.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `func _runtime_contact_service() -> RuntimeContactService` delegation token, then passed after the wrapper update.
- Fresh runtime contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `idle_collision_uses_torso_coeff_probe`, `melee_contact_source_probe`, `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `one_shot_contact_probe` (`hp_after_first=100`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `runtime_no_precontact_damage_probe` (`gap=2.0844`, `hp=150`), `runtime_no_precontact_fx_probe` (`gap=0.6095`, `effects=2`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `collision_broadphase_skip_probe` (`skip=1`, `precise=0`), `runtime_no_precontact_none_probe` (`effects=3`, `label=''`), and `runtime_contact_visual_identity_probe`.
- Runtime gates passed after the runtime contact scalar wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.805`, `max_ms=1.302`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Extra-probe caveats from systematic debugging: `gpu_contact_damage_probe` and `gpu_collision_init_probe` currently fail in this macOS headless session because `RenderingDevice` / GPU compute is unavailable; `no_runtime_collision_expansion_probe` currently fails because local `user://saved_units` has no saved unit named `2`. These were not counted as passed and are separate environment/fixture issues.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact intent wrapper cleanup:

- `main.gd` no longer keeps duplicate local fallback implementations for `RuntimeContactService.runtime_pair_intent()`, `gpu_contact_intent()`, or `damage_intent()`. These three contact intent wrappers now call through `_runtime_contact_service()` directly.
- `main.gd` still owns live unit validity checks, collider velocity/mass/stiffness sampling, active contact suppression state, pair seen/active bookkeeping, GPU position deltas, collision recovery, VFX/SFX, damage application, kill flow, and velocity response.
- `tools/runtime_contact_service_contract_probe.gd` and `tools/main_controller_boundary_probe.gd` now guard the lazy service intent tokens and reject the old `runtime_contact_service != null else {}` / `runtime_contact_service == null` fallback blocks.
- `tools/no_old_threshold_gate_probe.gd` now follows the new boundary: `main.gd` must feed stiffness data into `RuntimeContactService.damage_intent()`, and `RuntimeContactService` must continue exposing stiffness-capped `usable_contact_momentum`.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `_runtime_contact_service().runtime_pair_intent` delegation token, then passed after the `main.gd` wrapper update.
- Fresh runtime contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), `runtime_no_precontact_damage_probe` (`gap=2.0844`, `hp=150`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `melee_contact_source_probe`, `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `collision_broadphase_skip_probe` (`skip=1`, `precise=0`), and `runtime_contact_visual_identity_probe`.
- Runtime gates passed after the runtime contact intent wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.443`, `max_ms=11.453`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- During gate debugging, `no_old_threshold_gate_probe` first failed because it still expected `usable_contact_momentum` inside the `main.gd` damage block after that event shaping moved into `RuntimeContactService`; after updating the probe to inspect the service boundary, it briefly hung due an early `return` before `quit()`, then passed after removing that early return.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact velocity response wrapper cleanup:

- `RuntimeContactService` now owns the pure runtime contact velocity-response calculation through `velocity_response_intent()`: it validates momentum/normal, normalizes the direction, clamps masses to at least `1.0`, applies anchored-unit zero-delta rules, and returns `velocity_delta_a` / `velocity_delta_b`.
- `main.gd` still owns live mass and anchored-state sampling, velocity mutation, and collision auto-brake requests inside `_apply_runtime_contact_velocity_response()`.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, the `_runtime_contact_service().velocity_response_intent` wrapper token, the absence of the old inline `a.velocity -= direction * ...` / `b.velocity += direction * ...` calculation, and direct service outputs for normal, anchored, and invalid-normal cases.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy velocity-response service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `velocity_response_intent` service token, then passed after the service/main wrapper update.
- Fresh runtime contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `one_shot_contact_probe` (`hp_after_first=100`), and `runtime_contact_visual_identity_probe`.
- Runtime gates passed after the velocity-response wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.883`, `max_ms=39.200`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact action phase/recovery wrapper cleanup:

- `RuntimeContactService` now owns the pure runtime action node matching and phase/recovery calculations through `runtime_node_array_has()`, `runtime_action_phase()`, and `runtime_recovery_capable()`.
- `main.gd` still owns live unit validity checks, collider node-index extraction, `runtime_module_actions` reads, GPU collider dictionary assembly, and the actual GPU collision pipeline path.
- `main.gd` keeps the existing `_gpu_collision_recovery_capable()` and `_gpu_collision_action_phase()` wrapper names, but those wrappers now pass sampled action arrays and node indices into `RuntimeContactService`.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service helper tokens, the lazy wrapper tokens, direct outputs for numeric-string node ids, action phase, startup recovery, non-startup recovery, and no-target fallback, and rejects the old inline `duration/phase` block plus `_runtime_node_array_has_for_gpu()` helper in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy runtime action phase/recovery service tokens.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `runtime_node_array_has` service token, then failed once because `gpu_collision` in the initial service helper names violated the service purity guard, and then passed after renaming the service helpers to runtime/action terminology.
- Fresh runtime contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `runtime_contact_visual_identity_probe`, `collision_broadphase_skip_probe` (`skip=1`, `precise=0`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), and `one_shot_contact_probe` (`hp_after_first=100`).
- Runtime gates passed after the action phase/recovery wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.767`, `max_ms=51.219`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Real GPU collision pipeline probes remain environment-sensitive in this macOS headless session because `RenderingDevice` / GPU compute is unavailable; this cleanup was verified through the pure service contract and non-GPU runtime contact probes.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact passive scrape-factor wrapper cleanup:

- `RuntimeContactService` now owns the pure passive-contact scrape factor calculation through `passive_contact_scrape_factor()`, using the existing part-kind branches and `contact_damage_mult` minimum for limb muscles.
- `main.gd` still owns contact velocity sampling, tangent/normal construction, unit mass reads, combo transfer adjustment, and all stagger/damage side effects. `_passive_contact_scrape_factor()` remains as a thin wrapper for existing call sites.
- `_runtime_contact_constants()` now includes `passive_contact_scrape_mult` so the service receives the existing `PASSIVE_CONTACT_SCRAPE_MULT` value without reaching into `main.gd` constants directly.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct numeric outputs for terminal/limb/joint/fallback colliders, and rejects the old local `match String(collider.get("part_kind", ""))` scrape-factor branch in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy scrape-factor service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `passive_contact_scrape_factor` service token, then passed after the service/main wrapper update.
- Fresh contact/stagger verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `one_shot_contact_probe` (`hp_after_first=100`), and `runtime_contact_visual_identity_probe`.
- Runtime gates passed after the passive scrape-factor wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.118`, `max_ms=6.606`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact passive feedback-key wrapper cleanup:

- `RuntimeContactService` now owns the pure passive-contact feedback key helpers: `meta_safe_part_index()` and `passive_contact_damage_key()`.
- `main.gd` still owns live attacker/target instance-id sampling, contact feedback timers, hit-effect spawning, and hitstop; `_passive_contact_damage_key()` remains as a thin wrapper for existing call sites.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service helper tokens, the lazy wrapper token, direct negative/positive part-index formatting, passive feedback-key output, and rejects the old local `_meta_safe_part_index()` / inline `passive_contact_%d...` formatter in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy passive feedback-key service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the first run exposed a probe parse issue from using `:=` with a not-yet-defined service method, then the probe correctly failed on the missing `meta_safe_part_index` service token, and finally passed after the service/main wrapper update.
- Fresh passive/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `idle_collision_one_torso_damage_probe` (`hp_delta=20`), `one_shot_contact_probe` (`hp_after_first=100`), `runtime_contact_visual_identity_probe`, `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), and `collision_broadphase_skip_probe` (`skip=1`, `precise=0`).
- Runtime gates passed after the passive feedback-key wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=2.254`, `max_ms=35.618`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact unit-radius wrapper cleanup:

- `RuntimeContactService` now owns the pure unit contact broadphase radius formula through `unit_contact_radius()`: it preserves the existing radius/length minimums, default group count, limb bonus clamp, spacing multiplier, and final `[0.18, 4.6]` clamp.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_contact_radius()` keeps the existing invalid-unit fallback of `0.12` and delegates valid-unit stats to the service.
- `_runtime_contact_constants()` now includes `attack_group_count` and `unit_body_spacing_mult` so the service receives the existing `ATTACK_GROUP_COUNT` and `UNIT_BODY_SPACING_MULT` values without direct `main.gd` constant access.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct radius outputs for explicit stats, default stats, and tiny-body minimum clamp, and rejects the old local body-radius/length formula fragments in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy unit-radius service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_contact_radius` service token, then exposed one incorrect expected default-radius value in the probe itself; after correcting the expected value for `unit_body_spacing_mult=1.0`, the probe passed cleanly.
- Fresh broadphase/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `collision_broadphase_skip_probe` (`skip=1`, `precise=0`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_contact_visual_identity_probe`, `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `one_shot_contact_probe` (`hp_after_first=100`), and `idle_collision_one_torso_damage_probe` (`hp_delta=20`).
- Runtime gates passed after the unit-radius wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.939`, `max_ms=3.527`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact effective-mass wrapper cleanup:

- `RuntimeContactService` now owns the pure valid-unit mass clamp through `unit_effective_mass()`, preserving the existing `mass` stat default and minimum effective mass of `1.0`.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_effective_mass()` keeps the existing invalid-unit fallback of `1.0` and delegates valid-unit stats to the service.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct outputs for positive/low/default mass stats, and rejects the old local `unit.stats.get("mass", 1.0)` clamp in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy effective-mass service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_effective_mass` service token, then passed after the service/main wrapper update.
- Fresh mass/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `collision_broadphase_skip_probe` (`skip=1`, `precise=0`), `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`), `same_unit_no_self_collision_probe` (`hp=100`), `same_shape_different_unit_collision_probe` (`a_delta=20`, `b_delta=20`), `one_shot_contact_probe` (`hp_after_first=100`), and `runtime_contact_visual_identity_probe`.
- Runtime gates passed after the effective-mass wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.972`, `max_ms=3.909`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact thruster-power wrapper cleanup:

- `RuntimeContactService` now owns the pure valid-unit thruster power formula through `unit_thruster_power()`, preserving the existing `max(boost_momentum, 0) / effective_mass` behavior and reusing the service-side `unit_effective_mass()` clamp.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_thruster_power()` keeps the existing invalid-unit fallback of `0.0` and delegates valid-unit stats to the service.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct outputs for normal, low-mass, negative-boost, and default stats, and rejects the old local `boost_momentum / mass` formula in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy thruster-power service token.
- `tools/attack_reaction_cancel_probe.gd` was updated from the stale legacy `recoil_cancel` fixture key to current runtime `reaction_cancel` semantics after systematic debugging showed the failing probe contradicted `runtime_no_legacy_drive_reads_probe`.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_thruster_power` service token, then passed after the service/main wrapper update.
- Fresh thruster/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `attack_reaction_cancel_probe` (`weak=31.92`, `strong=110.40`), `runtime_no_legacy_drive_reads_probe`, `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), and `boost_torso_collision_damage_probe` (`hp_delta=62/62`).
- Runtime gates passed after the thruster-power wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.299`, `max_ms=4.732`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact knockback-resist wrapper cleanup:

- `RuntimeContactService` now owns the pure valid-unit knockback-resist clamp through `unit_knockback_resist()`, preserving the existing default of `0.0` and clamp range `[0.0, 0.68]`.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_knockback_resist()` keeps the existing invalid-unit fallback of `0.0` and delegates valid-unit stats to the service.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct outputs for normal, negative, high, and default stats, and rejects the old local `unit.stats.get("knockback_resist", 0.0)` clamp in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy knockback-resist service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_knockback_resist` service token, then passed after the service/main wrapper update.
- Fresh impulse/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `attack_reaction_cancel_probe` (`weak=31.92`, `strong=110.40`), and `one_shot_contact_probe` (`hp_after_first=100`).
- Runtime gates passed after the knockback-resist wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.347`, `max_ms=20.391`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact impulse-motion wrapper cleanup:

- `RuntimeContactService` now owns the pure impulse-motion multiplier through `unit_impulse_motion_mult()`, preserving the existing `1.0 - knockback_resist * 0.72` slope and `[0.48, 1.12]` clamp.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_impulse_motion_mult()` keeps the existing invalid-unit neutral multiplier behavior by delegating empty stats to the service.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct outputs for default, normal, and high knockback-resist stats, and rejects the old local `_unit_knockback_resist(unit) * 0.72` formula in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy impulse-motion service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_impulse_motion_mult` service token, then passed after the service/main wrapper update.
- Fresh impulse/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `one_shot_contact_probe` (`hp_after_first=100`), and `runtime_penetration_no_velocity_kick_probe` (`before=0.0000`, `after=0.0796`).
- Runtime gates passed after the impulse-motion wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.069`, `max_ms=4.972`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact melee-stability threshold wrapper cleanup:

- `RuntimeContactService` now owns the pure valid-unit melee-stability threshold clamp through `unit_melee_stability_threshold()`, preserving the existing floor/default behavior via `melee_stability_threshold_floor`.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_melee_stability_threshold()` keeps the existing invalid-unit floor behavior by delegating empty stats and `_runtime_contact_constants()` to the service.
- `_runtime_contact_constants()` now includes `melee_stability_threshold_floor` so the service receives the existing `MELEE_STABILITY_THRESHOLD_FLOOR` value without direct `main.gd` constant access.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, floor constant handoff, direct outputs for normal, low, default, and custom-floor stats, and rejects the old local `unit.stats.get("melee_stability_threshold", MELEE_STABILITY_THRESHOLD_FLOOR)` formula in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy melee-stability-threshold service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_melee_stability_threshold` service token, then passed after the service/main wrapper update.
- Fresh stagger/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `resource_entry_probe` (`hitstop=0.50`), `battle_hit_resolution_service_contract_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), and `boost_torso_collision_damage_probe` (`hp_delta=62/62`).
- Runtime gates passed after the melee-stability-threshold wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.997`, `max_ms=3.649`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 runtime contact posture-anchor wrapper cleanup:

- `RuntimeContactService` now owns the pure valid-unit posture-anchor formula through `unit_posture_anchor()`, reusing service-side effective mass, thruster power, and knockback-resist helpers.
- `main.gd` still owns live unit validity checks and stats reads; `_unit_posture_anchor()` keeps the existing invalid-unit fallback of `0.0` and delegates valid-unit stats/opposing mass to the service.
- `tools/runtime_contact_service_contract_probe.gd` now guards the service token, lazy wrapper token, direct outputs for default, normal, and capped posture-anchor cases, and rejects the old local stabilization/thruster-anchor formula in `main.gd`.
- `tools/main_controller_boundary_probe.gd` was updated to include the lazy posture-anchor service token.
- Fresh RED/GREEN verification passed through `runtime_contact_service_contract_probe`: the probe first failed on the missing `unit_posture_anchor` service token, then passed after the service/main wrapper update.
- Fresh posture/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `runtime_contact_service_contract_probe`, `main_controller_boundary_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `one_shot_contact_probe` (`hp_after_first=100`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the posture-anchor wrapper cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.027`, `max_ms=3.864`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 melee momentum stagger-pair intent cleanup:

- `BattleHitResolutionService.momentum_response_intent()` now owns the pure melee momentum stagger-pair decision under `kind = "melee_momentum_stagger_pair"`: mech-pair gating, momentum gap, collision required-gap uplift, gate timing, duration clamp, source/staggered side selection, max-momentum payload, and ripple-scale calculation.
- `main.gd` still owns live unit sampling and side effects in `_apply_melee_momentum_stagger_pair()`: unit role checks, candidate threshold/meta reads, `Time` sampling, `apply_melee_stagger()`, combo opening, local hitstop, Mobius impact positioning, VFX, and battle messages.
- `tools/battle_hit_resolution_service_contract_probe.gd` now guards the service token, the `main.gd` intent handoff token, direct service outputs for normal stagger, collision required-gap blocking, and active gate blocking, and rejects the old inline ratio/duration formula in `_apply_melee_momentum_stagger_pair()`.
- Fresh RED/GREEN verification passed through `battle_hit_resolution_service_contract_probe`: the probe first failed on the missing `melee_momentum_stagger_pair` service token, then passed after the service/main wrapper update.
- Fresh stagger/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_hit_resolution_service_contract_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `one_shot_contact_probe` (`hp_after_first=100`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the melee momentum stagger-pair intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.276`, `max_ms=3.786`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile weapon-recoil intent cleanup:

- `ProjectileRuntimeService.weapon_recoil_intent()` now owns the pure weapon-recoil decision after `main.gd` samples live facts: projectile/applied gates, projectile velocity validation, launch-momentum validation, shooter-mass clamp, recoil amount, recoil direction, and the event patch for `weapon_recoil_*` fields.
- `main.gd` still owns live shooter validation, the early no-projectile/already-applied short-circuit that avoids unnecessary projectile momentum mutation, projectile velocity/momentum sampling, applying the returned event patch, and dispatching `apply_projectile_recoil()` / `apply_recoil()`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct recoil intent outputs, no-projectile/already-applied/no-velocity gates, and rejects the old inline recoil-amount formula plus direct `weapon_recoil_momentum` event write in `main.gd`.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `weapon_recoil_intent` service token, then passed after the service/main wrapper update.
- Fresh projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), `salvo_arc_preview_release_fire_probe` (`ammo=2`), `salvo_arc_unique_fire_probe` (`tap=1.35`, `hold=3.80`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the weapon-recoil intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.129`, `max_ms=2.835`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Systematic debugging note: `web_tether_no_projectile_damage_probe` was run during exploratory verification and was not counted as passed because it prints `ERROR` despite exit code `0`; root cause is the existing direct-runtime-topology + explicit-gun web path using immediate GPU projectile query, which returns no hit in macOS headless where `RenderingDevice` / GPU compute is unavailable. This is separate from the weapon-recoil intent cleanup.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile collision-momentum intent cleanup:

- `ProjectileRuntimeService.projectile_collision_momentum_intent()` now owns the pure projectile collision-momentum calculation after `main.gd` samples live facts: projectile speed, fallback direction, target velocity, relative velocity, closing speed, scaled momentum, true-bullet explicit-momentum override, and the event patch for projectile momentum diagnostics.
- `main.gd` still owns live projectile velocity direction sampling, target/collider velocity sampling, projectile mass/default momentum resolution, applying the returned event patch, and all later hit resolution, stagger, damage, VFX, and queue side effects.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct collision-momentum outputs, true-bullet override behavior, no-projectile gate, and rejects the old inline relative-velocity / closing-speed / momentum formula in `main.gd`.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `projectile_collision_momentum_intent` service token, then passed after the service/main wrapper update.
- Fresh projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the projectile collision-momentum intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.981`, `max_ms=8.375`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known caveat remains: direct-runtime-topology web tether immediate GPU query is environment-sensitive in macOS headless and was not used as a passing verification signal for this cleanup.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile stagger impact-position intent cleanup:

- `ProjectileRuntimeService.projectile_stagger_impact_position_intent()` now owns the pure projectile-stagger impact-position priority: prefer `hit_position_combat`, fall back to `projectile_impact_position`, then fall back to the sampled target combat position.
- `main.gd` still owns live target position sampling and all stagger side effects in `_apply_projectile_momentum_stagger()`: target metadata, `apply_melee_stagger()`, combo opening, local hitstop, ripple spawning, impulse application, optional physics impulse, and battle messages.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct outputs for hit-position priority, projectile-impact fallback, target-position fallback, and rejects the old inline `hit_position_combat` / `projectile_impact_position` branch in `main.gd`.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `projectile_stagger_impact_position_intent` service token, then passed after the service/main wrapper update.
- Fresh projectile/stagger verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `battle_hit_resolution_service_contract_probe`, `sniper_hit_vfx_on_target_probe` (`effects=2`), `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the projectile stagger impact-position intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.514`, `max_ms=5.407`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-branch `rg` check confirmed the old inline impact-position branch is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 melee pair impact-position intent cleanup:

- `BattleHitResolutionService.melee_pair_impact_position_intent()` now owns the pure Mobius midpoint calculation used by melee momentum stagger-pair feedback.
- `main.gd` still owns live unit sampling and all side effects in `_apply_melee_momentum_stagger_pair()`: Mobius delta sampling, stagger application, combo opening, local hitstop, ripple/VFX spawning, and battle messages.
- `tools/battle_hit_resolution_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, wrapped/direct midpoint outputs, and rejects the old inline `b_near_x` / `wrapf(lerpf(...))` calculation in `_apply_melee_momentum_stagger_pair()`.
- Fresh RED/GREEN verification passed through `battle_hit_resolution_service_contract_probe`: the probe first failed on the missing `melee_pair_impact_position_intent` service token, then passed after the service/main wrapper update.
- Fresh melee/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_hit_resolution_service_contract_probe`, `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `boost_torso_collision_damage_probe` (`hp_delta=62/62`), `one_shot_contact_probe` (`hp_after_first=100`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the melee pair impact-position intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.810`, `max_ms=23.491`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-formula `rg` check confirmed the old midpoint calculation is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile first-hit consumption decision cleanup:

- `ProjectileRuntimeService.projectile_consumes_on_first_hit()` now owns the pure projectile first-hit consumption decision: projectile gate, non-damage gate, blocked projectile styles, projectile damage-type allowlist, and consuming projectile styles.
- `main.gd` still owns event normalization, ammo consumption, first-impact routing, projectile trace spawning, hit resolution, damage, VFX, and queue side effects; `_projectile_consumes_on_first_hit()` is now a wrapper around the service.
- `_projectile_runtime_constants()` now passes `PROJECTILE_DAMAGE_TYPES` as `projectile_damage_types`, preserving the existing damage taxonomy source while keeping the service pure.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct outputs for bullet, web-style, non-damage, missile-style, and non-projectile cases, and rejects the old inline first-hit consumption branch in `main.gd`.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `projectile_consumes_on_first_hit` service token, then passed after the service/main wrapper update.
- Fresh projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `battle_hit_resolution_service_contract_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), `salvo_arc_preview_release_fire_probe` (`ammo=2`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `sniper_hit_vfx_on_target_probe` (`effects=2`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the projectile first-hit consumption decision cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.935`, `max_ms=1.895`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-branch `rg` check confirmed the old inline first-hit consumption decision is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile projection intent cleanup:

- `BattleImpactQueryService.projectile_projection_intent()` now owns the pure projectile projection calculation from a sampled Mobius delta: attacker-live gate, direction fallback, direction normalization, and dot-product projection.
- `main.gd` still owns live attacker validation and Mobius delta sampling in `_projectile_projection_from()`; target enumeration, locked-target checks, occlusion checks, hit probing, GPU queries, and first-impact selection side effects remain outside this service method.
- `tools/battle_impact_query_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct outputs for valid direction, fallback direction, and dead attacker cases, and rejects the old inline normalization/dot projection formula in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `projectile_projection_intent` service token, then passed after the service/main wrapper update. During verification, the probe expectation for `Vector2.UP` was corrected after systematic debugging showed Godot's up vector produces a negative Y dot product.
- Fresh projectile impact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_impact_query_service_contract_probe`, `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `mobius_projectile_trace_projection_probe` (`start=(541.5385, 364.0)`, `end=(649.8461, 467.3846)`), `map_occlusion_projectile_integration_probe`, `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the projectile projection intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.219`, `max_ms=5.447`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-formula `rg` check confirmed the old inline projectile projection formula is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 true-bullet before-locked-target intent cleanup:

- `BattleImpactQueryService.true_bullet_before_locked_target_intent()` now owns the pure true-bullet blocker ordering decision from sampled projection distances: reject negative unit projection, reject units at or beyond the locked target clearance, and accept units clearly before the locked target.
- `main.gd` still owns live unit validation, direction sampling, Mobius projection distance sampling, map occlusion, blocker enumeration, `_attack_part_hit()`, and actual target filtering in `_true_bullet_target_blocked()` / `_first_projectile_impact()`.
- `tools/battle_impact_query_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, direct outputs for before-target, behind-attacker, and at/beyond-target cases, and rejects the old inline `unit_distance >= 0.0 and unit_distance <= target_distance - 0.035` formula in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `true_bullet_before_locked_target_intent` service token, then passed after the service/main wrapper update.
- Fresh true-bullet/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_impact_query_service_contract_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the true-bullet before-locked-target intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.991`, `max_ms=50.560`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-formula `rg` check confirmed the old true-bullet before-target comparison is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projection-to-target service delegation cleanup:

- `_projection_to_target()` now delegates its pure projection calculation through `BattleImpactQueryService.projectile_projection_intent()`, reusing the existing service-owned direction fallback, direction normalization, and dot-product projection rules.
- `main.gd` still owns live attacker/target validation, `_mobius_delta_vec_between()` sampling, and the true-bullet blocker/target filtering flow around `_projection_to_target()`.
- `tools/battle_impact_query_service_contract_probe.gd` now rejects the old `_projection_to_target()` inline `delta.dot(direction.normalized() ... _unit_forward_vector(attacker))` formula in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the stale inline `_projection_to_target()` formula, then passed after the main wrapper delegation update.
- Fresh true-bullet/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_impact_query_service_contract_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the projection-to-target delegation cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.912`, `max_ms=9.597`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-formula `rg` check confirmed the old `_projection_to_target()` inline projection formula is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 GPU projectile query-ray intent cleanup:

- `BattleImpactQueryService.gpu_projectile_query_ray_intent()` now owns the pure GPU projectile query-ray calculation: preserve the original collider endpoint for a zero direction, normalize valid directions, keep the query reach at least as long as the attack collider, and extend the endpoint to the requested projectile range.
- `main.gd` still owns attack-collider acquisition, live unit checks, event reads, target/collider enumeration, map occlusion sampling, GPU buffer construction, deferred/immediate query submission, hit selection, and all later damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards the service/main handoff, direct outputs for requested-range extension, collider-length minimum, and zero-direction preservation, and rejects the old inline range/`GameplayTransform.projectile_ray()` block in `_first_projectile_impact_gpu()`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `gpu_projectile_query_ray_intent` service token, then passed after the service and main wrapper update.
- Fresh GPU/query verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gpu_query_deferred_consumers_probe`, `gpu_no_hot_rd_sync_probe`, `runtime_no_cpu_geometry_probe`, `map_occlusion_projectile_integration_probe`, and `aim_line_straight_euclidean_probe` (`pixels=295.38`).
- Fresh projectile verification passed: `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the GPU projectile query-ray intent cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.950`, `max_ms=2.687`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-formula `rg` check confirmed the old inline GPU query-ray range and `GameplayTransform.projectile_ray(start, direction, range)` calls are no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`; RenderingDevice-dependent GPU compute probes are still not treated as passing evidence in this environment.

2026-06-13 P5 GPU projectile query-payload cleanup:

- `BattleImpactQueryService.gpu_projectile_query_payload()` now owns the pure GPU projectile query dictionary contract: start/end vectors, non-negative query radius, owner unit/team keys, query id, and friendly-hit flag.
- `_first_projectile_impact_gpu()` in `main.gd` still owns live attacker/collider sampling, event value sampling, target enumeration, GPU collider assembly, deferred/immediate query submission, target mapping, occlusion sampling, hit selection, and all downstream damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards the service/main handoff, direct field preservation, default owner/query/friendly values, negative-radius clamping, and rejection of the old inline GPU query dictionary shape.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `gpu_projectile_query_payload` token, then exposed an over-broad stale guard that also matched the valid service input. Systematic debugging narrowed that guard to the old direct-dictionary `}]` ending, after which the service/main update passed.
- Fresh GPU/query and projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gpu_query_deferred_consumers_probe`, `gpu_no_hot_rd_sync_probe`, `runtime_no_cpu_geometry_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), and `sniper_hit_vfx_on_target_probe` (`effects=2`).
- Runtime gates passed after the GPU projectile query-payload cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.045`, `max_ms=8.489`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-shape check confirms the old inline clamped-radius/query dictionary is no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`; RenderingDevice-dependent GPU compute remains outside the passing local evidence set.

2026-06-13 P5 GPU projectile target-entry pure-data cleanup:

- `BattleImpactQueryService.gpu_projectile_target_entry_payload()` now owns the pure conversion from a runtime GPU collider entry into the service-facing target entry: shallow-copy the source fields, remove the runtime `unit` reference, and attach target index, live state, occlusion state, and optional sampled target position.
- `_first_projectile_impact_gpu()` in `main.gd` still owns the live target reference, `_is_live_unit()` check, entry-to-target index mapping, map occlusion query, target combat-position sampling, GPU query submission, selected-target validation, and all downstream hit/damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards the service/main handoff, source-field preservation, runtime-unit removal, source dictionary immutability, live target metadata, and dead-target position omission; it also rejects the old inline `entry.erase("unit")` / target-index mutation in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `gpu_projectile_target_entry_payload` service token, then passed after the service and main handoff update.
- Fresh GPU/query and projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gpu_query_deferred_consumers_probe`, `gpu_no_hot_rd_sync_probe`, `runtime_no_cpu_geometry_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), and `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`).
- Runtime gates passed after the GPU projectile target-entry cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.169`, `max_ms=5.377`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-fragment check confirms direct runtime-unit erasure and target-index mutation are no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`; RenderingDevice-dependent GPU compute remains outside the passing local evidence set.

2026-06-13 P5 GPU projectile selection-result intent cleanup:

- `BattleImpactQueryService.gpu_projectile_selection_result_intent()` now owns the pure post-selection decision and extraction contract: reject empty selections, reject missing/out-of-range target indices, and expose accepted target index, hit payload, optional explicit position, and distance.
- `_first_projectile_impact_gpu()` in `main.gd` still owns the target Node array, selected Node lookup, final `_is_live_unit()` validation, target-position fallback sampling, GPU submission, and all downstream hit/damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards empty and invalid-index rejection, valid hit/position/distance extraction, absence of a fabricated position when the selection has none, and the service/main handoff; it rejects the old inline selected-entry extraction and bounds check in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `gpu_projectile_selection_result_intent` service token, then passed after the service and main handoff update.
- Fresh GPU/query and projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gpu_query_deferred_consumers_probe`, `gpu_no_hot_rd_sync_probe`, `runtime_no_cpu_geometry_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), and `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`).
- Runtime gates passed after the GPU projectile selection-result cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.992`, `max_ms=2.895`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- A stale-fragment check confirms the old selected-entry dictionary read and target-index bounds branch are no longer present in `scripts/main.gd`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`; RenderingDevice-dependent GPU compute remains outside the passing local evidence set.

2026-06-13 P5 GPU projectile final-impact payload cleanup:

- `BattleImpactQueryService.gpu_projectile_final_impact_payload()` now owns the pure final non-Node impact payload after GPU selection: reject a no-longer-live target, prefer explicit selection position, fall back to the sampled target position, and expose hit/distance fields.
- `_first_projectile_impact_gpu()` in `main.gd` still owns selected target Node lookup, `_is_live_unit()` sampling, target-position sampling, adding the selected target Node back into the returned result, GPU submission, and all downstream hit/damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards dead-target rejection, explicit selection-position priority, target-position fallback, service/main handoff, and rejection of the old inline `selection_result.get("position", Vector2(selected_target.ring_pos, selected_target.lane))` fallback in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `gpu_projectile_final_impact_payload` service token, then passed after the service and main handoff update.
- Fresh GPU/query and projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `gpu_query_deferred_consumers_probe`, `gpu_no_hot_rd_sync_probe`, `runtime_no_cpu_geometry_probe`, `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), and `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`).
- Runtime gates passed after the GPU projectile final-impact payload cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.308`, `max_ms=8.452`), `--headless --check-only --script res://scripts/main.gd`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`; RenderingDevice-dependent GPU compute remains outside the passing local evidence set.

2026-06-13 P5 projectile selection/final-impact payload cleanup:

- `BattleImpactQueryService.projectile_selection_result_intent()` now owns the pure non-GPU projectile selection-result contract after `first_impact_selection()`: reject empty selections, reject missing/out-of-range target indices, and expose accepted target index, hit payload, optional explicit position, and distance.
- `BattleImpactQueryService.projectile_final_impact_payload()` now owns the pure non-Node final impact payload: reject a no-longer-live target, prefer explicit selection position, fall back to the sampled target position, and expose hit/distance fields.
- `_first_projectile_impact()` in `main.gd` still owns target enumeration, locked-target checks, map occlusion and `_attack_part_hit()` sampling, candidate target Node storage, selected target Node lookup, final `_is_live_unit()` sampling, target-position sampling, and all downstream hit/damage/VFX side effects.
- `tools/battle_impact_query_service_contract_probe.gd` now guards empty and invalid-index rejection, valid selection extraction, explicit/fallback final position handling, dead-target rejection, service/main handoff, and rejection of the old inline `selection.get("position", Vector2(selected_target.ring_pos, selected_target.lane))` fallback in `main.gd`.
- Fresh RED/GREEN verification passed through `battle_impact_query_service_contract_probe`: the probe first failed on the missing `projectile_selection_result_intent` service token, then passed after the service and main handoff update.
- Fresh projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `map_occlusion_projectile_integration_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the projectile selection/final-impact cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.926`, `max_ms=2.542`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, and `git diff --check`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 target-acquisition selected-index intent cleanup:

- `BattleTargetAcquisitionService.selected_target_index_intent()` now owns the pure selected-target index bounds decision shared by true-bullet and missile target acquisition: accept valid target indices, reject missing negative indices, and reject out-of-range indices with stable reason keys.
- `_acquire_true_bullet_target()` and `_acquire_missile_lock_target()` in `main.gd` still own live unit traversal, hit/occlusion/direction sampling, candidate target Node storage, selected Node lookup, final `_is_live_unit()` validation, pending shot/projectile state, and all battle side effects.
- `tools/battle_target_acquisition_service_contract_probe.gd` now guards the service token, direct valid/negative/out-of-range outputs, `main.gd` handoff token, and rejection of the old inline target-index bounds branch.
- Fresh RED/GREEN verification passed through `battle_target_acquisition_service_contract_probe`: the probe first failed on the missing `selected_target_index_intent` service method, then passed after the service/main wrapper update.
- Fresh target acquisition verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `sniper_edge_target_lock_probe` (`distance=0.56`), `missile_lock_priority_screen_role_probe`, `missile_lock_priority_near_probe`, `missile_lock_priority_far_probe`, `missile_lock_barrier_support_probe`, `map_occlusion_projectile_integration_probe`, and `missile_lock_runtime_fire_probe`.
 - Runtime gates passed after the selected-index cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.961`, `max_ms=6.435`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline `selection.get("target_index", -1)` branch.
 - Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile ammo-type boundary cleanup:

- `ProjectileRuntimeService.ammo_type_for_event()` now owns the pure projectile event ammo-type parser used before ammo consumption: normalize explicit ammo aliases such as missile/explosion, silk/thread, and acid/chemical_splash, prefer valid explicit ammo kinds, then fall back to valid projectile/damage types.
- `_ammo_type_for_event()` in `main.gd` is now a thin wrapper over the service. `main.gd` still owns projectile gate checks, live attacker ammo capacity/current reads, fail SFX, empty-ammo messages, ammo meta mutation, heat application, projectile queues, and all firing side effects.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, direct alias/fallback/reject outputs, `main.gd` handoff token, and rejection of the old inline ammo-type parser body.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `ammo_type_for_event` service token, then passed after the service/main wrapper update.
- Fresh ammo/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `missile_ammo_heat_probe` (`ammo=2`, `heat=34.0`), `chemical_heat_probe` (`queued=true`, `impact=true`, `dot=true`, `hp=120->105->64`, `heat=44.00`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `gun_activate_native_semantic_dispatch_probe` (`count=7`), and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the projectile ammo-type cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.927`, `max_ms=2.932`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline `_ammo_type_for_event()` parser.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile event-vector parsing cleanup:

- `ProjectileRuntimeService.event_vector_value()` now owns the pure Vector2 field extraction helper used by projectile/momentum event parsing, returning `Vector2.ZERO` for missing or non-vector values.
- `ProjectileRuntimeService.event_momentum_magnitude()` now owns the pure event momentum magnitude fallback chain: prefer `momentum_vector` length, then clamped `momentum_magnitude`, then clamped `momentum`, then clamped fallback.
- `_event_vector_value()` and `_event_momentum_magnitude()` in `main.gd` are now thin wrappers over the service. `main.gd` still owns Node-aware direction fallback in `_event_direction_vector()`, Mobius delta sampling, unit-forward sampling, event mutation through `_set_event_momentum_vector()`, projectile collision side effects, reflection/explosion event copies, hit displacement, VFX/SFX, and all damage application.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service tokens, direct vector/magnitude fallback outputs, `main.gd` handoff tokens, and rejection of the old inline event-vector and event-momentum parser bodies.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `event_vector_value` service token, then passed after the service/main wrapper update.
- Fresh projectile/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `resource_entry_probe` (`hitstop=0.50`), and `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`).
- Runtime gates passed after the projectile event-vector cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.863`, `max_ms=1.889`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and multiline stale `rg` checks for the old inline `_event_vector_value()` and `_event_momentum_magnitude()` parser bodies.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile event-direction fallback cleanup:

- `ProjectileRuntimeService.event_direction_vector()` now owns the pure direction priority and normalization chain used by projectile and hit-response events: prefer `momentum_vector`, then explicit `direction`, sampled target delta, sampled attacker forward, explicit fallback, and finally `Vector2.RIGHT`.
- `_event_direction_vector()` in `main.gd` is now a thin scene-aware wrapper: it still owns attacker/target validity checks, Mobius delta sampling, and unit-forward sampling, then hands those plain vectors to the service. Damage application, VFX/SFX, projectile queues, contact response, and all Node-side effects remain in `main.gd`.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, direct priority/fallback outputs, `main.gd` handoff token, and rejection of the old inline event-direction parser body.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `event_direction_vector` service token, then passed after the service/main wrapper update.
- Fresh projectile/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `projectile_trace_aim_line_same_origin_probe` (`origin=(764.0616, 317.7231)`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `resource_entry_probe` (`hitstop=0.50`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), and `map_occlusion_projectile_integration_probe`.
- Runtime gates passed after the projectile event-direction cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.118`, `max_ms=5.106`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a multiline stale `rg` check for the old inline `_event_direction_vector()` parser body.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile event-momentum patch cleanup:

- `ProjectileRuntimeService.event_momentum_vector_patch()` now owns the pure event-field shaping rule used by melee momentum, reflection, shield reflection, and explosion paths: always expose `momentum_vector` and resolved `momentum_magnitude`, infer magnitude from vector length when no explicit non-negative value is supplied, and only expose normalized `direction` when both magnitude and vector are non-zero.
- `_set_event_momentum_vector()` in `main.gd` now applies the returned patch to the live event dictionary. `main.gd` still owns event mutation, Node traversal, runtime collision sampling, reflection target selection, explosion target traversal, damage, stagger, VFX/SFX, and all other battle side effects.
- `tools/projectile_runtime_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, inferred/explicit-zero/zero-vector outputs, and rejection of the old inline momentum-vector field rules.
- Fresh RED/GREEN verification passed through `projectile_runtime_service_contract_probe`: the probe first failed on the missing `event_momentum_vector_patch` service token, then passed after the service/main wrapper update.
- Fresh momentum/projectile/contact verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `projectile_runtime_service_contract_probe`, `sniper_projectile_momentum_probe` (`momentum=123.0`, `speed=999.0`, `mass=0.1231`), `runtime_collision_momentum_probe` (`attacker_v=1.0000`, `target_v=1.0000`), `contact_normal_momentum_probe` (`tangent=0`, `normal=124`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `battle_projectile_lifecycle_service_contract_probe`, `battle_hit_resolution_service_contract_probe`, `gun_recoil_momentum_probe` (`velocity=(-5.0, 0.0)`), `gun_drive_projectile_momentum_probe` (`under=600.0`, `full=1200.0`, `mult=1.00`), `runtime_contact_damage_probe` (`hp_delta=212`, `target_v=9.600`), `hammer_windup_slam_contact_probe`, `shield_guard_bash_contact_probe`, `sniper_hit_vfx_on_target_probe` (`effects=2`), `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the event-momentum patch cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.865`, `max_ms=30.578`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a multiline stale `rg` check for the old inline `_set_event_momentum_vector()` body.
- `projectile_momentum_probe` remains excluded from passing evidence because it reproduces the already documented explosive-preflight contract conflict: the probe expects legacy splash/stagger from `explosion_damage`, while `BattleHitResolutionService.projectile_preflight_intent()` intentionally requests `erase_explosion_damage` and `erase_explosion_damage_type`. This migration did not alter that behavior or resolve the separate design decision.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 target projectile-shield reflection gate cleanup:

- `BattleProjectileLifecycleService.target_projectile_shield_reflects()` now owns the pure target-shield reflection eligibility rule: reject non-live targets, reject expired shield timers, allow all projectile damage types when the reflect-type list is empty, and otherwise require the incoming damage type to be present in that list.
- `_target_projectile_shield_reflects()` in `main.gd` now samples live target state, `projectile_shield_timer`, and the active/meta-or-stats reflect type list, then delegates the decision to the lifecycle service. Target Node access, shield meta storage, reflection event copies, target traversal, damage, VFX/SFX, and all other side effects remain in `main.gd`.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, dead/expired/empty-list/matching/non-matching outputs, and rejection of the old inline reflection eligibility body.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `target_projectile_shield_reflects` service token, then passed after the service/main wrapper update.
- Fresh shield/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`), `projectile_runtime_service_contract_probe`, `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, and `resource_entry_probe` (`hitstop=0.50`).
- Runtime gates passed after the target projectile-shield reflection cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.194`, `max_ms=4.607`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a multiline stale `rg` check for the old inline `_target_projectile_shield_reflects()` body.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 projectile reflector candidate cleanup:

- `BattleProjectileLifecycleService.projectile_reflector_candidate_intent()` now owns the pure ordinary-reflector candidate gate: reject the attacker itself, reject non-live reflectors, reject units without `reflect_projectiles`, allow all damage types for an empty reflect-type list, and otherwise require an exact incoming damage-type match.
- `_apply_projectile_reflection()` in `main.gd` still owns friendly-unit traversal, live Node and stats sampling, Mobius delta sampling, candidate Node storage, fallback randomness, event mutation, aura/VFX/SFX, and battle messages. It now asks the lifecycle service whether each sampled reflector should enter the existing distance/angle scoring path.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, self/live/enabled/empty-list/type-match outputs, stable rejection reasons, and rejection of the old inline reflector candidate filter.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `projectile_reflector_candidate_intent` service token, then passed after the service/main wrapper update.
- Fresh reflection/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_path_not_bent_by_mobius_probe` (`distance=0.950`), `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the projectile reflector candidate cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.008`, `max_ms=4.379`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a multiline stale `rg` check for the old inline reflector candidate filter.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 target shield reflected-target cleanup:

- `BattleProjectileLifecycleService.target_shield_reflected_target_intent()` now owns the pure second-hop target gate used after target shield reflection: reject the original attacker, reject the source shield target, reject non-live targets, then apply the existing distance, lane, and reflected-direction checks with stable rejection reasons.
- `_reflect_projectile_from_target_shield()` in `main.gd` still owns enemy traversal, live Node sampling, Mobius delta sampling, target radius sampling, event-copy shaping, damage/material adjustment, hitstop, VFX/SFX, and `take_hit()` side effects. It now delegates only the pure include/reject decision to the lifecycle service.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, attacker/source/dead/range/lane/direction/include outputs, and rejection of the old inline reflected-target filter body.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `target_shield_reflected_target_intent` service token, then passed after the service/main handoff update.
- Fresh shield/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the target shield reflected-target cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.026`, `max_ms=3.987`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline reflected-target distance/lane/direction body.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 explosion target candidate cleanup:

- `BattleProjectileLifecycleService.explosion_target_candidate_intent()` now owns the pure target-candidate gate used before explosion falloff and damage payload construction: reject non-live targets first, reject the primary impact target next, and otherwise include the target with a stable reason.
- `_apply_explosion_damage()` in `main.gd` still owns attacker validation, enemy traversal, Mobius delta sampling, target radius sampling, event-copy mutation, falloff damage application, material adjustment, combo scaling, momentum stagger, hitstop, VFX/SFX, and `take_hit()` side effects. It now delegates only the candidate include/reject decision to the lifecycle service.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, target-gone/primary/include outputs, and rejection of the old inline `not _is_live_unit(target) or target == primary_target` filter body.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `explosion_target_candidate_intent` service token, then passed after the service/main handoff update.
- Fresh projectile/explosion-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the explosion target candidate cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.870`, `max_ms=15.937`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline explosion target-candidate filter.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 explosion request parsing cleanup:

- `BattleProjectileLifecycleService.explosion_request_intent()` now owns the pure explosion-event request parser used by `_apply_explosion_damage()`: reject non-positive `explosion_damage`, clamp explosion radius to the existing `0.08` minimum, preserve integer explosion damage, resolve `explosion_damage_type` with the existing `damage_type` fallback, and expose the explosion style used by the existing falloff/stagger intent.
- `_apply_explosion_damage()` in `main.gd` still owns attacker validation, primary-center Node sampling, initial hit effect fallback styling, enemy traversal, Mobius delta sampling, target radius sampling, event-copy mutation, falloff damage application, material adjustment, combo scaling, momentum stagger, hitstop, VFX/SFX, and `take_hit()` side effects. It now delegates only the pure explosion request parsing/gate to the lifecycle service.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, no-damage/radius/type/style outputs, and rejection of the old inline `explosion_radius` / `explosion_damage` / `explosion_damage_type` parser body.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `explosion_request_intent` service token, then passed after the service/main handoff update.
- Fresh projectile/explosion-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the explosion request parsing cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.283`, `max_ms=4.992`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline explosion request parser.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 explosion center selection cleanup:

- `BattleProjectileLifecycleService.explosion_center_position()` now owns the pure center-position choice used by `_apply_explosion_damage()`: use the primary target position when `main.gd` sampled a valid primary target, otherwise use the attacker position, and expose a stable `source` reason.
- `_apply_explosion_damage()` in `main.gd` still owns attacker validation, primary target Node validity checks, attacker/primary position sampling, initial hit effect fallback styling, enemy traversal, Mobius delta sampling, target radius sampling, event-copy mutation, falloff damage application, material adjustment, combo scaling, momentum stagger, hitstop, VFX/SFX, and `take_hit()` side effects. It now delegates only the pure center-position selection to the lifecycle service.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, attacker/primary center outputs, stable source strings, and rejection of the old inline `center_ring` / `center_lane` selection body.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `explosion_center_position` service token, then passed after the service/main handoff update.
- Fresh projectile/explosion-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the explosion center selection cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.909`, `max_ms=1.683`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline explosion center selection body.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 explosion initial effect anchor cleanup:

- `BattleProjectileLifecycleService.explosion_initial_effect_anchor_intent()` now owns the pure initial explosion hit-effect anchor choice: use the primary target anchor when `main.gd` sampled a valid primary target, otherwise use the attacker anchor, and expose a stable `source` value.
- `_apply_explosion_damage()` in `main.gd` still owns primary target Node validity checks, actual Node target selection, `_spawn_hit_effect()` calls, initial hit-effect style fallback, enemy traversal, Mobius delta sampling, falloff damage application, material adjustment, combo scaling, momentum stagger, hitstop, VFX/SFX, and `take_hit()` side effects. It now delegates only the source decision for the initial hit-effect anchor to the lifecycle service.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, attacker/primary source outputs, and rejection of the old inline `_spawn_hit_effect(primary_target if primary_target ... else attacker, ...)` anchor expression.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `explosion_initial_effect_anchor_intent` service token, then passed after the service/main handoff update.
- Fresh projectile/explosion-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the explosion initial effect anchor cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.042`, `max_ms=6.372`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg` check for the old inline explosion initial effect anchor expression.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 explosion hit block cleanup:

- `BattleProjectileLifecycleService.explosion_hit_block_intent()` now owns the pure blocked-hit decision used after explosion falloff damage and projectile-material adjustment: block non-positive final damage first, block explicit `contact_gate_blocked` events next, and otherwise allow the hit to continue with stable reason strings.
- `_apply_explosion_damage()` in `main.gd` still owns falloff damage calculation, vulnerability sampling, material adjustment, combo scaling, target VFX/SFX, stagger event shaping, hitstop, blocked-hit skip behavior, and `take_hit()` side effects. It now delegates only the pure blocked/not-blocked decision to the lifecycle service after final damage and contact-gate facts have been sampled.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now guards the service token, `main.gd` handoff token, no-damage/contact-gate/pass outputs, and rejection of the old inline explosion-path `final_damage <= 0 or contact_gate_blocked` expression. The similar target-shield reflection blocked expression remains in `main.gd` for a later scoped cleanup.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `explosion_hit_block_intent` service token, then passed after the service/main handoff update and stale guard was narrowed to the explosion path.
- Fresh projectile/explosion-adjacent verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, `backfilled_ranged_weapon_fire_probe` (`samples=6`), and `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`).
- Runtime gates passed after the explosion hit block cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=2.753`, `max_ms=94.426`), `--headless --check-only --script res://scripts/main.gd`, `no_old_threshold_gate_probe`, `jq empty tools/probe_manifest.json`, `git diff --check`, and a stale `rg -U` check for the old inline explosion-path blocked-hit expression.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 shared projectile hit block cleanup:

- The explosion-only `BattleProjectileLifecycleService.explosion_hit_block_intent()` boundary is now named `projectile_hit_block_intent()` because the same pure post-material rule is shared by explosion splash hits and target-shield reflected hits: block non-positive final damage first, block explicit `contact_gate_blocked` events next, and otherwise allow the hit.
- `_apply_explosion_damage()` and `_reflect_projectile_from_target_shield()` now delegate that decision to the shared lifecycle service method. `main.gd` still owns live target traversal, vulnerability/material sampling, hit effects, reflected-hit `break` behavior, explosion `continue` behavior, hitstop, kill handling, and `take_hit()` side effects.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now requires exactly two `main.gd` handoffs to `projectile_hit_block_intent()`, verifies no-damage/contact-gate/pass outputs and stable reasons, and rejects the old inline blocked-hit expression in both explosion and target-shield reflection paths.
- Fresh RED/GREEN verification passed through `battle_projectile_lifecycle_service_contract_probe`: the probe first failed on the missing `projectile_hit_block_intent` service token, then passed after the service rename and target-shield handoff were implemented.
- Fresh shield/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_projectile_lifecycle_service_contract_probe`, `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`), `projectile_runtime_service_contract_probe`, `projectile_damage_formula_probe` (`raw=80.0`, `allocated=300.0`, `sniper=10.0`), `sniper_hit_vfx_on_target_probe` (`effects=2`), `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `map_occlusion_projectile_integration_probe`, and `backfilled_ranged_weapon_fire_probe` (`samples=6`).
- Runtime gates passed after the shared projectile hit block cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.445`, `max_ms=43.495`), `--headless --check-only --script res://scripts/main.gd`, and `no_old_threshold_gate_probe`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 P5 one-way projectile pass policy cleanup:

- `BattleMapOcclusionService.one_way_projectile_pass_intent()` now owns the pure one-way shield pass policy: `iff`/`ally` modes pass matching owners, `enemy` mode passes different owners, and directional mode compares projectile X direction against shield facing with the existing attacker-facing fallback and optional `reverse` shield direction.
- `_one_way_shield_allows_projectile()` in `main.gd` now only samples shield stats, owner ids, projectile direction, and live facing values before delegating to the map-occlusion service. Unit traversal, collider construction, gap/projection sampling, blocker Node storage, and final occlusion selection remain in `main.gd`.
- `tools/battle_map_occlusion_service_contract_probe.gd` now guards the service/main handoff, allied/IFF/enemy/directional/reverse/facing-fallback outputs, stable reason values, and rejection of the old inline one-way pass policy in `main.gd`.
- The first probe draft exposed a GDScript static type-inference error in the new test variables; after adding explicit `Dictionary` annotations, the valid RED failed on the missing `one_way_projectile_pass_intent` service method. The probe then passed after the service and `main.gd` wrapper update.
- Fresh map/projectile verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_map_occlusion_service_contract_probe`, `map_occlusion_kind_probe` (allied fire passes and enemy fire remains blocked), `map_occlusion_projectile_integration_probe`, `laser_projectile_gate_probe`, `missile_projectile_gate_probe`, `shield_probe` (`hp=100`, `shield=20.0`, `bar_width=165.0`), `projectile_runtime_service_contract_probe`, and `battle_projectile_lifecycle_service_contract_probe`.
- Runtime gates passed after the one-way projectile pass cleanup: `combat_probe` (`runtime_topology_contact=true`, `hp_delta=4`, `min_gap=-0.1200`, `segments=3`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.991`, `max_ms=2.805`), `--headless --check-only --script res://scripts/main.gd`, and `no_old_threshold_gate_probe`.
- Known macOS headless ObjectDB leak warnings remain non-blocking when the relevant probe exits with code `0`.

2026-06-13 functional optimization roadmap completion audit:

- The P0-P5 roadmap was re-audited against current source, probe registration, actual page/training/battle scenarios, and the 16 probes listed in `.github/workflows/godot-governance.yml`; completion was not inferred only from the accumulated worklog.
- P0 evidence is current: all nine architecture/mode probes pass, `probe_manifest_no_legacy_fixture_probe` reports `current=174` and `sections=8`, packed runtime folders are absent from tracked files, the macOS Godot path/version remains `4.6.2.stable.official.71f334935`, and the main-script check/static gates pass.
- P1 evidence is current: mode contracts pass, while `main_menu_navigation_probe`, `settings_return_target_probe`, `saved_units_return_target_probe`, `saved_units_back_to_editor_probe`, `battle_exit_runtime_cleanup_probe`, and the repaired `training_all_entrypoints_require_seat_probe` exercise actual transitions and cleanup behavior.
- The audit found that `training_all_entrypoints_require_seat_probe` depended on a personal saved unit named `2`; missing fixture errors did not return from `_fail()` paths and the final plain `quit()` could leave the probe falsely green. It now follows the existing frame-budget fixture pattern, uses a legal saved Unit2 when available, otherwise uses the generated training starter, returns immediately after failures, exits explicitly with code `0` only on success, and is registered in the manifest `current` set.
- P2 evidence is current: Team Edit controller contracts, connected-part protection, unconnected-part hints, pagination/layout, strict legacy-data rejection, actionable save feedback, `ui_layout_probe`, and `text_overflow_probe` pass without changing legality or save schema.
- P3 evidence is current: saved-unit focus/controller/library contracts, delete selection repair, return routing, training readiness feedback, missing-dummy fallback, import role preservation, multi-unit loadout, and explicit training seat confirmation all pass without silently accepting invalid units.
- P4 evidence is current: HUD display clamping/normal-state formatting, diagnostics shown/omitted counts, battle instrument rendering, cleanup visibility, bilingual layout, text overflow, and combat behavior pass; the final standalone runtime budget sample reports `fixture=generated_training_starter`, `avg_ms=0.971`, and `max_ms=2.954`.
- P5 evidence is current: the changed input, command, event, hit-resolution, impact-query, map-occlusion, projectile-lifecycle, target-acquisition, projectile-runtime, and runtime-contact service contracts pass while live Node traversal, mutation, Input reads, VFX/SFX, and damage application remain in `main.gd`.
- The full GitHub governance probe list passes locally, including action-profile completeness (`live=32`, `projectile=6`), action-module execution (`profiles=11`), Mobius projectile readability, controlled-unit battle centering (`seats=2`), battle VFX budget (`accepted=40`, `dropped=160`), and zero bilingual layout/overflow failures.
- Known macOS headless ObjectDB leak warnings remain non-blocking when exit code is `0`. Personal-save-only legacy probes are not used as completion evidence unless they provide a generated fixture fallback.

2026-06-27 Unit Editor legality preview and socket-kind ownership follow-up:

- `UnitEditorLegalityService.audit_socket_kinds()` now owns exact socket ownership, compatible root/distal/torso-port pairing, and one-edge-per-socket occupancy with stable bilingual reason codes.
- `main.gd` materializes those records from live `custom_topology` edges, checks the shared report before legacy topology notes, and renders a persistent bilingual `LegalityStatus` line in Unit Edit.
- `tools/unit_editor_legality_preview_slot_kind_probe.gd` covers explicit records, legal and corrupted live topology, the training/save gate, and the player-facing status model without persisting transient reports.
- The same UI pass removed the reproducible English core-tutorial overflow and moved the guide copy clear of the Core Detail button; all editor layout/overflow counts now return zero without expanding panel bounds.

2026-06-27 Unit Editor cross-entrypoint legality follow-up:

- `tools/unit_editor_legality_cross_entrypoint_probe.gd` now builds socket-size, socket-kind, and manufacturer-illegal topology variants from the legal starter fixture and verifies that the shared report preserves the expected stable code.
- The probe covers editor save rejection, saved-unit readback legality notes, team-normalized saved entries, direct battle-entry legality, saved-team load/import rejection, and the formal battle-entry summary without changing saved-unit topology storage.
- The Unit Editor legality roadmap now marks the broader saved-unit, saved-team, team-validation, and battle-entry fixture item as done; the next active guardrail remains schema invariance until a separate saved-unit migration plan exists.

2026-06-27 Unit Editor schema invariance follow-up:

- `tools/unit_editor_schema_invariance_probe.gd` now injects transient legality report fields into single-unit and puppet-group save inputs, then verifies those fields are absent from saved JSON while `momentum_chain_v3`, `single_unit` / `puppet_group`, and `custom_topology` keys remain stable.
- `main.gd` now strips Unit Editor legality transient save keys through the same recursive save-cleanup boundary that already removes hardware fault transient runtime fields.
- Puppet-group saves now normalize member blueprints through the canonical saved-unit blueprint path before writing the group payload, so nested member blueprints do not persist transient legality reports.

2026-06-28 Hardware fault movement dependency follow-up:

- `tools/hardware_fault_movement_dependency_probe.gd` now covers a live unit whose primary core faults on the first overload: the unit remains alive, normal movement works before the fault, and `move_by_gameplay()` is blocked afterward with a hardware fault gate reason.
- `main.gd` syncs primary-core hardware fault state into unit movement gate metadata, while `fighter.gd` consumes that metadata before applying drive movement.
- This extends the non-module hardware dependency audit from gun/module queues into core movement dependency behavior; remaining non-module sources should continue to be audited separately.

2026-06-28 Hardware fault generated primary core follow-up:

- `tools/hardware_fault_primary_core_materialization_probe.gd` now computes puppet runtime topology from a real custom-topology blueprint and verifies each generated construct body carries its stable `construct_body_id` and `primary_core_node_id`.
- Runtime topology generation marks each connected component with its torso primary core, and Source Code body assignment writes that same primary core alongside stable body IDs on runtime nodes and segments.
- The probe then uses generated colliders to confirm a primary core's second overload emits `destroy_construct_body`, retires the live unit, and awards VP, instead of depending on hand-authored fixture metadata.

2026-06-28 Hardware fault boost dependency follow-up:

- `tools/hardware_fault_boost_dependency_probe.gd` now covers the Boost action path separately from normal drive movement: a healthy primary core can boost, but a faulted primary core blocks Boost and reports a hardware fault gate reason.
- `fighter.gd` now checks `hardware_fault_movement_blocked` at the Boost entry point before starting boost timers, heat events, projection guards, or thruster visuals.

2026-06-28 Hardware fault non-primary core destruction follow-up:

- `tools/hardware_fault_non_primary_core_destruction_probe.gd` now covers a multi-core-like construct body whose secondary `torso` segment points back to a different `primary_core_node_id`.
- The probe verifies that destroying that secondary core-like segment emits `destroy_hardware`, keeps the hero deployed, preserves VP and the real primary-core collider, removes the destroyed branch, and disables the dependent bound action.

2026-06-28 Hardware fault disabled module merge follow-up:

- `tools/hardware_fault_disabled_modules_merge_probe.gd` now covers the `_battle_actor_disabled_modules()` compatibility adapter when authored `stats.disabled_modules` and runtime hardware-fault disabled actions coexist.
- The adapter now preserves authored disabled attack indices, merges in fault-disabled runtime bindings without duplicates, and leaves `stats.disabled_modules` plus `runtime_module_bindings` unchanged for save/schema compatibility.

2026-06-28 Hardware fault destroyed branch dependency follow-up:

- `tools/hardware_fault_destruction_consumption_probe.gd` now covers a future action bound only to a downstream child removed with a destroyed non-core branch.
- Hardware dependency reports now merge Fighter runtime destroyed-node metadata as `destroyed`, so child-only bindings stay disabled after their collider and segment are removed without mutating blueprint/runtime module bindings.

2026-06-28 Hardware fault diagnostics feedback follow-up:

- Battle action telemetry now carries normalized hardware state counts, affected-node identity, capacity, transition sequence, and the latest matching runtime transition for each live unit.
- The optional diagnostics overlay shows a non-color-only `FAULT / 故障` marker plus raw, path-capped, hardware-capped, capacity, pre/post-state, and sequence data; its verified height now fits the enriched probe scenario without clipping lines.

2026-06-28 Hardware fault named gate reason follow-up:

- `tools/hardware_fault_direct_module_dependency_probe.gd` now requires a blocked direct runtime action to include the first failed hardware dependency name in `last_module_gate_reason`.
- Hardware fault dependency reports now keep the pure service's blocked hardware ID while the main battle adapter maps that ID back to the live runtime segment label, producing reasons such as `hardware Right Connector faulted` without mutating module bindings.

2026-06-28 Hardware fault battle log telemetry follow-up:

- `tools/hardware_fault_live_adapter_probe.gd` now requires `_battle_attack_rule_summary_text()` to expose hardware fault transitions in the battle log summary.
- Post-review attack result reasons now append a compact `HW pre>post raw/path/hardware/capacity/seq` payload when a breakdown contains a real hardware fault transition, so the same raw, path-capped, hardware-capped, capacity, and sequence data is inspectable outside the diagnostics overlay.

2026-06-28 Source Code runtime diagnostics follow-up:

- Battle command diagnostics now carry the selected Source Code entry ID, display name, and the first runtime rejection reason from `source_code_runtime_assignments` / `source_code_runtime_diagnostics`.
- `BattleRuntimeActionTelemetryService` preserves those fields into the action diagnostics model, and `BattleActionDiagnosticsView` renders a compact `source src:... src_name:... src_reason:...` row when available.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_action_diagnostics_overlay_probe` (`text_lines=24`), `source_code_priority_main_runtime_probe`, `source_code_priority_destruction_rebuild_probe`, and `battle_runtime_action_telemetry_service_contract_probe`.

2026-06-28 Source Code selected runtime behavior follow-up:

- Runtime Source Code assignment now records the primary construct body's selected assignment/entry and applies that Source Code back to unit behavior stats: `ai`, `sequence`, normalized `source_rules`, `module_sequence_limit`, `condition_slots`, and selected source targeting/movement hints.
- Carrier destruction rebuilds the selected behavior fields after removing the destroyed carrier's Source Code, so surviving Source Codes continue driving runtime commands instead of leaving the previous payload's AI/rules stale.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `source_code_priority_main_runtime_probe`, `source_code_priority_destruction_rebuild_probe`, `battle_action_diagnostics_overlay_probe`, and `battle_runtime_action_telemetry_service_contract_probe`.

2026-06-28 Explosive projectile preflight contract follow-up:

- `BattleHitResolutionService.projectile_preflight_intent()` now keeps explicit `explosion_damage` and `explosion_damage_type` payloads available for `_apply_explosion_damage()` while still normalizing explosive projectile behavior, speed, radius, and style.
- `tools/projectile_momentum_probe.gd` now exits nonzero on failure and is registered in `tools/probe_manifest.json`; it guards explosive direct damage, wide splash damage, and momentum stagger in the same runtime scenario.
- `tools/battle_projectile_lifecycle_service_contract_probe.gd` now exits nonzero on failure and guards the preflight payload contract before the explosion lifecycle handoff checks.

2026-06-28 Battle terrain service baseline:

- `scripts/services/battle_terrain_service.gd` introduces the pure terrain-feature contract for Barrier-Terrain Integration: normalized feature IDs, terrain kinds, colliders, orientation vectors, surface tags, owner/destructible metadata, anchor points, and effect channels.
- The service produces immutable arena snapshots, tag/kind/point-overlap spatial queries, terrain-only placement outcomes (`free`, `attach`, `bridge`, `overlap`, `replace`, `blocked`) with stable reasons, and combined occlusion candidates that can later merge terrain with barrier blockers.
- `tools/battle_terrain_service_contract_probe.gd` is registered in `tools/probe_manifest.json`; the first RED/GREEN cycle failed on the missing service, then passed after the pure service was added.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `battle_terrain_service_contract_probe`, `battle_map_occlusion_service_contract_probe`, `map_occlusion_kind_probe`, `map_occlusion_projectile_integration_probe`, `barrier_panel_probe`, `resource_entry_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `formal_battle_wording_probe`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.029`, `max_ms=1.945`), and Godot `--check-only`.

2026-06-28 Barrier terrain interaction service baseline:

- `scripts/services/barrier_terrain_interaction_service.gd` now consumes terrain snapshots and tile terrain policies to produce barrier-specific placement intents without reading or mutating saved barrier blueprints.
- The service normalizes attach/bridge/block/overlap/replace policies, checks anchor support compatibility, allows free/attach/bridge placements, blocks unsupported terrain or anchor mismatches, and emits deployment intents such as `attach_to_terrain`, `inherit_terrain_orientation`, `bridge_terrain_gap`, and `deploy_without_terrain`.
- `tools/barrier_terrain_interaction_service_contract_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on the missing service, then passed after the pure interaction service was added.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `barrier_terrain_interaction_service_contract_probe`, `battle_terrain_service_contract_probe`, `battle_map_occlusion_service_contract_probe`, `map_occlusion_kind_probe`, `map_occlusion_projectile_integration_probe`, `barrier_panel_probe`, `resource_entry_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.025`, `max_ms=1.970`), and Godot `--check-only`.

2026-06-28 Barrier terrain runtime integration baseline:

- `main.gd` now preloads and owns `BattleTerrainService` and `BarrierTerrainInteractionService`, exposes a default empty runtime terrain snapshot, and applies barrier-terrain placement when a live barrier unit is created.
- `_apply_barrier_terrain_deployment()` computes each runtime barrier tile's world position, asks the interaction service for placement and deployment intents, and stores placement, deployment, blocked-tile, and arena snapshot metadata on the live unit without mutating the caller stats or saved barrier blueprint.
- `tools/barrier_terrain_runtime_integration_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on missing `main.gd` integration tokens, then passed after `_create_unit()` consumed the terrain interaction service for barriers.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `barrier_terrain_runtime_integration_probe`, `barrier_terrain_interaction_service_contract_probe`, `battle_terrain_service_contract_probe`, `barrier_panel_probe`, `resource_entry_probe`, `battle_map_occlusion_service_contract_probe`, `map_occlusion_projectile_integration_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.994`, `max_ms=2.167`), and Godot `--check-only`.

2026-06-28 Terrain occlusion runtime integration:

- `_map_occlusion_query_for_path()` now appends terrain occlusion candidates from `BattleTerrainService.combined_occlusion_candidates()` to the existing live-unit/barrier candidate list, preserving default empty-snapshot behavior while allowing injected arena terrain to block projectile and sight paths.
- Terrain occlusion query results carry `blocker_source`, `terrain_feature_id`, and `terrain_kind` metadata, while existing unit blockers still attach the live blocker node.
- `tools/terrain_occlusion_runtime_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on missing combined-occlusion integration tokens, then passed with a terrain-only wall blocking line of sight and a laser hit without any barrier unit on the field.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `terrain_occlusion_runtime_probe`, `map_occlusion_projectile_integration_probe`, `map_occlusion_ai_sight_probe` (`clear=105.30`, `blocked=3.30`), `battle_map_occlusion_service_contract_probe`, `map_occlusion_kind_probe`, `barrier_terrain_runtime_integration_probe`, `barrier_terrain_interaction_service_contract_probe`, `battle_terrain_service_contract_probe`, `resource_entry_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=0.991`, `max_ms=2.359`), and Godot `--check-only`.

2026-06-28 Terrain awareness metadata integration:

- `_source_target_awareness_facts()` now uses the same map occlusion query as projectile and line-of-sight helpers, so source-target scoring keeps the existing occlusion penalty while preserving `sight_occlusion_kind`, `sight_blocker_source`, `sight_terrain_feature_id`, and `sight_terrain_kind`.
- `_source_target_candidate_facts()` remains as the compatibility wrapper for existing callers, while terrain walls injected through `BattleTerrainService` now reach the awareness facts without requiring a live barrier unit.
- `tools/terrain_awareness_metadata_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on missing awareness metadata tokens, then passed with a terrain-only wall reporting `source=terrain` and `feature=terrain-awareness-wall`.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `terrain_awareness_metadata_probe` (`clear=105.30`, `blocked=3.30`), `terrain_occlusion_runtime_probe`, `map_occlusion_ai_sight_probe` (`clear=105.30`, `blocked=3.30`), `battle_awareness_service_contract_probe`, `source_heat_pressure_policy_probe`, `map_occlusion_projectile_integration_probe`, `battle_map_occlusion_service_contract_probe`, `barrier_terrain_runtime_integration_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), and `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.604`, `max_ms=29.556`).

2026-06-28 Terrain collision runtime integration:

- `BattleTerrainService.combined_collision_candidates()` now exposes authored terrain features with the `collision` effect channel as static terrain candidates, carrying feature ID, terrain kind, surface tags, destructibility, blocker name, and collider geometry.
- `_resolve_unit_body_spacing()` now runs `_separate_unit_from_terrain()` for live physics subjects after unit-pair spacing. Terrain blockers push units out without entering `all_units`, runtime contact damage, or saved barrier blueprints, and the affected unit records `terrain_collision_feature_id`, `terrain_collision_kind`, `terrain_collision_source`, and `terrain_collision_blocker_name`.
- `tools/terrain_collision_runtime_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on missing terrain collision integration tokens, then passed with a terrain-only wall pushing a hero from `0.120` to `0.349` distance and recording `terrain-collision-wall`.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `terrain_collision_runtime_probe`, `battle_terrain_service_contract_probe`, `barrier_terrain_runtime_integration_probe`, `terrain_occlusion_runtime_probe`, `terrain_awareness_metadata_probe` (`clear=105.30`, `blocked=3.30`), `map_occlusion_ai_sight_probe` (`clear=105.30`, `blocked=3.30`), `runtime_contact_service_contract_probe`, `battle_frame_orchestrator_service_contract_probe`, `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.092`, `max_ms=2.185`), and `probe_manifest_no_legacy_fixture_probe` (`current=258`).

2026-06-28 Authored arena terrain runtime baseline:

- `_default_battle_terrain_snapshot_context()` now provides the default `mobius_default_arena` authored terrain snapshot instead of an empty arena: north/south midfield cover walls with collision, occlusion, tags, and barrier-panel anchors, plus a bridgeable north-route gap marker for later traversal/path-planning rules.
- `_battle_terrain_runtime_snapshot()` now normalizes that authored context through `BattleTerrainService.arena_snapshot()` whenever no test or battle entrypoint has injected a specific terrain snapshot, preserving explicit injected snapshots for targeted probes.
- `tools/authored_arena_terrain_runtime_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle failed on missing authored arena tokens, then passed with `features=3`, `collision=2`, `occlusion=2`, and a default barrier attachment to `mobius_mid_cover_north`.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `authored_arena_terrain_runtime_probe`, `barrier_terrain_runtime_integration_probe`, `terrain_collision_runtime_probe`, `terrain_occlusion_runtime_probe`, `terrain_awareness_metadata_probe` (`clear=105.30`, `blocked=3.30`), `battle_terrain_service_contract_probe`, `barrier_terrain_interaction_service_contract_probe`, `map_occlusion_ai_sight_probe` (`clear=105.30`, `blocked=3.30`), `battle_runtime_frame_budget_probe` (`fixture=generated_training_starter`, `avg_ms=1.746`, `max_ms=3.020`), and `probe_manifest_no_legacy_fixture_probe` (`current=258`).

2026-06-28 Barrier terrain map-independent saves:

- Saved-unit canonicalization now strips the live Barrier-Terrain runtime metadata keys (`barrier_terrain_placement_intents`, `barrier_terrain_deployment_intents`, blocked-tile/snapshot IDs, and terrain collision source fields) before unit-library blueprints or payloads are written.
- Authored barrier tile `terrain_policy` survives that save path, so reusable attachment/bridge intent remains map-independent and can be resolved later by editor preview or battle deployment.
- `tools/barrier_terrain_map_independent_save_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle first failed on missing transient-save handling and residual runtime keys, then passed with `tiles=1`.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `barrier_terrain_map_independent_save_probe`, `saved_unit_library_service_contract_probe`, `barrier_terrain_runtime_integration_probe`, `authored_arena_terrain_runtime_probe`, `terrain_collision_runtime_probe`, `terrain_occlusion_runtime_probe`, `terrain_awareness_metadata_probe`, `battle_terrain_service_contract_probe`, `barrier_terrain_interaction_service_contract_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `jq empty tools/probe_manifest.json`, `git diff --check`, and Godot `--check-only`.

2026-06-28 Barrier terrain editor preview consumption:

- `_barrier_terrain_editor_preview()` now resolves saved/editor `barrier_tiles` through the same `BattleTerrainService` snapshot and `BarrierTerrainInteractionService` placement/deployment intent path used by battle runtime, with an explicit preview origin and no blueprint mutation.
- Barrier editor board snapshots now carry top-level `terrain_preview` data plus per-tile `terrain_preview` dictionaries, and the barrier board renderer uses those outcomes to visually distinguish attach/bridge, blocked, and terrain-overlap states.
- Barrier visual revision keys include terrain snapshot revision data, so injected or future swapped terrain snapshots invalidate the preview even when the barrier tile layout itself is unchanged.
- `tools/barrier_terrain_editor_preview_probe.gd` is registered in `tools/probe_manifest.json`; its RED/GREEN cycle first failed on the missing editor preview helper/snapshot tokens, then passed with direct-helper and board-snapshot attach coverage for `mobius_mid_cover_north`.
- Focused verification passed on macOS Godot `4.6.2.stable.official.71f334935`: `barrier_terrain_editor_preview_probe`, `barrier_catalog_screen_place_probe`, `barrier_terrain_map_independent_save_probe`, `barrier_terrain_runtime_integration_probe`, `authored_arena_terrain_runtime_probe`, `terrain_collision_runtime_probe`, `terrain_occlusion_runtime_probe`, `terrain_awareness_metadata_probe`, `battle_terrain_service_contract_probe`, `barrier_terrain_interaction_service_contract_probe`, `saved_unit_library_service_contract_probe`, `probe_manifest_no_legacy_fixture_probe` (`current=258`), `jq empty tools/probe_manifest.json`, `git diff --check`, and Godot `--check-only`.
