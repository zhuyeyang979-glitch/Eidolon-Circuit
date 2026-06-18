extends RefCounted
class_name TeamLegalityService

const ACTIVE_RULE_ID := "light_5_pick_3_v1"

const LIGHT_5_PICK_3_PROFILE := {
	"rule_id": ACTIVE_RULE_ID,
	"roster_size": 5,
	"sortie_size": 3,
	"team_budget_cap": 2000,
	"starter_deploy_cost_cap": 200,
	"required_roster_roles": {
		"hero": 1,
		"puppet": 1,
		"barrier": 1,
	},
	"required_sortie_roles": {
		"hero": 1,
		"puppet": 1,
		"barrier": 1,
	},
	"max_unit_length": 4.5,
	"length_band_exempt_roles": ["barrier"],
	"length_bands": [
		{"threshold": 3.5, "max": 1},
		{"threshold": 2.5, "max": 2},
		{"threshold": 2.0, "max": 3},
	],
	"unit_legality_policy": "deployable",
}


func active_profile() -> Dictionary:
	return LIGHT_5_PICK_3_PROFILE.duplicate(true)


func profile_for_rule_id(rule_id: String) -> Dictionary:
	if rule_id == ACTIVE_RULE_ID:
		return active_profile()
	return {}


func profile_for_saved_payload(payload: Dictionary) -> Dictionary:
	var explicit_rule_id := String(payload.get("rule_id", "")).strip_edges()
	if explicit_rule_id != "":
		return profile_for_rule_id(explicit_rule_id)
	var match_format := String(payload.get("match_format", "")).strip_edges()
	var roster_cap := int(payload.get("roster_cap", 0))
	var sortie_cap := int(payload.get("sortie_cap", 0))
	if match_format == "light" or (roster_cap == 5 and sortie_cap == 3):
		return active_profile()
	return {}


func audit(profile: Dictionary, roster_entries: Array, sortie_entries: Array = [], starter_entry: Dictionary = {}) -> Dictionary:
	var active := active_profile() if profile.is_empty() else profile.duplicate(true)
	var roster_codes: Array = []
	var sortie_codes: Array = []
	var battle_codes: Array = []
	var warnings: Array = []
	var roster_role_counts := _role_counts(roster_entries)
	var sortie_role_counts := _role_counts(sortie_entries)
	var roster_cost := _total_cost(roster_entries)
	var roster_ids := _entry_ids(roster_entries)
	var sortie_ids := _entry_ids(sortie_entries)
	var roster_size := int(active.get("roster_size", 5))
	var sortie_size := int(active.get("sortie_size", 3))
	var team_budget_cap := int(active.get("team_budget_cap", 2000))
	var starter_cap := int(active.get("starter_deploy_cost_cap", 200))

	if roster_entries.size() != roster_size:
		_add_code(roster_codes, "roster_count")
	if roster_entries.size() > roster_size:
		_add_code(roster_codes, "roster_over_cap")
	if _has_duplicate_nonempty_values(roster_ids):
		_add_code(roster_codes, "duplicate_roster_entry")
	if _has_illegal_entry(roster_entries):
		_add_code(roster_codes, "illegal_roster_unit")
	if roster_cost > team_budget_cap:
		_add_code(roster_codes, "team_budget")
	for raw_role in Dictionary(active.get("required_roster_roles", {})).keys():
		var role_key := String(raw_role)
		if int(roster_role_counts.get(role_key, 0)) < int(Dictionary(active.get("required_roster_roles", {})).get(role_key, 0)):
			_add_code(roster_codes, "roster_missing_role:%s" % role_key)

	var length_metrics := _length_metrics(active, roster_entries)
	if int(length_metrics.get("over_max_count", 0)) > 0:
		_add_code(roster_codes, "unit_length")
	for raw_overflow in Array(length_metrics.get("band_overflows", [])):
		_add_code(roster_codes, "length_band:%s" % String(raw_overflow))

	if sortie_entries.size() != sortie_size:
		_add_code(sortie_codes, "sortie_count")
	if _has_duplicate_nonempty_values(sortie_ids):
		_add_code(sortie_codes, "duplicate_sortie_entry")
	if _has_illegal_entry(sortie_entries):
		_add_code(sortie_codes, "illegal_sortie_unit")
	if _contains_outside_entry(sortie_ids, roster_ids):
		_add_code(sortie_codes, "sortie_not_in_roster")
	for raw_role in Dictionary(active.get("required_sortie_roles", {})).keys():
		var role_key := String(raw_role)
		if int(sortie_role_counts.get(role_key, 0)) < int(Dictionary(active.get("required_sortie_roles", {})).get(role_key, 0)):
			_add_code(sortie_codes, "sortie_missing_role:%s" % role_key)

	var starter_id := _entry_id(starter_entry, -1)
	var starter_deploy_cost := int(starter_entry.get("deploy_cost", starter_entry.get("cost", 0))) if not starter_entry.is_empty() else 0
	if starter_entry.is_empty() or starter_id == "":
		_add_code(battle_codes, "starter_missing")
	elif not sortie_ids.has(starter_id):
		_add_code(battle_codes, "starter_not_in_sortie")
	if not starter_entry.is_empty() and starter_deploy_cost > starter_cap:
		_add_code(battle_codes, "starter_deploy_cost")

	var draft_blockers := _draft_blocking_codes(roster_codes)
	var draft_valid := draft_blockers.is_empty()
	var roster_ready := draft_valid and not roster_codes.has("roster_count") and not _has_code_prefix(roster_codes, "roster_missing_role:")
	var sortie_ready := roster_ready and sortie_codes.is_empty()
	var battle_ready := sortie_ready and battle_codes.is_empty()
	var blocking_codes := _merged_unique(roster_codes, sortie_codes, battle_codes)
	return {
		"rule_id": String(active.get("rule_id", "")),
		"draft_valid": draft_valid,
		"roster_ready": roster_ready,
		"sortie_ready": sortie_ready,
		"battle_ready": battle_ready,
		"valid": battle_ready,
		"roster_blocking_codes": roster_codes,
		"sortie_blocking_codes": sortie_codes,
		"battle_blocking_codes": battle_codes,
		"blocking_codes": blocking_codes,
		"blocking_notes": blocking_codes.duplicate(),
		"warnings": warnings,
		"metrics": {
			"roster_count": roster_entries.size(),
			"sortie_count": sortie_entries.size(),
			"team_cost": roster_cost,
			"starter_deploy_cost": starter_deploy_cost,
			"roster_role_counts": roster_role_counts,
			"sortie_role_counts": sortie_role_counts,
			"length_band_counts": Dictionary(length_metrics.get("band_counts", {})).duplicate(true),
			"over_max_length_count": int(length_metrics.get("over_max_count", 0)),
		},
	}


func _draft_blocking_codes(roster_codes: Array) -> Array:
	var result: Array = []
	for raw_code in roster_codes:
		var code := String(raw_code)
		if code == "roster_count" or code.begins_with("roster_missing_role:"):
			continue
		_add_code(result, code)
	return result


func _role_counts(entries: Array) -> Dictionary:
	var counts := {}
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var role_key := String(Dictionary(raw_entry).get("role", "")).strip_edges()
		if role_key == "":
			continue
		counts[role_key] = int(counts.get(role_key, 0)) + 1
	return counts


func _total_cost(entries: Array) -> int:
	var total := 0
	for raw_entry in entries:
		if raw_entry is Dictionary:
			total += maxi(0, int(Dictionary(raw_entry).get("cost", 0)))
	return total


func _entry_ids(entries: Array) -> Array:
	var ids: Array = []
	for i in range(entries.size()):
		if not (entries[i] is Dictionary):
			ids.append("")
			continue
		ids.append(_entry_id(Dictionary(entries[i]), i))
	return ids


func _entry_id(entry: Dictionary, fallback_index: int) -> String:
	var entry_id := String(entry.get("entry_id", entry.get("path", entry.get("unit_id", "")))).strip_edges()
	if entry_id == "" and fallback_index >= 0:
		entry_id = "slot:%d" % fallback_index
	return entry_id


func _has_duplicate_nonempty_values(values: Array) -> bool:
	var seen := {}
	for raw_value in values:
		var value := String(raw_value)
		if value == "":
			continue
		if seen.has(value):
			return true
		seen[value] = true
	return false


func _has_illegal_entry(entries: Array) -> bool:
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			return true
		var entry: Dictionary = raw_entry
		if not bool(entry.get("legal", false)) or String(entry.get("illegal_note", "")).strip_edges() != "":
			return true
	return false


func _contains_outside_entry(candidate_ids: Array, allowed_ids: Array) -> bool:
	for raw_id in candidate_ids:
		var entry_id := String(raw_id)
		if entry_id == "" or not allowed_ids.has(entry_id):
			return true
	return false


func _length_metrics(profile: Dictionary, entries: Array) -> Dictionary:
	var max_unit_length := float(profile.get("max_unit_length", 4.5))
	var exempt_roles: Array = Array(profile.get("length_band_exempt_roles", []))
	var bands: Array = Array(profile.get("length_bands", []))
	var band_counts := {}
	var band_overflows: Array = []
	var over_max_count := 0
	for raw_band in bands:
		if raw_band is Dictionary:
			band_counts[_threshold_key(float(Dictionary(raw_band).get("threshold", 0.0)))] = 0
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var length := maxf(0.0, float(entry.get("length", 0.0)))
		if length > max_unit_length:
			over_max_count += 1
		if exempt_roles.has(String(entry.get("role", ""))):
			continue
		for raw_band in bands:
			if not (raw_band is Dictionary):
				continue
			var threshold := float(Dictionary(raw_band).get("threshold", 0.0))
			if length > threshold:
				var key := _threshold_key(threshold)
				band_counts[key] = int(band_counts.get(key, 0)) + 1
				break
	for raw_band in bands:
		if not (raw_band is Dictionary):
			continue
		var band: Dictionary = raw_band
		var key := _threshold_key(float(band.get("threshold", 0.0)))
		if int(band_counts.get(key, 0)) > int(band.get("max", 0)):
			band_overflows.append(key)
	return {
		"over_max_count": over_max_count,
		"band_counts": band_counts,
		"band_overflows": band_overflows,
	}


func _threshold_key(value: float) -> String:
	return "%.1f" % value


func _has_code_prefix(codes: Array, prefix: String) -> bool:
	for raw_code in codes:
		if String(raw_code).begins_with(prefix):
			return true
	return false


func _merged_unique(first: Array, second: Array, third: Array) -> Array:
	var result: Array = []
	for source in [first, second, third]:
		for raw_code in source:
			_add_code(result, String(raw_code))
	return result


func _add_code(codes: Array, code: String) -> void:
	if code != "" and not codes.has(code):
		codes.append(code)
