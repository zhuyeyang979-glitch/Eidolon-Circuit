extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _runtime_stats(main, owner_id: int, mass: float) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats: Dictionary = main._compute_unit_stats(owner_id, "hero", -1, unit_bp)
	stats["teamedit_runtime_topology"] = true
	stats["mass"] = mass
	return stats


func _make_fighter(main, owner_id: int, mass: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "RuntimeMomentum%d" % owner_id, "owner_id": owner_id, "role": "hero", "stats": _runtime_stats(main, owner_id, mass)})
	fighter.deploy(4.0 + float(owner_id) * 0.1, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var attacker = _make_fighter(main, 1, 10.0)
	var target = _make_fighter(main, 2, 10.0)
	attacker.velocity = Vector2(2.0, 0.0)
	target.velocity = Vector2.ZERO
	var expected_transfer := 10.0
	main._apply_runtime_contact_velocity_response(attacker, target, Vector2.RIGHT, expected_transfer)
	var expected_target_vx := expected_transfer / 10.0
	var expected_attacker_vx := 2.0 - expected_transfer / 10.0
	if absf(target.velocity.x - expected_target_vx) > 0.0001:
		_fail("Target velocity did not follow reduced-mass momentum: got %.4f expected %.4f" % [target.velocity.x, expected_target_vx])
	if absf(attacker.velocity.x - expected_attacker_vx) > 0.0001:
		_fail("Attacker velocity did not follow reduced-mass momentum: got %.4f expected %.4f" % [attacker.velocity.x, expected_attacker_vx])
	if target.velocity.x > 1.2:
		_fail("Runtime collision still has arcade kick: %.4f" % target.velocity.x)
	print("RUNTIME_COLLISION_MOMENTUM_PROBE attacker_v=%.4f target_v=%.4f" % [attacker.velocity.x, target.velocity.x])
	quit()
