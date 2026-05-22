class_name PartArtResolver
extends RefCounted

# Base component art is now Godot-procedural. These legacy image-sheet paths
# stay empty so older callers cannot silently pull a second art system back
# into physical parts.
const COMPONENT_SHEET_PATH := ""
const SOFTWARE_SHEET_PATH := ""
const FALLBACK_SHEET_PATH := ""
const TORSO_GEOMETRY_SCALE := 2.0


static func load_texture(path: String) -> Texture2D:
	if path.strip_edges() == "":
		return null
	var resource := load(path)
	if resource is Texture2D:
		return resource
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func default_sheets() -> Dictionary:
	return {}


static func resolve(_slot_key: String, _part: Dictionary, _sheets: Dictionary, _context: String = "card", _part_kind: String = "") -> Dictionary:
	return {}


static func style_for(slot_key: String, part: Dictionary, context: String = "card", part_kind: String = "") -> Dictionary:
	var normalized_slot := _normalized_slot(slot_key, part, part_kind)
	var material_style := material_style_for(part)
	var damage_style := damage_style_for(part)
	return {
		"procedural": true,
		"slot": normalized_slot,
		"shape_kind": shape_kind_for(normalized_slot, part),
		"material_style": material_style,
		"damage_style": damage_style,
		"primary_color": material_color_for(material_style, normalized_slot),
		"accent_color": damage_color_for(damage_style, normalized_slot),
		"connector_count": connector_count_for(normalized_slot, part),
		"terminal_profile": terminal_profile_for(part),
		"software_icon_kind": software_icon_for(normalized_slot, part),
		"size_scale": size_scale_for(part),
		"fill": fill_for(normalized_slot, part, context),
		"length_fill": length_fill_for(normalized_slot, part),
		"width_fill": width_fill_for(normalized_slot, part),
		"rotate": normalized_slot == "cooling",
	}


static func make_group_part(group: Dictionary, part_kind: String, stats: Dictionary = {}) -> Dictionary:
	var part := group.duplicate(true)
	part["component_name"] = _first_non_empty([
		group.get("component_name", ""),
		group.get("muscle_name", ""),
		group.get("joint_name", ""),
		group.get("limb_muscle_name", ""),
		stats.get("name", ""),
	])
	if part_kind == "joint":
		part["slot"] = "joint"
		part["software_joint"] = true
		part["joint_is_software"] = true
		part["shape"] = _first_non_empty([group.get("joint_shape", ""), group.get("shape", "")])
		part["material_class"] = _first_non_empty([group.get("joint_material_class", ""), group.get("material_class", "")])
		part["component_length"] = 0.0
	elif part_kind == "limb_muscle":
		part["slot"] = "limb_muscle"
		part["shape"] = _first_non_empty([group.get("limb_muscle_shape", ""), group.get("shape", "")])
		part["material_class"] = _first_non_empty([group.get("limb_material_class", ""), group.get("material_class", "")])
		part["component_length"] = group.get("muscle_length", group.get("component_length", 0.48))
	elif part_kind == "terminal":
		part["slot"] = "muscle"
		part["terminal_weapon"] = true
		part["component_length"] = group.get("terminal_length", group.get("length", 0.62))
		part["component_mass"] = group.get("terminal_weapon_mass", group.get("mass", 8.0))
	elif part_kind == "torso":
		part["slot"] = "muscle"
		part["is_torso"] = true
		part["shape"] = stats.get("torso_visual_shape", stats.get("shape", group.get("shape", "core")))
		part["material_visual"] = stats.get("torso_visual_material", group.get("material_visual", "metal"))
		part["size_class"] = stats.get("size_class", group.get("size_class", ""))
	elif part_kind == "booster":
		part["slot"] = "booster"
		part["flame_color"] = stats.get("flame_color", group.get("flame_color", "blue"))
		part["thruster_family"] = stats.get("thruster_family", group.get("thruster_family", "cruise_blue"))
		part["allocated_momentum"] = stats.get("thruster_allocated_momentum", group.get("allocated_momentum", 0.0))
		part["move_momentum"] = stats.get("move_momentum", 0.0)
		part["boost_momentum"] = stats.get("boost_momentum", group.get("boost_momentum", 0.0))
		part["component_mass"] = stats.get("mass", group.get("mass", 0.0))
	elif part_kind == "barrier_tile":
		part["slot"] = "muscle"
		part["is_barrier_tile"] = true
	return part


static func shape_kind_for(slot_key: String, part: Dictionary) -> String:
	var key := _part_key(part)
	if slot_key == "joint":
		if bool(part.get("software_joint", false)) or bool(part.get("joint_is_software", false)):
			return "software_joint"
		if bool(part.get("fixed_corner_joint", false)) or key.contains("corner"):
			return "corner_joint"
		if key.contains("linear") or key.contains("telescopic") or key.contains("rail") or float(part.get("max_extension_m", part.get("range", 0.0))) > 0.08:
			return "telescopic_joint"
		return "ball_joint"
	if slot_key == "limb_muscle":
		if key.contains("chain") or key.contains("whip") or key.contains("tentacle"):
			return "chain_link"
		if key.contains("stake") or key.contains("rod") or key.contains("girder"):
			return "straight_beam"
		return "two_end_muscle"
	if slot_key == "torso":
		return "saddle_torso"
	if slot_key == "projectile":
		if key.contains("laser"):
			return "laser_gun"
		if key.contains("missile") or key.contains("rocket") or key.contains("mortar"):
			return "launcher"
		if key.contains("acid") or key.contains("chem"):
			return "sprayer"
		return "barrel_gun"
	if slot_key == "terminal":
		return terminal_profile_for(part)
	if slot_key == "barrier_tile":
		if key.contains("shield"):
			return "one_way_panel"
		if key.contains("field") or key.contains("gravity") or key.contains("trap"):
			return "field_plate"
		return "maze_plate"
	if _is_software_slot(slot_key, part):
		return "software_chip"
	if slot_key == "booster":
		return "thruster_nozzle"
	return "component_node"


static func material_style_for(part: Dictionary) -> String:
	var key := _part_key(part) + " " + String(part.get("material_visual", "")).to_lower()
	if key.contains("ceramic") or key.contains("stone"):
		return "ceramic"
	if key.contains("wood") or key.contains("timber"):
		return "wood"
	if key.contains("fur") or key.contains("hide") or key.contains("padded"):
		return "fur"
	if key.contains("software") or key.contains("engine") or key.contains("module") or key.contains("ether") or key.contains("source") or key.contains("soul"):
		return "software"
	return "metal"


static func damage_style_for(part: Dictionary) -> String:
	var damage := String(part.get("projectile_damage_type", part.get("damage_type", ""))).to_lower()
	var key := _part_key(part)
	if damage != "":
		return damage
	if key.contains("laser"):
		return "laser"
	if key.contains("chemical") or key.contains("acid"):
		return "chemical"
	if key.contains("bullet") or key.contains("rifle") or key.contains("gun"):
		return "bullet"
	if key.contains("blade") or key.contains("scythe") or key.contains("katana"):
		return "tear"
	if key.contains("spike") or key.contains("lance") or key.contains("drill"):
		return "pierce"
	if key.contains("hammer") or key.contains("glove") or key.contains("shield"):
		return "blunt"
	return "neutral"


static func material_color_for(material_style: String, slot_key: String = "") -> Color:
	match material_style:
		"ceramic":
			return Color(0.78, 0.74, 0.62, 1.0)
		"wood":
			return Color(0.56, 0.39, 0.2, 1.0)
		"fur":
			return Color(0.58, 0.5, 0.38, 1.0)
		"software":
			return Color(0.38, 0.86, 1.0, 1.0)
	return Color(0.7, 0.78, 0.84, 1.0)


static func damage_color_for(damage_style: String, slot_key: String = "") -> Color:
	if slot_key == "booster":
		return Color(1.0, 0.54, 0.14, 1.0)
	match damage_style:
		"bullet":
			return Color(1.0, 0.18, 0.12, 1.0)
		"chemical":
			return Color(0.74, 1.0, 0.18, 1.0)
		"laser":
			return Color(0.16, 0.82, 1.0, 1.0)
		"explosive":
			return Color(1.0, 0.5, 0.12, 1.0)
		"tear":
			return Color(0.2, 1.0, 0.62, 1.0)
		"pierce":
			return Color(0.82, 0.38, 1.0, 1.0)
		"blunt":
			return Color(1.0, 0.78, 0.26, 1.0)
	return Color(0.9, 0.96, 1.0, 1.0)


static func connector_count_for(slot_key: String, part: Dictionary) -> int:
	if _is_software_slot(slot_key, part):
		return 0
	if slot_key in ["terminal", "projectile", "booster"]:
		return 1
	if slot_key in ["joint", "limb_muscle"]:
		return 2
	if slot_key == "torso":
		return torso_saddle_port_count(part)
	return int(part.get("connection_ends", 2))


static func torso_saddle_port_count(part: Dictionary) -> int:
	var raw_ports := int(part.get("joint_ports", part.get("external_joint_ports", part.get("connector_count", part.get("connection_ends", 6)))))
	return clampi(maxi(1, raw_ports), 1, 6)


static func torso_saddle_local_points(length: float = 2.0, front_width: float = 0.72, rear_width: float = 1.56) -> PackedVector2Array:
	length *= TORSO_GEOMETRY_SCALE
	front_width *= TORSO_GEOMETRY_SCALE
	rear_width *= TORSO_GEOMETRY_SCALE
	var half_length := maxf(0.01, length) * 0.5
	var front_half := maxf(0.01, front_width) * 0.5
	var rear_half := maxf(front_half + 0.01, rear_width) * 0.5
	return PackedVector2Array([
		Vector2(half_length, -front_half),
		Vector2(half_length, front_half),
		Vector2(-half_length, rear_half),
		Vector2(-half_length, -rear_half),
	])


static func torso_saddle_port_local_offsets(port_count: int, length: float = 2.0, front_width: float = 0.72, rear_width: float = 1.56) -> Array:
	length *= TORSO_GEOMETRY_SCALE
	front_width *= TORSO_GEOMETRY_SCALE
	rear_width *= TORSO_GEOMETRY_SCALE
	var count := clampi(port_count, 1, 6)
	var half_length := maxf(0.01, length) * 0.5
	var front_half := maxf(0.01, front_width) * 0.5
	var rear_half := maxf(front_half + 0.01, rear_width) * 0.5
	var front_center := Vector2(half_length, 0.0)
	var front_top := Vector2(half_length, -front_half)
	var front_bottom := Vector2(half_length, front_half)
	var rear_top := Vector2(-half_length, -rear_half)
	var rear_bottom := Vector2(-half_length, rear_half)
	var offsets: Array = []
	if count in [1, 3, 5]:
		offsets.append(front_center)
	var t_values: Array = []
	match count:
		2, 3:
			t_values = [0.12]
		4, 5:
			t_values = [0.10, 0.34]
		6:
			t_values = [0.08, 0.25, 0.42]
	for raw_t in t_values:
		var t := float(raw_t)
		offsets.append(front_top.lerp(rear_top, t))
		offsets.append(front_bottom.lerp(rear_bottom, t))
	return offsets


static func torso_saddle_port_directions(port_count: int) -> Array:
	var dirs: Array = []
	for offset in torso_saddle_port_local_offsets(port_count):
		var v: Vector2 = offset
		dirs.append(v.normalized() if v.length() > 0.001 else Vector2.RIGHT)
	return dirs


static func terminal_profile_for(part: Dictionary) -> String:
	if _is_projectile_weapon(part):
		return "muzzle"
	var damage := damage_style_for(part)
	match damage:
		"tear":
			return "edge_blade"
		"pierce":
			return "pierce_tip"
		"blunt":
			return "blunt_face"
	return "impact_face"


static func terminal_geometry_length_multiplier(part: Dictionary) -> float:
	if not _is_terminal_weapon(part):
		return 1.0
	return 0.70 if _is_projectile_weapon(part) else 0.62


static func terminal_geometry_radius_multiplier(part: Dictionary) -> float:
	return 0.75 if _is_terminal_weapon(part) else 1.0


static func software_icon_for(slot_key: String, part: Dictionary) -> String:
	var key := _part_key(part)
	if slot_key == "special" or key.contains("soul"):
		return "soul_star"
	if key.contains("source") or key.contains("code") or key.contains("puppet"):
		return "source_star"
	if key.contains("ether") or key.contains("barrier"):
		return "ether_orbit"
	if slot_key == "engine" or key.contains("engine") or key.contains("reactor"):
		return "engine_core"
	if slot_key == "cooling" or key.contains("cool"):
		return "cooling_fins"
	if slot_key == "shield" or key.contains("shield") or key.contains("armor"):
		return "shield_grid"
	if slot_key == "ammo" or key.contains("ammo"):
		return "ammo_stack"
	return "action_chip"


static func normalized_size_tier(part: Dictionary) -> String:
	for key in ["size_tier", "size_class", "slot_volume_tier", "ammo_size_tier"]:
		var tier := _normalize_size_tier_value(String(part.get(key, "")))
		if tier != "":
			return tier
	var length := float(part.get("component_length", part.get("length", 0.45)))
	var radius := float(part.get("component_radius", part.get("radius", 0.0)))
	var mass := float(part.get("component_mass", part.get("mass", 8.0)))
	if _is_terminal_weapon(part) and not bool(part.get("terminal_geometry_scaled", false)):
		length *= terminal_geometry_length_multiplier(part)
	var footprint := maxf(length, radius * 2.7) + mass * 0.002
	if footprint <= 0.18:
		return "XS"
	if footprint <= 0.48:
		return "S"
	if footprint <= 1.15:
		return "M"
	if footprint <= 2.35:
		return "L"
	return "XL"


static func size_rank_for(part: Dictionary) -> int:
	match normalized_size_tier(part):
		"XS":
			return 1
		"S":
			return 2
		"M":
			return 3
		"L":
			return 4
		"XL":
			return 5
	return 3


static func _normalize_size_tier_value(raw_value: String) -> String:
	var value := raw_value.strip_edges().to_upper()
	if value == "":
		return ""
	if value in ["XS", "S", "M", "L", "XL"]:
		return value
	match value.to_lower():
		"nano", "micro", "tiny", "starter":
			return "XS"
		"small":
			return "S"
		"medium", "standard":
			return "M"
		"long", "large", "heavy", "siege", "titan":
			return "L"
		"monster", "kaiju", "colossus", "leviathan":
			return "XL"
	return "M"


static func size_scale_for(part: Dictionary) -> float:
	var tier_scale := {
		"XS": 0.46,
		"S": 0.68,
		"M": 1.0,
		"L": 1.34,
		"XL": 1.82,
	}
	var tier := normalized_size_tier(part)
	var base := float(tier_scale.get(tier, 1.0))
	var length := float(part.get("component_length", part.get("length", 0.45)))
	var radius := float(part.get("component_radius", part.get("radius", 0.0)))
	var mass := float(part.get("component_mass", part.get("mass", 8.0)))
	if _is_terminal_weapon(part) and not bool(part.get("terminal_geometry_scaled", false)):
		length *= terminal_geometry_length_multiplier(part)
	var footprint := maxf(length, radius * 2.7) + mass * 0.002
	var footprint_scale := clampf(0.64 + footprint * 0.44, 0.46, 1.9)
	return clampf(maxf(base, footprint_scale * 0.94), 0.46, 1.92)


static func fill_for(slot_key: String, part: Dictionary, context: String) -> Vector2:
	if context == "combat":
		return Vector2(length_fill_for(slot_key, part), width_fill_for(slot_key, part))
	match slot_key:
		"joint":
			return Vector2(0.78, 0.8)
		"limb_muscle":
			return Vector2(0.92, 0.52)
		"projectile":
			return Vector2(0.96, 0.58)
		"terminal":
			if damage_style_for(part) == "pierce":
				return Vector2(0.98, 0.48)
			if damage_style_for(part) == "blunt":
				return Vector2(0.86, 0.74)
			return Vector2(0.96, 0.68)
		"torso":
			return Vector2(0.84, 0.88)
		"booster":
			return Vector2(0.78, 0.84)
		"barrier_tile":
			return Vector2(0.94, 0.64)
	return Vector2(0.78, 0.78)


static func length_fill_for(slot_key: String, _part: Dictionary) -> float:
	match slot_key:
		"joint":
			return 0.72
		"limb_muscle":
			return 0.86
		"projectile":
			return 0.76
		"terminal":
			return 0.72
		"torso":
			return 0.82
		"booster":
			return 0.76
		"barrier_tile":
			return 0.88
	return 0.78


static func width_fill_for(slot_key: String, part: Dictionary) -> float:
	match slot_key:
		"joint":
			return 0.62
		"limb_muscle":
			return 0.38
		"projectile":
			return 0.5
		"terminal":
			if damage_style_for(part) == "pierce":
				return 0.26
			if damage_style_for(part) == "blunt":
				return 0.44
			return 0.34
		"torso":
			return 0.72
		"booster":
			return 0.58
		"barrier_tile":
			return 0.42
	return 0.56


static func _normalized_slot(slot_key: String, part: Dictionary, part_kind: String) -> String:
	if part_kind != "":
		if part_kind == "terminal":
			return "terminal"
		if part_kind == "barrier_tile":
			return "barrier_tile"
		return part_kind
	var slot := String(part.get("slot", slot_key)).to_lower()
	if slot == "muscle" and _is_terminal_weapon(part):
		return "terminal"
	if slot == "muscle" and _is_torso(part):
		return "torso"
	if slot == "muscle" and _is_projectile_weapon(part):
		return "projectile"
	return slot


static func _is_software_slot(slot_key: String, part: Dictionary) -> bool:
	if slot_key in ["engine", "cooling", "module", "special", "ammo", "shield", "software"]:
		return true
	var material_class := String(part.get("material_class", "")).to_lower()
	return material_class in ["software", "engine", "cooling", "module", "soul", "source_code", "ether", "electronic_armor"]


static func _is_torso(part: Dictionary) -> bool:
	var key := _part_key(part)
	return bool(part.get("is_torso", false)) or key.contains("torso") or key.contains("core") or key.contains("brain") or key.contains("body")


static func _is_projectile_weapon(part: Dictionary) -> bool:
	var key := _part_key(part)
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"] or key.contains("gun") or key.contains("rifle") or key.contains("cannon") or key.contains("launcher") or key.contains("laser")


static func _is_terminal_weapon(part: Dictionary) -> bool:
	if _is_projectile_weapon(part):
		return true
	var material_class := String(part.get("material_class", "")).to_lower()
	var key := _part_key(part)
	return bool(part.get("terminal_weapon", false)) or material_class in ["weapon", "racket", "whip_muscle", "whip_joint"] or int(part.get("connection_ends", 2)) <= 1 or key.contains("blade") or key.contains("scythe") or key.contains("katana") or key.contains("hammer") or key.contains("glove") or key.contains("shield") or key.contains("spike") or key.contains("lance") or key.contains("drill")


static func _part_key(part: Dictionary) -> String:
	return ("%s %s %s %s %s %s" % [
		String(part.get("name", "")),
		String(part.get("component_name", "")),
		String(part.get("label", "")),
		String(part.get("shape", "")),
		String(part.get("material_class", "")),
		String(part.get("archetype", "")),
	]).to_lower()


static func _first_non_empty(values: Array) -> String:
	for value in values:
		var text := String(value)
		if text != "":
			return text
	return ""
