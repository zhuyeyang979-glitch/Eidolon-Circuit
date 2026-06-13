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


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		return {"fixture": "generated_training_starter"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Saved unit 2 could not be opened.")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON is invalid.")
		return {}
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var note: String = main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("Unit 2 should be legal for training, got: %s" % note)
		return {}
	return {
		"role": role_key,
		"blueprint": unit_bp,
		"fixture": "saved_unit_2",
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit: Dictionary = _load_unit2(main)
	if unit.is_empty():
		return
	if unit.get("blueprint", {}) is Dictionary and not Dictionary(unit.get("blueprint", {})).is_empty():
		main.training_import_units = [{
			"role": String(unit.get("role", "hero")),
			"blueprint": Dictionary(unit["blueprint"]).duplicate(true),
		}]
		main.training_import_role_key = String(unit.get("role", "hero"))
		main.training_import_blueprint = Dictionary(unit["blueprint"]).duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training should enter seat/scout page before battle.")
		return
	main._try_begin_battle_from_scout()
	if main.game_state == MainScene.STATE_BATTLE:
		_fail("Training began without explicit P1/P2/P3 seat selection.")
		return
	if bool(main.training_seat_confirmed):
		_fail("Training seat should remain unconfirmed before clicking a seat.")
		return
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training did not begin after explicit seat selection.")
		return
	print("TRAINING_ALL_ENTRYPOINTS_REQUIRE_SEAT_PROBE ok fixture=%s" % String(unit.get("fixture", "")))
	quit(0)
