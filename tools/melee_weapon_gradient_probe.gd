extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _family_for(main, part: Dictionary, damage_type: String) -> String:
	if damage_type == "tear":
		return main._blade_weapon_family_for_part(part)
	if damage_type == "blunt":
		return main._blunt_weapon_family_for_part(part)
	if damage_type == "pierce":
		return main._pierce_weapon_family_for_part(part)
	return ""


func _check_family(main, damage_type: String, family: String) -> void:
	var count := 0
	var min_length := INF
	var max_length := -INF
	var min_mass := INF
	var max_mass := -INF
	var min_stiffness := INF
	var max_stiffness := -INF
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		var material_class := String(part.get("material_class", "")).to_lower()
		if not bool(part.get("terminal_weapon", false)) and material_class != "weapon":
			continue
		if String(part.get("damage_type", "")).to_lower() != damage_type:
			continue
		if _family_for(main, part, damage_type) != family:
			continue
		if main._terminal_weapon_kind_for_part(part, "muscle") != "melee":
			_fail("%s/%s contains a non-melee terminal: %s" % [damage_type, family, String(part.get("name", ""))])
		if bool(part.get("projectile", false)) or bool(part.get("projectile_only", false)):
			_fail("%s/%s must not expose projectile flags: %s" % [damage_type, family, String(part.get("name", ""))])
		for required_key in ["stiffness_momentum", "damage_coeff", "break_coeff", "contact_shape_kind", "size_tier"]:
			if not part.has(required_key):
				_fail("%s/%s missing %s on %s" % [damage_type, family, required_key, String(part.get("name", ""))])
		count += 1
		var length := float(part.get("length", 0.0))
		var mass := float(part.get("mass", 0.0))
		var stiffness := float(part.get("stiffness_momentum", 0.0))
		min_length = minf(min_length, length)
		max_length = maxf(max_length, length)
		min_mass = minf(min_mass, mass)
		max_mass = maxf(max_mass, mass)
		min_stiffness = minf(min_stiffness, stiffness)
		max_stiffness = maxf(max_stiffness, stiffness)
	if count < 3:
		_fail("%s/%s needs at least three gradient parts, found %d." % [damage_type, family, count])
	if max_length <= min_length or max_mass <= min_mass or max_stiffness <= min_stiffness:
		_fail("%s/%s gradient must increase length, mass, and stiffness." % [damage_type, family])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for family in ["scythe", "katana", "greatsword"]:
		_check_family(main, "tear", family)
	for family in ["gauntlet", "shield", "hammer"]:
		_check_family(main, "blunt", family)
	for family in ["lance", "rapier", "drill"]:
		_check_family(main, "pierce", family)
	print("MELEE_WEAPON_GRADIENT_PROBE ok")
	quit()
