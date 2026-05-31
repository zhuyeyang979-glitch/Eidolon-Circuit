extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var missile := {}
	for raw_part in main._catalog_for("hero", "muscle"):
		var part: Dictionary = raw_part
		if String(part.get("name", "")) == MainScene.STANDARD_MISSILE_NAME:
			missile = part
			break
	if missile.is_empty():
		_fail("Standard missile missing.")
	if float(missile.get("projectile_speed_mult", 0.0)) > 1.05:
		_fail("Missile speed should stay dodgeable at or below 1.05x.")
	var fake_event := {"range": 3.4, "projectile_speed_mult": float(missile.get("projectile_speed_mult", 0.0))}
	var travel := main._missile_projectile_travel_time(null, null, fake_event)
	if travel < 1.0:
		_fail("Missile travel time should leave a visible dodge window at max range.")
	print("MISSILE_HOMING_SPEED_DODGE_PROBE ok travel=%.2f" % travel)
	quit()
