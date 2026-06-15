# Build Rule Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current shallow training legality gate with a centralized build-rule audit that separates hard invalid construction problems from balance warnings and build-efficiency feedback.

**Architecture:** Add a focused `UnitBuildRuleService` that consumes already-computed stats plus normalized topology data and returns a structured audit. Keep `_training_blueprint_illegal_note()` as the final public gate, but delegate new hard-blocking construction balance checks to the service. Editor UI can later consume warnings without changing the gate again.

**Tech Stack:** Godot 4 GDScript, existing headless probe scripts under `tools/`, existing `main.gd` stats/topology helpers.

---

### Task 1: Add Build-Rule Service Probe

**Files:**
- Create: `tools/unit_build_rule_service_probe.gd`

**Step 1: Write the failing probe**

Create a probe that preloads `res://scripts/services/unit_build_rule_service.gd` and verifies:

- A healthy build audit has no hard invalid reason.
- A build with `idle_mass_ratio > 0.55` is hard invalid.
- A build with `weapon_utilization_ratio < 0.15` and meaningful weapon mass is hard invalid.
- A build with `dominant_role_ratio < 0.35` is a warning, not a hard invalid.
- A build with `drive_peak_ratio > 1.35` is hard invalid.
- A build with `heat_peak_ratio > 1.60` is a warning, not a hard invalid.

**Step 2: Run probe to verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_build_rule_service_probe.gd
```

Expected: FAIL because `scripts/services/unit_build_rule_service.gd` does not exist yet.

---

### Task 2: Implement UnitBuildRuleService

**Files:**
- Create: `scripts/services/unit_build_rule_service.gd`

**Step 1: Add service API**

Implement:

```gdscript
extends RefCounted
class_name UnitBuildRuleService

func audit(context: Dictionary) -> Dictionary
func first_hard_invalid_note(audit: Dictionary) -> String
```

The returned audit should include:

- `hard_invalid`: bool
- `hard_notes`: Array[String]
- `warnings`: Array[String]
- `score_notes`: Array[String]
- `metrics`: Dictionary

**Step 2: Add V1 rule thresholds**

Use these initial thresholds:

- Idle mass hard invalid: `idle_mass_ratio > 0.55`, warning at `> 0.40`.
- Weapon utilization hard invalid: `weapon_utilization_ratio < 0.15` when `weapon_mass >= 6.0`, warning at `< 0.30`.
- Dominant role warning: `dominant_role_ratio < 0.35` when at least two role contribution buckets are nonzero.
- Drive peak hard invalid: `drive_peak_ratio > 1.35`, warning at `> 1.0`.
- Heat peak warning: `heat_peak_ratio > 1.60`, caution at `> 1.20`; not a hard invalid in V1.
- Plugin pressure warning at `> 0.85`; hard invalid remains owned by existing slot compatibility checks.
- Apply idle-material and action-bound weapon rules only to roles where those concepts are meaningful; barrier canvas material is functional structure and is exempt from idle-mass rejection.

**Step 3: Run probe to verify GREEN**

Run the probe from Task 1. Expected: PASS.

---

### Task 3: Wire Build Audit Into Training Legality

**Files:**
- Modify: `scripts/main.gd`

**Step 1: Preload and initialize service**

Add:

```gdscript
const UnitBuildRuleService = preload("res://scripts/services/unit_build_rule_service.gd")
var unit_build_rule_service: UnitBuildRuleService
```

Initialize it in `_ready()` near other services.

**Step 2: Build audit context from stats**

Add helper:

```gdscript
func _unit_build_rule_audit(role_key: String, unit_bp: Dictionary, stats: Dictionary) -> Dictionary
```

The first version should derive metrics from existing stats only:

- idle mass ratio from disconnected/unbound material metrics when present, otherwise `0.0`.
- weapon utilization from `runtime_module_bindings`, `terminal_weapon_mass`, and future explicit stats fields.
- role contribution from damage, health, mobility, control/support fields.
- drive peak ratio from `drive_demand_total / drive_output_total`.
- heat peak ratio from attack/boost heat against heat capacity.
- plugin pressure from `slot_payload_volume_rank` against internal slot count.

**Step 3: Gate only hard invalid notes**

After `_topology_rule_note()` and before existing note-key checks in `_training_blueprint_illegal_note()`, call the audit and return the first hard invalid note if present.

Expected behavior: warnings do not block training yet.

---

### Task 4: Add Main-Level Probe

**Files:**
- Create: `tools/unit_build_rule_training_gate_probe.gd`

**Step 1: Write probe**

Instantiate `MainScene`, build a minimal legal hero blueprint, compute stats, and assert:

- `_unit_build_rule_audit()` returns a structured audit.
- A synthetic high idle-mass context blocks through `UnitBuildRuleService`.
- `_training_blueprint_illegal_note()` still returns existing topology errors before build-audit errors.

**Step 2: Run probe**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_build_rule_training_gate_probe.gd
```

Expected: PASS.

---

### Task 5: Verification

Run focused probes:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_build_rule_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_build_rule_training_gate_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/internal_slot_size_probe.gd
```

Run project check:

```bash
pwsh -File tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120
```

Expected: all focused probes pass; check-only exits 0.
