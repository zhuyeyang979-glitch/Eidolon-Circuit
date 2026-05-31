extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var has_short := false
	var has_mid := false
	var has_long := false
	var has_ball := false
	var has_linear_or_hybrid := false
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if bool(part.get("is_torso", false)):
			continue
		var length := float(part.get("length", 0.0))
		has_short = has_short or length <= 0.30
		has_mid = has_mid or (length > 0.30 and length < 0.90)
		has_long = has_long or length >= 0.9
		var profile: Dictionary = main._embedded_joint_profile_for_part(part, "limb_muscle")
		var kind := String(profile.get("kind", "ball"))
		has_ball = has_ball or kind == "ball"
		has_linear_or_hybrid = has_linear_or_hybrid or kind in ["linear", "hybrid"]
		if main._part_stiffness(part, "limb_muscle") <= 0.0:
			_fail("Limb muscle lacks stiffness: %s" % String(part.get("name", "")))
	if not (has_short and has_mid and has_long):
		_fail("Limb gradient must include short, medium, and long pieces.")
	if not has_ball:
		_fail("Limb gradient must include rotating limbs.")
	if not has_linear_or_hybrid:
		_fail("Limb gradient must include telescopic or hybrid limbs.")
	print("LIMB_GRADIENT_CATALOG_PROBE ok")
	quit()
