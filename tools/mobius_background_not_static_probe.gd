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
	var backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as CanvasItem
	if backdrop == null:
		_fail("Compatibility GeneratedSpaceBackdrop node should still exist for fallback modes.")
		return
	if backdrop.visible:
		_fail("GeneratedSpaceBackdrop must be hidden while Möbius battle surface rendering is active.")
		return
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius strip surface should replace the static battle backdrop.")
		return
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius strip surface should use world-grid battlefield rendering.")
		return
	if main.mobius_strip_surface_view.surface_texture != null:
		_fail("Mobius strip surface should not carry the old screen-locked generated texture as the main map.")
		return
	main.mobius_enabled = false
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view.visible:
		_fail("Mobius strip surface should hide when Mobius rendering is disabled.")
		return
	if not backdrop.visible:
		_fail("Static backdrop should remain available as a non-Mobius fallback.")
		return
	print("MOBIUS_BACKGROUND_NOT_STATIC_PROBE ok mode=world_grid fallback_visible=true")
	quit()
