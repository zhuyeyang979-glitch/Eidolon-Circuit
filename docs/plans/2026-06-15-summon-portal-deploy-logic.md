# Summon Portal Deploy Logic Plan

Goal: optimize the runtime operation for choosing a summon entrance and spending battle resource to deploy a hero, puppet group, or barrier.

## Design Direction

- Keep hero control as the only high-frequency direct-control layer.
- Treat summoning as a low-frequency tactical commitment, not another fighting-game command.
- Separate entrance selection from deployment confirmation.
- Preserve the existing pair-summon slot model so players still deploy prepared 5-pick-3 units instead of micromanaging roles.

## Operation Model

- Tap portal input to cycle the selected summon entrance.
- Hold a direction and tap portal input to direct-select the corresponding entrance.
- Press the sortie slot's assigned attack-key pair to commit deployment through the selected portal.
- Do not let the movement vector at pair-press time silently change the portal.
- On portal selection, show a concise preview of the first sortie bindings and current live deploy costs.
- On successful deployment, show one combined message with slot, role, unit index, portal, deploy wait, and resource cost or discount.

## Implementation

- Add `summon_portal_selection_intent()` to `BattleActorCommandService`.
- Delegate `main.gd` portal selection to the service.
- Change `_summon_sortie_slot()` so it uses `portal_index[player_id]` rather than the current movement input.
- Keep `_summon_role()` as the resource gate and pending deploy owner.
- Update README controls and tactical input text.

## Verification

- Extend `battle_actor_command_service_contract_probe`.
- Add `summon_portal_deploy_logic_probe`.
- Run Godot check-only, targeted battle actor/input/HUD probes, layout/text probes, manifest validation, and `git diff --check`.
