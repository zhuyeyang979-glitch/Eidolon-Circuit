extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_training_unit_path() -> String:
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
		if String(Dictionary(parsed).get("unit_name", "")) != "4":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _ensure_probe_drive_payloads(unit_bp: Dictionary) -> void:
	if not Array(unit_bp.get("slot_payloads", [])).is_empty():
		return
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var torso_node := -1
	for i in range(nodes.size()):
		if not (nodes[i] is Dictionary):
			continue
		var node: Dictionary = nodes[i]
		if String(node.get("slot", "")) == "muscle" and (bool(node.get("is_torso", false)) or String(node.get("material_class", "")).to_lower() == "torso"):
			torso_node = i
			break
	if torso_node < 0:
		return
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": int(unit_bp.get("engine", 0)), "internal_slot_index": 0, "torso_node": torso_node},
		{"kind": "booster", "booster": int(unit_bp.get("booster", 0)), "internal_slot_index": 1, "torso_node": torso_node},
		{"kind": "cooling", "cooling": int(unit_bp.get("cooling", 0)), "internal_slot_index": 2, "torso_node": torso_node},
	]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_training_unit_path()
	if path == "":
		_fail("No saved training unit named 4 found.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 4 JSON is invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	_ensure_probe_drive_payloads(unit_bp)
	main._repair_blueprint_limb_allocation_ranges(role_key, unit_bp)
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = role_key
	main.editor_working_blueprint = unit_bp
	main.editor_working_blueprint["unit_name"] = "Training Probe Unsaved Canvas"
	main.editor_working_blueprint["blank_canvas"] = false
	main._start_editor_canvas_training_test()
	if Dictionary(main.training_import_blueprint.get("entry_pose", {})).is_empty():
		_fail("Training import should preserve the current canvas entry pose.")
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Training import should enter battle training mode.")
	var p1_units: Dictionary = main.active_units.get(1, {})
	if p1_units.get("hero", null) == null and Array(p1_units.get("puppet", [])).is_empty() and p1_units.get("barrier", null) == null:
		_fail("Training import did not spawn the imported P1 unit.")
	print("TRAINING_UNIT_IMPORT_PROBE ok role=%s state=%s" % [main.training_import_role_key, main.game_state])
	quit()
