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

	var sniper := _find_standard_sniper(main)
	if sniper.is_empty():
		_fail("Missing Standard Bullet Sniper in muscle catalog.")
	if String(sniper.get("gun_kind", "")) != "sniper":
		_fail("Standard sniper should expose gun_kind=sniper.")
	if String(sniper.get("ammo_kind", "")) != "bullet":
		_fail("Standard sniper should expose ammo_kind=bullet.")
	var caps: Dictionary = sniper.get("ammo_capacity", {}) if sniper.get("ammo_capacity", {}) is Dictionary else {}
	if int(caps.get("bullet", 0)) != MainScene.STANDARD_SNIPER_AMMO_CAPACITY:
		_fail("Standard sniper should carry 10 bullet ammo.")
	if absf(float(sniper.get("projectile_width_m", 0.0)) - MainScene.STANDARD_SNIPER_PROJECTILE_WIDTH_M) > 0.001:
		_fail("Standard sniper projectile width should be 0.1m.")
	var expected_momentum := main._unit2_boost_momentum_reference() / 10.0
	if absf(float(sniper.get("projectile_momentum", 0.0)) - expected_momentum) > 0.05:
		_fail("Standard sniper projectile_momentum should be unit2 boost momentum / 10.")
	var expected_coeff := MainScene.PART_DAMAGE_COEFF_TERMINAL_MELEE * MainScene.STANDARD_SNIPER_PROJECTILE_DAMAGE_MULT
	if absf(float(sniper.get("projectile_damage_coeff", 0.0)) - expected_coeff) > 0.01:
		_fail("Standard sniper projectile damage coeff should be melee standard * 20.")
	if float(sniper.get("projectile_break_coeff", 1.0)) != 0.0:
		_fail("Standard sniper projectile should not use a projectile break coeff.")
	print("SNIPER_PART_DATA_PROBE ok momentum=%.2f coeff=%.2f" % [float(sniper.get("projectile_momentum", 0.0)), float(sniper.get("projectile_damage_coeff", 0.0))])
	quit()
