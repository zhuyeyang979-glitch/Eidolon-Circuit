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
- No large language model controls puppets, opponents, Source Code behavior, or formal battle decisions; those paths stay local and authored-rule driven.

The current prototype opens to a main menu:

- Team Edit
- Training
- PVP / Local Versus
- Computer Battle
- Settings

The UI direction is closer to modern fighting-game front ends: big mode entries, a strong title block, an information panel, and a separate team edit lab with component art and stat readouts.

## Current Implementation Status

Implemented in the current prototype:

- Momentum damage formula, strict `damage > break_value` gate, and knock on blocked contacts.
- Slash, stab, and blunt adjustments with compatibility aliases for old damage keys.
- Fixed momentum `1` for electric/laser and chemical projectile families.
- Player-facing Core, Connector, Function Module, Hybrid, and Thruster terminology in the editor path.
- Attack diagnostics for raw momentum, capped momentum, coefficients, break gate, final damage, and knock momentum.
- A data-only Source Code priority service with deterministic ordering and saved puppet-group round trips.

Designed but not yet connected to battle/editor runtime:

- Per-hardware `normal -> faulted -> destroyed` state and core-driven construct-body destruction.
- Exact socket-size, single-manufacturer-per-construct-body, and role-identity legality gates.
- Source Code priority controls and body-to-code runtime assignment.
- Full PVE story and PVE roguelike progression.

See [unit editor legality](docs/plans/2026-06-24-unit-editor-legality-roadmap.md), [hardware fault runtime](docs/plans/2026-06-24-hardware-fault-runtime.md), [Source Code priority](docs/plans/2026-06-24-source-code-priority-ui.md), and [balance examples](docs/reports/2026-06-24-star-soul-loop-balance-examples.md).

## Gameplay Baseline

The design baseline is now 星魂回环: a unit-construction battle game split into three large play families:

- PVP
- PVE story
- PVE roguelike

Before entering combat, players either edit their own units or choose prebuilt units supplied by the game. Each side can prepare heroes, puppets, and barriers from the same shared part library.

Combat resolution is momentum-first:

- Damage settlement: `damage = momentum * damage_coefficient * adjustment_coefficient`.
- Damage only enters HP settlement when the computed damage is greater than the target break value.
- Knockback or pull: `knock = momentum * adjustment_coefficient`.
- Knockback or pull still happens even when damage is blocked by the break value.
- Melee momentum is the attack-direction velocity times total unit mass. That velocity combines the unit's body movement and the local movement of the attacking part.
- Projectile momentum is the momentum value supplied by the gun that fired the projectile.

## Unit Editing

Players edit units on the unit editor canvas. Units are split into three roles:

- Hero: directly controlled by the player, must contain Soul software, and usually consists of one construct body.
- Puppet: automatically controlled, must contain Source Code software, and may consist of one or more construct bodies.
- Barrier: automatically controlled, must contain Ether software, usually consists of multiple non-moving construct bodies, and preserves its edited spatial layout when deployed.

A construct body is a single connected body made from hardware. Each construct body can only use hardware from one manufacturer. A unit must contain at least one hardware part.

Parts connect through three slot families:

- Hardware slots connect hardware to hardware.
- Software slots install software into hardware.
- Hybrid slots install hybrid hardware/software into hardware.

Every slot accepts one matching part at most, and the part size must be less than or equal to the slot size. Parts and slots use five size classes: `XS`, `S`, `M`, `L`, and `XL`. Every part has a price.

## Part System

Hardware parts have volume and are the physical effectors of movement and combat. All hardware exposes HP, damage coefficient, break value, mass, and momentum capacity.

Hardware HP is aggregated into the construct body's total HP. Hardware damage coefficient and break value are also resolved at construct-body level unless a part has an extra adjustment, such as a melee weapon. Hardware mass is normally aggregated into the construct body's total mass. The target fault rule is: if a hardware part receives momentum above its momentum capacity during one combat settlement, that settlement uses the capacity as the momentum cap and the hardware enters fault. A faulted hardware part cannot execute related action modules; if it faults again, it is destroyed. Destroyed hardware disappears. If the destroyed part is a core, the whole construct body is destroyed and disappears. This fault state machine is currently a reviewed design, not active battle behavior.

Hardware categories:

- Core: the former torso category. Cores have at least one hardware slot. Neural cores are smaller, have lower damage and break coefficients, have fewer hardware slots, have software slots, and do not have hybrid slots. Motion cores are larger, have more hardware slots, have hybrid slots, and do not have software slots. Hybrid cores may combine both traits.
- Connector: the former limb category. Connectors have at least two hardware slots and connect hardware together.
- Weapon: usually has one hardware slot. Weapons are melee or ranged.
- Function module: large and heavy special hardware for barriers and support structures, such as arsenals, ammo bays, cooling platforms, coin platforms, buff/debuff platforms, traps, heavy cannon towers, missile towers, puppet hatcheries, hacker signal towers, one-way shields, and repair stations.

Melee weapons usually apply `2x` damage and break-value coefficients. Sharp weapons and blunt weapons create different melee outcomes through action-module binding:

- Sharp + slash module creates slash, which gains `1.5x` damage adjustment.
- Sharp + thrust module creates stab, which applies `0.5x` target break-value adjustment.
- Blunt creates blunt regardless of module and gains `2x` knock distance adjustment.

Ranged weapons are described by two parallel classifications:

- Ammo type: metal bullet, electric, or chemical.
- Gun design: rifle, sniper rifle, machine gun, cannon, shotgun, grenade launcher, or missile.

Metal bullet guns have high projectile momentum. Electric guns have fixed projectile momentum `1` and high damage adjustment. Chemical guns have fixed projectile momentum `1` and apply DoT after hit.

Gun-design behavior:

- Rifle: fires toward the aim direction with medium projectile speed and normal travel distance.
- Sniper rifle: scans toward the aim direction, locks a valid target, displays a lock marker, then fires an extremely fast shot after a delay. Its projectile momentum receives design-specific bonus.
- Machine gun: fires continuously while the player adjusts direction.
- Cannon: consumes much ammo, creates heat and recoil, fires a fast projectile, and has high damage coefficient.
- Shotgun: fires into a cone, consumes more ammo, has shorter travel distance, and has high damage coefficient.
- Grenade launcher: fires an explosive that detonates on obstacle contact and deals circular area damage.
- Missile: automatically locks the highest-priority target, displays a lock marker, tracks the target, and explodes when it hits or is intercepted.

Software parts have no volume and define movement or construction logic:

- Action Module: binds one or more hardware parts and determines their movement pattern.
- Soul: grants direct player control to a construct body and provides special build rules. One hero can have one Soul.
- Source Code: controls one or more construct bodies automatically. The current runtime uses authored behavior rules; deterministic multi-code ordering now has a saved data contract, while editor controls and body-to-code runtime assignment remain planned.
- Ether: allows multiple disconnected construct bodies to form a fixed spatial barrier and provides barrier-specific rules.

Hybrid hardware/software parts have no volume but support both execution and logic:

- Thruster: controls construct-body movement, movement speed, boost speed, base heat, and boost heat.
- Engine: provides total kinetic energy. Players allocate engine output to parts or part groups in the kinetic-energy panel.
- Radiator: defines total heat capacity. Base heat must be lower than capacity. Remaining capacity becomes the heat pool; hero heat pools are shown on the battle HUD.
- Ammo Box: provides ammo for ranged weapons and can be resized to carry different ammo amounts.
- Electronic Shield: provides regenerating armor that is consumed before HP.

The project does not connect puppets or opponents to a large language model. Source Code behavior is evaluated locally from authored rules and the current battle state; it does not learn or generate decisions through an external model service.

## Compatibility Glossary

Player-facing terminology is updated first. Saved data and internal compatibility IDs remain stable until a dedicated schema migration.

| Player term | Current internal compatibility key | Migration status |
| --- | --- | --- |
| Core / 核心 | `torso`, `is_torso` | Player labels updated; key retained |
| Connector / 连接件 | `limb_muscle`, `muscle`, `joint` | Player category updated; topology keys retained |
| Function Module / 功能模块 | material-specific hardware keys, `barrier_tile` in some runtime paths | No single-key migration yet |
| Hybrid / 软硬件 | `engine`, `booster`, `cooling`, ammo/shield payload kinds | Player group updated; payload keys retained |
| Thruster / 推进器 | `booster` | Player label updated; key retained |
| Action Module / 行动模块 | `module` | Stable compatibility key |
| Soul / 英魂 | `special` payload with `kind: "soul"` | Stable compatibility shape |
| Source Code / 源代码 | `special` payload with `kind: "code"` | Priority array added; runtime selection pending |
| Ether / 以太 | `special` payload with `kind: "ether"` | Stable compatibility shape |
| Electric ammo / 电能弹药 | `laser` in projectile damage paths | Compatibility bridge documented |
| Slash / 斩击 | `tear` | Alias supported |
| Stab / 刺击 | `pierce` | Alias supported |

## Modes

The long-term mode families are PVP, PVE story, and PVE roguelike. The current prototype still exposes focused development entry points:

- Training: P1 fights a passive dummy or deterministic sparring unit to test reach, heat, overheat, and component stats.
- PVP / Local Versus: the formal battle priority for the initial playable model, using two-controller local versus.
- Computer Battle: P1 fights a deterministic authored opponent, or P3 watches a computer-versus-computer match with the spectator camera.

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

## Attack Rule Explanation

The structure authored in the unit editor is also the unit's move list. Action-module detail cards now show approximate move possibilities such as sweep control, linear thrust, heavy break, guard bash, sustained pressure, lock-on shot, or tether control. These labels describe the likely move family created by the selected structure and module; they do not promise exact damage or a fixed combo.

Live combat keeps explanation lightweight with short cause tags such as hit, low momentum, material disadvantage, occluded, reflected, empty ammo, or heat pressure. Training validation carries the detailed explanation: representative attack results record the attack group, hit part, final damage, and the main reasons that changed the result. Post-battle review keeps the latest attack explanations beside the command log. All explanation is advisory and never forces a build change.

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

Player-facing starter references for puppet groups live in `docs/plans/2026-06-22-puppet-standard-schemes.md`. These are standard schemes, not legality gates: players can modify the Source Code, bodies, weapons, modules, budget split, and saved-group membership freely.

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

Heat is the combat-tempo core / 热量是战斗节奏的核心. It is not a fixed power score or a legality gate: a player-designed unit may pursue sustained pressure, short burst strings, deliberate redline play, or active-cooling traps. The editor, live HUD, and training report use a shared rhythm language so new players can connect design choices to battle decisions.

This makes combat emphasize burst windows rather than infinite continuous attacks / 爆发窗口，而不是无限连续攻击. The heat system should expose hooks for different player-authored styles: low-heat endurance heroes, short-burst rotations, pressure loops that skim the buffer, and redline overlimit builds that intentionally touch danger before retreating or venting.

The live heat rhythm moves through `STABLE`, `PRESSURE`, `DECIDE`, `VENT`, and `OVERHEAT`. As heat rises, the player chooses whether to continue attacking, disengage, stop acting for natural cooling, or commit to active cooling. These are suggestions and tactical information, not forced corrections to the player's build.

Design profiles use these extension keys for future rules and content: `low_heat_endurance`, `short_burst_rotation`, `pressure_loop`, `redline_overlimit`, `cooling_window`, and `future_heat_traits`.

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
- During battle, corner labels show `P1 VP` and `P2 VP`; the central scoreboard shows both sides' score, target score, tied/lead state, and match point pressure while kill messages explain why the score changed.

## Post-Battle Review Loop

Battle end does not force the player into editing. The result freezes into a post-battle review panel where the player can stay on the field, inspect the score, adjust the current sortie configuration, open Unit Edit, rematch, or return to the main menu.

This is the deck-building loop for Eidolon Circuit: design a roster, test it in training, take it into formal battle, then choose whether the current configuration needs changes. The system offers the loop, but the player decides when to revise the build.
