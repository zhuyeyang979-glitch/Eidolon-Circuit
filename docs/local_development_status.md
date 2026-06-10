# Eidolon Circuit Local Development Status

Last updated: 2026-06-10

This file is the local execution board for the active Linear project `Eidolon Circuit Codebase Slimdown 2026-05-27`. The checked-in backlog remains `docs/development_backlog.md`; this file records local baseline and the next safe implementation order between Linear updates.

For the short current handoff, see `docs/next_development_handoff.md`.

## Current Baseline

- Project root: `E:\New project`
- Active integration branch: `codex/yhzlxp-eidolon-work`
- Active integration HEAD: `7d44ab2`
- GitHub PR: `https://github.com/zhuyeyang979-glitch/Eidolon-Circuit/pull/2`
- Local follow-up branch: `codex/future-dev-handoff`
- Git remote: `origin https://github.com/zhuyeyang979-glitch/Eidolon-Circuit.git`
- Worktree state at integration baseline: clean
- Godot version: `tools/godot-4.6.2/Godot_v4.6.2-stable_win64_console.exe`

## Current Local Delta

- PR #2 adopts yhzlxp's battle/action service boundary work and merges in the architecture guard branch.
- New architecture guard files are present for `AppModeHost`, mode owner stubs, `BattleState`, and their contract probes.
- This handoff branch only updates development handoff documentation; it does not change runtime behavior, save format, input bindings, or UI layout.
- Continue future work as stacked branches from `codex/yhzlxp-eidolon-work` until PR #2 lands on `main`.

## Large File Watch

| File | Lines | Bytes | Local Risk |
| --- | ---: | ---: | --- |
| `scripts/main.gd` | 53675 | 3170433 | Still the primary extraction target; move ownership into mode/app/service boundaries. |
| `scripts/fighter.gd` | 4682 | 231641 | Keep as Node shell; move pure heat/movement/action rules out gradually. |
| `scripts/assembly_board_renderer.gd` | 1911 | 107736 | Shared board/runtime art source; avoid duplicate combat visuals. |
| `scripts/part_art.gd` | 746 | 32890 | Good candidate for small visual taxonomy helpers. |
| `scripts/motion_budget.gd` | 40 | 2327 | Small and stable; preserve as canonical motion formula surface. |

## Verification Baseline

- `tools/run_godot_checked.ps1 -Headless -CheckOnly -TimeoutSec 120`: passed.
- Governance mirror probes from `.github/workflows/godot-governance.yml`: all 16 passed.
- PR #2 GitHub Actions `Godot Governance` run #32: passed.
- Architecture guard probes passed locally: `app_mode_host_contract_probe`, `app_root_boundary_probe`, `battle_state_contract_probe`, `battle_mode_contract_probe`, `menu_mode_contract_probe`, `team_edit_mode_contract_probe`, `saved_units_mode_contract_probe`, `settings_mode_contract_probe`, and `training_mode_contract_probe`.
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
