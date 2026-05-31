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

	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible in battle.")
	if main.mobius_stardust_band_view == null:
		_fail("Independent Mobius stardust band view node should still exist.")
	if main.mobius_stardust_band_view.visible:
		_fail("Independent Mobius stardust band view should stay hidden in world-grid battle.")
	var surface_snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if bool(surface_snapshot.get("visible", false)):
		_fail("Mobius surface view should not draw the stardust band internally.")
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Mobius surface view should render the world-grid battlefield surface.")
	var snapshot: Dictionary = main.mobius_stardust_band_view.stardust_band_snapshot()
	if bool(snapshot.get("enabled", false)):
		_fail("Mobius stardust band should be disabled while the world grid is the battle reference.")
	if bool(snapshot.get("visible", false)):
		_fail("Mobius stardust band should not have visible cached samples in world-grid mode.")
	if int(snapshot.get("band_count", 0)) != 0:
		_fail("Mobius stardust should not render surface-attached bands in world-grid mode.")
	if bool(snapshot.get("lane_guides_enabled", true)):
		_fail("Straight surface lane guides must stay disabled.")
	if int(snapshot.get("particle_count", 0)) != 0:
		_fail("Mobius stardust band should not budget particles in world-grid mode.")
	if float(snapshot.get("max_alpha", 1.0)) > 0.305:
		_fail("Mobius stardust band alpha should remain subtle, got %.3f." % float(snapshot.get("max_alpha", 1.0)))
	if int(snapshot.get("z_index", 0)) >= 0:
		_fail("Mobius stardust band should remain behind units and combat VFX.")
	print("MOBIUS_STARDUST_BAND_RUNTIME_PROBE ok hidden=true points=%d particles=%d alpha=%.3f" % [
		PackedVector2Array(snapshot.get("points", PackedVector2Array())).size(),
		int(snapshot.get("particle_count", 0)),
		float(snapshot.get("max_alpha", 0.0)),
	])
	quit()
