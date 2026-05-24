extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, name: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if String(part.get("name", "")) == name:
			return part
	return {}


func _require_profile(main, name: String, kind: String, min_angle: float, min_extension: float, min_output: float, min_capacity: float) -> Dictionary:
	var part := _part(main, name)
	if part.is_empty():
		_fail("Missing limb gradient part: %s" % name)
	var profile: Dictionary = main._embedded_joint_profile_for_part(part, "limb_muscle")
	if String(profile.get("kind", "")) != kind:
		_fail("%s expected %s embedded joint." % [name, kind])
	if float(profile.get("angle", 0.0)) < min_angle:
		_fail("%s embedded angle too low." % name)
	if float(profile.get("extension", 0.0)) < min_extension:
		_fail("%s embedded extension too low." % name)
	if float(profile.get("output_momentum", 0.0)) < min_output:
		_fail("%s output momentum too low." % name)
	if float(profile.get("momentum_capacity", 0.0)) < min_capacity:
		_fail("%s momentum capacity too low." % name)
	return part


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var forearm := _require_profile(main, "HUMANOVA FOREARM MYOMER", "ball", 90, 0, 110, 130)
	var thigh := _require_profile(main, "HUMANOVA THIGH MYOMER", "ball", 120, 0, 220, 270)
	var steel := _require_profile(main, "MONOCHROME STEEL SINEW", "ball", 120, 0, 320, 500)
	var tendon := _require_profile(main, "RAZOR FLEX TENDON", "ball", 180, 0, 120, 145)
	var strut := _require_profile(main, "CERAMIC SHIN STRUT", "linear", 0, 1.0, 145, 200)
	var girder := _require_profile(main, "COLOSSUS SINEW GIRDER", "ball", 90, 0, 850, 1700)
	if not (float(forearm.get("mass", 0.0)) < float(thigh.get("mass", 0.0)) and float(thigh.get("mass", 0.0)) < float(steel.get("mass", 0.0)) and float(steel.get("mass", 0.0)) < float(girder.get("mass", 0.0))):
		_fail("Special-joint limb mass gradient is not monotonic.")
	var tendon_profile: Dictionary = main._embedded_joint_profile_for_part(tendon, "limb_muscle")
	var steel_profile: Dictionary = main._embedded_joint_profile_for_part(steel, "limb_muscle")
	if float(tendon_profile.get("momentum_capacity", 0.0)) >= float(steel_profile.get("momentum_capacity", 0.0)):
		_fail("Flexible tendon must trade capacity for angle.")
	if not String(strut.get("shape", "")).contains("linear"):
		_fail("Ceramic shin strut should advertise linear geometry.")
	print("SPECIAL_JOINT_LIMB_GRADIENT_PROBE ok")
	quit()
