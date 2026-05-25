extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _generic_module(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
			return part
	return {}


func _first_rifle(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "rifle":
			return part
	return {}


func _gun_segment(part: Dictionary) -> Dictionary:
	var segment := part.duplicate(true)
	segment["node_index"] = 2
	segment["part_index"] = 2
	segment["part_kind"] = "terminal"
	segment["a_local"] = Vector2(0.7, 0.0)
	segment["b_local"] = Vector2(1.35, 0.0)
	segment["axis_local"] = Vector2.RIGHT
	segment["radius"] = maxf(0.02, float(part.get("radius", 0.05)))
	segment["terminal_weapon_kind"] = "ranged"
	segment["projectile"] = true
	segment["projectile_only"] = true
	segment["joint_output_momentum_base"] = 80.0
	segment["joint_drive_allocation"] = 80.0
	segment["allocated_limb_momentum"] = 80.0
	return segment


func _make_fighter(main):
	var module_part := _generic_module(main)
	var gun_part := _first_rifle(main)
	if module_part.is_empty() or gun_part.is_empty():
		_fail("Missing generic gun module or rifle catalog part.")
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": "gun_activate",
		"module_part": module_part.duplicate(true),
		"joint_drive_allocation_by_node": {"2": 80.0},
		"allocated_limb_momentum_by_node": {"2": 80.0},
	}
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Complex Gun Source",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 0, "part_index": 0, "part_kind": "torso", "a_local": Vector2(-0.35, 0.0), "b_local": Vector2(0.0, 0.0), "radius": 0.22},
				{"node_index": 1, "part_index": 1, "part_kind": "limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.7, 0.0), "radius": 0.07},
				_gun_segment(gun_part),
			],
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(2.0, 0.35)
	return {"fighter": fighter, "binding": binding}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var fixture: Dictionary = _make_fighter(main)
	var fighter = fixture["fighter"]
	var binding: Dictionary = fixture["binding"]
	main.active_units[1]["hero"] = fighter
	main.all_units = [fighter]
	main._start_runtime_gun_activation(1, "p1_", 0, "probe_fire", binding)
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty():
		_fail("Runtime gun activation did not create an event.")
	if int(event.get("source_gun_node", -1)) != 2 or int(event.get("source_node_index", -1)) != 2:
		_fail("Gun event should carry actual source gun node 2, got %s/%s." % [str(event.get("source_gun_node", null)), str(event.get("source_node_index", null))])
	if Array(event.get("runtime_target_nodes", [])).size() < 2 or int(Array(event.get("runtime_target_nodes", []))[-1]) != 2:
		_fail("Gun event should preserve bound target node chain ending at gun node.")
	var muzzle: Vector2 = fighter.runtime_world_segment_for_node(2, true).get("b", Vector2.INF)
	if not (event.get("muzzle_combat_position", null) is Vector2) or Vector2(event["muzzle_combat_position"]).distance_to(muzzle) > 0.01:
		_fail("Gun event muzzle should match runtime gun tip.")
	print("RUNTIME_GUN_EVENT_SOURCE_NODES_PROBE ok node=%d muzzle=%s" % [int(event.get("source_gun_node", -1)), str(event.get("muzzle_combat_position", Vector2.ZERO))])
	quit()
