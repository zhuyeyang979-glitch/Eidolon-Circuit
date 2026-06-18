# Heat Core Concept

## Goal

Treat heat as the main combat-tempo resource across unit design, beginner guidance, live battle feedback, and training review.

Heat is not a fixed strength score or a legality gate. A high-heat build may be intentional, but the player should understand the attack, disengage, stop, and active-cooling decisions required to use it.

## Shared Heat Language

All player-facing systems use the same five rhythm stages:

- `stable`: enough margin for ordinary actions.
- `pressure`: heat is rising and the next sequence should be chosen deliberately.
- `decision`: the player should finish the exchange, disengage, stop, or commit to active cooling.
- `vent`: manual or active cooling is committed and punishable.
- `overheat`: actions are restricted and the opponent gains a pressure window.

The unit-design side also describes an expected heat profile:

- `endurance`: sustained actions with generous margin.
- `burst`: short attack strings followed by natural cooling.
- `pressure`: planned sequences reach or cross the heat buffer.
- `redline`: repeated high-output actions require explicit retreat or vent windows.

## Burst Window Logic

Heat makes battle emphasize burst windows rather than infinite continuous attacks. A player should feel that every strong sequence asks a follow-up question: keep attacking, disengage, stop to cool, or commit to active cooling.

This logic should not collapse the meta into one correct answer. The heat profile exposes playstyle hooks for future content:

- `low_heat_endurance`: low-heat heroes can keep acting longer and treat burst windows as optional pressure, not forced recovery.
- `short_burst_rotation`: balanced attackers spend a short window, move or cool, then re-enter.
- `pressure_loop`: pressure builds skim the heat buffer and repeatedly choose whether to continue or reset.
- `redline_overlimit`: overlimit/red-temperature builds intentionally touch dangerous heat in exchange for stronger timing, then must retreat, stop, vent, or accept overheat risk.
- `cooling_window`: manual/active cooling, barriers, terrain, or future support systems can protect, fake, punish, or modify vent timing.
- `future_heat_traits`: later parts may add heat conversion, heat shields, conditional vents, redline bonuses, or low-heat precision traits without changing the core contract.

## Implementation

1. Add a pure `HeatDoctrineService` as the shared stage/profile vocabulary.
2. Make `UnitBuildRuleService` always return an advisory `heat_core` profile for applicable units and warn earlier about planned overheat loops.
3. Mark heat/cooling as a core concept in the beginner assembly guide and remind players to review heat rhythm after binding actions.
4. Add compact heat-stage labels to the live hero HUD without adding another control surface.
5. Add a heat-rhythm observation to training reports and explicitly teach the four heat decisions.
6. Expand README heat rules to state that heat is the combat-tempo core.

## Guardrails

- Heat advice never makes a unit illegal by itself.
- No fixed power score is introduced.
- The live HUD stays compact; detailed reasoning remains in editor guidance and training reports.
- Active cooling remains a punishable commitment rather than a free reset.
- Low-heat endurance and redline overlimit are both supported playstyle interfaces, not special-case exceptions.

## Verification

- A dedicated heat-core probe covers shared stages, build advisory behavior, beginner guidance, HUD labels, training guidance, and documentation.
- Existing build-rule, HUD, assembly-guide, training-report, cooling, and heat-model probes remain green.
