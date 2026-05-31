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
	var missile := _find_part(main, MainScene.STANDARD_MISSILE_NAME)
	if missile.is_empty():
		_fail("Standard missile pod missing.")
	if String(missile.get("gun_kind", "")) != "missile_launcher" or String(missile.get("ammo_kind", "")) != "explosive":
		_fail("Standard missile pod should expose missile_launcher + explosive.")
	if String(missile.get("projectile_style", "")) != "missile" or String(missile.get("projectile_behavior", "")) != "explosive":
		_fail("Standard missile should preserve missile style and explosive behavior.")
	if String(missile.get("travel_path", "")) != "homing":
		_fail("Standard missile should use homing travel.")
	if int(missile.get("carried_ammo", 0)) != MainScene.STANDARD_MISSILE_AMMO_CAPACITY:
		_fail("Standard missile ammo capacity mismatch.")
	if absf(float(missile.get("projectile_speed_mult", 0.0)) - MainScene.STANDARD_MISSILE_SPEED_MULT) > 0.001:
		_fail("Standard missile speed multiplier mismatch.")
	var module := _find_module(main, "missile_lock_activate")
	if module.is_empty():
		_fail("Kestrel Missile Lock module missing.")
	if String(module.get("module_target_kind", "")) != "gun_terminal":
		_fail("Kestrel Missile Lock should bind gun_terminal.")
	print("MISSILE_PART_DATA_PROBE ok ammo=%d range=%.2f speed=%.2f" % [int(missile.get("carried_ammo", 0)), float(missile.get("projectile_range", 0.0)), float(missile.get("projectile_speed_mult", 0.0))])
	quit()
