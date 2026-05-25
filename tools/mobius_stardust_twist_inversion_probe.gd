extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _average_point_motion(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var count := mini(a.size(), b.size())
	var total := 0.0
	for i in range(count):
		total += a[i].distance_to(b[i])
	return total / float(maxi(1, count))


func _average_band_gap(snapshot: Dictionary) -> float:
	var bands: Array = snapshot.get("bands", [])
	if bands.size() != 2:
		return 0.0
	var upper := PackedVector2Array(Dictionary(bands[0]).get("points", PackedVector2Array()))
	var lower := PackedVector2Array(Dictionary(bands[1]).get("points", PackedVector2Array()))
	var count := mini(upper.size(), lower.size())
	var total := 0.0
	for i in range(count):
		total += absf(lower[i].y - upper[i].y)
	return total / float(maxi(1, count))


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
	main.mobius_rotation_state = {"twist_phase": PI, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var second: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var first_bands: Array = first.get("bands", [])
	var second_bands: Array = second.get("bands", [])
	if first_bands.size() != 2 or second_bands.size() != 2:
		_fail("Twist probe requires two surface-attached bands.")
		return
	var motion := 0.0
	for band_index in range(2):
		var first_points := PackedVector2Array(Dictionary(first_bands[band_index]).get("points", PackedVector2Array()))
		var second_points := PackedVector2Array(Dictionary(second_bands[band_index]).get("points", PackedVector2Array()))
		motion += _average_point_motion(first_points, second_points)
	motion *= 0.5
	var gap_delta := absf(_average_band_gap(first) - _average_band_gap(second))
	if motion < 5.0:
		_fail("Twist phase should visibly move surface stardust; motion=%.3f." % motion)
		return
	if gap_delta < 2.0:
		_fail("Twist phase should change the near/far band gap; gap_delta=%.3f." % gap_delta)
		return
	print("MOBIUS_STARDUST_TWIST_INVERSION_PROBE ok motion=%.3f gap_delta=%.3f" % [motion, gap_delta])
	quit()
