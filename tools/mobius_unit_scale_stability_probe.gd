extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "Mobius Scale Stability",
		"stats": {
			"health": 100,
			"max_health": 100,
			"mass": 12.0,
			"mobius_visual_scale_max_step": 0.045,
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.18, "depth01": 0.72, "projection_source": "mobius"}, true)
	var initial := float(fighter.get("mobius_visual_scale"))
	if absf(initial - 1.18) > 0.001:
		_fail("First Mobius projection should initialize to its stable visual scale; got %.4f." % initial)
		return
	fighter.set_mobius_screen_projection({"position": Vector2(8.0, 4.0), "visible": true, "guarded": true, "projection_source": "mobius_hysteresis"}, true)
	var guarded := float(fighter.get("mobius_visual_scale"))
	if absf(guarded - initial) > 0.001:
		_fail("Guarded/hysteresis projection without scale should preserve the previous Mobius scale; before=%.4f after=%.4f." % [initial, guarded])
		return
	fighter.set_mobius_screen_projection({"position": Vector2(16.0, 9.0), "scale": 0.70, "depth01": 0.0, "projection_source": "mobius"}, true, 1.0 / 120.0)
	var stepped := float(fighter.get("mobius_visual_scale"))
	if initial - stepped > 0.046 or stepped >= initial:
		_fail("Mobius scale should move continuously toward a far target; before=%.4f after=%.4f." % [initial, stepped])
		return
	fighter.set_mobius_screen_projection({"position": Vector2(18.0, 12.0), "scale": 1.0, "visible": true, "guarded": true, "projection_source": "mobius_guard_fallback"}, true, 1.0 / 120.0)
	var fallback_target := float(fighter.get_meta("mobius_visual_scale_target", 1.0))
	if absf(fallback_target - 1.0) < 0.001:
		_fail("Guard fallback should not retarget scale to 1.0 after a valid Mobius target.")
		return
	var before_screen_path := float(fighter.get("mobius_visual_scale"))
	fighter.set_screen_position(Vector2(24.0, 18.0), true)
	var after_screen_path := float(fighter.get("mobius_visual_scale"))
	if absf(after_screen_path - 1.0) < 0.001 or absf(after_screen_path - before_screen_path) > 0.001:
		_fail("Visible Mobius unit should not reset to scale=1.0 when a guarded screen path is used; before=%.4f after=%.4f." % [before_screen_path, after_screen_path])
		return
	print("MOBIUS_UNIT_SCALE_STABILITY_PROBE ok initial=%.4f stepped=%.4f fallback_target=%.4f" % [initial, stepped, fallback_target])
	quit()
