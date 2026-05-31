extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

const SAMPLES := {
	"COMBO ROUTER: BALANCE STRING": ["balance_string", 1],
	"CLAMP ROUTER: VISE CLOSE": ["vise_close", 2],
	"ROUTE ROUTER: PICKUP DASH": ["pickup_dash", 1],
	"MONSTER ROUTER: CRUSH WINDUP": ["crush_windup", 1],
	"DUEL ROUTER: FEINT THRUST": ["feint_thrust", 1],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", name)
	if index < 0:
		_fail("Missing module catalog part: %s" % name)
		return {}
	return main._selected_component("hero", "module", index)


func _segments(count: int) -> Array:
	var result: Array = []
	for i in range(count):
		var y := 0.18 if i == 0 else -0.18
		result.append({
			"node_index": i,
			"part_index": i,
			"part_kind": "limb_muscle",
			"name": "Probe Limb %d" % i,
			"a_local": Vector2(0.0, y),
			"b_local": Vector2(0.8, y),
			"axis_local": Vector2.RIGHT,
			"radius": 0.08,
			"damage_type": "blunt",
			"material_class": "weapon",
			"contact_damage_mult": 0.18,
			"damage_coeff": 0.18,
			"runtime_topology": true,
		})
	return result


func _event_for(part: Dictionary, target_count: int) -> Dictionary:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var target_nodes: Array = []
	var drive_by_node := {}
	for i in range(target_count):
		target_nodes.append(i)
		drive_by_node[str(i)] = 80.0
	var binding := {
		"runtime_valid": true,
		"attack_key": 1,
		"target_nodes": target_nodes,
		"module_action_profile": String(part.get("module_action_profile", "")),
		"module_part": part.duplicate(true),
		"joint_drive_allocation_by_node": drive_by_node,
		"allocated_limb_momentum_by_node": drive_by_node.duplicate(true),
	}
	fighter.setup_unit({
		"unit_name": String(part.get("name", "Probe Module")),
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 32.0,
			"move_speed": 2.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": _segments(target_count),
			"runtime_module_bindings": [binding],
		},
	})
	fighter.deploy(0.0, 0.0)
	var before_velocity: Vector2 = fighter.velocity
	var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("%s failed to begin runtime action: %s" % [String(part.get("name", "")), String(fighter.get_meta("last_module_gate_reason", ""))])
		return {}
	if fighter.runtime_module_actions.size() != 1:
		_fail("%s did not record one runtime action." % String(part.get("name", "")))
	var action: Dictionary = Dictionary(fighter.runtime_module_actions[0])
	if String(part.get("module_variant_key", "")) == "feint_thrust":
		fighter.set_meta("gameplay_move_input_vector", Vector2.UP)
		fighter._tick_runtime_module_actions(0.03)
		if fighter.runtime_module_actions.is_empty():
			_fail("%s ended before feint startup retarget could be checked." % String(part.get("name", "")))
		action = Dictionary(fighter.runtime_module_actions[0])
	var world_segment := fighter.runtime_world_segment_for_node(0, true)
	event["_probe_action"] = action
	event["_probe_world_segment"] = world_segment
	event["_probe_velocity_delta"] = fighter.velocity - before_velocity
	fighter._tick_runtime_module_actions(99.0)
	event["_probe_combo_ready_until"] = float(fighter.get_meta("combo_balance_ready_until", 0.0))
	event["_probe_crush_result"] = String(fighter.get_meta("last_crush_windup_result", ""))
	event["_probe_crush_whiff_recovery"] = float(fighter.get_meta("last_crush_whiff_recovery", 0.0))
	fighter.queue_free()
	return event


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for raw_name in SAMPLES.keys():
		var name := String(raw_name)
		var sample: Array = Array(SAMPLES[name])
		var expected_variant := String(sample[0])
		var target_count := int(sample[1])
		var part := _module_part(main, name)
		var event := _event_for(part, target_count)
		if String(event.get("module_variant_key", "")) != expected_variant:
			_fail("%s event variant expected %s, got %s." % [name, expected_variant, String(event.get("module_variant_key", ""))])
		var action: Dictionary = Dictionary(event.get("_probe_action", {}))
		if String(action.get("module_variant_key", "")) != expected_variant:
			_fail("%s action missing variant key." % name)
		var world_segment: Dictionary = Dictionary(event.get("_probe_world_segment", {}))
		if String(world_segment.get("module_variant_key", "")) != expected_variant:
			_fail("%s dynamic world segment missing variant key." % name)
		match expected_variant:
			"balance_string":
				if float(event.get("_probe_combo_ready_until", 0.0)) <= 0.0:
					_fail("%s did not prime combo balance window on completion." % name)
			"vise_close":
				if float(event.get("clamp_pin_seconds", 0.0)) <= 0.0 or float(event.get("knock", 1.0)) >= 0.12:
					_fail("%s missing clamp pin/low knock fields." % name)
			"pickup_dash":
				var velocity_delta: Vector2 = event.get("_probe_velocity_delta", Vector2.ZERO)
				if velocity_delta.length() <= 0.01:
					_fail("%s did not apply startup dash impulse." % name)
			"crush_windup":
				if float(event.get("contact_momentum_mult", 1.0)) <= 1.0 or float(world_segment.get("runtime_contact_damage_mult", 1.0)) <= 1.0:
					_fail("%s missing crush momentum/contact fields." % name)
				if String(event.get("_probe_crush_result", "")) != "whiff" or float(event.get("_probe_crush_whiff_recovery", 0.0)) <= 0.0:
					_fail("%s did not apply whiff recovery when no hit was confirmed." % name)
			"feint_thrust":
				if float(event.get("feint_retarget_degrees", 0.0)) <= 0.0 or not bool(world_segment.get("feint_ghost_visible", false)):
					_fail("%s missing feint retarget/ghost fields." % name)
				var retarget: Vector2 = action.get("feint_retarget_direction", Vector2.RIGHT)
				if absf(rad_to_deg(Vector2.RIGHT.angle_to(retarget))) < 8.0:
					_fail("%s did not retarget during startup input." % name)
	print("MODULE_RUNTIME_VARIANT_PROBE ok samples=%d" % SAMPLES.size())
	quit()
