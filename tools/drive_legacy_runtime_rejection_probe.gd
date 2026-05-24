extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "LegacyRuntime", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var legacy_only := {
		"health": 100,
		"mass": 12.0,
		"body_move_speed": 3.0,
		"thruster_acceleration": 30.0,
		"boost_total_momentum": 84.0,
		"boost_duration": 0.2,
		"brake_efficiency": 2.0,
	}
	var old = _fighter(legacy_only)
	old.move_by(Vector2.RIGHT, 0.2, 100.0)
	old.tick(0.2, 100.0)
	if old.velocity.length() > 0.01:
		_fail("Legacy-only movement fields still drove Fighter movement.")
	print("DRIVE_LEGACY_RUNTIME_REJECTION_PROBE ok")
	quit()
