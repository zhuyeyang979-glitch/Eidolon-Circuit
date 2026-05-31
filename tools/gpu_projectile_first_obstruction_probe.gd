extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		push_error("GPU pipeline failed: %s" % pipeline.status_note)
		quit(1)
		return
	var colliders := [
		_box(Vector2(1.25, 0.0), Vector2(0.3, 0.6), 2),
		_box(Vector2(2.25, 0.0), Vector2(0.3, 0.6), 3),
	]
	var hits := pipeline.compute_geometry_queries(colliders, [{
		"start": Vector2.ZERO,
		"end": Vector2(3.0, 0.0),
		"radius": 0.05,
		"owner_unit_key": 1,
		"owner_team_key": 1,
	}], 1.0 / 60.0)
	if hits.size() < 2:
		push_error("Expected both obstruction hits in compact GPU query buffer, got %d" % hits.size())
		quit(1)
		return
	hits.sort_custom(func(a, b): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	var first: Dictionary = hits[0]
	var second: Dictionary = hits[1]
	if int(first.get("collider_index", -1)) != 0 or int(second.get("collider_index", -1)) != 1:
		push_error("Projectile obstruction order wrong: %s" % str(hits))
		quit(1)
		return
	print("gpu_projectile_first_obstruction_probe ok first=%.3f second=%.3f" % [float(first.get("distance", 0.0)), float(second.get("distance", 0.0))])
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
