extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_soul(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "special").size()):
		var part: Dictionary = main._selected_component("hero", "special", i)
		if String(part.get("name", "")) == "SOUL: FIRST EDGE ECHO":
			return part
	_fail("SOUL: FIRST EDGE ECHO is missing from hero special catalog.")
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var soul := _find_soul(main)
	if String(soul.get("zh_name", "")) != "始锋回响英魂":
		_fail("First soul is missing the Chinese standard name.")
	if String(soul.get("kind", "")) != "soul" or String(soul.get("soul_archetype", "")) != "duelist_oath":
		_fail("First soul should be a duelist-oath soul.")
	if float(soul.get("soul_heat_capacity", 0.0)) < 60.0:
		_fail("First soul should grant a readable baseline heat slot.")
	for key in ["soul_echo_window", "soul_echo_recovery_mult", "soul_echo_heat_relief"]:
		if not soul.has(key):
			_fail("First soul missing runtime echo field: %s" % key)
	var requirements: Dictionary = soul.get("soul_requirements", {})
	for key in ["mass_max", "radius_max", "module_group_min", "duelist_real_contact_min", "terminal_weapon_mass_max"]:
		if not requirements.has(key):
			_fail("First soul missing oath requirement: %s" % key)
	for forbidden in ["projectile", "attack_groups", "action_groups", "module_effect"]:
		if soul.has(forbidden):
			_fail("First soul should not expose old attack/projectile field: %s" % forbidden)
	print("FIRST_SOUL_DUELIST_OATH_PROBE ok")
	quit()
