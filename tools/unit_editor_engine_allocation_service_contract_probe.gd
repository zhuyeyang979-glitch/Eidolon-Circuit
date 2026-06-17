extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_engine_allocation_service.gd"
const Service := preload("res://scripts/services/unit_editor_engine_allocation_service.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))


func _stats() -> Dictionary:
	return {
		"runtime_topology_segments": [
			{
				"node_index": 1,
				"part_kind": "limb",
				"joint_drive_kind": "hinge",
				"name": "Flex Tendon",
				"momentum_min": 2.0,
				"momentum_max": 10.0,
				"allocated_limb_momentum": 4.0,
				"joint_output_momentum_base": 2.0,
				"a": Vector2.ZERO,
				"b": Vector2(1.0, 0.0),
				"mass": 1.2,
			},
		],
	}


func _payload_torso_node_index(payload: Dictionary, _unit_bp: Dictionary) -> int:
	return int(payload.get("torso_node", -1))


func _payload_part_for_payload(_role_key: String, payload: Dictionary) -> Dictionary:
	match String(payload.get("kind", "")):
		"engine":
			return {"name": "Pulse Engine", "stable_key": "engine_pulse"}
		"booster":
			return {"name": "Vector Booster", "stable_key": "booster_vector", "boost_heat": 6.0}
		"module":
			return {"name": "Snap Module", "stable_key": "module_snap", "swing_arc_degrees": 120.0}
	return {"name": "Unknown"}


func _topology_node_part(_role_key: String, _node: Dictionary, _unit_bp: Dictionary) -> Dictionary:
	return {"name": "Crab Core", "stable_key": "torso_crab"}


func _engine_allocation_pool_for_torso(_unit_bp: Dictionary, _torso_node_index: int) -> float:
	return 20.0


func _thermal_load_pool_for_stats(_stats: Dictionary) -> float:
	return 10.0


func _engine_allocation_engine_idle_heat_for_torso(_unit_bp: Dictionary, _torso_node_index: int) -> float:
	return 1.0


func _thruster_with_drive_defaults(part: Dictionary) -> Dictionary:
	var result := part.duplicate(true)
	result["boost_heat"] = float(part.get("boost_heat", 6.0))
	return result


func _engine_allocation_sorted_binding_refs(unit_bp: Dictionary) -> Array:
	var refs: Array = []
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	for i in range(bindings.size()):
		if bindings[i] is Dictionary:
			refs.append({"index": i, "slot": int(Dictionary(bindings[i]).get("software_slot_index", 999999)), "binding": bindings[i]})
	return refs


func _module_binding_torso_node_index(_role_key: String, _unit_bp: Dictionary, binding: Dictionary) -> int:
	return int(binding.get("target_torso_node", -1))


func _engine_allocation_limb_momentum_for_node(_binding: Dictionary, _node_index: int, _segment: Dictionary) -> float:
	return 4.0


func _engine_allocation_default_limb_momentum(_segment: Dictionary) -> float:
	return 2.0


func _engine_allocation_limb_duration_estimate(_segment: Dictionary, _module_part: Dictionary, momentum: float) -> Dictionary:
	return {"duration": 1.0 / maxf(1.0, momentum)}


func _engine_allocation_limb_motion_context(_segment: Dictionary, _module_part: Dictionary) -> Dictionary:
	return {
		"motion_stats": {"mass": 1.2, "length": 1.0},
		"angle_degrees": 120.0,
		"extension_m": 0.0,
		"fallback_duration": 0.72,
	}


func _engine_allocation_limb_duration_label(_module_part: Dictionary, min_momentum: float, max_momentum: float, duration_estimate: float) -> String:
	return "DUR %.2fs %.0f-%.0f" % [duration_estimate, min_momentum, max_momentum]


func _editor_int_array_signature(values: Array) -> String:
	var bits: Array = []
	for raw_value in values:
		bits.append(str(int(raw_value)))
	return ",".join(bits)


func _callbacks() -> Dictionary:
	return {
		"editor_current_stats": Callable(self, "_stats"),
		"payload_torso_node_index": Callable(self, "_payload_torso_node_index"),
		"payload_part_for_payload": Callable(self, "_payload_part_for_payload"),
		"topology_node_part": Callable(self, "_topology_node_part"),
		"engine_allocation_pool_for_torso": Callable(self, "_engine_allocation_pool_for_torso"),
		"thermal_load_pool_for_stats": Callable(self, "_thermal_load_pool_for_stats"),
		"engine_allocation_engine_idle_heat_for_torso": Callable(self, "_engine_allocation_engine_idle_heat_for_torso"),
		"thruster_drive_allocation_min_for_part": Callable(func(_part: Dictionary) -> float: return 3.0),
		"thruster_drive_allocation_max_for_part": Callable(func(_part: Dictionary) -> float: return 9.0),
		"thruster_drive_allocated_for_payload": Callable(func(_payload: Dictionary, _part: Dictionary) -> float: return 4.0),
		"thruster_boost_brake_allocation_min_for_part": Callable(func(_part: Dictionary) -> float: return 1.0),
		"thruster_boost_brake_allocation_max_for_part": Callable(func(_part: Dictionary) -> float: return 5.0),
		"thruster_boost_brake_allocated_for_payload": Callable(func(_payload: Dictionary, _part: Dictionary) -> float: return 2.0),
		"thruster_idle_heat_coeff_for_part": Callable(func(_part: Dictionary) -> float: return 0.1),
		"thruster_with_drive_defaults": Callable(self, "_thruster_with_drive_defaults"),
		"short_part_display_name": Callable(func(part: Dictionary, fallback: String = "") -> String: return String(part.get("name", fallback))),
		"short_part_name": Callable(func(part_name: String) -> String: return part_name),
		"engine_allocation_sorted_binding_refs": Callable(self, "_engine_allocation_sorted_binding_refs"),
		"module_binding_torso_node_index": Callable(self, "_module_binding_torso_node_index"),
		"engine_allocation_limb_momentum_for_node": Callable(self, "_engine_allocation_limb_momentum_for_node"),
		"engine_allocation_default_limb_momentum": Callable(self, "_engine_allocation_default_limb_momentum"),
		"engine_allocation_limb_duration_estimate": Callable(self, "_engine_allocation_limb_duration_estimate"),
		"engine_allocation_limb_motion_context": Callable(self, "_engine_allocation_limb_motion_context"),
		"limb_drive_heat_coeff_for_segment": Callable(func(_segment: Dictionary, _module_part: Dictionary) -> float: return 0.2),
		"engine_allocation_limb_duration_label": Callable(self, "_engine_allocation_limb_duration_label"),
		"editor_int_array_signature": Callable(self, "_editor_int_array_signature"),
		"zh_part_name": Callable(func(part_name: String) -> String: return "ZH_" + part_name),
	}


func _entry_by_kind(data: Dictionary, kind: String) -> Dictionary:
	for raw_entry in Array(data.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == kind:
			return Dictionary(raw_entry)
	return {}


func _assert_source_guardrails() -> void:
	var main_source := _source("res://scripts/main.gd")
	var service_source := _source(SERVICE_PATH)
	var wrapper_start := main_source.find("func _engine_momentum_allocation_data")
	var next_func := main_source.find("\n\nfunc ", wrapper_start + 1)
	var wrapper := main_source.substr(wrapper_start, next_func - wrapper_start)
	_assert(wrapper.find("_unit_editor_engine_allocation_service().allocation_data") >= 0, "main.gd wrapper should delegate engine allocation model construction.")
	_assert(wrapper.find("for ") < 0, "main.gd engine allocation wrapper should stay thin and loop-free.")
	_assert(main_source.find("UnitEditorEngineAllocationService") >= 0, "main.gd should preload and own UnitEditorEngineAllocationService.")
	_assert(service_source.find("func allocation_data") >= 0, "Engine allocation service should own allocation_data.")
	for forbidden in ["extends Node", "Control", "CanvasItem", "DisplayServer", "Input.", "FileAccess"]:
		_assert(service_source.find(forbidden) < 0, "Engine allocation service should stay free of UI/runtime dependency %s." % forbidden)


func _init() -> void:
	if load(SERVICE_PATH) == null:
		_fail("Missing UnitEditorEngineAllocationService script.")
		quit(1)
		return
	_assert_source_guardrails()
	var service = Service.new()
	var unit_bp := {
		"role": "hero",
		"custom_topology": {"nodes": [{"slot": "muscle", "part_index": 0}, {"slot": "limb_muscle", "part_index": 0}]},
		"slot_payloads": [
			{"kind": "engine", "engine": 0, "torso_node": 0},
			{"kind": "booster", "booster": 0, "torso_node": 0},
			{"kind": "module", "module": 0, "torso_node": 0},
		],
		"module_bindings": [
			{"software_slot_index": 2, "target_torso_node": 0, "root_index": 1, "target_nodes": [1]},
		],
	}
	var data: Dictionary = service.allocation_data(unit_bp, 0, 0, _callbacks(), false, "hero")
	_assert(not data.is_empty(), "Valid torso and engine payload should produce allocation data.")
	_assert(String(data.get("title", "")) == "DRIVE BUDGET", "English allocation title should be stable.")
	_assert(absf(float(data.get("engine_output", 0.0)) - 20.0) < 0.001, "Engine pool should come from callback.")
	_assert(bool(data.get("has_engine", false)), "Model should mark engine payload as present.")
	_assert(Array(data.get("entries", [])).size() == 3, "Model should include drive, boost-brake, and limb entries.")
	var drive_entry := _entry_by_kind(data, "booster_drive")
	var boost_entry := _entry_by_kind(data, "booster_boost_brake")
	var limb_entry := _entry_by_kind(data, "limb")
	_assert(String(drive_entry.get("id", "")) == "booster_drive:1", "Drive entry id should preserve payload index.")
	_assert(String(boost_entry.get("id", "")) == "booster_boost_brake:1", "Boost entry id should preserve payload index.")
	_assert(String(limb_entry.get("id", "")) == "limb:0:1", "Limb entry id should preserve binding and node index.")
	_assert(float(limb_entry.get("duration_estimate", 0.0)) > 0.0, "Limb entry should include duration estimate.")
	_assert(float(data.get("heat_used", 0.0)) > 1.0, "Heat summary should include engine idle and allocation heat.")
	_assert(Array(data.get("allocation_groups", [])).size() == 1, "Limb binding should produce one allocation group.")
	var invalid_engine: Dictionary = service.allocation_data(unit_bp, 0, 1, _callbacks(), false, "hero")
	_assert(invalid_engine.is_empty(), "Non-engine payload index should be rejected.")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_ENGINE_ALLOCATION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
