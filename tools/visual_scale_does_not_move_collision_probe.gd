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
		"radius": 0.20,
		"teamedit_runtime_topology": false,
	}, "Target", 2.0, 0.0)
	main._assign_unit_role(target, "hero")
	target.set("mobius_visual_scale", 1.24)
	target.set("visual_hitbox_scale", GameplayTransform.hitbox_scale_for_visual_scale(1.24))
	var body_collider: Dictionary = main._unit_part_colliders(target)[0]
	if absf(float(body_collider.get("radius", 0.0)) - 0.20) > 0.001:
		_fail("Body/melee collider should stay in gameplay coordinates and ignore visual scale.")
	var projectile_event := {"projectile": true, "gun_activation": true}
	var projectile_collider := main._target_collider_for_projectile_query(target, body_collider, projectile_event)
	if absf(float(projectile_collider.get("radius", 0.0)) - 0.20 * 1.24) > 0.001:
		_fail("Projectile target collider should strongly match visual scale.")
	var body_gap := main._collider_gap({"shape": "circle", "center": Vector2(1.52, 0.0), "radius": 0.20}, body_collider)
	var scaled_gap := main._collider_gap({"shape": "circle", "center": Vector2(1.52, 0.0), "radius": 0.20}, projectile_collider)
	if scaled_gap >= body_gap:
		_fail("Scaled projectile collider should make visually larger target easier to hit.")
	print("VISUAL_SCALE_DOES_NOT_MOVE_COLLISION_PROBE ok body=%.3f projectile=%.3f" % [float(body_collider.get("radius", 0.0)), float(projectile_collider.get("radius", 0.0))])
	quit()
