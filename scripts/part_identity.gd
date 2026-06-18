class_name PartIdentity
extends RefCounted

const PartArt = preload("res://scripts/part_art.gd")

const FULL_SCAN := 2
const PARTIAL_SCAN := 1
const UNKNOWN_SCAN := 0

static func scan_level_for(part: Dictionary, fallback: int = FULL_SCAN) -> int:
	if part.has("scan_level"):
		return clampi(int(part.get("scan_level", fallback)), UNKNOWN_SCAN, FULL_SCAN)
	if part.has("intel_level"):
		return clampi(int(part.get("intel_level", fallback)), UNKNOWN_SCAN, FULL_SCAN)
	if part.has("blueprint_scan_level"):
		return clampi(int(part.get("blueprint_scan_level", fallback)), UNKNOWN_SCAN, FULL_SCAN)
	if part.has("identified") and not bool(part.get("identified", true)):
		return UNKNOWN_SCAN
	return clampi(fallback, UNKNOWN_SCAN, FULL_SCAN)

static func identity_for(slot_key: String, part: Dictionary, language: String = "zh", scan_level: int = -1) -> Dictionary:
	var level := scan_level_for(part) if scan_level < 0 else clampi(scan_level, UNKNOWN_SCAN, FULL_SCAN)
	var zh := _is_zh(language)
	var base := _family_data(slot_key, part, zh)
	var size_code := _size_code(part)
	var color := _identity_color(slot_key, part)
	var code := "%s-%s-%s" % [String(base.get("prefix", "PRT")), String(base.get("subcode", "GEN")), size_code]
	var family := String(base.get("family", "部件" if zh else "Part"))
	var role := String(base.get("role", "组件" if zh else "Component"))
	var tags: Array = Array(base.get("tags", [])).duplicate()
	if not tags.has(size_code):
		tags.append(size_code)
	if level <= UNKNOWN_SCAN:
		code = "???-%s" % size_code
		family = "未知蓝图" if zh else "Unknown blueprint"
		role = String(base.get("coarse_role", "未识别" if zh else "Unidentified"))
		tags = [role, size_code]
	elif level == PARTIAL_SCAN:
		code = "%s-??-%s" % [String(base.get("prefix", "PRT")), size_code]
		family = "%s?" % String(base.get("coarse_family", family))
		tags = [String(base.get("coarse_role", role)), size_code]
	return {
		"code": code,
		"prefix": String(base.get("prefix", "PRT")),
		"subcode": String(base.get("subcode", "GEN")),
		"glyph": String(base.get("glyph", base.get("prefix", "PRT"))),
		"family": family,
		"coarse_family": String(base.get("coarse_family", family)),
		"role": role,
		"tags": tags,
		"size_code": size_code,
		"scan_level": level,
		"scan_label": _scan_label(level, zh),
		"color": color,
		"signature": "%s|%s|%s|%d|%s" % [slot_key, String(part.get("stable_key", part.get("name", ""))), code, level, String(base.get("tag_signature", ""))],
	}

static func signature_for(slot_key: String, part: Dictionary, language: String = "zh", scan_level: int = -1) -> String:
	return String(identity_for(slot_key, part, language, scan_level).get("signature", ""))

static func _family_data(slot_key: String, part: Dictionary, zh: bool) -> Dictionary:
	var normalized_slot := _normalized_slot(slot_key, part)
	match normalized_slot:
		"torso":
			return _torso_identity(part, zh)
		"joint":
			return _joint_identity(part, zh)
		"limb_muscle":
			return _limb_identity(part, zh)
		"booster":
			return _booster_identity(part, zh)
		"engine":
			return _engine_identity(part, zh)
		"cooling":
			return _cooling_identity(part, zh)
		"module":
			return _module_identity(part, zh)
		"special", "software", "soul", "code", "ether":
			return _source_identity(part, zh)
		"ammo":
			return _ammo_identity(part, zh)
		_:
			if _is_ranged_terminal(part):
				return _ranged_identity(part, zh)
			if _is_terminal_weapon(part):
				return _melee_identity(part, zh)
	return _generic_identity(normalized_slot, part, zh)

static func _normalized_slot(slot_key: String, part: Dictionary) -> String:
	var slot := slot_key.to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	if bool(part.get("is_torso", false)) or material_class == "torso" or slot == "torso":
		return "torso"
	if slot in ["software", "soul", "code", "ether"]:
		return "special"
	return slot

static func _torso_identity(part: Dictionary, zh: bool) -> Dictionary:
	var family_key := _first_key([String(part.get("archetype", "")), String(part.get("shape", "")), String(part.get("name", ""))])
	var subcode := _lookup_subcode(family_key, {
		"crab": "CRB",
		"octopus": "OCT",
		"bull": "BUL",
		"hound": "HND",
		"lizard": "LZD",
		"centipede": "CEN",
		"roach": "RCH",
		"bird": "BRD",
		"core": "COR",
	}, "COR")
	var ports := maxi(0, int(part.get("joint_ports", part.get("connection_ends", 0))))
	return _base("TRS", subcode, "TORSO", "躯干核心" if zh else "Torso core", "核心" if zh else "Core", ["核心" if zh else "Core", "接口%d" % ports if ports > 0 else ("接口" if zh else "Ports")], zh)

static func _joint_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := _part_key(part)
	var subcode := "BAL"
	var role := "球形" if zh else "Ball"
	if key.contains("linear") or key.contains("telescopic") or key.contains("rail") or float(part.get("max_extension_m", part.get("range", 0.0))) > 0.08:
		subcode = "TEL"
		role = "伸缩" if zh else "Telescopic"
	elif key.contains("corner") or bool(part.get("fixed_corner_joint", false)):
		subcode = "CRN"
		role = "折角" if zh else "Corner"
	elif bool(part.get("software_joint", false)) or bool(part.get("joint_is_software", false)):
		subcode = "SWJ"
		role = "软件关节" if zh else "Software joint"
	return _base("JNT", subcode, "JOINT", "关节件" if zh else "Joint", role, ["关节" if zh else "Joint", role], zh)

static func _limb_identity(part: Dictionary, zh: bool) -> Dictionary:
	var family := PartArt.limb_visual_family(part)
	var subcode := _lookup_subcode(family, {
		"forearm_myomer": "FAM",
		"thigh_myomer": "THI",
		"two_end_muscle": "TWO",
		"flex_tendon": "FLX",
		"chain_muscle": "CHN",
		"tentacle": "TEN",
		"ceramic_linear_strut": "LIN",
		"steel_sinew_beam": "STM",
		"barrier_strut": "BAR",
		"colossus_girder_muscle": "GDR",
		"fur_sleeve": "PAD",
	}, "LNK")
	var label := _lookup_label(family, {
		"forearm_myomer": ["前臂肌束", "Forearm myomer"],
		"thigh_myomer": ["大腿肌束", "Thigh myomer"],
		"two_end_muscle": ["双端连杆", "Two-end link"],
		"flex_tendon": ["柔性肌腱", "Flex tendon"],
		"chain_muscle": ["链式肌肉", "Chain muscle"],
		"tentacle": ["触腕肌束", "Tentacle link"],
		"ceramic_linear_strut": ["直线支杆", "Linear strut"],
		"steel_sinew_beam": ["钢索梁", "Sinew beam"],
		"barrier_strut": ["屏障支杆", "Barrier strut"],
		"colossus_girder_muscle": ["巨型梁肌", "Girder muscle"],
		"fur_sleeve": ["缓冲套", "Padded sleeve"],
	}, zh, "连接肢体" if zh else "Limb link")
	return _base("LMB", subcode, "LIMB", "连接肢体" if zh else "Limb link", label, ["连接" if zh else "Link", label], zh)

static func _ranged_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := _part_key(part)
	var gun_kind := String(part.get("gun_kind", "")).to_lower()
	var style := String(part.get("projectile_style", part.get("projectile_behavior", ""))).to_lower()
	if gun_kind == "":
		gun_kind = _first_matching_key(key, ["web", "missile", "grenade", "laser", "spray", "siphon", "mortar", "sniper", "rifle"])
	var subcode := "RNG"
	var label := "远程武器" if zh else "Ranged weapon"
	if gun_kind.contains("web"):
		subcode = "WEB"
		label = "牵引网枪" if zh else "Web gun"
	elif gun_kind.contains("missile") or gun_kind.contains("grenade") or style.contains("explosive") or key.contains("mortar"):
		subcode = "ARC"
		label = "抛射爆弹" if zh else "Arc launcher"
	elif gun_kind.contains("laser") or style.contains("beam"):
		subcode = "LSR"
		label = "激光束" if zh else "Laser beam"
	elif gun_kind.contains("spray") or key.contains("siphon") or style.contains("spray"):
		subcode = "SPR"
		label = "喷射器" if zh else "Sprayer"
	elif gun_kind.contains("sniper") or style.contains("true_bullet") or key.contains("rail"):
		subcode = "SNP"
		label = "狙击线炮" if zh else "Sniper"
	elif gun_kind.contains("rifle") or style.contains("bullet_hell"):
		subcode = "RFL"
		label = "连射枪" if zh else "Rifle"
	var damage := _damage_label(String(part.get("projectile_damage_type", part.get("damage_type", ""))), zh)
	return _base("GUN", subcode, "RANGED", "远程端件" if zh else "Ranged terminal", label, ["远程" if zh else "Ranged", label, damage], zh)

static func _melee_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := _part_key(part)
	var damage_type := String(part.get("damage_type", "")).to_lower()
	var family := String(part.get("weapon_family", "")).to_lower()
	var subcode := "MEL"
	var label := "近战端件" if zh else "Melee terminal"
	if key.contains("shield") or family.contains("shield"):
		subcode = "SHD"
		label = "盾牌" if zh else "Shield"
	elif key.contains("hammer") or key.contains("hoof") or damage_type == "blunt":
		subcode = "HMR"
		label = "钝击锤" if zh else "Hammer"
	elif key.contains("drill") or key.contains("auger"):
		subcode = "DRL"
		label = "钻头" if zh else "Drill"
	elif key.contains("rapier") or key.contains("needle") or key.contains("pike") or key.contains("lance") or damage_type == "pierce":
		subcode = "LNC"
		label = "刺击枪刃" if zh else "Piercer"
	elif key.contains("jaw") or key.contains("clamp"):
		subcode = "CLP"
		label = "夹咬爪" if zh else "Clamp jaw"
	elif key.contains("scythe") or key.contains("saber") or key.contains("blade") or key.contains("claw") or damage_type == "tear":
		subcode = "BLD"
		label = "切割刃" if zh else "Blade"
	var damage := _damage_label(damage_type, zh)
	return _base("MEL", subcode, "MELEE", "近战端件" if zh else "Melee terminal", label, ["近战" if zh else "Melee", label, damage], zh)

static func _booster_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := "%s %s" % [String(part.get("thruster_family", "")), _part_key(part)]
	key = key.to_lower()
	var subcode := "VEC"
	var label := "矢量推进" if zh else "Vector thrust"
	if key.contains("brake") or key.contains("reverse"):
		subcode = "BRK"
		label = "制动推进" if zh else "Brake thrust"
	elif key.contains("dash") or key.contains("burst") or key.contains("overburn"):
		subcode = "DAS"
		label = "冲刺推进" if zh else "Dash thrust"
	elif key.contains("cruise") or key.contains("sustain"):
		subcode = "CRS"
		label = "巡航推进" if zh else "Cruise thrust"
	return _base("BST", subcode, "BOOST", "推进器" if zh else "Booster", label, ["推进" if zh else "Boost", label], zh)

static func _engine_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := "%s %s" % [String(part.get("engine_family", "")), _part_key(part)]
	key = key.to_lower()
	var subcode := "PWR"
	var label := "动力核心" if zh else "Power core"
	if key.contains("reactor") or key.contains("fusion"):
		subcode = "RCT"
		label = "反应堆" if zh else "Reactor"
	elif key.contains("capacitor") or key.contains("cell") or key.contains("battery"):
		subcode = "CAP"
		label = "电容阵列" if zh else "Capacitor"
	elif key.contains("turbine") or key.contains("flywheel"):
		subcode = "TRB"
		label = "涡轮机" if zh else "Turbine"
	return _base("ENG", subcode, "POWER", "引擎" if zh else "Engine", label, ["动力" if zh else "Power", label], zh)

static func _cooling_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := _part_key(part)
	var subcode := "FIN"
	var label := "散热鳍片" if zh else "Cooling fins"
	if key.contains("pump") or key.contains("liquid"):
		subcode = "PMP"
		label = "液冷泵" if zh else "Coolant pump"
	elif key.contains("sink") or key.contains("plate"):
		subcode = "SNK"
		label = "热沉板" if zh else "Heat sink"
	elif key.contains("vent") or key.contains("exhaust"):
		subcode = "VNT"
		label = "排热口" if zh else "Heat vent"
	return _base("COL", subcode, "COOL", "散热件" if zh else "Cooling", label, ["散热" if zh else "Cooling", label], zh)

static func _module_identity(part: Dictionary, zh: bool) -> Dictionary:
	var profile := String(part.get("module_action_profile", part.get("gun_activation", ""))).to_lower()
	var visual := String(part.get("module_visual_family", part.get("module_variant_key", ""))).to_lower()
	var key := "%s %s %s" % [profile, visual, _part_key(part)]
	var subcode := "RTN"
	var label := "动作路由" if zh else "Action router"
	if key.contains("dash") or key.contains("route"):
		subcode = "DAS"
		label = "位移路由" if zh else "Dash router"
	elif key.contains("clamp") or key.contains("pincer"):
		subcode = "CLP"
		label = "夹具路由" if zh else "Clamp router"
	elif key.contains("laser") or key.contains("beam"):
		subcode = "LSR"
		label = "光束路由" if zh else "Beam router"
	elif key.contains("grenade") or key.contains("salvo") or key.contains("arc"):
		subcode = "ARC"
		label = "抛射路由" if zh else "Arc router"
	elif key.contains("gun") or key.contains("rifle"):
		subcode = "GUN"
		label = "枪械路由" if zh else "Gun router"
	elif key.contains("guard") or key.contains("parry"):
		subcode = "GRD"
		label = "防御路由" if zh else "Guard router"
	elif key.contains("swing") or key.contains("slash"):
		subcode = "SWG"
		label = "挥击路由" if zh else "Swing router"
	return _base("ACT", subcode, "ACTION", "行动模块" if zh else "Action module", label, ["动作" if zh else "Action", label], zh)

static func _source_identity(part: Dictionary, zh: bool) -> Dictionary:
	var key := _part_key(part)
	var subcode := "SRC"
	var label := "源质芯片" if zh else "Source chip"
	if key.contains("soul"):
		subcode = "SOL"
		label = "魂质源" if zh else "Soul source"
	elif key.contains("code"):
		subcode = "COD"
		label = "代码源" if zh else "Code source"
	elif key.contains("ether"):
		subcode = "ETH"
		label = "以太源" if zh else "Ether source"
	return _base("SRC", subcode, "SOURCE", "源质软件" if zh else "Source software", label, ["软件" if zh else "Software", label], zh)

static func _ammo_identity(part: Dictionary, zh: bool) -> Dictionary:
	var damage := String(part.get("ammo_kind", part.get("damage_type", part.get("projectile_damage_type", "")))).to_lower()
	var subcode := _lookup_subcode(damage, {"bullet": "BUL", "chemical": "CHM", "laser": "LSR", "explosive": "EXP", "web": "WEB"}, "AMO")
	var label := _damage_label(damage, zh)
	return _base("AMO", subcode, "AMMO", "弹药仓" if zh else "Ammo pod", label, ["弹药" if zh else "Ammo", label], zh)

static func _generic_identity(slot_key: String, part: Dictionary, zh: bool) -> Dictionary:
	var prefix := slot_key.substr(0, mini(3, slot_key.length())).to_upper()
	if prefix == "":
		prefix = "PRT"
	var shape := String(part.get("shape", part.get("material_class", ""))).to_upper()
	var subcode := "GEN" if shape == "" else shape.substr(0, mini(3, shape.length()))
	return _base(prefix, subcode, "PART", "通用部件" if zh else "Generic part", "组件" if zh else "Component", ["组件" if zh else "Part"], zh)

static func _base(prefix: String, subcode: String, glyph: String, family: String, role: String, tags: Array, _zh: bool) -> Dictionary:
	return {
		"prefix": prefix,
		"subcode": subcode,
		"glyph": glyph,
		"family": family,
		"coarse_family": family,
		"role": role,
		"coarse_role": family,
		"tags": tags,
		"tag_signature": _tags_signature(tags),
	}

static func _identity_color(slot_key: String, part: Dictionary) -> Color:
	var style := PartArt.style_for(slot_key, part, "identity")
	var color: Color = style.get("accent_color", Color(0.72, 0.9, 1.0, 1.0))
	if color.a <= 0.0:
		color.a = 1.0
	return color

static func _size_code(part: Dictionary) -> String:
	var tier := PartArt.normalized_size_tier(part).strip_edges().to_upper()
	if tier != "":
		return tier.substr(0, mini(2, tier.length()))
	var mass := float(part.get("mass", part.get("component_mass", 0.0)))
	if mass <= 4.0:
		return "XS"
	if mass <= 10.0:
		return "S"
	if mass <= 24.0:
		return "M"
	if mass <= 52.0:
		return "L"
	return "XL"

static func _is_ranged_terminal(part: Dictionary) -> bool:
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"] or String(part.get("gun_kind", "")) != ""

static func _is_terminal_weapon(part: Dictionary) -> bool:
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("terminal_weapon", false)) or material_class in ["weapon", "racket"] or int(part.get("connection_ends", 2)) <= 1

static func _part_key(part: Dictionary) -> String:
	return ("%s %s %s %s %s %s %s %s %s %s" % [
		String(part.get("name", "")),
		String(part.get("component_name", "")),
		String(part.get("stable_key", "")),
		String(part.get("shape", "")),
		String(part.get("source_shape", "")),
		String(part.get("material_class", "")),
		String(part.get("weapon_family", "")),
		String(part.get("gun_kind", "")),
		String(part.get("projectile_style", "")),
		String(part.get("projectile_behavior", "")),
	]).to_lower()

static func _first_key(values: Array) -> String:
	for value in values:
		var text := String(value).strip_edges().to_lower()
		if text != "":
			return text
	return ""

static func _first_matching_key(key: String, needles: Array) -> String:
	for needle in needles:
		var text := String(needle)
		if key.contains(text):
			return text
	return ""

static func _lookup_subcode(key: String, table: Dictionary, fallback: String) -> String:
	var normalized := key.to_lower()
	for needle in table.keys():
		if normalized.contains(String(needle)):
			return String(table[needle])
	return fallback

static func _lookup_label(key: String, table: Dictionary, zh: bool, fallback: String) -> String:
	var normalized := key.to_lower()
	for needle in table.keys():
		if normalized.contains(String(needle)):
			var pair: Array = Array(table[needle])
			return String(pair[0 if zh else 1])
	return fallback

static func _tags_signature(tags: Array) -> String:
	var values: Array = []
	for tag in tags:
		values.append(String(tag))
	return "|".join(values)

static func _damage_label(damage_type: String, zh: bool) -> String:
	match damage_type.to_lower():
		"bullet":
			return "实弹" if zh else "Bullet"
		"chemical":
			return "化学" if zh else "Chemical"
		"laser":
			return "激光" if zh else "Laser"
		"pierce":
			return "穿刺" if zh else "Pierce"
		"tear":
			return "撕裂" if zh else "Tear"
		"blunt", "impact":
			return "钝击" if zh else "Impact"
		"explosive":
			return "爆破" if zh else "Explosive"
		"web":
			return "牵引网" if zh else "Web"
	return "通用" if zh else "General"

static func _scan_label(level: int, zh: bool) -> String:
	if level <= UNKNOWN_SCAN:
		return "未知" if zh else "UNK"
	if level == PARTIAL_SCAN:
		return "疑似" if zh else "SCAN"
	return "已识别" if zh else "ID"

static func _is_zh(language: String) -> bool:
	return language.to_lower().begins_with("zh")
