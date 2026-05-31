extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var required_volume_fields := ["mass", "hp", "size_tier", "contact_shape_kind", "stiffness_momentum", "damage_coeff", "break_coeff"]
	var volume_slots := ["torso", "limb_muscle", "muscle", "barrier_panel"]
	for slot_key in volume_slots:
		for part in main._catalog_for("hero", slot_key):
			if not (part is Dictionary):
				continue
			if not main._component_has_combat_volume(Dictionary(part), slot_key):
				continue
			for key in required_volume_fields:
				if not Dictionary(part).has(key):
					_fail("%s/%s missing v3 volume field %s" % [slot_key, String(Dictionary(part).get("name", "?")), key])
	var engine: Dictionary = main._selected_component("hero", "engine", 0)
	for key in ["engine_momentum_output", "engine_heat_coeff", "engine_family", "mass", "cost", "slot_volume_tier"]:
		if not engine.has(key):
			_fail("Engine missing v3 field %s" % key)
	var booster: Dictionary = main._selected_component("hero", "booster", 0)
	for key in ["momentum_min", "momentum_max", "allocated_momentum", "move_efficiency", "boost_efficiency", "turn_efficiency", "brake_efficiency", "boost_momentum", "boost_duration", "boost_cooldown", "boost_heat", "boost_angle_degrees", "movement_profile", "thruster_family"]:
		if not booster.has(key):
			_fail("Thruster missing v3 field %s" % key)
	var cooling: Dictionary = main._selected_component("hero", "cooling", 0)
	for key in ["cooling_rate", "heat_capacity", "heat_dissipation", "mass", "cost", "slot_volume_tier"]:
		if not cooling.has(key):
			_fail("Cooling missing v3 field %s" % key)
	print("PART_CATALOG_SCHEMA_V3_PROBE ok")
	quit()
