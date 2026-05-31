extends SceneTree

const SERVICE_PATH := "res://scripts/services/runtime_collider_geometry_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const FIGHTER_PATH := "res://scripts/fighter.gd"
const RuntimeColliderGeometryServiceScript := preload("res://scripts/services/runtime_collider_geometry_service.gd")
const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing RuntimeColliderGeometryService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name RuntimeColliderGeometryService",
		"extends RefCounted",
		"func collider_center",
		"func collider_extent_radius",
		"func collider_bounding_radius",
		"func collider_broadphase_gap",
		"func collider_overlap_depth_estimate",
		"func collider_hit_position",
		"func collider_segments",
		"func collider_gap",
		"func collider_with_bounds",
		"func scale_collider_around_center",
		"func shift_collider_by_offset",
		"func point_in_polygon",
		"func polygon_collider_distance",
		"func point_segment_distance",
		"func segment_segment_distance",
		"func segments_intersect",
	]:
		if service_source.find(token) < 0:
			_fail("RuntimeColliderGeometryService missing token: %s" % token)
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
		"GpuCollisionPipeline",
		"AssemblyBoardRenderer",
		"_spawn_",
		"take_hit",
		"queue_free",
		"runtime_module_actions",
		"damage_intent",
		"heat",
	]:
		if service_source.find(forbidden) >= 0:
			_fail("RuntimeColliderGeometryService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const RuntimeColliderGeometryService = preload(\"res://scripts/services/runtime_collider_geometry_service.gd\")",
		"var runtime_collider_geometry_service: RuntimeColliderGeometryService",
		"runtime_collider_geometry_service = RuntimeColliderGeometryService.new()",
		"func _runtime_collider_geometry_service() -> RuntimeColliderGeometryService",
		"_runtime_collider_geometry_service().scale_collider_around_center",
		"_runtime_collider_geometry_service().shift_collider_by_offset",
		"_runtime_collider_geometry_service().collider_center",
		"_runtime_collider_geometry_service().collider_gap",
		"_runtime_collider_geometry_service().collider_bounding_radius",
		"_runtime_collider_geometry_service().polygon_collider_distance",
		"_runtime_collider_geometry_service().segments_intersect",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate collider geometry token: %s" % token)
			return
	var fighter_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(FIGHTER_PATH))
	for token in [
		"const RuntimeColliderGeometryService = preload(\"res://scripts/services/runtime_collider_geometry_service.gd\")",
		"var runtime_collider_geometry_service: RuntimeColliderGeometryService",
		"func _runtime_collider_geometry_service() -> RuntimeColliderGeometryService",
		"runtime_collider_geometry_service = RuntimeColliderGeometryService.new()",
		"return _runtime_collider_geometry_service().collider_with_bounds(collider)",
	]:
		if fighter_source.find(token) < 0:
			_fail("fighter.gd should delegate collider geometry token: %s" % token)
			return
	var service = RuntimeColliderGeometryServiceScript.new()
	_check_circle_capsule_math(service)
	_check_polygon_math(service)
	_check_transform_math(service)
	_check_owner_wrappers(service)
	print("RUNTIME_COLLIDER_GEOMETRY_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _check_circle_capsule_math(service) -> void:
	var circle_a := {"shape": "circle", "center": Vector2.ZERO, "radius": 0.5}
	var circle_b := {"shape": "circle", "center": Vector2(1.25, 0.0), "radius": 0.5}
	_assert_vec(service.collider_center(circle_a), Vector2.ZERO, "circle center")
	_assert_close(service.collider_extent_radius(circle_a), 0.5, "circle extent radius")
	_assert_close(service.collider_bounding_radius(circle_a), 0.5, "circle bounding radius")
	_assert_close(service.collider_gap(circle_a, circle_b), 0.25, "circle gap")
	_assert_close(service.collider_broadphase_gap(circle_a, circle_b), 0.25, "circle broadphase gap")
	_assert_vec(service.collider_hit_position(circle_a, circle_b), Vector2(0.625, 0.0), "circle hit position")
	var overlap_circle := {"shape": "circle", "center": Vector2(0.25, 0.0), "radius": 0.5}
	_assert_close(service.collider_overlap_depth_estimate(circle_a, overlap_circle), 0.12, "clamped overlap depth")
	var capsule := {"shape": "capsule", "a": Vector2.ZERO, "b": Vector2(2.0, 0.0), "radius": 0.2}
	_assert_vec(service.collider_center(capsule), Vector2(1.0, 0.0), "capsule center")
	_assert_close(service.collider_extent_radius(capsule), 1.2, "capsule extent radius")
	if service.collider_segments(capsule).size() != 1:
		_fail("Capsule should expose one segment.")
	_assert_close(service.point_segment_distance(Vector2(1.0, 1.0), Vector2.ZERO, Vector2(2.0, 0.0)), 1.0, "point segment distance")
	if not service.segments_intersect(Vector2.ZERO, Vector2(1.0, 1.0), Vector2(0.0, 1.0), Vector2(1.0, 0.0)):
		_fail("Diagonal segments should intersect.")
	_assert_close(service.segment_segment_distance(Vector2.ZERO, Vector2(1.0, 1.0), Vector2(0.0, 1.0), Vector2(1.0, 0.0)), 0.0, "intersecting segment distance")


func _check_polygon_math(service) -> void:
	var square := {
		"shape": "polygon",
		"polygon": [
			Vector2.ZERO,
			Vector2(1.0, 0.0),
			Vector2(1.0, 1.0),
			Vector2(0.0, 1.0),
		],
	}
	_assert_vec(service.collider_center(square), Vector2(0.5, 0.5), "polygon center")
	if service.collider_segments(square).size() != 4:
		_fail("Square should expose four segments.")
	if not service.point_in_polygon(Vector2(0.5, 0.5), Array(square.get("polygon", []))):
		_fail("Square should contain its center.")
	if service.point_in_polygon(Vector2(2.0, 0.5), Array(square.get("polygon", []))):
		_fail("Square should not contain outside point.")
	var shifted_square := {
		"shape": "polygon",
		"polygon": [
			Vector2(0.5, 0.5),
			Vector2(1.5, 0.5),
			Vector2(1.5, 1.5),
			Vector2(0.5, 1.5),
		],
	}
	if service.polygon_collider_distance(square, shifted_square) > 0.0:
		_fail("Overlapping polygons should have zero polygon distance.")
	if service.collider_gap(square, shifted_square) >= 0.0:
		_fail("Overlapping polygons should report a negative collider gap.")
	var bounds: Dictionary = service.collider_with_bounds(square)
	_assert_vec(Vector2(bounds.get("center", Vector2.ZERO)), Vector2(0.5, 0.5), "polygon bounds center")
	_assert_vec(Vector2(bounds.get("aabb_min", Vector2.ZERO)), Vector2.ZERO, "polygon bounds min")
	_assert_vec(Vector2(bounds.get("aabb_max", Vector2.ZERO)), Vector2(1.0, 1.0), "polygon bounds max")
	_assert_close(float(bounds.get("bounding_radius", 0.0)), sqrt(0.5), "polygon bounds radius")


func _check_transform_math(service) -> void:
	var collider := {
		"shape": "capsule",
		"center": Vector2(1.0, 0.0),
		"a": Vector2.ZERO,
		"b": Vector2(2.0, 0.0),
		"pivot": Vector2(1.0, 0.5),
		"local_joint_center": Vector2(0.0, 0.5),
		"radius": 0.25,
	}
	var scaled: Dictionary = service.scale_collider_around_center(collider, 2.0)
	_assert_close(float(scaled.get("radius", 0.0)), 0.5, "scaled radius")
	_assert_vec(Vector2(scaled.get("a", Vector2.ZERO)), Vector2(-1.0, 0.0), "scaled capsule a")
	_assert_vec(Vector2(scaled.get("b", Vector2.ZERO)), Vector2(3.0, 0.0), "scaled capsule b")
	_assert_vec(Vector2(scaled.get("pivot", Vector2.ZERO)), Vector2(1.0, 1.0), "scaled pivot")
	_assert_vec(Vector2(scaled.get("local_joint_center", Vector2.ZERO)), Vector2(-1.0, 1.0), "scaled joint center")
	var shifted: Dictionary = service.shift_collider_by_offset(collider, Vector2(3.0, -2.0))
	_assert_vec(Vector2(shifted.get("center", Vector2.ZERO)), Vector2(4.0, -2.0), "shifted center")
	_assert_vec(Vector2(shifted.get("a", Vector2.ZERO)), Vector2(3.0, -2.0), "shifted capsule a")
	_assert_vec(Vector2(shifted.get("b", Vector2.ZERO)), Vector2(5.0, -2.0), "shifted capsule b")


func _check_owner_wrappers(service) -> void:
	var main = MainScene.new()
	var circle_a := {"shape": "circle", "center": Vector2.ZERO, "radius": 0.5}
	var circle_b := {"shape": "circle", "center": Vector2(1.25, 0.0), "radius": 0.5}
	_assert_close(main._collider_gap(circle_a, circle_b), service.collider_gap(circle_a, circle_b), "main collider gap wrapper")
	var shifted: Dictionary = main._shift_collider_to_origin({"shape": "circle", "center": Vector2(12.0, 1.0), "radius": 0.5}, 10.0)
	_assert_vec(Vector2(shifted.get("center", Vector2.ZERO)), Vector2(12.0, 1.0), "main shift-to-origin wrapper")
	var fighter = FighterScene.new()
	var bounded: Dictionary = fighter._runtime_collider_with_bounds({"shape": "capsule", "a": Vector2.ZERO, "b": Vector2(2.0, 0.0), "radius": 0.25})
	_assert_vec(Vector2(bounded.get("center", Vector2.ZERO)), Vector2(1.0, 0.0), "fighter bounds center wrapper")
	_assert_vec(Vector2(bounded.get("aabb_min", Vector2.ZERO)), Vector2(-0.25, -0.25), "fighter bounds min wrapper")
	_assert_vec(Vector2(bounded.get("aabb_max", Vector2.ZERO)), Vector2(2.25, 0.25), "fighter bounds max wrapper")
	_assert_close(float(bounded.get("bounding_radius", 0.0)), 1.25, "fighter bounds radius wrapper")
	main.free()
	fighter.free()


func _assert_close(actual: float, expected: float, label: String, tolerance: float = 0.001) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.6f, got %.6f." % [label, expected, actual])


func _assert_vec(actual: Vector2, expected: Vector2, label: String, tolerance: float = 0.001) -> void:
	if actual.distance_to(expected) > tolerance:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
