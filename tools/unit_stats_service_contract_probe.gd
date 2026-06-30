extends SceneTree

const UnitStatsService := preload("res://scripts/services/unit_stats_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _near(actual: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(actual - expected) <= tolerance


func _assert_near(actual: float, expected: float, label: String) -> void:
	if not _near(actual, expected):
		_fail("%s expected %.4f got %.4f" % [label, expected, actual])


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/unit_stats_service.gd")
	if service_source.is_empty():
		_fail("Unable to read UnitStatsService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "Control.new", "Label", "ColorRect", "active_units", "all_units", "_compute_unit_stats", "queue_free", "take_hit"]:
		if service_source.contains(forbidden):
			_fail("UnitStatsService contains forbidden token: %s" % forbidden)
			return
	var service := UnitStatsService.new()
	var manufacturer_counts := {"SYNTAX ELEVEN": 2}
	var base_constants := {
		"deploy_wait_seconds": 4.5,
		"melee_stability_threshold_floor": 31.0,
		"economy_boost_momentum_mult": 2.25,
		"identity_switch_cooldown_seconds": 18.0,
		"barrier_map_columns": 12,
		"barrier_map_rows": 7,
		"barrier_blueprint_width": 980.0,
		"barrier_blueprint_height": 560.0,
		"bullet_hell_default_speed_mult": 3.2,
		"laser_default_aim_seconds": 0.52,
		"true_bullet_default_lock_seconds": 1.4,
		"true_bullet_default_lock_radius": 0.34,
		"chemical_dot_default_duration": 3.1,
		"chemical_dot_default_mult": 1.42,
		"chemical_dot_default_frontload": 0.51,
	}
	var base_stats := service.base_stats({
		"role_key": "hero",
		"unit_index": 3,
		"unit_name": "Probe Frame",
		"manufacturer_counts": manufacturer_counts,
		"manufacturer_locked": "SYNTAX ELEVEN",
		"primary_color": Color(0.1, 0.2, 0.3, 1.0),
		"accent_color": Color(0.8, 0.7, 0.2, 1.0),
		"constants": base_constants,
	})
	manufacturer_counts["SYNTAX ELEVEN"] = 9
	if String(base_stats.get("role", "")) != "hero" or int(base_stats.get("unit_index", -1)) != 3 or String(base_stats.get("name", "")) != "Probe Frame":
		_fail("base_stats should preserve role/index/name context: %s" % str(base_stats))
	if int(Dictionary(base_stats.get("manufacturer_counts", {})).get("SYNTAX ELEVEN", 0)) != 2 or String(base_stats.get("manufacturer_locked", "")) != "SYNTAX ELEVEN":
		_fail("base_stats should duplicate manufacturer metadata: %s" % str(base_stats.get("manufacturer_counts", {})))
	if base_stats.get("primary_color", Color.WHITE) != Color(0.1, 0.2, 0.3, 1.0) or base_stats.get("accent_color", Color.WHITE) != Color(0.8, 0.7, 0.2, 1.0):
		_fail("base_stats should preserve editor colors.")
	_assert_near(float(base_stats.get("deploy_wait", 0.0)), 4.5, "base deploy wait")
	_assert_near(float(base_stats.get("melee_stability_threshold", 0.0)), 31.0, "base melee stability threshold")
	_assert_near(float(base_stats.get("boost_efficiency", 0.0)), 2.25, "base boost efficiency")
	_assert_near(float(base_stats.get("switch_cooldown", 0.0)), 18.0, "base switch cooldown")
	if int(base_stats.get("barrier_map_columns", 0)) != 12 or int(base_stats.get("barrier_map_rows", 0)) != 7:
		_fail("base_stats should preserve barrier map dimensions.")
	_assert_near(float(base_stats.get("barrier_map_width", 0.0)), 980.0, "base barrier width")
	_assert_near(float(base_stats.get("barrier_map_height", 0.0)), 560.0, "base barrier height")
	_assert_near(float(base_stats.get("projectile_speed_mult", 0.0)), 3.2, "base projectile speed mult")
	_assert_near(float(base_stats.get("laser_aim_time", 0.0)), 0.52, "base laser aim time")
	_assert_near(float(base_stats.get("bullet_lock_time", 0.0)), 1.4, "base bullet lock time")
	_assert_near(float(base_stats.get("bullet_lock_radius", 0.0)), 0.34, "base bullet lock radius")
	_assert_near(float(base_stats.get("chemical_dot_duration", 0.0)), 3.1, "base chemical duration")
	_assert_near(float(base_stats.get("chemical_dot_mult", 0.0)), 1.42, "base chemical mult")
	_assert_near(float(base_stats.get("chemical_frontload", 0.0)), 0.51, "base chemical frontload")
	var base_stats_b := service.base_stats({"constants": base_constants})
	var ammo_a: Dictionary = base_stats.get("ammo_capacity", {})
	var ammo_b: Dictionary = base_stats_b.get("ammo_capacity", {})
	ammo_a["bullet"] = 7
	if int(ammo_b.get("bullet", -1)) != 0:
		_fail("base_stats should not share ammo_capacity dictionaries between calls.")
	var segments_a: Array = base_stats.get("torso_stiffness_segments", [])
	var segments_b: Array = base_stats_b.get("torso_stiffness_segments", [])
	segments_a.append({"hp": 3})
	if not segments_b.is_empty():
		_fail("base_stats should not share torso_stiffness_segments arrays between calls.")
	var logic_stats := {"orbit_radius": 0.0, "module_range": 0.0, "fracture_trigger": "", "is_support_node": false, "support_radius": 0.0}
	service.copy_part_logic_stats(logic_stats, {"orbit_radius": 1.25, "module_range": 9.0, "fracture_trigger": "break", "is_support_node": true, "support_radius": 4.0}, {"part_is_torso": false, "part_kind": "weapon", "puppet_only_inactive": false})
	if not _near(float(logic_stats.get("orbit_radius", 0.0)), 1.25) or not _near(float(logic_stats.get("module_range", 0.0)), 9.0):
		_fail("part logic copy should copy ordinary logic fields: %s" % str(logic_stats))
	if String(logic_stats.get("fracture_trigger", "")) != "break" or not bool(logic_stats.get("is_support_node", false)) or not _near(float(logic_stats.get("support_radius", 0.0)), 4.0):
		_fail("part logic copy should copy fracture/support fields: %s" % str(logic_stats))
	var torso_logic_stats := {"orbit_radius": 0.0, "module_range": 0.0, "ball_hit_damage": 0}
	service.copy_part_logic_stats(torso_logic_stats, {"orbit_radius": 2.0, "module_range": 9.0, "ball_hit_damage": 99}, {"part_is_torso": true, "part_kind": "torso", "puppet_only_inactive": false})
	if not _near(float(torso_logic_stats.get("orbit_radius", 0.0)), 2.0) or float(torso_logic_stats.get("module_range", 0.0)) != 0.0 or int(torso_logic_stats.get("ball_hit_damage", 0)) != 0:
		_fail("torso should not inherit attack/projectile logic fields: %s" % str(torso_logic_stats))
	var ether_logic_stats := {"material_slots": 0, "aura_range": 0.0, "barrier_disconnected": false, "role_switch": ""}
	service.copy_part_logic_stats(ether_logic_stats, {"material_slots": 3, "aura_range": 8.0, "barrier_disconnected": true, "role_switch": "puppet"}, {"part_is_torso": false, "part_kind": "ether", "puppet_only_inactive": false})
	if int(ether_logic_stats.get("material_slots", 0)) != 0 or float(ether_logic_stats.get("aura_range", 0.0)) != 0.0 or bool(ether_logic_stats.get("barrier_disconnected", false)) or String(ether_logic_stats.get("role_switch", "")) != "puppet":
		_fail("ether should block structural logic keys but copy normal logic: %s" % str(ether_logic_stats))
	var inactive_logic_stats := {"module_effect": "", "fracture_ai": "", "support_kind": ""}
	service.copy_part_logic_stats(inactive_logic_stats, {"module_effect": "hack", "fracture_ai": "split", "support_kind": "ammo"}, {"part_is_torso": false, "part_kind": "code", "puppet_only_inactive": true})
	if String(inactive_logic_stats.get("module_effect", "")) != "" or String(inactive_logic_stats.get("fracture_ai", "")) != "split" or String(inactive_logic_stats.get("support_kind", "")) != "ammo":
		_fail("puppet-only inactive should suppress logic keys while preserving fracture/support copy: %s" % str(inactive_logic_stats))
	var combat_stats := {"projectile_momentum": 2.0, "projectile_mass": 1.0, "projectile_collision_speed": 3.0, "data_security": 1.0, "takeover_power": 1.0}
	service.copy_part_combat_stats(combat_stats, {"normal_heat": 2.0, "projectile": true, "projectile_style": "beam", "projectile_momentum": 8.0, "projectile_mass": 4.0, "projectile_collision_speed": 12.0, "missile_lock_range": 3.5, "travel_path": "arc", "laser_aim_time": 0.4, "bullet_lock_radius": 0.8, "damage_type": "laser", "data_security": 0.4, "takeover_power": 2.5, "size_class": "light"}, {"part_is_torso": false})
	if not bool(combat_stats.get("projectile", false)) or String(combat_stats.get("projectile_style", "")) != "beam" or String(combat_stats.get("damage_type", "")) != "laser":
		_fail("combat copy should copy non-torso projectile identity: %s" % str(combat_stats))
	if not _near(float(combat_stats.get("projectile_momentum", 0.0)), 8.0) or not _near(float(combat_stats.get("missile_lock_range", 0.0)), 3.5) or not _near(float(combat_stats.get("laser_aim_time", 0.0)), 0.4):
		_fail("combat copy should copy projectile range/lock values: %s" % str(combat_stats))
	if not _near(float(combat_stats.get("data_security", 0.0)), 1.4) or not _near(float(combat_stats.get("takeover_power", 0.0)), 2.5) or String(combat_stats.get("size_class", "")) != "light":
		_fail("combat copy should merge security/takeover/size fields: %s" % str(combat_stats))
	var torso_combat_stats := {"projectile": false, "projectile_momentum": 1.0, "damage_type": "blunt", "data_security": 1.0}
	service.copy_part_combat_stats(torso_combat_stats, {"is_torso": true, "material_class": "torso", "projectile": true, "projectile_momentum": 9.0, "damage_type": "laser", "data_security": 0.5}, {"part_is_torso": true})
	if bool(torso_combat_stats.get("projectile", false)) or not _near(float(torso_combat_stats.get("projectile_momentum", 0.0)), 1.0) or String(torso_combat_stats.get("damage_type", "")) != "blunt":
		_fail("torso combat copy should block weapon/projectile identity: %s" % str(torso_combat_stats))
	if not _near(float(torso_combat_stats.get("data_security", 0.0)), 0.5):
		_fail("torso combat copy should still merge torso data security: %s" % str(torso_combat_stats))
	var payload_stats := {
		"ammo_capacity": {"bullet": 1},
		"mass": 10.0,
		"electronic_armor_max": 2.0,
		"electronic_armor_regen": 0.5,
		"electronic_armor_coverage": 0.2,
		"material_class": "weapon",
		"connection_ends": 1,
		"joint_ports": 1,
		"weapon_bays": 0,
		"engine_slots": 0,
		"booster_slots": 0,
		"cooling_slots": 0,
		"module_slots": 0,
		"torso_slots": 0,
		"spare_weapon_slots": 0,
		"torso_slot_volume_rank_limit": 0.0,
	}
	service.copy_part_payload_stats(payload_stats, {
		"ammo_capacity": {"bullet": 2, "missile": 3},
		"electronic_armor": true,
		"shield_hp": 5.0,
		"shield_regen": 1.0,
		"shield_coverage": 0.8,
		"material_class": "gun",
		"connection_ends": 3,
		"joint_ports": 2,
		"module_slots": 4,
		"torso_slots": 5,
		"torso_slot_mass_limit": 12.0,
		"torso_slot_volume_tier": "L",
		"spare_weapon_mass_limit": 9.0,
	}, {
		"part_is_torso": true,
		"torso_module_slots": 6,
		"torso_plugin_slots": 7,
		"legacy_mass_limit_volume_rank": 2.5,
		"torso_slot_volume_tier_rank": 4.0,
		"ammo_types": ["bullet", "laser", "chemical", "explosive", "web"],
		"ammo_unit_mass": {"bullet": 0.16, "laser": 0.11, "chemical": 0.24, "explosive": 0.42, "web": 0.09},
	})
	var payload_ammo: Dictionary = payload_stats.get("ammo_capacity", {})
	if int(payload_ammo.get("bullet", 0)) != 3 or int(payload_ammo.get("explosive", 0)) != 3:
		_fail("payload copy should merge and normalize ammo capacity: %s" % str(payload_ammo))
	_assert_near(float(payload_stats.get("ammo_payload_mass", 0.0)), 1.58, "payload ammo mass")
	_assert_near(float(payload_stats.get("mass", 0.0)), 11.58, "payload mass with ammo")
	_assert_near(float(payload_stats.get("electronic_armor_max", 0.0)), 7.0, "payload shield max")
	_assert_near(float(payload_stats.get("electronic_armor_regen", 0.0)), 1.5, "payload shield regen")
	_assert_near(float(payload_stats.get("electronic_armor_coverage", 0.0)), 0.8, "payload shield coverage")
	if String(payload_stats.get("material_class", "")) != "gun" or int(payload_stats.get("connection_ends", 0)) != 3:
		_fail("payload copy should preserve material and connection metadata: %s" % str(payload_stats))
	if int(payload_stats.get("module_slots", 0)) != 6 or int(payload_stats.get("torso_slots", 0)) != 7 or int(payload_stats.get("joint_ports", 0)) != 2:
		_fail("payload copy should apply torso capacity context: %s" % str(payload_stats))
	_assert_near(float(payload_stats.get("torso_slot_mass_limit", 0.0)), 12.0, "payload torso slot mass")
	_assert_near(float(payload_stats.get("torso_slot_volume_rank_limit", 0.0)), 4.0, "payload torso slot volume")
	_assert_near(float(payload_stats.get("spare_weapon_mass_limit", 0.0)), 9.0, "payload spare weapon mass")
	var torso_payload_context := {
		"ammo_types": ["bullet", "laser", "chemical", "explosive", "web"],
		"ammo_unit_mass": {"bullet": 0.16, "laser": 0.11, "chemical": 0.24, "explosive": 0.42, "web": 0.09},
	}
	var torso_payload_stats := {
		"cost": 10,
		"mass": 4.0,
		"energy": 1.0,
		"ammo_capacity": {"bullet": 1},
		"ammo_payload_mass": 0.0,
		"electronic_armor_max": 0.0,
		"electronic_armor_regen": 0.0,
		"electronic_armor_coverage": 0.0,
		"shield_max": 0.0,
		"shield_regen": 0.0,
		"shield_coverage": 0.0,
		"has_escape_pod": false,
		"escape_speed": 0.0,
		"escape_module_slots": 0,
		"escape_target_ring_delta": 2.8,
		"escape_target_lane": 0.0,
	}
	service.apply_torso_payload_direct_stats(torso_payload_stats, {"cost": 5, "mass": 2.0, "ammo_capacity": {"missile": 2}}, "ammo", torso_payload_context)
	var torso_ammo: Dictionary = torso_payload_stats.get("ammo_capacity", {})
	if int(torso_payload_stats.get("cost", 0)) != 15 or int(torso_ammo.get("explosive", 0)) != 2:
		_fail("torso ammo payload should merge cost and normalized capacity: %s" % str(torso_payload_stats))
	_assert_near(float(torso_payload_stats.get("ammo_payload_mass", 0.0)), 0.84, "torso ammo payload mass")
	_assert_near(float(torso_payload_stats.get("mass", 0.0)), 6.84, "torso ammo total mass")
	service.apply_torso_payload_direct_stats(torso_payload_stats, {"cost": 7, "mass": 1.5, "shield_hp": 9.0, "shield_regen": 2.0, "shield_coverage": 0.6}, "electronic_armor", torso_payload_context)
	if int(torso_payload_stats.get("cost", 0)) != 22:
		_fail("torso shield payload should merge cost: %s" % str(torso_payload_stats))
	_assert_near(float(torso_payload_stats.get("mass", 0.0)), 8.34, "torso shield total mass")
	_assert_near(float(torso_payload_stats.get("electronic_armor_max", 0.0)), 9.0, "torso shield max")
	_assert_near(float(torso_payload_stats.get("electronic_armor_regen", 0.0)), 2.0, "torso shield regen")
	_assert_near(float(torso_payload_stats.get("electronic_armor_coverage", 0.0)), 0.6, "torso shield coverage")
	service.apply_torso_payload_direct_stats(torso_payload_stats, {"cost": 11, "mass": 3.0, "energy": 4.5, "escape_speed": 8.0, "escape_module_slots": 2, "escape_target_ring_delta": 3.2, "escape_target_lane": -0.25}, "escape_pod", torso_payload_context)
	if int(torso_payload_stats.get("cost", 0)) != 33 or not bool(torso_payload_stats.get("has_escape_pod", false)):
		_fail("torso escape pod should merge cost and escape flag: %s" % str(torso_payload_stats))
	_assert_near(float(torso_payload_stats.get("mass", 0.0)), 11.34, "torso escape total mass")
	_assert_near(float(torso_payload_stats.get("energy", 0.0)), 5.5, "torso escape energy")
	_assert_near(float(torso_payload_stats.get("escape_speed", 0.0)), 8.0, "torso escape speed")
	if int(torso_payload_stats.get("escape_module_slots", 0)) != 2:
		_fail("torso escape module slots mismatch: %s" % str(torso_payload_stats))
	_assert_near(float(torso_payload_stats.get("escape_target_ring_delta", 0.0)), 3.2, "torso escape ring target")
	_assert_near(float(torso_payload_stats.get("escape_target_lane", 0.0)), -0.25, "torso escape lane target")
	service.apply_torso_payload_direct_stats(torso_payload_stats, {"cost": 13, "mass": 4.25}, "spare_weapon", torso_payload_context)
	if int(torso_payload_stats.get("cost", 0)) != 46:
		_fail("torso spare payload should merge cost: %s" % str(torso_payload_stats))
	_assert_near(float(torso_payload_stats.get("mass", 0.0)), 15.59, "torso spare total mass")
	if not service.has_method("record_torso_payload_summary_entry"):
		_fail("UnitStatsService missing record_torso_payload_summary_entry.")
		return
	var entry_summary := {}
	service.record_torso_payload_summary_entry(entry_summary, {"mass": 3.5, "volume_rank": 2.25})
	service.record_torso_payload_summary_entry(entry_summary, {"mass": 2.0, "volume_rank": 1.5, "ammo": true})
	service.record_torso_payload_summary_entry(entry_summary, {"payload": false, "software": true, "software_energy": 1.25})
	if int(entry_summary.get("payload_count", 0)) != 2:
		_fail("payload entry summary count mismatch: %s" % str(entry_summary))
	_assert_near(float(entry_summary.get("payload_mass", 0.0)), 5.5, "entry summary payload mass")
	_assert_near(float(entry_summary.get("payload_volume_rank", 0.0)), 3.75, "entry summary payload volume")
	if int(entry_summary.get("ammo_count", 0)) != 1:
		_fail("payload entry summary ammo count mismatch: %s" % str(entry_summary))
	_assert_near(float(entry_summary.get("ammo_mass", 0.0)), 2.0, "entry summary ammo mass")
	if int(entry_summary.get("software_payload_count", 0)) != 1:
		_fail("payload entry summary software count mismatch: %s" % str(entry_summary))
	_assert_near(float(entry_summary.get("software_payload_energy", 0.0)), 1.25, "entry summary software energy")
	if not service.has_method("torso_payload_processing_plan"):
		_fail("UnitStatsService missing torso_payload_processing_plan.")
		return
	var ammo_plan: Dictionary = service.torso_payload_processing_plan("ammo", {
		"name": "Probe Ammo",
		"mass": 2.0,
		"ammo_slot_payload": true,
		"slot_volume_tier": "S",
	}, {"kind": "ammo", "ammo_size_tier": "L"}, "muscle", {"volume_rank": 4.0})
	var ammo_summary: Dictionary = Dictionary(ammo_plan.get("summary_entry", {}))
	if String(ammo_plan.get("direct_stats_kind", "")) != "ammo" or String(ammo_plan.get("internal_slot_key", "")) != "":
		_fail("ammo payload plan route mismatch: %s" % str(ammo_plan))
	if not bool(ammo_summary.get("ammo", false)) or int(ammo_summary.get("payload_count", 0)) != 0:
		_fail("ammo payload summary should mark ammo without pre-counting: %s" % str(ammo_summary))
	_assert_near(float(ammo_summary.get("mass", 0.0)), 2.0, "ammo payload plan mass")
	_assert_near(float(ammo_summary.get("volume_rank", 0.0)), 4.0, "ammo payload plan volume")
	var special_plan: Dictionary = service.torso_payload_processing_plan("special", {"kind": "soul", "mass": 0.0}, {"kind": "special"}, "special")
	var special_summary: Dictionary = Dictionary(special_plan.get("summary_entry", {}))
	if not bool(special_summary.get("software", false)) or bool(special_summary.get("payload", true)) or String(special_plan.get("internal_slot_key", "")) != "special" or not bool(special_plan.get("special_logic", false)):
		_fail("special payload plan mismatch: %s" % str(special_plan))
	var booster_plan: Dictionary = service.torso_payload_processing_plan("booster", {
		"name": "Probe Booster",
		"mass": 5.5,
		"slot_volume_tier": "M",
	}, {"kind": "booster"}, "booster", {"volume_rank": 3.25})
	var booster_summary: Dictionary = Dictionary(booster_plan.get("summary_entry", {}))
	if String(booster_plan.get("direct_stats_kind", "")) != "" or String(booster_plan.get("internal_slot_key", "")) != "booster":
		_fail("booster payload plan route mismatch: %s" % str(booster_plan))
	_assert_near(float(booster_summary.get("mass", 0.0)), 5.5, "booster payload plan mass")
	_assert_near(float(booster_summary.get("volume_rank", 0.0)), 3.25, "booster payload plan precomputed volume")
	var generic_plan: Dictionary = service.torso_payload_processing_plan("custom_plugin", {"mass": 1.25, "slot_volume_tier": "XS"}, {"kind": "custom_plugin", "slot": "joint"}, "joint")
	if String(generic_plan.get("internal_slot_key", "")) != "joint" or String(generic_plan.get("slot_key", "")) != "joint":
		_fail("generic payload plan should route through explicit slot: %s" % str(generic_plan))
	if not service.has_method("apply_torso_special_payload_logic_stats"):
		_fail("UnitStatsService missing apply_torso_special_payload_logic_stats.")
		return
	var special_logic_stats := {
		"group_count": 1,
		"ai": "",
		"has_soul": false,
	}
	var ether_intent: Dictionary = service.apply_torso_special_payload_logic_stats(special_logic_stats, {"kind": "ether"}, {"role_key": "hero"})
	if not bool(ether_intent.get("apply_ether", false)) or bool(ether_intent.get("apply_soul_bonus", false)):
		_fail("ether payload special intent mismatch: %s" % str(ether_intent))
	var soul_intent: Dictionary = service.apply_torso_special_payload_logic_stats(special_logic_stats, {"kind": "soul"}, {"role_key": "hero"})
	if not bool(special_logic_stats.get("has_soul", false)) or not bool(soul_intent.get("apply_soul_heat_capacity", false)) or not bool(soul_intent.get("apply_soul_bonus", false)):
		_fail("hero soul payload special intent mismatch: stats=%s intent=%s" % [str(special_logic_stats), str(soul_intent)])
	var puppet_soul_intent: Dictionary = service.apply_torso_special_payload_logic_stats(special_logic_stats, {"kind": "soul"}, {"role_key": "puppet"})
	if bool(puppet_soul_intent.get("apply_soul_heat_capacity", false)) or bool(puppet_soul_intent.get("apply_soul_bonus", false)):
		_fail("non-hero soul payload should not request hero soul callbacks: %s" % str(puppet_soul_intent))
	var code_intent: Dictionary = service.apply_torso_special_payload_logic_stats(special_logic_stats, {"kind": "code", "group_count": 4, "ai": "ranged_pack"}, {"role_key": "hero"})
	if int(special_logic_stats.get("group_count", 0)) != 4 or String(special_logic_stats.get("ai", "")) != "ranged_pack":
		_fail("code payload special stats mismatch: %s" % str(special_logic_stats))
	if bool(code_intent.get("apply_ether", false)) or bool(code_intent.get("apply_soul_bonus", false)):
		_fail("code payload should not request special callbacks: %s" % str(code_intent))
	if not service.has_method("apply_soul_heat_capacity_stats"):
		_fail("UnitStatsService missing apply_soul_heat_capacity_stats.")
		return
	var soul_heat_stats := {}
	service.apply_soul_heat_capacity_stats(soul_heat_stats, {"name": "SOUL: TEST", "soul_heat_capacity": 88.0})
	if int(soul_heat_stats.get("soul_heat_capacity", 0)) != 88:
		_fail("soul heat capacity stat mismatch: %s" % str(soul_heat_stats))
	if String(soul_heat_stats.get("soul_heat_note", "")) != "SOUL: TEST SOUL 88: heat capacity is now supplied by cooling modules":
		_fail("soul heat note mismatch: %s" % str(soul_heat_stats))
	var minimum_soul_heat_stats := {}
	service.apply_soul_heat_capacity_stats(minimum_soul_heat_stats, {"name": "SOUL: LOW", "soul_heat_capacity": -5.0})
	if int(minimum_soul_heat_stats.get("soul_heat_capacity", 0)) != 1:
		_fail("soul heat capacity should clamp to minimum one: %s" % str(minimum_soul_heat_stats))
	for method_name in ["payload_slot_key_for_kind", "volume_tier_rank", "volume_rank_from_value"]:
		if not service.has_method(method_name):
			_fail("UnitStatsService missing %s." % method_name)
			return
	if String(service.payload_slot_key_for_kind("engine", "muscle")) != "engine" or String(service.payload_slot_key_for_kind("electronic_armor", "limb_muscle")) != "muscle":
		_fail("payload slot-key mapping mismatch.")
	if String(service.payload_slot_key_for_kind("unknown_payload", "custom_slot")) != "custom_slot":
		_fail("payload slot-key fallback mismatch.")
	if int(service.volume_tier_rank("XS")) != 1 or int(service.volume_tier_rank("XL")) != 5 or int(service.volume_tier_rank("???")) != 3:
		_fail("volume tier rank mismatch.")
	if int(service.volume_rank_from_value("", 4)) != 4 or int(service.volume_rank_from_value("-", 2)) != 2:
		_fail("blank volume rank fallback mismatch.")
	if int(service.volume_rank_from_value("L", 1)) != 4 or int(service.volume_rank_from_value(2, 1)) != 2 or int(service.volume_rank_from_value(2.2, 1)) != 3:
		_fail("volume rank value normalization mismatch.")
	if int(service.volume_rank_from_value(12.0, 1)) != 5 or int(service.volume_rank_from_value(-4, 3)) != 1:
		_fail("volume rank clamp mismatch.")
	if not service.has_method("part_slot_volume_rank"):
		_fail("UnitStatsService missing part_slot_volume_rank.")
		return
	_assert_near(float(service.part_slot_volume_rank({"slot_volume_tier": "XL"}, "engine")), 5.0, "explicit slot volume rank")
	_assert_near(float(service.part_slot_volume_rank({"electronic_armor": true, "shield_hp": 220.0, "shield_coverage": 0.2, "mass": 4.0}, "muscle")), 4.0, "shield payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"engine_momentum_output": 84.0, "mass": 4.0}, "engine")), 4.0, "engine output volume rank")
	_assert_near(float(service.part_slot_volume_rank({"cooling": 38.0, "mass": 3.0}, "cooling")), 4.0, "cooling payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"mass": 5.0}, "booster", {"booster_boost_momentum": 361.0})), 4.0, "booster payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"radius": 0.16, "length": 0.4, "mass": 3.0}, "muscle", {"size_tier_rank": 1.0})), 3.0, "footprint payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"radius": 0.16, "length": 0.4, "mass": 3.0}, "limb_muscle", {"size_tier_rank": 1.0})), 2.0, "limb footprint volume rank")
	if not service.has_method("apply_internal_payload_base_stats"):
		_fail("UnitStatsService missing apply_internal_payload_base_stats.")
		return
	var internal_payload_stats := {
		"cost": 10,
		"mass": 2.5,
		"energy": 1.0,
		"power_load": 3.0,
		"heat_capacity": 4.0,
		"hardware_heat_capacity": 2.0,
		"cooling_heat_capacity": 5.0,
		"speed_mult": 1.2,
		"cornering": 1.1,
		"speed_lane_affinity": 0.5,
	}
	service.apply_internal_payload_base_stats(internal_payload_stats, {
		"cost": 7,
		"mass": 1.5,
		"heat_capacity": 9.0,
		"speed_mult": 0.8,
		"cornering": 1.4,
		"speed_lane_affinity": 0.25,
	}, "engine", {"payload_power_load": 0.75})
	if int(internal_payload_stats.get("cost", 0)) != 17:
		_fail("internal payload base cost mismatch: %s" % str(internal_payload_stats))
	_assert_near(float(internal_payload_stats.get("mass", 0.0)), 4.0, "internal payload base mass")
	_assert_near(float(internal_payload_stats.get("energy", 0.0)), 1.75, "internal payload energy")
	_assert_near(float(internal_payload_stats.get("power_load", 0.0)), 3.75, "internal payload power load")
	_assert_near(float(internal_payload_stats.get("heat_capacity", 0.0)), 13.0, "internal payload heat capacity")
	_assert_near(float(internal_payload_stats.get("hardware_heat_capacity", 0.0)), 11.0, "internal payload hardware heat")
	_assert_near(float(internal_payload_stats.get("speed_mult", 0.0)), 0.96, "internal payload speed mult")
	_assert_near(float(internal_payload_stats.get("cornering", 0.0)), 1.4, "internal payload cornering")
	_assert_near(float(internal_payload_stats.get("speed_lane_affinity", 0.0)), 0.75, "internal payload lane affinity")
	var cooling_payload_stats := {
		"cost": 4,
		"mass": 1.0,
		"heat_capacity": 10.0,
		"hardware_heat_capacity": 6.0,
		"cooling_heat_capacity": 2.0,
		"speed_mult": 1.0,
	}
	service.apply_internal_payload_base_stats(cooling_payload_stats, {"cost": 3, "mass": 2.0, "heat_capacity": 99.0, "speed_mult": 1.1}, "cooling", {"cooling_heat_capacity": 12.5})
	if int(cooling_payload_stats.get("cost", 0)) != 7:
		_fail("cooling payload base cost mismatch: %s" % str(cooling_payload_stats))
	_assert_near(float(cooling_payload_stats.get("mass", 0.0)), 3.0, "cooling payload mass")
	_assert_near(float(cooling_payload_stats.get("heat_capacity", 0.0)), 10.0, "cooling should not add hardware heat")
	_assert_near(float(cooling_payload_stats.get("hardware_heat_capacity", 0.0)), 6.0, "cooling should not add hardware heat capacity")
	_assert_near(float(cooling_payload_stats.get("cooling_heat_capacity", 0.0)), 14.5, "cooling payload heat capacity")
	_assert_near(float(cooling_payload_stats.get("speed_mult", 0.0)), 1.1, "cooling payload speed mult")
	if not service.has_method("apply_torso_module_payload_logic_stats"):
		_fail("UnitStatsService missing apply_torso_module_payload_logic_stats.")
		return
	var module_logic_stats := {
		"command": "",
		"skill_state": "",
		"motion": "",
		"aim_mode": "",
		"module_effect": "",
		"module_state": "",
		"role_switch": "",
		"switch_cooldown": 0,
		"fracture_trigger": "",
		"fracture_exception_group": "",
		"fracture_ai": "",
		"morph_modes": [],
		"morph_cooldown": 0,
		"combine_range": 0.0,
		"combine_bonus_hp": 0,
		"identity_receiver_role": "",
		"identity_receiver_order": 0,
	}
	service.apply_torso_module_payload_logic_stats(module_logic_stats, {
		"command": "switch",
		"skill_state": "armed",
		"motion": "sweep",
		"aim_mode": "auto",
		"module_effect": "burst",
		"module_state": "locked",
		"role_switch": "puppet",
		"switch_cooldown": 12,
		"fracture_trigger": "shell",
		"fracture_exception_group": "A",
		"fracture_ai": "split",
		"morph_modes": ["alpha", "beta"],
		"morph_cooldown": 6,
		"combine_range": 3.5,
		"combine_bonus_hp": 18,
		"identity_receiver_role": "hero",
		"identity_receiver_order": 2,
	})
	if String(module_logic_stats.get("command", "")) != "switch" or String(module_logic_stats.get("skill_state", "")) != "armed" or String(module_logic_stats.get("motion", "")) != "sweep":
		_fail("module payload logic copy mismatch: %s" % str(module_logic_stats))
	if String(module_logic_stats.get("module_effect", "")) != "burst" or String(module_logic_stats.get("module_state", "")) != "locked" or String(module_logic_stats.get("role_switch", "")) != "puppet":
		_fail("module payload module-state copy mismatch: %s" % str(module_logic_stats))
	if int(module_logic_stats.get("switch_cooldown", 0)) != 12 or String(module_logic_stats.get("fracture_trigger", "")) != "shell" or String(module_logic_stats.get("fracture_exception_group", "")) != "A" or String(module_logic_stats.get("fracture_ai", "")) != "split":
		_fail("module payload fracture/switch copy mismatch: %s" % str(module_logic_stats))
	if Array(module_logic_stats.get("morph_modes", [])).size() != 2 or int(module_logic_stats.get("morph_cooldown", 0)) != 6:
		_fail("module payload morph copy mismatch: %s" % str(module_logic_stats))
	_assert_near(float(module_logic_stats.get("combine_range", 0.0)), 3.5, "module combine range")
	if int(module_logic_stats.get("combine_bonus_hp", 0)) != 18 or String(module_logic_stats.get("identity_receiver_role", "")) != "hero" or int(module_logic_stats.get("identity_receiver_order", 0)) != 2:
		_fail("module payload identity/combine copy mismatch: %s" % str(module_logic_stats))
	if not service.has_method("apply_torso_payload_summary"):
		_fail("UnitStatsService missing apply_torso_payload_summary.")
		return
	var payload_summary_stats := {
		"torso_slots": 2,
		"module_slots": 1,
		"engine_slots": 0,
		"cooling_slots": 0,
		"booster_slots": 0,
		"spare_weapon_slots": 0,
		"ammo_payload_mass": 0.84,
		"ammo_capacity": {"bullet": 2, "laser": 1, "chemical": 0, "explosive": 3, "web": 0},
	}
	service.apply_torso_payload_summary(payload_summary_stats, {
		"payload_count": 3,
		"payload_mass": 8.0,
		"payload_volume_rank": 4.5,
		"software_payload_count": 2,
		"software_payload_energy": 1.25,
		"ammo_count": 1,
		"ammo_mass": 2.0,
	}, {
		"role_key": "hero",
		"internal_slot_status": {"max_installed_rank": 4, "max_empty_rank": 2},
		"installed_rank_label": "L",
		"empty_rank_label": "S",
	})
	if int(payload_summary_stats.get("slot_payload_count", 0)) != 3 or int(payload_summary_stats.get("software_payload_count", 0)) != 2:
		_fail("torso payload summary should copy counts: %s" % str(payload_summary_stats))
	_assert_near(float(payload_summary_stats.get("slot_payload_mass", 0.0)), 8.84, "summary payload mass")
	_assert_near(float(payload_summary_stats.get("slot_payload_volume_rank", 0.0)), 4.5, "summary payload volume")
	_assert_near(float(payload_summary_stats.get("software_payload_energy", 0.0)), 1.25, "summary software energy")
	if int(payload_summary_stats.get("ammo_slot_count", 0)) != 1:
		_fail("summary ammo slot count mismatch: %s" % str(payload_summary_stats))
	_assert_near(float(payload_summary_stats.get("ammo_slot_mass", 0.0)), 2.84, "summary ammo mass")
	if String(payload_summary_stats.get("slot_payload_note", "")) != "INVALID: internal plugin slots 3/2.":
		_fail("summary plugin invalid note mismatch: %s" % str(payload_summary_stats.get("slot_payload_note", "")))
	if String(payload_summary_stats.get("ammo_note", "")) != "AMMO B/L/C/X/W 2/1/0/3/0  AMMO SLOTS 1 MASS 3":
		_fail("summary ammo note mismatch: %s" % str(payload_summary_stats.get("ammo_note", "")))
	var barrier_summary_stats := {
		"torso_slots": 0,
		"module_slots": 0,
		"engine_slots": 0,
		"cooling_slots": 0,
		"booster_slots": 0,
		"spare_weapon_slots": 0,
		"ammo_capacity": {"bullet": 0, "laser": 0, "chemical": 0, "explosive": 0, "web": 0},
	}
	service.apply_torso_payload_summary(barrier_summary_stats, {
		"payload_count": 2,
		"payload_mass": 6.0,
		"payload_volume_rank": 3.0,
		"software_payload_count": 2,
		"software_payload_energy": 0.0,
		"ammo_count": 0,
		"ammo_mass": 0.0,
	}, {
		"role_key": "barrier",
		"internal_slot_status": {"max_installed_rank": 3, "max_empty_rank": 0},
		"installed_rank_label": "M",
		"empty_rank_label": "-",
	})
	if String(barrier_summary_stats.get("slot_payload_note", "")) != "BARRIER INTERNAL 2  SOFTWARE 2/2  MAX M  MASS 6":
		_fail("barrier payload summary note mismatch: %s" % str(barrier_summary_stats.get("slot_payload_note", "")))
	var internal_invalid_stats := {
		"torso_slots": 4,
		"module_slots": 4,
		"engine_slots": 0,
		"cooling_slots": 0,
		"booster_slots": 0,
		"spare_weapon_slots": 0,
		"ammo_capacity": {"bullet": 0, "laser": 0, "chemical": 0, "explosive": 0, "web": 0},
	}
	service.apply_torso_payload_summary(internal_invalid_stats, {
		"payload_count": 2,
		"payload_mass": 6.0,
		"payload_volume_rank": 2.0,
		"software_payload_count": 1,
		"software_payload_energy": 0.0,
		"ammo_count": 0,
		"ammo_mass": 0.0,
	}, {
		"role_key": "hero",
		"internal_slot_status": {"max_installed_rank": 2, "max_empty_rank": 1, "invalid": "INVALID: custom internal slot conflict."},
		"installed_rank_label": "S",
		"empty_rank_label": "XS",
	})
	if String(internal_invalid_stats.get("slot_payload_note", "")) != "INVALID: custom internal slot conflict.":
		_fail("internal invalid payload summary note mismatch: %s" % str(internal_invalid_stats.get("slot_payload_note", "")))
	var motion_stats := {
		"usable_power": 80.0,
		"power_load": 20.0,
		"mass": 10.0,
		"structural_mass": 12.0,
		"speed_mult": 1.1,
		"cooling": 6.0,
		"health": 40,
		"radius": 0.7,
		"length": 5.0,
		"normal_lane_range": 0.2,
		"armor_lane_range": 0.3,
		"active_lane_range": 0.4,
	}
	service.apply_base_motion_envelope(motion_stats)
	_assert_near(float(motion_stats.get("speed", 0.0)), 1.4280, "motion speed")
	_assert_near(float(motion_stats.get("acceleration", 0.0)), 4.9962, "motion acceleration")
	_assert_near(float(motion_stats.get("drag", 0.0)), 2.4333, "motion drag")
	if int(motion_stats.get("health", 0)) != 54:
		_fail("motion health expected 54 got %d" % int(motion_stats.get("health", 0)))
	_assert_near(float(motion_stats.get("length", 0.0)), 4.5, "motion length")
	_assert_near(float(motion_stats.get("normal_lane_range", 0.0)), 0.264, "normal lane range")
	_assert_near(float(motion_stats.get("armor_lane_range", 0.0)), 0.348, "armor lane range")
	_assert_near(float(motion_stats.get("active_lane_range", 0.0)), 0.480, "active lane range")
	if float(motion_stats.get("move_heat", -1.0)) != 0.0:
		_fail("motion envelope should reset move_heat.")
	var hero_stats := {"cost": 100, "health": 50, "speed": 1.0}
	service.apply_role_deploy_profile(hero_stats, "hero")
	if int(hero_stats.get("deploy_cost", 0)) != 72 or int(hero_stats.get("health", 0)) != 85 or not _near(float(hero_stats.get("speed", 0.0)), 1.08):
		_fail("hero deploy profile mismatch: %s" % str(hero_stats))
	var puppet_stats := {"cost": 100, "health": 100, "speed": 1.0, "group_count": 20, "ai": "drone_cloud", "radius": 0.4, "pirate_discount": 0.25, "betrayal_chance": 0.1}
	service.apply_role_deploy_profile(puppet_stats, "puppet")
	if int(puppet_stats.get("raw_cost", 0)) != 100 or int(puppet_stats.get("cost", 0)) != 75 or int(puppet_stats.get("deploy_cost", 0)) != 26:
		_fail("puppet deploy/cost profile mismatch: %s" % str(puppet_stats))
	if int(puppet_stats.get("group_count", 0)) != 11 or int(puppet_stats.get("health", 0)) != 24 or not _near(float(puppet_stats.get("speed", 0.0)), 1.44) or not _near(float(puppet_stats.get("radius", 0.0)), 0.288):
		_fail("puppet drone profile mismatch: %s" % str(puppet_stats))
	if not String(puppet_stats.get("pirate_note", "")).contains("BOOTLEG 25% OFF"):
		_fail("puppet pirate note mismatch: %s" % str(puppet_stats))
	var barrier_stats := {"cost": 100, "health": 100, "speed": 1.0, "active_damage": 20, "active_lane_range": 0.3}
	service.apply_role_deploy_profile(barrier_stats, "barrier")
	if int(barrier_stats.get("deploy_cost", 0)) != 56 or int(barrier_stats.get("health", 0)) != 135 or float(barrier_stats.get("speed", -1.0)) != 0.0:
		_fail("barrier deploy profile mismatch: %s" % str(barrier_stats))
	if int(barrier_stats.get("normal_damage", -1)) != 0 or int(barrier_stats.get("armor_damage", -1)) != 0 or int(barrier_stats.get("active_damage", 0)) != 12:
		_fail("barrier damage profile mismatch: %s" % str(barrier_stats))
	var maker_stats := {"cost": 100, "deploy_cost": 70}
	service.apply_manufacturer_discount(maker_stats, 0.2)
	if int(maker_stats.get("raw_cost_before_maker", 0)) != 100 or int(maker_stats.get("cost", 0)) != 80 or int(maker_stats.get("deploy_cost", 0)) != 56:
		_fail("maker discount mismatch: %s" % str(maker_stats))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _unit_stats_service()",
		"func _unit_stats_base_constants()",
		"_unit_stats_service().base_stats({",
		"_unit_stats_service().apply_base_motion_envelope(stats)",
		"_unit_stats_service().apply_role_deploy_profile(stats, role_key)",
		"_unit_stats_service().apply_manufacturer_discount(stats, manufacturer_discount)",
		"_unit_stats_service().copy_part_logic_stats(stats, part",
		"_unit_stats_service().copy_part_combat_stats(stats, part",
		"_unit_stats_service().copy_part_payload_stats(stats, part",
		"_unit_stats_service().payload_slot_key_for_kind(",
		"_unit_stats_service().volume_tier_rank(",
		"_unit_stats_service().volume_rank_from_value(",
		"_unit_stats_service().part_slot_volume_rank(",
		"_unit_stats_service().apply_torso_payload_direct_stats(stats,",
		"_unit_stats_service().record_torso_payload_summary_entry(",
		"_unit_stats_service().torso_payload_processing_plan(",
		"_unit_stats_service().apply_torso_special_payload_logic_stats(stats,",
		"_unit_stats_service().apply_soul_heat_capacity_stats(stats,",
		"_unit_stats_service().apply_internal_payload_base_stats(stats,",
		"_unit_stats_service().apply_torso_module_payload_logic_stats(stats,",
		"_unit_stats_service().apply_torso_payload_summary(stats,",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing UnitStatsService delegation token: %s" % token)
			return
	if failed:
		return
	print("UNIT_STATS_SERVICE_CONTRACT_PROBE ok speed=%.3f puppet_cost=%d" % [float(motion_stats.get("speed", 0.0)), int(puppet_stats.get("cost", 0))])
	quit(0)
