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
	if not service.has_method("part_payload_context"):
		_fail("UnitStatsService missing part_payload_context.")
		return
	if not service.has_method("torso_payload_context"):
		_fail("UnitStatsService missing torso_payload_context.")
		return
	var ammo_types := ["bullet", "laser", "chemical", "explosive", "web"]
	var ammo_masses := {"bullet": 0.16, "laser": 0.11, "chemical": 0.24, "explosive": 0.42, "web": 0.09}
	var built_payload_context: Dictionary = service.part_payload_context({
		"module_slots": 4,
		"torso_slots": 5,
		"torso_slot_mass_limit": 80.0,
		"torso_slot_volume_tier": "L",
	}, {
		"part_is_torso": true,
		"torso_module_slots": 6,
		"torso_plugin_slots": 7,
		"ammo_types": ammo_types,
		"ammo_unit_mass": ammo_masses,
	})
	ammo_types.append("invalid_after_copy")
	ammo_masses["bullet"] = 9.0
	if not bool(built_payload_context.get("part_is_torso", false)) or int(built_payload_context.get("torso_module_slots", 0)) != 6 or int(built_payload_context.get("torso_plugin_slots", 0)) != 7:
		_fail("part payload context should preserve adapter torso facts: %s" % str(built_payload_context))
	if Array(built_payload_context.get("ammo_types", [])).has("invalid_after_copy") or not _near(float(Dictionary(built_payload_context.get("ammo_unit_mass", {})).get("bullet", 0.0)), 0.16):
		_fail("part payload context should duplicate ammo metadata: %s" % str(built_payload_context))
	_assert_near(float(built_payload_context.get("legacy_mass_limit_volume_rank", 0.0)), 4.0, "part payload legacy mass rank")
	_assert_near(float(built_payload_context.get("torso_slot_volume_tier_rank", 0.0)), 4.0, "part payload tier rank")
	var non_torso_payload_context: Dictionary = service.part_payload_context({"module_slots": 2, "torso_slots": 3}, {"ammo_types": ["bullet"], "ammo_unit_mass": {"bullet": 0.2}})
	if bool(non_torso_payload_context.get("part_is_torso", true)) or int(non_torso_payload_context.get("torso_module_slots", 0)) != 2 or int(non_torso_payload_context.get("torso_plugin_slots", 0)) != 3:
		_fail("non-torso payload context should fall back to raw slots: %s" % str(non_torso_payload_context))
	var built_torso_payload_context: Dictionary = service.torso_payload_context({"ammo_types": ["bullet", "web"], "ammo_unit_mass": {"bullet": 0.16, "web": 0.09}})
	if Array(built_torso_payload_context.get("ammo_types", [])).size() != 2 or not _near(float(Dictionary(built_torso_payload_context.get("ammo_unit_mass", {})).get("web", 0.0)), 0.09):
		_fail("torso payload context mismatch: %s" % str(built_torso_payload_context))
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
	}, built_payload_context)
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
	if not service.has_method("apply_torso_payload_plan"):
		_fail("UnitStatsService missing apply_torso_payload_plan.")
		return
	var shield_execution_stats := {
		"cost": 0,
		"mass": 0.0,
		"electronic_armor_max": 0.0,
		"electronic_armor_regen": 0.0,
		"electronic_armor_coverage": 0.0,
	}
	var shield_execution_summary := {}
	var shield_execution_part := {
		"cost": 9,
		"mass": 2.5,
		"electronic_armor": true,
		"shield_hp": 120.0,
		"shield_regen": 4.0,
		"shield_coverage": 0.7,
	}
	var shield_execution_plan: Dictionary = service.torso_payload_processing_plan("electronic_armor", shield_execution_part, {"kind": "electronic_armor"}, "muscle", {"volume_rank": 3.0})
	var shield_execution_intent: Dictionary = service.apply_torso_payload_plan(shield_execution_stats, shield_execution_summary, shield_execution_plan, shield_execution_part, {"role_key": "hero", "torso_payload_context": {}})
	if int(shield_execution_summary.get("payload_count", 0)) != 1 or int(shield_execution_summary.get("ammo_count", 0)) != 0:
		_fail("payload plan executor should record shield summary: %s" % str(shield_execution_summary))
	_assert_near(float(shield_execution_summary.get("payload_mass", 0.0)), 2.5, "payload plan executor shield mass")
	_assert_near(float(shield_execution_summary.get("payload_volume_rank", 0.0)), 3.0, "payload plan executor shield volume")
	if int(shield_execution_stats.get("cost", 0)) != 9:
		_fail("payload plan executor should apply direct cost: %s" % str(shield_execution_stats))
	_assert_near(float(shield_execution_stats.get("mass", 0.0)), 2.5, "payload plan executor direct mass")
	_assert_near(float(shield_execution_stats.get("electronic_armor_max", 0.0)), 120.0, "payload plan executor shield hp")
	if String(shield_execution_intent.get("internal_slot_key", "")) != "" or bool(shield_execution_intent.get("apply_ether", false)) or bool(shield_execution_intent.get("apply_soul_bonus", false)):
		_fail("payload plan executor direct intent mismatch: %s" % str(shield_execution_intent))
	var soul_execution_stats := {"has_soul": false, "group_count": 1}
	var soul_execution_summary := {}
	var soul_execution_part := {"kind": "soul", "name": "SOUL PLAN", "soul_heat_capacity": 91.0, "mass": 0.25}
	var soul_execution_intent: Dictionary = service.apply_torso_payload_plan(soul_execution_stats, soul_execution_summary, special_plan, soul_execution_part, {"role_key": "hero"})
	if int(soul_execution_summary.get("software_payload_count", 0)) != 1 or int(soul_execution_summary.get("payload_count", 0)) != 0:
		_fail("payload plan executor should record soul as software: %s" % str(soul_execution_summary))
	if not bool(soul_execution_stats.get("has_soul", false)) or int(soul_execution_stats.get("soul_heat_capacity", 0)) != 91:
		_fail("payload plan executor should apply soul heat stats: %s" % str(soul_execution_stats))
	if String(soul_execution_intent.get("internal_slot_key", "")) != "special" or not bool(soul_execution_intent.get("apply_soul_bonus", false)) or bool(soul_execution_intent.get("apply_ether", false)):
		_fail("payload plan executor soul intent mismatch: %s" % str(soul_execution_intent))
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
	if not service.has_method("apply_ether_payload_stats"):
		_fail("UnitStatsService missing apply_ether_payload_stats.")
		return
	var ether_stats := {
		"ether_count": 0,
		"material_slots": 1,
		"aura_range": 9.0,
		"active_range": 0.0,
		"ether_effects": [{"kind": "legacy"}],
	}
	service.apply_ether_payload_stats(ether_stats, {
		"material_slots": 8,
		"space_size": 0.5,
		"power": 2.0,
		"aura_range": 0.25,
		"active_range": 0.4,
		"barrier_disconnected": true,
		"ether_bind_radius_m": 4.0,
		"ether_link_capacity": 3,
		"ether_group_kind": "plain",
		"is_gravity_field": true,
		"gravity_direction": "up",
		"gravity_force": 0.42,
		"gravity_radius": 0.7,
	}, {"default_momentum_threshold_coeff": 1.15})
	if int(ether_stats.get("ether_count", 0)) != 1 or int(ether_stats.get("material_slots", 0)) != 9:
		_fail("ether merge count/material mismatch: %s" % str(ether_stats))
	_assert_near(float(ether_stats.get("ether_momentum_threshold_coeff", 0.0)), 1.64, "ether threshold coeff")
	_assert_near(float(ether_stats.get("space_size", 0.0)), 0.5, "ether space size")
	_assert_near(float(ether_stats.get("aura_range", 0.0)), 0.25, "first ether explicit aura should replace old aura")
	_assert_near(float(ether_stats.get("active_range", 0.0)), 0.4, "ether active range")
	if not bool(ether_stats.get("barrier_disconnected", false)) or int(ether_stats.get("ether_group_capacity", 0)) != 4:
		_fail("ether merge disconnected/group mismatch: %s" % str(ether_stats))
	if String(ether_stats.get("ether_group_kind", "")) != "plain" or Array(ether_stats.get("ether_effects", [])).size() != 2:
		_fail("ether merge kind/effects mismatch: %s" % str(ether_stats))
	var gravity_effect: Dictionary = Dictionary(Array(ether_stats.get("ether_effects", []))[1])
	if String(gravity_effect.get("direction", "")) != "up" or not _near(float(gravity_effect.get("force", 0.0)), 0.42) or not _near(float(gravity_effect.get("radius", 0.0)), 0.7):
		_fail("ether gravity effect mismatch: %s" % str(gravity_effect))
	service.apply_ether_payload_stats(ether_stats, {
		"fixed": 6,
		"space_size": 0.8,
		"ether_radius_m": 7.0,
		"ether_link_capacity": 1,
		"ether_group_kind": "gravity",
	})
	if int(ether_stats.get("ether_count", 0)) != 2 or int(ether_stats.get("material_slots", 0)) != 15:
		_fail("second ether merge count/material mismatch: %s" % str(ether_stats))
	if int(ether_stats.get("ether_group_capacity", 0)) != 2 or String(ether_stats.get("ether_group_kind", "")) != "mixed":
		_fail("second ether merge group mismatch: %s" % str(ether_stats))
	_assert_near(float(ether_stats.get("ether_bind_radius_m", 0.0)), 7.0, "second ether bind radius")
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
	if not service.has_method("apply_soul_bonus_stats"):
		_fail("UnitStatsService missing apply_soul_bonus_stats.")
		return
	var soul_bonus_stats := {
		"health": 100,
		"normal_damage": 10,
		"armor_damage": 11,
		"active_damage": 12,
		"speed": 1.0,
		"acceleration": 2.0,
		"cooling": 10.0,
		"heat_dissipation": 6.0,
		"boost_cooling_mult": 1.05,
		"pierce_range_bonus": 0.01,
		"tear_range_bonus": 0.02,
		"cooling_heat_capacity": 5.0,
		"soul_heat_note": "SOUL TEST",
	}
	var soul_bonus_part := {
		"name": "TITAN TEST",
		"cost": 164,
		"soul_bonus": {
			"boost_cooling_mult": 1.2,
			"pierce_range_bonus": 0.07,
			"tear_range_bonus": 0.11,
			"heat_capacity_bonus": 18.0,
			"speed_bonus": 0.09,
		},
	}
	service.apply_soul_bonus_stats(soul_bonus_stats, soul_bonus_part, {"requirements_met": true})
	if int(soul_bonus_stats.get("health", 0)) != 169 or int(soul_bonus_stats.get("normal_damage", 0)) != 15 or int(soul_bonus_stats.get("armor_damage", 0)) != 18 or int(soul_bonus_stats.get("active_damage", 0)) != 22:
		_fail("active soul base bonus mismatch: %s" % str(soul_bonus_stats))
	_assert_near(float(soul_bonus_stats.get("speed", 0.0)), 1.2212, "active soul speed")
	_assert_near(float(soul_bonus_stats.get("acceleration", 0.0)), 2.4592, "active soul acceleration")
	_assert_near(float(soul_bonus_stats.get("cooling", 0.0)), 24.76, "active soul cooling")
	_assert_near(float(soul_bonus_stats.get("heat_dissipation", 0.0)), 20.76, "active soul heat dissipation")
	_assert_near(float(soul_bonus_stats.get("boost_cooling_mult", 0.0)), 1.2, "active soul boost cooling")
	_assert_near(float(soul_bonus_stats.get("pierce_range_bonus", 0.0)), 0.08, "active soul pierce range")
	_assert_near(float(soul_bonus_stats.get("tear_range_bonus", 0.0)), 0.13, "active soul tear range")
	_assert_near(float(soul_bonus_stats.get("cooling_heat_capacity", 0.0)), 23.0, "active soul heat bonus")
	if String(soul_bonus_stats.get("soul_note", "")) != "TITAN TEST ONLINE" or not bool(soul_bonus_stats.get("soul_bonus_active", false)):
		_fail("active soul note/flag mismatch: %s" % str(soul_bonus_stats))
	if String(soul_bonus_stats.get("soul_heat_note", "")) != "SOUL TEST + cooling-slot bonus 18":
		_fail("active soul heat note mismatch: %s" % str(soul_bonus_stats))
	var inactive_soul_stats := {
		"health": 100,
		"normal_damage": 10,
		"armor_damage": 11,
		"active_damage": 12,
		"speed": 1.0,
		"acceleration": 2.0,
		"cooling": 10.0,
		"heat_dissipation": 6.0,
		"boost_cooling_mult": 1.05,
		"pierce_range_bonus": 0.01,
		"cooling_heat_capacity": 5.0,
	}
	service.apply_soul_bonus_stats(inactive_soul_stats, soul_bonus_part, {"requirements_met": false})
	if String(inactive_soul_stats.get("soul_note", "")) != "TITAN TEST BASE ONLY: body mismatch" or bool(inactive_soul_stats.get("soul_bonus_active", true)):
		_fail("inactive soul note/flag mismatch: %s" % str(inactive_soul_stats))
	_assert_near(float(inactive_soul_stats.get("boost_cooling_mult", 0.0)), 1.05, "inactive soul boost unchanged")
	_assert_near(float(inactive_soul_stats.get("pierce_range_bonus", 0.0)), 0.01, "inactive soul pierce unchanged")
	_assert_near(float(inactive_soul_stats.get("cooling_heat_capacity", 0.0)), 5.0, "inactive soul heat bonus unchanged")
	var oath_part := {
		"name": "OATH TEST",
		"soul_archetype": "duelist_oath",
		"soul_echo_window": 1.15,
		"soul_echo_recovery_mult": 0.72,
		"soul_echo_heat_relief": 0.18,
		"soul_bonus": {"pierce_range_bonus": 0.1, "speed_bonus": 0.04},
	}
	var oath_stats := {"speed": 1.0, "pierce_range_bonus": 0.02, "recovery_response": 0.85, "melee_stability_core": 0.85}
	service.apply_soul_bonus_stats(oath_stats, oath_part, {"duelist_oath_fail_reason": ""})
	if String(oath_stats.get("soul_archetype", "")) != "duelist_oath" or not bool(oath_stats.get("soul_oath_active", false)) or String(oath_stats.get("soul_oath_reason", "")) != "active":
		_fail("active oath identity mismatch: %s" % str(oath_stats))
	if String(oath_stats.get("soul_note", "")) != "OATH TEST OATH ONLINE" or not bool(oath_stats.get("soul_bonus_active", false)):
		_fail("active oath note/flag mismatch: %s" % str(oath_stats))
	_assert_near(float(oath_stats.get("soul_echo_window", 0.0)), 1.15, "active oath echo window")
	_assert_near(float(oath_stats.get("soul_echo_recovery_mult", 0.0)), 0.72, "active oath recovery mult")
	_assert_near(float(oath_stats.get("soul_echo_heat_relief", 0.0)), 0.18, "active oath heat relief")
	_assert_near(float(oath_stats.get("pierce_range_bonus", 0.0)), 0.12, "active oath pierce bonus")
	_assert_near(float(oath_stats.get("speed", 0.0)), 1.04, "active oath speed")
	_assert_near(float(oath_stats.get("recovery_response", 0.0)), 0.93, "active oath recovery response")
	_assert_near(float(oath_stats.get("melee_stability_core", 0.0)), 0.89, "active oath stability")
	var failed_oath_stats := {"speed": 1.0, "pierce_range_bonus": 0.02, "recovery_response": 0.85, "melee_stability_core": 0.85}
	service.apply_soul_bonus_stats(failed_oath_stats, oath_part, {"duelist_oath_fail_reason": "missing_bound_modules"})
	if bool(failed_oath_stats.get("soul_oath_active", true)) or String(failed_oath_stats.get("soul_oath_reason", "")) != "missing_bound_modules":
		_fail("failed oath state mismatch: %s" % str(failed_oath_stats))
	if String(failed_oath_stats.get("soul_note", "")) != "OATH TEST HEAT SLOT ONLY: missing_bound_modules" or bool(failed_oath_stats.get("soul_bonus_active", true)):
		_fail("failed oath note/flag mismatch: %s" % str(failed_oath_stats))
	_assert_near(float(failed_oath_stats.get("speed", 0.0)), 1.0, "failed oath speed unchanged")
	_assert_near(float(failed_oath_stats.get("pierce_range_bonus", 0.0)), 0.02, "failed oath pierce unchanged")
	for method_name in ["normalize_size_tier_label", "size_tier_rank", "size_tier_from_footprint", "part_size_tier_label", "part_size_tier_rank", "economy_median_mass_for_rank", "thruster_drive_demand_for_part", "thruster_move_efficiency_for_part", "thruster_boost_efficiency_for_part", "booster_normal_momentum_for_part", "booster_boost_momentum_for_part", "thruster_boost_total_momentum_for_part", "payload_slot_key_for_kind", "payload_catalog_selection", "volume_tier_rank", "volume_rank_from_value", "payload_slot_volume_rank", "internal_slot_accepts_payload", "torso_internal_slot_size_ranks", "best_internal_slot_for_payload"]:
		if not service.has_method(method_name):
			_fail("UnitStatsService missing %s." % method_name)
			return
	if String(service.normalize_size_tier_label("starter")) != "XS" or String(service.normalize_size_tier_label("small")) != "S":
		_fail("small size-tier aliases should normalize.")
	if String(service.normalize_size_tier_label("standard")) != "M" or String(service.normalize_size_tier_label("siege")) != "L":
		_fail("medium/large size-tier aliases should normalize.")
	if String(service.normalize_size_tier_label("leviathan")) != "XL" or String(service.normalize_size_tier_label("unknown")) != "M":
		_fail("colossal/unknown size-tier aliases should normalize.")
	if int(service.size_tier_rank("nano")) != 1 or int(service.size_tier_rank("heavy")) != 4 or int(service.size_tier_rank("monster")) != 5:
		_fail("normalized size-tier rank mismatch.")
	if String(service.size_tier_from_footprint(0.18, 0.0, 0.0)) != "XS" or String(service.size_tier_from_footprint(0.181, 0.0, 0.0)) != "S":
		_fail("XS footprint boundary mismatch.")
	if String(service.size_tier_from_footprint(1.15, 0.0, 0.0)) != "M" or String(service.size_tier_from_footprint(2.351, 0.0, 0.0)) != "XL":
		_fail("large footprint boundaries mismatch.")
	if String(service.part_size_tier_label({"size_class": "kaiju"})) != "XL" or int(service.part_size_tier_rank({"size_tier": "S"})) != 2:
		_fail("explicit part size-tier identity mismatch.")
	if String(service.part_size_tier_label({"length": 0.4, "radius": 0.16, "mass": 3.0})) != "S":
		_fail("part footprint size-tier inference mismatch.")
	_assert_near(float(service.economy_median_mass_for_rank(1)), 12.0, "XS economy median mass")
	_assert_near(float(service.economy_median_mass_for_rank(5)), 192.0, "XL economy median mass")
	_assert_near(float(service.thruster_drive_demand_for_part({"drive_demand": 80.0, "momentum_min": 40.0})), 80.0, "explicit thruster drive demand")
	_assert_near(float(service.thruster_drive_demand_for_part({"momentum_min": 40.0, "allocated_momentum": 999.0})), 40.0, "minimum thruster drive demand")
	_assert_near(float(service.thruster_drive_demand_for_part({"allocated_momentum": 20.0})), 11.0, "legacy allocated thruster demand")
	_assert_near(float(service.thruster_drive_demand_for_part({"slot_volume_tier": "M"})), 21.648, "rank fallback thruster demand")
	_assert_near(float(service.thruster_move_efficiency_for_part({"move_efficiency": 9.0})), 3.0, "thruster move efficiency clamp")
	_assert_near(float(service.thruster_boost_efficiency_for_part({"boost_efficiency": 9.0})), 4.0, "thruster boost efficiency clamp")
	_assert_near(float(service.booster_normal_momentum_for_part({"momentum_min": 20.0, "move_efficiency": 1.5})), 30.0, "booster normal momentum")
	_assert_near(float(service.booster_boost_momentum_for_part({"boost_momentum": -4.0})), 0.0, "booster extra momentum clamp")
	var boost_formula_part := {"drive_demand": 80.0, "boost_momentum": 40.0, "boost_efficiency": 2.5, "boost_duration": 0.3}
	_assert_near(float(service.thruster_boost_total_momentum_for_part(boost_formula_part)), 300.0, "booster total momentum")
	boost_formula_part["boost_duration"] = 0.0
	_assert_near(float(service.thruster_boost_total_momentum_for_part(boost_formula_part)), 0.0, "zero-duration booster total momentum")
	if String(service.payload_slot_key_for_kind("engine", "muscle")) != "engine" or String(service.payload_slot_key_for_kind("electronic_armor", "limb_muscle")) != "muscle":
		_fail("payload slot-key mapping mismatch.")
	if String(service.payload_slot_key_for_kind("unknown_payload", "custom_slot")) != "custom_slot":
		_fail("payload slot-key fallback mismatch.")
	var payload_catalog := [{"name": "ALPHA PART"}, {"name": "BETA PART"}]
	var saved_special: Dictionary = service.payload_catalog_selection({"kind": "special", "part_name": "BETA PART", "special": 7}, payload_catalog)
	if String(saved_special.get("slot_key", "")) != "special" or String(saved_special.get("index_key", "")) != "special" or int(saved_special.get("index", -1)) != 1 or not bool(saved_special.get("saved_name_matched", false)):
		_fail("saved special payload catalog selection mismatch: %s" % str(saved_special))
	var saved_module: Dictionary = service.payload_catalog_selection({"kind": "module", "component_name": "ALPHA PART", "module": 6}, payload_catalog)
	if String(saved_module.get("slot_key", "")) != "module" or int(saved_module.get("index", -1)) != 0 or not bool(saved_module.get("saved_name_matched", false)):
		_fail("saved module payload catalog selection mismatch: %s" % str(saved_module))
	var missing_engine: Dictionary = service.payload_catalog_selection({"kind": "engine", "part_name": "MISSING", "engine": 7}, payload_catalog)
	if String(missing_engine.get("slot_key", "")) != "engine" or int(missing_engine.get("index", -1)) != 7 or bool(missing_engine.get("saved_name_matched", true)):
		_fail("missing saved payload name should preserve legacy index: %s" % str(missing_engine))
	var ammo_selection: Dictionary = service.payload_catalog_selection({"kind": "ammo", "part_name": "BETA PART", "muscle": 4, "ammo_size_tier": "L"}, payload_catalog)
	if String(ammo_selection.get("slot_key", "")) != "muscle" or String(ammo_selection.get("index_key", "")) != "muscle" or int(ammo_selection.get("index", -1)) != 1:
		_fail("ammo payload catalog selection mismatch: %s" % str(ammo_selection))
	if not bool(ammo_selection.get("apply_ammo_variant", false)) or String(ammo_selection.get("ammo_size_tier", "")) != "L":
		_fail("ammo payload variant intent mismatch: %s" % str(ammo_selection))
	var armor_selection: Dictionary = service.payload_catalog_selection({"kind": "electronic_armor", "muscle": 2}, payload_catalog)
	if String(armor_selection.get("slot_key", "")) != "muscle" or int(armor_selection.get("index", -1)) != 2:
		_fail("muscle payload catalog selection mismatch: %s" % str(armor_selection))
	var custom_selection: Dictionary = service.payload_catalog_selection({"kind": "custom_payload", "slot": "custom_slot", "index": 3}, payload_catalog)
	if String(custom_selection.get("slot_key", "")) != "custom_slot" or String(custom_selection.get("index_key", "")) != "index" or int(custom_selection.get("index", -1)) != 3:
		_fail("custom payload catalog selection mismatch: %s" % str(custom_selection))
	if int(service.volume_tier_rank("XS")) != 1 or int(service.volume_tier_rank("XL")) != 5 or int(service.volume_tier_rank("???")) != 3:
		_fail("volume tier rank mismatch.")
	if int(service.volume_rank_from_value("", 4)) != 4 or int(service.volume_rank_from_value("-", 2)) != 2:
		_fail("blank volume rank fallback mismatch.")
	if int(service.volume_rank_from_value("L", 1)) != 4 or int(service.volume_rank_from_value(2, 1)) != 2 or int(service.volume_rank_from_value(2.2, 1)) != 3:
		_fail("volume rank value normalization mismatch.")
	if int(service.volume_rank_from_value(12.0, 1)) != 5 or int(service.volume_rank_from_value(-4, 3)) != 1:
		_fail("volume rank clamp mismatch.")
	_assert_near(float(service.payload_slot_volume_rank("ammo", {"ammo_size_tier": "S"}, {"kind": "ammo", "ammo_size_tier": "L"}, "muscle")), 4.0, "ammo payload volume should prefer payload tier")
	_assert_near(float(service.payload_slot_volume_rank("ammo", {"ammo_size_tier": "S"}, {"kind": "ammo"}, "muscle")), 2.0, "ammo payload volume should fall back to part tier")
	_assert_near(float(service.payload_slot_volume_rank("booster", {"mass": 5.0}, {"kind": "booster"}, "booster", {"booster_boost_momentum": 361.0})), 4.0, "booster payload volume should use adapter context")
	_assert_near(float(service.payload_slot_volume_rank("custom_plugin", {"slot_volume_tier": "XS"}, {"kind": "custom_plugin", "slot": "joint"}, "joint")), 1.0, "custom payload volume should use fallback slot rank")
	_assert_near(float(service.payload_slot_volume_rank("engine", {"engine_momentum_output": 84.0}, {"kind": "engine"}, "engine", {"volume_rank": 3.25})), 3.25, "payload volume should honor precomputed context rank")
	if not service.has_method("part_slot_volume_rank"):
		_fail("UnitStatsService missing part_slot_volume_rank.")
		return
	_assert_near(float(service.part_slot_volume_rank({"slot_volume_tier": "XL"}, "engine")), 5.0, "explicit slot volume rank")
	_assert_near(float(service.part_slot_volume_rank({"electronic_armor": true, "shield_hp": 220.0, "shield_coverage": 0.2, "mass": 4.0}, "muscle")), 4.0, "shield payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"engine_momentum_output": 84.0, "mass": 4.0}, "engine")), 4.0, "engine output volume rank")
	_assert_near(float(service.part_slot_volume_rank({"cooling": 38.0, "mass": 3.0}, "cooling")), 4.0, "cooling payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"mass": 5.0}, "booster", {"booster_boost_momentum": 361.0})), 4.0, "booster payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"drive_demand": 80.0, "boost_momentum": 40.0, "boost_efficiency": 2.5, "boost_duration": 0.3, "mass": 5.0}, "booster")), 3.0, "service-derived booster volume rank")
	_assert_near(float(service.part_slot_volume_rank({"radius": 0.16, "length": 0.4, "mass": 3.0}, "muscle")), 3.0, "footprint payload volume rank")
	_assert_near(float(service.part_slot_volume_rank({"radius": 0.16, "length": 0.4, "mass": 3.0}, "limb_muscle")), 2.0, "limb footprint volume rank")
	if not bool(service.internal_slot_accepts_payload(6, 5)) or bool(service.internal_slot_accepts_payload(2, 3)) or not bool(service.internal_slot_accepts_payload(0, 1)):
		_fail("internal slot acceptance clamp mismatch.")
	if service.torso_internal_slot_size_ranks({"internal_slot_sizes": ["XL", "S"]}, {"capacity": 4, "torso_size_rank": 3}) != [5, 2, 2, 2]:
		_fail("explicit internal slot sizes should normalize and pad.")
	if service.torso_internal_slot_size_ranks({}, {"capacity": 3, "torso_size_rank": 4}) != [5, 4, 4]:
		_fail("default internal slot sizes should trim by capacity.")
	if service.torso_internal_slot_size_ranks({}, {"capacity": 7, "torso_size_rank": 1}) != [2, 1, 1, 1, 1, 1, 1]:
		_fail("default internal slot sizes should pad by capacity.")
	if int(service.best_internal_slot_for_payload([5, 3, 2], {1: true}, 2)) != 2:
		_fail("best internal slot should choose smallest compatible open slot.")
	if int(service.best_internal_slot_for_payload([5, 3, 2], {2: true}, 2, 2)) != -1:
		_fail("requested occupied internal slot should fail.")
	if int(service.best_internal_slot_for_payload([5, 3, 2], {}, 5, 0)) != 0:
		_fail("requested compatible internal slot should be honored.")
	if int(service.best_internal_slot_for_payload([5, 3, 2], {}, 3, 2)) != -1:
		_fail("requested undersized internal slot should fail.")
	if not service.has_method("apply_internal_payload_merge_plan"):
		_fail("UnitStatsService missing apply_internal_payload_merge_plan.")
		return
	var engine_merge_stats := {
		"cost": 1,
		"mass": 1.0,
		"energy": 0.0,
		"power_load": 0.0,
		"heat_capacity": 0.0,
		"hardware_heat_capacity": 0.0,
		"speed_mult": 1.0,
	}
	var engine_merge_intent: Dictionary = service.apply_internal_payload_merge_plan(engine_merge_stats, {"cost": 5, "mass": 2.0, "heat_capacity": 7.0, "speed_mult": 0.9}, "engine", {"payload_power_load": 1.5})
	if int(engine_merge_stats.get("cost", 0)) != 6:
		_fail("internal merge plan should apply engine base cost: %s" % str(engine_merge_stats))
	_assert_near(float(engine_merge_stats.get("mass", 0.0)), 3.0, "internal merge engine mass")
	_assert_near(float(engine_merge_stats.get("energy", 0.0)), 1.5, "internal merge engine energy")
	_assert_near(float(engine_merge_stats.get("power_load", 0.0)), 1.5, "internal merge engine power")
	_assert_near(float(engine_merge_stats.get("heat_capacity", 0.0)), 7.0, "internal merge engine heat")
	_assert_near(float(engine_merge_stats.get("hardware_heat_capacity", 0.0)), 7.0, "internal merge engine hardware heat")
	if not bool(engine_merge_intent.get("apply_engine_stats", false)) or bool(engine_merge_intent.get("apply_cooling_profile_stats", false)) or bool(engine_merge_intent.get("apply_thruster_drive_stats", false)):
		_fail("internal merge engine intent mismatch: %s" % str(engine_merge_intent))
	var cooling_merge_stats := {
		"cost": 0,
		"mass": 0.0,
		"heat_capacity": 4.0,
		"hardware_heat_capacity": 3.0,
		"cooling_heat_capacity": 2.0,
		"speed_mult": 1.0,
	}
	var cooling_merge_intent: Dictionary = service.apply_internal_payload_merge_plan(cooling_merge_stats, {"cost": 2, "mass": 1.25, "heat_capacity": 99.0, "speed_mult": 1.1}, "cooling", {"cooling_heat_capacity": 13.5})
	if int(cooling_merge_stats.get("cost", 0)) != 2:
		_fail("internal merge plan should apply cooling base cost: %s" % str(cooling_merge_stats))
	_assert_near(float(cooling_merge_stats.get("mass", 0.0)), 1.25, "internal merge cooling mass")
	_assert_near(float(cooling_merge_stats.get("heat_capacity", 0.0)), 4.0, "internal merge cooling keeps hardware heat")
	_assert_near(float(cooling_merge_stats.get("hardware_heat_capacity", 0.0)), 3.0, "internal merge cooling keeps hardware heat capacity")
	_assert_near(float(cooling_merge_stats.get("cooling_heat_capacity", 0.0)), 15.5, "internal merge cooling heat capacity")
	if not bool(cooling_merge_intent.get("apply_cooling_profile_stats", false)) or not bool(cooling_merge_intent.get("apply_cooling_rate_stats", false)) or bool(cooling_merge_intent.get("apply_engine_stats", false)):
		_fail("internal merge cooling intent mismatch: %s" % str(cooling_merge_intent))
	var booster_merge_stats := {"cost": 0, "mass": 0.0, "speed_mult": 1.0}
	var booster_merge_intent: Dictionary = service.apply_internal_payload_merge_plan(booster_merge_stats, {"cost": 3, "mass": 4.0, "speed_mult": 1.05}, "booster")
	if int(booster_merge_stats.get("cost", 0)) != 3:
		_fail("internal merge plan should apply booster base cost: %s" % str(booster_merge_stats))
	_assert_near(float(booster_merge_stats.get("mass", 0.0)), 4.0, "internal merge booster mass")
	if not bool(booster_merge_intent.get("apply_thruster_drive_stats", false)) or bool(booster_merge_intent.get("apply_engine_stats", false)):
		_fail("internal merge booster intent mismatch: %s" % str(booster_merge_intent))
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
		"_unit_stats_service().part_payload_context(",
		"_unit_stats_service().torso_payload_context(",
		"_unit_stats_service().normalize_size_tier_label(",
		"_unit_stats_service().size_tier_rank(",
		"_unit_stats_service().size_tier_from_footprint(",
		"_unit_stats_service().part_size_tier_label(",
		"_unit_stats_service().economy_median_mass_for_rank(",
		"_unit_stats_service().thruster_drive_demand_for_part(",
		"_unit_stats_service().thruster_move_efficiency_for_part(",
		"_unit_stats_service().thruster_boost_efficiency_for_part(",
		"_unit_stats_service().booster_normal_momentum_for_part(",
		"_unit_stats_service().booster_boost_momentum_for_part(",
		"_unit_stats_service().thruster_boost_total_momentum_for_part(",
		"_unit_stats_service().payload_slot_key_for_kind(",
		"_unit_stats_service().payload_catalog_selection(",
		"_unit_stats_service().volume_tier_rank(",
		"_unit_stats_service().volume_rank_from_value(",
		"_unit_stats_service().payload_slot_volume_rank(",
		"_unit_stats_service().part_slot_volume_rank(",
		"_unit_stats_service().internal_slot_accepts_payload(",
		"_unit_stats_service().torso_internal_slot_size_ranks(",
		"_unit_stats_service().best_internal_slot_for_payload(",
		"_unit_stats_service().apply_torso_payload_direct_stats(stats,",
		"_unit_stats_service().record_torso_payload_summary_entry(",
		"_unit_stats_service().torso_payload_processing_plan(",
		"_unit_stats_service().apply_torso_payload_plan(",
		"_unit_stats_service().apply_ether_payload_stats(stats,",
		"_unit_stats_service().apply_soul_heat_capacity_stats(stats,",
		"_unit_stats_service().apply_soul_bonus_stats(stats,",
		"_unit_stats_service().apply_internal_payload_merge_plan(stats,",
		"_unit_stats_service().apply_torso_payload_summary(stats,",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing UnitStatsService delegation token: %s" % token)
			return
	if main_source.contains("\"size_tier_rank\": float(_size_tier_rank(_part_size_tier_label(part, slot_key)))"):
		_fail("main.gd should not derive part size-tier rank inside slot-volume adapters.")
		return
	if main_source.contains("\"booster_boost_momentum\":"):
		_fail("main.gd should not derive booster momentum inside slot-volume adapters.")
		return
	if main_source.contains("_component_index_by_exact_name(role_key, saved_slot, saved_name)"):
		_fail("main.gd should delegate saved payload catalog-name matching.")
		return
	if failed:
		return
	print("UNIT_STATS_SERVICE_CONTRACT_PROBE ok speed=%.3f puppet_cost=%d" % [float(motion_stats.get("speed", 0.0)), int(puppet_stats.get("cost", 0))])
	quit(0)
