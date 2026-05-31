extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _spawn_unit(main, owner: int, name: String, ring: float, lane: float):
	var unit = main._create_unit(owner, "hero", {
		"health": 100,
		"max_health": 100,
		"mass": 20.0,
		"radius": 0.18,
		"teamedit_runtime_topology": false,
	}, name, ring, lane)
	main._assign_unit_role(unit, "hero")
	return unit


func _event() -> Dictionary:
	return {
		"projectile": true,
		"gun_activation": true,
		"module_action_profile": "gun_activate",
		"projectile_behavior": "bullet_hell",
		"projectile_style": "bullet_hell",
		"travel_path": "straight",
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
		"direction": Vector2.RIGHT,
		"range": 0.7,
		"lane_range": 0.16,
		"muscle_node": 0,
		"collision_group": {
			"projectile": true,
			"projectile_only": true,
			"material_class": "gun",
			"shape": "rifle",
			"gun_kind": "rifle",
		},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH
	main.camera_lane_center = 0.0
	var attacker = _spawn_unit(main, 1, "Seam Shooter", MainScene.RING_LENGTH - 0.08, 1.0)
	var target = _spawn_unit(main, 2, "Adjacent Sheet Target", 0.18, -1.0)
	var event := _event()
	var hit: Dictionary = main._attack_part_hit(attacker, target, event)
	if hit.is_empty():
		_fail("Local Euclidean combat patch should let a shot cross the Mobius seam onto the adjacent sheet.")
	var shifted: Dictionary = hit.get("target_collider", {})
	var shifted_center: Vector2 = shifted.get("center", Vector2.ZERO)
	if shifted_center.x < MainScene.RING_LENGTH or absf(shifted_center.y - 1.0) > 0.03:
		_fail("Target collider should be lifted into the attacker's local Euclidean patch, got %s" % str(shifted_center))
	main.mobius_rotation_state = {"angle": 0.0, "pivot": Vector2.ZERO}
	var impact_a: Dictionary = main._first_projectile_impact(attacker, event)
	main.mobius_rotation_state = {"angle": 1.6, "pivot": Vector2(9.0, -2.0)}
	var impact_b: Dictionary = main._first_projectile_impact(attacker, event)
	if impact_a.is_empty() or impact_b.is_empty():
		_fail("Projectile impact should not disappear when the visual Mobius frame rotates.")
	if impact_a.get("target", null) != target or impact_b.get("target", null) != target:
		_fail("Visual Mobius rotation should not change local Euclidean projectile target.")
	print("MOBIUS_LOCAL_EUCLIDEAN_COMBAT_PATCH_PROBE ok shifted=%s distance=%.3f" % [str(shifted_center), float(impact_a.get("distance", 0.0))])
	quit()
