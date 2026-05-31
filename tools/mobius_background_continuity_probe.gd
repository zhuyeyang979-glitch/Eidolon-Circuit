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
	main.mobius_enabled = true
	main.game_state = MainScene.STATE_BATTLE
	main.camera_center = 0.0
	main.camera_mobius_s = 0.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"angle": 0.42, "angular_velocity": 0.0, "pivot": Vector2(5.0, 1.0)}
	main._refresh_mobius_surface_view()
	main._update_parallax_background()
	main._update_arena_boundary_lines()
	if main.space_backdrop_texture == null:
		_fail("Generated fallback battle backdrop texture should load.")
	var backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as CanvasItem
	if backdrop == null:
		_fail("Generated fallback battle backdrop node should exist.")
	if backdrop.visible:
		_fail("Fallback battle backdrop should be hidden while Möbius world-grid surface is active.")
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface decoration should be visible as the battle surface background.")
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius surface decoration should be the world-grid battlefield reference.")
	if main.mobius_strip_surface_view.surface_texture != null:
		_fail("Mobius surface decoration should not use the old screen-locked generated texture.")
	var stardust: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	if bool(stardust.get("visible", false)):
		_fail("Mobius surface decoration should keep the screen-locked stardust band disabled.")
	if bool(stardust.get("lane_guides_enabled", true)):
		_fail("Mobius surface decoration should not draw straight lane guides.")
	if not main.parallax_nodes.is_empty() or not main.world_background_art_nodes.is_empty() or not main.world_near_dust_nodes.is_empty():
		_fail("Minimal battle background should not keep parallax/world/dust decoration layers.")
	var config := main._mobius_config()
	var camera_coord := main._mobius_camera_coord()
	var seam_left := MobiusWorld.project_to_screen(Vector2(-0.04, -1.0), camera_coord, config, main.mobius_rotation_state)
	var seam_right := MobiusWorld.project_to_screen(Vector2(MainScene.RING_LENGTH - 0.04, 1.0), camera_coord, config, main.mobius_rotation_state)
	var seam_distance := Vector2(seam_left.get("position", Vector2.ZERO)).distance_to(Vector2(seam_right.get("position", Vector2.ZERO)))
	if seam_distance > 8.0:
		_fail("Mobius seam projection should still wrap/invert continuously; distance %.3f" % seam_distance)
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Minimal battle background should hide top/bottom map boundary borders.")
	print("MOBIUS_BACKGROUND_CONTINUITY_PROBE world_grid seam=%.3f mode=%s stardust_visible=%s" % [
		seam_distance,
		String(surface_snapshot.get("surface_render_mode", "")),
		str(bool(stardust.get("visible", false))),
	])
	quit()
