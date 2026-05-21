extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_web_gun(main) -> Dictionary:
	for raw_part in main._catalog_for("hero", "muscle"):
		var part: Dictionary = main._gun_part_with_runtime_defaults(Dictionary(raw_part), "muscle")
		if String(part.get("name", "")) == MainScene.STANDARD_WEB_TETHER_GUN_NAME:
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var web_gun := _find_web_gun(main)
	if web_gun.is_empty():
		_fail("Standard web tether gun is missing.")
	if String(web_gun.get("gun_kind", "")) != "web_gun":
		_fail("Standard web gun must use gun_kind=web_gun.")
	if String(web_gun.get("ammo_kind", "")) != "web":
		_fail("Standard web gun must use web ammo.")
	if absf(float(web_gun.get("projectile_range", 0.0)) - MainScene.STANDARD_WEB_TETHER_RANGE_M) > 0.001:
		_fail("Standard web gun range should be 4.4m.")
	if absf(float(web_gun.get("range", 0.0)) - MainScene.STANDARD_WEB_TETHER_RANGE_M) > 0.001:
		_fail("Standard web gun displayed range should be 4.4m.")
	if not bool(web_gun.get("web_anchor_swing", false)):
		_fail("Standard web gun should support boundary swing anchors.")
	if not bool(web_gun.get("web_swing_uses_melee_collision", false)):
		_fail("Web swing must use melee/entity collision after movement.")
	print("WEB_GUN_RANGE_PROBE ok range=%.1f" % float(web_gun.get("range", 0.0)))
	quit()
