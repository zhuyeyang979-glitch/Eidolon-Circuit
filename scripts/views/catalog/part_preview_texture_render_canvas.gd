class_name PartPreviewTextureRenderCanvas
extends Control

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")
const PartArt = preload("res://scripts/part_art.gd")

var slot_key := ""
var part := {}
var selected := false
var pulse := 0.0
var image2_part_art_cache := {}

func configure(next_slot: String, next_part: Dictionary, next_selected: bool, next_pulse: float, next_size: Vector2) -> void:
	slot_key = next_slot
	part = next_part
	selected = next_selected
	pulse = next_pulse
	size = next_size
	queue_redraw()

func _draw() -> void:
	if slot_key == "" or part.is_empty():
		return
	if _draw_catalog_detail_thumbnail(Rect2(Vector2.ZERO, size).grow(-2.0)):
		return
	if _draw_image2_part_preview(Rect2(Vector2.ZERO, size).grow(-4.0)):
		return
	if not AssemblyBoardRenderer.draw_part_preview(self, Rect2(Vector2.ZERO, size), slot_key, part, selected, pulse):
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.08, 0.12, 0.16, 0.8), true)
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.48, 0.66, 0.78, 0.45), false, 1.2)


func _draw_catalog_detail_thumbnail(rect: Rect2) -> bool:
	if rect.size.x <= 16.0 or rect.size.y <= 12.0:
		return false
	var style := PartArt.style_for(slot_key, part, "card")
	var resolved_slot := String(style.get("slot", slot_key)).to_lower()
	var primary := _style_color(style, "primary_color", Color(0.68, 0.78, 0.84, 1.0))
	var accent := _style_color(style, "accent_color", Color(0.9, 0.96, 1.0, 1.0))
	_draw_thumbnail_plate(rect, primary, accent)
	var icon_rect := rect.grow(-4.0)
	match resolved_slot:
		"terminal", "projectile":
			_draw_terminal_thumbnail(icon_rect, style, primary, accent)
		"torso":
			_draw_torso_thumbnail(icon_rect, primary, accent)
		"joint":
			_draw_joint_thumbnail(icon_rect, String(style.get("shape_kind", "")), primary, accent)
		"limb_muscle":
			_draw_limb_thumbnail(icon_rect, String(style.get("shape_kind", "")), primary, accent)
		"barrier_tile", "barrier_panel":
			_draw_barrier_thumbnail(icon_rect, primary, accent)
		"booster":
			_draw_booster_thumbnail(icon_rect, primary, accent)
		"engine":
			_draw_engine_thumbnail(icon_rect, primary, accent)
		"cooling":
			_draw_cooling_thumbnail(icon_rect, primary, accent)
		"module", "special", "ammo", "shield", "software":
			_draw_software_thumbnail(icon_rect, String(style.get("software_icon_kind", "")), primary, accent)
		_:
			_draw_generic_thumbnail(icon_rect, primary, accent)
	return true


func _style_color(style: Dictionary, key: String, fallback: Color) -> Color:
	var raw = style.get(key, fallback)
	if raw is Color:
		return raw
	return fallback


func _thumbnail_plate_fill(primary: Color) -> Color:
	return primary.darkened(0.64).lerp(Color(0.0, 0.0, 0.0, 1.0), 0.18)


func _thumbnail_fill(primary: Color) -> Color:
	return primary.lerp(Color.WHITE, 0.22)


func _thumbnail_stroke(accent: Color) -> Color:
	return accent.lerp(Color.WHITE, 0.28)


func _draw_thumbnail_plate(rect: Rect2, primary: Color, accent: Color) -> void:
	draw_rect(rect, Color(0.012, 0.018, 0.024, 0.98), true)
	draw_rect(rect.grow(-1.0), _thumbnail_plate_fill(primary), true)
	draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2(maxf(3.0, rect.size.x * 0.035), rect.size.y - 4.0)), Color(accent.r, accent.g, accent.b, 0.72), true)
	draw_line(rect.position + Vector2(5.0, rect.size.y - 4.0), rect.position + Vector2(rect.size.x - 5.0, rect.size.y - 4.0), Color(0.86, 0.96, 1.0, 0.14), 1.0)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.5), false, 1.1)


func _p(rect: Rect2, x: float, y: float) -> Vector2:
	return rect.position + Vector2(rect.size.x * x, rect.size.y * y)


func _poly(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		if point is Vector2:
			result.append(point)
	return result


func _draw_poly(points: Array, color: Color, outline: Color = Color.TRANSPARENT, outline_width: float = 1.0) -> void:
	var packed := _poly(points)
	if packed.size() < 3:
		return
	draw_colored_polygon(packed, color)
	if outline.a > 0.0:
		var closed := PackedVector2Array(packed)
		closed.append(packed[0])
		draw_polyline(closed, outline, outline_width, true)


func _draw_terminal_thumbnail(rect: Rect2, style: Dictionary, primary: Color, accent: Color) -> void:
	var profile := String(style.get("terminal_profile", "")).to_lower()
	var key := _image2_part_match_key()
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	var dark := primary.darkened(0.46)
	if _thumbnail_profile_is_ranged(profile, key):
		_draw_ranged_weapon_thumbnail(rect, profile, key, fill, stroke, dark, accent)
		return
	if profile.contains("shield"):
		_draw_shield_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("hammer"):
		_draw_hammer_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("drill"):
		_draw_drill_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("rapier") or profile.contains("lance") or profile.contains("spear") or profile.contains("pierce"):
		_draw_pierce_weapon_thumbnail(rect, profile, fill, stroke, accent)
	elif profile.contains("scythe"):
		_draw_scythe_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("claw"):
		_draw_claw_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("gauntlet") or profile.contains("fist"):
		_draw_gauntlet_weapon_thumbnail(rect, fill, stroke, accent)
	elif profile.contains("chain") or profile.contains("whip"):
		_draw_chain_weapon_thumbnail(rect, fill, stroke, accent)
	else:
		_draw_blade_weapon_thumbnail(rect, profile, fill, stroke, accent)


func _thumbnail_profile_is_ranged(profile: String, key: String) -> bool:
	if profile in ["web_spool_gun", "missile_tube_pod", "prism_laser_gun", "chemical_sprayer", "grenade_launcher", "heavy_launcher", "scoped_sniper", "stocked_rifle", "muzzle"]:
		return true
	for token in ["gun", "rifle", "cannon", "launcher", "missile", "laser", "mortar", "sniper", "sprayer"]:
		if profile.contains(token) or key.contains(token):
			return true
	return false


func _draw_ranged_weapon_thumbnail(rect: Rect2, profile: String, key: String, fill: Color, stroke: Color, dark: Color, accent: Color) -> void:
	var barrel_y := 0.48
	if profile.contains("missile"):
		for y in [0.28, 0.48, 0.68]:
			draw_rect(Rect2(_p(rect, 0.18, y - 0.07), Vector2(rect.size.x * 0.56, rect.size.y * 0.12)), fill, true)
			draw_line(_p(rect, 0.74, y), _p(rect, 0.92, y), stroke, 2.0)
			_draw_poly([_p(rect, 0.92, y - 0.09), _p(rect, 0.98, y), _p(rect, 0.92, y + 0.09)], accent, Color(0, 0, 0, 0.28), 1.0)
		draw_rect(Rect2(_p(rect, 0.13, 0.22), Vector2(rect.size.x * 0.08, rect.size.y * 0.55)), dark, true)
		return
	if profile.contains("web"):
		draw_circle(_p(rect, 0.34, 0.5), minf(rect.size.x, rect.size.y) * 0.24, fill)
		draw_circle(_p(rect, 0.34, 0.5), minf(rect.size.x, rect.size.y) * 0.12, dark)
		draw_line(_p(rect, 0.44, 0.5), _p(rect, 0.9, 0.42), stroke, 2.0)
		draw_line(_p(rect, 0.54, 0.42), _p(rect, 0.68, 0.66), Color(stroke.r, stroke.g, stroke.b, 0.62), 1.2)
		draw_line(_p(rect, 0.54, 0.58), _p(rect, 0.72, 0.32), Color(stroke.r, stroke.g, stroke.b, 0.62), 1.2)
		return
	if profile.contains("sprayer") or key.contains("sprayer"):
		draw_circle(_p(rect, 0.28, 0.52), minf(rect.size.x, rect.size.y) * 0.22, fill)
		draw_rect(Rect2(_p(rect, 0.36, 0.38), Vector2(rect.size.x * 0.3, rect.size.y * 0.24)), fill, true)
		_draw_poly([_p(rect, 0.66, 0.34), _p(rect, 0.9, 0.48), _p(rect, 0.66, 0.64)], dark, stroke, 1.0)
		for x in [0.78, 0.88, 0.96]:
			draw_circle(_p(rect, x, 0.28 + fmod(x * 7.0, 0.34)), 1.3, accent)
		return
	if profile.contains("laser"):
		draw_rect(Rect2(_p(rect, 0.16, 0.39), Vector2(rect.size.x * 0.44, rect.size.y * 0.22)), fill, true)
		_draw_poly([_p(rect, 0.58, 0.29), _p(rect, 0.73, 0.5), _p(rect, 0.58, 0.71), _p(rect, 0.49, 0.5)], dark, stroke, 1.0)
		draw_line(_p(rect, 0.73, 0.5), _p(rect, 0.98, 0.5), accent, 2.4)
		draw_line(_p(rect, 0.77, 0.39), _p(rect, 0.96, 0.39), Color(accent.r, accent.g, accent.b, 0.42), 1.0)
		return
	if profile.contains("grenade") or profile.contains("heavy") or key.contains("cannon"):
		draw_rect(Rect2(_p(rect, 0.16, 0.33), Vector2(rect.size.x * 0.36, rect.size.y * 0.34)), fill, true)
		draw_rect(Rect2(_p(rect, 0.48, 0.38), Vector2(rect.size.x * 0.36, rect.size.y * 0.24)), dark, true)
		draw_rect(Rect2(_p(rect, 0.78, 0.34), Vector2(rect.size.x * 0.12, rect.size.y * 0.32)), stroke, true)
		draw_line(_p(rect, 0.28, 0.7), _p(rect, 0.5, 0.88), stroke, 1.7)
		return
	draw_rect(Rect2(_p(rect, 0.2, 0.39), Vector2(rect.size.x * 0.42, rect.size.y * 0.22)), fill, true)
	if profile.contains("sniper") or key.contains("sniper") or key.contains("rail"):
		draw_rect(Rect2(_p(rect, 0.56, 0.45), Vector2(rect.size.x * 0.36, rect.size.y * 0.08)), stroke, true)
		draw_rect(Rect2(_p(rect, 0.34, 0.24), Vector2(rect.size.x * 0.18, rect.size.y * 0.09)), accent, true)
		draw_line(_p(rect, 0.64, 0.45), _p(rect, 0.92, 0.27), Color(accent.r, accent.g, accent.b, 0.46), 1.0)
	else:
		draw_rect(Rect2(_p(rect, 0.58, 0.43), Vector2(rect.size.x * 0.28, rect.size.y * 0.12)), stroke, true)
		draw_rect(Rect2(_p(rect, 0.36, 0.62), Vector2(rect.size.x * 0.1, rect.size.y * 0.22)), dark, true)
	_draw_poly([_p(rect, 0.18, 0.42), _p(rect, 0.08, 0.54), _p(rect, 0.2, 0.67), _p(rect, 0.31, 0.61), _p(rect, 0.28, 0.43)], dark, stroke, 1.0)
	draw_line(_p(rect, 0.86, barrel_y), _p(rect, 0.98, barrel_y), accent, 1.4)


func _draw_blade_weapon_thumbnail(rect: Rect2, profile: String, fill: Color, stroke: Color, accent: Color) -> void:
	draw_rect(Rect2(_p(rect, 0.08, 0.45), Vector2(rect.size.x * 0.16, rect.size.y * 0.12)), accent, true)
	var broad := profile.contains("greatsword")
	if broad:
		_draw_poly([_p(rect, 0.22, 0.26), _p(rect, 0.9, 0.48), _p(rect, 0.22, 0.76), _p(rect, 0.28, 0.5)], fill, stroke, 1.2)
	else:
		_draw_poly([_p(rect, 0.2, 0.39), _p(rect, 0.93, 0.48), _p(rect, 0.2, 0.61), _p(rect, 0.31, 0.5)], fill, stroke, 1.1)
	draw_line(_p(rect, 0.32, 0.5), _p(rect, 0.86, 0.5), Color(0.0, 0.0, 0.0, 0.26), 1.0)
	if profile.contains("katana"):
		draw_line(_p(rect, 0.36, 0.38), _p(rect, 0.85, 0.44), accent, 1.0)


func _draw_scythe_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	draw_line(_p(rect, 0.18, 0.78), _p(rect, 0.72, 0.22), fill, 3.0)
	_draw_poly([_p(rect, 0.62, 0.13), _p(rect, 0.96, 0.22), _p(rect, 0.74, 0.62), _p(rect, 0.7, 0.36)], fill, stroke, 1.1)
	draw_line(_p(rect, 0.7, 0.32), _p(rect, 0.92, 0.24), accent, 1.2)


func _draw_shield_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	_draw_poly([_p(rect, 0.28, 0.16), _p(rect, 0.76, 0.16), _p(rect, 0.86, 0.48), _p(rect, 0.66, 0.86), _p(rect, 0.32, 0.86), _p(rect, 0.14, 0.48)], fill, stroke, 1.2)
	draw_line(_p(rect, 0.5, 0.22), _p(rect, 0.5, 0.77), Color(0.0, 0.0, 0.0, 0.2), 1.3)
	draw_line(_p(rect, 0.28, 0.48), _p(rect, 0.74, 0.48), accent, 1.2)


func _draw_hammer_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	draw_line(_p(rect, 0.18, 0.78), _p(rect, 0.62, 0.36), fill, 3.0)
	draw_rect(Rect2(_p(rect, 0.55, 0.18), Vector2(rect.size.x * 0.3, rect.size.y * 0.34)), fill, true)
	draw_rect(Rect2(_p(rect, 0.55, 0.18), Vector2(rect.size.x * 0.3, rect.size.y * 0.34)), stroke, false, 1.2)
	draw_line(_p(rect, 0.52, 0.56), _p(rect, 0.7, 0.74), accent, 1.4)


func _draw_pierce_weapon_thumbnail(rect: Rect2, profile: String, fill: Color, stroke: Color, accent: Color) -> void:
	draw_line(_p(rect, 0.12, 0.5), _p(rect, 0.82, 0.5), fill, 2.4 if profile.contains("lance") else 1.7)
	_draw_poly([_p(rect, 0.8, 0.28), _p(rect, 0.98, 0.5), _p(rect, 0.8, 0.72)], fill, stroke, 1.0)
	draw_rect(Rect2(_p(rect, 0.18, 0.42), Vector2(rect.size.x * 0.1, rect.size.y * 0.16)), accent, true)


func _draw_drill_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	_draw_poly([_p(rect, 0.18, 0.28), _p(rect, 0.95, 0.5), _p(rect, 0.18, 0.72)], fill, stroke, 1.0)
	for t in [0.28, 0.44, 0.6, 0.76]:
		draw_line(_p(rect, t, 0.31), _p(rect, t + 0.1, 0.65), Color(accent.r, accent.g, accent.b, 0.76), 1.0)
	draw_rect(Rect2(_p(rect, 0.08, 0.39), Vector2(rect.size.x * 0.14, rect.size.y * 0.22)), accent, true)


func _draw_claw_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	draw_rect(Rect2(_p(rect, 0.14, 0.35), Vector2(rect.size.x * 0.22, rect.size.y * 0.3)), fill, true)
	for y in [0.24, 0.5, 0.76]:
		_draw_poly([_p(rect, 0.34, 0.5), _p(rect, 0.92, y), _p(rect, 0.48, y + (0.08 if y < 0.6 else -0.08))], fill, stroke, 1.0)
	draw_line(_p(rect, 0.24, 0.5), _p(rect, 0.38, 0.5), accent, 1.4)


func _draw_gauntlet_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	draw_rect(Rect2(_p(rect, 0.16, 0.36), Vector2(rect.size.x * 0.28, rect.size.y * 0.32)), fill, true)
	for i in range(4):
		draw_rect(Rect2(_p(rect, 0.42 + float(i) * 0.1, 0.25), Vector2(rect.size.x * 0.08, rect.size.y * 0.28)), fill, true)
	draw_rect(Rect2(_p(rect, 0.42, 0.52), Vector2(rect.size.x * 0.38, rect.size.y * 0.22)), stroke, true)
	draw_line(_p(rect, 0.18, 0.72), _p(rect, 0.76, 0.72), accent, 1.2)


func _draw_chain_weapon_thumbnail(rect: Rect2, fill: Color, stroke: Color, accent: Color) -> void:
	var previous := _p(rect, 0.14, 0.58)
	for i in range(6):
		var point := _p(rect, 0.18 + float(i) * 0.13, 0.5 + sin(float(i) * 1.3) * 0.22)
		draw_line(previous, point, stroke, 1.2)
		draw_circle(point, minf(rect.size.x, rect.size.y) * 0.08, fill)
		previous = point
	_draw_poly([_p(rect, 0.86, 0.28), _p(rect, 0.98, 0.48), _p(rect, 0.84, 0.62)], accent, stroke, 1.0)


func _draw_torso_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	_draw_poly([_p(rect, 0.18, 0.5), _p(rect, 0.36, 0.18), _p(rect, 0.72, 0.2), _p(rect, 0.88, 0.5), _p(rect, 0.72, 0.8), _p(rect, 0.36, 0.82)], fill, stroke, 1.2)
	for point in [_p(rect, 0.28, 0.28), _p(rect, 0.28, 0.72), _p(rect, 0.78, 0.3), _p(rect, 0.78, 0.7)]:
		draw_circle(point, minf(rect.size.x, rect.size.y) * 0.055, accent)
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.15, primary.darkened(0.42))


func _draw_joint_thumbnail(rect: Rect2, shape_kind: String, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	if shape_kind.contains("telescopic") or shape_kind.contains("linear"):
		draw_rect(Rect2(_p(rect, 0.16, 0.42), Vector2(rect.size.x * 0.68, rect.size.y * 0.16)), fill, true)
		draw_rect(Rect2(_p(rect, 0.32, 0.34), Vector2(rect.size.x * 0.36, rect.size.y * 0.32)), primary.darkened(0.38), false, 1.1)
		draw_line(_p(rect, 0.16, 0.5), _p(rect, 0.06, 0.5), accent, 2.0)
		draw_line(_p(rect, 0.84, 0.5), _p(rect, 0.96, 0.5), accent, 2.0)
		return
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.28, fill)
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.13, primary.darkened(0.48))
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(_p(rect, 0.5, 0.5) + dir * minf(rect.size.x, rect.size.y) * 0.24, _p(rect, 0.5, 0.5) + dir * minf(rect.size.x, rect.size.y) * 0.43, stroke, 1.4)


func _draw_limb_thumbnail(rect: Rect2, shape_kind: String, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	if shape_kind.contains("chain") or shape_kind.contains("tentacle") or shape_kind.contains("flex"):
		var previous := _p(rect, 0.12, 0.58)
		for i in range(5):
			var point := _p(rect, 0.18 + float(i) * 0.17, 0.5 + sin(float(i) * 1.2) * 0.2)
			draw_line(previous, point, stroke, 2.0)
			draw_circle(point, minf(rect.size.x, rect.size.y) * 0.1, fill)
			previous = point
		return
	if shape_kind.contains("barrier") or shape_kind.contains("girder") or shape_kind.contains("steel"):
		draw_rect(Rect2(_p(rect, 0.14, 0.38), Vector2(rect.size.x * 0.72, rect.size.y * 0.24)), fill, true)
		for x in [0.22, 0.42, 0.62, 0.82]:
			draw_line(_p(rect, x, 0.34), _p(rect, x - 0.1, 0.68), stroke, 1.0)
		return
	draw_rect(Rect2(_p(rect, 0.16, 0.42), Vector2(rect.size.x * 0.68, rect.size.y * 0.18)), fill, true)
	draw_circle(_p(rect, 0.14, 0.51), minf(rect.size.x, rect.size.y) * 0.13, accent)
	draw_circle(_p(rect, 0.86, 0.51), minf(rect.size.x, rect.size.y) * 0.13, accent)
	draw_line(_p(rect, 0.28, 0.38), _p(rect, 0.7, 0.64), stroke, 1.0)


func _draw_barrier_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	_draw_poly([_p(rect, 0.18, 0.22), _p(rect, 0.82, 0.22), _p(rect, 0.9, 0.5), _p(rect, 0.82, 0.78), _p(rect, 0.18, 0.78), _p(rect, 0.1, 0.5)], Color(fill.r, fill.g, fill.b, 0.82), stroke, 1.2)
	draw_line(_p(rect, 0.22, 0.34), _p(rect, 0.76, 0.34), accent, 1.2)
	draw_line(_p(rect, 0.22, 0.66), _p(rect, 0.76, 0.66), Color(accent.r, accent.g, accent.b, 0.55), 1.0)
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.09, accent)


func _draw_booster_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	for y in [0.36, 0.64]:
		draw_rect(Rect2(_p(rect, 0.3, y - 0.1), Vector2(rect.size.x * 0.36, rect.size.y * 0.2)), fill, true)
		_draw_poly([_p(rect, 0.66, y - 0.12), _p(rect, 0.9, y), _p(rect, 0.66, y + 0.12)], accent, Color(accent.r, accent.g, accent.b, 0.35), 1.0)
	draw_rect(Rect2(_p(rect, 0.16, 0.28), Vector2(rect.size.x * 0.18, rect.size.y * 0.44)), primary.darkened(0.32), true)
	draw_line(_p(rect, 0.22, 0.5), _p(rect, 0.64, 0.5), stroke, 1.0)


func _draw_engine_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.3, fill)
	draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.16, primary.darkened(0.46))
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(_p(rect, 0.5, 0.5), _p(rect, 0.5, 0.5) + dir * minf(rect.size.x, rect.size.y) * 0.36, accent, 1.4)
	draw_rect(Rect2(_p(rect, 0.2, 0.42), Vector2(rect.size.x * 0.18, rect.size.y * 0.16)), Color(accent.r, accent.g, accent.b, 0.58), true)
	draw_rect(Rect2(_p(rect, 0.62, 0.42), Vector2(rect.size.x * 0.18, rect.size.y * 0.16)), Color(accent.r, accent.g, accent.b, 0.58), true)


func _draw_cooling_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	for i in range(5):
		var x := 0.22 + float(i) * 0.12
		_draw_poly([_p(rect, x, 0.22), _p(rect, x + 0.08, 0.22), _p(rect, x + 0.04, 0.78)], fill, Color(accent.r, accent.g, accent.b, 0.35), 1.0)
	draw_line(_p(rect, 0.18, 0.78), _p(rect, 0.86, 0.78), accent, 1.4)
	draw_line(_p(rect, 0.22, 0.34), _p(rect, 0.78, 0.34), Color(0.0, 0.0, 0.0, 0.22), 1.0)


func _draw_software_thumbnail(rect: Rect2, icon_kind: String, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	var stroke := _thumbnail_stroke(accent)
	if icon_kind == "ammo_stack":
		for y in [0.3, 0.5, 0.7]:
			draw_rect(Rect2(_p(rect, 0.24, y - 0.08), Vector2(rect.size.x * 0.5, rect.size.y * 0.12)), fill, true)
			_draw_poly([_p(rect, 0.74, y - 0.08), _p(rect, 0.88, y), _p(rect, 0.74, y + 0.08)], accent, stroke, 0.8)
		return
	if icon_kind in ["soul_star", "source_star", "ether_orbit"]:
		draw_circle(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.2, fill)
		draw_arc(_p(rect, 0.5, 0.5), minf(rect.size.x, rect.size.y) * 0.34, -0.8, PI * 1.35, 24, accent, 1.3, true)
		draw_line(_p(rect, 0.5, 0.18), _p(rect, 0.5, 0.82), Color(accent.r, accent.g, accent.b, 0.38), 1.0)
		return
	draw_rect(Rect2(_p(rect, 0.24, 0.22), Vector2(rect.size.x * 0.52, rect.size.y * 0.56)), fill, true)
	draw_rect(Rect2(_p(rect, 0.24, 0.22), Vector2(rect.size.x * 0.52, rect.size.y * 0.56)), stroke, false, 1.1)
	for x in [0.3, 0.42, 0.54, 0.66]:
		draw_line(_p(rect, x, 0.22), _p(rect, x, 0.08), accent, 1.0)
		draw_line(_p(rect, x, 0.78), _p(rect, x, 0.92), accent, 1.0)
	draw_line(_p(rect, 0.34, 0.5), _p(rect, 0.66, 0.5), primary.darkened(0.44), 1.5)


func _draw_generic_thumbnail(rect: Rect2, primary: Color, accent: Color) -> void:
	var fill := _thumbnail_fill(primary)
	_draw_poly([_p(rect, 0.18, 0.32), _p(rect, 0.74, 0.26), _p(rect, 0.9, 0.5), _p(rect, 0.74, 0.74), _p(rect, 0.18, 0.68)], fill, _thumbnail_stroke(accent), 1.1)
	draw_line(_p(rect, 0.26, 0.5), _p(rect, 0.78, 0.5), accent, 1.1)


func _draw_image2_part_preview(rect: Rect2) -> bool:
	var part_id := _image2_part_id_for_component()
	if part_id == "" or not PartArt.IMAGE2_PART_TEXTURE_PATHS.has(part_id):
		return false
	var art := _image2_part_art(part_id)
	var texture := art.get("texture", null) as Texture2D
	var region: Rect2 = art.get("region", Rect2())
	if texture == null or region.size.x <= 0.0 or region.size.y <= 0.0:
		return false
	var fit := minf(rect.size.x / region.size.x, rect.size.y / region.size.y)
	var draw_size := region.size * fit
	var draw_rect := Rect2(rect.get_center() - draw_size * 0.5, draw_size)
	draw_texture_rect_region(texture, draw_rect, region, Color.WHITE)
	return true


func _image2_part_art(part_id: String) -> Dictionary:
	if image2_part_art_cache.has(part_id):
		return Dictionary(image2_part_art_cache[part_id])
	var path := String(PartArt.IMAGE2_PART_TEXTURE_PATHS[part_id])
	var image := Image.new()
	if image.load(path) != OK:
		image2_part_art_cache[part_id] = {}
		return {}
	var used_rect_i := image.get_used_rect()
	if used_rect_i.size.x <= 0 or used_rect_i.size.y <= 0:
		used_rect_i = Rect2i(Vector2i.ZERO, image.get_size())
	var used_rect := Rect2(
		Vector2(float(used_rect_i.position.x), float(used_rect_i.position.y)),
		Vector2(float(used_rect_i.size.x), float(used_rect_i.size.y))
	)
	var art := {
		"texture": ImageTexture.create_from_image(image),
		"region": used_rect,
	}
	image2_part_art_cache[part_id] = art
	return art


func _image2_part_id_for_component() -> String:
	var style := PartArt.style_for(slot_key, part, "card")
	var resolved_slot := String(style.get("slot", slot_key))
	var shape_kind := String(style.get("shape_kind", "")).to_lower()
	var terminal_profile := String(style.get("terminal_profile", "")).to_lower()
	var software_icon := String(style.get("software_icon_kind", "")).to_lower()
	var material_style := String(style.get("material_style", "")).to_lower()
	var damage_style := String(style.get("damage_style", "")).to_lower()
	var key := _image2_part_match_key()
	if resolved_slot == "torso":
		return "torso_core"
	if resolved_slot == "joint":
		return "telescopic_joint" if shape_kind.contains("telescopic") or key.contains("rail") else "ball_joint"
	if resolved_slot == "limb_muscle":
		if shape_kind.contains("barrier") or shape_kind.contains("girder") or shape_kind.contains("steel") or key.contains("heavy") or key.contains("shield"):
			return "heavy_barrier_strut"
		return "light_forearm_strut"
	if resolved_slot == "booster" or shape_kind == "thruster_nozzle":
		return "thruster_nozzle_pair"
	if resolved_slot == "engine" or software_icon == "engine_core":
		return "engine_reactor_capsule"
	if resolved_slot == "cooling" or software_icon == "cooling_fins":
		return "cooling_fin_module"
	if resolved_slot == "barrier_tile" or shape_kind.contains("plate") or shape_kind.contains("panel") or shape_kind.contains("field") or key.contains("barrier"):
		return "barrier_emitter_plate"
	if resolved_slot == "special" or software_icon in ["soul_star", "source_star", "ether_orbit"]:
		return "soul_source_ether_chip"
	if resolved_slot == "ammo" or software_icon == "ammo_stack" or key.contains("ammo"):
		return "ammo_pod"
	if resolved_slot in ["module", "software"] or shape_kind == "software_chip" or material_style == "software":
		return "sensor_eye_array"
	if resolved_slot == "projectile" or _image2_terminal_profile_is_ranged(terminal_profile) or _image2_key_is_ranged(key):
		if terminal_profile.contains("missile") or terminal_profile.contains("launcher") or key.contains("missile") or key.contains("rocket") or damage_style == "explosive":
			return "missile_tube_pod"
		return "railgun_pod"
	if resolved_slot == "terminal":
		if terminal_profile.contains("shield"):
			return "barrier_emitter_plate"
		if terminal_profile.contains("claw") or key.contains("claw") or key.contains("jaw") or key.contains("talon") or key.contains("pincer"):
			return "paired_pincer_claw"
		return "curved_blade_claw"
	return ""


func _image2_part_match_key() -> String:
	return ("%s %s %s %s %s %s %s %s" % [
		String(part.get("name", "")),
		String(part.get("component_name", "")),
		String(part.get("label", "")),
		String(part.get("shape", "")),
		String(part.get("material_class", "")),
		String(part.get("weapon_family", "")),
		String(part.get("gun_kind", "")),
		String(part.get("projectile_style", "")),
	]).to_lower()


func _image2_terminal_profile_is_ranged(terminal_profile: String) -> bool:
	return terminal_profile in [
		"web_spool_gun",
		"missile_tube_pod",
		"prism_laser_gun",
		"chemical_sprayer",
		"grenade_launcher",
		"heavy_launcher",
		"scoped_sniper",
		"stocked_rifle",
		"muzzle",
	]


func _image2_key_is_ranged(key: String) -> bool:
	for token in ["gun", "rifle", "cannon", "launcher", "missile", "laser", "mortar", "turret", "sniper"]:
		if key.contains(token):
			return true
	return false
