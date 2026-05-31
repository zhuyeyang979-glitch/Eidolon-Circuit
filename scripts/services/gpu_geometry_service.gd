extends RefCounted
class_name GpuGeometryService

var pipeline
var contact_submit_count := 0
var query_submit_count := 0
var contact_consume_count := 0
var query_consume_count := 0
var no_pipeline_count := 0
var last_readback_bytes := 0
var last_status := "unbound"


func bind_pipeline(next_pipeline) -> void:
	pipeline = next_pipeline
	last_status = "bound" if pipeline != null else "unbound"


func is_available() -> bool:
	return pipeline != null and pipeline.is_available()


func compute_contact_responses_deferred(colliders: Array, required_overlap: float, delta: float = 0.0) -> Array:
	if not is_available():
		no_pipeline_count += 1
		last_status = "unavailable"
		return []
	contact_submit_count += 1
	var records: Array = pipeline.compute_contact_responses_deferred(colliders, required_overlap, delta)
	last_readback_bytes = int(pipeline.last_readback_bytes)
	if not records.is_empty():
		contact_consume_count += 1
	last_status = "contact:%d" % records.size()
	return records


func compute_geometry_queries_deferred(colliders: Array, queries: Array, delta: float = 0.0) -> Array:
	if not is_available():
		no_pipeline_count += 1
		last_status = "unavailable"
		return []
	query_submit_count += 1
	var records: Array = pipeline.compute_geometry_queries_deferred(colliders, queries, delta)
	last_readback_bytes = int(pipeline.last_readback_bytes)
	if not records.is_empty():
		query_consume_count += 1
	last_status = "query:%d" % records.size()
	return records


func compute_geometry_queries(colliders: Array, queries: Array, delta: float = 0.0) -> Array:
	if not is_available():
		no_pipeline_count += 1
		last_status = "unavailable"
		return []
	query_submit_count += 1
	var records: Array = pipeline.compute_geometry_queries(colliders, queries, delta, false)
	last_readback_bytes = int(pipeline.last_readback_bytes)
	if not records.is_empty():
		query_consume_count += 1
	last_status = "query_now:%d" % records.size()
	return records


func summary_line() -> String:
	return "gpu svc c:%d/%d q:%d/%d bytes:%d %s" % [
		contact_consume_count,
		contact_submit_count,
		query_consume_count,
		query_submit_count,
		last_readback_bytes,
		last_status,
	]
