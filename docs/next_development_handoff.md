# Eidolon Circuit Next Development Handoff

Last updated: 2026-06-10

This is the short handoff for continuing development after adopting yhzlxp's battle boundary work and the architecture guard branch.

## Current Integration Baseline

- Base repository: `zhuyeyang979-glitch/Eidolon-Circuit`
- Next-version PR: `https://github.com/zhuyeyang979-glitch/Eidolon-Circuit/pull/2`
- PR branch: `codex/yhzlxp-eidolon-work`
- PR head: `7d44ab2` (`Merge remote-tracking branch 'origin/codex/eidolon-architecture-boundaries' into codex/yhzlxp-eidolon-work`)
- Base branch: `main` at `c9178ab`
- Local follow-up branch for this handoff: `codex/future-dev-handoff`
- GitHub Actions on PR #2: `Godot Governance` run #32 passed.

## Recommended Branching

- Treat `codex/yhzlxp-eidolon-work` as the active next-version integration branch until PR #2 is merged.
- For new work, create stacked branches from `codex/yhzlxp-eidolon-work`, then open PRs targeting `codex/yhzlxp-eidolon-work`.
- After PR #2 merges to `main`, retarget or rebase any stacked follow-up PRs onto `main`.
- Keep the old local stash `codex-preserve-before-sync-to-origin-main-2026-06-10` untouched unless explicitly recovering the pre-sync safety branch work.

## Development Direction

- Continue reducing `main.gd` by moving ownership, not by moving deep algorithms first.
- Keep `main.gd` as AppRoot/composition root while `AppModeHost`, mode owner stubs, and `BattleState` mature behind contract probes.
- Put new top-level screen behavior in the matching mode owner: menu, team edit, saved units, training, battle, or settings.
- Put shared pure rules in services/domain-style helpers, and keep Godot Node side effects in Node owners.
- Do not add new battle rules, editor board behavior, save/load policy, HUD/view bodies, or direct gameplay input policy directly to `main.gd`.

## Verification Gate

Run this minimum gate before pushing stacked branches:

```powershell
tools\run_godot_checked.ps1 -CheckOnly -TimeoutSec 120
```

Then run the probes most relevant to the edited boundary. For architecture/mode work, include:

```text
app_mode_host_contract_probe
app_root_boundary_probe
battle_state_contract_probe
battle_mode_contract_probe
menu_mode_contract_probe
team_edit_mode_contract_probe
saved_units_mode_contract_probe
settings_mode_contract_probe
training_mode_contract_probe
combat_probe
ui_layout_probe
text_overflow_probe
```

For broad changes, also run the GitHub Governance 16-probe mirror from `.github/workflows/godot-governance.yml`.

## Next Safe Work

1. Move a thin, non-behavioral ownership slice from `main.gd` into one mode owner while preserving existing wrappers.
2. Add or extend the matching contract probe before moving behavior.
3. Run the focused probe, then `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
4. Push the stacked branch and open a PR targeting `codex/yhzlxp-eidolon-work` until PR #2 lands.
