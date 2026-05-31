extends SceneTree

const GpuCollisionPipeline := preload("res://scripts/gpu_collision_pipeline.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var pipeline := GpuCollisionPipeline.new()
	if not pipeline.initialize():
		_fail("GPU collision pipeline failed to initialize: %s" % pipeline.status_note)
		return
	print("GPU_COLLISION_INIT_PROBE ok %s" % pipeline.status_note)
	quit()
