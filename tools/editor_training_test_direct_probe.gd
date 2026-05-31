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
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	_ensure_probe_drive_payloads(unit_bp)
	main._show_editor(true)
	var role_key := String(saved.get("unit_role", "hero"))
	main._repair_blueprint_limb_allocation_ranges(role_key, unit_bp)
	main.editor_role_index = MainScene.ROLE_ORDER.find(role_key)
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = role_key
	main.editor_working_blueprint = unit_bp
	main.editor_working_blueprint["unit_name"] = "Probe Direct Training Test"
	main.editor_working_blueprint["blank_canvas"] = false

	main._editor_action("training_import")
	var entry_note := String(main.editor_summary_label.text) if main.editor_summary_label != null else ""
	var import_note := String(main.training_import_error_note)
	if main.game_state == MainScene.STATE_SCOUT:
		_fail("Unit Edit Training Test should bypass the training config/scout page.")
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Unit Edit Training Test should enter training battle directly, got state=%s mode=%s summary=%s import_note=%s." % [main.game_state, main.battle_mode, entry_note, import_note])
	var p1_units: Dictionary = main.active_units.get(1, {})
	if p1_units.get("hero", null) == null and Array(p1_units.get("puppet", [])).is_empty() and p1_units.get("barrier", null) == null:
		_fail("Direct training test did not spawn the edited P1 unit.")
	print("EDITOR_TRAINING_TEST_DIRECT_PROBE ok state=%s mode=%s" % [main.game_state, main.battle_mode])
	quit()
