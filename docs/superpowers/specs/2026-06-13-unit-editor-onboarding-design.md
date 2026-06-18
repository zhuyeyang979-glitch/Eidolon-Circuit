# Unit Editor Onboarding Design

Date: 2026-06-13
Status: design ready for review
Scope: Unit Edit first-time guidance only

## Goal

Add an optional first-time onboarding flow for Unit Edit that teaches a new player how to assemble and save a minimal legal hero unit.

The flow should help a first-time player understand the real editor loop:

1. place a torso on the blank canvas
2. attach a basic weapon limb
3. open torso detail
4. install minimum required internal payloads
5. install and bind one action module
6. try the bound action on the board
7. save the unit

The onboarding ends inside Unit Edit after the unit is saved. Training entry remains a separate future onboarding pass.

## Current State

The current Unit Edit screen already has many contextual hints:

- blank-canvas hints such as dragging parts into the free canvas
- layout and pose-mode rejection feedback
- connected-part and unconnected-part guidance
- torso-detail hints
- action-module binding feedback
- save-blocking feedback
- `Options -> Help` text for Unit Edit

What is missing is a guided first-run path:

- no first-time Unit Edit onboarding state
- no automatic "start or skip" prompt
- no persistent skip/completed flag
- no replay entry
- no task sequence that carries a new player from blank canvas to saved legal unit

## Non-Goals

This design must not change the game's core rules or editing philosophy.

- Do not change topology legality, unit legality, save schema, battle rules, damage rules, or balance numbers.
- Do not auto-create, auto-place, auto-bind, or auto-save parts for the player.
- Do not force the player to choose only recommended parts.
- Do not combine this with Training, Computer Battle, or PVP tutorials.
- Do not add a separate simplified editor mode with different rules.
- Do not bypass existing validation or save-blocking messages.

## Recommended Approach

Use a hybrid "spotlight plus checklist" onboarding layer.

The spotlight explains the current step and visually highlights the relevant editor target. The checklist remains visible on the side and shows the whole progress toward "saved minimal legal hero."

This combines the strengths of two patterns:

- Spotlight cards are precise enough for a complex editor.
- A checklist prevents the player from feeling lost in a long sequence.

The alternative approaches were rejected for this pass:

- Pure spotlight cards are clear but can feel like a modal slideshow.
- Pure task checklist is low-interruption but does not answer "where do I click now?"

## Entry And Persistence

On first Unit Edit entry:

1. If no onboarding state exists, show a small prompt: `Start Tutorial` / `Skip`.
2. `Start Tutorial` activates the onboarding flow at step 1.
3. `Skip` writes a local skipped state and hides future automatic prompts.

During onboarding:

- The player can use `Skip Tutorial` at any step.
- Skipping never changes the current canvas.
- Completed steps advance only after the real editor action has happened.

After completion:

- The game writes a local completed state.
- Unit Edit no longer auto-prompts.
- `Options -> Help` exposes `Replay Unit Edit Tutorial`.

Replay behavior:

- Replay can be triggered manually from Unit Edit help/options.
- Replay should not silently clear the current canvas.
- If the current canvas is not blank, show a prompt:
  - `New Blank Canvas`
  - `Continue Current Canvas`
  - `Cancel`

## Step Sequence

### Step 0: Start Or Skip

Trigger: first Unit Edit entry with no onboarding state.

UI:

- small prompt over Unit Edit
- short purpose text: "Build and save your first legal hero."
- actions: `Start Tutorial`, `Skip`

Completion:

- `Start Tutorial` enters step 1.
- `Skip` persists skipped state and closes onboarding.

### Step 1: Place A Torso

Intent:

Teach that a hero starts from physical parts on the blank canvas.

Highlight:

- Parts catalog group that contains a recommended starter torso
- free canvas drop area

Player action:

- click or drag a torso-like recommended component into the canvas

Completion detection:

- current role is hero
- current canvas has a custom topology
- at least one torso or torso-equivalent root component exists

Notes:

- Recommended part is highlighted, but any valid torso-equivalent component passes.

### Step 2: Attach A Weapon Limb

Intent:

Teach that combat behavior comes from connected body topology.

Highlight:

- recommended weapon or muscle component
- available torso socket or board placement target

Player action:

- place a weapon limb and connect it to the torso

Completion detection:

- canvas has at least two topology nodes
- at least one edge connects a non-torso combat-volume part to the torso/root chain

Notes:

- If the player places but does not connect the part, show a corrective hint rather than advancing.

### Step 3: Open Torso Detail

Intent:

Teach that internal payloads are installed through torso detail, not loose board placement.

Highlight:

- selected torso
- `Torso Detail` button or double-click target

Player action:

- open the torso detail panel

Completion detection:

- torso detail panel is visible for a valid torso node

### Step 4: Install Minimum Internal Payloads

Intent:

Teach the minimum internal structure needed for a usable hero.

Highlight:

- recommended engine
- recommended cooling
- recommended Soul payload
- relevant torso detail slots

Player action:

- install a valid engine
- install a valid cooling unit
- install a Soul or hero identity payload

Completion detection:

- selected/current hero blueprint has valid internal payloads for movement/heat/hero identity according to existing stats and validation facts

Notes:

- If exact legality checks need multiple current services, onboarding should read existing calculated editor stats or validator summaries instead of duplicating rules.

### Step 5: Install And Bind One Action Module

Intent:

Teach that action modules define controllable attacks and must be bound to a target.

Highlight:

- recommended beginner module compatible with the weapon limb
- module/software slot in torso detail
- bindable target on the board
- attack key choices `U/I/O/J/K/L`

Player action:

- install one compatible module
- choose a valid target part
- bind it to an attack key

Completion detection:

- current blueprint has at least one valid action-module binding
- the binding target remains valid

Notes:

- The onboarding should accept non-recommended modules if the resulting binding is valid.
- Existing binding failure messages remain authoritative.

### Step 6: Try The Bound Action

Intent:

Teach that Unit Edit can preview action behavior before Training.

Highlight:

- bound action key button or board tryout control
- board feedback area

Player action:

- trigger the board tryout for the bound module

Completion detection:

- editor tryout reports a valid module execution preview

Notes:

- Tryout remains preview-only: no real damage, ammo cost, or battle state.

### Step 7: Save The Unit

Intent:

Teach that saved units are the bridge from Unit Edit to Saved Units and Training.

Highlight:

- `Save Unit` button
- save name dialog

Player action:

- open save dialog
- provide or accept a name
- complete the existing save flow

Completion detection:

- existing save flow succeeds for the current unit

Notes:

- Existing validation and save-blocking feedback must remain unchanged.
- The tutorial must not save automatically.

### Step 8: Complete

Intent:

Close the onboarding and point to the next natural options without moving the player.

UI:

- "First unit saved."
- "You can continue editing, open Saved Units, or use it for Training."

Completion:

- persist completed state
- close onboarding when the player confirms

## UI Model

The onboarding layer needs three visible pieces:

- start/skip prompt
- step card
- checklist

The step card should contain:

- step number and title
- one-sentence instruction
- current recommended target
- `Skip Tutorial`

The checklist should show:

- torso
- weapon limb
- torso detail
- engine/cooling/Soul
- module binding
- tryout
- save

Highlight targets can be expressed as stable semantic target keys first, then resolved by `main.gd` to actual controls or board regions.

Example target keys:

- `catalog.recommended_torso`
- `board.free_canvas`
- `board.torso_socket`
- `dashboard.torso_detail`
- `torso_detail.engine_slot`
- `torso_detail.cooling_slot`
- `torso_detail.identity_slot`
- `torso_detail.module_slot`
- `board.bindable_weapon`
- `module_binding.attack_keys`
- `board.tryout`
- `editor.save_unit`

## Architecture

Add a pure `UnitEditorTutorialService` or equivalent controller-style service.

The service owns:

- first-run decision
- start/skip/complete/replay intents
- step list
- step metadata
- checklist state model
- pure completion checks from supplied facts

`main.gd` owns:

- reading and writing the local onboarding state file
- showing and hiding UI nodes
- resolving highlight target keys to actual controls or board regions
- forwarding editor facts into the service
- applying existing editor actions
- save IO, SFX, and all Node side effects

This follows the current project boundary:

- services make pure decisions
- `main.gd` remains the composition root and side-effect owner for current UI/runtime work

## Persistence

Store onboarding state in a small local JSON file under `user://`.

Proposed path:

```text
user://onboarding_state.json
```

Proposed shape:

```json
{
  "unit_editor": {
    "version": 1,
    "state": "completed",
    "last_step": "save_unit"
  }
}
```

Supported states:

- `unseen`
- `active`
- `skipped`
- `completed`

Versioning keeps the option open to re-show onboarding if a future editor redesign changes the flow.

## Failure And Recovery

If the player takes a valid alternate path:

- advance if the step completion facts are satisfied
- do not require the exact recommended part

If the player creates an invalid or confusing state:

- keep the current step active
- show a short corrective hint
- offer `Skip Tutorial`

If the player switches page or leaves Unit Edit:

- keep local onboarding state as active with the last step
- on return, resume only if the canvas still satisfies the prior step facts
- if not, show the current step again with a recovery hint

If the player clears the canvas:

- keep the tutorial active
- return to the earliest unmet step

## Testing Plan

Focused probes should cover the pure service first:

- first-run prompt intent when state is missing
- skip intent persists skipped state
- completed state suppresses auto-prompt
- replay intent starts from step 1
- checklist model marks completed steps from supplied facts
- non-recommended but valid torso/weapon/module facts pass
- invalid partial states do not advance
- completion writes completed intent only after save-success fact

Integration probes should cover current editor wrappers:

- first Unit Edit entry can show start/skip prompt
- skipping does not modify the current canvas
- replay entry is reachable through Unit Edit help/options
- save legality remains controlled by existing validation
- current contextual hints still appear when onboarding is inactive
- text/layout probes pass with onboarding UI visible

Standard checks:

```bash
GODOT=/Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
git diff --check
jq empty tools/probe_manifest.json
```

## Full Player Flow

1. A new player opens Unit Edit.
2. The game asks whether to start the Unit Edit tutorial or skip it.
3. The player starts the tutorial.
4. A checklist appears and the first step highlights a recommended torso.
5. The player places the torso onto the blank canvas.
6. The tutorial advances and highlights a beginner weapon limb.
7. The player attaches the limb to the torso.
8. The tutorial highlights torso detail.
9. The player opens torso detail and installs the minimum internal payloads.
10. The tutorial highlights a compatible action module and binding target.
11. The player installs and binds the module to an attack key.
12. The tutorial asks the player to try the bound action on the board.
13. The player triggers the preview.
14. The tutorial highlights save.
15. The player saves the unit through the existing save dialog.
16. The tutorial marks itself complete and tells the player they can continue editing, open Saved Units, or later take the unit into Training.

## Open Implementation Notes

- Choose the exact recommended starter parts during implementation by inspecting current catalog compatibility.
- Prefer stable semantic target keys over direct node paths so the tutorial survives future layout changes.
- Keep onboarding copy short enough to fit the current 1280x720 editor layout.
- Add bilingual copy at implementation time using the current UI language pattern.
