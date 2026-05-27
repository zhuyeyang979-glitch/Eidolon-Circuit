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
	main.camera_mobius_s = 3.0
	main.camera_center = 3.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {
		"twist_phase": 0.31,
		"ridge_phase": 0.27,
		"ridge_angle_phase": 0.14,
		"twist_amplitude": 0.20,
		"pivot_influence": 0.0,
	}
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible.")
		return
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if float(snapshot.get("surface_grid_cell_px", 0.0)) < 56.0:
		_fail("Quiet battlefield grid should use large displayed cells; got %.1fpx." % float(snapshot.get("surface_grid_cell_px", 0.0)))
		return
	if float(snapshot.get("surface_alpha_gain", 0.0)) < 1.0 or float(snapshot.get("surface_alpha_gain", 99.0)) > 1.12 or float(snapshot.get("surface_alpha_max", 0.0)) < 0.17 or float(snapshot.get("surface_alpha_max", 99.0)) > 0.20:
		_fail("Quiet battlefield grid should stay visible without returning to high gain; got gain=%.2f max=%.2f." % [float(snapshot.get("surface_alpha_gain", 0.0)), float(snapshot.get("surface_alpha_max", 0.0))])
		return
	if float(snapshot.get("surface_color_gain", 0.0)) < 1.16 or float(snapshot.get("surface_color_gain", 99.0)) > 1.28:
		_fail("Quiet battlefield grid should be readable but not use strong color gain; got %.2f." % float(snapshot.get("surface_color_gain", 0.0)))
		return
	var grid_near := float(snapshot.get("grid_near_brightness", 1.0))
	var grid_far := float(snapshot.get("grid_far_brightness", 0.0))
	var unit_far := float(snapshot.get("unit_surface_far_brightness", 0.0))
	if grid_far < 0.50:
		_fail("Grid valley/far brightness floor is too low; got %.2f." % grid_far)
		return
	if grid_near >= unit_far:
		_fail("Grid brightness must stay below foreground unit brightness; grid_near=%.2f unit_far=%.2f." % [grid_near, unit_far])
		return
	var params := MobiusWorld.surface_shader_parameters(main._mobius_camera_coord(), main.mobius_strip_surface_view.config, main.mobius_rotation_state)
	if float(params.get("grid_far_brightness", 0.0)) < 0.50 or float(params.get("grid_near_brightness", 0.0)) > 0.90:
		_fail("Shader grid brightness uniforms should stay quiet; got %.2f/%.2f." % [float(params.get("grid_far_brightness", 0.0)), float(params.get("grid_near_brightness", 0.0))])
		return
	print("MOBIUS_SURFACE_QUIET_READABILITY_PROBE ok grid=%.1f alpha=%.2f/%.2f" % [float(snapshot.get("surface_grid_cell_px", 0.0)), float(snapshot.get("surface_alpha_gain", 0.0)), float(snapshot.get("surface_alpha_max", 0.0))])
	quit()
