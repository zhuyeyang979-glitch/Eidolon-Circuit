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
	var contacts := pipeline.compute_contacts([_square(Vector2.ZERO, 0.5, 1), _square(Vector2(1.02, 0.0), 0.5, 2)], 0.0, 1.0 / 60.0)
	if not contacts.is_empty():
		_fail("Expected no contact with visible gap, got %d" % contacts.size())
		return
	print("GPU_COLLISION_NO_PRECONTACT_PROBE ok")
	quit()
