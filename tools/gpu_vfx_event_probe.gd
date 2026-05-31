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
		"unit_velocity": Vector2.RIGHT,
		"gpu_mass": 4.0,
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
	var contacts := pipeline.compute_contact_responses([_square(Vector2.ZERO, 0.5, 1), _square(Vector2(0.75, 0.0), 0.5, 2)], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one VFX contact, got %d" % contacts.size())
		return
	if float(contacts[0].get("vfx_strength", 0.0)) <= 0.0 or int(contacts[0].get("vfx_kind", 0)) <= 0:
		_fail("GPU did not emit VFX descriptor: %s" % str(contacts[0]))
		return
	var no_contacts := pipeline.compute_contact_responses([_square(Vector2.ZERO, 0.5, 1), _square(Vector2(2.0, 0.0), 0.5, 2)], 0.0, 1.0 / 60.0)
	if not no_contacts.is_empty():
		_fail("GPU emitted VFX/contact for separated colliders")
		return
	print("GPU_VFX_EVENT_PROBE ok strength=%.3f" % float(contacts[0].get("vfx_strength", 0.0)))
	quit()
