extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part(main, part_name: String) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("name", "")) == part_name:
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var sniper := _find_part(main, MainScene.STANDARD_SNIPER_NAME)
	if sniper.is_empty():
		_fail("Missing STANDARD BULLET SNIPER.")
	if String(sniper.get("gun_kind", "")) != "sniper":
		_fail("True-round rifle should resolve gun_kind=sniper, got %s." % String(sniper.get("gun_kind", "")))
	if String(sniper.get("ammo_kind", "")) != "bullet":
		_fail("True-round rifle should resolve ammo_kind=bullet, got %s." % String(sniper.get("ammo_kind", "")))
	if float(sniper.get("projectile_momentum", 0.0)) <= 0.0:
		_fail("Sniper rifle should keep an explicit projectile_momentum.")
	if float(sniper.get("sniper_fire_delay", 0.0)) <= 0.0:
		_fail("Sniper rifle should expose sniper_fire_delay.")

	var explosive := _find_part(main, "REDLINE BREACH SHELL CANNON")
	if explosive.is_empty():
		_fail("Missing REDLINE BREACH SHELL CANNON.")
	if String(explosive.get("gun_kind", "")) != "grenade_launcher":
		_fail("Explosive cannon should resolve gun_kind=grenade_launcher, got %s." % String(explosive.get("gun_kind", "")))
	if String(explosive.get("ammo_kind", "")) != "explosive":
		_fail("Explosive cannon should resolve ammo_kind=explosive, got %s." % String(explosive.get("ammo_kind", "")))

	var laser_found := false
	var chemical_found := false
	var web_found := false
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("gun_kind", "")) == "laser_gun" and String(part.get("ammo_kind", "")) == "laser":
			laser_found = true
		if String(part.get("gun_kind", "")) == "sprayer" and String(part.get("ammo_kind", "")) == "chemical":
			chemical_found = true
		if String(part.get("gun_kind", "")) == "web_gun" and String(part.get("ammo_kind", "")) == "web":
			web_found = true
	if not laser_found:
		_fail("At least one laser gun should resolve ammo_kind=laser.")
	if not chemical_found:
		_fail("At least one sprayer should resolve ammo_kind=chemical.")
	if not web_found:
		_fail("At least one web gun should resolve ammo_kind=web.")

	print("GUN_KIND_AMMO_KIND_PROBE ok sniper=%s/%s explosive=%s/%s" % [
		String(sniper.get("gun_kind", "")),
		String(sniper.get("ammo_kind", "")),
		String(explosive.get("gun_kind", "")),
		String(explosive.get("ammo_kind", "")),
	])
	quit()
