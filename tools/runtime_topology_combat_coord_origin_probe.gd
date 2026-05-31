extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"node_index": 3, "part_kind": "terminal", "a_local": Vector2.ZERO, "b_local": Vector2.RIGHT, "radius": 0.08}],
		},
	})
	fighter.deploy(1.0, 0.6)
	fighter.mobius_s = 25.0
	fighter.mobius_v = 0.6
	fighter.ring_pos = 1.0
	var segment: Dictionary = fighter.runtime_world_segment_for_node(3, true)
	var a: Vector2 = segment.get("a", Vector2.ZERO)
	var b: Vector2 = segment.get("b", Vector2.ZERO)
	if absf(a.x - 25.0) > 0.001 or b.x < 25.9:
		_fail("Runtime segment fell back to wrapped ring origin; a=%s b=%s." % [str(a), str(b)])
	print("RUNTIME_TOPOLOGY_COMBAT_COORD_ORIGIN_PROBE ok a=%s b=%s" % [str(a), str(b)])
	quit()
