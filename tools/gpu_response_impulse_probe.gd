extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _square(center: Vector2, half: float, unit_key: int, velocity: Vector2, mass: float, stiffness: float) -> Dictionary:
	return {
		"shape": "polygon",
		"center": center,
		"gpu_unit_key": unit_key,
		"unit_velocity": velocity,
		"gpu_mass": mass,
		"gpu_path_stiffness": stiffness,
		"polygon": [
			center + Vector2(-half, -half),
			center + Vector2(half, -half),
			center + Vector2(half, half),
			center + Vector2(-half, half),
		],
	}


func _near(a: float, b: float, eps: float = 0.02) -> bool:
	return absf(a - b) <= eps


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		_fail("GPU collision unavailable: %s" % pipeline.status_note)
		return
	var a := _square(Vector2.ZERO, 0.5, 1, Vector2.RIGHT, 2.0, 100.0)
	var b := _square(Vector2(0.75, 0.0), 0.5, 2, Vector2.ZERO, 3.0, 100.0)
	var contacts := pipeline.compute_contact_responses([a, b], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("Expected one contact, got %d" % contacts.size())
		return
	var contact: Dictionary = contacts[0]
	if not _near(float(contact.get("raw_contact_momentum", 0.0)), 5.0):
		_fail("Unexpected raw momentum %.4f" % float(contact.get("raw_contact_momentum", 0.0)))
		return
	var dva: Vector2 = contact.get("velocity_delta_a", Vector2.ZERO)
	var dvb: Vector2 = contact.get("velocity_delta_b", Vector2.ZERO)
	if not _near(dva.x, -2.5) or not _near(dvb.x, 5.0 / 3.0):
		_fail("Unexpected GPU velocity deltas a=%s b=%s" % [str(dva), str(dvb)])
		return
	print("GPU_RESPONSE_IMPULSE_PROBE ok raw=%.2f dva=%s dvb=%s" % [float(contact.get("raw_contact_momentum", 0.0)), str(dva), str(dvb)])
	quit()
