# Contextual Battle Effects Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Continue EC-SLIM-002 by moving the remaining contextual battle effect inline classes out of `scripts/main.gd` without changing runtime behavior.

**Architecture:** Extract each VFX class into a dedicated `scripts/effects/*.gd` file with the same `class_name` and public methods. Keep `scripts/main.gd` as the runtime owner that instantiates, positions, stores, and frees these effects; only the drawing/lifetime class bodies move. Extend the existing effect extraction probes and inline-class guard so future regressions are caught by source and instantiation checks.

**Tech Stack:** Godot 4.6.2 GDScript, `Node2D` effect scripts, existing headless probes under `tools/`, and EC-SLIM architecture guardrails.

---

## File Structure

- Create `scripts/effects/salvo_landing_preview_effect.gd`
  - Publishes `class_name SalvoLandingPreviewEffect`.
  - Owns arc/landing reticle drawing and short lifetime.

- Create `scripts/effects/laser_aim_telegraph_effect.gd`
  - Publishes `class_name LaserAimTelegraphEffect`.
  - Owns beam charge line drawing and `set_line()` refresh behavior.

- Create `scripts/effects/true_bullet_target_lock_effect.gd`
  - Publishes `class_name TrueBulletTargetLockEffect`.
  - Owns target lock ring charge drawing.

- Create `scripts/effects/blind_zone_effect.gd`
  - Publishes `class_name BlindZoneEffect`.
  - Owns blind-zone visibility, ticking, and owner-visible drawing.

- Create `scripts/effects/field_aura_effect.gd`
  - Publishes `class_name FieldAuraEffect`.
  - Owns field aura screen updates and all field-kind motifs.

- Create `scripts/effects/coin_pickup_effect.gd`
  - Publishes `class_name CoinPickupEffect`.
  - Owns coin pickup TTL, collect/expire behavior, and coin drawing.

- Create `scripts/effects/identity_transfer_effect.gd`
  - Publishes `class_name IdentityTransferEffect`.
  - Owns transfer animation progress, callback execution, and payload drawing.

- Modify `scripts/main.gd`
  - Add preloads for the seven extracted effect scripts.
  - Remove the seven inline class bodies.
  - Preserve all existing creation and runtime ownership call sites.

- Modify `tools/effect_extraction_contract_probe.gd`
  - Require all seven new effect files, `class_name`s, key behavior tokens, and `main.gd` preloads.
  - Instantiate representative effects and check public state after setup/update calls.

- Modify `tools/main_inline_class_guard_probe.gd`
  - Remove the seven contextual effect names from `ALLOWED_INLINE_CLASSES`.
  - Add them to `EXTRACTED_INLINE_CLASSES`.

---

### Task 1: Add RED Contract Coverage

**Files:**
- Modify: `tools/effect_extraction_contract_probe.gd`
- Modify: `tools/main_inline_class_guard_probe.gd`

- [ ] **Step 1: Extend effect extraction probe**

Add constants and preloads near the existing extracted effect constants:

```gdscript
const SALVO_LANDING_PREVIEW_EFFECT_PATH := "res://scripts/effects/salvo_landing_preview_effect.gd"
const LASER_AIM_TELEGRAPH_EFFECT_PATH := "res://scripts/effects/laser_aim_telegraph_effect.gd"
const TRUE_BULLET_TARGET_LOCK_EFFECT_PATH := "res://scripts/effects/true_bullet_target_lock_effect.gd"
const BLIND_ZONE_EFFECT_PATH := "res://scripts/effects/blind_zone_effect.gd"
const FIELD_AURA_EFFECT_PATH := "res://scripts/effects/field_aura_effect.gd"
const COIN_PICKUP_EFFECT_PATH := "res://scripts/effects/coin_pickup_effect.gd"
const IDENTITY_TRANSFER_EFFECT_PATH := "res://scripts/effects/identity_transfer_effect.gd"
const SalvoLandingPreviewEffectScript := preload("res://scripts/effects/salvo_landing_preview_effect.gd")
const LaserAimTelegraphEffectScript := preload("res://scripts/effects/laser_aim_telegraph_effect.gd")
const TrueBulletTargetLockEffectScript := preload("res://scripts/effects/true_bullet_target_lock_effect.gd")
const BlindZoneEffectScript := preload("res://scripts/effects/blind_zone_effect.gd")
const FieldAuraEffectScript := preload("res://scripts/effects/field_aura_effect.gd")
const CoinPickupEffectScript := preload("res://scripts/effects/coin_pickup_effect.gd")
const IdentityTransferEffectScript := preload("res://scripts/effects/identity_transfer_effect.gd")
```

Add `_require_source()` checks inside `_init()`:

```gdscript
_require_source(SALVO_LANDING_PREVIEW_EFFECT_PATH, "SalvoLandingPreviewEffect", ["setup", "refresh", "landing_point", "hold_ratio"])
_require_source(LASER_AIM_TELEGRAPH_EFFECT_PATH, "LaserAimTelegraphEffect", ["setup", "set_line", "beam_color", "draw_polyline"])
_require_source(TRUE_BULLET_TARGET_LOCK_EFFECT_PATH, "TrueBulletTargetLockEffect", ["setup", "lock_color", "draw_arc", "draw_line"])
_require_source(BLIND_ZONE_EFFECT_PATH, "BlindZoneEffect", ["setup", "tick_zone", "is_alive", "OWNER VISIBLE"])
_require_source(FIELD_AURA_EFFECT_PATH, "FieldAuraEffect", ["setup", "update_screen", "_field_color", "_gravity_visual_direction"])
_require_source(COIN_PICKUP_EFFECT_PATH, "CoinPickupEffect", ["setup", "collect", "expired", "ttl"])
_require_source(IDENTITY_TRANSFER_EFFECT_PATH, "IdentityTransferEffect", ["setup", "_payload_color", "_draw_payload", "callback.call"])
```

Extend preload and inline-class loops to include all seven new effect paths and class names.

- [ ] **Step 2: Add runtime setup checks**

Add instantiation checks after the existing `ProjectileTraceEffect` checks:

```gdscript
var salvo = SalvoLandingPreviewEffectScript.new()
salvo.setup(Vector2.ZERO, Vector2(24.0, 18.0), 0.8)
if salvo.landing_point != Vector2(24.0, 18.0) or absf(salvo.hold_ratio - 0.8) > 0.001:
	_fail("SalvoLandingPreviewEffect.setup should preserve landing state.")
salvo.refresh(Vector2.ONE, Vector2(30.0, 4.0), 2.0)
if salvo.hold_ratio != 1.0:
	_fail("SalvoLandingPreviewEffect.refresh should clamp hold ratio.")
salvo.free()

var laser = LaserAimTelegraphEffectScript.new()
laser.setup(Vector2.ZERO, Vector2(80.0, 0.0), 0.4, Color.RED)
laser.set_line(Vector2(2.0, 3.0), Vector2(7.0, 11.0))
if laser.start_point != Vector2(2.0, 3.0) or laser.end_point != Vector2(7.0, 11.0) or laser.beam_color != Color.RED:
	_fail("LaserAimTelegraphEffect should preserve setup and set_line state.")
laser.free()

var lock = TrueBulletTargetLockEffectScript.new()
lock.setup(0.9, Color.YELLOW)
if lock.max_lifetime < 0.89 or lock.lock_color != Color.YELLOW:
	_fail("TrueBulletTargetLockEffect.setup should preserve lock state.")
lock.free()

var blind = BlindZoneEffectScript.new()
blind.setup(2, 0.2, -0.3, 0.7, 2.0, 0.6)
blind.tick_zone(0.25, Vector2(4.0, 9.0), true)
if not blind.is_alive() or blind.position != Vector2(4.0, 9.0) or not blind.visible:
	_fail("BlindZoneEffect.tick_zone should update screen visibility while alive.")
blind.free()

var aura = FieldAuraEffectScript.new()
aura.setup(1, "gravity_up_right", 0.8, 2.0)
aura.update_screen(Vector2(6.0, 7.0), true, 0.2)
if aura.position != Vector2(6.0, 7.0) or not aura.visible or aura.field_kind != "gravity_up_right":
	_fail("FieldAuraEffect should preserve field screen state.")
aura.free()

var coin = CoinPickupEffectScript.new()
coin.setup(1, 150, 2.5)
coin.update_screen(Vector2(12.0, 5.0), true, 0.1)
if coin.value != 150 or coin.position != Vector2(12.0, 5.0) or coin.expired():
	_fail("CoinPickupEffect should preserve coin state before collection.")
coin.collect()
if not coin.expired():
	_fail("CoinPickupEffect.collect should mark the effect expired.")

var source := Node2D.new()
var target := Node2D.new()
root.add_child(source)
root.add_child(target)
source.global_position = Vector2.ZERO
target.global_position = Vector2(40.0, 20.0)
var transfer = IdentityTransferEffectScript.new()
root.add_child(transfer)
var callback_called := false
transfer.setup(source, target, ["soul", "code", "ether"], func(): callback_called = true)
if transfer.payloads.size() != 3 or transfer.progress != 0.0:
	_fail("IdentityTransferEffect.setup should preserve payload state.")
transfer._process(1.0)
if not callback_called:
	_fail("IdentityTransferEffect should call the finish callback when complete.")
source.queue_free()
target.queue_free()
```

- [ ] **Step 3: Update inline-class guard**

Move these class names from `ALLOWED_INLINE_CLASSES` to `EXTRACTED_INLINE_CLASSES`:

```gdscript
"SalvoLandingPreviewEffect",
"LaserAimTelegraphEffect",
"TrueBulletTargetLockEffect",
"BlindZoneEffect",
"FieldAuraEffect",
"CoinPickupEffect",
"IdentityTransferEffect",
```

- [ ] **Step 4: Verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/effect_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: both fail. The effect probe should report missing extracted effect scripts. The inline-class guard should report that extracted classes are still inline in `main.gd`.

---

### Task 2: Extract Small Telegraph and Lock Effects

**Files:**
- Create: `scripts/effects/salvo_landing_preview_effect.gd`
- Create: `scripts/effects/laser_aim_telegraph_effect.gd`
- Create: `scripts/effects/true_bullet_target_lock_effect.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Create the three effect scripts**

Move the complete current class bodies for `SalvoLandingPreviewEffect`, `LaserAimTelegraphEffect`, and `TrueBulletTargetLockEffect` from `scripts/main.gd` into dedicated files. Add `class_name` at the top of each file and preserve `extends Node2D`.

- [ ] **Step 2: Add main preloads**

Add these near existing effect preloads in `scripts/main.gd`:

```gdscript
const SalvoLandingPreviewEffect = preload("res://scripts/effects/salvo_landing_preview_effect.gd")
const LaserAimTelegraphEffect = preload("res://scripts/effects/laser_aim_telegraph_effect.gd")
const TrueBulletTargetLockEffect = preload("res://scripts/effects/true_bullet_target_lock_effect.gd")
```

- [ ] **Step 3: Remove inline class bodies**

Delete the three inline class blocks from `scripts/main.gd`. Keep all existing creation sites unchanged.

- [ ] **Step 4: Verify partial extraction**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/effect_extraction_contract_probe.gd
```

Expected: still fails because the remaining four effect scripts are not extracted yet, but no longer complains about the three files created in this task.

---

### Task 3: Extract Zone, Aura, Coin, and Identity Effects

**Files:**
- Create: `scripts/effects/blind_zone_effect.gd`
- Create: `scripts/effects/field_aura_effect.gd`
- Create: `scripts/effects/coin_pickup_effect.gd`
- Create: `scripts/effects/identity_transfer_effect.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Create the four effect scripts**

Move the complete current class bodies for `BlindZoneEffect`, `FieldAuraEffect`, `CoinPickupEffect`, and `IdentityTransferEffect` from `scripts/main.gd` into dedicated files. Add `class_name` at the top of each file and preserve `extends Node2D`.

- [ ] **Step 2: Add main preloads**

Add these near existing effect preloads in `scripts/main.gd`:

```gdscript
const BlindZoneEffect = preload("res://scripts/effects/blind_zone_effect.gd")
const FieldAuraEffect = preload("res://scripts/effects/field_aura_effect.gd")
const CoinPickupEffect = preload("res://scripts/effects/coin_pickup_effect.gd")
const IdentityTransferEffect = preload("res://scripts/effects/identity_transfer_effect.gd")
```

- [ ] **Step 3: Remove inline class bodies**

Delete the four inline class blocks from `scripts/main.gd`. Keep all existing creation and update call sites unchanged.

- [ ] **Step 4: Verify all extracted effect contracts**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/effect_extraction_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/main_inline_class_guard_probe.gd
```

Expected: both exit `0`. `effect_extraction_contract_probe` should report the updated effect count, and `main_inline_class_guard_probe` should no longer list the seven contextual effects as allowed inline classes.

---

### Task 4: Run Focused Battle VFX Regression

**Files:**
- No planned source edits unless a regression is found.

- [ ] **Step 1: Run VFX and runtime probes**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_vfx_budget_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_runtime_frame_budget_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/combat_probe.gd
```

Expected: all exit `0`. Frame budget may vary, but should remain within the probe's own threshold.

- [ ] **Step 2: Run broad sanity gates**

Run:

```bash
git diff --check
jq empty tools/probe_manifest.json
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

Expected: all exit `0`; the known ObjectDB warning may still appear on Godot exit.

---

## Self-Review

- Spec coverage: Covers the selected EC-SLIM-002 continuation: seven contextual battle effect inline classes currently allowed by `main_inline_class_guard_probe`.
- Placeholder scan: No `TBD`, vague TODOs, or missing verification commands remain.
- Type consistency: Class names, file paths, and public methods match the current `scripts/main.gd` implementation and existing effect extraction pattern.
