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
		"radius": 0.16,
		"teamedit_runtime_topology": false,
	}, name, ring, lane)
	main._assign_unit_role(unit, "hero")
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	var attacker = _spawn_unit(main, 1, "Edge Sniper", 23.62, 0.0)
	var target = _spawn_unit(main, 2, "Edge Target", 0.18, 0.0)
	var hit := main._sniper_wrapped_aim_query(attacker, Vector2(attacker.ring_pos, attacker.lane), Vector2.RIGHT)
	if hit.is_empty() or hit.get("target", null) != target:
		_fail("Sniper wrapped aim should find the edge target across the ring boundary.")
	var event := main._true_bullet_event_for_aim(attacker, Vector2.RIGHT, {
		"projectile": true,
		"projectile_behavior": "true_bullet",
		"projectile_style": "true_bullet",
		"projectile_range": 4.0,
		"bullet_lock_radius": 0.18,
	}, 0)
	var locked = main._acquire_true_bullet_target(attacker, event)
	if locked != target:
		_fail("True bullet lock should acquire edge target across wrap.")
	print("SNIPER_EDGE_TARGET_LOCK_PROBE ok distance=%.2f" % float(hit.get("distance", 0.0)))
	quit()
