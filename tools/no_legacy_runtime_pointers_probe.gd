extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "NoLegacyRuntimePointers",
		"stats": {
			"health": 100,
			"mass": 20.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_kind": "torso", "name": "Torso", "polygon_local": [Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.1), Vector2(-0.2, 0.1)], "radius": 0.1},
			],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(0.0, 0.0)
	var forbidden_stat_keys := ["attack_groups", "action_groups", "child_hull", "legacy_swing_90", "legacy_extend_1m", "legacy_extend_2m"]
	for key in forbidden_stat_keys:
		if fighter.stats.has(key):
			_fail("Runtime stats still expose old pointer key: %s" % key)
			return
	var forbidden := [
		"shell",
		"joint_a",
		"joint_b",
		"muscle_a",
		"muscle_b",
		"special_core",
		"topology_line",
	]
	for child in fighter.get_children():
		if forbidden.has(String(child.name)):
			_fail("Saved runtime unit created legacy visual/collider pointer: %s" % child.name)
			return
	if fighter.stats.has("attack_groups") and Array(fighter.stats.get("attack_groups", [])).size() > 0:
		_fail("Saved runtime unit should not carry attack_groups.")
		return
	for raw_segment in Array(fighter.stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary:
			var segment: Dictionary = raw_segment
			for key in segment.keys():
				var key_string := String(key)
				if key_string.begins_with("legacy_") or key_string in ["a_socket", "b_socket", "attack_group"]:
					_fail("Runtime segment still exposes old pointer key: %s" % key_string)
					return
	for raw_binding in Array(fighter.stats.get("runtime_module_bindings", [])):
		if raw_binding is Dictionary:
			var binding: Dictionary = raw_binding
			if String(binding.get("module_action_profile", "")).begins_with("legacy_"):
				_fail("Runtime binding still exposes legacy module profile.")
				return
	print("NO_LEGACY_RUNTIME_POINTERS_PROBE ok")
	quit()
