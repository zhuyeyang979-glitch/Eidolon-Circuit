extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legacy := ["power", "energy", "power_load", "engine_power", "required_power", "engine_torque", "engine_motion_scale", "normal_thrust", "boost_power", "thruster_momentum", "load_capacity", "momentum_capacity", "damage_unit_threshold", "reference_damage"]
	for slot_key in ["torso", "limb_muscle", "muscle", "barrier_panel", "engine", "booster", "cooling", "module", "ammo", "special"]:
		for part in main._catalog_for("hero", slot_key):
			if not (part is Dictionary):
				continue
			var dict := Dictionary(part)
			for key in legacy:
				if dict.has(key):
					_fail("%s/%s exposes legacy field %s" % [slot_key, String(dict.get("name", "?")), key])
	print("PART_CATALOG_NO_LEGACY_FIELDS_PROBE ok")
	quit()
