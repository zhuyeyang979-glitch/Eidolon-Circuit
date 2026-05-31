# Eidolon Circuit Local Development Status

Last updated: 2026-05-30

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

Next safe chunk: use the enriched diagnostics overlay to inspect real battle action/gate/command state, then either extract another read-only battle runtime summary or plan a narrow diagnostics-only signal for projectile/targeting visibility. Do not move topology segment mutation, socket anchoring, collider generation, or scythe side-mount geometry until a new plan explicitly covers ownership and failure probes.
