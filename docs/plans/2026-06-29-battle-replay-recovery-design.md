# Battle Replay Recovery Design

## Goal

Provide deterministic rollback and reconnect boundaries that can be verified locally before any online transport, lobby, matchmaking, or live session orchestration is implemented.

## Chosen Architecture

Recovery uses canonical input-history replay from the deterministic battle-start payload. It does not serialize or restore Godot nodes.

- Rollback accepts corrected input frames only when their step is inside the configured rollback window and the current recorded history.
- The first corrected step is reported as `rollback_step`, while `replay_from_step` remains zero because the current implementation rebuilds from the deterministic battle start.
- Reconnect packages the canonical battle-start payload, canonical Star Soul draft queue, all confirmed serialized input frames, and the confirmed replay checkpoint.
- A SHA-256 history digest covers the complete reconnect core. Any frame, draft, start payload, or checkpoint change invalidates the reconnect plan.
- Reconnect requires the checkpoint step to equal the bundled input-history length before replay begins.
- Reconnect also requires the checkpoint time to match `current_step / simulation_hz`, and rejects structurally invalid serialized history frames instead of treating malformed payloads as empty input.

This is deliberately slower than restoring an in-memory object snapshot, but it is much safer at the current project stage: all recovery state is pure data, existing deterministic replay remains the source of truth, and no scene-node identity or runtime object pointer crosses the boundary.

## Public Contracts

`BattleInputService.rollback_replay_plan()` returns either a rejected reason or a canonical corrected frame sequence with rollback and resimulation metadata.

`BattleInputService.battle_reconnect_payload()` builds a versioned reconnect payload. `serialize_battle_reconnect_payload()` and `deserialize_battle_reconnect_payload()` provide the stable JSON boundary. `reconnect_replay_plan()` validates schema, history length, Star Soul draft, serialized frame structure, checkpoint coverage, fixed-step checkpoint time, checkpoint digest shape, and the full history digest before returning replay inputs.

## Verification

- `tools/battle_rollback_replay_probe.gd` runs baseline, predicted, and corrected PVP simulations. It proves a missing remote portal edge diverges, an in-window correction converges, and a stale correction is rejected.
- `tools/battle_reconnect_replay_probe.gd` disconnects at step 90, rebuilds the same midpoint, continues to the same step-180 state, rejects tampered input history, and rejects a checkpoint that does not cover the complete bundled history.

## Non-Goals

- Network packet transport or retransmission
- Matchmaking, lobbies, or session discovery
- Live frame-delay negotiation or rollback scheduling
- Scene-tree or object snapshot restoration
- Anti-cheat and remote-authority policy
