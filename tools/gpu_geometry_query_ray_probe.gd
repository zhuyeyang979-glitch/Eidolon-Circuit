extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		push_error("GPU pipeline failed: %s" % pipeline.status_note)
		quit(1)
		return
	var colliders := [
		_box(Vector2(2.0, 0.0), Vector2(0.4, 0.7), 2),
		_box(Vector2(3.0, 0.0), Vector2(0.4, 0.7), 3),
	]
	var hits := pipeline.compute_geometry_queries(colliders, [{
		"start": Vector2.ZERO,
		"end": Vector2(4.0, 0.0),
		"radius": 0.0,
		"owner_unit_key": 1,
		"owner_team_key": 1,
		"query_id": 42,
	}], 1.0 / 60.0)
	if hits.is_empty():
		push_error("Expected GPU ray query hit.")
		quit(1)
		return
	hits.sort_custom(func(a, b): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	var first: Dictionary = hits[0]
	if int(first.get("collider_index", -1)) != 0:
		push_error("Expected nearest collider 0, got %s hits=%s" % [str(first.get("collider_index", -1)), str(hits)])
		quit(1)
		return
	var pos: Vector2 = first.get("position", Vector2.ZERO)
	if absf(pos.x - 1.8) > 0.06 or absf(pos.y) > 0.06:
		push_error("Unexpected ray hit position: %s" % str(pos))
		quit(1)
		return
	print("gpu_geometry_query_ray_probe ok hits=%d first_distance=%.3f position=%s readback=%d" % [hits.size(), float(first.get("distance", 0.0)), str(pos), pipeline.last_readback_bytes])
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
