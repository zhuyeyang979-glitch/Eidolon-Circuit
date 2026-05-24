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
		var modified := int(FileAccess.get_modified_time(path))
		if modified >= best_time:
			best_time = modified
			best_path = path
	return best_path


func _load_unit2(main) -> Dictionary:
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
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
	return {"role": role_key, "blueprint": unit_bp}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit := _load_unit2(main)
	main.training_import_units = [{"role": unit["role"], "blueprint": Dictionary(unit["blueprint"]).duplicate(true)}]
	main.training_import_role_key = String(unit["role"])
	main.training_import_blueprint = Dictionary(unit["blueprint"]).duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training battle did not start.")
		return
	var total_usec := 0
	var max_usec := 0
	var warmup := 20
	var frames := 180
	for i in range(frames):
		var start := Time.get_ticks_usec()
		main._tick_battle(MainScene.BATTLE_FRAME_DELTA)
		var elapsed := Time.get_ticks_usec() - start
		if i < warmup:
			continue
		total_usec += elapsed
		max_usec = maxi(max_usec, elapsed)
	var measured_frames := frames - warmup
	var avg_ms := float(total_usec) / float(measured_frames) / 1000.0
	var max_ms := float(max_usec) / 1000.0
	if avg_ms > 18.0:
		_fail("Average frame budget too high: %.2f ms" % avg_ms)
		return
	if max_ms > 120.0:
		_fail("Maximum frame spike too high: %.2f ms" % max_ms)
		return
	print("BATTLE_RUNTIME_FRAME_BUDGET_PROBE ok avg_ms=%.3f max_ms=%.3f frames=%d warmup=%d" % [avg_ms, max_ms, measured_frames, warmup])
	quit()
