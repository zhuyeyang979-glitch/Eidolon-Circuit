extends RefCounted
class_name RuntimeColliderBuilderService


func runtime_segment_collider_payload(context: Dictionary) -> Dictionary:
	var segment: Dictionary = Dictionary(context.get("segment", {})).duplicate(true)
	if segment.is_empty():
		return {}
	var part_kind := String(segment.get("part_kind", "limb_muscle"))
	var node_index := int(segment.get("node_index", segment.get("part_index", -999999)))
	var active_nodes: Dictionary = Dictionary(context.get("active_nodes", {}))
	var independent_damage := part_kind == "torso" or active_nodes.has(node_index)
	var part_name := String(segment.get("name", part_kind.to_upper()))
	segment["runtime_topology"] = true
	segment["independent_damage"] = independent_damage
	if not independent_damage:
		segment["damage_proxy"] = "torso"
		segment["damage_proxy_torso_unit_index"] = int(segment.get("torso_unit_index", 0))
	var runtime_polygon: Array = Array(context.get("runtime_polygon", []))
	if runtime_polygon.size() >= 3:
		segment["shape"] = "polygon"
		segment["polygon"] = runtime_polygon.duplicate(true)
		segment["radius"] = 0.0
	else:
		segment["shape"] = String(segment.get("shape", "capsule"))
		segment["radius"] = maxf(0.006, float(segment.get("radius", 0.04)) * maxf(0.0, float(context.get("body_collider_expand", 1.0))))
	segment["part_index"] = -1 if part_kind == "torso" else int(context.get("attack_index", -1))
	segment["name"] = part_name
	var contact_fields: Dictionary = Dictionary(context.get("contact_fields", {})).duplicate(true)
	if part_kind == "torso":
		contact_fields = torso_contact_fields(segment)
		segment["torso_unit_index"] = int(segment.get("node_index", 0))
	for key in contact_fields.keys():
		segment[key] = contact_fields[key]
	if not segment.has("contact_shape_kind"):
		segment["contact_shape_kind"] = default_contact_shape_kind(part_kind)
	if not segment.has("stiffness_momentum"):
		segment["stiffness_momentum"] = float(context.get("default_stiffness", 1.0))
	if not segment.has("path_stiffness_momentum"):
		segment["path_stiffness_momentum"] = float(context.get("default_path_stiffness", 1.0))
	return segment


func torso_contact_fields(segment: Dictionary) -> Dictionary:
	return {
		"damage_type": "blunt",
		"material_class": String(segment.get("material_class", "body")),
		"contact_damage": 0.4,
		"contact_damage_mult": 0.08,
		"damage_coeff": 1.0,
		"break_coeff": 0.5,
		"contact_shape_kind": "rounded_torso",
	}


func default_contact_shape_kind(part_kind: String) -> String:
	match part_kind:
		"terminal":
			return "rounded_terminal"
		"barrier_tile":
			return "rounded_panel"
	return "rounded_limb"
