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
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
	var helper := _function_block(source, "func _submit_gpu_geometry_queries_deferred")
	if helper.is_empty() or not helper.contains("compute_geometry_queries_deferred"):
		_fail("Main runtime lacks deferred GPU geometry query submit helper.")
	var projectile_block := _function_block(source, "func _first_projectile_impact_gpu")
	if projectile_block.is_empty():
		_fail("_first_projectile_impact_gpu not found.")
	if projectile_block.contains(".compute_geometry_queries("):
		_fail("Projectile runtime GPU query still uses immediate compute_geometry_queries().")
	if not projectile_block.contains("_submit_gpu_geometry_queries_deferred"):
		_fail("Projectile runtime does not use deferred GPU query consumer.")
	print("GPU_QUERY_DEFERRED_CONSUMERS_PROBE ok")
	quit(0)
