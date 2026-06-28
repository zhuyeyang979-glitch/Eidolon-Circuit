# Project TODO

## Star Soul Loop Gameplay Follow-Ups

Status: gameplay baseline polished; the items below have reviewed ownership and probe-first plans but are not all active runtime behavior.

Unit editor legality:

- Pure `scripts/services/unit_editor_legality_service.gd` baseline is implemented and integrated through `_training_blueprint_illegal_note()`; role identity, explicit/custom-topology socket size and exact socket-kind ownership, per-socket occupancy, explicit/custom-topology construct-body manufacturers, localized messages, a persistent bilingual editor status, hero/puppet/barrier main save/training rejection paths, team validation, battle-entry legality, saved-unit readback, saved-team load/import, formal PVP/BP battle-start rechecks, combined-rule report merging, and cross-entrypoint topology failures are covered by the registered Unit Editor legality probes, including `tools/unit_editor_legality_preview_slot_kind_probe.gd` and `tools/unit_editor_legality_cross_entrypoint_probe.gd`.
- Keep future Unit Editor legality changes behind the registered probes; `momentum_chain_v3`, `single_unit` / `puppet_group`, and `custom_topology` storage remain unchanged until a separate migration plan exists.
- Follow `docs/plans/2026-06-24-unit-editor-legality-roadmap.md` only if a later rule gains path-specific handling or a saved-unit migration is explicitly planned.

Hardware fault runtime:

- Pure state service, deterministic pure contact replay, the save round-trip guard, the basic live contact adapter, deterministic live replay coverage, live `normal` / `faulted` / `destroyed` state exposure without blueprint serialization, faulted-segment amber pulse overlays with a non-color `!` marker, gun activation dependency blocking at startup and active fire frames, named direct runtime module and Boot Driver dependency blocking, primary-core movement and boost dependency blocking, true-bullet and laser telegraph delayed pre-fire queue dependency cancellation, non-core `destroy_hardware` intent consumption with downstream branch dependency invalidation, core `destroy_construct_body` kill-flow routing, non-primary core-like hardware destruction routing, runtime disabled-module merge behavior, bilingual diagnostics markers with latest transition telemetry, battle-log transition telemetry, and generated-runtime primary core materialization are implemented through `tools/hardware_fault_contract_probe.gd`, `tools/hardware_fault_save_roundtrip_probe.gd`, `tools/hardware_fault_live_adapter_probe.gd`, `tools/hardware_fault_live_replay_probe.gd`, `tools/hardware_fault_runtime_state_exposure_probe.gd`, `tools/hardware_fault_visual_overlay_probe.gd`, `tools/hardware_fault_gun_activation_dependency_probe.gd`, `tools/hardware_fault_direct_module_dependency_probe.gd`, `tools/hardware_fault_movement_dependency_probe.gd`, `tools/hardware_fault_boost_dependency_probe.gd`, `tools/hardware_fault_true_bullet_queue_dependency_probe.gd`, `tools/hardware_fault_laser_telegraph_dependency_probe.gd`, `tools/hardware_fault_destruction_consumption_probe.gd`, `tools/hardware_fault_core_destruction_probe.gd`, `tools/hardware_fault_non_primary_core_destruction_probe.gd`, `tools/hardware_fault_disabled_modules_merge_probe.gd`, `tools/hardware_fault_primary_core_materialization_probe.gd`, `tools/battle_runtime_action_telemetry_service_contract_probe.gd`, and `tools/battle_action_diagnostics_overlay_probe.gd`.
- Continue with the runtime adapter described in `docs/plans/2026-06-24-hardware-fault-runtime.md`.
- Keep extending construct-body destruction coverage beyond the current primary-core kill-flow route, and continue auditing any remaining non-module action sources for hardware dependency gates. Treat chemical and missile queues as already-fired projectile travel unless a later design changes their launch timing.
- Add equality, first-overload, second-overload, action dependency, save round-trip, and deterministic replay probes first.

Source Code priority:

- Keep `scripts/services/source_code_priority_service.gd` as the pure ordering and surviving-carrier boundary.
- Basic `源代码优先级 / SOURCE PRIORITY` editor metadata, Torso Detail Up/Down controls, Reset writeback, keyboard focus, and rank announcements are implemented through `tools/source_code_priority_editor_probe.gd`.
- Stable runtime construct-body IDs and deterministic body-to-code assignment tables are materialized in puppet stats/spawn through `tools/source_code_priority_runtime_assignment_probe.gd` and `tools/source_code_priority_main_runtime_probe.gd`.
- Carrier destruction now rebuilds runtime assignment tables without removing Source Codes on surviving bodies through `tools/source_code_priority_destruction_rebuild_probe.gd`.
- Follow `docs/plans/2026-06-24-source-code-priority-ui.md`.

Mode families:

- Keep local PVP as the first formal battle target.
- Design PVE story mission structure and authored encounter progression separately from battle rules.
- Design PVE roguelike run state, rewards, repair/loss rules, and prebuilt-unit choices separately from permanent player profiles.

Combat contract cleanup:

- Reconcile the existing explosive projectile preflight contract with `_apply_explosion_damage()` before treating missile/explosion probes as a completion gate.
- Preserve the current electric/laser naming bridge until a saved-data migration is explicitly planned.

## Online Battle / Deferred

Status: planned after the local two-player formal battle feels complete.

- Prioritize local two-player formal battle first: two controllers, deterministic round start, clear seat ownership, stable resource reset, and readable post-match state.
- Preserve network-ready interfaces while keeping implementation local: fixed battle tick, deterministic input frames, replay seed capture, seat-to-player abstraction, and a battle-start payload that can later accept remote inputs.
- Keep computer-controlled matches as local authored-rule opponents for testing and accessibility; they are not a replacement for the local versus priority.
- Defer matchmaking, lobby, rollback, reconnection, anti-cheat, and cloud profile synchronization until local battle rules, team selection, and spectator behavior are stable.
- Add future probes for identical local replay results, seat abstraction compatibility, and deterministic input-frame serialization before online work begins.

## Barrier-Terrain Integration

Status: high-priority planned extension. Current barriers already create runtime collision, projectile occlusion, walls, lanes, triggers, and local fields, but the arena has no independent authored-terrain layer for barriers to query or modify.

- Introduce a normalized terrain-feature contract containing stable feature ID, terrain kind, collider geometry, orientation, surface tags, ownership, destructibility, anchor points, and effect channels.
- Keep saved barrier blueprints map-independent. Resolve terrain attachment and interaction only when previewing or deploying into a specific arena.
- Add a placement query that returns explicit outcomes such as `free`, `attach`, `bridge`, `overlap`, `replace`, or `blocked`, with a player-readable reason.
- Define barrier interactions with map walls, floors, gaps, hazards, cover, traversal lanes, portals, and scripted arena mechanisms.
- Allow appropriate barrier panels to attach to terrain anchors, bridge valid gaps, reinforce or breach destructible terrain, and inherit a wall or lane orientation.
- Route projectile occlusion, line of sight, collision, target awareness, and later path planning through a combined terrain-plus-barrier spatial query.
- Let local fields react to terrain tags where designed: gravity may follow a surface vector, heat/coolant may be amplified or damped, and speed lanes may connect to authored routes.
- Define cleanup and restoration behavior when either the supporting terrain or attached barrier component is destroyed, transformed, or removed.
- Preserve deterministic, replayable results from map state and authored rules; this feature does not require a large language model or external model service.
- Add focused probes for attachment legality, combined occlusion, destruction invalidation, map-independent saves, and identical replay results.

Suggested future ownership boundary:

- `BattleTerrainService`: exposes immutable arena terrain snapshots and spatial queries.
- `BarrierTerrainInteractionService`: evaluates placement and produces terrain interaction intents.
- Battle runtime: applies accepted intents and owns temporary collision/effect instances.
- Editor and scout UI: preview interaction outcomes without mutating the arena.

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
