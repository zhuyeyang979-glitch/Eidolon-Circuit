# Battle HUD Service Boundary Tightening

## Goal

Make `BattleHudStateService` the single owner for battle HUD display text, bar models, ammo display, scoreboard text, and instrument-gauge model calculations.

## Priority

P5 service-boundary cleanup. After the view classes were extracted, this is a low-risk way to keep `scripts/main.gd` moving toward a composition-root role without introducing a large battle runtime facade in one step.

## Steps

1. Add a lazy `_battle_hud_service()` accessor in `scripts/main.gd` so HUD wrappers do not need service-null fallback branches.
2. Replace duplicated HUD model fallbacks in `main.gd` with calls to `BattleHudStateService`.
3. Remove legacy battle HUD text/bar/status/ammo formatting functions from `main.gd`.
4. Update service contract probes to require the service boundary and reject reintroduced legacy HUD fallback functions.
