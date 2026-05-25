extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _average_motion(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var count := mini(a.size(), b.size())
	if count <= 0:
		return 0.0
	var total := 0.0
	for i in range(count):
		total += a[i].distance_to(b[i])
	return total / float(count)


func _max_width_delta(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var count := mini(a.size(), b.size())
	var delta := 0.0
	for i in range(count):
		delta = maxf(delta, absf(a[i] - b[i]))
	return delta


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 2.0
	main.camera_center = 2.0

	main.mobius_rotation_state = {"twist_phase": 0.0, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var first: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var first_points := PackedVector2Array(first.get("points", PackedVector2Array()))
	var first_widths := PackedFloat32Array(first.get("widths", PackedFloat32Array()))

	main.mobius_rotation_state = {"twist_phase": 1.35, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var second: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var second_points := PackedVector2Array(second.get("points", PackedVector2Array()))
	var second_widths := PackedFloat32Array(second.get("widths", PackedFloat32Array()))

	if first_points.size() != second_points.size() or first_points.size() < 24:
		_fail("Mobius stardust band should keep a stable sample budget across twist updates.")
	var motion := _average_motion(first_points, second_points)
	var width_delta := _max_width_delta(first_widths, second_widths)
	if motion < 3.0:
		_fail("Mobius stardust band should visibly twist over phase changes; motion=%.3f." % motion)
	if width_delta < 0.25:
		_fail("Mobius stardust band should vary thickness over phase changes; width_delta=%.3f." % width_delta)
	print("MOBIUS_STARDUST_BAND_TWIST_PROBE ok motion=%.3f width_delta=%.3f" % [
		motion,
		width_delta,
	])
	quit()
