extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_stats() -> Dictionary:
	return {
		"health": 100,
		"mass": 18.0,
		"heat_capacity": 100.0,
		"cooling": 12.0,
		"teamedit_runtime_topology": true,
		"bound_limb_allocated_momentum": 60.0,
		"runtime_topology_segments": [
			{"node_index": 0, "part_kind": "limb_muscle", "name": "A", "a_local": Vector2.ZERO, "b_local": Vector2(0.55, 0.0), "axis_local": Vector2.RIGHT, "radius": 0.04, "mass": 4.0, "joint_drive_kind": "rotation", "joint_output_momentum_base": 60.0, "allocated_limb_momentum": 60.0, "damage_type": "blunt", "normal_damage": 5},
			{"node_index": 1, "part_kind": "terminal", "name": "B", "a_local": Vector2(0.55, 0.0), "b_local": Vector2(1.05, 0.0), "axis_local": Vector2.RIGHT, "radius": 0.045, "mass": 5.0, "joint_drive_kind": "rotation", "joint_output_momentum_base": 60.0, "allocated_limb_momentum": 60.0, "terminal_weapon_kind": "melee", "damage_type": "pierce", "normal_damage": 7},
		],
	}


func _event_for_profile(profile: String) -> Dictionary:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Matrix", "owner_id": 1, "role": "hero", "stats": _base_stats()})
	fighter.deploy(0.0, 0.0)
	var module_part := {
		"name": profile,
		"module_action_profile": profile,
		"module_extension_m": 1.2 if profile.contains("extend") or profile.contains("pierce") or profile.contains("lance") or profile.contains("drill") or profile.contains("rapier") else 0.0,
		"swing_arc_degrees": 150.0,
	}
	var binding := {
		"attack_key": 1,
		"target_nodes": [0, 1] if profile == "two_link_forward_snap" or profile.begins_with("dual_") or profile == "inward_pincer_clamp" else [1],
		"module_action_profile": profile,
		"module_part": module_part,
	}
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	fighter.queue_free()
	return event


func _init() -> void:
	var profiles := [
		"two_link_forward_snap",
		"extend_2m",
		"pierce_telescopic_lunge",
		"rapier_feint_thrust",
		"lance_couched_charge",
		"drill_breach_drive",
		"reeling_hook_rip",
		"chain_backlash",
		"dual_extend_2m",
		"inward_pincer_clamp",
	]
	for profile in profiles:
		var event := _event_for_profile(profile)
		if event.is_empty():
			_fail("%s did not start runtime action." % profile)
		if bool(event.get("projectile", false)):
			_fail("%s produced projectile in melee matrix." % profile)
		if String(event.get("module_action_profile", "")) != profile:
			_fail("%s event profile mismatch." % profile)
	print("ACTION_MODULE_EXECUTION_MATRIX_PROBE ok profiles=%d" % profiles.size())
	quit()
