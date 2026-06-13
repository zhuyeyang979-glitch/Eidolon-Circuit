extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_auto_connection_service.gd"

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _socket(id: String, pos: Vector2, occupied: bool = false) -> Dictionary:
	return {
		"id": id,
		"pos": pos,
		"occupied": occupied,
	}


func _fact(index: int, slot_key: String, pos: Vector2, sockets: Array, is_torso: bool = false, terminal: bool = false, size_rank: int = 2, edge_count: int = 0) -> Dictionary:
	return {
		"index": index,
		"slot_key": slot_key,
		"pos": pos,
		"is_component": true,
		"is_torso": is_torso,
		"is_terminal_weapon": terminal,
		"size_rank": size_rank,
		"edge_count": edge_count,
		"sockets": sockets,
	}


func _plan_edges(plan: Dictionary) -> Array:
	var result: Array = []
	for raw_intent in Array(plan.get("intents", [])):
		if raw_intent is Dictionary:
			var intent: Dictionary = raw_intent
			result.append("%d:%s>%d:%s" % [
				int(intent.get("child", -1)),
				String(intent.get("child_socket", "")),
				int(intent.get("parent", -1)),
				String(intent.get("parent_socket", "")),
			])
	return result


func _init() -> void:
	var script := load(SERVICE_PATH)
	if script == null:
		_fail("Missing UnitEditorAutoConnectionService script.")
		quit(1)
		return
	var service = script.new()
	var torso := _fact(0, "muscle", Vector2(0.50, 0.50), [
		_socket("torso_port:0", Vector2(0.58, 0.50)),
		_socket("torso_port:1", Vector2(0.42, 0.50)),
	], true, false, 3)
	var limb := _fact(1, "limb_muscle", Vector2(0.66, 0.50), [
		_socket("root_joint", Vector2(0.62, 0.50)),
		_socket("distal", Vector2(0.75, 0.50)),
	], false, false, 2)
	var weapon := _fact(2, "muscle", Vector2(0.84, 0.50), [
		_socket("root_joint", Vector2(0.79, 0.50)),
		_socket("blade_tip", Vector2(0.91, 0.50)),
	], false, true, 2)
	var plan: Dictionary = service.plan_auto_connections({
		"node_facts": [torso, limb, weapon],
		"edges": [],
	})
	var expected := [
		"1:root_joint>0:torso_port:0",
		"2:root_joint>1:distal",
	]
	if _plan_edges(plan) != expected:
		_fail("Expected torso -> limb -> weapon plan, got %s." % str(_plan_edges(plan)))
	var occupied_limb := _fact(1, "limb_muscle", Vector2(0.66, 0.50), [
		_socket("root_joint", Vector2(0.62, 0.50), true),
		_socket("distal", Vector2(0.75, 0.50)),
	], false, false, 2)
	var occupied_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [torso, occupied_limb, weapon],
		"edges": [],
	})
	if not Array(occupied_plan.get("unresolved_nodes", [])).has(1):
		_fail("Occupied child root should leave limb unresolved.")
	var upstream := _fact(1, "limb_muscle", Vector2(0.78, 0.50), [
		_socket("root_joint", Vector2(0.72, 0.50), true),
		_socket("distal", Vector2(0.82, 0.50)),
	], false, false, 2, 1)
	var close_child := _fact(2, "muscle", Vector2(0.93, 0.50), [
		_socket("root_joint", Vector2(0.90, 0.50)),
		_socket("distal", Vector2(0.98, 0.50)),
	], false, false, 2)
	var distance_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [
			_fact(0, "muscle", Vector2(0.50, 0.50), [
				_socket("torso_port:0", Vector2(0.68, 0.50)),
			], true, false, 3),
			upstream,
			close_child,
		],
		"edges": [],
	})
	if _plan_edges(distance_plan) != ["2:root_joint>1:distal"]:
		_fail("Nearest parent socket should win before role tie-breakers, got %s." % str(_plan_edges(distance_plan)))
	var no_root_weapon := _fact(1, "muscle", Vector2(0.66, 0.50), [
		_socket("blade_tip", Vector2(0.72, 0.50)),
	], false, true, 2)
	var no_root_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [torso, no_root_weapon],
		"edges": [],
	})
	if not Array(no_root_plan.get("unresolved_nodes", [])).has(1):
		_fail("Unconnected child without root_joint should be unresolved, got %s." % str(no_root_plan))
	var reversed_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [weapon, limb, torso],
		"edges": [],
	})
	if _plan_edges(reversed_plan) != expected:
		_fail("Input order must not change deterministic output, got %s." % str(_plan_edges(reversed_plan)))
	var passed: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=2",
		"last_signature": "nodes=3|edges=2",
		"topology_note": "",
		"node_count": 3,
		"edge_count": 2,
		"torso_count": 1,
		"unconnected_nodes": [],
		"repairable_nodes": [],
	})
	if String(passed.get("state", "")) != "passed":
		_fail("Connected topology should pass, got %s." % str(passed))
	var repairable: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=0",
		"last_signature": "",
		"topology_note": "INVALID: disconnected topology",
		"node_count": 3,
		"edge_count": 0,
		"torso_count": 1,
		"unconnected_nodes": [1, 2],
		"repairable_nodes": [1, 2],
	})
	if String(repairable.get("state", "")) != "repairable":
		_fail("Disconnected but repairable topology should be repairable, got %s." % str(repairable))
	var blocked: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=2|edges=0",
		"last_signature": "",
		"topology_note": "INVALID: missing torso",
		"node_count": 2,
		"edge_count": 0,
		"torso_count": 0,
		"unconnected_nodes": [0, 1],
		"repairable_nodes": [],
	})
	if String(blocked.get("state", "")) != "blocked":
		_fail("Missing torso should block, got %s." % str(blocked))
	var stale: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=1",
		"last_signature": "nodes=3|edges=2",
		"topology_note": "",
		"node_count": 3,
		"edge_count": 1,
		"torso_count": 1,
		"unconnected_nodes": [],
		"repairable_nodes": [],
	})
	if String(stale.get("state", "")) != "stale":
		_fail("Signature mismatch should be stale, got %s." % str(stale))
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_AUTO_CONNECTION_SERVICE_PROBE ok")
	quit(0)
