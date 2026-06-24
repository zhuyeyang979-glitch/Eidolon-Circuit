# Mobius BP Star Soul Runtime Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the Mobius battle-map contract, shared-pool Star Soul BP, alternating Star Soul queue, and VP reward rules as a tested foundation for the next formal battle loop.

**Architecture:** Start with a pure `StarSoulBPService` that owns data-only rules for map dimensions, draft turns, draft validation, spawn queue construction, catalog examples, and VP awards. Keep Godot scene spawning, battle UI, player input, and live unit AI outside the service until the data contract is stable.

**Tech Stack:** Godot 4.6.2, GDScript RefCounted services, headless `SceneTree` probes under `tools/`, existing probe manifest governance.

---

## Scope

Allowed now:

- Add a Chinese-facing design document for the new map and BP rules.
- Add a pure service for the deterministic parts of the rules.
- Add focused probes for the service.
- Register the probe in the current probe manifest.

Deferred:

- BP screen UI.
- Live Star Soul entity spawning.
- Star Soul movement/combat AI.
- VP scoreboard presentation.
- Full Mobius camera and collision changes.
- Balance numbers beyond the first documented archetype baseline.

## Task 1: Design Copy And Rule Boundary

**Files:**

- Create: `docs/reports/2026-06-24-mobius-bp-star-soul-design.md`
- Create: `docs/plans/2026-06-24-mobius-bp-star-soul-runtime.md`

**Steps:**

1. Write the player/design-facing explanation for the Mobius map, BP, Star Soul queue, VP, and initial archetypes.
2. Define which rules are pure data now and which parts are deferred runtime work.
3. Keep language aligned with the current 星魂回环 README terminology.

**Verification:**

- Confirm the design mentions the 2-screen by 1.5-screen Mobius map, shared pool BP, 10 picks per player, one active Star Soul, 10-second announcement delay, alternating ownership queue, and VP-on-destroy rule.

## Task 2: Pure Rule Service

**Files:**

- Create: `scripts/services/star_soul_bp_service.gd`
- Create: `tools/star_soul_bp_service_probe.gd`
- Modify: `tools/probe_manifest.json`

**Steps:**

1. Add `battle_map_spec()` and home-half helpers for the Mobius map dimensions.
2. Add `draft_turns()` for alternating shared-pool BP.
3. Add `validate_draft()` to reject wrong turn order, duplicate shared-pool picks, unknown pool IDs, and wrong pick counts.
4. Add `build_spawn_queue()` to alternate owners from the BP first player, while allowing each player's internal Star Soul order to vary.
5. Add `vp_award_for_exit()` so destroyed Star Souls award VP to the opposing player and timeout/arrival exits award none.
6. Add the initial catalog examples for towers, cart, giant, traitor, loyalist, rebel, lord, tyrant, and coward.
7. Cover all of the above with a focused headless probe.

**Verification:**

```bash
/Volumes/vol1/Godot/bin/godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/star_soul_bp_service_probe.gd
/Volumes/vol1/Godot/bin/godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit
git diff --check
```

## Task 3: BP Screen Model

**Files:**

- Add later: `scripts/services/star_soul_bp_screen_service.gd`
- Add later: `tools/star_soul_bp_screen_service_probe.gd`
- Modify later: battle/team mode controllers after ownership is chosen.

**Steps:**

1. Define a screen model with shared pool, current turn, picked entries by player, unavailable entries, and confirm-ready state.
2. Add selection intent helpers for pick, undo, confirm, and timeout fallback.
3. Keep controller/UI rendering outside the service.
4. Add a probe for alternating turns and duplicate-pick rejection.

**Verification:**

- Probe confirms the UI model cannot select a Star Soul that has already left the shared pool.

## Task 4: Battle Runtime Adapter

**Files:**

- Modify later: `scripts/controllers/battle_controller.gd`
- Modify later: `scripts/modes/battle_mode.gd`
- Modify later: `scripts/main.gd` only as the current battle host adapter requires.
- Add later: `tools/star_soul_runtime_queue_probe.gd`

**Steps:**

1. Carry the validated draft payload into battle start state.
2. At battle start, announce queue entry 0 and create a 10-second pending spawn.
3. Spawn exactly one Star Soul when the countdown ends.
4. When the active Star Soul is destroyed or leaves, apply VP if needed, clear active state, announce the next entry, and start the next countdown.
5. Add deterministic replay seed fields before any randomized per-player order is used.

**Verification:**

- Probe confirms no second Star Soul can spawn while one is active.
- Probe confirms destroy, timeout, and arrival exits advance the queue consistently.

## Task 5: Star Soul Entity Families

**Files:**

- Add later: pure behavior service file(s) for Star Soul archetypes.
- Modify later: battle spawning and actor command services.
- Add later: family-specific probes.

**Steps:**

1. Implement stationary tower targeting and range models.
2. Implement aura buff/debuff models without adding direct player micromanagement.
3. Implement cart pathing from owner spawn to enemy spawn.
4. Implement nearest-target retargeting for giant/traitor/loyalist/rebel.
5. Implement economy-rate modifiers for lord/tyrant.
6. Implement coward flee logic and health-loss coverage rule.

**Verification:**

- Each family has service-level probes before live battle integration.

## Task 6: Scoreboard And Readability

**Files:**

- Modify later: battle HUD state service and view files.
- Add later: scoreboard/announcement probes.

**Steps:**

1. Show VP totals, active Star Soul owner, VP value, and announcement countdown.
2. Keep the display compact and avoid adding a second live-control layer.
3. Add post-battle summary rows for each Star Soul: owner, result, VP swing, and lifetime.

**Verification:**

- Probe confirms scoreboard state derives from battle data and does not mutate VP directly.
