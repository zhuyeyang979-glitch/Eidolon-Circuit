extends RefCounted
class_name DataRuleService

const ENGINE_MOMENTUM_OUTPUT_SCALE := 9.0
const COOLING_OUTPUT_SCALE := 1.0
const COOLING_POOL_SCALE := 2.0
const THRUSTER_ALLOCATION_MAX_MULT := 3.0
const LIMB_MOMENTUM_MAX_SCALE := 1.0

const ACTION_MODULE_COMBAT_FIELD_KEYS := [
	"normal_damage",
	"armor_damage",
	"active_damage",
	"damage",
	"damage_type",
	"damage_coeff",
	"break_coeff",
	"stiffness_momentum",
	"path_stiffness_momentum",
	"projectile_damage",
	"projectile_damage_type",
	"projectile_damage_coeff",
	"projectile_break_coeff",
	"explosion_damage",
	"explosion_damage_type",
	"trap_damage",
	"trap_damage_type",
	"barrage_damage",
	"barrage_damage_type",
	"homing_damage",
	"homing_damage_type",
	"cage_damage",
	"cage_damage_type",
	"ball_hit_damage",
	"takeover_damage_rate",
	"takeover_damage_type",
	"module_damage_mult",
]

const GUN_LEGACY_DAMAGE_FIELD_KEYS := [
	"normal_damage",
	"projectile_damage",
	"projectile_damage_coeff",
	"ammo_damage_coeff",
	"gun_damage_coeff",
	"explosion_damage",
	"explosion_damage_type",
]

const NONPHYSICAL_HP_FIELD_KEYS := ["hp", "max_hp", "health"]


func engine_output(raw_output: float, scale: float = 1.0) -> float:
	return maxf(0.0, raw_output * scale) * ENGINE_MOMENTUM_OUTPUT_SCALE


func allocation_max(minimum: float) -> float:
	var safe_minimum := maxf(0.0, minimum)
	return safe_minimum * THRUSTER_ALLOCATION_MAX_MULT if safe_minimum > 0.0 else 0.0


func clamp_allocation(value: float, minimum: float, maximum: float) -> float:
	var safe_minimum := maxf(0.0, minimum)
	var safe_maximum := maxf(safe_minimum, maximum)
	return clampf(value, safe_minimum, safe_maximum)


func limb_max(raw_maximum: float) -> float:
	return maxf(0.0, raw_maximum) * LIMB_MOMENTUM_MAX_SCALE


func cooling_pool_capacity(raw_capacity: float, already_scaled: bool) -> float:
	var safe_capacity := maxf(0.0, raw_capacity)
	return safe_capacity if already_scaled else safe_capacity * COOLING_POOL_SCALE


func gun_current_multiplier(max_multiplier: float, allocated: float, maximum: float, non_damage: bool = false) -> float:
	if non_damage:
		return 0.0
	var safe_max_multiplier := maxf(0.0, max_multiplier)
	var safe_maximum := maxf(0.0, maximum)
	if safe_maximum <= 0.001:
		return safe_max_multiplier
	return safe_max_multiplier * (clampf(allocated, 0.0, safe_maximum) / safe_maximum)


func is_action_module(slot_key: String, part: Dictionary) -> bool:
	return slot_key == "module" or part.has("module_action_profile") or part.has("module_target_kind") or part.has("command_window_profile")


func is_gun_part(slot_key: String, part: Dictionary) -> bool:
	if slot_key != "muscle":
		return false
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("projectile", false)) or part.has("gun_kind") or material_class in ["gun", "missile_launcher", "web_gun"]


func is_nonphysical_equipment_or_software(slot_key: String, part: Dictionary) -> bool:
	if slot_key in ["engine", "booster", "cooling", "ammo", "special", "module", "joint"]:
		return true
	if bool(part.get("software", false)):
		return true
	if bool(part.get("torso_slot_payload", false)) and not bool(part.get("is_torso", false)):
		return true
	if bool(part.get("ammo_slot_payload", false)) or bool(part.get("shield_payload", false)) or bool(part.get("electronic_armor", false)):
		return true
	var material_class := String(part.get("material_class", ""))
	return material_class in ["ammo_payload", "shield_payload", "engine_payload", "booster_payload", "cooling_payload"]


func canonical_catalog_part(part: Dictionary, slot_key: String) -> Dictionary:
	var canonical := part.duplicate(true)
	if is_nonphysical_equipment_or_software(slot_key, canonical):
		for key in NONPHYSICAL_HP_FIELD_KEYS:
			canonical.erase(key)
	if is_action_module(slot_key, canonical):
		for key in ACTION_MODULE_COMBAT_FIELD_KEYS:
			canonical.erase(key)
	if is_gun_part(slot_key, canonical):
		for key in GUN_LEGACY_DAMAGE_FIELD_KEYS:
			canonical.erase(key)
	return canonical


func canonical_part_rejection_reason(slot_key: String, part: Dictionary) -> String:
	if is_nonphysical_equipment_or_software(slot_key, part):
		for key in NONPHYSICAL_HP_FIELD_KEYS:
			if part.has(key):
				return "nonphysical %s payload contains %s" % [slot_key, key]
	if is_action_module(slot_key, part):
		for key in ACTION_MODULE_COMBAT_FIELD_KEYS:
			if part.has(key):
				return "action module contains combat field %s" % key
	if is_gun_part(slot_key, part):
		for key in GUN_LEGACY_DAMAGE_FIELD_KEYS:
			if part.has(key):
				return "gun contains legacy damage field %s" % key
	return ""


func saved_dict_looks_like_nonphysical_payload(data: Dictionary) -> bool:
	var kind := String(data.get("kind", data.get("slot_key", data.get("slot", ""))))
	if kind in ["engine", "booster", "cooling", "ammo", "special", "module", "joint", "electronic_armor", "shield"]:
		return true
	if data.has("engine_family") or data.has("engine_momentum_output"):
		return true
	if data.has("thruster_family") or data.has("movement_profile"):
		return true
	if data.has("cooling_family") or data.has("cooling_rate") or data.has("heat_dissipation"):
		return true
	if bool(data.get("ammo_slot_payload", false)) or bool(data.get("shield_payload", false)) or bool(data.get("electronic_armor", false)):
		return true
	return bool(data.get("software", false)) or data.has("soul_heat_capacity") or data.has("source_rules") or data.has("ether_group_kind")


func first_nonphysical_combat_path(value: Variant, path: String = "$") -> String:
	if value is Dictionary:
		var data: Dictionary = value
		if saved_dict_looks_like_nonphysical_payload(data):
			for key in NONPHYSICAL_HP_FIELD_KEYS:
				if data.has(key):
					return "%s.%s" % [path, key]
		if is_action_module(String(data.get("slot_key", data.get("kind", ""))), data):
			for key in ACTION_MODULE_COMBAT_FIELD_KEYS:
				if data.has(key):
					return "%s.%s" % [path, key]
		for child_key in data.keys():
			var found := first_nonphysical_combat_path(data[child_key], "%s.%s" % [path, str(child_key)])
			if found != "":
				return found
	elif value is Array:
		var array: Array = value
		for i in range(array.size()):
			var found := first_nonphysical_combat_path(array[i], "%s[%d]" % [path, i])
			if found != "":
				return found
	return ""
