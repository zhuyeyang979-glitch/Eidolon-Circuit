extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, x: float):
	var f = FighterScene.new()
	root.add_child(f)
	f._ready()
	f.setup_unit({
		"unit_name": "OneShot%d" % owner_id,
		"owner_id": owner_id,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0,
			"health": 120,
			"torso_break_threshold": 2.0,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Torso", "a_local": Vector2(-0.18, 0.0), "b_local": Vector2(0.18, 0.0), "radius": 0.14, "material_class": "metal"},
			],
			"runtime_module_bindings": [],
		},
	})
	f.deploy(x, 0.0)
	return f


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a = _make_unit(1, 4.0)
	var b = _make_unit(2, 4.1)
	a.velocity = Vector2(3.0, 0.0)
	b.velocity = Vector2.ZERO
	var ca: Dictionary = a.part_colliders()[0]
	var cb: Dictionary = b.part_colliders()[0]
	var cba: Dictionary = main._shift_collider_to_origin(ca, a.ring_pos)
	var cbb: Dictionary = main._shift_collider_to_origin(cb, a.ring_pos)
	main.runtime_contact_pairs_seen = {}
	main._resolve_runtime_contact_pair_once(a, ca, cba, b, cb, cbb, Vector2.RIGHT, 0.1)
	var hp_after_first := int(b.health)
	main._resolve_runtime_contact_pair_once(a, ca, cba, b, cb, cbb, Vector2.RIGHT, 0.1)
	if int(b.health) != hp_after_first:
		_fail("same contact pair damaged more than once before separation: first=%d second=%d" % [hp_after_first, int(b.health)])
	print("ONE_SHOT_CONTACT_PROBE hp_after_first=%d" % hp_after_first)
	quit()
