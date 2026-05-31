extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const REQUIRED_VARIANTS := {
	"COMBO ROUTER: BALANCE STRING": "balance_string",
	"CLAMP ROUTER: VISE CLOSE": "vise_close",
	"ROUTE ROUTER: PICKUP DASH": "pickup_dash",
	"MONSTER ROUTER: CRUSH WINDUP": "crush_windup",
	"DUEL ROUTER: FEINT THRUST": "feint_thrust",
	"SALVO ROUTER: EXPLOSIVE ARC": "explosive_arc_salvo",
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", name)
	if index < 0:
		_fail("Missing module catalog part: %s" % name)
		return {}
	return main._selected_component("hero", "module", index)


func _assert_no_old_helper_name(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var old_terms := [
		"_copy_" + "leg" + "acy_module_variant_fields",
		"_apply_" + "leg" + "acy_module_variant_hit_effect",
		"leg" + "acy_clamp_pin_timer",
	]
	for term in old_terms:
		if text.find(String(term)) >= 0:
			_fail("%s still exposes old module variant helper/pin names." % path)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for raw_name in REQUIRED_VARIANTS.keys():
		var name := String(raw_name)
		var part := _module_part(main, name)
		var expected := String(REQUIRED_VARIANTS[name])
		if String(part.get("module_variant_key", "")) != expected:
			_fail("%s expected module_variant_key=%s." % [name, expected])
		match expected:
			"vise_close":
				if float(part.get("clamp_pin_seconds", 0.0)) < 0.37 or float(part.get("clamp_velocity_mult", 1.0)) >= 0.5:
					_fail("VISE CLOSE contract should include fair short control fields.")
			"feint_thrust":
				if float(part.get("feint_retarget_degrees", 0.0)) < 17.5:
					_fail("FEINT THRUST contract should include startup retarget angle.")
			"explosive_arc_salvo":
				if not bool(part.get("salvo_landing_marker", false)) or float(part.get("salvo_arc_max_range", 0.0)) <= float(part.get("salvo_arc_min_range", 0.0)):
					_fail("EXPLOSIVE ARC SALVO contract should include landing mark and range ramp.")
			"crush_windup":
				if float(part.get("whiff_recovery_mult", 1.0)) <= 1.0 or float(part.get("crush_contact_momentum_mult", 1.0)) <= 1.0:
					_fail("CRUSH WINDUP contract should distinguish hit power and whiff recovery.")
	_assert_no_old_helper_name("res://scripts/main.gd")
	_assert_no_old_helper_name("res://scripts/fighter.gd")
	print("MODULE_VARIANT_BEHAVIOR_CONTRACT_PROBE ok variants=%d" % REQUIRED_VARIANTS.size())
	quit()
