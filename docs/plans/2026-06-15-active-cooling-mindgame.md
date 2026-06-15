# Active Cooling Mindgame

Goal: make active cooling a readable combat commitment instead of a free numeric reset.

## Design

Active cooling should answer the player's heat-pressure problem while creating an opponent-facing decision point. The player can stop and vent to keep a high-heat build online, but the opponent should be able to see the vent, chase it, and punish bad timing.

The implementation keeps manual cooling and active cooling modules separate:

- Manual cooling is the low-input recovery option. Holding the cooling input quickly lowers heat, locks movement for at least a short beat, and shows a visible vent cloud.
- Active cooling modules are stronger commitments. They dump a large authored heat amount, set an authored movement lock, show the same readable vent state, and leave a short exposure window where incoming hits receive a small damage bonus.
- Cooling records are diagnostic. Active cooling module use is written to the post-battle command review log, but live combat keeps only immediate visual and heat-bar feedback.

## Runtime Contract

- `Fighter.begin_cooling_exposure(duration, kind)` owns the shared cooling exposure state.
- `manual_cool()` marks a manual cooling window.
- `_try_active_cooling_module()` marks an active cooling window and logs the event.
- `take_hit()` applies the small cooling-exposure punish multiplier only while the window is live.
- `_refresh_cooling_smoke()` renders a simple local vent cloud so the window is visible without new art assets.

## Balance Notes

Cooling should not force one correct build. High-burst builds can spend windows to stay online; low-heat builds can avoid those windows; space-control builds can protect or attack vent timing. Future extensions can add fake vents, interrupt grades, barrier-protected coolant fields, and terrain-assisted cooling without changing the core contract.

## Verification

- `active_cooling_mindgame_probe` validates manual cooling exposure, vent visuals, active cooling lock, exposure damage, and post-battle log text.
- Existing heat and movement probes continue to guard heat-rate math and cooling movement gates.
