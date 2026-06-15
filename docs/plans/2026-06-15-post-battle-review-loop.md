# Post-Battle Review Loop Implementation Plan

**Goal:** Add an optional post-battle review loop so players can choose whether to inspect the result, adjust the current sortie/build, rematch, or leave.

**Architecture:** Keep battle-end resolution in place and add a HUD-level review overlay that appears after `game_over` without navigating away automatically. Route player choices through existing battle, scout, editor, and menu transitions so the loop stays compatible with local versus, computer battle, and training flows.

**Tech Stack:** Godot 4.6 GDScript, existing menu controller/view pattern, existing `tools/*_probe.gd` headless probes.

---

### Task 1: Contract Probe

**Files:**
- Create: `tools/post_battle_review_loop_probe.gd`
- Modify: `tools/probe_manifest.json`

**Steps:**
1. Add a probe that ends a battle and confirms the game remains on the battle page.
2. Confirm the post-battle panel is visible and offers review, adjust-sortie, edit-units, rematch, and main-menu actions.
3. Confirm adjust-sortie navigates to Scout, edit-units navigates to Team Edit, and rematch starts a fresh battle.

### Task 2: Review Overlay

**Files:**
- Modify: `scripts/controllers/menu_controller.gd`
- Modify: `scripts/views/menu_view.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/ui_layout_tokens.gd`

**Steps:**
1. Add a post-battle model and action mapper to `MenuController`.
2. Add a HUD-level post-battle panel to `MenuView`.
3. Wire `main.gd` to show the panel from `_end_battle()` and hide it when leaving battle or rematching.
4. Keep `game_state == STATE_BATTLE` until the player chooses an action.

### Task 3: Documentation

**Files:**
- Modify: `README.md`

**Steps:**
1. Add a Post-Battle Review Loop section after the win condition.
2. Explain that deck/build adjustment is optional and player-triggered, not forced by battle end.

### Task 4: Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/post_battle_review_loop_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://scripts/main.gd --check-only --quit-after 1
git diff --check
jq empty tools/probe_manifest.json
```

Latest local verification on 2026-06-15:

- [x] `post_battle_review_loop_probe` passed with `failed=false`.
- [x] `ui_layout_probe` passed with `overlap=0 out=0 hard=0`.
- [x] `text_overflow_probe` passed with all counts `0`.
- [x] `--script res://scripts/main.gd --check-only --quit-after 1` returned exit code `0`.
- [x] `main_menu_navigation_probe` passed.
- [x] `settings_return_target_probe` passed.
- [x] `git diff --check` and `jq empty tools/probe_manifest.json` returned exit code `0`.
