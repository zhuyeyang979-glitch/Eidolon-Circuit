extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ActionProfileRegistry := preload("res://scripts/services/action_profile_registry.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var modules: Array = main._catalog_for("hero", "module")
	if modules.size() <= 29:
		_fail("Module catalog too small for display #29 Boot Driver check.")
	var boot: Dictionary = main._selected_component("hero", "module", 28)
	var turret: Dictionary = main._selected_component("hero", "module", 29)
	if String(boot.get("name", "")) != "BOOT ACTION DRIVER":
		_fail("Display #29 / zero-based module 28 is not BOOT ACTION DRIVER: %s" % String(boot.get("name", "")))
	if String(turret.get("name", "")) != "TURRET TRAVERSE FIRE":
		_fail("Zero-based module 29 must remain TURRET TRAVERSE FIRE: %s" % String(turret.get("name", "")))
	var raw_boot: Dictionary = MainScene.COMMON_CATALOG["module"][28]
	if String(raw_boot.get("damage_type", "")) != "blunt":
		_fail("Raw Boot Driver catalog entry must declare blunt damage type.")
	var expected := {
		"module_action_profile": "boot_action_driver",
		"module_target_kind": "boot_driver_limb_group",
		"command_window_profile": "boot_driver_4_6",
	}
	for key in expected.keys():
		if String(boot.get(key, "")) != String(expected[key]):
			_fail("Boot Driver %s mismatch: %s" % [key, String(boot.get(key, ""))])
	for bool_key in ["requires_bound_key", "hold_to_activate", "turn_keys_steer_joint"]:
		if not bool(boot.get(bool_key, false)):
			_fail("Boot Driver missing true %s." % bool_key)
	if bool(boot.get("projectile", true)):
		_fail("Boot Driver must not be projectile.")
	if not is_equal_approx(float(boot.get("startup_ratio", 0.0)), 0.333333):
		_fail("Boot Driver startup ratio mismatch.")
	if not is_equal_approx(float(boot.get("recovery_ratio", 0.0)), 0.666667):
		_fail("Boot Driver recovery ratio mismatch.")
	var registry := ActionProfileRegistry.new()
	if not registry.is_melee_profile("boot_action_driver"):
		_fail("Boot Driver profile is not registered as melee.")
	if registry.is_projectile_profile("boot_action_driver"):
		_fail("Boot Driver profile leaked into projectile profiles.")
	if main._gun_activation_profiles().has("boot_action_driver"):
		_fail("Boot Driver leaked into gun activation whitelist.")
	print("BOOT_DRIVER_CATALOG_PROFILE_PROBE ok index=28")
	quit()
