extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _code_indices(main, count: int) -> Array:
	var result: Array = []
	var catalog: Array = main._catalog_for("puppet", "special")
	for i in range(catalog.size()):
		if catalog[i] is Dictionary and String(Dictionary(catalog[i]).get("kind", "")) == "code":
			result.append(i)
			if result.size() >= count:
				return result
	return result


func _priority_payloads(unit_bp: Dictionary) -> Array:
	var result: Array = []
	for raw_entry in Array(unit_bp.get("source_code_priority", [])):
		if raw_entry is Dictionary:
			result.append(int(Dictionary(raw_entry).get("payload_index", -1)))
	return result


func _source_entry_for_payload(entries: Array, payload_index: int) -> Dictionary:
	for raw_entry in entries:
		if raw_entry is Dictionary and int(Dictionary(raw_entry).get("payload_index", -1)) == payload_index:
			return Dictionary(raw_entry)
	return {}


func _build_puppet_blueprint(code_a: int, code_b: int) -> Dictionary:
	return {
		"role": "puppet",
		"blank_canvas": false,
		"custom_topology": {
			"nodes": [
				{"slot": "muscle", "part_index": 0, "label": "Core A", "construct_body_id": "body-a"},
				{"slot": "muscle", "part_index": 0, "label": "Core B", "construct_body_id": "body-b"},
			],
			"edges": [],
		},
		"slot_payloads": [
			{"kind": "special", "special": code_a, "software_kind": "code", "torso_node": 0},
			{"kind": "special", "special": code_b, "software_kind": "code", "torso_node": 1},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	main.editor_role_index = MainScene.ROLE_ORDER.find("puppet")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "puppet"
	var codes := _code_indices(main, 2)
	_require(codes.size() >= 2, "Probe needs at least two puppet Source Code catalog entries.")
	if failed:
		quit(1)
		return
	var unit_bp := _build_puppet_blueprint(int(codes[0]), int(codes[1]))
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = 0
	for method_name in [
		"_source_code_priority_entries_for_blueprint",
		"_move_source_code_priority_for_payload",
		"_reset_source_code_priority",
	]:
		_require(main.has_method(method_name), "Main should expose Source Code priority editor adapter method %s." % method_name)
	_require(main.editor_torso_detail_view != null and main.editor_torso_detail_view.has_signal("source_priority_move"), "Torso detail view should emit source_priority_move.")
	_require(main.editor_torso_detail_view != null and main.editor_torso_detail_view.has_signal("source_priority_reset"), "Torso detail view should emit source_priority_reset.")
	if failed:
		quit(1)
		return
	var initial_entries: Array = main._source_code_priority_entries_for_blueprint(unit_bp)
	_require(_priority_payloads({"source_code_priority": initial_entries}) == [0, 1], "Initial Source Code priority should follow payload order: %s" % str(initial_entries))
	var torso_a_entries: Array = main._torso_software_slot_summary(unit_bp, 0)
	var torso_b_entries: Array = main._torso_software_slot_summary(unit_bp, 1)
	var entry_a := _source_entry_for_payload(torso_a_entries, 0)
	var entry_b := _source_entry_for_payload(torso_b_entries, 1)
	_require(bool(entry_a.get("source_code_priority", false)), "Source Code row A should expose priority metadata: %s" % str(entry_a))
	_require(bool(entry_b.get("source_code_priority", false)), "Source Code row B should expose priority metadata: %s" % str(entry_b))
	_require(int(entry_a.get("source_priority", -1)) == 1 and int(entry_b.get("source_priority", -1)) == 2, "Rows should show 1-based priority labels: %s / %s" % [str(entry_a), str(entry_b)])
	main._move_source_code_priority_for_payload(0, 1)
	_require(_priority_payloads(unit_bp) == [1, 0], "Moving first Source Code down should write reversed priority order: %s" % str(unit_bp.get("source_code_priority", [])))
	torso_a_entries = main._torso_software_slot_summary(unit_bp, 0)
	torso_b_entries = main._torso_software_slot_summary(unit_bp, 1)
	entry_a = _source_entry_for_payload(torso_a_entries, 0)
	entry_b = _source_entry_for_payload(torso_b_entries, 1)
	_require(int(entry_a.get("source_priority", -1)) == 2 and int(entry_b.get("source_priority", -1)) == 1, "Moved rows should refresh priority labels: %s / %s" % [str(entry_a), str(entry_b)])
	main._move_source_code_priority_for_payload(0, -1)
	_require(_priority_payloads(unit_bp) == [0, 1], "Moving Source Code back up should restore priority order.")
	main._move_source_code_priority_for_payload(0, 1)
	main._reset_source_code_priority()
	_require(_priority_payloads(unit_bp) == [0, 1], "Reset should restore stable payload order: %s" % str(unit_bp.get("source_code_priority", [])))
	if failed:
		quit(1)
		return
	print("SOURCE_CODE_PRIORITY_EDITOR_PROBE ok order=%s" % str(_priority_payloads(unit_bp)))
	quit(0)
