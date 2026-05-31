extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _component_index(slot_key: String, name: String) -> int:
	for i in range(MainScene.COMMON_CATALOG[slot_key].size()):
		var part = MainScene.COMMON_CATALOG[slot_key][i]
		if part is Dictionary and String(Dictionary(part).get("name", "")) == name:
			return i
	return -1


func _component_index_for_role(main, role_key: String, slot_key: String, name: String) -> int:
	var index: int = int(main._component_index_by_name(role_key, slot_key, name, -1))
	if index < 0:
		_fail("Missing %s catalog item for %s/%s." % [name, role_key, slot_key])
	return index


func _barrier_probe_blueprint(main) -> Dictionary:
	var wall_index: int = _component_index_for_role(main, "barrier", "muscle", "MAZE HARDLIGHT CAGE WALL PANEL")
	return {
		"name": "Resource Entry Barrier Probe",
		"archetype": "custom",
		"special": 0,
		"joint": 30,
		"limb_muscle": 0,
		"muscle": wall_index,
		"booster": 0,
		"engine": 0,
		"cooling": 5,
		"module": 10,
		"barrier_tiles": [{"index": 0, "muscle": wall_index}],
	}


func _projectile_hero_blueprint(main) -> Dictionary:
	var unit: Dictionary = main._ai_starter_unit("Resource Entry Ammo")
	var topology: Dictionary = Dictionary(unit.get("custom_topology", {}))
	var nodes: Array = Array(topology.get("nodes", []))
	if nodes.is_empty():
		_fail("Starter projectile hero topology missing nodes.")
	var torso_node: int = 0
	var bullet_ammo_index: int = _component_index_for_role(main, "hero", "muscle", "BULLET DRUM AMMO BAY")
	unit["name"] = "Resource Entry Ammo Hero"
	unit["slot_payloads"] = Array(unit.get("slot_payloads", []))
	unit["slot_payloads"].append({
		"kind": "ammo",
		"muscle": bullet_ammo_index,
		"part_name": "BULLET DRUM AMMO BAY",
		"ammo_size_tier": "XS",
		"torso_node": torso_node,
		"internal_slot_index": 0,
	})
	return unit


func _shield_hero_blueprint(main) -> Dictionary:
	var unit: Dictionary = main._ai_starter_unit("Resource Entry Shield")
	var topology: Dictionary = Dictionary(unit.get("custom_topology", {}))
	var nodes: Array = Array(topology.get("nodes", []))
	if nodes.is_empty():
		_fail("Starter shield hero topology missing nodes.")
	var shield_index: int = _component_index_for_role(main, "hero", "muscle", "SHIELD DUEL HALO")
	unit["name"] = "Resource Entry Shield Hero"
	unit["slot_payloads"] = Array(unit.get("slot_payloads", []))
	unit["slot_payloads"].append({
		"kind": "electronic_armor",
		"muscle": shield_index,
		"part_name": "SHIELD DUEL HALO",
		"torso_node": 0,
		"internal_slot_index": 1,
	})
	return unit


func _spawn_unit(main, owner: int, role_key: String, unit_name: String, ring: float, lane: float, overrides: Dictionary):
	var stats: Dictionary = main._compute_unit_stats(owner, role_key, 0).duplicate(true)
	for key in overrides.keys():
		stats[key] = overrides[key]
	var unit = main._create_unit(owner, role_key, stats, unit_name, ring, lane)
	main._assign_unit_role(unit, role_key)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.runtime_resource = {1: 999.0, 2: 999.0}
	main.victory_points = {1: 0, 2: 0}
	main.blueprints[1]["barrier"] = [_barrier_probe_blueprint(main)]
	main.blueprints[1]["hero"] = [_projectile_hero_blueprint(main)]
	main.blueprints[2]["hero"] = [_projectile_hero_blueprint(main)]
	main.active_roster_indices[1]["barrier"] = 0
	main.active_roster_indices[1]["hero"] = 0
	main.active_roster_indices[2]["hero"] = 0

	main.player_camera_centers[1] = 3.25
	main.player_camera_lanes[1] = 0.9
	var summoned := main._summon_role(1, "barrier", true, false)
	if not summoned:
		_fail("Barrier pending summon was rejected.")
	main.player_camera_centers[1] = 8.0
	main.player_camera_lanes[1] = -1.1
	main._tick_deploys(4.2)
	var barrier = main.active_units[1]["barrier"]
	if not main._is_live_unit(barrier):
		_fail("Pending barrier did not finish deploy.")
	if absf(float(barrier.ring_pos) - 3.25) > 0.02 or absf(float(barrier.lane) - 0.9) > 0.02:
		_fail("Barrier used moved camera instead of summon snapshot: %.2f %.2f" % [float(barrier.ring_pos), float(barrier.lane)])

	var hero_stats: Dictionary = main._compute_unit_stats(1, "hero", 0)
	if int(Dictionary(hero_stats.get("ammo_capacity", {})).get("bullet", 0)) <= 0:
		_fail("Default projectile hero should have consumable integrated bullet ammo.")
	var hero = _spawn_unit(main, 1, "hero", "Ammo Hero", 1.0, 0.0, {})
	var ammo_before := main._current_ammo(hero, "bullet")
	var event := {
		"projectile": true,
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
	}
	if not main._consume_ammo_for_event(hero, event):
		_fail("Hero failed to consume available bullet ammo.")
	if main._current_ammo(hero, "bullet") != ammo_before - 1:
		_fail("Ammo did not decrement exactly once.")
	hero.tick(1.0, MainScene.RING_LENGTH)
	if main._current_ammo(hero, "bullet") != ammo_before - 1:
		_fail("Ammo regenerated without a support station.")
	var resource_before_refill := float(main.runtime_resource[1])
	var unit_price := float(main._ammo_unit_price("bullet"))
	var refill_result: Dictionary = main._paid_refill_ammo(hero, "bullet", 1)
	if int(refill_result.get("refilled", 0)) != 1 or main._current_ammo(hero, "bullet") != ammo_before:
		_fail("Paid support-style ammo refill did not restore exactly one bullet.")
	if absf(float(main.runtime_resource[1]) - (resource_before_refill - unit_price)) > 0.01:
		_fail("Paid ammo refill did not charge the catalog unit price.")
	main.unit_set_ammo(hero, "bullet", ammo_before - 1)
	main.runtime_resource[1] = 0.0
	var unpaid_result: Dictionary = main._paid_refill_ammo(hero, "bullet", 1)
	if int(unpaid_result.get("refilled", 0)) != 0 or String(unpaid_result.get("reason", "")) != "resource":
		_fail("Ammo station refill should fail when the player cannot pay.")
	main.runtime_resource[1] = resource_before_refill - unit_price
	main.unit_set_ammo(hero, "bullet", ammo_before)
	main.active_units[1]["hero"] = hero
	main._update_battle_ui()
	if main.hero_ammo_labels.get(1, null) == null or not main.hero_ammo_labels[1].visible:
		_fail("Hero ammo label is not visible in battle HUD.")
	if String(main._unit_status_text(hero, "Hero")).contains(main._ui_term("ammo")):
		_fail("Ammo should not be embedded in generic unit status text.")

	var bp: Dictionary = _shield_hero_blueprint(main)
	var installed := false
	for raw_payload in Array(bp.get("slot_payloads", [])):
		if raw_payload is Dictionary and String(Dictionary(raw_payload).get("kind", "")) == "electronic_armor":
			installed = true
	if not installed:
		_fail("Shield payload fixture did not install electronic armor.")
	var shield_stats := main._compute_unit_stats(1, "hero", -1, bp)
	if float(shield_stats.get("electronic_armor_max", 0.0)) <= 0.0:
		_fail("Installed shield payload did not contribute shield stats.")

	var projectile_target = _spawn_unit(main, 2, "hero", "Projectile Target", 2.0, 0.0, {
		"health": 100,
		"resistances": {},
		"electronic_armor_max": 0.0,
	})
	var projectile_event := {
		"projectile": true,
		"damage_type": "laser",
		"target_part_kind": "torso",
	}
	var projectile_damage := main._projectile_material_adjusted_damage(projectile_target, projectile_event, 8)
	if projectile_damage <= 0 or bool(projectile_event.get("contact_gate_blocked", false)):
		_fail("Projectile material adjustment should not use legacy contact threshold gates.")

	var stagger_a = _spawn_unit(main, 1, "hero", "Heavy Hit", 4.0, 0.0, {"melee_stability_threshold": 10.0, "mass": 120.0})
	var stagger_b = _spawn_unit(main, 2, "hero", "Light Receiver", 4.4, 0.0, {"melee_stability_threshold": 10.0, "mass": 20.0})
	stagger_a.set_meta("local_hitstop_timer", 0.0)
	stagger_b.set_meta("local_hitstop_timer", 0.0)
	main._apply_melee_momentum_stagger_pair(stagger_a, 180.0, stagger_b, 20.0, Vector2.RIGHT, "probe")
	var local_hitstop := maxf(float(stagger_a.get_meta("local_hitstop_timer", 0.0)), float(stagger_b.get_meta("local_hitstop_timer", 0.0)))
	if local_hitstop < MainScene.MELEE_STAGGER_HITSTOP_SECONDS - 0.01:
		_fail("Melee stagger did not create 0.5s local hitstop.")

	print("RESOURCE_ENTRY_PROBE barrier=(%.2f,%.2f) ammo=%d shield=%.1f projectile=%d hitstop=%.2f" % [
		float(barrier.ring_pos),
		float(barrier.lane),
		main._current_ammo(hero, "bullet"),
		float(shield_stats.get("electronic_armor_max", 0.0)),
		projectile_damage,
		local_hitstop,
	])
	quit()
