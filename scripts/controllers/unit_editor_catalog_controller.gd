extends RefCounted
class_name UnitEditorCatalogController

var profiler
var clear_count := 0

const PART_GROUP_SLOTS := {
	"torso": ["muscle"],
	"limb": ["limb_muscle"],
	"terminal_weapon": ["muscle"],
	"barrier_panel": ["limb_muscle", "muscle"],
	"software_muscle": ["engine", "booster", "cooling", "muscle"],
	"software": ["special", "module"],
}

const PART_GROUP_FOR_SLOT := {
	"limb_muscle": "limb",
	"engine": "software_muscle",
	"booster": "software_muscle",
	"cooling": "software_muscle",
	"special": "software",
	"module": "software",
	"muscle": "terminal_weapon",
}

const DEFAULT_FILTER_BY_SLOT := {
	"muscle": "weapon_all",
	"limb_muscle": "connector_limb",
	"booster": "booster",
	"engine": "engine",
	"cooling": "cooling",
	"special": "soul",
	"module": "module",
}

const PREFERRED_FILTER_BY_GROUP := {
	"torso": "connector_torso",
	"limb": "connector_limb",
	"terminal_weapon": "weapon_all",
	"barrier_panel": "barrier_muscle",
	"software_muscle": "engine",
}

const SOFTWARE_PREFERRED_FILTER_BY_ROLE := {
	"hero": "soul",
	"puppet": "code",
	"barrier": "ether",
}

const PART_GROUP_NAMES_ZH := {
	"torso": "核心",
	"limb": "连接件",
	"terminal_weapon": "武器",
	"barrier_panel": "功能模块",
	"software_muscle": "软硬件",
	"software": "软件",
}

const PART_GROUP_NAMES_EN := {
	"torso": "CORE",
	"limb": "CONNECTOR",
	"terminal_weapon": "WEAPON",
	"barrier_panel": "FUNCTION",
	"software_muscle": "HYBRID",
	"software": "SOFTWARE",
}

const FILTER_OPTIONS_BY_GROUP := {
	"torso": [
		{"key": "connector_torso", "slot": "muscle", "zh": "运动核心", "en": "MOTION CORE"},
		{"key": "connector_brain", "slot": "muscle", "zh": "神经核心", "en": "NEURAL CORE"},
	],
	"limb": [
		{"key": "connector_limb", "slot": "limb_muscle", "zh": "连接件", "en": "CONNECTOR"},
	],
	"barrier_panel": [
		{"key": "barrier_muscle", "slots": ["limb_muscle", "muscle"], "zh": "功能模块", "en": "FUNCTION"},
	],
	"software_muscle": [
		{"key": "engine", "slot": "engine", "zh": "引擎", "en": "ENGINE"},
		{"key": "booster", "slot": "booster", "zh": "推进器", "en": "THRUSTER"},
		{"key": "cooling", "slot": "cooling", "zh": "散热器", "en": "COOLING"},
		{"key": "ammo", "slot": "muscle", "zh": "弹药", "en": "AMMO"},
		{"key": "shield_payload", "slot": "muscle", "zh": "电子护盾", "en": "E-SHIELD"},
	],
	"software": [
		{"key": "soul", "slot": "special", "zh": "英魂", "en": "SOUL"},
		{"key": "code", "slot": "special", "zh": "源代码", "en": "CODE"},
		{"key": "ether", "slot": "special", "zh": "以太", "en": "ETHER"},
		{"key": "module", "slot": "module", "zh": "全部模块", "en": "MOD ALL"},
		{"key": "module_melee", "slot": "module", "zh": "近战", "en": "MELEE"},
		{"key": "module_ranged", "slot": "module", "zh": "远程", "en": "RANGED"},
		{"key": "module_other", "slot": "module", "zh": "其他", "en": "OTHER"},
	],
}

const TERMINAL_WEAPON_BASE_FILTER_OPTIONS := [
	{"key": "weapon_all", "slot": "muscle", "weapon_group": "all", "weapon_subtype": "all", "zh": "全部", "en": "ALL"},
	{"key": "weapon_melee", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "all", "zh": "近战", "en": "MELEE"},
	{"key": "weapon_gun", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "all", "zh": "枪械", "en": "GUN"},
]

const TERMINAL_WEAPON_MELEE_FILTER_OPTIONS := [
	{"key": "weapon_blade", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "blade", "zh": "斩击", "en": "BLADE"},
	{"key": "weapon_blunt", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "blunt", "zh": "钝击", "en": "BLUNT"},
	{"key": "weapon_pierce", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "pierce", "zh": "戳刺", "en": "PIERCE"},
]

const TERMINAL_WEAPON_GUN_FILTER_OPTIONS := [
	{"key": "gun_sniper", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "sniper", "zh": "狙击", "en": "SNP"},
	{"key": "gun_rifle", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "rifle", "zh": "来复", "en": "RFL"},
	{"key": "gun_laser_gun", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "laser_gun", "zh": "激光", "en": "LSR"},
	{"key": "gun_sprayer", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "sprayer", "zh": "喷射", "en": "SPR"},
	{"key": "gun_grenade_launcher", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "grenade_launcher", "zh": "榴弹", "en": "GRN"},
	{"key": "gun_missile_launcher", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "missile_launcher", "zh": "导弹", "en": "MSL"},
	{"key": "gun_web", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "web", "zh": "蛛丝", "en": "WEB"},
]

const TERMINAL_WEAPON_RULE_AUDIT_FILTER_OPTIONS := [
	{"key": "terminal", "slot": "muscle", "weapon_group": "all", "weapon_subtype": "all", "zh": "全部终端", "en": "TERMINAL"},
	{"key": "terminal_melee", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "all", "zh": "近战终端", "en": "MELEE TERM"},
	{"key": "terminal_ranged", "slot": "muscle", "weapon_group": "gun", "weapon_subtype": "all", "zh": "远程终端", "en": "RANGED TERM"},
	{"key": "weapon_scythe", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "scythe", "zh": "镰刀", "en": "SCYTHE"},
	{"key": "weapon_katana", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "katana", "zh": "刀", "en": "KATANA"},
	{"key": "weapon_greatsword", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "greatsword", "zh": "大剑", "en": "G.SWORD"},
	{"key": "weapon_gauntlet", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "gauntlet", "zh": "拳套", "en": "GAUNTLET"},
	{"key": "weapon_shield", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "shield", "zh": "盾", "en": "SHIELD"},
	{"key": "weapon_hammer", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "hammer", "zh": "锤", "en": "HAMMER"},
	{"key": "weapon_lance", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "lance", "zh": "枪矛", "en": "LANCE"},
	{"key": "weapon_rapier", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "rapier", "zh": "刺剑", "en": "RAPIER"},
	{"key": "weapon_drill", "slot": "muscle", "weapon_group": "melee", "weapon_subtype": "drill", "zh": "钻头", "en": "DRILL"},
]


func bind(hot_profiler = null) -> void:
	profiler = hot_profiler


func raw_cache_key(role_key: String, slot_key: String, part_group_mode: String, part_filter_mode: String, weapon_filter_group: String, weapon_filter_subtype: String, source_signature: String) -> String:
	return "%s|%s|%s|%s|%s|%s|%s" % [
		role_key,
		slot_key,
		part_group_mode,
		part_filter_mode,
		weapon_filter_group,
		weapon_filter_subtype,
		source_signature,
	]


func entries_cache_key(role_key: String, slot_key: String, part_group_mode: String, part_filter_mode: String, weapon_filter_group: String, weapon_filter_subtype: String, sort_key: String, sort_ascending: bool, source_signature: String) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		role_key,
		slot_key,
		part_group_mode,
		part_filter_mode,
		weapon_filter_group,
		weapon_filter_subtype,
		sort_key,
		str(sort_ascending),
		source_signature,
	]


func page_selection_key(page_entries: Array, selected_indices_by_slot: Dictionary, pending_place_slot: String, pending_place_index: int, has_pending_canvas_part: bool, pending_payload_slot: String = "", pending_payload_index: int = -1, has_pending_payload_part: bool = false) -> String:
	var slots := {}
	for raw_entry in page_entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			slots[String(entry.get("slot", ""))] = true
	var pieces: Array = []
	for raw_slot in slots.keys():
		var entry_slot := String(raw_slot)
		pieces.append("%s:%d" % [entry_slot, int(selected_indices_by_slot.get(entry_slot, -1))])
	pieces.sort()
	pieces.append("pending:%s:%d:%d" % [
		pending_place_slot,
		pending_place_index,
		1 if has_pending_canvas_part else 0,
	])
	pieces.append("pending_payload:%s:%d:%d" % [
		pending_payload_slot,
		pending_payload_index,
		1 if has_pending_payload_part else 0,
	])
	return ",".join(pieces)


func selected_indices_for_entries(page_entries: Array, role_key: String, unit_bp: Dictionary, fallback_slot_key: String, selected_part_index: Callable) -> Dictionary:
	var selected_by_slot := {}
	for raw_entry in page_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var entry_slot := String(entry.get("slot", fallback_slot_key))
		if selected_by_slot.has(entry_slot):
			continue
		var selected_index := -1
		if selected_part_index.is_valid():
			selected_index = int(selected_part_index.call(unit_bp, role_key, entry_slot))
		selected_by_slot[entry_slot] = selected_index
	return selected_by_slot


func page_cache_key(entries_key: String, page: int, page_size: int, language: String, selection_key: String) -> String:
	return "%s|page:%d|size:%d|lang:%s|sel:%s" % [
		entries_key,
		page,
		page_size,
		language,
		selection_key,
	]


func page_state(current_page: int, entry_count: int, page_size: int) -> Dictionary:
	var normalized_page_size := maxi(1, page_size)
	var normalized_count := maxi(0, entry_count)
	var max_page := maxi(0, int(ceilf(float(normalized_count) / float(normalized_page_size))) - 1)
	var page := clampi(current_page, 0, max_page)
	var start_index := page * normalized_page_size if normalized_count > 0 else 0
	var end_index := mini(normalized_count, start_index + normalized_page_size)
	return {
		"valid": true,
		"page": page,
		"max_page": max_page,
		"page_size": normalized_page_size,
		"entry_count": normalized_count,
		"start_index": start_index,
		"end_index": end_index,
	}


func entry_state_for_card(component_index: int, current_page: int, page_size: int, entries: Array, fallback_slot_key: String) -> Dictionary:
	var state := page_state(current_page, entries.size(), page_size)
	var normalized_page := int(state.get("page", 0))
	var normalized_page_size := int(state.get("page_size", 1))
	var absolute_index := int(state.get("start_index", 0)) + component_index
	if component_index < 0 or component_index >= normalized_page_size:
		return {
			"valid": false,
			"clear_hover": true,
			"reason": "card_out_of_page",
			"page": normalized_page,
			"page_size": normalized_page_size,
			"absolute_index": absolute_index,
		}
	if absolute_index < int(state.get("start_index", 0)) or absolute_index >= int(state.get("end_index", 0)) or absolute_index >= entries.size():
		return {
			"valid": false,
			"clear_hover": true,
			"reason": "empty_card",
			"page": normalized_page,
			"page_size": normalized_page_size,
			"absolute_index": absolute_index,
		}
	var raw_entry = entries[absolute_index]
	if not (raw_entry is Dictionary):
		return {
			"valid": false,
			"clear_hover": true,
			"reason": "invalid_entry",
			"page": normalized_page,
			"page_size": normalized_page_size,
			"absolute_index": absolute_index,
		}
	var entry: Dictionary = raw_entry
	var entry_slot := String(entry.get("slot", fallback_slot_key))
	var part_index := int(entry.get("index", 0))
	var part: Dictionary = entry.get("display_part", {})
	if part.is_empty():
		part = entry.get("part", {})
	var stable_key := String(part.get("stable_key", part.get("name", "")))
	return {
		"valid": true,
		"clear_hover": false,
		"page": normalized_page,
		"page_size": normalized_page_size,
		"absolute_index": absolute_index,
		"slot": entry_slot,
		"part_index": part_index,
		"entry": entry,
		"part": part,
		"hover_key": "%d|%s:%d:%s" % [absolute_index, entry_slot, part_index, stable_key],
	}


func state_for_slot_selection(slot_index: int, build_slots: Array) -> Dictionary:
	var clamped_index := clampi(slot_index, 0, maxi(0, build_slots.size() - 1))
	var slot_key := String(build_slots[clamped_index]) if not build_slots.is_empty() else ""
	return {
		"valid": not build_slots.is_empty(),
		"slot_index": clamped_index,
		"part_group_mode": part_group_for_slot(slot_key),
		"part_filter_mode": default_filter_for_slot(slot_key),
		"weapon_filter_group": "all",
		"weapon_filter_subtype": "all",
	}


func state_for_part_group_selection(group_key: String, role_key: String, current_slot_key: String, build_slots: Array, weapon_filter_group: String = "all") -> Dictionary:
	if not has_part_group(group_key):
		return {"valid": false}
	var result := {
		"valid": true,
		"part_group_mode": group_key,
		"weapon_filter_group": "all",
		"weapon_filter_subtype": "all",
		"slot_index": build_slots.find(current_slot_key),
	}
	var filter_options := filter_options_for_group(group_key, weapon_filter_group)
	if not filter_options.is_empty():
		var preferred_filter := preferred_filter_for_part_group(group_key, role_key)
		var first_option: Dictionary = Dictionary(filter_options[0])
		for option in filter_options:
			if option is Dictionary and String(Dictionary(option).get("key", "")) == preferred_filter:
				first_option = Dictionary(option)
				break
		result["part_filter_mode"] = String(first_option.get("key", "all"))
		result["slot_index"] = _slot_index_for_option(first_option, current_slot_key, build_slots)
	return result


func state_for_filter_selection(filter_index: int, group_key: String, current_slot_key: String, build_slots: Array, weapon_filter_group: String = "all") -> Dictionary:
	var filter_options := filter_options_for_group(group_key, weapon_filter_group)
	if filter_index < 0 or filter_index >= filter_options.size():
		return {"valid": false}
	var option: Dictionary = Dictionary(filter_options[filter_index])
	var result := {
		"valid": true,
		"part_filter_mode": String(option.get("key", "all")),
		"slot_index": _slot_index_for_option(option, current_slot_key, build_slots),
	}
	if group_key == "terminal_weapon":
		result["weapon_filter_group"] = String(option.get("weapon_group", weapon_filter_group))
		result["weapon_filter_subtype"] = String(option.get("weapon_subtype", "all"))
	else:
		result["weapon_filter_group"] = "all"
		result["weapon_filter_subtype"] = "all"
	return result


func _slot_index_for_option(option: Dictionary, current_slot_key: String, build_slots: Array) -> int:
	var primary_slot := primary_slot_from_filter_option(option, current_slot_key)
	var slot_index := build_slots.find(primary_slot)
	if slot_index < 0:
		return 0
	return slot_index


func source_signature_for_slots(slot_keys: Array, role_key: String, catalog_for: Callable) -> String:
	var pieces: Array = []
	for raw_slot in slot_keys:
		var entry_slot := String(raw_slot)
		var catalog_size := 0
		if catalog_for.is_valid():
			var catalog = catalog_for.call(role_key, entry_slot)
			if catalog is Array:
				catalog_size = Array(catalog).size()
		pieces.append("%s:%d" % [entry_slot, catalog_size])
	return ",".join(pieces)


func collect_raw_entries(role_key: String, slot_keys: Array, catalog_for: Callable, selected_component: Callable, passes_filter: Callable, display_part: Callable) -> Array:
	var entries: Array = []
	for raw_slot in slot_keys:
		var entry_slot := String(raw_slot)
		var catalog: Array = []
		if catalog_for.is_valid():
			var raw_catalog = catalog_for.call(role_key, entry_slot)
			if raw_catalog is Array:
				catalog = raw_catalog
		for i in range(catalog.size()):
			var part: Dictionary = {}
			if selected_component.is_valid():
				var raw_part = selected_component.call(role_key, entry_slot, i)
				if raw_part is Dictionary:
					part = raw_part
			if passes_filter.is_valid() and not bool(passes_filter.call(entry_slot, part)):
				continue
			var rendered_part := part
			if display_part.is_valid():
				var raw_display = display_part.call(entry_slot, part)
				if raw_display is Dictionary:
					rendered_part = raw_display
			entries.append({
				"slot": entry_slot,
				"index": i,
				"part": part,
				"display_part": rendered_part,
			})
	return entries


func build_page_models(page_entries: Array, role_key: String, unit_bp: Dictionary, fallback_slot_key: String, language: String, has_pending_canvas_part: bool, selected_part_index: Callable, catalog_display_part: Callable, selected_component: Callable, card_model_for_part: Callable, pending_payload_slot: String = "", pending_payload_index: int = -1, has_pending_payload_part: bool = false) -> Array:
	var selected_by_slot := selected_indices_for_entries(page_entries, role_key, unit_bp, fallback_slot_key, selected_part_index)
	var zh := language == "zh"
	var models: Array = []
	for raw_entry in page_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var entry_slot := String(entry.get("slot", fallback_slot_key))
		var part_index := int(entry.get("index", 0))
		var part: Dictionary = entry.get("display_part", {})
		if part.is_empty():
			var source_part: Dictionary = {}
			if selected_component.is_valid():
				var raw_source_part = selected_component.call(role_key, entry_slot, part_index)
				if raw_source_part is Dictionary:
					source_part = raw_source_part
			else:
				source_part = entry.get("part", {})
			if catalog_display_part.is_valid():
				var raw_display = catalog_display_part.call(entry_slot, entry.get("part", source_part))
				if raw_display is Dictionary:
					part = raw_display
			if part.is_empty():
				part = source_part
		var pending_payload_card := has_pending_payload_part and entry_slot == pending_payload_slot and part_index == pending_payload_index
		var selected_card := part_index == int(selected_by_slot.get(entry_slot, -1)) or pending_payload_card
		var card_model: Dictionary = {}
		if card_model_for_part.is_valid():
			var raw_card_model = card_model_for_part.call(entry_slot, part, part_index)
			if raw_card_model is Dictionary:
				card_model = raw_card_model
		var marker := "已装 " if zh and selected_card else ("IN " if selected_card else "")
		if entry_slot in ["joint", "limb_muscle", "muscle"]:
			marker = "待选 " if zh and selected_card and has_pending_canvas_part else marker
		if pending_payload_card:
			marker = "待安装 " if zh else "PENDING "
		var title := "%s%s" % [marker, String(card_model.get("title_base", ""))]
		var line_a := String(card_model.get("line_a", ""))
		var line_b := String(card_model.get("line_b", ""))
		var card_signature := "%s|%d|%s|%s|%s|%s|%s|%s" % [
			entry_slot,
			part_index,
			String(part.get("stable_key", part.get("name", ""))),
			str(selected_card),
			language,
			title,
			line_a,
			line_b,
		]
		models.append({
			"slot": entry_slot,
			"part_index": part_index,
			"part": part,
			"selected": selected_card,
			"title": title,
			"line_a": line_a,
			"line_b": line_b,
			"signature": card_signature,
		})
	return models


func has_part_group(group_key: String) -> bool:
	return PART_GROUP_SLOTS.has(group_key)


func part_group_for_slot(slot_key: String) -> String:
	return String(PART_GROUP_FOR_SLOT.get(slot_key, "terminal_weapon"))


func default_filter_for_slot(slot_key: String) -> String:
	return String(DEFAULT_FILTER_BY_SLOT.get(slot_key, "all"))


func preferred_filter_for_part_group(group_key: String, role_key: String = "") -> String:
	if group_key == "software":
		return String(SOFTWARE_PREFERRED_FILTER_BY_ROLE.get(role_key, "module"))
	return String(PREFERRED_FILTER_BY_GROUP.get(group_key, "terminal"))


func visible_part_group_slots(group_key: String) -> Array:
	return Array(PART_GROUP_SLOTS.get(group_key, PART_GROUP_SLOTS["terminal_weapon"])).duplicate()


func part_group_name(group_key: String, zh: bool) -> String:
	var names := PART_GROUP_NAMES_ZH if zh else PART_GROUP_NAMES_EN
	return String(names.get(group_key, group_key.to_upper()))


func filter_option_name(option: Dictionary, zh: bool) -> String:
	if zh:
		return String(option.get("zh", option.get("key", "")))
	return String(option.get("en", option.get("key", ""))).to_upper()


func filter_options_for_group(group_key: String, weapon_filter_group: String = "all", include_rule_audit_filters: bool = false) -> Array:
	if group_key == "terminal_weapon":
		var options := TERMINAL_WEAPON_BASE_FILTER_OPTIONS.duplicate(true)
		if include_rule_audit_filters:
			options.append_array(TERMINAL_WEAPON_RULE_AUDIT_FILTER_OPTIONS.duplicate(true))
			options.append_array(TERMINAL_WEAPON_MELEE_FILTER_OPTIONS.duplicate(true))
			options.append_array(TERMINAL_WEAPON_GUN_FILTER_OPTIONS.duplicate(true))
			return _unique_filter_options(options)
		if weapon_filter_group == "melee":
			options.append_array(TERMINAL_WEAPON_MELEE_FILTER_OPTIONS.duplicate(true))
		elif weapon_filter_group == "gun":
			options.append_array(TERMINAL_WEAPON_GUN_FILTER_OPTIONS.duplicate(true))
		return options
	if FILTER_OPTIONS_BY_GROUP.has(group_key):
		return Array(FILTER_OPTIONS_BY_GROUP[group_key]).duplicate(true)
	return []


func _unique_filter_options(options: Array) -> Array:
	var seen := {}
	var result: Array = []
	for raw_option in options:
		if not (raw_option is Dictionary):
			continue
		var option: Dictionary = Dictionary(raw_option).duplicate(true)
		var key := String(option.get("key", ""))
		if key == "" or seen.has(key):
			continue
		seen[key] = true
		result.append(option)
	return result


func slot_keys_from_filter_option(option: Dictionary) -> Array:
	var slot_keys: Array = []
	if option.has("slots") and option["slots"] is Array:
		for raw_slot in Array(option["slots"]):
			var slot_key := String(raw_slot)
			if slot_key != "" and not slot_keys.has(slot_key):
				slot_keys.append(slot_key)
	else:
		var single_slot := String(option.get("slot", ""))
		if single_slot != "":
			slot_keys.append(single_slot)
	return slot_keys


func primary_slot_from_filter_option(option: Dictionary, fallback_slot: String) -> String:
	var slot_keys := slot_keys_from_filter_option(option)
	if slot_keys.is_empty():
		return fallback_slot
	return String(slot_keys[0])


func catalog_slots_for_filter(fallback_slot_key: String, group_key: String, filter_key: String, weapon_filter_group: String = "all") -> Array:
	for option in filter_options_for_group(group_key, weapon_filter_group):
		if option is Dictionary and String(Dictionary(option).get("key", "")) == filter_key:
			var option_slots := slot_keys_from_filter_option(Dictionary(option))
			if not option_slots.is_empty():
				return option_slots
	return [fallback_slot_key]


func available_sort_keys_from_entries(entries: Array, sort_key_order: Array, has_sort_property: Callable) -> Array:
	var available: Array = []
	for raw_key in sort_key_order:
		var key := String(raw_key)
		var has_key := false
		for raw_entry in entries:
			if not (raw_entry is Dictionary):
				continue
			var entry: Dictionary = raw_entry
			var part: Dictionary = entry.get("display_part", entry.get("part", {}))
			var slot_key := String(entry.get("slot", ""))
			if has_sort_property.is_valid() and bool(has_sort_property.call(slot_key, part, key)):
				has_key = true
				break
		if has_key:
			available.append(key)
	if available.is_empty():
		available.append("cost")
	return available


func sort_entries(entries: Array, fallback_slot_key: String, sort_value: Callable, ascending: bool) -> void:
	for i in range(entries.size()):
		var best := i
		for j in range(i + 1, entries.size()):
			var entry_best: Dictionary = entries[best]
			var entry_next: Dictionary = entries[j]
			var best_slot := String(entry_best.get("slot", fallback_slot_key))
			var next_slot := String(entry_next.get("slot", fallback_slot_key))
			var value_best := 0.0
			var value_next := 0.0
			if sort_value.is_valid():
				value_best = float(sort_value.call(best_slot, entry_best.get("display_part", entry_best.get("part", {}))))
				value_next = float(sort_value.call(next_slot, entry_next.get("display_part", entry_next.get("part", {}))))
			var should_swap := value_next < value_best if ascending else value_next > value_best
			if is_equal_approx(value_next, value_best):
				should_swap = int(entry_next.get("index", 0)) < int(entry_best.get("index", 0))
			if should_swap:
				best = j
		if best != i:
			var temp = entries[i]
			entries[i] = entries[best]
			entries[best] = temp


func clear_catalog_caches(raw_cache: Dictionary, entries_cache: Dictionary, sort_keys_cache: Dictionary, card_model_cache: Dictionary, page_model_cache: Dictionary, load_entry_stats_cache: Dictionary) -> void:
	clear_count += 1
	raw_cache.clear()
	entries_cache.clear()
	sort_keys_cache.clear()
	card_model_cache.clear()
	page_model_cache.clear()
	load_entry_stats_cache.clear()
	if profiler != null:
		profiler.count("unit_editor.catalog.clear")
