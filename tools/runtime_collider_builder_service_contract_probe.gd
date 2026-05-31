extends SceneTree

const SERVICE_PATH := "res://scripts/services/runtime_collider_builder_service.gd"
const FIGHTER_PATH := "res://scripts/fighter.gd"
const RuntimeColliderBuilderServiceScript := preload("res://scripts/services/runtime_collider_builder_service.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing RuntimeColliderBuilderService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name RuntimeColliderBuilderService",
		"extends RefCounted",
		"func runtime_segment_collider_payload",
		"func torso_contact_fields",
		"func default_contact_shape_kind",
		"runtime_topology",
		"independent_damage",
		"damage_proxy_torso_unit_index",
		"contact_shape_kind",
		"stiffness_momentum",
		"path_stiffness_momentum",
	]:
		if service_source.find(token) < 0:
			_fail("RuntimeColliderBuilderService missing token: %s" % token)
			return
	for forbidden in [
		"Input.",
		"FileAccess",
		"DirAccess",
		"JSON.parse_string",
		"extends Node",
		"extends Control",
		"Control.new",
		"active_units",
		"all_units",
		"TopologyPoseResolver",
		"AssemblyBoardRenderer",
		"GpuCollisionPipeline",
		"runtime_module_actions",
		"_runtime_topology_world_segments",
		"_runtime_segment_polygon_world",
		"_runtime_attack_index_for_segment",
		"_contact_fields_for_segment",
		"_default_stiffness_for_segment",
		"_default_path_stiffness_for_segment",
		"take_hit",
		"queue_free",
		"_spawn_",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("RuntimeColliderBuilderService should stay pure; found forbidden token: %s" % forbidden)
			return
	var fighter_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(FIGHTER_PATH))
	for token in [
		"const RuntimeColliderBuilderService = preload(\"res://scripts/services/runtime_collider_builder_service.gd\")",
		"var runtime_collider_builder_service: RuntimeColliderBuilderService",
		"func _runtime_collider_builder_service() -> RuntimeColliderBuilderService",
		"runtime_collider_builder_service = RuntimeColliderBuilderService.new()",
		"func _runtime_collider_payload_for_segment",
		"_runtime_collider_builder_service().runtime_segment_collider_payload",
	]:
		if fighter_source.find(token) < 0:
			_fail("fighter.gd should delegate runtime collider builder token: %s" % token)
			return
	var cached_body := _function_body(fighter_source, "func _runtime_cached_part_colliders")
	if cached_body.is_empty():
		_fail("Unable to locate _runtime_cached_part_colliders body.")
		return
	for forbidden_cached_token in [
		"damage_proxy_torso_unit_index",
		"contact_shape_kind",
		"stiffness_momentum",
		"path_stiffness_momentum",
		"contact_fields = {",
	]:
		if cached_body.contains(forbidden_cached_token):
			_fail("_runtime_cached_part_colliders should delegate payload assembly; found token: %s" % forbidden_cached_token)
			return
	var service = RuntimeColliderBuilderServiceScript.new()
	_check_torso_payload(service)
	_check_active_terminal_payload(service)
	_check_passive_limb_proxy_payload(service)
	_check_fighter_wrapper()
	print("RUNTIME_COLLIDER_BUILDER_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_torso_payload(service) -> void:
	var payload: Dictionary = service.runtime_segment_collider_payload({
		"segment": {
			"shape": "capsule",
			"part_kind": "torso",
			"node_index": 4,
			"material_class": "ceramic",
			"radius": 0.33,
		},
		"active_nodes": {},
		"runtime_polygon": [],
		"body_collider_expand": 1.0,
		"attack_index": 3,
		"contact_fields": {"damage_type": "tear", "material_class": "weapon", "contact_damage": 9.0},
		"default_stiffness": 100.0,
		"default_path_stiffness": 90.0,
	})
	if not bool(payload.get("runtime_topology", false)) or not bool(payload.get("independent_damage", false)):
		_fail("Torso payload should be runtime topology and independent damage: %s" % str(payload))
	_assert_eq(int(payload.get("part_index", -99)), -1, "torso part index")
	_assert_eq(int(payload.get("torso_unit_index", -99)), 4, "torso unit index")
	_assert_eq(String(payload.get("damage_type", "")), "blunt", "torso damage type")
	_assert_eq(String(payload.get("material_class", "")), "ceramic", "torso material")
	_assert_close(float(payload.get("contact_damage", 0.0)), 0.4, "torso contact damage")
	_assert_eq(String(payload.get("contact_shape_kind", "")), "rounded_torso", "torso contact shape")


func _check_active_terminal_payload(service) -> void:
	var payload: Dictionary = service.runtime_segment_collider_payload({
		"segment": {
			"shape": "capsule",
			"part_kind": "terminal",
			"node_index": 8,
			"torso_unit_index": 2,
			"name": "HOOK",
			"radius": 0.1,
		},
		"active_nodes": {8: true},
		"runtime_polygon": [Vector2.ZERO, Vector2(1.0, 0.0), Vector2(0.0, 1.0)],
		"body_collider_expand": 2.0,
		"attack_index": 5,
		"contact_fields": {"damage_type": "tear", "material_class": "weapon", "contact_damage": 7.0, "damage_coeff": 3.2, "break_coeff": 1.0},
		"default_stiffness": 200.0,
		"default_path_stiffness": 150.0,
	})
	if not bool(payload.get("independent_damage", false)) or payload.has("damage_proxy"):
		_fail("Active terminal should stay independently damaging without torso proxy: %s" % str(payload))
	_assert_eq(String(payload.get("shape", "")), "polygon", "active terminal shape")
	_assert_eq(int(payload.get("part_index", -99)), 5, "active terminal attack index")
	_assert_eq(String(payload.get("name", "")), "HOOK", "active terminal name")
	_assert_eq(String(payload.get("contact_shape_kind", "")), "rounded_terminal", "active terminal contact shape")
	_assert_close(float(payload.get("radius", -1.0)), 0.0, "polygon collider radius")
	_assert_close(float(payload.get("stiffness_momentum", 0.0)), 200.0, "active terminal stiffness")
	_assert_close(float(payload.get("path_stiffness_momentum", 0.0)), 150.0, "active terminal path stiffness")


func _check_passive_limb_proxy_payload(service) -> void:
	var payload: Dictionary = service.runtime_segment_collider_payload({
		"segment": {
			"shape": "capsule",
			"part_kind": "limb_muscle",
			"node_index": 6,
			"torso_unit_index": 3,
			"radius": 0.05,
		},
		"active_nodes": {},
		"runtime_polygon": [],
		"body_collider_expand": 1.5,
		"attack_index": 1,
		"contact_fields": {"damage_type": "blunt", "material_class": "body", "contact_damage": 1.0, "damage_coeff": 1.8, "break_coeff": 0.5},
		"default_stiffness": 60.0,
		"default_path_stiffness": 45.0,
	})
	if bool(payload.get("independent_damage", true)):
		_fail("Passive limb should use torso proxy damage: %s" % str(payload))
	_assert_eq(String(payload.get("damage_proxy", "")), "torso", "passive limb damage proxy")
	_assert_eq(int(payload.get("damage_proxy_torso_unit_index", -99)), 3, "passive limb torso proxy index")
	_assert_eq(String(payload.get("contact_shape_kind", "")), "rounded_limb", "passive limb contact shape")
	_assert_close(float(payload.get("radius", 0.0)), 0.075, "passive limb expanded radius")


func _check_fighter_wrapper() -> void:
	var fighter = FighterScene.new()
	var payload: Dictionary = fighter._runtime_collider_payload_for_segment({
		"shape": "capsule",
		"part_kind": "limb_muscle",
		"node_index": 2,
		"torso_unit_index": 0,
		"radius": 0.05,
		"a": Vector2.ZERO,
		"b": Vector2(1.0, 0.0),
	}, {})
	if bool(payload.get("independent_damage", true)) or String(payload.get("damage_proxy", "")) != "torso":
		_fail("Fighter wrapper should return passive limb torso proxy payload: %s" % str(payload))
	if not payload.has("stiffness_momentum") or not payload.has("path_stiffness_momentum"):
		_fail("Fighter wrapper should preserve stiffness defaults.")
	fighter.free()


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, label: String, tolerance: float = 0.001) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.6f, got %.6f." % [label, expected, actual])
