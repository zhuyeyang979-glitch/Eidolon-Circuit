class_name AssemblyBoardRenderer
extends RefCounted

const PartArt = preload("res://scripts/part_art.gd")


static func draw_component(canvas: CanvasItem, center: Vector2, node: Dictionary, color: Color, axis: Vector2, physical_radius: float, pulse: float = 0.0, visual_length_px: float = -1.0) -> bool:
	var forward := _safe_axis(axis)
	var kind := component_kind(node)
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
			_draw_torso(canvas, center, forward, base_color, physical_radius, node, visual_length_px)
		"limb":
			_draw_limb(canvas, center, forward, base_color, physical_radius, pulse, visual_length_px, node)
		"terminal":
			_draw_terminal(canvas, center, forward, base_color, physical_radius, pulse, visual_length_px, node)
		"barrier":
			_draw_barrier(canvas, center, forward, base_color, physical_radius, pulse, visual_length_px, node)
		_:
			_draw_limb(canvas, center, forward, base_color, physical_radius, pulse, visual_length_px, node)
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
	return draw_component(canvas, center, node, draw_color, axis, radius_px, 0.0, visual_length)


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


static func component_polygon(center: Vector2, node: Dictionary, axis: Vector2, physical_radius: float, visual_length_px: float = -1.0, pixel_minimums: bool = true) -> PackedVector2Array:
	var forward := _safe_axis(axis)
	var kind := component_kind(node)
	match kind:
		"torso":
			var min_length := 10.0 if pixel_minimums else 0.001
			var min_width := 6.0 if pixel_minimums else 0.001
			var length := maxf(visual_length_px if visual_length_px > 0.0 else physical_radius * 1.94, min_length)
			var front_width := maxf(physical_radius * 1.2, min_width)
			var rear_width := maxf(physical_radius * 2.4, front_width + (2.0 if pixel_minimums else 0.001))
			return saddle_polygon(center, forward, length, front_width, rear_width)
		"terminal":
			return terminal_polygon(center, node, forward, physical_radius, visual_length_px, pixel_minimums)
		"barrier":
			var barrier_length := maxf(visual_length_px if visual_length_px > 0.0 else physical_radius * 2.0, 10.0 if pixel_minimums else 0.001)
			return capsule_polygon(center, forward, barrier_length, maxf(physical_radius * 0.9, 7.0 if pixel_minimums else 0.001), 6)
		_:
			var limb_length := maxf(visual_length_px if visual_length_px > 0.0 else physical_radius * 1.9, 8.0 if pixel_minimums else 0.001)
			return capsule_polygon(center, forward, limb_length, maxf(physical_radius * 0.76, 5.0 if pixel_minimums else 0.001), 6)


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
