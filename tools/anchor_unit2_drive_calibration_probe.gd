extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit2_path() -> String:
	var dir := DirAccess.open("user://saved_units")
	if dir == null:
		return ""
	var best_path := ""
	var best_time := -1
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "user://saved_units/%s" % file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			continue
		if String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit2_path()
	if path == "":
		_fail("No latest saved unit named 2 is available as the drive anchor.")
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var note := main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("Unit 2 is not legal for drive calibration: %s" % note)
	var stats := main._compute_unit_stats(1, role_key, -1, unit_bp)
	if float(stats.get("mass", 0.0)) <= 0.0:
		_fail("Unit 2 mass must be positive.")
	var move_speed := maxf(float(stats.get("move_speed", 0.0)), float(stats.get("body_move_speed", 0.0)))
	var thruster_drive := maxf(float(stats.get("thruster_drive_demand", 0.0)), float(stats.get("thruster_allocated_momentum", 0.0)))
	var drive_margin := float(stats.get("drive_margin", stats.get("engine_momentum_margin", -999999.0)))
	if move_speed <= 0.0:
		_fail("Unit 2 move speed must be positive.")
	if thruster_drive <= 0.0:
		_fail("Unit 2 must have allocated thruster power.")
	if drive_margin < -0.01:
		_fail("Unit 2 engine power allocation is illegal: %.1f" % drive_margin)
	print("ANCHOR_UNIT2_DRIVE_CALIBRATION_PROBE ok mass=%.2f move=%.3f allocated=%.1f path=%s" % [float(stats.get("mass", 0.0)), move_speed, thruster_drive, ProjectSettings.globalize_path(path)])
	quit()
