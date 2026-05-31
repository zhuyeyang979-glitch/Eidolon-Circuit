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
	var contacts := pipeline.compute_contacts([_square(Vector2.ZERO, 0.5, 1), _square(Vector2(0.75, 0.0), 0.5, 2)], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one GPU overlap contact, got %d" % contacts.size())
		return
	var contact: Dictionary = contacts[0]
	var penetration := float(contact.get("penetration", 0.0))
	var normal: Vector2 = contact.get("normal", Vector2.ZERO)
	if penetration <= 0.2 or penetration >= 0.35:
		_fail("Unexpected penetration %.4f" % penetration)
		return
	if normal.dot(Vector2.RIGHT) < 0.9:
		_fail("Expected contact normal to point right, got %s" % str(normal))
		return
	print("GPU_COLLISION_OVERLAP_PROBE ok penetration=%.4f normal=%s" % [penetration, str(normal)])
	quit()
