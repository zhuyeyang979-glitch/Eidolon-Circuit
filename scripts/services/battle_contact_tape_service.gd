extends RefCounted
class_name BattleContactTapeService

# GPU responses are authoritative when consumed by a simulation step. A replay
# feeds those same responses back to the existing contact resolver; render-frame
# timing and GPU availability do not decide when damage occurs during playback.
# The caller must also replay the same battle start payload and input frames.
const SCHEMA_VERSION := 1
const RECORD_WIDTH := 22
const MAX_RECORDS_PER_STEP := 8192


static func encode_step(step: int, collider_count: int, records: Array, candidate_count: int, readback_bytes: int) -> Dictionary:
	if step <= 0 or collider_count < 2 or records.size() > MAX_RECORDS_PER_STEP:
		return {}
	var packed: Array = []
	for raw_record in records:
		if not (raw_record is Dictionary):
			return {}
		var record: Dictionary = raw_record
		var normal: Vector2 = record.get("normal", Vector2.ZERO)
		var point: Vector2 = record.get("contact_point", Vector2.ZERO)
		var velocity_a: Vector2 = record.get("velocity_delta_a", Vector2.ZERO)
		var velocity_b: Vector2 = record.get("velocity_delta_b", Vector2.ZERO)
		var position_a: Vector2 = record.get("position_delta_a", Vector2.ZERO)
		var position_b: Vector2 = record.get("position_delta_b", Vector2.ZERO)
		packed.append([
			int(record.get("index_a", -1)), int(record.get("index_b", -1)),
			normal.x, normal.y, float(record.get("penetration", 0.0)),
			point.x, point.y, float(record.get("relative_normal_velocity", 0.0)),
			float(record.get("raw_contact_momentum", 0.0)), float(record.get("usable_contact_momentum", 0.0)),
			velocity_a.x, velocity_a.y, velocity_b.x, velocity_b.y,
			position_a.x, position_a.y, position_b.x, position_b.y,
			bool(record.get("recovery_a", false)), bool(record.get("recovery_b", false)),
			float(record.get("vfx_strength", 0.0)), int(record.get("vfx_kind", 0)),
		])
	return {
		"step": step,
		"collider_count": collider_count,
		"candidate_count": candidate_count,
		"readback_bytes": readback_bytes,
		"records": packed,
	}


static func decode_step(raw_step, expected_step: int, collider_count: int) -> Dictionary:
	if not (raw_step is Dictionary):
		return {"error": "contact step is not a dictionary"}
	var step: Dictionary = raw_step
	if int(step.get("step", -1)) != expected_step:
		return {"error": "contact step mismatch: expected %d, got %d" % [expected_step, int(step.get("step", -1))]}
	if int(step.get("collider_count", -1)) != collider_count:
		return {"error": "contact collider count mismatch at step %d" % expected_step}
	if not (step.get("records") is Array):
		return {"error": "contact records missing at step %d" % expected_step}
	var packed: Array = step["records"]
	if packed.size() > MAX_RECORDS_PER_STEP:
		return {"error": "too many contact records at step %d" % expected_step}
	var records: Array = []
	for raw_record in packed:
		if not (raw_record is Array) or Array(raw_record).size() != RECORD_WIDTH:
			return {"error": "invalid contact record width at step %d" % expected_step}
		var values: Array = raw_record
		for index in range(RECORD_WIDTH):
			if index in [18, 19]:
				if typeof(values[index]) != TYPE_BOOL:
					return {"error": "invalid contact recovery flag at step %d" % expected_step}
			elif not (typeof(values[index]) in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(values[index])):
				return {"error": "non-finite contact value at step %d" % expected_step}
		var index_a := int(values[0])
		var index_b := int(values[1])
		if index_a < 0 or index_b < 0 or index_a >= collider_count or index_b >= collider_count:
			return {"error": "contact collider index out of range at step %d" % expected_step}
		var normal := Vector2(float(values[2]), float(values[3]))
		if normal.length() <= 0.0001:
			return {"error": "contact normal missing at step %d" % expected_step}
		records.append({
			"index_a": index_a, "index_b": index_b,
			"normal": normal, "penetration": float(values[4]),
			"contact_point": Vector2(float(values[5]), float(values[6])),
			"relative_normal_velocity": float(values[7]),
			"raw_contact_momentum": float(values[8]),
			"usable_contact_momentum": float(values[9]),
			"velocity_delta_a": Vector2(float(values[10]), float(values[11])),
			"velocity_delta_b": Vector2(float(values[12]), float(values[13])),
			"position_delta_a": Vector2(float(values[14]), float(values[15])),
			"position_delta_b": Vector2(float(values[16]), float(values[17])),
			"recovery_a": bool(values[18]), "recovery_b": bool(values[19]),
			"vfx_strength": float(values[20]), "vfx_kind": int(values[21]),
		})
	return {
		"records": records,
		"candidate_count": maxi(0, int(step.get("candidate_count", 0))),
		"readback_bytes": maxi(0, int(step.get("readback_bytes", 0))),
	}
