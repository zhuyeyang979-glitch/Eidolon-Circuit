extends SceneTree

const SERVICE_PATH := "res://scripts/services/projectile_runtime_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const ProjectileRuntimeServiceScript := preload("res://scripts/services/projectile_runtime_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing ProjectileRuntimeService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name ProjectileRuntimeService",
		"projectile_behavior_for_data",
		"projectile_behavior_key",
		"gun_drive_projectile_momentum_mult",
		"projectile_collision_speed_for_event",
		"projectile_mass_for_event",
		"projectile_momentum_state_for_event",
		"gun_projectile_damage_mult_max_for_data",
		"projectile_damage_coeffs_for_event",
		"projectile_raw_damage_for_momentum",
		"default_recoil_transfer_for_projectile",
		"heat_tags_for_projectile_event",
		"heat_reason_for_projectile_event",
		"chemical_queue_intent",
		"missile_queue_intent",
		"web_trace_event",
		"trace_payload",
	]:
		if service_source.find(token) < 0:
			_fail("ProjectileRuntimeService missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "extends Node", "extends Control", "Control.new", "active_units", "all_units", "_spawn_", "_apply_projectile_damage", "_apply_explosion_damage", "pending_chemical_projectiles", "pending_missile_projectiles", "gpu_collision", "GpuCollisionPipeline"]:
		if service_source.find(forbidden) >= 0:
			_fail("ProjectileRuntimeService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const ProjectileRuntimeService = preload(\"res://scripts/services/projectile_runtime_service.gd\")",
		"var projectile_runtime_service: ProjectileRuntimeService",
		"projectile_runtime_service = ProjectileRuntimeService.new()",
		"projectile_runtime_service.projectile_behavior_for_data",
		"projectile_runtime_service.projectile_behavior_key",
		"projectile_runtime_service.gun_drive_projectile_momentum_mult",
		"projectile_runtime_service.projectile_collision_speed_for_event",
		"projectile_runtime_service.projectile_mass_for_event",
		"projectile_runtime_service.projectile_momentum_state_for_event",
		"projectile_runtime_service.gun_projectile_damage_mult_max_for_data",
		"projectile_runtime_service.projectile_damage_coeffs_for_event",
		"projectile_runtime_service.projectile_raw_damage_for_momentum",
		"projectile_runtime_service.heat_tags_for_projectile_event",
		"projectile_runtime_service.chemical_queue_intent",
		"projectile_runtime_service.missile_queue_intent",
		"projectile_runtime_service.web_trace_event",
		"projectile_runtime_service.trace_payload",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate projectile runtime service token: %s" % token)
			return
	var service = ProjectileRuntimeServiceScript.new()
	var constants := _constants()
	_assert_eq(service.projectile_behavior_for_data({"projectile_damage_type": "bullet", "projectile_style": "true_bullet"}), "true_bullet", "true bullet behavior")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam"}), "laser", "laser behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_damage_type": "chemical", "projectile_style": "spray"}), "chemical", "chemical behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_style": "missile", "projectile_behavior": "explosive"}), "explosive", "missile behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_style": "web", "projectile_behavior": "web_tether", "travel_path": "tether"}), "web_tether", "web behavior key")
	var sniper := {"projectile": true, "projectile_behavior": "true_bullet", "projectile_style": "true_bullet", "projectile_momentum": 123.0}
	if absf(service.projectile_collision_speed_for_event(sniper, constants) - 32.0) > 0.001:
		_fail("Sniper speed should use true bullet constant.")
	if absf(service.projectile_mass_for_event(sniper, constants, 32.0) - (123.0 / 32.0)) > 0.001:
		_fail("Sniper mass should derive from explicit momentum and speed.")
	var sniper_state: Dictionary = service.projectile_momentum_state_for_event(sniper, constants)
	if absf(float(sniper_state.get("momentum", 0.0)) - 123.0) > 0.001:
		_fail("Sniper momentum should use explicit projectile_momentum.")
	var bullet := {"projectile": true, "projectile_damage_type": "bullet", "projectile_style": "bullet_hell", "projectile_speed_mult": 2.8}
	if absf(service.projectile_collision_speed_for_event(bullet, constants) - 16.8) > 0.001:
		_fail("Bullet hell speed should be speed_mult * unit.")
	if absf(service.projectile_mass_for_event(bullet, constants) - 2.85) > 0.001:
		_fail("Bullet hell mass should use default mass.")
	var laser := {"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam"}
	if absf(service.default_recoil_transfer_for_projectile(laser) - 0.35) > 0.001:
		_fail("Laser recoil transfer should be low.")
	if absf(service.gun_projectile_damage_mult_max_for_data({"gun_kind": "laser_gun"}, "laser_gun", "laser", constants) - 3.0) > 0.001:
		_fail("Laser gun max multiplier should be 3.")
	var coeffs: Dictionary = service.projectile_damage_coeffs_for_event({"projectile": true, "gun_drive_allocated": 5.0, "gun_drive_max": 10.0}, "rifle", "bullet", constants, Callable(self, "_gun_mult_for_probe"))
	if absf(float(coeffs.get("gun", 0.0)) - 2.0) > 0.001:
		_fail("Gun current multiplier should use callback ratio.")
	if absf(service.projectile_raw_damage_for_momentum({"projectile": true, "gun_drive_allocated": 5.0, "gun_drive_max": 10.0}, 40.0, "rifle", "bullet", constants, Callable(self, "_gun_mult_for_probe")) - 80.0) > 0.001:
		_fail("Raw projectile damage should be momentum * gun multiplier.")
	var tags: Array = service.heat_tags_for_projectile_event({"gun_kind": "laser_gun", "projectile_style": "beam"})
	if not tags.has("projectile") or not tags.has("laser"):
		_fail("Heat tags should include projectile and laser: %s" % str(tags))
	if service.heat_reason_for_projectile_event({"ammo_kind": "chemical"}) != "heat:projectile heat:chemical projectile":
		_fail("Projectile heat reason should be canonical.")
	var chem_intent: Dictionary = service.chemical_queue_intent({"projectile": true, "range": 1.2}, Vector2.ZERO, Vector2.LEFT, constants)
	var chem_event: Dictionary = Dictionary(chem_intent.get("event", {}))
	if String(chem_event.get("damage_type", "")) != "chemical" or String(chem_event.get("projectile_style", "")) != "spray" or Vector2(chem_event.get("direction", Vector2.ZERO)).distance_to(Vector2.LEFT) > 0.001:
		_fail("Chemical queue intent should prepare chemical event and fallback direction: %s" % str(chem_intent))
	if float(chem_intent.get("timer", 0.0)) <= 0.0 or float(chem_intent.get("signal_time", 0.0)) <= float(chem_intent.get("timer", 0.0)):
		_fail("Chemical queue intent should include travel timer and signal time.")
	var missile_intent: Dictionary = service.missile_queue_intent({"projectile": true, "range": 2.0}, Vector2.RIGHT, 3.4, constants)
	var missile_event: Dictionary = Dictionary(missile_intent.get("event", {}))
	if String(missile_event.get("projectile_style", "")) != "missile" or String(missile_event.get("travel_path", "")) != "homing" or not bool(missile_event.get("aim_locked", false)):
		_fail("Missile queue intent should prepare homing missile event: %s" % str(missile_intent))
	var web_event: Dictionary = service.web_trace_event({"projectile": true}, Vector2(4.0, 1.0))
	if String(web_event.get("projectile_style", "")) != "web" or not bool(web_event.get("non_damage", false)) or Vector2(web_event.get("projectile_impact_position", Vector2.ZERO)) != Vector2(4.0, 1.0):
		_fail("Web trace event should be non-damage tether trace.")
	var payload: Dictionary = service.trace_payload({"damage_type": "chemical", "travel_path": "burst", "projectile_speed_mult": 0.8}, {"start": Vector2.ONE, "end": Vector2(2.0, 3.0)}, Vector2.ZERO, constants)
	if String(payload.get("projectile_style", "")) != "spray" or Vector2(payload.get("start", Vector2.ZERO)) != Vector2.ONE or Vector2(payload.get("end", Vector2.ZERO)) != Vector2(2.0, 3.0):
		_fail("Trace payload should derive style and preserve projected segment.")
	print("PROJECTILE_RUNTIME_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _constants() -> Dictionary:
	return {
		"bullet_hell_default_speed_mult": 2.8,
		"projectile_momentum_true_bullet": 96.0,
		"projectile_momentum_bullet_hell": 48.0,
		"projectile_momentum_laser": 18.0,
		"projectile_momentum_chemical": 16.0,
		"projectile_momentum_explosive": 92.0,
		"projectile_speed_unit": 6.0,
		"projectile_speed_true_bullet": 32.0,
		"projectile_speed_laser": 60.0,
		"projectile_mass_true_bullet": 3.0,
		"projectile_mass_bullet_hell": 2.85,
		"projectile_mass_laser": 0.3,
		"projectile_mass_chemical": 3.7,
		"projectile_mass_explosive": 9.6,
		"standard_sniper_gun_damage_coeff": 20.0,
		"standard_missile_range_m": 3.4,
		"standard_missile_speed_mult": 1.05,
		"chemical_projectile_default_speed_mult": 0.72,
		"chemical_projectile_min_travel": 0.32,
		"chemical_projectile_max_travel": 1.25,
		"chemical_dot_default_duration": 2.6,
		"chemical_dot_default_mult": 1.35,
		"chemical_dot_default_frontload": 0.46,
	}


func _gun_mult_for_probe(max_multiplier: float, allocated: float, maximum: float, non_damage: bool) -> float:
	if non_damage:
		return 0.0
	return max_multiplier if maximum <= 0.001 else max_multiplier * clampf(allocated, 0.0, maximum) / maximum


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])
