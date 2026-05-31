extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_module(main, predicate: Callable) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if predicate.call(part):
			return part
	return {}


func _assert_blade_module(part: Dictionary, label: String, required_family: String = "") -> void:
	if part.is_empty():
		_fail("Missing blade module: %s" % label)
	if String(part.get("module_target_kind", "")) != "blade_ball_joint":
		_fail("%s must target blade_ball_joint." % label)
	if part.has("damage_type"):
		_fail("%s should not expose raw damage_type on the action module." % label)
	if String(part.get("command_window_profile", "")) not in ["blade_simple_4_6", "blade_complex_236_214"]:
		_fail("%s must expose a blade command window profile." % label)
	if required_family != "" and String(part.get("required_blade_family", "")) != required_family:
		_fail("%s must require %s family." % [label, required_family])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_assert_blade_module(_find_module(main, func(part): return String(part.get("module_action_profile", "")) == "blade_arc_return"), "Blade Arc Return")
	_assert_blade_module(_find_module(main, func(part): return String(part.get("module_action_profile", "")) == "katana_quickdraw"), "Katana Quickdraw", "katana")
	_assert_blade_module(_find_module(main, func(part): return String(part.get("module_action_profile", "")) == "scythe_hook_return"), "Scythe Hook Return", "scythe")
	_assert_blade_module(_find_module(main, func(part): return String(part.get("module_action_profile", "")) == "greatsword_commit_cleave"), "Greatsword Commit Cleave", "greatsword")
	_assert_blade_module(_find_module(main, func(part): return String(part.get("module_action_profile", "")) == "triple_limb_cross_cut"), "Triple-Limb Cross Cut")
	var extend_slash := _find_module(main, func(part): return String(part.get("module_action_profile", "")) == "extend_slash_driver")
	_assert_blade_module(extend_slash, "Extend-Slash Driver")
	if not bool(extend_slash.get("requires_extend_or_hybrid_chain", false)):
		_fail("Extend-Slash Driver must require an extend/hybrid chain.")
	var gauntlet := _find_module(main, func(part): return String(part.get("module_action_profile", "")) == "blunt_gauntlet_extend_swing")
	if gauntlet.is_empty():
		_fail("Missing Gauntlet Extend-Swing module.")
	if String(gauntlet.get("module_target_kind", "")) != "blunt_hybrid_gauntlet" or String(gauntlet.get("command_window_profile", "")) != "gauntlet_4_6_236_214":
		_fail("Gauntlet module must target hybrid blunt gauntlets and expose its command profile.")
	if float(gauntlet.get("required_extension_m", 0.0)) < 2.0:
		_fail("Gauntlet module must require the 2m extend-capable gauntlet.")
	var thrust := _find_module(main, func(part): return String(part.get("module_target_kind", "")) == "pierce_telescopic_joint")
	if thrust.is_empty():
		_fail("Missing pierce thrust module.")
	if float(thrust.get("required_extension_m", 0.0)) <= 0.0:
		_fail("Pierce thrust module must target telescopic/extension limbs.")
	print("MELEE_MODULE_COMPATIBILITY_PROBE ok")
	quit()
