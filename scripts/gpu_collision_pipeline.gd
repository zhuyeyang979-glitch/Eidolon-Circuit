class_name GpuCollisionPipeline
extends RefCounted

const MAX_VERTICES := 24
const COLLIDER_FLOATS := 80
const RESPONSE_FLOATS := 28
const QUERY_FLOATS := 16
const QUERY_HIT_FLOATS := 16
const MAX_COLLIDERS := 768
const MAX_CANDIDATES := 8192
const MAX_RESPONSES := 4096
const MAX_QUERIES := 512
const MAX_QUERY_HITS := 4096
const BROADPHASE_SHADER_PATH := "res://shaders/gpu_collision_broadphase.glsl"
const NARROWPHASE_SHADER_PATH := "res://shaders/gpu_collision_narrowphase.glsl"
const GEOMETRY_QUERY_SHADER_PATH := "res://shaders/gpu_geometry_query.glsl"

const FLAG_ANCHORED := 1

var rd: RenderingDevice
var broadphase_shader_rid: RID
var broadphase_pipeline_rid: RID
var narrowphase_shader_rid: RID
var narrowphase_pipeline_rid: RID
var geometry_query_shader_rid: RID
var geometry_query_pipeline_rid: RID
var available := false
var status_note := ""
var last_collider_count := 0
var last_pair_count := 0
var last_candidate_count := 0
var last_response_count := 0
var last_contact_count := 0
var last_upload_bytes := 0
var last_readback_bytes := 0
var last_broadphase_groups := 0
var last_narrowphase_groups := 0
var last_overflow_flags := 0
var last_buffer_recreate_count := 0
var last_buffer_reuse_count := 0
var buffer_recreate_count := 0
var buffer_reuse_count := 0
var last_query_count := 0
var last_query_hit_count := 0
var last_query_groups := 0
var deferred_contact_submit_count := 0
var deferred_contact_consume_count := 0
var deferred_contact_pending := false
var last_deferred_readback := false
var _pending_contact_frame: Dictionary = {}
var _last_consumed_contact_stats: Dictionary = {}
var deferred_query_submit_count := 0
var deferred_query_consume_count := 0
var deferred_query_pending := false
var last_deferred_query_readback := false
var _pending_query_frame: Dictionary = {}
var _last_consumed_query_stats: Dictionary = {}

var collider_buffer_rid: RID
var candidate_buffer_rid: RID
var counter_buffer_rid: RID
var param_buffer_rid: RID
var response_buffer_rid: RID
var collider_buffer_bytes := 0
var candidate_buffer_bytes := 0
var counter_buffer_bytes := 0
var param_buffer_bytes := 0
var response_buffer_bytes := 0

var query_buffer_rid: RID
var query_param_buffer_rid: RID
var query_counter_buffer_rid: RID
var query_hit_buffer_rid: RID
var query_buffer_bytes := 0
var query_param_buffer_bytes := 0
var query_counter_buffer_bytes := 0
var query_hit_buffer_bytes := 0


func initialize() -> bool:
	if available:
		return true
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		status_note = "RenderingDevice unavailable."
		return false
	var broadphase_spirv = _load_shader_spirv(BROADPHASE_SHADER_PATH)
	if broadphase_spirv == null:
		return false
	var narrowphase_spirv = _load_shader_spirv(NARROWPHASE_SHADER_PATH)
	if narrowphase_spirv == null:
		return false
	var geometry_query_spirv = _load_shader_spirv(GEOMETRY_QUERY_SHADER_PATH)
	if geometry_query_spirv == null:
		return false
	broadphase_shader_rid = rd.shader_create_from_spirv(broadphase_spirv)
	narrowphase_shader_rid = rd.shader_create_from_spirv(narrowphase_spirv)
	geometry_query_shader_rid = rd.shader_create_from_spirv(geometry_query_spirv)
	if not broadphase_shader_rid.is_valid() or not narrowphase_shader_rid.is_valid() or not geometry_query_shader_rid.is_valid():
		status_note = "GPU collision shader failed to compile."
		return false
	broadphase_pipeline_rid = rd.compute_pipeline_create(broadphase_shader_rid)
	narrowphase_pipeline_rid = rd.compute_pipeline_create(narrowphase_shader_rid)
	geometry_query_pipeline_rid = rd.compute_pipeline_create(geometry_query_shader_rid)
	if not broadphase_pipeline_rid.is_valid() or not narrowphase_pipeline_rid.is_valid() or not geometry_query_pipeline_rid.is_valid():
		status_note = "GPU collision pipeline creation failed."
		return false
	available = true
	status_note = "GPU collision broadphase/response/query pipeline ready."
	return true


func _load_shader_spirv(path: String):
	if ResourceLoader.exists(path):
		var shader_file = load(path)
		if shader_file != null and shader_file.has_method("get_spirv"):
			return shader_file.get_spirv()
	var shader_code := FileAccess.get_file_as_string(path)
	if shader_code.strip_edges() == "":
		status_note = "GPU collision shader source missing: %s" % path
		return null
	shader_code = shader_code.replace("#[compute]\n", "")
	shader_code = shader_code.replace("#[compute]\r\n", "")
	if not rd.has_method("shader_compile_spirv_from_source"):
		status_note = "GPU collision shader is not imported and runtime GLSL compile is unavailable."
		return null
	var source := RDShaderSource.new()
	source.source_compute = shader_code
	var compiled = rd.shader_compile_spirv_from_source(source)
	if compiled == null:
		status_note = "GPU collision shader source failed to compile: %s" % path
		return null
	if compiled.has_method("get_stage_compile_error"):
		var compile_error := String(compiled.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE))
		if compile_error.strip_edges() != "":
			status_note = "GPU collision shader compile error in %s: %s" % [path, compile_error.strip_edges()]
			return null
	return compiled


func is_available() -> bool:
	return available or initialize()


func compute_contacts(colliders: Array, required_overlap: float = 0.0, delta: float = 0.0) -> Array:
	return compute_contact_responses(colliders, required_overlap, delta)


func compute_contact_responses_deferred(colliders: Array, required_overlap: float = 0.0, delta: float = 0.0) -> Array:
	return compute_contact_responses(colliders, required_overlap, delta, true)


func compute_geometry_queries_deferred(colliders: Array, queries: Array, delta: float = 0.0) -> Array:
	return compute_geometry_queries(colliders, queries, delta, true)


func compute_contact_responses(colliders: Array, required_overlap: float = 0.0, delta: float = 0.0, defer_readback: bool = false) -> Array:
	if not is_available():
		return []
	# Contact and query jobs share collider buffers. Consume any pending query before
	# writing fresh collider data so the GPU never races the CPU-side upload.
	_consume_pending_query_frame()
	var deferred_records: Array = []
	var deferred_stats: Dictionary = {}
	if defer_readback:
		deferred_records = _consume_pending_contact_frame()
		deferred_stats = _last_consumed_contact_stats.duplicate(true)
	else:
		_consume_pending_contact_frame()
	var collider_count := mini(colliders.size(), MAX_COLLIDERS)
	last_collider_count = collider_count
	last_pair_count = int(maxi(0, collider_count * (collider_count - 1) / 2))
	last_candidate_count = 0
	last_response_count = 0
	last_contact_count = 0
	last_overflow_flags = 0
	if collider_count < 2:
		last_upload_bytes = 0
		last_readback_bytes = 0
		return []
	var max_candidates := maxi(1, mini(MAX_CANDIDATES, last_pair_count))
	var max_responses := maxi(1, mini(MAX_RESPONSES, max_candidates))

	var collider_floats := PackedFloat32Array()
	collider_floats.resize(collider_count * COLLIDER_FLOATS)
	for i in range(collider_count):
		_pack_collider(collider_floats, i, Dictionary(colliders[i]))
	var params := PackedFloat32Array([
		float(collider_count),
		float(last_pair_count),
		required_overlap,
		delta,
		float(max_candidates),
		float(max_responses),
	])
	var collider_bytes := collider_floats.to_byte_array()
	var param_bytes := params.to_byte_array()
	var counter_bytes := _zero_bytes(4 * 4)
	last_upload_bytes = collider_bytes.size() + param_bytes.size() + counter_bytes.size()
	last_buffer_recreate_count = 0
	last_buffer_reuse_count = 0
	_ensure_collision_buffers(collider_bytes.size(), max_candidates * 2 * 4, counter_bytes.size(), param_bytes.size(), max_responses * RESPONSE_FLOATS * 4)
	_update_buffer(collider_buffer_rid, collider_bytes)
	_update_buffer(counter_buffer_rid, counter_bytes)
	_update_buffer(param_buffer_rid, param_bytes)

	var broadphase_uniforms: Array[RDUniform] = []
	broadphase_uniforms.append(_storage_uniform(0, collider_buffer_rid))
	broadphase_uniforms.append(_storage_uniform(1, candidate_buffer_rid))
	broadphase_uniforms.append(_storage_uniform(2, counter_buffer_rid))
	broadphase_uniforms.append(_storage_uniform(3, param_buffer_rid))
	var broadphase_set := rd.uniform_set_create(broadphase_uniforms, broadphase_shader_rid, 0)

	var narrowphase_uniforms: Array[RDUniform] = []
	narrowphase_uniforms.append(_storage_uniform(0, collider_buffer_rid))
	narrowphase_uniforms.append(_storage_uniform(1, candidate_buffer_rid))
	narrowphase_uniforms.append(_storage_uniform(2, response_buffer_rid))
	narrowphase_uniforms.append(_storage_uniform(3, counter_buffer_rid))
	narrowphase_uniforms.append(_storage_uniform(4, param_buffer_rid))
	var narrowphase_set := rd.uniform_set_create(narrowphase_uniforms, narrowphase_shader_rid, 0)

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, broadphase_pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, broadphase_set, 0)
	last_broadphase_groups = int(ceil(float(last_pair_count) / 64.0))
	rd.compute_list_dispatch(compute_list, last_broadphase_groups, 1, 1)
	if rd.has_method("compute_list_add_barrier"):
		rd.compute_list_add_barrier(compute_list)
	rd.compute_list_bind_compute_pipeline(compute_list, narrowphase_pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, narrowphase_set, 0)
	last_narrowphase_groups = int(ceil(float(max_candidates) / 64.0))
	rd.compute_list_dispatch(compute_list, last_narrowphase_groups, 1, 1)
	rd.compute_list_end()
	rd.submit()
	if defer_readback:
		deferred_contact_submit_count += 1
		deferred_contact_pending = true
		_pending_contact_frame = {
			"counter_buffer": counter_buffer_rid,
			"response_buffer": response_buffer_rid,
			"counter_bytes": counter_bytes.size(),
			"max_responses": max_responses,
			"collider_count": collider_count,
			"broadphase_set": broadphase_set,
			"narrowphase_set": narrowphase_set,
		}
		last_deferred_readback = true
		last_candidate_count = int(deferred_stats.get("candidate_count", 0))
		last_response_count = int(deferred_stats.get("response_count", deferred_records.size()))
		last_contact_count = deferred_records.size()
		last_overflow_flags = int(deferred_stats.get("overflow_flags", 0))
		last_readback_bytes = int(deferred_stats.get("readback_bytes", 0))
		return deferred_records
	last_deferred_readback = false
	rd.sync()

	var out_counter_bytes := rd.buffer_get_data(counter_buffer_rid, 0, counter_bytes.size())
	last_candidate_count = int(out_counter_bytes.decode_u32(0))
	last_response_count = int(out_counter_bytes.decode_u32(4))
	last_overflow_flags = int(out_counter_bytes.decode_u32(8))
	var parse_count := mini(last_response_count, max_responses)
	var responses: Array = []
	if parse_count > 0:
		var wanted_response_bytes := parse_count * RESPONSE_FLOATS * 4
		var out_bytes := rd.buffer_get_data(response_buffer_rid, 0, wanted_response_bytes)
		var out_floats := out_bytes.to_float32_array()
		for response_index in range(parse_count):
			var base := response_index * RESPONSE_FLOATS
			if base + 22 >= out_floats.size():
				break
			if out_floats[base] < 0.5:
				continue
			var a_index := int(roundf(out_floats[base + 1]))
			var b_index := int(roundf(out_floats[base + 2]))
			if a_index < 0 or b_index < 0 or a_index >= collider_count or b_index >= collider_count:
				continue
			var normal := Vector2(out_floats[base + 3], out_floats[base + 4])
			if normal.length() <= 0.0001:
				continue
			responses.append({
				"index_a": a_index,
				"index_b": b_index,
				"normal": normal.normalized(),
				"penetration": maxf(0.0, out_floats[base + 5]),
				"contact_point": Vector2(out_floats[base + 6], out_floats[base + 7]),
				"relative_normal_velocity": out_floats[base + 8],
				"raw_contact_momentum": maxf(0.0, out_floats[base + 9]),
				"usable_contact_momentum": maxf(0.0, out_floats[base + 10]),
				"velocity_delta_a": Vector2(out_floats[base + 11], out_floats[base + 12]),
				"velocity_delta_b": Vector2(out_floats[base + 13], out_floats[base + 14]),
				"position_delta_a": Vector2(out_floats[base + 15], out_floats[base + 16]),
				"position_delta_b": Vector2(out_floats[base + 17], out_floats[base + 18]),
				"recovery_a": out_floats[base + 19] > 0.5,
				"recovery_b": out_floats[base + 20] > 0.5,
				"vfx_strength": maxf(0.0, out_floats[base + 21]),
				"vfx_kind": int(roundf(out_floats[base + 22])),
			})
		last_readback_bytes = out_counter_bytes.size() + wanted_response_bytes
	else:
		last_readback_bytes = out_counter_bytes.size()
	last_contact_count = responses.size()

	_free_rid(broadphase_set)
	_free_rid(narrowphase_set)
	if last_overflow_flags != 0:
		status_note = "GPU collision truncated response/candidate buffers: %d" % last_overflow_flags
	return responses


func _consume_pending_contact_frame() -> Array:
	_last_consumed_contact_stats = {}
	if _pending_contact_frame.is_empty() or rd == null:
		deferred_contact_pending = false
		return []
	var frame := _pending_contact_frame
	_pending_contact_frame = {}
	deferred_contact_pending = false
	rd.sync()
	deferred_contact_consume_count += 1
	var counter_bytes_size := int(frame.get("counter_bytes", 16))
	var out_counter_bytes := rd.buffer_get_data(frame.get("counter_buffer", RID()), 0, counter_bytes_size)
	var candidate_count := int(out_counter_bytes.decode_u32(0))
	var response_count := int(out_counter_bytes.decode_u32(4))
	var overflow_flags := int(out_counter_bytes.decode_u32(8))
	var max_responses := int(frame.get("max_responses", MAX_RESPONSES))
	var collider_count := int(frame.get("collider_count", 0))
	var parse_count := mini(response_count, max_responses)
	var responses: Array = []
	var readback_bytes := out_counter_bytes.size()
	if parse_count > 0:
		var wanted_response_bytes := parse_count * RESPONSE_FLOATS * 4
		var out_bytes := rd.buffer_get_data(frame.get("response_buffer", RID()), 0, wanted_response_bytes)
		readback_bytes += wanted_response_bytes
		responses = _parse_contact_response_floats(out_bytes.to_float32_array(), parse_count, collider_count)
	_free_rid(frame.get("broadphase_set", RID()))
	_free_rid(frame.get("narrowphase_set", RID()))
	_last_consumed_contact_stats = {
		"candidate_count": candidate_count,
		"response_count": response_count,
		"contact_count": responses.size(),
		"overflow_flags": overflow_flags,
		"readback_bytes": readback_bytes,
	}
	if overflow_flags != 0:
		status_note = "GPU collision truncated response/candidate buffers: %d" % overflow_flags
	return responses


func _parse_contact_response_floats(out_floats: PackedFloat32Array, parse_count: int, collider_count: int) -> Array:
	var responses: Array = []
	for response_index in range(parse_count):
		var base := response_index * RESPONSE_FLOATS
		if base + 22 >= out_floats.size():
			break
		if out_floats[base] < 0.5:
			continue
		var a_index := int(roundf(out_floats[base + 1]))
		var b_index := int(roundf(out_floats[base + 2]))
		if a_index < 0 or b_index < 0 or a_index >= collider_count or b_index >= collider_count:
			continue
		var normal := Vector2(out_floats[base + 3], out_floats[base + 4])
		if normal.length() <= 0.0001:
			continue
		responses.append({
			"index_a": a_index,
			"index_b": b_index,
			"normal": normal.normalized(),
			"penetration": maxf(0.0, out_floats[base + 5]),
			"contact_point": Vector2(out_floats[base + 6], out_floats[base + 7]),
			"relative_normal_velocity": out_floats[base + 8],
			"raw_contact_momentum": maxf(0.0, out_floats[base + 9]),
			"usable_contact_momentum": maxf(0.0, out_floats[base + 10]),
			"velocity_delta_a": Vector2(out_floats[base + 11], out_floats[base + 12]),
			"velocity_delta_b": Vector2(out_floats[base + 13], out_floats[base + 14]),
			"position_delta_a": Vector2(out_floats[base + 15], out_floats[base + 16]),
			"position_delta_b": Vector2(out_floats[base + 17], out_floats[base + 18]),
			"recovery_a": out_floats[base + 19] > 0.5,
			"recovery_b": out_floats[base + 20] > 0.5,
			"vfx_strength": maxf(0.0, out_floats[base + 21]),
			"vfx_kind": int(roundf(out_floats[base + 22])),
		})
	return responses


func compute_geometry_queries(colliders: Array, queries: Array, delta: float = 0.0, defer_readback: bool = false) -> Array:
	if not is_available():
		return []
	# Geometry queries share the collider buffer. Drain any deferred contact job before
	# uploading query data so the GPU never reads a buffer while the CPU rewrites it.
	_consume_pending_contact_frame()
	var deferred_hits: Array = []
	var deferred_stats: Dictionary = {}
	if defer_readback:
		deferred_hits = _consume_pending_query_frame()
		deferred_stats = _last_consumed_query_stats.duplicate(true)
	else:
		_consume_pending_query_frame()
	var collider_count := mini(colliders.size(), MAX_COLLIDERS)
	var query_count := mini(queries.size(), MAX_QUERIES)
	last_collider_count = collider_count
	last_query_count = query_count
	last_query_hit_count = 0
	last_overflow_flags = 0
	if collider_count <= 0 or query_count <= 0:
		last_upload_bytes = 0
		last_readback_bytes = 0
		return []
	var max_hits := maxi(1, mini(MAX_QUERY_HITS, collider_count * query_count))
	var collider_floats := PackedFloat32Array()
	collider_floats.resize(collider_count * COLLIDER_FLOATS)
	for i in range(collider_count):
		_pack_collider(collider_floats, i, Dictionary(colliders[i]))
	var query_floats := PackedFloat32Array()
	query_floats.resize(query_count * QUERY_FLOATS)
	for i in range(query_count):
		_pack_query(query_floats, i, Dictionary(queries[i]))
	var params := PackedFloat32Array([
		float(collider_count),
		float(query_count),
		float(max_hits),
		delta,
	])
	var collider_bytes := collider_floats.to_byte_array()
	var query_bytes := query_floats.to_byte_array()
	var param_bytes := params.to_byte_array()
	var counter_bytes := _zero_bytes(4 * 4)
	var hit_bytes_size := max_hits * QUERY_HIT_FLOATS * 4
	last_upload_bytes = collider_bytes.size() + query_bytes.size() + param_bytes.size() + counter_bytes.size()
	last_buffer_recreate_count = 0
	last_buffer_reuse_count = 0
	_ensure_query_buffers(collider_bytes.size(), query_bytes.size(), param_bytes.size(), counter_bytes.size(), hit_bytes_size)
	_update_buffer(collider_buffer_rid, collider_bytes)
	_update_buffer(query_buffer_rid, query_bytes)
	_update_buffer(query_param_buffer_rid, param_bytes)
	_update_buffer(query_counter_buffer_rid, counter_bytes)

	var uniforms: Array[RDUniform] = []
	uniforms.append(_storage_uniform(0, collider_buffer_rid))
	uniforms.append(_storage_uniform(1, query_buffer_rid))
	uniforms.append(_storage_uniform(2, query_hit_buffer_rid))
	uniforms.append(_storage_uniform(3, query_counter_buffer_rid))
	uniforms.append(_storage_uniform(4, query_param_buffer_rid))
	var uniform_set := rd.uniform_set_create(uniforms, geometry_query_shader_rid, 0)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, geometry_query_pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	last_query_groups = int(ceil(float(collider_count * query_count) / 64.0))
	rd.compute_list_dispatch(compute_list, last_query_groups, 1, 1)
	rd.compute_list_end()
	rd.submit()
	if defer_readback:
		deferred_query_submit_count += 1
		deferred_query_pending = true
		_pending_query_frame = {
			"query_counter_buffer": query_counter_buffer_rid,
			"query_hit_buffer": query_hit_buffer_rid,
			"counter_bytes": counter_bytes.size(),
			"max_hits": max_hits,
			"uniform_set": uniform_set,
		}
		last_deferred_query_readback = true
		last_query_hit_count = int(deferred_stats.get("hit_count", deferred_hits.size()))
		last_overflow_flags = int(deferred_stats.get("overflow_flags", 0))
		last_readback_bytes = int(deferred_stats.get("readback_bytes", 0))
		return deferred_hits
	last_deferred_query_readback = false
	rd.sync()

	var out_counter_bytes := rd.buffer_get_data(query_counter_buffer_rid, 0, counter_bytes.size())
	var hit_count := int(out_counter_bytes.decode_u32(0))
	last_overflow_flags = int(out_counter_bytes.decode_u32(4))
	var parse_count := mini(hit_count, max_hits)
	var hits: Array = []
	if parse_count > 0:
		var wanted_hit_bytes := parse_count * QUERY_HIT_FLOATS * 4
		var out_bytes := rd.buffer_get_data(query_hit_buffer_rid, 0, wanted_hit_bytes)
		var out_floats := out_bytes.to_float32_array()
		for hit_index in range(parse_count):
			var base := hit_index * QUERY_HIT_FLOATS
			if base + 11 >= out_floats.size():
				break
			if out_floats[base] < 0.5:
				continue
			hits.append({
				"query_index": int(roundf(out_floats[base + 1])),
				"collider_index": int(roundf(out_floats[base + 2])),
				"distance": maxf(0.0, out_floats[base + 3]),
				"position": Vector2(out_floats[base + 4], out_floats[base + 5]),
				"normal": Vector2(out_floats[base + 6], out_floats[base + 7]).normalized(),
				"projection": out_floats[base + 8],
				"vfx_strength": maxf(0.0, out_floats[base + 9]),
				"vfx_kind": int(roundf(out_floats[base + 10])),
			})
	last_query_hit_count = hits.size()
	last_readback_bytes = out_counter_bytes.size() + parse_count * QUERY_HIT_FLOATS * 4
	_free_rid(uniform_set)
	if last_overflow_flags != 0:
		status_note = "GPU geometry query truncated hit buffer: %d" % last_overflow_flags
	return hits


func _consume_pending_query_frame() -> Array:
	_last_consumed_query_stats = {}
	if _pending_query_frame.is_empty() or rd == null:
		deferred_query_pending = false
		return []
	var frame := _pending_query_frame
	_pending_query_frame = {}
	deferred_query_pending = false
	rd.sync()
	deferred_query_consume_count += 1
	var counter_bytes_size := int(frame.get("counter_bytes", 16))
	var out_counter_bytes := rd.buffer_get_data(frame.get("query_counter_buffer", RID()), 0, counter_bytes_size)
	var hit_count := int(out_counter_bytes.decode_u32(0))
	var overflow_flags := int(out_counter_bytes.decode_u32(4))
	var max_hits := int(frame.get("max_hits", MAX_QUERY_HITS))
	var parse_count := mini(hit_count, max_hits)
	var hits: Array = []
	var readback_bytes := out_counter_bytes.size()
	if parse_count > 0:
		var wanted_hit_bytes := parse_count * QUERY_HIT_FLOATS * 4
		var out_bytes := rd.buffer_get_data(frame.get("query_hit_buffer", RID()), 0, wanted_hit_bytes)
		readback_bytes += wanted_hit_bytes
		hits = _parse_query_hit_floats(out_bytes.to_float32_array(), parse_count)
	_free_rid(frame.get("uniform_set", RID()))
	_last_consumed_query_stats = {
		"hit_count": hits.size(),
		"overflow_flags": overflow_flags,
		"readback_bytes": readback_bytes,
	}
	if overflow_flags != 0:
		status_note = "GPU geometry query truncated hit buffer: %d" % overflow_flags
	return hits


func _parse_query_hit_floats(out_floats: PackedFloat32Array, parse_count: int) -> Array:
	var hits: Array = []
	for hit_index in range(parse_count):
		var base := hit_index * QUERY_HIT_FLOATS
		if base + 11 >= out_floats.size():
			break
		if out_floats[base] < 0.5:
			continue
		hits.append({
			"query_index": int(roundf(out_floats[base + 1])),
			"collider_index": int(roundf(out_floats[base + 2])),
			"distance": maxf(0.0, out_floats[base + 3]),
			"position": Vector2(out_floats[base + 4], out_floats[base + 5]),
			"normal": Vector2(out_floats[base + 6], out_floats[base + 7]).normalized(),
			"projection": out_floats[base + 8],
			"vfx_strength": maxf(0.0, out_floats[base + 9]),
			"vfx_kind": int(roundf(out_floats[base + 10])),
		})
	return hits


func _ensure_collision_buffers(collider_bytes: int, candidate_bytes: int, counter_bytes: int, param_bytes: int, response_bytes: int) -> void:
	collider_buffer_rid = _ensure_storage_buffer(collider_buffer_rid, "collider_buffer_bytes", collider_bytes)
	candidate_buffer_rid = _ensure_storage_buffer(candidate_buffer_rid, "candidate_buffer_bytes", candidate_bytes)
	counter_buffer_rid = _ensure_storage_buffer(counter_buffer_rid, "counter_buffer_bytes", counter_bytes)
	param_buffer_rid = _ensure_storage_buffer(param_buffer_rid, "param_buffer_bytes", param_bytes)
	response_buffer_rid = _ensure_storage_buffer(response_buffer_rid, "response_buffer_bytes", response_bytes)


func _ensure_query_buffers(collider_bytes: int, query_bytes: int, query_param_bytes: int, query_counter_bytes: int, query_hit_bytes: int) -> void:
	collider_buffer_rid = _ensure_storage_buffer(collider_buffer_rid, "collider_buffer_bytes", collider_bytes)
	query_buffer_rid = _ensure_storage_buffer(query_buffer_rid, "query_buffer_bytes", query_bytes)
	query_param_buffer_rid = _ensure_storage_buffer(query_param_buffer_rid, "query_param_buffer_bytes", query_param_bytes)
	query_counter_buffer_rid = _ensure_storage_buffer(query_counter_buffer_rid, "query_counter_buffer_bytes", query_counter_bytes)
	query_hit_buffer_rid = _ensure_storage_buffer(query_hit_buffer_rid, "query_hit_buffer_bytes", query_hit_bytes)


func _ensure_storage_buffer(current: RID, byte_field: String, required_bytes: int) -> RID:
	required_bytes = maxi(required_bytes, 4)
	var current_bytes := int(get(byte_field))
	if current.is_valid() and current_bytes >= required_bytes:
		buffer_reuse_count += 1
		last_buffer_reuse_count += 1
		return current
	_free_rid(current)
	var next_bytes := _next_buffer_capacity(required_bytes)
	set(byte_field, next_bytes)
	buffer_recreate_count += 1
	last_buffer_recreate_count += 1
	return rd.storage_buffer_create(next_bytes, _zero_bytes(next_bytes))


func _next_buffer_capacity(required_bytes: int) -> int:
	var capacity := 256
	while capacity < required_bytes:
		capacity *= 2
	return capacity


func _update_buffer(buffer: RID, bytes: PackedByteArray) -> void:
	if not buffer.is_valid() or bytes.is_empty():
		return
	if rd.has_method("buffer_update"):
		rd.buffer_update(buffer, 0, bytes.size(), bytes)
	else:
		status_note = "RenderingDevice buffer_update unavailable; persistent GPU buffer updates cannot run."


func _storage_uniform(binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform


func _zero_bytes(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(maxi(0, size))
	return bytes


func _pack_collider(target: PackedFloat32Array, index: int, collider: Dictionary) -> void:
	var base := index * COLLIDER_FLOATS
	var polygon := _polygon_points(collider)
	var center := _center_for(collider, polygon)
	var aabb := _aabb_for(polygon, center)
	var velocity: Vector2 = collider.get("unit_velocity", Vector2.ZERO)
	var flags := int(collider.get("gpu_flags", 0))
	if bool(collider.get("gpu_anchored", false)):
		flags |= FLAG_ANCHORED
	target[base + 0] = 1.0
	target[base + 1] = float(int(collider.get("gpu_unit_key", collider.get("unit_instance_id", 0))))
	target[base + 2] = float(int(collider.get("gpu_team_key", collider.get("team_id", collider.get("owner_id", 0)))))
	target[base + 3] = float(flags)
	target[base + 4] = center.x
	target[base + 5] = center.y
	target[base + 6] = aabb.position.x
	target[base + 7] = aabb.position.y
	target[base + 8] = aabb.position.x + aabb.size.x
	target[base + 9] = aabb.position.y + aabb.size.y
	target[base + 10] = _bounding_radius(polygon, center)
	target[base + 11] = float(mini(polygon.size(), MAX_VERTICES))
	target[base + 12] = velocity.x
	target[base + 13] = velocity.y
	target[base + 14] = maxf(1.0, float(collider.get("gpu_mass", collider.get("mass", 1.0))))
	target[base + 15] = maxf(1.0, float(collider.get("gpu_path_stiffness", collider.get("path_stiffness_momentum", collider.get("stiffness_momentum", 1.0)))))
	target[base + 16] = clampf(float(collider.get("gpu_action_phase", 1.0)), 0.0, 1.0)
	target[base + 17] = 1.0 if bool(collider.get("gpu_recovery_capable", false)) else 0.0
	target[base + 66] = maxf(0.0, float(collider.get("damage_coeff", 1.0)))
	target[base + 67] = maxf(0.0, float(collider.get("break_coeff", 0.5)))
	for i in range(mini(polygon.size(), MAX_VERTICES)):
		var point: Vector2 = polygon[i]
		target[base + 18 + i * 2] = point.x
		target[base + 19 + i * 2] = point.y


func _pack_query(target: PackedFloat32Array, index: int, query: Dictionary) -> void:
	var base := index * QUERY_FLOATS
	var start: Vector2 = query.get("start", query.get("from", Vector2.ZERO))
	var end: Vector2 = query.get("end", query.get("to", start))
	var direction := end - start
	var max_distance := float(query.get("max_distance", direction.length()))
	if direction.length() <= 0.0001:
		var raw_direction: Vector2 = query.get("direction", Vector2.RIGHT)
		direction = raw_direction.normalized() * maxf(0.001, max_distance)
		end = start + direction
	if max_distance <= 0.0001:
		max_distance = direction.length()
	target[base + 0] = 1.0 if bool(query.get("active", true)) else 0.0
	target[base + 1] = float(int(query.get("owner_unit_key", query.get("gpu_unit_key", 0))))
	target[base + 2] = float(int(query.get("owner_team_key", query.get("gpu_team_key", 0))))
	target[base + 3] = float(int(query.get("query_kind", 0)))
	target[base + 4] = start.x
	target[base + 5] = start.y
	target[base + 6] = end.x
	target[base + 7] = end.y
	target[base + 8] = maxf(0.0, float(query.get("radius", 0.0)))
	target[base + 9] = max_distance
	target[base + 10] = 1.0 if bool(query.get("include_friendly", false)) else 0.0
	target[base + 11] = float(int(query.get("query_id", index)))


func _polygon_points(collider: Dictionary) -> Array:
	var polygon: Array = []
	if String(collider.get("shape", "")) == "polygon":
		for raw_point in Array(collider.get("polygon", [])):
			if raw_point is Vector2:
				polygon.append(Vector2(raw_point))
	if polygon.size() >= 3:
		return _decimate_polygon(polygon)
	var center: Vector2 = collider.get("center", Vector2.ZERO)
	var radius := maxf(0.001, float(collider.get("radius", 0.04)))
	if String(collider.get("shape", "")) == "capsule":
		var a: Vector2 = collider.get("a", center)
		var b: Vector2 = collider.get("b", center)
		return _capsule_polygon(a, b, radius)
	var steps := 16
	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		polygon.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return polygon


func _capsule_polygon(a: Vector2, b: Vector2, radius: float) -> Array:
	var axis := b - a
	if axis.length() <= 0.0001:
		return _polygon_points({"shape": "circle", "center": a, "radius": radius})
	var forward := axis.normalized()
	var right := Vector2(-forward.y, forward.x)
	var points: Array = []
	var steps := 8
	for i in range(steps + 1):
		var angle := PI * 0.5 + PI * float(i) / float(steps)
		points.append(a + right * cos(angle) * radius + forward * sin(angle) * radius)
	for i in range(steps + 1):
		var angle := -PI * 0.5 + PI * float(i) / float(steps)
		points.append(b + right * cos(angle) * radius + forward * sin(angle) * radius)
	return _decimate_polygon(points)


func _decimate_polygon(points: Array) -> Array:
	if points.size() <= MAX_VERTICES:
		return points
	var result: Array = []
	for i in range(MAX_VERTICES):
		var idx := int(floor(float(i) * float(points.size()) / float(MAX_VERTICES)))
		result.append(points[clampi(idx, 0, points.size() - 1)])
	return result


func _center_for(collider: Dictionary, polygon: Array) -> Vector2:
	if collider.has("center") and collider["center"] is Vector2:
		return collider["center"]
	var sum := Vector2.ZERO
	for raw_point in polygon:
		if raw_point is Vector2:
			sum += raw_point
	return sum / maxf(1.0, float(polygon.size()))


func _aabb_for(polygon: Array, center: Vector2) -> Rect2:
	if polygon.is_empty():
		return Rect2(center, Vector2.ZERO)
	var min_p := Vector2(1.0e20, 1.0e20)
	var max_p := Vector2(-1.0e20, -1.0e20)
	for raw_point in polygon:
		if raw_point is Vector2:
			var point: Vector2 = raw_point
			min_p.x = minf(min_p.x, point.x)
			min_p.y = minf(min_p.y, point.y)
			max_p.x = maxf(max_p.x, point.x)
			max_p.y = maxf(max_p.y, point.y)
	return Rect2(min_p, max_p - min_p)


func _bounding_radius(polygon: Array, center: Vector2) -> float:
	var radius := 0.001
	for raw_point in polygon:
		if raw_point is Vector2:
			radius = maxf(radius, center.distance_to(Vector2(raw_point)))
	return radius


func _free_rid(rid: RID) -> void:
	if rd != null and rid.is_valid():
		rd.free_rid(rid)
