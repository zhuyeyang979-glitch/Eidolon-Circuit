extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _square(center: Vector2, half: float, unit_key: int) -> Dictionary:
	return {
		"shape": "polygon",
		"center": center,
		"gpu_unit_key": unit_key,
		"gpu_mass": 10.0,
		"gpu_path_stiffness": 100.0,
		"unit_velocity": Vector2.ZERO,
		"polygon": [
			center + Vector2(-half, -half),
			center + Vector2(half, -half),
			center + Vector2(half, half),
			center + Vector2(-half, half),
		],
	}


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		_fail("GPU collision unavailable: %s" % pipeline.status_note)
		return
	var contacts := pipeline.compute_contact_responses([_square(Vector2.ZERO, 0.5, 1), _square(Vector2(0.75, 0.0), 0.5, 2)], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one static contact, got %d" % contacts.size())
		return
	var contact: Dictionary = contacts[0]
	var pa: Vector2 = contact.get("position_delta_a", Vector2.ZERO)
	var pb: Vector2 = contact.get("position_delta_b", Vector2.ZERO)
	var va: Vector2 = contact.get("velocity_delta_a", Vector2.ZERO)
	var vb: Vector2 = contact.get("velocity_delta_b", Vector2.ZERO)
	if pa.length() <= 0.0001 or pb.length() <= 0.0001:
		_fail("Expected GPU position separation deltas, got a=%s b=%s" % [str(pa), str(pb)])
		return
	if va.length() > 0.0001 or vb.length() > 0.0001:
		_fail("Static overlap injected velocity a=%s b=%s" % [str(va), str(vb)])
		return
	print("GPU_POSITION_SEPARATION_PROBE ok pa=%s pb=%s" % [str(pa), str(pb)])
	quit()
