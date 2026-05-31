extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _min_max_depth_indices(depths: PackedFloat32Array) -> Array:
	var min_index := 0
	var max_index := 0
	for i in range(depths.size()):
		if depths[i] < depths[min_index]:
			min_index = i
		if depths[i] > depths[max_index]:
			max_index = i
	return [min_index, max_index]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 2.0
	main.camera_center = 2.0
	main.mobius_rotation_state = {"twist_phase": 1.1, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var bands: Array = snapshot.get("bands", [])
	if bands.size() != 2:
		_fail("Near/far wave check requires two stardust bands.")
		return
	for band in bands:
		var band_dict: Dictionary = band
		var depths := PackedFloat32Array(band_dict.get("depths", PackedFloat32Array()))
		var widths := PackedFloat32Array(band_dict.get("widths", PackedFloat32Array()))
		var alphas := PackedFloat32Array(band_dict.get("alphas", PackedFloat32Array()))
		var radii := PackedFloat32Array(band_dict.get("radii", PackedFloat32Array()))
		if depths.size() < 48:
			_fail("Stardust band does not expose enough depth samples.")
			return
		var indices := _min_max_depth_indices(depths)
		var far_index := int(indices[0])
		var near_index := int(indices[1])
		if widths[near_index] <= widths[far_index]:
			_fail("Near stardust samples should be wider than far samples.")
			return
		if alphas[near_index] <= alphas[far_index]:
			_fail("Near stardust samples should be brighter than far samples.")
			return
		if radii[near_index] <= radii[far_index]:
			_fail("Near stardust particles should be larger than far particles.")
			return
	print("MOBIUS_STARDUST_NEAR_FAR_WAVE_PROBE ok bands=%d" % bands.size())
	quit()
