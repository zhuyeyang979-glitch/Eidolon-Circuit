extends SceneTree

const MainScene := preload("res://scripts/main.gd")


class TestUnit:
	extends RefCounted
	var ring_pos := 0.0
	var lane := 0.0
	var owner_id := 1
	var role := "hero"
	var stats := {"teamedit_runtime_topology": true, "mass": 20.0}
	var active := true
	var health := 100.0
	var max_health := 100.0
	var velocity := Vector2.ZERO
	var unit_name := "GPU_DAMAGE_TEST"
	var colliders: Array = []
	var visible := true
	var facing := 1
	var heat := 0.0
	var overheated := false
	var position := Vector2.ZERO

	func part_colliders() -> Array:
		return colliders

	func take_hit(damage: int, _state := "normal", _owner := 0, _damage_type := "blunt", _material := "body") -> bool:
		health = maxf(0.0, health - float(damage))
		active = health > 0.0
		return not active

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
		"stiffness_momentum": 10000.0,
		"damage_coeff": 100.0,
		"break_coeff": 0.0,
		"damage_type": "blunt",
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
	a.velocity = Vector2(8.0, 0.0)
	a.colliders = [_square(Vector2.ZERO, 0.5)]
	var b := TestUnit.new()
	b.owner_id = 2
	b.ring_pos = 0.72
	b.velocity = Vector2.ZERO
	b.colliders = [_square(Vector2(0.72, 0.0), 0.5)]
	main.all_units = [a, b]
	main._resolve_unit_body_spacing(1.0 / 60.0)
	if b.health >= 100.0:
		_fail("GPU contact did not enter runtime damage chain.")
		return
	if int(main.collision_polygon_precise_check_count) != 0:
		_fail("CPU precise collision ran on GPU contact damage path.")
		return
	print("GPU_CONTACT_DAMAGE_PROBE ok target_hp=%.1f contacts=%d" % [b.health, int(main.gpu_collision_contact_count)])
	quit()
