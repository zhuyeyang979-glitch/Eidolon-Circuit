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
	if main.arena_top_boundary_line == null or main.arena_bottom_boundary_line == null:
		_fail("Top/bottom boundary nodes should remain for compatibility.")
		return
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Top/bottom map borders should not be visible in local rectangular Möbius battle.")
		return
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Möbius surface should remain visible without top/bottom borders.")
		return
	if bool(main.mobius_strip_surface_view.config.get("show_surface_boundary_guides", true)):
		_fail("Möbius surface should not draw top/bottom guide lines.")
		return
	print("MOBIUS_NO_TOP_BOTTOM_BORDER_PROBE ok")
	quit()
