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
		"projectile_style_for_damage",
		"projectile_behavior_for_data",
		"projectile_behavior_key",
		"projectile_ammo_family",
		"projectile_uses_fixed_momentum",
		"ammo_type_for_event",
		"event_vector_value",
		"event_momentum_vector_patch",
		"event_direction_vector",
		"event_momentum_magnitude",
		"gun_drive_projectile_momentum_mult",
		"projectile_drive_momentum_mult_for_event",
		"projectile_drive_momentum_fields",
		"projectile_collision_speed_for_event",
		"projectile_mass_for_event",
		"projectile_momentum_state_for_event",
		"projectile_collision_momentum_intent",
		"projectile_stagger_impact_position_intent",
		"projectile_consumes_on_first_hit",
		"gun_projectile_damage_mult_max_for_data",
		"projectile_damage_coeffs_for_event",
		"projectile_raw_damage_for_momentum",
		"default_recoil_transfer_for_projectile",
		"weapon_recoil_intent",
		"heat_tags_for_projectile_event",
		"heat_reason_for_tags",
		"heat_reason_for_projectile_event",
		"is_chemical_projectile_event",
		"prepared_chemical_projectile_event",
		"chemical_firework_event",
		"chemical_projectile_travel_time",
		"chemical_queue_intent",
		"is_missile_projectile_event",
		"missile_projectile_travel_time",
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
		"func _projectile_runtime_service() -> ProjectileRuntimeService",
		"_projectile_runtime_service().projectile_style_for_damage(damage_type)",
		"_projectile_runtime_service().projectile_behavior_for_data(data)",
		"_projectile_runtime_service().projectile_behavior_key(event)",
		"_projectile_runtime_service().projectile_ammo_family(event)",
		"_projectile_runtime_service().ammo_type_for_event(event, AMMO_TYPES)",
		"_projectile_runtime_service().event_vector_value(event, key)",
		"_projectile_runtime_service().event_momentum_vector_patch(vector, magnitude)",
		"_projectile_runtime_service().event_direction_vector(event, target_delta, attacker_forward, fallback)",
		"_projectile_runtime_service().event_momentum_magnitude(event, fallback)",
		"_projectile_runtime_service().gun_drive_projectile_momentum_mult(gun_drive_ratio)",
		"_projectile_runtime_service().projectile_drive_momentum_mult_for_event(event)",
		"_projectile_runtime_service().projectile_drive_momentum_fields(event)",
		"_projectile_runtime_service().projectile_default_momentum_for_event(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().projectile_collision_speed_for_event(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().projectile_mass_for_event(event, _projectile_runtime_constants(), collision_speed)",
		"_projectile_runtime_service().projectile_momentum_state_for_event(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().projectile_collision_momentum_intent({",
		"_projectile_runtime_service().projectile_stagger_impact_position_intent(event, Vector2(target.ring_pos, target.lane))",
		"_projectile_runtime_service().projectile_consumes_on_first_hit(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().gun_projectile_damage_mult_max_for_data(data, _gun_kind_for_data(data), _ammo_kind_for_data(data), _projectile_runtime_constants())",
		"_projectile_runtime_service().gun_projectile_damage_mult_for_event(event, _gun_kind_for_data(event), _ammo_kind_for_data(event), _projectile_runtime_constants(), Callable(self, \"_gun_current_multiplier_for_projectile_service\"))",
		"_projectile_runtime_service().projectile_damage_coeffs_for_event(event, _gun_kind_for_data(event), _ammo_kind_for_data(event), _projectile_runtime_constants(), Callable(self, \"_gun_current_multiplier_for_projectile_service\"))",
		"_projectile_runtime_service().projectile_raw_damage_for_momentum(event, projectile_momentum, _gun_kind_for_data(event), _ammo_kind_for_data(event), _projectile_runtime_constants(), Callable(self, \"_gun_current_multiplier_for_projectile_service\"))",
		"_projectile_runtime_service().default_recoil_transfer_for_projectile(event)",
		"_projectile_runtime_service().weapon_recoil_intent({",
		"_projectile_runtime_service().heat_tags_for_projectile_event(event)",
		"_projectile_runtime_service().heat_reason_for_tags(tags, source)",
		"_projectile_runtime_service().heat_reason_for_projectile_event(event)",
		"_projectile_runtime_service().is_chemical_projectile_event(event)",
		"_projectile_runtime_service().prepared_chemical_projectile_event(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().chemical_firework_event(event)",
		"_projectile_runtime_service().chemical_queue_intent(event, event.get(\"direction\", _unit_forward_vector(attacker)), _unit_forward_vector(attacker), _projectile_runtime_constants())",
		"_projectile_runtime_service().chemical_projectile_travel_time(event, _projectile_runtime_constants())",
		"_projectile_runtime_service().is_missile_projectile_event(event)",
		"_projectile_runtime_service().missile_projectile_travel_time(range_hint, event, _projectile_runtime_constants())",
		"_projectile_runtime_service().missile_queue_intent(shot_event, direction, target_distance, _projectile_runtime_constants())",
		"_projectile_runtime_service().web_trace_event(base_event, impact_position)",
		"_projectile_runtime_service().trace_payload(event, segment, attacker.position, _projectile_runtime_constants())",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate projectile runtime service token: %s" % token)
			return
	for stale_behavior_parse in [
		"var behavior := String(data.get(\"projectile_behavior\", \"\"))\n\tif behavior != \"\":\n\t\treturn behavior",
		"if style in [\"web\", \"web_snap\"] or path == \"tether\":\n\t\treturn \"web_tether\"",
		"return \"chemical_firework\" if path in [\"firework\", \"shotgun\", \"burst\", \"sine\", \"arc_u\"] else \"chemical_line\"",
	]:
		if main_source.find(stale_behavior_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile behavior parser: %s" % stale_behavior_parse)
			return
	for stale_behavior_key_parse in [
		"var behavior := _projectile_behavior_for_data(event)\n\tvar style := String(event.get(\"projectile_style\", \"\"))",
		"if behavior == \"true_bullet\" or style == \"true_bullet\":\n\t\treturn \"true_bullet\"",
		"if damage_type == \"laser\" or style in [\"beam\", \"chaos\"]:\n\t\treturn \"laser\"",
	]:
		if main_source.find(stale_behavior_key_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile behavior-key parser: %s" % stale_behavior_key_parse)
			return
	var stale_ammo_type_parse := "func _ammo_type_for_event(event: Dictionary) -> String:\n\tvar ammo_kind := _normalized_ammo_type(String(event.get(\"ammo_kind\", \"\")))\n\tif AMMO_TYPES.has(ammo_kind):\n\t\treturn ammo_kind\n\tvar damage_type := String(event.get(\"projectile_damage_type\", event.get(\"damage_type\", \"\")))\n\treturn damage_type if AMMO_TYPES.has(damage_type) else \"\""
	if main_source.find(stale_ammo_type_parse) >= 0:
		_fail("main.gd should not keep duplicate projectile ammo-type parser.")
		return
	var stale_event_vector_parse := "func _event_vector_value(event: Dictionary, key: String) -> Vector2:\n\tif event.has(key) and event[key] is Vector2:\n\t\tvar value: Vector2 = event[key]\n\t\treturn value\n\treturn Vector2.ZERO"
	if main_source.find(stale_event_vector_parse) >= 0:
		_fail("main.gd should not keep duplicate event vector parser.")
		return
	var stale_set_event_momentum_parse := "func _set_event_momentum_vector(event: Dictionary, vector: Vector2, magnitude: float = -1.0) -> void:\n\tvar resolved_magnitude := magnitude if magnitude >= 0.0 else vector.length()\n\tevent[\"momentum_vector\"] = vector\n\tevent[\"momentum_magnitude\"] = resolved_magnitude\n\tif resolved_magnitude > 0.001 and vector.length() > 0.001:\n\t\tevent[\"direction\"] = vector.normalized()"
	if main_source.find(stale_set_event_momentum_parse) >= 0:
		_fail("main.gd should not keep duplicate event momentum vector patch rules.")
		return
	var stale_event_momentum_parse := "func _event_momentum_magnitude(event: Dictionary, fallback: float = 0.0) -> float:\n\tvar momentum_vector := _event_vector_value(event, \"momentum_vector\")\n\tif momentum_vector.length() > 0.001:\n\t\treturn momentum_vector.length()\n\tif event.has(\"momentum_magnitude\"):\n\t\treturn maxf(0.0, float(event.get(\"momentum_magnitude\", fallback)))\n\tif event.has(\"momentum\"):\n\t\treturn maxf(0.0, float(event.get(\"momentum\", fallback)))\n\treturn maxf(0.0, fallback)"
	if main_source.find(stale_event_momentum_parse) >= 0:
		_fail("main.gd should not keep duplicate event momentum magnitude parser.")
		return
	var stale_event_direction_parse := "func _event_direction_vector(attacker, target, event: Dictionary, fallback: Vector2 = Vector2.RIGHT) -> Vector2:\n\tvar momentum_vector := _event_vector_value(event, \"momentum_vector\")\n\tif momentum_vector.length() > 0.001:\n\t\treturn momentum_vector.normalized()\n\tvar event_direction := _event_vector_value(event, \"direction\")\n\tif event_direction.length() > 0.001:\n\t\treturn event_direction.normalized()"
	if main_source.find(stale_event_direction_parse) >= 0:
		_fail("main.gd should not keep duplicate event direction parser.")
		return
	for stale_drive_or_style_parse in [
		"func _gun_drive_projectile_momentum_mult(gun_drive_ratio: float) -> float:\n\tif projectile_runtime_service != null:",
		"if not event.has(\"gun_drive_ratio\"):\n\t\treturn 1.0\n\treturn _gun_drive_projectile_momentum_mult",
		"var base_momentum := maxf(0.0, float(event.get(\"projectile_base_momentum\", event.get(\"projectile_momentum\", 0.0))))",
		"match damage_type:\n\t\t\"chemical\":\n\t\t\treturn \"spray\"",
	]:
		if main_source.find(stale_drive_or_style_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile drive/style fallback: %s" % stale_drive_or_style_parse)
			return
	for stale_physics_parse in [
		"match _projectile_behavior_key(event):\n\t\t\"true_bullet\":\n\t\t\treturn PROJECTILE_MOMENTUM_TRUE_BULLET",
		"return clampf(float(event.get(\"projectile_speed_mult\", BULLET_HELL_DEFAULT_SPEED_MULT)), 1.5, 5.0) * PROJECTILE_SPEED_UNIT",
		"return maxf(0.01, float(event[\"projectile_momentum\"]) * _projectile_drive_momentum_mult_for_event(event) / speed)",
		"return PROJECTILE_MASS_TRUE_BULLET",
		"var relative_velocity := projectile_velocity - target_velocity",
		"var closing_speed := maxf(0.0, relative_velocity.dot(projectile_direction))",
		"var momentum := projectile_mass * closing_speed * maxf(0.0, momentum_scale)",
		"var impact_combat := Vector2(target.ring_pos, target.lane)\n\tif event.has(\"hit_position_combat\") and event[\"hit_position_combat\"] is Vector2:",
		"elif event.has(\"projectile_impact_position\") and event[\"projectile_impact_position\"] is Vector2:\n\t\timpact_combat = event[\"projectile_impact_position\"]",
	]:
		if main_source.find(stale_physics_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile physics fallback: %s" % stale_physics_parse)
			return
	for stale_damage_parse in [
		"func _projectile_consumes_on_first_hit(event: Dictionary) -> bool:\n\tif not bool(event.get(\"projectile\", false)):\n\t\treturn false",
		"if style in [\"web\", \"web_snap\", \"blind\", \"shield\", \"chain\"]:\n\t\treturn false",
		"return damage_type in PROJECTILE_DAMAGE_TYPES or style in [\"beam\", \"chaos\", \"true_bullet\", \"bullet_hell\", \"spray\", \"missile\", \"explosive\", \"blast\"]",
		"if float(event.get(\"projectile_momentum\", 0.0)) > 0.0:\n\t\tvar effective := maxf(0.0, float(event.get(\"projectile_momentum\", 0.0))",
		"var gun_kind := String(data.get(\"gun_kind\", _gun_kind_for_data(data))).to_lower()",
		"var max_mult := _gun_projectile_damage_mult_max_for_data(event)\n\tvar max_drive := maxf(0.0, float(event.get(\"gun_drive_max\"",
		"event[\"gun_projectile_damage_mult_current\"] = gun_mult\n\tevent[\"gun_projectile_damage_mult\"] = _gun_projectile_damage_mult_max_for_data(event)",
		"return projectile_momentum * float(coeffs.get(\"gun\", 1.0))",
		"match _projectile_behavior_key(event):\n\t\t\"true_bullet\":\n\t\t\treturn 0.85",
		"var recoil_amount := launch_momentum / maxf(1.0, shooter_mass)",
		"event[\"weapon_recoil_momentum\"] = launch_momentum",
	]:
		if main_source.find(stale_damage_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile momentum/damage/recoil fallback: %s" % stale_damage_parse)
			return
	for stale_heat_parse in [
		"var tags: Array = [\"projectile\"]\n\tvar tag_source := \"\"",
		"for key in [\"gun_kind\", \"ammo_kind\", \"projectile_style\", \"projectile_behavior\", \"module_action_profile\"]:",
		"var reason_tags: Array = []\n\tfor raw_tag in tags:",
		"return _heat_reason_for_tags(_heat_tags_for_projectile_event(event), \"projectile\")",
	]:
		if main_source.find(stale_heat_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile heat fallback: %s" % stale_heat_parse)
			return
	for stale_trace_parse in [
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.web_trace_event(base_event, impact_position)",
		"var event := base_event.duplicate(true)\n\tevent[\"projectile_impact_position\"] = impact_position",
		"var payload := projectile_runtime_service.trace_payload(event, segment, attacker.position, _projectile_runtime_constants()) if projectile_runtime_service != null else _legacy_projectile_trace_payload(attacker, event, segment)",
		"func _legacy_projectile_trace_payload(attacker, event: Dictionary, segment: Dictionary) -> Dictionary:",
	]:
		if main_source.find(stale_trace_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile trace fallback: %s" % stale_trace_parse)
			return
	for stale_queue_parse in [
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.is_chemical_projectile_event(event)",
		"if projectile_runtime_service != null:\n\t\tvar prepared := projectile_runtime_service.prepared_chemical_projectile_event(event, _projectile_runtime_constants())",
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.chemical_firework_event(event)",
		"var queue_intent := projectile_runtime_service.chemical_queue_intent(event, event.get(\"direction\", _unit_forward_vector(attacker)), _unit_forward_vector(attacker), _projectile_runtime_constants()) if projectile_runtime_service != null else _legacy_chemical_queue_intent(attacker, event)",
		"func _legacy_chemical_queue_intent(attacker, event: Dictionary) -> Dictionary:",
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.chemical_projectile_travel_time(event, _projectile_runtime_constants())",
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.is_missile_projectile_event(event)",
		"if projectile_runtime_service != null:\n\t\treturn projectile_runtime_service.missile_projectile_travel_time(range_hint, event, _projectile_runtime_constants())",
		"var queue_intent := projectile_runtime_service.missile_queue_intent(shot_event, direction, target_distance, _projectile_runtime_constants()) if projectile_runtime_service != null else {}",
	]:
		if main_source.find(stale_queue_parse) >= 0:
			_fail("main.gd should not keep duplicate projectile queue fallback: %s" % stale_queue_parse)
			return
	var service = ProjectileRuntimeServiceScript.new()
	var constants := _constants()
	_assert_eq(service.projectile_behavior_for_data({"projectile_damage_type": "bullet", "projectile_style": "true_bullet"}), "true_bullet", "true bullet behavior")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam"}), "laser", "laser behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_damage_type": "chemical", "projectile_style": "spray"}), "chemical", "chemical behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_style": "missile", "projectile_behavior": "explosive"}), "explosive", "missile behavior key")
	_assert_eq(service.projectile_behavior_key({"projectile": true, "projectile_style": "web", "projectile_behavior": "web_tether", "travel_path": "tether"}), "web_tether", "web behavior key")
	_assert_eq(service.projectile_ammo_family({"ammo_kind": "bullet"}), "metal", "metal bullet family")
	_assert_eq(service.projectile_ammo_family({"ammo_kind": "laser"}), "electric", "laser compatibility family")
	_assert_eq(service.projectile_ammo_family({"ammo_kind": "electric"}), "electric", "electric family alias")
	_assert_eq(service.projectile_ammo_family({"ammo_kind": "chemical"}), "chemical", "chemical family")
	_assert_eq(service.projectile_ammo_family({"ammo_kind": "missile"}), "explosive", "missile family")
	if not service.projectile_uses_fixed_momentum({"ammo_kind": "laser"}) or not service.projectile_uses_fixed_momentum({"ammo_kind": "chemical"}):
		_fail("Electric/laser and chemical families should use fixed momentum.")
	if service.projectile_uses_fixed_momentum({"ammo_kind": "bullet"}):
		_fail("Metal bullet family should keep gun-supplied momentum.")
	var fixed_drive_fields: Dictionary = service.projectile_drive_momentum_fields({
		"projectile": true,
		"ammo_kind": "laser",
		"projectile_momentum": 99.0,
	})
	if absf(float(fixed_drive_fields.get("projectile_effective_momentum", 0.0)) - 1.0) > 0.001:
		_fail("Fixed-momentum ammo should ignore explicit drive momentum fields.")
	var ammo_types := ["bullet", "laser", "chemical", "explosive", "web"]
	_assert_eq(service.ammo_type_for_event({"ammo_kind": "missile"}, ammo_types), "explosive", "missile ammo alias")
	_assert_eq(service.ammo_type_for_event({"ammo_kind": "silk"}, ammo_types), "web", "silk ammo alias")
	_assert_eq(service.ammo_type_for_event({"ammo_kind": "unknown", "projectile_damage_type": "chemical"}, ammo_types), "chemical", "projectile damage ammo fallback")
	_assert_eq(service.ammo_type_for_event({"damage_type": "laser"}, ammo_types), "laser", "damage ammo fallback")
	_assert_eq(service.ammo_type_for_event({"ammo_kind": "unknown", "damage_type": "blunt"}, ammo_types), "", "unsupported ammo fallback")
	_assert_vec_close(service.event_vector_value({"momentum_vector": Vector2(3.0, 4.0)}, "momentum_vector"), Vector2(3.0, 4.0), "event vector value")
	_assert_vec_close(service.event_vector_value({"momentum_vector": "bad"}, "momentum_vector"), Vector2.ZERO, "event vector bad fallback")
	var inferred_momentum_patch: Dictionary = service.event_momentum_vector_patch(Vector2(3.0, 4.0))
	_assert_vec_close(inferred_momentum_patch.get("momentum_vector", Vector2.ZERO), Vector2(3.0, 4.0), "event momentum patch vector")
	if absf(float(inferred_momentum_patch.get("momentum_magnitude", 0.0)) - 5.0) > 0.001:
		_fail("Event momentum patch should infer vector length: %s" % str(inferred_momentum_patch))
	_assert_vec_close(inferred_momentum_patch.get("direction", Vector2.ZERO), Vector2(0.6, 0.8), "event momentum patch direction")
	var zero_magnitude_patch: Dictionary = service.event_momentum_vector_patch(Vector2(2.0, 0.0), 0.0)
	if absf(float(zero_magnitude_patch.get("momentum_magnitude", -1.0))) > 0.001 or zero_magnitude_patch.has("direction"):
		_fail("Event momentum patch should keep zero magnitude and omit direction: %s" % str(zero_magnitude_patch))
	var zero_vector_patch: Dictionary = service.event_momentum_vector_patch(Vector2.ZERO, 7.0)
	if absf(float(zero_vector_patch.get("momentum_magnitude", 0.0)) - 7.0) > 0.001 or zero_vector_patch.has("direction"):
		_fail("Event momentum patch should keep explicit magnitude and omit zero-vector direction: %s" % str(zero_vector_patch))
	if absf(service.event_momentum_magnitude({"momentum_vector": Vector2(3.0, 4.0), "momentum_magnitude": 2.0}, 1.0) - 5.0) > 0.001:
		_fail("Event momentum magnitude should prefer vector length.")
	if absf(service.event_momentum_magnitude({"momentum_magnitude": -2.0, "momentum": 7.0}, 1.0) - 0.0) > 0.001:
		_fail("Event momentum magnitude should clamp explicit magnitude before momentum fallback.")
	if absf(service.event_momentum_magnitude({"momentum": 7.0}, 1.0) - 7.0) > 0.001:
		_fail("Event momentum magnitude should fall back to momentum.")
	if absf(service.event_momentum_magnitude({}, -3.0) - 0.0) > 0.001:
		_fail("Event momentum magnitude should clamp fallback.")
	_assert_vec_close(service.event_direction_vector({"momentum_vector": Vector2(0.0, 2.0), "direction": Vector2.RIGHT}, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT), Vector2.DOWN, "event direction momentum priority")
	_assert_vec_close(service.event_direction_vector({"direction": Vector2(4.0, 0.0)}, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT), Vector2.RIGHT, "event direction explicit direction fallback")
	_assert_vec_close(service.event_direction_vector({}, Vector2(-3.0, 0.0), Vector2.DOWN, Vector2.RIGHT), Vector2.LEFT, "event direction target delta fallback")
	_assert_vec_close(service.event_direction_vector({}, Vector2.ZERO, Vector2(0.0, -2.0), Vector2.RIGHT), Vector2.UP, "event direction attacker forward fallback")
	_assert_vec_close(service.event_direction_vector({}, Vector2.ZERO, Vector2.ZERO, Vector2(2.0, 0.0)), Vector2.RIGHT, "event direction explicit fallback")
	_assert_vec_close(service.event_direction_vector({}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO), Vector2.RIGHT, "event direction hard fallback")
	var sniper := {"projectile": true, "projectile_behavior": "true_bullet", "projectile_style": "true_bullet", "projectile_momentum": 123.0}
	if absf(service.projectile_collision_speed_for_event(sniper, constants) - 32.0) > 0.001:
		_fail("Sniper speed should use true bullet constant.")
	if absf(service.projectile_mass_for_event(sniper, constants, 32.0) - (123.0 / 32.0)) > 0.001:
		_fail("Sniper mass should derive from explicit momentum and speed.")
	var sniper_state: Dictionary = service.projectile_momentum_state_for_event(sniper, constants)
	if absf(float(sniper_state.get("momentum", 0.0)) - 123.0) > 0.001:
		_fail("Sniper momentum should use explicit projectile_momentum.")
	var collision_intent: Dictionary = service.projectile_collision_momentum_intent({
		"projectile": true,
		"projectile_velocity": Vector2(30.0, 0.0),
		"fallback_direction": Vector2.RIGHT,
		"target_velocity": Vector2(10.0, 0.0),
		"projectile_mass": 2.5,
		"explicit_momentum": 0.0,
		"behavior_key": "bullet_hell",
		"momentum_scale": 0.5,
	})
	_assert_eq(String(collision_intent.get("action", "")), "resolve_projectile_collision_momentum", "projectile collision momentum action")
	if absf(float(collision_intent.get("momentum", 0.0)) - 25.0) > 0.001:
		_fail("Projectile collision momentum should use mass * closing speed * scale: %s" % str(collision_intent))
	var collision_patch: Dictionary = Dictionary(collision_intent.get("event_patch", {}))
	if absf(float(collision_patch.get("projectile_collision_speed", 0.0)) - 30.0) > 0.001 or absf(float(collision_patch.get("projectile_closing_speed", 0.0)) - 20.0) > 0.001:
		_fail("Projectile collision patch should expose speed and closing speed: %s" % str(collision_patch))
	_assert_vec_close(collision_patch.get("projectile_relative_velocity_vector", Vector2.ZERO), Vector2(20.0, 0.0), "projectile collision relative velocity")
	_assert_vec_close(collision_patch.get("momentum_vector", Vector2.ZERO), Vector2(25.0, 0.0), "projectile collision momentum vector")
	_assert_vec_close(collision_patch.get("direction", Vector2.ZERO), Vector2.RIGHT, "projectile collision direction patch")
	var true_bullet_collision: Dictionary = service.projectile_collision_momentum_intent({
		"projectile": true,
		"projectile_velocity": Vector2(3.0, 4.0),
		"fallback_direction": Vector2.RIGHT,
		"target_velocity": Vector2.ZERO,
		"projectile_mass": 2.0,
		"explicit_momentum": 123.0,
		"behavior_key": "true_bullet",
		"momentum_scale": 0.25,
	})
	if absf(float(true_bullet_collision.get("momentum", 0.0)) - 30.75) > 0.001:
		_fail("True bullet collision momentum should use explicit momentum override: %s" % str(true_bullet_collision))
	_assert_vec_close(Dictionary(true_bullet_collision.get("event_patch", {})).get("momentum_vector", Vector2.ZERO), Vector2(18.45, 24.6), "true bullet momentum vector")
	_assert_eq(String(service.projectile_collision_momentum_intent({"projectile": false}).get("reason", "")), "not_projectile", "projectile collision projectile gate")
	var hit_impact_intent: Dictionary = service.projectile_stagger_impact_position_intent({
		"hit_position_combat": Vector2(7.0, -0.25),
		"projectile_impact_position": Vector2(3.0, 4.0),
	}, Vector2(1.0, 2.0))
	_assert_eq(String(hit_impact_intent.get("action", "")), "resolve_projectile_stagger_impact_position", "projectile stagger impact action")
	_assert_eq(String(hit_impact_intent.get("source", "")), "hit_position_combat", "projectile stagger hit-position priority")
	_assert_vec_close(hit_impact_intent.get("position", Vector2.ZERO), Vector2(7.0, -0.25), "projectile stagger hit impact")
	var projectile_impact_intent: Dictionary = service.projectile_stagger_impact_position_intent({"projectile_impact_position": Vector2(3.0, 4.0)}, Vector2(1.0, 2.0))
	_assert_eq(String(projectile_impact_intent.get("source", "")), "projectile_impact_position", "projectile stagger projectile-position fallback")
	_assert_vec_close(projectile_impact_intent.get("position", Vector2.ZERO), Vector2(3.0, 4.0), "projectile stagger projectile impact")
	var fallback_impact_intent: Dictionary = service.projectile_stagger_impact_position_intent({"hit_position_combat": "bad"}, Vector2(1.0, 2.0))
	_assert_eq(String(fallback_impact_intent.get("source", "")), "target_position", "projectile stagger target-position fallback")
	_assert_vec_close(fallback_impact_intent.get("position", Vector2.ZERO), Vector2(1.0, 2.0), "projectile stagger fallback impact")
	if not service.projectile_consumes_on_first_hit({"projectile": true, "damage_type": "bullet", "projectile_style": "bullet"}, constants):
		_fail("Bullet projectile should consume on first hit.")
	if service.projectile_consumes_on_first_hit({"projectile": true, "damage_type": "bullet", "projectile_style": "web"}, constants):
		_fail("Web-style projectile should not consume on first hit.")
	if service.projectile_consumes_on_first_hit({"projectile": true, "damage_type": "bullet", "non_damage": true}, constants):
		_fail("Non-damage projectile should not consume on first hit.")
	if not service.projectile_consumes_on_first_hit({"projectile": true, "damage_type": "", "projectile_style": "missile"}, constants):
		_fail("Missile style should consume on first hit even without damage type.")
	if service.projectile_consumes_on_first_hit({"projectile": false, "damage_type": "bullet", "projectile_style": "bullet"}, constants):
		_fail("Non-projectile event should not consume on first hit.")
	var bullet := {"projectile": true, "projectile_damage_type": "bullet", "projectile_style": "bullet_hell", "projectile_speed_mult": 2.8}
	if absf(service.projectile_collision_speed_for_event(bullet, constants) - 16.8) > 0.001:
		_fail("Bullet hell speed should be speed_mult * unit.")
	if absf(service.projectile_mass_for_event(bullet, constants) - 2.85) > 0.001:
		_fail("Bullet hell mass should use default mass.")
	var laser := {"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam"}
	if absf(service.projectile_default_momentum_for_event(laser, constants) - 1.0) > 0.001:
		_fail("Laser projectile default momentum should be fixed to 1.")
	if absf(service.projectile_mass_for_event(laser, constants, 60.0) - (1.0 / 60.0)) > 0.001:
		_fail("Laser projectile mass should derive from fixed momentum 1.")
	if absf(service.projectile_mass_for_event({"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam", "projectile_mass": 9.0}, constants, 60.0) - (1.0 / 60.0)) > 0.001:
		_fail("Laser projectile mass should ignore explicit mass and preserve fixed momentum 1.")
	var laser_state: Dictionary = service.projectile_momentum_state_for_event({"projectile": true, "projectile_damage_type": "laser", "projectile_style": "beam", "projectile_momentum": 99.0}, constants)
	if absf(float(laser_state.get("momentum", 0.0)) - 1.0) > 0.001:
		_fail("Laser momentum state should ignore explicit projectile_momentum and stay fixed at 1.")
	var chemical_state: Dictionary = service.projectile_momentum_state_for_event({"projectile": true, "projectile_damage_type": "chemical", "projectile_style": "spray", "projectile_momentum": 44.0}, constants)
	if absf(float(chemical_state.get("momentum", 0.0)) - 1.0) > 0.001:
		_fail("Chemical momentum state should ignore explicit projectile_momentum and stay fixed at 1.")
	var electric_alias_state: Dictionary = service.projectile_momentum_state_for_event({
		"projectile": true,
		"ammo_kind": "electric",
		"projectile_damage_type": "bullet",
		"projectile_style": "bullet_hell",
		"projectile_momentum": 77.0,
		"projectile_mass": 12.0,
	}, constants)
	if absf(float(electric_alias_state.get("momentum", 0.0)) - 1.0) > 0.001:
		_fail("Electric ammo alias should force momentum 1 even when projectile behavior looks ballistic.")
	if absf(service.projectile_mass_for_event({
		"projectile": true,
		"ammo_kind": "chemical",
		"projectile_damage_type": "bullet",
		"projectile_style": "bullet_hell",
		"projectile_mass": 9.0,
		"projectile_momentum": 44.0,
	}, constants, 12.0) - (1.0 / 12.0)) > 0.001:
		_fail("Chemical ammo family should ignore explicit mass and momentum.")
	var chemical_collision: Dictionary = service.projectile_collision_momentum_intent({
		"projectile": true,
		"projectile_velocity": Vector2(12.0, 0.0),
		"fallback_direction": Vector2.RIGHT,
		"target_velocity": Vector2.ZERO,
		"projectile_mass": 3.0,
		"explicit_momentum": 44.0,
		"behavior_key": "chemical",
		"momentum_scale": 1.0,
	})
	if absf(float(chemical_collision.get("momentum", 0.0)) - 1.0) > 0.001:
		_fail("Chemical collision momentum should stay fixed at 1: %s" % str(chemical_collision))
	if absf(service.default_recoil_transfer_for_projectile(laser) - 0.35) > 0.001:
		_fail("Laser recoil transfer should be low.")
	if absf(service.gun_projectile_damage_mult_max_for_data({"gun_kind": "laser_gun"}, "laser_gun", "laser", constants) - 54.0) > 0.001:
		_fail("Laser gun max multiplier should be 54.")
	var coeffs: Dictionary = service.projectile_damage_coeffs_for_event({"projectile": true, "gun_drive_allocated": 5.0, "gun_drive_max": 10.0}, "rifle", "bullet", constants, Callable(self, "_gun_mult_for_probe"))
	if absf(float(coeffs.get("gun", 0.0)) - 2.0) > 0.001:
		_fail("Gun current multiplier should use callback ratio.")
	if absf(service.projectile_raw_damage_for_momentum({"projectile": true, "gun_drive_allocated": 5.0, "gun_drive_max": 10.0}, 40.0, "rifle", "bullet", constants, Callable(self, "_gun_mult_for_probe")) - 80.0) > 0.001:
		_fail("Raw projectile damage should be momentum * gun multiplier.")
	var recoil_intent: Dictionary = service.weapon_recoil_intent({
		"projectile": true,
		"weapon_recoil_applied": false,
		"projectile_velocity": Vector2(3.0, 4.0),
		"launch_momentum": 50.0,
		"shooter_mass": 10.0,
	})
	_assert_eq(String(recoil_intent.get("action", "")), "apply_weapon_recoil", "weapon recoil action")
	_assert_vec_close(recoil_intent.get("direction", Vector2.ZERO), Vector2(0.6, 0.8), "weapon recoil direction")
	if absf(float(recoil_intent.get("recoil_amount", 0.0)) - 5.0) > 0.001:
		_fail("Weapon recoil amount should be launch momentum / mass: %s" % str(recoil_intent))
	var recoil_patch: Dictionary = Dictionary(recoil_intent.get("event_patch", {}))
	if not bool(recoil_patch.get("weapon_recoil_applied", false)):
		_fail("Weapon recoil intent should mark event as applied: %s" % str(recoil_patch))
	if absf(float(recoil_patch.get("weapon_recoil_momentum", 0.0)) - 50.0) > 0.001 or absf(float(recoil_patch.get("weapon_recoil_amount", 0.0)) - 5.0) > 0.001:
		_fail("Weapon recoil event patch should expose momentum and amount: %s" % str(recoil_patch))
	_assert_vec_close(recoil_patch.get("weapon_recoil_direction", Vector2.ZERO), Vector2(-0.6, -0.8), "weapon recoil patch direction")
	_assert_eq(String(service.weapon_recoil_intent({"projectile": false}).get("reason", "")), "not_projectile", "weapon recoil projectile gate")
	_assert_eq(String(service.weapon_recoil_intent({"projectile": true, "weapon_recoil_applied": true}).get("reason", "")), "already_applied", "weapon recoil applied gate")
	_assert_eq(String(service.weapon_recoil_intent({"projectile": true, "projectile_velocity": Vector2.ZERO, "launch_momentum": 50.0}).get("reason", "")), "no_velocity", "weapon recoil velocity gate")
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
		"projectile_damage_types": ["bullet", "chemical", "laser", "explosion"],
	}


func _gun_mult_for_probe(max_multiplier: float, allocated: float, maximum: float, non_damage: bool) -> float:
	if non_damage:
		return 0.0
	return max_multiplier if maximum <= 0.001 else max_multiplier * clampf(allocated, 0.0, maximum) / maximum


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual)])


func _assert_vec_close(actual, expected: Vector2, label: String) -> void:
	if not (actual is Vector2):
		_fail("%s expected Vector2, got %s." % [label, str(actual)])
		return
	var actual_vec: Vector2 = actual
	if actual_vec.distance_to(expected) > 0.001:
		_fail("%s expected %s, got %s." % [label, str(expected), str(actual_vec)])
