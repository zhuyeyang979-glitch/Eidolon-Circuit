extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, name: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == name:
			return part
	return {}


func _check_family(main, names: Array, family: String, flag: String, min_angles: Array) -> void:
	var last_mass := -1.0
	var last_hp := -1.0
	for i in range(names.size()):
		var part := _part(main, String(names[i]))
		if part.is_empty():
			_fail("Missing blunt gradient part: %s" % String(names[i]))
		if String(part.get("weapon_family", "")) != family or not bool(part.get(flag, false)):
			_fail("%s must expose %s family fields." % [String(names[i]), family])
		if bool(part.get("projectile", false)) or bool(part.get("projectile_only", false)):
			_fail("%s must remain melee-only." % String(names[i]))
		if main._terminal_weapon_kind_for_part(part, "muscle") != "melee":
			_fail("%s must be a melee terminal." % String(names[i]))
		var profile: Dictionary = main._embedded_joint_profile_for_part(part, "muscle")
		if String(profile.get("kind", "")) != "ball":
			_fail("%s must use an embedded ball joint." % String(names[i]))
		if float(profile.get("angle", 0.0)) < float(min_angles[i]):
			_fail("%s joint angle is below gradient expectation." % String(names[i]))
		if float(part.get("mass", 0.0)) <= last_mass or float(part.get("hp", 0.0)) <= last_hp:
			_fail("%s gradient must be strictly increasing in mass and HP." % family)
		last_mass = float(part.get("mass", 0.0))
		last_hp = float(part.get("hp", 0.0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_check_family(main, ["BUCKLER RAM SHIELD", "AURORA BASH SHIELD", "COLOSSUS TOWER SHIELD"], "shield", "blunt_shield", [90, 120, 90])
	_check_family(main, ["LIGHT IRON HAMMER", "GRAVITY HAMMER", "SIEGE IRON HAMMER", "COLOSSUS ARENA MAUL"], "hammer", "blunt_hammer", [120, 150, 180, 180])
	print("BLUNT_WEAPON_GRADIENT_PROBE ok")
	quit()
