extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Coeff Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 50.0,
			"torso_break_threshold": 4.0,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Probe Torso", "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.15, "material_class": "metal"},
				{"node_index": 1, "part_kind": "limb_muscle", "name": "Probe Limb", "a_local": Vector2(0.2, 0.0), "b_local": Vector2(0.5, 0.0), "radius": 0.04, "material_class": "metal"},
				{"node_index": 2, "part_kind": "terminal", "terminal_weapon_kind": "melee", "name": "Probe Blade", "a_local": Vector2(0.5, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.05, "damage_type": "tear", "material_class": "weapon"},
				{"node_index": 3, "part_kind": "terminal", "terminal_weapon_kind": "ranged", "name": "Probe Gun", "a_local": Vector2(-0.5, 0.0), "b_local": Vector2(-0.7, 0.0), "radius": 0.05, "damage_type": "blunt", "material_class": "gun"},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 0.0)
	return fighter


func _expect_close(value: float, expected: float, label: String) -> void:
	if absf(value - expected) > 0.001:
		_fail("%s expected %.3f got %.3f" % [label, expected, value])


func _init() -> void:
	var fighter = _make_fighter()
	var by_name := {}
	for raw in fighter.part_colliders():
		var c: Dictionary = raw
		by_name[String(c.get("name", ""))] = c
	_expect_close(float(by_name["Probe Torso"].get("damage_coeff", -1.0)), 1.0, "torso damage_coeff")
	_expect_close(float(by_name["Probe Torso"].get("break_coeff", -1.0)), 0.5, "torso break_coeff")
	_expect_close(float(by_name["Probe Limb"].get("damage_coeff", -1.0)), 1.0, "limb damage_coeff")
	_expect_close(float(by_name["Probe Limb"].get("break_coeff", -1.0)), 0.5, "limb break_coeff")
	_expect_close(float(by_name["Probe Blade"].get("damage_coeff", -1.0)), 2.5, "melee terminal damage_coeff")
	_expect_close(float(by_name["Probe Blade"].get("break_coeff", -1.0)), 1.0, "melee terminal break_coeff")
	_expect_close(float(by_name["Probe Gun"].get("damage_coeff", -1.0)), 0.8, "ranged terminal damage_coeff")
	_expect_close(float(by_name["Probe Gun"].get("break_coeff", -1.0)), 0.5, "ranged terminal break_coeff")
	print("PART_DAMAGE_COEFF_PROBE ok")
	quit()
