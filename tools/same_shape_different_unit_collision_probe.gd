extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, name: String, x: float, velocity: Vector2):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"owner_id": owner_id,
		"role": "hero",
		"unit_name": name,
		"stats": {
			"health": 500,
			"mass": 40.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Shared Torso", "polygon_local": [Vector2(-0.22, -0.12), Vector2(0.22, -0.12), Vector2(0.22, 0.12), Vector2(-0.22, 0.12)], "radius": 0.12},
			],
		},
	})
	unit.deploy(x, 0.0)
	unit.velocity = velocity
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a = _make_unit(1, "Same A", 0.0, Vector2.RIGHT * 3.0)
	var b = _make_unit(2, "Same B", 0.25, Vector2.ZERO)
	var a_collider: Dictionary = a.part_colliders()[0]
	var b_collider: Dictionary = b.part_colliders()[0]
	var before_a := int(a.health)
	var before_b := int(b.health)
	main._resolve_runtime_contact_pair_once(a, a_collider, a_collider, b, b_collider, b_collider, Vector2.RIGHT, 0.08)
	if int(a.health) == before_a and int(b.health) == before_b:
		_fail("Two identical blueprints as different Fighter instances should collide and resolve damage.")
		return
	print("SAME_SHAPE_DIFFERENT_UNIT_COLLISION_PROBE a_delta=%d b_delta=%d" % [before_a - int(a.health), before_b - int(b.health)])
	quit()
