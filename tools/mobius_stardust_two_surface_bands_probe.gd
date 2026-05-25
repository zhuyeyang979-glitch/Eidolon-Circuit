extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _average_y(points: PackedVector2Array) -> float:
	var total := 0.0
	for point in points:
		total += point.y
	return total / float(maxi(1, points.size()))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.mobius_rotation_state = {"twist_phase": 0.35, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var bands: Array = snapshot.get("bands", [])
	if bands.size() != 2:
		_fail("Mobius stardust should expose exactly two surface bands.")
		return
	var upper: Dictionary = bands[0]
	var lower: Dictionary = bands[1]
	if float(upper.get("lane_ratio", 0.0)) >= 0.0 or float(lower.get("lane_ratio", 0.0)) <= 0.0:
		_fail("Mobius stardust bands should sample upper/lower surface lanes.")
		return
	var upper_points := PackedVector2Array(upper.get("points", PackedVector2Array()))
	var lower_points := PackedVector2Array(lower.get("points", PackedVector2Array()))
	if upper_points.size() < 48 or lower_points.size() < 48:
		_fail("Each Mobius stardust band needs enough samples for a soft ribbon.")
		return
	if _average_y(upper_points) >= _average_y(lower_points):
		_fail("Upper stardust band should read above the lower band on the default camera.")
		return
	print("MOBIUS_STARDUST_TWO_SURFACE_BANDS_PROBE ok upper=%d lower=%d" % [upper_points.size(), lower_points.size()])
	quit()
