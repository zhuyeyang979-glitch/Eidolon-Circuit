extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var checked := 0
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("gun_kind", "")) == "" and not bool(part.get("projectile", false)):
			continue
		checked += 1
		for legacy_key in ["normal_damage", "projectile_damage", "projectile_damage_coeff", "ammo_damage_coeff", "gun_damage_coeff", "explosion_damage", "explosion_damage_type"]:
			if part.has(legacy_key):
				_fail("Normalized gun catalog still exposes legacy damage key %s on %s." % [legacy_key, String(part.get("name", ""))])
	var event := {
		"projectile": true,
		"projectile_momentum": 10.0,
		"gun_projectile_damage_mult_current": 3.0,
		"ammo_damage_coeff": 500.0,
		"gun_damage_coeff": 500.0,
		"projectile_damage_coeff": 500.0,
	}
	var damage := main._projectile_raw_damage_for_event(null, null, event)
	if absf(damage - 30.0) > 0.01:
		_fail("Legacy gun/ammo/projectile coeffs should be ignored, got %.3f" % damage)
	if checked <= 0:
		_fail("No normalized guns were checked.")
	print("GUN_NO_LEGACY_DAMAGE_COEFF_PROBE ok checked=%d" % checked)
	quit()
