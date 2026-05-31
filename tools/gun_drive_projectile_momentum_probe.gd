extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _event(ratio: float) -> Dictionary:
	return {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"projectile_momentum": 100.0,
		"gun_projectile_damage_mult": 12.0,
		"gun_drive_max": 10.0,
		"gun_drive_allocated": 10.0 * ratio,
		"ammo_damage_coeff": 2.0,
		"gun_damage_coeff": 3.0,
		"gun_drive_ratio": ratio,
		"direction": Vector2.RIGHT,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var underpowered := _event(0.5)
	var under_mult := main._gun_drive_projectile_momentum_mult(0.5)
	var under_damage := main._projectile_raw_damage_for_event(null, null, underpowered)
	var expected_under := 100.0 * 6.0
	if absf(under_damage - expected_under) > 0.01:
		_fail("Underpowered gun drive should reduce only the gun damage multiplier. got %.3f expected %.3f" % [under_damage, expected_under])
	if absf(float(underpowered.get("projectile_effective_momentum", 0.0)) - 100.0) > 0.01:
		_fail("Projectile momentum should stay gun-defined and not be reduced by drive allocation.")
	var sufficient := _event(1.35)
	var sufficient_damage := main._projectile_raw_damage_for_event(null, null, sufficient)
	if absf(sufficient_damage - 1200.0) > 0.01:
		_fail("Above max gun drive should clamp current multiplier to max. got %.3f" % sufficient_damage)
	print("GUN_DRIVE_PROJECTILE_MOMENTUM_PROBE ok under=%.1f full=%.1f mult=%.2f" % [under_damage, sufficient_damage, under_mult])
	quit()
