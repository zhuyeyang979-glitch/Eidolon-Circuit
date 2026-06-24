# Hardware Fault And Destruction Runtime Design

## Goal

Implement the Star Soul Loop overload rule without changing saved-unit topology or replacing the current construct-body health pool:

- A hardware part has a momentum capacity.
- A hit that exceeds that capacity uses the capacity as capped momentum for damage resolution.
- The first overload changes the hardware from `normal` to `faulted`.
- A later overload changes the same hardware from `faulted` to `destroyed`.
- Faulted hardware cannot execute actions that depend on it.
- Destroying a core destroys its entire construct body.

This document defines the runtime contract only. Runtime implementation starts with failing probes in a later task.

## State Model

Each spawned hardware node receives one runtime-only state:

| State | Collision and damage | Action execution | Next overload |
| --- | --- | --- | --- |
| `normal` | Active | Allowed | `faulted` |
| `faulted` | Active and targetable | Blocked for dependent actions | `destroyed` |
| `destroyed` | Removed from collision and rendering | Blocked | No transition |

An overload means `raw_momentum > runtime_momentum_capacity`. Equality does not overload.

A normal hit at or below capacity does not change state. A faulted part remains faulted when hit at or below capacity. State transitions are applied after the current hit has finished damage, knock, and telemetry calculation, so the current result cannot depend on callback order.

## Runtime Ownership

Add a pure `scripts/services/hardware_fault_runtime_service.gd` for:

- capacity resolution;
- momentum capping;
- overload state transitions;
- action dependency checks;
- deterministic destruction intents.

Keep live actor lookup, collider removal, effects, messages, and construct-body removal in `scripts/fighter.gd` and the `scripts/main.gd` battle adapter.

The runtime state table is keyed by stable hardware identity, not display name:

```text
construct_body_id -> hardware_node_id -> {
  state,
  runtime_momentum_capacity,
  transition_sequence
}
```

`hardware_node_id` is the canonical topology node index inside its saved blueprint member. `construct_body_id` is derived at spawn from player, sortie slot or puppet member, and connected-component index. It must not depend on scene instance IDs.

## Momentum Capacity Mapping

Capacity is resolved once when runtime colliders are built:

1. Use the catalog part's explicit `momentum_capacity` when positive.
2. For a connector's embedded joint, use `embedded_joint_momentum_capacity` for the embedded-joint hardware dependency.
3. Otherwise use the part's current `stiffness_momentum`.
4. Otherwise use the existing `_part_stiffness()` fallback for that hardware kind.
5. Clamp the runtime value to at least `1.0`.

Store the derived value as `runtime_momentum_capacity` on runtime hardware/collider records. Do not add it to saved blueprints.

`path_stiffness_momentum` remains the chain transmission cap. Hit resolution therefore uses:

```text
path_capped_momentum = min(raw_momentum, attacker_path_stiffness)
hardware_capped_momentum = min(path_capped_momentum, target_runtime_momentum_capacity)
```

The overload test uses the momentum borne by the target hardware before its own cap:

```text
overloaded = path_capped_momentum > target_runtime_momentum_capacity
```

This keeps the existing path-stiffness rule and adds the documented per-hardware overload rule without treating them as the same value.

## Damage And Knock Order

For one contact event:

1. Resolve stable attacker, construct body, and target hardware IDs.
2. Read the target's pre-hit hardware state and capacity.
3. Calculate path-capped and hardware-capped momentum.
4. Use hardware-capped momentum for damage and break-gate calculation.
5. Use the existing knock rule and record both uncapped and applied knock momentum.
6. Complete construct-body health damage.
7. Calculate the hardware transition from the pre-hit state.
8. Queue hardware or construct-body removal.
9. Apply queued removals in stable ID order after all contacts for the simulation tick.

Construct-body health remains the sum of its hardware health. Hardware does not gain an independent hit-point pool in this design.

## Action Dependencies

Every executable action exposes a set of required hardware IDs:

- Action modules require their bound `target_nodes`, root node, and firing/striking hardware.
- Thruster movement requires the bound thruster and movement core dependency.
- Gun fire requires the gun hardware; ammunition, heat, and engine rules remain separate gates.
- Passive software rules with no hardware executor are not disabled by an unrelated fault.

Before startup and again before an active hit/fire frame, the battle adapter calls the service with required hardware IDs. The action is rejected when any dependency is `faulted` or `destroyed`.

The existing `_battle_actor_disabled_modules()` path remains the compatibility adapter for AI and command selection. It should merge authored disabled modules with runtime fault-disabled modules rather than mutating blueprint `module_bindings`.

## Destruction Rules

Non-core hardware destruction:

- removes its collider and visible segment;
- cancels actions that depend on it;
- invalidates topology paths that pass through it;
- does not delete unrelated Source Code or software carried by surviving hardware;
- may split a construct body only after a dedicated split-runtime design. Until then, disconnected descendants become non-executing wreckage and are removed with the destroyed branch in stable node order.

Core destruction:

- emits one `destroy_construct_body` intent;
- removes every hardware node in that construct body;
- cancels its actions and projectiles that require a live source;
- enters the existing unit/puppet/barrier destruction and scoring flow exactly once.

If a construct body has multiple core-like nodes, spawn normalization designates one `primary_core_node_id`. Destroying that node destroys the body; other core-like nodes behave as ordinary hardware until multi-core bodies receive a separate rule.

## Player Feedback

- Faulted hardware stays visible with an amber pulse, electrical interruption effect, and a compact `FAULT / 故障` marker in diagnostics.
- Destroyed hardware disappears after the hit result is shown and emits the existing destruction effect.
- A rejected action reports the first stable failed dependency, for example `行动失败：右臂连接件故障` / `ACTION BLOCKED: right connector faulted`.
- The standard combat HUD remains compact. Detailed raw momentum, capped momentum, capacity, pre-state, post-state, and transition sequence appear in the diagnostics overlay and battle log.
- Feedback must not rely on color alone.

## Save Compatibility

- Hardware state, transition sequence, and `runtime_momentum_capacity` are battle-runtime data and are never serialized into saved-unit JSON.
- Existing blueprint node indices, internal slot keys, part names, and module bindings remain unchanged.
- Capacity is re-derived from canonical catalog data when a unit spawns.
- Old saves without explicit capacity continue through the `stiffness_momentum` and `_part_stiffness()` fallback.
- The current `UnitBlueprintValidator` rejection of legacy embedded drive fields remains unchanged.

## Replay Determinism

Every transition event records:

```text
simulation_tick
contact_sequence
attacker_actor_id
target_construct_body_id
target_hardware_node_id
raw_momentum
path_capped_momentum
hardware_capped_momentum
runtime_momentum_capacity
pre_state
post_state
destruction_intent
```

No random roll participates in overload or transition decisions. Contact events are sorted by the existing stable contact order, then removals are sorted by `construct_body_id` and `hardware_node_id`. Replays reconstruct states from spawn data plus ordered transition events rather than saving mutable scene object IDs.

## Probe-First Implementation Plan

1. Add `tools/hardware_fault_contract_probe.gd` before the runtime service.
2. Cover equality without overload, first overload fault, sub-cap hit while faulted, and second overload destruction.
3. Cover capacity fallback from `momentum_capacity` to `stiffness_momentum`.
4. Cover action rejection for one faulted dependency and acceptance for unrelated faults.
5. Cover non-core destruction intent and core construct-body destruction intent.
6. Add a runtime probe that strikes one hardware node twice and checks capped damage telemetry and ordered transitions.
7. Add a save round-trip probe proving runtime state is absent from the saved blueprint.
8. Add a deterministic replay fixture proving identical ordered contacts produce identical transitions.

## Acceptance

- The three states and both transitions are represented by one pure service.
- Damage uses capped momentum and equality does not fault.
- Related actions stop when hardware faults.
- Core destruction removes one construct body through the existing destruction flow.
- Runtime state never contaminates saved-unit data.
- Transition output is deterministic and inspectable.
