extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_profile_exists(main, profile: String) -> bool:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == profile:
			return true
	return false


func _muscle_exists(main, gun_kind: String, ammo_kind: String) -> bool:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if String(part.get("gun_kind", main._gun_kind_for_data(part))) == gun_kind and String(part.get("ammo_kind", main._ammo_kind_for_data(part))) == ammo_kind:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var specialist_expected := {
		"rifle_burst_activate": ["rifle", "bullet"],
		"laser_beam_activate": ["laser_gun", "laser"],
		"missile_lock_activate": ["missile_launcher", "explosive"],
		"web_tether_activate": ["web_gun", "web"],
		"grenade_arc_activate": ["grenade_launcher", "explosive"],
	}
	var generic_expected := {
		"sniper": ["bullet", "gun_activate"],
		"sprayer": ["chemical", "gun_activate"],
		"rifle": ["bullet", "rifle_burst_activate"],
		"laser_gun": ["laser", "laser_beam_activate"],
		"missile_launcher": ["explosive", "missile_lock_activate"],
		"web_gun": ["web", "web_tether_activate"],
		"grenade_launcher": ["explosive", "grenade_arc_activate"],
	}
	if not _module_profile_exists(main, "gun_activate"):
		_fail("Module catalog missing generic gun_activate.")
	for gun_kind in generic_expected.keys():
		var expected: Array = generic_expected[gun_kind]
		var ammo_kind := String(expected[0])
		var effective_profile := String(expected[1])
		if not _muscle_exists(main, String(gun_kind), ammo_kind):
			_fail("Muscle catalog missing %s/%s terminal." % [String(gun_kind), ammo_kind])
		if not main._gun_activation_profile_supports_kind("gun_activate", String(gun_kind), ammo_kind):
			_fail("Generic gun_activate did not accept %s/%s." % [String(gun_kind), ammo_kind])
		if main._effective_gun_activation_profile("gun_activate", String(gun_kind), ammo_kind) != effective_profile:
			_fail("Generic gun_activate did not resolve %s to %s." % [String(gun_kind), effective_profile])
	for profile in specialist_expected.keys():
		if not main._gun_activation_profiles().has(profile):
			_fail("Gun activation whitelist missing %s." % profile)
		if not _module_profile_exists(main, profile):
			_fail("Module catalog missing %s." % profile)
		var pair: Array = specialist_expected[profile]
		if not _muscle_exists(main, String(pair[0]), String(pair[1])):
			_fail("Muscle catalog missing %s/%s terminal." % [String(pair[0]), String(pair[1])])
		if not main._gun_activation_profile_supports_kind(profile, String(pair[0]), String(pair[1])):
			_fail("%s did not accept its intended gun kind." % profile)
	if main._gun_activation_profile_supports_kind("grenade_arc_activate", "rifle", "bullet"):
		_fail("Grenade arc accepted rifle/bullet.")
	if main._gun_activation_profile_supports_kind("rifle_burst_activate", "grenade_launcher", "explosive"):
		_fail("Rifle burst accepted grenade/explosive.")
	print("GUN_MODULE_BINDING_MATRIX_PROBE ok generic=%d specialist=%d" % [generic_expected.size(), specialist_expected.size()])
	quit()
