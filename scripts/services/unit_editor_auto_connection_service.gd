extends RefCounted
class_name UnitEditorAutoConnectionService

const STATE_PASSED := "passed"
const STATE_REPAIRABLE := "repairable"
const STATE_BLOCKED := "blocked"
const STATE_STALE := "stale"

const CHILD_SOCKET := "root_joint"
const PARENT_SOCKET_DISTAL := "distal"
const TORSO_PORT_PREFIX := "torso_port:"


func plan_auto_connections(context: Dictionary) -> Dictionary:
	var facts := _sorted_facts(Array(context.get("node_facts", [])))
	var edges := Array(context.get("edges", []))
	var occupied := _occupied_socket_map(facts, edges)
	var intents: Array = []
	var unresolved: Array = []
	var connected := _initial_connected_nodes(facts, edges)
	var pending := _pending_child_nodes(facts, connected)
	var guard := 0
	while not pending.is_empty() and guard < facts.size() + 4:
		guard += 1
		var best := _best_candidate(pending, facts, connected, occupied)
		if best.is_empty():
			break
		intents.append(best)
		_mark_socket_occupied(occupied, int(best.get("child", -1)), String(best.get("child_socket", "")))
		_mark_socket_occupied(occupied, int(best.get("parent", -1)), String(best.get("parent_socket", "")))
		connected[int(best.get("child", -1))] = true
		_remove_pending_child(pending, int(best.get("child", -1)))
	for raw_fact in pending:
		if raw_fact is Dictionary:
			unresolved.append(int(Dictionary(raw_fact).get("index", -1)))
	return {
		"intents": intents,
		"unresolved_nodes": _sorted_ints(unresolved),
		"summary": _plan_summary(intents.size(), unresolved.size()),
	}


func evaluate_connection(context: Dictionary) -> Dictionary:
	var signature := String(context.get("topology_signature", ""))
	var last_signature := String(context.get("last_signature", ""))
	if last_signature != "" and signature != last_signature:
		return _evaluation(STATE_STALE, "连接已改动，请重新评估。", "Connection changed; evaluate again.", signature, context)
	var node_count := int(context.get("node_count", 0))
	var torso_count := int(context.get("torso_count", 0))
	var topology_note := String(context.get("topology_note", ""))
	var repairable_nodes := _sorted_ints(Array(context.get("repairable_nodes", [])))
	var unconnected_nodes := _sorted_ints(Array(context.get("unconnected_nodes", [])))
	if node_count <= 0:
		return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干或构件。", "Connection blocked: place a torso or component first.", signature, context)
	if torso_count <= 0:
		return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干。", "Connection blocked: place a torso first.", signature, context)
	if topology_note.begins_with("INVALID"):
		if not repairable_nodes.is_empty():
			return _evaluation(STATE_REPAIRABLE, "部分构件未接入；可尝试自动连接。", "Some parts are unlinked; Auto Connect can try to repair them.", signature, context)
		return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干或修正接口冲突。", "Connection blocked: fix torso or socket conflicts first.", signature, context)
	if not unconnected_nodes.is_empty():
		if not repairable_nodes.is_empty():
			return _evaluation(STATE_REPAIRABLE, "部分构件未接入；可尝试自动连接。", "Some parts are unlinked; Auto Connect can try to repair them.", signature, context)
		return _evaluation(STATE_BLOCKED, "连接阻断：请先修正未接入构件。", "Connection blocked: fix unlinked components first.", signature, context)
	return _evaluation(STATE_PASSED, "连接评估通过：可以进入入场姿态。", "Connection passed: entry pose is available.", signature, context)


func topology_signature(nodes: Array, edges: Array) -> String:
	var node_parts: Array = []
	for i in range(nodes.size()):
		if not (nodes[i] is Dictionary):
			continue
		var node: Dictionary = nodes[i]
		var pos_key := _position_key(node.get("pos", Vector2.ZERO))
		var slot := String(node.get("slot", node.get("slot_key", "")))
		var part_index := int(node.get("part_index", node.get(slot, -1)))
		node_parts.append("%d:%s:%d:%s" % [i, slot, part_index, pos_key])
	var edge_parts: Array = []
	for raw_edge in edges:
		if raw_edge is Dictionary:
			var edge: Dictionary = raw_edge
			edge_parts.append("%d:%s-%d:%s" % [
				int(edge.get("a_node", edge.get("a", -1))),
				String(edge.get("a_socket", "")),
				int(edge.get("b_node", edge.get("b", -1))),
				String(edge.get("b_socket", "")),
			])
		else:
			edge_parts.append(str(raw_edge))
	edge_parts.sort()
	return "nodes=%s|edges=%s" % [";".join(node_parts), ";".join(edge_parts)]


func _sorted_facts(facts: Array) -> Array:
	var result: Array = []
	for raw_fact in facts:
		if raw_fact is Dictionary and bool(Dictionary(raw_fact).get("is_component", false)):
			result.append(Dictionary(raw_fact).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("index", -1)) < int(b.get("index", -1))
	)
	return result


func _pending_child_nodes(facts: Array, connected: Dictionary) -> Array:
	var result: Array = []
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		var index := int(fact.get("index", -1))
		if bool(fact.get("is_torso", false)):
			continue
		if connected.has(index):
			continue
		if _socket_by_id(fact, CHILD_SOCKET).is_empty():
			continue
		result.append(fact)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := _child_priority(a)
		var pb := _child_priority(b)
		if pa == pb:
			return int(a.get("index", -1)) < int(b.get("index", -1))
		return pa < pb
	)
	return result


func _initial_connected_nodes(facts: Array, edges: Array) -> Dictionary:
	var result := {}
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		var index := int(fact.get("index", -1))
		if bool(fact.get("is_torso", false)):
			result[index] = true
	if edges.is_empty():
		for raw_fact in facts:
			var fact: Dictionary = raw_fact
			if int(fact.get("edge_count", 0)) > 0:
				result[int(fact.get("index", -1))] = true
		return result
	var changed := true
	while changed:
		changed = false
		for raw_edge in edges:
			var endpoint := _edge_nodes(raw_edge)
			var a := int(endpoint.get("a", -1))
			var b := int(endpoint.get("b", -1))
			if a < 0 or b < 0:
				continue
			var a_connected := result.has(a)
			var b_connected := result.has(b)
			if a_connected and not b_connected:
				result[b] = true
				changed = true
			elif b_connected and not a_connected:
				result[a] = true
				changed = true
	return result


func _best_candidate(pending: Array, facts: Array, connected: Dictionary, occupied: Dictionary) -> Dictionary:
	var best := {}
	var best_score := INF
	for raw_child in pending:
		var child: Dictionary = raw_child
		var child_index := int(child.get("index", -1))
		var child_socket := _socket_by_id(child, CHILD_SOCKET)
		if child_socket.is_empty() or _socket_is_occupied(occupied, child_index, CHILD_SOCKET):
			continue
		for raw_parent in facts:
			var parent: Dictionary = raw_parent
			var parent_index := int(parent.get("index", -1))
			if not connected.has(parent_index):
				continue
			if parent_index == child_index:
				continue
			for parent_socket in _parent_sockets(parent):
				var parent_socket_id := String(parent_socket.get("id", ""))
				if not _socket_can_be_parent(parent, parent_socket_id):
					continue
				if _socket_is_occupied(occupied, parent_index, parent_socket_id):
					continue
				var score := _candidate_score(child, child_socket, parent, parent_socket)
				if score < best_score:
					best_score = score
					best = {
						"child": child_index,
						"child_socket": CHILD_SOCKET,
						"parent": parent_index,
						"parent_socket": parent_socket_id,
						"score": score,
					}
	return best


func _candidate_score(child: Dictionary, child_socket: Dictionary, parent: Dictionary, parent_socket: Dictionary) -> float:
	var child_pos := _vector2_value(child_socket.get("pos", child.get("pos", Vector2.ZERO)), _vector2_value(child.get("pos", Vector2.ZERO)))
	var parent_pos := _vector2_value(parent_socket.get("pos", parent.get("pos", Vector2.ZERO)), _vector2_value(parent.get("pos", Vector2.ZERO)))
	var distance := child_pos.distance_to(parent_pos)
	var size_delta := absf(float(child.get("size_rank", 2)) - float(parent.get("size_rank", 2)))
	var terminal_penalty := 0.35 if bool(child.get("is_terminal_weapon", false)) else 0.0
	var torso_bonus := -0.20 if bool(parent.get("is_torso", false)) else 0.0
	return distance + size_delta * 0.05 + terminal_penalty + torso_bonus + float(int(child.get("index", 0))) * 0.0001


func _child_priority(fact: Dictionary) -> int:
	if bool(fact.get("is_terminal_weapon", false)):
		return 20
	if String(fact.get("slot_key", "")) == "limb_muscle":
		return 5
	return 10


func _parent_sockets(parent: Dictionary) -> Array:
	var result: Array = []
	for raw_socket in Array(parent.get("sockets", [])):
		if raw_socket is Dictionary:
			result.append(Dictionary(raw_socket))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return result


func _socket_by_id(fact: Dictionary, socket_id: String) -> Dictionary:
	for raw_socket in Array(fact.get("sockets", [])):
		if not (raw_socket is Dictionary):
			continue
		var socket: Dictionary = raw_socket
		if String(socket.get("id", "")) == socket_id:
			return socket
	return {}


func _socket_can_be_parent(parent: Dictionary, socket_id: String) -> bool:
	if socket_id.begins_with(TORSO_PORT_PREFIX):
		return bool(parent.get("is_torso", false))
	if bool(parent.get("is_terminal_weapon", false)):
		return false
	return socket_id == PARENT_SOCKET_DISTAL


func _socket_key(node_index: int, socket_id: String) -> String:
	return "%d:%s" % [node_index, socket_id]


func _socket_is_occupied(occupied: Dictionary, node_index: int, socket_id: String) -> bool:
	return bool(occupied.get(_socket_key(node_index, socket_id), false))


func _occupied_socket_map(facts: Array, edges: Array) -> Dictionary:
	var result := {}
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		var node_index := int(fact.get("index", -1))
		for raw_socket in Array(fact.get("sockets", [])):
			if raw_socket is Dictionary:
				var socket: Dictionary = raw_socket
				if bool(socket.get("occupied", false)):
					result[_socket_key(node_index, String(socket.get("id", "")))] = true
	for raw_edge in edges:
		for endpoint in _edge_socket_endpoints(raw_edge):
			_mark_socket_occupied(result, int(endpoint.get("node", -1)), String(endpoint.get("socket", "")))
	return result


func _mark_socket_occupied(occupied: Dictionary, node_index: int, socket_id: String) -> void:
	if node_index >= 0 and socket_id != "":
		occupied[_socket_key(node_index, socket_id)] = true


func _remove_pending_child(pending: Array, child_index: int) -> void:
	for i in range(pending.size() - 1, -1, -1):
		if pending[i] is Dictionary and int(Dictionary(pending[i]).get("index", -1)) == child_index:
			pending.remove_at(i)


func _sorted_ints(values: Array) -> Array:
	var result: Array = []
	for raw_value in values:
		var value := int(raw_value)
		if value >= 0 and not result.has(value):
			result.append(value)
	result.sort()
	return result


func _plan_summary(applied_count: int, unresolved_count: int) -> String:
	if applied_count <= 0 and unresolved_count <= 0:
		return "no_safe_links"
	if unresolved_count > 0:
		return "partial"
	return "complete"


func _evaluation(state: String, zh_note: String, en_note: String, signature: String, context: Dictionary) -> Dictionary:
	return {
		"state": state,
		"note": zh_note,
		"zh_note": zh_note,
		"en_note": en_note,
		"topology_signature": signature,
		"repairable_nodes": _sorted_ints(Array(context.get("repairable_nodes", []))),
		"blocked_nodes": _sorted_ints(Array(context.get("blocked_nodes", []))),
	}


func _edge_nodes(raw_edge: Variant) -> Dictionary:
	if not (raw_edge is Dictionary):
		return {}
	var edge: Dictionary = raw_edge
	return {
		"a": int(edge.get("a_node", edge.get("a", edge.get("parent", -1)))),
		"b": int(edge.get("b_node", edge.get("b", edge.get("child", -1)))),
	}


func _edge_socket_endpoints(raw_edge: Variant) -> Array:
	if not (raw_edge is Dictionary):
		return []
	var edge: Dictionary = raw_edge
	return [
		{
			"node": int(edge.get("a_node", edge.get("a", edge.get("parent", -1)))),
			"socket": String(edge.get("a_socket", edge.get("parent_socket", ""))),
		},
		{
			"node": int(edge.get("b_node", edge.get("b", edge.get("child", -1)))),
			"socket": String(edge.get("b_socket", edge.get("child_socket", ""))),
		},
	]


func _position_key(value: Variant) -> String:
	var pos := _vector2_value(value)
	return "%.3f,%.3f" % [snappedf(pos.x, 0.001), snappedf(pos.y, 0.001)]


func _vector2_value(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Vector2:
		return value
	return fallback
