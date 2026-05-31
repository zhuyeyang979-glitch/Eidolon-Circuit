extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var pipeline_source := FileAccess.get_file_as_string("res://scripts/gpu_collision_pipeline.gd")
	if main_source.is_empty() or pipeline_source.is_empty():
		_fail("Unable to read GPU query sources.")
	var first_projectile := _function_block(main_source, "func _first_projectile_impact_gpu")
	if first_projectile.contains(".compute_geometry_queries("):
		_fail("Hot projectile query path can still force current-frame rd.sync.")
	if not first_projectile.contains("_submit_gpu_geometry_queries_deferred"):
		_fail("Hot projectile query path is not deferred.")
	var deferred_api := _function_block(pipeline_source, "func compute_geometry_queries_deferred")
	if deferred_api.is_empty() or not deferred_api.contains("true"):
		_fail("GPU pipeline deferred query API missing.")
	var immediate_api := _function_block(pipeline_source, "func compute_geometry_queries(")
	if immediate_api.is_empty():
		_fail("GPU pipeline geometry query function missing.")
	if not immediate_api.contains("if defer_readback:"):
		_fail("Geometry query does not have a deferred no-current-readback branch.")
	print("GPU_NO_HOT_RD_SYNC_PROBE ok")
	quit(0)
