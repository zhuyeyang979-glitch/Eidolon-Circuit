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


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var combined_bp := {
		"name": "Combined Rule Invalid Hero",
		"role": "hero",
		"archetype": "custom",
		"special": -1,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": 0,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"slot_payloads": [],
		"custom_topology": {"nodes": [], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"socket_size_records": [
			{
				"part_name": "Oversized Probe Part",
				"part_size": "M",
				"socket_capacity": "S",
				"socket_id": "probe_socket",
			},
		],
		"construct_body_manufacturer_records": [
			{
				"body_id": "probe_body",
				"parts": [
					{"name": "Probe Torso", "maker": "HUMANOVA ATELIER", "slot_key": "muscle"},
					{"name": "Probe Arm", "maker": "REDLINE ARMS", "slot_key": "limb_muscle"},
					{"name": "Probe Code", "maker": "NULL SOFTWARE", "slot_key": "special", "kind": "source_code"},
				],
			},
		],
	}
	var report: Dictionary = main._unit_editor_legality_report("hero", combined_bp)
	_require(not bool(report.get("valid", true)), "Combined invalid blueprint should fail: %s" % str(report))
	for code in ["hero_soul_count", "socket_part_too_large", "construct_body_mixed_manufacturer"]:
		_require(_has_code(report, code), "Combined report should preserve %s: %s" % [code, str(report)])
	var messages: Dictionary = Dictionary(report.get("messages", {}))
	_require(Array(messages.get("zh", [])).size() >= 3, "Combined report should preserve zh messages for all merged issues: %s" % str(report))
	_require(Array(messages.get("en", [])).size() >= 3, "Combined report should preserve en messages for all merged issues: %s" % str(report))
	_require(Array(report.get("issues", [])).size() >= 3, "Combined report should preserve all issue dictionaries: %s" % str(report))
	var note := main._training_blueprint_illegal_note(1, "hero", combined_bp)
	_require(note.begins_with("INVALID"), "Training note should still reject the combined invalid blueprint: %s" % note)

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_COMBINED_RULE_PROBE ok codes=%s" % str(report.get("blocking_codes", [])))
	quit(0)
