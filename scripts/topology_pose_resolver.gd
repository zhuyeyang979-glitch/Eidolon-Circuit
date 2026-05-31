class_name TopologyPoseResolver
extends RefCounted

const SOCKET_ROOT := "root_joint"
const SOCKET_DISTAL := "distal"
const SOCKET_TORSO_PREFIX := "torso_port:"


static func resolve_runtime_segments(base_segments: Array, edges: Array, pose_overrides: Dictionary = {}, local_space := true) -> Dictionary:
	var a_key := "a_local" if local_space else "a"
	var b_key := "b_local" if local_space else "b"
	var axis_key := "axis_local" if local_space else "axis"
	var polygon_key := "polygon_local" if local_space else "polygon"
	var root_anchor_key := "root_anchor_local" if local_space else "root_anchor"
	var tip_anchor_key := "tip_anchor_local" if local_space else "tip_anchor"
	var parent_anchor_key := "parent_socket_anchor_local" if local_space else "parent_socket_anchor"
	var base_by_node := {}
	var order: Array = []
	for raw_segment in base_segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = Dictionary(raw_segment)
		var node_index := int(segment.get("node_index", -1))
		if node_index < 0:
			continue
		base_by_node[node_index] = segment
		order.append(node_index)
	var relations := _runtime_parent_relations(edges, base_by_node)
	var children_by_parent := {}
	for child_raw in relations.keys():
		var child := int(child_raw)
		var parent := int(Dictionary(relations[child]).get("parent", -1))
		if parent < 0:
			continue
		if not children_by_parent.has(parent):
			children_by_parent[parent] = []
		children_by_parent[parent].append(child)
	var resolved_by_node := {}
	var socket_anchors := {}
	var max_gap := 0.0
	var visiting := {}
	for raw_node in order:
		var node_index := int(raw_node)
		var gap := _resolve_node(
			node_index,
			base_by_node,
			relations,
			resolved_by_node,
			pose_overrides,
			a_key,
			b_key,
			axis_key,
			polygon_key,
			root_anchor_key,
			tip_anchor_key,
			parent_anchor_key,
			visiting
		)
		max_gap = maxf(max_gap, gap)
	var resolved_segments: Array = []
	for raw_node in order:
		var node_index := int(raw_node)
		if not resolved_by_node.has(node_index):
			continue
		var segment: Dictionary = Dictionary(resolved_by_node[node_index])
		resolved_segments.append(segment)
		socket_anchors[node_index] = {
			"root": segment.get(root_anchor_key, segment.get(a_key, Vector2.ZERO)),
			"tip": segment.get(tip_anchor_key, segment.get(b_key, Vector2.ZERO)),
			"parent": segment.get(parent_anchor_key, segment.get(a_key, Vector2.ZERO)),
			"socket_gap": float(segment.get("socket_gap", 0.0)),
			"pre_resolve_socket_gap": float(segment.get("pre_resolve_socket_gap", 0.0)),
		}
	return {
		"segments": resolved_segments,
		"socket_anchors": socket_anchors,
		"max_socket_gap": max_gap,
		"children_by_parent": children_by_parent,
	}


static func _resolve_node(node_index: int, base_by_node: Dictionary, relations: Dictionary, resolved_by_node: Dictionary, pose_overrides: Dictionary, a_key: String, b_key: String, axis_key: String, polygon_key: String, root_anchor_key: String, tip_anchor_key: String, parent_anchor_key: String, visiting: Dictionary) -> float:
	if resolved_by_node.has(node_index):
		return float(Dictionary(resolved_by_node[node_index]).get("socket_gap", 0.0))
	if visiting.has(node_index) or not base_by_node.has(node_index):
		return 0.0
	visiting[node_index] = true
	var base: Dictionary = Dictionary(base_by_node[node_index])
	var override := _override_for_segment(base, pose_overrides)
	var overridden := not override.is_empty()
	var segment := _segment_with_pose_override(base, override, a_key, b_key, axis_key, polygon_key)
	var base_a := _vector(base.get(a_key, Vector2.ZERO))
	var base_b := _vector(base.get(b_key, base_a))
	var parent_anchor := _vector(segment.get(a_key, base_a))
	var pre_gap := 0.0
	if relations.has(node_index):
		var relation: Dictionary = Dictionary(relations[node_index])
		var parent_index := int(relation.get("parent", -1))
		if parent_index >= 0 and base_by_node.has(parent_index):
			_resolve_node(parent_index, base_by_node, relations, resolved_by_node, pose_overrides, a_key, b_key, axis_key, polygon_key, root_anchor_key, tip_anchor_key, parent_anchor_key, visiting)
			var parent_segment: Dictionary = Dictionary(resolved_by_node.get(parent_index, {}))
			if String(parent_segment.get("part_kind", "")) == "torso":
				parent_anchor = _vector(base.get(parent_anchor_key, base_a))
				if parent_anchor == Vector2.ZERO and base.has(a_key):
					parent_anchor = base_a
			else:
				parent_anchor = _vector(parent_segment.get(b_key, parent_segment.get(tip_anchor_key, base_a)))
			var desired_axis := _axis_from_segment(segment, a_key, b_key, axis_key)
			if not overridden:
				var base_parent: Dictionary = Dictionary(base_by_node.get(parent_index, {}))
				var base_parent_axis := _axis_from_segment(base_parent, a_key, b_key, axis_key)
				var base_axis := _axis_from_segment(base, a_key, b_key, axis_key)
				var resolved_parent_axis := _axis_from_segment(parent_segment, a_key, b_key, axis_key)
				if base_parent_axis.length() > 0.001 and base_axis.length() > 0.001 and resolved_parent_axis.length() > 0.001:
					desired_axis = resolved_parent_axis.normalized().rotated(wrapf(base_axis.angle() - base_parent_axis.angle(), -PI, PI)).normalized()
			pre_gap = _vector(segment.get(a_key, base_a)).distance_to(parent_anchor)
			segment = _reanchor_segment(segment, parent_anchor, desired_axis, a_key, b_key, axis_key, polygon_key)
	var root_anchor := _vector(segment.get(a_key, base_a))
	var tip_anchor := _vector(segment.get(b_key, base_b))
	var gap := root_anchor.distance_to(parent_anchor)
	segment[root_anchor_key] = root_anchor
	segment[tip_anchor_key] = tip_anchor
	segment[parent_anchor_key] = parent_anchor
	segment["socket_gap"] = gap
	segment["pre_resolve_socket_gap"] = pre_gap
	if not segment.has("pose_source"):
		segment["pose_source"] = "pose_resolver_override" if overridden else String(base.get("pose_source", "topology_pose_resolver"))
	resolved_by_node[node_index] = segment
	visiting.erase(node_index)
	return gap


static func _runtime_parent_relations(edges: Array, base_by_node: Dictionary) -> Dictionary:
	var result := {}
	for raw_edge in edges:
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a := int(edge.get("a_node", edge.get("a", -1)))
		var b := int(edge.get("b_node", edge.get("b", -1)))
		if not base_by_node.has(a) or not base_by_node.has(b):
			continue
		var a_socket := _canonical_socket_id(String(edge.get("a_socket", "")))
		var b_socket := _canonical_socket_id(String(edge.get("b_socket", "")))
		if _is_parent_socket(a_socket) and b_socket == SOCKET_ROOT:
			result[b] = {"parent": a, "parent_socket": a_socket, "child_socket": b_socket}
		elif _is_parent_socket(b_socket) and a_socket == SOCKET_ROOT:
			result[a] = {"parent": b, "parent_socket": b_socket, "child_socket": a_socket}
	return result


static func _segment_with_pose_override(base: Dictionary, override: Dictionary, a_key: String, b_key: String, axis_key: String, polygon_key: String) -> Dictionary:
	var segment: Dictionary = base.duplicate(true)
	if override.is_empty():
		return segment
	var full_segment := false
	for key in [a_key, b_key, "a", "b", "a_local", "b_local"]:
		if override.has(key):
			full_segment = true
			break
	if full_segment:
		segment = override.duplicate(true)
		for key in ["node_index", "part_kind", "name", "slot", "radius", "visual_mount_side", "weapon_family", "shape", "source_shape", "terminal_weapon_kind"]:
			if not segment.has(key) and base.has(key):
				segment[key] = base[key]
		return segment
	var root := _vector(segment.get(a_key, Vector2.ZERO))
	var base_b := _vector(segment.get(b_key, root + Vector2.RIGHT))
	var length := maxf(0.001, root.distance_to(base_b))
	var axis := _axis_from_segment(segment, a_key, b_key, axis_key)
	if override.has("absolute_axis_local") or override.has("absolute_axis"):
		axis = _vector(override.get("absolute_axis_local", override.get("absolute_axis", axis))).normalized()
	elif override.has("absolute_angle"):
		axis = Vector2.RIGHT.rotated(float(override.get("absolute_angle", 0.0))).normalized()
	elif override.has("local_angle_offset"):
		axis = axis.rotated(float(override.get("local_angle_offset", 0.0))).normalized()
	elif override.has("axis_local") or override.has("axis"):
		axis = _vector(override.get("axis_local", override.get("axis", axis))).normalized()
	if override.has("local_extension"):
		length += maxf(0.0, float(override.get("local_extension", 0.0)))
	return _reanchor_segment(segment, root, axis, a_key, b_key, axis_key, polygon_key, length)


static func _reanchor_segment(segment: Dictionary, new_root: Vector2, desired_axis: Vector2, a_key: String, b_key: String, axis_key: String, polygon_key: String, forced_length := -1.0) -> Dictionary:
	var old_a := _vector(segment.get(a_key, Vector2.ZERO))
	var old_b := _vector(segment.get(b_key, old_a + Vector2.RIGHT))
	var old_axis := old_b - old_a
	var length := forced_length if forced_length > 0.0 else maxf(0.001, old_axis.length())
	var old_dir := old_axis.normalized() if old_axis.length() > 0.001 else _axis_from_segment(segment, a_key, b_key, axis_key)
	var new_dir := desired_axis.normalized() if desired_axis.length() > 0.001 else old_dir
	var angle_delta := wrapf(new_dir.angle() - old_dir.angle(), -PI, PI)
	var updated := segment.duplicate(true)
	updated[a_key] = new_root
	updated[b_key] = new_root + new_dir * length
	updated[axis_key] = new_dir
	if updated.has(polygon_key):
		var rotated: Array = []
		for raw_point in Array(updated.get(polygon_key, [])):
			rotated.append(new_root + (_vector(raw_point) - old_a).rotated(angle_delta))
		updated[polygon_key] = rotated
	return updated


static func _override_for_segment(segment: Dictionary, pose_overrides: Dictionary) -> Dictionary:
	if pose_overrides.is_empty():
		return {}
	var node_index := int(segment.get("node_index", -1))
	var key := _segment_key(segment)
	for candidate in [key, str(node_index), node_index]:
		if pose_overrides.has(candidate) and pose_overrides[candidate] is Dictionary:
			return Dictionary(pose_overrides[candidate])
	return {}


static func _segment_key(segment: Dictionary) -> String:
	return "%d:%s" % [int(segment.get("node_index", -1)), String(segment.get("part_kind", ""))]


static func _axis_from_segment(segment: Dictionary, a_key: String, b_key: String, axis_key: String) -> Vector2:
	var raw_axis = segment.get(axis_key, null)
	if raw_axis is Vector2 and Vector2(raw_axis).length() > 0.001:
		return Vector2(raw_axis).normalized()
	var a := _vector(segment.get(a_key, Vector2.ZERO))
	var b := _vector(segment.get(b_key, a + Vector2.RIGHT))
	var axis := b - a
	if axis.length() <= 0.001:
		return Vector2.RIGHT
	return axis.normalized()


static func _vector(value) -> Vector2:
	return value if value is Vector2 else Vector2.ZERO


static func _canonical_socket_id(socket_id: String) -> String:
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


static func _is_parent_socket(socket_id: String) -> bool:
	return socket_id == SOCKET_DISTAL or socket_id.begins_with(SOCKET_TORSO_PREFIX)
