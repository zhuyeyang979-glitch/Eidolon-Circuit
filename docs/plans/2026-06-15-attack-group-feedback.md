# Attack Group Feedback Plan

## Goal

Make every attack-group input visibly legible. The player should know whether a key press was accepted, entered an aiming or command state, executed, or failed because the group is unbound, blocked, overheated, cooling, severed, or out of ammo.

## Design Rules

1. Keep feedback advisory. The HUD explains current execution state, not whether the player's build is "correct."
2. Tie feedback to the six attack groups instead of adding more real-time commands.
3. Use three channels at once: attack-key slot flash, corresponding runtime segment highlight, and compact state text.
4. Surface resource causes through tiny bars: recovery/cooldown, heat, and ammo where relevant.
5. Keep debug-heavy details in diagnostics overlays; the normal battle HUD only shows short labels.

## Implemented Structure

1. `BattleAttackFeedbackView` renders six stable slots with key, group number, bound label, compact status, flash, heat, cooldown, and ammo bars.
2. `main.gd` owns the feedback model and records attack events through `_record_attack_feedback()`.
3. Runtime gun activation, held melee activation, command windows, unbound inputs, ammo failures, lock acquisition, and normal/runtime attacks all write to the same feedback channel.
4. `fighter.gd` exposes `pulse_attack_feedback()` and uses runtime segment overlays to highlight the relevant limb or weapon group.

## Follow-Up Hooks

- Replace keyboard labels with controller glyphs when input-device-aware HUD rendering lands.
- Split global recovery into per-module cooldown if combat rules later expose independent recovery timers.
- Add spectator mode support that can switch the attack feedback strip between P1, P2, or hidden state.
