# Eidolon Circuit Architecture Boundaries

Last updated: 2026-06-03

This document defines the target architecture for continuing the codebase slimdown without synchronizing risky changes into `main`. It does not replace the current EC-SLIM backlog. It clarifies the ownership boundaries that future extraction work should move toward.

## Goal

Move the project from a `main.gd`-centered prototype into a mode-owned game architecture while preserving current behavior, probes, and save compatibility.

The migration should stay incremental:

- Keep existing public wrapper functions until focused probes prove the new owner is stable.
- Move ownership before moving deep algorithms.
- Prefer source-only contract probes for boundary work, then headed gameplay probes for behavior.
- Keep runtime side effects in Godot Node owners and pure rule decisions in RefCounted domain/system helpers.

## Target Layers

```text
scripts/
  app/
    app_root.gd
    app_mode_host.gd
  modes/
    menu_mode.gd
    team_edit_mode.gd
    saved_units_mode.gd
    training_mode.gd
    battle_mode.gd
    settings_mode.gd
  domain/
    action/
    catalog/
    stats/
    topology/
    unit/
  battle/
    state/
    systems/
    presentation/
  editor/
    controllers/
    views/
  persistence/
  services/
```

The current `scripts/services/` folder remains a safe staging area during migration. Services should be renamed or moved only after their ownership is clear and their probes are stable.

## Ownership Rules

### AppRoot

`main.gd` is the current AppRoot and composition root. Its target responsibility is limited to startup, shared resource initialization, and mode transitions.

Allowed long-term responsibilities:

- load global assets
- create shared services that are intentionally app-wide
- initialize `AppModeHost`
- transition between modes
- provide temporary wrappers while probes are being migrated

Not allowed as new work:

- new battle rules
- new editor board behavior
- new save/load policy
- new HUD or view class bodies
- new direct gameplay input policies

### Modes

Each top-level game screen owns its UI nodes, controllers, and page-local state.

- `MenuMode` owns menu UI and menu selection behavior.
- `TeamEditMode` owns unit editor UI, catalog, board, detail panels, and editor-only SFX.
- `SavedUnitsMode` owns saved-unit browsing and import/delete page interactions.
- `TrainingMode` owns training entry setup and handoff into battle.
- `BattleMode` owns battle runtime state, fixed tick orchestration, battle HUD, VFX presenters, and pause/runtime menu behavior.
- `SettingsMode` owns settings UI and input rebinding page behavior.

Mode code may call domain rules and persistence repositories. Domain code must not call modes.

### Domain

Domain code is the single source of truth for game rules that are shared by editor, save/load, and battle runtime.

Domain candidates:

- action profiles and module rules
- catalog normalization
- drive and allocation rules
- stat calculation
- topology validation
- unit blueprint validation

Domain code should not create UI nodes, read `Input`, own live `Fighter` nodes, spawn VFX, or perform file IO.

### Battle Runtime

Battle runtime should be organized around a fixed-tick system order:

```text
BattleFixedTickRunner
  BattleInputSystem
  BattleCommandSystem
  BattleSpawnSystem
  BattleMovementSystem
  BattleActionSystem
  BattleProjectileSystem
  BattleContactSystem
  BattleDamageSystem
  BattleHeatStatusSystem
  BattleAISystem
  BattleCameraSystem
```

Systems consume `BattleState`, commands, and delta time. They should emit state changes or battle events. They should not create HUD nodes or VFX directly.

### Presentation

Presentation code turns battle/editor/menu models and events into Godot nodes.

Examples:

- battle HUD presenter
- VFX presenter
- camera presenter
- editor board view
- debug overlay view

Presentation code may read snapshots and events. It should not decide damage, legality, movement gates, or save schema.

### Persistence

Persistence code owns disk-facing behavior:

- saved unit repository
- settings repository
- schema read/write boundaries
- cache invalidation decisions tied to storage

Persistence may call domain validators. It should not call UI or battle systems.

## Migration Order

1. Add architecture guardrails and keep all existing behavior unchanged.
2. Introduce `AppModeHost` while `main.gd` still builds the current screens.
3. Move Menu ownership into `MenuMode`.
4. Move Settings, Saved Units, and Scout/Training setup into mode owners.
5. Move Team Edit ownership into `TeamEditMode`.
6. Move battle state ownership into `BattleMode` and `BattleState`.
7. Convert battle runtime services into fixed-tick systems.
8. Move battle HUD/VFX/camera into presentation owners.
9. Rename staged services into final `domain/`, `battle/`, `editor/`, and `persistence/` paths.

## Probe Policy

Every ownership migration needs a focused contract probe before broad behavior probes.

Required probe types:

- boundary probe: verifies source ownership and forbidden dependencies
- wrapper probe: verifies old public wrappers delegate to the new owner
- behavior probe: verifies gameplay/editor behavior did not change
- manifest probe: verifies the probe is registered in `tools/probe_manifest.json`

The first guards for this architecture are `tools/app_root_boundary_probe.gd`, `tools/app_mode_host_contract_probe.gd`, `tools/battle_state_contract_probe.gd`, `tools/battle_mode_contract_probe.gd`, `tools/menu_mode_contract_probe.gd`, `tools/team_edit_mode_contract_probe.gd`, `tools/saved_units_mode_contract_probe.gd`, `tools/settings_mode_contract_probe.gd`, and `tools/training_mode_contract_probe.gd`.
