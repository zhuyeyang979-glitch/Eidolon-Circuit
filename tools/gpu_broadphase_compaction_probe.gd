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
	var colliders: Array = []
	for i in range(24):
		colliders.append(_square(Vector2(float(i) * 8.0, 0.0), 0.35, i + 1))
	colliders[7] = _square(Vector2(0.45, 0.0), 0.35, 88)
	var contacts := pipeline.compute_contact_responses(colliders, 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one compact contact, got %d" % contacts.size())
		return
	if pipeline.last_pair_count <= pipeline.last_candidate_count:
		_fail("Broadphase did not compact pairs: pairs=%d candidates=%d" % [pipeline.last_pair_count, pipeline.last_candidate_count])
		return
	var old_full_readback := pipeline.last_pair_count * 28 * 4
	if pipeline.last_readback_bytes >= old_full_readback:
		_fail("Readback was not compact: readback=%d old_full=%d" % [pipeline.last_readback_bytes, old_full_readback])
		return
	print("GPU_BROADPHASE_COMPACTION_PROBE ok pairs=%d candidates=%d readback=%d" % [pipeline.last_pair_count, pipeline.last_candidate_count, pipeline.last_readback_bytes])
	quit()
