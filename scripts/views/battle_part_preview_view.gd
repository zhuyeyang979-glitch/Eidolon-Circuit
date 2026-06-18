extends Control
class_name BattlePartPreviewView

const PartArt = preload("res://scripts/part_art.gd")
const PartIdentity = preload("res://scripts/part_identity.gd")


var slot_key := ""
var part := {}
var language := "zh"
var last_component_signature := ""

func set_component(next_slot: String, next_part: Dictionary, next_language: String = "zh") -> void:
	var signature := _component_signature(next_slot, next_part, next_language)
	if signature == last_component_signature:
		return
	last_component_signature = signature
	slot_key = next_slot
	part = next_part.duplicate(true)
	language = next_language
	queue_redraw()

func _component_signature(next_slot: String, next_part: Dictionary, next_language: String) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		next_slot,
		next_language,
		String(next_part.get("name", "")),
		str(next_part.get("cost", "")),
		str(next_part.get("mass", "")),
		str(next_part.get("length", "")),
		str(next_part.get("radius", "")),
		str(next_part.get("shape", "")),
		str(next_part.get("material_visual", "")),
		PartIdentity.signature_for(next_slot, next_part, next_language),
	]

func _draw() -> void:
	var font := ThemeDB.get_fallback_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.006, 0.012, 0.018, 0.96), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.88, 1.0, 0.22), false, 1.4)
	var title := "战斗外观预览" if language == "zh" else "BATTLE ART PREVIEW"
	draw_string(font, Vector2(12.0, 18.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 12, Color(0.72, 0.95, 1.0, 0.94))
	_draw_identity_overlays(font)
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var scale := minf(size.x / 280.0, size.y / 110.0)
	var material := _material_color()
	var accent := _damage_color()
	if slot_key == "joint":
		_draw_joint(center, scale, material, accent)
	elif slot_key == "limb_muscle":
		_draw_limb(center, scale, material, accent)
	elif slot_key == "booster":
		_draw_booster(center, scale, material, accent)
	elif slot_key == "muscle" and (bool(part.get("is_torso", false)) or String(part.get("material_class", "")).to_lower() == "torso"):
		_draw_torso(center, scale, material, accent)
	elif slot_key == "muscle" and (bool(part.get("projectile", false)) or String(part.get("material_class", "")) in ["gun", "missile_launcher", "web_gun"]):
		_draw_gun(center, scale, material, accent)
	elif slot_key == "muscle" and _identity_subcode() == "SHD":
		_draw_shield(center, scale, material, accent)
	elif slot_key == "muscle" and String(part.get("damage_type", "")) == "tear":
		_draw_blade(center, scale, material, accent)
	elif slot_key == "muscle" and String(part.get("damage_type", "")) == "pierce":
		_draw_pierce(center, scale, material, accent)
	elif slot_key == "muscle":
		_draw_blunt(center, scale, material, accent)
	else:
		_draw_software(center, scale, material, accent)
	draw_string(font, Vector2(12.0, size.y - 10.0), _caption(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 10, Color(0.9, 0.92, 0.96, 0.9))

func _material_color() -> Color:
	if slot_key in ["special", "module", "engine", "cooling"]:
		return Color(0.26, 0.82, 1.0, 1.0)
	return PartArt.material_color_for(_material_style(), slot_key)

func _material_style() -> String:
	var style_part := part.duplicate(true)
	style_part["slot"] = slot_key
	return PartArt.material_style_for(style_part)

func _damage_color() -> Color:
	match String(part.get("projectile_damage_type", part.get("damage_type", ""))):
		"laser":
			return Color(0.28, 0.82, 1.0, 1.0)
		"chemical":
			return Color(0.58, 1.0, 0.3, 1.0)
		"bullet":
			return Color(1.0, 0.78, 0.32, 1.0)
		"tear":
			return Color(1.0, 0.28, 0.48, 1.0)
		"pierce":
			return Color(0.94, 0.96, 1.0, 1.0)
		"blunt":
			return Color(1.0, 0.52, 0.24, 1.0)
	return Color(0.92, 0.9, 0.82, 1.0)

func _caption() -> String:
	var kind := "软件/插槽件" if language == "zh" else "software slot"
	if slot_key == "joint":
		kind = "关节：旋转/伸缩" if language == "zh" else "joint: rotate/extend"
	elif slot_key == "limb_muscle":
		kind = "普通肢体：两端接关节" if language == "zh" else "limb: two joint ends"
	elif slot_key == "muscle":
		kind = "武器/躯干肌肉" if language == "zh" else "weapon or torso muscle"
	elif slot_key == "booster":
		kind = "推进器：喷口与火焰同轴" if language == "zh" else "thruster: aligned flame"
	var identity := PartIdentity.identity_for(slot_key, part, language)
	var name_text := String(part.get("name", slot_key.to_upper()))
	if int(identity.get("scan_level", PartIdentity.FULL_SCAN)) < PartIdentity.FULL_SCAN:
		name_text = String(identity.get("family", name_text))
	return "%s | %s | %s" % [String(identity.get("code", "")), name_text, kind]

func _draw_identity_overlays(font: Font) -> void:
	if part.is_empty():
		return
	var identity := PartIdentity.identity_for(slot_key, part, language)
	var accent: Color = identity.get("color", _damage_color())
	var code_width := minf(116.0, maxf(82.0, size.x * 0.36))
	var code_rect := Rect2(Vector2(size.x - code_width - 10.0, 6.0), Vector2(code_width, 18.0))
	_draw_identity_chip(font, code_rect, String(identity.get("code", "")), accent, 9, 0.92)
	var tags: Array = identity.get("tags", [])
	var y := size.y - 31.0
	var x := 12.0
	for i in range(mini(tags.size(), 3)):
		var tag := String(tags[i])
		var tag_w := clampf(float(tag.length()) * 7.0 + 13.0, 34.0, 74.0)
		_draw_identity_chip(font, Rect2(Vector2(x, y), Vector2(tag_w, 14.0)), tag, accent, 8, 0.62)
		x += tag_w + 5.0
	var scan := String(identity.get("scan_label", ""))
	if scan != "":
		var scan_w := clampf(float(scan.length()) * 7.0 + 14.0, 34.0, 58.0)
		_draw_identity_chip(font, Rect2(Vector2(size.x - scan_w - 10.0, size.y - 31.0), Vector2(scan_w, 14.0)), scan, accent, 8, 0.52)

func _draw_identity_chip(font: Font, rect: Rect2, text_value: String, accent: Color, font_size: int, alpha: float) -> void:
	if text_value == "":
		return
	var bg := accent.darkened(0.62)
	bg.a = 0.66 * alpha
	var border := accent.lerp(Color.WHITE, 0.22)
	border.a = 0.62 * alpha
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.5 * alpha), true)
	draw_rect(rect.grow(-1.0), bg, true)
	draw_rect(rect, border, false, 1.0)
	draw_string(font, rect.position + Vector2(5.0, rect.size.y - 4.0), _trim(text_value, maxi(3, int(rect.size.x / 6.0))), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 9.0, font_size, Color(0.92, 0.98, 1.0, 0.96 * alpha))

func _draw_capsule(a: Vector2, b: Vector2, radius: float, color: Color, outline: Color) -> void:
	draw_line(a, b, outline, radius * 2.35)
	draw_circle(a, radius * 1.18, outline)
	draw_circle(b, radius * 1.18, outline)
	draw_line(a, b, color, radius * 1.8)
	draw_circle(a, radius * 0.9, color)
	draw_circle(b, radius * 0.9, color)

func _draw_connector(pos: Vector2, radius: float, color: Color) -> void:
	draw_circle(pos, radius, Color(0.02, 0.04, 0.06, 1.0))
	draw_circle(pos, radius * 0.64, color)
	draw_circle(pos, radius * 0.34, Color(0.0, 0.0, 0.0, 0.55))

func _rect_points(center: Vector2, axis: Vector2, length: float, width: float) -> PackedVector2Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	return PackedVector2Array([
		center - forward * length * 0.5 - right * width * 0.5,
		center + forward * length * 0.5 - right * width * 0.5,
		center + forward * length * 0.5 + right * width * 0.5,
		center - forward * length * 0.5 + right * width * 0.5,
	])

func _draw_preview_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], color, width)

func _draw_material_rect_marks(center: Vector2, axis: Vector2, length: float, width: float, material_style: String, alpha: float = 1.0) -> void:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	match material_style:
		"metal":
			draw_line(center - forward * length * 0.42 - right * width * 0.24, center + forward * length * 0.42 - right * width * 0.1, Color(1.0, 1.0, 1.0, 0.38 * alpha), maxf(1.0, width * 0.12))
			draw_line(center - forward * length * 0.46 + right * width * 0.38, center + forward * length * 0.46 + right * width * 0.38, Color(0.02, 0.05, 0.07, 0.46 * alpha), maxf(1.0, width * 0.08))
		"wood":
			for i in range(4):
				var t := -0.34 + float(i) * 0.22
				var yoff := right * width * t
				draw_line(center - forward * length * 0.42 + yoff, center + forward * length * 0.42 + yoff + right * sin(float(i)) * width * 0.04, Color(0.18, 0.1, 0.04, 0.5 * alpha), maxf(1.0, width * 0.06))
			draw_circle(center + forward * length * 0.08 + right * width * 0.12, maxf(1.4, width * 0.09), Color(0.12, 0.06, 0.02, 0.38 * alpha))
		"ceramic":
			for i in range(3):
				var p0 := center - forward * length * (0.34 - float(i) * 0.18) + right * width * (0.18 - float(i) * 0.12)
				var p1 := p0 + forward * length * 0.16 + right * width * (0.18 if i % 2 == 0 else -0.18)
				draw_line(p0, p1, Color(0.18, 0.17, 0.15, 0.38 * alpha), maxf(1.0, width * 0.045))
			for i in range(7):
				var p := center + forward * length * (-0.42 + float(i) * 0.14) + right * width * (0.28 * sin(float(i) * 1.7))
				draw_circle(p, maxf(0.8, width * 0.025), Color(1.0, 1.0, 1.0, 0.28 * alpha))
		"fur":
			for i in range(10):
				var t := -0.48 + float(i) / 9.0 * 0.96
				for side in [-1.0, 1.0]:
					var base: Vector2 = center + forward * length * t + right * width * 0.5 * float(side)
					draw_line(base, base + right * side * width * 0.22 + forward * width * 0.06 * sin(float(i)), Color(0.92, 0.76, 0.48, 0.46 * alpha), maxf(1.0, width * 0.045))

func _draw_joint(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var axis := Vector2.RIGHT
	draw_circle(center, 32.0 * scale, Color(0.0, 0.0, 0.0, 0.72))
	draw_circle(center, 24.0 * scale, material)
	_draw_material_rect_marks(center, axis, 48.0 * scale, 16.0 * scale, _material_style(), 0.62)
	draw_arc(center, 39.0 * scale, -PI * 0.75, PI * 0.75, 28, accent, 3.0 * scale)
	_draw_connector(center - axis * 27.0 * scale, 8.0 * scale, accent)
	_draw_connector(center + axis * 27.0 * scale, 8.0 * scale, accent)

func _draw_limb(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var half := 58.0 * scale * (0.72 + clampf(float(part.get("length", 0.55)), 0.25, 1.35))
	var width := 25.0 * scale
	var beam := _rect_points(center, Vector2.RIGHT, half * 2.0, width)
	draw_colored_polygon(beam, material.darkened(0.08))
	_draw_preview_outline(beam, Color(0.0, 0.0, 0.0, 0.82), 2.0 * scale)
	_draw_material_rect_marks(center, Vector2.RIGHT, half * 1.82, width * 0.86, _material_style(), 0.95)
	draw_line(center - Vector2(half, 0.0), center + Vector2(half, 0.0), accent.lerp(Color.WHITE, 0.2), 1.6 * scale)
	_draw_connector(center - Vector2(half, 0.0), 9.0 * scale, accent)
	_draw_connector(center + Vector2(half, 0.0), 9.0 * scale, accent)

func _draw_gun(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var back := center - Vector2(78.0, 0.0) * scale
	var front := center + Vector2(80.0, 0.0) * scale
	_draw_capsule(back, center + Vector2(24.0, 0.0) * scale, 17.0 * scale, material, Color(0.0, 0.0, 0.0, 0.82))
	draw_rect(Rect2(center + Vector2(20.0, -8.0) * scale, Vector2(64.0, 16.0) * scale), material.darkened(0.2), true)
	draw_line(center + Vector2(36.0, 0.0) * scale, front, accent, 5.0 * scale)
	draw_line(front, front + Vector2(46.0, 0.0) * scale, Color(accent.r, accent.g, accent.b, 0.34), 2.0 * scale)
	_draw_connector(back, 10.0 * scale, accent)
	_draw_gun_variant_details(center, scale, material, accent)

func _draw_blade(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var pts := PackedVector2Array([center - Vector2(80.0, 15.0) * scale, center + Vector2(52.0, -24.0) * scale, center + Vector2(92.0, 0.0) * scale, center + Vector2(50.0, 24.0) * scale])
	draw_colored_polygon(pts, material.lerp(accent, 0.2))
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, accent, 2.4 * scale)
	_draw_connector(center - Vector2(92.0, 0.0) * scale, 10.0 * scale, accent)
	_draw_blade_variant_details(center, scale, accent)

func _draw_pierce(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	_draw_capsule(center - Vector2(86.0, 0.0) * scale, center + Vector2(48.0, 0.0) * scale, 8.0 * scale, material, Color(0.0, 0.0, 0.0, 0.8))
	draw_colored_polygon(PackedVector2Array([center + Vector2(48.0, -16.0) * scale, center + Vector2(102.0, 0.0) * scale, center + Vector2(48.0, 16.0) * scale]), accent)
	_draw_connector(center - Vector2(90.0, 0.0) * scale, 9.0 * scale, accent)
	_draw_pierce_variant_details(center, scale, accent)

func _draw_blunt(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	_draw_capsule(center - Vector2(86.0, 0.0) * scale, center + Vector2(38.0, 0.0) * scale, 12.0 * scale, material, Color(0.0, 0.0, 0.0, 0.8))
	draw_circle(center + Vector2(72.0, 0.0) * scale, 28.0 * scale, Color(0.0, 0.0, 0.0, 0.78))
	draw_circle(center + Vector2(72.0, 0.0) * scale, 22.0 * scale, material.lerp(accent, 0.28))
	draw_arc(center + Vector2(72.0, 0.0) * scale, 24.0 * scale, -1.2, 1.2, 16, accent, 3.0 * scale)
	_draw_connector(center - Vector2(92.0, 0.0) * scale, 9.0 * scale, accent)
	for y in [-13.0, 0.0, 13.0]:
		draw_line(center + Vector2(54.0, y) * scale, center + Vector2(88.0, y - 4.0) * scale, Color(0.0, 0.0, 0.0, 0.32), 1.4 * scale)

func _draw_shield(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(-64.0, -42.0) * scale,
		center + Vector2(42.0, -38.0) * scale,
		center + Vector2(82.0, 0.0) * scale,
		center + Vector2(42.0, 38.0) * scale,
		center + Vector2(-64.0, 42.0) * scale,
		center + Vector2(-92.0, 0.0) * scale,
	])
	draw_colored_polygon(pts, material.lerp(accent, 0.16))
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, accent, 2.2 * scale)
	draw_line(center + Vector2(-54.0, 0.0) * scale, center + Vector2(60.0, 0.0) * scale, Color(0.0, 0.0, 0.0, 0.28), 2.0 * scale)
	draw_arc(center + Vector2(-8.0, 0.0) * scale, 36.0 * scale, -1.2, 1.2, 24, accent.lerp(Color.WHITE, 0.18), 2.0 * scale)
	_draw_connector(center - Vector2(92.0, 0.0) * scale, 10.0 * scale, accent)

func _draw_gun_variant_details(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var subcode := _identity_subcode()
	var key := _part_visual_key()
	match subcode:
		"SNP":
			draw_rect(Rect2(center + Vector2(-34.0, -28.0) * scale, Vector2(48.0, 10.0) * scale), accent.lerp(Color.WHITE, 0.22), true)
			draw_line(center + Vector2(36.0, -10.0) * scale, center + Vector2(124.0, -26.0) * scale, Color(accent.r, accent.g, accent.b, 0.42), 1.4 * scale)
			draw_line(center + Vector2(58.0, 6.0) * scale, center + Vector2(118.0, 6.0) * scale, accent.lerp(Color.WHITE, 0.1), 1.6 * scale)
		"RFL":
			draw_rect(Rect2(center + Vector2(-8.0, 12.0) * scale, Vector2(18.0, 34.0) * scale), material.darkened(0.36), true)
			draw_rect(Rect2(center + Vector2(-8.0, 12.0) * scale, Vector2(18.0, 34.0) * scale), accent.lerp(Color.WHITE, 0.08), false, 1.0 * scale)
			for x in [38.0, 52.0, 66.0]:
				draw_line(center + Vector2(x, -9.0) * scale, center + Vector2(x, 9.0) * scale, Color(0.0, 0.0, 0.0, 0.28), 1.1 * scale)
		"LSR":
			var prism := PackedVector2Array([
				center + Vector2(20.0, 0.0) * scale,
				center + Vector2(44.0, -24.0) * scale,
				center + Vector2(70.0, 0.0) * scale,
				center + Vector2(44.0, 24.0) * scale,
			])
			draw_colored_polygon(prism, accent.lerp(Color.WHITE, 0.32))
			draw_polyline(PackedVector2Array([prism[0], prism[1], prism[2], prism[3], prism[0]]), Color.WHITE.lerp(accent, 0.35), 1.4 * scale)
			for x in [-16.0, 2.0, 84.0]:
				draw_arc(center + Vector2(x, 0.0) * scale, 15.0 * scale, -PI * 0.42, PI * 0.42, 18, accent, 1.5 * scale)
		"SPR":
			draw_circle(center + Vector2(-38.0, 22.0) * scale, 18.0 * scale, material.darkened(0.32))
			draw_arc(center + Vector2(-38.0, 22.0) * scale, 18.0 * scale, 0.0, TAU, 24, accent, 1.5 * scale)
			draw_line(center + Vector2(-20.0, 18.0) * scale, center + Vector2(58.0, -4.0) * scale, accent.lerp(Color.WHITE, 0.1), 2.0 * scale)
			for i in range(5):
				draw_circle(center + Vector2(104.0 + float(i) * 12.0, -18.0 + sin(float(i)) * 18.0) * scale, 2.4 * scale, Color(accent.r, accent.g, accent.b, 0.62))
		"ARC":
			for x in [4.0, 24.0, 44.0]:
				draw_line(center + Vector2(x, -16.0) * scale, center + Vector2(x, 16.0) * scale, Color(0.0, 0.0, 0.0, 0.32), 2.0 * scale)
			draw_arc(center + Vector2(70.0, 0.0) * scale, 18.0 * scale, 0.0, TAU, 28, accent.lerp(Color.WHITE, 0.12), 2.0 * scale)
		"WEB":
			for off in [-16.0, 16.0]:
				draw_circle(center + Vector2(-22.0, off) * scale, 14.0 * scale, material.darkened(0.38))
				draw_arc(center + Vector2(-22.0, off) * scale, 11.0 * scale, 0.0, TAU, 22, accent, 1.3 * scale)
			draw_line(center + Vector2(48.0, 0.0) * scale, center + Vector2(124.0, -24.0) * scale, Color(accent.r, accent.g, accent.b, 0.42), 1.4 * scale)
			draw_line(center + Vector2(70.0, -8.0) * scale, center + Vector2(114.0, 18.0) * scale, Color(accent.r, accent.g, accent.b, 0.32), 1.0 * scale)
		_:
			if key.contains("missile"):
				for off in [-10.0, 10.0]:
					draw_line(center + Vector2(18.0, off) * scale, center + Vector2(82.0, off) * scale, accent, 2.0 * scale)

func _draw_blade_variant_details(center: Vector2, scale: float, accent: Color) -> void:
	var key := _part_visual_key()
	if key.contains("razor") or key.contains("feeler") or key.contains("antenna"):
		for i in range(6):
			var x := -10.0 + float(i) * 18.0
			draw_line(center + Vector2(x, -10.0) * scale, center + Vector2(x + 9.0, -22.0) * scale, accent, 1.6 * scale)
	elif key.contains("wing") or key.contains("feather"):
		for i in range(5):
			draw_line(center + Vector2(-42.0, 12.0) * scale, center + Vector2(-8.0 + float(i) * 22.0, -20.0 + float(i) * 4.0) * scale, Color(accent.r, accent.g, accent.b, 0.66), 1.3 * scale)
	elif key.contains("tail") or key.contains("machete"):
		draw_arc(center + Vector2(20.0, 0.0) * scale, 48.0 * scale, -0.86, 0.54, 28, accent.lerp(Color.WHITE, 0.12), 2.0 * scale)
	else:
		draw_line(center + Vector2(-30.0, 0.0) * scale, center + Vector2(70.0, 0.0) * scale, Color(0.0, 0.0, 0.0, 0.26), 1.5 * scale)

func _draw_pierce_variant_details(center: Vector2, scale: float, accent: Color) -> void:
	var key := _part_visual_key()
	if key.contains("needle") or key.contains("nano"):
		draw_line(center + Vector2(-60.0, -6.0) * scale, center + Vector2(100.0, -6.0) * scale, Color(accent.r, accent.g, accent.b, 0.42), 1.2 * scale)
		draw_circle(center + Vector2(102.0, 0.0) * scale, 2.8 * scale, accent.lerp(Color.WHITE, 0.28))
		return
	if key.contains("horn") or key.contains("talon"):
		draw_arc(center + Vector2(48.0, 0.0) * scale, 32.0 * scale, -0.68, 0.68, 22, accent, 1.7 * scale)
	for y in [-13.0, 13.0]:
		draw_line(center + Vector2(-8.0, 0.0) * scale, center + Vector2(28.0, y) * scale, accent, 1.5 * scale)

func _draw_torso(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var length := 190.0 * scale
	var front_width := 70.0 * scale
	var rear_width := 132.0 * scale
	var pts := _preview_saddle_polygon(center, Vector2.RIGHT, length, front_width, rear_width)
	draw_colored_polygon(pts, material.darkened(0.04))
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, accent, 2.2 * scale)
	_draw_material_rect_marks(center, Vector2.RIGHT, length * 0.48, rear_width * 0.44, _material_style(), 0.86)
	draw_line(center + Vector2(length * 0.5, -front_width * 0.42), center + Vector2(length * 0.5, front_width * 0.42), accent.lerp(Color.WHITE, 0.25), 2.0 * scale)
	for port_pos in _preview_saddle_port_positions(center, Vector2.RIGHT, PartArt.torso_saddle_port_count(part), length, front_width, rear_width):
		_draw_connector(port_pos, 7.0 * scale, accent)

func _preview_saddle_polygon(center: Vector2, axis: Vector2, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var pts := PackedVector2Array()
	for local in PartArt.torso_hull_local_points(part, length, front_width, rear_width):
		var p: Vector2 = local
		pts.append(center + forward * p.x + right * p.y)
	return pts

func _preview_saddle_port_positions(center: Vector2, axis: Vector2, port_count: int, length: float, front_width: float, rear_width: float) -> Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var positions: Array = []
	for local in PartArt.torso_hull_port_local_offsets(part, port_count, length, front_width, rear_width):
		var p: Vector2 = local
		positions.append(center + forward * p.x + right * p.y)
	return positions

func _draw_booster(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-76.0, -22.0) * scale, center + Vector2(32.0, -18.0) * scale, center + Vector2(72.0, 0.0) * scale, center + Vector2(32.0, 18.0) * scale, center + Vector2(-76.0, 22.0) * scale]), material)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-74.0, -14.0) * scale, center + Vector2(-140.0, 0.0) * scale, center + Vector2(-74.0, 14.0) * scale]), Color(accent.r, accent.g, accent.b, 0.46))
	_draw_connector(center + Vector2(70.0, 0.0) * scale, 8.0 * scale, accent)
	var family := ("%s %s" % [String(part.get("thruster_family", "")), _part_visual_key()]).to_lower()
	if family.contains("dash") or family.contains("burst") or family.contains("overburn"):
		draw_colored_polygon(PackedVector2Array([center + Vector2(-76.0, -24.0) * scale, center + Vector2(-172.0, 0.0) * scale, center + Vector2(-76.0, 24.0) * scale]), _booster_flame_color())
		for y in [-12.0, 0.0, 12.0]:
			draw_line(center + Vector2(-42.0, y) * scale, center + Vector2(42.0, y * 0.5) * scale, accent.lerp(Color.WHITE, 0.12), 1.4 * scale)
	elif family.contains("brake") or family.contains("reverse"):
		for y in [-18.0, 0.0, 18.0]:
			draw_line(center + Vector2(20.0, y) * scale, center + Vector2(94.0, y * 0.6) * scale, accent, 2.2 * scale)
			draw_colored_polygon(PackedVector2Array([center + Vector2(26.0, y - 6.0) * scale, center + Vector2(8.0, y) * scale, center + Vector2(26.0, y + 6.0) * scale]), _booster_flame_color())
	else:
		for y in [-10.0, 10.0]:
			draw_line(center + Vector2(-54.0, y) * scale, center + Vector2(46.0, y) * scale, accent.lerp(Color.WHITE, 0.08), 1.4 * scale)

func _draw_software(center: Vector2, scale: float, material: Color, accent: Color) -> void:
	var card := Rect2(center - Vector2(78.0, 30.0) * scale, Vector2(156.0, 60.0) * scale)
	draw_rect(card, Color(0.03, 0.08, 0.12, 1.0), true)
	draw_rect(card, accent, false, 2.0 * scale)
	draw_circle(center, 18.0 * scale, Color(accent.r, accent.g, accent.b, 0.22))
	draw_circle(center, 7.0 * scale, accent)
	draw_line(center - Vector2(54.0, 0.0) * scale, center + Vector2(54.0, 0.0) * scale, material, 2.0 * scale)

func _identity_subcode() -> String:
	return String(PartIdentity.identity_for(slot_key, part, language).get("subcode", "")).to_upper()

func _part_visual_key() -> String:
	return ("%s %s %s %s %s %s %s %s %s" % [
		String(part.get("name", "")),
		String(part.get("component_name", "")),
		String(part.get("shape", "")),
		String(part.get("material_class", "")),
		String(part.get("weapon_family", "")),
		String(part.get("gun_kind", "")),
		String(part.get("projectile_style", "")),
		String(part.get("projectile_behavior", "")),
		String(part.get("module_visual_family", "")),
	]).to_lower()

func _booster_flame_color() -> Color:
	var flame := String(part.get("flame_color", "")).to_lower()
	var family := String(part.get("thruster_family", "")).to_lower()
	if flame.contains("red") or family.contains("overburn") or family.contains("burst") or family.contains("dash"):
		return Color(1.0, 0.16, 0.08, 0.92)
	if flame.contains("yellow") or family.contains("sustain") or family.contains("cruise"):
		return Color(1.0, 0.86, 0.18, 0.92)
	return Color(0.24, 0.72, 1.0, 0.92)

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."
