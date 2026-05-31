extends RefCounted

const PartArt = preload("res://scripts/part_art.gd")

const SOCKET_ROOT := "root_joint"
const SOCKET_DISTAL := "distal"
const SOCKET_TORSO_PREFIX := "torso_port:"


static func canonical_socket_id(socket_id: String) -> String:
	match socket_id:
		"torso", "port":
			return SOCKET_TORSO_PREFIX + "0"
		"side:-1", "side:a", "end:a", "single", "handle", "root", "root_joint":
			return SOCKET_ROOT
		"side:1", "side:b", "end:b", "tip", "distal":
			return SOCKET_DISTAL
	if socket_id.begins_with("torso:"):
		return SOCKET_TORSO_PREFIX + socket_id.get_slice(":", 1)
	if socket_id.begins_with("port:"):
		return SOCKET_TORSO_PREFIX + socket_id.get_slice(":", 1)
	return socket_id


static func socket_side_value(socket_id: String) -> int:
	var id := canonical_socket_id(socket_id)
	if id == SOCKET_ROOT:
		return -1
	if id == SOCKET_DISTAL:
		return 1
	return 0


static func is_torso_socket(socket_id: String) -> bool:
	return canonical_socket_id(socket_id).begins_with(SOCKET_TORSO_PREFIX)


static func socket_pair_can_connect(socket_a: String, socket_b: String) -> bool:
	var a := canonical_socket_id(socket_a)
	var b := canonical_socket_id(socket_b)
	if a == "" or b == "":
		return false
	if is_torso_socket(a) or is_torso_socket(b):
		return (is_torso_socket(a) and b == SOCKET_ROOT) or (is_torso_socket(b) and a == SOCKET_ROOT)
	return (a == SOCKET_DISTAL and b == SOCKET_ROOT) or (a == SOCKET_ROOT and b == SOCKET_DISTAL)


static func socket_key(node_index: int, socket_id: String) -> String:
	return "%d|%s" % [node_index, canonical_socket_id(socket_id)]


static func occupancy_from_edges(edges: Array) -> Dictionary:
	var occupancy := {}
	for edge in edges:
		if not (edge is Dictionary):
			continue
		var dict: Dictionary = edge
		var a := int(dict.get("a_node", dict.get("a", -1)))
		var b := int(dict.get("b_node", dict.get("b", -1)))
		var a_socket := canonical_socket_id(String(dict.get("a_socket", "")))
		var b_socket := canonical_socket_id(String(dict.get("b_socket", "")))
		if a >= 0 and a_socket != "":
			var key_a := socket_key(a, a_socket)
			if not occupancy.has(key_a):
				occupancy[key_a] = []
			occupancy[key_a].append(edge)
		if b >= 0 and b_socket != "":
			var key_b := socket_key(b, b_socket)
			if not occupancy.has(key_b):
				occupancy[key_b] = []
			occupancy[key_b].append(edge)
	return occupancy


static func edge_uses_socket(edge, node_index: int, socket_id: String) -> bool:
	if not (edge is Dictionary):
		return false
	var dict: Dictionary = edge
	var id := canonical_socket_id(socket_id)
	if int(dict.get("a_node", dict.get("a", -1))) == node_index:
		return canonical_socket_id(String(dict.get("a_socket", ""))) == id
	if int(dict.get("b_node", dict.get("b", -1))) == node_index:
		return canonical_socket_id(String(dict.get("b_socket", ""))) == id
	return false


static func edge_node_a(edge) -> int:
	if edge is Dictionary:
		return int(Dictionary(edge).get("a_node", Dictionary(edge).get("a", -1)))
	if edge is Array and edge.size() >= 2:
		return int(edge[0])
	return -1


static func edge_node_b(edge) -> int:
	if edge is Dictionary:
		return int(Dictionary(edge).get("b_node", Dictionary(edge).get("b", -1)))
	if edge is Array and edge.size() >= 2:
		return int(edge[1])
	return -1


static func edge_socket_for_node(edge, node_index: int) -> String:
	if not (edge is Dictionary):
		return ""
	var dict: Dictionary = edge
	if int(dict.get("a_node", dict.get("a", -1))) == node_index:
		return canonical_socket_id(String(dict.get("a_socket", "")))
	if int(dict.get("b_node", dict.get("b", -1))) == node_index:
		return canonical_socket_id(String(dict.get("b_socket", "")))
	return ""


static func edge_other_node(edge, node_index: int) -> int:
	var a := edge_node_a(edge)
	var b := edge_node_b(edge)
	if a == node_index:
		return b
	if b == node_index:
		return a
	return -1


static func downstream_nodes_from_edges(edges: Array, root_index: int, node_count: int) -> Array:
	if root_index < 0 or root_index >= node_count:
		return []
	var result: Array = []
	var visited := {}
	var stack: Array = [root_index]
	while not stack.is_empty():
		var current := int(stack.pop_back())
		if current < 0 or current >= node_count or visited.has(current):
			continue
		visited[current] = true
		result.append(current)
		for edge in edges:
			var a := edge_node_a(edge)
			var b := edge_node_b(edge)
			if a < 0 or b < 0 or a >= node_count or b >= node_count:
				continue
			if a != current and b != current:
				continue
			var own_socket := edge_socket_for_node(edge, current)
			if own_socket != SOCKET_DISTAL:
				continue
			var other := b if a == current else a
			var other_socket := edge_socket_for_node(edge, other)
			if other_socket != SOCKET_ROOT:
				continue
			if not visited.has(other):
				stack.append(other)
	return result


static func torso_port_local_offsets(port_count: int, length: float, front_width: float, rear_width: float) -> Array:
	return PartArt.torso_saddle_port_local_offsets(port_count, length, front_width, rear_width)


static func torso_port_directions(port_count: int) -> Array:
	return PartArt.torso_saddle_port_directions(port_count)
