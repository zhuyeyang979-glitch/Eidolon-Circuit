extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.strip_edges() == "":
		_fail("Unable to read main.gd")
		return
	if source.find("class BattleContactVfxPool") < 0:
		_fail("BattleContactVfxPool class missing")
		return
	if source.find("GPUParticles2D") < 0:
		_fail("BattleContactVfxPool is not GPU-backed")
		return
	if source.find("func _emit_gpu_contact_vfx_descriptor") < 0:
		_fail("Runtime GPU VFX descriptor consumer missing")
		return
	var contact_start := source.find("func _resolve_runtime_gpu_contact_once")
	var next_start := source.find("func _emit_gpu_contact_vfx_descriptor", contact_start)
	if contact_start < 0 or next_start < 0:
		_fail("Unable to locate GPU contact VFX callsite")
		return
	var contact_body := source.substr(contact_start, next_start - contact_start)
	if contact_body.find("_emit_gpu_contact_vfx_descriptor") < 0:
		_fail("GPU contact response does not emit through the VFX pool")
		return
	print("gpu_contact_vfx_pool_probe ok")
	quit(0)
