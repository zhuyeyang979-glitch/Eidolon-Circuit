extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var base_part := {}
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			base_part = part.duplicate(true)
			break
	if base_part.is_empty():
		_fail("No torso part found.")
	for port_count in range(1, 7):
		var part: Dictionary = base_part.duplicate(true)
		part["joint_ports"] = port_count
		part["connection_ends"] = port_count
		var profiles: Array = main._torso_joint_slot_profiles_for_part(part)
		if profiles.size() != port_count:
			_fail("Expected %d slot profiles, got %d." % [port_count, profiles.size()])
		for raw_profile in profiles:
			if not (raw_profile is Dictionary):
				_fail("Slot profile is not a Dictionary.")
			var profile: Dictionary = raw_profile
			if float(profile.get("half_width", 0.0)) <= 0.0:
				_fail("Slot profile has no positive half_width.")
	var override_part: Dictionary = base_part.duplicate(true)
	override_part["joint_ports"] = 2
	override_part["connection_ends"] = 2
	override_part["joint_slot_profiles"] = [{"port_index": 1, "center_angle": 45.0, "min_angle": 10.0, "max_angle": 80.0, "motion_kind": "ball"}]
	var override_profiles: Array = main._torso_joint_slot_profiles_for_part(override_part)
	if absf(float(Dictionary(override_profiles[1]).get("center_angle", 0.0)) - deg_to_rad(45.0)) > 0.001:
		_fail("Explicit joint slot profile did not override center angle.")
	print("TORSO_SLOT_ANGLE_PROFILE_PROBE ok")
	quit()
