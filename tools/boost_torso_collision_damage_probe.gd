extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, x: float, vx: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Boost Torso %d" % owner_id,
		"owner_id": owner_id,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 48.0,
			"max_health": 120,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "M Torso", "size_tier": "M", "a_local": Vector2(-0.24, 0.0), "b_local": Vector2(0.24, 0.0), "radius": 0.14, "damage_type": "blunt", "material_class": "metal"},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(x, 0.0)
	fighter.velocity = Vector2(vx, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a = _make_unit(1, 4.0, 4.0)
	var b = _make_unit(2, 4.35, -4.0)
	var ca: Dictionary = a.part_colliders()[0]
	var cb: Dictionary = b.part_colliders()[0]
	var hp_a := int(a.health)
	var hp_b := int(b.health)
	main._resolve_runtime_contact_pair_once(a, ca, ca, b, cb, cb, Vector2.RIGHT, 0.05)
	if int(a.health) >= hp_a or int(b.health) >= hp_b:
		_fail("Boost torso collision did not break threshold: hp %d/%d -> %d/%d" % [hp_a, hp_b, a.health, b.health])
	print("BOOST_TORSO_COLLISION_DAMAGE_PROBE hp_delta=%d/%d" % [hp_a - int(a.health), hp_b - int(b.health)])
	quit()
