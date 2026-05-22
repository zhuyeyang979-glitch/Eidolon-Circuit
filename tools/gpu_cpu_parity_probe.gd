extends SceneTree

const MainScene := preload("res://scripts/main.gd")
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
	var a := _square(Vector2.ZERO, 0.5, 1)
	var b := _square(Vector2(0.72, 0.0), 0.5, 2)
	var contacts := pipeline.compute_contacts([a, b], 0.0, 1.0 / 60.0)
	if contacts.size() != 1:
		_fail("GPU expected one contact, got %d" % contacts.size())
		return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var cpu_gap := main._collider_gap(a, b)
	var gpu_penetration := float(Dictionary(contacts[0]).get("penetration", 0.0))
	if cpu_gap > 0.0 or gpu_penetration <= 0.0:
		_fail("GPU/CPU overlap disagreement gpu=%.4f cpu_gap=%.4f" % [gpu_penetration, cpu_gap])
		return
	print("GPU_CPU_PARITY_PROBE ok gpu=%.4f cpu_gap=%.4f" % [gpu_penetration, cpu_gap])
	quit()
