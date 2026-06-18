# Unit Library Legality Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow only canonical, deployable units into the formal saved-unit library while preserving non-blocking balance warnings.

**Architecture:** Add a single main-level unit-library eligibility audit that composes the existing saved-payload schema validation with `_training_blueprint_illegal_note()`. Keep `SavedUnitLibraryService` focused on pure payload/path/cache operations, and keep `UnitBuildRuleService` as the source of detailed construction-balance metrics. The save command must run the eligibility audit before any file write and verify the loaded entry after serialization.

**Tech Stack:** Godot 4 GDScript, JSON files under `user://saved_units`, existing headless probes under `tools/`.

---

## Design Decision

The formal unit library stores reusable deployable units, not incomplete drafts.

An entry is eligible when:

1. `storage_valid`: the payload uses the current schema, contains canonical topology, and contains no deprecated drive, pointer, or nonphysical combat fields.
2. `deployable`: `_training_blueprint_illegal_note(player_id, role_key, blueprint)` returns an empty string, including topology, size, module material, idle mass, weapon utilization, drive, slot, and stiffness hard rules.
3. `warnings`: balance warnings from `_unit_build_rule_audit()` are returned for UI use but do not block saving.

Player ownership and component unlock eligibility are intentionally deferred until a persistent player-profile identity exists.

### Rejected alternatives

- Keep accepting structurally valid but undeployable units: conflicts with the requirement that the formal library contain legal units.
- Add a draft library now: useful later, but introduces another persistence lifecycle before player profiles exist.
- Duplicate all training rules inside the library service: would create rule drift; the save gate must reuse the existing legality entry point.

---

### Task 1: Add Unit-Library Eligibility Probe

**Files:**
- Create: `tools/unit_library_legality_gate_probe.gd`

**Step 1: Write the failing probe**

Verify that:

- A current-schema blueprint that is canonical but fails a hard construction rule is rejected before a file is created.
- The rejection message contains the first construction failure.
- A known legal starter blueprint saves successfully and can be loaded back.
- A warning-only `UnitBuildRuleService` audit remains non-blocking.

**Step 2: Run the probe to verify RED**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_library_legality_gate_probe.gd
```

Expected: FAIL because the current save path only validates canonical storage format.

---

### Task 2: Implement Eligibility Audit

**Files:**
- Modify: `scripts/main.gd`

**Step 1: Add structured audit helper**

Add:

```gdscript
func _unit_library_save_audit(player_id: int, role_key: String, unit_bp: Dictionary, payload: Dictionary) -> Dictionary
```

Return:

```gdscript
{
    "accepted": bool,
    "storage_valid": bool,
    "deployable": bool,
    "blocking_note": String,
    "warnings": Array,
    "build_audit": Dictionary,
}
```

Storage rejection has priority. If storage is valid, compute stats, collect `UnitBuildRuleService` warnings, and reuse `_training_blueprint_illegal_note()` for the complete hard gate.

**Step 2: Gate before writing**

In `_save_editor_current_unit_to_library_named()`, replace the schema-only preflight with `_unit_library_save_audit()`. On rejection, use existing save failure feedback and return without creating or replacing a file.

**Step 3: Verify readback deployability**

After reading the saved entry back, reject the operation if `_saved_unit_entry_illegal_note()` is non-empty. The preflight remains the primary protection; readback validation detects serialization or future schema drift.

---

### Task 3: Record Player-Bound Library Backlog

**Files:**
- Create or modify: `docs/TODO.md`

Document a future project covering:

- Persistent `profile_id` separate from local battle seat IDs.
- `user://profiles/<profile_id>/saved_units/<unit_id>.json` namespace.
- Payload fields `owner_profile_id`, stable `unit_id`, timestamps, and revision.
- Repository API for list/load/save/delete/duplicate by profile.
- Save-As generating a new `unit_id`.
- Migration from the current shared `user://saved_units` directory.
- Ownership/component-unlock eligibility integrated into the legality audit.

---

### Task 4: Verification

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_library_legality_gate_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/saved_unit_postwrite_validation_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/saved_unit_strict_rejection_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/teamedit_save_unit_real_ui_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
```

Expected: focused probes pass, project check exits 0, and no whitespace errors are reported.
