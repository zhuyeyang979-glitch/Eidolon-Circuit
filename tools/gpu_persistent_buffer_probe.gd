extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		push_error("GPU pipeline failed: %s" % pipeline.status_note)
		quit(1)
		return
	var a := _box(Vector2.ZERO, Vector2(0.5, 0.5), 1)
	var b := _box(Vector2(0.35, 0.0), Vector2(0.5, 0.5), 2)
	var responses := pipeline.compute_contact_responses([a, b], 0.0, 1.0 / 60.0)
	var recreates_after_first := pipeline.buffer_recreate_count
	var reuse_after_first := pipeline.buffer_reuse_count
	if responses.is_empty():
		push_error("Expected first GPU contact response.")
		quit(1)
		return
	for i in range(6):
		responses = pipeline.compute_contact_responses([a, b], 0.0, 1.0 / 60.0)
	if pipeline.buffer_recreate_count != recreates_after_first:
		push_error("Persistent buffers recreated without capacity growth: before=%d after=%d" % [recreates_after_first, pipeline.buffer_recreate_count])
		quit(1)
		return
	if pipeline.buffer_reuse_count <= reuse_after_first:
		push_error("Persistent buffers were not reused.")
		quit(1)
		return
	print("gpu_persistent_buffer_probe ok recreates=%d reuses=%d responses=%d" % [pipeline.buffer_recreate_count, pipeline.buffer_reuse_count, responses.size()])
	quit(0)


func _box(center: Vector2, size: Vector2, unit_key: int) -> Dictionary:
	var half := size * 0.5
	return {
		"shape": "polygon",
		"polygon": [
			center + Vector2(-half.x, -half.y),
			center + Vector2(half.x, -half.y),
			center + Vector2(half.x, half.y),
			center + Vector2(-half.x, half.y),
		],
		"center": center,
		"gpu_unit_key": unit_key,
		"gpu_team_key": unit_key,
		"gpu_mass": 10.0,
		"gpu_path_stiffness": 100.0,
	}
