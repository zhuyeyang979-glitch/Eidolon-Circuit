extends RefCounted
class_name UnitEditorEngineAllocationService


func allocation_data(unit_bp: Dictionary, torso_node_index: int, engine_payload_index: int, callbacks: Dictionary, zh: bool, fallback_role_key: String = "hero") -> Dictionary:
	if not unit_bp.has("custom_topology"):
		return {}
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	var role_key: String = String(unit_bp.get("role", fallback_role_key))
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	if torso_node_index < 0 or torso_node_index >= nodes.size() or not (nodes[torso_node_index] is Dictionary):
		return {}
	var has_engine_payload := false
	var engine_payload: Dictionary = {}
	if engine_payload_index >= 0:
		if engine_payload_index >= payloads.size() or not (payloads[engine_payload_index] is Dictionary):
			return {}
		engine_payload = payloads[engine_payload_index]
		if String(engine_payload.get("kind", "")) != "engine":
			return {}
		if _payload_torso_node_index(callbacks, engine_payload, unit_bp) != torso_node_index:
			return {}
		has_engine_payload = true
	var stats := _callback_dict(callbacks, "editor_current_stats", [], {})
	var segments: Array = Array(stats.get("runtime_topology_segments", []))
	var segments_by_node := _segment_by_node(stats)
	var pool := _callback_float(callbacks, "engine_allocation_pool_for_torso", [unit_bp, torso_node_index], 0.0)
	var cooling_pool := _callback_float(callbacks, "thermal_load_pool_for_stats", [stats], 0.0)
	var engine_heat_load := _callback_float(callbacks, "engine_allocation_engine_idle_heat_for_torso", [unit_bp, torso_node_index], 0.0)
	var engine_part := _payload_part_for_payload(callbacks, role_key, engine_payload) if has_engine_payload else {"name": "NO ENGINE"}
	var torso_part := _callback_dict(callbacks, "topology_node_part", [role_key, nodes[torso_node_index], unit_bp], {})
	var entries: Array = []
	_append_booster_entries(entries, payloads, unit_bp, role_key, torso_node_index, pool, callbacks, zh)
	var allocation_groups := _append_limb_entries(entries, payloads, unit_bp, role_key, torso_node_index, pool, segments_by_node, callbacks, zh)
	var used_ratio := 0.0
	for entry in entries:
		if entry is Dictionary:
			used_ratio += maxf(0.0, float(Dictionary(entry).get("ratio", 0.0)))
	for i in range(entries.size()):
		if entries[i] is Dictionary:
			var entry: Dictionary = entries[i]
			entry["over_budget"] = used_ratio > 1.0001
			entries[i] = entry
	var heat_summary := _recalculate_heat(entries, cooling_pool, engine_heat_load, zh)
	entries = Array(heat_summary.get("entries", entries))
	var display_entries := entries.duplicate(true)
	if engine_heat_load > 0.0:
		display_entries.insert(0, _engine_heat_entry(engine_part, engine_heat_load, cooling_pool, callbacks, zh))
	var title := "动力预算" if zh else "DRIVE BUDGET"
	var engine_label := _zh_part_name(callbacks, String(engine_part.get("name", "引擎"))) if zh else String(engine_part.get("name", "ENGINE"))
	if not has_engine_payload:
		engine_label = "未装引擎" if zh else "NO ENGINE"
	var subtitle := ("%s / %s / 池 %.0f = 1.00" if zh else "%s / %s / POOL %.0f = 1.00") % [
		engine_label,
		_zh_part_name(callbacks, String(torso_part.get("name", "躯干"))) if zh else String(torso_part.get("name", "TORSO")),
		pool,
	]
	return {
		"title": title,
		"subtitle": subtitle,
		"engine_name": String(engine_part.get("name", "ENGINE")),
		"torso_name": String(torso_part.get("name", "TORSO")),
		"engine_output": pool,
		"used_ratio": used_ratio,
		"cooling_pool": cooling_pool,
		"engine_heat_load": engine_heat_load,
		"allocation_heat_used": maxf(0.0, float(heat_summary.get("allocation_heat_used", 0.0))),
		"heat_used": maxf(0.0, float(heat_summary.get("heat_used", 0.0))),
		"heat_ratio": maxf(0.0, float(heat_summary.get("heat_ratio", 0.0))),
		"thermal_margin": float(heat_summary.get("thermal_margin", cooling_pool)),
		"entries": entries,
		"display_entries": display_entries,
		"segments": segments,
		"allocation_groups": allocation_groups,
		"torso_node": torso_node_index,
		"engine_payload_index": engine_payload_index,
		"has_engine": has_engine_payload,
	}


func _append_booster_entries(entries: Array, payloads: Array, unit_bp: Dictionary, role_key: String, torso_node_index: int, pool: float, callbacks: Dictionary, zh: bool) -> void:
	for i in range(payloads.size()):
		if not (payloads[i] is Dictionary):
			continue
		var payload: Dictionary = payloads[i]
		if String(payload.get("kind", "")) != "booster":
			continue
		if _payload_torso_node_index(callbacks, payload, unit_bp) != torso_node_index:
			continue
		var booster_part := _payload_part_for_payload(callbacks, role_key, payload)
		var drive_min := _callback_float(callbacks, "thruster_drive_allocation_min_for_part", [booster_part], 0.0)
		var drive_max := _callback_float(callbacks, "thruster_drive_allocation_max_for_part", [booster_part], drive_min)
		var drive_momentum := _callback_float(callbacks, "thruster_drive_allocated_for_payload", [payload, booster_part], drive_min)
		var drive_ratio := drive_momentum / maxf(1.0, pool) if pool > 0.0 else 0.0
		var boost_min := _callback_float(callbacks, "thruster_boost_brake_allocation_min_for_part", [booster_part], 0.0)
		var boost_max := _callback_float(callbacks, "thruster_boost_brake_allocation_max_for_part", [booster_part], boost_min)
		var boost_momentum := _callback_float(callbacks, "thruster_boost_brake_allocated_for_payload", [payload, booster_part], boost_min)
		var boost_ratio := boost_momentum / maxf(1.0, pool) if pool > 0.0 else 0.0
		var boost_peak := drive_momentum + boost_momentum
		var boost_peak_ratio := boost_peak / maxf(1.0, pool) if pool > 0.0 else 0.0
		var booster_heat_coeff := _callback_float(callbacks, "thruster_idle_heat_coeff_for_part", [booster_part], 0.0)
		var booster_defaults := _callback_dict(callbacks, "thruster_with_drive_defaults", [booster_part], booster_part)
		var boost_heat_cost := maxf(0.0, float(booster_defaults.get("boost_heat", 0.0)))
		var booster_label := _short_part_display_name(callbacks, booster_part, "BOOSTER")
		entries.append({
			"id": "booster_drive:%d" % i,
			"kind": "booster_drive",
			"payload_index": i,
			"label": ("%s / 推进" if zh else "%s / MOVE") % booster_label,
			"line": ("普通移动/转向 %.0f-%.0f" if zh else "Move/turn %.0f-%.0f") % [drive_min, drive_max],
			"ratio": drive_ratio,
			"momentum": drive_momentum,
			"allocated_momentum": drive_momentum,
			"min_momentum": drive_min,
			"max_momentum": drive_max,
			"default_momentum": drive_min,
			"boost_extra_momentum": boost_momentum,
			"boost_peak_momentum": boost_peak,
			"boost_extra_ratio": boost_ratio,
			"boost_peak_ratio": boost_peak_ratio,
			"boost_dash_hint": true,
			"boost_label": ("Boost刹车 +%.0f / 峰值 %.0f" if zh else "Boost-brake +%.0f / PEAK %.0f") % [boost_momentum, boost_peak],
			"heat_coeff": booster_heat_coeff,
			"heat_color": Color(1.0, 0.48, 0.14, 1.0),
			"readonly": drive_max <= drive_min,
			"disabled": pool <= 0.0,
			"color": Color(1.0, 0.52, 0.18, 1.0),
		})
		entries.append({
			"id": "booster_boost_brake:%d" % i,
			"kind": "booster_boost_brake",
			"payload_index": i,
			"label": ("%s / Boost刹车" if zh else "%s / BOOST-BRAKE") % booster_label,
			"line": ("Boost/刹车峰值动力 %.0f-%.0f；事件热 %.1f" if zh else "Boost/brake peak drive %.0f-%.0f; event heat %.1f") % [boost_min, boost_max, boost_heat_cost],
			"ratio": boost_ratio,
			"momentum": boost_momentum,
			"allocated_momentum": boost_momentum,
			"min_momentum": boost_min,
			"max_momentum": boost_max,
			"default_momentum": boost_min,
			"boost_peak_momentum": boost_peak,
			"boost_peak_ratio": boost_peak_ratio,
			"heat_coeff": 0.0,
			"heat_exempt": true,
			"heat_label": ("Boost事件热 %.1f / 不占常热" if zh else "Boost event heat %.1f / no idle heat") % boost_heat_cost,
			"heat_color": Color(1.0, 0.62, 0.18, 1.0),
			"readonly": boost_max <= boost_min,
			"disabled": pool <= 0.0 or boost_max <= 0.0,
			"color": Color(1.0, 0.72, 0.22, 1.0),
		})


func _append_limb_entries(entries: Array, payloads: Array, unit_bp: Dictionary, role_key: String, torso_node_index: int, pool: float, segments_by_node: Dictionary, callbacks: Dictionary, zh: bool) -> Array:
	var allocation_groups: Array = []
	var counted_nodes := {}
	for ref in _callback_array(callbacks, "engine_allocation_sorted_binding_refs", [unit_bp], []):
		if not (ref is Dictionary):
			continue
		var ref_dict: Dictionary = ref
		var binding_index := int(ref_dict.get("index", -1))
		var binding: Dictionary = ref_dict.get("binding", {})
		var software_slot := int(binding.get("software_slot_index", -1))
		if software_slot < 0 or software_slot >= payloads.size() or not (payloads[software_slot] is Dictionary):
			continue
		var module_payload: Dictionary = payloads[software_slot]
		if String(module_payload.get("kind", "")) != "module":
			continue
		if _payload_torso_node_index(callbacks, module_payload, unit_bp) != torso_node_index:
			continue
		if _callback_int(callbacks, "module_binding_torso_node_index", [role_key, unit_bp, binding], -1) != torso_node_index:
			continue
		var module_part := _payload_part_for_payload(callbacks, role_key, module_payload)
		var binding_target_nodes: Array = Array(binding.get("target_nodes", []))
		var group_nodes: Array = []
		for raw_group_node in binding_target_nodes:
			var group_node := int(raw_group_node)
			if group_node >= 0 and segments_by_node.has(group_node):
				group_nodes.append(group_node)
		var group_id := "binding:%d:%s" % [binding_index, _callback_string(callbacks, "editor_int_array_signature", [group_nodes], "")]
		if not group_nodes.is_empty():
			allocation_groups.append({
				"id": group_id,
				"binding_index": binding_index,
				"target_nodes": group_nodes.duplicate(true),
				"root_index": int(binding.get("root_index", group_nodes[0])),
				"label": _short_part_display_name(callbacks, module_part, "ACTION"),
			})
		for raw_node in Array(binding.get("target_nodes", [])):
			var node_index := int(raw_node)
			if counted_nodes.has(node_index):
				continue
			if not segments_by_node.has(node_index):
				continue
			var segment: Dictionary = segments_by_node[node_index]
			if String(segment.get("part_kind", "")) == "torso":
				continue
			var drive_kind := String(segment.get("joint_drive_kind", "rigid"))
			if drive_kind == "rigid" or drive_kind == "port":
				continue
			var momentum := _callback_float(callbacks, "engine_allocation_limb_momentum_for_node", [binding, node_index, segment], 0.0)
			var default_momentum := _callback_float(callbacks, "engine_allocation_default_limb_momentum", [segment], 0.0)
			var min_momentum := maxf(0.0, float(segment.get("momentum_min", 0.0)))
			var max_momentum := maxf(0.0, float(segment.get("momentum_max", 0.0)))
			if max_momentum <= 0.0:
				max_momentum = maxf(default_momentum, min_momentum)
			var anchor := _segment_anchor(segment)
			var duration_info := _callback_dict(callbacks, "engine_allocation_limb_duration_estimate", [segment, module_part, momentum], {})
			var duration_estimate := maxf(0.0, float(duration_info.get("duration", 0.0)))
			var duration_context := _callback_dict(callbacks, "engine_allocation_limb_motion_context", [segment, module_part], {})
			var limb_heat_coeff := _callback_float(callbacks, "limb_drive_heat_coeff_for_segment", [segment, module_part], 0.0)
			counted_nodes[node_index] = true
			entries.append({
				"id": "limb:%d:%d" % [binding_index, node_index],
				"kind": "limb",
				"binding_index": binding_index,
				"node_index": node_index,
				"group_id": group_id,
				"target_nodes": group_nodes.duplicate(true),
				"label": _callback_string(callbacks, "short_part_name", [String(segment.get("name", "LIMB"))], String(segment.get("name", "LIMB"))),
				"line": ("%s %.0f-%.0f" if zh else "%s %.0f-%.0f") % [_callback_string(callbacks, "short_part_name", [String(module_part.get("name", "ACT"))], String(module_part.get("name", "ACT"))), min_momentum, max_momentum],
				"ratio": momentum / maxf(1.0, pool) if pool > 0.0 else 0.0,
				"momentum": momentum,
				"min_momentum": min_momentum,
				"max_momentum": max_momentum,
				"default_momentum": default_momentum,
				"duration_estimate": duration_estimate,
				"duration_budget": duration_info,
				"duration_label": _callback_string(callbacks, "engine_allocation_limb_duration_label", [module_part, min_momentum, max_momentum, duration_estimate], ""),
				"duration_module_part": module_part.duplicate(true),
				"duration_motion_stats": Dictionary(duration_context.get("motion_stats", {})).duplicate(true),
				"duration_angle_degrees": float(duration_context.get("angle_degrees", 180.0)),
				"duration_extension_m": float(duration_context.get("extension_m", 0.0)),
				"duration_fallback": float(duration_context.get("fallback_duration", 0.72)),
				"heat_coeff": limb_heat_coeff,
				"heat_color": Color(1.0, 0.38, 0.12, 1.0),
				"anchor_local": anchor,
				"disabled": pool <= 0.0,
				"color": Color(0.38, 0.9, 1.0, 1.0),
			})
	return allocation_groups


func _segment_by_node(stats: Dictionary) -> Dictionary:
	var result := {}
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		result[int(segment.get("node_index", -9999))] = segment
	return result


func _segment_anchor(segment: Dictionary) -> Vector2:
	var anchor := Vector2.ZERO
	var a_value = segment.get("a_local", segment.get("a", Vector2.ZERO))
	var b_value = segment.get("b_local", segment.get("b", a_value))
	if a_value is Vector2 and b_value is Vector2:
		anchor = (a_value + b_value) * 0.5
	return anchor


func _recalculate_heat(entries: Array, cooling_pool: float, engine_heat_load: float, zh: bool) -> Dictionary:
	var next_entries: Array = []
	var allocation_heat := 0.0
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			next_entries.append(raw_entry)
			continue
		var entry: Dictionary = Dictionary(raw_entry).duplicate(true)
		if bool(entry.get("heat_only", false)):
			var static_heat := maxf(0.0, float(entry.get("heat_load", 0.0)))
			entry["heat_ratio"] = static_heat / maxf(1.0, cooling_pool) if cooling_pool > 0.0 else (1.6 if static_heat > 0.0 else 0.0)
			entry["heat_label"] = _heat_label(static_heat, cooling_pool, zh)
			next_entries.append(entry)
			continue
		entry = _entry_with_heat(entry, maxf(0.0, float(entry.get("momentum", entry.get("allocated_momentum", 0.0)))), cooling_pool, zh)
		allocation_heat += maxf(0.0, float(entry.get("heat_load", 0.0)))
		next_entries.append(entry)
	var heat_used := maxf(0.0, engine_heat_load) + allocation_heat
	var over_heat := heat_used > cooling_pool + 0.001 if cooling_pool > 0.0 else heat_used > 0.0
	for i in range(next_entries.size()):
		if next_entries[i] is Dictionary:
			var entry: Dictionary = Dictionary(next_entries[i]).duplicate(true)
			entry["heat_over_budget"] = over_heat
			next_entries[i] = entry
	return {
		"entries": next_entries,
		"allocation_heat_used": allocation_heat,
		"heat_used": heat_used,
		"heat_ratio": heat_used / maxf(1.0, cooling_pool) if cooling_pool > 0.0 else (1.6 if heat_used > 0.0 else 0.0),
		"thermal_margin": cooling_pool - heat_used,
	}


func _entry_with_heat(entry: Dictionary, momentum: float, cooling_pool: float, zh: bool) -> Dictionary:
	var updated := entry.duplicate(true)
	if bool(updated.get("heat_exempt", false)):
		updated["heat_coeff"] = 0.0
		updated["heat_load"] = 0.0
		updated["heat_ratio"] = 0.0
		if String(updated.get("heat_label", "")) == "":
			updated["heat_label"] = "峰值提示 / 不占常热" if zh else "Peak hint / no idle heat"
		if not updated.has("heat_color"):
			updated["heat_color"] = _heat_color_for_kind(String(updated.get("kind", "")))
		return updated
	var heat_coeff := maxf(0.0, float(updated.get("heat_coeff", 0.0)))
	var heat_load := maxf(0.0, momentum) * heat_coeff
	updated["heat_coeff"] = heat_coeff
	updated["heat_load"] = heat_load
	updated["heat_ratio"] = heat_load / maxf(1.0, cooling_pool) if cooling_pool > 0.0 else (1.6 if heat_load > 0.0 else 0.0)
	updated["heat_label"] = _heat_label(heat_load, cooling_pool, zh)
	if not updated.has("heat_color"):
		updated["heat_color"] = _heat_color_for_kind(String(updated.get("kind", "")))
	return updated


func _engine_heat_entry(engine_part: Dictionary, engine_heat_load: float, cooling_pool: float, callbacks: Dictionary, zh: bool) -> Dictionary:
	var heat_load := maxf(0.0, engine_heat_load)
	var engine_label := _short_part_display_name(callbacks, engine_part, "ENGINE")
	return {
		"id": "engine_heat",
		"kind": "engine_heat",
		"label": ("%s / 常热负载" if zh else "%s / IDLE LOAD") % engine_label,
		"line": "不占动力分配" if zh else "Not a power allocation",
		"ratio": heat_load / maxf(1.0, cooling_pool) if cooling_pool > 0.0 else (1.0 if heat_load > 0.0 else 0.0),
		"momentum": 0.0,
		"allocated_momentum": 0.0,
		"heat_load": heat_load,
		"heat_ratio": heat_load / maxf(1.0, cooling_pool) if cooling_pool > 0.0 else (1.6 if heat_load > 0.0 else 0.0),
		"heat_label": _heat_label(heat_load, cooling_pool, zh),
		"heat_color": Color(1.0, 0.34, 0.16, 1.0),
		"color": Color(1.0, 0.44, 0.22, 1.0),
		"readonly": true,
		"disabled": false,
		"heat_only": true,
	}


func _heat_color_for_kind(kind: String) -> Color:
	match kind:
		"limb":
			return Color(1.0, 0.38, 0.12, 1.0)
		"booster_boost_brake":
			return Color(1.0, 0.62, 0.18, 1.0)
		"booster_drive":
			return Color(1.0, 0.48, 0.14, 1.0)
		_:
			return Color(1.0, 0.42, 0.14, 1.0)


func _heat_label(heat_load: float, cooling_pool: float, zh: bool) -> String:
	if cooling_pool <= 0.0:
		return ("常热 %.1f / 无热池" if zh else "Idle %.1f / no pool") % heat_load
	return ("常热 %.1f / 热池 %.0f%%" if zh else "Idle %.1f / pool %.0f%%") % [heat_load, heat_load / maxf(1.0, cooling_pool) * 100.0]


func _payload_torso_node_index(callbacks: Dictionary, payload: Dictionary, unit_bp: Dictionary) -> int:
	return _callback_int(callbacks, "payload_torso_node_index", [payload, unit_bp], -1)


func _payload_part_for_payload(callbacks: Dictionary, role_key: String, payload: Dictionary) -> Dictionary:
	return _callback_dict(callbacks, "payload_part_for_payload", [role_key, payload], {})


func _short_part_display_name(callbacks: Dictionary, part: Dictionary, fallback: String) -> String:
	return _callback_string(callbacks, "short_part_display_name", [part, fallback], fallback)


func _zh_part_name(callbacks: Dictionary, part_name: String) -> String:
	return _callback_string(callbacks, "zh_part_name", [part_name], part_name)


func _callback_value(callbacks: Dictionary, key: String, args: Array, fallback = null):
	var raw_callback = callbacks.get(key, Callable())
	if raw_callback is Callable:
		var callback: Callable = raw_callback
		if callback.is_valid():
			return callback.callv(args)
	return fallback


func _callback_dict(callbacks: Dictionary, key: String, args: Array, fallback: Dictionary = {}) -> Dictionary:
	var value = _callback_value(callbacks, key, args, fallback)
	if value is Dictionary:
		return Dictionary(value)
	return fallback


func _callback_array(callbacks: Dictionary, key: String, args: Array, fallback: Array = []) -> Array:
	var value = _callback_value(callbacks, key, args, fallback)
	if value is Array:
		return Array(value)
	return fallback


func _callback_string(callbacks: Dictionary, key: String, args: Array, fallback: String = "") -> String:
	return String(_callback_value(callbacks, key, args, fallback))


func _callback_float(callbacks: Dictionary, key: String, args: Array, fallback: float = 0.0) -> float:
	return float(_callback_value(callbacks, key, args, fallback))


func _callback_int(callbacks: Dictionary, key: String, args: Array, fallback: int = 0) -> int:
	return int(_callback_value(callbacks, key, args, fallback))
