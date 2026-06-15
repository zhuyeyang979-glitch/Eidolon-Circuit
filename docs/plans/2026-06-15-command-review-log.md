# Command Review Log Plan

Goal: move armor and active command cache feedback out of live combat HUD text and into a post-battle review log for players and developers.

## Design Rules

- Do not show command cached messages during active combat.
- Keep attack-group HUD feedback focused on immediate attack validity, cooldown, heat, ammo, and blocked inputs.
- Record command cache, command consumption, and special-module command matches with enough context to explain player intent after the round.
- Show the latest command log entries in post-battle review, where the player has chosen to inspect results instead of continuing real-time control.

## Implementation

- Add `battle_command_log` and cache dedupe state to `scripts/main.gd`.
- Record `236` as armor cache and `214` as active cache when the command buffer recognizes them.
- Record command consumption when melee state, attack button, runtime module, or special module logic clears a matched command.
- Add `command_log` to the post-battle review model and render it through the `PostBattleReviewCommandLog` label in `MenuView`.
- Expand `UILayoutTokens` post-battle review metrics so the log has its own readable area.

## Verification

- Add `tools/battle_command_review_log_probe.gd`.
- Register the probe in `tools/probe_manifest.json`.
- Run Godot check-only, targeted probes, layout probes, manifest validation, and `git diff --check`.
