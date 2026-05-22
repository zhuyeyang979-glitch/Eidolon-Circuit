extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/gpu_collision_pipeline.gd")
	if not source.contains("compute_geometry_queries_deferred") or not source.contains("deferred_query_pending"):
		_fail("GPU geometry query pipeline lacks deferred compact readback.")
		return
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		_fail("GPU pipeline failed: %s" % pipeline.status_note)
		return
	var colliders := [
		_box(Vector2(2.0, 0.0), Vector2(0.4, 0.7), 2),
		_box(Vector2(3.0, 0.0), Vector2(0.4, 0.7), 3),
	]
	var query := [{
		"start": Vector2.ZERO,
		"end": Vector2(4.0, 0.0),
		"radius": 0.0,
		"owner_unit_key": 1,
		"owner_team_key": 1,
		"query_id": 42,
	}]
	var first := pipeline.compute_geometry_queries_deferred(colliders, query, 1.0 / 60.0)
	if not first.is_empty():
		_fail("First deferred query call should submit and return only previous compact hits.")
		return
	if not bool(pipeline.deferred_query_pending):
		_fail("Deferred query job was not left pending after submit.")
		return
	var second := pipeline.compute_geometry_queries_deferred(colliders, query, 1.0 / 60.0)
	if second.is_empty():
		_fail("Second deferred query call did not consume previous GPU query hits.")
		return
	second.sort_custom(func(a, b): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	if int(Dictionary(second[0]).get("collider_index", -1)) != 0:
		_fail("Deferred query nearest hit was not collider 0: %s" % str(second))
		return
	if int(pipeline.deferred_query_submit_count) < 2 or int(pipeline.deferred_query_consume_count) < 1:
		_fail("Deferred query submit/consume counters did not advance.")
		return
	print("gpu_geometry_query_async_probe ok submit=%d consume=%d hits=%d" % [int(pipeline.deferred_query_submit_count), int(pipeline.deferred_query_consume_count), second.size()])
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
	}
