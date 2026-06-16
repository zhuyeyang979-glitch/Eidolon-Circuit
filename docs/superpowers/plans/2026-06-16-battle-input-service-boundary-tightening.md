# Battle Input Service Boundary Tightening

## Goal

Make `BattleInputService` the single owner for battle input action names, edge-frame consumption, control routing, spectator intent, direction-edge checks, movement input state, and input-vector shaping.

## Priority

P5 service-boundary cleanup. This keeps `scripts/main.gd` as battle input orchestration glue while moving rule decisions and fallback behavior into a pure service that can be probe-tested without a scene tree.

## Steps

1. Add a lazy `_battle_input_service()` accessor in `scripts/main.gd`.
2. Route input wrappers, battle-control routing, spectator intent, movement state, direction-edge checks, and vector shaping through `_battle_input_service()`.
3. Remove legacy battle input fallback functions from `main.gd`.
4. Update input and controller boundary probes to require the accessor-based service boundary and reject reintroduced legacy input fallback tokens.

## Verification

- `tools/battle_input_service_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Tactical input and movement probes that cover action edges, direction taps, and battle input side effects.
