# Battle Contact VFX Pool Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Continue EC-SLIM-002 by moving `BattleContactVfxPool` out of `scripts/main.gd` without changing runtime contact VFX behavior.

**Architecture:** Keep `scripts/main.gd` as the battle owner that creates, configures, and calls the pool. Move only the GPU particle pool implementation to `scripts/effects/battle_contact_vfx_pool.gd`, matching the existing extracted effect preload pattern. Update the source and runtime probes so future regressions catch both missing extraction and broken particle-pool setup.

**Tech Stack:** Godot 4.6.2 GDScript, `Node2D`, `GPUParticles2D`, `ParticleProcessMaterial`, and existing headless probes under `tools/`.

---

## File Structure

- Create `scripts/effects/battle_contact_vfx_pool.gd`
  - Publishes `class_name BattleContactVfxPool`.
  - Owns `setup_pool()` and `emit_gpu_contact()` particle-pool behavior.

- Modify `scripts/main.gd`
  - Add `const BattleContactVfxPool = preload("res://scripts/effects/battle_contact_vfx_pool.gd")`.
  - Remove the inline `class BattleContactVfxPool` body.
  - Preserve existing creation and call sites.

- Modify `tools/effect_extraction_contract_probe.gd`
  - Require the new effect script, preload token, no inline class, and runtime state checks.

- Modify `tools/gpu_contact_vfx_pool_probe.gd`
  - Require the external pool script instead of an inline `main.gd` class.
  - Instantiate the pool and verify particle count, scaling, emission cursor, and material color behavior.

- Modify `tools/main_inline_class_guard_probe.gd`
  - Move `BattleContactVfxPool` from `ALLOWED_INLINE_CLASSES` to `EXTRACTED_INLINE_CLASSES`.

---

### Task 1: Add RED Contract Coverage

**Files:**
- Modify: `tools/effect_extraction_contract_probe.gd`
- Modify: `tools/gpu_contact_vfx_pool_probe.gd`
- Modify: `tools/main_inline_class_guard_probe.gd`

- [ ] **Step 1: Require the new external effect script**

Add `BATTLE_CONTACT_VFX_POOL_PATH`, preload it in the effect extraction probe, include it in the main preload loop, forbid the inline class, and instantiate it with:

```gdscript
var contact_pool = BattleContactVfxPoolScript.new()
root.add_child(contact_pool)
contact_pool.setup_pool(3, 2.0)
contact_pool.emit_gpu_contact(Vector2(9.0, 12.0), Vector2.RIGHT, 2.0, 1)
```

Verify `particles.size() == 3`, `pool_scale == 1.65`, `cursor == 1`, and `emitted_count == 1`.

- [ ] **Step 2: Update the dedicated GPU contact VFX probe**

Make `tools/gpu_contact_vfx_pool_probe.gd` read `scripts/effects/battle_contact_vfx_pool.gd` for `class_name BattleContactVfxPool`, `GPUParticles2D`, `setup_pool`, and `emit_gpu_contact`, while still requiring `main.gd` to preload the script and route runtime descriptors through `_emit_gpu_contact_vfx_descriptor()`.

- [ ] **Step 3: Update the inline-class guard**

Remove `"BattleContactVfxPool"` from `ALLOWED_INLINE_CLASSES` and add it to `EXTRACTED_INLINE_CLASSES`.

- [ ] **Step 4: Verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/effect_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/gpu_contact_vfx_pool_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: fail because `scripts/effects/battle_contact_vfx_pool.gd` does not exist yet and the class remains inline.

---

### Task 2: Extract the Pool

**Files:**
- Create: `scripts/effects/battle_contact_vfx_pool.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Create the external pool script**

Move the complete current `BattleContactVfxPool` body into `scripts/effects/battle_contact_vfx_pool.gd`, replacing the inline declaration with:

```gdscript
class_name BattleContactVfxPool
extends Node2D
```

- [ ] **Step 2: Add the main preload**

Add near the existing effect preloads:

```gdscript
const BattleContactVfxPool = preload("res://scripts/effects/battle_contact_vfx_pool.gd")
```

- [ ] **Step 3: Remove the inline class body**

Delete only the `class BattleContactVfxPool` block from `scripts/main.gd`; keep `battle_contact_vfx_pool = BattleContactVfxPool.new()` and all runtime calls unchanged.

---

### Task 3: Verify the Extraction

**Files:**
- Test: `tools/effect_extraction_contract_probe.gd`
- Test: `tools/gpu_contact_vfx_pool_probe.gd`
- Test: `tools/main_inline_class_guard_probe.gd`

- [ ] **Step 1: Run targeted probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/effect_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/gpu_contact_vfx_pool_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: all exit `0`.

- [ ] **Step 2: Run adjacent runtime probes**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_vfx_budget_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_runtime_frame_budget_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/combat_probe.gd
```

Expected: all exit `0`; no new GPU contact VFX regression.

## Self-Review

- Spec coverage: Covers the next low-coupling EC-SLIM extraction after contextual battle effects.
- Placeholder scan: No `TBD`, open TODOs, or unspecified test commands remain.
- Type consistency: Uses the existing `BattleContactVfxPool.new()`, `setup_pool()`, and `emit_gpu_contact()` API unchanged.
