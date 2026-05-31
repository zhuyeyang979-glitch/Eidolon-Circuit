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
	main.camera_mobius_s = 3.2
	main.camera_lane_center = 0.0
	main._refresh_mobius_surface_view()
	var snapshot: Dictionary = main.mobius_strip_surface_view.stardust_band_snapshot()
	if String(snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("Battle surface should be rendered as a world-anchored grid field.")
		return
	var arena := Rect2(Vector2(MainScene.ARENA_LEFT, MainScene.ARENA_TOP), Vector2(MainScene.ARENA_WIDTH, MainScene.ARENA_HEIGHT))
	var drawn: Rect2 = snapshot.get("surface_draw_rect", Rect2())
	if not drawn.encloses(arena):
		_fail("Mobius world grid must cover the complete arena including its top edge; drawn=%s arena=%s." % [str(drawn), str(arena)])
		return
	if not bool(snapshot.get("lane_guides_enabled", false)):
		_fail("World-grid surface should expose lane/boundary guides as part of the battlefield reference grid.")
		return
	print("MOBIUS_SURFACE_FULL_RECT_COVERAGE_PROBE ok mode=world_grid rect=%s" % str(drawn))
	quit()
