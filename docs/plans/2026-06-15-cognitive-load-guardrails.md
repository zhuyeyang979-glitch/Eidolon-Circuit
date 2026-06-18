# Cognitive Load Guardrails

**Goal:** Keep the game readable under fighting-game pressure by making the hero the only high-frequency direct-control focus. Puppets and barriers should deepen construction and tactical timing without becoming extra real-time units to micromanage.

## Rules

1. Hero control owns the fast loop: movement, facing, Boost, attack buttons, command inputs, aiming holds, and cooling.
2. Aiming may temporarily reserve `Q/E` or equivalent turn inputs, but movement remains on the same movement layer.
3. Puppets and barriers are committed through low-frequency tactical actions: portal selection, pair-summon chords, prepared sortie slots, and placement intent.
4. Puppet behavior comes from authored Source Code routines. Barrier behavior comes from authored Ether logic and runtime fields.
5. New mechanics must not add continuous puppet movement axes, puppet attack buttons, barrier movement axes, barrier attack buttons, or role-camera micro-cycling.
6. If a feature needs more player decisions, prefer build-time authoring, delayed execution, buffered confirmation, or clearer feedback over adding more live buttons.

## Implementation

- `BattleInputService.cognitive_load_contract()` defines the runtime focus owner, forbidden micro actions, and feature gates.
- `tactical_input_contract()` embeds the cognitive-load contract so input tests can verify both tactical layering and attention-budget rules.
- README documents the guardrails as a battle design principle, not only a control note.
- `tools/cognitive_load_guardrails_probe.gd` prevents forbidden puppet/barrier direct-control actions from appearing in the runtime action list.

## Verification

- `cognitive_load_guardrails_probe`
- `tactical_input_contract_probe`
- `battle_input_settings_ui_probe`
- `ui_layout_probe`
- `text_overflow_probe`
