# Tactical Input Layers Implementation Plan

**Goal:** Preserve fighting-game precision by making the hero the only high-frequency direct-control unit, while puppets and barriers remain low-frequency tactical deployments governed by preauthored rules.

**Architecture:** Add a small input contract to `BattleInputService`, expose that contract through README and in-game help text, and verify the settings page lists tactical deployment controls without adding direct puppet or barrier micro-control actions. Keep all battle behavior local and deterministic.

**Tech Stack:** Godot 4.6 GDScript, existing `tools/*_probe.gd` headless probes, README gameplay documentation.

---

### Task 1: Contract Probe

**Files:**
- Create: `tools/tactical_input_contract_probe.gd`
- Modify: `tools/probe_manifest.json`

**Steps:**
1. [x] Add a probe that checks the README, `BattleInputService`, HUD help text, and settings input list.
2. [x] Verify the probe fails before implementation because the service contract and updated wording do not exist yet.

### Task 2: Runtime Input Contract

**Files:**
- Modify: `scripts/services/battle_input_service.gd`
- Modify: `scripts/main.gd`

**Steps:**
1. [x] Add a `tactical_input_contract()` method returning high-frequency hero actions, mid-frequency tactical actions, low-frequency prebattle rules, and forbidden direct puppet/barrier micro actions.
2. [x] Update battle help text to explain high-frequency hero control and low-frequency tactical deployment.
3. [x] Add the portal/tactical deployment control to the settings input list so it is visible and rebindable.
4. [x] Restore hero manual cooling as a high-frequency input layer action.

### Task 3: Documentation

**Files:**
- Modify: `README.md`

**Steps:**
1. [x] Correct the portal key from `Q` to `Tab`.
2. [x] Add a Tactical Input Model section explaining why this is not auto-battler control and not RTS-style micro.
3. [x] Mention paired attack-button summon chords as low-frequency tactical deployment.

### Task 4: Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/tactical_input_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_input_settings_ui_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://scripts/main.gd --check-only --quit-after 1
git diff --check
jq empty tools/probe_manifest.json
```

Latest local verification on 2026-06-15:

- [x] `tactical_input_contract_probe` passed with `failed=false`.
- [x] `battle_input_settings_ui_probe` passed.
- [x] `battle_input_service_contract_probe` passed.
- [x] `manual_cooling_contract_probe` passed.
- [x] `input_map_reserved_keys_probe` passed.
- [x] `ui_layout_probe` passed with `overlap=0 out=0 hard=0`.
- [x] `text_overflow_probe` passed with all counts `0`.
- [x] `--script res://scripts/main.gd --check-only --quit-after 1` returned exit code `0`.
- [x] `git diff --check` and `jq empty tools/probe_manifest.json` returned exit code `0`.
