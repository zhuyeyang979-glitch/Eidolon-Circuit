extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MotionBudget := preload("res://scripts/motion_budget.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var module_index := _module(main)
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 1,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 8.0},
		"joint_drive_allocation_by_node": {str(limb_a): 8.0},
	}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _first_limb_entry(main, unit: Dictionary) -> Dictionary:
	var payload: Dictionary = Dictionary(Array(unit.get("slot_payloads", []))[0])
	var torso := int(payload.get("torso_node", 0))
	var data: Dictionary = main._engine_momentum_allocation_data(unit, torso, 0)
	for raw_entry in Array(data.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "limb":
			return Dictionary(raw_entry)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_panel_mode = "parts"
	main.editor_working_role_key = "hero"
	var unit := _unit(main)
	main.editor_working_blueprint = unit
	var entry := _first_limb_entry(main, unit)
	if entry.is_empty():
		_fail("Missing limb duration entry.")
		return
	if not String(entry.get("duration_label", "")).contains("时长") and not String(entry.get("duration_label", "")).contains("DUR"):
		_fail("Limb entry should show duration estimate text.")
		return
	var duration_a := float(entry.get("duration_estimate", 0.0))
	if duration_a <= 0.0:
		_fail("Duration estimate should be positive.")
		return
	var module_part: Dictionary = Dictionary(entry.get("duration_module_part", {}))
	var motion: Dictionary = Dictionary(entry.get("duration_motion_stats", {}))
	motion["output"] = float(entry.get("momentum", 0.0))
	motion["allocated_limb_momentum"] = float(entry.get("momentum", 0.0))
	var helper := MotionBudget.estimate_motion_budget(motion, module_part, float(entry.get("duration_angle_degrees", 180.0)), float(entry.get("duration_extension_m", 0.0)), float(entry.get("duration_fallback", 0.72)), "normal")
	if absf(float(helper.get("duration", 0.0)) - duration_a) > 0.001:
		_fail("Editor duration estimate does not match MotionBudget helper.")
		return
	var slow := entry.duplicate(true)
	var slow_motion: Dictionary = Dictionary(slow.get("duration_motion_stats", {}))
	slow_motion["mass"] = float(slow_motion.get("mass", 1.0)) * 2.0
	slow["duration_motion_stats"] = slow_motion
	slow = main._engine_allocation_entry_with_duration(slow, 2.0)
	var slow_duration := float(slow.get("duration_estimate", 0.0))
	if slow_duration <= 0.12 or slow_duration >= 6.0:
		_fail("Monotonic duration fixture should stay outside clamp boundaries, got %.3f." % slow_duration)
		return
	var higher := main._engine_allocation_entry_with_duration(slow, 4.0)
	if float(higher.get("duration_estimate", 0.0)) >= slow_duration:
		_fail("Increasing drive allocation should shorten duration.")
		return
	var heavier := slow.duplicate(true)
	var heavy_motion: Dictionary = Dictionary(heavier.get("duration_motion_stats", {}))
	heavy_motion["mass"] = float(heavy_motion.get("mass", 1.0)) * 1.5
	heavier["duration_motion_stats"] = heavy_motion
	heavier = main._engine_allocation_entry_with_duration(heavier, 2.0)
	if float(heavier.get("duration_estimate", 0.0)) <= slow_duration:
		_fail("Increasing driven mass should lengthen duration.")
		return
	var saturated := slow.duplicate(true)
	var saturated_motion: Dictionary = Dictionary(saturated.get("duration_motion_stats", {}))
	saturated_motion["mass"] = float(saturated_motion.get("mass", 1.0)) * 10.0
	saturated["duration_motion_stats"] = saturated_motion
	saturated = main._engine_allocation_entry_with_duration(saturated, 2.0)
	var saturated_duration := float(saturated.get("duration_estimate", 0.0))
	if absf(saturated_duration - 6.0) > 0.001:
		_fail("Duration estimate should clamp saturated motion to 6 seconds, got %.3f." % saturated_duration)
		return
	print("POWER_ALLOCATION_PANEL_DURATION_ESTIMATE_PROBE ok base=%.3f slow=%.3f high=%.3f heavy=%.3f capped=%.3f" % [duration_a, slow_duration, float(higher.get("duration_estimate", 0.0)), float(heavier.get("duration_estimate", 0.0)), saturated_duration])
	quit(0)
