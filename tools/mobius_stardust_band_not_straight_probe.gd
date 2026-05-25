extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _range(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var low := values[0]
	var high := values[0]
	for value in values:
		low = minf(low, value)
		high = maxf(high, value)
	return high - low


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 4.0
	main.camera_center = 4.0
	main.mobius_rotation_state = {"twist_phase": 0.85, "angle": 0.0}
	main._refresh_mobius_surface_view()

	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var points := PackedVector2Array(snapshot.get("points", PackedVector2Array()))
	var widths := PackedFloat32Array(snapshot.get("widths", PackedFloat32Array()))
	if points.size() < 24:
		_fail("Mobius stardust band should have enough samples to form a curve.")
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	var y_range := max_y - min_y
	var chord := points[points.size() - 1] - points[0]
	var chord_len := maxf(0.001, chord.length())
	var max_chord_error := 0.0
	for point in points:
		var error := absf((point - points[0]).cross(chord)) / chord_len
		max_chord_error = maxf(max_chord_error, error)
	var width_range := _range(widths)
	if y_range < 18.0:
		_fail("Mobius stardust band should visibly arc instead of staying horizontal; y_range=%.3f." % y_range)
	if max_chord_error < 10.0:
		_fail("Mobius stardust band should not collapse to a straight line; chord_error=%.3f." % max_chord_error)
	if width_range < 2.0:
		_fail("Mobius stardust band should vary thickness; width_range=%.3f." % width_range)
	print("MOBIUS_STARDUST_BAND_NOT_STRAIGHT_PROBE ok y_range=%.3f chord_error=%.3f width_range=%.3f" % [
		y_range,
		max_chord_error,
		width_range,
	])
	quit()
