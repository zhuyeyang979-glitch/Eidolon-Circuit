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
		"unit_name": "MELEE_PROJECTILE_GATE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.1},
				{"part_kind": "terminal", "node_index": 2, "terminal_weapon_kind": "melee", "projectile": false, "a_local": Vector2(0.2, 0.0), "b_local": Vector2(0.6, 0.0), "radius": 0.08},
			],
		},
	})
	fighter.deploy(0.0, 0.0)
	var collider := fighter.attack_collider_for_event({
		"projectile": true,
		"runtime_target_nodes": [2],
		"muscle_node": 1,
		"range": 2.0,
		"direction": Vector2.RIGHT,
	})
	if not collider.is_empty():
		_fail("Projectile collider should not be generated from a melee terminal.")
		return
	print("MELEE_PROJECTILE_GATE_PROBE ok")
	quit()
