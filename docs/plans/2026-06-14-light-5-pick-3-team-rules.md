# Light 5 Pick 3 Team Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `light_5_pick_3_v1` the only active early-game team model and use one legality report for team drafting, saving, loading, sortie selection, and battle entry.

**Architecture:** Add a pure `TeamLegalityService` that owns the active rule profile, legacy light-profile resolution, and normalized roster/sortie audits. Keep `main.gd` responsible for converting saved-unit and live-roster data into normalized entries, localization, file IO, and UI feedback. Preserve unsupported current-schema 10/6 saves on disk and expose them as unsupported instead of deleting them.

**Tech Stack:** Godot 4 GDScript, JSON team saves under `user://saved_teams`, headless probes under `tools/`.

---

## Rule Contract

The only active profile is `light_5_pick_3_v1`:

- Formal roster: exactly 5 legal units, unique entry IDs, total cost `<= 2000`.
- Formal roster roles: at least 1 hero, 1 puppet, and 1 barrier.
- Sortie: exactly 3 unique units from the formal roster.
- Sortie roles: exactly one hero, one puppet, and one barrier.
- Starter: one of the sortie units with deploy cost `<= 200`.
- Unit length: each unit `<= 4.5`; non-barrier bands allow at most 1 above `3.5`, 2 above `2.5`, and 3 above `2.0`.
- Drafts with fewer than 5 units remain editable, but only `roster_ready` teams can be saved.

Compatibility:

- `rule_id: light_5_pick_3_v1`, legacy `match_format: light`, and legacy `roster_cap: 5` plus `sortie_cap: 3` resolve to the active profile.
- Current-schema 10/6 or unknown profiles remain visible but cannot be loaded as active teams.
- Loading always re-audits the restored roster before mutating current player state.

---

### Task 1: Define the Pure Team Rule Contract

**Files:**
- Create: `tools/team_legality_service_probe.gd`
- Create: `scripts/services/team_legality_service.gd`
- Modify: `tools/probe_manifest.json`

- [x] Write a failing probe covering the active profile, exact 5 roster, role coverage, budget, duplicate IDs, unit legality, length bands, exact 3 sortie, roster membership, starter membership/cost, and legacy light-save resolution.
- [x] Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/team_legality_service_probe.gd
```

Expected before implementation: FAIL because `TeamLegalityService` does not exist.

- [x] Implement:

```gdscript
func active_profile() -> Dictionary
func profile_for_rule_id(rule_id: String) -> Dictionary
func profile_for_saved_payload(payload: Dictionary) -> Dictionary
func audit(profile: Dictionary, roster_entries: Array, sortie_entries: Array = [], starter_entry: Dictionary = {}) -> Dictionary
```

- [x] Re-run the probe and expect `TEAM_LEGALITY_SERVICE_PROBE ok`.

### Task 2: Wire Saved-Unit Draft and Formal Team Save

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/controllers/saved_units_controller.gd`
- Modify: `tools/saved_units_controller_contract_probe.gd`
- Modify: `tools/saved_units_team_legality_probe.gd`
- Create: `tools/team_legality_main_integration_probe.gd`

- [x] Add service preload, initialization, active-profile accessors, normalized saved-unit entries, and localized report feedback.
- [x] Make the saved-unit selection toggle reject every entry with a non-empty `_saved_unit_entry_illegal_note()`.
- [x] Make the Save Team button and `_save_team_from_saved_unit_selection()` require `roster_ready`, not merely non-empty or under-cap.
- [x] Persist `rule_id: light_5_pick_3_v1` in new team saves.
- [x] Verify the focused probes fail before the wiring change and pass afterward.

### Task 3: Re-audit Team Loads and Preserve Unsupported Saves

**Files:**
- Modify: `scripts/main.gd`
- Modify: `tools/saved_units_saved_team_view_probe.gd`
- Modify: `tools/team_import_export_probe.gd`

- [x] Resolve the saved payload profile before loading.
- [x] Reject unsupported current-schema profiles without deleting their files.
- [x] Restore candidate slots into temporary data, audit them, and mutate the player roster only when `roster_ready`.
- [x] Keep legacy light 5/3 payloads load-compatible.
- [x] Export new teams with the active `rule_id`.

### Task 4: Use the Same Audit for Sortie and Battle Entry

**Files:**
- Modify: `scripts/main.gd`
- Modify: `tools/team_legality_main_integration_probe.gd`

- [x] Normalize live roster entries, sortie entries, and starter into the service contract.
- [x] Replace `_team_battle_entry_summary()` decision logic with `TeamLegalityService.audit()`.
- [x] Keep current detailed UI text by adapting the structured audit result at the main boundary.
- [x] Make the active cap/name helpers read the single active profile.

### Task 5: Limit Early UI to the Active Profile

**Files:**
- Modify: `scripts/main.gd`

- [x] Default `editor_match_format` to `light`.
- [x] Route format selection and the old toggle action to `light_5_pick_3_v1`.
- [x] Keep 10/6 save parsing compatibility but do not expose it as an active construction mode.

### Task 6: Verification

- [x] Run focused probes:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/team_legality_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/team_legality_main_integration_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/saved_units_controller_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/saved_units_team_legality_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/saved_units_saved_team_view_probe.gd
```

- [x] Run project parse check:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

- [x] Run `git diff --check`.
