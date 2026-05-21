extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part(main, name: String) -> Dictionary:
	for raw_part in main._catalog_for("hero", "muscle"):
		var part: Dictionary = raw_part
		if String(part.get("name", "")) == name:
			return part
	return {}


func _find_module(main, profile: String) -> Dictionary:
	for raw_part in main._catalog_for("hero", "module"):
		var part: Dictionary = raw_part
		if String(part.get("module_action_profile", "")) == profile:
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var laser := _find_part(main, MainScene.STANDARD_LASER_NAME)
	if laser.is_empty():
		_fail("Standard laser gun missing.")
	if String(laser.get("gun_kind", "")) != "laser_gun":
		_fail("Standard laser gun should expose gun_kind=laser_gun.")
	if String(laser.get("ammo_kind", "")) != "laser":
		_fail("Standard laser gun should expose ammo_kind=laser.")
	if String(laser.get("projectile_style", "")) != "beam" or String(laser.get("projectile_behavior", "")) != "laser":
		_fail("Standard laser gun should use beam/laser projectile fields.")
	if String(laser.get("travel_path", "")) != "instant_line":
		_fail("Standard laser gun should use instant_line travel.")
	if int(laser.get("carried_ammo", 0)) != MainScene.STANDARD_LASER_AMMO_CAPACITY:
		_fail("Standard laser ammo capacity mismatch.")
	if absf(float(laser.get("projectile_width_m", 0.0)) - MainScene.STANDARD_LASER_WIDTH_M) > 0.001:
		_fail("Standard laser beam width mismatch.")
	var module := _find_module(main, "laser_beam_activate")
	if module.is_empty():
		_fail("Prism Beam Activate module missing.")
	if String(module.get("module_target_kind", "")) != "gun_terminal":
		_fail("Prism Beam Activate should bind gun_terminal.")
	print("LASER_PART_DATA_PROBE ok ammo=%d range=%.2f width=%.2f" % [int(laser.get("carried_ammo", 0)), float(laser.get("projectile_range", 0.0)), float(laser.get("projectile_width_m", 0.0))])
	quit()

