extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _block(source: String, marker: String, next_marker: String = "\nfunc ") -> String:
	var start := source.find(marker)
	if start < 0:
		_fail("Missing block marker %s." % marker)
	var end := source.find(next_marker, start + marker.length())
	return source.substr(start, source.length() - start if end < 0 else end - start)


func _assert_block_clean(source: String, marker: String, forbidden: Array) -> void:
	var text := _block(source, marker)
	for token in forbidden:
		if text.find(String(token)) >= 0:
			_fail("%s still reads legacy token %s." % [marker, String(token)])


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/fighter.gd"))
	if source == "":
		_fail("Could not read fighter.gd.")
	var forbidden := ["body_move_speed", "thruster_acceleration", "brake_efficiency", "recoil_cancel", "joint_power"]
	for marker in [
		"func _turn_brake_acceleration",
		"func _speedometer_max_speed",
		"func _brake_delta_velocity",
		"func move_by",
		"func _group_joint_motion_speed",
		"func _available_attack_reaction_cancel_momentum",
	]:
		_assert_block_clean(source, marker, forbidden)
	print("RUNTIME_NO_LEGACY_DRIVE_READS_PROBE ok blocks=6")
	quit()
