extends RefCounted
class_name UnitEditorLegalityService

const HERO_SOUL_COUNT := "hero_soul_count"
const PUPPET_SOURCE_CODE_MISSING := "puppet_source_code_missing"
const BARRIER_ETHER_MISSING := "barrier_ether_missing"

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
	var messages: Dictionary = Dictionary(ROLE_IDENTITY_MESSAGES.get(code, {}))
	return {
		"code": code,
		"role": role,
		"actual": actual,
		"expected": expected,
		"message_zh": String(messages.get("zh", code)),
		"message_en": String(messages.get("en", code)),
	}


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
