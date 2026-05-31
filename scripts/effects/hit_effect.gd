class_name HitEffect
extends Node2D

var lifetime := 0.0
var max_lifetime := 0.62
var tier := 0
var damage_type := "blunt"
var nullified := false
var projectile_style := ""
var label := ""
var vfx_texture: Texture2D

func setup(effect_tier: int, effect_damage_type: String, was_nullified: bool, next_projectile_style: String = "", next_vfx_texture: Texture2D = null, block_label: String = "NULL") -> void:
	tier = clampi(effect_tier, 0, 3)
	damage_type = effect_damage_type
	nullified = was_nullified
	projectile_style = next_projectile_style
	vfx_texture = next_vfx_texture
	if nullified:
		label = block_label
	elif tier <= 0:
		label = ""
	else:
		label = ["", "SMALL", "MEDIUM", "LARGE"][tier]
	max_lifetime = 0.78 if nullified or tier >= 3 else 0.58
	lifetime = max_lifetime
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	position.y -= delta * 18.0
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(lifetime / max_lifetime, 0.0, 1.0)
	var inv := 1.0 - ratio
	var color := _effect_color()
	var radius := 18.0 + inv * (28.0 + float(tier) * 13.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, Color(color.r, color.g, color.b, ratio), 2.0 + float(tier) * 1.2)
	if tier >= 2 or nullified:
		draw_arc(Vector2.ZERO, radius * 0.62, -PI * 0.3, PI * 1.25, 26, Color(1.0, 1.0, 1.0, ratio * 0.82), 2.0)
	for i in range(4 + tier * 3):
		var angle := TAU * float(i) / float(4 + tier * 3) + inv * 1.6
		var p0 := Vector2(cos(angle), sin(angle)) * (radius * 0.42)
		var p1 := Vector2(cos(angle), sin(angle)) * (radius * (0.78 + inv * 0.38))
		draw_line(p0, p1, Color(color.r, color.g, color.b, ratio * 0.8), 2.0)
	_draw_vfx_cell(_hit_vfx_index(), Vector2.ZERO, Vector2.ONE * radius * 2.25, 0.0, ratio * 0.86)
	_draw_damage_motif(color, ratio, radius, inv)
	if label != "":
		draw_string(ThemeDB.get_fallback_font(), Vector2(-32.0, -radius - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, 96.0, 13, Color(1.0, 1.0, 1.0, ratio))

func _draw_vfx_cell(index: int, center: Vector2, draw_size: Vector2, angle: float, alpha: float) -> void:
	if vfx_texture == null:
		return
	var cell := vfx_texture.get_size() / 4.0
	var safe_index := clampi(index, 0, 15)
	var region := Rect2(Vector2(float(safe_index % 4) * cell.x, float(safe_index / 4) * cell.y), cell)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect_region(vfx_texture, Rect2(-draw_size * 0.5, draw_size), region, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _hit_vfx_index() -> int:
	if nullified or projectile_style == "shield":
		return 9
	if projectile_style == "blind":
		return 15
	if projectile_style in ["guided", "web", "web_snap"]:
		return 14
	if projectile_style == "missile":
		return 1
	if projectile_style == "spray":
		return 5
	if projectile_style == "true_bullet":
		return 1
	if projectile_style == "bullet_hell":
		return 0
	match damage_type:
		"bullet":
			return 1
		"chemical":
			return 5
		"laser":
			return 3
		"tear":
			return 6
		"blunt":
			return 7
		"pierce":
			return 8
	return 10

func _draw_damage_motif(color: Color, alpha: float, radius: float, inv: float) -> void:
	if projectile_style == "web" or projectile_style == "web_snap":
		for i in range(7):
			var angle := TAU * float(i) / 7.0 + inv * 0.45
			var p0 := Vector2(cos(angle), sin(angle)) * radius * 0.16
			var p1 := Vector2(cos(angle + sin(inv * TAU + float(i)) * 0.22), sin(angle + sin(inv * TAU + float(i)) * 0.22)) * radius * (0.72 + float(i % 3) * 0.08)
			draw_line(p0, p1, Color(0.86, 0.98, 1.0, 0.74 * alpha), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 18, Color(0.86, 0.98, 1.0, 0.54 * alpha), 2.0)
		if projectile_style == "web_snap":
			draw_line(Vector2(-radius, -radius * 0.22), Vector2(radius, radius * 0.18), Color(1.0, 0.32, 0.24, 0.86 * alpha), 4.0)
		return
	if projectile_style == "blind":
		draw_circle(Vector2.ZERO, radius * 0.72, Color(0.0, 0.0, 0.018, 0.78 * alpha))
		for i in range(10):
			var angle := TAU * float(i) / 10.0 - inv * 1.2
			var p0 := Vector2(cos(angle), sin(angle)) * radius * 0.18
			var p1 := Vector2(cos(angle), sin(angle)) * radius * 1.05
			draw_line(p1, p0, Color(0.4, 0.56, 1.0, 0.26 * alpha), 3.0)
		draw_arc(Vector2.ZERO, radius * 0.9, 0.0, TAU, 34, Color(0.68, 0.82, 1.0, 0.46 * alpha), 2.0)
		return
	if projectile_style == "shield":
		draw_arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 6, Color(0.86, 0.94, 1.0, 0.82 * alpha), 5.0)
		draw_arc(Vector2.ZERO, radius * 1.12, -0.7, 0.9, 18, Color(1.0, 0.84, 0.24, 0.72 * alpha), 3.0)
		return
	if projectile_style == "guided":
		for i in range(4):
			var t := float(i) / 3.0
			var p := Vector2(lerpf(-radius, radius, t), sin(t * TAU + inv * TAU) * radius * 0.28)
			draw_circle(p, 5.0 + float(i), Color(0.32, 1.0, 0.78, 0.62 * alpha))
		draw_polyline(PackedVector2Array([Vector2(-radius, 0.0), Vector2(-radius * 0.2, -radius * 0.32), Vector2(radius * 0.42, radius * 0.18), Vector2(radius, -radius * 0.08)]), Color(0.32, 1.0, 0.78, 0.7 * alpha), 3.0)
		return
	if projectile_style == "missile":
		for i in range(8):
			var angle := TAU * float(i) / 8.0 + inv * 1.4
			var p := Vector2(cos(angle), sin(angle)) * radius * (0.22 + float(i % 3) * 0.1)
			draw_circle(p, 5.0 + float(i % 2) * 4.0, Color(1.0, 0.5, 0.12, 0.28 * alpha))
		draw_arc(Vector2.ZERO, radius * 1.18, 0.0, TAU, 42, Color(1.0, 0.8, 0.18, 0.58 * alpha), 4.0)
		return
	if projectile_style == "true_bullet":
		draw_line(Vector2(-radius * 1.05, 0.0), Vector2(radius * 1.05, 0.0), Color(1.0, 0.92, 0.58, 0.9 * alpha), 3.0)
		draw_line(Vector2(0.0, -radius * 0.62), Vector2(0.0, radius * 0.62), Color(1.0, 0.68, 0.22, 0.6 * alpha), 2.0)
		draw_arc(Vector2.ZERO, radius * (0.52 + inv * 0.36), 0.0, TAU, 36, Color(1.0, 0.72, 0.18, 0.62 * alpha), 2.0)
		for i in range(5):
			var p := Vector2(-radius * 0.5 + float(i) * radius * 0.25, sin(float(i) * 1.7 + inv * TAU) * radius * 0.12)
			draw_circle(p, 2.0 + float(i % 2), Color(1.0, 0.95, 0.62, 0.62 * alpha))
		return
	if projectile_style == "bullet_hell":
		for i in range(7):
			var angle := -0.75 + float(i) * 0.25 + inv * 0.24
			var p0 := Vector2(cos(angle), sin(angle)) * radius * 0.12
			var p1 := Vector2(cos(angle), sin(angle)) * radius * (0.56 + float(i % 3) * 0.11)
			draw_line(p0, p1, Color(1.0, 0.54, 0.1, 0.78 * alpha), 2.0)
			draw_circle(p1, 2.5 + float(i % 2), Color(1.0, 0.92, 0.44, 0.58 * alpha))
		draw_arc(Vector2.ZERO, radius * 0.44, -0.4, PI + 0.4, 18, Color(1.0, 0.78, 0.22, 0.42 * alpha), 3.0)
		return
	if projectile_style == "spray":
		for i in range(16):
			var angle := TAU * float(i) / 16.0 + sin(inv * TAU + float(i)) * 0.18
			var dist := radius * (0.18 + float((i * 5) % 11) / 12.0)
			var p := Vector2(cos(angle), sin(angle)) * dist
			draw_circle(p, 3.0 + float(i % 5) * 1.4, Color(0.62, 1.0, 0.12, 0.42 * alpha))
		draw_arc(Vector2.ZERO, radius * 0.72, PI * 0.18, PI * 1.74, 28, Color(0.28, 1.0, 0.44, 0.72 * alpha), 5.0)
		draw_arc(Vector2.ZERO, radius * 0.38, -PI * 0.4, PI * 0.8, 18, Color(1.0, 0.92, 0.24, 0.52 * alpha), 3.0)
		return
	match damage_type:
		"tear":
			for i in range(3):
				var offset := -16.0 + float(i) * 16.0
				draw_line(Vector2(-radius * 0.95, offset + radius * 0.28), Vector2(radius * 0.82, offset - radius * 0.42), Color(0.92, 1.0, 0.88, 0.86 * alpha), 4.0 - float(i) * 0.5)
				draw_line(Vector2(-radius * 0.62, offset + radius * 0.1), Vector2(radius * 0.68, offset - radius * 0.5), Color(color.r, color.g, color.b, 0.5 * alpha), 1.0)
		"blunt":
			draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 6, Color(1.0, 1.0, 1.0, 0.68 * alpha), 5.0)
			for i in range(6):
				var angle := TAU * float(i) / 6.0
				var p := Vector2(cos(angle), sin(angle)) * radius * 0.42
				draw_rect(Rect2(p - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color(color.r, color.g, color.b, 0.68 * alpha), true)
		"pierce":
			for i in range(5):
				var angle := -0.35 + float(i) * 0.17
				var tip := Vector2(cos(angle), sin(angle)) * radius
				draw_line(-tip * 0.25, tip, Color(1.0, 1.0, 1.0, 0.82 * alpha), 2.0)
				draw_line(-tip * 0.05, tip * 0.7, Color(color.r, color.g, color.b, 0.58 * alpha), 1.0)
		"chemical":
			for i in range(12):
				var angle := TAU * float(i) / 12.0 + inv * 0.7
				var dist := radius * (0.22 + float((i * 7) % 9) / 12.0)
				var p := Vector2(cos(angle), sin(angle)) * dist
				draw_circle(p, 3.0 + float(i % 4) * 1.6, Color(0.78, 1.0, 0.12, 0.34 * alpha))
			draw_arc(Vector2.ZERO, radius * 0.48, PI * 0.15, PI * 1.55, 22, Color(0.2, 1.0, 0.46, 0.62 * alpha), 5.0)
		"laser":
			for i in range(3):
				var y := -8.0 + float(i) * 8.0
				draw_line(Vector2(-radius * 1.05, y), Vector2(radius * 1.05, y + sin(inv * TAU + float(i)) * 5.0), Color(0.75, 0.95, 1.0, 0.9 * alpha), 2.0)
			draw_circle(Vector2.ZERO, 7.0, Color(1.0, 1.0, 1.0, 0.82 * alpha))
		"bullet":
			for i in range(9):
				var angle := TAU * float(i) / 9.0 - inv * 1.4
				var p0 := Vector2(cos(angle), sin(angle)) * radius * 0.18
				var p1 := Vector2(cos(angle), sin(angle)) * radius * 0.72
				draw_line(p0, p1, Color(1.0, 0.7, 0.22, 0.82 * alpha), 2.0)
			draw_circle(Vector2.ZERO, 5.0 + tier * 2.0, Color(1.0, 1.0, 1.0, 0.74 * alpha))

func _effect_color() -> Color:
	if nullified:
		return Color(0.3, 0.36, 0.42, 1.0)
	var tier_palette: Array = [Color(0.82, 0.86, 0.9, 1.0), Color(0.34, 0.9, 1.0, 1.0), Color(1.0, 0.82, 0.18, 1.0), Color(1.0, 0.2, 0.12, 1.0)]
	var tier_color: Color = tier_palette[tier]
	if projectile_style == "web" or projectile_style == "web_snap":
		return tier_color.lerp(Color(0.72, 0.96, 1.0, 1.0), 0.55)
	if projectile_style == "blind":
		return tier_color.lerp(Color(0.12, 0.1, 0.32, 1.0), 0.6)
	match damage_type:
		"bullet":
			return tier_color.lerp(Color(1.0, 0.08, 0.05, 1.0), 0.3)
		"chemical":
			return tier_color.lerp(Color(0.9, 1.0, 0.12, 1.0), 0.35)
		"laser":
			return tier_color.lerp(Color(0.2, 0.78, 1.0, 1.0), 0.35)
		"pierce":
			return tier_color.lerp(Color(0.95, 0.24, 1.0, 1.0), 0.3)
		"tear":
			return tier_color.lerp(Color(0.2, 1.0, 0.58, 1.0), 0.3)
	return tier_color
