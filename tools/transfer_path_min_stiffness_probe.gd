extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect_close(value: float, expected: float, label: String) -> void:
	if absf(value - expected) > 0.01:
		_fail("%s expected %.2f got %.2f" % [label, expected, value])


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Path Stiffness Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 60.0,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "M Torso", "size_tier": "M", "a_local": Vector2(-0.25, 0.0), "b_local": Vector2(0.25, 0.0), "radius": 0.16, "material_class": "metal"},
				{"node_index": 1, "part_kind": "limb_muscle", "name": "M Limb", "size_tier": "M", "a_local": Vector2(0.25, 0.0), "b_local": Vector2(0.55, 0.0), "radius": 0.04, "material_class": "metal"},
				{"node_index": 2, "part_kind": "terminal", "terminal_weapon_kind": "melee", "name": "M Blade", "size_tier": "M", "a_local": Vector2(0.55, 0.0), "b_local": Vector2(0.8, 0.0), "radius": 0.05, "damage_type": "tear", "material_class": "weapon"},
				{"node_index": 3, "part_kind": "terminal", "terminal_weapon_kind": "ranged", "name": "M Gun", "size_tier": "M", "a_local": Vector2(-0.55, 0.0), "b_local": Vector2(-0.8, 0.0), "radius": 0.05, "damage_type": "blunt", "material_class": "gun"},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 0.0)
	fighter.runtime_module_actions = [{
		"profile": "probe_active_limb",
		"target_nodes": [1, 2, 3],
		"timer": 0.1,
		"duration": 1.0,
	}]
	var by_name := {}
	for raw in fighter.part_colliders():
		var collider: Dictionary = raw
		by_name[String(collider.get("name", ""))] = collider
	var base := 768.0
	_expect_close(float(by_name["M Torso"].get("path_stiffness_momentum", 0.0)), base * 2.0, "torso path")
	_expect_close(float(by_name["M Limb"].get("path_stiffness_momentum", 0.0)), base, "limb path")
	_expect_close(float(by_name["M Blade"].get("path_stiffness_momentum", 0.0)), base, "melee terminal path min")
	_expect_close(float(by_name["M Gun"].get("path_stiffness_momentum", 0.0)), base * 0.8, "ranged terminal path min")
	print("TRANSFER_PATH_MIN_STIFFNESS_PROBE ok")
	quit()
