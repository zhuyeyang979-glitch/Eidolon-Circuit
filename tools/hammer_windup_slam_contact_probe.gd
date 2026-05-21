extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/blunt_terminal_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _target_segment(fighter, node_index: int) -> Dictionary:
	for raw_segment in fighter._runtime_topology_world_segments(false, true):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -1)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := ProbeLib.first_module(main, "blunt_hammer_windup_slam")
	var hammer_index := ProbeLib.first_part(main, func(part): return bool(part.get("blunt_hammer", false)))
	var unit_bp := ProbeLib.build_unit(main, hammer_index, module_index, "hammer_terminal", "HAMMER")
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var binding: Dictionary = Dictionary(Array(stats.get("runtime_module_bindings", []))[0])
	var target_node := int(Array(binding.get("target_nodes", []))[0])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "HammerContact", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("active", binding, Vector2.LEFT)
	if event.is_empty():
		_fail("Hammer Windup-Slam did not start.")
	var segment := _target_segment(fighter, target_node)
	var collider := {
		"runtime_topology": true,
		"node_index": target_node,
		"part_kind": "terminal",
		"shape": "capsule",
		"a": segment.get("a", Vector2.ZERO),
		"b": segment.get("b", Vector2.ZERO),
		"pivot": segment.get("a", Vector2.ZERO),
	}
	if fighter._runtime_action_contact_velocity_for_collider(collider).length() <= 0.01:
		_fail("Hammer Windup-Slam contact must come from runtime action velocity.")
	if bool(event.get("projectile", false)):
		_fail("Hammer Windup-Slam contact must not be projectile damage.")
	print("HAMMER_WINDUP_SLAM_CONTACT_PROBE ok")
	quit()
