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
		"unit_name": "Scale Continuity",
		"stats": {
			"health": 100,
			"max_health": 100,
			"mass": 12.0,
			"mobius_visual_scale_max_step": 0.045,
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.0, "depth01": 0.5}, true)
	fighter.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.35, "depth01": 0.5}, true)
	var applied := float(fighter.get("mobius_visual_scale"))
	if applied <= 1.0 or applied > 1.046:
		_fail("Mobius visual scale should move continuously toward target, not jump. applied=%.4f" % applied)
	if absf(fighter.scale.x - applied) > 0.001 or absf(fighter.scale.y - applied) > 0.001:
		_fail("Fighter scale should match smoothed Mobius visual scale.")
	for i in range(8):
		fighter.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.35, "depth01": 0.5}, true)
	var progressed := float(fighter.get("mobius_visual_scale"))
	if progressed <= applied:
		_fail("Mobius visual scale should continue progressing toward projection target.")
	print("BATTLE_MOBIUS_SCALE_CONTINUITY_PROBE ok first=%.4f progressed=%.4f" % [applied, progressed])
	quit()
