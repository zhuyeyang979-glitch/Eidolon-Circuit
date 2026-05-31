extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main.mobius_enabled = true
	main.game_state = MainScene.STATE_BATTLE
	main.camera_center = 0.0
	main.camera_mobius_s = 0.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"angle": 0.0, "angular_velocity": 0.0, "pivot": Vector2.ZERO}
	main._ready()
	main._refresh_mobius_surface_view()
	main._update_arena_boundary_lines()
	if main.arena_top_boundary_line == null or main.arena_bottom_boundary_line == null:
		_fail("Boundary compatibility nodes should still exist.")
		return
	if main.arena_top_boundary_line.visible or main.arena_bottom_boundary_line.visible:
		_fail("Möbius battle should not draw top/bottom map borders.")
		return
	var line := Line2D.new()
	root.add_child(line)
	main._update_single_world_boundary_line(line, MainScene.BATTLE_HALF_HEIGHT, Color(1.0, 0.2, 0.36, 1.0))
	if not line.visible or line.points.size() < 16:
		_fail("Low-level boundary sampler should remain available for compatibility/debug.")
		return
	print("MOBIUS_BOUNDARY_VISUAL_PROBE ok hidden=true sampler_points=%d" % line.points.size())
	quit()
