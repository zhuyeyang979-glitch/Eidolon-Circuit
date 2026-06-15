# Attack Rule Explanation Plan

Goal: help players understand why attacks work or fail without turning combat into a formula-reading exercise.

## Design Rules

- Keep combat lightweight. Live HUD feedback should use short cause tags only.
- Put detailed explanations in training validation and post-battle review, where the player has chosen to inspect results.
- Explain causes, not fixed strength. The system should never rank a build with a single power score or force a change.
- Use one shared attack-result breakdown so build preview, training, battle HUD, and review do not invent separate explanations.

## Explanation Layers

1. Build preview: each attack group should expose what the key drives, its damage source, range, heat/ammo cost, common failure risks, and approximate move possibilities such as thrust, sweep, heavy strike, shield bash, sustained pressure, lock-on shot, or tether control.
2. Training validation: important hits and failures should record compact reasons such as contact, momentum, material, occlusion, reflection, ammo, heat, and final damage.
3. Live combat: attack-group HUD should show short cause tags such as LOW MOM, MATERIAL, OCCLUDED, REFLECT, EMPTY, HEAT, RANGE, or HIT.
4. Post-battle review: command and result logs should make it possible to inspect whether the build executed as intended.

## Implementation

- Add helper methods in `scripts/main.gd` to create attack-result breakdown dictionaries and cause tags.
- Extend the training validation sample with an `attack_breakdowns` list capped to a small count.
- Record hit, blocked, reflected, occluded, empty-ammo, and low-momentum reasons through the shared sample helper.
- Extend `TrainingValidationReportService.report_text()` to render a short "命中解释" / "Hit explanation" section.
- Add build-preview text to action module detail cards so players know that training will explain final damage instead of the editor pretending to simulate it.
- Add an approximate move-possibility classifier to action module detail cards. It describes the move family and tactical use without promising exact damage or a fixed combo.
- Show the primary move possibility beside valid attack-key bindings so the editor reads like an authored move list at a glance.

## Verification

- Add `tools/attack_rule_explanation_probe.gd`.
- Register the probe in `tools/probe_manifest.json`.
- Run Godot check-only, the new probe, existing training validation probes, attack feedback probes, command review probes, and `git diff --check`.
