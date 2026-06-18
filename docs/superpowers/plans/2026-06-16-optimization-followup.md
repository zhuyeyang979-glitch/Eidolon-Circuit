# Eidolon Circuit Optimization Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the June 16 completion audit into an ordered set of fixes that first removes known verification failures, then improves delivery hygiene, and finally resumes larger architecture optimization.

**Architecture:** Keep the first pass narrow: fix existing probes and user-facing copy before moving any gameplay ownership. Use existing Godot probe scripts as the test harness. Keep architecture work incremental and aligned with `docs/architecture_boundaries.md` and the EC-SLIM backlog.

**Tech Stack:** Godot 4.6.2 GDScript, existing `tools/*.gd` probes, `tools/probe_manifest.json`, `git diff --check`, `jq`, and project docs under `docs/`.

---

## File Structure

- Modify `scripts/main.gd`
  - Update `_battle_help_text()` so live battle help matches the tactical-input contract in README, settings copy, and `BattleInputService`.

- Modify `tools/probe_exit_status_contract_probe.gd`
  - Add `probe_manifest_no_legacy_fixture_probe.gd` to the list of probes that must aggregate failures before calling `quit(0)`.

- Modify `tools/probe_manifest_no_legacy_fixture_probe.gd`
  - Convert immediate `_fail()`/`quit(1)` behavior into explicit failure aggregation so a later success path cannot override a detected failure.

- Modify `tools/battle_attack_feedback_probe.gd`
  - Remove the legacy `body_move_speed` fixture token from the current probe.

- Modify `.gitignore`
  - Add a narrow generated-artifact policy for Godot metadata and local screenshots after checking which untracked files are generated rather than source.

- Create or update docs only when the execution order or artifact policy needs to be captured for future work.

---

### Task 1: Fix Tactical Battle Help Contract

**Files:**
- Modify: `scripts/main.gd`
- Test: `tools/tactical_input_contract_probe.gd`

- [ ] **Step 1: Verify the existing RED failure**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/tactical_input_contract_probe.gd
```

Expected: exit `1`, with missing battle-help phrases `英雄高频`, `战术低频`, `双攻击键`, `High-frequency hero`, `Low-frequency tactics`, and `paired attack buttons`.

- [ ] **Step 2: Update battle help text**

In `scripts/main.gd`, replace `_battle_help_text()` with concise localized copy containing the required phrases while preserving the existing heat, movement, attack, portal, and options controls.

- [ ] **Step 3: Verify GREEN**

Run the same `tactical_input_contract_probe.gd` command.

Expected: exit `0`, `TACTICAL_INPUT_CONTRACT_PROBE failed=false`.

- [ ] **Step 4: Run adjacent UI checks**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/ui_layout_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
```

Expected: both exit `0`, with no hard layout or text-overflow failures.

---

### Task 2: Fix Legacy Fixture Guard Reliability

**Files:**
- Modify: `tools/probe_exit_status_contract_probe.gd`
- Modify: `tools/probe_manifest_no_legacy_fixture_probe.gd`
- Modify: `tools/battle_attack_feedback_probe.gd`
- Test: `tools/probe_exit_status_contract_probe.gd`
- Test: `tools/probe_manifest_no_legacy_fixture_probe.gd`
- Test: `tools/battle_attack_feedback_probe.gd`

- [ ] **Step 1: Add a failing guard test**

Add `res://tools/probe_manifest_no_legacy_fixture_probe.gd` to `GUARDED_PROBES` in `tools/probe_exit_status_contract_probe.gd` with required tokens:

```gdscript
"var failures",
"failures.append",
"if not failures.is_empty()",
"quit(1)",
"return",
"quit(0)",
```

- [ ] **Step 2: Verify RED**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/probe_exit_status_contract_probe.gd
```

Expected: exit `1`, because `probe_manifest_no_legacy_fixture_probe.gd` does not yet preserve the failure aggregation contract.

- [ ] **Step 3: Implement failure aggregation**

In `tools/probe_manifest_no_legacy_fixture_probe.gd`, add `var failures: Array = []`, make `_fail()` append to it, replace immediate failure exits with a final `if not failures.is_empty(): quit(1); return`, and keep the existing success print followed by `quit(0)`.

- [ ] **Step 4: Remove current-probe legacy fixture token**

In `tools/battle_attack_feedback_probe.gd`, replace `body_move_speed` with canonical runtime movement stats already used by current code, such as `move_speed`.

- [ ] **Step 5: Verify GREEN**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/probe_exit_status_contract_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/probe_manifest_no_legacy_fixture_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/battle_attack_feedback_probe.gd
```

Expected: all exit `0`; manifest probe prints no legacy-token `ERROR`.

---

### Task 3: Clean Generated Artifact Noise

**Files:**
- Modify: `.gitignore`
- Inspect: `git status --short`

- [ ] **Step 1: Classify untracked files**

Run:

```bash
git status --short
git ls-files '*.uid' '*.import'
```

Expected: untracked files are separated into generated Godot metadata, generated image imports, and local visual artifacts.

- [ ] **Step 2: Add narrow ignore rules**

If the current untracked files are generated metadata rather than authored source, add rules for generated script/shader UID files and local visual output. Preserve already tracked files.

- [ ] **Step 3: Verify status noise is reduced**

Run:

```bash
git status --short
git check-ignore -v scripts/services/battle_input_service.gd.uid shaders/mobius_strip_surface.gdshader.uid artifacts/scoreboard_feedback/01_tied_start_hud.png
```

Expected: generated metadata and local artifacts are ignored while source, authored images, and tracked imports remain visible.

---

### Task 4: Re-run Core Regression Gates

**Files:**
- No source edits unless verification exposes a new failure.

- [ ] **Step 1: Run static gates**

```bash
git diff --check
jq empty tools/probe_manifest.json
```

Expected: both exit `0`.

- [ ] **Step 2: Run Godot check-only**

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
```

Expected: exit `0`. The known ObjectDB warning may still appear.

- [ ] **Step 3: Run focused probes from Tasks 1 and 2**

Run the probes named in Task 1 and Task 2.

Expected: all exit `0`.

---

### Task 5: Resume Larger Architecture Optimization

**Files:**
- Inspect: `docs/development_backlog.md`
- Inspect: `docs/architecture_boundaries.md`
- Inspect: `scripts/main.gd`

- [ ] **Step 1: Re-measure large files**

```bash
find scripts -name '*.gd' -print0 | xargs -0 wc -l | sort -nr | sed -n '1,30p'
```

Expected: `scripts/main.gd` remains the top extraction target.

- [ ] **Step 2: Pick the next safe EC-SLIM extraction**

Choose the next boundary from EC-SLIM-002 through EC-SLIM-006 where a focused contract probe can be written first and behavior can remain unchanged.

- [ ] **Step 3: Write a separate extraction plan**

Create a new plan file for that extraction instead of mixing it into this bugfix/hygiene pass.

Expected: this follow-up plan stays focused and does not bundle architecture movement with current probe repairs.

---

## Self-Review

- Spec coverage: Covers the current recommended order: tactical help failure, legacy fixture guard reliability, worktree hygiene, regression gates, then larger `main.gd`/EC-SLIM optimization.
- Placeholder scan: No `TBD`, open-ended TODOs, or unspecified test commands remain.
- Type consistency: Uses existing file names, probe names, Godot path, and project branch conventions.
