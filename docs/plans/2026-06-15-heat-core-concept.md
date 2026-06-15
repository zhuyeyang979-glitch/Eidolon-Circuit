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

## Verification

- A dedicated heat-core probe covers shared stages, build advisory behavior, beginner guidance, HUD labels, training guidance, and documentation.
- Existing build-rule, HUD, assembly-guide, training-report, cooling, and heat-model probes remain green.
