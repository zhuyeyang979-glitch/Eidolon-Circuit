extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var event := {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"projectile_momentum": 123.0,
		"projectile_collision_speed": 999.0,
	}
	var speed := main._projectile_collision_speed_for_event(event)
	var mass := main._projectile_mass_for_event(event, speed)
	var resolved_momentum := main._projectile_momentum_for_event(event)
	if absf(mass * speed - 123.0) > 0.01:
		_fail("Sniper projectile mass should be reverse-derived from explicit projectile_momentum.")
	if absf(resolved_momentum - 123.0) > 0.01:
		_fail("Sniper projectile momentum should use explicit projectile_momentum.")

	var catalog: Array = main._catalog_for("hero", "muscle")
	var found := false
	for i in range(catalog.size()):
		var part := main._selected_component("hero", "muscle", i)
		if String(part.get("gun_kind", "")) == "sniper":
			found = true
			if float(part.get("projectile_momentum", 0.0)) <= 0.0:
				_fail("Sniper gun part should expose direct projectile_momentum.")
			if float(part.get("projectile_mass", 0.0)) <= 0.0 or float(part.get("projectile_collision_speed", 0.0)) <= 0.0:
				_fail("Sniper gun part should keep compatible mass/speed fields for old math helpers.")
			break
	if not found:
		_fail("No sniper gun found in the muscle catalog.")
	print("SNIPER_PROJECTILE_MOMENTUM_PROBE ok momentum=%.1f speed=%.1f mass=%.4f" % [resolved_momentum, speed, mass])
	quit()
