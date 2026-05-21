extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect_close(value: float, expected: float, label: String) -> void:
	if absf(value - expected) > 0.01:
		_fail("%s expected %.2f got %.2f" % [label, expected, value])


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Stiffness Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 50.0,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "M Torso", "size_tier": "M", "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.15, "material_class": "metal"},
				{"node_index": 1, "part_kind": "limb_muscle", "name": "M Limb", "size_tier": "M", "a_local": Vector2(0.2, 0.0), "b_local": Vector2(0.5, 0.0), "radius": 0.04, "material_class": "metal"},
				{"node_index": 2, "part_kind": "terminal", "terminal_weapon_kind": "melee", "name": "M Blade", "size_tier": "M", "a_local": Vector2(0.5, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.05, "damage_type": "tear", "material_class": "weapon"},
				{"node_index": 3, "part_kind": "terminal", "terminal_weapon_kind": "ranged", "name": "M Gun", "size_tier": "M", "a_local": Vector2(-0.5, 0.0), "b_local": Vector2(-0.7, 0.0), "radius": 0.05, "damage_type": "blunt", "material_class": "gun"},
				{"node_index": 4, "part_kind": "limb_muscle", "name": "XL Limb", "size_tier": "XL", "a_local": Vector2(0.0, 0.3), "b_local": Vector2(0.4, 0.3), "radius": 0.08, "material_class": "metal"},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 0.0)
	return fighter


func _init() -> void:
	var fighter = _make_fighter()
	var by_name := {}
	for raw in fighter.part_colliders():
		var c: Dictionary = raw
		by_name[String(c.get("name", ""))] = c
	var base := 768.0
	_expect_close(float(by_name["M Limb"].get("stiffness_momentum", 0.0)), base, "ordinary limb stiffness")
	_expect_close(float(by_name["M Torso"].get("stiffness_momentum", 0.0)), base * 2.0, "torso stiffness")
	_expect_close(float(by_name["M Blade"].get("stiffness_momentum", 0.0)), base * 2.0, "melee terminal stiffness")
	_expect_close(float(by_name["M Gun"].get("stiffness_momentum", 0.0)), base * 0.8, "ranged terminal stiffness")
	_expect_close(float(by_name["XL Limb"].get("stiffness_momentum", 0.0)), base * 4.0, "XL size stiffness")
	_expect_close(float(by_name["M Blade"].get("path_stiffness_momentum", 0.0)), base, "terminal path min stiffness")
	print("STIFFNESS_VALUE_PROBE ok")
	quit()
