extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._set_training_ball_dummy_radius(1.25)
	main._show_training_config(true)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE:
		_fail("Training battle did not start.")
	var dummy = main.active_units[2]["hero"]
	if not main._is_live_unit(dummy):
		_fail("Training ball dummy did not spawn.")
	var colliders: Array = main._unit_part_colliders(dummy)
	if colliders.size() != 1:
		_fail("Training ball dummy should expose one spherical collider, got %d" % colliders.size())
	var collider: Dictionary = colliders[0]
	if String(collider.get("shape", "")) != "circle":
		_fail("Training ball dummy collider should be circle, got %s" % String(collider.get("shape", "")))
	if absf(float(collider.get("radius", 0.0)) - 1.25) > 0.001:
		_fail("Training ball dummy collider radius mismatch: %.3f" % float(collider.get("radius", 0.0)))
	print("TRAINING_BALL_DUMMY_COLLISION_RADIUS_PROBE ok radius=%.2f" % float(collider.get("radius", 0.0)))
	quit()
