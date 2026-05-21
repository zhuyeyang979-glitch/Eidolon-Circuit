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
		if not (parsed is Dictionary) or String(Dictionary(parsed).get("unit_name", "")) != "2":
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
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
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
		_fail("No controllable runtime hero in training.")
	if hero.has_method("set_facing_immediate"):
		hero.set_facing_immediate(1)
	var start_x: float = hero.ring_pos
	hero.velocity = Vector2.ZERO
	hero.move_by(Vector2.LEFT, 0.5, MainScene.RING_LENGTH)
	hero.tick(0.5, MainScene.RING_LENGTH)
	if main._ring_delta(start_x, hero.ring_pos) < -0.001 or hero.velocity.x < -0.001:
		_fail("Reverse input produced backward movement instead of no-motion/brake.")
	hero.ring_pos = start_x
	hero.lane = 0.0
	hero.velocity = Vector2.RIGHT * 1.4
	var speed_before: float = hero.velocity.length()
	hero.move_by(Vector2.LEFT, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	if hero.velocity.x < -0.001:
		_fail("Reverse brake overshot into backward velocity.")
	if hero.velocity.length() >= speed_before:
		_fail("Reverse input did not brake current velocity.")
	print("NO_REVERSE_RUNTIME_MOVEMENT_PROBE speed %.3f -> %.3f" % [speed_before, hero.velocity.length()])
	quit()
