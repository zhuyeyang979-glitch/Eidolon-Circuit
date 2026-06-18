extends RefCounted
class_name UnitEditorAssemblyTemplateService

const TOPOLOGY_PART_SLOTS := ["limb_muscle", "muscle"]


func model(role_key: String, unit_bp: Dictionary, visual_stats: Dictionary = {}, callbacks: Dictionary = {}, zh: bool = true) -> Dictionary:
	if role_key != "hero" or not unit_bp.has("custom_topology"):
		return {}
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	var used_topology_parts := {}
	var used_payload_parts := {}
	var torso_count := 0
	var limb_count := 0
	var weapon_count := 0
	for raw_node in nodes:
		if not (raw_node is Dictionary):
			continue
		var node: Dictionary = raw_node
		if _callback_bool(callbacks, "topology_node_is_component", [node], false):
			var slot_key := _callback_string(callbacks, "topology_node_slot", [node], "")
			var part_index := _callback_int(callbacks, "topology_node_resolved_part_index", [role_key, node, unit_bp], -1)
			used_topology_parts[_part_key(callbacks, role_key, slot_key, part_index)] = true
			var part := _callback_dict(callbacks, "topology_node_part", [role_key, node, unit_bp], {})
			if slot_key == "muscle" and _component_is_torso(callbacks, part):
				torso_count += 1
			elif slot_key == "limb_muscle":
				limb_count += 1
			elif slot_key == "muscle":
				weapon_count += 1
			continue
		for slot_key in TOPOLOGY_PART_SLOTS:
			var part_index := int(node.get(slot_key, unit_bp.get(slot_key, -1)))
			if part_index < 0:
				continue
			used_topology_parts[_part_key(callbacks, role_key, slot_key, part_index)] = true
			var part := _selected_part(callbacks, role_key, slot_key, part_index)
			if slot_key == "muscle" and _component_is_torso(callbacks, part):
				torso_count += 1
			elif slot_key == "limb_muscle":
				limb_count += 1
			elif slot_key == "muscle":
				weapon_count += 1
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	var plugin_count := 0
	var special_count := 0
	var module_payload_count := 0
	var module_payload_rows := {}
	for payload_i in range(payloads.size()):
		if not (payloads[payload_i] is Dictionary):
			continue
		var payload: Dictionary = payloads[payload_i]
		var payload_kind := String(payload.get("kind", ""))
		var payload_slot := _payload_slot_key_for_kind(callbacks, payload_kind)
		var payload_part := _callback_dict(callbacks, "payload_part_for_payload", [role_key, payload], {})
		var payload_index := int(payload.get(payload_slot, payload.get(payload_kind, -1)))
		var payload_key := "%s:%d:%s" % [payload_slot, payload_index, String(payload_part.get("stable_key", payload_part.get("name", "")))]
		used_payload_parts[payload_key] = true
		match payload_kind:
			"special":
				special_count += 1
			"module":
				module_payload_count += 1
				module_payload_rows[payload_i] = {
					"index": payload_index,
					"name": _short_part_name(callbacks, String(payload_part.get("name", "MODULE"))),
					"valid_binding": false,
					"has_binding": false,
				}
			_:
				plugin_count += 1
	var valid_module_bindings := 0
	for raw_binding in _callback_array(callbacks, "runtime_module_bindings_for_blueprint", [role_key, unit_bp], []):
		if not (raw_binding is Dictionary):
			continue
		var binding: Dictionary = raw_binding
		var payload_index := int(binding.get("software_slot_index", -1))
		if not module_payload_rows.has(payload_index):
			continue
		var row: Dictionary = module_payload_rows[payload_index]
		row["has_binding"] = true
		row["valid_binding"] = bool(binding.get("runtime_valid", true))
		module_payload_rows[payload_index] = row
		if bool(binding.get("runtime_valid", true)):
			valid_module_bindings += 1
	var warnings: Array = []
	if torso_count <= 0:
		_append_warning(warnings, _label(zh, "核心未放置", "Core missing"), _part_label(callbacks, role_key, "muscle", int(unit_bp.get("muscle", 0))), "missing")
	for slot_key in TOPOLOGY_PART_SLOTS:
		if not unit_bp.has(slot_key):
			continue
		var selected_index := int(unit_bp.get(slot_key, -1))
		var selected_key := _part_key(callbacks, role_key, slot_key, selected_index)
		if selected_key == "" or used_topology_parts.has(selected_key):
			continue
		var selected_part := _selected_part(callbacks, role_key, slot_key, selected_index)
		if slot_key == "muscle" and _component_is_torso(callbacks, selected_part):
			_append_warning(warnings, _label(zh, "躯干未上画布", "Torso off-board"), _short_part_name(callbacks, String(selected_part.get("name", "TORSO"))))
		elif slot_key == "muscle":
			_append_warning(warnings, _label(zh, "武器未连接", "Weapon unlinked"), _short_part_name(callbacks, String(selected_part.get("name", "WEAPON"))))
		else:
			_append_warning(warnings, _label(zh, "连接肢未放置", "Limb unused"), _short_part_name(callbacks, String(selected_part.get("name", "LIMB"))))
	for slot_key in ["engine", "booster", "cooling", "special", "module"]:
		if not unit_bp.has(slot_key):
			continue
		var selected_index := int(unit_bp.get(slot_key, -1))
		var selected_key := _part_key(callbacks, role_key, slot_key, selected_index)
		if selected_key == "" or used_payload_parts.has(selected_key):
			continue
		var label := _part_label(callbacks, role_key, slot_key, selected_index)
		match slot_key:
			"engine":
				_append_warning(warnings, _label(zh, "引擎未入槽", "Engine not installed"), label)
			"booster":
				_append_warning(warnings, _label(zh, "推进器未入槽", "Booster not installed"), label)
			"cooling":
				_append_warning(warnings, _label(zh, "散热未入槽", "Cooling not installed"), label)
			"special":
				_append_warning(warnings, _label(zh, "核心软件未入槽", "Special not installed"), label)
			"module":
				_append_warning(warnings, _label(zh, "行动模块未入槽", "Module not installed"), label)
	for raw_payload_index in module_payload_rows.keys():
		var row: Dictionary = module_payload_rows[raw_payload_index]
		if bool(row.get("valid_binding", false)):
			continue
		var module_name := String(row.get("name", "MODULE"))
		var warning_label := _label(zh, "模块未绑定", "Module unbound")
		if bool(row.get("has_binding", false)):
			warning_label = _label(zh, "模块绑定无效", "Module binding invalid")
		_append_warning(warnings, warning_label, module_name)
	if bool(visual_stats.get("illegal", false)):
		_append_warning(warnings, _label(zh, "搭配规则冲突", "Build rule conflict"), _label(zh, "属性", "Stats"))
	var slots: Array = []
	_append_slot(slots, "core", _label(zh, "核心", "Core"), str(torso_count), "missing" if torso_count <= 0 else ("warn" if torso_count > 1 else "ok"), _label(zh, "躯干", "Torso"))
	_append_slot(slots, "limb", _label(zh, "连接肢", "Limb"), str(limb_count), "warn" if limb_count <= 0 else "ok", _label(zh, "外部结构", "Frame"))
	_append_slot(slots, "weapon", _label(zh, "末端武器", "Weapon"), str(weapon_count), "warn" if weapon_count <= 0 else "ok", _label(zh, "输出端", "Output"))
	_append_slot(slots, "plugin", _label(zh, "机内插件", "Plugin"), str(plugin_count), "empty" if plugin_count <= 0 else "ok", _label(zh, "引擎/推进/散热", "Engine/boost/cool"))
	_append_slot(slots, "software", _label(zh, "软件槽", "Software"), str(special_count + module_payload_count), "empty" if special_count + module_payload_count <= 0 else "ok", _label(zh, "核心/动作", "Core/action"))
	var binding_state := "ok"
	if module_payload_count > 0 and valid_module_bindings < module_payload_count:
		binding_state = "warn"
	elif module_payload_count <= 0:
		binding_state = "empty"
	_append_slot(slots, "binding", _label(zh, "动作绑定", "Binding"), "%d/%d" % [valid_module_bindings, module_payload_count], binding_state, _label(zh, "模块目标", "Targets"))
	var status := "ok"
	if torso_count <= 0:
		status = "missing"
	elif not warnings.is_empty():
		status = "warn"
	var shown_warnings: Array = []
	for i in range(mini(warnings.size(), 5)):
		shown_warnings.append(warnings[i])
	var summary := (_label(zh, "核心%d 肢体%d 武器%d 插件%d 绑定%d/%d", "Core %d Limb %d Weapon %d Plug %d Bind %d/%d")) % [
		torso_count,
		limb_count,
		weapon_count,
		plugin_count,
		valid_module_bindings,
		module_payload_count,
	]
	var signature_bits: Array = [status, summary, str(warnings.size())]
	for slot in slots:
		var slot_info: Dictionary = slot
		signature_bits.append("%s:%s:%s" % [String(slot_info.get("key", "")), String(slot_info.get("value", "")), String(slot_info.get("state", ""))])
	for warning in shown_warnings:
		var warning_info: Dictionary = warning
		signature_bits.append("%s:%s:%s" % [String(warning_info.get("label", "")), String(warning_info.get("detail", "")), String(warning_info.get("state", ""))])
	return {
		"title": _label(zh, "组装模板", "Assembly Template"),
		"status": status,
		"summary": summary,
		"slots": slots,
		"warnings": shown_warnings,
		"warning_count": warnings.size(),
		"hidden_warning_count": maxi(0, warnings.size() - shown_warnings.size()),
		"signature": "|".join(signature_bits),
	}


func _selected_part(callbacks: Dictionary, role_key: String, slot_key: String, part_index: int) -> Dictionary:
	return _callback_dict(callbacks, "selected_component", [role_key, slot_key, part_index], {})


func _part_key(callbacks: Dictionary, role_key: String, slot_key: String, part_index: int) -> String:
	if part_index < 0:
		return ""
	var part := _selected_part(callbacks, role_key, slot_key, part_index)
	return "%s:%d:%s" % [slot_key, part_index, String(part.get("stable_key", part.get("name", "")))]


func _part_label(callbacks: Dictionary, role_key: String, slot_key: String, part_index: int) -> String:
	if part_index < 0:
		return "-"
	var part := _selected_part(callbacks, role_key, slot_key, part_index)
	return _short_part_name(callbacks, String(part.get("name", slot_key)))


func _short_part_name(callbacks: Dictionary, part_name: String) -> String:
	return _callback_string(callbacks, "short_part_name", [part_name], part_name)


func _component_is_torso(callbacks: Dictionary, part: Dictionary) -> bool:
	return _callback_bool(callbacks, "component_is_torso", [part], false)


func _payload_slot_key_for_kind(callbacks: Dictionary, payload_kind: String) -> String:
	return _callback_string(callbacks, "payload_slot_key_for_kind", [payload_kind], payload_kind)


func _append_slot(slots: Array, key: String, label: String, value: String, state: String, detail: String = "") -> void:
	slots.append({
		"key": key,
		"label": label,
		"value": value,
		"state": state,
		"detail": detail,
	})


func _append_warning(warnings: Array, label: String, detail: String, state: String = "warn") -> void:
	warnings.append({
		"label": label,
		"detail": detail,
		"state": state,
	})


func _label(zh: bool, zh_text: String, en_text: String) -> String:
	return zh_text if zh else en_text


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


func _callback_int(callbacks: Dictionary, key: String, args: Array, fallback: int = 0) -> int:
	return int(_callback_value(callbacks, key, args, fallback))


func _callback_bool(callbacks: Dictionary, key: String, args: Array, fallback: bool = false) -> bool:
	return bool(_callback_value(callbacks, key, args, fallback))
