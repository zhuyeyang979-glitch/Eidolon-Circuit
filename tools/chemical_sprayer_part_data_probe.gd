extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_sprayer(main) -> Dictionary:
	for part in main._catalog_for("hero", "muscle"):
		var data: Dictionary = main._gun_part_with_runtime_defaults(Dictionary(part), "muscle")
		if String(data.get("name", "")) == MainScene.STANDARD_CHEMICAL_SPRAYER_NAME:
			return data
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var sprayer := _find_sprayer(main)
	if sprayer.is_empty():
		_fail("Standard chemical sprayer is missing from the muscle catalog.")
		return
	var expected_momentum := main._unit2_boost_momentum_reference() / MainScene.STANDARD_CHEMICAL_SPRAYER_MOMENTUM_DIVISOR
	if String(sprayer.get("gun_kind", "")) != "sprayer":
		_fail("Chemical sprayer gun_kind should be sprayer.")
	if String(sprayer.get("ammo_kind", "")) != "chemical":
		_fail("Chemical sprayer ammo_kind should be chemical.")
	if int(sprayer.get("carried_ammo", 0)) != MainScene.STANDARD_CHEMICAL_SPRAYER_AMMO_CAPACITY:
		_fail("Chemical sprayer should carry 12 chemical ammo.")
	if absf(float(sprayer.get("projectile_range", 0.0)) - MainScene.STANDARD_CHEMICAL_SPRAYER_RANGE_M) > 0.001:
		_fail("Chemical sprayer range should be 1.6m.")
	if absf(float(sprayer.get("projectile_width_m", 0.0)) - MainScene.STANDARD_CHEMICAL_SPRAYER_WIDTH_M) > 0.001:
		_fail("Chemical sprayer spray width should be 0.28m.")
	if absf(float(sprayer.get("projectile_momentum", 0.0)) - expected_momentum) > maxf(0.01, expected_momentum * 0.01):
		_fail("Chemical sprayer projectile momentum should be unit2 boost momentum / 30.")
	if absf(float(sprayer.get("chemical_dot_duration", 0.0)) - MainScene.STANDARD_CHEMICAL_SPRAYER_DOT_SECONDS) > 0.001:
		_fail("Chemical sprayer DoT duration should be 4s.")
	if not bool(sprayer.get("chemical_dot_no_stack", false)):
		_fail("Chemical sprayer DoT should refresh instead of stacking.")
	print("CHEMICAL_SPRAYER_PART_DATA_PROBE ok momentum=%.2f" % float(sprayer.get("projectile_momentum", 0.0)))
	quit()
