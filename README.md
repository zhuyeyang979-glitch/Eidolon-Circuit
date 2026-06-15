# 星魂回环 / Eidolon Circuit

Eidolon Circuit is a topology-construction fighting prototype with a local-versus-first formal battle flow.

## Current Governance Baseline

The active development source is `E:\New project`. Documents and OneDrive copies are mirrors only.

The current runtime contract is intentionally narrower than many older notes in this prototype:

- Drive logic flows through `DriveSystemService` and the normalized stats keys `drive_output_total`, `drive_demand_total`, `drive_margin`, `drive_ratio`, `move_speed`, `boost_speed`, `action_drive_scale`, and `stability_drive_scale`.
- Action modules are governed through `ActionProfileRegistry`; melee profiles must stay in contact-preview/runtime paths, while projectile profiles must pass the explicit gun activation whitelist.
- Unit legality and old-data rejection are governed through `UnitBlueprintValidator`. Old drive fields, old topology pointers, and old attack/action group pointers are rejection data, not migration data.
- Probe governance is tracked in `tools/probe_manifest.json`; current probes must not use old drive fixtures unless they are listed as legacy rejection checks.
- The baseline verification command is `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120`, followed by the governance probes listed in the manifest.

The game now opens to a main menu:

- Team Edit
- Training
- PVP / Local Versus
- Computer Battle
- Settings

The UI direction is closer to modern fighting-game front ends: big mode entries, a strong title block, an information panel, and a separate team edit lab with component art and stat readouts.

## Team Construction

Each team owns a roster of mutually exclusive unit roles:

- Hero: contains a Soul component and is the directly controlled unit.
- Puppet: contains Source Code and deploys as a group governed by deterministic conditions, target priorities, movement routines, and action sequences.
- Barrier: contains Ether and behaves as a fixed space/topology.

The project does not connect puppets or opponents to a large language model. Source Code behavior is evaluated locally from authored rules and the current battle state; it does not learn or generate decisions through an external model service.

Every role uses the same common component categories:

- Joint
- Muscle
- Booster
- Engine
- Cooling
- Action Module

The current muscle shop contains the first concrete sci-fi material set:

- Guns: chemical sprayer, bullet gun, laser emitter. These have one joint-connection end and deal high damage through projectiles; if the gun body itself touches an enemy, it is treated like a weak wood/stake contact.
- Shield-strike melee weapons: boxing glove, gravity hammer, hydraulic jack.
- Piercing melee weapons: spike lance, needle pike, cactus spine cluster.
- Tearing melee weapons: scythe blade, heavy machete, mono katana.
- These weapon muscles have one joint-connection end, with the opposite end acting as the damaging glove face, hammer head, jack plate, blade face, or spike tip.
- Decorative bridge muscles: broad-bend stake, shallow-bend stake, straight stake. These can connect joints at both ends and deal only tiny contact damage.
- Torso muscle: the crab torso chassis. It is expensive and large, and defines joint ports, weapon bays, and engine/booster/cooling/action-module capacity.

The roster must stay within:

- `1000` construction resource
- each unit length `<= 4.5`
- at most `1` unit longer than `3.5`
- at most `2` units longer than `2.5`
- at most `3` units longer than `2.0`
- any number of units at length `<= 2.0`

Each role can contain multiple owned units. Before battle, the player chooses the active roster entry per role and which one role appears first. During battle, a player can have at most one hero, one puppet group, and one barrier in play at the same time.

Action Modules replace calculators. A hero design can eventually carry up to seven action modules mapped to seven buttons and seven component groups; the current prototype exposes one selected action-module slot and uses the same catalog for heroes, puppets, and barriers. Example modules include chain swing, rod swing, swing assault, direct assault, manual aim, swing aim, auto aim, chain clamp, rod clamp, chain deflect, and rod deflect.

Damage is split into six named effects:

- Projectile: bullet, chemical corrosion, laser
- Melee: blunt, pierce, tear

Projectile types are no longer resisted by a simple resistance stat. They stay distinct through ammo economy, range, projectile path, recoil, heat, hit timing, reflection rules, and visual/audio feedback.

Joint and muscle components keep melee resistance profiles for blunt, pierce, and tear. High resistance means reduced incoming melee damage, low resistance means increased incoming melee damage, creating price and matchup gradients.

Materials now also expose small/medium/large melee counter tiers. A tier reduces incoming matching melee damage by `20%`, then another `20%`, then another `20%` for large counters. Wood/stake attacks cannot damage a material that counters that melee type at any tier.

Materials keep melee resistance and small/medium/large counter tiers. Counter readability has moved to hit effects:

- Hit sparks display NONE, SMALL, MEDIUM, LARGE, or NULL when a strike connects.
- Small/medium/large counter tiers still reduce incoming matching melee damage by repeated `20%` steps.
- Wood/stake attacks still cannot damage a material that counters that melee type at any tier.
- Blunt resistance adds reflective gloss; higher resistance means stronger shine.
- Pierce resistance adds wavy side edges; higher resistance means larger wave amplitude.
- Tear resistance adds honeycomb cutouts; low/medium/high resistance shifts the holes from square-like to hex-like to octagonal.
- Before battle, the player chooses a unified team color; that color drives unit body art instead of projectile-resistance RGB mixing.

Team Edit controls:

- Mouse: click role tabs, owned-unit actions, build slots, body sockets, and catalog parts.
- Catalog click behavior: for hero joints/muscles/modules, the selected catalog part magnet-locks onto the selected body socket. For other slots and roles, it installs into the selected unit slot.
- The assembly board gives a visual snap pulse when a part is installed.
- Select slot: `W` / `S`
- Change component: `A` / `D`
- Change role: `Q`
- Change owned unit in current role: `E`
- Duplicate current unit: `N`
- Remove current unit: `Delete`
- Set current role as initial deployment: `L`
- Copy P1 team to P2/computer: `C`
- Return to menu: `Enter` or `Esc`

## Modes

Training:
- P1 fights a passive dummy.
- Good for testing reach, heat, overheat, and component stats.
- The dummy can be replaced by a deterministic computer sparring unit for movement, aiming, defense, and pressure testing. It uses local authored combat rules, not a large language model.

PVP / Local Versus:
- This is the formal battle priority for the initial playable model.
- Two-controller local versus.
- P1 uses controller 1.
- P2 uses controller 2.
- Keyboard remains a P1 fallback only.

Computer Battle:
- P1 fights a deterministic computer-controlled opponent.
- The opponent follows authored rules to buy and deploy its hero, puppet group, and barrier.
- P3 can watch a computer-versus-computer match with the spectator camera.
- No large language model or external model service is involved.

## Battle Space Visuals

The battle arena still uses a top-down horizontal field with left and right wrapping. The codebase has Mobius projection and surface-rendering infrastructure, but the current battle view deliberately keeps combat projection locally rectangular so attacks, hitboxes, and map references remain readable.

Because a Mobius space has little design value if players cannot see or feel it, the current runtime presents a temporary linear elevation cue instead of a full twist: the world-grid surface gains subtle low-to-high lane bands and dashed height contours. This is visual-only. It does not change collision, projectile paths, target queries, or the local battle coordinate contract.

This leaves a clear extension point for a later full Mobius treatment: visual twist, authored terrain height, barrier/terrain interaction, and topology-aware local battle events can be added without mixing those ideas into today's combat geometry.

## Battle Controls

P1 keyboard:

- Move hero: `W` / `A` / `S` / `D`
- Boost: double-tap a direction
- Six attack groups: `U` / `I` / `O` / `J` / `K` / `L`
- Manual cooling: hold `G`
- Command module: directional command plus an attack button
- Melee command attack: `236+attack` becomes armor-state, `214+attack` becomes active-state
- Summon portal: tap `Tab` to cycle; hold a direction and tap `Tab` to direct-select that entrance
- Pair-summon sortie slot: press the slot's assigned two attack buttons together to deploy through the selected portal

Controller:

- Move: D-pad or left stick
- Boost: double-tap a direction
- Six attack groups: face buttons plus left/right shoulder
- Manual cooling: guide button
- Summon portal: tap back to cycle; hold a direction and tap back to direct-select that entrance
- Pair-summon sortie slot: press the slot's assigned two attack buttons together to deploy through the selected portal

Normal attacks are always normal state. Armor and active states only appear through action modules or source-code puppet sequences. Gun-like muscle components can fire bullet, chemical, or laser projectiles and add a sharp heat spike when used.

The command notation is fighting-game numpad notation, not number keys. In this prototype `236` is recognized as down then forward, and `214` as down then back, relative to the hero's facing direction. Any melee attack button can be combined with these: `236+attack` is armor-state, `214+attack` is active-state.

## Tactical Input Model

High-frequency hero control is the part that feels closest to a fighting game: movement, facing, Boost, attack buttons, aiming holds, command inputs, and manual cooling all stay on the hero and are expected to be used moment to moment.

Low-frequency tactical commands are intentionally smaller. The player chooses a summon portal first, either by cycling or by direct-selecting with direction plus portal input, then deploys a prepared sortie slot by pressing its paired attack buttons together. The deployed slot may be a hero, puppet group, or barrier depending on the team setup and current resource gate.

Pair-summon deployment no longer steals the live movement direction as an implicit portal choice. The selected portal is the commitment; the pair chord only confirms the prepared unit and spends the resource. Portal feedback shows the first sortie bindings and current live deploy costs so the player can decide before committing.

Puppet and barrier control is not direct micromanagement during battle. Puppet Source Code and barrier Ether logic are authored before battle, then evaluated locally from the current battle state. Runtime input chooses when and where to commit those prepared tools; it does not add separate puppet-move, puppet-attack, barrier-move, or barrier-attack controls.

## Attack Group Feedback

The six attack groups have a dedicated battle HUD strip so the player can tell whether an input was accepted, prepared, executed, or blocked without reading a long debug panel.

- Each slot shows the input key, attack group number, bound module or limb label, and a compact state: READY, AIM, LOCK, FIRE, CMD, COOL, HEAT, BLOCK, EMPTY, or SEVER.
- A short flash is recorded whenever the player presses an attack group, enters an aim or command window, fires, runs out of ammo, hits a module gate, or presses an unbound group.
- The controlled unit highlights the corresponding runtime segment for the same flash window. Successful fire is warm, aim and lock are cool or gold, and blocked or empty inputs are red.
- The small bars under each slot link to recovery, heat, and ammo where available. They are advisory feedback only; they do not force the player to change a build or prescribe a single "correct" combo.

## Command Review Log

Directional command cache messages such as armor command cached or active command cached are not shown as live HUD text. They are recorded silently for post-battle review so combat stays focused on hero movement and attack feedback.

- The log records command cache, consume, and special-module match events with player, timestamp, command text, state, and source.
- The post-battle review panel shows the latest entries for players and developers to inspect input timing, command consumption, and build execution after the round.
- This log is diagnostic and advisory. It helps explain why a build did or did not execute a planned command, but it does not interrupt battle or force a player to change the current configuration.

## Cognitive Load Guardrails

The battle input model treats the hero as the only high-frequency direct-control focus. Aiming can temporarily reserve the turn keys, but it must not create a second real-time control layer for puppets or barriers.

Puppets and barriers are tactical commitments, not extra hands. New features for those roles should prefer build-time authoring, source-code routines, ether logic, deployment timing, placement choice, buffered confirmation, or delayed execution. They should not add continuous puppet movement axes, puppet attack buttons, barrier movement axes, barrier attack buttons, or separate role-camera micromanagement.

If a new mechanic asks the player to aim, move, attack, and maintain a support unit at the same time, it should be redesigned into a hero action, a preauthored puppet/barrier rule, or a low-frequency deployment decision. The goal is to keep difficulty in construction, timing, matchup reading, and commitment, not in overloading the player's attention.

The default hero is now a crab-style mech built around a torso chassis. Each claw is not a single pincer part: it is represented as two opposing scythe blades connected by a joint and driven by a rod-clamp module. The front two legs mount bullet guns with swing-aim modules, and the rear two legs mount scythes with chain-swing modules.

Team Edit includes a first-pass assembly board. Select a crab body part, then use the shop buttons to install a joint, muscle, or action module for that part. Action modules are software and add no body volume. If multiple body parts use the same action module, those parts must also use identical joint and muscle materials; otherwise the board marks the parts with `!` and the roster becomes invalid.

The editor now uses self-drawn component art for each part class rather than plain text-only previews. Guns, scythes, spikes, gloves, wood stakes, joints, boosters, engines, cooling units, modules, and torso chassis all have separate silhouettes and color language.

Puppet Source Code defines deterministic behavior routines:

- `CODE: GUARD ORBIT` circles the friendly hero and intercepts close approaches.
- `CODE: PINCER` splits a puppet pair high/low and collapses from both lanes.
- `CODE: SCREEN WALL` forms a moving line between the enemy hero and your hero.
- `CODE: MINE DANCE` orbits the target and periodically creates wider strike pockets.

Barrier ether now supports space-control logic:

- `ETHER: HEAT WELL` adds heat to enemies inside its area.
- `ETHER: COOLANT VEIL` cools allied units inside its area.
- `ETHER: DRAG NET` damps enemy velocity inside its area.
- `ETHER: RIPOSTE MIRROR` pulses only when enemies enter its area.

Barrier tiles currently act as player-deployed terrain-like objects: they can provide collision, projectile occlusion, walls, lanes, triggers, and local fields. The arena does not yet expose an independent authored-terrain layer, so barriers cannot currently attach to, read, transform, or inherit properties from native map terrain. This is a planned high-priority extension tracked in `docs/TODO.md`.

The arena is now treated as a horizontal bullet-hell top-down strip: left and right wrap, top and bottom are the paper strip's width, and the camera eases around the ring while keeping both heroes readable.

Summoned units take `4` seconds to enter after purchase. The initial pre-battle deployment appears immediately.

Aim behavior is action-module driven:

- Fixed aim attacks fire in the current held or facing direction.
- Manual aim attacks hold the attack button, steer an aim line with direction input, and release to strike.
- Auto aim attacks sweep the aim line automatically; release fires at the current angle.

## Heat Rules

The battle HUD places all three role resources in the corners: P1 health bars live in the upper-left and P1 heat bars in the lower-left; P2 health bars live in the upper-right and P2 heat bars in the lower-right. Each side has separate bars for hero, puppet group, and barrier.

- Skills add a large amount of heat.
- Normal attacks add moderate heat.
- If cooling is weak, ordinary movement also accumulates heat.
- Stopping and not acting lowers heat faster.
- Holding manual cooling locks the hero in place for at least `0.4` seconds and vents smoke while rapidly lowering heat.
- Manual cooling and active cooling modules now create a readable active cooling window / 散热窗口: the unit vents a visible cyan heat cloud, its heat bar shifts color, and movement is locked while the commitment is live.
- Active cooling modules trade a larger heat dump for a larger punish window. Hits during the cooling exposure window deal a small extra damage bonus, so opponents can chase, pre-aim, or force unsafe vent timing instead of treating cooling as a free reset.
- Active cooling module use is also written to the post-battle review log so players and developers can inspect when a build chose to stop, vent, and re-enter pressure.
- Boosting adds a large heat spike.
- At full heat, a hero enters Overheat.
- While overheated, skills are locked, hero actions slow down, and incoming damage is increased by `15%`.
- Overheat ends after heat falls below the recovery threshold.

## Win Condition

- Killing the enemy hero gives `1` victory point.
- The defeated hero's owner gains `100` resource.
- If the opponent has no hero in play, destroying their puppet group or barrier gives `1` victory point.
- If the opponent has no units in play, the battle ends immediately.
- First to `7` victory points wins.
- Matches target roughly `10` minutes; timeout resolves by victory points, then remaining health.

## Post-Battle Review Loop

Battle end does not force the player into editing. The result freezes into a post-battle review panel where the player can stay on the field, inspect the score, adjust the current sortie configuration, open Unit Edit, rematch, or return to the main menu.

This is the deck-building loop for Eidolon Circuit: design a roster, test it in training, take it into formal battle, then choose whether the current configuration needs changes. The system offers the loop, but the player decides when to revise the build.
