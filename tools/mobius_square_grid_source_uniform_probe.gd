extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const EXPECTED_WIDTH := 4096
const EXPECTED_HEIGHT := 512
const CELL_PX := 32


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _load_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		_fail("Missing Mobius square grid texture: %s" % path)
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		_fail("Mobius square grid texture is not a readable PNG: %s" % path)
		return null
	return image


func _mean(values: PackedFloat32Array) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / float(maxi(1, values.size()))


func _max_delta_from(values: PackedFloat32Array, center: float) -> float:
	var result := 0.0
	for value in values:
		result = maxf(result, absf(value - center))
	return result


func _sample_vertical_lines(image: Image) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	var y := CELL_PX / 2
	for x in range(0, image.get_width(), CELL_PX):
		values.append(image.get_pixel(x, y).a)
	return values


func _sample_horizontal_lines(image: Image) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	var x := CELL_PX / 2
	for y in range(0, image.get_height(), CELL_PX):
		values.append(image.get_pixel(x, y).a)
	return values


func _sample_cell_centers(image: Image) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	for y in range(CELL_PX / 2, image.get_height(), CELL_PX):
		for x in range(CELL_PX / 2, image.get_width(), CELL_PX * 8):
			values.append(image.get_pixel(x, y).a)
	return values


func _init() -> void:
	var image := _load_png(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	if image == null:
		return
	if image.get_width() != EXPECTED_WIDTH or image.get_height() != EXPECTED_HEIGHT:
		_fail("Mobius square grid texture should be %dx%d, got %dx%d." % [EXPECTED_WIDTH, EXPECTED_HEIGHT, image.get_width(), image.get_height()])
		return
	if image.get_width() % CELL_PX != 0 or image.get_height() % CELL_PX != 0:
		_fail("Mobius square grid texture dimensions must be exact multiples of the grid cell.")
		return
	var vertical := _sample_vertical_lines(image)
	var horizontal := _sample_horizontal_lines(image)
	var center_alpha := _sample_cell_centers(image)
	var vertical_mean := _mean(vertical)
	var horizontal_mean := _mean(horizontal)
	var background_mean := _mean(center_alpha)
	if vertical_mean < 0.11 or horizontal_mean < 0.11:
		_fail("Mobius square grid source lines should be visibly bright and uniform; vertical=%.4f horizontal=%.4f." % [vertical_mean, horizontal_mean])
		return
	if absf(vertical_mean - horizontal_mean) > 0.010:
		_fail("Mobius square grid source must use matching horizontal and vertical brightness; vertical=%.4f horizontal=%.4f." % [vertical_mean, horizontal_mean])
		return
	if _max_delta_from(vertical, vertical_mean) > 0.006 or _max_delta_from(horizontal, horizontal_mean) > 0.006:
		_fail("Mobius square grid source line brightness should not vary across UV space.")
		return
	if background_mean > 0.004:
		_fail("Mobius square grid cell interiors should stay mostly transparent; got %.4f." % background_mean)
		return
	var seam_delta := 0.0
	for y in range(0, image.get_height(), 7):
		seam_delta = maxf(seam_delta, absf(image.get_pixel(0, y).a - image.get_pixel(image.get_width() - 1, y).a))
		seam_delta = maxf(seam_delta, absf(image.get_pixel(0, y).a - image.get_pixel(image.get_width() - 1, image.get_height() - 1 - y).a))
	if seam_delta > 0.006:
		_fail("Mobius square grid U seam should match direct and half-twist flipped sampling; delta=%.4f." % seam_delta)
		return
	print("MOBIUS_SQUARE_GRID_SOURCE_UNIFORM_PROBE ok cell=%d vertical=%.4f horizontal=%.4f background=%.4f" % [CELL_PX, vertical_mean, horizontal_mean, background_mean])
	quit()
