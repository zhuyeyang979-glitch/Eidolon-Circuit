extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var families := {"scythe": false, "katana": false, "greatsword": false}
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_blade_weapon(part):
			continue
		if main._terminal_weapon_kind_for_part(part, "muscle") != "melee":
			continue
		if main._part_damage_coeff(part, "muscle") <= 0.0 or main._part_stiffness(part, "muscle") <= 0.0:
			_fail("Blade weapon lacks combat coefficients: %s" % String(part.get("name", "")))
		var family := main._blade_weapon_family_for_part(part)
		if families.has(family):
			families[family] = true
	for family in families.keys():
		if not bool(families[family]):
			_fail("Missing blade family in catalog: %s" % family)
	print("BLADE_WEAPON_CATALOG_PROBE ok")
	quit()
