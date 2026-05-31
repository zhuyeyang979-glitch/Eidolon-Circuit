extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"unit_name": "SELF_COLLISION",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"health": 100,
			"max_health": 100,
			"mass": 20.0,
			"runtime_topology_segments": [
				{"part_kind": "torso", "node_index": 0, "shape": "polygon", "polygon_local": [Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.1), Vector2(-0.2, 0.1)], "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.1},
				{"part_kind": "limb_muscle", "node_index": 1, "a_local": Vector2(-0.1, 0.0), "b_local": Vector2(0.1, 0.0), "radius": 0.08},
			],
		},
	})
	unit.deploy(0.0, 0.0)
	main._separate_unit_part_pair(unit, unit, 0.016)
	if int(unit.health) != 100:
		_fail("Same unit limb/torso overlap must not damage itself.")
		return
	print("SAME_UNIT_NO_SELF_COLLISION_PROBE hp=%d" % int(unit.health))
	quit()
