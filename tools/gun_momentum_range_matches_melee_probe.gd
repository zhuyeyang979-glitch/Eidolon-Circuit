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
		_fail("Probe requires standard sniper and Crusta claw.")
	var gun_min := main._limb_momentum_min_for_part(sniper, "muscle")
	var gun_max := main._limb_momentum_max_for_part(sniper, "muscle")
	var melee_min := main._limb_momentum_min_for_part(claw, "muscle")
	var melee_max := main._limb_momentum_max_for_part(claw, "muscle")
	if gun_min < melee_min * 0.85 or gun_max < melee_max * 0.85:
		_fail("Gun momentum range appears to still have a special low-drive rule: gun %.2f-%.2f melee %.2f-%.2f" % [gun_min, gun_max, melee_min, melee_max])
	print("GUN_MOMENTUM_RANGE_MATCHES_MELEE_PROBE ok gun %.2f-%.2f melee %.2f-%.2f" % [gun_min, gun_max, melee_min, melee_max])
	quit()
