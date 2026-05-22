extends SceneTree


const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var pipeline_source := FileAccess.get_file_as_string("res://scripts/gpu_collision_pipeline.gd")
	if main_source.is_empty() or pipeline_source.is_empty():
		_fail("Unable to read GPU collision sources.")
		return
	if not main_source.contains("compute_contact_responses_deferred"):
		_fail("Runtime battle path does not use deferred compact GPU contact readback.")
		return
	if not pipeline_source.contains("deferred_contact_pending") or not pipeline_source.contains("_consume_pending_contact_frame"):
		_fail("GPU collision pipeline lacks deferred readback state.")
		return
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		_fail("GPU pipeline failed: %s" % pipeline.status_note)
		return
	var a := _box(Vector2.ZERO, Vector2(0.5, 0.5), 1)
	var b := _box(Vector2(0.35, 0.0), Vector2(0.5, 0.5), 2)
	var first := pipeline.compute_contact_responses_deferred([a, b], 0.0, 1.0 / 60.0)
	if not first.is_empty():
		_fail("First deferred contact call should submit work and return previous compact results only.")
		return
	if not bool(pipeline.deferred_contact_pending):
		_fail("Deferred contact job was not left pending after submit.")
		return
	var second: Array = []
	for attempt in range(3):
		await process_frame
		second = pipeline.compute_contact_responses_deferred([a, b], 0.0, 1.0 / 60.0)
		if not second.is_empty():
			break
	if second.is_empty():
		_fail("Second deferred contact call did not consume previous GPU contact results.")
		return
	if int(pipeline.deferred_contact_submit_count) < 2 or int(pipeline.deferred_contact_consume_count) < 1:
		_fail("Deferred submit/consume counters did not advance.")
		return
	print("gpu_async_readback_probe ok submit=%d consume=%d responses=%d" % [int(pipeline.deferred_contact_submit_count), int(pipeline.deferred_contact_consume_count), second.size()])
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
