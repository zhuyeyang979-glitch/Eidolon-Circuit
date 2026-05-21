extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, x: float, velocity: Vector2):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Normal Momentum %d" % owner_id,
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
	fighter.velocity = velocity
	return fighter


func _run_pair(main, velocity_a: Vector2, velocity_b: Vector2) -> int:
	var a = _make_unit(1, 4.0, velocity_a)
	var b = _make_unit(2, 4.35, velocity_b)
	var ca: Dictionary = a.part_colliders()[0]
	var cb: Dictionary = b.part_colliders()[0]
	var hp_before := int(a.health) + int(b.health)
	main._resolve_runtime_contact_pair_once(a, ca, ca, b, cb, cb, Vector2.RIGHT, 0.05)
	return hp_before - int(a.health) - int(b.health)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var tangent_damage := _run_pair(main, Vector2(0.0, 4.0), Vector2(0.0, -4.0))
	if tangent_damage != 0:
		_fail("Tangent-only motion caused contact damage: %d" % tangent_damage)
	main.runtime_contact_pairs_active.clear()
	main.runtime_contact_pairs_seen.clear()
	var normal_damage := _run_pair(main, Vector2(4.0, 0.0), Vector2(-4.0, 0.0))
	if normal_damage <= 0:
		_fail("Normal closing momentum did not cause damage.")
	print("CONTACT_NORMAL_MOMENTUM_PROBE tangent=%d normal=%d" % [tangent_damage, normal_damage])
	quit()
