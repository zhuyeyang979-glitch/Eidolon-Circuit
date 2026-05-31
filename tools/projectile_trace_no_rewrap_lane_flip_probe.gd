extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH + 1.0
	main.camera_center = 1.0
	main.camera_lane_center = 0.0
	var muzzle := Vector2(MainScene.RING_LENGTH + 1.0, 0.8)
	var impact := muzzle + Vector2(1.2, 0.0)
	var segment: Dictionary = main._projected_screen_segment_from_combat(muzzle, impact)
	var direct: Vector2 = main._mobius_project_coord(muzzle).get("position", Vector2.ZERO)
	var relifted: Vector2 = main._screen_from_ring(fposmod(muzzle.x, MainScene.RING_LENGTH), muzzle.y).get("position", Vector2.ZERO)
	if Vector2(segment.get("start", Vector2.ZERO)).distance_to(direct) > 0.001:
		_fail("Projectile trace should use canonical combat projection origin.")
	if direct.distance_to(relifted) <= 0.1:
		_fail("Probe did not exercise sheet lane flip; direct=%s relifted=%s." % [str(direct), str(relifted)])
	print("PROJECTILE_TRACE_NO_REWRAP_LANE_FLIP_PROBE ok")
	quit()
