extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {
		"twist_phase": 0.46,
		"twist_speed": 0.12,
		"twist_amplitude": 0.20,
		"pivot": Vector2(MainScene.RING_LENGTH * 0.25, 1.0),
	}
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Battle should render the Mobius surface view.")
		return
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Linear elevation cue should live on the world-grid battlefield surface.")
		return
	if not bool(snapshot.get("local_rectangular_projection", false)):
		_fail("Linear elevation cue must keep combat projection locally rectangular.")
		return
	if not bool(snapshot.get("linear_elevation_visual_enabled", false)):
		_fail("Battle surface should expose the temporary linear elevation visual cue.")
		return
	if String(snapshot.get("linear_elevation_mode", "")) != "lane_height_gradient":
		_fail("Linear elevation mode should be lane_height_gradient.")
		return
	if int(snapshot.get("linear_elevation_band_count", 0)) < 7:
		_fail("Linear elevation cue needs enough low-to-high bands to read as a height field.")
		return
	if int(snapshot.get("linear_elevation_contour_count", 0)) < 5:
		_fail("Linear elevation cue needs dashed height contours.")
		return
	if float(snapshot.get("linear_elevation_alpha_span", 0.0)) <= 0.06:
		_fail("Linear elevation bands should vary brightness enough to be visible.")
		return
	if float(snapshot.get("linear_elevation_width_span", 0.0)) <= 0.6:
		_fail("Linear elevation contours should vary line width enough to read as height.")
		return
	var config := main._mobius_config()
	if not bool(config.get("linear_elevation_visual_enabled", false)):
		_fail("Mobius config should default to the temporary linear elevation visual cue.")
		return
	if float(config.get("surface_ridge_lift_strength", 1.0)) != 0.0:
		_fail("Temporary elevation cue must not alter world projection lift.")
		return
	if float(config.get("surface_twist_shear_strength", 1.0)) != 0.0:
		_fail("Temporary elevation cue must not restore twist shear in combat projection.")
		return
	if main.mobius_stardust_band_view != null and main.mobius_stardust_band_view.visible:
		_fail("Temporary elevation cue should not re-enable the old independent stardust band.")
		return
	var readme := FileAccess.get_file_as_string("res://README.md")
	if readme.find("temporary linear elevation cue") < 0 or readme.find("visual-only") < 0:
		_fail("README should document that the current Mobius replacement is visual-only.")
		return
	print("MOBIUS_LINEAR_ELEVATION_VISUAL_PROBE ok bands=%d contours=%d alpha_span=%.3f width_span=%.3f" % [
		int(snapshot.get("linear_elevation_band_count", 0)),
		int(snapshot.get("linear_elevation_contour_count", 0)),
		float(snapshot.get("linear_elevation_alpha_span", 0.0)),
		float(snapshot.get("linear_elevation_width_span", 0.0)),
	])
	quit()
