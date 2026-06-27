extends RefCounted
class_name UnitEditorLegalityService

const HERO_SOUL_COUNT := "hero_soul_count"
const PUPPET_SOURCE_CODE_MISSING := "puppet_source_code_missing"
const BARRIER_ETHER_MISSING := "barrier_ether_missing"
const SOCKET_PART_TOO_LARGE := "socket_part_too_large"
const CONSTRUCT_BODY_MIXED_MANUFACTURER := "construct_body_mixed_manufacturer"

const SOFTWARE_MANUFACTURERS := ["NULL SOFTWARE", "BOOTLEG GHOST"]

const ROLE_IDENTITY_MESSAGES := {
	HERO_SOUL_COUNT: {
		"zh": "英雄必须恰好携带 1 个英魂。",
		"en": "A hero must carry exactly 1 Soul.",
	},
	PUPPET_SOURCE_CODE_MISSING: {
		"zh": "傀儡必须至少携带 1 个源代码。",
		"en": "A puppet must carry at least 1 Source Code.",
	},
	BARRIER_ETHER_MISSING: {
		"zh": "结界必须至少携带 1 个以太。",
		"en": "A barrier must carry at least 1 Ether.",
	},
}

const SOCKET_SIZE_MESSAGES := {
	SOCKET_PART_TOO_LARGE: {
		"zh": "部件尺寸超过插槽容量。",
		"en": "Part size exceeds socket capacity.",
	},
}

const MANUFACTURER_MESSAGES := {
	CONSTRUCT_BODY_MIXED_MANUFACTURER: {
		"zh": "同一构件体只能使用同一硬件厂商。",
		"en": "Each construct body can only use one hardware manufacturer.",
	},
}


func audit_role_identity(role_key: String, blueprint: Dictionary, catalog_by_slot: Dictionary = {}) -> Dictionary:
	var role := role_key.strip_edges()
	if role == "":
		role = String(blueprint.get("role", "")).strip_edges()
	var metrics := identity_metrics(blueprint, catalog_by_slot)
	var issues: Array = []
	match role:
		"hero":
			var soul_count := int(metrics.get("soul_count", 0))
			if soul_count != 1:
				issues.append(_issue(HERO_SOUL_COUNT, role, soul_count, "1"))
		"puppet":
			var source_code_count := int(metrics.get("source_code_count", 0))
			if source_code_count < 1:
				issues.append(_issue(PUPPET_SOURCE_CODE_MISSING, role, source_code_count, ">=1"))
		"barrier":
			var ether_count := int(metrics.get("ether_count", 0))
			if ether_count < 1:
				issues.append(_issue(BARRIER_ETHER_MISSING, role, ether_count, ">=1"))
	return _report(role, metrics, issues)


func audit_socket_sizes(blueprint: Dictionary) -> Dictionary:
	var records := socket_size_records(blueprint)
	var issues: Array = []
	var checked_count := 0
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var record: Dictionary = raw_record
		var part_size := _part_size_rank(record)
		var socket_capacity := _socket_capacity_rank(record)
		if part_size <= 0 or socket_capacity <= 0:
			continue
		checked_count += 1
		if part_size > socket_capacity:
			issues.append(_socket_size_issue(record, part_size, socket_capacity))
	return _report(String(blueprint.get("role", "")).strip_edges(), {
		"checked_socket_count": checked_count,
		"oversized_socket_count": issues.size(),
		"socket_record_count": records.size(),
	}, issues)


func audit_construct_body_manufacturers(blueprint: Dictionary) -> Dictionary:
	var records := construct_body_manufacturer_records(blueprint)
	var issues: Array = []
	var checked_count := 0
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var record: Dictionary = raw_record
		var manufacturers := _hardware_manufacturers_for_body(record)
		if manufacturers.is_empty():
			continue
		checked_count += 1
		if manufacturers.size() > 1:
			issues.append(_manufacturer_issue(record, manufacturers))
	return _report(String(blueprint.get("role", "")).strip_edges(), {
		"checked_construct_body_count": checked_count,
		"mixed_construct_body_count": issues.size(),
		"construct_body_record_count": records.size(),
	}, issues)


func construct_body_manufacturer_records(blueprint: Dictionary) -> Array:
	var records: Array = []
	for key in ["construct_bodies", "construct_body_manufacturer_records", "construct_body_records"]:
		_append_dictionary_array(records, blueprint.get(key, []))
	return records


func socket_size_records(blueprint: Dictionary) -> Array:
	var records: Array = []
	for key in ["socket_attachments", "socket_size_records", "socket_records"]:
		_append_dictionary_array(records, blueprint.get(key, []))
	for raw_payload in Array(blueprint.get("slot_payloads", [])):
		if not (raw_payload is Dictionary):
			continue
		var payload: Dictionary = Dictionary(raw_payload)
		if payload.has("socket_capacity") or payload.has("socket_size") or payload.has("slot_capacity"):
			records.append(payload)
	return records


func identity_metrics(blueprint: Dictionary, catalog_by_slot: Dictionary = {}) -> Dictionary:
	var identity_payloads := _identity_payloads(blueprint)
	var soul_count := 0
	var source_code_count := 0
	var ether_count := 0
	for raw_payload in identity_payloads:
		if not (raw_payload is Dictionary):
			continue
		var payload: Dictionary = raw_payload
		var identity_kind := _identity_kind(payload, catalog_by_slot)
		match identity_kind:
			"soul":
				soul_count += 1
			"source_code":
				source_code_count += 1
			"ether":
				ether_count += 1
	return {
		"soul_count": soul_count,
		"source_code_count": source_code_count,
		"ether_count": ether_count,
		"identity_payload_count": identity_payloads.size(),
	}


func _identity_payloads(blueprint: Dictionary) -> Array:
	var payloads: Array = []
	for key in ["identity_payloads", "software_payloads", "slot_payloads", "parts"]:
		_append_dictionary_array(payloads, blueprint.get(key, []))
	for raw_node in Array(blueprint.get("nodes", Array(Dictionary(blueprint.get("custom_topology", {})).get("nodes", [])))):
		if not (raw_node is Dictionary):
			continue
		var node: Dictionary = raw_node
		if node.has("part") and node.get("part") is Dictionary:
			payloads.append({"part": Dictionary(node.get("part", {}))})
		elif node.has("identity_kind") or node.has("software_kind") or node.has("kind"):
			payloads.append(node)
	return payloads


func _append_dictionary_array(target: Array, raw_value) -> void:
	if not (raw_value is Array):
		return
	for raw_entry in Array(raw_value):
		if raw_entry is Dictionary:
			target.append(Dictionary(raw_entry))


func _identity_kind(payload: Dictionary, catalog_by_slot: Dictionary) -> String:
	for key in ["identity_kind", "software_kind", "special_kind", "kind"]:
		var normalized := _normalize_identity_kind(String(payload.get(key, "")))
		if normalized != "":
			if normalized == "special" or normalized == "module":
				break
			return normalized
	for part_key in ["part", "special_part"]:
		if payload.get(part_key) is Dictionary:
			var part: Dictionary = Dictionary(payload.get(part_key, {}))
			var normalized_part := _normalize_identity_kind(String(part.get("kind", part.get("identity_kind", part.get("software_kind", "")))))
			if normalized_part != "":
				return normalized_part
	if payload.has("special"):
		var slot_key := String(payload.get("slot", payload.get("slot_key", "special"))).strip_edges()
		if slot_key == "":
			slot_key = "special"
		var catalog_part := _catalog_part(catalog_by_slot, slot_key, int(payload.get("special", -1)))
		return _normalize_identity_kind(String(catalog_part.get("kind", catalog_part.get("identity_kind", catalog_part.get("software_kind", "")))))
	return ""


func _part_size_rank(record: Dictionary) -> int:
	for key in ["part_size", "size", "size_rank", "part_size_rank", "slot_volume_tier", "size_tier", "size_class", "ammo_size_tier"]:
		if record.has(key):
			var rank := _size_rank(record.get(key))
			if rank > 0:
				return rank
	for key in ["part", "payload_part"]:
		if record.get(key) is Dictionary:
			var part: Dictionary = Dictionary(record.get(key, {}))
			for part_key in ["part_size", "size", "size_rank", "part_size_rank", "slot_volume_tier", "size_tier", "size_class", "ammo_size_tier"]:
				if part.has(part_key):
					var part_rank := _size_rank(part.get(part_key))
					if part_rank > 0:
						return part_rank
	return 0


func _socket_capacity_rank(record: Dictionary) -> int:
	for key in ["socket_capacity", "socket_size", "capacity", "slot_capacity", "socket_rank", "slot_size"]:
		if record.has(key):
			var rank := _size_rank(record.get(key))
			if rank > 0:
				return rank
	if record.get("socket") is Dictionary:
		var socket: Dictionary = Dictionary(record.get("socket", {}))
		for socket_key in ["socket_capacity", "socket_size", "capacity", "slot_capacity", "socket_rank", "slot_size"]:
			if socket.has(socket_key):
				var socket_rank := _size_rank(socket.get(socket_key))
				if socket_rank > 0:
					return socket_rank
	return 0


func _size_rank(raw_value) -> int:
	if raw_value is int or raw_value is float:
		return clampi(int(round(float(raw_value))), 1, 5)
	var label := String(raw_value).strip_edges().to_lower()
	if label == "":
		return 0
	if label.is_valid_float():
		return clampi(int(round(float(label))), 1, 5)
	match label:
		"xs", "nano", "starter", "tiny":
			return 1
		"s", "small", "light":
			return 2
		"m", "medium", "standard", "mid":
			return 3
		"l", "large", "heavy":
			return 4
		"xl", "xlarge", "extra_large", "siege", "titan", "monster", "leviathan":
			return 5
	return 0


func _hardware_manufacturers_for_body(record: Dictionary) -> Array:
	var manufacturers: Array = []
	for raw_part in Array(record.get("parts", record.get("hardware_parts", []))):
		if not (raw_part is Dictionary):
			continue
		var part_record: Dictionary = Dictionary(raw_part)
		if not _manufacturer_record_counts_as_hardware(part_record):
			continue
		var maker := _manufacturer_for_record(part_record)
		if maker == "" or SOFTWARE_MANUFACTURERS.has(maker) or manufacturers.has(maker):
			continue
		manufacturers.append(maker)
	return manufacturers


func _manufacturer_record_counts_as_hardware(record: Dictionary) -> bool:
	var part: Dictionary = Dictionary(record.get("part", {})) if record.get("part") is Dictionary else {}
	if bool(record.get("software", part.get("software", false))):
		return false
	var slot_key := String(record.get("slot_key", record.get("slot", part.get("slot_key", part.get("slot", ""))))).strip_edges().to_lower()
	if slot_key in ["special", "module", "code", "ether"]:
		return false
	var kind := _normalize_identity_kind(String(record.get("kind", part.get("kind", part.get("identity_kind", part.get("software_kind", ""))))))
	if kind in ["soul", "source_code", "ether", "module"]:
		return false
	return true


func _manufacturer_for_record(record: Dictionary) -> String:
	var maker := String(record.get("maker", record.get("manufacturer", ""))).strip_edges()
	if maker != "":
		return maker
	if record.get("part") is Dictionary:
		var part: Dictionary = Dictionary(record.get("part", {}))
		return String(part.get("maker", part.get("manufacturer", ""))).strip_edges()
	return ""


func _manufacturer_issue(record: Dictionary, manufacturers: Array) -> Dictionary:
	var messages: Dictionary = _messages_for_code(CONSTRUCT_BODY_MIXED_MANUFACTURER)
	return {
		"code": CONSTRUCT_BODY_MIXED_MANUFACTURER,
		"body_id": String(record.get("body_id", record.get("construct_body_id", ""))),
		"manufacturers": manufacturers.duplicate(),
		"manufacturer_count": manufacturers.size(),
		"message_zh": String(messages.get("zh", CONSTRUCT_BODY_MIXED_MANUFACTURER)),
		"message_en": String(messages.get("en", CONSTRUCT_BODY_MIXED_MANUFACTURER)),
	}


func _socket_size_issue(record: Dictionary, part_size: int, socket_capacity: int) -> Dictionary:
	var messages: Dictionary = _messages_for_code(SOCKET_PART_TOO_LARGE)
	var part_name := String(record.get("part_name", ""))
	if part_name == "" and record.get("part") is Dictionary:
		part_name = String(Dictionary(record.get("part", {})).get("name", ""))
	return {
		"code": SOCKET_PART_TOO_LARGE,
		"socket_id": String(record.get("socket_id", record.get("socket", ""))),
		"part_name": part_name,
		"part_size": part_size,
		"socket_capacity": socket_capacity,
		"message_zh": String(messages.get("zh", SOCKET_PART_TOO_LARGE)),
		"message_en": String(messages.get("en", SOCKET_PART_TOO_LARGE)),
	}


func _catalog_part(catalog_by_slot: Dictionary, slot_key: String, part_index: int) -> Dictionary:
	if part_index < 0:
		return {}
	var raw_catalog = catalog_by_slot.get(slot_key, [])
	if raw_catalog is Array:
		var catalog: Array = Array(raw_catalog)
		if part_index >= 0 and part_index < catalog.size() and catalog[part_index] is Dictionary:
			return Dictionary(catalog[part_index])
	elif raw_catalog is Dictionary:
		var catalog_by_index: Dictionary = Dictionary(raw_catalog)
		var raw_part = catalog_by_index.get(part_index, catalog_by_index.get(str(part_index), {}))
		if raw_part is Dictionary:
			return Dictionary(raw_part)
	return {}


func _normalize_identity_kind(raw_kind: String) -> String:
	var kind := raw_kind.strip_edges().to_lower()
	match kind:
		"soul":
			return "soul"
		"code", "source", "source_code", "source code":
			return "source_code"
		"ether":
			return "ether"
		"special", "module":
			return kind
	return ""


func _issue(code: String, role: String, actual: int, expected: String) -> Dictionary:
	var messages: Dictionary = _messages_for_code(code)
	return {
		"code": code,
		"role": role,
		"actual": actual,
		"expected": expected,
		"message_zh": String(messages.get("zh", code)),
		"message_en": String(messages.get("en", code)),
	}


func _messages_for_code(code: String) -> Dictionary:
	var role_messages = ROLE_IDENTITY_MESSAGES.get(code, {})
	if role_messages is Dictionary and not Dictionary(role_messages).is_empty():
		return Dictionary(role_messages)
	var socket_messages = SOCKET_SIZE_MESSAGES.get(code, {})
	if socket_messages is Dictionary:
		return Dictionary(socket_messages)
	var manufacturer_messages = MANUFACTURER_MESSAGES.get(code, {})
	if manufacturer_messages is Dictionary:
		return Dictionary(manufacturer_messages)
	return {}


func _report(role: String, metrics: Dictionary, issues: Array) -> Dictionary:
	var blocking_codes: Array = []
	var messages_zh: Array = []
	var messages_en: Array = []
	for raw_issue in issues:
		if not (raw_issue is Dictionary):
			continue
		var issue: Dictionary = raw_issue
		var code := String(issue.get("code", ""))
		if code != "" and not blocking_codes.has(code):
			blocking_codes.append(code)
		var message_zh := String(issue.get("message_zh", "")).strip_edges()
		if message_zh != "":
			messages_zh.append(message_zh)
		var message_en := String(issue.get("message_en", "")).strip_edges()
		if message_en != "":
			messages_en.append(message_en)
	return {
		"role": role,
		"valid": blocking_codes.is_empty(),
		"blocking_codes": blocking_codes,
		"blocking_notes": blocking_codes.duplicate(),
		"issues": issues.duplicate(true),
		"messages": {
			"zh": messages_zh,
			"en": messages_en,
		},
		"metrics": metrics.duplicate(true),
	}
