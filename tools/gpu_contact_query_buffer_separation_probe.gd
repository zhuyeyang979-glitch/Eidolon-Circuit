extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/gpu_collision_pipeline.gd")
	if source.is_empty():
		_fail("Unable to read GPU collision pipeline.")
		return
	if not source.contains("query_collider_buffer_rid") or not source.contains("query_collider_buffer_bytes"):
		_fail("Geometry queries do not have an independent collider buffer.")
		return
	var contact_block := _function_block(source, "func compute_contact_responses(")
	var query_block := _function_block(source, "func compute_geometry_queries(")
	if contact_block.contains("_consume_pending_query_frame"):
		_fail("Contact path still drains pending query jobs before upload.")
		return
	if query_block.contains("_consume_pending_contact_frame"):
		_fail("Query path still drains pending contact jobs before upload.")
		return
	if not query_block.contains("query_collider_buffer_rid"):
		_fail("Query path does not bind the independent query collider buffer.")
		return
	print("GPU_CONTACT_QUERY_BUFFER_SEPARATION_PROBE ok")
	quit(0)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)
