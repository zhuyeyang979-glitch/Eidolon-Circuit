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

	var surface = main.mobius_strip_surface_view
	var stardust = main.mobius_stardust_band_view
	if surface == null:
		_fail("Mobius surface node is missing.")
		return
	if stardust == null:
		_fail("MobiusStardustBandView node is missing.")
		return
	if stardust.name != "MobiusStardustBandView":
		_fail("Independent stardust node should keep its explicit runtime name.")
		return
	if not stardust.visible:
		_fail("MobiusStardustBandView should be visible in Mobius battle.")
		return
	if int(stardust.z_index) <= int(surface.z_index):
		_fail("Stardust band should render above the Mobius surface texture.")
		return
	if main.units_root != null and int(stardust.z_index) >= int(main.units_root.z_index):
		_fail("Stardust band should render below units.")
		return
	if main.effects_root != null and int(stardust.z_index) >= int(main.effects_root.z_index):
		_fail("Stardust band should render below combat effects.")
		return
	var surface_snapshot: Dictionary = surface.stardust_band_snapshot()
	if bool(surface_snapshot.get("visible", false)):
		_fail("MobiusStripSurfaceView should no longer draw the stardust band internally.")
		return
	print("MOBIUS_STARDUST_NAMED_NODE_PROBE ok surface_z=%d stardust_z=%d units_z=%d" % [
		int(surface.z_index),
		int(stardust.z_index),
		int(main.units_root.z_index) if main.units_root != null else 0,
	])
	quit()
