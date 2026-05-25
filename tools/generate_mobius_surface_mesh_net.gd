extends SceneTree

const OUT_PATH := "res://assets/generated/mobius_surface_mesh_net.png"
const WIDTH := 4096
const HEIGHT := 512
const MAX_ALPHA := 0.165


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _clamp_alpha(color: Color) -> Color:
	return Color(color.r, color.g, color.b, clampf(color.a, 0.0, MAX_ALPHA))


func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
		return
	var src := _clamp_alpha(color)
	if src.a <= 0.0001:
		return
	var dst := image.get_pixel(x, y)
	var out_a := src.a + dst.a * (1.0 - src.a)
	if out_a <= 0.0001:
		return
	var out_r := (src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / out_a
	var out_g := (src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / out_a
	var out_b := (src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / out_a
	image.set_pixel(x, y, Color(out_r, out_g, out_b, minf(MAX_ALPHA, out_a)))


func _draw_disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := maxf(0.35, radius)
	var min_x := int(floor(center.x - r - 1.0))
	var max_x := int(ceil(center.x + r + 1.0))
	var min_y := int(floor(center.y - r - 1.0))
	var max_y := int(ceil(center.y + r + 1.0))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			if distance > r:
				continue
			var falloff := pow(1.0 - distance / r, 1.65)
			_blend_pixel(image, x, y, Color(color.r, color.g, color.b, color.a * falloff))


func _draw_line(image: Image, from_point: Vector2, to_point: Vector2, width_px: float, color: Color) -> void:
	var distance := from_point.distance_to(to_point)
	var steps := maxi(1, int(ceil(distance * 0.72)))
	var radius := maxf(0.35, width_px * 0.5)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		_draw_disc(image, from_point.lerp(to_point, t), radius, color)


func _strand_y(v_base: float, x: float, phase: float, amp: float, cycles: float) -> float:
	var u := x / float(WIDTH)
	var wave := sin((u * cycles + phase) * TAU)
	wave += sin((u * cycles * 0.5 - phase * 0.73) * TAU) * 0.32
	return clampf((v_base + wave * amp) * float(HEIGHT), 0.0, float(HEIGHT - 1))


func _draw_wave_strand(image: Image, v_base: float, phase: float, amp: float, cycles: float, width_px: float, color: Color) -> void:
	var previous := Vector2(0.0, _strand_y(v_base, 0.0, phase, amp, cycles))
	var step_px := 20
	for x in range(step_px, WIDTH + step_px, step_px):
		var xx := mini(x, WIDTH - 1)
		var current := Vector2(float(xx), _strand_y(v_base, float(xx), phase, amp, cycles))
		_draw_line(image, previous, current, width_px, color)
		previous = current


func _draw_symmetric_strand_pair(image: Image, v_base: float, phase: float, amp: float, cycles: float, width_px: float, color: Color) -> void:
	_draw_wave_strand(image, v_base, phase, amp, cycles, width_px, color)
	_draw_wave_strand(image, 1.0 - v_base, -phase, amp, cycles, width_px, color)


func _draw_rib(image: Image, x_center: float, phase: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 14
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var v := lerpf(0.16, 0.84, t)
		var sway := sin(t * PI + phase) * 18.0
		points.append(Vector2(x_center + sway, v * float(HEIGHT)))
	for i in range(points.size() - 1):
		_draw_line(image, points[i], points[i + 1], 1.6, color)


func _draw_diagonal_thread(image: Image, x0: float, v0: float, x1: float, v1: float, phase: float, color: Color) -> void:
	var segments := 18
	var previous := Vector2(fposmod(x0, float(WIDTH)), v0 * float(HEIGHT))
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var x := lerpf(x0, x1, t)
		var v := lerpf(v0, v1, t) + sin(t * PI + phase) * 0.035
		var current := Vector2(fposmod(x, float(WIDTH)), clampf(v, 0.05, 0.95) * float(HEIGHT))
		if absf(current.x - previous.x) < float(WIDTH) * 0.5:
			_draw_line(image, previous, current, 1.2, color)
		previous = current


func _add_dust_nodes(image: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xEC105A
	for i in range(720):
		var x := rng.randf_range(0.0, float(WIDTH - 1))
		var lane_pick := rng.randi_range(0, 3)
		var lane := 0.20
		if lane_pick == 1:
			lane = 0.34
		elif lane_pick == 2:
			lane = 0.66
		elif lane_pick == 3:
			lane = 0.80
		var mirrored_lane := lane if rng.randf() < 0.5 else 1.0 - lane
		var y := _strand_y(mirrored_lane, x, rng.randf_range(-0.12, 0.12), rng.randf_range(0.012, 0.024), rng.randf_range(1.0, 3.0))
		var radius := rng.randf_range(0.8, 2.4)
		var alpha := rng.randf_range(0.026, 0.105)
		_draw_disc(image, Vector2(x, y), radius, Color(0.78, 0.92, 1.0, alpha))


func _add_corner_compatible_seam(image: Image) -> void:
	for y in range(HEIGHT):
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(WIDTH - 1, y)
		var flipped_right := image.get_pixel(WIDTH - 1, HEIGHT - 1 - y)
		var merged := Color(
			(left.r + right.r + flipped_right.r) / 3.0,
			(left.g + right.g + flipped_right.g) / 3.0,
			(left.b + right.b + flipped_right.b) / 3.0,
			minf(MAX_ALPHA, (left.a + right.a + flipped_right.a) / 3.0)
		)
		image.set_pixel(0, y, merged)
		image.set_pixel(WIDTH - 1, y, merged)
		image.set_pixel(WIDTH - 1, HEIGHT - 1 - y, merged)


func _generate_image() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var faint := Color(0.28, 0.52, 0.74, 0.010)
	for lane in [0.21, 0.32, 0.68, 0.79]:
		_draw_wave_strand(image, float(lane), 0.0, 0.018, 1.0, 18.0, faint)
	for index in range(9):
		var v := lerpf(0.14, 0.40, float(index) / 8.0)
		var alpha := lerpf(0.032, 0.055, 1.0 - absf(v - 0.27) / 0.18)
		_draw_symmetric_strand_pair(image, v, float(index) * 0.071, 0.018 + float(index % 3) * 0.004, 1.0 + float(index % 4), 1.5 + float(index % 2) * 0.45, Color(0.52, 0.82, 1.0, alpha))
	for index in range(6):
		var v := lerpf(0.18, 0.36, float(index) / 5.0)
		_draw_symmetric_strand_pair(image, v, float(index) * 0.113, 0.009, 4.0, 0.9, Color(0.84, 0.96, 1.0, 0.047))
	for x in range(0, WIDTH + 1, 256):
		_draw_rib(image, float(x), float(x) / float(WIDTH) * TAU, Color(0.45, 0.72, 1.0, 0.030))
	for x in range(0, WIDTH, 512):
		_draw_diagonal_thread(image, float(x), 0.18, float(x + 512), 0.82, float(x) * 0.01, Color(0.64, 0.86, 1.0, 0.027))
		_draw_diagonal_thread(image, float(x), 0.82, float(x + 512), 0.18, float(x) * 0.008, Color(0.42, 0.68, 1.0, 0.020))
	_add_dust_nodes(image)
	_add_corner_compatible_seam(image)
	return image


func _init() -> void:
	var output_dir := ProjectSettings.globalize_path("res://assets/generated")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := _generate_image()
	var err := image.save_png(OUT_PATH)
	if err != OK:
		_fail("Failed to save Mobius mesh texture: %s err=%d" % [OUT_PATH, err])
		return
	print("MOBIUS_SURFACE_MESH_NET_GENERATED %s %dx%d" % [OUT_PATH, WIDTH, HEIGHT])
	quit()
