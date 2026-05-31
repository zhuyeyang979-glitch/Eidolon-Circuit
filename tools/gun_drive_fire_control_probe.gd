extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part(main, name: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == name:
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var sniper := _find_part(main, MainScene.STANDARD_SNIPER_NAME)
	var claw := _find_part(main, "CRUSTA PRESS CLAW")
	if sniper.is_empty() or claw.is_empty():
		_fail("Probe requires standard sniper and Crusta claw parts.")
	var sniper_drive := main._default_limb_allocated_momentum_for_part(sniper, "muscle")
	var claw_drive := main._default_limb_allocated_momentum_for_part(claw, "muscle")
	if sniper_drive <= 0.0:
		_fail("Gun muscle should still have a positive fire-control drive demand.")
	if absf(main._gun_drive_demand_multiplier(sniper, "muscle") - 1.0) > 0.001:
		_fail("Gun drive demand should no longer apply a special low-drive multiplier.")
	var weak_aim := main._gun_drive_aim_speed_mult(0.45)
	var strong_aim := main._gun_drive_aim_speed_mult(1.8)
	if strong_aim <= weak_aim:
		_fail("More gun drive should improve aim sweep control.")
	print("GUN_DRIVE_FIRE_CONTROL_PROBE ok gun=%.2f melee=%.2f aim %.2f->%.2f" % [sniper_drive, claw_drive, weak_aim, strong_aim])
	quit()
