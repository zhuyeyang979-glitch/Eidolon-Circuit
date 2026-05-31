extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _square(center: Vector2, half: float, unit_key: int, recovery: bool) -> Dictionary:
	return {
		"shape": "polygon",
		"center": center,
		"gpu_unit_key": unit_key,
		"gpu_recovery_capable": recovery,
		"unit_velocity": Vector2.RIGHT,
		"gpu_mass": 5.0,
		"gpu_path_stiffness": 100.0,
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
	var contacts := pipeline.compute_contact_responses([_square(Vector2.ZERO, 0.5, 1, true), _square(Vector2(0.75, 0.0), 0.5, 2, false)], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one recovery contact, got %d" % contacts.size())
		return
	if not bool(contacts[0].get("recovery_a", false)) or bool(contacts[0].get("recovery_b", false)):
		_fail("Unexpected recovery flags: %s" % str(contacts[0]))
		return
	print("GPU_RECOVERY_EVENT_PROBE ok")
	quit()
