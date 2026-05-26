class_name AssemblyBoardRenderer
extends RefCounted

const PartArt = preload("res://scripts/part_art.gd")


static func draw_component(canvas: CanvasItem, center: Vector2, node: Dictionary, color: Color, axis: Vector2, physical_radius: float, pulse: float = 0.0, visual_length_px: float = -1.0, match_preview_profile: bool = false) -> bool:
	var forward := _safe_axis(axis)
	var kind := component_kind(node)
	var display_radius := component_display_radius(node, physical_radius, visual_length_px, true) if match_preview_profile else physical_radius
	var base_color := _component_color(color, node)
	if bool(node.get("runtime_action", false)):
		match String(node.get("runtime_action_state", "")):
			"armor":
				base_color = Color(0.42, 0.84, 1.0, 1.0)
			"active":
				base_color = Color(1.0, 0.38, 0.14, 1.0)
			_:
				base_color = Color(1.0, 1.0, 0.86, 1.0)
	match kind:
		"torso":
			_draw_torso(canvas, center, forward, base_color, display_radius, node, visual_length_px)
		"limb":
			_draw_limb(canvas, center, forward, base_color, display_radius, pulse, visual_length_px, node)
		"terminal":
			_draw_terminal(canvas, center, forward, base_color, display_radius, pulse, visual_length_px, node)
		"barrier":
			_draw_barrier(canvas, center, forward, base_color, display_radius, pulse, visual_length_px, node)
		_:
			_draw_limb(canvas, center, forward, base_color, display_radius, pulse, visual_length_px, node)
	return true


static func draw_runtime_segment(canvas: CanvasItem, segment: Dictionary, center_world: Vector2, body_rotation: float, visual_scale: float, material_color: Color, primary_color: Color) -> bool:
	var local_a := world_to_local(Vector2(segment.get("a", center_world)), center_world, body_rotation, visual_scale)
	var local_b := world_to_local(Vector2(segment.get("b", Vector2(segment.get("a", center_world)))), center_world, body_rotation, visual_scale)
	var axis := local_b - local_a
	if axis.length() < 0.001:
		axis = Vector2.RIGHT
	var part_kind := String(segment.get("part_kind", "limb_muscle"))
	var radius_px := maxf(2.0, float(segment.get("radius", 0.025)) * visual_scale)
	var visual_length := maxf(0.0, local_a.distance_to(local_b))
	var node := segment_to_component_node(segment)
	node["runtime_action"] = bool(segment.get("runtime_action", false))
	node["runtime_action_state"] = String(segment.get("runtime_action_state", ""))
	node["runtime_action_phase"] = String(segment.get("runtime_action_phase", ""))
	node["runtime_action_progress"] = float(segment.get("runtime_action_progress", 0.0))
	var draw_color := material_color
	if part_kind == "torso":
		draw_color = primary_color.lerp(material_color, 0.45).lerp(Color.WHITE, 0.08)
	var center := (local_a + local_b) * 0.5
	return draw_component(canvas, center, node, draw_color, axis, radius_px, 0.0, visual_length, true)


static func runtime_segment_overlay_polygon(segment: Dictionary, center_world: Vector2, body_rotation: float, visual_scale: float) -> PackedVector2Array:
	var local_a := world_to_local(Vector2(segment.get("a", center_world)), center_world, body_rotation, visual_scale)
	var local_b := world_to_local(Vector2(segment.get("b", Vector2(segment.get("a", center_world)))), center_world, body_rotation, visual_scale)
	var axis := local_b - local_a
	if axis.length() < 0.001:
		axis = Vector2.RIGHT
	var radius_px := maxf(2.0, float(segment.get("radius", 0.025)) * visual_scale)
	var visual_length := maxf(0.0, local_a.distance_to(local_b))
	var node := segment_to_component_node(segment)
	var center := (local_a + local_b) * 0.5
	return component_polygon(center, node, axis, radius_px, visual_length, true)


static func draw_runtime_segment_status_overlay(canvas: CanvasItem, segment: Dictionary, center_world: Vector2, body_rotation: float, visual_scale: float, overlay_color: Color, outline_width: float = 3.0) -> bool:
	var polygon := runtime_segment_overlay_polygon(segment, center_world, body_rotation, visual_scale)
	if polygon.size() < 3:
		return false
	var fill_alpha := clampf(overlay_color.a * 0.38, 0.05, 0.22)
	var fill := Color(overlay_color.r, overlay_color.g, overlay_color.b, fill_alpha)
	var outline := Color(overlay_color.r, overlay_color.g, overlay_color.b, clampf(overlay_color.a + 0.26, 0.32, 0.92))
	canvas.draw_colored_polygon(polygon, fill)
	_draw_outline(canvas, polygon, outline, maxf(1.4, outline_width))
	return true


static func draw_part_preview(canvas: CanvasItem, rect: Rect2, slot_key: String, part: Dictionary, selected: bool = false, pulse: float = 0.0) -> bool:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	var preview_rect := rect.grow(-maxf(3.0, minf(rect.size.x, rect.size.y) * 0.04))
	if preview_rect.size.x <= 1.0 or preview_rect.size.y <= 1.0:
		preview_rect = rect
	var center := preview_rect.get_center()
	var slot := slot_key.to_lower()
	var node := part_to_component_node(slot, part)
	var kind := component_kind(node)
	var color := PartArt.material_color_for(PartArt.material_style_for(node), String(node.get("slot", slot_key)))
	if kind == "plugin":
		_draw_plugin_preview(canvas, preview_rect, slot, part, color, selected, pulse)
		return true
	var scale := PartArt.size_scale_for(part)
	var axis := Vector2.RIGHT
	var length := preview_rect.size.x * clampf(0.62 + scale * 0.12, 0.58, 0.9)
	var radius := preview_rect.size.y * clampf(0.14 + scale * 0.035, 0.12, 0.26)
	match kind:
		"torso":
			length = minf(preview_rect.size.x * 0.72, preview_rect.size.y * 1.55) * clampf(scale, 0.74, 1.35)
			radius = minf(preview_rect.size.y * 0.36, length * 0.34)
		"terminal":
			length = preview_rect.size.x * clampf(0.62 + scale * 0.1, 0.58, 0.88)
			radius = preview_rect.size.y * clampf(0.18 + scale * 0.025, 0.16, 0.28)
		"barrier":
			length = preview_rect.size.x * 0.72
			radius = preview_rect.size.y * 0.27
		_:
			length = preview_rect.size.x * clampf(0.64 + scale * 0.09, 0.6, 0.88)
			radius = preview_rect.size.y * clampf(0.18 + scale * 0.02, 0.16, 0.26)
	var glow_color := PartArt.damage_color_for(String(part.get("projectile_damage_type", part.get("damage_type", "blunt"))), slot)
	if selected or pulse > 0.01:
		var glow_alpha := 0.16 + clampf(pulse, 0.0, 1.0) * 0.24
		canvas.draw_circle(center, maxf(length, radius * 2.0) * 0.46, Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha))
	return draw_component(canvas, center, node, color, axis, radius, pulse, length)


static func part_to_component_node(slot_key: String, part: Dictionary) -> Dictionary:
	var slot := slot_key.to_lower()
	var node := part.duplicate(true)
	node["slot"] = slot_key
	node["source_shape"] = String(part.get("shape", ""))
	node["component_name"] = String(part.get("name", part.get("component_name", slot_key.to_upper())))
	node["label"] = String(node.get("component_name", slot_key.to_upper()))
	node["material_visual"] = String(part.get("material_visual", part.get("torso_material", part.get("material_class", ""))))
	node["projectile_damage_type"] = String(part.get("projectile_damage_type", part.get("damage_type", "")))
	node["projectile"] = bool(part.get("projectile", false))
	var material_class := String(part.get("material_class", "")).to_lower()
	var shape := String(part.get("shape", "")).to_lower()
	var terminal_kind := String(part.get("terminal_weapon_kind", "")).to_lower()
	if slot in ["engine", "cooling", "booster", "module", "special", "ammo", "shield_payload", "software", "soul", "code", "ether"]:
		node["slot"] = slot
		node["component_preview_kind"] = "plugin"
		return node
	if slot == "barrier_tile" or slot == "barrier_panel" or bool(part.get("is_barrier_tile", false)):
		node["slot"] = "barrier_tile"
		node["is_barrier_tile"] = true
		node["shape"] = "barrier"
		return node
	if bool(part.get("is_torso", false)) or material_class == "torso" or shape.contains("torso") or shape.contains("core") or slot == "torso":
		node["slot"] = "muscle"
		node["is_torso"] = true
		node["shape"] = "torso"
		node["connection_ends"] = int(part.get("joint_ports", part.get("external_joint_ports", part.get("connection_ends", 4))))
		node["joint_ports"] = int(node.get("connection_ends", 4))
		return node
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or terminal_kind != "" or bool(part.get("projectile", false)) or material_class in ["weapon", "gun", "missile_launcher", "web_gun", "racket"]
	if slot == "terminal_weapon" or terminal_like:
		node["slot"] = "muscle"
		node["terminal_weapon"] = true
		node["connection_ends"] = 1
		node["shape"] = _terminal_shape_name(node)
		if _terminal_supports_mount_side(node):
			node["asymmetric_terminal"] = true
			node["orientation_category"] = String(part.get("orientation_category", "orthogonal_side_mount"))
			node["orientation_basis"] = String(part.get("orientation_basis", "parent_normal"))
			node["mount_side_choices"] = Array(part.get("mount_side_choices", part.get("orientation_choices", ["left", "right"]))).duplicate(true)
			node["orientation_choices"] = Array(node.get("mount_side_choices", ["left", "right"])).duplicate(true)
			node["default_mount_side"] = normalized_mount_side(part)
			node["default_visual_handedness"] = String(node.get("default_mount_side", "right"))
			node["visual_mount_side"] = normalized_mount_side(node)
			node["visual_handedness"] = String(node.get("visual_mount_side", "right"))
		return node
	node["slot"] = "limb_muscle"
	node["connection_ends"] = 2
	var limb_shape := String(part.get("shape", part.get("source_shape", ""))).to_lower()
	node["shape"] = limb_shape if limb_shape != "" else PartArt.limb_visual_family(node)
	node["limb_visual_family"] = PartArt.limb_visual_family(node)
	node["limb_material_visual"] = PartArt.limb_material_visual(node)
	node["limb_role_tags"] = PartArt.limb_role_tags_for(node)
	node["barrier_fit_tags"] = PartArt.limb_barrier_fit_tags_for(node)
	return node


static func world_to_local(point: Vector2, center_world: Vector2, body_rotation: float, visual_scale: float) -> Vector2:
	return (point - center_world).rotated(-body_rotation) * visual_scale


static func segment_to_component_node(segment: Dictionary) -> Dictionary:
	var part_kind := String(segment.get("part_kind", "limb_muscle"))
	var node := {
		"component_name": String(segment.get("name", part_kind.to_upper())),
		"label": String(segment.get("name", part_kind.to_upper())),
		"damage_type": String(segment.get("damage_type", "")),
		"projectile_damage_type": String(segment.get("projectile_damage_type", segment.get("damage_type", ""))),
		"material_class": String(segment.get("material_class", "")),
		"material_visual": String(segment.get("material_visual", segment.get("material_class", ""))),
		"projectile": bool(segment.get("projectile", false)),
		"gun_kind": String(segment.get("gun_kind", "")),
		"ammo_kind": String(segment.get("ammo_kind", "")),
		"projectile_style": String(segment.get("projectile_style", "")),
		"projectile_behavior": String(segment.get("projectile_behavior", "")),
		"radius": float(segment.get("radius", 0.025)),
		"component_radius": float(segment.get("radius", 0.025)),
		"source_shape": String(segment.get("source_shape", segment.get("shape", ""))),
		"shape": String(segment.get("shape", "")),
		"weapon_family": String(segment.get("weapon_family", "")),
		"orientation_category": String(segment.get("orientation_category", "")),
		"orientation_basis": String(segment.get("orientation_basis", "")),
		"visual_mount_side": String(segment.get("visual_mount_side", "")),
		"default_mount_side": String(segment.get("default_mount_side", "")),
		"mount_side_choices": Array(segment.get("mount_side_choices", [])),
		"mount_parent_axis_local": segment.get("mount_parent_axis_local", Vector2.ZERO),
		"visual_handedness": String(segment.get("visual_handedness", "")),
		"default_visual_handedness": String(segment.get("default_visual_handedness", "")),
		"asymmetric_terminal": bool(segment.get("asymmetric_terminal", false)),
		"orientation_choices": Array(segment.get("orientation_choices", [])),
		"blunt_shield": bool(segment.get("blunt_shield", false)),
		"blunt_gauntlet": bool(segment.get("blunt_gauntlet", false)),
		"blunt_hammer": bool(segment.get("blunt_hammer", false)),
	}
	match part_kind:
		"torso":
			node["slot"] = "muscle"
			node["is_torso"] = true
			node["shape"] = "torso"
			node["connection_ends"] = int(segment.get("joint_ports", segment.get("port_count", 4)))
			node["joint_ports"] = int(segment.get("joint_ports", segment.get("port_count", 4)))
		"terminal":
			node["slot"] = "muscle"
			node["terminal_weapon"] = true
			node["connection_ends"] = 1
			node["terminal_weapon_kind"] = String(segment.get("terminal_weapon_kind", ""))
			node["shape"] = _terminal_shape_name(node)
			if _terminal_supports_mount_side(node):
				node["asymmetric_terminal"] = true
				if String(node.get("orientation_category", "")) == "":
					node["orientation_category"] = "orthogonal_side_mount"
				if String(node.get("orientation_basis", "")) == "":
					node["orientation_basis"] = "parent_normal"
				if Array(node.get("mount_side_choices", [])).is_empty():
					node["mount_side_choices"] = Array(node.get("orientation_choices", ["left", "right"]))
				if Array(node.get("orientation_choices", [])).is_empty():
					node["orientation_choices"] = ["left", "right"]
				if String(node.get("default_mount_side", "")) == "":
					node["default_mount_side"] = String(node.get("default_visual_handedness", "right"))
				if String(node.get("default_visual_handedness", "")) == "":
					node["default_visual_handedness"] = String(node.get("default_mount_side", "right"))
				node["visual_mount_side"] = normalized_mount_side(node)
				node["visual_handedness"] = String(node.get("visual_mount_side", "right"))
		"barrier_tile":
			node["slot"] = "barrier_tile"
			node["is_barrier_tile"] = true
			node["shape"] = "barrier"
		_:
			node["slot"] = "limb_muscle"
			node["connection_ends"] = 2
			var source_shape := String(node.get("source_shape", ""))
			var collision_shape := String(node.get("shape", "")).to_lower()
			node["shape"] = source_shape if source_shape != "" and not (collision_shape in ["capsule", "polygon", "circle"]) else (collision_shape if collision_shape != "" and not (collision_shape in ["capsule", "polygon", "circle"]) else PartArt.limb_visual_family(node))
			node["limb_visual_family"] = PartArt.limb_visual_family(node)
			node["limb_material_visual"] = PartArt.limb_material_visual(node)
			node["limb_role_tags"] = PartArt.limb_role_tags_for(node)
			node["barrier_fit_tags"] = PartArt.limb_barrier_fit_tags_for(node)
	return node


static func component_kind(node: Dictionary) -> String:
	if String(node.get("component_preview_kind", "")) == "plugin":
		return "plugin"
	var slot_key := String(node.get("slot", "")).to_lower()
	var material_class := String(node.get("material_class", "")).to_lower()
	var shape := String(node.get("shape", "")).to_lower()
	var label := String(node.get("component_name", node.get("label", ""))).to_lower()
	if bool(node.get("is_torso", false)) or material_class == "torso" or shape.contains("torso") or shape.contains("core") or label.contains("core"):
		return "torso"
	if bool(node.get("is_barrier_tile", false)) or slot_key == "barrier_tile":
		return "barrier"
	if bool(node.get("terminal_weapon", false)) or bool(node.get("projectile", false)) or int(node.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "gun", "missile_launcher", "web_gun", "racket"]:
		return "terminal"
	return "limb"


static func component_display_radius(node: Dictionary, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> float:
	var kind := component_kind(node)
	var length := _component_profile_length(kind, physical_radius, visual_length_px, pixel_minimums)
	var min_radius := 0.001
	if pixel_minimums:
		match kind:
			"torso":
				min_radius = 3.0
			"terminal":
				min_radius = 4.0
			"barrier":
				min_radius = 7.0 / 0.9
			_:
				min_radius = 5.0 / 0.76
	match kind:
		"torso":
			# Matches the card silhouette used by the catalog: front width ~= 36%
			# of length, rear width ~= 72% of length.
			return maxf(length * 0.30, min_radius)
		"terminal":
			return maxf(length * 0.135, min_radius)
		"barrier":
			return maxf(length * 0.18, min_radius)
		_:
			# Limb cards are intentionally slimmer than their metric radius can imply.
			return maxf(length * 0.145, min_radius)


static func component_display_metrics(node: Dictionary, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> Dictionary:
	var kind := component_kind(node)
	var display_radius := component_display_radius(node, physical_radius, visual_length_px, pixel_minimums)
	var length := _component_profile_length(kind, physical_radius, visual_length_px, pixel_minimums)
	var min_width := 6.0 if pixel_minimums else 0.001
	match kind:
		"torso":
			var front_width := maxf(length * 0.36, maxf(display_radius * 1.2, min_width))
			var rear_width := maxf(length * 0.72, maxf(display_radius * 2.4, front_width + (2.0 if pixel_minimums else 0.001)))
			return {
				"kind": kind,
				"length": length,
				"display_radius": display_radius,
				"front_width": front_width,
				"rear_width": rear_width,
				"root_extent": length * 0.5,
				"tip_extent": length * 0.5,
			}
		"terminal":
			return {
				"kind": kind,
				"length": length,
				"display_radius": display_radius,
				"body_width": display_radius,
				"root_extent": length * 0.5,
				"tip_extent": length * 0.5,
			}
		"barrier":
			return {
				"kind": kind,
				"length": length,
				"display_radius": display_radius,
				"body_width": maxf(display_radius * 0.9, 7.0 if pixel_minimums else 0.001),
				"root_extent": length * 0.5,
				"tip_extent": length * 0.5,
			}
		_:
			return {
				"kind": kind,
				"length": length,
				"display_radius": display_radius,
				"body_width": maxf(display_radius * 0.76, 5.0 if pixel_minimums else 0.001),
				"root_extent": length * 0.5,
				"tip_extent": length * 0.5,
			}


static func torso_port_positions(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> Array:
	var metrics := component_display_metrics(node, physical_radius, visual_length_px, pixel_minimums)
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var torso_scale := maxf(0.001, PartArt.TORSO_GEOMETRY_SCALE)
	var port_count := PartArt.torso_saddle_port_count(node)
	var positions: Array = []
	for raw_local in PartArt.torso_hull_port_local_offsets(
		node,
		port_count,
		float(metrics.get("length", 0.0)) / torso_scale,
		float(metrics.get("front_width", 0.0)) / torso_scale,
		float(metrics.get("rear_width", 0.0)) / torso_scale
	):
		var local: Vector2 = raw_local
		positions.append(center + forward * local.x + right * local.y)
	return positions


static func component_connection_anchor(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, toward: Vector2, socket_id: String = "", visual_length_px: float = -1.0, pixel_minimums: bool = true) -> Vector2:
	var forward := _safe_axis(axis)
	var kind := component_kind(node)
	var id := socket_id.to_lower()
	if kind == "torso" and id.begins_with("torso_port:"):
		var ports := torso_port_positions(center, node, forward, physical_radius, visual_length_px, pixel_minimums)
		if ports.size() > 0:
			return ports[clampi(int(id.get_slice(":", 1)), 0, ports.size() - 1)]
	var direction := toward - center
	if direction.length() < 0.01:
		direction = forward
	var side := 1.0 if direction.dot(forward) >= 0.0 else -1.0
	if id in ["root_joint", "handle", "end:a", "side:-1", "side:a"]:
		side = -1.0
	elif id in ["distal", "end:b", "side:1", "side:b"]:
		side = 1.0
	var metrics := component_display_metrics(node, physical_radius, visual_length_px, pixel_minimums)
	var extent := float(metrics.get("tip_extent" if side >= 0.0 else "root_extent", float(metrics.get("length", 0.0)) * 0.5))
	return center + forward * extent * side


static func _component_profile_length(kind: String, physical_radius: float, visual_length_px: float, pixel_minimums: bool) -> float:
	var min_length := 0.001
	if pixel_minimums:
		match kind:
			"torso":
				min_length = 10.0
			"terminal":
				min_length = 10.0
			"barrier":
				min_length = 10.0
			_:
				min_length = 8.0
	if visual_length_px > 0.0:
		return maxf(visual_length_px, min_length)
	match kind:
		"torso":
			return maxf(physical_radius * 1.94, min_length)
		"terminal", "barrier":
			return maxf(physical_radius * 2.0, min_length)
		_:
			return maxf(physical_radius * 1.9, min_length)


static func component_polygon(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var kind := component_kind(node)
	var metrics := component_display_metrics(node, physical_radius, visual_length_px, pixel_minimums)
	var display_radius := float(metrics.get("display_radius", component_display_radius(node, physical_radius, visual_length_px, pixel_minimums)))
	match kind:
		"torso":
			return torso_hull_polygon(center, forward, node, float(metrics.get("length", 0.0)), float(metrics.get("front_width", 0.0)), float(metrics.get("rear_width", 0.0)))
		"terminal":
			return terminal_polygon(center, node, forward, display_radius, visual_length_px, pixel_minimums)
		"barrier":
			return capsule_polygon(center, forward, float(metrics.get("length", 0.0)), float(metrics.get("body_width", display_radius)), 6)
		_:
			return limb_polygon(center, node, forward, physical_radius, visual_length_px, pixel_minimums)


static func saddle_polygon(center: Vector2, axis: Vector2, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var points := PackedVector2Array()
	var half_length := maxf(0.01, length) * 0.5
	var front_half := maxf(0.01, front_width) * 0.5
	var rear_half := maxf(front_half + 0.01, rear_width) * 0.5
	var steps := 28
	for i in range(steps):
		var theta := TAU * float(i) / float(steps)
		var cx := cos(theta)
		var sx := sin(theta)
		var x := cx * half_length
		var t := clampf((x + half_length) / maxf(0.001, length), 0.0, 1.0)
		var width := lerpf(rear_half, front_half, t)
		var local := Vector2(x, sx * width)
		points.append(center + forward * local.x + right * local.y)
	return points


static func torso_hull_polygon(center: Vector2, axis: Vector2, node: Dictionary, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var torso_scale := maxf(0.001, PartArt.TORSO_GEOMETRY_SCALE)
	var points := PackedVector2Array()
	for raw_local in PartArt.torso_hull_local_points(node, length / torso_scale, front_width / torso_scale, rear_width / torso_scale):
		var local: Vector2 = raw_local
		points.append(center + forward * local.x + right * local.y)
	return points


static func capsule_polygon(center: Vector2, axis: Vector2, length: float, width: float, arc_steps: int = 6) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var half_length := maxf(0.001, length) * 0.5
	var half_width := maxf(0.001, width) * 0.5
	var shaft_half := maxf(0.0, half_length - half_width)
	var points := PackedVector2Array()
	var steps := maxi(3, arc_steps)
	for i in range(steps + 1):
		var theta := -PI * 0.5 + PI * float(i) / float(steps)
		var local := Vector2(shaft_half + cos(theta) * half_width, sin(theta) * half_width)
		points.append(center + forward * local.x + right * local.y)
	for i in range(steps + 1):
		var theta := PI * 0.5 + PI * float(i) / float(steps)
		var local := Vector2(-shaft_half + cos(theta) * half_width, sin(theta) * half_width)
		points.append(center + forward * local.x + right * local.y)
	return points


static func limb_polygon(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var metrics := component_display_metrics(node, physical_radius, visual_length_px, pixel_minimums)
	var length := maxf(float(metrics.get("length", visual_length_px if visual_length_px > 0.0 else physical_radius * 1.9)), 8.0 if pixel_minimums else 0.001)
	var body_width := maxf(float(metrics.get("body_width", maxf(0.001, physical_radius * 0.76))), 5.0 if pixel_minimums else 0.001)
	var half_width := body_width * 0.5
	match PartArt.limb_visual_family(node):
		"forearm_myomer":
			return _limb_local_polygon(center, forward, right, [
				Vector2(-length * 0.50, -half_width * 0.72),
				Vector2(-length * 0.36, -half_width * 1.16),
				Vector2(-length * 0.06, -half_width * 0.96),
				Vector2(length * 0.25, -half_width * 1.36),
				Vector2(length * 0.44, -half_width * 0.84),
				Vector2(length * 0.50, 0.0),
				Vector2(length * 0.44, half_width * 0.84),
				Vector2(length * 0.25, half_width * 1.36),
				Vector2(-length * 0.06, half_width * 0.96),
				Vector2(-length * 0.36, half_width * 1.16),
				Vector2(-length * 0.50, half_width * 0.72),
			])
		"thigh_myomer":
			return _limb_local_polygon(center, forward, right, [
				Vector2(-length * 0.50, -half_width * 0.90),
				Vector2(-length * 0.34, -half_width * 1.50),
				Vector2(0.0, -half_width * 1.82),
				Vector2(length * 0.34, -half_width * 1.42),
				Vector2(length * 0.50, -half_width * 0.86),
				Vector2(length * 0.50, half_width * 0.86),
				Vector2(length * 0.34, half_width * 1.42),
				Vector2(0.0, half_width * 1.82),
				Vector2(-length * 0.34, half_width * 1.50),
				Vector2(-length * 0.50, half_width * 0.90),
			])
		"flex_tendon":
			return _limb_wave_polygon(center, forward, right, length, half_width * 0.92, 9, 0.24)
		"chain_muscle":
			return _limb_chain_outline(center, forward, right, length, half_width * 1.34, 7, false)
		"tentacle":
			return _limb_wave_polygon(center, forward, right, length, half_width * 1.12, 10, 0.36)
		"steel_sinew_beam":
			return _limb_ibeam_polygon(center, forward, right, length, half_width * 1.62)
		"ceramic_linear_strut":
			return _limb_linear_strut_polygon(center, forward, right, length, half_width * 1.28)
		"colossus_girder_muscle":
			return _limb_girder_polygon(center, forward, right, length, half_width * 1.90)
		"barrier_strut":
			return _limb_barrier_strut_polygon(center, forward, right, length, half_width * 1.68)
		"fur_sleeve":
			return capsule_polygon(center, forward, length, half_width * 1.78, 10)
		_:
			return capsule_polygon(center, forward, length, body_width, 6)


static func limb_visual_detail_tags(node: Dictionary) -> PackedStringArray:
	var tags := PackedStringArray()
	for raw_tag in PartArt.limb_role_tags_for(node):
		tags.append(String(raw_tag))
	for raw_tag in PartArt.limb_barrier_fit_tags_for(node):
		if not tags.has(String(raw_tag)):
			tags.append(String(raw_tag))
	match PartArt.limb_visual_family(node):
		"forearm_myomer":
			tags.append_array(PackedStringArray(["paired_myomer", "wrist_cuff", "light_limb"]))
		"thigh_myomer":
			tags.append_array(PackedStringArray(["thick_myomer", "load_belly", "standard_limb"]))
		"flex_tendon":
			tags.append_array(PackedStringArray(["fiber_bundle", "flex_tendon", "wide_angle"]))
		"chain_muscle":
			tags.append_array(PackedStringArray(["chain_segments", "linked_limb", "weighted_return"]))
		"tentacle":
			tags.append_array(PackedStringArray(["soft_curve", "organic_segments", "wide_angle"]))
		"steel_sinew_beam":
			tags.append_array(PackedStringArray(["i_beam", "rivet_line", "load_bearing"]))
		"ceramic_linear_strut":
			tags.append_array(PackedStringArray(["ceramic_panels", "linear_rail", "telescopic_sleeve"]))
		"colossus_girder_muscle":
			tags.append_array(PackedStringArray(["truss_girder", "giant_muscle_wrap", "anchor_mount"]))
		"barrier_strut":
			tags.append_array(PackedStringArray(["hard_barrier_beam", "maze_fit", "panel_mount"]))
		"fur_sleeve":
			tags.append_array(PackedStringArray(["padded_sleeve", "impact_fur", "shove_absorb"]))
		_:
			tags.append("fallback_two_end_muscle")
	match PartArt.limb_material_visual(node):
		"metal", "chain":
			tags.append_array(PackedStringArray(["metal_rivets", "hard_edges"]))
		"ceramic":
			tags.append_array(PackedStringArray(["ceramic_plate_lines", "clean_hard_panels"]))
		"wood":
			tags.append_array(PackedStringArray(["wood_grain", "timber_support"]))
		"flex":
			tags.append_array(PackedStringArray(["fiber_strands", "soft_bundle"]))
		"hardlight":
			tags.append_array(PackedStringArray(["barrier_glow_edges", "hardlight_plate"]))
		"fur":
			tags.append_array(PackedStringArray(["fur_edge", "padded_texture"]))
	return tags


static func _limb_local_polygon(center: Vector2, forward: Vector2, right: Vector2, points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for raw_point in points:
		var p: Vector2 = raw_point
		polygon.append(center + forward * p.x + right * p.y)
	return polygon


static func _limb_wave_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float, steps: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(5, steps)
	for i in range(count + 1):
		var t := float(i) / float(count)
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var width := half_width * lerpf(0.72, 1.0, sin(t * PI))
		var wave := sin(t * TAU * 2.0) * half_width * amplitude
		points.append(center + forward * x + right * (width + wave))
	for i in range(count, -1, -1):
		var t := float(i) / float(count)
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var width := half_width * lerpf(0.72, 1.0, sin(t * PI))
		var wave := sin(t * TAU * 2.0 + PI * 0.6) * half_width * amplitude
		points.append(center + forward * x - right * (width + wave))
	return points


static func _limb_chain_outline(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float, segments: int, tapered: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(5, segments)
	for i in range(count + 1):
		var t := float(i) / float(count)
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var tooth := 0.72 + (0.26 if i % 2 == 0 else -0.08)
		var taper := lerpf(1.0, 0.58, t) if tapered else 1.0
		points.append(center + forward * x + right * half_width * tooth * taper)
	for i in range(count, -1, -1):
		var t := float(i) / float(count)
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var tooth := 0.72 + (0.26 if i % 2 == 0 else -0.08)
		var taper := lerpf(1.0, 0.58, t) if tapered else 1.0
		points.append(center + forward * x - right * half_width * tooth * taper)
	return points


static func _limb_ibeam_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float) -> PackedVector2Array:
	var flange := half_width
	var web := half_width * 0.34
	return _limb_local_polygon(center, forward, right, [
		Vector2(-length * 0.50, -flange),
		Vector2(-length * 0.36, -flange),
		Vector2(-length * 0.32, -web),
		Vector2(length * 0.32, -web),
		Vector2(length * 0.36, -flange),
		Vector2(length * 0.50, -flange),
		Vector2(length * 0.50, flange),
		Vector2(length * 0.36, flange),
		Vector2(length * 0.32, web),
		Vector2(-length * 0.32, web),
		Vector2(-length * 0.36, flange),
		Vector2(-length * 0.50, flange),
	])


static func _limb_linear_strut_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float) -> PackedVector2Array:
	return _limb_local_polygon(center, forward, right, [
		Vector2(-length * 0.50, -half_width * 0.54),
		Vector2(-length * 0.22, -half_width * 0.78),
		Vector2(length * 0.05, -half_width * 0.48),
		Vector2(length * 0.38, -half_width * 0.48),
		Vector2(length * 0.50, -half_width * 0.30),
		Vector2(length * 0.50, half_width * 0.30),
		Vector2(length * 0.38, half_width * 0.48),
		Vector2(length * 0.05, half_width * 0.48),
		Vector2(-length * 0.22, half_width * 0.78),
		Vector2(-length * 0.50, half_width * 0.54),
	])


static func _limb_girder_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float) -> PackedVector2Array:
	return _limb_local_polygon(center, forward, right, [
		Vector2(-length * 0.50, -half_width * 0.72),
		Vector2(-length * 0.36, -half_width * 1.02),
		Vector2(-length * 0.12, -half_width * 0.86),
		Vector2(length * 0.12, -half_width * 1.08),
		Vector2(length * 0.36, -half_width * 0.92),
		Vector2(length * 0.50, -half_width * 0.62),
		Vector2(length * 0.50, half_width * 0.62),
		Vector2(length * 0.36, half_width * 0.92),
		Vector2(length * 0.12, half_width * 1.08),
		Vector2(-length * 0.12, half_width * 0.86),
		Vector2(-length * 0.36, half_width * 1.02),
		Vector2(-length * 0.50, half_width * 0.72),
	])


static func _limb_barrier_strut_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, half_width: float) -> PackedVector2Array:
	return _limb_local_polygon(center, forward, right, [
		Vector2(-length * 0.50, -half_width * 0.86),
		Vector2(length * 0.46, -half_width * 0.86),
		Vector2(length * 0.50, -half_width * 0.62),
		Vector2(length * 0.50, half_width * 0.62),
		Vector2(length * 0.46, half_width * 0.86),
		Vector2(-length * 0.50, half_width * 0.86),
	])


static func terminal_polygon(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var length := maxf(visual_length_px if visual_length_px > 0.0 else physical_radius * 2.0, 10.0 if pixel_minimums else 0.001)
	var radius := maxf(physical_radius, 4.0 if pixel_minimums else 0.001)
	var root := center - forward * length * 0.5
	var tip := center + forward * length * 0.5
	var damage_type := String(node.get("damage_type", "")).to_lower()
	var family := terminal_shape_family(node)
	match family:
		"sniper":
			return _terminal_sniper_polygon(center, forward, right, length, radius)
		"rifle":
			return _terminal_rifle_polygon(center, forward, right, length, radius)
		"laser_gun":
			return _terminal_laser_gun_polygon(center, forward, right, length, radius)
		"sprayer":
			return _terminal_sprayer_polygon(center, forward, right, length, radius)
		"grenade_launcher", "mortar", "cannon":
			return _terminal_launcher_polygon(center, forward, right, length, radius)
		"missile_launcher":
			return _terminal_missile_launcher_polygon(center, forward, right, length, radius)
		"web_gun":
			return _terminal_web_gun_polygon(center, forward, right, length, radius)
	if family == "gun":
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.82, radius * 0.36, 16)
	if family == "scythe":
		var mount_forward := terminal_visual_forward(node, forward)
		var mount_right := Vector2(-mount_forward.y, mount_forward.x) * terminal_mount_side_sign(node)
		return _terminal_scythe_polygon(center, mount_forward, mount_right, length, radius)
	if family == "saber":
		return _terminal_saber_polygon(center, forward, right, length, radius)
	if family == "shield":
		return _terminal_shield_polygon(center, forward, right, length, radius)
	if family == "drill":
		return _terminal_drill_polygon(center, forward, right, length, radius)
	if family == "gauntlet":
		return _terminal_gauntlet_polygon(center, forward, right, length, radius)
	match family:
		"katana":
			return _terminal_katana_polygon(center, forward, right, length, radius)
		"greatsword":
			return _terminal_greatsword_polygon(center, forward, right, length, radius)
		"hammer":
			return _terminal_hammer_polygon(center, forward, right, length, radius)
		"lance":
			return _terminal_lance_polygon(center, forward, right, length, radius)
		"rapier":
			return _terminal_rapier_polygon(center, forward, right, length, radius)
		"claw":
			return _terminal_claw_polygon(center, forward, right, length, radius)
		"racket":
			return _terminal_racket_polygon(center, forward, right, length, radius)
		"chain":
			return _terminal_chain_polygon(center, forward, right, length, radius)
	if family == "generic_blade" or damage_type == "tear":
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.62, radius * 0.2, 18, 1.35)
	if family == "generic_pierce" or damage_type == "pierce":
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.55, radius * 0.08, 16, 0.9)
	return capsule_polygon(center, forward, length, radius * 1.7, 6)


static func normalized_visual_handedness(node: Dictionary) -> String:
	var value := String(node.get("visual_handedness", node.get("default_visual_handedness", node.get("visual_mount_side", node.get("default_mount_side", "right"))))).to_lower()
	return "left" if value == "left" else "right"


static func normalized_mount_side(node: Dictionary) -> String:
	var mount_side := String(node.get("visual_mount_side", "")).strip_edges().to_lower()
	var handedness := String(node.get("visual_handedness", "")).strip_edges().to_lower()
	var default_side := String(node.get("default_mount_side", node.get("default_visual_handedness", "right"))).strip_edges().to_lower()
	default_side = "left" if default_side == "left" else "right"
	if mount_side != "":
		return "left" if mount_side == "left" else "right"
	if handedness != "":
		return "left" if handedness == "left" else "right"
	return "left" if default_side == "left" else "right"


static func terminal_handedness_sign(node: Dictionary) -> float:
	return -1.0 if normalized_visual_handedness(node) == "left" else 1.0


static func terminal_mount_side_sign(node: Dictionary) -> float:
	return -1.0 if normalized_mount_side(node) == "left" else 1.0


static func terminal_visual_forward(node: Dictionary, fallback_axis: Vector2) -> Vector2:
	var fallback := _safe_axis(fallback_axis)
	if not _terminal_uses_orthogonal_side_mount(node):
		return fallback
	var raw_axis = node.get("mount_parent_axis_local", Vector2.ZERO)
	if raw_axis is Vector2 and Vector2(raw_axis).length() > 0.0001:
		return Vector2(raw_axis).normalized()
	return fallback


static func _terminal_supports_mount_side(node: Dictionary) -> bool:
	if String(node.get("orientation_category", "")).to_lower() == "orthogonal_side_mount":
		return true
	return terminal_shape_family(node) == "scythe"


static func _terminal_supports_visual_handedness(node: Dictionary) -> bool:
	return _terminal_supports_mount_side(node)


static func _terminal_uses_orthogonal_side_mount(node: Dictionary) -> bool:
	return _terminal_supports_mount_side(node) and String(node.get("orientation_basis", "parent_normal")).to_lower() == "parent_normal"


static func terminal_shape_family(node: Dictionary) -> String:
	var material_class := String(node.get("material_class", "")).to_lower()
	var family := String(node.get("weapon_family", "")).to_lower()
	var gun_kind := String(node.get("gun_kind", "")).to_lower()
	var projectile_style := String(node.get("projectile_style", "")).to_lower()
	var projectile_behavior := String(node.get("projectile_behavior", "")).to_lower()
	var damage_type := String(node.get("projectile_damage_type", node.get("damage_type", ""))).to_lower()
	var source_shape := String(node.get("source_shape", node.get("shape", ""))).to_lower()
	var shape := String(node.get("shape", "")).to_lower()
	var name := String(node.get("component_name", node.get("label", ""))).to_lower()
	var key := "%s %s %s %s %s %s %s %s %s" % [family, gun_kind, projectile_style, projectile_behavior, damage_type, material_class, source_shape, shape, name]
	if bool(node.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"]:
		if material_class == "web_gun" or gun_kind == "web_gun" or key.contains("web"):
			return "web_gun"
		if material_class == "missile_launcher" or gun_kind == "missile_launcher" or projectile_style == "missile" or key.contains("missile"):
			return "missile_launcher"
		if gun_kind == "laser_gun" or projectile_style == "beam" or key.contains("laser"):
			return "laser_gun"
		if gun_kind == "sprayer" or key.contains("sprayer") or key.contains("siphon") or key.contains("nozzle"):
			return "sprayer"
		if gun_kind == "grenade_launcher" or key.contains("grenade"):
			return "grenade_launcher"
		if key.contains("mortar"):
			return "mortar"
		if key.contains("cannon") or key.contains("turret"):
			return "cannon"
		if projectile_style == "spray" or damage_type == "chemical" or key.contains("spray") or key.contains("caustic") or key.contains("chemical"):
			return "sprayer"
		if gun_kind == "sniper" or projectile_style == "true_bullet" or key.contains("sniper") or key.contains("rail"):
			return "sniper"
		if gun_kind == "rifle" or projectile_style == "bullet_hell" or key.contains("rifle"):
			return "rifle"
		return "gun"
	if bool(node.get("blunt_shield", false)) or family == "shield" or key.contains("shield") or key.contains("buckler"):
		return "shield"
	if bool(node.get("blunt_gauntlet", false)) or family == "gauntlet" or key.contains("gauntlet") or key.contains("glove") or key.contains("fist"):
		return "gauntlet"
	if family in ["saber", "sabre"] or key.contains("saber") or key.contains("sabre"):
		return "saber"
	if family == "scythe" or key.contains("scythe") or key.contains("crescent") or key.contains("hook"):
		return "scythe"
	if family == "drill" or key.contains("drill") or key.contains("auger") or key.contains("borer"):
		return "drill"
	if family == "katana" or key.contains("katana") or key.contains("wakizashi") or key.contains("odachi") or key.contains("saber"):
		return "katana"
	if family == "greatsword" or key.contains("greatsword") or key.contains("great_sword") or key.contains("buster"):
		return "greatsword"
	if bool(node.get("blunt_hammer", false)) or family == "hammer" or key.contains("hammer") or key.contains("maul") or key.contains("mace") or key.contains("jack"):
		return "hammer"
	if family == "rapier" or key.contains("rapier") or key.contains("foil") or key.contains("epee") or key.contains("stiletto"):
		return "rapier"
	if family == "lance" or key.contains("lance") or key.contains("spear") or key.contains("pike") or key.contains("harpoon") or key.contains("needle") or key.contains("spike"):
		return "lance"
	if family == "claw" or key.contains("claw") or key.contains("jaw") or key.contains("talon") or key.contains("paw") or key.contains("hoof"):
		return "claw"
	if family == "racket" or material_class == "racket" or key.contains("racket") or key.contains("rake"):
		return "racket"
	if family == "chain" or key.contains("chain") or key.contains("whip") or key.contains("antenna"):
		return "chain"
	if damage_type == "tear" or family in ["katana", "greatsword", "blade"]:
		return "generic_blade"
	if damage_type == "pierce" or family in ["lance", "rapier", "pierce"]:
		return "generic_pierce"
	if damage_type == "blunt" or family in ["hammer", "blunt"] or bool(node.get("blunt_hammer", false)):
		return "generic_blunt"
	return "generic_terminal"


static func terminal_visual_detail_tags(node: Dictionary) -> PackedStringArray:
	match terminal_shape_family(node):
		"scythe":
			return PackedStringArray(["long_handle", "right_angle_scythe", "crescent_hook_blade", "inner_cutting_edge"])
		"saber":
			return PackedStringArray(["curved_saber_edge", "single_edge_blade", "old_scythe_art_reassigned"])
		"shield":
			return PackedStringArray(["thick_arc_shield", "top_down_curved_plate", "inner_grip_ridge"])
		"drill":
			return PackedStringArray(["powered_drill_body", "chuck_collar", "animated_spiral_texture", "bit_ridges"])
		"gauntlet":
			return PackedStringArray(["piston_rod_handle", "wrist_cuff", "finger_knuckles", "iron_fist_front"])
		"katana":
			return PackedStringArray(["single_edge_curve", "short_guard", "wrapped_grip"])
		"greatsword":
			return PackedStringArray(["broad_double_edge", "cross_guard", "heavy_tip"])
		"hammer":
			return PackedStringArray(["long_handle", "hammer_head", "counterweight"])
		"lance":
			return PackedStringArray(["long_shaft", "spear_tip", "barbed_point"])
		"rapier":
			return PackedStringArray(["needle_blade", "cup_guard", "thin_thrust_line"])
		"claw":
			return PackedStringArray(["paired_claws", "hinge_palm", "hook_tips"])
		"racket":
			return PackedStringArray(["racket_frame", "inner_mesh", "long_grip"])
		"chain":
			return PackedStringArray(["chain_links", "flex_segments", "weighted_tip"])
		"sniper":
			return PackedStringArray(["long_barrel", "scope", "stock"])
		"rifle":
			return PackedStringArray(["rifle_barrel", "magazine", "stock"])
		"laser_gun":
			return PackedStringArray(["prism_lens", "focus_coils", "slim_emitter"])
		"sprayer":
			return PackedStringArray(["fluid_tank", "wide_nozzle", "hose_line"])
		"grenade_launcher", "mortar", "cannon":
			return PackedStringArray(["thick_barrel", "breech_block", "muzzle_ring"])
		"missile_launcher":
			return PackedStringArray(["missile_tubes", "rack_body", "nose_caps"])
		"web_gun":
			return PackedStringArray(["spool_body", "anchor_muzzle", "tether_line"])
		_:
			return PackedStringArray()


static func terminal_drill_spiral_offset(node: Dictionary) -> float:
	if not bool(node.get("runtime_action", false)):
		return 0.0
	return fposmod(float(node.get("runtime_action_progress", 0.0)) * 0.33, 1.0)


static func _terminal_local_polygon(center: Vector2, forward: Vector2, right: Vector2, points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for raw_point in points:
		var p: Vector2 = raw_point
		polygon.append(center + forward * p.x + right * p.y)
	return polygon


static func _terminal_scythe_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var handle_root := -length * 0.50
	var handle_tip := length * 0.16
	var blade_base := handle_tip
	var hook_tip := length * 0.38
	return _terminal_local_polygon(center, forward, right, [
		Vector2(handle_root, -radius * 0.18),
		Vector2(handle_tip, -radius * 0.18),
		Vector2(handle_tip + length * 0.035, radius * 0.48),
		Vector2(blade_base + length * 0.11, radius * 1.06),
		Vector2(blade_base + length * 0.26, radius * 1.42),
		Vector2(hook_tip, radius * 1.18),
		Vector2(blade_base + length * 0.32, radius * 0.72),
		Vector2(blade_base + length * 0.17, radius * 0.46),
		Vector2(handle_tip + length * 0.055, radius * 0.18),
		Vector2(handle_tip, radius * 0.18),
		Vector2(handle_root, radius * 0.18),
	])


static func _terminal_saber_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var guard := -length * 0.28
	var belly := length * 0.12
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.22),
		Vector2(guard, -radius * 0.28),
		Vector2(belly, -radius * 0.34),
		Vector2(tip - length * 0.08, -radius * 0.16),
		Vector2(tip, radius * 0.02),
		Vector2(tip - length * 0.10, radius * 0.34),
		Vector2(belly, radius * 0.72),
		Vector2(guard, radius * 0.48),
		Vector2(root, radius * 0.22),
	])


static func _terminal_shield_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var shoulder := -length * 0.30
	var belly := length * 0.04
	var face := length * 0.34
	var nose := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.42),
		Vector2(shoulder, -radius * 0.88),
		Vector2(belly, -radius * 1.14),
		Vector2(face, -radius * 1.04),
		Vector2(nose, -radius * 0.62),
		Vector2(nose, radius * 0.62),
		Vector2(face, radius * 1.04),
		Vector2(belly, radius * 1.14),
		Vector2(shoulder, radius * 0.88),
		Vector2(root, radius * 0.42),
	])


static func _terminal_drill_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var motor := -length * 0.30
	var chuck := -length * 0.06
	var bit := length * 0.34
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.76),
		Vector2(motor, -radius * 0.90),
		Vector2(chuck, -radius * 0.52),
		Vector2(bit, -radius * 0.18),
		Vector2(tip, 0.0),
		Vector2(bit, radius * 0.18),
		Vector2(chuck, radius * 0.52),
		Vector2(motor, radius * 0.90),
		Vector2(root, radius * 0.76),
	])


static func _terminal_gauntlet_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var wrist := -length * 0.50
	var rod_end := -length * 0.22
	var palm := length * 0.02
	var knuckle := length * 0.30
	var front := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(wrist, -radius * 0.20),
		Vector2(rod_end, -radius * 0.22),
		Vector2(rod_end + length * 0.06, -radius * 0.56),
		Vector2(palm, -radius * 1.02),
		Vector2(knuckle, -radius * 1.20),
		Vector2(front, -radius * 0.88),
		Vector2(front, radius * 0.88),
		Vector2(knuckle, radius * 1.20),
		Vector2(palm, radius * 1.02),
		Vector2(rod_end + length * 0.06, radius * 0.56),
		Vector2(rod_end, radius * 0.22),
		Vector2(wrist, radius * 0.20),
	])


static func _terminal_katana_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var guard := -length * 0.33
	var belly := length * 0.08
	var shoulder := length * 0.34
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.16),
		Vector2(guard, -radius * 0.18),
		Vector2(belly, -radius * 0.28),
		Vector2(shoulder, -radius * 0.20),
		Vector2(tip, radius * 0.02),
		Vector2(shoulder, radius * 0.42),
		Vector2(belly, radius * 0.54),
		Vector2(guard, radius * 0.24),
		Vector2(root, radius * 0.16),
	])


static func _terminal_greatsword_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var pommel := -length * 0.50
	var guard := -length * 0.30
	var blade_root := -length * 0.22
	var shoulder := length * 0.34
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(pommel, -radius * 0.22),
		Vector2(guard, -radius * 0.24),
		Vector2(guard - length * 0.02, -radius * 0.82),
		Vector2(guard + length * 0.06, -radius * 0.82),
		Vector2(blade_root, -radius * 0.58),
		Vector2(shoulder, -radius * 0.42),
		Vector2(tip, 0.0),
		Vector2(shoulder, radius * 0.42),
		Vector2(blade_root, radius * 0.58),
		Vector2(guard + length * 0.06, radius * 0.82),
		Vector2(guard - length * 0.02, radius * 0.82),
		Vector2(guard, radius * 0.24),
		Vector2(pommel, radius * 0.22),
	])


static func _terminal_hammer_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var grip := -length * 0.50
	var neck := length * 0.16
	var head_center := length * 0.32
	var head_front := length * 0.50
	var head_back := length * 0.14
	return _terminal_local_polygon(center, forward, right, [
		Vector2(grip, -radius * 0.24),
		Vector2(neck, -radius * 0.22),
		Vector2(head_back, -radius * 1.10),
		Vector2(head_front, -radius * 1.10),
		Vector2(head_front, radius * 1.10),
		Vector2(head_back, radius * 1.10),
		Vector2(neck, radius * 0.22),
		Vector2(grip, radius * 0.24),
		Vector2(grip - length * 0.02, 0.0),
		Vector2(head_center, -radius * 0.16),
		Vector2(head_front + length * 0.02, 0.0),
		Vector2(head_center, radius * 0.16),
	])


static func _terminal_lance_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var butt := -length * 0.50
	var shaft_end := length * 0.22
	var head := length * 0.38
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(butt, -radius * 0.16),
		Vector2(shaft_end, -radius * 0.16),
		Vector2(head, -radius * 0.46),
		Vector2(head + length * 0.03, -radius * 0.18),
		Vector2(tip, 0.0),
		Vector2(head + length * 0.03, radius * 0.18),
		Vector2(head, radius * 0.46),
		Vector2(shaft_end, radius * 0.16),
		Vector2(butt, radius * 0.16),
	])


static func _terminal_rapier_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var pommel := -length * 0.50
	var guard := -length * 0.28
	var blade_root := -length * 0.18
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(pommel, -radius * 0.14),
		Vector2(guard, -radius * 0.16),
		Vector2(guard, -radius * 0.70),
		Vector2(blade_root, -radius * 0.18),
		Vector2(tip, 0.0),
		Vector2(blade_root, radius * 0.18),
		Vector2(guard, radius * 0.70),
		Vector2(guard, radius * 0.16),
		Vector2(pommel, radius * 0.14),
	])


static func _terminal_claw_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var wrist := -length * 0.50
	var palm := -length * 0.08
	var tine := length * 0.26
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(wrist, -radius * 0.38),
		Vector2(palm, -radius * 0.88),
		Vector2(tine, -radius * 1.04),
		Vector2(tip, -radius * 0.54),
		Vector2(tine + length * 0.04, -radius * 0.12),
		Vector2(tip - length * 0.05, 0.0),
		Vector2(tine + length * 0.04, radius * 0.12),
		Vector2(tip, radius * 0.54),
		Vector2(tine, radius * 1.04),
		Vector2(palm, radius * 0.88),
		Vector2(wrist, radius * 0.38),
	])


static func _terminal_racket_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var grip := -length * 0.50
	var throat := -length * 0.12
	var head_mid := length * 0.20
	var front := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(grip, -radius * 0.20),
		Vector2(throat, -radius * 0.22),
		Vector2(head_mid, -radius * 1.14),
		Vector2(front, -radius * 0.78),
		Vector2(front, radius * 0.78),
		Vector2(head_mid, radius * 1.14),
		Vector2(throat, radius * 0.22),
		Vector2(grip, radius * 0.20),
	])


static func _terminal_chain_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var tip := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.22),
		Vector2(tip - length * 0.14, -radius * 0.22),
		Vector2(tip, -radius * 0.46),
		Vector2(tip + length * 0.02, 0.0),
		Vector2(tip, radius * 0.46),
		Vector2(tip - length * 0.14, radius * 0.22),
		Vector2(root, radius * 0.22),
	])


static func _terminal_sniper_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var butt := -length * 0.50
	var stock := -length * 0.28
	var body := -length * 0.02
	var barrel := length * 0.34
	var muzzle := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(butt, -radius * 0.42),
		Vector2(stock, -radius * 0.50),
		Vector2(body, -radius * 0.46),
		Vector2(barrel, -radius * 0.18),
		Vector2(muzzle, -radius * 0.14),
		Vector2(muzzle, radius * 0.14),
		Vector2(barrel, radius * 0.18),
		Vector2(body, radius * 0.46),
		Vector2(stock, radius * 0.50),
		Vector2(butt, radius * 0.42),
	])


static func _terminal_rifle_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var butt := -length * 0.50
	var stock := -length * 0.24
	var body := length * 0.08
	var barrel := length * 0.34
	var muzzle := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(butt, -radius * 0.40),
		Vector2(stock, -radius * 0.50),
		Vector2(body, -radius * 0.50),
		Vector2(barrel, -radius * 0.26),
		Vector2(muzzle, -radius * 0.20),
		Vector2(muzzle, radius * 0.20),
		Vector2(barrel, radius * 0.26),
		Vector2(body, radius * 0.50),
		Vector2(stock, radius * 0.50),
		Vector2(butt, radius * 0.40),
	])


static func _terminal_laser_gun_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var root := -length * 0.50
	var prism := length * 0.16
	var emitter := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(root, -radius * 0.32),
		Vector2(-length * 0.18, -radius * 0.46),
		Vector2(prism, -radius * 0.70),
		Vector2(emitter, -radius * 0.22),
		Vector2(emitter, radius * 0.22),
		Vector2(prism, radius * 0.70),
		Vector2(-length * 0.18, radius * 0.46),
		Vector2(root, radius * 0.32),
	])


static func _terminal_sprayer_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var tank_root := -length * 0.50
	var tank_front := length * 0.04
	var neck := length * 0.28
	var nozzle := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(tank_root, -radius * 0.58),
		Vector2(tank_root + length * 0.08, -radius * 0.80),
		Vector2(tank_front, -radius * 0.80),
		Vector2(neck, -radius * 0.44),
		Vector2(nozzle, -radius * 0.54),
		Vector2(nozzle, radius * 0.54),
		Vector2(neck, radius * 0.44),
		Vector2(tank_front, radius * 0.80),
		Vector2(tank_root + length * 0.08, radius * 0.80),
		Vector2(tank_root, radius * 0.58),
	])


static func _terminal_launcher_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var breech := -length * 0.50
	var chamber := -length * 0.16
	var throat := length * 0.16
	var barrel := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(breech, -radius * 0.72),
		Vector2(chamber, -radius * 0.86),
		Vector2(throat, -radius * 0.62),
		Vector2(barrel - length * 0.04, -radius * 0.70),
		Vector2(barrel, -radius * 0.54),
		Vector2(barrel, radius * 0.54),
		Vector2(barrel - length * 0.04, radius * 0.70),
		Vector2(throat, radius * 0.62),
		Vector2(chamber, radius * 0.86),
		Vector2(breech, radius * 0.72),
	])


static func _terminal_missile_launcher_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var rear := -length * 0.50
	var rack := -length * 0.12
	var body := length * 0.22
	var nose := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(rear, -radius * 0.86),
		Vector2(rack, -radius * 0.98),
		Vector2(body, -radius * 0.86),
		Vector2(nose - length * 0.08, -radius * 0.48),
		Vector2(nose, -radius * 0.18),
		Vector2(nose, radius * 0.18),
		Vector2(nose - length * 0.08, radius * 0.48),
		Vector2(body, radius * 0.86),
		Vector2(rack, radius * 0.98),
		Vector2(rear, radius * 0.86),
	])


static func _terminal_web_gun_polygon(center: Vector2, forward: Vector2, right: Vector2, length: float, radius: float) -> PackedVector2Array:
	var rear := -length * 0.50
	var spool := -length * 0.05
	var throat := length * 0.22
	var muzzle := length * 0.50
	return _terminal_local_polygon(center, forward, right, [
		Vector2(rear, -radius * 0.42),
		Vector2(rear + length * 0.12, -radius * 0.78),
		Vector2(spool, -radius * 0.92),
		Vector2(throat, -radius * 0.48),
		Vector2(muzzle, -radius * 0.22),
		Vector2(muzzle, radius * 0.22),
		Vector2(throat, radius * 0.48),
		Vector2(spool, radius * 0.92),
		Vector2(rear + length * 0.12, radius * 0.78),
		Vector2(rear, radius * 0.42),
	])


static func smooth_taper_polygon(root: Vector2, tip: Vector2, forward: Vector2, right: Vector2, root_half: float, tip_half: float, steps: int = 16, belly_mult: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(8, steps)
	for i in range(count + 1):
		var t := float(i) / float(count)
		var center := root.lerp(tip, t)
		var width := lerpf(root_half, tip_half, t)
		width *= lerpf(1.0, belly_mult, sin(t * PI))
		points.append(center + right * width)
	for i in range(count, -1, -1):
		var t := float(i) / float(count)
		var center := root.lerp(tip, t)
		var width := lerpf(root_half, tip_half, t)
		width *= lerpf(1.0, belly_mult, sin(t * PI))
		points.append(center - right * width)
	return points


static func rotated_rect(center: Vector2, axis: Vector2, length: float, width: float) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	return PackedVector2Array([
		center - forward * length * 0.5 - right * width * 0.5,
		center + forward * length * 0.5 - right * width * 0.5,
		center + forward * length * 0.5 + right * width * 0.5,
		center - forward * length * 0.5 + right * width * 0.5,
	])


static func _draw_torso(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, node: Dictionary, visual_length_px: float = -1.0) -> void:
	var metrics := component_display_metrics(node, radius, visual_length_px, true)
	var length := float(metrics.get("length", maxf(float(node.get("component_length", 0.0)), radius * 1.94)))
	var front_width := float(metrics.get("front_width", maxf(radius * 1.2, 6.0)))
	var rear_width := float(metrics.get("rear_width", maxf(radius * 2.4, front_width + 2.0)))
	var hull := torso_hull_polygon(center, axis, node, length, front_width, rear_width)
	canvas.draw_colored_polygon(hull, color.darkened(0.44))
	_draw_outline(canvas, hull, color.lerp(Color.WHITE, 0.24), 2.0)
	var inner := torso_hull_polygon(center, axis, node, length * 0.62, front_width * 0.58, rear_width * 0.58)
	canvas.draw_colored_polygon(inner, color.darkened(0.16))
	_draw_material_marks(canvas, center, axis, length * 0.48, rear_width * 0.46, _node_material_style(node), 0.86)
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	_draw_torso_design_marks(canvas, center, forward, right, length, front_width, rear_width, node, color)
	canvas.draw_line(center + forward * length * 0.5 - right * front_width * 0.42, center + forward * length * 0.5 + right * front_width * 0.42, color.lerp(Color.WHITE, 0.42), 2.0)
	var port_positions := torso_port_positions(center, node, axis, radius, visual_length_px, true)
	var occupied_ports: Array = Array(node.get("occupied_ports", []))
	for i in range(port_positions.size()):
		var p: Vector2 = port_positions[i]
		var occupied := occupied_ports.has(i)
		var port_color := Color(1.0, 0.88, 0.22, 0.95) if not occupied else Color(0.24, 1.0, 0.72, 1.0)
		var port_radius := maxf(3.0, radius * 0.085)
		canvas.draw_circle(p, port_radius, port_color.darkened(0.08))
		canvas.draw_arc(p, port_radius * 1.08, -0.9, 0.9, 14, port_color.lerp(Color.WHITE, 0.34), 1.7)


static func _draw_torso_design_marks(canvas: CanvasItem, center: Vector2, forward: Vector2, right: Vector2, length: float, front_width: float, rear_width: float, node: Dictionary, color: Color) -> void:
	var family := PartArt.torso_visual_family(node)
	var light := color.lerp(Color.WHITE, 0.38)
	var shadow := color.darkened(0.52)
	match family:
		"robot_core":
			var shoulder_y := rear_width * 0.22
			canvas.draw_line(center - forward * length * 0.18 - right * shoulder_y, center + forward * length * 0.18 - right * front_width * 0.20, light, 1.5)
			canvas.draw_line(center - forward * length * 0.18 + right * shoulder_y, center + forward * length * 0.18 + right * front_width * 0.20, light, 1.5)
			canvas.draw_circle(center + forward * length * 0.10, maxf(2.2, front_width * 0.055), Color(0.26, 0.95, 1.0, 0.72))
		"spacecraft_hull":
			canvas.draw_line(center - forward * length * 0.42, center + forward * length * 0.44, light, 1.7)
			for raw_y in [-0.24, 0.24]:
				canvas.draw_line(center - forward * length * 0.22 + right * rear_width * float(raw_y), center + forward * length * 0.32 + right * front_width * float(raw_y), Color(light.r, light.g, light.b, 0.72), 1.2)
			canvas.draw_arc(center - forward * length * 0.36, rear_width * 0.16, 0.0, TAU, 24, Color(light.r, light.g, light.b, 0.48), 1.2)
		"carapace", "mantle":
			for i in range(5):
				var t := lerpf(-0.32, 0.34, float(i) / 4.0)
				var rib_center := center + forward * length * t
				var rib_width := lerpf(rear_width * 0.34, front_width * 0.26, clampf(t + 0.36, 0.0, 1.0))
				canvas.draw_line(rib_center - right * rib_width, rib_center + right * rib_width, Color(light.r, light.g, light.b, 0.56), 1.1)
			canvas.draw_circle(center - forward * length * 0.16, maxf(2.4, rear_width * 0.035), Color(0.18, 1.0, 0.72, 0.44))
		"spine":
			canvas.draw_line(center - forward * length * 0.44, center + forward * length * 0.42, light, 1.6)
			for i in range(6):
				var t := lerpf(-0.38, 0.36, float(i) / 5.0)
				var p := center + forward * length * t
				canvas.draw_circle(p, maxf(1.8, rear_width * 0.024), shadow.lerp(light, 0.48))
				canvas.draw_line(p - right * rear_width * 0.11, p + right * rear_width * 0.11, Color(light.r, light.g, light.b, 0.44), 0.9)
		_:
			canvas.draw_line(center - forward * length * 0.34, center + forward * length * 0.34, Color(light.r, light.g, light.b, 0.58), 1.2)
			canvas.draw_circle(center, maxf(2.0, front_width * 0.048), Color(0.32, 0.84, 1.0, 0.46))


static func _draw_limb(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float, node: Dictionary) -> void:
	var forward := _safe_axis(axis)
	var metrics := component_display_metrics(node, radius, visual_length_px, true)
	var length := float(metrics.get("length", visual_length_px if visual_length_px > 0.0 else radius * 1.9))
	var body_width := float(metrics.get("body_width", maxf(4.0, radius * 0.76)))
	var body := limb_polygon(center, node, forward, radius, visual_length_px, true)
	canvas.draw_colored_polygon(_drawable_polygon(body), color.darkened(0.18))
	_draw_outline(canvas, body, color.lerp(Color.WHITE, 0.28), 1.6)
	_draw_material_marks(canvas, center, forward, length * 0.9, body_width * 0.86, _node_material_style(node), 0.92)
	_draw_limb_family_details(canvas, center, forward, color, radius, length, body_width, node)
	for raw_offset in [-0.5, 0.5]:
		var p := center + forward * length * float(raw_offset)
		var socket_r := maxf(3.2, body_width * 0.42)
		canvas.draw_circle(p, socket_r, Color(0.05, 0.08, 0.1, 0.88))
		canvas.draw_arc(p, socket_r * 1.18, 0.0, TAU, 24, color.lerp(Color.WHITE, 0.44), 1.5)
		canvas.draw_circle(p, socket_r * 0.42, Color(0.28, 0.96, 1.0, 0.62))


static func _draw_limb_family_details(canvas: CanvasItem, center: Vector2, forward: Vector2, color: Color, radius: float, length: float, body_width: float, node: Dictionary) -> void:
	var right := Vector2(-forward.y, forward.x)
	var bright := color.lerp(Color.WHITE, 0.44)
	var dark := color.darkened(0.52)
	var half_width := maxf(1.0, body_width * 0.5)
	match PartArt.limb_visual_family(node):
		"forearm_myomer":
			for side in [-1.0, 1.0]:
				_draw_local_polyline(canvas, center, forward, right, [
					Vector2(-length * 0.36, half_width * 0.38 * side),
					Vector2(-length * 0.04, half_width * 0.20 * side),
					Vector2(length * 0.28, half_width * 0.46 * side),
				], bright, maxf(1.0, radius * 0.045), false)
			canvas.draw_line(center + forward * length * 0.34 - right * half_width * 0.48, center + forward * length * 0.34 + right * half_width * 0.48, dark.lerp(Color.WHITE, 0.22), maxf(1.0, radius * 0.05))
		"thigh_myomer":
			for t in [-0.26, 0.0, 0.26]:
				canvas.draw_line(center + forward * length * float(t) - right * half_width * 0.72, center + forward * length * float(t) + right * half_width * 0.72, Color(bright.r, bright.g, bright.b, 0.58), maxf(1.0, radius * 0.04))
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.38, 0.0),
				Vector2(-length * 0.10, half_width * 0.48),
				Vector2(length * 0.22, half_width * 0.36),
				Vector2(length * 0.40, 0.0),
			], dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.045), false)
		"flex_tendon", "tentacle":
			for strand in [-0.44, -0.16, 0.16, 0.44]:
				var points := []
				for i in range(6):
					var t := float(i) / 5.0
					points.append(Vector2(lerpf(-length * 0.42, length * 0.42, t), half_width * float(strand) + sin(t * TAU * 1.5 + strand) * half_width * 0.14))
				_draw_local_polyline(canvas, center, forward, right, points, bright, maxf(1.0, radius * 0.035), false)
		"chain_muscle":
			var segments := maxi(4, int(node.get("chain_segments", 7)))
			for i in range(segments):
				var t := (float(i) + 0.5) / float(segments)
				var p := center + forward * lerpf(-length * 0.40, length * 0.40, t)
				canvas.draw_arc(p, half_width * 0.42, 0.0, TAU, 18, bright if i % 2 == 0 else dark.lerp(Color.WHITE, 0.24), maxf(1.0, radius * 0.035))
				canvas.draw_line(p - right * half_width * 0.34, p + right * half_width * 0.34, Color(dark.r, dark.g, dark.b, 0.42), maxf(1.0, radius * 0.025))
		"steel_sinew_beam":
			canvas.draw_line(center - forward * length * 0.40, center + forward * length * 0.40, bright, maxf(1.0, radius * 0.055))
			for x in [-0.32, -0.16, 0.0, 0.16, 0.32]:
				var p := center + forward * length * float(x)
				canvas.draw_circle(p - right * half_width * 0.58, maxf(1.4, radius * 0.035), bright)
				canvas.draw_circle(p + right * half_width * 0.58, maxf(1.4, radius * 0.035), bright)
		"ceramic_linear_strut":
			for x in [-0.26, 0.0, 0.26]:
				canvas.draw_line(center + forward * length * float(x) - right * half_width * 0.50, center + forward * length * float(x) + right * half_width * 0.50, dark.lerp(Color.WHITE, 0.24), maxf(1.0, radius * 0.04))
			var rail_a := center - forward * length * 0.36
			var rail_b := center + forward * length * 0.38
			canvas.draw_line(rail_a - right * half_width * 0.20, rail_b - right * half_width * 0.20, bright, maxf(1.0, radius * 0.035))
			canvas.draw_line(rail_a + right * half_width * 0.20, rail_b + right * half_width * 0.20, bright, maxf(1.0, radius * 0.035))
		"colossus_girder_muscle":
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.40, -half_width * 0.58),
				Vector2(-length * 0.20, half_width * 0.58),
				Vector2(0.0, -half_width * 0.58),
				Vector2(length * 0.20, half_width * 0.58),
				Vector2(length * 0.40, -half_width * 0.58),
			], bright, maxf(1.0, radius * 0.045), false)
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.42, half_width * 0.54),
				Vector2(length * 0.42, half_width * 0.54),
			], dark.lerp(Color.WHITE, 0.28), maxf(1.0, radius * 0.045), false)
		"barrier_strut":
			canvas.draw_line(center - forward * length * 0.42 - right * half_width * 0.46, center + forward * length * 0.42 - right * half_width * 0.46, bright, maxf(1.0, radius * 0.04))
			canvas.draw_line(center - forward * length * 0.42 + right * half_width * 0.46, center + forward * length * 0.42 + right * half_width * 0.46, bright, maxf(1.0, radius * 0.04))
			for x in [-0.28, 0.0, 0.28]:
				canvas.draw_line(center + forward * length * float(x) - right * half_width * 0.58, center + forward * length * float(x) + right * half_width * 0.58, dark.lerp(Color.WHITE, 0.24), maxf(1.0, radius * 0.04))
		"fur_sleeve":
			for i in range(12):
				var t := -0.44 + float(i) / 11.0 * 0.88
				var p := center + forward * length * t
				canvas.draw_line(p - right * half_width * 0.76, p - right * half_width * 1.02 + forward * half_width * 0.12, bright, maxf(1.0, radius * 0.026))
				canvas.draw_line(p + right * half_width * 0.76, p + right * half_width * 1.02 + forward * half_width * 0.12, bright, maxf(1.0, radius * 0.026))
		_:
			return


static func _draw_terminal(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float, node: Dictionary) -> void:
	var forward := _safe_axis(axis)
	var visual_forward := terminal_visual_forward(node, forward)
	var polygon := terminal_polygon(center, node, forward, radius, visual_length_px)
	canvas.draw_colored_polygon(_drawable_polygon(polygon), color.darkened(0.16))
	_draw_outline(canvas, polygon, color.lerp(Color.WHITE, 0.34), 1.6)
	var length := visual_length_px if visual_length_px > 0.0 else radius * 2.0
	_draw_terminal_family_details(canvas, center, visual_forward, color, radius, length, node)
	_draw_terminal_root_handle(canvas, center, visual_forward, color, radius, pulse, length)
	if bool(node.get("projectile", false)) or String(node.get("material_class", "")).to_lower() in ["gun", "missile_launcher", "web_gun"]:
		var muzzle := center + forward * length * 0.5
		canvas.draw_circle(muzzle, maxf(2.6, radius * 0.18), Color.WHITE.lerp(color, 0.35))


static func _drawable_polygon(polygon: PackedVector2Array) -> PackedVector2Array:
	if polygon.size() < 3:
		return polygon
	if Geometry2D.triangulate_polygon(polygon).size() >= 3:
		return polygon
	var hull := Geometry2D.convex_hull(polygon)
	if hull.size() >= 2 and hull[0].distance_squared_to(hull[hull.size() - 1]) <= 0.001:
		hull.remove_at(hull.size() - 1)
	return hull


static func _draw_terminal_family_details(canvas: CanvasItem, center: Vector2, forward: Vector2, color: Color, radius: float, length: float, node: Dictionary) -> void:
	var right := Vector2(-forward.y, forward.x)
	var bright := color.lerp(Color.WHITE, 0.42)
	var dark := color.darkened(0.48)
	match terminal_shape_family(node):
		"scythe":
			var scythe_forward := terminal_visual_forward(node, forward)
			var scythe_right := Vector2(-scythe_forward.y, scythe_forward.x) * terminal_mount_side_sign(node)
			_draw_local_polyline(canvas, center, scythe_forward, scythe_right, [
				Vector2(-length * 0.46, 0.0),
				Vector2(length * 0.16, 0.0),
			], dark, maxf(1.2, radius * 0.10), false)
			_draw_local_polyline(canvas, center, scythe_forward, scythe_right, [
				Vector2(length * 0.16, radius * 0.12),
				Vector2(length * 0.19, radius * 0.66),
				Vector2(length * 0.28, radius * 1.04),
				Vector2(length * 0.39, radius * 1.04),
			], bright, maxf(1.2, radius * 0.10), false)
			_draw_local_polyline(canvas, center, scythe_forward, scythe_right, [
				Vector2(length * 0.22, radius * 0.24),
				Vector2(length * 0.28, radius * 0.62),
				Vector2(length * 0.35, radius * 0.78),
			], dark.lerp(Color.WHITE, 0.16), maxf(1.0, radius * 0.055), false)
		"saber":
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.44, -radius * 0.02),
				Vector2(length * 0.05, -radius * 0.08),
				Vector2(length * 0.42, radius * 0.02),
			], dark, maxf(1.1, radius * 0.07), false)
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.22, radius * 0.32),
				Vector2(length * 0.12, radius * 0.52),
				Vector2(length * 0.40, radius * 0.22),
			], bright, maxf(1.1, radius * 0.08), false)
			canvas.draw_line(center - forward * length * 0.30 - right * radius * 0.48, center - forward * length * 0.30 + right * radius * 0.48, bright.darkened(0.12), maxf(1.0, radius * 0.065))
		"shield":
			var inner := _terminal_shield_polygon(center, forward, right, length * 0.72, radius * 0.68)
			_draw_outline(canvas, inner, bright, maxf(1.0, radius * 0.08))
			canvas.draw_arc(center + forward * length * 0.06, radius * 1.02, -PI * 0.40, PI * 0.40, 28, bright.lerp(Color.WHITE, 0.08), maxf(1.0, radius * 0.07))
			canvas.draw_arc(center + forward * length * 0.02, radius * 0.62, -PI * 0.40, PI * 0.40, 28, dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.05))
			var grip := rotated_rect(center - forward * length * 0.10, forward, length * 0.24, radius * 0.18)
			canvas.draw_colored_polygon(grip, dark.lerp(Color.WHITE, 0.10))
			_draw_outline(canvas, grip, bright.darkened(0.12), maxf(1.0, radius * 0.045))
		"drill":
			canvas.draw_line(center - forward * length * 0.44, center - forward * length * 0.12, dark.lerp(Color.WHITE, 0.2), maxf(1.0, radius * 0.09))
			var chuck := rotated_rect(center - forward * length * 0.06, forward, length * 0.12, radius * 0.84)
			canvas.draw_colored_polygon(chuck, dark.lerp(Color.WHITE, 0.12))
			_draw_outline(canvas, chuck, bright.darkened(0.08), maxf(1.0, radius * 0.055))
			var spin_offset := terminal_drill_spiral_offset(node)
			for i in range(8):
				var t := fposmod(0.02 + float(i) * 0.13 + spin_offset, 1.0)
				var x := lerpf(-length * 0.02, length * 0.42, t)
				var half_width := lerpf(radius * 0.48, radius * 0.09, t)
				var p0 := center + forward * (x - length * 0.055) - right * half_width
				var p1 := center + forward * (x + length * 0.075) + right * half_width * 0.78
				canvas.draw_line(p0, p1, bright, maxf(1.0, radius * 0.075))
				var shadow0 := center + forward * (x + length * 0.018) + right * half_width * 0.78
				var shadow1 := center + forward * (x + length * 0.105) - right * half_width * 0.58
				canvas.draw_line(shadow0, shadow1, dark.lerp(Color.WHITE, 0.08), maxf(1.0, radius * 0.045))
		"gauntlet":
			var rod := capsule_polygon(center - forward * length * 0.36, forward, length * 0.24, maxf(2.4, radius * 0.18), 5)
			canvas.draw_colored_polygon(rod, dark.lerp(Color.WHITE, 0.18))
			_draw_outline(canvas, rod, bright.darkened(0.2), maxf(1.0, radius * 0.04))
			var front_x := length * 0.34
			for offset in [-0.60, -0.20, 0.20, 0.60]:
				var knuckle := center + forward * front_x + right * radius * float(offset)
				var knuckle_plate := rotated_rect(knuckle, forward, maxf(3.8, radius * 0.36), maxf(3.1, radius * 0.32))
				canvas.draw_colored_polygon(knuckle_plate, bright.darkened(0.04))
				_draw_outline(canvas, knuckle_plate, dark.lerp(Color.WHITE, 0.22), maxf(1.0, radius * 0.045))
			canvas.draw_line(center - forward * length * 0.18 - right * radius * 0.38, center - forward * length * 0.18 + right * radius * 0.38, bright, maxf(1.0, radius * 0.08))
			canvas.draw_line(center + forward * length * 0.02 - right * radius * 0.84, center + forward * length * 0.02 + right * radius * 0.84, dark.lerp(Color.WHITE, 0.16), maxf(1.0, radius * 0.055))
		"katana":
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.42, -radius * 0.02),
				Vector2(length * 0.02, -radius * 0.10),
				Vector2(length * 0.42, radius * 0.02),
			], dark, maxf(1.0, radius * 0.06), false)
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(-length * 0.26, radius * 0.26),
				Vector2(length * 0.12, radius * 0.38),
				Vector2(length * 0.42, radius * 0.12),
			], bright, maxf(1.0, radius * 0.065), false)
			canvas.draw_line(center - forward * length * 0.32 - right * radius * 0.48, center - forward * length * 0.32 + right * radius * 0.48, bright.darkened(0.12), maxf(1.0, radius * 0.055))
		"greatsword":
			canvas.draw_line(center - forward * length * 0.26 - right * radius * 0.82, center - forward * length * 0.26 + right * radius * 0.82, bright, maxf(1.0, radius * 0.08))
			canvas.draw_line(center - forward * length * 0.18, center + forward * length * 0.34, dark.lerp(Color.WHITE, 0.22), maxf(1.0, radius * 0.065))
			canvas.draw_line(center - forward * length * 0.16 - right * radius * 0.34, center + forward * length * 0.28 - right * radius * 0.20, bright.darkened(0.12), maxf(1.0, radius * 0.04))
			canvas.draw_line(center - forward * length * 0.16 + right * radius * 0.34, center + forward * length * 0.28 + right * radius * 0.20, bright.darkened(0.12), maxf(1.0, radius * 0.04))
		"hammer":
			canvas.draw_line(center - forward * length * 0.44, center + forward * length * 0.16, dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.10))
			var hammer_face_a := rotated_rect(center + forward * length * 0.33 - right * radius * 0.52, forward, length * 0.20, radius * 0.16)
			var hammer_face_b := rotated_rect(center + forward * length * 0.33 + right * radius * 0.52, forward, length * 0.20, radius * 0.16)
			canvas.draw_colored_polygon(hammer_face_a, bright.darkened(0.08))
			canvas.draw_colored_polygon(hammer_face_b, bright.darkened(0.08))
			canvas.draw_circle(center + forward * length * 0.04, maxf(2.0, radius * 0.12), bright)
		"lance":
			canvas.draw_line(center - forward * length * 0.46, center + forward * length * 0.30, dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.055))
			_draw_local_polyline(canvas, center, forward, right, [
				Vector2(length * 0.24, -radius * 0.36),
				Vector2(length * 0.48, 0.0),
				Vector2(length * 0.24, radius * 0.36),
			], bright, maxf(1.0, radius * 0.065), false)
			canvas.draw_line(center - forward * length * 0.18 - right * radius * 0.34, center - forward * length * 0.18 + right * radius * 0.34, bright.darkened(0.1), maxf(1.0, radius * 0.055))
		"rapier":
			canvas.draw_line(center - forward * length * 0.20, center + forward * length * 0.48, bright, maxf(1.0, radius * 0.045))
			canvas.draw_line(center - forward * length * 0.28 - right * radius * 0.58, center - forward * length * 0.28 + right * radius * 0.58, bright.darkened(0.1), maxf(1.0, radius * 0.05))
			canvas.draw_arc(center - forward * length * 0.30, radius * 0.42, 0.0, TAU, 28, dark.lerp(Color.WHITE, 0.25), maxf(1.0, radius * 0.045))
		"claw":
			var palm_plate := rotated_rect(center - forward * length * 0.10, forward, length * 0.24, radius * 0.84)
			canvas.draw_colored_polygon(palm_plate, dark.lerp(Color.WHITE, 0.12))
			_draw_outline(canvas, palm_plate, bright.darkened(0.12), maxf(1.0, radius * 0.045))
			for offset in [-0.46, 0.0, 0.46]:
				_draw_local_polyline(canvas, center, forward, right, [
					Vector2(length * 0.02, radius * float(offset)),
					Vector2(length * 0.38, radius * (float(offset) + 0.10)),
					Vector2(length * 0.50, radius * (float(offset) + 0.26)),
				], bright, maxf(1.0, radius * 0.055), false)
		"racket":
			canvas.draw_arc(center + forward * length * 0.24, radius * 0.72, 0.0, TAU, 40, bright, maxf(1.0, radius * 0.07))
			canvas.draw_line(center - forward * length * 0.46, center + forward * length * 0.04, dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.08))
			for offset in [-0.38, 0.0, 0.38]:
				canvas.draw_line(center + forward * length * 0.04 + right * radius * float(offset), center + forward * length * 0.48 + right * radius * float(offset) * 0.72, bright.darkened(0.1), maxf(1.0, radius * 0.035))
			for offset in [-0.26, 0.26]:
				canvas.draw_line(center + forward * length * 0.20 + right * radius * float(offset) * 2.2, center + forward * length * 0.28 - right * radius * float(offset) * 2.2, bright.darkened(0.16), maxf(1.0, radius * 0.035))
		"chain":
			for i in range(6):
				var t := float(i) / 5.0
				var x := lerpf(-length * 0.38, length * 0.30, t)
				var y := radius * 0.16 if i % 2 == 0 else -radius * 0.16
				var link_axis := forward if i % 2 == 0 else right
				var link := rotated_rect(center + forward * x + right * y, link_axis, length * 0.12, radius * 0.22)
				canvas.draw_colored_polygon(link, dark.lerp(Color.WHITE, 0.16))
				_draw_outline(canvas, link, bright.darkened(0.08), maxf(1.0, radius * 0.035))
			canvas.draw_circle(center + forward * length * 0.44, maxf(2.4, radius * 0.18), bright)
		"sniper":
			canvas.draw_line(center - forward * length * 0.02, center + forward * length * 0.48, bright, maxf(1.0, radius * 0.045))
			var scope := capsule_polygon(center - forward * length * 0.06 + right * radius * 0.48, forward, length * 0.24, maxf(2.2, radius * 0.12), 5)
			canvas.draw_colored_polygon(scope, bright.darkened(0.05))
			_draw_outline(canvas, scope, dark.lerp(Color.WHITE, 0.22), maxf(1.0, radius * 0.035))
			canvas.draw_line(center - forward * length * 0.36 - right * radius * 0.28, center - forward * length * 0.18 - right * radius * 0.46, dark.lerp(Color.WHITE, 0.20), maxf(1.0, radius * 0.055))
		"rifle":
			canvas.draw_line(center + forward * length * 0.04, center + forward * length * 0.48, bright, maxf(1.0, radius * 0.055))
			var magazine := rotated_rect(center + forward * length * 0.02 - right * radius * 0.56, forward, length * 0.13, radius * 0.22)
			canvas.draw_colored_polygon(magazine, dark.lerp(Color.WHITE, 0.14))
			_draw_outline(canvas, magazine, bright.darkened(0.18), maxf(1.0, radius * 0.035))
			canvas.draw_line(center - forward * length * 0.36, center - forward * length * 0.18, dark.lerp(Color.WHITE, 0.18), maxf(1.0, radius * 0.08))
		"laser_gun":
			var prism := _terminal_local_polygon(center, forward, right, [
				Vector2(length * 0.02, 0.0),
				Vector2(length * 0.16, -radius * 0.42),
				Vector2(length * 0.30, 0.0),
				Vector2(length * 0.16, radius * 0.42),
			])
			canvas.draw_colored_polygon(prism, bright.darkened(0.04))
			_draw_outline(canvas, prism, Color.WHITE.lerp(color, 0.30), maxf(1.0, radius * 0.045))
			canvas.draw_line(center - forward * length * 0.18, center + forward * length * 0.46, dark.lerp(Color.WHITE, 0.20), maxf(1.0, radius * 0.045))
			for offset in [-0.38, 0.38]:
				canvas.draw_line(center - forward * length * 0.08 + right * radius * float(offset), center + forward * length * 0.34 + right * radius * float(offset) * 0.62, bright, maxf(1.0, radius * 0.035))
		"sprayer":
			var tank := capsule_polygon(center - forward * length * 0.24 - right * radius * 0.38, forward, length * 0.26, maxf(2.4, radius * 0.22), 6)
			canvas.draw_colored_polygon(tank, dark.lerp(Color.WHITE, 0.12))
			_draw_outline(canvas, tank, bright.darkened(0.12), maxf(1.0, radius * 0.035))
			canvas.draw_line(center - forward * length * 0.08 - right * radius * 0.24, center + forward * length * 0.30 + right * radius * 0.14, bright.darkened(0.08), maxf(1.0, radius * 0.045))
			canvas.draw_line(center + forward * length * 0.34 - right * radius * 0.36, center + forward * length * 0.48 + right * radius * 0.36, bright, maxf(1.0, radius * 0.06))
		"grenade_launcher", "mortar", "cannon":
			var breech := rotated_rect(center - forward * length * 0.12, forward, length * 0.22, radius * 0.64)
			canvas.draw_colored_polygon(breech, dark.lerp(Color.WHITE, 0.12))
			_draw_outline(canvas, breech, bright.darkened(0.14), maxf(1.0, radius * 0.04))
			canvas.draw_line(center + forward * length * 0.00, center + forward * length * 0.46, bright, maxf(1.0, radius * 0.12))
			canvas.draw_arc(center + forward * length * 0.46, radius * 0.28, 0.0, TAU, 24, Color.WHITE.lerp(color, 0.22), maxf(1.0, radius * 0.055))
		"missile_launcher":
			for offset in [-0.44, 0.0, 0.44]:
				var tube := capsule_polygon(center + right * radius * float(offset), forward, length * 0.78, maxf(2.2, radius * 0.13), 5)
				canvas.draw_colored_polygon(tube, dark.lerp(Color.WHITE, 0.12))
				_draw_outline(canvas, tube, bright.darkened(0.12), maxf(1.0, radius * 0.035))
				canvas.draw_circle(center + forward * length * 0.38 + right * radius * float(offset), maxf(1.8, radius * 0.095), bright)
		"web_gun":
			canvas.draw_circle(center - forward * length * 0.18 - right * radius * 0.24, maxf(2.8, radius * 0.24), dark.lerp(Color.WHITE, 0.18))
			canvas.draw_circle(center - forward * length * 0.18 + right * radius * 0.24, maxf(2.8, radius * 0.24), dark.lerp(Color.WHITE, 0.18))
			canvas.draw_arc(center - forward * length * 0.18 - right * radius * 0.24, radius * 0.16, 0.0, TAU, 20, bright, maxf(1.0, radius * 0.035))
			canvas.draw_arc(center - forward * length * 0.18 + right * radius * 0.24, radius * 0.16, 0.0, TAU, 20, bright, maxf(1.0, radius * 0.035))
			canvas.draw_line(center - forward * length * 0.02, center + forward * length * 0.46, bright.darkened(0.08), maxf(1.0, radius * 0.045))
		_:
			return


static func _draw_local_polyline(canvas: CanvasItem, center: Vector2, forward: Vector2, right: Vector2, points: Array, color: Color, width: float, closed: bool = false) -> void:
	if points.size() < 2:
		return
	var transformed: Array[Vector2] = []
	for raw_point in points:
		var p: Vector2 = raw_point
		transformed.append(center + forward * p.x + right * p.y)
	for i in range(transformed.size() - 1):
		canvas.draw_line(transformed[i], transformed[i + 1], color, width)
	if closed:
		canvas.draw_line(transformed[transformed.size() - 1], transformed[0], color, width)


static func _draw_barrier(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float, node: Dictionary) -> void:
	var length := visual_length_px if visual_length_px > 0.0 else radius * 2.0
	var body := capsule_polygon(center, axis, length, maxf(radius * 0.9, 7.0), 6)
	canvas.draw_colored_polygon(body, color.darkened(0.24))
	_draw_outline(canvas, body, color.lerp(Color.WHITE, 0.22), 1.5)


static func _draw_plugin_preview(canvas: CanvasItem, rect: Rect2, slot_key: String, part: Dictionary, color: Color, selected: bool, pulse: float) -> void:
	var center := rect.get_center()
	var min_side := maxf(1.0, minf(rect.size.x, rect.size.y))
	var radius := min_side * 0.33
	var base := _plugin_preview_color(slot_key, part, color)
	var dark := base.darkened(0.48)
	var light := base.lerp(Color.WHITE, 0.42)
	var chip_rect := Rect2(center - Vector2(radius * 1.08, radius * 0.72), Vector2(radius * 2.16, radius * 1.44))
	if selected or pulse > 0.01:
		canvas.draw_circle(center, radius * 1.38, Color(base.r, base.g, base.b, 0.14 + clampf(pulse, 0.0, 1.0) * 0.22))
	canvas.draw_rect(chip_rect, dark, true)
	canvas.draw_rect(chip_rect.grow(-radius * 0.13), base.darkened(0.08), true)
	canvas.draw_rect(chip_rect, light, false, maxf(1.0, radius * 0.08))
	for i in range(4):
		var y := lerpf(chip_rect.position.y + radius * 0.22, chip_rect.end.y - radius * 0.22, float(i) / 3.0)
		canvas.draw_line(Vector2(chip_rect.position.x - radius * 0.26, y), Vector2(chip_rect.position.x, y), light, maxf(1.0, radius * 0.035))
		canvas.draw_line(Vector2(chip_rect.end.x, y), Vector2(chip_rect.end.x + radius * 0.26, y), light, maxf(1.0, radius * 0.035))
	var key := "%s %s %s" % [slot_key.to_lower(), String(part.get("ammo_kind", "")).to_lower(), String(part.get("name", "")).to_lower()]
	if key.contains("engine"):
		canvas.draw_circle(center, radius * 0.42, light)
		canvas.draw_circle(center, radius * 0.22, dark)
		canvas.draw_arc(center, radius * 0.62, 0.0, TAU, 36, light, maxf(1.0, radius * 0.07))
		canvas.draw_line(center - Vector2(radius * 0.72, 0.0), center + Vector2(radius * 0.72, 0.0), light, maxf(1.0, radius * 0.045))
	elif key.contains("cool"):
		for i in range(5):
			var x := lerpf(center.x - radius * 0.56, center.x + radius * 0.56, float(i) / 4.0)
			canvas.draw_rect(Rect2(Vector2(x - radius * 0.045, center.y - radius * 0.54), Vector2(radius * 0.09, radius * 1.08)), light.lerp(base, float(i) * 0.1), true)
		canvas.draw_line(center - Vector2(radius * 0.76, 0.0), center + Vector2(radius * 0.76, 0.0), dark, maxf(1.0, radius * 0.12))
	elif key.contains("booster"):
		var nozzle := PackedVector2Array([
			center + Vector2(-radius * 0.66, -radius * 0.48),
			center + Vector2(radius * 0.18, -radius * 0.34),
			center + Vector2(radius * 0.18, radius * 0.34),
			center + Vector2(-radius * 0.66, radius * 0.48),
		])
		canvas.draw_colored_polygon(nozzle, light.darkened(0.18))
		_draw_triangle(canvas, center + Vector2(radius * 0.62, 0.0), radius * 0.48, PI * 0.5, _thruster_flame_color(part))
	elif key.contains("ammo"):
		_draw_ammo_preview_icon(canvas, center, radius, String(part.get("ammo_kind", part.get("projectile_damage_type", part.get("damage_type", "bullet")))).to_lower(), light, dark)
	elif key.contains("shield"):
		canvas.draw_arc(center, radius * 0.64, -PI * 0.92, PI * 0.92, 32, light, maxf(1.0, radius * 0.09))
		canvas.draw_arc(center, radius * 0.36, -PI * 0.7, PI * 0.7, 24, light.lerp(Color.WHITE, 0.25), maxf(1.0, radius * 0.055))
	elif key.contains("soul") or key.contains("spirit") or key.contains("hero"):
		for i in range(8):
			var a := TAU * float(i) / 8.0
			canvas.draw_line(center, center + Vector2(cos(a), sin(a)) * radius * (0.34 if i % 2 == 0 else 0.62), light, maxf(1.0, radius * 0.035))
		canvas.draw_circle(center, radius * 0.24, light)
	elif key.contains("code"):
		var pts := [center + Vector2(-radius * 0.48, -radius * 0.18), center + Vector2(0.0, radius * 0.34), center + Vector2(radius * 0.48, -radius * 0.24)]
		canvas.draw_line(pts[0], pts[1], light, maxf(1.0, radius * 0.05))
		canvas.draw_line(pts[1], pts[2], light, maxf(1.0, radius * 0.05))
		for p in pts:
			canvas.draw_circle(p, radius * 0.12, light)
	elif key.contains("ether"):
		canvas.draw_arc(center, radius * 0.52, -PI * 0.25, PI * 1.22, 34, light, maxf(1.0, radius * 0.07))
		canvas.draw_line(center, center + Vector2(radius * 0.48, radius * 0.42), light, maxf(1.0, radius * 0.05))
	elif String(part.get("module_visual_family", "")).to_lower() != "":
		if _draw_module_visual_family_preview(canvas, center, radius, String(part.get("module_visual_family", "")).to_lower(), base, light, dark):
			return
	elif key.contains("module") or key.contains("action"):
		canvas.draw_arc(center, radius * 0.56, -PI * 0.82, PI * 0.72, 28, light, maxf(1.0, radius * 0.08))
		canvas.draw_line(center + Vector2(radius * 0.48, radius * 0.38), center + Vector2(radius * 0.78, radius * 0.08), light, maxf(1.0, radius * 0.08))
	else:
		canvas.draw_circle(center, radius * 0.42, light)
		canvas.draw_rect(Rect2(center - Vector2(radius * 0.16, radius * 0.16), Vector2(radius * 0.32, radius * 0.32)), dark, true)


static func _draw_module_visual_family_preview(canvas: CanvasItem, center: Vector2, radius: float, family: String, base: Color, light: Color, dark: Color) -> bool:
	var accent := base.lerp(Color.WHITE, 0.58)
	match family:
		"balance_string":
			canvas.draw_arc(center + Vector2(-radius * 0.12, 0.0), radius * 0.54, -PI * 0.86, PI * 0.26, 28, accent, maxf(1.0, radius * 0.07))
			canvas.draw_arc(center + Vector2(radius * 0.12, 0.0), radius * 0.54, PI * 0.14, PI * 1.26, 28, accent, maxf(1.0, radius * 0.07))
			canvas.draw_line(center + Vector2(-radius * 0.46, -radius * 0.32), center + Vector2(radius * 0.46, radius * 0.32), light, maxf(1.0, radius * 0.045))
			canvas.draw_line(center + Vector2(-radius * 0.46, radius * 0.32), center + Vector2(radius * 0.46, -radius * 0.32), light, maxf(1.0, radius * 0.045))
			canvas.draw_circle(center + Vector2(-radius * 0.52, 0.0), radius * 0.13, light)
			canvas.draw_circle(center + Vector2(radius * 0.52, 0.0), radius * 0.13, light)
			return true
		"vise_close":
			var left_jaw := PackedVector2Array([
				center + Vector2(-radius * 0.72, -radius * 0.48),
				center + Vector2(-radius * 0.18, -radius * 0.48),
				center + Vector2(-radius * 0.18, -radius * 0.18),
				center + Vector2(-radius * 0.46, -radius * 0.08),
				center + Vector2(-radius * 0.18, radius * 0.02),
				center + Vector2(-radius * 0.18, radius * 0.48),
				center + Vector2(-radius * 0.72, radius * 0.48),
			])
			var right_jaw := PackedVector2Array()
			for p in left_jaw:
				right_jaw.append(Vector2(center.x * 2.0 - p.x, p.y))
			canvas.draw_colored_polygon(left_jaw, light.darkened(0.08))
			canvas.draw_colored_polygon(right_jaw, light.darkened(0.08))
			_draw_outline(canvas, left_jaw, dark.lerp(Color.WHITE, 0.28), maxf(1.0, radius * 0.04))
			_draw_outline(canvas, right_jaw, dark.lerp(Color.WHITE, 0.28), maxf(1.0, radius * 0.04))
			canvas.draw_line(center + Vector2(-radius * 0.64, 0.0), center + Vector2(radius * 0.64, 0.0), accent, maxf(1.0, radius * 0.08))
			for i in range(4):
				var x := lerpf(-radius * 0.28, radius * 0.28, float(i) / 3.0)
				canvas.draw_line(center + Vector2(x, -radius * 0.16), center + Vector2(x, radius * 0.16), dark, maxf(1.0, radius * 0.035))
			return true
		"pickup_dash":
			canvas.draw_line(center + Vector2(-radius * 0.72, -radius * 0.26), center + Vector2(radius * 0.54, -radius * 0.26), dark.lerp(Color.WHITE, 0.28), maxf(1.0, radius * 0.045))
			canvas.draw_line(center + Vector2(-radius * 0.72, radius * 0.26), center + Vector2(radius * 0.54, radius * 0.26), dark.lerp(Color.WHITE, 0.28), maxf(1.0, radius * 0.045))
			canvas.draw_line(center + Vector2(-radius * 0.62, 0.0), center + Vector2(radius * 0.48, 0.0), light, maxf(1.0, radius * 0.09))
			_draw_triangle(canvas, center + Vector2(radius * 0.62, 0.0), radius * 0.24, PI * 0.5, light)
			canvas.draw_arc(center + Vector2(radius * 0.12, radius * 0.06), radius * 0.36, -PI * 0.15, PI * 0.92, 20, accent, maxf(1.0, radius * 0.055))
			return true
		"crush_windup":
			var wedge := PackedVector2Array([
				center + Vector2(-radius * 0.56, -radius * 0.38),
				center + Vector2(radius * 0.18, -radius * 0.56),
				center + Vector2(radius * 0.66, -radius * 0.18),
				center + Vector2(radius * 0.66, radius * 0.18),
				center + Vector2(radius * 0.18, radius * 0.56),
				center + Vector2(-radius * 0.56, radius * 0.38),
			])
			canvas.draw_colored_polygon(wedge, light.darkened(0.2))
			_draw_outline(canvas, wedge, Color(1.0, 0.26, 0.16, 0.92), maxf(1.0, radius * 0.05))
			canvas.draw_line(center + Vector2(-radius * 0.76, -radius * 0.42), center + Vector2(radius * 0.38, radius * 0.42), dark.lerp(Color.WHITE, 0.35), maxf(1.0, radius * 0.05))
			canvas.draw_line(center + Vector2(-radius * 0.76, radius * 0.42), center + Vector2(radius * 0.38, -radius * 0.42), dark.lerp(Color.WHITE, 0.35), maxf(1.0, radius * 0.05))
			canvas.draw_arc(center, radius * 0.76, -PI * 0.95, PI * 0.15, 24, Color(1.0, 0.24, 0.12, 0.78), maxf(1.0, radius * 0.045))
			return true
		"feint_thrust":
			canvas.draw_line(center + Vector2(-radius * 0.62, 0.0), center + Vector2(radius * 0.70, 0.0), light, maxf(1.0, radius * 0.055))
			canvas.draw_line(center + Vector2(-radius * 0.34, radius * 0.24), center + Vector2(radius * 0.46, radius * 0.12), Color(light.r, light.g, light.b, 0.38), maxf(1.0, radius * 0.035))
			_draw_triangle(canvas, center + Vector2(radius * 0.78, 0.0), radius * 0.16, PI * 0.5, light)
			canvas.draw_arc(center + Vector2(radius * 0.34, 0.0), radius * 0.26, 0.0, TAU, 28, accent, maxf(1.0, radius * 0.035))
			canvas.draw_line(center + Vector2(radius * 0.08, -radius * 0.2), center + Vector2(radius * 0.08, radius * 0.2), accent, maxf(1.0, radius * 0.035))
			return true
		"explosive_arc":
			var last := center + Vector2(-radius * 0.66, radius * 0.28)
			for i in range(1, 8):
				var t := float(i) / 7.0
				var p := center + Vector2(lerpf(-radius * 0.66, radius * 0.66, t), radius * 0.28 - sin(t * PI) * radius * 0.72)
				if i % 2 == 1:
					canvas.draw_line(last, p, Color(1.0, 0.72, 0.24, 0.82), maxf(1.0, radius * 0.035))
				canvas.draw_circle(p, maxf(1.2, radius * 0.035), light)
				last = p
			canvas.draw_rect(Rect2(center + Vector2(radius * 0.42, radius * 0.22), Vector2(radius * 0.34, radius * 0.16)), Color(1.0, 0.42, 0.12, 0.72), false, maxf(1.0, radius * 0.035))
			canvas.draw_line(center + Vector2(-radius * 0.58, radius * 0.38), center + Vector2(-radius * 0.26, radius * 0.12), dark.lerp(Color.WHITE, 0.35), maxf(1.0, radius * 0.07))
			return true
	return false


static func _draw_terminal_root_handle(canvas: CanvasItem, center: Vector2, forward: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float) -> void:
	var axis := _safe_axis(forward)
	var root := center - axis * visual_length_px * 0.5
	var right := Vector2(-axis.y, axis.x)
	var sleeve_center := root + axis * maxf(5.0, radius * 0.35)
	var sleeve_len := maxf(8.0, radius * 0.65)
	var sleeve_width := maxf(5.0, radius * 0.5)
	var sleeve := capsule_polygon(sleeve_center, axis, sleeve_len, sleeve_width, 4)
	canvas.draw_colored_polygon(sleeve, color.darkened(0.32).lerp(Color(0.06, 0.12, 0.14, 1.0), 0.45))
	_draw_outline(canvas, sleeve, color.lerp(Color.WHITE, 0.38), 1.3)
	var clamp_width := maxf(5.0, radius * 0.56)
	canvas.draw_line(root - right * clamp_width, root + right * clamp_width, Color(0.32, 0.96, 1.0, 0.9), 1.8 + pulse * 0.8)


static func _draw_material_marks(canvas: CanvasItem, center: Vector2, axis: Vector2, length: float, width: float, material_style: String, alpha: float) -> void:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	match material_style:
		"metal":
			canvas.draw_line(center - forward * length * 0.44 - right * width * 0.24, center + forward * length * 0.44 - right * width * 0.08, Color(1.0, 1.0, 1.0, 0.42 * alpha), maxf(1.0, width * 0.13))
			canvas.draw_line(center - forward * length * 0.48 + right * width * 0.42, center + forward * length * 0.48 + right * width * 0.42, Color(0.02, 0.05, 0.07, 0.5 * alpha), maxf(1.0, width * 0.07))
		"wood":
			for i in range(5):
				var offset := right * width * (-0.38 + float(i) * 0.19)
				canvas.draw_line(center - forward * length * 0.44 + offset, center + forward * length * 0.44 + offset + right * width * 0.04 * sin(float(i) * 1.4), Color(0.18, 0.09, 0.04, 0.56 * alpha), maxf(1.0, width * 0.055))
		"ceramic":
			for i in range(4):
				var p0 := center - forward * length * (0.38 - float(i) * 0.18) + right * width * (0.24 - float(i) * 0.14)
				canvas.draw_line(p0, p0 + forward * length * 0.16 + right * width * (0.16 if i % 2 == 0 else -0.16), Color(0.18, 0.16, 0.13, 0.42 * alpha), maxf(1.0, width * 0.045))
		"fur":
			for i in range(12):
				var t := -0.48 + float(i) / 11.0 * 0.96
				for side in [-1.0, 1.0]:
					var base: Vector2 = center + forward * length * t + right * width * 0.5 * float(side)
					canvas.draw_line(base, base + right * side * width * 0.22 + forward * width * 0.05 * sin(float(i) * 1.7), Color(0.92, 0.74, 0.46, 0.52 * alpha), maxf(1.0, width * 0.045))
		"flex":
			for i in range(5):
				var y := -0.32 + float(i) * 0.16
				var points := []
				for step in range(5):
					var t := float(step) / 4.0
					points.append(Vector2(lerpf(-length * 0.42, length * 0.42, t), width * y + sin(t * TAU * 1.2 + float(i)) * width * 0.055))
				_draw_local_polyline(canvas, center, forward, right, points, Color(0.95, 1.0, 1.0, 0.36 * alpha), maxf(1.0, width * 0.035), false)
		"chain":
			for i in range(6):
				var t := (float(i) + 0.5) / 6.0
				var p := center + forward * lerpf(-length * 0.40, length * 0.40, t)
				canvas.draw_arc(p, width * 0.20, 0.0, TAU, 16, Color(0.98, 1.0, 1.0, 0.44 * alpha), maxf(1.0, width * 0.035))
		"hardlight":
			canvas.draw_line(center - forward * length * 0.46 - right * width * 0.46, center + forward * length * 0.46 - right * width * 0.46, Color(0.42, 1.0, 1.0, 0.62 * alpha), maxf(1.0, width * 0.055))
			canvas.draw_line(center - forward * length * 0.46 + right * width * 0.46, center + forward * length * 0.46 + right * width * 0.46, Color(0.42, 1.0, 1.0, 0.62 * alpha), maxf(1.0, width * 0.055))
			for i in range(4):
				var x := -0.30 + float(i) * 0.20
				canvas.draw_line(center + forward * length * x - right * width * 0.34, center + forward * length * x + right * width * 0.34, Color(0.72, 1.0, 1.0, 0.34 * alpha), maxf(1.0, width * 0.035))


static func _plugin_preview_color(slot_key: String, part: Dictionary, fallback: Color) -> Color:
	var key := "%s %s %s" % [slot_key.to_lower(), String(part.get("ammo_kind", "")).to_lower(), String(part.get("name", "")).to_lower()]
	match String(part.get("module_visual_family", "")).to_lower():
		"balance_string":
			return Color(0.44, 0.92, 1.0, 1.0)
		"vise_close":
			return Color(1.0, 0.66, 0.24, 1.0)
		"pickup_dash":
			return Color(0.62, 1.0, 0.36, 1.0)
		"crush_windup":
			return Color(1.0, 0.28, 0.18, 1.0)
		"feint_thrust":
			return Color(0.72, 0.82, 1.0, 1.0)
		"explosive_arc":
			return Color(1.0, 0.48, 0.18, 1.0)
	if key.contains("engine"):
		return Color(0.58, 0.42, 1.0, 1.0)
	if key.contains("cool"):
		return Color(0.28, 0.96, 0.72, 1.0)
	if key.contains("booster"):
		return Color(1.0, 0.42, 0.12, 1.0)
	if key.contains("shield"):
		return Color(0.34, 0.78, 1.0, 1.0)
	if key.contains("ammo") or key.contains("bullet") or key.contains("laser") or key.contains("chemical") or key.contains("explosive") or key.contains("web"):
		return PartArt.damage_color_for(String(part.get("ammo_kind", part.get("projectile_damage_type", part.get("damage_type", "bullet")))), "ammo")
	if key.contains("module") or key.contains("action"):
		return Color(0.92, 0.94, 1.0, 1.0)
	if key.contains("soul") or key.contains("spirit"):
		return Color(1.0, 0.82, 0.22, 1.0)
	if key.contains("code"):
		return Color(0.48, 0.95, 1.0, 1.0)
	if key.contains("ether"):
		return Color(0.78, 0.44, 1.0, 1.0)
	return fallback


static func _thruster_flame_color(part: Dictionary) -> Color:
	var flame := String(part.get("flame_color", "")).to_lower()
	var family := String(part.get("thruster_family", "")).to_lower()
	if flame.contains("red") or family.contains("overburn") or family.contains("burst"):
		return Color(1.0, 0.16, 0.08, 0.92)
	if flame.contains("yellow") or family.contains("sustain"):
		return Color(1.0, 0.86, 0.18, 0.92)
	return Color(0.24, 0.72, 1.0, 0.92)


static func _draw_ammo_preview_icon(canvas: CanvasItem, center: Vector2, radius: float, ammo_kind: String, light: Color, dark: Color) -> void:
	match ammo_kind:
		"laser":
			canvas.draw_line(center - Vector2(radius * 0.66, 0.0), center + Vector2(radius * 0.66, 0.0), light, maxf(1.0, radius * 0.12))
			canvas.draw_circle(center + Vector2(radius * 0.7, 0.0), radius * 0.12, light)
		"chemical":
			canvas.draw_circle(center + Vector2(-radius * 0.2, -radius * 0.04), radius * 0.26, light)
			canvas.draw_circle(center + Vector2(radius * 0.18, radius * 0.16), radius * 0.2, light.lerp(Color.WHITE, 0.25))
			canvas.draw_line(center + Vector2(-radius * 0.44, radius * 0.5), center + Vector2(radius * 0.46, -radius * 0.46), light, maxf(1.0, radius * 0.05))
		"explosive":
			_draw_triangle(canvas, center, radius * 0.48, 0.0, light)
			canvas.draw_circle(center, radius * 0.18, dark)
		"web":
			for i in range(6):
				var a := TAU * float(i) / 6.0
				canvas.draw_line(center, center + Vector2(cos(a), sin(a)) * radius * 0.58, light, maxf(1.0, radius * 0.035))
			canvas.draw_arc(center, radius * 0.32, 0.0, TAU, 28, light, maxf(1.0, radius * 0.035))
			canvas.draw_arc(center, radius * 0.56, 0.0, TAU, 28, light, maxf(1.0, radius * 0.03))
		_:
			var shell := Rect2(center + Vector2(-radius * 0.18, -radius * 0.62), Vector2(radius * 0.36, radius * 1.02))
			canvas.draw_rect(shell, light, true)
			_draw_triangle(canvas, center + Vector2(0.0, -radius * 0.66), radius * 0.24, 0.0, light.lerp(Color.WHITE, 0.2))


static func _draw_triangle(canvas: CanvasItem, center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(3):
		var angle := rotation + TAU * float(i) / 3.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	canvas.draw_colored_polygon(pts, color)


static func _draw_outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	for i in range(points.size()):
		canvas.draw_line(points[i], points[(i + 1) % points.size()], color, width)


static func _component_color(fallback: Color, node: Dictionary) -> Color:
	var material := _node_material_style(node)
	var slot := String(node.get("slot", ""))
	var base := PartArt.material_color_for(material, slot)
	if bool(node.get("projectile", false)):
		base = base.lerp(PartArt.damage_color_for(String(node.get("projectile_damage_type", node.get("damage_type", "bullet"))), slot), 0.32)
	return base.lerp(fallback, 0.38)


static func _node_material_style(node: Dictionary) -> String:
	return PartArt.material_style_for(node)


static func _terminal_shape_name(node: Dictionary) -> String:
	match terminal_shape_family(node):
		"gun":
			return "gun"
		"sniper":
			return "sniper"
		"rifle":
			return "rifle"
		"laser_gun":
			return "laser_gun"
		"sprayer":
			return "sprayer"
		"grenade_launcher":
			return "grenade_launcher"
		"mortar":
			return "mortar"
		"cannon":
			return "cannon"
		"missile_launcher":
			return "missile_launcher"
		"web_gun":
			return "web_gun"
		"scythe":
			return "scythe"
		"shield":
			return "shield"
		"drill":
			return "drill"
		"gauntlet":
			return "gauntlet"
		"saber":
			return "saber"
		"katana":
			return "katana"
		"greatsword":
			return "greatsword"
		"hammer":
			return "hammer"
		"lance":
			return "lance"
		"rapier":
			return "rapier"
		"claw":
			return "claw"
		"racket":
			return "racket"
		"chain":
			return "chain"
		"generic_blade":
			return "blade"
		"generic_pierce":
			return "spike"
		"generic_blunt":
			return "hammer"
		_:
			return "terminal"


static func _safe_axis(axis: Vector2) -> Vector2:
	if axis.length() < 0.001:
		return Vector2.RIGHT
	return axis.normalized()
