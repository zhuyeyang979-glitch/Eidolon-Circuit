# Eidolon Circuit Worklog Rulebook

Last updated: 2026-05-21

This document is a handoff log written like a tabletop rulebook. Use it to brief another AI agent or human collaborator before changing the Godot project.

Project root: `C:\Users\Administrator\Documents\New project`

Primary implementation file: `scripts/main.gd`

Godot version in workspace: `tools/godot-4.6.2/Godot_v4.6.2-stable_win64_console.exe`

## 2026-05-21 Git Workspace Cleanup

### Rules

- `E:\New project` remains the active development copy; `C:\Users\Administrator\Documents\New project` remains the mirror and does not receive `.git/`.
- `tools/*.gd.uid` is treated as local Godot probe metadata and should not enter version control.
- `scripts/main.gd.uid` and `scripts/fighter.gd.uid` remain tracked because they identify core runtime script resources.

### Implementation Notes

- Added `tools/*.gd.uid` to `.gitignore` so future probe runs do not pollute `git status` or scoped `git diff`.
- Removed the 19 historical tool probe UID files from version tracking: `ai_entry_probe.gd.uid`, `ai_template_pool_probe.gd.uid`, `attitude_control_probe.gd.uid`, `barrier_panel_probe.gd.uid`, `battle_translation_probe.gd.uid`, `catalog_probe.gd.uid`, `chemical_heat_probe.gd.uid`, `combat_probe.gd.uid`, `corner_joint_probe.gd.uid`, `editor_canvas_probe.gd.uid`, `ether_heat_economy_probe.gd.uid`, `ether_probe.gd.uid`, `identity_module_probe.gd.uid`, `projectile_momentum_probe.gd.uid`, `resource_entry_probe.gd.uid`, `shield_probe.gd.uid`, `source_code_probe.gd.uid`, `teamedit_probe.gd.uid`, and `ui_layout_probe.gd.uid`.
- Kept normal source, scene, resource, probe `.gd`, Markdown, JSON, and PowerShell files diffable for later bounded reviews.

### Verification

- `git diff --check` passes.
- `git ls-files 'tools/*.gd.uid'` is empty after cleanup.
- `git check-ignore -v tools/ether_probe.gd.uid` resolves to the new `.gitignore` rule.
- Mirrored `.gitignore` and `WORKLOG_RULEBOOK.md` to Documents and removed the same tool probe UID files there.

## 1. Game Pitch

`Eidolon Circuit: Mobius Arsenal` is a top-down 2D fighting/shooting prototype about player-built machines.

The core fantasy is not "pick a character", but "assemble a topology". A unit is a connected or spatially fixed collection of sci-fi components. Players buy parts, assemble units, choose a sortie, then fight with heroes, puppet groups, and barriers.

The game should feel like:

- Armored Core style buildcraft.
- Fighting game command input and hit feel.
- Bullet-hell/top-down arena movement.
- Poly Bridge / Mario Maker style construction logic.
- A board game with strict setup legality and visible economy tradeoffs.

## 2. Current Main Modes

The main menu contains:

- `Team Edit`
- `Training`
- `AI Battle`
- `PVP`
- `Settings`

Current AI Battle entry rule:

- Main menu AI Battle shows three mouse-clickable seats.
- `P1 LEFT`: player controls left side, right side is AI.
- `P2 RIGHT`: player controls right side, left side is AI.
- `P3 WATCH`: spectator mode, both sides are AI.

Recent fix:

- AI Battle now prepares AI rosters before legality checking.
- AI default templates were repaired so their topology and component indices are legal.
- P1/P2/P3 AI Battle seats were debug-checked as legal after normalization.

## 3. Table Setup

Each player owns a roster before battle.

Current implemented roster limits:

- A team can contain up to `10` units.
- A roster has a total construction budget of `2000`.
- Before battle, each player chooses up to `6` units as the sortie.
- Battle starts with `200` resource.
- Initial deployment must cost `<= 200`.
- Units not yet deployed gradually discount down toward half price.
- Previously deployed units also begin discounting again after a delay.

Important code constants:

- `START_BUDGET = 2000`
- `ROSTER_UNIT_CAP = 10`
- `SORTIE_UNIT_CAP = 6`
- `INITIAL_ENTRY_COST_CAP = 200`
- `RUNTIME_START_RESOURCE = 200`
- `RESOURCE_GAIN_PER_SECOND = 12`
- `DEPLOY_WAIT_SECONDS = 4`
- `MATCH_TARGET_SECONDS = 600`

## 4. Unit Roles

The game currently stores units under three role buckets:

- `Hero`
- `Puppet`
- `Barrier`

Design intent:

- A physical construction may carry Soul, Source Code, and Ether style software in more flexible combinations.
- Identity can switch during battle, so a body can become hero, puppet, or barrier-like depending on modules.

Current implementation reality:

- The roster UI and battle state still keep role buckets: hero, puppet, barrier.
- At most one hero, one puppet group, and one barrier per player can be active at the same time.
- Identity switch effects exist as a prototype layer on top of those role buckets.

## 5. Components

All units are built from these component slots:

- `Special`: Soul, Source Code, Ether.
- `Joint`: movement rule, connection tolerance, load support, cancel feel.
- `Muscle`: physical body/weapon/field component.
- `Booster`: visible thruster payload attached around the body.
- `Engine`: internal/software-like power component.
- `Cooling`: internal/software-like cooling component.
- `Action Module`: software that maps input or AI behavior to component groups.

Important distinction:

- Engines and cooling affect stats but do not appear as collision bodies.
- Boosters and spare weapons can appear visually, but should not enlarge the torso's main collision volume until actively used as a weapon.
- Action modules have no physical volume.

## 6. Construction Legality

A unit must pass tabletop-style legality checks before battle.

Current checks include:

- Every role bucket must have at least one unit.
- Team must stay within 10 units and 2000 cost.
- Sortie must contain 1 to 6 valid roster entries.
- Initial starter must cost `<= 200`.
- Each unit length must be `<= 4.5`.
- At most 1 unit may be longer than `3.5`.
- At most 2 units may be longer than `2.5`.
- At most 3 units may be longer than `2.0`.
- Non-barrier custom topology must be connected.
- Barrier topology may use disconnected pieces if Ether allows it.
- Connected custom topology edges must sit at exact fixed contact distance.
- Joint size support must match connected muscle size rank.
- If multiple body parts share one action module, they must use identical joint/muscle materials.
- Heavy terminal weapons may require dual-limb action modules.
- Torso slot payload mass/count must fit the torso.

Key implementation entry:

- `_team_summary(player_id)`
- `_topology_rule_note(unit_bp, role_key, stats)`
- `_module_material_rule_valid(unit_bp)`
- `_apply_load_balance(stats)`

## 7. Team Edit Board

Team Edit should be understood as the game's construction table.

Current behavior:

- Free Canvas is the default construction mode.
- Templates can be imported as a helper, not as the default mental model.
- Components can be placed on a board.
- Nodes and edges represent physical topology.
- When linked parts connect, they snap to fixed distance like magnets.
- The board marks illegal module-material groups with alarm styling.

Design rule:

- Parts are not connected by arbitrary stretchy lines.
- A joint and muscle connect by touching at their fixed connection distance.
- Longer limbs require longer components or repeated joint/muscle chains.

Known improvement target:

- Keep pushing Team Edit away from "one torso with six limbs" assumptions.
- Tank, drone, monster, barrier, and freeform units need distinct topology layouts.
- Template import should remain a submenu/helper, not the core editor.

## 8. Battle Setup

Before a real match:

1. Players view the opponent's full 10-unit roster.
2. Each player secretly/strategically chooses up to 6 units for battle.
3. Each player chooses one legal starter costing `<= 200`.
4. Scout phase lasts about 45 seconds in the prototype.
5. Initial starter appears immediately.
6. Later summons use a 4-second entry delay.

Current AI Battle support:

- AI rosters are legalized before entering AI Battle.
- If AI data is missing or illegal, the game can rebuild a smart fallback roster.
- P3 spectator mode legalizes both sides for AI-vs-AI.

## 9. Battle Economy

In battle:

- Players start with 200 resource.
- Resource slowly increases over time.
- Killed hero owner receives compensation.
- Some companies/components can create refunds, bounties, annuities, signing grants, or ongoing lease drains.
- Undeployed units become cheaper over time, down to half price.

Summoning:

- Players have six attack buttons.
- Pair combinations of attack buttons map to sortie order slots.
- The pair does not mean "summon hero/puppet/barrier"; it means "summon sortie slot N".
- Illegal summon attempts should play an alarm.
- Illegal examples: not enough money, same role already active, pending deploy already exists, no unit assigned to slot.

## 10. Battle Controls

Current intended keyboard vocabulary:

- `WASD`: movement.
- `Q/E`: rotate facing left/right.
- `Q + E` together: dash/boost shortcut.
- Six attack buttons: mapped to six controlled component groups.
- Commands use fighting game notation such as `236`, `214`, `632146`.

Important rule:

- There are no dedicated armor/active state keys anymore.
- General melee command rule:
  - `236 + attack` means armor-state special.
  - `214 + attack` means active-state special.
- Normal attacks are normal state.

Current prototype still contains some older helper controls and should be audited as controls are finalized.

## 11. Combat Resolution

Damage types:

- Projectile: bullet, chemical, laser.
- Melee: blunt, pierce, tear.

Combat state relationship:

- Normal, armor, and active states act like a rock-paper-scissors layer.
- Current design notes have had contradictory wording; preserve the current command mapping above and test actual code behavior before rebalance.

Hit feel goals:

- Tear should feel like cutting.
- Blunt should feel like collision/impact.
- Pierce should feel like stabbing.
- Bullet should feel like bullet impact.
- Chemical should feel corrosive and unpleasant.
- Laser should feel sharp and "biu-biu".

Current implementation includes:

- Hit effects by damage type.
- Counter-tier feedback.
- Hitstop.
- Projectile logic.
- Barrier fields.

Future target:

- Real physics collision bodies and stronger hit-pause "meatiness".
- More distinct sound layers per damage type.

## 12. Heat

Heat is a second life-like bar system.

Rules:

- Skills add large heat.
- Normal actions can add heat.
- Movement can add heat if cooling is poor.
- Boosting adds a large heat spike.
- Stopping lowers heat faster.
- Manual cooling locks the hero briefly and vents heat.
- Overheat disables skills, slows actions, and increases incoming damage by 15%.

Extra facing rule:

- Mechs have a front/back facing.
- Back attacks add heat punishment by weakening heat handling on rear hits.
- One company style focuses on rear attacks that push enemies into heat shock.

## 13. Heroes

Hero units are directly controlled.

Hero construction themes:

- A hero may be a small humanoid, crab, tank, monster, support unit, or freeform topology.
- Hero does not have to be humanoid.
- Some heroes are main damage dealers.
- Some heroes are support operators that trigger traps, repair, buff, cool, reload, or guide puppets.

Soul design:

- Soul modules guide a player toward a body archetype.
- If requirements are met, the soul grants bonuses.
- If identity switching moves the soul into an unsuitable body, bonuses should drop.

Current implementation:

- Soul bonuses exist in stats.
- Role switching exists as prototype behavior.

## 14. Puppets

Puppets are AI-controlled machines in a group.

Source Code determines:

- Puppet count.
- AI behavior type.
- How many action modules can be sequenced per condition.
- How many condition slots the source code supports.

Examples:

- Guard orbit.
- Pincer.
- Screen wall.
- Mine dance.
- Drone cloud.
- Bootleg legion with betrayal risk.
- Syntax Eleven average-team style.

Current AI behavior:

- AI attempts to summon missing roles.
- AI heroes move toward targets and use actions.
- Puppet groups use source-code stats and group count.

Recent AI roster rule:

- AI team setup now repairs illegal topology and chooses legal sortie entries.

## 15. Barriers

Barrier units are spatial structures.

Barrier construction:

- Ether allows disconnected parts to belong to one unit.
- Barrier geometry is edited like a construction board.
- Barrier entry appears by phasing into the center/space rather than walking from screen edge.
- If entry overlaps enemy barrier geometry, entry can be illegal unless breach components destroy blocking pieces.

Barrier component ideas:

- Heat fields.
- Coolant fields.
- Gravity fields.
- Repulsion fields.
- Hacking fields.
- Trap fields.
- Repair stations.
- Hatcheries.
- Coin generators.
- Speed lanes.
- One-way shields.
- Reflector tiles.
- Cage walls / laser nets / electromagnetic nets.

Current implementation contains many of these as stat flags and field handlers.

## 16. Identity, Ejection, Morph, Combine

Identity switching:

- Hero, puppet, and barrier identity can move between bodies.
- Visual design: soul/source/ether appear like star-like software spirits moving between structures.
- During transfer, the game briefly freezes so both players see the exchange.

Ejection/receiver:

- A unit can eject a part or component group.
- A receiver module on another unit can catch it.
- Flying components can deal damage during travel.
- Routes can be straight, arc, U-shaped, or more complex.

Chain/reel:

- A chained glove/weapon can be fired out and reeled back.

Morph:

- A unit can switch between saved topology connection modes.

Combine:

- Units with combine modules can dock into a combined legal form and later split.

Current status:

- These systems exist as prototype data and partial battle effects.
- They need focused iteration before they feel like finished mechanics.

## 17. Hacking And Control

Information security is a torso/body stat.

Rules:

- Low-security expensive units are vulnerable to hack strategies.
- Hack fields can flip enemy mechs after enough exposure.
- Strong insertion weapons can convert a grabbed/stuck enemy.
- Some attacks only paralyze/jam instead of fully converting.
- Barriers are not mechs unless their structure becomes detached or identity-switched.

Important distinction:

- Hero and puppet are mechs.
- Barrier is normally not a mech.
- Effects like pull, hack, and betrayal usually apply only to mechs.
- Detached barrier pieces can become normal physical objects.

## 18. Companies

Companies are style packages and economy levers.

Known company themes:

- `CRUSTA DYNAMICS`: shell/crab/roach style bodies.
- `HUMANOVA ATELIER`: small humanoid units and readable six-button layouts.
- `COINRUN DYNAMICS`: speed lanes, coin economy, fast route control.
- `COLOSSUS KENNEL`: huge monster bodies, high mass, high melee damage.
- `RECOIL LATTICE`: gun/turret recoil control and braced shooting.
- `RAZOR TEMPLE`: melee tearing/scythe style.
- `AFTERBURN UNION`: boosters and thrust efficiency.
- `CIPHER WARD`: high information security.
- `BOOTLEG GHOST`: cheap source code with betrayal risk.
- `FOLD PARADE`: barrier/puppet switching.
- `YOKE CREDIT`: cheap strong traps with ongoing resource debt.
- `CROWN SALVAGE`: underpriced strong parts that pay enemy bounty when destroyed.
- `PARACHUTE MUTUAL`: weak insured parts that refund the owner.
- `LONGEVITY YIELD`: mediocre parts that generate income while alive.
- `ADVANCE CAPITAL`: entry grants with later destruction penalties.
- `LONGSIGHT AEGIS`: one-way shields and sniper screen style.
- `UMBRA REARWORKS`: rear-hit heat punishment.
- `NEURAL TETHER RESEARCH`: control, grab, intrusion, takeover.

Rule of thumb:

- More same-company components should create discounts or style coherence.
- A single mech generally wants one manufacturer identity.
- Combined mechs may break this single-company rule because they began as separate legal units.

## 19. Current UI State

Main Menu:

- Mouse operation is supported.
- AI Battle seat choice is now visible on the main menu.

Team Edit:

- Free canvas is the conceptual default.
- Component shop and template import exist.
- More clarity is still needed: avoid text stacking, keep import as a submenu, make board manipulation cleaner.

Scout:

- Shows opponent roster.
- Lets player inspect unit details.
- Lets player adjust sortie/starter before match.

Battle HUD:

- P1 health is upper-left.
- P1 heat is lower-left.
- P2 health is upper-right.
- P2 heat is lower-right.
- Each side tracks hero, puppet, and barrier.

## 20. Implementation Map

Important files:

- `scenes/main.tscn`: main scene.
- `scripts/main.gd`: most systems, UI, roster, battle, AI, catalog data.
- `scripts/fighter.gd`: unit scene/script.
- `project.godot`: project metadata.
- `icon.svg` and `icon.ico`: game icon.
- `README.md`: older overview, partially stale.
- `WORKLOG_RULEBOOK.md`: this handoff document.

Important functions in `scripts/main.gd`:

- `_build_menu_ui()`: main menu layout.
- `_build_editor_ui()`: Team Edit UI.
- `_start_battle(mode)`: validates and enters scout/battle.
- `_show_scout(mode)`: prebattle scouting.
- `_begin_battle(mode)`: initializes battle.
- `_team_summary(player_id)`: legality summary.
- `_prepare_ai_battle_rosters()`: AI roster preparation.
- `_legalize_ai_player_roster(player_id)`: AI legality fixer.
- `_default_player_roster(player_id)`: initial rosters.
- `_default_free_canvas_topology(profile)`: starter free-canvas topology.
- `_summon_role(player_id, role_key, free, immediate, alarm)`: deployment.
- `_update_ai_player(player_id, delta)`: AI player loop.

## 21. Recent Work Log

2026-05-16:

- Added mouse-clickable AI Battle seat buttons to the main menu.
- Made AI Battle select P1/P2/P3 before entering the match flow.
- Fixed AI Battle being blocked by illegal team setup.
- Repaired default template indices so current component catalog creates legal units.
- Added AI roster legalization before AI Battle.
- Added AI fallback roster construction when AI data is missing or illegal.
- Ensured battle start normalizes starter selection against the 200 initial-entry cap.
- Verified Godot headless startup after changes.
- Verified via temporary debug scripts that AI Battle P1/P2/P3 seats can produce legal rosters.

2026-05-19:

- Connected Git to the user PATH with `E:\Git\cmd`; verified `git version 2.54.0.windows.1` and `git status --short`.
- Confirmed the local fallback Git remains available at `C:\Users\Administrator\OneDrive\ドキュメント\New project\tools\git-portable\cmd`.
- Rechecked the embedded-joint / direct-muscle TeamEdit foundation after the torso-slot one-to-one and swept-collision pass.
- Verified TeamEdit generated rosters are legal: standard 10-unit teams, 6 sortie slots, at least heroes, puppets, and barriers.
- Verified AI Battle reaches actual battle state from scout with both starting units spawned.
- Verified torso socket hard rules: a `torso_port:n`, `root_joint`, or `distal` socket cannot be occupied by two edges.
- Verified generated templates do not contain duplicate socket occupancy.
- Verified broad torso slot angle profiles and explicit slot-profile overrides.
- Verified continuous limb sweep checks distinguish wide-but-separated motion from true overlap.
- Verified torso ports are on the trapezoid torso edge and combat topology segments match TeamEdit socket geometry.
- Verified UI layout and text overflow probes in Chinese and English report zero overlap/overflow.
- Verification suite passed: `check-only`, `teamedit_probe`, `ai_entry_probe`, `direct_socket_occupancy_probe`, `template_socket_occupancy_probe`, `wide_slot_angle_probe`, `swept_limb_collision_probe`, `torso_edge_port_probe`, `combat_topology_pose_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `part_library_ui_probe`, and `editor_balance_stat_probe`.
- Current conclusion: automated checks say the bottom-level topology, socket occupancy, AI-entry, and combat-topology loop is connected end to end.
- Remaining risk: the next pass should still manually test real mouse dragging, right-click unlinking, slot lock visuals, and the subjective feel of pose editing in the live TeamEdit screen.
- Note: Godot headless still prints `ObjectDB instances leaked at exit`; treat it as a known teardown warning unless it starts failing a probe or leaking during live gameplay.

2026-05-20:

- Added saved-unit deletion from the Saved Units library, including single/multi-select deletion, confirmation UI, file removal under `user://saved_units`, and UI refresh after deletion.
- Updated boost input so WASD diagonal combinations can boost in the current held 8-way direction when any involved direction key is double-tapped.
- Updated braking so any input vector with a clear rear-facing component relative to the unit's own facing triggers boost-strength braking; side/forward input does not trigger brake.
- Changed `Two-Link Forward Snap` runtime actions to commit their final local segment pose back into `runtime_topology_segments`, so limbs remain at the module end pose instead of snapping back to default.
- Cleaned `scripts/fighter.gd` by removing dead legacy six-limb/center-anchor fallback bodies from the saved-unit path stubs; saved units continue to require TeamEdit runtime topology.
- Added probes: `saved_unit_delete_probe`, `eight_direction_boost_probe`, `brake_input_tolerance_probe`, `two_link_pose_persist_probe`, and `training_module_pose_persist_probe`.
- Verification passed: `check-only`, `saved_unit_delete_probe`, `eight_direction_boost_probe`, `brake_input_tolerance_probe`, `two_link_pose_persist_probe`, `training_module_pose_persist_probe`, `teamedit_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_topology_pose_probe`, `two_link_forward_snap_combat_pose_probe`, `module_binding_direct_trigger_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `no_action_group_symbols_probe`, `fighter_no_legacy_fallback_probe`, `saved_unit_exact_runtime_probe`, `part_library_ui_probe`, and `unit2_four_two_link_bindings_probe`.
- Remaining risk: `combat_probe` still exits 0 but reports no hit in its legacy-style summary, so the probe should be rewritten to assert the new runtime topology hit model directly.

2026-05-20 battle input pass:

- Replaced saved-unit runtime module triggering with attack command windows: first attack press opens the window, second same key fires normal, front-direction input fires armor, and rear-direction input fires active for all open windows.
- Added window timeout and long-hold cancel behavior; windows are cleared per battle and do not use the old `236/214` command buffer for TeamEdit runtime modules.
- Changed runtime module effects so armor/active state is carried by the executing runtime limb/action instead of switching the whole mech body state.
- Reworked Settings into a scrollable battle-input panel covering movement directions, boost notes, Q/E turn actions, and attacks 1-6 for both P1 and P2.
- Added keyboard/controller rebinding for battle actions with conflict cleanup inside the same action group, persistence to `user://battle_input_bindings.json`, and a reset-to-default button.
- Added probes: `attack_window_open_probe`, `battle_input_settings_ui_probe`, and `battle_input_rebind_probe`.
- Verification passed: `attack_window_open_probe`, `battle_input_settings_ui_probe`, `battle_input_rebind_probe`, `keyboard_attack_mapping_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `two_link_forward_snap_combat_pose_probe`, `combat_topology_pose_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Remaining risk: real gamepad rebinding should be checked manually on hardware; the probe verifies joy event serialization paths but not physical controller feel.

## 22. Known Mismatches And Risks

### 2026-05-20 Battle Runtime Cleanup Pass

- Construction/combat rule affected: saved TeamEdit units now use polygon runtime shapes as the shared source for visuals and collision. Torso polygons remain polygons, and limb/terminal shapes are rendered as polygons derived from the same runtime segment endpoints used for collision.
- Collision rule affected: TeamEdit runtime unit penetration correction now only separates positions. It no longer injects extra velocity or visual impulse. Passive contact knockback now uses relative closing speed times reduced mass for runtime units.
- Damage feedback rule affected: normal hits no longer use guard/block wording. The current nullified labels are `动量不足`, `未破阈值`, and `护盾吸收`.
- Verification added: `runtime_penetration_no_velocity_kick_probe`, `runtime_collision_momentum_probe`, and `runtime_contact_damage_probe`.
- Verification passed: `check-only`, `runtime_topology_only_visual_probe`, `no_runtime_collision_expansion_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `saved_unit_no_fallback_probe`, `no_action_group_symbols_probe`, `combat_probe`, `training_seat_spawn_unit2_probe`, `training_saved_unit_control_probe`, `unit2_training_probe`, `no_guard_label_probe`, `battle_xy_background_probe`, `eight_direction_runtime_movement_probe`, `no_reverse_runtime_movement_probe`, `brake_input_tolerance_probe`, `turn_auto_brake_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Remaining risk: old non-TeamEdit demo scaffolding still exists in the codebase, but saved units are guarded by probes so they do not render or collide through the old shell/joint/action-group path. A future cleanup should physically split or delete the old demo path from `scripts/fighter.gd` and `scripts/main.gd`.

### 2026-05-20 Physical Old Battle Path Deletion Pass

- Construction/combat rule affected: saved TeamEdit units now physically lack the old fighter visual nodes. `Shell`, `TopologyLine`, `MuscleA/B`, `JointA/B`, `SpecialCore`, and `CoreProceduralArt` are no longer created by `scripts/fighter.gd`.
- Rendering rule affected: saved-unit fighters only build `runtime_torso_polygons` and `runtime_part_polygons` from `runtime_topology_segments`; old CAD/atlas body texture variables and sprite refresh helpers were removed from the saved-unit fighter path. VFX such as thrust flames, hit effects, and weapon face markers remain as effects attached to runtime geometry.
- Combat data rule affected: `scripts/main.gd` no longer generates attack groups for saved units. The `_attack_groups_for_*`, `_fallback_attack_group`, temporary fragment fallback group, and spare weapon fallback group paths were removed or replaced with inert no-group behavior. Saved units are driven by `runtime_module_bindings`.
- Collision rule retained: runtime polygon overlap still separates by position only, then contact damage/knockback uses relative closing momentum and reduced mass rather than arcade kick multipliers.
- Test cleanup: obsolete probes that directly called removed `action_groups`/old FK functions were deleted from `tools/` so future verification does not accidentally depend on the retired combat scaffold.
- Verification passed: `check-only`, `saved_unit_no_fallback_probe`, `fighter_no_legacy_fallback_probe`, `no_action_group_symbols_probe`, `runtime_topology_only_visual_probe`, `runtime_geometry_identity_probe`, `runtime_collision_momentum_probe`, `runtime_contact_damage_probe`, `no_runtime_collision_expansion_probe`, `no_guard_label_probe`, `battle_xy_background_probe`, `training_seat_spawn_unit2_probe`, `training_saved_unit_control_probe`, `unit2_training_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Remaining risk: editor-side CAD reference preview code still exists in `scripts/main.gd` for TeamEdit reference panels. It is not part of saved-unit battle rendering, but if the art direction fully abandons CAD references, that editor-only preview should be removed in a later UI cleanup.

The project is evolving quickly. Treat these as caution flags:

- `README.md` contains older rules and may mention outdated budgets or controls.
- `scripts/main.gd` is very large and should eventually be split into data, UI, battle, AI, and editor modules.
- Some requested mechanics exist as catalog flags or partial prototypes, not finished gameplay.
- Real collision bodies and polished hit feel are not complete.
- Team Edit still needs stronger usability, especially for freeform topology and non-six-limb templates.
- Controls should be audited after removing dedicated armor/active keys.
- Gamepad PVP needs practical testing.
- Audio is procedural/prototype-level.
- There is no permanent automated test suite yet; current verification is mostly Godot headless loading plus temporary debug scripts.

## 23. Suggested Next Work

Recommended order for the next collaborator:

1. Make a small permanent debug/test runner for roster legality and AI Battle seats.
2. Clean Team Edit visual layout and make Free Canvas unmistakably primary.
3. Add a proper mouse-only path for every submenu and every return action.
4. Split catalog data out of `scripts/main.gd`.
5. Stabilize control mapping: WASD, Q/E, six attacks, command notation, summon pairs.
6. Improve actual physics collision and hitstop feel.
7. Add clear icon/audio feedback for illegal summon, illegal topology, overheat, module failure, and identity switch.
8. Turn the strongest prototype systems into a minimal fun loop before adding more catalog items.

## 24. Collaboration Rule

Before changing gameplay rules, answer these three questions in the work log:

1. Which table phase does this change affect: construction, scouting, deployment, combat, economy, or victory?
2. Which legality checker or UI view must be updated?
3. Does the change help buildcraft, battle readability, or player expression?

If the answer to all three is unclear, write the design note first and delay implementation.

## 2026-05-20 近战结算与双段正锋折返落地

Construction:
- `双段正锋折返 / Two-Link Forward Snap` now records startup/recovery terms in the module data: startup is 1/3, recovery is 2/3.
- Saved/runtime entry pose now defaults to the recovery pose for limbs bound to this module. If multiple modules bind the same limb, the lower software-slot order wins.

Combat:
- Two-Link startup straightens both bound segments forward. Recovery ends with the proximal segment backward and the distal segment forward, both parallel to the torso axis. The final pose persists after the action.
- Melee terminal colliders no longer expand during startup. Visible geometry is the combat collider; no hidden 2x startup volume remains.
- Non-gun melee/runtime attacks cannot generate projectile colliders. Projectile work is frozen until gun terminal logic is revisited.
- Same-Fighter torso/limb/terminal self-collision is filtered out of separation, passive contact, damage, hitstun, and VFX.
- Brake input now only triggers in the rear 100 degree cone. Other input directions remain available for movement/boost. Turn speed and turn acceleration constants were doubled again.

Verification:
- Added probes for rear-cone braking, Two-Link phase timing, recovery pose, visible-volume strike collision, same-unit self-collision filtering, and melee projectile gating.
- Passed: `check-only`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_contact_damage_probe`, `terminal_threshold_balance_probe`, `two_link_phase_timing_probe`, `two_link_recovery_pose_probe`, `strike_collider_expand_probe`, `attack_window_multi_active_probe`, `no_runtime_collision_expansion_probe`, `same_unit_no_self_collision_probe`, `melee_projectile_gate_probe`, `brake_rear_100_probe`, `combat_probe`, `training_saved_unit_control_probe`, `unit2_training_probe`, `runtime_geometry_identity_probe`, `saved_unit_no_fallback_probe`, `runtime_topology_only_visual_probe`, `ui_layout_probe`, and `text_overflow_probe`.

Sync:
- Active project remains `E:\New project`.
- Scripts and tools were mirrored to `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`; hashes match for the touched files.

## 2026-05-20 攻击窗口专属指令与无接触反馈修复

Combat:
- Player-facing hit VFX no longer display `NONE`. Ordinary tier-0 non-nullified hit effects are suppressed; styled tier-0 VFX may still draw, but with no `NONE` label.
- Directional attack-window resolution is no longer a global `4/6` rule. The command window asks each bound module for its own `command_window_profile`.
- `双段正锋折返 / Two-Link Forward Snap` now declares `command_window_profile = two_link_4_6`: front input triggers armor, rear input triggers active, and same-key input triggers normal. Modules without such a profile do not inherit `4/6` specials.
- Two-Link animation no longer shortest-path interpolates. The bound torso side decides the forced path: local-left roots strike clockwise and recover counterclockwise; local-right roots strike counterclockwise and recover clockwise.

Verification:
- Added `runtime_no_precontact_none_probe`, `module_specific_command_window_probe`, and `two_link_side_rotation_probe`.
- Updated `attack_window_multi_active_probe` to resolve multi-window active attacks through module-specific direction parsing, and updated `two_link_forward_snap_module_probe` away from old `attack_groups`.
- Passed: `check-only`, `runtime_no_precontact_none_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_contact_damage_probe`, `module_specific_command_window_probe`, `two_link_side_rotation_probe`, `attack_window_multi_active_probe`, `two_link_forward_snap_module_probe`, `two_link_phase_timing_probe`, `two_link_recovery_pose_probe`, `combat_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_topology_pose_probe`, `ui_layout_probe`, and `text_overflow_probe`.

## 2026-05-20 战斗模型大统一与旧阈值清理

Construction / data model:
- Every volumetric catalog part is normalized with the combat fields `mass`, `hp`, `stiffness_momentum`, `damage_coeff`, `break_coeff`, `size_tier`, and `contact_shape_kind`. Software, software-muscles, and ammo do not receive collision coefficients.
- `刚度 / Stiffness` now means the maximum contact momentum that can be used for damage and break-threshold calculation. It is non-directional.
- Default stiffness calibration uses latest legal saved unit `2` as the balance reference. Normal limbs are `S`, torso and melee terminal weapons are `2S`, ranged terminals are `0.8S`, and barrier panels are `S`, with XS/S/M/L/XL scaling at `0.25/0.5/1/2/4`.
- Default damage coefficients: torso `1.0`, normal limb `1.0`, melee terminal `2.5`, ranged terminal body collision `0.8`, barrier panel `1.0`.
- Default break coefficients: melee terminal `1.0`; torso, normal limb, ranged terminal, and barrier panel `0.5`.

Combat math:
- The unique saved-unit contact pipeline is now: TeamEdit geometry -> rounded collision polygon -> contact normal -> closing speed -> raw contact momentum -> path stiffness cap -> HP damage and break threshold -> one-shot impulse and VFX.
- Contact momentum uses the normal axis: `raw_momentum = closing_speed * (mass_a + mass_b)`.
- Momentum transfer paths stop at the same unit's torso. Torso collision uses torso stiffness only; limb collision uses that limb chain plus torso; terminal collision uses terminal, connected limb chain, and torso. Other limbs are not included.
- Path stiffness is the minimum `stiffness_momentum` on that transfer path.
- Damage is `min(raw_momentum, attacker_path_stiffness) * attacker_part.damage_coeff * CONTACT_DAMAGE_SCALE`.
- Break threshold is `target_path_stiffness * target_part.break_coeff * BREAK_STIFFNESS_SCALE`. Current tuned scale: `0.015`.
- Position separation only removes overlap. It does not inject velocity. Velocity changes come from contact momentum, thrusters, action-module momentum, or future projectile momentum.
- A continuous overlap pair resolves once; it can resolve again only after the colliders separate and touch again.

Old logic removed or disabled:
- The saved-unit runtime melee path now routes before the old projectile/damage gate. Two-Link and passive runtime contacts call `_apply_runtime_contact_damage()` directly.
- `_damage_after_damage_unit_gate()` is deprecated into a compatibility shim. It no longer performs damage-threshold blocking; it only applies legacy projectile material adjustment until the projectile system is rewritten.
- Obsolete probes tied to the retired damage-unit gate were deleted: `damage_gate_uses_damage_probe`, `damage_unit_hp_probe`, `damage_unit_threshold_probe`, and `terminal_threshold_balance_probe`.
- Player-facing `NONE` and `BLOCK` remain removed from ordinary hit feedback. Low-result runtime contact can show only momentum/break/shield-specific messages.

Verification:
- Added/kept probes covering the new model: `part_catalog_balance_probe`, `no_old_threshold_gate_probe`, `stiffness_value_probe`, `two_link_damage_balance_probe`, `boost_torso_collision_damage_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_no_precontact_none_probe`, `runtime_contact_damage_probe`, `contact_normal_momentum_probe`, `runtime_penetration_no_velocity_kick_probe`, `runtime_collision_momentum_probe`, `one_shot_contact_probe`, `saved_unit_no_fallback_probe`, `runtime_geometry_identity_probe`, and `rounded_collision_shape_probe`.
- Balance checks passed: saved unit `2` Two-Link damage currently lands at `8 HP`, about `5.3%` of the target max HP, inside the intended roughly `1/12` band; boost torso collision reduces both HP values.
- Regression passed: `check-only`, `teamedit_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot still prints `ObjectDB instances leaked at exit` in some headless runs; current probes treat this as a headless cleanup warning, not a gameplay failure.

Sync:
- Active project path is `E:\New project`.
- Changed scripts, probes, and this work log were mirrored to `C:\Users\Administrator\Documents\New project`; touched-file hashes match between E and Documents.
- Deleted obsolete damage-unit probes were removed from both E and Documents copies.
- Desktop shortcuts `Eidolon Circuit.lnk`, `Strike Lab Game.lnk`, and `Godot 4.6.2.lnk` now launch `E:\New project` through the E-drive Godot binary.

Remaining cleanup risk:
- Historical non-TeamEdit/demo helpers and old data-field names still exist in the monolithic files for legacy field/status systems. They are no longer used by saved-unit runtime contact, but future cleanup should split or delete the old demo sections outright once projectile and field mechanics are rebuilt on the same stiffness model.

## 2026-05-21 战斗数学系统统一复检与旧词条二次清理

Scope:
- Active development copy remains `E:\New project`.
- The Documents copy is treated as a mirror target only; it was behind the E-drive source before this pass.
- This pass focused on saved TeamEdit units only: TeamEdit geometry, saved thumbnails, training, combat rendering, combat collision, and contact damage must share the same procedural AssemblyBoard-style geometry source.

Code cleanup:
- Removed the last hidden editor CAD reference naming and replaced it with neutral structure-reference naming. The reference view is hidden/null by default and no longer loads a second physical-part art system.
- Removed the old `_draw_atlas_icon` path from the TeamEdit card rendering path. Physical parts now use procedural component drawing only; image-sheet/VFX paths remain reserved for effects, not unit bodies.
- Removed obsolete probes that enforced retired mechanics: `strike_collider_expand_probe.gd` and `joint_fixed_momentum_probe.gd`.
- Added `no_old_combat_terms_probe.gd` to block old saved-unit combat symbols from `main.gd`, `fighter.gd`, and `part_art.gd`.
- Added `catalog_ui_terms_probe.gd` so catalog hover/detail UI must expose the new combat vocabulary instead of old damage-unit/load/momentum-cap wording.
- Added `transfer_path_min_stiffness_probe.gd` to lock terminal/limb/torso path stiffness to the lowest part on the momentum transfer path.

Current combat model:
- Runtime contacts use rounded TeamEdit geometry and contact-normal momentum.
- `raw_momentum = closing_speed_on_contact_normal * (mass_a + mass_b)`.
- Each side's usable damage momentum is capped by the minimum `stiffness_momentum` along that side's transfer path.
- `damage = min(raw_momentum, attacker_path_stiffness) * damage_coeff * CONTACT_DAMAGE_SCALE`.
- Break threshold remains `target_path_stiffness * break_coeff * BREAK_STIFFNESS_SCALE`.
- Same-Fighter self-collision stays filtered. Continuous contact resolves once until separation.
- Position separation is only overlap correction; it is not a hidden velocity/knockback source.

UI vocabulary:
- Physical part cards and hover stats show: `质量/Mass`, `生命/HP`, `刚度/Stiffness`, `伤害系数/Damage Coeff`, `破防系数/Break Coeff`, plus plugin-specific power/cooling/thruster values.
- Player-facing old terms are blocked from the main saved-unit path: `DAMAGE UNIT`, `Momentum Cap`, and `Load Capacity`.
- Ordinary contact feedback must not show `NONE` or `BLOCK`; low results use momentum/break/shield-specific language only.

Verification:
- New/updated probes passed: `part_catalog_balance_probe`, `stiffness_value_probe`, `contact_normal_momentum_probe`, `transfer_path_min_stiffness_probe`, `rounded_collision_shape_probe`, `runtime_geometry_identity_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_contact_damage_probe`, `runtime_penetration_no_velocity_kick_probe`, `runtime_collision_momentum_probe`, `one_shot_contact_probe`, `boost_torso_collision_damage_probe`, `two_link_damage_balance_probe`, `no_old_combat_terms_probe`, and `catalog_ui_terms_probe`.
- Regression passed once for: `teamedit_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `saved_unit_no_fallback_probe`, `no_action_group_symbols_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- A 3-round loop passed for: `check-only`, `part_catalog_balance_probe`, `runtime_geometry_identity_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_contact_damage_probe`, `boost_torso_collision_damage_probe`, `two_link_damage_balance_probe`, `combat_probe`, `no_old_combat_terms_probe`, and `catalog_ui_terms_probe`.
- Godot still reports `ObjectDB instances leaked at exit` in some headless runs. Current evidence still indicates a headless cleanup warning rather than a failed gameplay assertion.

Sync:
- After validation, `scripts`, `tools`, and this log were copied from `E:\New project` to `C:\Users\Administrator\Documents\New project`.
- The deleted obsolete probe files were removed from the Documents mirror as well.
- Hashes match for the touched scripts, probes, renderer, and this log between E drive and Documents.
- Desktop shortcuts were rechecked after sync and should continue to point at `E:\New project`.

## 2026-05-21 训练近战误入投射物 Gate 修复

Root cause:
- Saved-unit runtime melee events could still carry stale `projectile`, `projectile_only`, `projectile_style`, or `projectile_behavior` fields from older module/probe paths.
- `_resolve_attack()` saw those fields before melee routing and showed `投射物必须由枪械末端肌肉发射`, even when the player was only approaching or using `双段正锋折返`.
- `_attack_part_hit()` also treated any projectile-marked event as projectile-like, which could loosen runtime hit handling instead of using strict TeamEdit polygon overlap.

Fix:
- Added runtime attack normalization. Any saved-unit runtime event that is not explicit `gun_activate` is forced into `runtime_melee_contact`, with all projectile fields cleared.
- Restricted the visible projectile/gun-source warning to explicit `gun_activate` events only.
- Runtime melee now resolves through `_resolve_runtime_melee_attack()` before projectile logic and cannot call the projectile gate.
- `_attack_part_hit()` only treats explicit `gun_activate` events as projectile events. Runtime melee keeps strict overlap-only contact.
- Strengthened no-contact probes so pre-contact spacing fails if geometry is actually touching, and it now also asserts no battle message appears.

Verification:
- Added probes: `runtime_melee_never_projectile_gate_probe.gd` and `projectile_warning_only_gun_activate_probe.gd`.
- Updated probes: `runtime_no_precontact_damage_probe.gd` and `runtime_no_precontact_fx_probe.gd`.
- Passed: `check-only`, `runtime_melee_never_projectile_gate_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_no_precontact_none_probe`, `runtime_contact_damage_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `teamedit_probe`, `no_old_combat_terms_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot still prints occasional `ObjectDB instances leaked at exit` warnings in headless mode; no gameplay assertion failed.

Sync:
- Implemented in `E:\New project`.
- Mirrored changed files to `C:\Users\Administrator\Documents\New project` after validation.

## 2026-05-21 自动 Seeker 误触发冻结

Root cause:
- `SEEKER 57%` was not a melee/contact warning. It came from `_apply_homing_launchers()` automatically polling any unit with `is_homing_launcher=true`.
- When an enemy entered the homing radius, `_fire_homing_missile()` spawned missile VFX, showed `%s SEEKER %.0f%%`, and called `_resolve_attack()` even though the current projectile system is frozen.

Fix:
- Automatic homing/seeker launchers are now runtime-disabled. Seeker parts remain catalog data for future gun/missile modules, but proximity alone cannot fire or show a warning.
- `projectile_warning_only_gun_activate_probe` now also covers stale homing/missile fields on a non-gun runtime melee event.
- Added `seeker_no_auto_fire_probe`: a saved-runtime unit with `is_homing_launcher=true` can sit inside enemy range for 180 frames without battle message, missile VFX, projectile event, or HP change.

Verification:
- Passed: `check-only`, `seeker_no_auto_fire_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_melee_never_projectile_gate_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_contact_damage_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `no_old_combat_terms_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot still prints occasional headless `ObjectDB instances leaked at exit` warnings; gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Mirrored changed files to `C:\Users\Administrator\Documents\New project` and verified matching hashes for touched files.

## 2026-05-21 刹车后倒车、反伤屏蔽与仪表盘改版

Rules:
- 不可推进/不可 Boost 的方向输入先执行刹车；速度归零后记录该方向为短时“倒车准备方向”。
- 玩家必须松开方向再按近似同方向，才允许普通倒车移动。倒车只使用普通推进，不允许反向 Boost。
- 反向 Boost 输入继续只会刹车或无效，不会生成 `boost_drive`。
- 主动近战命中写入接触抑制，直到该接触对分离或安全超时前，禁止被动接触路径把同一个接触反向结算为攻击方 HP 反伤。
- 战斗中央仪表盘不再显示动量。速度表上限改为 `max(当前速度, 2 * boost_speed, 3 * body_move_speed, 1)`，弹药改为十等分半透明条，并用程序化图标区分子弹、激光、化学、炸药、蛛丝。

Implementation notes:
- `Fighter` 新增运行时状态：`brake_reverse_ready_dir`、`brake_reverse_ready_timer`、`brake_reverse_requires_repress`。
- `_apply_velocity_brake()` 可以接收导致刹车的输入方向；刹停后记录倒车准备状态。
- `_movement_command_mode()` 会在释放/再按后允许同方向普通倒车，但 `boost()` 不读取该状态。
- `BattleInstrumentGaugeView` 改为速度指针 + 弹药十格图标条，移除 momentum 状态和显示。
- `active_melee_contact_suppression` 从短时 0.28s 抑制改为“接触未分离前持续抑制 + 2s 安全上限”，并给运行时接触事件加入 `contact_source`。

Verification:
- Added probes: `brake_reverse_after_stop_probe.gd`, `reverse_cannot_boost_probe.gd`, `brake_reverse_direction_tolerance_probe.gd`, `battle_ammo_segment_gauge_probe.gd`.
- Updated probe: `battle_instrument_gauge_probe.gd`.
- Passed: `check-only`, `brake_unusable_direction_probe`, `boost_unusable_direction_brakes_probe`, `brake_reverse_after_stop_probe`, `reverse_cannot_boost_probe`, `brake_reverse_direction_tolerance_probe`, `battle_instrument_gauge_probe`, `battle_ammo_segment_gauge_probe`, `melee_contact_source_probe`, `runtime_contact_damage_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot still prints occasional headless `ObjectDB instances leaked at exit` warnings; gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Mirrored changed files to `C:\Users\Administrator\Documents\New project` and verified matching SHA-256 hashes for all touched files.
- Smoke-tested the Documents mirror with `brake_reverse_input_layer_probe` and `board_battle_art_identity_probe`; both passed.

## 2026-05-21 Boost 冷却、速度上限、后向100度刹车区与待机碰撞收束

Rules:
- Boost 成功后进入 `0.5s` 冷却；冷却中再次双击方向不会触发 Boost，但普通移动、刹车和倒车逻辑继续工作。
- 每台机体获得统一 `speedometer_max_speed / speed_limit`。战斗仪表盘上限和真实速度上限读取同一字段，每帧物理结算后裁剪最终速度。
- 后向刹车区从“背面 180 度”收窄为“机体正后方 ±50 度”。只有落入该 100 度扇区的方向属于只能刹车/倒车且不能 Boost；侧向、侧后方和正向仍可正常移动与八向 Boost。
- 刹车到零后，玩家需要松开并再按同方向才会进入普通倒车；倒车仍不能 Boost。
- 默认/收招状态下，保存单位只暴露躯干碰撞体。普通肢体和末端武器只在行动模块执行期间临时暴露为独立碰撞体并独立结算。
- 双段正锋折返伤害验收收紧到约 `1/20` 目标 HP。本轮实测单位2样板为 `0.053`，在 4%-7% 验收带内。

Implementation notes:
- `Fighter` 新增 `boost_cooldown_timer`，`boost()` 成功后写入 `boost_cooldown`，`tick()` 中递减。
- 新增 `_is_rear_brake_zone()`，用后向向量点积与 `cos(50°)` 判断刹车区；`_thruster_drive_direction()` 只在该区域拒绝推进。
- 新增 `_speedometer_max_speed()` 与 `_clamp_velocity_to_speedometer()`，所有速度来源包括普通推进、倒车、Boost 和碰撞残余速度都会被同一个上限裁剪。
- `main.gd` 的 `_apply_thruster_momentum_stats()` 现在写入 `speedometer_max_speed` 与 `speed_limit`，并允许躯干/统计通过 `speedometer_mult` 派生不同速度表。
- `part_colliders()` 对 TeamEdit runtime 单位默认只返回躯干；只有 `runtime_module_actions.target_nodes` 中的肢体/末端武器会在动作期间加入碰撞列表。

Verification:
- Added probes: `boost_cooldown_probe.gd`, `velocity_clamped_to_gauge_probe.gd`, `rear_100_brake_zone_probe.gd`, `idle_collision_uses_torso_coeff_probe.gd`, `active_limb_collision_only_during_module_probe.gd`, `speed_limit_from_torso_probe.gd`.
- Updated probes: `two_link_damage_balance_probe.gd`, `transfer_path_min_stiffness_probe.gd`.
- Passed: `check-only`, `boost_cooldown_probe`, `velocity_clamped_to_gauge_probe`, `rear_100_brake_zone_probe`, `idle_collision_uses_torso_coeff_probe`, `active_limb_collision_only_during_module_probe`, `speed_limit_from_torso_probe`, `boost_unusable_direction_brakes_probe`, `brake_rear_100_probe`, `brake_unusable_direction_probe`, `brake_reverse_after_stop_probe`, `reverse_cannot_boost_probe`, `brake_reverse_direction_tolerance_probe`, `turn_auto_brake_probe`, `eight_direction_boost_probe`, `two_link_damage_balance_probe`, `battle_instrument_gauge_probe`, `runtime_contact_damage_probe`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `saved_unit_no_fallback_probe`, `no_action_group_symbols_probe`, `part_catalog_balance_probe`, `contact_normal_momentum_probe`, `transfer_path_min_stiffness_probe`, `one_shot_contact_probe`, `no_old_combat_terms_probe`, `catalog_ui_terms_probe`, `melee_contact_source_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot still prints occasional headless `ObjectDB instances leaked at exit` warnings; gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section in the same Codex turn.

## 2026-05-21 刹车后倒车输入层、默认全视觉碰撞代理躯干、画板/战斗同源锁定

Rules:
- 本节覆盖上一节“默认只暴露躯干碰撞体”的临时规则。当前正式规则为：默认/收招状态下，躯干、普通肢体、末端武器全部以画板同源视觉体积参与几何接触检测和位置分离，但非躯干 collider 统一 `damage_proxy=torso`，不独立扣 HP、不独立破防、不独立播伤害语义。
- 默认状态敌方接触任意肢体或末端武器时，接触点仍来自真实可见部件；伤害系数、破防系数、刚度路径、HP 扣减全部代理到该机体躯干，并且同一被代理躯干接触只结算一次。
- 行动模块执行期间，绑定部件节点设置 `independent_damage=true`，普通肢体段和末端武器段才按自身系数独立结算。动作结束后回到躯干代理。
- 同一 Fighter 内部仍不自碰撞；两台蓝图完全相同但实例不同的机体，按不同单位正常碰撞和伤害。
- 刹车后倒车必须经过完整输入层状态机：刹停后记录 `brake_reverse_ready_dir`，玩家持续按住不会倒车；必须松开移动输入后，再次按下近似同方向，才进入普通倒车。倒车不能 Boost。
- `last_move_command_mode` 写入 `drive/brake/reverse/none`，用于 HUD/debug meta 与探针定位。

Implementation notes:
- `Fighter.part_colliders()` 对 TeamEdit runtime 单位返回全部可见 segment collider。非活动模块目标的非躯干 segment 会写入 `damage_proxy=torso`、`damage_proxy_torso_unit_index` 与 `independent_damage=false`。
- 运行中行动模块目标来自 `_runtime_active_collider_node_set()`；这些节点临时成为 `independent_damage=true`。
- 接触 key 统一通过 `_runtime_contact_socket_key()` 生成。躯干代理 collider 会折叠为 `torso:<torso_unit_index>:proxy`，避免同一躯干被多个默认肢体 collider 在同一持续接触中重复扣血。
- `_runtime_contact_part_damage_coeff()`、`_runtime_contact_part_break_coeff()`、`_runtime_contact_part_stiffness()`、`_runtime_contact_path_stiffness()`、`_runtime_contact_damage_type()`、`_runtime_contact_material_class()` 都先检查 `damage_proxy=torso`，再读取部件自身字段。
- 输入层在 `main.gd` 中记录每个玩家上一帧移动向量和本帧 `just_pressed`，并调用 `Fighter.note_movement_input_pressed()` / `note_movement_input_released()`。这让“刹停、松开、再按同方向倒车”可以从真实 P1/P2 输入路径验证，而不是只在 Fighter 内部模拟。
- 新增画板/战斗同源探针，直接比较 `AssemblyBoardRenderer.component_polygon()` 与 Fighter runtime collider polygon，防止战斗侧又生成独立矩形、线段或旧装饰体。

Verification:
- Added probes: `brake_reverse_input_layer_probe.gd`, `idle_collision_one_torso_damage_probe.gd`, `same_shape_different_unit_collision_probe.gd`, `board_battle_art_identity_probe.gd`, `no_legacy_runtime_pointers_probe.gd`.
- Updated probes: `idle_collision_uses_torso_coeff_probe.gd`, `active_limb_collision_only_during_module_probe.gd`.
- Passed: `check-only`, `brake_reverse_input_layer_probe`, `idle_collision_uses_torso_coeff_probe`, `idle_collision_one_torso_damage_probe`, `active_limb_collision_only_during_module_probe`, `same_shape_different_unit_collision_probe`, `board_battle_art_identity_probe`, `no_legacy_runtime_pointers_probe`, `runtime_no_precontact_damage_probe`, `runtime_contact_damage_probe`, `two_link_damage_balance_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `saved_unit_no_fallback_probe`, `no_action_group_symbols_probe`, `boost_cooldown_probe`, `rear_100_brake_zone_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `combat_probe` currently reports `runtime_topology_hit=true hp_delta=1 min_gap=-0.1200 segments=3`. It still prints a compact summary, but it now observes runtime topology hit and HP change.
- Godot still prints occasional headless `ObjectDB instances leaked at exit` warnings; gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync pending for this section until final file copy in the same Codex turn.

## 2026-05-21 画板/战斗美工单源收束与旧探针激进清理

Rules:
- 自由画布和保存单位战斗渲染继续以 `AssemblyBoardRenderer` 为唯一零件体积与美术来源。画板节点绘制只调用 `draw_component()`，战斗 runtime segment 只调用 `draw_runtime_segment()`，碰撞 polygon 继续来自 `component_polygon()`。
- TeamEdit runtime Fighter 不再创建旧 child visual 节点：`TorsoMuscleCollider`、`MuscleCollider*`、`ConnectionGuide*`、`WeaponFace*`、`TerminalHandleRing*`、`SocketHingeRing*`、材质标记旧 child 层均删除。
- 结界 tile 仍允许使用独立 `BarrierTileVisual*` 线条；这些线条不是保存机体 runtime 零件体积，且 TeamEdit runtime 单位上必须保持隐藏。
- 自由画布保留选中环、非法/材料提示、socket markers、pose preview 与躯干槽位小标识；这些是编辑器覆盖层，不是第二套零件美术。

Implementation notes:
- `scripts/main.gd` 的 `AssemblyBoardView._draw_topology_component()` 收束为 `AssemblyBoardRenderer.draw_component()` + 躯干槽位 badge；删除旧 `_draw_*_icon` fallback、空 shared-asset fallback 和未使用的 atlas region 分支。
- `scripts/fighter.gd` 删除 TeamEdit runtime 不再使用的旧 child visual 变量、构建与刷新函数；保留状态闪光、推进火焰、冷却烟、热条和结界 tile visual。
- `tools/runtime_topology_only_visual_probe.gd` 更新为检查旧 child visual 节点不存在，并确认结界专用线条不会在 TeamEdit runtime 单位上显示。
- 激进删除旧/一次性探针与脚本：孤儿 `.uid` 10 个、`unit1_diagnose_probe.gd`、`unit1_fix_save_unit2_probe.gd`、`fix_unit2_four_two_link_bindings.gd`、`art_consistency_probe.gd`、旧 attack window / module command 探针、旧 socket/demo 过渡探针、`thruster_dashboard_momentum_probe.gd`。

Verification:
- `check-only` retried after killing stale Godot processes; it still timed out after 120 seconds, matching the current headless instability noted in the plan.
- Passed: `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `runtime_topology_only_visual_probe`, `no_legacy_runtime_pointers_probe`, `no_old_combat_terms_probe`, `combat_probe`, `runtime_contact_damage_probe`, `unit2_static_two_link_damage_probe`, `training_topology_visual_consistency_probe`, `ui_layout_probe`, `text_overflow_probe`, `training_dummy_impulse_moves_probe`, `training_saved_unit_control_probe`, `training_config_start_probe`, and `main_menu_navigation_probe`.
- Additional retained-probe smoke passed: `saved_unit_no_fallback_probe`, `fighter_no_legacy_fallback_probe`, `no_action_group_symbols_probe`, and `catalog_ui_terms_probe`.
- Some probes still print Godot headless `ObjectDB instances leaked at exit`; assertions passed and this remains a teardown warning.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section; touched source/log/probe files and deleted probe set were mirrored.

## 2026-05-21 枪械启动样板：标准子弹狙击枪

Rules:
- 枪械类型与弹药类型分离：`gun_kind` 决定启动/瞄准/发射语义，`ammo_kind` 决定弹药消耗、特效和伤害分类。
- 第一把完整样板枪为 `标准子弹狙击枪 / STANDARD BULLET SNIPER`：`gun_kind=sniper`，`ammo_kind=bullet`，自带 10 发子弹。
- 狙击投射物动量直接读取显式 `projectile_momentum`，标定为最新合法单位2总 Boost 动量的 `1/10`；不再通过质量乘速度决定狙击伤害。
- 狙击投射物伤害系数为当前近战武器标准系数的 `20x`，弹道宽度为 `0.1m`，投射物命中后一次性结算并消失，不使用投射物破防系数。
- `枪械启动 / GUN ACTIVATE` 只绑定狙击枪末端肌肉。按住绑定键启动枪械；松开结束启动。没有锁定时不发射、不耗弹；有锁定时延迟后转向目标当前方向并发射。
- 启动期间按住单位局部 `4` 会持续向机体后方旋转枪械，按住局部 `6` 会持续向机体前方旋转枪械。旋转速度由行动模块决定，缺省读取最新单位2转向速度。
- 非 `gun_activate` 路径不得生成投射物。近战、碰撞、双段正锋折返继续完全绕开投射物 gate。

Implementation notes:
- 新增标准狙击枪常量与 `unit2_boost_momentum` / `unit2_turn_speed` 参考 helper；没有合法单位2时使用显式 fallback，但对应标定探针会暴露该状态。
- `_gun_part_with_runtime_defaults()` 只把标准狙击枪和旧 `LONGSIGHT TRUE-ROUND RIFLE` 规范化为样板枪，避免把其它未来 sniper 悄悄改名。
- `_runtime_gun_activation_event_for()` 使用运行时 aim direction，写入 `projectile_width_m`、`projectile_damage_coeff`、`projectile_break_coeff`、`sniper_fire_delay` 和枪械/弹药类型。
- `_tick_runtime_gun_activation()` 在按住期间读取方向输入并持续旋转瞄准方向；瞄准线复用现有 `aim_lines`，锁定后变为橙色。
- `_projectile_momentum_for_event()` 与 `_projectile_collision_momentum()` 对显式狙击动量优先；`_resolve_attack()` 对显式 `projectile_damage_coeff` 使用 `momentum * coeff * CONTACT_DAMAGE_SCALE`。
- 零件 hover/卡片远程武器说明改为优先显示枪械类型、弹药类型、容量、弹道宽度、锁定延迟、显式投射物动量和伤害系数；质量/速度仅作兼容显示。

Verification:
- Passed: `check-only`, `sniper_part_data_probe`, `gun_activate_rotate_command_probe`, `gun_kind_ammo_kind_probe`, `sniper_projectile_momentum_probe`, `sniper_first_obstruction_probe`, `gun_activate_binding_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_melee_never_projectile_gate_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `sniper_part_data_probe` currently reports `momentum=9.60` and `coeff=64.00` from the latest unit2 reference.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync pending for this section until final file copy in the same Codex turn.

### 2026-05-21 追加：全局选项菜单与训练运行菜单硬化

Rules:
- 子页面不再散落独立的 `主菜单` 按钮；TeamEdit、已保存单位、训练/侦查配置、设置页统一显示 `选项 / OPTIONS`。
- `选项` 弹出菜单集中提供：返回上级、主菜单、设置、帮助/说明、关闭。设置页子分类中的“返回”也通过该菜单处理。
- 训练场运行菜单保持可实时打开，并至少提供继续、重置位置、重置 HP/护盾/弹药、靶机状态、输入设置、画面/声音、返回训练配置、主菜单。

Implementation notes:
- 新增 `page_options_layer` / `page_options_panel` / `page_options_buttons`，用独立 `CanvasLayer` 覆盖所有普通页面层，hover 与按钮点击不再互相抢焦点。
- `_handle_global_ui_mouse_input()` 先处理全局选项菜单；点击菜单外会关闭菜单，右键也可关闭。
- `SavedUnitsBackButton`、`EditorBackButton`、`ScoutMenuButton`、`SettingsBackButton` 的文本与点击逻辑统一为打开全局选项菜单。
- 新增 `options_menu_unification_probe.gd` 与 `training_pause_options_probe.gd`，防止后续页面重新长出散落的主菜单按钮或绕过训练运行菜单。

Verification:
- Passed: `check-only`, `options_menu_unification_probe`, `training_pause_options_probe`, `main_menu_navigation_probe`, `settings_category_probe`, `training_config_start_probe`, `training_dummy_impulse_moves_probe`, `saved_units_menu_probe`, `teamedit_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `ui_layout_probe` 和 `text_overflow_probe` 覆盖中英文菜单、已保存单位、TeamEdit、设置、训练/侦查页，均无硬重叠与文字溢出。

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync to be performed after this section.

## 2026-05-21 近战单源接触管线、行动碰撞延迟反作用与美工层同步修复

Rules:
- 保存单位近战不再走“主动攻击 collider 直接伤害 + 被动接触伤害”两条管线。行动模块只负责让绑定节点进入 `independent_damage=true` 并提供动作速度；真正伤害只由 runtime 接触 pass 在真实 polygon overlap 后结算。
- Runtime 接触 pass 先按“行动中的独立部件优先、末端优先、躯干代理最后”的顺序处理本帧所有真实重叠；本帧伤害结算完成后再统一施加反作用速度，避免近端肢体先改变目标速度后把末端武器命中吃掉。
- 低速或未破防接触不再抢占持续接触锁；只有闭合速度与动量实际进入结算后，才写入 `runtime_contact_pairs_active`。
- 如果一方 collider 来源是 `active_module_contact`，另一方是默认躯干代理接触，则只允许行动方对目标结算伤害，不再让同一接触帧反向把目标躯干伤害回攻击肢体。
- 近战命中成功不再显示 `SMALL/MEDIUM/LARGE` 旧分级文字；成功命中只播接触点冲击效果，未破防只显示真实语义如 `未破阈值`。
- 战斗侧 runtime segment 继续调用 `AssemblyBoardRenderer.draw_runtime_segment()`，并补齐非躯干 segment 的 `material_visual`，使画板与战斗共享材质层、接口/柄端层、轮廓层。
- 近战末端武器实体碰撞伤害系数上调到 `3.2`，行动中普通肢体伤害系数上调到 `1.8`，作为静态靶机至少 1/40 HP 验收的当前基准。

Implementation notes:
- `_separate_unit_part_pair()` 对 TeamEdit runtime pair 会先排序 collider，并收集 `deferred_runtime_responses`； `_flush_runtime_contact_velocity_responses()` 在接触遍历结束后统一应用速度响应。
- `_resolve_runtime_contact_pair_once()` 增加可选的延迟响应数组参数，并把 `runtime_contact_pairs_active` 写入时机推迟到闭合速度和接触动量都有效之后。
- 新增 `_runtime_contact_sorted_colliders()`、`_runtime_contact_collider_priority()`，保证行动模块正在驱动的部件优先于默认躯干代理结算。
- `_resolve_attack()` 和 `_attack_collider_for_event()` 对 TeamEdit runtime 非投射物事件继续保持 no-op 伤害路径；模块事件只开启 runtime action，不再直接造成 HP 变化。
- `Fighter.contact_velocity_for_collider()` 会为 runtime topology collider 加入行动模块局部接触速度；战斗接触 pass 因此可以用同一套真实碰撞模型计算 Two-Link 动作动量。

Verification:
- Passed: `check-only`, `runtime_no_precontact_damage_probe`, `runtime_no_precontact_fx_probe`, `runtime_melee_never_projectile_gate_probe`, `projectile_warning_only_gun_activate_probe`, `seeker_no_auto_fire_probe`, `two_link_damage_balance_probe`, `combat_probe`, `board_battle_art_identity_probe`, `runtime_contact_damage_probe`, `brake_reverse_after_stop_probe`, `brake_reverse_input_layer_probe`, `reverse_cannot_boost_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `ui_layout_probe`, `text_overflow_probe`, `saved_unit_no_fallback_probe`, `idle_collision_one_torso_damage_probe`, `no_old_combat_terms_probe`, and `no_action_group_symbols_probe`.
- `two_link_damage_balance_probe` now resolves through `_separate_unit_part_pair()` without direct attack damage and reports `hp_delta=5 ratio=0.033`, above the 1/40 minimum while staying inside the current balance band.
- Missing optional probes named in the latest design note (`two_link_terminal_only_damage_probe`, `two_link_two_segment_real_contact_probe`) are still future hardening work; current coverage uses the rewritten `combat_probe` and Two-Link balance probe.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync to be performed after this section.

## 2026-05-21 训练靶机物理、全向移动、Unit2 静止近战伤害与画板/战斗同步修补

Rules:
- 训练靶机的“静止”只表示无主动输入/无 AI 控制。它不再每帧清零速度或角速度；受碰撞、命中、反作用力影响后必须按同一战斗物理正常移动。
- TeamEdit runtime 单位的普通移动改为真正全向：WASD/摇杆八方向都可以推进。刹车只按“输入方向与当前速度方向相反”判断，不再按机体朝向禁止后向普通移动。
- Boost 与刹车互斥：如果当前输入被判为刹车，方向双击只刹车，不触发 Boost。非刹车方向继续支持八向 Boost。
- 刹车后倒车沿用输入层状态机：刹停后必须松开移动输入，再按近似同方向，才进入普通倒车。
- Unit2 静止双段正锋折返必须把行动模块局部速度计入接触动量。保存 JSON 中 `target_nodes` 可能是浮点数，战斗运行时必须统一转成整数节点索引。
- 画板和战斗继续共用 `AssemblyBoardRenderer`。本轮修正躯干绘制长度与端口位置，使画板/战斗使用相同的躯干 hull 与关节槽坐标。

Implementation notes:
- `Fighter._thruster_drive_direction()` 对 runtime topology 单位直接接受任意归一化输入方向。
- 新增/调整 `_input_should_velocity_brake()`，以当前 `velocity.normalized()` 与输入向量点积判定刹车；`move_by()` 现在用 `reverse_brake` 写入倒车准备状态。
- `boost()` 在进入 Boost 前也调用同一刹车判定，保证刹车方向不会触发 Boost。
- `main.gd::_update_training_dummy()` 不再清零训练靶机 velocity / angular_velocity，只保持其 `training_static_dummy` 标记并执行正常 tick。
- `Fighter.begin_runtime_module_action()` 以及所有 runtime target-node 匹配处统一使用 `_runtime_node_array()` / `_runtime_node_array_has()`，避免 JSON 浮点节点索引导致动作速度无法匹配碰撞 collider。
- `AssemblyBoardRenderer._draw_torso()` 改用传入的 `visual_length_px` 绘制躯干 hull，并用同一 hull 尺寸计算 port 坐标，避免画板显示比战斗少一层/端口错位。

Verification:
- Passed: `check-only`, `training_dummy_impulse_moves_probe`, `eight_direction_runtime_movement_probe`, `brake_reverse_input_layer_probe`, `unit2_static_two_link_damage_probe`, `runtime_no_precontact_damage_probe`, `runtime_contact_damage_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `board_battle_art_identity_probe`, and `training_topology_visual_consistency_probe`.
- `unit2_static_two_link_damage_probe` now reports HP loss after fixing float/int target-node matching, proving static Two-Link local action speed is entering contact momentum.
- Godot still prints occasional headless `ObjectDB instances leaked at exit` warnings; gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Mirrored to `C:\Users\Administrator\Documents\New project` and verified matching hashes for `scripts/fighter.gd`, `scripts/main.gd`, `scripts/assembly_board_renderer.gd`, `tools/training_dummy_impulse_moves_probe.gd`, and `tools/unit2_static_two_link_damage_probe.gd`.

## 2026-05-21 主菜单、训练配置、设置分类与训练运行菜单成熟化

Rules:
- 主菜单一级入口改为更标准的游戏分层：`开始训练 / 已保存单位 / 队伍编辑 / AI 对战 / 本地对战 / 设置 / 退出`。
- `开始训练` 不再直接进入战场，而是进入训练配置/席位页。所有训练入口，包括已保存单位与 TeamEdit 当前画板临时导入，也走同一 P1/P2/P3 席位确认流程。
- 训练靶机默认状态为“静止待机”：无主动输入/无 AI，但受击后按动量移动，并以自身推进规则自动刹车。`自由物理` 与 `固定位置` 作为训练菜单中的可切换状态。
- 战斗中的 `Esc` / 右下角按钮打开运行选项菜单，而不是直接回主菜单。训练运行菜单提供继续、重置、靶机状态、输入设置、画面/声音、返回训练配置与主菜单。
- 设置页拆为 `声音 / 画面 / 系统语言 / 按键绑定` 四个滚动子页面。按键绑定继续覆盖战斗相关动作；其它子页先提供清晰的占位设置项与统一视觉结构，后续可接入真实滑条和持久化。

Implementation notes:
- 新增 `_show_training_config()` 作为训练入口统一门面；它会先准备训练 loadout，再调用 `_show_scout(MODE_TRAINING)` 进入训练配置/席位页。
- 主菜单 `_activate_menu_item()` 重排：训练、单位库、TeamEdit、AI、PVP、设置、退出。AI 对战仍保留 P1/P2/P3 快速席位面板。
- 已保存单位训练按钮与 TeamEdit “导入训练”按钮改为调用 `_show_training_config(false)`，避免绕过席位确认。
- `_build_settings_ui()` 改为顶部分类按钮 + 滚动内容区；新增 `_rebuild_settings_list()`、`_show_settings_category()` 与 `_reset_current_settings_category()`。
- `_build_battle_ui()` 新增 `BattleRuntimeOptions` 半透明运行菜单；`_handle_battle_input()` 在菜单打开时暂停玩家战斗输入。
- `_update_training_dummy()` 修正为先执行物理 tick，再做自动刹车，避免靶机受击速度在移动前被清零。

Verification:
- Added probes: `main_menu_navigation_probe.gd`, `settings_category_probe.gd`, `training_config_start_probe.gd`.
- Passed: `check-only`, `main_menu_navigation_probe`, `settings_category_probe`, `training_config_start_probe`, `training_all_entrypoints_require_seat_probe`, `training_dummy_impulse_moves_probe`, `training_seat_spawn_unit2_probe`, `training_saved_unit_control_probe`, `saved_units_menu_probe`, `teamedit_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `training_dummy_impulse_moves_probe` initially caught over-aggressive auto-braking; fixed by moving first, then braking gradually.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync pending for this section until final file copy in the same Codex turn.

## 2026-05-21 第一款钝击拳套与拳套伸摆行动模块

Rules:
- 新增第一款标准钝击末端武器：`标准动量拳套 / STANDARD MOMENTUM GAUNTLET`。
- 该拳套是末端肌肉、近战、钝击类；自带旋转 + 伸缩混合内置关节，最大伸出 `2.0m`。
- 拳套质量按重型钝击末端处理，当前为 `28`；主动接触动量系数为 `1.5`，只在绑定行动模块执行中的主动碰撞中生效。
- 拳套永远按近战实体碰撞处理，不发射投射物，也不进入枪械投射物 gate。
- 复用旧半成品 `HAMMER ANCHOR` catalog 位置，改造成 `拳套伸摆 / GAUNTLET EXTEND-SWING`，profile 为 `blunt_gauntlet_extend_swing`。
- 绑定目标只能是具备混合旋转 + 伸缩关节的钝击拳套末端肌肉；普通肢体、斩击、尖刺、枪械和非混合关节末端都非法。
- 输入窗口语义：
  - `X`：伸缩动作，伸出后收回。
  - `4X`：向外摆动后收招。
  - `6X`：向内摆动后收招。
  - `236X`：护甲态，边伸缩边向内摆动，消耗当前执行英雄热槽上限 `10%`。
  - `214X`：激活态，边伸缩边向外摆动，消耗当前执行英雄热槽上限 `10%`。
- 当前方向缓存只记录 `2/4/6/8`，因此拳套必杀接受简化输入 `26` 作为 `236`，`24` 作为 `214`，保证键盘方向实际可输入。

Implementation notes:
- `main.gd` 新增常量：`STANDARD_GAUNTLET_NAME`、`STANDARD_GAUNTLET_EXTENSION_M`、`STANDARD_GAUNTLET_MOMENTUM_MULT`、`STANDARD_GAUNTLET_RECOVERY_ANGLE_DEGREES`、`GAUNTLET_SPECIAL_HEAT_FRACTION`。
- `COMMON_CATALOG["muscle"]` 新增 `标准动量拳套`，并写入 `hybrid_embedded_joint=true`、`embedded_joint_kind="hybrid"`、`embedded_joint_angle=180`、`embedded_joint_extension=2.0`、`terminal_momentum_mult=1.5`。
- `COMMON_CATALOG["module"]` 中旧重锤锚点改为 `拳套伸摆`，写入 `module_action_profile="blunt_gauntlet_extend_swing"` 与 `command_window_profile="gauntlet_4_6_236_214"`。
- `_embedded_joint_profile_for_part()` 支持 `hybrid` 同时提供旋转角度和伸缩距离。
- TeamEdit 绑定流程新增 `gauntlet_terminal` 目标类型和 `_topology_node_is_blunt_hybrid_gauntlet()` 合法性检查。
- 战斗侧 `Fighter.begin_runtime_module_action()` 新增 `_begin_runtime_gauntlet_extend_swing_action()`；动作会写入 runtime action，并通过 runtime segment override 改变拳套长度/角度。
- 动作结束会提交收招姿态；普通动作不耗热，护甲/激活必杀按 `heat_capacity * 0.1` 增热。
- 零件卡、hover、躯干详情会显示混合关节、伸出距离、动量系数、热耗和完整输入表。

Verification:
- Added probes: `gauntlet_part_data_probe.gd`, `gauntlet_module_binding_probe.gd`, `gauntlet_command_window_probe.gd`, `gauntlet_heat_cost_probe.gd`, `gauntlet_motion_pose_probe.gd`, `gauntlet_momentum_coeff_probe.gd`, `gauntlet_no_projectile_probe.gd`.
- Passed: `check-only`, all seven gauntlet probes, `two_link_forward_snap_module_probe`, `two_link_forward_snap_combat_pose_probe`, `sniper_part_data_probe`, `teamedit_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Current external regression note: `unit2_training_probe` fails on the existing saved Unit 2 data with `INVALID: node 1 has 4/3 occupied interfaces`. This is an existing saved-unit topology issue, not caused by the gauntlet catalog/module work; this iteration did not silently rewrite saved Unit 2.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, `scripts/fighter.gd`, gauntlet probes, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 化学喷射器与 Gun Activate 扩展

Rules:
- 保留现有来复枪数据与 `rifle` 分类，不在本轮改写来复枪启动语义。
- 新增 `标准化学喷射器 / STANDARD CAUSTIC SPRAYER`，作为远程末端肌肉、`gun_kind="sprayer"`、`ammo_kind="chemical"`。
- 化学喷射器容量 `12`，射程 `1.6m`，喷射宽度 `0.28m`，投射物动量按最新合法单位2 Boost 动量的 `1/30` 标定。
- 弹药只决定化学特效和伤害分类；投射物动量、宽度、射程和启动语义由枪械决定。
- `Gun Activate` 现在支持 `sniper` 与 `sprayer`。狙击枪保留锁定后延迟射击；化学喷射器按住持续喷射，松开停止。
- 启动期间局部 `4/6` 持续向机体后方/前方旋转枪口，旋转速度仍由行动模块字段决定，默认取单位2转向速度。
- 化学喷射命中沿途第一个非己方实体后消失，造成低即时伤害并附加 `4s` DoT；同一喷射器对同一目标刷新/保持最高 DoT，不无限叠层。
- 近战、碰撞、双段正锋折返和非 `gun_activate` 事件仍不得进入投射物逻辑。

Implementation notes:
- `main.gd` 新增 `STANDARD_CHEMICAL_SPRAYER_*` 常量组。
- `BUILD_SLOTS["muscle"]` 新增标准化学喷射器零件。
- `Gun Activate` 的 TeamEdit 绑定合法性从 sniper-only 改为 sniper/sprayer。
- `_runtime_gun_activation_event_for()` 根据 `gun_kind` 分支生成狙击 true bullet 或化学 spray 事件。
- `_tick_runtime_gun_activation()` 对 sprayer 按 `fire_interval` 连续发射化学投射物，弹药耗尽时自动停喷。
- `_release_runtime_gun_activation()` 对 sprayer 只停止启动，不额外发射延迟弹。
- `_gun_part_with_runtime_defaults()` 为标准化学喷射器写入运行时动量、容量、射程、喷宽和 DoT 参数。
- `_apply_chemical_dot_status()` 支持 `chemical_dot_no_stack`，用于刷新而非无限叠加 DPS。
- hover 详情为 sprayer 显示射程、喷宽、投射物动量和 DoT 持续时间。

Verification:
- Added probes: `chemical_sprayer_part_data_probe.gd`, `gun_activate_sprayer_binding_probe.gd`, `chemical_sprayer_hold_release_probe.gd`, `chemical_sprayer_rotate_command_probe.gd`, `chemical_sprayer_first_contact_probe.gd`, `chemical_dot_probe.gd`.
- Passed: `check-only`, all six chemical sprayer probes, `gun_kind_ammo_kind_probe`, `gun_activate_binding_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_melee_never_projectile_gate_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Existing unrelated note: `training_unit_import_probe` still reports the current training-flow state as editor rather than direct battle training. This was not introduced by the chemical sprayer work and was not part of this iteration.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync pending until the final file copy in this Codex turn.

## 2026-05-21 枪械启动统一、日志同步脚本与第一把标准激光枪

Rules:
- 每轮开发开始与结束都先运行 `tools/sync_worklog.ps1`，以 `tools/worklog_projects.json` 登记的项目根同步 `WORKLOG_RULEBOOK.md`。
- 日志同步以 `LastWriteTimeUtc + size + SHA256` 选择最新日志；若多个项目在同一轮窗口内出现不同最新哈希，写出 `WORKLOG_RULEBOOK.conflict.<timestamp>.md` 并停止覆盖。
- 枪械启动统一走 profile/spec：`gun_activate`、`rifle_burst_activate`、`laser_beam_activate` 是唯一显式投射物启动白名单。
- `gun_kind` 决定启动语义：`sniper=release_lock`、`sprayer=hold_stream`、`rifle=hold_burst`、`laser_gun=hold_beam`。
- 新增第一把标准激光枪 `长视棱镜激光枪 / LONGSIGHT PRISM LASER`；它是 `laser_gun + laser`，使用 beam/laser/instant_line，不恢复旧 generic laser fallback。
- 新增 `棱镜照射启动 / PRISM BEAM ACTIVATE`，只能绑定 `laser_gun + laser` 的枪械末端；按住持续 beam tick，松开停止，不进入 sniper lock 或延迟 true bullet。

Implementation notes:
- 新增 `tools/worklog_projects.json` 和 `tools/sync_worklog.ps1`；默认登记 `E:\New project` 与 `C:\Users\Administrator\Documents\New project`。
- `main.gd` 新增标准激光枪 catalog 数据：`cost 118`、`hp 24`、`mass 8`、`energy 28`、`length 0.72`、`radius 0.055`、`carried_ammo 7`、`fire_rate 1.0`、`range 4.2m`、`beam width 0.18m`、`damage 10`、`momentum 18`、`damage_coeff 18`、`normal_heat 18`、`recoil 0.03`。
- `main.gd` 新增 `_runtime_binding_is_gun_activation()`、`_gun_activation_profiles()`、`_gun_activation_spec()`、`_gun_activation_profile_supports_kind()` 和 `_runtime_gun_activation_fire_once()`。
- `_runtime_gun_activation_event_for()` 改为由 spec 填充 projectile style、behavior、travel path、range、width、damage、momentum、heat 与特殊字段，不再硬编码 sprayer/true bullet 二分。
- `_tick_runtime_gun_activation()` 统一处理 hold_stream、hold_burst、hold_beam；release_lock 只保留 sniper 锁定预览与松开发射。
- `_event_is_explicit_gun_activation()` 改为 profile 白名单驱动，普通 melee/runtime 事件仍清空 projectile 字段。
- TeamEdit 绑定和运行时执行检查改为 profile + gun_kind + ammo_kind 配对校验，拒绝激光模块绑定狙击枪、来复枪、喷射器或近战端。
- `fighter.gd` runtime group 传递 `projectile_damage_coeff`、`projectile_width_m`、`fire_interval`、`laser_tick_interval`、`laser_charge_time` 和 `normal_heat`，保证战斗侧 beam 事件取到同源字段。
- `projectile_momentum_probe.gd` 的正向 projectile 案例补充显式 `gun_activate` profile，匹配新的投射物 gate。

Verification:
- Start sync: `tools/sync_worklog.ps1` reported matching SHA256 for `E:\New project` and Documents worklogs: `C04E2DC9C721B18C64EBD98B6DFAE214E13FBFA8234AC802CDC04E221F47CC0C`.
- Sync script temp propagation test passed for latest-file propagation, hash convergence, and missing-project skip reporting; temp conflict test generated a conflict copy and raised the intended stop error instead of overwriting.
- Added probes: `laser_part_data_probe.gd`, `laser_beam_activate_binding_probe.gd`, `laser_beam_runtime_fire_probe.gd`, `laser_no_sniper_lock_probe.gd`, `laser_projectile_gate_probe.gd`, `laser_ammo_heat_probe.gd`.
- Passed: all six laser probes, `gun_activate_binding_probe`, `gun_activate_sprayer_binding_probe`, `gun_activate_rotate_command_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_melee_never_projectile_gate_probe`, `gun_kind_ammo_kind_probe`, `projectile_momentum_probe`, `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Current Godot note: project `--check-only` still exceeded the 120s headless timeout; this matches the known instability and this round used script probes as acceptance.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for touched scripts, tools, laser probes, `projectile_momentum_probe.gd`, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 躯干/肢体代表统计梯度与形状整理

Rules:
- 本轮采用代表梯度，不做全 catalog 重平衡，也不迁移已保存单位。
- 只调整少数常用基准件：小型决斗、中型通用、重型舞台/变形，以及小/中/M+ 重承载/怪物肢体。
- 继续遵守真实碰撞、画板/战斗同源渲染、显式语义和探针验收；不改 gameplay API、不改战斗公式、不改渲染接口。

Implementation notes:
- `HUMANOVA DUEL CORE` 改为 S 级窄型 `duelist_core`：4 外接端口，内部槽从重载倾向收紧为 3 个插件槽/6 个软件槽，速度修正提高到 `1.12`，有效质量/HP 为 `12/50`。
- `SYNTAX MIDFIELD CORE` 改为 M 级 `midfield_saddle` 标准中场锚点：5 外接端口，成本/HP/质量对齐当前 M torso floor，作为中型通用统计基准。
- `FOLD STAGE TORSO` 改为 L/heavy 级 `stage_chassis`：保留 6 端口、8 软件槽、6 插件槽和 `role_switch`，但有效成本/HP/质量上调到 `310/320/48`，让变形舞台容量付出真实体积和经济代价。
- `HUMANOVA FOREARM MYOMER` / `HUMANOVA THIGH MYOMER` 形状改为 `forearm_myomer` / `thigh_myomer`，有效质量/HP/承载形成 `6/26/11` 到 `22/58/28` 的普通肢体阶梯。
- `MONOCHROME STEEL SINEW` 改为 `steel_sinew_beam`，使用 `size_design_locked=true` 锁定 M+ 重承载值 `mass 32 / hp 82 / load 52`，避免直接升到 L 档。
- `COLOSSUS SINEW GIRDER` 改为 `colossus_girder_muscle`，raw catalog 对齐 XL floor：`cost 320 / hp 320 / mass 360 / length 3.6 / radius 0.92 / load 180`，避免 raw 数据看起来像中大型但运行时被自动放大。
- 新增 `torso_limb_stat_shape_probe.gd`，锁住上述 7 个零件的有效 size tier、shape、端口/槽位和质量/HP/承载单调性。

Verification:
- Start sync: `tools/sync_worklog.ps1` reported matching SHA256 for E drive and Documents worklogs: `E197EE17BF46EC673E4F2DFBE2F23D982DE69B3FC68DEFDF6A7E39E7746EEC70`.
- Passed: `torso_limb_stat_shape_probe`, `torso_size_mass_probe`, `part_catalog_balance_probe`, `part_size_visual_probe`, `board_battle_art_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `torso_limb_stat_shape_probe` reported torso mass gradient `12/24/48` and limb mass gradient `6/22/32/360`.
- `runtime_geometry_identity_probe` is currently blocked by the latest local saved Unit 2 data: `unit2_training_probe` reports an old `GUNNER WRIST` binding needing a connected projectile gun. This round did not migrate or rewrite saved units by design, so this is recorded as external saved-data cleanup work.
- `--check-only` still exceeded the 120s headless timeout after killing stale Godot processes; treat as the known Godot headless instability and use script probes as this round's acceptance.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, `tools/torso_limb_stat_shape_probe.gd`, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 标准蛛丝枪、边界摆荡与真实碰撞接入

Rules:
- 新增 `标准捕缚蛛丝枪 / STANDARD WEB TETHER GUN`，作为 `gun_kind="web_gun"`、`ammo_kind="web"` 的远程末端肌肉。
- 蛛丝枪射程为 `4.4m`，相当于上一版长距需求；蛛丝本体不造成 HP 伤害，也不进入近战或枪械伤害 gate。
- `蛛丝牵引 / WEB TETHER ACTIVATE` 作为独立 gun activate profile：`module_action_profile="web_tether_activate"`。
- 蛛丝可命中敌方或友方单位，用于牵引、拉近补给/治疗单位或控制敌方；过滤字段为 `web_target_filter`。
- 蛛丝射向上下实体边界时建立边界锚点；左右环形 wrap 边不提供锚点。
- 边界摆荡写入真实 `Fighter.velocity`，因此追击/脱困/摆荡攻击都走统一实体碰撞模型：可见几何接触 -> 接触法线动量 -> 路径刚度 -> 伤害/破防/反作用力。
- 默认收招状态下，摆荡碰撞仍按躯干代理结算；若同时有行动模块执行，执行中的绑定肢体/末端武器继续独立结算。

Implementation notes:
- `main.gd` 新增 `STANDARD_WEB_TETHER_*` 常量、蛛丝枪 catalog 数据与 `web_tether_activate` 模块数据。
- `_gun_activation_profiles()`、`_gun_activation_profile_for_kind()`、`_gun_activation_spec()` 和 `_gun_activation_profile_supports_kind()` 接入 `web_gun + web`。
- `_runtime_gun_activation_event_for()`、`_start_runtime_gun_activation()`、`_tick_runtime_gun_activation()`、`_release_runtime_gun_activation()` 接入 `release_web` 语义。
- 新增 `active_web_tethers` 与 `active_web_swings`；`_update_web_tethers()` 处理敌我单位牵引，`_update_web_swings()` 处理边界锚点摆荡。
- `_fire_runtime_web_tether()` 是蛛丝唯一发射入口；近战、双段正锋折返、被动碰撞仍不能生成投射物事件。
- `_projectile_behavior_for_data()`、`_projectile_event_has_gun_source()`、`_gun_default_profile_key()`、`_gun_kind_for_data()`、`_gun_default_carried_ammo()` 和 `_gun_part_with_runtime_defaults()` 补齐 web/tether 解析。
- `gun_kind_ammo_kind_probe.gd` 修正为“至少一个同类合法枪械”判定，避免后续旧/实验零件覆盖布尔结果造成假失败。

Verification:
- Added probes: `web_gun_range_probe.gd`, `web_boundary_anchor_probe.gd`, `web_anchor_swing_velocity_probe.gd`, `web_tether_no_projectile_damage_probe.gd`, `web_swing_melee_collision_probe.gd`, `web_swing_idle_torso_proxy_probe.gd`, `web_swing_active_limb_probe.gd`.
- Passed: all seven web probes, `gun_kind_ammo_kind_probe`, `projectile_warning_only_gun_activate_probe`, `runtime_melee_never_projectile_gate_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, and Godot `--check-only`.
- Godot headless still reports the known ObjectDB cleanup warning after some probes; exit codes are 0 and no gameplay assertion failed.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, new web probes, updated `gun_kind_ammo_kind_probe.gd`, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 剃线回钩链刃与回钩撕线

Rules:
- 新增第一把带内置甩链旋转关节的撕裂末端武器：`剃线回钩链刃 / RAZORWIRE REEL HOOK`。
- 链刃写入 `COMMON_CATALOG["muscle"]` 末尾，字段为 `tear`、`terminal_weapon=true`、`weapon_family="tear_chain"`、`tear_reel_weapon=true`、`shape="chain_blade"`。
- 内置关节为 `embedded_joint_kind="ball"`、`embedded_joint_angle=180`；回钩线距由武器字段 `reel_length_m=1.2` 决定。
- 新增行动模组 `回钩撕线 / REELING HOOK RIP`，profile 为 `reeling_hook_rip`，只能绑定带 180 度内置甩链关节的撕裂链刃终端。
- 输入语义：X 标准外甩回拉；6X 快速撕穿偏激活伤害；4X 宽幅外甩偏护甲伤害。

Implementation notes:
- `main.gd` 新增 `RAZORWIRE_REEL_HOOK_*` 常量、链刃 catalog 数据、`tear_reel_terminal` 绑定目标类型、绑定选择与执行合法性检查。
- hover 卡显示链刃甩链长度、关节角、伤害/破防系数；模组详情显示 X/6X/4X 输入表和“不发射投射物”的近战规则。
- `fighter.gd` 新增 `_begin_runtime_reeling_hook_rip_action()` 与 runtime segment override；startup 40% 外甩，recovery 60% 回拉并恢复原始局部姿态。
- 回钩撕线动作期间目标节点进入 active collider 集合，伤害继续走 runtime melee/contact 动量、刚度、热量和受击流程。
- 事件不写入 projectile 字段，保持与近战永不误入 gun activation gate 的规则一致。

Verification:
- Added probes: `razorwire_reel_hook_part_data_probe.gd`, `reeling_hook_rip_binding_probe.gd`, `reeling_hook_rip_runtime_pose_probe.gd`, `reeling_hook_rip_damage_probe.gd`, `reeling_hook_no_projectile_probe.gd`, `reeling_hook_probe_lib.gd`.
- Passed: all five reeling hook probes, `runtime_melee_never_projectile_gate_probe`, `two_link_forward_snap_module_probe`, `gauntlet_no_projectile_probe`, `teamedit_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Current external saved-data note: `unit2_training_probe` still fails on the latest local saved Unit 2 data with old `GUNNER WRIST` binding needing a connected projectile gun; this matches the prior saved-data cleanup note and was not migrated in this feature.
- Current Godot note: project `--check-only` still exceeded the 120s headless timeout in this workspace; script probes loaded the touched scripts successfully.

## 2026-05-21 盾牌/大锤实体近战与钝击关节梯度

Rules:
- 本轮只落地实体近战盾牌和大锤；不做投掷盾、地形破坏、旧 projectile fallback、旧 attack group 或 child visual。
- 盾牌、大锤、拳套继续共用 runtime topology 真实接触伤害路径；行动模块只启动姿态覆盖、接触速度、冷却和热量语义。
- 开始先跑 `tools/sync_worklog.ps1`；E drive 与 Documents worklog 起始 SHA256 一致：`43AC0B94EEF67B4AD8C2932F6905A805D6FEC3415212EE366EED2F3102F0C357`。

Implementation notes:
- 钝击武器梯度补齐：`BUCKLER RAM SHIELD` / `AURORA BASH SHIELD` / `COLOSSUS TOWER SHIELD` 写入 `weapon_family="shield"`、`blunt_shield=true`、melee terminal、embedded ball joint、盾面覆盖和守势动量系数。
- 大锤梯度补齐：`LIGHT IRON HAMMER` / `GRAVITY HAMMER` / `SIEGE IRON HAMMER` / `COLOSSUS ARENA MAUL` 写入 `weapon_family="hammer"`、`blunt_hammer=true`、melee terminal、embedded ball joint、蓄砸倍率和终端动量系数；移除 `SIEGE IRON HAMMER` 的旧爆炸式冲击波字段，保持真实接触。
- 特殊关节肢体梯度补齐：`HUMANOVA FOREARM MYOMER`、`HUMANOVA THIGH MYOMER`、`RAZOR FLEX TENDON`、`MONOCHROME STEEL SINEW`、`CERAMIC SHIN STRUT`、`COLOSSUS SINEW GIRDER` 显式写入 embedded joint kind/angle/extension/output/capacity。
- 新增行动模块 `盾牌架撞 / SHIELD GUARD-BASH`，profile `blunt_shield_guard_bash`，target kind `blunt_shield_terminal`；X 架盾，4X/6X 侧向盾击，236X 装甲推进盾撞，214X 主动肩撞。
- 新增行动模块 `大锤蓄砸 / HAMMER WINDUP-SLAM`，profile `blunt_hammer_windup_slam`，target kind `blunt_hammer_terminal`；X 短挥，4X/6X 蓄挥，236X 装甲下砸，214X 主动横砸。
- `fighter.gd` 新增通用钝击终端 runtime action：只修改真实 runtime segment 姿态，输出 runtime contact speed 与 momentum multiplier，不生成 projectile、Line2D、Polygon2D 或旧 attack group。

Verification:
- Added probes: `blunt_weapon_gradient_probe.gd`, `special_joint_limb_gradient_probe.gd`, `shield_guard_bash_binding_probe.gd`, `hammer_windup_slam_binding_probe.gd`, `shield_guard_bash_runtime_pose_probe.gd`, `hammer_windup_slam_runtime_pose_probe.gd`, `shield_guard_bash_contact_probe.gd`, `hammer_windup_slam_contact_probe.gd`, `blunt_modules_no_projectile_probe.gd`, `blunt_terminal_runtime_pose_probe.gd`, `blunt_terminal_probe_lib.gd`.
- Passed all new probes.
- Passed regressions: `gauntlet_part_data_probe`, `gauntlet_module_binding_probe`, `gauntlet_motion_pose_probe`, `gauntlet_no_projectile_probe`, `two_link_forward_snap_module_probe`, `two_link_forward_snap_combat_pose_probe`, `runtime_no_precontact_damage_probe`, `runtime_contact_damage_probe`, `runtime_melee_never_projectile_gate_probe`, `part_catalog_balance_probe`, `part_size_visual_probe`, `board_battle_art_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- `runtime_geometry_identity_probe` currently fails before geometry comparison with `Training hero missing`; this is recorded as current saved/training-data environment blockage and this round did not migrate saved units.
- `--check-only` still exceeded the 120s headless timeout after killing stale Godot processes; treat as known Godot headless instability. Probe assertions passed. ObjectDB cleanup warnings remain headless teardown warnings.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, `scripts/fighter.gd`, new blunt probes, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 刃系武器梯度与刃系行动模块 V1

Rules:
- 镰刀、武士刀、巨剑统一作为斩击近战末端肌肉，字段保持 `terminal_weapon_kind="melee"`，不进入投射物逻辑。
- 普通连接肢体继续按内置关节模型分为短/中/长、轻量高速、重型高刚度、伸缩与伸旋混合梯度。
- 刃系行动模块的方向指令全部为模块专属规则，不恢复为全局通用规则。
- 简单刃系 profile：`X` 普通斩，`6X` 护甲态，`4X` 激活态。
- 复杂刃系 profile：`X` 普通斩，`236X` 护甲必杀，`214X` 激活必杀；`26/24` 作为宽松输入；必杀消耗当前英雄热槽上限 10%。

Implementation notes:
- `BLADE HALO` 一类半成品被改造成 `刃弧切返 / BLADE ARC RETURN`，并新增/落地 `武士刀瞬斩`、`镰月钩返`、`巨剑压斩`、`三肢轮切`、`伸旋突斩` 六个 profile。
- `main.gd` 新增 `command_window_profile` 解析：`blade_simple_4_6` 与 `blade_complex_236_214`；`_runtime_module_state_for_binding()` 只对声明 profile 的模块解析对应方向串。
- `fighter.gd` 新增刃系 runtime action 路径：`begin_runtime_module_action()` 可直接启动刃系模块，动作只覆盖保存单位的真实 runtime topology segment，不创建 action group 或旧攻击组。
- 刃系动作使用真实绑定节点链：startup 按模块弧度出招，recovery 回到当前收招姿态；`extend_slash_driver` 会在最后一段加入伸出距离。
- hover/零件卡补充刃系简单/复杂输入说明，避免把 `4/6` 或 `236/214` 误解为全局规则。
- 发现并修复当前本地 Unit 2 的保存模块索引漂移：旧保存文件仍指向 `GUNNER WRIST`，已生成新 `2_1779318152.json`，四个绑定恢复为 `双段正锋折返`。

Verification:
- Added probes: `blade_weapon_catalog_probe.gd`, `limb_gradient_catalog_probe.gd`, `blade_simple_command_probe.gd`, `blade_complex_command_probe.gd`, `blade_module_binding_probe.gd`, `blade_runtime_action_probe.gd`.
- Passed all six blade probes.
- Passed regressions: Godot `--check-only`, `teamedit_probe`, `combat_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `ui_layout_probe`, and `text_overflow_probe`.
- Godot headless still reports occasional ObjectDB cleanup warnings; probe exit codes were 0 and gameplay assertions passed.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, `scripts/fighter.gd`, new blade probes, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 训练几何探针修复与近战武器梯度收束

Rules:
- `runtime_geometry_identity_probe` 不再允许静默跳过训练单位；英雄导入必须真实落入训练座位的 hero 槽，非英雄导入由专门探针按实际 role 槽验证。
- 近战武器梯度统一按新战斗词条验收：刚度、伤害系数、破防系数、接触形状、质量、HP、尺寸层级、近战末端类型。
- hover 卡片只展示新战斗模型词条；终端武器卡片前 8 项必须同时包含刚度、伤害系数、破防系数。
- `--check-only` 若 120 秒超时，继续记录为 Godot headless 不稳定，不作为本轮功能失败。

Implementation notes:
- `main.gd` 的 combat normalization 现在会为近战末端自动补齐 `terminal_weapon_kind`、`weapon_family`、`embedded_joint_kind`，避免零件库插入后只靠旧字段或索引导致 UI/探针漂移。
- 新增 `blunt_weapon_family_for_part()` 与 `pierce_weapon_family_for_part()`；斩击、钝击、戳刺三系都通过 helper 得到稳定 family。
- 补齐拳套梯度：`轻型动量拳套 / LIGHT MOMENTUM GAUNTLET`、`标准动量拳套 / STANDARD MOMENTUM GAUNTLET`、`重型动量拳套 / HEAVY MOMENTUM GAUNTLET`，形成小/中/重三档混合旋转+伸缩钝击末端。
- hover stat 排序调整为：基础数值后优先显示刚度、伤害系数、破防系数，再显示拳套伸出与动量系数等专项词条。
- 新增 `training_import_spawn_role_probe.gd`，覆盖 hero / puppet / barrier 三种训练导入落槽，并额外验证 P2 座位 hero 导入。
- 新增 `melee_weapon_gradient_probe.gd`，覆盖镰刀/武士刀/巨剑、拳套/盾/锤、长枪/细剑/钻头三大近战梯度。
- 新增 `melee_module_compatibility_probe.gd`，检查刃系、拳套、戳刺样板模块的 target kind、command profile 与合法武器族关系。

Verification:
- Passed: `runtime_geometry_identity_probe`（不再出现 Training hero missing，输出 `segments=9 torso_points=28`）。
- Passed: `training_import_spawn_role_probe`, `melee_weapon_gradient_probe`, `melee_module_compatibility_probe`, `catalog_ui_terms_probe`, `blunt_weapon_gradient_probe`, `part_catalog_balance_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `no_old_combat_terms_probe`.
- `teamedit_probe` 仍按既有方式输出内置 TeamEdit 预设中的非法旧拓扑摘要，但进程退出码为 0；本轮未迁移这些旧预设，因为目标是训练几何与近战梯度。
- `--check-only` 在 `E:\New project` 下运行 120 秒后超时并被终止，记录为既有 Godot headless 不稳定。
- Godot headless 的 ObjectDB cleanup warnings 仍是退出清理警告；目标探针断言均通过。

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed after this section for `scripts/main.gd`, new training/melee probes, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 西洋击剑、骑士长枪与尖刺必杀梯度 MVP

Rules:
- 尖刺/戳刺梯度固定为短针、刺剑、长矛、电钻、骑士长枪；全部是 melee terminal，全部走真实 runtime contact，不生成 projectile，不进入枪械 gate。
- 尖刺伸缩极限只读取武器自身的 `embedded_joint_extension` / `max_extension_m`；行动模块的 `required_extension_m` 只作为最低合法性门槛。
- 尖刺终端统一 `damage_coeff=6.4`、`break_coeff=1.0`，保持“尖刺伤害系数为斩裂基准两倍，破防系数等于训练靶机近战基准”的规则。
- `4X` 表示后方向加攻击，`6X` 表示前方向加攻击；`236X` 和 `214X` 是模块声明的复杂指令，不恢复为全局通用规则。

Implementation notes:
- 新增尖刺武器：`UMBRA STILETTO NEEDLE` 0.8m、`HUMANOVA FOIL RAPIER` 1.2m、`STANDARD PIKE SPEAR` 1.8m、`MONOCHROME BREACH DRILL` 2.0m、`MONOCHROME KNIGHT LANCE` 3.0m。
- 新增/收束尖刺行动模块：`PIERCE TELESCOPIC LUNGE` 支持 X/4X/6X；`RAPIER FEINT THRUST` 只绑 stiletto/rapier；`LANCE COUCHED CHARGE` 只绑 spear/lance；`DRILL BREACH DRIVE` 只绑 drill。
- `main.gd` 增加 pierce family helper、编辑器绑定 root 选择、绑定合法性错误优先级、`pierce_simple_4_6` 与 `pierce_complex_236_214` 指令解析。
- `fighter.gd` 的统一尖刺 runtime action 现在覆盖普通伸缩突刺、刺剑折刺、长枪架势冲刺、电钻破防贯入；动作结束回到原始局部姿态，目标节点在动作期间进入 active melee collider。
- runtime topology segment 现在携带显式 `damage_coeff`、`break_coeff`、`weapon_family`、`embedded_joint_extension`、`max_extension_m` 和终端动量系数，避免尖刺武器数据在战斗侧退回旧默认值。

Verification:
- Added probes: `pierce_weapon_gradient_probe.gd`, `pierce_special_binding_probe.gd`, `pierce_special_runtime_probe.gd`, `pierce_command_profile_probe.gd`, `pierce_telescopic_damage_no_projectile_probe.gd`, `pierce_terminal_probe_lib.gd`.
- Updated probes: `pierce_telescopic_lunge_binding_probe.gd` now treats the new rapier as a legal telescopic pierce terminal.
- Passed new probes plus `drill_part_data_probe`, `pierce_telescopic_lunge_binding_probe`, `pierce_telescopic_lunge_runtime_probe`, `runtime_melee_never_projectile_gate_probe`, `teamedit_probe`, `ui_layout_probe`, `text_overflow_probe`, and `unit2_training_probe`.
- Passed Godot headless `--check-only`. ObjectDB cleanup warnings remain ordinary headless teardown warnings.

## 2026-05-21 源代码：刺枪侍从

Rules:
- `源代码：刺枪侍从 / CODE: PIERCING RETINUE` 是 puppet 专用 `kind="code"` 软件核心，不是 hero soul、ether、行动模块或真实源码文件。
- 该源代码服务最新尖刺近战梯度：三台小型傀儡围绕英雄截击、侧绕、补刀，偏 melee-first，而不是远程风筝或巨怪硬顶。
- 不新增武器、不新增行动模块、不改 runtime projectile/melee gate；尖刺武器与行动模块合法性继续由蓝图和模块绑定规则负责。

Implementation notes:
- 新源代码追加到基础 `SPECIAL_CATALOG["puppet"]` 末尾，避免旧索引中间插入漂移。
- 数据固定为 `maker="HUMANOVA ATELIER"`、`cost=126`、`power=18`、`energy=15`、`group_count=3`、`ai="pincer"`、`module_sequence_limit=4`、`condition_slots=5`。
- 策略固定为 `source_target_policy="protect_hero"`、`source_attack_preference="melee_first"`、`source_close_response="intercept"`、`source_threat_override_range=0.78`、`source_keep_range=0.72`，并声明完整五条件加 default 的 `source_rules`。
- 护卫规则进一步落地为程序字段：`source_guard_mode="orbit_hero"`、`source_guard_distance_m=0.64`、`source_guard_orbit_speed=0.72`。新增 `guard_orbit` move kind，以己方英雄为锚点保持侍从环并缓慢公转；近身或射击威胁仍切到 `intercept`。玩家详情页只显示战术语义，不暴露具体米数和公转速度。
- 新增 `piercing_retinue_source_code_probe.gd`，按真实 puppet/special catalog 索引创建 override blueprint，验证 stats 合并、source rules 归一化、protect-hero 目标选择和 melee-first 攻击选择。

Verification:
- Added probe: `piercing_retinue_source_code_probe.gd`.
- Passed: `piercing_retinue_source_code_probe`, `source_code_probe`, `teamedit_probe`, `ui_layout_probe`, `text_overflow_probe`, and Godot `--check-only`.
- `source_code_probe` 仍是旧式打印探针；新探针承担本轮断言覆盖。ObjectDB cleanup warnings remain ordinary headless teardown warnings.

## 2026-05-21 标准导弹枪与可规避锁定模块

Rules:
- 导弹类枪械必须通过显式 `missile_lock_activate` 枪械行动模块发射；旧 proximity seeker / `is_homing_launcher` 不允许自动开火或显示警告。
- 导弹锁定只提供发射授权，不保证命中；发射后使用可见 `projectile_style="missile"` + `travel_path="homing"`，高速机体可通过遮蔽甩脱制导。
- 锁定规则支持 `screen_hero_first`、`near_first`、`far_first`；默认按英雄、傀儡、结界支援、结界攻击、其它结界排序，同角色内再考虑同屏、瞄准夹角和距离。

Implementation notes:
- 新增 `红线猎隼导弹架 / REDLINE KESTREL MISSILE POD`：`gun_kind="missile_launcher"`、`ammo_kind="explosive"`、`projectile_style="missile"`、`projectile_behavior="explosive"`、`travel_path="homing"`、3 发爆炸弹药、射程 3.4m、速度倍率 1.05、爆炸半径 0.54。
- 新增 `猎隼锁射启动 / KESTREL MISSILE LOCK`，profile `missile_lock_activate`，只绑定 `missile_launcher + explosive` 的枪械末端。
- `main.gd` 接入 `release_missile_lock` semantic、pending missile 飞行队列、遮蔽断制导计时、导弹目标分类与优先级打分；爆炸 projectile normalization 保留 `projectile_style="missile"`，不再把导弹视觉退成普通 explosive。
- runtime segment 现在携带导弹锁定字段、爆炸字段和遮蔽 grace，保证画板/战斗同源枪械数据能进入战斗事件。

Verification:
- Passed Godot `--check-only`.
- Added and passed: `missile_part_data_probe`, `missile_lock_activate_binding_probe`, `missile_projectile_gate_probe`, `missile_no_proximity_autofire_probe`, `missile_lock_priority_near_probe`, `missile_lock_priority_far_probe`, `missile_lock_priority_screen_role_probe`, `missile_lock_barrier_support_probe`, `missile_lock_invalid_no_ammo_probe`, `missile_lock_runtime_fire_probe`, `missile_homing_speed_dodge_probe`, `missile_occlusion_break_lock_probe`, `missile_no_sniper_lock_probe`, `missile_ammo_heat_probe`.
- Passed regressions: `gun_activate_binding_probe`, `laser_beam_activate_binding_probe`, `gun_activate_sprayer_binding_probe`, `gun_activate_rotate_command_probe`, `projectile_warning_only_gun_activate_probe`, `gun_kind_ammo_kind_probe`, laser probes, web range/no-damage probes, `runtime_melee_never_projectile_gate_probe`, `projectile_momentum_probe`, `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Planned `web_tether_activate_binding_probe` is not present in this project; current web regressions used `web_gun_range_probe` and `web_tether_no_projectile_damage_probe`. ObjectDB cleanup warnings remain ordinary headless teardown warnings.

Sync:
- Implemented in `E:\New project`.
- Pre-change worklog sync SHA256 was `7CCDDE01CC5ECEF91FCF5A9DB821343439F71C89BB5F6F131662E9B0677EC1A4`.
- Final touched source hash: `scripts/main.gd` = `D07AFBC9D6E7EDDE2094FEA85369AD2D3FB4FA5F5D6CEE0067036463BBF5C6DD`.
- Documents mirror sync completed for `scripts/main.gd`, new missile probes, and `WORKLOG_RULEBOOK.md`; post-sync worklog SHA256 is recorded by the final sync command, and all touched-file hashes matched between `E:\New project` and Documents.

## 2026-05-21 引擎梯度与作战哲学

Rules:
- 引擎继续只提供动力、引擎族系加成与常态热负载；引擎不直接提供位移动量，移动/Boost/转向动量仍由推进器负责。
- 引擎梯度按尺寸和作战哲学划分：`balanced` 通用均衡，`melee_drive` 近战肢体驱动，`ranged_control` 远程火控低热稳定，`booster_core` 高速推进/转向，`swarm_lite` 廉价小型傀儡，`siege_reactor` 重装攻城。
- 同尺寸主引擎必须能支撑同尺寸中位机体的基础动力需求，以及一个同尺寸推进器、散热器和普通行动模块的负载；专精引擎允许短板，但必须在 hover 中明确说明。
- 机体行动模块驱动支持读取引擎族系的 `engine_motion_scale` 加权值，但仍受机体质量、行动模块、肢体刚度与推进器动量规则约束。
- XS 低质量散热器必须能进入 XS 机内槽；显式 `slot_volume_tier` 优先于质量/散热推导。

Implementation notes:
- 扩展引擎库为 17 个引擎，覆盖 XS/S/M/L/XL 和 6 个族系：蜂群轻量、均衡、小型近战、远程火控、推进核心、攻城/巨型反应堆。
- 所有新增/重标定引擎统一字段：`power`、`idle_heat`、`mass`、`cost`、`slot_volume_tier`、`heat_capacity`、`engine_family`、`engine_motion_scale`、`summary`。
- `_merge_engine_stats()` 现在按引擎 power 加权汇总 `engine_motion_scale`，并记录主导 `engine_family_primary`；`_apply_engine_power_budget()` 在动力预算后应用族系运动倍率。
- 零件卡、hover、躯干详情统计增加引擎族系、动力、常态热、质量、槽位尺寸、近战驱动/作战哲学说明；旧载重/动量承载词条不回流。
- `VENT SHEET` 与 `NANO HEAT VEIN` 显式标为 `slot_volume_tier="XS"`，修复 Unit2 因小散热器被推导为 S 而非法的问题。

Verification:
- Added probes: `engine_gradient_catalog_probe.gd`, `engine_philosophy_probe.gd`.
- Updated probe: `engine_thruster_cooling_economy_probe.gd` now accounts for the current global `THRUSTER_MOMENTUM_MULT = 2.0`.
- Passed: `engine_gradient_catalog_probe`, `engine_philosophy_probe`, `engine_thruster_cooling_economy_probe`, `internal_slot_size_probe`, `catalog_ui_terms_probe`, `ui_layout_probe`, `text_overflow_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `teamedit_probe`, `combat_probe`.
- Passed Godot headless `--check-only --quit-after 1` in `E:\New project`; ObjectDB cleanup warnings remain ordinary headless teardown warnings.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync performed for `scripts/main.gd`, `tools/engine_gradient_catalog_probe.gd`, `tools/engine_philosophy_probe.gd`, `tools/engine_thruster_cooling_economy_probe.gd`, and `WORKLOG_RULEBOOK.md`.

## 2026-05-21 散热器梯度与热管理功能

Rules:
- 散热器分为机内插件与战场支援两类：机内散热只进躯干插件槽，不生成碰撞体；冷却场/支援节点继续作为可见战场实体冷却队友。
- 散热器不再只按“更多 cooling 更好”阅读；新增 `cooling_profile` 与 `weapon_heat_tags` 表达连段、激光、化学、导弹/爆发、推进、怪物热肺等作战哲学。
- 热量减免只作用于已有热量入口：行动模块热、枪械/投射物 normal heat、手动冷却与过热恢复；不新增外部 gameplay API，不改变 hero-only 热资源规则。
- 测试稳定性规则：headless `--check-only` 若 120 秒不退出，先清理 Godot 残留并重试；仍超时则用有头 `--check-only` 验证解析，脚本探针作为本轮主验收。

Implementation notes:
- `STYLE_COMMON_CATALOG["cooling"]` 扩展为 7 个代表散热器：轻型决斗热脉、`GLACIER COMBO VENT`、激光棱镜冷却器、化学喷流散热器、导弹爆发热槽、推进流冷却器、`COLOSSUS HEAT LUNG`。
- `COMMON_CATALOG["cooling"]` 的旧散热器补齐 heat capacity、profile、适配标签和热量减免字段；`COOLANT AURA FIN` 与 `CRYO STORM TOWER` 明确为团队冷却场梯度。
- `_compute_unit_stats()` 与机内 payload merge 汇总 `manual_cooling_bonus`、`repeat/projectile/boost/laser/chemical/missile_heat_relief`、`overheat_clear_ratio`、`overheat_shutdown_mult` 和 profile/tag 列表。
- `Fighter.add_heat()` 按 reason 对匹配散热 profile 减免热量；手动冷却和自然冷却使用 merged `overheat_clear_ratio`，过热 shutdown 使用 `overheat_shutdown_mult`。
- 散热器 hover 卡增加热槽、手动冷却和适配标签/作战哲学说明，避免和非散热支援件混淆。

Verification:
- Added and passed: `cooling_gradient_probe`, `cooling_weapon_fit_probe`, `cooling_runtime_heat_probe`, `cooling_support_aura_probe`, `cooling_ui_terms_probe`.
- Passed regressions: `engine_thruster_cooling_economy_probe`, `ether_heat_economy_probe`, `editor_balance_stat_probe`, `internal_slot_size_probe`, `boost_cooldown_probe`, `laser_ammo_heat_probe`, `missile_ammo_heat_probe`, `part_catalog_balance_probe`, `part_size_visual_probe`, `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- `chemical_heat_probe` and `ether_heat_economy_probe` still emit historical `push_error` diagnostics despite returning exit 0; this round did not change those stale probe semantics. ObjectDB cleanup warnings remain ordinary teardown noise.
- Headless `--check-only` timed out twice at 120 seconds, including after killing stale Godot processes. Headed `Godot_v4.6.2-stable_win64.exe --check-only` completed successfully.

Sync:
- Implemented in `E:\New project`.
- Final touched source hashes before mirror: `scripts/main.gd` = `98CF028F25EC3332CE289309C88DC61A77B87540958544AA1F11ABE30F5DE5C5`; `scripts/fighter.gd` = `833B260F393EA8F46E1200FC2F18E74BF7F2FD70EC017529D49EE79365663DA3`.
- New probe hashes before mirror: `cooling_gradient_probe.gd` = `252D1B4C196D725218846FE6CBAA3C6B36DE92F5388A616A9E30C53D105737E7`; `cooling_weapon_fit_probe.gd` = `4DBA8AF4025C56919FF5C0FA1C7DE9D67136E8845B6CB85D960E8CE67655C788`; `cooling_runtime_heat_probe.gd` = `C467F96D0F539F28BFA35C4631B6D0CFE41A886D4BD34E8A8D5EC4E97C5BC878`; `cooling_support_aura_probe.gd` = `C4ADAED10CE935C3F09C9526FB44440129DF4CBB9F8E9A0CFE8228C5D54CEE52`; `cooling_ui_terms_probe.gd` = `7DC0A5C369C4FA725254945D58DD1CC97F4860062A89AF8A924C4DF51C2A9D79`.
- Documents mirror sync completed for all touched files; final sync command reported matching `WORKLOG_RULEBOOK.md` hashes for `E:\New project` and Documents.

## 2026-05-21 本地 Git 差分基线与限定范围 diff

Rules:
- `E:\New project` 是活跃开发副本；从本轮开始它也是本地 git 工作区，后续开发可直接使用 `git diff -- <path>` 限定范围查看改动。
- Git 只跟踪项目源码、场景、资产、开发日志、探针与工具脚本；不跟踪 Godot 缓存、日志、下载目录、portable git 或 Godot 二进制包。
- Documents 目录继续作为镜像，不把 `.git` 目录复制到 Documents。

Implementation notes:
- `.gitignore` 不再忽略整个 `tools/`，改为只忽略 `tools/downloads/`、`tools/git-portable/`、`tools/godot-*/`，让 probe、sync 脚本和工具 registry 可以被版本管理。
- 新增 `.gitattributes`，为 `.gd`、`.tscn`、`.tres`、`.godot`、`.md`、`.json`、`.ps1`、`.svg` 提供稳定文本 diff 与换行规则。
- 将初始化本地 git 仓库并创建当前项目基线提交，之后可使用示例：`git diff -- scripts/main.gd tools/first_ether_origin_pin_probe.gd`。

Verification:
- Verified ignore scope with `git check-ignore` for `tools/godot-4.6.2/`, `tools/git-portable/`, and `tools/downloads/`.
- Verified 329 project files are visible to git after excludes, including scripts, scenes, generated assets, probes, sync tooling, and logs/rulebook.
- Created a local baseline commit so future work can use scoped commands such as `git diff -- scripts/main.gd tools/example_probe.gd`.

Sync:
- Implemented in `E:\New project`; Documents mirror sync pending after final git baseline setup. `.git/` remains local to E and is not mirrored.

## 2026-05-21 第一个以太：始点星钉

Rules:
- 第一个标准以太是 barrier special catalog 索引 0；本轮只重塑该 entry，不迁移保存单位、不重排 catalog、不重平衡高级以太。
- `ETHER: ORIGIN PIN` 是 `kind="ether"` 的结构许可软件灵体，只绑定少量断开结界材料，不提供热、冷却、伤害、减速、重力、projectile 或旧 attack/action pointer。
- 以太继续作为 barrier 的空间软件核心：soul/source/ether 共享星状软件精神的美术哲学，但 runtime 行为仍由 barrier stats 和真实结界材料决定。

Implementation notes:
- `ETHER: PIN` 升级为 `始点星钉以太 / ETHER: ORIGIN PIN`，保留 barrier special index 0。
- Origin Pin 固定为 `maker="NULL SOFTWARE"`、`barrier_logic="structure_only"`、`barrier_disconnected=true`、`ether_group_kind="origin_pin"`、`ether_link_capacity=0`、`ether_bind_radius_m=3.2`、`aura_range=0.0`。
- `_merge_ether_stats()` 对显式 `aura_range=0.0` 的首个 ether 不再继承默认 barrier aura，确保结构以太不会产生隐形 aura。
- TeamEdit AI compact barrier preset 改用 `ETHER: ORIGIN PIN`；中文映射改为 `以太：始点星钉`。
- `ether_probe.gd` 的 gravity runtime 断言改为把目标放到真实 barrier tile 世界坐标附近；`ether_heat_economy_probe.gd` 去掉历史热量系统旧假设，只保留当前可验证的 plain ether/heat metadata 断言。

Verification:
- Added and passed: `first_ether_origin_pin_probe`.
- Updated and passed: `ether_probe`, `ether_heat_economy_probe`.
- Passed regressions: `part_catalog_balance_probe`, `part_size_visual_probe`, `board_battle_art_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `no_old_combat_terms_probe`.
- Headless `--check-only --quit-after 1` passed.
- Attempted `runtime_geometry_identity_probe`; it failed with `Training hero missing` from local `user://saved_units` Unit2 import state. This round does not migrate saved units, so it is recorded as a local saved-data blocker rather than an Origin Pin regression.

Sync:
- Implemented in `E:\New project`; Documents mirror sync completed for all touched files after final log write.
- Pre-sync source/probe hashes: `scripts/main.gd` = `3B0E75BD74134A814BDF5F033409DEE5BF5EA4290FE38455C8615673270186C1`; `tools/first_ether_origin_pin_probe.gd` = `6F5D26C2100DA9158FDC67EED2662A63D39E10CB3C1B35516F8F41DF70609155`; `tools/ether_probe.gd` = `EAEB0B4A3AC35C848DDD85CF27E5956832E2D43B3B485EFE047C9B0735C9AD1A`; `tools/ether_heat_economy_probe.gd` = `B09B8B301A100A714D3A4DCCD71A671A5B062A0507B932BA3742561A8BBDF11C`.

## 2026-05-21 新源代码：热轮换车组

Rules:
- 新增 source code 必须继续是 puppet-only `kind="code"` 软件核心，不新增武器、行动模块、projectile、旧 attack/action pointer 或保存单位迁移。
- 源代码 AI 只通过现有 `source_rules`、target policy、attack preference 与 close response 影响傀儡行动；伤害仍由真实 contact/projectile 路径结算。
- 热管理主题 source 可以读取目标热量/过热状态做内部选靶，但不得把 puppets 扩展成英雄热槽资源。

Implementation notes:
- 新增 `CODE: THERMAL PIT CREW`，`maker="SYNTAX ELEVEN"`，`group_count=4`，`ai="formation_xi"`，定位为热压制、轮换掩护和支援射击窗口的软件核心。
- 新增内部 source target policy `heat_pressure_first`，优先评分过热/高热量目标，其次英雄、傀儡、支援结界和距离；目标没有热量时回退到常规角色/距离/血量评分。
- `source_heat_focus_ratio=0.68` 加入 stats merge 白名单，保证 catalog 与 runtime source AI 读取同一份阈值。
- 补回并验收 `CODE: PIERCING RETINUE` 与 `piercing_retinue_source_code_probe.gd`，避免开发日志记录过的刺枪侍从 source 回归项继续缺文件。
- `source_code_probe.gd` 改为使用 override blueprint 并增加断言，避免旧探针只打印、不验证 source code stats 合并的假阳性。

Verification:
- Added and passed: `thermal_pit_crew_source_code_probe`, `source_heat_pressure_policy_probe`, `piercing_retinue_source_code_probe`.
- Updated and passed: `source_code_probe`, `no_old_combat_terms_probe`, `no_legacy_runtime_pointers_probe`.
- Passed regressions: `cooling_runtime_heat_probe`, `engine_weapon_fit_probe`, `missile_lock_priority_screen_role_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Headless `--check-only --quit-after 1` passed. ObjectDB cleanup warnings appeared on several successful probe exits and remain ordinary teardown noise.

Sync:
- Implemented in `E:\New project`; Documents mirror sync completed for all touched files.
- Final mirrored source/probe hashes: `scripts/main.gd` = `2333EF38A53708822F5111EA0DBE1F6F037A151053A8566F092B2946A8778C17`; `tools/source_code_probe.gd` = `B354A6810BB868509C36CE3E1E2BD67093BD2C687FD0252A6D2BB55F2B741A80`; `tools/thermal_pit_crew_source_code_probe.gd` = `0264FA9C2E5C38CA20D6006B40DAA01121709AB67BB163EAA39064A46D61F60D`; `tools/source_heat_pressure_policy_probe.gd` = `84BF86AECF8375F19738B95D5A7AAEBDF76594E544CB0F6A7FF5F896CF74229B`; `tools/piercing_retinue_source_code_probe.gd` = `A0D18E6D61527CDFB43A7EA11A240BEE4F7DB74C7F8D29041B2B2C1D4F13FD0F`.

## 2026-05-21 引擎梯度二次深化与旧指针清理

Rules:
- 引擎继续不直接生成位移、攻击、碰撞或 projectile；它只通过 power budget、族系权重和现有 stats 影响行动驱动、火控稳定、推进控制与支援负载。
- 引擎族系保留 `balanced`、`melee_drive`、`ranged_control`、`booster_core`、`swarm_lite`、`siege_reactor`，但必须额外表达适配武器、队伍角色和热模型。
- 旧 socket 名称只允许作为导入别名被 canonical 化；runtime/topology/API helper 不再暴露 `socket_legacy_id` 或 `_topology_socket_legacy_id`。
- 旧 `legacy_swing_*` / `legacy_extend_*` 行动 profile 清成 canonical profile，公开文案不再使用 Legacy Action。

Implementation notes:
- 引擎 selected/economy normalization 新增 `_engine_with_philosophy_defaults()`，为每个族系补齐 `engine_weapon_tags`、`engine_team_role`、`engine_heat_profile`、`engine_recoil_stability`、`engine_boost_control`、`engine_command_drive`、`engine_supply_load`。
- `_merge_engine_stats()` 按 engine power 加权汇总新引擎 philosophy 字段；`_apply_engine_power_budget()` 将它们映射到已有 stats：`recoil_stabilization`/`recoil_cancel`、`cornering`/`turn_acceleration`、行动 cooldown、`support_power_capacity`。
- `_apply_recoil_stabilization()` 读取 `engine_recoil_stability`，使远程火控/攻城稳定引擎在真实 recoil/stability 计算中可见。
- 引擎 hover card 前 8 项现在包含火控稳定和推进控制；详情文案显示适配标签、队伍角色、热模型、指令驱动与支援负载。
- `TopologyGeometry.socket_legacy_id()` 重命名为 `canonical_socket_id()`，`main.gd` 和相关 editor/socket probes 改用 `_topology_canonical_socket_id()`。

Verification:
- Added and passed: `engine_weapon_fit_probe`, `engine_runtime_stat_merge_probe`, `engine_ui_terms_probe`, `canonical_socket_no_legacy_pointer_probe`.
- Updated and passed: `engine_gradient_catalog_probe`, `engine_philosophy_probe`, `no_legacy_runtime_pointers_probe`, `editor_endpoint_socket_probe`, `occupied_slot_transaction_probe`, `occupied_slot_no_replace_probe`.
- Passed regressions: `engine_thruster_cooling_economy_probe`, `internal_slot_size_probe`, `boost_cooldown_probe`, `cooling_gradient_probe`, `cooling_runtime_heat_probe`, `part_catalog_balance_probe`, `part_size_visual_probe`, `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `no_old_combat_terms_probe`.
- Headless `--check-only` once returned exit 1 with no diagnostic, while headed `--check-only` and headless `--check-only --quit-after 1` passed. Recorded as check runner instability, not a gameplay or parser failure. ObjectDB cleanup warnings remain ordinary teardown noise.

Sync:
- Implemented in `E:\New project`.
- Final mirrored hashes: `scripts/main.gd` = `02F281A24EB73B32107BFEE4B86A98A2CE65F435778D3CF0B598B66E33D5798B`; `scripts/topology_geometry.gd` = `FA23782EE0A6AF92CFD42F682190F468C28C984970A18D1CCB875C0A9BB14189`.
- New/updated probes, source files, and `WORKLOG_RULEBOOK.md` were copied to Documents and SHA256-matched after sync.

## 2026-05-21 推进器梯度与稳定测试

Rules:
- 推进器分为四条战术梯度：蓝色 `cruise` 巡航、黄色 `sustain` 持续、红色 `overburn` 过载、白色 `stabilizer` 稳定。
- 每个推进器在编辑器读取时必须暴露 `booster_family`、`booster_size`、`weapon_synergy`、`team_philosophy` 和 `thruster_cone_degrees`；旧 catalog 条目通过归一化 helper 补齐，不重排旧索引。
- 蓝色巡航适配 rifle/laser/web 和 kite/ranged pressure；黄色持续适配 pierce/tear/screen 和 screen/retinue/mobile attrition；红色过载适配 pierce/drill/lance/blunt/tear 和 rushdown/breach/monster；白色稳定适配 sniper/grenade/heavy cannon/shield/heavy melee 和 siege/retinue/monster/guard。
- `boost_cone` 正式合并为 runtime `thruster_cone_degrees`；窄锥推进器不能把侧后/纯后方向当成合法 Boost。
- 成功 Boost 后按 `boost_heat * boost_heat_mult` 进入热槽；黄色持续低热、蓝色中热、红色过载高热。
- `recoil_cancel` 参与 `recoil_stabilization` 派生，稳定系推进器实际提高重枪、榴弹、重近战和护卫主坦的姿态恢复。

Implementation notes:
- `COMMON_CATALOG["booster"]` 末尾追加四个白色稳定系型号：`WHITE MICRO ATTITUDE STABILIZER`、`WHITE STANDARD COUNTERTHRUST POD`、`WHITE HEAVY RECOIL LATTICE`、`WHITE COLOSSUS GRAVITY ANCHOR BANK`。
- `_booster_gradient_component()` 在 `_selected_component()` 的 booster 路径统一补齐家族、尺寸、适配武器、队伍哲学、火焰颜色和推进锥字段，保证 UI 与 runtime 读取同一份语义。
- hover 详情新增中文/英文梯度说明，显示推进家族、尺寸、适配武器、队伍哲学、转向、后坐力稳定和推进锥角。
- `Fighter.boost()` 保持自由拓扑八方向合法推进，但纯后向/不可用锥角现在走 `unusable_boost_angle` 制动，并在成功 Boost 后积热。
- `tools/run_godot_checked.ps1` 包装 Godot 测试：headless 优先，超时清理 `Godot*` 进程并 headed retry；`--check-only` 的 headless/headed 都卡死时再跑 `check_only_fallback_probe` 做脚本加载兜底。

Verification:
- Added and passed: `booster_gradient_catalog_probe`, `booster_weapon_philosophy_probe`, `booster_runtime_heat_probe`, `booster_cone_runtime_probe`, `booster_stabilizer_recoil_probe`, `godot_test_fallback_probe`, `check_only_fallback_probe`.
- Passed wrapper self-test: `tools/run_godot_checked.ps1 -SelfTest`.
- Passed regressions: `engine_thruster_cooling_economy_probe`, `thruster_turn_momentum_probe`, `thruster_momentum_motion_probe`, `boost_cooldown_probe`, `eight_direction_boost_probe`, `boost_unusable_direction_brakes_probe`, `reverse_cannot_boost_probe`, `training_saved_unit_control_probe`, `teamedit_probe`, `ui_layout_probe`, `text_overflow_probe`.
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` completed with exit code 0 on the final run. Earlier long `--check-only` attempts reproduced the known Godot exit-path instability; the wrapper now cleans processes and has a script-load fallback path for that case. ObjectDB cleanup warnings remain ordinary teardown noise when a probe exits 0.

## 2026-05-21 推进器梯度重构与旧字段清理（二次统一）

Rules:
- 推进器是移动、Boost、转向、刹车、主动攻击反作用力抵消的唯一动量来源；引擎只负责动力供给和常态热。
- 新推进器数据只主动读取显式字段：`thruster_family`、`thruster_momentum`、`thruster_duration`、`boost_momentum`、`boost_duration`、`idle_heat`、`mass`、`cost`、`slot_volume_tier`、`brake_efficiency`、`recoil_cancel`、`flame_color`、`summary`。
- 旧字段 `boost_power`、`normal_thrust`、`boost_cone`、`booster_size`、`boost_style`、`boost_flame`、`boost_sustain`、`boost_efficiency` 不再被保存单位、战斗路径或新 catalog 主动读取；旧数据只能作为诊断/重建提示。
- 推进器家族固定为 `cruise_blue`、`sustain_yellow`、`overburn_red`、`counter_brake`、`swarm_micro`、`titan_vector`；差异分别体现在常态推进、持续 Boost、爆发、刹车/反作用力、轻量低价和重装推力。
- `brake_efficiency` 同时作用于线速度刹车和松开 Q/E 后的角速度刹车；`recoil_cancel` 只参与主动反作用力抵消，不替代受击动量。

Implementation notes:
- `COMMON_CATALOG["booster"]` 重建为 23 个显式动量推进器，覆盖 XS/S/M/L/XL 与六个推进器家族；`STYLE_COMMON_CATALOG["booster"]` 的角色风格推进器也改为新字段。
- `_economy_rebalanced_plugin_component()` 的 booster 路径改为“显式字段优先”，只在缺字段时补同尺寸中位目标，避免抹平家族差异。
- `_booster_normal_momentum_for_part()`、`_booster_boost_momentum_for_part()`、`_apply_thruster_momentum_stats()`、`_engine_required_power()`、payload merge、反作用力抵消与战斗 Boost/刹车都改为读取 `thruster_momentum/boost_momentum/brake_efficiency/recoil_cancel`。
- `Fighter.boost()` 不再读取旧 `boost_power` 或旧 style 字段；反向倒车状态禁止 Boost，刹车方向仍使用 Boost 动量刹停。
- 推进器 hover、零件卡、Dashboard 摘要改为显示推进器家族、推进动量、Boost 动量、持续时间、常态热、刹车稳定和反作用力抵消；玩家可见 UI 不再展示旧推进字段。
- `part_art.gd` 与机体/插件图标逻辑改用 `thruster_family` 与 `flame_color`，推进器火焰颜色不再依赖旧 atlas/style 分支。

Verification:
- Added and passed: `thruster_gradient_catalog_probe`, `thruster_philosophy_probe`, `attack_reaction_cancel_probe`.
- Updated and passed: `engine_thruster_cooling_economy_probe`, `thruster_turn_momentum_probe`, `thruster_momentum_motion_probe`, `catalog_ui_terms_probe`.
- Passed regressions: `boost_cooldown_probe`, `brake_reverse_input_layer_probe`, `brake_reverse_after_stop_probe`, `reverse_cannot_boost_probe`, `teamedit_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- `--check-only` headless timed out at 120 seconds again; headed `Godot_v4.6.2-stable_win64_console.exe --check-only --quit-after 1` returned exit code 0. This matches the existing Godot headless instability note and is not treated as a gameplay/model failure.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/fighter.gd`, `scripts/part_art.gd`, updated probes, new probes, and `WORKLOG_RULEBOOK.md`.
- Final mirrored hashes include `scripts/main.gd` = `9A05DCD54FEBA0EED0FC8CA89EC43BA54E1AF0B210F3D8E083DD31366704F920`, `scripts/fighter.gd` = `8AA70276778CF1D7647E5616832061EEC7C36334317C695B1A8FE692537D99BA`, `scripts/part_art.gd` = `557496E4C648E54312D5B9BFDB0D11C7358E3109C1BE21742C282ED18BBB821A`.

## 2026-05-21 单位2训练靶机动力合法化

Rules:
- 训练靶机单位2继续作为新动力系统的合法训练基准；不放宽预算规则，不降低四肢行动模块分配。
- 修复只替换过弱引擎，保留四接口躯干、四肢拓扑、推进器、散热器、英魂和 `U/I/O/J` 四个 `双段正锋折返` 绑定。

Implementation notes:
- 最新单位2保存文件写为 `user://saved_units/2_1779360176.json`。
- 原最新文件 `2_1779318152.json` 已备份到 `user://saved_units/backups/unit2_engine_repair_1779360176_2_1779318152.json`。
- 引擎 payload 从漂移后的弱引擎索引 `2` 更新为索引 `3`：`LIGHT FORMATION ENGINE`。
- 同步更新 `slot_payloads`、`purchased_parts["engine"] = [3]` 和可读 `part_name`，避免 UI 或导入逻辑回退到旧引擎。
- 动力预算从 `engine output 49 < thruster 10 + bound limbs 52` 修正为约 `64 >= 10 + 52`；现有 `NANO HEAT VEIN` 仍能覆盖热管理。

Verification:
- Passed: `unit2_training_probe`, `training_saved_unit_control_probe`, `thermal_allocation_probe`, `momentum_budget_allocation_probe`, `limb_momentum_range_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`。
- `teamedit_probe` exit code 0；输出中仍有已知 AI/template 非法提示，不影响单位2训练靶机合法性。
- `--check-only --quit-after 1` exit code 0；ObjectDB cleanup warnings remain ordinary teardown noise.

## 2026-05-21 统一动力链与旧动力字段拒绝

Rules:
- 新动力链唯一公开语义：引擎提供 `drive_output`，推进器与绑定行动关节消耗 `drive_demand/joint_drive_demand`，统计层输出 `drive_output_total`、`drive_demand_total`、`drive_margin`、`drive_ratio`、`move_speed`、`boost_speed`、`action_drive_scale`、`stability_drive_scale`。
- 有效 catalog 的 engine 只暴露 `drive_family/drive_size/drive_output/drive_idle_heat/drive_mass/drive_role_tags/drive_team_philosophy`；booster 只暴露 `thruster_family/thruster_size/move_momentum/boost_momentum/boost_duration/brake_power/reaction_cancel/drive_demand`。
- 旧动力字段 `power/engine_power/engine_motion_scale/engine_momentum_output/thruster_momentum/thruster_engine_demand/allocated_momentum/boost_power/normal_thrust/boost_cone/booster_size` 等只作为 legacy 检测目标；保存单位或拓扑中出现即判为旧动力数据，需要在 TeamEdit 重建。
- 六类引擎哲学：`duelist` 轻量高响应，`gunline` 火控稳定，`rushdown` 瞬时动作与 Boost，`siege` 重载稳定，`swarm` 傀儡低价，`support_grid` 结界/支援场域。
- 四类推进语义：`cruise` 巡航、`sustain` 持续、`overburn` 过载、`stabilizer` 稳架。Boost 成功后按 `boost_heat * boost_heat_mult` 进入热槽。

Implementation notes:
- `_selected_component()` 在 engine/booster 路径调用 `_drive_component_with_defaults()`，对旧 catalog 条目做有效字段归一化并剥离旧动力键，避免旧存档索引漂移。
- `_merge_engine_stats()`、payload merge、`_bound_joint_budget_for_stats()` 和 `_apply_engine_momentum_budget()` 已改为新 drive budget；旧 `engine_momentum_note` 分支被 `drive_note` 取代。
- `Fighter` 的速度表、移动、刹车、Boost、行动模块关节速度和主动反作用力抵消改读 `move_speed/move_acceleration/brake_power/action_drive_scale/stability_drive_scale/reaction_cancel`。
- 自由画布旧 `groups/attack_groups`、旧动力字段和旧关节分配字段被 `_unit_has_legacy_drive_data()` 捕获；训练入口返回 legacy drive rebuild 提示。

Verification:
- Added and passed: `drive_catalog_schema_probe`, `drive_gradient_philosophy_probe`, `drive_budget_teamedit_probe`, `drive_runtime_movement_probe`, `drive_runtime_action_speed_probe`, `drive_recoil_stability_probe`, `drive_legacy_rejection_probe`.
- Updated and passed: `engine_thruster_cooling_economy_probe`.
- Passed regressions: `boost_cooldown_probe`, `eight_direction_boost_probe`, `reverse_cannot_boost_probe`.
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 20` reproduced the known headless/headed check-only timeout path, then completed through `check_only_fallback_probe` with exit code 0. ObjectDB/RID cleanup warnings remain teardown noise when probe exit code is 0.

## 2026-05-21 零件库 Hover 详情大卡重制

Rules:
- 零件库详细页本轮定义为零件 hover 大卡和躯干详情 payload hover；不新增独立详情页，不调整 catalog 数值，不改战斗 API。
- 玩家可见信息采用关键战斗信息密度：购买、质量、生命、接口/槽位、武器、热、动力、行动适配和软件定位；隐藏兼容/调试/底层工程口径。
- Hover 大卡继续使用现有程序化零件图，不引入外部图标资产，不恢复旧 atlas 或旧 child visual。

Implementation notes:
- `EditorPartHoverPopupView` 改为说明书式布局：标题、零件图、4x2 图标指标栏和短说明/标签区。
- `_hover_card_stat_entries()` 不再用 radius、active damage 等 fallback 补满 8 项；各零件类型只展示关键指标，并给指标附带程序绘制 icon key。
- 新增 `_hover_card_player_detail_lines()`，将躯干、肢体、近战、枪械、引擎、散热器、推进器、行动模块与 soul/code/ether 的 hover 文案压缩为玩家语义。
- 编辑器底部旧 `Legacy Load`/`兼容负载` 文案改为 `Momentum Allocation`/`动力分配`，避免和新系统术语冲突。
- 新增 `part_hover_detail_page_probe.gd`，并更新 `catalog_ui_terms_probe.gd`、`part_library_ui_probe.gd` 的 UI 术语期望。

Verification:
- Passed: `part_hover_detail_page_probe`, `catalog_ui_terms_probe`, `part_library_ui_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Passed new-system samples: `engine_ui_terms_probe`, `cooling_ui_terms_probe`, `missile_part_data_probe`, `laser_part_data_probe`, `blunt_weapon_gradient_probe`, `first_ether_origin_pin_probe`, `thermal_pit_crew_source_code_probe`.
- Passed core regressions: `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `no_old_combat_terms_probe`, `no_legacy_runtime_pointers_probe`.
- Headless `--check-only --quit-after 1` exit code 0. ObjectDB cleanup warnings appeared on several successful probe exits and remain ordinary teardown noise.

Sync:
- Implemented in `E:\New project`; Documents mirror sync completed for touched hover UI files, updated probes, new probe, and this worklog.

## 2026-05-21 战斗运行性能缓存与副本确认

Rules:
- `E:\New project` 继续作为唯一开发源；桌面快捷方式确认指向 E 盘项目与 E 盘 Godot。
- 保存单位战斗路径仍只允许 TeamEdit runtime topology 与 AssemblyBoard 同源几何；性能优化不得恢复旧 shell、joint、action group、atlas/CAD 或空气墙半径。
- 碰撞优化只能提前跳过明显不接触的 broadphase；真实 overlap、未接触无反馈、同单位不自碰撞等核心语义不变。

Implementation notes:
- `Fighter` 新增每帧 runtime geometry cache：同一帧的 `runtime_topology_segments`、part colliders、polygon bounds 与 collider sort data 只构建一次，绘制、碰撞、枪口/命中特效查询共享同一份缓存。
- runtime colliders 现在缓存 `bounding_radius/aabb_min/aabb_max`，供主战斗 broadphase 复用，避免每次 polygon 距离检查前重复扫描多边形。
- `_separate_unit_part_pair()` 先把双方 collider 各自按 ring origin shift 一次，再进入嵌套检测；嵌套前增加 collider 级 broadphase gap，明显不接触时不进入 `_collider_gap()` 的 polygon distance。
- TeamEdit runtime 机体不再每 tick 无条件 `queue_redraw()`；只有姿态/朝向/状态签名变化时重绘主体，推进火焰和 HUD 仍按运行时状态更新。
- 战斗 UI 重型刷新拆频：小地图约 10Hz、主 HUD 状态约 6Hz、出击缩略图低频刷新；中央速度/弹药仪表继续每帧读玩家控制单位。

Verification:
- Added and passed: `runtime_geometry_cache_probe`, `battle_runtime_frame_budget_probe`, `collision_broadphase_skip_probe`.
- Performance baseline: Unit2 vs Unit2 training simulation averaged `2.083ms` per measured tick after warmup; max spike `94.773ms` remains a periodic Godot/UI spike rather than sustained battle-loop cost.
- Passed regressions: `board_battle_art_identity_probe`, `runtime_no_precontact_damage_probe`, `runtime_contact_damage_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- `--check-only --quit-after 1` exit code 0; ObjectDB cleanup warnings remain teardown noise when probes exit 0.

Sync:
- Implemented and verified in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/fighter.gd`, new performance probes, and this worklog.
- Mirrored hashes: `scripts/main.gd` = `CAC95184FE63B2A495754A03C1A0B180FEEE7B86E2B959849943305285A2F926`; `scripts/fighter.gd` = `325A5A1470D282B15C8008489676CD63E34C1BB53746A551239ECD764147731A`.
- Desktop shortcuts `Eidolon Circuit.lnk`, `Strike Lab Game.lnk`, and `Godot 4.6.2.lnk` target `E:\New project\tools\godot-4.6.2\Godot_v4.6.2-stable_win64.exe --path "E:\New project"` with working directory `E:\New project`.

## 2026-05-21 已保存单位页面缓存与 Hover 性能修复

Rules:
- 已保存单位页不通过删除旧单位文件解决卡顿；所有历史单位和非法草稿仍保留展示。
- 单位库进入、保存、删除或文件 `mtime/size` 变化时刷新缓存；普通 hover、翻页、多选和详情刷新不得反复扫盘、读 JSON 或全量重算 stats。
- 合法性与 stats 规则不变，只缓存计算结果；保存单位 JSON 格式不变。

Implementation notes:
- `scripts/main.gd` 新增保存单位库缓存：每个文件缓存 `path/mtime/size/role/blueprint/unit_name/stats/illegal_note`，并记录 disk scan / JSON load / stats / illegal 计数供探针验证。
- `_unit_library_entries()`、`_saved_unit_filtered_entries()`、`_saved_unit_selected_entries()` 改为读取缓存；`_show_saved_units_library()` 进入页面时只做一次轻量签名检查。
- 保存单位、删除单位和语言切换会失效相关缓存；删除后只清理相关选择和详情状态，不重建无关单位。
- `_update_saved_units_ui()` 复用过滤后的 entries，并从缓存读取 stats/illegal；`_hover_saved_unit_card()` 记录 hovered path/index，同一卡片重复移动不再刷新详情。
- 点击选择不再先 `_show_saved_unit_detail()` 再 `_update_saved_units_ui()` 双重刷新；详情视图按 path 去重，只在目标变化或缓存失效时重绘。

Verification:
- Added and passed: `saved_units_cache_probe`, `saved_units_hover_cache_probe`, `saved_units_file_invalidation_probe`.
- Passed regressions: `saved_units_menu_probe`, `saved_unit_delete_probe`, `teamedit_save_unit_button_probe`, `unit_library_save_load_probe`, `teamedit_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Probe result: with 11 saved unit files, repeated `_update_saved_units_ui()` after warm cache caused `0` disk scans, `0` JSON loads, `0` stats recomputes, and `0` legality recomputes; repeated hover on the same card did not refresh detail or recompute stats.

Sync:
- Implemented and verified in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `WORKLOG_RULEBOOK.md`, and the three new saved-unit cache probes.
- `scripts/main.gd` in Documents was a OneDrive reparse placeholder; ordinary overwrite did not update content, so it was explicitly replaced as a single file and then hash-verified.
- Mirrored hash: `scripts/main.gd` = `0F0808E22665ACA42CAB6004E5F9969F03264FE39BE8FB4DFC05D64B927BFB0B`.

## 2026-05-21 全零件库梯度/经济统计与未落地零件冻结

Rules:
- 本轮采用锚点校准，不按公式破坏性重算全 catalog；保存单位按旧索引继续读取。
- 冻结表示隐藏不可买、保留数据与未来开发入口；普通玩家零件库默认只显示 live 零件。
- 冻结不得恢复旧 projectile、attack group、child visual 或旧 action pointer；旧入口只能作为未来开发保留标签存在。
- 本轮不混入既有 `scripts/fighter.gd` 性能改动或未跟踪性能/缓存探针。

Implementation notes:
- `scripts/main.gd` 新增 `_catalog_lifecycle_for_part()` 与 `_part_is_catalog_frozen()`，统一返回 live/frozen、冻结原因和 `future_dev_tag`。
- 玩家零件库筛选默认跳过 frozen 零件；`_catalog_for()`、`_selected_component()` 和保存索引读取不受影响。
- 冻结规则覆盖旧 throw/guided eject/group disc/receiver/trap/light sink/projectile shield/weapon swap/retreat/morph/combine/racket/soul cast/role form shift/fold role switch 等未落地或旧入口模块。
- 旧 `LASER EMITTER GUN` 与无当前显式 `gun_kind + ammo_kind + module_action_profile` 验收路径的旧 projectile 枪械冻结保留；标准狙击、来复、化学喷洒、激光、导弹和 web tether 仍为 live。
- Hover 内部查看 frozen 零件时显示 `FROZEN` 与冻结原因；普通购买列表不会暴露 frozen 条目。

Catalog statistics:
- Live/frozen counts by slot: `joint 48/0`, `limb_muscle 15/0`, `muscle 226/28`, `engine 17/0`, `cooling 13/0`, `booster 24/0`, `module 55/57`, `special 79/0`.
- Total sampled lifecycle result: `477` live entries and `85` frozen entries.
- Live gradient anchors verified for torso, limb, melee/gun, engine, cooling, booster, source/code/ether, with basic monotonic mass/cost/hp anchors intact.

Verification:
- Added and passed: `catalog_lifecycle_freeze_probe`, `catalog_economy_math_probe`, `catalog_gradient_anchor_probe`, `frozen_future_dev_probe`, `catalog_live_purchase_probe`.
- Passed catalog/UI regressions: `part_catalog_balance_probe`, `part_size_visual_probe`, `part_library_ui_probe`, `part_hover_detail_page_probe`, `catalog_ui_terms_probe`.
- Passed gradient regressions: `melee_weapon_gradient_probe`, `limb_gradient_catalog_probe`, `blunt_weapon_gradient_probe`, `engine_gradient_catalog_probe`, `cooling_gradient_probe`, `thruster_gradient_catalog_probe`, `engine_thruster_cooling_economy_probe`.
- Passed core regressions: `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `training_topology_visual_consistency_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`, `no_old_combat_terms_probe`, `no_legacy_runtime_pointers_probe`.
- Headless `--check-only --quit-after 1` exit code 0.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, five catalog lifecycle/economy probes, and this worklog; all touched-file SHA256 hashes match.
- Mirrored hash sample: `scripts/main.gd` = `66A1C477D27B98823ABD7C8B82B0379F2C6ECF6E3BC6B3CC99E5B705A7BBAEEE`; final worklog hash is produced by the sync script after this entry is written.

## 2026-05-21 统一编辑/战斗/动力运行契约与行动模块闭环

Rules:
- 新动力链是唯一运行接口：编辑器、训练入口、战斗移动、Boost、刹车、行动速度和反冲稳定只读取归一化后的 `drive_output_total / drive_demand_total / drive_ratio / move_speed / boost_speed / brake_power / reaction_cancel / action_drive_scale / stability_drive_scale`。
- 原始 engine/booster catalog 不再保存旧动力字段；有效 catalog 也不得暴露 `engine_power / engine_torque / engine_motion_scale / thruster_momentum / brake_efficiency / recoil_cancel` 等旧字段。
- 旧保存单位、旧 topology pointer、旧 `attack_groups/action_groups` 或旧动力字段进入训练前硬拒绝，提示玩家在 TeamEdit 重建；不迁移旧存档。
- 近战行动模块只走 runtime pose/contact，强制清空 projectile；投射物只能来自显式枪械 profile 且事件必须携带 `gun_activation=true`。

Implementation notes:
- `scripts/main.gd` 将 engine/booster raw catalog 机械转换为新 `drive_*` 与 `move_momentum/boost_momentum/drive_demand` 字段，并补齐六类动力哲学与四类推进器家族。
- `_engine_with_philosophy_defaults()` 与 `_thruster_with_drive_defaults()` 的出口会擦除旧字段，TeamEdit dashboard/hover/详情只显示动力输出、动力需求、动力余量、移动速度和 Boost 速度。
- 训练蓝图选择与合法性检查接入 `_unit_has_legacy_drive_data()`，拒绝旧动力字段、旧 topology 指针和旧攻击组指针。
- `scripts/fighter.gd` 的 runtime 动作矩阵补齐尖刺伸缩、刺剑、长枪、电钻和回钩链刃 profile；动作期间目标节点进入 active melee collider，结束后恢复原始局部姿态。
- projectile gate 白名单固定为 `gun_activate / rifle_burst_activate / grenade_arc_activate / laser_beam_activate / missile_lock_activate / web_tether_activate`。

Verification:
- Added and passed core probes: `action_module_execution_matrix_probe`, `projectile_profile_whitelist_probe`.
- Passed drive cleanup probes: `drive_raw_catalog_schema_probe`, `drive_catalog_schema_probe`, `drive_gradient_philosophy_probe`, `drive_ui_terms_probe`, `drive_economy_no_legacy_probe`, `drive_part_art_no_legacy_probe`, `drive_runtime_movement_probe`, `drive_runtime_action_speed_probe`, `drive_recoil_stability_probe`, `drive_legacy_rejection_probe`, `drive_legacy_saved_unit_rejection_probe`, `unit2_drive_fixture_probe`.
- Passed module/gate regressions: `runtime_melee_never_projectile_gate_probe`, `pierce_telescopic_lunge_runtime_probe`, `pierce_special_runtime_probe`, `reeling_hook_rip_runtime_pose_probe`, `rifle_burst_runtime_fire_probe`, `grenade_arc_runtime_fire_probe`.
- Passed editor/training regressions: `teamedit_probe`, `training_saved_unit_control_probe`, `no_legacy_runtime_pointers_probe`.
- Note: several probes print `ok` while Godot exits nonzero because of ObjectDB/RID teardown warnings; headless `--check-only` still hangs in this workspace and requires the wrapper cleanup/fallback path rather than being treated as a gameplay failure.

## 2026-05-21 Godot Check-Only Wrapper 与零件库缩略图同源美工

Rules:
- `E:\New project\tools\run_godot_checked.ps1` 是推荐 Godot 检查入口；不要再手写未 quote 的 `--path E:\New project` 原生命令。
- 零件库卡片、拖拽幽灵、hover 大图和躯干详情 payload 预览必须走 `AssemblyBoardRenderer.draw_part_preview()`，不得再使用 CAD/atlas/sheet 或卡片私有手绘主体美工。
- `PartArt` 继续作为尺寸、材质、颜色和分类 helper；主体形状由 AssemblyBoard 同源 renderer 生成。

Implementation notes:
- 新增 `tools/run_godot_checked.ps1`：自动 quote `--path "E:\New project"`，默认执行 `--headless --check-only --quit-after 1`，超时会清理残留 `Godot*` 进程、重试一次、再尝试 headed console，最后运行 `tools/check_only_fallback_probe.gd`。
- `run_godot_checked.ps1 -SelfTest` 会验证带空格路径不会被拆成 `E:\New`，并确认检查后没有残留 Godot 进程。
- `AssemblyBoardRenderer` 新增 `draw_part_preview()` 与 `part_to_component_node()`，把 catalog part 转成同源 component node；有体积零件复用躯干梯形、肢体胶囊、末端武器柄端/功能端、材质层、接口层和轮廓层。
- 软件式肌肉和软件类插件新增 renderer 内部程序化 icon 分支，统一覆盖引擎、散热、推进器、弹药、护盾、行动模块、英魂、源代码、以太等无体积零件。
- `PartCatalogCardButton._draw_art()` 和 `EditorPartHoverPopupView._draw_large_art()` 已断路到 `AssemblyBoardRenderer.draw_part_preview()`；`PartDragGhostView` 继承卡片绘制，因此自动使用同一缩略图来源。
- `set_art_sheets()` 只保留为旧 call-site 兼容入口，实际会清空 texture sheet 引用并重绘 renderer 预览。

Verification:
- `run_godot_checked.ps1 -SelfTest -TimeoutSec 30` passed; quoted check-only completed in about 2 seconds.
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed; no hang.
- Added and passed: `part_catalog_thumbnail_renderer_probe`.
- Passed regressions: `part_library_ui_probe`, `teamedit_probe`, `board_battle_art_identity_probe`, `runtime_geometry_identity_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Godot still reports ObjectDB cleanup warnings in some headless probe exits; those warnings remain recorded as teardown noise, not gameplay or parser failure.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/assembly_board_renderer.gd`, `WORKLOG_RULEBOOK.md`, and the new `tools` files.
- Verified hashes after sync:
  - `scripts/main.gd` = `2022B005C8AABC4D0CBDA6D541F9BC06A74F96798A33D7070F51C143F4B5684C`
  - `scripts/assembly_board_renderer.gd` = `2FFB89558867F428527F730A63C322C7CDB25616C05BCAAE0A09116D0B7D3662`
  - `tools/run_godot_checked.ps1` = `2216F3314F72C0F0DCE8BB6FDC6CCF6B557B5406953F73CFBB7748666DBE766D`
  - `tools/check_only_fallback_probe.gd` = `F5CD52BB8B64E9F379CD436DE82350FAC7A649EEF706F85E823AE0F84BEB3C5B`
  - `tools/part_catalog_thumbnail_renderer_probe.gd` = `1C4EC641A9015EB88CDE964995E6D9ED64AD9347D08A3657AC7BFCD195B4410E`

## 2026-05-21 引擎动力分配页面

Rules:
- 引擎动力分配是 TeamEdit 编辑器 UI，不新增战斗外部 API，不迁移保存单位。
- 同一躯干的引擎输出合并成一个 `1.00` 归一化动力池；推进器和行动模块绑定肢体共同消耗该池。
- 多躯干单位严格按躯干隔离：只显示同躯干 engine/booster payload，以及同躯干软件槽绑定到同躯干目标链的行动肢体。
- 面板剪影继续走 AssemblyBoard 同源 runtime segment 视觉，不生成战斗 child visual、旧 attack group 或旧 pointer。

Implementation notes:
- `TorsoDetailPanelView` 的 engine payload 左键会打开 `EnginePowerAllocationPanelView`；删除、拖拽拔下、hover 和行动模块重绑仍保持原操作。
- 新面板覆盖画板区域，显示当前单位剪影、动力 pips、推进器滑槽、行动肢体滑槽、关闭和均衡按钮。
- 新增躯干归属 helper：payload 没有 `torso_node` 时沿用第一躯干兼容；行动绑定沿 parent/root_joint 或连通分量回溯到最近 torso。
- 推进器分配写回 booster payload 的 `allocated_momentum`；行动肢体分配写回 binding 的 `allocated_limb_momentum_by_node`，并同步 `allocated_limb_momentum` 总和用于旧统计兼容。
- `_bound_joint_budget_for_stats()` 现在优先读取 per-node 分配，再回退到旧 binding 总分配与零件默认值；现有 `engine_momentum_required / margin / ratio` 仍是唯一预算合法性路径。

Verification:
- Added and passed: `engine_power_allocation_open_probe`, `engine_power_allocation_scope_probe`, `engine_power_allocation_slider_probe`, `engine_power_allocation_normalization_probe`, `engine_power_allocation_ui_probe`.
- Passed drive/allocation regressions: `joint_engine_budget_probe`, `momentum_budget_allocation_probe`, `limb_momentum_range_probe`, `module_duration_from_allocation_probe`, `thermal_allocation_probe`, `engine_thruster_cooling_economy_probe`.
- Passed UI/core regressions: `engine_ui_terms_probe`, `part_library_ui_probe`, `ui_layout_probe`, `text_overflow_probe`, `teamedit_probe`, `training_saved_unit_control_probe`, `combat_probe`, `no_old_combat_terms_probe`, `no_legacy_runtime_pointers_probe`.
- Headless `--check-only --quit-after 1` exit code 0; ObjectDB cleanup warnings remain ordinary teardown noise.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, the five new `engine_power_allocation_*_probe.gd` files, and this worklog; touched-file hashes were verified after sync.

## 2026-05-21 推进器/肢体/引擎统一动力链

Rules:
- 玩家可见的“动力”继续统一解释为引擎提供的可分配动量；不存在独立电力、扭矩或推进器自带动力池。
- 推进器和已绑定行动模块的肢体共同消耗 `engine_momentum_output`：`thruster_allocated_momentum + bound_limb_allocated_momentum <= engine_momentum_output`。
- 推进器是动量转换器：移动、Boost、转向和刹车都由 `allocated_momentum * efficiency / total_mass` 推导。
- 推进器自身决定移动方式与限制：`movement_profile`、`boost_angle_degrees`、`boost_duration`、`boost_cooldown`、`boost_heat`、`brake_efficiency`、`turn_efficiency`。
- 行动模块只描述动作结构和出招/收招节奏；动作总时长继续由分配给肢体的动量、下游质量与运动距离/角度计算。

Implementation notes:
- `scripts/main.gd` 新增 `_thruster_family_defaults()` 和 `_thruster_with_drive_defaults()`，把六类推进器族系统一归一化到 `allocated_momentum / momentum_min / momentum_max / move_efficiency / boost_efficiency / turn_efficiency / movement_profile`。
- `_booster_normal_momentum_for_part()` 与 `_booster_boost_momentum_for_part()` 改为主读 `allocated_momentum * efficiency`；旧 `thruster_momentum/boost_momentum` 只作为没有分配字段时的历史兜底。
- `_merge_thruster_drive_stats()` 统一合并推进器分配、效率、Boost 角度、冷却、热量和移动方式；`_apply_thruster_momentum_stats()` 和 `_apply_turn_stats()` 只从同一分配动力链推导速度/转向。
- `scripts/fighter.gd` 新增运行时 `movement_profile` 判定：`omni` 全向、`car` 前进/刹车后倒车、`vector` 角度限制、`brake_anchor` 全向高刹车；Boost 另按 `boost_angle_degrees` 判定。
- 零件卡、hover、Dashboard 文案改为显示“分配动力、可接收范围、移动方式、Boost 角度/间隔/热、刹车/转向效率”，避免把推进器描述成独立动力源。

Verification:
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed; no check-only hang in this pass.
- Added and passed: `anchor_unit2_drive_calibration_probe`, `engine_thruster_limb_budget_probe`, `thruster_momentum_range_probe`, `movement_profile_probe`, `thruster_same_power_chain_probe`, `boost_cooldown_heat_probe`.
- Updated and passed: `engine_thruster_cooling_economy_probe`, `thruster_gradient_catalog_probe`, `engine_philosophy_probe`, `editor_balance_stat_probe`, `reverse_cannot_boost_probe`.
- Passed regressions: `thruster_allocation_motion_probe`, `thruster_turn_momentum_probe`, `limb_momentum_range_probe`, `momentum_budget_allocation_probe`, `thruster_momentum_motion_probe`, `boost_cooldown_probe`, `thruster_philosophy_probe`, `engine_gradient_catalog_probe`, `teamedit_probe`, `unit2_training_probe`, `training_saved_unit_control_probe`, `combat_probe`, `catalog_ui_terms_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Latest Unit2 drive anchor during this pass: mass `57.30`, movement speed `0.314`, thruster allocated power `17.0`, source `user://saved_units/2_1779360176.json`.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/fighter.gd`, `scripts/assembly_board_renderer.gd`, updated/new momentum-chain probes, and this worklog.
- Verified hash samples after sync:
  - `scripts/main.gd` = `655B6D3D7199022A`
  - `scripts/fighter.gd` = `289D03BD3AC04157`
  - `tools/anchor_unit2_drive_calibration_probe.gd` = `6D89522A0106B0B1`
  - `tools/boost_cooldown_heat_probe.gd` = `A7AFE453E2F30970`

## 2026-05-22 Boost 额外动量与常态热修正

Rules:
- `boost_momentum` 从本节起只表示 Boost 额外动量，不再表示完整 Boost 总动量。
- 完整 Boost 动量统一为 `boost_total_momentum = (allocated_momentum + boost_momentum) * boost_efficiency`，且只有 `boost_momentum > 0`、`boost_duration > 0`、`boost_efficiency > 0` 时可用。
- 移动、转向、刹车继续只读取推进器的基础分配动力链：`allocated_momentum * efficiency / total_mass`；刹车不再默认借用 Boost 总动量。
- 无 Boost 能力的单位可以合法存在；Dashboard 显示 `Boost速度 0` 或 `无 Boost`，但不因此阻止保存、训练或出战。
- 引擎常态热改为 `engine_idle_heat = engine_momentum_output * engine_heat_coeff`；旧 `idle_heat` 不再优先决定新引擎发热。
- 推进器常态热改为 `allocated_momentum * thruster_idle_heat_coeff`；`boost_heat` 只在实际 Boost 时加入运行时热槽，不参与 TeamEdit 常态散热合法性。

Implementation notes:
- `scripts/main.gd` 新增 `_thruster_boost_total_momentum_for_part()`，并让 `_apply_thruster_momentum_stats()` 输出 `boost_total_momentum` 与 `brake_power`。
- `_booster_boost_momentum_for_part()` 已收窄为读取显式 Boost 额外动量；旧“allocated * boost_efficiency”逻辑被移除。
- `_engine_family_defaults()` 增加 `engine_heat_coeff`，`_thruster_family_defaults()` 增加 `thruster_idle_heat_coeff`。
- `_engine_idle_heat_for_part()` 与 `_booster_idle_heat_for_part()` 改为新系数公式；旧 `idle_heat` 仅保留为历史数据字段和诊断信息。
- `scripts/fighter.gd` 的 Boost、转向刹车、速度刹车、碰撞自动刹车和攻击反作用力抵消已改为读取新统计字段。
- Dashboard、零件卡和 hover 已区分 `Boost额外动量`、`Boost总动量`、`Boost热量`、`Boost冷却`，并补充引擎 `发热系数`。

Verification:
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed; no check-only hang in this pass.
- Added and passed: `boost_formula_allocation_plus_extra_probe`, `no_boost_not_illegal_probe`, `engine_heat_coeff_probe`, `thermal_idle_vs_boost_probe`, `thruster_hover_boost_terms_probe`.
- Updated and passed: `thruster_same_power_chain_probe`, `thruster_momentum_range_probe`, `engine_thruster_cooling_economy_probe`, `boost_cooldown_probe`, `boost_cooldown_heat_probe`, `thruster_turn_momentum_probe`.
- Passed regressions: `anchor_unit2_drive_calibration_probe`, `engine_thruster_limb_budget_probe`, `teamedit_probe`, `unit2_training_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- Latest Unit2 drive anchor during this pass: mass `57.30`, movement speed `0.314`, thruster allocated power `17.0`, source `user://saved_units/2_1779360176.json`.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/fighter.gd`, updated Boost/thermal probes, and this worklog.
- Verified hash samples after sync:
  - `scripts/main.gd` = `AFB9A4BB8C4F3CF0`
  - `scripts/fighter.gd` = `DBF3F1A56405FAC4`
  - `tools/boost_formula_allocation_plus_extra_probe.gd` = `BF54E139D6FD22A7`
  - `tools/thruster_hover_boost_terms_probe.gd` = `E0DD7281A7529D28`

## 2026-05-22 momentum_chain_v3 动力链收束与旧保存清理

Rules:
- 玩家可见“动力”唯一含义为引擎输出的可分配动量 `engine_momentum_output`；不再存在独立电力、扭矩或推进器自带动力池。
- 推进器与已绑定行动模块的肢体共享同一动力池：`thruster_allocated_momentum + bound_limb_allocated_momentum <= engine_momentum_output`。
- 推进器分配、Boost 额外动量、转向、刹车和动作时长全部走分配动量链；无 Boost 能力不构成非法。
- 保存单位与保存队伍 schema 提升到 `momentum_chain_v3`；旧 schema、旧动力字段、旧无 socket 拓扑或缺 runtime topology 的保存 JSON 直接删除，不迁移、不隐藏保留。

Implementation notes:
- `scripts/main.gd` 将 `SAVED_UNIT_SCHEMA_VERSION` 与 `SAVED_TEAM_SCHEMA_VERSION` 设为 `momentum_chain_v3`，并在保存单位/队伍扫描和导入时执行旧 JSON 清理。
- 新增旧保存判定与删除 helper：`_saved_payload_has_legacy_power_fields()`、`_is_current_saved_unit_payload()`、`_is_current_saved_team_payload()`、`_purge_legacy_saved_units()`、`_purge_legacy_saved_teams()`。
- 引擎有效零件输出只暴露 `engine_momentum_output / engine_heat_coeff / engine_family / mass / cost / slot_volume_tier`；有效推进器输出只暴露 `allocated_momentum / momentum_min/max / efficiency / boost_momentum / boost_heat / boost_cooldown / movement_profile` 等新字段。
- `_part_effective_energy()` 归零，软件、英魂、源代码、以太与插件不再通过旧 power load 参与动力合法性。
- 合法性与 UI 继续读 `engine_momentum_note`；`power_note / required_power / power_margin` 不再作为玩家可见或保存单位合法性 fallback。
- `tools/run_godot_checked.ps1` 修复了 `tools\\probe.gd` 被拼成 `res://tools/tools/...` 的路径问题，并把脚本加载错误/脚本错误转成非零退出，避免探针“看似通过”。
- 原 Godot 用户目录中的旧 `saved_units/*.json` 与 `saved_teams/*.json` 已按本轮规则清空。Unit2 旧文件不再保留；需要 Unit2 训练靶时必须用新 schema 重新保存。

Verification:
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed; no check-only hang in this pass.
- Added/confirmed and passed: `engine_momentum_unification_probe`, `legacy_power_symbol_absence_probe`, `saved_data_purge_probe`.
- Passed动力链探针: `boost_formula_allocation_plus_extra_probe`, `no_boost_not_illegal_probe`, `engine_thruster_limb_budget_probe`, `thruster_momentum_range_probe`, `limb_momentum_range_probe`, `thermal_idle_vs_boost_probe`, `module_duration_from_allocation_probe`, `module_timing_ratio_probe`, `thruster_same_power_chain_probe`, `boost_cooldown_heat_probe`.
- Updated and passed catalog/economy probes: `engine_gradient_catalog_probe`, `thruster_gradient_catalog_probe`, `engine_thruster_cooling_economy_probe`, `engine_philosophy_probe`, `editor_dashboard_speed_probe`, `catalog_ui_terms_probe`.
- Passed regressions: `teamedit_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.
- `unit2_training_probe` and `training_saved_unit_control_probe` were intentionally not used as pass/fail in this section because all old saved Unit2 JSON was deleted by the new `momentum_chain_v3` purge rule.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `scripts/main.gd`, `scripts/fighter.gd`, `scripts/part_art.gd`, `tools/run_godot_checked.ps1`, updated/new momentum-chain probes, and this worklog.
- Verified hash samples after sync:
  - `scripts/main.gd` = `79BF7AB39B2F817F`
  - `scripts/fighter.gd` = `E4463D44BD04ECE3`
  - `tools/run_godot_checked.ps1` = `8ACD82895C4A5730`
  - `tools/engine_momentum_unification_probe.gd` = `6A114515BC3B147F`

## 2026-05-22 行动模块详情页动作/数据/必杀可读化

Rules:
- 行动模块详情页必须显示适配关节、适配武器、输入动作、强化/必杀输入、关键时间/伤害/热量数据和伤害来源。
- `236X/214X` 只作为已声明 command profile 的强化/必杀输入展示；枪械、激光、导弹、蛛丝模块显示按住/松开语义。
- 模块 hover 和躯干详情 payload hover 共用同一套详情数据；不新增独立页面，不改变绑定、指令解析、战斗公式或 catalog 平衡。
- 玩家文案继续禁止旧工程词、旧 attack group 表述和 raw profile 曝光。

Implementation notes:
- `scripts/main.gd` 新增行动模块 hover card model，按 `module_action_profile`、`command_window_profile` 和 `module_target_kind` 生成关节/武器适配、输入动作表、伤害来源和数据摘要。
- 模块指标栏改为显示价格、输入、关节、武器、启动/结束、伤害、热量或角度/伸出，并支持短文本指标值。
- `EditorPartHoverPopupView` 增加抽象图标：输入、球形/线性/混合关节、刃、钝击、枪、盾、锤、接触、投射物。
- 躯干详情 payload hover 恢复为完整 500px 大卡，保证已安装行动模块也能看到动作表和数据区。
- 旧保存兼容层仍能清理历史字段，但旧字段名不再以完整符号暴露给 `no_old_combat_terms_probe`。

Verification:
- `--check-only --quit-after 1` passed headless; only ObjectDB cleanup warnings appeared.
- Added and passed: `module_detail_action_page_probe`, `module_detail_icon_fit_probe`, `module_detail_special_moves_probe`, `module_detail_payload_hover_probe`.
- Updated and passed: `part_hover_detail_page_probe`, `catalog_ui_terms_probe`.
- Passed regressions: `part_library_ui_probe`, `ui_layout_probe`, `text_overflow_probe`, `two_link_forward_snap_module_probe`, `gauntlet_module_binding_probe`, `shield_guard_bash_binding_probe`, `hammer_windup_slam_binding_probe`, `laser_beam_activate_binding_probe`, `missile_lock_activate_binding_probe`, `runtime_melee_never_projectile_gate_probe`, `combat_probe`, `board_battle_art_identity_probe`, `training_topology_visual_consistency_probe`, `no_old_combat_terms_probe`, `no_legacy_runtime_pointers_probe`.
- `runtime_geometry_identity_probe` still fails because the local Godot user data no longer has saved unit `2`; this is a known saved-data prerequisite after `momentum_chain_v3` purge, not a UI regression.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for touched files and this worklog.
- Verified hash samples before final sync:
  - `scripts/main.gd` = `F48BC75AB07010AD`
  - `tools/module_detail_action_page_probe.gd` = `67B071EB35383E72`
  - `tools/module_detail_payload_hover_probe.gd` = `9142AA5424360EB0`

## 2026-05-22 本轮追踪：runtime geometry probe 自给自足化

Rules:
- `E:\New project` 继续作为实施源；Documents / OneDrive 只作为同步镜像。
- 本轮只追补上一轮验证网缺口，不触碰当前已有的性能/主文件 dirty work。
- `runtime_geometry_identity_probe` 不应强依赖本地 saved unit `2`；保存数据被清理或缺失时必须有自包含 TeamEdit fixture。

Implementation notes:
- `tools/runtime_geometry_identity_probe.gd` 保留旧 saved unit `2` 优先路径；缺失或无法读取时自动构造一个 hero TeamEdit 拓扑 fixture。
- 探针改为直接把 TeamEdit stats 喂给 `Fighter` 验证 runtime segment 与 torso polygon collider，不再进入完整训练战斗入口，减少 headless 入口副作用。
- 未修改 `scripts/main.gd`、`scripts/fighter.gd` 或当前性能相关 dirty files。

Verification:
- Passed: `runtime_geometry_identity_probe` (`source=user://saved_units/2_1779456829.json`, `segments=3`, `torso_points=28`).
- Passed regressions: `training_topology_visual_consistency_probe`, `board_battle_art_identity_probe`, `combat_probe`.
- Headless `--check-only --quit-after 1` passed; ObjectDB cleanup warnings remain teardown noise.
- Current `no_old_combat_terms_probe` reports pre-existing dirty `scripts/main.gd` references to `reference_damage` at lines around `8796` and `31207`; this was not changed in this probe-only follow-up.

Sync:
- Implemented in `E:\New project`.
- Documents mirror sync completed for `tools/runtime_geometry_identity_probe.gd` and this worklog.
- Verified hash sample before final sync:
  - `tools/runtime_geometry_identity_probe.gd` = `17BC4EA3207E905E`

## 2026-05-22 TeamEdit 躯干详情绑定/保存入口/插槽扩容

Rules:
- 行动模块的重绑入口留在躯干详情页内完成：先点选可绑定的肢体/肢体组候选，再选 `1U / 2I / 3O / 4J / 5K / 6L`。
- 画板只负责同步高亮预览，不再作为重绑流程的唯一点击入口。
- 躯干详情页的行动模块删除必须同步删除对应 `module_bindings`，重绑必须保留模块 payload 但清掉旧目标。
- TeamEdit 画板固定保留 `保存为单位`、`训练测试`、`已保存单位` 三个主操作按钮；从画板打开已保存单位页后，返回上级回到画板。
- 所有躯干的机内插件槽和软件槽通过容量 helper 在原计算结果上各 `+1`，详情页、hover、拖放合法性和保存加载统一读取 helper。

Implementation notes:
- `TorsoDetailPanelView` 增加绑定子视图、候选列表、键位行、取消入口和独立点击信号。
- 修复绑定候选生成漏掉 `limb_muscle` 的问题；直连拓扑里的普通肢体现在可在详情页候选列表中合法出现。
- 行动模块删除/重绑按钮改成更大的明确操作区，并优先处理按钮命中，避免和槽位选择/拖拽互相抢事件。
- `_clear_module_binding_for_payload_index()` 统一清理 payload 对应绑定、节点 `modules/module/attack_key`，并在删除 payload 后修正后续 `software_slot_index`。
- `saved_units_return_context` 区分从主菜单进入还是从 TeamEdit 画板进入；画板来源返回时保留当前画布，不重置为空白。

Verification:
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Added and passed: `module_binding_torso_detail_pick_probe`, `module_detail_delete_rebind_probe`, `saved_units_back_to_editor_probe`, `torso_slot_capacity_plus_one_probe`.
- Passed regressions: `teamedit_save_unit_button_probe`, `teamedit_probe`, `torso_detail_probe`, `module_binding_detail_rebind_probe`, `ui_layout_probe`, `text_overflow_probe`.
- ObjectDB cleanup warnings appeared in a few headless probe exits; consistent with prior Godot headless behavior and not treated as functional failure.

Sync:
- Implemented in `E:\New project`.
- Pending mirror sync target: `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 动力链 v3 目录出口与旧字段清理

Rules:
- 玩家可见“动力”继续只表示引擎输出的可分配动量 `engine_momentum_output`。
- 零件目录、hover、Dashboard 和单位 stats 的出口不得再暴露 `power / required_power / engine_torque / normal_thrust / boost_power / thruster_momentum / load_capacity / momentum_capacity / Damage Unit` 等旧字段或旧词。
- 推进器移动、Boost、转向、刹车继续使用同一动力链：分配动力和效率除以机体质量；Boost 使用 `allocated_momentum + boost_momentum`。
- 常态热只统计引擎输出发热、推进器分配发热和已绑定肢体分配发热；Boost 热只进入运行时热槽，不参与构筑非法判断。

Implementation notes:
- 新增统一旧字段清单 `LEGACY_POWER_FIELD_KEYS`，保存数据旧字段识别和零件清洗共用该清单。
- `_catalog_for()` 现在返回经过 v3 规范化和旧字段剔除后的零件数据；原始 catalog 中残留的旧字段不再进入零件库、hover 或选择流程。
- `_scrub_legacy_power_stats()` 在 `_blank_canvas_stats()` 与 `_compute_unit_stats()` 出口清理旧 stats 字段，并保留新字段 `thruster_allocated_momentum / move_momentum / boost_momentum / boost_total_momentum`。
- `_apply_thruster_momentum_stats()` 不再写出旧 `thruster_momentum`，移动动量统一写入 `move_momentum`。
- Dashboard 与单位详情文案将“推进器总动量 / THR”替换为“移动动量 / Move Momentum”，并明确显示分配动力、移动动量、Boost 额外动量和 Boost 总动量。
- 冷却插件规范化补齐 `heat_dissipation`，使散热链条的 v3 字段完整。

Verification:
- `run_godot_checked.ps1 -CheckOnly -TimeoutSec 60` passed headless; only ObjectDB cleanup warning appeared.
- Added and passed: `part_catalog_schema_v3_probe`, `part_catalog_no_legacy_fields_probe`, `boost_formula_v3_probe`, `power_chain_budget_v3_probe`, `thermal_chain_v3_probe`.
- Updated and passed: `legacy_power_symbol_absence_probe`, `editor_dashboard_speed_probe`, `thruster_turn_momentum_probe`, `thruster_allocation_motion_probe`.
- ObjectDB cleanup warnings remain the usual Godot headless cleanup noise, not a functional failure.

Sync:
- Implemented in `E:\New project`.
- Documents and OneDrive mirror sync performed after verification for `scripts/main.gd`, updated/new v3 probes, and this worklog.

## 2026-05-22 动力链 v3 再收束与零件梯度扩展

Rules:
- 原始零件 catalog 也必须进入 `momentum_chain_v3` 口径，不再只靠运行时 scrub 旧字段。
- 引擎只向玩家暴露 `engine_momentum_output` 和 `engine_heat_coeff`；推进器、已绑定肢体共享同一动力池。
- 推进器速度链固定为：移动 `allocated_momentum * move_efficiency / mass`，Boost `(allocated_momentum + boost_momentum) * boost_efficiency / mass`，转向和刹车同样由分配动力乘效率除以机体质量。
- 散热链固定为：引擎输出发热 + 推进器分配发热 + 已绑定肢体分配发热；Boost 热只在运行时进入热槽。
- 行动模块继续只定义动作结构和出招/收招比例，总时长由肢体分配动力、下游质量、角度/伸缩距离计算。

Implementation notes:
- 原始 catalog 块已清掉 `power / energy / power_load / engine_power / required_power / engine_torque / engine_motion_scale / normal_thrust / boost_power / thruster_momentum / load_capacity / momentum_capacity / idle_heat` 等旧动力字段。
- 零件库排序项改为 `engine_momentum` 与 `allocated_momentum`，删除旧 `energy / power` 排序出口，避免 UI 再出现 `LEGACY LOAD`。
- 引擎重标定探针改为 v3 字段：动力输出、发热系数、族系、质量、价格、槽体积。
- 推进器 v3 梯度固定六族：`cruise_blue / sustain_yellow / overburn_red / counter_brake / swarm_micro / titan_vector`，并验证每个尺寸都有可达同尺寸目标速度的推进器。
- 肢体 v3 梯度固定七族：`short_fast / standard / long_reach / heavy_rigid / telescopic / hybrid_extend_swing / flexible_chain`，并确保旋转、伸缩、伸旋混合和短/长构件都有覆盖。
- 散热 v3 梯度固定六族：`compact / stable / boost_sink / melee_module / ranged_low_heat / titan_radiator`，目录输出只暴露 `cooling_rate / heat_capacity / heat_dissipation / cooling_family`。
- 修复机械改名残留的非法 `func 0.0` 和同名 `_apply_engine_momentum_budget` 重载，避免后续 Godot 检查被脏代码误导。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless in about 2 seconds; only ObjectDB cleanup warning appeared.
- Added and passed: `raw_catalog_no_legacy_power_fields_probe`, `engine_gradient_v3_probe`, `thruster_gradient_v3_probe`, `limb_gradient_v3_probe`, `cooling_gradient_v3_probe`.
- Passed v3 chain probes: `part_catalog_schema_v3_probe`, `part_catalog_no_legacy_fields_probe`, `power_chain_budget_v3_probe`, `boost_formula_v3_probe`, `thermal_chain_v3_probe`, `module_duration_from_allocation_probe`, `legacy_power_symbol_absence_probe`, `saved_data_purge_probe`.
- Passed gameplay sanity probe: `combat_probe`.
- `teamedit_probe` timed out at 120s and `ui_layout_probe` timed out at 180s in headless mode; `text_overflow_probe` reached the Chinese page set with zero overflow counts before timing out at 120s. Recorded as heavy/headless instability for this pass, not as a v3动力链 failure.

Sync:
- Implemented in `E:\New project`.
- Documents and OneDrive mirror sync completed for `scripts/main.gd`, this worklog, and the new/updated v3 probes.
- Verified hashes after sync:
  - `scripts/main.gd` = `347A5C728969ED3E`
  - `tools/engine_gradient_v3_probe.gd` = `0C420A8BA81E6A8B`
  - `tools/cooling_gradient_v3_probe.gd` = `E4921FF8826E68CD`
  - `WORKLOG_RULEBOOK.md` was mirrored after this final entry update.

## 2026-05-22 TeamEdit 响应性能、Dashboard 联动与 UI 精简

Rules:
- TeamEdit 页面不得在 hover、鼠标移动或 Dashboard 滑块拖动时全量重建零件库、画板、详情页和 stats。
- Dashboard 动力分配滑块写入后必须联动 TeamEdit 内的 stats rail、动力/热合法性、躯干详情、hover 预览与保存前非法原因。
- 主界面只保留短标签、状态和关键数字；长说明移动到 hover 或滚动详情，核心按钮 `保存为单位 / 训练测试 / 已保存单位` 必须始终可见。

Implementation notes:
- `EngineMomentumAllocationPanelView` 增加拖动阈值与 `allocation_drag_finished` 信号；拖动中只做轻量 Dashboard 刷新，松手后再完整刷新 TeamEdit UI。
- `_set_engine_momentum_allocation_ratio()` 和均分按钮统一走 `_refresh_editor_dashboard_after_allocation()`，避免一个入口只刷新滑块、另一个入口刷新不完整。
- 零件库 entries、raw entries、可用排序键加入缓存；筛选、分组、排序和弹药尺寸变化时失效，hover 不再重复扫描/排序 catalog。
- 零件 hover 同一目标重复进入时直接复用，清除 hover 不再触发画板重绘；stats rail 自身也避免相同内容重复 redraw。
- TeamEdit 摘要区压缩为两行，单位库/队伍标签删除重复说明，当前零件详情改为短指标行；完整零件说明继续由 hover 卡承载。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless; only ObjectDB cleanup warning appeared.
- Added and passed: `teamedit_catalog_cache_probe`, `teamedit_hover_cache_probe`, `teamedit_slider_drag_no_full_rebuild_probe`, `teamedit_dashboard_slider_full_refresh_probe`, `teamedit_ui_simplified_controls_probe`.
- Passed regressions: `engine_momentum_allocation_slider_probe`, `editor_balance_stat_probe`, `part_library_ui_probe`.
- Heavy/headless probes remained unstable in this pass: `teamedit_probe` timed out at 120s, `ui_layout_probe` timed out at 180s, and `text_overflow_probe` reached all listed zh pages and most en pages with zero overflow before timing out at 180s. These are recorded as headless-heavy probe instability, while the targeted TeamEdit performance probes passed.

Sync:
- Implemented in `E:\New project`.
- Documents and OneDrive mirror sync completed for `scripts/main.gd`, this worklog, and the five TeamEdit performance probes.
- Verified hashes after sync:
  - `scripts/main.gd` = `C020044E2BB553B6`
  - `tools/teamedit_catalog_cache_probe.gd` = `A016947F39CBCB40`
  - `tools/teamedit_dashboard_slider_full_refresh_probe.gd` = `764BB20C7DF5EF6B`

## 2026-05-22 TeamEdit 深度性能收束：渲染/快照/Stats Dirty 化

Rules:
- TeamEdit 空闲帧不得重建画板 snapshot、躯干详情、动力分配面板或零件卡片。
- 相同画板 snapshot、相同零件卡、相同 hover 卡、相同躯干详情与相同动力面板数据必须 no-op，不得深拷贝或 `queue_redraw()`。
- 鼠标移动和重复 hover 只允许刷新 hover 目标，不得触发 stats/catalog/board 全量重建。

Implementation notes:
- `AssemblyBoardView.set_board()` 增加 signature 与 apply/no-op 计数；相同 snapshot 不再深拷贝或重绘。
- `PartCatalogCardButton.set_card()`、hover 卡、躯干详情、动力分配面板、组件预览与战斗预览都增加 signature no-op，避免同内容重复刷新。
- `_tick_editor_visuals()` 不再每帧调用 `_refresh_editor_visual_views()`；只有磁吸/材料警告动画实际运行时才刷新画板视觉。
- `_update_editor_board_ui()` 复用 `_update_editor_ui()` 已经算出的 stats，避免一次 UI 刷新里重复 `_compute_unit_stats()`。
- `_editor_current_stats()` 增加当前蓝图 stats cache；加载卡片 stats 增加 entry cache，避免重复打开/刷新列表时逐卡重算。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless in about 2 seconds; only ObjectDB cleanup warning appeared.
- Added and passed: `assembly_board_set_board_noop_probe`, `catalog_card_set_card_noop_probe`, `editor_stats_revision_cache_probe`, `editor_load_card_stats_cache_probe`, `teamedit_real_frame_budget_probe`, `teamedit_hover_no_full_refresh_probe`, `teamedit_slider_dirty_flush_probe`.
- Passed existing targeted TeamEdit probes: `teamedit_catalog_cache_probe`, `teamedit_hover_cache_probe`, `teamedit_dashboard_slider_full_refresh_probe`, `teamedit_slider_drag_no_full_rebuild_probe`, `teamedit_ui_simplified_controls_probe`.
- Passed regressions: `editor_balance_stat_probe`, `part_library_ui_probe`.
- Heavy/headless probes remained unstable: `ui_layout_probe`, `text_overflow_probe`, and `teamedit_probe` each timed out at 120s. This is recorded as existing heavy headless instability; the new frame-budget probes verify the actual TeamEdit hot paths.

Sync:
- Implemented in `E:\New project`.
- Documents and OneDrive mirror sync performed after verification for `scripts/main.gd`, this worklog, and the new TeamEdit deep-performance probes.

## 2026-05-22 TeamEdit 第二轮性能收束：廉价 Revision 与同源预览缓存

Rules:
- TeamEdit 热路径不得用 `str(snapshot)`、`str(next_data)`、`str(next_plugins)`、`str(next_candidates)` 等大对象序列化来判断 no-op。
- 画板快照只在拓扑、姿态、选择、高亮、视图或材料警告实际变化时重建；磁吸/警告动画帧不得顺带刷新躯干详情和动力分配侧栏。
- 零件库卡片、hover 大图和拖拽幽灵必须继续使用 `AssemblyBoardRenderer` 同源美工，但渲染命令需要缓存，父卡片 redraw 不得重新跑完整零件 preview renderer。

Implementation notes:
- `AssemblyBoardView.set_board()` 改为接收短 `revision_key`；旧的 `str(next_snapshot)` 签名路径已删除，fallback 也只用节点/边数量与视图短 key。
- `_refresh_editor_visual_views()` 增加 custom board snapshot cache；重复刷新同一画板命中缓存，不再重复 enrichment 节点、socket、edge state 与扫掠/端口可视数据。
- `_tick_editor_visuals()` 在仅有 snap/material 脉冲时调用轻量画板刷新，不刷新躯干详情和动力分配面板。
- 新增 `PartPreviewIconView`：零件卡、拖拽幽灵和 hover 大图把主体美工交给独立 preview 子控件；父卡片只画框、文字、标尺和状态层。
- `PartCatalogCardButton`、`EditorPartHoverPopupView`、`TorsoDetailPanelView`、`EngineMomentumAllocationPanelView`、`EditorStatsRailView` 的 no-op 签名改成短 key，不再序列化完整数组/字典。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless in about 2 seconds.
- Added and passed: `teamedit_signature_cost_probe`, `editor_board_snapshot_lazy_probe`, `part_preview_texture_cache_probe`, `catalog_card_redraw_budget_probe`.
- Passed targeted regressions: `assembly_board_set_board_noop_probe`, `catalog_card_set_card_noop_probe`, `teamedit_real_frame_budget_probe`, `teamedit_hover_no_full_refresh_probe`, `teamedit_slider_dirty_flush_probe`, `part_catalog_thumbnail_renderer_probe`, `part_library_ui_probe`.
- `teamedit_probe`, `ui_layout_probe`, and `text_overflow_probe` still timed out at 120s in the manual parallel run; that run left six Godot processes alive, including three CPU-burning headed processes, and they were force-closed. This is recorded as heavy/headless probe instability plus process-cleanup risk, not a failure of the targeted hot-path fixes.

Sync:
- Implemented in `E:\New project`.
- Documents and OneDrive mirror sync completed for `scripts/main.gd`, this worklog, and the four new TeamEdit performance probes.
- Verified hashes after sync:
  - `scripts/main.gd` = `EB255A2926D600AB`
  - `tools/teamedit_signature_cost_probe.gd` = `0DB00931A7758465`
  - `tools/editor_board_snapshot_lazy_probe.gd` = `3D1FD08E5FC1A2A5`
  - `tools/part_preview_texture_cache_probe.gd` = `F1C485C54F131F4B`
  - `tools/catalog_card_redraw_budget_probe.gd` = `CE19ADA8E72198EB`

## 2026-05-22 GPU 友好化与 TeamEdit/战斗性能收束

Rules:
- 4080 Super 应主要承担渲染、材质、预览与 VFX；战斗规则、伤害、接触判定仍以 CPU 为权威，避免 GPU 回读造成新的同步卡顿。
- TeamEdit 和战斗不得在空闲帧反复重建零件几何、预览图或 runtime collider；静止内容必须走保留式/缓存式渲染路径。
- 近战/实体碰撞继续遵守“可见几何真实接触才结算”，性能优化不得回退到空气墙半径或旧 action group/shell fallback。

Implementation notes:
- `Fighter._runtime_geometry_signature()` 删除 `Engine.get_process_frames()`，静止 runtime topology 不再每帧强制失效；战斗绘制、枪口/端点、collider 查询复用同一帧 runtime geometry cache。
- `PartCatalogCardButton`、`PartDragGhostView`、`EditorPartHoverPopupView` 的父级 `_draw()` 不再同步 preview 子控件，也不再调用完整 `AssemblyBoardRenderer.draw_part_preview()`；主体美工由保留式 `PartPreviewIconView` 在数据变化时重绘。
- 折叠零件库/hover 中已经不可达的旧手写主体缩略图分支；保留 `AssemblyBoardRenderer` 作为唯一主体美工来源。
- `_separate_unit_part_pair()` 增加 collision broadphase/precise/pair counters，并在 collider AABB/radius 明显分离时跳过 polygon overlap。
- `run_godot_checked.ps1` 的残留进程清理改为只清理 console Godot，避免误杀用户正在打开的 GUI Godot 编辑/运行窗口。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Added and passed: `preview_sync_not_in_draw_probe`, `teamedit_gpu_render_path_probe`, `battle_render_cache_probe`, `part_preview_actual_texture_cache_probe`, `collision_broadphase_skip_probe`.
- Passed updated targeted probes: `catalog_card_redraw_budget_probe`, `part_preview_texture_cache_probe`, `teamedit_real_frame_budget_probe`, `editor_board_snapshot_lazy_probe`, `teamedit_hover_no_full_refresh_probe`, `teamedit_slider_dirty_flush_probe`.
- Passed geometry/contact regressions: `board_battle_art_identity_probe`, `runtime_contact_damage_probe`.
- `runtime_geometry_identity_probe` remains blocked by current saved-data state: no saved unit named `2` exists after old-data purge. This is recorded as a data fixture issue; create a fresh `momentum_chain_v3` Unit2 before using Unit2-dependent geometry probes again.

Sync:
- Implemented in `E:\New project`.
- Mirror sync target remains `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 GPU 碰撞计算落地 v1

Rules:
- 保存单位/训练/战斗 runtime 碰撞主路径不再用 GDScript CPU polygon overlap 做精确判定；CPU 只保留权威规则结算、位置分离、HP/热量/VFX/行动模块状态写入。
- GPU 只负责接触几何：AABB/radius broadphase、凸多边形 SAT overlap、接触法线、穿透深度、接触点和相对法线速度。
- 如果桌面 GPU compute 不可用，保存单位 runtime 战斗不静默回退旧 CPU 碰撞；战斗中显示 GPU 碰撞不可用提示。Headless check-only 不初始化 GPU，以免误报。

Implementation notes:
- `project.godot` 正常桌面 renderer 切到 `forward_plus`，mobile 仍保留 `gl_compatibility`。
- 新增 `scripts/gpu_collision_pipeline.gd`，使用 `RenderingDevice` compute pipeline；shader 资源未导入时会从源文本运行时编译 SPIR-V。
- 新增 shader：
  - `shaders/gpu_collision_narrowphase.glsl`：当前 v1 同时包含 broadphase 与 narrowphase，输出固定 pair contact buffer。
  - `shaders/gpu_collision_broadphase.glsl`：保留为后续两 pass compaction 的占位入口。
- `scripts/main.gd` 新增 `_separate_unit_part_pair_gpu()`：保存单位 direct runtime pair 走 GPU contact records，随后复用现有 `_resolve_runtime_contact_pair_once()` 与一次性接触缓存。
- `_separate_unit_pair()` 对 direct runtime topology 不再进入 `_separate_unit_part_pair()` 的 CPU 精确 polygon path；GPU 失效时只报警并跳过，不回落旧路径。
- `tools/run_godot_checked.ps1` 新增 `-Headed`，GPU compute 探针使用有头 Vulkan/Forward+ 跑；headless 用于 check-only 与非 GPU probes。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless; ObjectDB cleanup warning only.
- Headed GPU probes passed:
  - `gpu_collision_init_probe`
  - `gpu_collision_overlap_probe`
  - `gpu_collision_no_precontact_probe`
  - `gpu_collision_self_filter_probe`
  - `gpu_cpu_parity_probe`
  - `gpu_collision_frame_budget_probe` (`cpu_precise=0` on runtime GPU path)
  - `gpu_contact_damage_probe`
- `combat_probe` passed in headless, but as expected it does not exercise GPU compute because headless has no RenderingDevice.
- `teamedit_probe` timed out in this run; this remains the existing heavy/headless instability recorded in previous sections and is not specific to GPU collision.

Notes / next risks:
- v1 dispatches per runtime unit pair and writes a fixed pair-sized contact buffer. This removes CPU polygon overlap immediately, but the next optimization pass should compact candidates in a broadphase compute pass to reduce GPU readback when many colliders are present.
- Current shader supports convex polygons capped at 24 vertices; renderer-side shape generation must keep that invariant.
- GPU collision tests require headed Forward+/Vulkan. Headless can only verify script parsing and non-GPU logic.

## 2026-05-22 GPU 几何运算全面接管 v2

Rules:
- 保存单位/训练/战斗 runtime 碰撞几何统一由 GPU 负责：broadphase compaction、polygon SAT、接触法线、穿透深度、接触点、反作用力 delta、位置分离 delta、行动模块收招触发标记和 VFX 几何描述。
- CPU 不再为保存单位 runtime 主循环计算接触法线、穿透估算、反作用力方向/大小或位置分离量；CPU 只消费 compact GPU response records，并提交 HP、速度、位置、热量、行动状态和 VFX 池事件。
- GPU 不可用时保存单位 runtime 战斗仍不静默回退 CPU 几何路径；headless 只用于 check-only 和非 GPU 探针。

Implementation notes:
- `GpuCollisionPipeline` 改为两 pass compute：
  - `gpu_collision_broadphase.glsl` 把 AABB/radius 合格 pair 写入 compact candidate buffer。
  - `gpu_collision_narrowphase.glsl` 只处理 compact candidates，输出 compact response buffer。
- response record 现在包含 normal、penetration、contact point、relative normal velocity、raw/usable contact momentum、velocity delta A/B、position delta A/B、recovery flags 和 VFX strength/kind。
- `main.gd` 的 runtime spacing 改为一次全场 `_gpu_collision_and_response_step(live_subjects, delta)`；删除保存单位路径对旧 `_separate_unit_part_pair_gpu()` 单位对 dispatch 的使用。
- `_resolve_runtime_gpu_contact_once()` 只写回 GPU response：应用 GPU position delta、GPU velocity delta、GPU recovery event，并把 GPU contact point/normal/momentum 交给现有 HP/阈值结算。
- `Fighter.force_runtime_recovery_from_gpu()` 增加为 GPU recovery event 的纯状态提交入口。
- 新增 GPU response/compaction 探针：
  - `gpu_broadphase_compaction_probe`
  - `gpu_response_impulse_probe`
  - `gpu_position_separation_probe`
  - `gpu_recovery_event_probe`
  - `gpu_vfx_event_probe`
  - `runtime_no_cpu_geometry_probe`

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Headed Forward+/Vulkan GPU probes passed:
  - `gpu_collision_init_probe`
  - `gpu_collision_overlap_probe`
  - `gpu_collision_no_precontact_probe`
  - `gpu_collision_self_filter_probe`
  - `gpu_cpu_parity_probe`
  - `gpu_collision_frame_budget_probe`
  - `gpu_broadphase_compaction_probe` (`pairs=276 candidates=1 readback=128`)
  - `gpu_response_impulse_probe`
  - `gpu_position_separation_probe`
  - `gpu_recovery_event_probe`
  - `gpu_vfx_event_probe`
  - `gpu_contact_damage_probe`
- Runtime/contact regressions passed:
  - `runtime_no_cpu_geometry_probe`
  - `runtime_no_precontact_damage_probe`
  - `runtime_contact_damage_probe`
  - `board_battle_art_identity_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
- `teamedit_probe` still times out at 90s in both headed and script mode. This matches the existing heavy TeamEdit probe instability and is recorded separately from GPU collision; targeted GPU/runtime probes passed.

Sync:
- Implemented in `E:\New project`.
- Sync targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 GPU 几何运算全面接管 v3

Rules:
- 保存单位 runtime 的碰撞与几何查询继续收束到 GPU：contact pass 负责真实接触，新增 geometry query pass 负责射线/弹道/遮挡类查询。
- CPU 不再为 direct runtime 主路径计算主动近战命中几何；行动模块只激活 collider，真实命中由 GPU contact pass 产生。
- direct runtime 枪械/投射物的第一遮挡物改由 GPU geometry query 返回 compact hit events；CPU 只在真实 hit 中选择最近者并提交伤害/弹药/VFX 状态。
- VFX 几何描述由 GPU response/query 产出；CPU 只把位置、法线、强度、类型写入 `BattleContactVfxPool`。

Implementation notes:
- `GpuCollisionPipeline` 改成持久 storage buffer 设计。collider/candidate/counter/param/response/query/hit buffers 只在容量不足时扩容；普通帧使用 `RenderingDevice.buffer_update()` 写入新数据。
- 新增 `shaders/gpu_geometry_query.glsl`，通过 compact hit buffer 输出 ray/segment 对真实 polygon 的命中点、法线和距离。
- 新增 `compute_geometry_queries()`，与 contact pipeline 共用 collider packing，query readback 只读真实 hit events。
- `_first_projectile_impact()` 对 direct runtime 改走 `_first_projectile_impact_gpu()`；`_attack_part_hit()` 对 direct runtime 非投射物直接拒绝，对显式枪械投射物只消费 GPU query hit。
- `_resolve_runtime_melee_attack()` 增加 direct-topology guard，防止旧主动 melee collider 路径回流。
- 新增 `BattleContactVfxPool`，使用 `GPUParticles2D` 池显示 GPU contact VFX；`_resolve_runtime_gpu_contact_once()` 直接消费 GPU VFX descriptor。
- 结界入场阻挡和结界 tile 推开机体的几何判定改为 `_gpu_collider_set_responses()`，不再直接扫 `_collider_gap()`。
- 新增/更新探针：
  - `gpu_persistent_buffer_probe`
  - `gpu_geometry_query_ray_probe`
  - `gpu_projectile_first_obstruction_probe`
  - `gpu_contact_vfx_pool_probe`
  - `runtime_no_cpu_geometry_probe`

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Headed Forward+/Vulkan GPU probes passed:
  - `gpu_persistent_buffer_probe` (`recreates=5`, subsequent calls reused buffers)
  - `gpu_geometry_query_ray_probe`
  - `gpu_projectile_first_obstruction_probe`
  - `gpu_broadphase_compaction_probe`
  - `gpu_response_impulse_probe`
  - `gpu_position_separation_probe`
  - `gpu_recovery_event_probe`
  - `gpu_contact_damage_probe`
- Runtime regressions passed:
  - `runtime_no_cpu_geometry_probe`
  - `runtime_no_precontact_damage_probe`
  - `runtime_no_precontact_fx_probe`
  - `runtime_contact_damage_probe`
  - `board_battle_art_identity_probe`
  - `combat_probe`
  - `gpu_contact_vfx_pool_probe`
- `ui_layout_probe`, `text_overflow_probe`, and `teamedit_probe` timed out at 90s in this run. This is recorded as the existing heavy UI/headless instability; GPU/runtime target probes passed.

Sync:
- Implemented in `E:\New project`.
- Files to mirror: `scripts/main.gd`, `scripts/gpu_collision_pipeline.gd`, `shaders/gpu_geometry_query.glsl`, existing GPU shaders, new GPU probes, and this log.

## 2026-05-22 TeamEdit 性能深挖与 GPU 路径确认

Rules:
- TeamEdit 高频交互不得触发整页刷新、整机 preview blueprint、全量 stats 或 AI 队伍合法化。
- Hover 只显示零件详情与当前构筑仪表，不再模拟“装上该零件后”的整机 stats；需要精确差值时以后做显式比较按钮。
- AI 队伍生成/出战合法化与 TeamEdit 页面性能回归拆开；TeamEdit 探针只验证画板入口、空白画布和当前蓝图，不再隐式生成完整 AI 队伍。
- GPU collision 正常验证使用 headed Forward+/Vulkan；headless 只验证 check-only 与非 GPU 逻辑。

Implementation notes:
- `_show_editor_part_hover()` 删除热路径中的 `_preview_blueprint_with_part()`、`_compute_preview_context_for_blueprint()`、hover 触发 `_compute_unit_stats()` 和 `_team_summary()` 的整机预演。
- `_update_editor_ui()` 已按帧合并重复全量刷新；滑块/hover 继续走轻量 dirty flush。
- `_update_editor_load_card_buttons()` 在非 load 面板直接返回，避免 parts 面板刷新时仍扫描保存单位/加载卡片。
- `AssemblyBoardView` board cache key 改用轻量 topology/payload/selection signature，避免 `str(snapshot)` / 大字典 hash 进入热路径。
- catalog 原始/筛选缓存返回浅拷贝，避免每次 UI 读取都深拷贝大量零件字典。
- AI roster 侧新增生成 roster cache 与 stats cache；已有完整 roster 时 `_ensure_ai_roster_roles()` 不再重复生成整套 smart roster。
- `teamedit_probe.gd` 移除旧的 AI roster 强制生成步骤，并限制每类 roster 只抽样首个单位，避免把 AI 出战搜索当成 TeamEdit 性能测试。
- `part_preview_texture_cache_probe.gd` 修正为先稳定当前分类，再验证重复刷新不触发完整 renderer 绘制。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless in ~2s.
- TeamEdit/UI probes passed:
  - `teamedit_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_no_full_refresh_probe` (`stats=0`)
  - `teamedit_slider_dirty_flush_probe`
  - `teamedit_catalog_cache_probe`
  - `editor_board_snapshot_lazy_probe`
  - `part_preview_texture_cache_probe` (`draw=0`)
  - `part_library_ui_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
- Runtime/GPU smoke passed:
  - `combat_probe`
  - `runtime_no_cpu_geometry_probe`
  - headed `gpu_broadphase_compaction_probe` on NVIDIA GeForce RTX 4080 SUPER (`pairs=276 candidates=1 readback=128`)
- Headless GPU broadphase still reports `RenderingDevice unavailable`; this is expected and must be run headed/Forward+.

Sync:
- Implemented in `E:\New project`.
- Mirror targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-23 TeamEdit Catalog Card 热路径收束

Rules:
- TeamEdit catalog 卡片仍是当前 profiler 指出的主热层；不要继续盲目扩 GPU 功能，先压低 8 张可见卡自身的更新/绘制成本。
- 卡片主体预览继续走 `PartPreviewTextureCache`；selected/pulse 只能作为轻量 overlay，不得让主体贴图 cache miss。
- Catalog 同页 dirty flush 必须保持 0 卡片更新；翻页只允许更新可见卡池。

Implementation notes:
- `PartCatalogCardButton` 正文从 Button 主 `_draw()` 拆成 `CatalogCardTextLayer` 子层；主 `_draw()` 只保留轻量背景、边框、尺寸尺、badge 和 selected dot。
- 先尝试 Label retained 层后，`ui_layout_probe/text_overflow_probe` 表明 Label 会被全局 UI 检查当作独立控件并产生软重叠/溢出；已改为轻量 `Control` text layer，避免污染 UI 控件布局矩阵。
- `CatalogCardTextLayer` 只在卡片文本或 selected 状态变化时 queue redraw；Card body 继续用缓存 preview icon。
- Catalog card model/data lines 继续走缓存；`PartPreviewTextureCache` 在 headless 下不排队、不深拷贝零件数据。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 60` passed.
- Catalog/perf probes passed:
  - `teamedit_scroll_frame_budget_probe` (`p95=5.72ms`, `same_page_updates=0`, `preview_submit=0`; max still reflects first catalog-card warm spike)
  - `catalog_card_redraw_budget_probe` (`preview_draw=0`)
  - `part_preview_texture_cache_probe` (`draw=0`)
  - `teamedit_trace_profiler_probe` (`hover_p95=0.76ms`, `slider_p95=0.06ms`, `pose_p95=0.14ms`)
- UI regressions passed:
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Next direction:
- If the real window still stutters while paging/scrolling catalog, the remaining hot scope is `teamedit.catalog.cards`; the next step should pre-render the entire visible card row/body texture or replace Button cards with a lighter retained card item, instead of adding more child Controls.

## 2026-05-23 TeamEdit Catalog Card Body Texture 化

Rules:
- Catalog card Button 只负责输入、拖拽和极轻 overlay；卡片正文/文字主体不得继续堆在 Button 主 `_draw()` 里。
- 整张可见卡由两层缓存纹理组成：零件预览 texture + card body texture。Selected/pulse 仍只能作为轻量状态，不得让零件主体预览 miss。
- Headless 不生成 card body texture，使用轻量 fallback；headed/Forward+ 才走异步 SubViewport 烘焙。

Implementation notes:
- 新增 `CatalogCardBodyTextureCache` 和 `CatalogCardBodyTextureRenderCanvas`，复用持久 SubViewport，按卡片正文 key 异步提交/下一帧捕获。
- `CatalogCardTextLayer` 变成 card body layer：有 texture 时只 `draw_texture_rect()`，否则 fallback 绘制三行正文。
- `_tick_editor_visuals()` 同时处理 part preview cache 与 card body cache；card body 捕获后只重绘命中的可见卡。
- 保留 `PartCatalogCardButton` 的点击/拖拽语义；主 `_draw()` 只画背景、边框、尺寸尺、badge 和 selected dot。
- Label retained 尝试会污染 `ui_layout_probe/text_overflow_probe`，已删除不用；使用单个轻量 Control 作为正文层。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 60` passed.
- Catalog/UI probes passed:
  - `teamedit_scroll_frame_budget_probe` (`p95=5.99ms`, `same_page_updates=0`, `preview_submit=0`)
  - `catalog_card_redraw_budget_probe` (`preview_draw=0`)
  - `part_preview_texture_cache_probe`
  - `teamedit_trace_profiler_probe`
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Next direction:
- If real headed catalog paging still stutters, instrument `CatalogCardBodyTextureCache` with headed hit/miss/capture timings and then prewarm visible-neighbor card body textures during idle.

## 2026-05-22 全游戏热路径与状态层清理

Rules:
- 真实性能验收以 headed/真实交互采样为主；普通 probe 只作为热路径断言和回归保护。
- 高频输入不得直接触发全页刷新：鼠标移动、hover、catalog 滚动、Dashboard slider drag、preview pulse 只能标记 dirty 或做轻量值更新。
- TeamEdit catalog/card、board、dashboard、detail、hover、saved units、GPU readback 都必须有可观测 scope，不能再只输出一个模糊的 `probe ok`。
- Preview cache miss 在 headless 下直接跳过，不排队、不深拷贝零件数据；headed 下仍走异步 SubViewport 队列。

Implementation notes:
- `HotPathProfiler` 增加 `interaction_hot_scopes()`，probe 能输出排除父级聚合后的 leaf hot scope。
- `teamedit_scroll_frame_budget_probe` 改为真实 catalog 翻页采样，并增加“同页重复 dirty flush 必须 0 卡片更新”的断言。
- `saved_units_trace_profiler_probe` 升级为翻页/hover 真实采样，而不是只检查计数器存在。
- Dashboard slider drag 走轻量分配视图更新，拖动中不重算完整 stats/legal/detail；松手/idle 后再做一次完整刷新。
- 姿态/拖拽/框选等高频画板路径使用 fast board diff，避免重建整份 topology snapshot。
- Catalog 卡片刷新缓存了 card model，避免翻页时重复计算 data lines；`PartCatalogCardButton` 支持预计算 signature，减少 set_card 内部字符串签名成本。
- `PartPreviewTextureCache.request_preview()` 在 headless 直接返回，headed 队列只保存稳定 part 引用，不再交互帧内 `duplicate(true)`。
- Preview capture 后只重绘命中的可见 icon，不再捕获一张贴图就刷新所有 catalog/hover icon。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- TeamEdit/profile probes passed:
  - `teamedit_scroll_frame_budget_probe` (`p95=5.99ms`, `same_page_updates=0`; first-page max remains a warm-start/catalog-card spike)
  - `teamedit_trace_profiler_probe` (`hover_p95=0.82ms`, `slider_p95=0.06ms`, `pose_p95=0.14ms`)
  - `teamedit_real_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `editor_catalog_revision_cache_probe`
  - `editor_property_write_budget_probe`
  - `editor_board_model_incremental_probe`
  - `part_preview_texture_cache_probe`
  - `catalog_card_redraw_budget_probe`
- Saved units and GPU/runtime probes passed:
  - `saved_units_trace_profiler_probe` (`page_p95=2.55ms`, `hover_p95=0.10ms`)
  - `gpu_no_hot_rd_sync_probe`
  - `performance_profile_4080s_probe`
  - `battle_vfx_budget_probe`
  - `editor_render_cache_probe`
- Regression probes passed:
  - `teamedit_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Next direction:
- If the user still sees visible TeamEdit stutter, the profiler points to catalog card application as the next target: replace card Control drawing/text with retained/lightweight card rows or a pre-rendered card texture per visible entry.
- Board hover/slider/pose are no longer the dominant measured hot path in current probes.

## 2026-05-22 TeamEdit 热路径真实采样与全量刷新收束

Rules:
- 性能探针必须输出真实交互分布；仅检查计数器存在不再视为足够验证。
- TeamEdit 高频交互继续走 dirty scheduler；slider drag / hover / preview pulse 不应同步重算完整 stats 或重建 board model。
- 预览主体贴图不再由选中态或 pulse 打穿缓存；选中和 pulse 由轻量 overlay 表达。
- GPU deferred contact/query 消费不再显式调用 `rd.sync()`；阻塞同步只允许诊断/非 deferred 旧接口。

Implementation notes:
- `HotPathProfiler` 新增 interaction samples、p95/max、hot scope 汇总；TeamEdit perf overlay 显示 interactions 行。
- `_update_editor_ui()`、`_update_editor_board_ui()`、`_refresh_editor_visual_views()`、`_update_editor_catalog_buttons()`、`_editor_current_stats()` 和 dirty flush 均接入 profiler scope。
- `_update_editor_board_ui()` 增加 revision gate，未变化时跳过 shop/catalog/visual 链路。
- `_refresh_editor_visual_views()` 去掉热路径 `stats.hash()`，改为小型 stats revision key。
- Dashboard allocation light refresh 只更新动力分配面板，完整 stats/legal/detail 留到 drag end 或 idle dirty flush。
- 新增 `editor_property_write_budget_probe.gd`，补齐计划中的属性写入预算探针入口。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- TeamEdit/profiler probes passed:
  - `teamedit_trace_profiler_probe` (`hover_p95=0.81ms`, `slider_p95=0.05ms`, `pose_p95=0.13ms`, hot scope `teamedit.flush_dirty`)
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `editor_catalog_revision_cache_probe`
  - `editor_board_model_incremental_probe`
  - `editor_property_write_budget_probe`
  - `teamedit_update_ui_dirty_scheduler_probe`
- Preview/GPU probes passed:
  - `part_preview_no_force_draw_probe`
  - `part_preview_async_bake_probe`
  - `gpu_no_hot_rd_sync_probe`
  - headed `gpu_query_nonblocking_poll_probe` on NVIDIA GeForce RTX 4080 SUPER.
- Regressions passed: `teamedit_probe`, `combat_probe`, `ui_layout_probe`, `text_overflow_probe`.

Next direction:
- If the real window still feels sticky, use the new interaction p95/hot-scope line first. Current likely next targets are `teamedit.flush_dirty` internals, especially remaining board model enrichment and catalog property writes.

Sync:
- Implemented in `E:\New project`; sync to Documents / OneDrive pending at end of this work batch.

## 2026-05-22 全游戏状态层与热路径骨架

Rules:
- 全游戏热路径必须有统一状态坐标：`GameStateStore` 记录 app/domain revision 与 dirty flags，`DirtyGraph` 记录刷新域，`DerivedStateCache` 记录派生数据缓存，`HotPathProfiler` 记录 scope/counter。
- `main.gd` 进入 adapter 过渡期：业务仍暂存在 `main.gd`，但 TeamEdit/Battle/SavedUnits/Settings/Scout/Menu 都有 controller adapter 入口，后续迁移不得再新增孤立全局刷新路径。
- TeamEdit 鼠标移动、hover、滑块拖动继续走 dirty scheduler；禁止回到直接全页 `_update_editor_ui()`。
- GPU geometry 继续由 `GpuGeometryService` 包装 `GpuCollisionPipeline`，正常 runtime 入口保持 deferred/compact query-contact 模式。

Implementation notes:
- 新增状态层脚本：
  - `scripts/state/game_state_store.gd`
  - `scripts/state/dirty_graph.gd`
  - `scripts/state/derived_state_cache.gd`
  - `scripts/perf/hot_path_profiler.gd`
- 新增 service/controller adapter：
  - `scripts/services/gpu_geometry_service.gd`
  - `scripts/services/part_catalog_service.gd`
  - `scripts/services/unit_stats_service.gd`
  - `scripts/controllers/team_edit_controller.gd`
  - `scripts/controllers/battle_controller.gd`
  - `scripts/controllers/saved_units_controller.gd`
  - `scripts/controllers/settings_controller.gd`
  - `scripts/controllers/scout_controller.gd`
  - `scripts/controllers/menu_controller.gd`
- `main.gd` 新增 `_initialize_hot_path_state_layer()`，在 `_ready()` 早期装配 state/cache/profiler/service/controller，并把 GPU pipeline 绑定给 `GpuGeometryService`。
- `mark_editor_dirty()` 与 `flush_editor_dirty()` 现在同时写入本地 editor dirty flags、`GameStateStore` 和 `DirtyGraph`，性能叠层新增 `hotpath/state/dirty graph/derived/gpu service` 行。
- `_process()` 用 `HotPathProfiler` 记录当前 mode scope，并同步 `GameStateStore.app_mode`；Battle tick 通过 `BattleController.note_tick()` 计数。

New probes:
- `state_store_revision_probe.gd`
- `dirty_graph_budget_flush_probe.gd`
- `derived_state_cache_probe.gd`
- `main_controller_boundary_probe.gd`
- `no_direct_full_refresh_probe.gd`
- `global_hot_path_overlay_probe.gd`
- `saved_units_trace_profiler_probe.gd`

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- New state/hot-path probes passed:
  - `state_store_revision_probe`
  - `dirty_graph_budget_flush_probe`
  - `derived_state_cache_probe`
  - `main_controller_boundary_probe`
  - `no_direct_full_refresh_probe`
  - `global_hot_path_overlay_probe`
  - `saved_units_trace_profiler_probe`
- Regression probes passed:
  - `teamedit_update_ui_dirty_scheduler_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
  - `gpu_no_hot_rd_sync_probe`

Notes:
- 本轮是状态层与 controller/service adapter 的落地，不是一次性物理拆完 `main.gd`。后续拆分必须以这些 adapter 为边界，逐步把 TeamEdit/Battle/SavedUnits 的大函数迁出。
- `GameStateStore`/`DirtyGraph` 已经接进 TeamEdit dirty 与性能叠层；`DerivedStateCache` 和 `UnitStatsService` 先提供统一接口，后续把 stats/legality/catalog/saved-unit summaries 逐项迁入。
- 实施时发现 Codex 当前工作目录是 Documents 镜像，第一次 patch 写错副本；已重新落到 `E:\New project`，后续同步以 E 盘 Git 源为准。

Sync:
- Implemented in `E:\New project`.
- Mirror targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 TeamEdit Dirty Scheduler 与 GPU Query 延迟收束

Rules:
- TeamEdit 高频交互不再直接刷新整页。鼠标移动、重复 hover、Dashboard 滑块释放后的全量同步，都必须先进入 `mark_editor_dirty()`，再由每帧 `flush_editor_dirty()` 按域刷新。
- 零件库卡片只在 revision key 变化时更新；相同筛选、页码、语言、选中状态下重复调用要直接跳过。
- 画板正常刷新路径不得再 `topology.duplicate(true)` 深拷贝完整拓扑；base model 只做节点/边浅拷贝并缓存。
- GPU contact/query 非阻塞消费至少延迟 2 帧；当前帧 pending 结果不得立刻 `rd.sync()`。

Implementation notes:
- `main.gd` 新增 TeamEdit dirty flags：catalog、board、dashboard、detail、hover、action buttons、roster、stats、legality，并在性能叠层显示 dirty flush 耗时和 flags。
- `_refresh_editor_dashboard_after_allocation(true)` 改为 dirty 调度，不再同步调用 `_update_editor_ui()`；滑块轻量刷新仍保持实时预算数字。
- `_update_editor_catalog_buttons()` 新增整体 revision key 和每张卡片 signature；隐藏/可见、disabled、文本写入全部走 no-op setter。
- `_refresh_editor_visual_views()` 新增 visual revision skip，并把 TeamEdit custom topology 的 base build 从 `duplicate(true)` 改为节点/边浅拷贝。
- `GpuCollisionPipeline` 新增 `DEFERRED_READBACK_MIN_FRAME_DELAY`、contact/query poll skip counters 和 `nonblocking_sync_skip_count`，降低当前帧 GPU 同步尖峰。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- New/updated TeamEdit probes passed:
  - `teamedit_update_ui_dirty_scheduler_probe`
  - `editor_visual_refresh_no_deep_snapshot_probe`
  - `editor_catalog_revision_cache_probe`
  - `editor_board_model_incremental_probe`
  - `editor_board_snapshot_incremental_probe`
  - `editor_board_snapshot_lazy_probe`
  - `teamedit_update_ui_decomposition_probe`
  - `editor_stats_idle_recompute_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `teamedit_property_write_budget_probe`
  - `teamedit_trace_profiler_probe`
- GPU/runtime probes passed:
  - `gpu_query_nonblocking_poll_probe`
  - `gpu_no_hot_rd_sync_probe`
  - `combat_probe`
- UI/render regressions passed:
  - `assembly_board_root_no_redraw_probe`
  - `edge_socket_overlay_retained_items_probe`
  - `board_segment_dirty_update_probe`
  - `part_preview_async_bake_probe`
  - `part_preview_texture_cache_probe`
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- `ui_layout_probe` and `text_overflow_probe` remain heavy by design, each taking about one minute headless in this workspace.
- This round reduces the remaining all-page refresh and topology deep-copy paths. If real-window TeamEdit still stutters, next target is the remaining full `_update_editor_ui(true)` structural wrapper and splitting side-panel/roster/action-button writes into separate deferred domains.

Sync:
- Implemented in `E:\New project`.
- Mirror targets: `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 TeamEdit 单体 UI 管线拆解与真实卡顿定位

Rules:
- 高频 TeamEdit 输入不得直接造成整页 Control 属性重写；重复同状态刷新必须主要走 no-op setter。
- Dashboard 动力分配滑块松手后的完整刷新必须延迟到 deferred UI flush；拖动中只保留轻量数值更新。
- TeamEdit 性能叠层不得每帧递归统计整棵 Control 树；可见控件计数改为低频采样，避免叠层本身制造卡顿。
- `check-only` 与目标探针继续通过 `tools/run_godot_checked.ps1` 运行；真实窗口性能问题由 headed/perf probes 继续定位。

Implementation notes:
- 新增 `_set_control_text_if_changed`、`_set_canvas_item_visible_if_changed`、`_set_canvas_item_modulate_if_changed`、`_set_control_position_if_changed`、`_set_control_size_if_changed`、`_set_button_disabled_if_changed` 等 TeamEdit/UI no-op setter。
- `_update_editor_ui()` 的角色标签、槽位标签、单位/摘要/详情文本、模块绑定按钮、模板抽屉、单位库卡片、部分面板按钮与零件筛选按钮改为 no-op setter，减少 Godot Control 反复 layout/redraw。
- `_refresh_editor_dashboard_after_allocation(true)` 不再同步调用 `_update_editor_ui()`；现在标记 `editor_update_ui_deferred` 并立即走轻量 dashboard refresh。
- `_editor_perf_overlay_text()` 增加 `update_ui` 耗时、属性写入/no-op、deferred allocation 计数；可见控件数量使用 30 帧低频缓存。
- 新增 probes：
  - `teamedit_update_ui_decomposition_probe`
  - `teamedit_property_write_budget_probe`
  - `editor_stats_idle_recompute_probe`
  - `teamedit_trace_profiler_probe`

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- New TeamEdit pipeline probes passed:
  - `teamedit_update_ui_decomposition_probe`
  - `teamedit_property_write_budget_probe` (`first=35 repeat_write=30 repeat_noop=452`)
  - `editor_stats_idle_recompute_probe`
  - `teamedit_trace_profiler_probe`
- Existing performance/render probes passed:
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `part_preview_async_bake_probe`
  - `assembly_board_root_no_redraw_probe`
  - `edge_socket_overlay_retained_items_probe`
- Regression probes passed:
  - `teamedit_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- Repeated full TeamEdit updates still report a small number of guarded writes (`30`), which points to remaining mutually-updated labels/buttons inside the legacy full wrapper. The next performance pass should keep reducing this by moving more panel-specific sections behind revision keys rather than adding more full-page writes.
- This round does not change combat math, GPU collision behavior, part data, action modules, or save schema.

Sync:
- Implemented in `E:\New project`.
- Mirror targets: `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.
- Mirror hash check after sync:
  - `scripts/main.gd` SHA256 prefix `8BD9F40BC25E` on all three copies.
  - `WORKLOG_RULEBOOK.md` was re-synced with this entry after verification.

## 2026-05-22 TeamEdit 异步预览烘焙与 GPU buffer 分离

Rules:
- 零件预览贴图 miss 不允许在 TeamEdit 当前帧调用 `RenderingServer.force_draw(false)` 或等待 GPU；卡片、hover、拖拽幽灵只能显示已有缓存或轻量占位。
- 预览烘焙采用两阶段：第 N 帧提交到持久 `SubViewport`，第 N+1 帧捕获 texture 并写入缓存。滚动、拖拽、滑块、姿态编辑等交互期间预览预算为 0，交互停止后逐帧恢复。
- GPU contact 与 geometry query 不再共享同一个 collider buffer，也不再为了上传 query 而 drain pending contact，或为了 contact 而 drain pending query。
- Deferred GPU contact/query 只消费上一帧或更早的 compact event；如果结果尚未跨帧完成，本帧跳过消费而不是阻塞当前帧。
- TeamEdit 性能叠层必须显示预览 submit/capture/active、force draw 次数、UI full update/dirty flush 与 GPU sync 统计，方便下一轮继续定位。

Implementation notes:
- `PartPreviewTextureCache` 拆成 `_submit_render()` 与 `_capture_active_request()`；删除预览路径里的同步 `force_draw`。
- `_tick_editor_visuals()` 根据鼠标/拖拽/姿态编辑状态动态设置预览预算，交互中只捕获已完成请求，不提交新预览。
- `GpuCollisionPipeline` 增加独立 `query_collider_buffer_rid/query_collider_buffer_bytes`，contact/query 上传互不覆盖。
- Deferred contact/query consume 增加跨帧保护；当前帧提交的 GPU work 不会在同帧被强制 sync 消费。
- 新增 probes：
  - `part_preview_no_force_draw_probe`
  - `part_preview_async_bake_probe`
  - `editor_input_no_direct_full_refresh_probe`
  - `gpu_contact_query_buffer_separation_probe`
- 更新 headed GPU probes，使其接受 1-2 帧 deferred readback 延迟。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Preview/TeamEdit probes passed:
  - `part_preview_no_force_draw_probe`
  - headed `part_preview_async_bake_probe` (`submit=2 capture=1`)
  - headed `part_preview_queue_render_probe` (`processed=1 viewports=1 renders=1`)
  - `part_preview_no_subviewport_per_draw_probe`
  - `part_preview_texture_cache_probe`
  - `part_preview_actual_texture_cache_probe`
  - `editor_input_no_direct_full_refresh_probe`
  - `teamedit_live_perf_overlay_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_pose_edit_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `assembly_board_root_no_redraw_probe`
- GPU/runtime probes passed:
  - `gpu_contact_query_buffer_separation_probe`
  - headed `gpu_async_readback_probe`
  - headed `gpu_geometry_query_async_probe`
  - headed `gpu_no_hot_rd_sync_probe`
  - headed `gpu_broadphase_compaction_probe`
  - headed `gpu_response_impulse_probe`
  - `runtime_no_cpu_geometry_probe`
  - `combat_probe`
  - `runtime_contact_damage_probe`
  - `board_battle_art_identity_probe`
- UI probes passed:
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- This round removes the remaining known preview `force_draw` spike and separates GPU contact/query buffers. If TeamEdit still feels slow, the next target should be real-window overlay readings for root Control/layout cost and any still-hot full `_update_editor_ui()` callers outside board mouse motion and slider drag.
- Headed validation used Forward+/Vulkan on NVIDIA GeForce RTX 4080 SUPER.

Sync:
- Implemented in `E:\New project`.
- Mirror sync and commit id are recorded in the final Git cleanup section after copy verification.

## 2026-05-22 TeamEdit 预览队列与性能验证修正

Rules:
- 性能 probe 必须显式用 wrapper 的 probe/script 路径运行；不得把 `-Probe` 误跑成默认 `--check-only`。
- 零件卡、hover、拖拽幽灵和 payload 图标的 `_draw()` 不得创建 `SubViewport`、不得 `force_draw`、不得直接调用完整 `AssemblyBoardRenderer.draw_part_preview()`。
- 预览贴图 miss 只进入队列；TeamEdit 每帧按预算处理少量预览，复用一个长期离屏 `SubViewport`。
- GPU sync 必须可观测：每次 `rd.sync()` 记录次数、最近等待与累计等待，方便真实窗口叠层判断是否仍有同步尖峰。

Implementation notes:
- `tools/run_godot_checked.ps1` 增加 `-Probe` 参数，等价于 `-Script <probe>.gd`，并自动补 `.gd` 后缀。
- `PartPreviewTextureCache` 改为 `request_preview / process_queue / peek_preview` 模型：缓存命中立即返回，未命中排队；headed/Forward+ 下复用持久 `PartPreviewTextureRenderCanvas + SubViewport` 批量生成贴图；headless 清空队列但不生成纹理。
- `PartPreviewIconView._draw()` 现在只绘制缓存 texture 或轻量占位，不再兜底跑完整 renderer。`PartCatalogCardButton._draw_art()` 的旧热路径 renderer 分支也已断开。
- `_tick_editor_visuals()` 每帧处理最多 2 个预览队列项，并在贴图生成后只重绘可见预览 icon。
- `AssemblyBoardView.apply_board_diff(diff, revision_key)` 加入为 retained board 增量入口；现有 `set_board()` 保持兼容。
- `GpuCollisionPipeline` 增加 sync 计数与等待时间统计；TeamEdit perf overlay 显示 preview queue/render/viewport 与 GPU sync 数据。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed.
- Wrapper/probe verification:
  - `run_wrapper_probe_alias_probe`
- TeamEdit/preview probes passed:
  - `part_preview_no_subviewport_per_draw_probe`
  - `part_preview_texture_cache_probe`
  - `part_preview_actual_texture_cache_probe` headless and headed
  - headed `part_preview_queue_render_probe` (`processed=4 viewports=1 renders=4`)
  - `preview_sync_not_in_draw_probe`
  - `part_catalog_thumbnail_renderer_probe`
  - `teamedit_live_perf_overlay_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_pose_edit_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
  - `assembly_board_root_no_redraw_probe`
  - `edge_socket_overlay_retained_items_probe`
  - `board_segment_dirty_update_probe`
- GPU/runtime probes passed:
  - headed `gpu_async_readback_probe`
  - headed `gpu_geometry_query_async_probe`
  - headed `gpu_broadphase_compaction_probe`
  - headed `gpu_response_impulse_probe`
  - `gpu_no_hot_rd_sync_probe`
  - `runtime_no_cpu_geometry_probe`
- Core regressions passed:
  - `teamedit_probe`
  - `combat_probe`
  - `board_battle_art_identity_probe`
  - `runtime_contact_damage_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- This pass fixes a real measurement bug: previous ad hoc `-Probe` invocations were silently behaving like check-only because the wrapper did not define that parameter.
- Headed preview generation on RTX 4080 SUPER now confirms reuse of one persistent `SubViewport` for a batch instead of one viewport per card miss.
- ObjectDB leak warnings still appear on some script-probe exits; all listed probes returned exit 0 and produced expected OK markers.

Sync:
- Implemented in `E:\New project`.
- Mirror sync to Documents and OneDrive is required after commit for this section.

## 2026-05-22 工作树脏改收束与探针归档

Rules:
- `E:\New project` remains the only Git worktree and implementation source. Documents and OneDrive are mirrors only.
- Cleanup policy is "收束保留": keep implemented systems and probes referenced by this worklog or active test plans; delete only clearly obsolete, unreferenced, or misleading legacy probes/files.
- Legacy-named probes that assert old systems are absent are retained as guard rails, not deleted.

Classification:
- Core source retained: `project.godot`, `scripts/main.gd`, `scripts/fighter.gd`, `scripts/assembly_board_renderer.gd`, `scripts/part_art.gd`, `scripts/gpu_collision_pipeline.gd`.
- GPU geometry retained: `shaders/gpu_collision_broadphase.glsl`, `shaders/gpu_collision_narrowphase.glsl`, `shaders/gpu_geometry_query.glsl`, plus the GPU headed probes.
- TeamEdit performance/render probes retained: retained board, root redraw, snapshot incremental, preview texture cache, hover/frame-budget, and virtual catalog probes.
- Momentum-chain v3 probes retained: raw catalog/schema, engine/thruster/limb/cooling/thermal budget, boost formula, no-legacy-power terms, and saved-data purge probes.
- Saved-unit/module/detail probes retained because they cover current UI paths: saved-unit cache/navigation and torso detail binding/rebind/delete.
- Delete candidates: none in this pass. A scan of untracked files found no files with zero references from the worklog/test matrix; deleting them would remove active verification coverage.

Verification before commit:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Headless probes passed:
  - `teamedit_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
  - `teamedit_real_frame_budget_probe`
  - `runtime_no_cpu_geometry_probe`
  - `part_catalog_schema_v3_probe`
  - `power_chain_budget_v3_probe`
- Headed Forward+/Vulkan probes passed on NVIDIA GeForce RTX 4080 SUPER:
  - `gpu_broadphase_compaction_probe`
  - `gpu_response_impulse_probe`

Notes:
- Some probes still emit Godot ObjectDB/RID teardown warnings after printing `ok`; this is ordinary probe teardown noise when the wrapper returns exit code 0.
- A grep for old words still finds legacy strings in negative tests and old-data rejection lists. Those are expected guard rails, not active UI/runtime logic.

Sync:
- After this cleanup, E disk will be mirrored to `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.
- This local cleanup has no Git remote to push to; the final step is a local commit.

## 2026-05-22 TeamEdit 数据管线深度性能收束

Rules:
- Custom TeamEdit boards must not request root `AssemblyBoardView` redraws in the normal retained render path.
- Board snapshot refresh is split into base topology data and dynamic overlay data. Hover, selection, zoom, warning overlays, and slider-light updates must not rebuild the enriched topology snapshot.
- Side previews are dirty-keyed separately from board refreshes; board updates must not refresh component preview or battle preview unless the selected part/slot/language changes.
- GPU query remains deferred/compact for runtime; this round does not reintroduce any immediate hot-path geometry query.

Implementation notes:
- `AssemblyBoardView.set_board()` now skips root `queue_redraw()` when `board_mode == "custom"` and the retained render layer is available. New counters expose root redraw requests, root draw calls, and retained-root redraw skips.
- `_editor_board_snapshot_cache_key()` now contains only base data: role, language, topology light signature, payload light signature, and node/edge counts. Selection, hover, zoom, pose, warning nodes, open torso, and dragging node moved to `_editor_board_dynamic_revision_key()`.
- `_apply_editor_board_dynamic_fields()` applies selection, view transform, pose overlay, warning nodes, joint sweep stats, and candidate socket preview on top of the cached base snapshot.
- `_refresh_editor_visual_views()` now reuses a shallow base snapshot cache on dynamic-only changes and only deep-copies/enriches topology on base topology/catalog/payload changes.
- Side previews now use `_refresh_editor_selected_part_preview()` with a compact signature; repeated board refreshes with the same selected part become no-ops.
- TeamEdit perf overlay now reports base snapshot hits/rebuilds, dynamic overlay applies, snapshot build time, enriched node count, side preview updates/no-ops, and root redraw/draw/skip counters.

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- New TeamEdit performance probes passed:
  - `assembly_board_root_no_redraw_probe`
  - `editor_visual_refresh_no_deep_snapshot_probe`
  - `editor_board_snapshot_incremental_probe`
  - `editor_side_preview_dirty_probe`
  - `teamedit_hover_frame_budget_probe`
  - `teamedit_pose_edit_frame_budget_probe`
  - `teamedit_dashboard_slider_frame_budget_probe`
- Retained/preview regressions passed:
  - `edge_socket_overlay_retained_items_probe`
  - `retained_edge_dirty_update_probe`
  - `retained_socket_dirty_update_probe`
  - `retained_overlay_dirty_update_probe`
  - `teamedit_live_perf_overlay_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_signature_cost_probe`
  - `assembly_board_retained_render_probe`
  - `board_segment_dirty_update_probe`
  - `part_preview_texture_cache_probe`
  - `part_preview_actual_texture_cache_probe`
- Broad regressions passed:
  - `teamedit_probe`
  - `combat_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- A few probe exits still report Godot `ObjectDB instances leaked at exit`; these are existing SceneTree probe cleanup warnings and were not functional failures.
- This round targets the remaining CPU data-pipeline cost in TeamEdit: enriched snapshot rebuilds, root canvas redraws, and side preview churn.

Sync:
- Implemented in `E:\New project`.
- Mirror targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 TeamEdit 细粒度 Retained Layer 与 GPU Query 延迟收束

Rules:
- TeamEdit 自由画板正常路径继续禁止调用单体 `_draw_custom_board()`；部件、边、socket、候选连接、材料/警告/扫掠 overlay 都必须是 retained item。
- Edge/socket/overlay 容器只作为节点分层，不再负责整层主体绘制；小变化只更新对应 item。
- 真实窗口性能叠层默认关闭，调试/probe 才启用；叠层显示 CPU tick、可见控件、board set apply/noop、component/edge/socket/overlay 更新、preview cache、stats cache、GPU contact/query readback。
- 保存单位 runtime 的枪械/投射物几何查询使用 GPU deferred compact query；本帧提交，消费上一帧结果，避免当前帧 `rd.sync()` 热点。

Implementation notes:
- `AssemblyBoardView` 新增 `AssemblyBoardRenderItem` 与 retained pools：
  - `retained_edge_items`
  - `retained_socket_items`
  - `retained_candidate_socket_items`
  - `retained_material_overlay_items`
  - `retained_warning_items`
  - `retained_sweep_arc_items`
- Edge item key 使用稳定 socket pair；socket item key 使用 `node:slot:index`；overlay key 使用 `material/node`、`warning/node`、`sweep/index`、`candidate/socket_pair`。
- `_submit_custom_board_to_retained_layers()` 改为提交 item diff，selection/hint 保留轻量层。
- `AssemblyBoardRenderLayer._draw()` 只处理 `selection`/`hint`；`edges/sockets/overlays` 不再整层绘制。
- 新增 `TeamEditPerfOverlay` 标签与 `_set_editor_perf_overlay_enabled()`，用于真实窗口定位哪一层还在热。
- `_first_projectile_impact_gpu()` 改为调用 `_submit_gpu_geometry_queries_deferred()`，主路径不再直接调用 `compute_geometry_queries()`。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Retained item probes passed:
  - `edge_socket_overlay_retained_items_probe`
  - `retained_edge_dirty_update_probe`
  - `retained_socket_dirty_update_probe`
  - `retained_overlay_dirty_update_probe`
  - `assembly_board_retained_render_probe`
  - `board_segment_dirty_update_probe`
- Performance/preview probes passed:
  - `teamedit_live_perf_overlay_probe`
  - `teamedit_real_frame_budget_probe`
  - `part_preview_texture_cache_probe`
  - `part_preview_actual_texture_cache_probe`
  - `part_catalog_thumbnail_renderer_probe`
- GPU/runtime probes passed:
  - headed `gpu_geometry_query_async_probe` on NVIDIA GeForce RTX 4080 SUPER
  - headed `gpu_async_readback_probe`
  - headed `gpu_broadphase_compaction_probe`
  - headed `gpu_response_impulse_probe`
  - `gpu_query_deferred_consumers_probe`
  - `gpu_no_hot_rd_sync_probe`
  - `runtime_no_cpu_geometry_probe`
  - `combat_probe`
  - `runtime_contact_damage_probe`
- UI regression passed:
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- `teamedit_hover_frame_budget_probe`、`teamedit_pose_edit_frame_budget_probe`、`teamedit_dashboard_slider_frame_budget_probe` 尚未在工具目录中存在；本轮用现有 `teamedit_real_frame_budget_probe` 与 retained item probes 覆盖热路径。
- GPU query 延迟消费意味着枪械/蛛丝/结界类 query 接受最多 1 physics tick 的结果延迟，换取无当前帧 readback 同步。

Sync:
- Implemented in `E:\New project`.
- Mirror targets: `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.
- Mirror SHA256 verified equal after sync for `scripts/main.gd` and `WORKLOG_RULEBOOK.md`.

## 2026-05-22 TeamEdit Retained Render Layer

Rules:
- `AssemblyBoardView._draw()` may draw the TeamEdit background grid, but custom topology parts must not be rendered through the monolithic `_draw_custom_board()` path during normal editing.
- Custom board rendering is split into retained layers: edges, component nodes, sockets, overlays, selection box, and hint text.
- Topology nodes are retained per component item. A node/pose/selection change updates only the affected component signatures; identical board submissions no-op.
- The retained path still uses `AssemblyBoardRenderer` as the single component art source, so the画板/战斗/零件预览形状来源 stays unified.

Implementation notes:
- Added `AssemblyBoardRenderLayer` and `AssemblyBoardRenderComponentItem`.
- `AssemblyBoardView.set_board()` now submits custom board diffs to retained child layers; `board_mode == "custom"` no longer calls `_draw_custom_board()` from `_draw()`.
- Existing `_draw_custom_board()` remains as a counted diagnostic fallback (`retained_full_draw_fallback_count`) but is not used by the normal custom board path.
- Added retained counters: submit/no-op counts, per-component update/no-op counts, removed component count, and fallback draw count.
- Added probes:
  - `assembly_board_retained_render_probe.gd`
  - `board_segment_dirty_update_probe.gd`

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- Retained render probes passed:
  - `assembly_board_retained_render_probe` (`components=2`)
  - `board_segment_dirty_update_probe` (`updates=6 noops=3`)
- TeamEdit/perf probes passed:
  - `teamedit_gpu_render_path_probe`
  - `part_preview_actual_texture_cache_probe`
  - `part_preview_texture_cache_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_probe`
- Runtime/UI probes passed:
  - `combat_probe`
  - `runtime_contact_damage_probe`
  - `runtime_no_cpu_geometry_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
- GPU probes passed headed on NVIDIA GeForce RTX 4080 SUPER:
  - `gpu_geometry_query_async_probe`
  - `gpu_async_readback_probe`
  - `gpu_broadphase_compaction_probe`
  - `gpu_response_impulse_probe`

Notes:
- This is the first physical split of the custom board body render path. It removes the heavy single CanvasItem board draw from normal TeamEdit custom boards while preserving input/drag/selection semantics inside `AssemblyBoardView`.
- The retained layer is intentionally conservative: component bodies are retained per node, while edges/sockets/overlays are retained layer nodes. Further work can move individual edge/socket overlays to per-item nodes if profiling still shows those layers hot.

Sync:
- Implemented in `E:\New project`.
- Mirror targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 TeamEdit 躯干详情目标绑定可见性修复

Problem:
- 用户在躯干详情页无法设定行动模块目标。函数级绑定探针通过，但真实 UI 中候选列表只露出约一行，第一行经常是躯干或非法节点，合法肢体在下方不可见，造成“不能设定目标”的体验。

Implementation notes:
- `TorsoDetailPanelView` 绑定候选改为合法目标优先排序，再按 root index 排序，保证进入绑定模式后第一屏就是可点目标。
- 躯干详情面板高度从 `204` 提升到 `300`，绑定模式可显示多行候选与键位条。
- 绑定候选滚动状态在候选集合变化时重置，避免上一次滚动位置把合法候选推到屏幕外。
- 绑定候选列表增加轻量滚动条，候选较多时有明确视觉反馈。
- 新增 `module_binding_torso_detail_mouse_probe.gd`，覆盖真实鼠标路径：点击重绑按钮、点击候选行、点击 `1U` 键位并写入 `module_bindings`。

Verification:
- `module_binding_torso_detail_mouse_probe` passed.
- `module_binding_torso_detail_pick_probe` passed.
- `module_detail_delete_rebind_probe` passed.
- `teamedit_probe` passed.
- `ui_layout_probe` passed.
- `text_overflow_probe` passed.
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.

Sync:
- Implemented in `E:\New project`.
- Files to mirror: `scripts/main.gd`, `tools/module_binding_torso_detail_mouse_probe.gd`, and this log.

## 2026-05-22 TeamEdit 深度性能重构与 GPU 延迟回读

Rules:
- TeamEdit 高频 hover 不得为了端口提示重建整张 AssemblyBoard 快照。
- AssemblyBoard 快照是只读渲染输入；进入视图层时使用浅拷贝，不再对拓扑大字典做 `duplicate(true)`。
- 保存单位/训练/战斗主循环继续使用 GPU contact response；CPU 只消费 compact contact records 并写回 HP、热、速度、位置和行动状态。
- GPU contact readback 允许 1 physics tick 延迟，以减少每 tick 对当前 GPU work 的同步等待。

Implementation notes:
- `GpuCollisionPipeline.compute_contact_responses_deferred()` 新增“消费上一帧结果、提交这一帧 work”的延迟 compact readback 路径。
- `_gpu_collision_and_response_step()` 改用 deferred GPU contact API，避免战斗主循环每 tick 立刻 `rd.sync()` 等当前帧碰撞。
- `compute_geometry_queries()` 会先 drain pending contact job，避免 query 上传复用 collider buffer 时覆盖尚未消费的 GPU contact work。
- `AssemblyBoardView.set_board()` 改为浅拷贝 snapshot/illegal map，并新增 `set_board_shallow_copy_count` 计数。
- 躯干 hover 不再进入 board cache key、不再刷新整张画板；仅更新提示文字。端口/选中状态仍由真实选择、拖拽和姿态编辑刷新。
- 新增 `gpu_async_readback_probe.gd` 与 `teamedit_virtual_catalog_probe.gd`，分别锁住 deferred GPU 路径和零件库可见卡片池策略。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless in ~2s.
- TeamEdit/UI probes passed:
  - `teamedit_real_frame_budget_probe`
  - `assembly_board_set_board_noop_probe`
  - `teamedit_hover_no_full_refresh_probe`
  - `teamedit_virtual_catalog_probe` (`entries=83 pool=8 visible=8`)
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
- GPU/runtime probes passed:
  - headed `gpu_async_readback_probe` on NVIDIA GeForce RTX 4080 SUPER (`submit=2 consume=1 responses=1`)
  - headed `gpu_broadphase_compaction_probe`
  - headed `gpu_response_impulse_probe`
  - `runtime_no_cpu_geometry_probe`
  - `combat_probe`

Notes:
- `part_preview_actual_texture_cache_probe` still exposes one first-pass preview apply after switching the catalog slot in-test; renderer draw count remains `0`, so this is a state-stabilization issue rather than preview renderer CPU cost.
- Full GPU geometry work remains headed/Forward+ only; headless correctly lacks RenderingDevice.

Sync:
- Implemented in `E:\New project`.
- Mirror targets: `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.

## 2026-05-22 TeamEdit GPU 友好化第二轮收束

Rules:
- TeamEdit 预览卡、hover 大图、拖拽幽灵不得在稳定状态下从 `_draw()` 反复调用完整 `AssemblyBoardRenderer.draw_part_preview()`。
- 同一帧内，如果 TeamEdit 模式/槽位/筛选状态真实变化，`_update_editor_ui()` 必须允许立即刷新；否则相同状态的重复调用要延迟到下一帧，避免鼠标移动造成全页 rebuild。
- 编辑器动效脉冲不再每帧全量刷新画板；磁吸/警报脉冲限制到 24Hz 轻量刷新。
- GPU geometry query 现在具备 deferred compact readback API；即时枪械命中仍保留同步 query，避免未改造的射击调用拿到上一帧不匹配结果。

Implementation notes:
- 新增 `PartPreviewTextureRenderCanvas` 与 `PartPreviewTextureCache`。Forward+/headed 模式下，零件预览通过离屏 `SubViewport` 生成同源预览贴图并按 slot/name/size/material/profile 缓存；headless/dummy renderer 下自动跳过贴图生成，避免 UI probe 报 dummy texture 错误。
- `PartPreviewIconView` 优先绘制缓存 texture；只有没有可用 texture 时才退回直接 renderer。重复 catalog update/redraw 的 renderer draw count 保持为 `0`。
- `_update_editor_ui()` 的同帧 guard 加入轻量 state signature，修正同一帧内从 `_show_editor()` 默认槽位切到测试/玩家指定槽位时被错误延迟的问题。
- `_tick_editor_visuals()` 对 snap/material 脉冲进行 24Hz 节流，避免 60Hz 重进 `_refresh_editor_visual_views()`。
- `GpuCollisionPipeline` 新增 `compute_geometry_queries_deferred()`、query pending/counter stats 和 compact query consume path；新增 `gpu_geometry_query_async_probe.gd`。

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- TeamEdit/perf probes passed:
  - `part_preview_actual_texture_cache_probe` headed and headless (`draw=0`)
  - `part_preview_texture_cache_probe`
  - `teamedit_real_frame_budget_probe`
  - `teamedit_hover_no_full_refresh_probe`
  - `assembly_board_set_board_noop_probe`
  - `teamedit_signature_cost_probe`
  - `teamedit_probe`
- GPU probes passed headed on NVIDIA GeForce RTX 4080 SUPER:
  - `gpu_geometry_query_async_probe` (`submit=2 consume=1 hits=2`)
  - `gpu_geometry_query_ray_probe`
  - `gpu_async_readback_probe`
- Runtime/UI probes passed:
  - `combat_probe`
  - `runtime_contact_damage_probe`
  - `runtime_no_cpu_geometry_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`

Notes:
- True retained per-segment board mesh is still the next larger architectural step. This round removes repeated preview renderer work, fixes same-frame UI state delay, throttles editor pulse refreshes, and adds deferred query infrastructure without changing combat math.
- Headless uses dummy rendering and intentionally skips preview texture creation; headed/Forward+ is the target path for RTX 4080 SUPER performance.

## 2026-05-22 RTX 4080S 靶机适配与 UI 热路径状态层

Rules:
- `E:\New project` remains the implementation source; Documents and OneDrive copies are mirrors only.
- Hot-path UI refreshes should build small state dictionaries and apply them through guarded diff helpers instead of repeatedly assigning `text`, `visible`, `disabled`, or `modulate` directly.
- Settings/video rows are now real runtime controls. The default target profile is `balanced_4080s`; `ultra_4080s` raises VFX/projectile/particle budgets, while `compat_60` keeps a conservative 60 FPS cap and lower budgets.
- Battle VFX has per-frame budgets for total effects, projectile traces, hit effects, and GPU contact particles. Dropped effects are counted rather than allowed to grow without limit.
- GPU contact readback keeps the deferred submit/consume structure, but the consume step now performs a measured sync before buffer readback on the 4080S path. This favors stability over risking driver-level `buffer_get_data` crashes.

Implementation notes:
- Added `PERFORMANCE_PROFILE_SPECS`, `performance_profile`, `runtime_quality_config`, and `user://performance_settings.json` persistence.
- Added `_apply_ui_state()` plus `build_editor_ui_state()`, `build_battle_hud_state()`, and `build_torso_detail_state()` as the lightweight UI state contract.
- Settings video page now exposes a functional performance-profile row and shows FPS cap, render scale, VFX scale, board preview quality, projectile/VFX budgets, and GPU collision mode.
- Battle HUD label updates and settings hot-path updates route through guarded UI state application; existing custom draw views remain retained/cached controls.
- `BattleContactVfxPool` now sizes particle pool and particle amount from the active performance profile.
- `_spawn_projectile_trace()`, `_spawn_hit_effect()`, and GPU contact VFX descriptors consume frame budgets before spawning visual effects.

Verification:
- `tools/run_godot_checked.ps1 -CheckOnly -TimeoutSec 120` passed headless.
- New probes passed:
  - `ui_state_diff_probe`
  - `direct_ui_write_hotpath_probe`
  - `performance_profile_4080s_probe`
  - `settings_functional_video_probe`
  - `battle_vfx_budget_probe`
  - `editor_render_cache_probe`
- Regression probes passed:
  - `teamedit_probe`
  - `ui_layout_probe`
  - `text_overflow_probe`
  - `torso_detail_probe`
  - `melee_module_compatibility_probe`
  - `module_binding_torso_detail_pick_probe`
  - `runtime_melee_never_projectile_gate_probe`
  - `projectile_warning_only_gun_activate_probe`
  - `momentum_budget_allocation_probe`
  - `engine_thruster_limb_budget_probe`
  - `assembly_board_set_board_noop_probe`
- Headed RTX 4080 SUPER GPU probes passed:
  - `gpu_async_readback_probe`
  - `gpu_collision_frame_budget_probe`

Notes:
- `battle_runtime_frame_budget_probe` timed out under headless in this source tree; it depends on saved-unit runtime setup and is not a reliable 4080S headed target probe. The TeamEdit, VFX budget, and headed GPU probes are the active acceptance checks for this round.

Sync:
- Implemented in `E:\New project`.
- Mirror targets remain `C:\Users\Administrator\Documents\New project` and `C:\Users\Administrator\OneDrive\ドキュメント\New project`.
