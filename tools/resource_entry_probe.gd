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

	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	var shield_index := _component_index("muscle", "SHIELD DUEL HALO")
	if shield_index < 0:
		_fail("Shield payload catalog item missing.")
	main.editor_catalog_page = int(floori(float(shield_index) / float(main.editor_catalog_buttons.size())))
	main._select_catalog_component(shield_index % main.editor_catalog_buttons.size())
	var bp: Dictionary = main._blueprint_for(1, "hero", int(main.editor_unit_indices["hero"]))
	var installed := false
	for raw_payload in Array(bp.get("slot_payloads", [])):
		if raw_payload is Dictionary and String(Dictionary(raw_payload).get("kind", "")) == "electronic_armor":
			installed = true
	if not installed:
		_fail("Shield payload was not installed into torso slot from the shop.")
	var shield_stats := main._compute_unit_stats(1, "hero", int(main.editor_unit_indices["hero"]))
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
	main.hitstop_timer = 0.0
	main._apply_melee_momentum_stagger_pair(stagger_a, 180.0, stagger_b, 20.0, Vector2.RIGHT, "probe")
	if main.hitstop_timer < MainScene.MELEE_STAGGER_HITSTOP_SECONDS - 0.01:
		_fail("Melee stagger did not create 0.5s hitstop.")

	print("RESOURCE_ENTRY_PROBE barrier=(%.2f,%.2f) ammo=%d shield=%.1f projectile=%d hitstop=%.2f" % [
		float(barrier.ring_pos),
		float(barrier.lane),
		main._current_ammo(hero, "bullet"),
		float(shield_stats.get("electronic_armor_max", 0.0)),
		projectile_damage,
		main.hitstop_timer,
	])
	quit()
