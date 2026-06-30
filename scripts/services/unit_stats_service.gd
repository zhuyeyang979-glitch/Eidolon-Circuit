extends RefCounted
class_name UnitStatsService

var main_ref: Object
var cache
var hit_count := 0
var miss_count := 0

const PART_LOGIC_COPY_KEYS := [
	"orbit_radius", "hold_range", "flank_width", "source_target_policy", "source_attack_preference", "source_close_response", "source_threat_override_range", "source_keep_range", "source_heat_focus_ratio", "barrier_logic", "aura_range", "aura_heat", "ally_cooling", "slow_power", "pulse_interval", "role_switch", "switch_cooldown", "identity_receiver_role", "identity_receiver_order", "role_form_target_role", "role_form_mech_role", "role_form_shape", "combine_partner_count", "combine_max_partners", "combine_shape", "module_effect", "module_state", "module_range", "module_lane_range", "module_damage_mult", "pull_power", "non_damage", "web_strength", "web_break_force", "web_pull_mode", "blind_radius", "blind_duration", "blind_strength", "cool_burst", "cool_lock", "cool_overheat_clear", "chemical_dot_duration", "chemical_dot_mult", "chemical_frontload", "chemical_pellets", "chemical_spread", "takeover_on_hit", "takeover_seconds", "takeover_damage_rate", "takeover_damage_type", "is_signal_jammer", "jam_radius", "jam_seconds", "jam_power", "jam_duration", "jam_affects", "is_repair_station", "repair_rate", "repair_capacity", "station_repair_mult", "retreat_on_defeat", "retreat_repair_rate", "repair_time_mult", "prefer_repair_station", "is_hatchery", "hatch_profile", "hatch_interval", "hatch_limit", "hatch_ai", "hatch_modifier", "is_gravity_field", "gravity_force", "gravity_direction", "gravity_radius", "is_coolant_field", "coolant_radius", "coolant_boost", "coolant_affects", "is_heat_field", "heat_field_radius", "heat_field_rate", "heat_field_affects", "is_repulsion_field", "repulsion_radius", "repulsion_force", "is_hack_field", "hack_radius", "hack_seconds", "hack_power", "is_trap_field", "trap_radius", "trap_effect", "trap_command", "trap_cooldown", "trap_power", "trap_damage", "trap_damage_type", "trap_slow_duration", "trap_affects", "trap_direction_mode", "trap_link", "lease_rate", "lease_heat_penalty", "reflect_projectiles", "reflect_types", "reflect_power", "reflect_bonus_range", "reflect_affects", "shield_duration", "control_pages", "can_control_traps", "is_barrage_emitter", "barrage_mode", "barrage_interval", "barrage_damage", "barrage_damage_type", "barrage_range", "barrage_lane_range", "barrage_heat", "barrage_style", "barrage_spin_rate", "barrage_affects", "explosion_radius", "explosion_damage", "explosion_damage_type", "explosion_style", "projectile_momentum", "entry_breach_damage", "entry_breach_damage_type", "entry_breach_self_heat", "has_escape_pod", "escape_speed", "escape_module_slots", "escape_target_ring_delta", "escape_target_lane", "bounty_reward", "insured_refund", "annuity_rate", "entry_grant", "owner_destroy_penalty", "is_cage_wall", "cage_radius", "cage_damage", "cage_damage_type", "cage_repel", "cage_hit_interval", "cage_affects", "cage_shape", "is_homing_launcher", "homing_radius", "homing_interval", "homing_accuracy", "homing_damage", "homing_damage_type", "homing_heat", "homing_knock", "homing_affects", "suicide_on_hit", "vuln_kind", "vuln_mult", "vuln_duration", "blast_radius", "ball_puppet", "ball_hit_damage", "racket_power", "racket_lane_lift", "serve_range", "combine_range", "combine_bonus_hp", "is_resource_siphon", "siphon_radius", "siphon_rate", "is_speed_lane", "speed_lane_radius", "speed_lane_width", "speed_lane_mult", "speed_lane_pull", "speed_lane_affects", "speed_lane_bidirectional", "speed_field_shape", "is_coin_generator", "coin_interval", "coin_value", "coin_ttl", "coin_spawn_radius", "coin_pickup_radius", "is_one_way_shield", "shield_radius", "shield_lane_width", "shield_pass_mode", "shield_pass_direction", "shield_block_damage_mult", "shield_affects", "pirate_discount", "betrayal_chance", "morph_modes", "morph_cooldown", "charge_time", "focus_cost", "receiver", "material_slots", "space_size", "barrier_damage_type", "damage_boost_type", "damage_boost_mult", "barrier_disconnected"
]
const TORSO_BLOCKED_PART_LOGIC_KEYS := [
	"module_range", "module_lane_range", "module_damage_mult", "pull_power", "non_damage", "web_strength", "web_break_force", "web_pull_mode", "blind_radius", "blind_duration", "blind_strength", "chemical_dot_duration", "chemical_dot_mult", "chemical_frontload", "chemical_pellets", "chemical_spread", "takeover_on_hit", "takeover_seconds", "takeover_damage_rate", "takeover_damage_type", "is_barrage_emitter", "barrage_mode", "barrage_interval", "barrage_damage", "barrage_damage_type", "barrage_range", "barrage_lane_range", "barrage_heat", "barrage_style", "barrage_spin_rate", "barrage_affects", "explosion_radius", "explosion_damage", "explosion_damage_type", "explosion_style", "projectile_momentum", "is_homing_launcher", "homing_radius", "homing_interval", "homing_accuracy", "homing_damage", "homing_damage_type", "homing_heat", "homing_knock", "homing_affects", "suicide_on_hit", "vuln_kind", "vuln_mult", "blast_radius", "ball_hit_damage", "racket_power", "racket_lane_lift", "serve_range"
]
const ETHER_BLOCKED_PART_LOGIC_KEYS := ["material_slots", "space_size", "aura_range", "barrier_disconnected"]
const FRACTURE_COPY_KEYS := ["fracture_trigger", "fracture_exception_group", "fracture_ai"]
const SUPPORT_COPY_KEYS := ["is_support_node", "support_kind", "support_radius", "support_rate", "support_amount", "support_refill_seconds", "support_ammo_type", "support_buff_type", "support_buff_mult", "support_duration", "support_affects", "support_field_shape", "is_support_platform", "platform_pair_range", "platform_width", "platform_armor_hp"]
const MISSILE_COPY_KEYS := ["missile_lock_priority", "missile_lock_cone_degrees", "missile_lock_range", "missile_lock_target_classes", "missile_occlusion_grace"]
const TORSO_MODULE_PAYLOAD_LOGIC_KEYS := ["command", "skill_state", "motion", "aim_mode", "module_effect", "module_state", "role_switch", "switch_cooldown", "fracture_trigger", "fracture_exception_group", "fracture_ai", "morph_modes", "morph_cooldown", "combine_range", "combine_bonus_hp", "identity_receiver_role", "identity_receiver_order"]


func bind(main: Object, next_cache) -> void:
	main_ref = main
	cache = next_cache


func stats_key(unit_bp: Dictionary, revision_key: Variant) -> String:
	return "%s:%s:%s" % [
		str(unit_bp.get("unit_name", unit_bp.get("name", ""))),
		str(unit_bp.get("schema_version", unit_bp.get("save_schema", ""))),
		str(revision_key),
	]


func get_cached_stats(ns_name: String, unit_bp: Dictionary, revision_key: Variant, compute_callable: Callable) -> Variant:
	if cache == null:
		miss_count += 1
		return compute_callable.call() if compute_callable.is_valid() else {}
	var key := stats_key(unit_bp, revision_key)
	if cache.has_value(ns_name, key, revision_key):
		hit_count += 1
	else:
		miss_count += 1
	return cache.get_value(ns_name, key, revision_key, compute_callable)


func summary_line() -> String:
	return "stats svc h/m:%d/%d" % [hit_count, miss_count]


func base_stats(context: Dictionary) -> Dictionary:
	var constants := Dictionary(context.get("constants", {}))
	var manufacturer_counts: Dictionary = Dictionary(context.get("manufacturer_counts", {})).duplicate(true)
	return {
		"role": String(context.get("role_key", "")),
		"unit_index": int(context.get("unit_index", -1)),
		"name": String(context.get("unit_name", "")),
		"cost": 0,
		"health": 30,
		"mass": 0.0,
		"structural_mass": 0.0,
		"power": 0.0,
		"energy": 0.0,
		"power_load": 0.0,
		"length": 0.0,
		"cooling": 0.0,
		"heat_capacity": 0.0,
		"hardware_heat_capacity": 0.0,
		"cooling_heat_capacity": 0.0,
		"soul_heat_capacity": 0.0,
		"soul_heat_note": "",
		"engine_idle_heat": 0.0,
		"booster_idle_heat": 0.0,
		"idle_heat_load": 0.0,
		"thermal_margin": 0.0,
		"thermal_note": "",
		"thermal_pool": 0.0,
		"thermal_load_pool": 0.0,
		"thermal_dissipation_rate": 0.0,
		"heat_dissipation": 0.0,
		"cooling_pool": 0.0,
		"cooling_rate": 0.0,
		"runtime_cooling_rate": 0.0,
		"radius": 0.08,
		"speed_mult": 1.0,
		"cornering": 1.0,
		"speed_lane_affinity": 0.0,
		"normal_damage": 9,
		"armor_damage": 7,
		"active_damage": 17,
		"normal_range": 0.36,
		"armor_range": 0.24,
		"active_range": 0.52,
		"normal_lane_range": 0.24,
		"armor_lane_range": 0.2,
		"active_lane_range": 0.32,
		"normal_knock": 0.08,
		"armor_knock": 0.05,
		"active_knock": 0.14,
		"normal_duration": 0.2,
		"armor_duration": 0.42,
		"active_duration": 0.28,
		"normal_cooldown": 0.34,
		"armor_cooldown": 0.5,
		"active_cooldown": 0.74,
		"normal_heat": 0.0,
		"armor_heat": 0.0,
		"active_heat": 0.0,
		"move_heat": 0.0,
		"back_hit_heat_bonus": 0.0,
		"back_hit_heat_mult": 1.0,
		"deploy_wait": float(constants.get("deploy_wait_seconds", 4.0)),
		"projectile": false,
		"engine_power": 0.0,
		"aux_power": 0.0,
		"engine_count": 0,
		"engine_torque": 0.0,
		"engine_volume_rank": 0.0,
		"engine_momentum_budget": 0.0,
		"engine_joint_momentum_budget": 0.0,
		"engine_thruster_momentum_budget": 0.0,
		"engine_momentum_required": 0.0,
		"engine_momentum_margin": 0.0,
		"engine_momentum_ratio": 1.0,
		"engine_momentum_note": "",
		"thruster_engine_demand": 0.0,
		"bound_joint_engine_demand": 0.0,
		"bound_joint_count": 0,
		"bound_joint_output_momentum": 0.0,
		"estimated_joint_motion_speed": 0.0,
		"estimated_module_duration": 0.0,
		"required_power": 0.0,
		"power_ratio": 1.0,
		"power_margin": 0.0,
		"usable_power": 1.0,
		"power_note": "",
		"damage_type": "blunt",
		"material_class": "weapon",
		"connection_ends": 1,
		"joint_ports": 0,
		"weapon_bays": 0,
		"engine_slots": 0,
		"booster_slots": 0,
		"cooling_slots": 0,
		"module_slots": 0,
		"torso_slots": 0,
		"torso_slot_mass_limit": 0.0,
		"torso_slot_volume_rank_limit": 0.0,
		"slot_payload_count": 0,
		"slot_payload_mass": 0.0,
		"slot_payload_volume_rank": 0.0,
		"slot_payload_note": "",
		"spare_weapon_slots": 0,
		"spare_weapon_mass_limit": 0.0,
		"ammo_capacity": {"bullet": 0, "chemical": 0, "laser": 0},
		"ammo_slot_count": 0,
		"ammo_slot_mass": 0.0,
		"ammo_note": "",
		"electronic_armor_max": 0.0,
		"electronic_armor_regen": 0.0,
		"electronic_armor_coverage": 0.0,
		"electronic_armor_note": "",
		"shield_max": 0.0,
		"shield_regen": 0.0,
		"shield_coverage": 0.0,
		"shield_note": "",
		"attitude_control": 0.85,
		"melee_stability_core": 0.85,
		"melee_stability_threshold": float(constants.get("melee_stability_threshold_floor", 28.0)),
		"recoil_stabilization": 0.65,
		"knockback_resist": 0.12,
		"recovery_response": 0.85,
		"attitude_control_note": "",
		"load_capacity": 0.0,
		"stiffness": 0.0,
		"momentum_capacity": 0.0,
		"torso_break_threshold": 0.0,
		"torso_stiffness_segment_hp": 0.0,
		"torso_stiffness_segment_count": 0,
		"torso_stiffness_segments": [],
		"torso_material_family": "",
		"torso_material_mixed": false,
		"torso_resist": {"bullet": 1.0, "chemical": 1.0, "laser": 1.0, "blunt": 1.0, "pierce": 1.0, "tear": 1.0},
		"stiffness_note": "",
		"stiffness_segment_valid": true,
		"max_possible_momentum": 0.0,
		"weakest_group_stiffness": 0.0,
		"momentum_overload_ratio": 1.0,
		"momentum_note": "",
		"worst_joint_momentum": 0.0,
		"weakest_joint_momentum_capacity": 0.0,
		"max_joint_output_momentum": 0.0,
		"joint_momentum_overload_ratio": 1.0,
		"joint_momentum_note": "",
		"joint_slot_profiles": [],
		"joint_slot_count": 0,
		"joint_slot_note": "",
		"swept_collision_note": "",
		"swept_collision_count": 0,
		"terminal_weapon_mass": 0.0,
		"load_overload_ratio": 1.0,
		"load_note": "",
		"requires_dual_mount": false,
		"dual_mount_module": false,
		"dual_mount_points": 1,
		"dual_mount_load_mult": 1.0,
		"recoil_brace_mult": 1.0,
		"allows_vertical_overlap": false,
		"vertical_overlap_ports": 0,
		"resistances": {"bullet": 1.0, "chemical": 1.0, "laser": 1.0, "blunt": 1.0, "pierce": 1.0, "tear": 1.0},
		"counter_tiers": {"bullet": 0, "chemical": 0, "laser": 0, "blunt": 0, "pierce": 0, "tear": 0},
		"recoil": 0.06,
		"cancel_profile": "none",
		"cancel_power": 0.0,
		"aim_mode": "fixed",
		"motion": "straight",
		"aim_swing": 5.5,
		"auto_swing": 2.4,
		"thruster_family": "",
		"movement_profile": "",
		"flame_color": "blue",
		"brake_efficiency": 1.0,
		"move_efficiency": 1.0,
		"boost_efficiency": float(constants.get("economy_boost_momentum_mult", 2.0)),
		"turn_efficiency": 1.0,
		"boost_angle_degrees": 360.0,
		"boost_cooldown": 0.5,
		"boost_heat": 0.0,
		"thruster_drive_demand": 0.0,
		"thruster_allocated_momentum": 0.0,
		"thruster_efficiency_weight": 0.0,
		"move_efficiency_sum": 0.0,
		"boost_efficiency_sum": 0.0,
		"turn_efficiency_sum": 0.0,
		"thruster_momentum": 0.0,
		"boost_momentum": 0.0,
		"boost_total_momentum": 0.0,
		"thruster_duration": 0.0,
		"body_move_speed": 0.0,
		"boost_speed": 0.0,
		"thruster_acceleration": 0.0,
		"brake_power": 0.0,
		"boost_duration": 0.0,
		"thruster_boost_extra_demand": 0.0,
		"thruster_boost_peak_demand": 0.0,
		"thruster_effective_drive_demand": 0.0,
		"thruster_effective_boost_peak_demand": 0.0,
		"engine_drive_chain_ratio": 0.0,
		"engine_boost_chain_ratio": 0.0,
		"turn_speed": 2.4,
		"turn_acceleration": 4.2,
		"turn_damping": 3.2,
		"turn_inertia": 1.0,
		"recoil_cancel": 0.45,
		"engine_weapon_tags": [],
		"engine_team_roles": [],
		"engine_heat_profiles": [],
		"engine_recoil_stability": 1.0,
		"engine_boost_control": 1.0,
		"engine_command_drive": 1.0,
		"engine_supply_load": 1.0,
		"boost_cooling_mult": 1.0,
		"pierce_range_bonus": 0.0,
		"tear_range_bonus": 0.0,
		"manual_cooling": 48.0,
		"cooling_profiles": [],
		"weapon_heat_tags": [],
		"repeat_heat_relief": 0.0,
		"projectile_heat_relief": 0.0,
		"boost_heat_relief": 0.0,
		"laser_heat_relief": 0.0,
		"chemical_heat_relief": 0.0,
		"missile_heat_relief": 0.0,
		"overheat_clear_ratio": 0.42,
		"overheat_shutdown_mult": 1.0,
		"cooling_aura_bonus": 0.0,
		"shape": "core",
		"command": "236",
		"skill_state": "active",
		"sequence": ["normal"],
		"group_count": 1,
		"ai": "direct",
		"source_rules": {},
		"module_sequence_limit": 1,
		"condition_slots": 1,
		"has_soul": false,
		"soul_anchor_torso_unit_index": -1,
		"soul_bonus_active": false,
		"soul_note": "",
		"soul_archetype": "",
		"soul_oath_active": false,
		"soul_oath_reason": "",
		"soul_echo_window": 0.0,
		"soul_echo_recovery_mult": 1.0,
		"soul_echo_heat_relief": 0.0,
		"orbit_radius": 0.45,
		"hold_range": 0.82,
		"flank_width": 0.55,
		"barrier_logic": "pulse",
		"aura_range": 0.58,
		"aura_heat": 0.0,
		"ally_cooling": 0.0,
		"slow_power": 0.0,
		"pulse_interval": 1.25,
		"role_switch": "",
		"switch_cooldown": float(constants.get("identity_switch_cooldown_seconds", 20.0)),
		"identity_receiver_role": "",
		"identity_receiver_order": 0,
		"role_form_target_role": "",
		"role_form_mech_role": "puppet",
		"role_form_shape": "",
		"combine_partner_count": 1,
		"combine_max_partners": 1,
		"combine_shape": "",
		"material_slots": 0,
		"space_size": 0.0,
		"barrier_map_tiles": [],
		"barrier_map_columns": int(constants.get("barrier_map_columns", 10)),
		"barrier_map_rows": int(constants.get("barrier_map_rows", 5)),
		"barrier_map_width": float(constants.get("barrier_blueprint_width", 960.0)),
		"barrier_map_height": float(constants.get("barrier_blueprint_height", 540.0)),
		"barrier_damage_type": "",
		"damage_boost_type": "",
		"damage_boost_mult": 1.0,
		"barrier_disconnected": false,
		"ether_count": 0,
		"ether_bind_radius_m": 0.0,
		"ether_group_link_limit": -1,
		"ether_group_capacity": 1,
		"ether_group_kind": "",
		"ether_effects": [],
		"module_effect": "",
		"module_state": "",
		"fracture_trigger": "",
		"fracture_exception_group": false,
		"fracture_ai": "",
		"module_range": 0.0,
		"module_lane_range": 0.0,
		"module_damage_mult": 1.0,
		"projectile_style": "",
		"projectile_behavior": "",
		"projectile_range": 0.0,
		"projectile_momentum": 0.0,
		"projectile_speed_mult": float(constants.get("bullet_hell_default_speed_mult", 2.8)),
		"travel_path": "",
		"laser_aim_time": float(constants.get("laser_default_aim_seconds", 0.46)),
		"bullet_lock_time": float(constants.get("true_bullet_default_lock_seconds", 1.0)),
		"bullet_lock_radius": float(constants.get("true_bullet_default_lock_radius", 0.22)),
		"chemical_dot_duration": float(constants.get("chemical_dot_default_duration", 2.6)),
		"chemical_dot_mult": float(constants.get("chemical_dot_default_mult", 1.35)),
		"chemical_frontload": float(constants.get("chemical_dot_default_frontload", 0.46)),
		"chemical_pellets": 1,
		"chemical_spread": 0.0,
		"pull_power": 0.0,
		"non_damage": false,
		"web_strength": 0.0,
		"web_break_force": 0.0,
		"web_pull_mode": "",
		"blind_radius": 0.0,
		"blind_duration": 0.0,
		"blind_strength": 0.0,
		"data_security": 1.0,
		"security_note": "",
		"cool_burst": 0.0,
		"cool_lock": 0.0,
		"cool_overheat_clear": false,
		"takeover_on_hit": false,
		"takeover_seconds": 0.0,
		"takeover_power": 1.0,
		"takeover_damage_rate": 0.0,
		"takeover_damage_type": "laser",
		"is_signal_jammer": false,
		"jam_radius": 0.0,
		"jam_seconds": 0.0,
		"jam_power": 1.0,
		"jam_duration": 0.0,
		"jam_affects": "enemy",
		"is_repair_station": false,
		"repair_rate": 0.0,
		"repair_capacity": 0,
		"station_repair_mult": 1.0,
		"retreat_on_defeat": false,
		"retreat_repair_rate": 0.0,
		"repair_time_mult": 1.0,
		"prefer_repair_station": false,
		"is_hatchery": false,
		"hatch_profile": "",
		"hatch_interval": 0.0,
		"hatch_limit": 0,
		"hatch_ai": "",
		"hatch_modifier": "",
		"is_gravity_field": false,
		"gravity_force": 0.0,
		"gravity_direction": "",
		"gravity_radius": 0.0,
		"is_coolant_field": false,
		"coolant_radius": 0.0,
		"coolant_boost": 0.0,
		"coolant_affects": "ally",
		"is_heat_field": false,
		"heat_field_radius": 0.0,
		"heat_field_rate": 0.0,
		"heat_field_affects": "all",
		"is_repulsion_field": false,
		"repulsion_radius": 0.0,
		"repulsion_force": 0.0,
		"is_hack_field": false,
		"hack_radius": 0.0,
		"hack_seconds": 0.0,
		"hack_power": 1.0,
		"is_trap_field": false,
		"trap_radius": 0.0,
		"trap_effect": "",
		"trap_command": "",
		"trap_cooldown": 0.0,
		"trap_power": 0.0,
		"trap_damage": 0,
		"trap_damage_type": "",
		"trap_slow_duration": 0.0,
		"trap_affects": "enemy",
		"trap_direction_mode": "input",
		"trap_link": "",
		"lease_rate": 0.0,
		"lease_heat_penalty": 0.0,
		"reflect_projectiles": false,
		"reflect_types": [],
		"reflect_power": 0.0,
		"reflect_bonus_range": 0.0,
		"reflect_affects": "ally",
		"shield_duration": 0.0,
		"control_pages": [],
		"can_control_traps": false,
		"is_barrage_emitter": false,
		"barrage_mode": "",
		"barrage_interval": 0.0,
		"barrage_damage": 0,
		"barrage_damage_type": "bullet",
		"barrage_range": 0.0,
		"barrage_lane_range": 0.0,
		"barrage_heat": 0.0,
		"barrage_style": "",
		"barrage_spin_rate": 1.0,
		"barrage_affects": "enemy",
		"explosion_radius": 0.0,
		"explosion_damage": 0,
		"explosion_damage_type": "",
		"explosion_style": "",
		"entry_breach_damage": 0,
		"entry_breach_damage_type": "blunt",
		"entry_breach_self_heat": 0.0,
		"has_escape_pod": false,
		"escape_speed": 0.0,
		"escape_module_slots": 0,
		"escape_target_ring_delta": 2.8,
		"escape_target_lane": 0.0,
		"bounty_reward": 0,
		"insured_refund": 0,
		"annuity_rate": 0.0,
		"entry_grant": 0,
		"owner_destroy_penalty": 0,
		"is_cage_wall": false,
		"cage_radius": 0.0,
		"cage_damage": 0,
		"cage_damage_type": "blunt",
		"cage_repel": 0.0,
		"cage_hit_interval": 0.6,
		"cage_affects": "enemy",
		"cage_shape": "",
		"is_homing_launcher": false,
		"homing_radius": 0.0,
		"homing_interval": 0.0,
		"homing_accuracy": 0.0,
		"homing_damage": 0,
		"homing_damage_type": "bullet",
		"homing_heat": 0.0,
		"homing_knock": 0.08,
		"homing_affects": "enemy",
		"manufacturer_counts": manufacturer_counts,
		"manufacturer_locked": String(context.get("manufacturer_locked", "")),
		"manufacturer_note": "",
		"suicide_on_hit": false,
		"vuln_kind": "",
		"vuln_mult": 1.0,
		"vuln_duration": 0.0,
		"blast_radius": 0.0,
		"ball_puppet": false,
		"ball_hit_damage": 0,
		"racket_power": 0.0,
		"racket_lane_lift": 0.0,
		"serve_range": 0.0,
		"combine_range": 0.0,
		"combine_bonus_hp": 0,
		"is_resource_siphon": false,
		"siphon_radius": 0.0,
		"siphon_rate": 0.0,
		"is_support_node": false,
		"support_kind": "",
		"support_radius": 0.0,
		"support_rate": 0.0,
		"support_amount": 0,
		"support_refill_seconds": 1.0,
		"support_ammo_type": "",
		"support_buff_type": "",
		"support_buff_mult": 1.0,
		"support_duration": 0.0,
		"support_affects": "ally",
		"support_field_shape": "circle",
		"is_support_platform": false,
		"platform_pair_range": 0.0,
		"platform_width": 0.0,
		"platform_armor_hp": 0.0,
		"is_speed_lane": false,
		"speed_lane_radius": 0.0,
		"speed_lane_width": 0.0,
		"speed_lane_mult": 1.0,
		"speed_lane_pull": 0.0,
		"speed_lane_affects": "all",
		"speed_lane_bidirectional": true,
		"speed_field_shape": "rectangle",
		"is_coin_generator": false,
		"coin_interval": 0.0,
		"coin_value": 0,
		"coin_ttl": 0.0,
		"coin_spawn_radius": 0.0,
		"coin_pickup_radius": 0.0,
		"is_one_way_shield": false,
		"shield_radius": 0.0,
		"shield_lane_width": 0.0,
		"shield_pass_mode": "directional",
		"shield_pass_direction": "facing",
		"shield_block_damage_mult": 1.0,
		"shield_affects": "enemy",
		"pirate_discount": 0.0,
		"betrayal_chance": 0.0,
		"morph_modes": [],
		"morph_cooldown": 0.0,
		"charge_time": 0.0,
		"focus_cost": 0.0,
		"receiver": false,
		"size_class": "standard",
		"deploy_cost": 0,
		"primary_color": context.get("primary_color", Color.WHITE),
		"accent_color": context.get("accent_color", Color.WHITE),
		"torso_visual_shape": "core",
		"torso_visual_material": "metal",
	}


func copy_part_logic_stats(stats: Dictionary, part: Dictionary, context: Dictionary) -> Dictionary:
	var puppet_only_inactive := bool(context.get("puppet_only_inactive", false))
	var part_is_torso := bool(context.get("part_is_torso", false))
	var part_kind := String(context.get("part_kind", ""))
	if not puppet_only_inactive:
		for logic_key in PART_LOGIC_COPY_KEYS:
			if part_is_torso and logic_key in TORSO_BLOCKED_PART_LOGIC_KEYS:
				continue
			if part_kind == "ether" and logic_key in ETHER_BLOCKED_PART_LOGIC_KEYS:
				continue
			if part.has(logic_key):
				stats[logic_key] = part[logic_key]
	for fracture_key in FRACTURE_COPY_KEYS:
		if part.has(fracture_key):
			stats[fracture_key] = part[fracture_key]
	for support_key in SUPPORT_COPY_KEYS:
		if part.has(support_key):
			stats[support_key] = part[support_key]
	return stats


func copy_part_combat_stats(stats: Dictionary, part: Dictionary, context: Dictionary) -> Dictionary:
	var part_is_torso := bool(context.get("part_is_torso", false))
	if not part_is_torso:
		if part.has("normal_heat"):
			stats["normal_heat"] = float(part["normal_heat"])
		if part.has("armor_heat"):
			stats["armor_heat"] = float(part["armor_heat"])
		if part.has("active_heat"):
			stats["active_heat"] = float(part["active_heat"])
		if part.has("projectile"):
			stats["projectile"] = bool(part["projectile"])
		if part.has("projectile_damage_type"):
			stats["projectile_damage_type"] = String(part["projectile_damage_type"])
		if part.has("projectile_style"):
			stats["projectile_style"] = String(part["projectile_style"])
		if part.has("projectile_behavior"):
			stats["projectile_behavior"] = String(part["projectile_behavior"])
		if part.has("projectile_range"):
			stats["projectile_range"] = float(part["projectile_range"])
		if part.has("projectile_momentum"):
			stats["projectile_momentum"] = maxf(float(stats.get("projectile_momentum", 0.0)), float(part["projectile_momentum"]))
		if part.has("projectile_mass"):
			stats["projectile_mass"] = maxf(float(stats.get("projectile_mass", 0.0)), float(part["projectile_mass"]))
		if part.has("projectile_collision_speed"):
			stats["projectile_collision_speed"] = maxf(float(stats.get("projectile_collision_speed", 0.0)), float(part["projectile_collision_speed"]))
		if part.has("projectile_speed_mult"):
			stats["projectile_speed_mult"] = float(part["projectile_speed_mult"])
		for missile_key in MISSILE_COPY_KEYS:
			if part.has(missile_key):
				stats[missile_key] = part[missile_key]
		if part.has("travel_path"):
			stats["travel_path"] = String(part["travel_path"])
		if part.has("laser_aim_time"):
			stats["laser_aim_time"] = float(part["laser_aim_time"])
		if part.has("bullet_lock_time"):
			stats["bullet_lock_time"] = float(part["bullet_lock_time"])
		if part.has("bullet_lock_radius"):
			stats["bullet_lock_radius"] = float(part["bullet_lock_radius"])
		if part.has("damage_type"):
			stats["damage_type"] = String(part["damage_type"])
	if part.has("data_security"):
		var security_value := float(part["data_security"])
		if bool(part.get("is_torso", false)) or String(part.get("material_class", "")) == "torso":
			stats["data_security"] = maxf(float(stats.get("data_security", 1.0)), security_value) if security_value >= 1.0 else minf(float(stats.get("data_security", 1.0)), clampf(security_value, 0.25, 1.0))
		else:
			stats["data_security"] = float(stats.get("data_security", 1.0)) + security_value
	if part.has("takeover_power"):
		var intrusion_value := float(part["takeover_power"])
		stats["takeover_power"] = maxf(float(stats.get("takeover_power", 1.0)), intrusion_value) if intrusion_value >= 1.0 else float(stats.get("takeover_power", 1.0)) + intrusion_value
	if part.has("size_class"):
		stats["size_class"] = String(part["size_class"])
	return stats


func copy_part_payload_stats(stats: Dictionary, part: Dictionary, context: Dictionary) -> Dictionary:
	var part_is_torso := bool(context.get("part_is_torso", false))
	if part.has("ammo_capacity"):
		_merge_ammo_capacity(stats, part.get("ammo_capacity", {}), float(context.get("ammo_scale", 1.0)), context)
	if bool(part.get("electronic_armor", false)):
		_merge_electronic_armor_stats(stats, part, float(context.get("shield_scale", 1.0)))
	if part.has("material_class"):
		stats["material_class"] = String(part["material_class"])
	if part.has("connection_ends"):
		stats["connection_ends"] = maxi(int(stats.get("connection_ends", 0)), int(part["connection_ends"]))
	if part_is_torso:
		stats["module_slots"] = maxi(int(stats.get("module_slots", 0)), int(context.get("torso_module_slots", part.get("module_slots", 0))))
		stats["torso_slots"] = maxi(int(stats.get("torso_slots", 0)), int(context.get("torso_plugin_slots", part.get("torso_slots", 0))))
	for capacity_key in ["joint_ports", "weapon_bays", "engine_slots", "booster_slots", "cooling_slots", "module_slots", "torso_slots", "spare_weapon_slots"]:
		if not part.has(capacity_key):
			continue
		var capacity_value := int(part[capacity_key])
		if part_is_torso and capacity_key == "module_slots":
			capacity_value = int(context.get("torso_module_slots", capacity_value))
		elif part_is_torso and capacity_key == "torso_slots":
			capacity_value = int(context.get("torso_plugin_slots", capacity_value))
		stats[capacity_key] = maxi(int(stats.get(capacity_key, 0)), capacity_value)
	if part.has("torso_slot_mass_limit"):
		stats["torso_slot_mass_limit"] = maxf(float(stats.get("torso_slot_mass_limit", 0.0)), float(part["torso_slot_mass_limit"]))
		stats["torso_slot_volume_rank_limit"] = maxf(float(stats.get("torso_slot_volume_rank_limit", 0.0)), float(context.get("legacy_mass_limit_volume_rank", 0.0)))
	if part.has("torso_slot_volume_tier"):
		stats["torso_slot_volume_rank_limit"] = maxf(float(stats.get("torso_slot_volume_rank_limit", 0.0)), float(context.get("torso_slot_volume_tier_rank", 0.0)))
	if part.has("spare_weapon_mass_limit"):
		stats["spare_weapon_mass_limit"] = maxf(float(stats.get("spare_weapon_mass_limit", 0.0)), float(part["spare_weapon_mass_limit"]))
	return stats


func apply_torso_payload_direct_stats(stats: Dictionary, part: Dictionary, payload_kind: String, context: Dictionary) -> Dictionary:
	if not (payload_kind in ["ammo", "electronic_armor", "escape_pod", "spare_weapon"]):
		return stats
	stats["cost"] = int(stats.get("cost", 0)) + int(part.get("cost", 0))
	stats["mass"] = float(stats.get("mass", 0.0)) + float(part.get("mass", 0.0))
	match payload_kind:
		"ammo":
			_merge_ammo_capacity(stats, part.get("ammo_capacity", {}), float(context.get("ammo_scale", 1.0)), context)
		"electronic_armor":
			_merge_electronic_armor_stats(stats, part, float(context.get("shield_scale", 1.0)))
		"escape_pod":
			stats["energy"] = float(stats.get("energy", 0.0)) + float(part.get("energy", 0.0))
			stats["has_escape_pod"] = true
			stats["escape_speed"] = maxf(float(stats.get("escape_speed", 0.0)), float(part.get("escape_speed", 0.0)))
			stats["escape_module_slots"] = maxi(int(stats.get("escape_module_slots", 0)), int(part.get("escape_module_slots", 0)))
			stats["escape_target_ring_delta"] = float(part.get("escape_target_ring_delta", stats.get("escape_target_ring_delta", 2.8)))
			stats["escape_target_lane"] = float(part.get("escape_target_lane", stats.get("escape_target_lane", 0.0)))
	return stats


func record_torso_payload_summary_entry(summary: Dictionary, entry: Dictionary) -> Dictionary:
	if bool(entry.get("payload", true)):
		summary["payload_count"] = int(summary.get("payload_count", 0)) + 1
		summary["payload_mass"] = float(summary.get("payload_mass", 0.0)) + float(entry.get("mass", 0.0))
		summary["payload_volume_rank"] = float(summary.get("payload_volume_rank", 0.0)) + float(entry.get("volume_rank", 0.0))
	if bool(entry.get("software", false)):
		summary["software_payload_count"] = int(summary.get("software_payload_count", 0)) + 1
		summary["software_payload_energy"] = float(summary.get("software_payload_energy", 0.0)) + float(entry.get("software_energy", 0.0))
	if bool(entry.get("ammo", false)):
		summary["ammo_count"] = int(summary.get("ammo_count", 0)) + 1
		summary["ammo_mass"] = float(summary.get("ammo_mass", 0.0)) + float(entry.get("mass", 0.0))
	return summary


func payload_slot_key_for_kind(payload_kind: String, fallback_slot: String = "muscle") -> String:
	match payload_kind:
		"engine":
			return "engine"
		"cooling":
			return "cooling"
		"booster":
			return "booster"
		"special":
			return "special"
		"module":
			return "module"
		"ammo", "electronic_armor", "escape_pod", "spare_weapon":
			return "muscle"
	return fallback_slot


func volume_tier_rank(tier: String) -> int:
	match tier.to_upper():
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


func volume_rank_from_value(value: Variant, fallback: int = 3) -> int:
	if value is String:
		var text := String(value).strip_edges()
		if text == "" or text == "-":
			return clampi(fallback, 1, 5)
		return volume_tier_rank(text)
	if value is int:
		return clampi(int(value), 1, 5)
	if value is float:
		return clampi(int(ceilf(float(value))), 1, 5)
	return clampi(fallback, 1, 5)


func torso_payload_processing_plan(payload_kind: String, part: Dictionary, payload: Dictionary = {}, fallback_slot: String = "muscle", context: Dictionary = {}) -> Dictionary:
	var kind := payload_kind.strip_edges()
	if kind == "":
		kind = String(payload.get("kind", "")).strip_edges()
	var explicit_slot := String(payload.get("slot", "")).strip_edges()
	var slot_key := payload_slot_key_for_kind(kind, fallback_slot)
	var summary_entry := {}
	var direct_stats_kind := ""
	var internal_slot_key := ""
	var special_logic := false
	var module_logic := false
	match kind:
		"special":
			summary_entry = {"payload": false, "software": true}
			internal_slot_key = "special"
			special_logic = true
		"module":
			summary_entry = {"payload": false, "software": true}
			internal_slot_key = "module"
			module_logic = true
		"ammo", "electronic_armor", "escape_pod", "spare_weapon":
			summary_entry = {
				"mass": float(part.get("mass", 0.0)),
				"volume_rank": _torso_payload_volume_rank(kind, part, payload, slot_key, context),
			}
			if kind == "ammo":
				summary_entry["ammo"] = true
			direct_stats_kind = kind
		"engine", "booster", "cooling":
			summary_entry = {
				"mass": float(part.get("mass", 0.0)),
				"volume_rank": _torso_payload_volume_rank(kind, part, payload, slot_key, context),
			}
			internal_slot_key = kind
		_:
			if explicit_slot != "":
				slot_key = explicit_slot
				summary_entry = {
					"mass": float(part.get("mass", 0.0)),
					"volume_rank": _torso_payload_volume_rank(kind, part, payload, slot_key, context),
				}
				internal_slot_key = explicit_slot
	return {
		"payload_kind": kind,
		"slot_key": slot_key,
		"summary_entry": summary_entry,
		"direct_stats_kind": direct_stats_kind,
		"internal_slot_key": internal_slot_key,
		"special_logic": special_logic,
		"module_logic": module_logic,
	}


func apply_torso_special_payload_logic_stats(stats: Dictionary, special_part: Dictionary, context: Dictionary) -> Dictionary:
	var special_kind := String(special_part.get("kind", ""))
	var intent := {
		"kind": special_kind,
		"apply_ether": false,
		"apply_soul_heat_capacity": false,
		"apply_soul_bonus": false,
	}
	match special_kind:
		"ether":
			intent["apply_ether"] = true
		"soul":
			stats["has_soul"] = true
			if String(context.get("role_key", "")) == "hero":
				intent["apply_soul_heat_capacity"] = true
				intent["apply_soul_bonus"] = true
		"code":
			stats["group_count"] = maxi(int(stats.get("group_count", 1)), int(special_part.get("group_count", 1)))
			if special_part.has("ai"):
				stats["ai"] = String(special_part["ai"])
	return intent


func apply_soul_heat_capacity_stats(stats: Dictionary, soul_part: Dictionary) -> Dictionary:
	var soul_capacity := maxf(1.0, float(soul_part.get("soul_heat_capacity", 74.0)))
	stats["soul_heat_capacity"] = soul_capacity
	stats["soul_heat_note"] = "%s SOUL %.0f: heat capacity is now supplied by cooling modules" % [
		String(soul_part.get("name", "SOUL")),
		soul_capacity,
	]
	return stats


func apply_internal_payload_base_stats(stats: Dictionary, part: Dictionary, slot_key: String, context: Dictionary = {}) -> Dictionary:
	stats["cost"] = int(stats.get("cost", 0)) + int(part.get("cost", 0))
	stats["mass"] = float(stats.get("mass", 0.0)) + float(part.get("mass", 0.0))
	var payload_power_load := float(context.get("payload_power_load", 0.0))
	stats["energy"] = float(stats.get("energy", 0.0)) + payload_power_load
	stats["power_load"] = float(stats.get("power_load", 0.0)) + payload_power_load
	if slot_key == "cooling":
		stats["cooling_heat_capacity"] = float(stats.get("cooling_heat_capacity", 0.0)) + float(context.get("cooling_heat_capacity", 0.0))
	else:
		var heat_capacity := float(part.get("heat_capacity", 0.0))
		stats["heat_capacity"] = float(stats.get("heat_capacity", 0.0)) + heat_capacity
		stats["hardware_heat_capacity"] = float(stats.get("hardware_heat_capacity", 0.0)) + heat_capacity
	stats["speed_mult"] = float(stats.get("speed_mult", 1.0)) * float(part.get("speed_mult", 1.0))
	if part.has("cornering"):
		stats["cornering"] = maxf(float(stats.get("cornering", 1.0)), float(part["cornering"]))
	if part.has("speed_lane_affinity"):
		stats["speed_lane_affinity"] = float(stats.get("speed_lane_affinity", 0.0)) + float(part["speed_lane_affinity"])
	return stats


func apply_torso_module_payload_logic_stats(stats: Dictionary, module_part: Dictionary) -> Dictionary:
	for logic_key in TORSO_MODULE_PAYLOAD_LOGIC_KEYS:
		if module_part.has(logic_key):
			stats[logic_key] = module_part[logic_key]
	return stats


func apply_torso_payload_summary(stats: Dictionary, summary: Dictionary, context: Dictionary) -> Dictionary:
	var payload_count := int(summary.get("payload_count", 0))
	var payload_mass := float(summary.get("payload_mass", 0.0))
	var payload_volume_rank := float(summary.get("payload_volume_rank", 0.0))
	var software_payload_count := int(summary.get("software_payload_count", 0))
	var software_payload_energy := float(summary.get("software_payload_energy", 0.0))
	var ammo_count := int(summary.get("ammo_count", 0))
	var ammo_mass := float(summary.get("ammo_mass", 0.0))
	var counted_ammo_payload_mass := float(stats.get("ammo_payload_mass", 0.0))
	ammo_mass += counted_ammo_payload_mass
	payload_mass += counted_ammo_payload_mass
	stats["slot_payload_count"] = payload_count
	stats["slot_payload_mass"] = payload_mass
	stats["slot_payload_volume_rank"] = payload_volume_rank
	stats["software_payload_count"] = software_payload_count
	stats["software_payload_energy"] = software_payload_energy
	stats["ammo_slot_count"] = ammo_count
	stats["ammo_slot_mass"] = ammo_mass
	var internal_slot_status: Dictionary = Dictionary(context.get("internal_slot_status", {}))
	stats["internal_slot_max_installed_rank"] = int(internal_slot_status.get("max_installed_rank", 0))
	stats["internal_slot_max_empty_rank"] = int(internal_slot_status.get("max_empty_rank", 0))
	var slot_cap := int(stats.get("torso_slots", 0))
	if slot_cap <= 0:
		slot_cap = int(stats.get("engine_slots", 0)) + int(stats.get("cooling_slots", 0)) + int(stats.get("booster_slots", 0)) + int(stats.get("spare_weapon_slots", 0))
	var software_cap := int(stats.get("module_slots", 0))
	var role_key := String(context.get("role_key", ""))
	if role_key == "barrier" and software_cap <= 0:
		software_cap = maxi(software_cap, software_payload_count)
	var installed_rank_label := String(context.get("installed_rank_label", str(stats.get("internal_slot_max_installed_rank", 0))))
	var empty_rank_label := String(context.get("empty_rank_label", str(stats.get("internal_slot_max_empty_rank", 0))))
	var note := "INTERNAL SLOTS %d/%d  SOFTWARE %d/%d  MAX %s / FREE %s  MASS %.0f" % [payload_count, slot_cap, software_payload_count, software_cap, installed_rank_label, empty_rank_label, payload_mass]
	if role_key == "barrier" and slot_cap <= 0:
		note = "BARRIER INTERNAL %d  SOFTWARE %d/%d  MAX %s  MASS %.0f" % [payload_count, software_payload_count, software_cap, installed_rank_label, payload_mass]
	elif slot_cap > 0 and payload_count > slot_cap:
		note = "INVALID: internal plugin slots %d/%d." % [payload_count, slot_cap]
	elif software_payload_count > software_cap:
		note = "INVALID: software slots %d/%d." % [software_payload_count, software_cap]
	elif String(internal_slot_status.get("invalid", "")) != "":
		note = String(internal_slot_status.get("invalid", ""))
	stats["slot_payload_note"] = note
	var ammo_capacity: Dictionary = Dictionary(stats.get("ammo_capacity", {}))
	stats["ammo_note"] = "AMMO B/L/C/X/W %d/%d/%d/%d/%d  AMMO SLOTS %d MASS %.0f" % [
		int(ammo_capacity.get("bullet", 0)),
		int(ammo_capacity.get("laser", 0)),
		int(ammo_capacity.get("chemical", 0)),
		int(ammo_capacity.get("explosive", 0)),
		int(ammo_capacity.get("web", 0)),
		ammo_count,
		ammo_mass,
	]
	return stats


func _merge_ammo_capacity(stats: Dictionary, capacity: Variant, scale: float, context: Dictionary) -> void:
	if not (capacity is Dictionary):
		return
	var ammo_capacity: Dictionary = Dictionary(stats.get("ammo_capacity", {"bullet": 0, "chemical": 0, "laser": 0})).duplicate(true)
	var added_mass := 0.0
	for raw_type in Dictionary(capacity).keys():
		var ammo_type := _normalized_ammo_type(String(raw_type), context)
		if ammo_type == "":
			continue
		var added_count := maxi(0, int(roundf(float(Dictionary(capacity).get(raw_type, 0)) * scale)))
		ammo_capacity[ammo_type] = int(ammo_capacity.get(ammo_type, 0)) + added_count
		added_mass += float(added_count) * _ammo_unit_mass(ammo_type, context)
	stats["ammo_capacity"] = ammo_capacity
	if added_mass > 0.0:
		stats["ammo_payload_mass"] = float(stats.get("ammo_payload_mass", 0.0)) + added_mass
		stats["mass"] = float(stats.get("mass", 0.0)) + added_mass


func _normalized_ammo_type(ammo_type: String, context: Dictionary) -> String:
	var normalized := ammo_type.to_lower()
	if normalized in ["explosion", "missile"]:
		normalized = "explosive"
	elif normalized in ["chemical_splash", "acid"]:
		normalized = "chemical"
	elif normalized in ["silk", "thread"]:
		normalized = "web"
	var ammo_types: Array = Array(context.get("ammo_types", []))
	return normalized if ammo_types.has(normalized) else ""


func _ammo_unit_mass(ammo_type: String, context: Dictionary) -> float:
	var masses: Dictionary = Dictionary(context.get("ammo_unit_mass", {}))
	return float(masses.get(_normalized_ammo_type(ammo_type, context), 0.0))


func _torso_payload_volume_rank(payload_kind: String, part: Dictionary, payload: Dictionary, fallback_slot: String, context: Dictionary) -> float:
	if context.has("volume_rank"):
		return maxf(0.0, float(context.get("volume_rank", 0.0)))
	if payload_kind == "ammo":
		return float(volume_rank_from_value(payload.get("ammo_size_tier", part.get("ammo_size_tier", part.get("slot_volume_tier", "XS"))), 1))
	if part.has("slot_volume_tier"):
		return float(volume_rank_from_value(part.get("slot_volume_tier", "XS"), 1))
	if part.has("size_tier"):
		return float(volume_rank_from_value(part.get("size_tier", "XS"), 1))
	if part.has("size_class"):
		return float(volume_rank_from_value(part.get("size_class", "M"), 3))
	if part.has("ammo_size_tier"):
		return float(volume_rank_from_value(part.get("ammo_size_tier", "XS"), 1))
	return 1.0 if fallback_slot != "" else 0.0


func _merge_electronic_armor_stats(stats: Dictionary, part: Dictionary, scale: float = 1.0) -> void:
	var shield_hp := float(part.get("shield_hp", part.get("electronic_armor_hp", 0.0)))
	var shield_regen := float(part.get("shield_regen", part.get("electronic_armor_regen", 0.0)))
	var shield_coverage := float(part.get("shield_coverage", part.get("electronic_armor_coverage", 0.0)))
	stats["electronic_armor_max"] = float(stats.get("electronic_armor_max", 0.0)) + shield_hp * scale
	stats["electronic_armor_regen"] = float(stats.get("electronic_armor_regen", 0.0)) + shield_regen * scale
	stats["electronic_armor_coverage"] = maxf(float(stats.get("electronic_armor_coverage", 0.0)), shield_coverage * sqrt(maxf(0.0, scale)))
	stats["shield_max"] = float(stats.get("electronic_armor_max", 0.0))
	stats["shield_regen"] = float(stats.get("electronic_armor_regen", 0.0))
	stats["shield_coverage"] = float(stats.get("electronic_armor_coverage", 0.0))


func apply_base_motion_envelope(stats: Dictionary) -> Dictionary:
	var power_surplus: float = maxf(1.0, float(stats.get("usable_power", stats.get("power", 0.0))) - float(stats.get("power_load", stats.get("energy", 0.0))) * 0.18)
	var mass: float = maxf(1.0, float(stats.get("mass", 0.0)))
	var structural_mass: float = maxf(1.0, float(stats.get("structural_mass", mass)))
	stats["speed"] = clampf((0.42 + power_surplus / (mass + 28.0)) * float(stats.get("speed_mult", 1.0)), 0.28, 1.5)
	stats["acceleration"] = clampf(2.0 + power_surplus / (mass + 12.0), 1.4, 5.2)
	stats["drag"] = clampf(2.1 + float(stats.get("cooling", 0.0)) / (mass + 8.0), 1.4, 5.6)
	stats["health"] = maxi(25, int(roundf(float(stats.get("health", 0)) + structural_mass * 1.2)))
	stats["radius"] = clampf(float(stats.get("radius", 0.08)), 0.08, 3.2)
	stats["length"] = clampf(float(stats.get("length", 0.14)), 0.14, 4.5)
	var radius_drag: float = 1.0 + maxf(0.0, float(stats["radius"]) - 0.58) * 0.42
	var tiny_lift: float = 1.0 + clampf(0.2 - float(stats["radius"]), 0.0, 0.12) * 1.4
	stats["speed"] = clampf(float(stats["speed"]) * tiny_lift / radius_drag, 0.12, 1.72)
	stats["acceleration"] = clampf(float(stats["acceleration"]) * tiny_lift / (1.0 + maxf(0.0, float(stats["radius"]) - 0.58) * 0.34), 0.42, 5.6)
	stats["drag"] = clampf(float(stats["drag"]) + maxf(0.0, float(stats["radius"]) - 0.72) * 0.38, 0.9, 6.8)
	stats["move_heat"] = 0.0
	stats["normal_lane_range"] = float(stats.get("normal_lane_range", 0.0)) + maxf(0.0, float(stats["radius"]) - 0.3) * 0.16
	stats["armor_lane_range"] = float(stats.get("armor_lane_range", 0.0)) + maxf(0.0, float(stats["radius"]) - 0.3) * 0.12
	stats["active_lane_range"] = float(stats.get("active_lane_range", 0.0)) + maxf(0.0, float(stats["radius"]) - 0.3) * 0.2
	return stats


func apply_role_deploy_profile(stats: Dictionary, role_key: String) -> Dictionary:
	if role_key == "hero":
		stats["deploy_cost"] = int(ceilf(float(stats.get("cost", 0)) * 0.72))
		stats["health"] = int(stats.get("health", 0)) + 35
		stats["speed"] = float(stats.get("speed", 0.0)) + 0.08
	elif role_key == "puppet":
		var pirate_discount: float = clampf(float(stats.get("pirate_discount", 0.0)), 0.0, 0.45)
		if pirate_discount > 0.0:
			stats["raw_cost"] = int(stats.get("cost", 0))
			stats["cost"] = maxi(1, int(roundf(float(stats.get("cost", 0)) * (1.0 - pirate_discount))))
			stats["pirate_note"] = "BOOTLEG %.0f%% OFF / %.0f%% BETRAY" % [pirate_discount * 100.0, float(stats.get("betrayal_chance", 0.0)) * 100.0]
		stats["deploy_cost"] = int(ceilf(float(stats.get("cost", 0)) * 0.48))
		stats["health"] = int(roundf(float(stats.get("health", 0)) * 0.58))
		stats["speed"] = float(stats.get("speed", 0.0)) + 0.12
		stats["group_count"] = clampi(int(stats.get("group_count", 1)), 1, 11)
		if String(stats.get("ai", "")) == "drone_cloud":
			stats["radius"] = clampf(float(stats.get("radius", 0.0)) * 0.72, 0.035, 0.32)
			stats["health"] = maxi(8, int(roundf(float(stats.get("health", 0)) * 0.42)))
			stats["speed"] = float(stats.get("speed", 0.0)) + 0.32
			stats["deploy_cost"] = int(ceilf(float(stats.get("cost", 0)) * 0.34))
	else:
		stats["deploy_cost"] = int(ceilf(float(stats.get("cost", 0)) * 0.55))
		stats["health"] = int(roundf(float(stats.get("health", 0)) * 1.35))
		stats["speed"] = 0.0
		stats["normal_damage"] = 0
		stats["armor_damage"] = 0
		stats["active_damage"] = maxi(4, int(roundf(float(stats.get("active_damage", 0)) * 0.6)))
		stats["active_cooldown"] = 1.2
		stats["active_heat"] = 28.0
		stats["active_lane_range"] = 0.64
	return stats


func apply_manufacturer_discount(stats: Dictionary, manufacturer_discount: float) -> Dictionary:
	if manufacturer_discount > 0.0:
		stats["manufacturer_discount"] = manufacturer_discount
		stats["raw_cost_before_maker"] = int(stats.get("cost", 0))
		stats["cost"] = maxi(1, int(roundf(float(stats.get("cost", 0)) * (1.0 - manufacturer_discount))))
		stats["deploy_cost"] = maxi(1, int(roundf(float(stats.get("deploy_cost", 0)) * (1.0 - manufacturer_discount))))
	return stats
