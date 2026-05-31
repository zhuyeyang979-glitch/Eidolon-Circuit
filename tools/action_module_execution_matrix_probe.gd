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
		"joint_drive_allocation_total": 60.0,
		"runtime_topology_segments": [
			{"node_index": 0, "part_kind": "limb_muscle", "name": "A", "a_local": Vector2.ZERO, "b_local": Vector2(0.55, 0.0), "axis_local": Vector2.RIGHT, "radius": 0.04, "mass": 4.0, "joint_drive_kind": "rotation", "joint_output_momentum_base": 60.0, "joint_drive_allocation": 60.0, "damage_type": "blunt", "normal_damage": 5},
			{"node_index": 1, "part_kind": "terminal", "name": "B", "a_local": Vector2(0.55, 0.0), "b_local": Vector2(1.05, 0.0), "axis_local": Vector2.RIGHT, "radius": 0.045, "mass": 5.0, "joint_drive_kind": "rotation", "joint_output_momentum_base": 60.0, "joint_drive_allocation": 60.0, "terminal_weapon_kind": "melee", "damage_type": "blunt", "normal_damage": 7, "joint_extension_m": 1.2},
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
		"module_extension_m": 0.0 if profile == "boot_action_driver" else (1.2 if profile.contains("extend") or profile.contains("pierce") or profile.contains("lance") or profile.contains("drill") or profile.contains("rapier") else 0.0),
		"swing_arc_degrees": 150.0,
	}
	if profile == "boot_action_driver":
		module_part["startup_ratio"] = 0.333333
		module_part["recovery_ratio"] = 0.666667
		module_part["damage_type"] = "blunt"
		module_part["projectile"] = false
	var binding := {
		"attack_key": 1,
		"target_nodes": [0, 1] if profile == "boot_action_driver" or profile == "two_link_forward_snap" or profile.begins_with("dual_") or profile == "inward_pincer_clamp" else [1],
		"module_action_profile": profile,
		"module_part": module_part,
	}
	if profile == "boot_action_driver":
		binding["target_kind"] = "boot_driver_limb_group"
		binding["boot_driver_rotating_node"] = 0
		binding["boot_driver_weapon_node"] = 1
		binding["boot_driver_extension_m"] = 1.2
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	fighter.queue_free()
	return event


func _init() -> void:
	var profiles := [
		"boot_action_driver",
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
