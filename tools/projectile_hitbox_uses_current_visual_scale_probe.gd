extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var target = main._create_unit(2, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.25,
		"teamedit_runtime_topology": false,
	}, "Scaled Target", 2.0, 0.0)
	target.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.24, "depth01": 0.5}, true)
	var current_hitbox := float(target.get("visual_hitbox_scale"))
	var collider: Dictionary = main._unit_part_colliders(target)[0]
	var projectile_collider := main._target_collider_for_projectile_query(target, collider, {"projectile": true, "gun_activation": true})
	var expected_radius := float(collider.get("radius", 0.0)) * current_hitbox
	if absf(float(projectile_collider.get("radius", 0.0)) - expected_radius) > 0.001:
		_fail("Projectile query should use current projected visual hitbox scale. expected=%.4f actual=%.4f" % [expected_radius, float(projectile_collider.get("radius", 0.0))])
	target.set_aim_pose(2, Vector2.RIGHT, 0.2)
	var after_hitbox := float(target.get("visual_hitbox_scale"))
	if absf(after_hitbox - current_hitbox) > 0.001:
		_fail("Aiming should not alter the projected hitbox scale used by projectile query.")
	var clamped := GameplayTransform.hitbox_scale_for_visual_scale(float(target.get("mobius_visual_scale")))
	if absf(after_hitbox - clamped) > 0.001:
		_fail("Projectile hitbox scale should still come from normal projection scale.")
	print("PROJECTILE_HITBOX_USES_CURRENT_VISUAL_SCALE_PROBE ok hitbox=%.3f radius=%.3f" % [after_hitbox, float(projectile_collider.get("radius", 0.0))])
	quit()
