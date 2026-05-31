extends SceneTree

const MainScene := preload("res://scripts/main.gd")

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


func _average_row_alpha(image: Image, y: int) -> float:
	var total := 0.0
	var samples := 0
	for x in range(0, image.get_width(), 8):
		total += image.get_pixel(x, clampi(y, 0, image.get_height() - 1)).a
		samples += 1
	return total / float(maxi(1, samples))


func _init() -> void:
	var image := _load_png(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	if image == null:
		return
	var width := image.get_width()
	var height := image.get_height()
	if width != 4096 or height != 512:
		_fail("Mobius square grid texture should be 4096x512, got %dx%d." % [width, height])
		return
	if width % CELL_PX != 0 or height % CELL_PX != 0:
		_fail("Mobius square grid texture should divide evenly into square cells.")
		return
	var max_alpha := 0.0
	var total_alpha := 0.0
	var samples := 0
	var visible_samples := 0
	var seam_delta := 0.0
	for y in range(0, height, 4):
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(width - 1, y)
		var right_flipped := image.get_pixel(width - 1, height - 1 - y)
		seam_delta = maxf(seam_delta, absf(left.a - right.a))
		seam_delta = maxf(seam_delta, absf(left.a - right_flipped.a))
		for x in range(0, width, 4):
			var alpha := image.get_pixel(x, y).a
			max_alpha = maxf(max_alpha, alpha)
			total_alpha += alpha
			samples += 1
			if alpha > 0.008:
				visible_samples += 1
	var average_alpha := total_alpha / float(maxi(1, samples))
	if max_alpha < 0.16 or max_alpha > 0.235:
		_fail("Mobius square grid texture max alpha should be uniform but restrained, got %.4f." % max_alpha)
		return
	if average_alpha < 0.012 or average_alpha > 0.085:
		_fail("Mobius square grid texture average alpha should stay low, got %.4f." % average_alpha)
		return
	if visible_samples < 4000:
		_fail("Mobius square grid texture should contain enough visible grid samples, got %d." % visible_samples)
		return
	if seam_delta > 0.006:
		_fail("Mobius square grid U seam should be compatible with direct and flipped V sampling; delta=%.4f." % seam_delta)
		return
	var upper_alpha := _average_row_alpha(image, CELL_PX / 2)
	var lower_alpha := _average_row_alpha(image, height - CELL_PX / 2)
	var center_alpha := _average_row_alpha(image, height / 2 + CELL_PX / 2)
	if maxf(absf(upper_alpha - lower_alpha), absf(upper_alpha - center_alpha)) > 0.006:
		_fail("Mobius square grid source brightness should be row-uniform; upper=%.4f lower=%.4f center=%.4f." % [upper_alpha, lower_alpha, center_alpha])
		return
	print("MOBIUS_SURFACE_MESH_TEXTURE_ASSET_PROBE ok square_grid size=%dx%d avg=%.4f max=%.4f seam=%.4f" % [width, height, average_alpha, max_alpha, seam_delta])
	quit()
