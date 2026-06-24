extends SceneTree

const BattleHitResolutionServiceScript := preload("res://scripts/services/battle_hit_resolution_service.gd")
const ProjectileRuntimeServiceScript := preload("res://scripts/services/projectile_runtime_service.gd")
const NOTE_PATH := "res://docs/reports/2026-06-24-star-soul-loop-balance-examples.md"

var failed := false


func _init() -> void:
	var hit_service = BattleHitResolutionServiceScript.new()
	var projectile_service = ProjectileRuntimeServiceScript.new()

	var low_momentum: Dictionary = hit_service.momentum_damage_gate_intent({
		"momentum": 2.0,
		"damage_coefficient": 1.0,
		"adjustment_coefficient": 1.0,
		"break_value": 3.0,
	})
	_require(bool(low_momentum.get("threshold_blocked", false)), "Low-momentum sample should be blocked.")

	var equal_break: Dictionary = hit_service.momentum_damage_gate_intent({
		"momentum": 10.0,
		"damage_coefficient": 2.0,
		"adjustment_coefficient": 1.0,
		"break_value": 20.0,
	})
	_require(bool(equal_break.get("threshold_blocked", false)), "Damage equal to break value should be blocked.")

	var slash_adjustments: Dictionary = hit_service.melee_type_adjustments("slash")
	var slash: Dictionary = hit_service.momentum_damage_gate_intent({
		"momentum": 10.0,
		"damage_coefficient": 1.0,
		"adjustment_coefficient": float(slash_adjustments.get("damage_adjustment", 1.0)),
		"break_value": 14.0,
	})
	_require(not bool(slash.get("threshold_blocked", true)) and absf(float(slash.get("damage_value", 0.0)) - 15.0) < 0.001, "Slash sample should pass at 15 damage.")

	var stab_adjustments: Dictionary = hit_service.melee_type_adjustments("stab")
	var stab: Dictionary = hit_service.momentum_damage_gate_intent({
		"momentum": 10.0,
		"damage_coefficient": 1.0,
		"adjustment_coefficient": 1.0,
		"break_value": 18.0,
		"break_value_adjustment": float(stab_adjustments.get("break_value_adjustment", 1.0)),
	})
	_require(not bool(stab.get("threshold_blocked", true)) and absf(float(stab.get("break_gate", 0.0)) - 9.0) < 0.001, "Stab sample should pass against adjusted break gate 9.")

	var blunt_adjustments: Dictionary = hit_service.melee_type_adjustments("blunt")
	var blunt: Dictionary = hit_service.momentum_damage_gate_intent({
		"momentum": 12.0,
		"damage_coefficient": 1.0,
		"adjustment_coefficient": 1.0,
		"break_value": 20.0,
		"knock_adjustment_coefficient": float(blunt_adjustments.get("knock_adjustment", 1.0)),
	})
	_require(bool(blunt.get("threshold_blocked", false)) and absf(float(blunt.get("knock_momentum", 0.0)) - 24.0) < 0.001, "Blocked blunt sample should still apply knock momentum 24.")

	var projectile_constants := {
		"projectile_speed_laser": 60.0,
		"chemical_projectile_default_speed_mult": 0.72,
		"projectile_speed_unit": 6.0,
	}
	var laser_state: Dictionary = projectile_service.projectile_momentum_state_for_event({
		"projectile": true,
		"ammo_kind": "electric",
		"projectile_damage_type": "laser",
		"projectile_momentum": 999.0,
		"projectile_mass": 999.0,
	}, projectile_constants)
	_require(absf(float(laser_state.get("momentum", 0.0)) - 1.0) < 0.001, "Electric sample should keep fixed momentum 1.")

	var chemical_state: Dictionary = projectile_service.projectile_momentum_state_for_event({
		"projectile": true,
		"ammo_kind": "chemical",
		"projectile_damage_type": "chemical",
		"projectile_momentum": 999.0,
		"projectile_mass": 999.0,
	}, projectile_constants)
	var chemical_damage: Dictionary = hit_service.damage_stack_intent({
		"raw_damage": 10.0,
		"multiplier": 1.0,
		"projectile": true,
		"chemical_dot_applies": true,
		"chemical_dot_mult": 1.2,
		"chemical_frontload": 0.25,
	})
	_require(absf(float(chemical_state.get("momentum", 0.0)) - 1.0) < 0.001, "Chemical sample should keep fixed momentum 1.")
	_require(int(chemical_damage.get("damage", 0)) == 3 and int(chemical_damage.get("chemical_dot_total", 0)) == 12, "Chemical sample should split into 3 frontload and 12 DoT.")

	var note := FileAccess.get_file_as_string(ProjectSettings.globalize_path(NOTE_PATH))
	for token in ["低动量", "等值破防", "斩击", "刺击", "钝击", "电能", "化学", "`capped_momentum`", "`break_gate`"]:
		_require(note.find(token) >= 0, "Balance note missing token: %s" % token)

	if failed:
		quit(1)
		return
	print("STAR_SOUL_LOOP_BALANCE_EXAMPLES_PROBE ok slash=15 stab_gate=9 blunt_knock=24 chemical=3+12dot")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
