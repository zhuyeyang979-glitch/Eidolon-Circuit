# Project TODO

## Star Soul Loop Gameplay Follow-Ups

Status: gameplay baseline polished; the items below have reviewed ownership and probe-first plans but are not all active runtime behavior.

Unit editor legality:

- Pure `scripts/services/unit_editor_legality_service.gd` baseline is implemented and integrated through `_training_blueprint_illegal_note()`; role identity, explicit/custom-topology socket size and exact socket-kind ownership, per-socket occupancy, explicit/custom-topology construct-body manufacturers, localized messages, a persistent bilingual editor status, hero/puppet/barrier main save/training rejection paths, team validation, battle-entry legality, saved-unit readback, saved-team load/import, formal PVP/BP battle-start rechecks, combined-rule report merging, and cross-entrypoint topology failures are covered by the registered Unit Editor legality probes, including `tools/unit_editor_legality_preview_slot_kind_probe.gd` and `tools/unit_editor_legality_cross_entrypoint_probe.gd`.
- Keep future Unit Editor legality changes behind the registered probes; `momentum_chain_v3`, `single_unit` / `puppet_group`, and `custom_topology` storage remain unchanged until a separate migration plan exists.
- Follow `docs/plans/2026-06-24-unit-editor-legality-roadmap.md` only if a later rule gains path-specific handling or a saved-unit migration is explicitly planned.

Hardware fault runtime:

- Pure state service, deterministic pure contact replay, the save round-trip guard, the basic live contact adapter, deterministic live replay coverage, live `normal` / `faulted` / `destroyed` state exposure without blueprint serialization, faulted-segment amber pulse overlays with a non-color `!` marker, gun activation dependency blocking at startup and active fire frames, named direct runtime module and Boot Driver dependency blocking, named primary-core movement and boost dependency blocking, true-bullet and laser telegraph delayed pre-fire queue dependency cancellation, non-core `destroy_hardware` intent consumption with downstream branch dependency invalidation, core `destroy_construct_body` kill-flow routing, non-primary core-like hardware destruction routing, runtime disabled-module merge behavior, bilingual diagnostics markers with latest transition telemetry, battle-log transition telemetry, and generated-runtime primary core materialization are implemented through `tools/hardware_fault_contract_probe.gd`, `tools/hardware_fault_save_roundtrip_probe.gd`, `tools/hardware_fault_live_adapter_probe.gd`, `tools/hardware_fault_live_replay_probe.gd`, `tools/hardware_fault_runtime_state_exposure_probe.gd`, `tools/hardware_fault_visual_overlay_probe.gd`, `tools/hardware_fault_gun_activation_dependency_probe.gd`, `tools/hardware_fault_direct_module_dependency_probe.gd`, `tools/hardware_fault_movement_dependency_probe.gd`, `tools/hardware_fault_boost_dependency_probe.gd`, `tools/hardware_fault_true_bullet_queue_dependency_probe.gd`, `tools/hardware_fault_laser_telegraph_dependency_probe.gd`, `tools/hardware_fault_destruction_consumption_probe.gd`, `tools/hardware_fault_core_destruction_probe.gd`, `tools/hardware_fault_non_primary_core_destruction_probe.gd`, `tools/hardware_fault_disabled_modules_merge_probe.gd`, `tools/hardware_fault_primary_core_materialization_probe.gd`, `tools/battle_runtime_action_telemetry_service_contract_probe.gd`, and `tools/battle_action_diagnostics_overlay_probe.gd`.
- Continue with the runtime adapter described in `docs/plans/2026-06-24-hardware-fault-runtime.md`.
- Keep extending construct-body destruction coverage beyond the current primary-core kill-flow route, and continue auditing any remaining non-module action sources for hardware dependency gates. Treat chemical and missile queues as already-fired projectile travel unless a later design changes their launch timing.
- Add equality, first-overload, second-overload, action dependency, save round-trip, and deterministic replay probes first.

Source Code priority:

- Keep `scripts/services/source_code_priority_service.gd` as the pure ordering and surviving-carrier boundary.
- Basic `源代码优先级 / SOURCE PRIORITY` editor metadata, Torso Detail Up/Down controls, Reset writeback, keyboard focus, and rank announcements are implemented through `tools/source_code_priority_editor_probe.gd`.
- Stable runtime construct-body IDs and deterministic body-to-code assignment tables are materialized in puppet stats/spawn through `tools/source_code_priority_runtime_assignment_probe.gd` and `tools/source_code_priority_main_runtime_probe.gd`.
- Carrier destruction now rebuilds runtime assignment tables without removing Source Codes on surviving bodies through `tools/source_code_priority_destruction_rebuild_probe.gd`.
- Runtime command diagnostics now expose the selected Source Code entry/name and the first rejection reason in the battle action diagnostics overlay through `tools/battle_action_diagnostics_overlay_probe.gd`.
- Runtime stats now apply the primary construct body's selected Source Code to `ai`, `sequence`, `source_rules`, `module_sequence_limit`, and `condition_slots`, and carrier destruction refreshes those behavior fields through `tools/source_code_priority_main_runtime_probe.gd` and `tools/source_code_priority_destruction_rebuild_probe.gd`.
- Continue auditing only if later combat routing needs simultaneous per-body routines inside one spawned multi-body puppet unit.

Mode families:

- Keep local PVP as the first formal battle target.
- Design PVE story mission structure and authored encounter progression separately from battle rules.
- Design PVE roguelike run state, rewards, repair/loss rules, and prebuilt-unit choices separately from permanent player profiles.

Combat contract cleanup:

- Explosive projectile preflight now preserves explicit `explosion_damage` / `explosion_damage_type` payloads for `_apply_explosion_damage()`, with `projectile_momentum_probe` guarding direct damage, splash damage, and explosive momentum stagger.
- Preserve the current electric/laser naming bridge until a saved-data migration is explicitly planned.

## Online Battle / Deferred

Status: planned after the local two-player formal battle feels complete.

- Prioritize local two-player formal battle first: two controllers, deterministic round start, clear seat ownership, stable resource reset, and readable post-match state.
- Preserve network-ready interfaces while keeping implementation local: fixed battle tick, deterministic input frames, replay seed capture, seat-to-player abstraction, and a battle-start payload that can later accept remote inputs.
- Keep computer-controlled matches as local authored-rule opponents for testing and accessibility; they are not a replacement for the local versus priority.
- Defer matchmaking, lobby, rollback, reconnection, anti-cheat, and cloud profile synchronization until local battle rules, team selection, and spectator behavior are stable.
- Add future probes for identical local replay results, seat abstraction compatibility, and deterministic input-frame serialization before online work begins.

## Barrier-Terrain Integration

Status: high-priority planned extension. Current barriers already create runtime collision, projectile occlusion, walls, lanes, triggers, and local fields. The independent authored-terrain contract is implemented through `scripts/services/battle_terrain_service.gd`; the first barrier-terrain interaction intent layer is implemented through `scripts/services/barrier_terrain_interaction_service.gd`; runtime barrier creation records terrain placement/deployment intents; runtime map occlusion now consumes terrain-plus-barrier candidates, runtime collision now resolves authored terrain as static blockers, the default Mobius arena now ships authored terrain content, saved barrier blueprints strip arena/runtime terrain metadata while preserving authored `terrain_policy`, editor barrier previews now consume the same terrain placement services, runtime barrier tile removal now invalidates stale terrain placement/deployment metadata, battle/editor entrypoints now replay identical terrain intents for the same authored barrier tile, local fields now react to authored terrain tags, puppet/source path planning now consumes terrain traversal queries plus live bridge intents, destructible terrain can now be reinforced or breached by deployed barrier panels, portal terrain can now be activated by deployed barrier panels to override a player's summon portal slot, scripted terrain mechanisms can now restore/replace/remove/mutate runtime terrain features from arena metadata, hazard terrain can now apply runtime heat/damage effects to overlapping units, and floor/surface terrain can now apply runtime speed, push, heat, and cooling modifiers to overlapping units.

- Normalized terrain-feature snapshots now carry stable feature ID, terrain kind, collider geometry, orientation, surface tags, ownership, destructibility, anchor points, and effect channels.
- Keep saved barrier blueprints map-independent. Resolve terrain attachment and interaction only when previewing or deploying into a specific arena.
- `BattleTerrainService.placement_query()` now returns explicit `free`, `attach`, `bridge`, `reinforce`, `breach`, `portal`, `mechanism`, `overlap`, `replace`, or `blocked` outcomes with stable player-readable reasons for terrain-only placement checks.
- `BarrierTerrainInteractionService.barrier_placement_intent()` now turns terrain placement outcomes into barrier-specific allow/block decisions, attachment/bridge deployment intents, anchor-support checks, and inherited terrain orientation without mutating saved barrier blueprints.
- Runtime barrier creation now calls the barrier-terrain interaction layer and stores placement, deployment, blocked-tile, and arena snapshot metadata on the live barrier unit without mutating input stats or saved blueprints.
- The default runtime terrain snapshot now uses `mobius_default_arena`, with two midfield cover walls that feed collision/occlusion/barrier anchors, a bridgeable north-route gap marker for traversal/path-planning rules, and a midfield fold-gate portal feature for scripted portal activation.
- Saved-unit canonicalization now removes live terrain placement/deployment and collision metadata from stored unit-library blueprints and payloads while keeping map-independent barrier tile `terrain_policy`.
- Editor barrier board snapshots now include a read-only terrain preview generated from `BattleTerrainService` and `BarrierTerrainInteractionService`, so UI rendering can distinguish free, attached, bridged, overlapping, or blocked terrain outcomes without mutating the blueprint.
- Blueprint-to-runtime barrier conversion now preserves authored tile `tile_id` and `terrain_policy`, so battle deployment resolves the same terrain intents shown by the editor preview.
- Define additional scripted arena mechanism effects beyond feature add/remove/restore/mutation.
- Appropriate barrier panels can attach to terrain anchors, bridge valid gaps, reinforce or breach destructible terrain, activate portal terrain, and inherit a wall or lane orientation.
- Runtime projectile occlusion and line-of-sight helpers now route through combined terrain-plus-barrier occlusion candidates; target awareness facts now preserve terrain occlusion source metadata. Runtime collision now pushes live physics subjects out of authored terrain collision candidates while preserving terrain source metadata. Hazard terrain candidates now apply metadata-driven heat and periodic damage to overlapping live mech subjects while preserving `terrain_hazard_*` diagnostics. Floor/surface terrain candidates now apply metadata-driven stable speed targets, directional push, cooling, and heat to overlapping live mech subjects while preserving `terrain_surface_*` diagnostics. Puppet/source target facts and movement intents now query terrain traversal features: unbridged gaps produce blocked/detour path plans, hazard routes produce avoid plans, while live `bridge_terrain_gap` barrier intents reopen gap routes as bridged paths.
- Local field runtime now queries overlapping authored terrain and feeds `surface_tags` into `BattleFieldRuntimeService`: gravity can follow a terrain surface vector and amplify/dampen, coolant and heat fields can be amplified or damped, and speed lanes can connect to authored route tags.
- Runtime barrier tile removal now recomputes terrain placement/deployment metadata so destroyed or detached attached tiles no longer leave stale terrain intents on the live barrier. Live barrier deployment now applies a first arena-state pass for destructible terrain, portals, and scripted mechanism terrain transforms: reinforce intents raise runtime terrain HP and tag the feature, breach intents damage or remove destroyed features from the runtime terrain snapshot, `activate_terrain_portal` intents override the owning player's selected summon portal slot from map feature metadata, and `trigger_arena_mechanism` can remove feature IDs, restore/upsert authored features, or mutate existing feature kind/tags/channels/metadata from mechanism metadata. Additional scripted mechanism effect families remain later work.
- Deterministic replay coverage now verifies repeated editor previews, repeated battle deployments, and cross-entrypoint terrain intent equality from the same map state and authored rules. This feature does not require a large language model or external model service.

Suggested future ownership boundary:

- `BattleTerrainService`: exposes immutable arena terrain snapshots and spatial queries.
- `BarrierTerrainInteractionService`: evaluates placement and produces terrain interaction intents. Pure service baseline, battle/editor placement application, destructible terrain state, first portal activation, first mechanism-driven terrain restoration, and feature mutation are implemented; broader arena mechanisms remain future work.
- Battle runtime: applies accepted intents and owns temporary collision/effect instances.
- Editor and scout UI: preview interaction outcomes without mutating the arena. Editor barrier board preview consumption is implemented; scout-side surfacing remains future UI polish.

## Player-Bound Unit Library

Status: planned, deferred until persistent player profiles are introduced.

- Introduce a persistent `profile_id` that is separate from local P1/P2 battle seat IDs.
- Store units under `user://profiles/<profile_id>/saved_units/<unit_id>.json`.
- Add `owner_profile_id`, stable `unit_id`, `created_at`, `updated_at`, and `revision` to saved-unit payloads.
- Provide a repository API: `list(profile_id)`, `load(profile_id, unit_id)`, `save(profile_id, unit)`, `delete(profile_id, unit_id)`, and `duplicate(profile_id, unit_id)`.
- Make Save overwrite by `profile_id + unit_id`; make Save As generate a new `unit_id`.
- Migrate existing files from the shared `user://saved_units` directory without deleting rejected or legacy-visible entries.
- Add ownership and component-unlock eligibility to the unit-library legality audit.
- Define local profile switching, backup/restore, and conflict behavior before adding cloud synchronization.
