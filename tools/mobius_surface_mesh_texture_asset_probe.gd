extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _load_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		_fail("Missing Mobius surface mesh texture: %s" % path)
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		_fail("Mobius surface mesh texture is not a readable PNG: %s" % path)
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
		_fail("Mobius surface mesh texture should be 4096x512, got %dx%d." % [width, height])
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
	if max_alpha < 0.08 or max_alpha > 0.175:
		_fail("Mobius mesh texture max alpha should stay visible but restrained, got %.4f." % max_alpha)
		return
	if average_alpha < 0.003 or average_alpha > 0.040:
		_fail("Mobius mesh texture average alpha should stay low, got %.4f." % average_alpha)
		return
	if visible_samples < 2800:
		_fail("Mobius mesh texture should contain enough visible net/star samples, got %d." % visible_samples)
		return
	if seam_delta > 0.035:
		_fail("Mobius mesh texture U seam should be compatible with direct and flipped V sampling; delta=%.4f." % seam_delta)
		return
	var upper_alpha := _average_row_alpha(image, int(round(float(height) * 0.24)))
	var lower_alpha := _average_row_alpha(image, int(round(float(height) * 0.76)))
	var center_alpha := _average_row_alpha(image, int(round(float(height) * 0.50)))
	if minf(upper_alpha, lower_alpha) <= center_alpha * 1.20:
		_fail("Mobius mesh texture should keep stronger upper/lower surface lanes than the center; upper=%.4f lower=%.4f center=%.4f." % [upper_alpha, lower_alpha, center_alpha])
		return
	print("MOBIUS_SURFACE_MESH_TEXTURE_ASSET_PROBE ok size=%dx%d avg=%.4f max=%.4f seam=%.4f" % [width, height, average_alpha, max_alpha, seam_delta])
	quit()
