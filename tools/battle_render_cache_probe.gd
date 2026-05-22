extends SceneTree


const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _runtime_stats() -> Dictionary:
	return {
		"teamedit_runtime_topology": true,
		"health": 100,
		"mass": 20.0,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"name": "Probe Torso",
				"a_local": Vector2(-0.24, 0.0),
				"b_local": Vector2(0.24, 0.0),
				"axis_local": Vector2.RIGHT,
				"radius": 0.12,
				"shape": "polygon",
				"polygon_local": [Vector2(-0.24, -0.12), Vector2(0.24, -0.12), Vector2(0.24, 0.12), Vector2(-0.24, 0.12)],
			},
			{
				"node_index": 1,
				"part_kind": "limb_muscle",
				"name": "Probe Limb",
				"a_local": Vector2(0.24, 0.0),
				"b_local": Vector2(0.74, 0.0),
				"axis_local": Vector2.RIGHT,
				"radius": 0.045,
			},
		],
		"runtime_module_bindings": [],
	}


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({"owner_id": 1, "role": "hero", "stats": _runtime_stats()})
	fighter.deploy(0.0, 0.0)
	var first_segments: Array = fighter._runtime_topology_world_segments(true, true)
	var builds_after_first := int(fighter.runtime_geometry_cache_builds)
	var second_segments: Array = fighter._runtime_topology_world_segments(true, true)
	if second_segments.size() != first_segments.size():
		_fail("Cached runtime segment count changed.")
	if int(fighter.runtime_geometry_cache_builds) != builds_after_first:
		_fail("Static fighter rebuilt runtime segments on repeated query.")
	var first_colliders: Array = fighter.part_colliders()
	var collider_builds_after_first := int(fighter.runtime_geometry_collider_builds)
	var second_colliders: Array = fighter.part_colliders()
	if second_colliders.size() != first_colliders.size():
		_fail("Cached collider count changed.")
	if int(fighter.runtime_geometry_collider_builds) != collider_builds_after_first:
		_fail("Static fighter rebuilt colliders on repeated query.")
	if int(fighter.runtime_geometry_cache_hits) <= 0:
		_fail("Runtime geometry cache recorded no hits.")
	print("BATTLE_RENDER_CACHE_PROBE ok segments=%d colliders=%d hits=%d" % [first_segments.size(), first_colliders.size(), int(fighter.runtime_geometry_cache_hits)])
	quit(0)
