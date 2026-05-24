extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_standard_sniper(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == MainScene.STANDARD_SNIPER_NAME:
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var event := {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"projectile_momentum": 40.0,
		"gun_projectile_damage_mult_current": 2.0,
		"ammo_damage_coeff": 1.5,
		"gun_damage_coeff": 2.0,
		"projectile_damage_coeff": 99.0,
		"direction": Vector2.RIGHT,
	}
	var raw_damage := main._projectile_raw_damage_for_event(null, null, event)
	if absf(raw_damage - 80.0) > 0.01:
		_fail("Projectile damage formula should be momentum * current gun multiplier only, got %.3f." % raw_damage)
	var legacy_event := {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"projectile_momentum": 50.0,
		"gun_projectile_damage_mult": 12.0,
		"gun_drive_allocated": 4.0,
		"gun_drive_max": 8.0,
		"direction": Vector2.RIGHT,
	}
	var legacy_damage := main._projectile_raw_damage_for_event(null, null, legacy_event)
	var expected_legacy := 50.0 * 6.0
	if absf(legacy_damage - expected_legacy) > 0.01:
		_fail("Allocated gun multiplier should scale by gun_drive_allocated / gun_drive_max, got %.3f expected %.3f." % [legacy_damage, expected_legacy])
	var sniper := _find_standard_sniper(main)
	if sniper.is_empty():
		_fail("Missing standard sniper.")
	if absf(main._gun_projectile_damage_mult_max_for_data(sniper) - MainScene.STANDARD_SNIPER_GUN_DAMAGE_COEFF) > 0.001:
		_fail("Standard sniper gun projectile damage multiplier should use the sniper multiplier.")
	print("PROJECTILE_DAMAGE_FORMULA_PROBE ok raw=%.1f allocated=%.1f sniper=%.1f" % [raw_damage, legacy_damage, main._gun_projectile_damage_mult_max_for_data(sniper)])
	quit()
