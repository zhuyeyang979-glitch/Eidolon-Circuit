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
	main._refresh_mobius_surface_view()
	main._update_arena_boundary_lines()

	var backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as Sprite2D
	if backdrop == null or backdrop.texture == null:
		_fail("Battle should keep the generated fallback background sprite.")
	if backdrop.visible:
		_fail("Fallback background sprite should be hidden while the Möbius surface is active.")
	if not main.world_background_art_nodes.is_empty():
		_fail("Battle minimal background should not build world-bound debris/art nodes.")
	if not main.world_near_dust_nodes.is_empty():
		_fail("Battle minimal background should not build near dust lanes.")
	for layer_name in ["FarStarVeil", "WarmStarScatter", "BlueRiftNebula", "RedClusterWake", "NearIonDust"]:
		if main.find_child(layer_name, true, false) != null:
			_fail("Battle minimal background should not include parallax layer %s." % layer_name)
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius strip surface should remain visible as the core battle background.")
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius strip surface should use the world-grid battlefield background.")
	if main.mobius_strip_surface_view.surface_texture != null:
		_fail("Mobius world grid should not use the old full-screen generated texture as the main map.")
	var stardust: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	if bool(stardust.get("visible", false)):
		_fail("Minimal battle background should keep screen-locked Mobius stardust disabled.")
	if bool(stardust.get("lane_guides_enabled", true)):
		_fail("Minimal battle background should not show straight Mobius lane guides.")
	if main.arena_top_boundary_line == null or main.arena_bottom_boundary_line == null:
		_fail("Arena boundary line nodes should exist.")
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Arena top/bottom boundary borders should stay hidden.")
	print("BATTLE_MINIMAL_BACKGROUND_PROBE ok mode=%s stardust_visible=%s borders_hidden=true" % [
		String(surface_snapshot.get("surface_render_mode", "")),
		str(bool(stardust.get("visible", false))),
	])
	quit()
