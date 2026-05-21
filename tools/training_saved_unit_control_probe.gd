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
		var data: Dictionary = parsed
		if String(data.get("unit_name", "")) != "2":
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
		_fail("No saved unit named 2 found.")
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	var hero = main.active_units[1]["hero"]
	if not main._is_live_unit(hero):
		_fail("Saved unit 2 did not spawn as a controllable training hero.")
	if float(hero.stats.get("body_move_speed", 0.0)) <= 0.001 or float(hero.stats.get("turn_speed", 0.0)) <= 0.001:
		_fail("Saved unit 2 has no thruster-derived movement/turn speed in training.")
	var before_pos := Vector2(hero.ring_pos, hero.lane)
	var before_angle: float = hero.facing_angle
	hero.move_by(Vector2.RIGHT, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_right := Vector2(hero.ring_pos, hero.lane)
	hero.move_by(Vector2.UP, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_up := Vector2(hero.ring_pos, hero.lane)
	hero.velocity = Vector2.ZERO
	hero.move_by(Vector2.DOWN, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_down := Vector2(hero.ring_pos, hero.lane)
	hero.request_turn(1, 0.25)
	hero.tick(0.25, MainScene.RING_LENGTH)
	var after_pos := Vector2(hero.ring_pos, hero.lane)
	if absf(after_right.x - before_pos.x) <= 0.001:
		_fail("Training WASD-equivalent movement did not move the imported unit.")
	if absf(after_up.y - after_right.y) <= 0.001:
		_fail("Training upward movement did not change lane.")
	if absf(after_down.y - after_up.y) <= 0.001:
		_fail("Training downward movement did not change lane.")
	if absf(hero.facing_angle - before_angle) <= 0.001:
		_fail("Training Q/E-equivalent turn did not rotate the imported unit.")
	print("TRAINING_SAVED_UNIT_CONTROL_PROBE moved=%.3f lane_up=%.3f lane_down=%.3f turned=%.3f" % [after_pos.distance_to(before_pos), absf(after_up.y - after_right.y), absf(after_down.y - after_up.y), absf(hero.facing_angle - before_angle)])
	quit()
