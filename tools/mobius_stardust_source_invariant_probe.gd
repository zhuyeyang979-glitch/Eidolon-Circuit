extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_constant(values: PackedFloat32Array, label: String) -> void:
	if values.size() < 96:
		_fail("%s should expose enough source samples, got %d." % [label, values.size()])
		return
	var first := values[0]
	for value in values:
		if absf(value - first) > 0.0001:
			_fail("%s should be invariant on the Mobius surface source; first=%.4f value=%.4f." % [label, first, value])
			return


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 5.0
	main.camera_center = 5.0
	main.mobius_rotation_state = {"twist_phase": 0.15, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var first: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var first_widths := PackedFloat32Array(first.get("source_widths", PackedFloat32Array()))
	var first_alphas := PackedFloat32Array(first.get("source_alphas", PackedFloat32Array()))
	_assert_constant(first_widths, "source widths")
	_assert_constant(first_alphas, "source alphas")
	main.mobius_rotation_state = {"twist_phase": PI * 0.8, "angle": 0.0}
	main.camera_mobius_s = 8.25
	main.camera_center = 8.25
	main._refresh_mobius_surface_view()
	var second: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var second_widths := PackedFloat32Array(second.get("source_widths", PackedFloat32Array()))
	var second_alphas := PackedFloat32Array(second.get("source_alphas", PackedFloat32Array()))
	_assert_constant(second_widths, "source widths after motion")
	_assert_constant(second_alphas, "source alphas after motion")
	if absf(first_widths[0] - second_widths[0]) > 0.0001:
		_fail("Source width should not change across camera/twist updates.")
		return
	if absf(first_alphas[0] - second_alphas[0]) > 0.0001:
		_fail("Source alpha should not change across camera/twist updates.")
		return
	print("MOBIUS_STARDUST_SOURCE_INVARIANT_PROBE ok width=%.2f alpha=%.3f samples=%d" % [
		first_widths[0],
		first_alphas[0],
		first_widths.size(),
	])
	quit()
