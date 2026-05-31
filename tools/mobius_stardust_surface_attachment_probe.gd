extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 4.0
	main.camera_center = 4.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.92, "angle": 0.0}
	main._refresh_mobius_surface_view()
	var visual_config: Dictionary = main.mobius_stardust_band_view.config.duplicate(true)
	visual_config["twist_visual_enabled"] = true
	visual_config["local_rectangular_projection"] = false
	visual_config["depth_contrast"] = maxf(1.18, float(visual_config.get("depth_contrast", 1.0)))
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	var bands: Array = snapshot.get("bands", [])
	if bands.size() != 2:
		_fail("Two stardust bands are required before attachment can be checked.")
		return
	var worst_error := 0.0
	var checked := 0
	for band in bands:
		var points := PackedVector2Array(Dictionary(band).get("points", PackedVector2Array()))
		var coords := PackedVector2Array(Dictionary(band).get("surface_coords", PackedVector2Array()))
		var source_widths := PackedFloat32Array(Dictionary(band).get("source_widths", PackedFloat32Array()))
		var display_widths := PackedFloat32Array(Dictionary(band).get("display_widths", PackedFloat32Array()))
		if points.size() != coords.size() or points.size() < 48:
			_fail("Stardust band should keep point and surface coord samples aligned.")
			return
		if source_widths.size() != coords.size() or display_widths.size() != coords.size():
			_fail("Stardust source/display samples should stay aligned with surface coords.")
			return
		var step := maxi(1, points.size() / 12)
		for i in range(0, points.size(), step):
			var projection := MobiusWorld.project_to_screen(coords[i], main._mobius_camera_coord(), visual_config, main.mobius_rotation_state)
			var expected: Vector2 = projection.get("position", Vector2.ZERO)
			worst_error = maxf(worst_error, expected.distance_to(points[i]))
			checked += 1
	if worst_error > 0.05:
		_fail("Stardust samples should stay attached to projected Mobius surface lanes; worst_error=%.4f." % worst_error)
		return
	print("MOBIUS_STARDUST_SURFACE_ATTACHMENT_PROBE ok checked=%d worst_error=%.4f" % [checked, worst_error])
	quit()
