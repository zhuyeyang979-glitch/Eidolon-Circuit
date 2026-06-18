# Scoreboard Feedback

## Goal

Make battle scoring visible as a match objective, not just as corner numbers.

Players should always know:

- current P1/P2 victory points,
- target score,
- who is leading or whether the match is tied,
- when either side reaches match point,
- why a score changed through the existing kill-flow message.

## Design

Use three layers of feedback:

1. Keep per-side corner victory labels near resources, but include the player id: `P1 VP 3/7`, `P2 VP 4/7`.
2. Add a central scoreboard line in the battle HUD: `SCORE P1 3 - 4 P2 / 7  P2 LEADS +1`.
3. When a side is one point from victory, replace the lead note with `P1 MATCH POINT` / `P2 MATCH POINT`.

The central scoreboard is informational only. It does not change victory scoring, resource payout, timeout resolution, or post-battle review.

## Implementation

- Keep score text formatting inside `BattleHudStateService`.
- Add pure helpers for per-player VP text, lead state, and central scoreboard text.
- Main scene creates one `Scoreboard` label and maps it to the service's `scoreboard` text state.
- Existing kill-flow messages continue to report score sources.
- README documents where players see score during battle.

## Verification

- New `battle_scoreboard_feedback_probe` covers player labels, central score, tie, lead, match point, main HUD wiring, and README wording.
- Existing HUD contract, layout, post-battle review, and battle lifecycle probes remain green.
