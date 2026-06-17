extends Control
class_name BackdropView

var mode := "menu"
var background_texture: Texture2D


func set_mode(next_mode: String) -> void:
	mode = next_mode
	queue_redraw()


func set_background_texture(texture: Texture2D) -> void:
	background_texture = texture
	queue_redraw()


func _draw() -> void:
	var base := Color(0.008, 0.014, 0.02, 0.94)
	if mode == "menu":
		base = Color(0.0, 0.004, 0.008, 1.0)
	elif mode == "editor":
		base = Color(0.012, 0.018, 0.022, 0.92)
	elif mode == "settings":
		base = Color(0.012, 0.014, 0.024, 0.93)
	elif mode == "battle":
		base = Color(0.01, 0.013, 0.017, 0.3)
	draw_rect(Rect2(Vector2.ZERO, size), base, true)
	if background_texture != null:
		var art_alpha := 0.34
		if mode == "menu":
			art_alpha = 0.86
		elif mode == "editor":
			art_alpha = 0.26
		elif mode == "battle":
			art_alpha = 0.28
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, size), false, Color(1.0, 1.0, 1.0, art_alpha))
	if mode == "menu":
		_draw_menu_key_art_veil()
	var grid_color := Color(0.26, 0.86, 1.0, 0.08)
	var warm_color := Color(1.0, 0.78, 0.24, 0.11)
	for x in range(-80, int(size.x) + 160, 64):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x) + 140.0, size.y), grid_color, 1.0)
	for y in range(42, int(size.y), 58):
		draw_line(Vector2(0.0, float(y)), Vector2(size.x, float(y)), Color(0.68, 0.74, 0.8, 0.055), 1.0)
	for i in range(9):
		var y0 := 96.0 + float(i) * 54.0
		var points := PackedVector2Array()
		for p in range(42):
			var t := float(p) / 41.0
			points.append(Vector2(lerpf(42.0, size.x - 42.0, t), y0 + sin(t * TAU + float(i) * 0.7) * 18.0))
		draw_polyline(points, warm_color if i % 2 == 0 else grid_color, 2.0)
	for i in range(12):
		var x0 := 70.0 + float(i) * 96.0
		draw_rect(Rect2(Vector2(x0, 604.0 + float(i % 3) * 12.0), Vector2(42.0, 3.0)), Color(0.9, 0.96, 1.0, 0.12), true)


func _draw_menu_key_art_veil() -> void:
	var left_w := size.x * 0.45
	draw_rect(Rect2(Vector2.ZERO, Vector2(left_w, size.y)), Color(0.0, 0.006, 0.014, 0.68), true)
	draw_rect(Rect2(Vector2(left_w, 0.0), Vector2(size.x * 0.18, size.y)), Color(0.0, 0.006, 0.014, 0.32), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 112.0)), Color(0.0, 0.006, 0.014, 0.26), true)
	draw_rect(Rect2(Vector2(0.0, size.y - 96.0), Vector2(size.x, 96.0)), Color(0.0, 0.006, 0.014, 0.38), true)
