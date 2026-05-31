extends RefCounted
class_name ActionProfileRegistry

const COMMAND_STATE_BY_INPUT := {
	"X": "normal",
	"4X": "active",
	"6X": "armor",
	"236X": "armor",
	"214X": "active",
}

const PROJECTILE_PROFILES := [
	"gun_activate",
	"rifle_burst_activate",
	"grenade_arc_activate",
	"laser_beam_activate",
	"missile_lock_activate",
	"web_tether_activate",
]

const MELEE_PROFILES := [
	"swing_90",
	"swing_180",
	"swing_360",
	"extend_1m",
	"extend_2m",
	"extend_3m",
	"pierce_rail_3m",
	"pierce_telescopic_lunge",
	"rapier_feint_thrust",
	"lance_couched_charge",
	"drill_breach_drive",
	"dual_extend_2m",
	"inward_pincer_clamp",
	"chain_backlash",
	"reeling_hook_rip",
	"boot_action_driver",
	"two_link_forward_snap",
	"blunt_gauntlet_extend_swing",
	"blunt_shield_guard_bash",
	"blunt_hammer_windup_slam",
	"blade_arc_return",
	"katana_quickdraw",
	"scythe_hook_return",
	"greatsword_commit_cleave",
	"triple_limb_cross_cut",
	"extend_slash_driver",
]

const PROFILE_FOR_GUN_KIND := {
	"sniper": "gun_activate",
	"sprayer": "gun_activate",
	"rifle": "rifle_burst_activate",
	"grenade_launcher": "grenade_arc_activate",
	"laser_gun": "laser_beam_activate",
	"missile_launcher": "missile_lock_activate",
	"web_gun": "web_tether_activate",
}

const AMMO_FOR_PROJECTILE_PROFILE := {
	"rifle_burst_activate": "bullet",
	"grenade_arc_activate": "explosive",
	"laser_beam_activate": "laser",
	"missile_lock_activate": "explosive",
	"web_tether_activate": "web",
}

const PROJECTILE_MOBILITY_CONTRACT := {
	"move_while_firing": true,
	"direction_boost_while_firing": true,
	"aim_input_mode": "turn_keys",
}


func projectile_profiles() -> Array:
	return PROJECTILE_PROFILES.duplicate()


func melee_profiles() -> Array:
	return MELEE_PROFILES.duplicate()


func live_profiles() -> Array:
	var profiles := MELEE_PROFILES.duplicate()
	for profile in PROJECTILE_PROFILES:
		if not profiles.has(profile):
			profiles.append(profile)
	return profiles


func command_state_for(command: String) -> String:
	return String(COMMAND_STATE_BY_INPUT.get(command.to_upper(), "normal"))


func is_projectile_profile(profile: String) -> bool:
	return PROJECTILE_PROFILES.has(profile.to_lower())


func is_melee_profile(profile: String) -> bool:
	return MELEE_PROFILES.has(profile.to_lower())


func is_live_profile(profile: String) -> bool:
	var key := profile.to_lower()
	return is_melee_profile(key) or is_projectile_profile(key)


func projectile_mobility_contract(profile: String) -> Dictionary:
	if not is_projectile_profile(profile):
		return {}
	return PROJECTILE_MOBILITY_CONTRACT.duplicate(true)


func profile_for_gun_kind(gun_kind: String) -> String:
	return String(PROFILE_FOR_GUN_KIND.get(gun_kind.to_lower(), ""))


func projectile_profile_supports_kind(profile: String, gun_kind: String, ammo_kind: String = "") -> bool:
	return module_supports_gun(profile, gun_kind, ammo_kind)


func module_supports_gun(profile: String, gun_kind: String, ammo_kind: String = "") -> bool:
	var profile_key := profile.to_lower()
	var gun_key := gun_kind.to_lower()
	if profile_key == "gun_activate":
		var native_profile := profile_for_gun_kind(gun_key)
		return native_profile != "" and _native_profile_supports_kind(native_profile, gun_key, ammo_kind)
	return _native_profile_supports_kind(profile_key, gun_key, ammo_kind)


func effective_profile_for_activation(module_profile: String, gun_kind: String, ammo_kind: String = "") -> String:
	var profile_key := module_profile.to_lower()
	var gun_key := gun_kind.to_lower()
	if not module_supports_gun(profile_key, gun_key, ammo_kind):
		return ""
	if profile_key == "gun_activate":
		return profile_for_gun_kind(gun_key)
	return profile_key


func _native_profile_supports_kind(profile_key: String, gun_key: String, ammo_kind: String = "") -> bool:
	if profile_for_gun_kind(gun_key) != profile_key:
		return false
	if not AMMO_FOR_PROJECTILE_PROFILE.has(profile_key):
		return true
	return ammo_kind.to_lower() == String(AMMO_FOR_PROJECTILE_PROFILE[profile_key])
