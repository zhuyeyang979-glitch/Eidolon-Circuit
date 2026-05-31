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
	var source := FileAccess.get_file_as_string("res://scripts/gpu_collision_pipeline.gd")
	if source.is_empty():
		_fail("Unable to read gpu_collision_pipeline.gd.")
		return
	if not source.contains("DEFERRED_READBACK_MIN_FRAME_DELAY") or not source.contains("nonblocking_sync_skip_count"):
		_fail("GPU query pipeline does not expose deferred nonblocking counters.")
		return
	var query_block := _function_block(source, "func _consume_pending_query_frame")
	var contact_block := _function_block(source, "func _consume_pending_contact_frame")
	if query_block.is_empty() or contact_block.is_empty():
		_fail("Unable to inspect GPU deferred consumers.")
		return
	if not query_block.contains("DEFERRED_READBACK_MIN_FRAME_DELAY") or not query_block.contains("deferred_query_poll_skip_count"):
		_fail("Query deferred consumer does not skip early nonblocking polls.")
		return
	if not contact_block.contains("DEFERRED_READBACK_MIN_FRAME_DELAY") or not contact_block.contains("deferred_contact_poll_skip_count"):
		_fail("Contact deferred consumer does not skip early nonblocking polls.")
		return
	print("GPU_QUERY_NONBLOCKING_POLL_PROBE ok")
	quit(0)
