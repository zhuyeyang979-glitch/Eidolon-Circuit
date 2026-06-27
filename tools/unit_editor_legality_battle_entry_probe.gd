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


func _minimal_puppet(main, unit_name: String, has_source_code: bool) -> Dictionary:
	main.editor_role_index = MainScene.ROLE_ORDER.find("puppet")
	var core_index: int = int(main._component_index_by_name("puppet", "muscle", "FLOATING BIT CORE", 95))
	var node: Dictionary = main._topology_component_node(0, "CORE", Vector2(0.5, 0.5), "muscle", core_index)
	return {
		"name": unit_name,
		"unit_name": unit_name,
		"role": "puppet",
		"archetype": "custom",
		"special": 0 if has_source_code else -1,
		"joint": 0,
		"limb_muscle": 0,
		"muscle": core_index,
		"booster": 0,
		"engine": 0,
		"cooling": 0,
		"module": 0,
		"blank_canvas": false,
		"custom_topology": {"nodes": [node], "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION},
		"slot_payloads": [],
		"purchased_parts": {},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var legal_puppet := _minimal_puppet(main, "Battle Entry Legal Puppet", true)
	var invalid_puppet := _minimal_puppet(main, "Battle Entry Invalid Puppet", false)
	var legal_note := main._training_blueprint_illegal_note(1, "puppet", legal_puppet)
	var invalid_note := main._training_blueprint_illegal_note(1, "puppet", invalid_puppet)
	_require(legal_note == "", "Legal puppet fixture should be training legal, got %s" % legal_note)
	_require(invalid_note.find("puppet_source_code_missing") >= 0, "Invalid puppet fixture should fail shared legality report, got %s" % invalid_note)
	if failed:
		quit(1)
		return

	main.blueprints[1]["puppet"] = [legal_puppet, invalid_puppet]
	main.ai_roster_stats_cache.clear()
	_require(main._sortie_entry_is_battle_legal(1, {"role": "puppet", "index": 0}, false), "Legal puppet should remain battle-entry legal.")
	_require(not main._sortie_entry_is_battle_legal(1, {"role": "puppet", "index": 1}, false), "Battle-entry legality should reject puppet_source_code_missing.")

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_BATTLE_ENTRY_PROBE ok note=%s" % invalid_note)
	quit(0)
