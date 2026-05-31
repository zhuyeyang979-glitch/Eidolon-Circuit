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


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
	return main._json_restore_value(Dictionary(parsed))


func _enter_training_with_seat(main, seat: int) -> void:
	var saved: Dictionary = _load_unit2(main)
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(seat)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training failed to begin for seat %d." % seat)


func _check_seat(seat: int) -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	_enter_training_with_seat(main, seat)
	var player := 2 if seat == 2 else 1
	var dummy_player := 1 if seat == 2 else 2
	var player_unit = main.active_units[player]["hero"]
	var dummy_unit = main.active_units[dummy_player]["hero"]
	if not main._is_live_unit(player_unit):
		_fail("Seat %d player unit missing." % seat)
	if not main._is_live_unit(dummy_unit):
		_fail("Seat %d training dummy missing." % seat)
	if not bool(dummy_unit.get_meta("training_static_dummy", false)):
		_fail("Seat %d dummy is not marked static." % seat)
	if not bool(dummy_unit.stats.get("training_ball_dummy", false)):
		_fail("Seat %d dummy did not use the dedicated ball dummy." % seat)
	if dummy_player == 2 and main._ring_delta(player_unit.ring_pos, dummy_unit.ring_pos) <= 0.0:
		_fail("P1 seat should place unit 2 on the right/opposite side.")
	if dummy_player == 1 and main._ring_delta(dummy_unit.ring_pos, player_unit.ring_pos) <= 0.0:
		_fail("P2 seat should place unit 2 on the left/opposite side.")
	main.queue_free()


func _init() -> void:
	_check_seat(1)
	_check_seat(2)
	print("TRAINING_SEAT_SPAWN_UNIT2_PROBE ok")
	quit()
