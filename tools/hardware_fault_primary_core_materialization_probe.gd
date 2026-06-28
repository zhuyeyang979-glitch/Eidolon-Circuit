extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const TARGET_NODE_ID := 0

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _torso_index(main) -> int:
	var catalog: Array = main._catalog_for("puppet", "muscle")
	for i in range(catalog.size()):
		if catalog[i] is Dictionary and main._component_is_torso(Dictionary(catalog[i])):
			return i
	return -1


func _blueprint(torso: int) -> Dictionary:
	return {
		"role": "puppet",
		"name": "Hardware Fault Primary Core Materialization Probe",
		"blank_canvas": false,
		"custom_topology": {
			"nodes": [
				{"id": 0, "slot": "muscle", "part_index": torso, "label": "Core A"},
				{"id": 1, "slot": "muscle", "part_index": torso, "label": "Core B"},
			],
			"edges": [],
		},
		"slot_payloads": [],
		"source_code_priority": [],
	}


func _segment_by_node(stats: Dictionary, node_id: int) -> Dictionary:
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -1)) == node_id:
			return Dictionary(raw_segment)
	return {}


func _with_probe_capacity(stats: Dictionary) -> Dictionary:
	var result := stats.duplicate(true)
	result["health"] = 1000
	result["max_health"] = 1000
	result["electronic_armor_max"] = 0.0
	var segments: Array = Array(result.get("runtime_topology_segments", [])).duplicate(true)
	for i in range(segments.size()):
		if not (segments[i] is Dictionary):
			continue
		var segment: Dictionary = Dictionary(segments[i]).duplicate(true)
		segment["runtime_momentum_capacity"] = 10.0
		segment["stiffness_momentum"] = 10.0
		segment["path_stiffness_momentum"] = 10.0
		segments[i] = segment
	result["runtime_topology_segments"] = segments
	return result


func _attacker_stats() -> Dictionary:
	return {
		"unit_id": "primary-core-materialization-attacker",
		"health": 1000,
		"max_health": 1000,
		"mass": 40.0,
		"radius": 0.18,
		"length": 0.7,
		"electronic_armor_max": 0.0,
	}


func _attacker_collider() -> Dictionary:
	return {
		"name": "Primary Core Materialization Hammer",
		"part_kind": "terminal",
		"part_index": 0,
		"node_index": 9,
		"torso_unit_index": 0,
		"independent_damage": true,
		"terminal_weapon_kind": "melee",
		"damage_type": "blunt",
		"material_class": "weapon",
		"damage_coeff": 2.0,
		"break_coeff": 1.0,
		"stiffness_momentum": 120.0,
		"path_stiffness_momentum": 120.0,
	}


func _collider_for_node(unit, node_id: int) -> Dictionary:
	for raw_collider in unit.part_colliders():
		if raw_collider is Dictionary and int(Dictionary(raw_collider).get("node_index", -1)) == node_id:
			return Dictionary(raw_collider)
	return {}


func _apply_core_hit(main, attacker, target) -> void:
	var target_collider := _collider_for_node(target, TARGET_NODE_ID)
	_require(not target_collider.is_empty(), "Generated primary core collider should be available before hit.")
	if target_collider.is_empty():
		return
	main._apply_runtime_contact_damage(
		attacker,
		_attacker_collider(),
		target,
		target_collider,
		Vector2.RIGHT,
		80.0,
		Vector2(1.2, 0.0),
		"active_melee"
	)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main._reset_hardware_fault_runtime_state()
	main.battle_attack_rule_log.clear()
	main.battle_mode = MainScene.MODE_PVP
	main.victory_points = {1: 0, 2: 0}
	main.game_over = false
	var torso := _torso_index(main)
	_require(torso >= 0, "Probe needs one puppet torso.")
	if failed:
		quit(1)
		return
	var stats: Dictionary = main._compute_unit_stats(1, "puppet", 4, _blueprint(torso))
	var segment_a := _segment_by_node(stats, 0)
	var segment_b := _segment_by_node(stats, 1)
	_require(not segment_a.is_empty() and not segment_b.is_empty(), "Generated topology should expose both torso segments: %s" % str(stats.get("runtime_topology_segments", [])))
	_require(String(segment_a.get("construct_body_id", "")) == "p1:puppet:u4:body0", "First segment should carry runtime construct-body ID: %s" % str(segment_a))
	_require(String(segment_b.get("construct_body_id", "")) == "p1:puppet:u4:body1", "Second segment should carry runtime construct-body ID: %s" % str(segment_b))
	_require(int(segment_a.get("primary_core_node_id", -1)) == 0, "First generated body should name node 0 as its primary core: %s" % str(segment_a))
	_require(int(segment_b.get("primary_core_node_id", -1)) == 1, "Second generated body should name node 1 as its primary core: %s" % str(segment_b))
	if failed:
		quit(1)
		return
	var attacker = main._create_unit(1, "hero", _attacker_stats(), "Primary Core Materialization Attacker", 1.0, 0.0)
	var target = main._create_unit(2, "puppet", _with_probe_capacity(stats), "Primary Core Materialization Target", 1.4, 0.0)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	_apply_core_hit(main, attacker, target)
	_require(main.active_units[2]["hero"] == target, "First generated core overload should fault without retiring the target.")
	_apply_core_hit(main, attacker, target)
	var intents: Array = main._hardware_fault_destruction_intents()
	_require(intents.size() == 1, "Second generated core overload should record one destruction intent: %s" % str(intents))
	if not intents.is_empty() and intents[0] is Dictionary:
		_require(String(Dictionary(intents[0]).get("destruction_intent", "")) == "destroy_construct_body", "Generated primary core destruction should target the construct body: %s" % str(intents[0]))
	_require(main.active_units[2]["hero"] == null, "Generated primary core destruction should retire the target unit.")
	_require(int(main.victory_points[1]) == 1, "Generated primary core destruction should award one VP.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_PRIMARY_CORE_MATERIALIZATION_PROBE ok intents=%d" % intents.size())
	quit(0)
