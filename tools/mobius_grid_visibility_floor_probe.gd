extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _load_grid_image() -> Image:
	var bytes := FileAccess.get_file_as_bytes(MainScene.MOBIUS_SURFACE_MESH_TEXTURE_PATH)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		_fail("Could not load Mobius grid texture.")
		return null
	return image


func _mean_line_alpha(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), 32):
		for x in range(0, image.get_width(), 128):
			total += image.get_pixel(x, y).a
			count += 1
	return total / float(maxi(1, count))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible.")
		return
	var config: Dictionary = main.mobius_strip_surface_view.config
	var image := _load_grid_image()
	if image == null:
		return
	var source_alpha := _mean_line_alpha(image)
	var alpha_gain := float(config.get("surface_alpha_gain", 0.0))
	var grid_far := float(config.get("grid_far_brightness", 0.0))
	var far_line_alpha := source_alpha * alpha_gain * grid_far
	if grid_far < 0.50:
		_fail("Grid far/valley brightness floor is too low; got %.3f." % grid_far)
		return
	if far_line_alpha < 0.10:
		_fail("Far/valley grid line alpha can disappear; estimated %.4f from source=%.4f gain=%.2f brightness=%.2f." % [far_line_alpha, source_alpha, alpha_gain, grid_far])
		return
	if float(config.get("grid_near_brightness", 1.0)) >= float(config.get("unit_surface_far_brightness", 0.0)):
		_fail("Grid should remain below foreground units after raising floor.")
		return
	print("MOBIUS_GRID_VISIBILITY_FLOOR_PROBE ok far_alpha=%.4f grid=%.2f/%.2f" % [far_line_alpha, grid_far, float(config.get("grid_near_brightness", 0.0))])
	quit()
