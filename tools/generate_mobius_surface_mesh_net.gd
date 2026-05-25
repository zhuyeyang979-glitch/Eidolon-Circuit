extends SceneTree

const OUT_PATH := "res://assets/generated/mobius_surface_mesh_net.png"
const WIDTH := 4096
const HEIGHT := 512
const CELL_PX := 32
const LINE_HALF_WIDTH := 0.88
const GLOW_HALF_WIDTH := 3.2
const MAX_ALPHA := 0.155
const CORE_ALPHA := 0.140
const GLOW_ALPHA := 0.040


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _distance_to_wrapped_grid(pixel_center: float, period: float) -> float:
	var wrapped := fposmod(pixel_center, period)
	return minf(wrapped, period - wrapped)


func _smooth_line(distance: float, half_width: float, feather: float) -> float:
	if distance <= half_width:
		return 1.0
	var outer := half_width + maxf(0.001, feather)
	if distance >= outer:
		return 0.0
	var t := (distance - half_width) / maxf(0.001, feather)
	return 1.0 - t * t * (3.0 - 2.0 * t)


func _generate_image() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y in range(HEIGHT):
		var py := float(y) + 0.5
		var dy := _distance_to_wrapped_grid(py, float(CELL_PX))
		for x in range(WIDTH):
			var px := float(x) + 0.5
			var dx := _distance_to_wrapped_grid(px, float(CELL_PX))
			var core := maxf(
				_smooth_line(dx, LINE_HALF_WIDTH, 0.72),
				_smooth_line(dy, LINE_HALF_WIDTH, 0.72)
			)
			var glow := maxf(
				_smooth_line(dx, GLOW_HALF_WIDTH, 1.8),
				_smooth_line(dy, GLOW_HALF_WIDTH, 1.8)
			)
			var alpha := minf(MAX_ALPHA, maxf(core * CORE_ALPHA, glow * GLOW_ALPHA))
			if alpha <= 0.0001:
				continue
			image.set_pixel(x, y, Color(0.58, 0.86, 1.0, alpha))
	return image


func _init() -> void:
	var output_dir := ProjectSettings.globalize_path("res://assets/generated")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := _generate_image()
	var err := image.save_png(OUT_PATH)
	if err != OK:
		_fail("Failed to save Mobius square grid texture: %s err=%d" % [OUT_PATH, err])
		return
	print("MOBIUS_SURFACE_SQUARE_GRID_GENERATED %s %dx%d cell=%d" % [OUT_PATH, WIDTH, HEIGHT, CELL_PX])
	quit()
