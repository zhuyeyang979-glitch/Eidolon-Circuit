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
	var draw_color := material_color
	if part_kind == "torso":
		draw_color = primary_color.lerp(material_color, 0.45).lerp(Color.WHITE, 0.08)
	var center := (local_a + local_b) * 0.5
	return draw_component(canvas, center, node, draw_color, axis, radius_px, 0.0, visual_length, true)


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
		return node
	node["slot"] = "limb_muscle"
	node["connection_ends"] = 2
	node["shape"] = "limb"
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
		"radius": float(segment.get("radius", 0.025)),
		"component_radius": float(segment.get("radius", 0.025)),
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
		"barrier_tile":
			node["slot"] = "barrier_tile"
			node["is_barrier_tile"] = true
			node["shape"] = "barrier"
		_:
			node["slot"] = "limb_muscle"
			node["connection_ends"] = 2
			node["shape"] = "limb"
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
			# Matches the saddle card silhouette: rear width is about 60% of length,
			# because _draw_torso derives rear width as radius * 2.4.
			return maxf(length * 0.25, min_radius)
		"terminal":
			return maxf(length * 0.135, min_radius)
		"barrier":
			return maxf(length * 0.18, min_radius)
		_:
			# Limb cards are intentionally slimmer than their metric radius can imply.
			return maxf(length * 0.145, min_radius)


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
	var display_radius := component_display_radius(node, physical_radius, visual_length_px, pixel_minimums)
	match kind:
		"torso":
			var min_length := 10.0 if pixel_minimums else 0.001
			var min_width := 6.0 if pixel_minimums else 0.001
			var length := maxf(visual_length_px if visual_length_px > 0.0 else display_radius * 1.94, min_length)
			var front_width := maxf(display_radius * 1.2, min_width)
			var rear_width := maxf(display_radius * 2.4, front_width + (2.0 if pixel_minimums else 0.001))
			return saddle_polygon(center, forward, length, front_width, rear_width)
		"terminal":
			return terminal_polygon(center, node, forward, display_radius, visual_length_px, pixel_minimums)
		"barrier":
			var barrier_length := maxf(visual_length_px if visual_length_px > 0.0 else display_radius * 2.0, 10.0 if pixel_minimums else 0.001)
			return capsule_polygon(center, forward, barrier_length, maxf(display_radius * 0.9, 7.0 if pixel_minimums else 0.001), 6)
		_:
			var limb_length := maxf(visual_length_px if visual_length_px > 0.0 else display_radius * 1.9, 8.0 if pixel_minimums else 0.001)
			return capsule_polygon(center, forward, limb_length, maxf(display_radius * 0.76, 5.0 if pixel_minimums else 0.001), 6)


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


static func terminal_polygon(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	var length := maxf(visual_length_px if visual_length_px > 0.0 else physical_radius * 2.0, 10.0 if pixel_minimums else 0.001)
	var radius := maxf(physical_radius, 4.0 if pixel_minimums else 0.001)
	var root := center - forward * length * 0.5
	var tip := center + forward * length * 0.5
	var damage_type := String(node.get("damage_type", "")).to_lower()
	var material_class := String(node.get("material_class", "")).to_lower()
	var projectile := bool(node.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"]
	var handle_len := minf(length * 0.24, radius * 2.2)
	var body_root := root + forward * handle_len
	if projectile:
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.82, radius * 0.36, 16)
	if damage_type == "tear":
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.62, radius * 0.2, 18, 1.35)
	if damage_type == "pierce":
		return smooth_taper_polygon(root, tip, forward, right, radius * 0.55, radius * 0.08, 16, 0.9)
	return capsule_polygon(center, forward, length, radius * 1.7, 6)


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
	var length := maxf(float(node.get("component_length", 0.0)), 0.0)
	if visual_length_px > 0.0:
		length = visual_length_px
	if length <= 0.0:
		length = maxf(float(node.get("edge_extent_units", 0.0)), 0.0) * 1.94
	if length <= 0.0:
		length = radius * 1.94
	var front_width := maxf(radius * 1.2, 6.0)
	var rear_width := maxf(radius * 2.4, front_width + 2.0)
	var hull := saddle_polygon(center, axis, length, front_width, rear_width)
	canvas.draw_colored_polygon(hull, color.darkened(0.44))
	_draw_outline(canvas, hull, color.lerp(Color.WHITE, 0.24), 2.0)
	var inner := saddle_polygon(center, axis, length * 0.62, front_width * 0.58, rear_width * 0.58)
	canvas.draw_colored_polygon(inner, color.darkened(0.16))
	_draw_material_marks(canvas, center, axis, length * 0.48, rear_width * 0.46, _node_material_style(node), 0.86)
	var forward := _safe_axis(axis)
	var right := Vector2(-forward.y, forward.x)
	canvas.draw_line(center + forward * length * 0.5 - right * front_width * 0.42, center + forward * length * 0.5 + right * front_width * 0.42, color.lerp(Color.WHITE, 0.42), 2.0)
	var port_count := PartArt.torso_saddle_port_count(node)
	var port_positions := []
	var torso_scale := maxf(0.001, PartArt.TORSO_GEOMETRY_SCALE)
	for raw_local in PartArt.torso_saddle_port_local_offsets(port_count, length / torso_scale, front_width / torso_scale, rear_width / torso_scale):
		var local: Vector2 = raw_local
		port_positions.append(center + forward * local.x + right * local.y)
	var occupied_ports: Array = Array(node.get("occupied_ports", []))
	for i in range(port_positions.size()):
		var p: Vector2 = port_positions[i]
		var occupied := occupied_ports.has(i)
		var port_color := Color(1.0, 0.88, 0.22, 0.95) if not occupied else Color(0.24, 1.0, 0.72, 1.0)
		var port_radius := maxf(3.0, radius * 0.085)
		canvas.draw_circle(p, port_radius, port_color.darkened(0.08))
		canvas.draw_arc(p, port_radius * 1.08, -0.9, 0.9, 14, port_color.lerp(Color.WHITE, 0.34), 1.7)


static func _draw_limb(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float, node: Dictionary) -> void:
	var forward := _safe_axis(axis)
	var length := visual_length_px if visual_length_px > 0.0 else radius * 1.9
	var body_width := maxf(4.0, radius * 0.76)
	var body := capsule_polygon(center, forward, length, body_width, 6)
	canvas.draw_colored_polygon(body, color.darkened(0.18))
	_draw_outline(canvas, body, color.lerp(Color.WHITE, 0.28), 1.6)
	_draw_material_marks(canvas, center, forward, length * 0.9, body_width * 0.86, _node_material_style(node), 0.92)
	for raw_offset in [-0.5, 0.5]:
		var p := center + forward * length * float(raw_offset)
		var socket_r := maxf(3.2, body_width * 0.42)
		canvas.draw_circle(p, socket_r, Color(0.05, 0.08, 0.1, 0.88))
		canvas.draw_arc(p, socket_r * 1.18, 0.0, TAU, 24, color.lerp(Color.WHITE, 0.44), 1.5)
		canvas.draw_circle(p, socket_r * 0.42, Color(0.28, 0.96, 1.0, 0.62))


static func _draw_terminal(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, pulse: float, visual_length_px: float, node: Dictionary) -> void:
	var forward := _safe_axis(axis)
	var polygon := terminal_polygon(center, node, forward, radius, visual_length_px)
	canvas.draw_colored_polygon(polygon, color.darkened(0.16))
	_draw_outline(canvas, polygon, color.lerp(Color.WHITE, 0.34), 1.6)
	var length := visual_length_px if visual_length_px > 0.0 else radius * 2.0
	_draw_terminal_root_handle(canvas, center, forward, color, radius, pulse, length)
	if bool(node.get("projectile", false)) or String(node.get("material_class", "")).to_lower() in ["gun", "missile_launcher", "web_gun"]:
		var muzzle := center + forward * length * 0.5
		canvas.draw_circle(muzzle, maxf(2.6, radius * 0.18), Color.WHITE.lerp(color, 0.35))


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
	elif key.contains("module") or key.contains("action"):
		canvas.draw_arc(center, radius * 0.56, -PI * 0.82, PI * 0.72, 28, light, maxf(1.0, radius * 0.08))
		canvas.draw_line(center + Vector2(radius * 0.48, radius * 0.38), center + Vector2(radius * 0.78, radius * 0.08), light, maxf(1.0, radius * 0.08))
	else:
		canvas.draw_circle(center, radius * 0.42, light)
		canvas.draw_rect(Rect2(center - Vector2(radius * 0.16, radius * 0.16), Vector2(radius * 0.32, radius * 0.32)), dark, true)


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


static func _plugin_preview_color(slot_key: String, part: Dictionary, fallback: Color) -> Color:
	var key := "%s %s %s" % [slot_key.to_lower(), String(part.get("ammo_kind", "")).to_lower(), String(part.get("name", "")).to_lower()]
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
	if bool(node.get("projectile", false)):
		return "gun"
	match String(node.get("damage_type", "")).to_lower():
		"tear":
			return "blade"
		"pierce":
			return "spike"
		"blunt":
			return "hammer"
	return "terminal"


static func _safe_axis(axis: Vector2) -> Vector2:
	if axis.length() < 0.001:
		return Vector2.RIGHT
	return axis.normalized()
