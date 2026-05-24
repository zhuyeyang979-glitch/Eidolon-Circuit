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
		"projectile_momentum": 30.0,
		"gun_projectile_damage_mult": 15.0,
		"gun_drive_allocated": 4.0,
		"gun_drive_max": 10.0,
		"ammo_damage_coeff": 99.0,
		"gun_damage_coeff": 99.0,
		"projectile_damage_coeff": 99.0,
	}
	var current_mult := main._gun_projectile_damage_mult_for_event(event)
	if absf(current_mult - 6.0) > 0.001:
		_fail("Gun multiplier should scale linearly with allocated gun momentum, got %.3f" % current_mult)
	var damage := main._projectile_raw_damage_for_event(null, null, event)
	if absf(damage - 180.0) > 0.01:
		_fail("Projectile raw damage should be projectile momentum x current gun multiplier, got %.3f" % damage)
	event["gun_drive_allocated"] = 20.0
	var clamped_mult := main._gun_projectile_damage_mult_for_event(event)
	if absf(clamped_mult - 15.0) > 0.001:
		_fail("Gun multiplier should clamp to max at gun_drive_max, got %.3f" % clamped_mult)
	print("GUN_DAMAGE_MULTIPLIER_FROM_ALLOCATION_PROBE ok current=%.2f max=%.2f" % [current_mult, clamped_mult])
	quit()
