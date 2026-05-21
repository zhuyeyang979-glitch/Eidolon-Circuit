extends SceneTree

const MainScene := preload("res://scripts/main.gd")


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

	var hero = _spawn_unit(main, 1, "hero", "Probe Soul Launcher", 1.0, 0.0, {
		"module_effect": "soul_cast_transfer",
		"identity_receiver_role": "puppet",
		"identity_receiver_order": 0,
		"switch_cooldown": 0.1,
	})
	var receiver = _spawn_unit(main, 1, "puppet", "Probe Receiver", 1.24, 0.05, {
		"ai": "guard_orbit",
	})
	var soul_started := main._try_soul_cast_transfer(hero)
	var soul_plan: Dictionary = main.get_meta("last_identity_transfer_plan", {})
	if soul_started and not soul_plan.is_empty():
		main._finish_identity_transfer(soul_plan)
	var soul_ok: bool = soul_started and main.active_units[1]["hero"] == receiver and String(hero.role) == "puppet"

	main._clear_all_units()
	var barrier = _spawn_unit(main, 1, "barrier", "Probe Barrier Gate", 2.0, 0.0, {
		"module_effect": "role_form_shift",
		"role_form_target_role": "cycle_mech_barrier",
		"role_form_mech_role": "puppet",
		"switch_cooldown": 0.1,
	})
	var form_started := main._try_role_form_shift(barrier)
	if form_started and String(barrier.role) == "barrier":
		main._finish_role_form_shift(barrier, "puppet")
	var form_ok: bool = form_started and String(barrier.role) == "puppet" and main.active_units[1]["puppet"].has(barrier)

	main._clear_all_units()
	var lead = _spawn_unit(main, 1, "hero", "Probe Triad Lead", 3.0, 0.0, {
		"module_effect": "combine",
		"combine_partner_count": 2,
		"combine_max_partners": 2,
		"combine_range": 0.7,
		"combine_bonus_hp": 30,
		"combine_shape": "crab",
	})
	var partner_a = _spawn_unit(main, 1, "puppet", "Probe Dock A", 3.18, 0.06, {"module_effect": "combine"})
	var partner_b = _spawn_unit(main, 1, "puppet", "Probe Dock B", 2.84, -0.05, {"module_effect": "combine"})
	var combine_started := main._try_combine_or_separate(lead)
	var combined_ok: bool = combine_started and bool(lead.get_meta("combined", false)) and not main.active_units[1]["puppet"].has(partner_a) and not main.active_units[1]["puppet"].has(partner_b)
	var separated_started := main._try_combine_or_separate(lead)
	var separated_ok: bool = separated_started and not bool(lead.get_meta("combined", false)) and main.active_units[1]["puppet"].size() >= 2

	print("IDENTITY_MODULE_PROBE soul=%s form=%s combine=%s separate=%s" % [
		str(soul_ok),
		str(form_ok),
		str(combined_ok),
		str(separated_ok),
	])
	if not soul_ok:
		push_error("Soul cast transfer failed")
	if not form_ok:
		push_error("Role form shift failed")
	if not combined_ok:
		push_error("Multi-unit combine failed")
	if not separated_ok:
		push_error("Combine separation restore failed")
	quit()
