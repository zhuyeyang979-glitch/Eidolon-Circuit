extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var names := [
		"TIMBER 90 MAZE ELBOW JOINT",
		"CERAMIC 90 MAZE ELBOW JOINT",
		"METAL 90 MAZE ELBOW JOINT",
		"PADDED 90 MAZE ELBOW JOINT",
	]
	var found := 0
	for part in MainScene.COMMON_CATALOG["joint"]:
		if not (part is Dictionary):
			continue
		var joint: Dictionary = part
		if not names.has(String(joint.get("name", ""))):
			continue
		found += 1
		print("CORNER_JOINT %s cost=%d hp=%d mass=%.0f angle=%d range=%.1f power=%.1f stiff=%.0f" % [
			String(joint.get("name", "")),
			int(joint.get("cost", 0)),
			int(joint.get("hp", 0)),
			float(joint.get("mass", 0.0)),
			int(joint.get("connection_angle_degrees", 0)),
			float(joint.get("range", 0.0)),
			main._joint_output_power(joint),
			main._part_stiffness(joint, "joint"),
		])
		if not bool(joint.get("fixed_corner_joint", false)):
			_fail("Corner joint missing fixed_corner_joint flag.")
		if int(joint.get("connection_angle_degrees", 0)) != 90:
			_fail("Corner joint is not marked as 90 degrees.")
		if float(joint.get("range", 1.0)) != 0.0:
			_fail("Corner joint must have zero motion range.")
		if main._joint_supports_ball_swing(joint, 90):
			_fail("Corner joint incorrectly supports ball swing modules.")
		if main._joint_supported_degrees(joint) != 0:
			_fail("Corner joint incorrectly reports movable degrees.")
		if main._joint_output_power(joint) != 0.0:
			_fail("Corner joint incorrectly provides output power.")
		if not bool(joint.get("maze_wall_joint", false)) or not bool(joint.get("barrier_tile_component", false)):
			_fail("Corner joint is not registered as a barrier wall joint.")
	if found != names.size():
		_fail("Expected %d corner joints, found %d." % [names.size(), found])
	quit()
