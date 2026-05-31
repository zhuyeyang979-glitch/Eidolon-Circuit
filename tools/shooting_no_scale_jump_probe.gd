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
		"unit_name": "Aim Scale Guard",
		"stats": {
			"health": 100,
			"max_health": 100,
			"mass": 12.0,
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.18, "depth01": 0.5}, true)
	var before_scale: Vector2 = fighter.scale
	var before_visual := float(fighter.get("mobius_visual_scale"))
	var before_hitbox := float(fighter.get("visual_hitbox_scale"))
	fighter.set_aim_pose(2, Vector2.UP, 0.24)
	var after_scale: Vector2 = fighter.scale
	var after_visual := float(fighter.get("mobius_visual_scale"))
	var after_hitbox := float(fighter.get("visual_hitbox_scale"))
	if before_scale.distance_to(after_scale) > 0.001:
		_fail("Aim pose should not change whole-fighter scale. before=%s after=%s" % [before_scale, after_scale])
	if absf(before_visual - after_visual) > 0.001:
		_fail("Aim pose should not change mobius_visual_scale.")
	if absf(before_hitbox - after_hitbox) > 0.001:
		_fail("Aim pose should not change visual_hitbox_scale.")
	print("SHOOTING_NO_SCALE_JUMP_PROBE ok scale=%.3f hitbox=%.3f" % [after_visual, after_hitbox])
	quit()
