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
	var same_unit_contacts := pipeline.compute_contacts([_square(Vector2.ZERO, 0.5, 7), _square(Vector2(0.55, 0.0), 0.5, 7)], 0.0, 1.0 / 60.0)
	if not same_unit_contacts.is_empty():
		_fail("Same unit colliders should be filtered, got %d" % same_unit_contacts.size())
		return
	var distinct_unit_contacts := pipeline.compute_contacts([_square(Vector2.ZERO, 0.5, 7), _square(Vector2(0.55, 0.0), 0.5, 8)], 0.0, 1.0 / 60.0)
	if distinct_unit_contacts.size() != 1:
		_fail("Different units with same shape should collide, got %d" % distinct_unit_contacts.size())
		return
	print("GPU_COLLISION_SELF_FILTER_PROBE ok")
	quit()
