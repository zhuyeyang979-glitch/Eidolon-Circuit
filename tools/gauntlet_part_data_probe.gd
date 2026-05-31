extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_gauntlet(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == MainScene.STANDARD_GAUNTLET_NAME:
			part["catalog_index"] = i
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var gauntlet := _find_gauntlet(main)
	if gauntlet.is_empty():
		_fail("Missing Standard Momentum Gauntlet.")
	if not main._part_counts_as_terminal_weapon(gauntlet, "muscle"):
		_fail("Gauntlet must be a terminal muscle weapon.")
	if main._terminal_weapon_kind_for_part(gauntlet, "muscle") != "melee":
		_fail("Gauntlet must be a melee terminal weapon.")
	if String(gauntlet.get("damage_type", "")) != "blunt":
		_fail("Gauntlet must be blunt damage.")
	if not bool(gauntlet.get("blunt_gauntlet", false)):
		_fail("Gauntlet must expose blunt_gauntlet=true.")
	var profile: Dictionary = main._embedded_joint_profile_for_part(gauntlet, "muscle")
	if String(profile.get("kind", "")) != "hybrid":
		_fail("Gauntlet must have a hybrid embedded joint.")
	if int(profile.get("angle", 0)) < 180:
		_fail("Gauntlet hybrid joint must rotate at least 180 degrees.")
	if absf(float(profile.get("extension", 0.0)) - MainScene.STANDARD_GAUNTLET_EXTENSION_M) > 0.001:
		_fail("Gauntlet max extension must be 2m.")
	if absf(float(gauntlet.get("terminal_momentum_mult", 0.0)) - MainScene.STANDARD_GAUNTLET_MOMENTUM_MULT) > 0.001:
		_fail("Gauntlet active momentum multiplier must be 1.5.")
	if float(gauntlet.get("mass", 0.0)) < 18.0:
		_fail("Gauntlet mass should be roughly twice a same-size light melee terminal.")
	if bool(gauntlet.get("projectile", false)):
		_fail("Gauntlet must never be a projectile weapon.")
	print("GAUNTLET_PART_DATA_PROBE ok index=%d mass=%.1f extension=%.1f momentum_mult=%.2f" % [int(gauntlet.get("catalog_index", -1)), float(gauntlet.get("mass", 0.0)), float(profile.get("extension", 0.0)), float(gauntlet.get("terminal_momentum_mult", 0.0))])
	quit()
