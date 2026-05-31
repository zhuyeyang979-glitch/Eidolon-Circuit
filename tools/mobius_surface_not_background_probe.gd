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
		"twist_phase": 0.35,
		"twist_speed": 0.12,
		"twist_amplitude": 0.20,
		"pivot": Vector2(MainScene.RING_LENGTH * 0.25, 1.0),
		"diagonal_phase": 0.4,
	}
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius battle should render the field through MobiusStripSurfaceView.")
		return
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(snapshot.get("surface_field_kind", "")) != "square_grid_field":
		_fail("Mobius surface view should advertise the square-grid field, got %s." % String(snapshot.get("surface_field_kind", "")))
		return
	if String(snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius surface should use the world-grid field, got %s." % String(snapshot.get("surface_render_mode", "")))
		return
	if not bool(snapshot.get("local_rectangular_projection", false)):
		_fail("World-grid surface should share the gameplay camera projection so map marks stay world-anchored.")
		return
	if String(snapshot.get("surface_texture_path", "")) != "":
		_fail("Mobius world grid should not use the old full-screen ripple texture as the main map.")
		return
	if main.mobius_stardust_band_view != null and main.mobius_stardust_band_view.visible:
		_fail("Independent stardust band should stay hidden; world-grid marks are the battlefield reference.")
		return
	var battle_backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as CanvasItem
	if battle_backdrop != null and battle_backdrop.visible:
		_fail("Static generated battle backdrop should be hidden while Mobius field rendering is active.")
		return
	print("MOBIUS_SURFACE_NOT_BACKGROUND_PROBE ok mode=world_grid stardust_hidden=true")
	quit()
