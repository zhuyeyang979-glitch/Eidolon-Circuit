extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "ActiveLimbColliderProbe",
		"stats": {
			"health": 100,
			"mass": 20.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Torso", "polygon_local": [Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.1), Vector2(-0.2, 0.1)], "radius": 0.1},
				{"node_index": 1, "part_kind": "limb_muscle", "name": "Active Limb", "a_local": Vector2(0.2, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.04},
				{"node_index": 2, "part_kind": "terminal", "name": "Active Weapon", "a_local": Vector2(0.7, 0.0), "b_local": Vector2(0.95, 0.0), "radius": 0.05},
			],
			"runtime_module_bindings": [],
		},
	})
	unit.deploy(0.0, 0.0)
	return unit


func _init() -> void:
	var unit = _make_unit()
	unit.runtime_module_actions = [{
		"profile": "two_link_forward_snap",
		"target_nodes": [1, 2],
		"timer": 0.1,
		"duration": 1.0,
	}]
	var colliders: Array = unit.part_colliders()
	var kinds := []
	for raw in colliders:
		if raw is Dictionary:
			var collider: Dictionary = raw
			kinds.append(String(collider.get("part_kind", "")))
			if String(collider.get("part_kind", "")) != "torso" and not bool(collider.get("independent_damage", false)):
				_fail("Active bound limb/terminal should have independent damage: %s" % str(collider))
				return
	if not kinds.has("torso") or not kinds.has("limb_muscle") or not kinds.has("terminal"):
		_fail("Active module should expose torso plus bound limb/terminal colliders, got %s" % str(kinds))
		return
	print("ACTIVE_LIMB_COLLISION_ONLY_DURING_MODULE_PROBE ok")
	quit()
