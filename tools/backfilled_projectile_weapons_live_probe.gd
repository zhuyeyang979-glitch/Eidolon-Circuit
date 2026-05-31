extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const EXPECTED := {
	"KINETIC BULLET GUN": ["gun_activate", "sniper", "bullet"],
	"AUTOCANNON TURRET": ["rifle_burst_activate", "rifle", "bullet"],
	"HEAVY RAIL CANNON TURRET": ["gun_activate", "sniper", "bullet"],
	"长视制式来复枪 / LONGSIGHT PATTERN RIFLE": ["rifle_burst_activate", "rifle", "bullet"],
	"DUAL-RAIL HEAVY CANNON": ["gun_activate", "sniper", "bullet"],
	"CAUSTIC SPRAY GUN": ["gun_activate", "sprayer", "chemical"],
	"SIPHON CHEM NOZZLE": ["gun_activate", "sprayer", "chemical"],
	"CHEM SPLASH NOZZLE": ["gun_activate", "sprayer", "chemical"],
	"CHEM SIEGE MORTAR": ["gun_activate", "sprayer", "chemical"],
	"LASER EMITTER GUN": ["laser_beam_activate", "laser_gun", "laser"],
	"LASER LANCE TURRET": ["laser_beam_activate", "laser_gun", "laser"],
	"UMBRA HEAT NEEDLER": ["laser_beam_activate", "laser_gun", "laser"],
	"ANTI-TANK MICRO MISSILE": ["grenade_arc_activate", "grenade_launcher", "explosive"],
	"BUNKER POPPER MISSILE": ["grenade_arc_activate", "grenade_launcher", "explosive"],
	"REDLINE BREACH SHELL CANNON": ["grenade_arc_activate", "grenade_launcher", "explosive"],
	"红线跳爆榴弹枪 / REDLINE HOPPER GRENADE LAUNCHER": ["grenade_arc_activate", "grenade_launcher", "explosive"],
	"WEB SILK PISTOL": ["web_tether_activate", "web_gun", "web"],
	"ANCHOR SILK CANNON": ["web_tether_activate", "web_gun", "web"],
	"GRAVITY CABLE LAUNCHER": ["web_tether_activate", "web_gun", "web"],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "muscle", name)
	if index < 0:
		for i in range(main._catalog_for("hero", "muscle").size()):
			var candidate: Dictionary = main._selected_component("hero", "muscle", i)
			if String(candidate.get("name", "")).to_upper().find(name.to_upper()) >= 0:
				index = i
				break
	if index < 0:
		_fail("Missing projectile weapon catalog part: %s" % name)
		return {}
	return main._selected_component("hero", "muscle", index)


func _assert_live_weapon(main, name: String, expected: Array) -> void:
	var part := _part(main, name)
	if part.is_empty():
		return
	var profile := String(expected[0])
	var gun_kind := String(expected[1])
	var ammo_kind := String(expected[2])
	if not bool(part.get("catalog_backfilled_live", false)):
		_fail("%s was not marked backfilled live." % name)
	if main._part_is_catalog_frozen("muscle", part):
		_fail("%s should be live after projectile backfill." % name)
	if String(part.get("compatible_gun_activation_profile", "")) != profile:
		_fail("%s profile expected %s, got %s." % [name, profile, String(part.get("compatible_gun_activation_profile", ""))])
	if String(part.get("gun_kind", "")) != gun_kind or String(part.get("ammo_kind", "")) != ammo_kind:
		_fail("%s gun/ammo expected %s/%s, got %s/%s." % [name, gun_kind, ammo_kind, String(part.get("gun_kind", "")), String(part.get("ammo_kind", ""))])
	if not main._gun_activation_profile_supports_kind(profile, gun_kind, ammo_kind):
		_fail("%s profile %s does not support %s/%s." % [name, profile, gun_kind, ammo_kind])
	if float(part.get("projectile_momentum", 0.0)) <= 0.0:
		_fail("%s missing projectile momentum." % name)
	if float(part.get("gun_projectile_damage_mult", -1.0)) < 0.0:
		_fail("%s missing damage multiplier." % name)
	if not bool(part.get("non_damage", false)) and float(part.get("gun_projectile_damage_mult", 0.0)) <= 0.0:
		_fail("%s damage weapon has non-positive damage multiplier." % name)


func _assert_frozen_weapon(main, name: String) -> void:
	var part := _part(main, name)
	if part.is_empty():
		return
	if not main._part_is_catalog_frozen("muscle", part):
		_fail("%s should remain frozen." % name)
	var lifecycle: Dictionary = main._catalog_lifecycle_for_part("muscle", part)
	if String(lifecycle.get("future_dev_tag", "")) != "future_projectile_family":
		_fail("%s should remain in future projectile family, got %s." % [name, String(lifecycle.get("future_dev_tag", ""))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for name in EXPECTED.keys():
		_assert_live_weapon(main, String(name), Array(EXPECTED[name]))
	_assert_frozen_weapon(main, "REDLINE MIRV POD")
	_assert_frozen_weapon(main, "LIGHT-SINK NEEDLE")
	_assert_frozen_weapon(main, "TRACKING MISSILE POD")
	print("BACKFILLED_PROJECTILE_WEAPONS_LIVE_PROBE ok live=%d" % EXPECTED.size())
	quit()
