# Eidolon Circuit

Eidolon Circuit is a topology-construction fighting prototype with a single-player-first flow.

The game now opens to a main menu:

- Team Edit
- Training
- AI Battle
- PVP
- Settings

The UI direction is closer to modern fighting-game front ends: big mode entries, a strong title block, an information panel, and a separate team edit lab with component art and stat readouts.

## Team Construction

Each team owns a roster of mutually exclusive unit roles:

- Hero: contains a Soul component and is the directly controlled unit.
- Puppet: contains Source Code and deploys as a shared-code puppet group.
- Barrier: contains Ether and behaves as a fixed space/topology.

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
- Copy P1 team to P2/AI: `C`
- Return to menu: `Enter` or `Esc`

## Modes

Training:
- P1 fights a passive dummy.
- Good for testing reach, heat, overheat, and component stats.

AI Battle:
- P1 fights an automated opponent.
- AI buys and deploys hero, puppet group, and barrier from its team.

PVP:
- Two-controller local versus.
- P1 uses controller 1.
- P2 uses controller 2.
- Keyboard remains a P1 fallback only.

## Battle Controls

P1 keyboard:

- Move hero: `W` / `A` / `S` / `D`
- Boost: double-tap a direction
- Six crab attack groups: `F` left claw, `R` right claw, `T` front-left leg, `C` front-right leg, `V` rear-left leg, `B` rear-right leg
- Manual cooling: hold `G`
- Command module: direction input then `Y`
- Melee command attack: `236+F` becomes armor-state, `214+F` becomes active-state
- Cycle summon portal: `Q`
- Buy/deploy Hero: `1`
- Buy/deploy Puppet group: `2`
- Buy/deploy Barrier: `3`

Controller:

- Move: D-pad or left stick
- Boost: double-tap a direction
- Six attack groups: face buttons plus left/right shoulder
- Manual cooling: guide button
- Cycle summon portal: back button
- Buy/deploy Hero: start button
- Buy/deploy Puppet group: left stick press
- Buy/deploy Barrier: right stick press

Normal attacks are always normal state. Armor and active states only appear through action modules or source-code puppet sequences. Gun-like muscle components can fire bullet, chemical, or laser projectiles and add a sharp heat spike when used.

The command notation is fighting-game numpad notation, not number keys. In this prototype `236` is recognized as down then forward, and `214` as down then back, relative to the hero's facing direction. Any melee attack button can be combined with these: `236+attack` is armor-state, `214+attack` is active-state.

The default hero is now a crab-style mech built around a torso chassis. Each claw is not a single pincer part: it is represented as two opposing scythe blades connected by a joint and driven by a rod-clamp module. The front two legs mount bullet guns with swing-aim modules, and the rear two legs mount scythes with chain-swing modules.

Team Edit includes a first-pass assembly board. Select a crab body part, then use the shop buttons to install a joint, muscle, or action module for that part. Action modules are software and add no body volume. If multiple body parts use the same action module, those parts must also use identical joint and muscle materials; otherwise the board marks the parts with `!` and the roster becomes invalid.

The editor now uses self-drawn component art for each part class rather than plain text-only previews. Guns, scythes, spikes, gloves, wood stakes, joints, boosters, engines, cooling units, modules, and torso chassis all have separate silhouettes and color language.

Puppet source code now has distinct behavior systems:

- `CODE: GUARD ORBIT` circles the friendly hero and intercepts close approaches.
- `CODE: PINCER` splits a puppet pair high/low and collapses from both lanes.
- `CODE: SCREEN WALL` forms a moving line between the enemy hero and your hero.
- `CODE: MINE DANCE` orbits the target and periodically creates wider strike pockets.

Barrier ether now supports space-control logic:

- `ETHER: HEAT WELL` adds heat to enemies inside its area.
- `ETHER: COOLANT VEIL` cools allied units inside its area.
- `ETHER: DRAG NET` damps enemy velocity inside its area.
- `ETHER: RIPOSTE MIRROR` pulses only when enemies enter its area.

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
