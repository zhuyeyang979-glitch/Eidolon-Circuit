extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "stats": {"health": 100, "mass": 12.0, "move_speed": 4.0, "move_acceleration": 40.0}})
	fighter.deploy(3.0, 0.0)
	fighter.capture_motion_snapshot(true)
	fighter.velocity = Vector2(2.0, 0.6)
	fighter.angular_velocity = 1.0
	fighter.tick(1.0 / 120.0, 24.0)
	fighter.capture_motion_snapshot(false)
	fighter.apply_interpolated_presentation(0.5)
	var midpoint := fighter.presentation_combat_coord()
	var expected := Vector2(3.0, 0.0).lerp(Vector2(fighter.mobius_s, fighter.mobius_v), 0.5)
	if midpoint.distance_to(expected) > 0.0001:
		_fail("Presentation coordinate did not interpolate between 120Hz snapshots.")
		return
	fighter.apply_interpolated_presentation(0.75)
	if fighter.presentation_combat_coord().x <= midpoint.x:
		_fail("Interpolated movement should be monotonic between simulation states.")
		return
	print("BATTLE_RENDER_INTERPOLATION_COMPAT_PROBE ok midpoint=%s" % str(midpoint))
	quit(0)
