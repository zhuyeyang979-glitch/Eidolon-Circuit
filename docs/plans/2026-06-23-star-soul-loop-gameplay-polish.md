# Star Soul Loop Gameplay Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish the new 星魂回环 gameplay baseline into a coherent, tested, player-readable implementation without breaking existing saved-unit compatibility.

**Architecture:** Keep `scripts/main.gd` as the current runtime adapter, but move pure rules into service classes and contract probes whenever possible. Preserve legacy internal keys such as `torso`, `limb_muscle`, `muscle`, and `booster` until a dedicated migration is ready; only player-facing labels should move immediately to 核心、连接件、硬件、推进器、软硬件、功能模块等新术语.

**Tech Stack:** Godot 4.6.2, GDScript, headless probes under `tools/`, local Godot at `/Volumes/vol1/Godot/bin/godot`, existing probe manifest and modular-monolith architecture.

---

## Scope

This plan covers follow-up polishing for the current gameplay update. It does not require a rewrite of the battle runtime or unit editor in one pass.

Allowed work:

- Tighten wording, labels, tutorial copy, summaries, and contract probes.
- Add focused services or helper methods for pure rules.
- Add failing probes before changing behavior.
- Keep internal data compatibility while updating player-facing terminology.
- Improve numeric examples and telemetry so designers can tune later.

Deferred work:

- Full save-data schema migration away from legacy keys.
- New art assets for every part family.
- Online battle, rollback, matchmaking, or cloud profile behavior.
- Large-scale `main.gd` extraction unless a task explicitly scopes it.

## Current Baseline

Recent changes already completed:

- README gameplay baseline rewritten around PVP, PVE story, PVE roguelike, unit editing, part families, and momentum-first combat.
- Editor-visible categories moved toward 核心、连接件、武器、功能模块、软硬件、软件.
- Combat now has `momentum_damage_gate_intent()` and a strict `damage > break_value` gate.
- Blocked hits still apply displacement/knock intent.
- Laser and chemical projectile momentum are fixed at `1`.
- Targeted probes and `--check-only` pass.

Known compatibility choice:

- Runtime/catalog internals still use old keys such as `torso`, `limb_muscle`, `muscle`, `booster`, and `software_muscle`. Treat these as compatibility IDs, not player-facing terms.

## Verification Commands

Use these commands after every task:

```bash
GODOT=/Volumes/vol1/Godot/bin/godot

"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit
git diff --check
```

Focused probe template:

```bash
GODOT=/Volumes/vol1/Godot/bin/godot
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/<probe_name>.gd
```

## Task 1: Terminology Audit And Glossary Contract

**Files:**

- Modify: `README.md`
- Modify: `scripts/controllers/unit_editor_catalog_controller.gd`
- Modify: `scripts/services/unit_editor_assembly_guide_service.gd`
- Modify: `scripts/main.gd`
- Test: `tools/equipment_group_label_probe.gd`
- Test: `tools/unit_editor_catalog_controller_contract_probe.gd`
- Test: `tools/unit_editor_assembly_guide_service_probe.gd`
- Test: `tools/unit_editor_assembly_guide_ui_probe.gd`

**Steps:**

1. Search for player-facing old terms: `躯干`, `肢体`, `连接肌肉`, `装备`, `结界板`, `BOOSTER`, `TORSO`, `LIMB`, `EQUIPMENT`, `BARRIER`.
2. Classify each hit as compatibility ID, old player-facing label, part name, or historical doc.
3. Update only player-facing labels and tutorials in this pass.
4. Add probe assertions for 核心、连接件、功能模块、软硬件、THRUSTER.
5. Keep old part names like `CRAB TORSO CHASSIS` unless a dedicated catalog rename task is approved.

**Acceptance:**

- No old category labels appear in editor group names, filter names, or assembly guide copy.
- Legacy keys remain readable in source where they are internal IDs.
- The four editor terminology probes pass.

## Task 2: Combat Formula Traceability

**Files:**

- Modify: `scripts/services/battle_hit_resolution_service.gd`
- Modify: `scripts/services/runtime_contact_service.gd`
- Modify: `scripts/main.gd`
- Test: `tools/battle_hit_resolution_service_contract_probe.gd`
- Test: `tools/runtime_contact_service_contract_probe.gd`
- Add if needed: `tools/momentum_damage_gate_runtime_probe.gd`

**Steps:**

1. Add examples to probe `momentum_damage_gate_intent()` for pass, equal-block, below-block, non-damage knock, and adjusted break value.
2. Verify every runtime hit event records `momentum`, `damage_coefficient`, `adjustment_coefficient`, `break_value`, `effective_break_value`, and `knock_momentum`.
3. Add a runtime-level probe that executes one melee hit and checks attack-rule telemetry, not only pure service output.
4. Confirm `damage == break_value` always blocks.
5. Confirm blocked hits still trigger displacement intent.

**Acceptance:**

- Designers can inspect a hit result and see why it damaged or failed to damage.
- Service-level and runtime-level probes both cover the formula.

## Task 3: Melee Type Rule Pass

**Files:**

- Modify: `scripts/main.gd`
- Modify if extracting: `scripts/services/battle_hit_resolution_service.gd`
- Test: `tools/battle_hit_resolution_service_contract_probe.gd`
- Add if needed: `tools/melee_damage_type_rule_probe.gd`

**Steps:**

1. Lock current mapping: `tear` means slash, `pierce` means stab, `blunt` means blunt.
2. Add probe cases for slash `1.5x` damage adjustment.
3. Add probe cases for stab `0.5x` target break-value adjustment.
4. Add probe cases for blunt `2x` knock adjustment without extra damage adjustment.
5. Decide whether code names should stay `tear/pierce/blunt` or gain aliases `slash/stab/blunt`.

**Acceptance:**

- Player-facing explanation and runtime behavior match.
- Old internal damage keys remain supported until a separate migration.

## Task 4: Projectile Ammo Family Alignment

**Files:**

- Modify: `scripts/services/projectile_runtime_service.gd`
- Modify: `scripts/main.gd`
- Test: `tools/projectile_runtime_service_contract_probe.gd`
- Test: `tools/chemical_sprayer_hold_release_probe.gd`

**Steps:**

1. Document current mapping: metal bullet = `bullet`, electric = current `laser`, chemical = `chemical`.
2. Add a helper or comments that make the electric/laser naming bridge explicit.
3. Ensure laser/electric and chemical ignore explicit `projectile_momentum` and `projectile_mass` when fixed momentum applies.
4. Confirm metal bullet guns still use gun-supplied projectile momentum.
5. Add a probe for chemical DoT still applying after fixed momentum changes.

**Acceptance:**

- Fixed-momentum projectile families are impossible to accidentally override through part data.
- Bullet/sniper/missile momentum behavior is unchanged.

## Task 5: Unit Editor Legality Roadmap

**Files:**

- Reference: `scripts/services/unit_stats_service.gd`
- Reference: `scripts/services/unit_blueprint_validator.gd` if present
- Modify later: `scripts/main.gd`
- Test later: saved-unit and validator probes under `tools/`

**Steps:**

1. List legality rules now only documented: one hardware minimum, slot size <= slot capacity, one part per matching slot, construct-body single manufacturer, role-required Soul/Source Code/Ether.
2. Map each rule to current validator coverage.
3. Add missing rejection probes before implementation.
4. Keep validator errors player-readable in both Chinese and English.
5. Do not migrate topology storage keys in this task.

**Acceptance:**

- Every documented editor rule has either an existing probe or a TODO with exact missing owner file.
- No silent invalid builds enter battle.

## Task 6: Hardware Fault And Destruction Design

**Files:**

- Reference: `scripts/fighter.gd`
- Reference: `scripts/main.gd`
- Reference: `scripts/services/battle_hit_resolution_service.gd`
- Add design first: `docs/plans/YYYY-MM-DD-hardware-fault-runtime.md`
- Test later: `tools/hardware_fault_contract_probe.gd`

**Steps:**

1. Define runtime state names: normal, faulted, destroyed.
2. Decide where hardware momentum capacity is stored and how it maps from current `stiffness` / `momentum_capacity`.
3. Define how action modules query faulted hardware before execution.
4. Define how core destruction removes the whole construct body.
5. Add probe-first plan before implementation.

**Acceptance:**

- Fault/destruction is designed before touching battle runtime.
- The design includes UI feedback, save compatibility, and replay determinism.

## Task 7: Source Code Priority UI Plan

**Files:**

- Reference: `scripts/services/unit_editor_assembly_guide_service.gd`
- Reference: `scripts/main.gd`
- Add later: controller/view/service files if needed
- Test later: source-code priority UI probe

**Steps:**

1. Inventory current Source Code selection and puppet behavior fields.
2. Define a minimal priority-order editor for multiple Source Codes.
3. Keep first implementation data-only if UI complexity is high.
4. Add a probe that saved puppet blueprints preserve Source Code order.
5. Add player-facing explanation for what priority means after construct bodies are destroyed.

**Acceptance:**

- Multiple Source Codes can be ordered deterministically.
- Destroyed construct bodies do not erase Source Codes carried by surviving bodies.

## Task 8: Balance Instrumentation

**Files:**

- Modify: attack-rule telemetry helpers in `scripts/main.gd`
- Modify or add: battle diagnostics probes under `tools/`

**Steps:**

1. Add optional debug fields for raw momentum, capped momentum, break gate, final damage, and knock momentum.
2. Keep the HUD compact; expose detailed numbers in diagnostics or post-battle review, not always-on combat UI.
3. Create sample probes for low momentum, equal break block, slash pass, stab pass, blunt knock, laser fixed momentum, and chemical DoT.
4. Record numeric examples in a small balance note.

**Acceptance:**

- Designers can tune coefficients without guessing why a hit succeeded.
- Probe fixtures cover representative numeric cases.

## Task 9: Documentation Reconciliation

**Files:**

- Modify: `README.md`
- Modify or add: `docs/TODO.md`
- Add if useful: `docs/reports/2026-06-23-star-soul-loop-gameplay-polish-summary.md`

**Steps:**

1. Separate current prototype entry points from long-term mode families.
2. Mark legacy terms as compatibility terms where they still appear in code.
3. Add a small glossary table: player term, current internal key, migration status.
4. Move deeper future systems such as fault runtime and Source Code priority UI into TODO or follow-up plan files.
5. Keep README readable for a new contributor.

**Acceptance:**

- A contributor can tell what is already implemented, what is compatibility naming, and what is planned.

## Task 10: Completion Gate

The polish pass is complete when:

- `git diff --check` passes.
- Godot `--check-only` passes.
- All changed focused probes pass.
- New runtime probes cover the momentum damage gate in actual battle flow.
- Editor labels and tutorials no longer mix old and new category terminology except intentional compatibility IDs.
- README and TODO explain remaining deferred systems clearly.

Suggested final verification:

```bash
GODOT=/Volumes/vol1/Godot/bin/godot

"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_hit_resolution_service_contract_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/projectile_runtime_service_contract_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/runtime_contact_service_contract_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_catalog_controller_contract_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_service_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_ui_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/equipment_group_label_probe.gd
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/chemical_sprayer_hold_release_probe.gd
git diff --check
```
