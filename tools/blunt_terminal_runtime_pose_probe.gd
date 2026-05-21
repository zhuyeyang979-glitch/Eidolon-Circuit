extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/blunt_terminal_probe_lib.gd")


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


func _check_runtime(main, profile: String, flag: String, target_kind: String, label: String, action_state: String) -> void:
	var module_index := ProbeLib.first_module(main, profile)
	var terminal_index := ProbeLib.first_part(main, func(part): return bool(part.get(flag, false)))
	if module_index < 0 or terminal_index < 0:
		_fail("%s module or terminal missing." % profile)
	var unit_bp := ProbeLib.build_unit(main, terminal_index, module_index, target_kind, label)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var bindings: Array = stats.get("runtime_module_bindings", [])
	if bindings.is_empty() or not bool(Dictionary(bindings[0]).get("runtime_valid", false)):
		_fail("%s runtime binding missing." % profile)
	var binding: Dictionary = bindings[0]
	var target_node := int(Array(binding.get("target_nodes", []))[0])
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": label, "stats": stats})
	fighter.deploy(0.0, 0.0)
	var base_segment := _target_segment(fighter, target_node)
	var base_axis := _axis(base_segment)
	var event: Dictionary = fighter.begin_runtime_module_action(action_state, binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("%s action did not start: %s" % [profile, String(fighter.get_meta("last_module_gate_reason", ""))])
	if bool(event.get("projectile", false)) or String(event.get("projectile_behavior", "")) != "":
		_fail("%s must not create projectile fields." % profile)
	var action: Dictionary = fighter.runtime_module_actions[0]
	var duration := float(action.get("duration", 0.6))
	action["timer"] = duration * 0.65
	fighter.runtime_module_actions[0] = action
	var moving_segment := _target_segment(fighter, target_node)
	var moving_axis := _axis(moving_segment)
	if absf(rad_to_deg(base_axis.angle_to(moving_axis))) < 8.0:
		_fail("%s should visibly rotate its terminal during runtime pose." % profile)
	if float(event.get("runtime_contact_speed", 0.0)) <= 0.01:
		_fail("%s should provide contact speed for real collision." % profile)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_check_runtime(main, "blunt_shield_guard_bash", "blunt_shield", "shield_terminal", "SHIELD", "armor")
	_check_runtime(main, "blunt_hammer_windup_slam", "blunt_hammer", "hammer_terminal", "HAMMER", "active")
	print("BLUNT_TERMINAL_RUNTIME_POSE_PROBE ok")
	quit()
