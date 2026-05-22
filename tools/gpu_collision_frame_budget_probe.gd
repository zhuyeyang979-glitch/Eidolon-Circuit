extends SceneTree

const MainScene := preload("res://scripts/main.gd")


class TestUnit:
	extends RefCounted
	var ring_pos := 0.0
	var lane := 0.0
	var owner_id := 1
	var role := "hero"
	var stats := {"teamedit_runtime_topology": true, "mass": 10.0}
	var active := true
	var health := 100.0
	var max_health := 100.0
	var velocity := Vector2.ZERO
	var unit_name := "GPU_TEST"
	var colliders: Array = []

	func part_colliders() -> Array:
		return colliders

	func queue_free() -> void:
		active = false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _square(center: Vector2, half: float) -> Dictionary:
	return {
		"shape": "polygon",
		"part_kind": "torso",
		"center": center,
		"polygon": [
			center + Vector2(-half, -half),
			center + Vector2(half, -half),
			center + Vector2(half, half),
			center + Vector2(-half, half),
		],
		"bounding_radius": half * 1.42,
		"independent_damage": false,
		"damage_proxy": "torso",
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if not main._gpu_collision_available():
		_fail("GPU collision unavailable: %s" % main.gpu_collision_status_note)
		return
	var a := TestUnit.new()
	a.owner_id = 1
	a.ring_pos = 0.0
	a.colliders = [_square(Vector2.ZERO, 0.5)]
	var b := TestUnit.new()
	b.owner_id = 1
	b.ring_pos = 0.75
	b.colliders = [_square(Vector2(0.75, 0.0), 0.5)]
	main.all_units = [a, b]
	main.collision_polygon_precise_check_count = 0
	main.gpu_collision_pair_dispatch_count = 0
	main.gpu_collision_contact_count = 0
	main._resolve_unit_body_spacing(1.0 / 60.0)
	if int(main.gpu_collision_pair_dispatch_count) <= 0:
		_fail("Runtime pair did not dispatch to GPU collision.")
		return
	if int(main.gpu_collision_contact_count) <= 0:
		_fail("GPU collision produced no contacts for overlapping test units.")
		return
	if int(main.collision_polygon_precise_check_count) != 0:
		_fail("CPU precise polygon overlap should not run for runtime GPU path.")
		return
	print("GPU_COLLISION_FRAME_BUDGET_PROBE ok dispatch=%d contacts=%d cpu_precise=%d" % [int(main.gpu_collision_pair_dispatch_count), int(main.gpu_collision_contact_count), int(main.collision_polygon_precise_check_count)])
	quit()
