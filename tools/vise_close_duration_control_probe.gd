extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = FighterScene.new()
	var target = FighterScene.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker._ready()
	target._ready()
	attacker.setup_unit({"unit_name": "Clamp Probe A", "owner_id": 1, "role": "hero", "stats": {"health": 100, "mass": 30.0, "move_speed": 2.0, "move_acceleration": 8.0}})
	target.setup_unit({"unit_name": "Clamp Probe B", "owner_id": 2, "role": "hero", "stats": {"health": 100, "mass": 30.0, "move_speed": 3.0, "move_acceleration": 10.0}})
	attacker.deploy(0.0, 0.0)
	target.deploy(0.4, 0.0)
	target.velocity = Vector2(2.0, 0.0)
	var event := {
		"module_variant_key": "vise_close",
		"attack_key": 1,
		"clamp_pin_seconds": 0.38,
		"clamp_velocity_mult": 0.35,
	}
	main._apply_module_variant_hit_effect(attacker, target, event)
	if float(target.get_meta("clamp_pin_timer", 0.0)) < 0.37:
		_fail("VISE CLOSE did not apply canonical clamp pin timer.")
	if target.velocity.length() > 0.72:
		_fail("VISE CLOSE did not immediately suppress target velocity.")
	var cooldown := float(target.action_cooldown)
	if cooldown <= 0.0:
		_fail("VISE CLOSE did not add short action cooldown.")
	target.tick(0.16, 24.0)
	target.move_by(Vector2.RIGHT, 0.10, 24.0)
	if float(target.get_meta("clamp_pin_timer", 0.0)) <= 0.0:
		_fail("VISE CLOSE pin expired too early.")
	if float(target.get_meta("clamp_velocity_mult", 1.0)) > 0.36:
		_fail("VISE CLOSE clamp multiplier did not persist.")
	target.tick(0.30, 24.0)
	if float(target.get_meta("clamp_pin_timer", 0.0)) > 0.01:
		_fail("VISE CLOSE pin should clear after its fair short-control window.")
	print("VISE_CLOSE_DURATION_CONTROL_PROBE ok cooldown=%.3f" % cooldown)
	quit()
