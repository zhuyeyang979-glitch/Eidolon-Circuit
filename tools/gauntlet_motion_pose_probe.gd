extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/gauntlet_runtime_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _axis(segment: Dictionary) -> Vector2:
	var a: Vector2 = segment.get("a", Vector2.ZERO)
	var b: Vector2 = segment.get("b", Vector2.ZERO)
	var d := b - a
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func _target_segment(fighter, target_node: int) -> Dictionary:
	for raw_segment in fighter._runtime_topology_world_segments(false, true):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -1)) == target_node:
			return Dictionary(raw_segment)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := ProbeLib.build_unit(main)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.is_empty():
		_fail("Gauntlet runtime binding missing.")
	var binding: Dictionary = bindings[0]
	var target_node := int(Array(binding.get("target_nodes", []))[0])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "GauntletPose", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var base_segment := _target_segment(fighter, target_node)
	if base_segment.is_empty():
		_fail("Gauntlet base segment missing.")
	var base_len := Vector2(base_segment.get("a", Vector2.ZERO)).distance_to(Vector2(base_segment.get("b", Vector2.ZERO)))
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Gauntlet action did not start.")
	var action: Dictionary = fighter.runtime_module_actions[0]
	var duration := float(action.get("duration", 0.68))
	action["timer"] = duration * 0.78
	fighter.runtime_module_actions[0] = action
	var startup_segment := _target_segment(fighter, target_node)
	var startup_len := Vector2(startup_segment.get("a", Vector2.ZERO)).distance_to(Vector2(startup_segment.get("b", Vector2.ZERO)))
	if startup_len <= base_len + 0.4:
		_fail("Normal gauntlet startup should extend beyond base segment length.")
	fighter._tick_runtime_module_actions(duration + 0.2)
	var final_segment := _target_segment(fighter, target_node)
	var final_axis := _axis(final_segment)
	var final_angle := absf(rad_to_deg(atan2(final_axis.y, final_axis.x)))
	if final_angle < 10.0 or final_angle > 20.0:
		_fail("Gauntlet should recover to a 15 degree guard pose, got %.2f degrees." % final_angle)
	var final_len := Vector2(final_segment.get("a", Vector2.ZERO)).distance_to(Vector2(final_segment.get("b", Vector2.ZERO)))
	if absf(final_len - base_len) > 0.08:
		_fail("Gauntlet should finish retracted to base length.")
	print("GAUNTLET_MOTION_POSE_PROBE ok base=%.2f startup=%.2f final_angle=%.2f" % [base_len, startup_len, final_angle])
	quit()
