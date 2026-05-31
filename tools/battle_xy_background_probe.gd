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
	main.camera_center = 3.0
	main.camera_lane_center = -1.0
	main._refresh_mobius_surface_view()
	main._update_parallax_background()
	main._update_arena_boundary_lines()
	if not main.world_background_art_nodes.is_empty():
		_fail("Battle background should no longer create world-bound debris/art nodes.")
	if not main.world_near_dust_nodes.is_empty():
		_fail("Battle background should no longer create near dust/current lines.")
	for raw_line in main.world_coordinate_grid_lines:
		if raw_line is Line2D and (raw_line as Line2D).visible:
			_fail("Battle background should not show coordinate grid lines.")
	var backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as Sprite2D
	if backdrop == null or backdrop.texture == null:
		_fail("Battle background should keep the generated fallback backdrop image.")
	if backdrop.visible:
		_fail("Fallback backdrop image should be hidden while the Möbius strip surface is active.")
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Battle background should use the Mobius world-grid surface.")
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Battle background should use world-grid rendering, got %s." % String(surface_snapshot.get("surface_render_mode", "")))
	if main.mobius_strip_surface_view.surface_texture != null:
		_fail("Battle background should not use the old full-screen generated texture in Mobius mode.")
	var stardust: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	if bool(stardust.get("visible", false)):
		_fail("Battle background should keep screen-locked Mobius stardust disabled.")
	if bool(stardust.get("lane_guides_enabled", true)):
		_fail("Battle background should disable straight Mobius lane guide lines.")
	if main.arena_top_boundary_line == null or main.arena_bottom_boundary_line == null:
		_fail("Battle should keep map boundary line nodes.")
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Battle should hide top/bottom map boundary borders.")
	print("BATTLE_XY_BACKGROUND_PROBE world_grid mode=%s stardust_visible=%s" % [
		String(surface_snapshot.get("surface_render_mode", "")),
		str(bool(stardust.get("visible", false))),
	])
	quit()
