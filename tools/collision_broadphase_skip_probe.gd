extends SceneTree

const MainScene := preload("res://scripts/main.gd")


class TestUnit:
	extends RefCounted
	var ring_pos := 0.0
	var lane := 0.0
	var owner_id := 1
	var stats := {"teamedit_runtime_topology": true}
	var active := true
	var health := 100.0
	var max_health := 100.0
	var velocity := Vector2.ZERO
	var colliders: Array = []

	func part_colliders() -> Array:
		return colliders


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var a := {
		"shape": "polygon",
		"center": Vector2.ZERO,
		"polygon": [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)],
		"bounding_radius": 0.72,
	}
	var b := {
		"shape": "polygon",
		"center": Vector2(20.0, 0.0),
		"polygon": [Vector2(19.5, -0.5), Vector2(20.5, -0.5), Vector2(20.5, 0.5), Vector2(19.5, 0.5)],
		"bounding_radius": 0.72,
	}
	var broad_gap := main._collider_broadphase_gap(a, b)
	if broad_gap <= 18.0:
		_fail("Broadphase gap should be large for far colliders, got %.3f" % broad_gap)
		return
	var exact_gap := main._collider_gap(a, b)
	if exact_gap <= 18.0:
		_fail("Exact gap should also be large for far colliders, got %.3f" % exact_gap)
		return
	var unit_a := TestUnit.new()
	unit_a.owner_id = 1
	unit_a.ring_pos = 0.0
	unit_a.lane = 0.0
	unit_a.colliders = [a]
	var unit_b := TestUnit.new()
	unit_b.owner_id = 2
	unit_b.ring_pos = 20.0
	unit_b.lane = 0.0
	unit_b.colliders = [b]
	main.collision_broadphase_skip_count = 0
	main.collision_polygon_precise_check_count = 0
	main.collision_pair_loop_count = 0
	main._separate_unit_part_pair(unit_a, unit_b, 1.0 / 60.0)
	if int(main.collision_pair_loop_count) <= 0:
		_fail("Collision pair loop did not run.")
	if int(main.collision_broadphase_skip_count) <= 0:
		_fail("Far collider pair was not skipped by broadphase.")
	if int(main.collision_polygon_precise_check_count) != 0:
		_fail("Far collider pair still entered precise polygon checks.")
	print("COLLISION_BROADPHASE_SKIP_PROBE ok broad_gap=%.3f exact_gap=%.3f skip=%d precise=%d" % [broad_gap, exact_gap, int(main.collision_broadphase_skip_count), int(main.collision_polygon_precise_check_count)])
	quit()
