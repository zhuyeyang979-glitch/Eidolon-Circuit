extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const GunActivationService := preload("res://scripts/services/gun_activation_service.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _constants() -> Dictionary:
	return {
		"standard_sniper_projectile_width_m": 0.11,
		"standard_chemical_sprayer_width_m": 0.22,
		"standard_chemical_sprayer_range_m": 1.7,
		"standard_chemical_sprayer_fire_interval": 0.31,
		"standard_laser_width_m": 0.19,
		"standard_laser_range_m": 4.7,
		"standard_laser_fire_interval": 0.08,
		"standard_missile_width_m": 0.27,
		"standard_missile_range_m": 6.2,
		"standard_web_tether_width_m": 0.16,
		"standard_web_tether_range_m": 5.4,
	}


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/gun_activation_service.gd")
	if source.is_empty():
		_fail("Unable to read GunActivationService.")
	for forbidden in [
		"Input.",
		"FileAccess",
		"DirAccess",
		"JSON.parse_string",
		"extends Node",
		"extends Control",
		"active_units",
		"all_units",
		"gun_activation_state",
		"_resolve_attack",
		"_queue_true_bullet_lock",
		"_show_battle_message",
		"set_aim_pose",
		"FighterScene",
		"UnitScene",
	]:
		if source.contains(forbidden):
			_fail("GunActivationService contains forbidden token: %s" % forbidden)
	var service := GunActivationService.new()
	var sniper: Dictionary = service.gun_activation_spec("sniper", "gun_activate", _constants())
	_assert(String(sniper.get("semantic", "")) == "release_lock", "Sniper spec semantic mismatch: %s" % str(sniper))
	_assert(String(sniper.get("projectile_behavior", "")) == "true_bullet", "Sniper spec behavior mismatch: %s" % str(sniper))
	_assert(absf(float(sniper.get("default_width", 0.0)) - 0.11) < 0.001, "Sniper spec should use injected width constants: %s" % str(sniper))
	var rifle: Dictionary = service.gun_activation_spec("rifle", "rifle_burst_activate", _constants())
	_assert(String(rifle.get("semantic", "")) == "hold_burst", "Rifle spec semantic mismatch: %s" % str(rifle))
	_assert(String(rifle.get("projectile_style", "")) == "bullet_hell", "Rifle spec style mismatch: %s" % str(rifle))
	_assert(service.gun_activation_spec("rifle", "gun_activate", _constants()).is_empty(), "Service should require an effective native profile for rifle specs.")
	var laser: Dictionary = service.gun_activation_spec("laser_gun", "laser_beam_activate", _constants())
	_assert(absf(float(laser.get("default_range", 0.0)) - 4.7) < 0.001, "Laser spec should use injected range constants: %s" % str(laser))
	var missile: Dictionary = service.gun_activation_spec("missile_launcher", "missile_lock_activate", _constants())
	_assert(String(missile.get("semantic", "")) == "release_missile_lock", "Missile spec semantic mismatch: %s" % str(missile))
	var web: Dictionary = service.gun_activation_spec("web_gun", "web_tether_activate", _constants())
	_assert(String(web.get("travel_path", "")) == "tether", "Web spec travel path mismatch: %s" % str(web))
	if not service.has_method("gun_activation_profile_supports_kind"):
		_fail("GunActivationService missing gun_activation_profile_supports_kind.")
	else:
		_assert(service.gun_activation_profile_supports_kind("gun_activate", "rifle", "bullet", true, rifle), "Generic gun_activate should allow registry-supported effective rifle spec.")
		_assert(service.gun_activation_profile_supports_kind("laser_beam_activate", "laser_gun", "laser", true, laser), "Laser profile should support laser gun + laser ammo.")
		_assert(not service.gun_activation_profile_supports_kind("laser_beam_activate", "rifle", "bullet", true, laser), "Laser profile should reject rifle + bullet.")
		_assert(not service.gun_activation_profile_supports_kind("rifle_burst_activate", "rifle", "explosive", true, rifle), "Rifle burst should reject non-bullet ammo.")
		_assert(not service.gun_activation_profile_supports_kind("missile_lock_activate", "missile_launcher", "bullet", true, missile), "Missile lock should require explosive ammo.")
		_assert(not service.gun_activation_profile_supports_kind("web_tether_activate", "web_gun", "web", false, web), "Registry rejection should override matching service spec.")
		_assert(not service.gun_activation_profile_supports_kind("web_tether_activate", "web_gun", "web", true, {}), "Empty activation spec should reject support.")
	if not service.has_method("activation_profile_gate"):
		_fail("GunActivationService missing activation_profile_gate.")
	else:
		var empty_profile_gate: Dictionary = service.activation_profile_gate("", rifle, true)
		_assert(not bool(empty_profile_gate.get("can_start", true)) and String(empty_profile_gate.get("reason", "")) == "empty_effective_profile", "Activation profile gate should reject empty effective profile: %s" % str(empty_profile_gate))
		var empty_spec_gate: Dictionary = service.activation_profile_gate("rifle_burst_activate", {}, true)
		_assert(not bool(empty_spec_gate.get("can_start", true)) and String(empty_spec_gate.get("reason", "")) == "empty_spec", "Activation profile gate should reject empty activation spec: %s" % str(empty_spec_gate))
		var unsupported_gate: Dictionary = service.activation_profile_gate("rifle_burst_activate", rifle, false)
		_assert(not bool(unsupported_gate.get("can_start", true)) and String(unsupported_gate.get("reason", "")) == "unsupported_profile", "Activation profile gate should reject registry-unsupported profiles: %s" % str(unsupported_gate))
		var supported_gate: Dictionary = service.activation_profile_gate("rifle_burst_activate", rifle, true)
		_assert(bool(supported_gate.get("can_start", false)) and String(supported_gate.get("reason", "")) == "" and String(supported_gate.get("effective_profile", "")) == "rifle_burst_activate", "Activation profile gate should accept supported effective profile/spec: %s" % str(supported_gate))
	_assert(service.gun_aim_input_mode_for_data({"gun_aim_input_mode": "face_keys"}, []) == "turn_keys", "face_keys should normalize to turn_keys.")
	_assert(service.gun_aim_input_mode_for_data({"aim_input_mode": "movement_keys"}, []) == "direction_keys", "movement_keys should normalize to direction_keys.")
	_assert(service.gun_aim_input_mode_for_data({"turn_keys_steer_joint": true}, []) == "turn_keys", "turn_keys_steer_joint should select turn_keys.")
	_assert(service.gun_aim_input_mode_for_data({"module_action_profile": "rifle_burst_activate"}, ["rifle_burst_activate"]) == "turn_keys", "Projectile profiles should default to turn_keys.")
	_assert(service.gun_aim_input_mode_for_data({"motion": "gun_activate"}, []) == "turn_keys", "gun_activate motion should default to turn_keys.")
	_assert(service.gun_aim_input_mode_for_data({}, []) == "direction_keys", "Non-gun data should default to direction_keys.")
	if not service.has_method("runtime_binding_profile"):
		_fail("GunActivationService missing runtime_binding_profile.")
	else:
		_assert(service.runtime_binding_profile({"module_part": {"module_action_profile": "laser_beam_activate"}}) == "laser_beam_activate", "Binding profile should read module_part fallback.")
		_assert(service.runtime_binding_profile({"module_part": {"module_action_profile": "laser_beam_activate"}, "module_action_profile": "rifle_burst_activate"}) == "rifle_burst_activate", "Binding profile should prefer top-level binding profile.")
	if not service.has_method("runtime_binding_is_gun_activation"):
		_fail("GunActivationService missing runtime_binding_is_gun_activation.")
	else:
		_assert(service.runtime_binding_is_gun_activation({"module_part": {"module_action_profile": "laser_beam_activate"}}, ["laser_beam_activate"]) == true, "Binding should classify projectile activation from module_part profile.")
		_assert(service.runtime_binding_is_gun_activation({"module_action_profile": "boot_action_driver"}, ["laser_beam_activate"]) == false, "Non-projectile binding should not classify as gun activation.")
	if not service.has_method("runtime_binding_gun_aim_input_mode"):
		_fail("GunActivationService missing runtime_binding_gun_aim_input_mode.")
	else:
		_assert(service.runtime_binding_gun_aim_input_mode({"module_part": {"module_action_profile": "laser_beam_activate", "gun_aim_input_mode": "movement_keys"}}, ["laser_beam_activate"]) == "direction_keys", "Binding aim mode should preserve module_part explicit movement key mode.")
		_assert(service.runtime_binding_gun_aim_input_mode({"module_part": {"module_action_profile": "laser_beam_activate"}, "gun_aim_input_mode": "face_keys"}, ["laser_beam_activate"]) == "turn_keys", "Binding aim mode should let top-level fields override module_part.")
		_assert(service.runtime_binding_gun_aim_input_mode({"module_action_profile": "boot_action_driver"}, ["laser_beam_activate"]) == "", "Non-projectile binding aim mode should be empty.")
	if not service.has_method("runtime_binding_gun_mobility_contract"):
		_fail("GunActivationService missing runtime_binding_gun_mobility_contract.")
	else:
		var mobility := {"move_while_firing": true, "direction_boost_while_firing": true}
		var gated_mobility: Dictionary = service.runtime_binding_gun_mobility_contract({"module_action_profile": "laser_beam_activate"}, ["laser_beam_activate"], mobility)
		_assert(bool(gated_mobility.get("move_while_firing", false)) and bool(gated_mobility.get("direction_boost_while_firing", false)), "Gun binding mobility contract should pass through registry contract: %s" % str(gated_mobility))
		mobility["direction_boost_while_firing"] = false
		_assert(bool(gated_mobility.get("direction_boost_while_firing", false)), "Mobility contract should be duplicated, not aliased.")
		_assert(service.runtime_binding_gun_mobility_contract({"module_action_profile": "boot_action_driver"}, ["laser_beam_activate"], {"direction_boost_while_firing": true}).is_empty(), "Non-gun binding mobility contract should be empty.")
	if not service.has_method("active_direction_boost_allowed"):
		_fail("GunActivationService missing active_direction_boost_allowed.")
	else:
		_assert(not service.active_direction_boost_allowed({}, {"direction_boost_while_firing": true}), "Empty active state should not allow direction boost.")
		_assert(service.active_direction_boost_allowed({"direction_boost_while_firing": true}, {"direction_boost_while_firing": false}), "State boost flag should override binding contract.")
		_assert(not service.active_direction_boost_allowed({"direction_boost_while_firing": false}, {"direction_boost_while_firing": true}), "False state boost flag should override binding contract.")
		_assert(service.active_direction_boost_allowed({"binding": {"module_action_profile": "laser_beam_activate"}}, {"direction_boost_while_firing": true}), "Binding mobility contract should allow direction boost when state has no override.")
	if not service.has_method("activation_state_active"):
		_fail("GunActivationService missing activation_state_active.")
	else:
		_assert(not service.activation_state_active({}), "Empty gun activation state should not be active.")
		_assert(service.activation_state_active({"action_name": "p1_attack_1"}), "Non-empty gun activation state should be active.")
	_assert(service.gun_drive_aim_speed_mult(0.45) < service.gun_drive_aim_speed_mult(1.8), "Gun drive should improve aim speed multiplier.")
	if not service.has_method("activation_rotate_speed"):
		_fail("GunActivationService missing activation_rotate_speed.")
	else:
		var explicit_speed: float = service.activation_rotate_speed({"gun_rotate_speed": 3.0}, 5.0, 1.0)
		_assert(absf(float(explicit_speed) - 3.0) < 0.001, "Activation rotate speed should preserve explicit module speed at neutral drive: %s" % str(explicit_speed))
		var fallback_speed: float = service.activation_rotate_speed({}, 4.0, 1.0)
		_assert(absf(float(fallback_speed) - 4.0) < 0.001, "Activation rotate speed should use default turn speed when module speed is empty: %s" % str(fallback_speed))
		var negative_speed: float = service.activation_rotate_speed({"gun_rotate_speed": -2.0}, 4.0, 1.0)
		_assert(absf(float(negative_speed) - 4.0) < 0.001, "Activation rotate speed should use default turn speed for negative module speed: %s" % str(negative_speed))
		var low_drive_speed: float = service.activation_rotate_speed({"gun_rotate_speed": 4.0}, 5.0, 0.45)
		var high_drive_speed: float = service.activation_rotate_speed({"gun_rotate_speed": 4.0}, 5.0, 1.8)
		_assert(low_drive_speed < 4.0 and high_drive_speed > 4.0, "Activation rotate speed should apply gun drive aim multiplier: low=%s high=%s" % [str(low_drive_speed), str(high_drive_speed)])
	if not service.has_method("activation_source_gate"):
		_fail("GunActivationService missing activation_source_gate.")
	else:
		var empty_source_gate: Dictionary = service.activation_source_gate({})
		_assert(not bool(empty_source_gate.get("can_start", true)) and String(empty_source_gate.get("reason", "")) == "missing_source", "Empty activation source gate should reject missing source: %s" % str(empty_source_gate))
		var melee_source_gate: Dictionary = service.activation_source_gate({"terminal_weapon_kind": "melee", "projectile": true})
		_assert(not bool(melee_source_gate.get("can_start", true)) and String(melee_source_gate.get("reason", "")) == "not_ranged_terminal", "Activation source gate should reject non-ranged terminals: %s" % str(melee_source_gate))
		var non_projectile_gate: Dictionary = service.activation_source_gate({"terminal_weapon_kind": "ranged", "projectile": false})
		_assert(not bool(non_projectile_gate.get("can_start", true)) and String(non_projectile_gate.get("reason", "")) == "not_projectile_terminal", "Activation source gate should reject ranged non-projectile terminals: %s" % str(non_projectile_gate))
		var valid_source_gate: Dictionary = service.activation_source_gate({"terminal_weapon_kind": " RANGED ", "projectile": true, "source_gun_node": 7})
		_assert(bool(valid_source_gate.get("can_start", false)) and String(valid_source_gate.get("reason", "")) == "" and String(valid_source_gate.get("terminal_weapon_kind", "")) == "ranged", "Activation source gate should accept ranged projectile terminal and normalize kind: %s" % str(valid_source_gate))
	if not service.has_method("binding_drive_allocation_for_node"):
		_fail("GunActivationService missing binding_drive_allocation_for_node.")
	else:
		_assert(absf(float(service.binding_drive_allocation_for_node({"joint_drive_allocation_by_node": {"7": 44.0}}, 7, 12.0)) - 44.0) < 0.001, "String node drive allocation mismatch.")
		_assert(absf(float(service.binding_drive_allocation_for_node({"allocated_limb_momentum_by_node": {7: 55.0}}, 7, 12.0)) - 55.0) < 0.001, "Integer node drive allocation mismatch.")
		_assert(absf(float(service.binding_drive_allocation_for_node({"joint_drive_allocation_total": 90.0, "target_nodes": [1, 2, 7]}, 7, 12.0)) - 30.0) < 0.001, "Total drive allocation should split by target count.")
		_assert(absf(float(service.binding_drive_allocation_for_node({}, 7, 12.0)) - 12.0) < 0.001, "Drive allocation should use fallback when no binding fields exist.")
	if not service.has_method("gun_drive_info_for_segment"):
		_fail("GunActivationService missing gun_drive_info_for_segment.")
	else:
		var drive_info: Dictionary = service.gun_drive_info_for_segment({
			"momentum_min": 20.0,
			"momentum_max": 120.0,
			"allocated_limb_momentum": 84.0,
		}, {
			"joint_drive_allocation_by_node": {"7": 180.0},
			"target_nodes": [7],
		}, 7)
		_assert(absf(float(drive_info.get("allocated", 0.0)) - 120.0) < 0.001, "Drive info should clamp allocation to max: %s" % str(drive_info))
		_assert(absf(float(drive_info.get("ratio", 0.0)) - 6.0) < 0.001, "Drive info ratio mismatch: %s" % str(drive_info))
		_assert(absf(float(drive_info.get("ratio_to_max", 0.0)) - 1.0) < 0.001, "Drive info ratio-to-max mismatch: %s" % str(drive_info))
		var fallback_drive: Dictionary = service.gun_drive_info_for_segment({"momentum_min": 12.0, "momentum_max": 36.0, "joint_output_momentum_base": 24.0}, {}, 3)
		_assert(absf(float(fallback_drive.get("allocated", 0.0)) - 24.0) < 0.001, "Drive info should use segment fallback: %s" % str(fallback_drive))
	if not service.has_method("runtime_gun_group_payload"):
		_fail("GunActivationService missing runtime_gun_group_payload.")
	else:
		var raw_group := {"material_class": "wood", "shape": "", "gun_kind": "rifle"}
		var group_payload: Dictionary = service.runtime_gun_group_payload(raw_group, {
			"allocated": 42.0,
			"min": 12.0,
			"max": 84.0,
			"ratio": 3.5,
			"ratio_to_max": 0.5,
		})
		_assert(bool(group_payload.get("projectile", false)) and bool(group_payload.get("projectile_only", false)), "Runtime gun group payload should mark projectile-only source: %s" % str(group_payload))
		_assert(String(group_payload.get("material_class", "")) == "gun", "Runtime gun group payload should normalize non-gun material class: %s" % str(group_payload))
		_assert(String(group_payload.get("shape", "")) == "rifle", "Runtime gun group payload should fill empty shape fallback: %s" % str(group_payload))
		_assert(absf(float(group_payload.get("gun_drive_allocated", 0.0)) - 42.0) < 0.001 and absf(float(group_payload.get("gun_drive_ratio_to_max", 0.0)) - 0.5) < 0.001, "Runtime gun group payload should copy drive fields: %s" % str(group_payload))
		raw_group["shape"] = "mutated"
		_assert(String(group_payload.get("shape", "")) == "rifle", "Runtime gun group payload should duplicate group fields, not alias raw input.")
		var missile_group: Dictionary = service.runtime_gun_group_payload({"material_class": "missile_launcher", "shape": "missile_rack"}, {})
		_assert(String(missile_group.get("material_class", "")) == "missile_launcher" and String(missile_group.get("shape", "")) == "missile_rack", "Runtime gun group payload should preserve explicit gun material/shape: %s" % str(missile_group))
	if not service.has_method("activation_direction"):
		_fail("GunActivationService missing activation_direction.")
	else:
		var segment_direction: Vector2 = service.activation_direction({"a": Vector2(2.0, 1.0), "b": Vector2(2.0, 4.0)}, Vector2.LEFT)
		_assert(segment_direction.distance_to(Vector2.DOWN) < 0.001, "Activation direction should use normalized segment b-a: %s" % str(segment_direction))
		var degenerate_direction: Vector2 = service.activation_direction({"a": Vector2(1.0, 1.0), "b": Vector2(1.0, 1.0)}, Vector2.LEFT)
		_assert(degenerate_direction.distance_to(Vector2.LEFT) < 0.001, "Activation direction should use fallback for degenerate segments: %s" % str(degenerate_direction))
		var empty_direction: Vector2 = service.activation_direction({}, Vector2.ZERO)
		_assert(empty_direction.distance_to(Vector2.RIGHT) < 0.001, "Activation direction should use a stable right vector when segment and fallback are empty: %s" % str(empty_direction))
	if not service.has_method("activation_event_direction"):
		_fail("GunActivationService missing activation_event_direction.")
	else:
		var state_direction: Vector2 = service.activation_event_direction({"aim_direction": Vector2(0.0, -4.0)}, Vector2.RIGHT, Vector2.LEFT)
		_assert(state_direction.distance_to(Vector2.UP) < 0.001, "Activation event direction should prefer normalized active aim direction: %s" % str(state_direction))
		var binding_direction: Vector2 = service.activation_event_direction({"aim_direction": Vector2.ZERO}, Vector2.DOWN, Vector2.LEFT)
		_assert(binding_direction.distance_to(Vector2.DOWN) < 0.001, "Activation event direction should fall back to materialized binding direction: %s" % str(binding_direction))
		var forward_direction: Vector2 = service.activation_event_direction({"aim_direction": "bad"}, Vector2.ZERO, Vector2.LEFT)
		_assert(forward_direction.distance_to(Vector2.LEFT) < 0.001, "Activation event direction should fall back to unit forward direction: %s" % str(forward_direction))
		var stable_direction: Vector2 = service.activation_event_direction({}, Vector2.ZERO, Vector2.ZERO)
		_assert(stable_direction.distance_to(Vector2.RIGHT) < 0.001, "Activation event direction should use a stable right vector when all inputs are empty: %s" % str(stable_direction))
	if not service.has_method("activation_event_source_identity"):
		_fail("GunActivationService missing activation_event_source_identity.")
	else:
		var binding_targets := [1, 4]
		var binding_identity: Dictionary = service.activation_event_source_identity({"target_nodes": binding_targets, "attack_key": 2})
		_assert(int(binding_identity.get("source_gun_node", -1)) == 4 and int(binding_identity.get("source_node_index", -1)) == 4, "Activation event source identity should use final binding target node: %s" % str(binding_identity))
		binding_targets.append(8)
		_assert(Array(binding_identity.get("runtime_target_nodes", [])).size() == 2, "Activation event source identity should duplicate binding target nodes: %s" % str(binding_identity))
		var attack_key_identity: Dictionary = service.activation_event_source_identity({"attack_key": 3})
		_assert(int(attack_key_identity.get("source_gun_node", -1)) == 2 and Array(attack_key_identity.get("runtime_target_nodes", [])).is_empty(), "Activation event source identity should fall back to attack_key - 1 when no target nodes exist: %s" % str(attack_key_identity))
		var source_targets := [2, 9]
		var source_identity: Dictionary = service.activation_event_source_identity({"target_nodes": [1, 4], "attack_key": 2}, {"runtime_target_nodes": source_targets, "source_gun_node": 9})
		_assert(int(source_identity.get("source_gun_node", -1)) == 9 and int(source_identity.get("source_node_index", -1)) == 9, "Activation event source identity should prefer gun_source node: %s" % str(source_identity))
		source_targets.append(99)
		_assert(Array(source_identity.get("runtime_target_nodes", [])).size() == 2 and int(Array(source_identity.get("runtime_target_nodes", []))[1]) == 9, "Activation event source identity should duplicate gun_source target nodes: %s" % str(source_identity))
		var source_node_fallback: Dictionary = service.activation_event_source_identity({"attack_key": 5}, {"source_node_index": 6})
		_assert(int(source_node_fallback.get("source_gun_node", -1)) == 6 and int(source_node_fallback.get("source_node_index", -1)) == 6, "Activation event source identity should use source_node_index fallback when source_gun_node is absent: %s" % str(source_node_fallback))
	if not service.has_method("runtime_gun_source_payload"):
		_fail("GunActivationService missing runtime_gun_source_payload.")
	else:
		var ranged_source: Dictionary = service.runtime_gun_source_payload(
			{"terminal_weapon_kind": "ranged", "projectile": true, "a": Vector2(1.0, 2.0), "b": Vector2(4.0, 2.0)},
			{"material_class": "gun", "shape": "rifle"},
			9,
			[1, 9],
			Vector2.ZERO,
			Vector2.UP
		)
		_assert(int(ranged_source.get("source_gun_node", -1)) == 9 and int(ranged_source.get("source_node_index", -1)) == 9, "Runtime gun source should preserve source node: %s" % str(ranged_source))
		_assert(Array(ranged_source.get("runtime_target_nodes", [])).size() == 2 and int(Array(ranged_source.get("runtime_target_nodes", []))[1]) == 9, "Runtime gun source should duplicate target nodes: %s" % str(ranged_source))
		_assert(Vector2(ranged_source.get("muzzle_combat_position", Vector2.ZERO)).distance_to(Vector2(4.0, 2.0)) < 0.001, "Runtime gun source should preserve muzzle combat position: %s" % str(ranged_source))
		_assert(Vector2(ranged_source.get("muzzle_direction", Vector2.ZERO)).distance_to(Vector2.RIGHT) < 0.001, "Runtime gun source should use normalized segment direction: %s" % str(ranged_source))
		var missile_source: Dictionary = service.runtime_gun_source_payload(
			{"a": Vector2(3.0, 3.0), "b": Vector2(3.0, 3.0)},
			{"material_class": "missile_launcher"},
			4,
			[4],
			Vector2(3.0, 3.0),
			Vector2.LEFT
		)
		_assert(not missile_source.is_empty() and Vector2(missile_source.get("muzzle_direction", Vector2.ZERO)).distance_to(Vector2.LEFT) < 0.001, "Missile material should classify as gun source and use fallback direction: %s" % str(missile_source))
		_assert(service.runtime_gun_source_payload({"terminal_weapon_kind": "melee", "a": Vector2.ZERO, "b": Vector2.RIGHT}, {"material_class": "weapon"}, 2, [2], Vector2.ZERO, Vector2.RIGHT).is_empty(), "Non-projectile melee weapon should not classify as runtime gun source.")
	var rotated_right: Vector2 = service.rotated_direction(Vector2.RIGHT, Vector2.RIGHT, 2.0, 0.25, Vector2.LEFT)
	_assert(rotated_right.angle() > 0.01, "Right turn input should rotate aim positively: %s" % str(rotated_right))
	var unchanged: Vector2 = service.rotated_direction(Vector2.RIGHT, Vector2.UP, 2.0, 0.25, Vector2.LEFT)
	_assert(unchanged.distance_to(Vector2.RIGHT) < 0.001, "Vertical input should not rotate aim: %s" % str(unchanged))
	if not service.has_method("should_release_activation"):
		_fail("GunActivationService missing should_release_activation.")
	else:
		_assert(service.should_release_activation("", false, true), "Empty action name should release gun activation.")
		_assert(service.should_release_activation("p1_attack_1", true, true), "Just released action should release gun activation.")
		_assert(service.should_release_activation("p1_attack_1", false, false), "Unpressed action should release gun activation.")
		_assert(not service.should_release_activation("p1_attack_1", false, true), "Pressed non-released action should keep gun activation.")
	if not service.has_method("tick_state_payload"):
		_fail("GunActivationService missing tick_state_payload.")
	else:
		var ticked: Dictionary = service.tick_state_payload({"hold_time": 0.25, "aim_input_mode": ""}, 0.125, "direction_keys")
		_assert(absf(float(ticked.get("hold_time", 0.0)) - 0.375) < 0.001, "Gun tick payload should add delta to hold_time: %s" % str(ticked))
		_assert(String(ticked.get("aim_input_mode", "")) == "turn_keys", "Gun tick payload should preserve the legacy turn-key default when state mode exists but is empty: %s" % str(ticked))
		var fallback_tick: Dictionary = service.tick_state_payload({"hold_time": 0.25}, 0.125, "direction_keys")
		_assert(String(fallback_tick.get("aim_input_mode", "")) == "direction_keys", "Gun tick payload should use fallback aim mode only when state mode is absent: %s" % str(fallback_tick))
		var clamped_tick: Dictionary = service.tick_state_payload({"hold_time": -0.25, "aim_input_mode": "TURN_KEYS", "binding": {"attack_key": 2}}, -1.0, "")
		_assert(absf(float(clamped_tick.get("hold_time", 1.0))) < 0.001, "Gun tick payload should clamp negative hold time and delta: %s" % str(clamped_tick))
		_assert(String(clamped_tick.get("aim_input_mode", "")) == "turn_keys", "Gun tick payload should lowercase existing aim mode: %s" % str(clamped_tick))
		_assert(int(Dictionary(clamped_tick.get("binding", {})).get("attack_key", 0)) == 2, "Gun tick payload should preserve duplicated state fields: %s" % str(clamped_tick))
	if not service.has_method("continuous_fire_timer_intent"):
		_fail("GunActivationService missing continuous_fire_timer_intent.")
	else:
		var waiting_fire: Dictionary = service.continuous_fire_timer_intent({"fire_timer": 0.4, "binding": {"attack_key": 1}}, 0.125, {"fire_interval": 0.18})
		var waiting_state: Dictionary = waiting_fire.get("state", {}) if waiting_fire.get("state", {}) is Dictionary else {}
		_assert(not bool(waiting_fire.get("fire_due", true)), "Continuous fire timer should not fire before timer reaches zero: %s" % str(waiting_fire))
		_assert(absf(float(waiting_state.get("fire_timer", 0.0)) - 0.275) < 0.001, "Continuous fire timer should subtract delta while waiting: %s" % str(waiting_fire))
		_assert(int(Dictionary(waiting_state.get("binding", {})).get("attack_key", 0)) == 1, "Continuous fire timer should preserve state fields: %s" % str(waiting_fire))
		var due_fire: Dictionary = service.continuous_fire_timer_intent({"fire_timer": 0.1}, 0.125, {"fire_interval": 0.18})
		var due_state: Dictionary = due_fire.get("state", {}) if due_fire.get("state", {}) is Dictionary else {}
		_assert(bool(due_fire.get("fire_due", false)), "Continuous fire timer should fire when timer reaches zero: %s" % str(due_fire))
		_assert(absf(float(due_state.get("fire_timer", 0.0)) - 0.18) < 0.001, "Continuous fire timer should reset to event fire_interval after due fire: %s" % str(due_fire))
		var min_fire: Dictionary = service.continuous_fire_timer_intent({"fire_timer": 0.0}, 0.25, {"fire_interval": 0.01})
		var min_state: Dictionary = min_fire.get("state", {}) if min_fire.get("state", {}) is Dictionary else {}
		_assert(absf(float(min_state.get("fire_timer", 0.0)) - 0.05) < 0.001, "Continuous fire timer should clamp reset interval to 0.05s minimum: %s" % str(min_fire))
	if not service.has_method("fire_ammo_gate"):
		_fail("GunActivationService missing fire_ammo_gate.")
	else:
		var empty_kind_gate: Dictionary = service.fire_ammo_gate("", 0, 0)
		_assert(bool(empty_kind_gate.get("can_fire", false)) and not bool(empty_kind_gate.get("ammo_empty", true)), "Empty ammo kind should not block firing: %s" % str(empty_kind_gate))
		var no_capacity_gate: Dictionary = service.fire_ammo_gate("bullet", 0, 0)
		_assert(bool(no_capacity_gate.get("can_fire", false)) and not bool(no_capacity_gate.get("ammo_empty", true)), "Zero capacity should be treated as non-ammo-gated: %s" % str(no_capacity_gate))
		var loaded_gate: Dictionary = service.fire_ammo_gate("bullet", 10, 1)
		_assert(bool(loaded_gate.get("can_fire", false)) and not bool(loaded_gate.get("ammo_empty", true)), "Positive current ammo should allow firing: %s" % str(loaded_gate))
		var empty_gate: Dictionary = service.fire_ammo_gate("explosive", 3, 0)
		_assert(not bool(empty_gate.get("can_fire", true)) and bool(empty_gate.get("ammo_empty", false)), "Positive capacity with zero ammo should block firing: %s" % str(empty_gate))
		_assert(String(empty_gate.get("ammo_kind", "")) == "explosive" and int(empty_gate.get("capacity", -1)) == 3 and int(empty_gate.get("current", -1)) == 0, "Ammo gate should preserve normalized scalar facts: %s" % str(empty_gate))
		var clamped_gate: Dictionary = service.fire_ammo_gate("laser", -4, -2)
		_assert(bool(clamped_gate.get("can_fire", false)) and int(clamped_gate.get("capacity", -1)) == 0 and int(clamped_gate.get("current", -1)) == 0, "Ammo gate should clamp negative capacity/current without blocking: %s" % str(clamped_gate))
	if not service.has_method("tick_route_intent"):
		_fail("GunActivationService missing tick_route_intent.")
	else:
		_assert(String(service.tick_route_intent({"activation_semantic": "release_lock"}, {})) == "event_empty", "Empty event tick route should keep state and clear pose.")
		_assert(String(service.tick_route_intent({"activation_semantic": "hold_grenade_arc"}, {"module_variant_key": "explosive_arc_salvo"})) == "salvo_preview", "Explosive arc salvo should route to preview instead of continuous fire.")
		_assert(String(service.tick_route_intent({"activation_semantic": "hold_grenade_arc"}, {"module_variant_key": "single_arc"})) == "continuous_fire", "Non-salvo grenade arc should route to continuous fire.")
		_assert(String(service.tick_route_intent({"activation_semantic": "hold_beam"}, {"projectile": true})) == "continuous_fire", "Hold beam should route to continuous fire.")
		_assert(String(service.tick_route_intent({"activation_semantic": "release_web"}, {"projectile": true})) == "hold_aim_pose", "Web release should keep the aim pose while held.")
		_assert(String(service.tick_route_intent({"activation_semantic": "release_missile_lock"}, {"projectile": true})) == "missile_lock", "Missile semantic should route to lock tracking.")
		_assert(String(service.tick_route_intent({"activation_semantic": "release_lock"}, {"projectile": true})) == "true_bullet_lock", "Release-lock semantic should route to true-bullet tracking.")
		_assert(String(service.tick_route_intent({"activation_semantic": "unknown"}, {"projectile": true})) == "clear_state", "Unknown gun activation semantic should clear active state.")
	if not service.has_method("aim_pose_payload"):
		_fail("GunActivationService missing aim_pose_payload.")
	else:
		var source_pose: Dictionary = service.aim_pose_payload({"source_gun_node": 8, "direction": Vector2(0.0, -3.0)}, Vector2.RIGHT, -1)
		_assert(int(source_pose.get("node_index", -1)) == 8 and Vector2(source_pose.get("direction", Vector2.ZERO)).distance_to(Vector2.UP) < 0.001, "Aim pose should prefer source_gun_node and normalized event direction: %s" % str(source_pose))
		var fallback_pose: Dictionary = service.aim_pose_payload({"source_node_index": 4, "direction": Vector2.ZERO}, Vector2.LEFT, -1)
		_assert(int(fallback_pose.get("node_index", -1)) == 4 and Vector2(fallback_pose.get("direction", Vector2.ZERO)).distance_to(Vector2.LEFT) < 0.001, "Aim pose should use source_node_index and fallback direction when event direction is zero: %s" % str(fallback_pose))
		var muscle_pose: Dictionary = service.aim_pose_payload({"muscle_node": 3}, Vector2.ZERO, 2)
		_assert(int(muscle_pose.get("node_index", -1)) == 3 and Vector2(muscle_pose.get("direction", Vector2.ZERO)).distance_to(Vector2.RIGHT) < 0.001, "Aim pose should fall back to muscle_node and default right direction: %s" % str(muscle_pose))
		var default_pose: Dictionary = service.aim_pose_payload({"direction": "bad"}, Vector2.DOWN, 6)
		_assert(int(default_pose.get("node_index", -1)) == 6 and Vector2(default_pose.get("direction", Vector2.ZERO)).distance_to(Vector2.DOWN) < 0.001, "Aim pose should ignore non-vector direction and use fallback node: %s" % str(default_pose))
	if not service.has_method("activation_event_options_payload"):
		_fail("GunActivationService missing activation_event_options_payload.")
	else:
		var source_targets := [2, 7]
		var event_options: Dictionary = service.activation_event_options_payload(
			{"attack_key": 4, "target_nodes": [1, 7]},
			{
				"runtime_target_nodes": source_targets,
				"source_gun_node": 7,
				"source_node_index": 6,
				"muzzle_combat_position": Vector2(3.0, 4.0),
				"muzzle_direction": Vector2(0.0, -5.0),
			},
			"gun_activate",
			"rifle_burst_activate",
			"rifle",
			"bullet",
			[1, 7],
			5,
			Vector2.ZERO,
			Vector2.RIGHT
		)
		_assert(int(event_options.get("attack_key", 0)) == 4, "Activation event options should preserve attack key: %s" % str(event_options))
		_assert(int(event_options.get("source_gun_node", -1)) == 7 and int(event_options.get("source_node_index", -1)) == 7, "Activation event options should use source gun node for event identity: %s" % str(event_options))
		_assert(Vector2(event_options.get("muzzle_combat_position", Vector2.ZERO)).distance_to(Vector2(3.0, 4.0)) < 0.001, "Activation event options should preserve muzzle combat position: %s" % str(event_options))
		_assert(Vector2(event_options.get("muzzle_direction", Vector2.ZERO)).distance_to(Vector2(0.0, -5.0)) < 0.001, "Activation event options should preserve materialized muzzle direction: %s" % str(event_options))
		_assert(String(event_options.get("module_action_profile", "")) == "gun_activate" and String(event_options.get("effective_gun_activation_profile", "")) == "rifle_burst_activate", "Activation event options should preserve module/effective profiles: %s" % str(event_options))
		_assert(bool(event_options.get("gun_activation", false)) and String(event_options.get("gun_kind", "")) == "rifle" and String(event_options.get("ammo_kind", "")) == "bullet", "Activation event options should preserve gun metadata: %s" % str(event_options))
		source_targets.append(99)
		_assert(Array(event_options.get("runtime_target_nodes", [])).size() == 2, "Activation event options should duplicate source target nodes: %s" % str(event_options))
		var fallback_targets := [3, 5]
		var fallback_options: Dictionary = service.activation_event_options_payload(
			{"attack_key": 2},
			{},
			"laser_beam_activate",
			"laser_beam_activate",
			"laser_gun",
			"laser",
			fallback_targets,
			8,
			Vector2(8.0, 9.0),
			Vector2.LEFT
		)
		fallback_targets.append(12)
		_assert(int(fallback_options.get("source_gun_node", -1)) == 8 and int(fallback_options.get("source_node_index", -1)) == 8, "Activation event options should use fallback source node when source is empty: %s" % str(fallback_options))
		_assert(Array(fallback_options.get("runtime_target_nodes", [])).size() == 2 and int(Array(fallback_options.get("runtime_target_nodes", []))[1]) == 5, "Activation event options should duplicate fallback target nodes: %s" % str(fallback_options))
		_assert(Vector2(fallback_options.get("muzzle_combat_position", Vector2.ZERO)).distance_to(Vector2(8.0, 9.0)) < 0.001 and Vector2(fallback_options.get("muzzle_direction", Vector2.ZERO)).distance_to(Vector2.LEFT) < 0.001, "Activation event options should use fallback muzzle facts when source is empty: %s" % str(fallback_options))
	if not service.has_method("release_route_intent"):
		_fail("GunActivationService missing release_route_intent.")
	else:
		var empty_release: Dictionary = service.release_route_intent({"activation_semantic": "release_lock"}, {})
		_assert(String(empty_release.get("route", "")) == "clear_pose", "Empty release event should route to pose cleanup: %s" % str(empty_release))
		var salvo_release: Dictionary = service.release_route_intent({"activation_semantic": "hold_grenade_arc"}, {"module_variant_key": "explosive_arc_salvo"})
		var salvo_patch: Dictionary = salvo_release.get("event_patch", {}) if salvo_release.get("event_patch", {}) is Dictionary else {}
		_assert(String(salvo_release.get("route", "")) == "salvo_release_fire" and bool(salvo_patch.get("salvo_release_fire", false)), "Explosive arc salvo release should request salvo fire patch: %s" % str(salvo_release))
		_assert(String(service.release_route_intent({"activation_semantic": "release_web"}, {"projectile": true}).get("route", "")) == "web_tether", "Web semantic should route to web tether release.")
		_assert(String(service.release_route_intent({"activation_semantic": "release_missile_lock"}, {"projectile": true}).get("route", "")) == "missile_lock", "Missile semantic should route to missile release.")
		_assert(String(service.release_route_intent({"activation_semantic": "release_lock"}, {"projectile": true}).get("route", "")) == "true_bullet_lock", "Release-lock semantic should route to true-bullet lock.")
		_assert(String(service.release_route_intent({"activation_semantic": "hold_stream"}, {"projectile": true}).get("route", "")) == "clear_pose", "Non-release hold semantic should route to pose cleanup.")
	if not service.has_method("release_lock_event_patch"):
		_fail("GunActivationService missing release_lock_event_patch.")
	else:
		var missile_patch: Dictionary = service.release_lock_event_patch("missile_lock", {"direction": Vector2.UP}, Vector2.RIGHT, 0.8)
		_assert(bool(missile_patch.get("aim_locked", false)) and Vector2(missile_patch.get("direction", Vector2.ZERO)).distance_to(Vector2.RIGHT) < 0.001, "Missile release lock patch should set aim lock and injected direction: %s" % str(missile_patch))
		_assert(not missile_patch.has("bullet_lock_time"), "Missile release lock patch should not set true-bullet lock time: %s" % str(missile_patch))
		var true_patch: Dictionary = service.release_lock_event_patch("true_bullet_lock", {"sniper_fire_delay": 0.92, "direction": Vector2.UP}, Vector2.LEFT, 0.8)
		_assert(bool(true_patch.get("aim_locked", false)) and Vector2(true_patch.get("direction", Vector2.ZERO)).distance_to(Vector2.LEFT) < 0.001, "True-bullet release lock patch should set aim lock and injected direction: %s" % str(true_patch))
		_assert(absf(float(true_patch.get("bullet_lock_time", 0.0)) - 0.92) < 0.001, "True-bullet release lock patch should prefer sniper_fire_delay: %s" % str(true_patch))
		var fallback_patch: Dictionary = service.release_lock_event_patch("true_bullet_lock", {"bullet_lock_time": 1.25}, Vector2.ZERO, 0.8)
		_assert(absf(float(fallback_patch.get("bullet_lock_time", 0.0)) - 1.25) < 0.001 and Vector2(fallback_patch.get("direction", Vector2.ZERO)).length() > 0.99, "True-bullet release lock patch should preserve event lock time and fallback direction: %s" % str(fallback_patch))
		_assert(service.release_lock_event_patch("web_tether", {"direction": Vector2.RIGHT}, Vector2.RIGHT, 0.8).is_empty(), "Non-lock release route should not emit lock patch.")
	var payload: Dictionary = service.activation_state_payload({
		"prefix": "p1_",
		"attack_index": 2,
		"action_name": "p1_attack_3",
		"binding": {"attack_key": 3, "target_nodes": [7]},
		"aim_direction": Vector2.UP,
		"gun_rotate_speed": 3.4,
		"gun_kind": "rifle",
		"effective_gun_activation_profile": "rifle_burst_activate",
		"activation_semantic": "hold_burst",
		"aim_input_mode": "turn_keys",
		"mobility_contract": {"move_while_firing": true, "direction_boost_while_firing": true},
	})
	_assert(String(payload.get("prefix", "")) == "p1_" and int(payload.get("attack_index", -1)) == 2, "State payload identity mismatch: %s" % str(payload))
	_assert(bool(payload.get("move_while_firing", false)) and bool(payload.get("direction_boost_while_firing", false)), "State payload mobility mismatch: %s" % str(payload))
	_assert(float(payload.get("fire_timer", -1.0)) == 0.0 and float(payload.get("hold_time", -1.0)) == 0.0, "State payload timers should initialize to zero: %s" % str(payload))
	payload["binding"]["attack_key"] = 99
	_assert(int(Dictionary(service.activation_state_payload({"binding": {"attack_key": 3}}).get("binding", {})).get("attack_key", 0)) == 3, "State payload should duplicate binding data.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/gun_activation_service.gd",
		"GunActivationService.new",
		"_gun_activation_service().gun_activation_spec",
		"_gun_activation_service().gun_activation_profile_supports_kind",
		"_gun_activation_service().activation_profile_gate",
		"_gun_activation_service().gun_aim_input_mode_for_data",
		"_gun_activation_service().runtime_binding_profile",
		"_gun_activation_service().runtime_binding_is_gun_activation",
		"_gun_activation_service().runtime_binding_gun_aim_input_mode",
		"_gun_activation_service().runtime_binding_gun_mobility_contract",
		"_gun_activation_service().active_direction_boost_allowed",
		"_gun_activation_service().activation_state_active",
		"_gun_activation_service().binding_drive_allocation_for_node",
		"_gun_activation_service().gun_drive_info_for_segment",
		"_gun_activation_service().runtime_gun_group_payload",
		"_gun_activation_service().gun_drive_aim_speed_mult",
		"_gun_activation_service().activation_rotate_speed",
		"_gun_activation_service().activation_source_gate",
		"_gun_activation_service().activation_direction",
		"_gun_activation_service().activation_event_direction",
		"_gun_activation_service().activation_event_source_identity",
		"_gun_activation_service().runtime_gun_source_payload",
		"_gun_activation_service().rotated_direction",
		"_gun_activation_service().should_release_activation",
		"_gun_activation_service().tick_state_payload",
		"_gun_activation_service().continuous_fire_timer_intent",
		"_gun_activation_service().fire_ammo_gate",
		"_gun_activation_service().tick_route_intent",
		"_gun_activation_service().aim_pose_payload",
		"_gun_activation_service().activation_event_options_payload",
		"_gun_activation_service().release_route_intent",
		"_gun_activation_service().release_lock_event_patch",
		"_gun_activation_service().activation_state_payload",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing GunActivationService boundary token: %s" % token)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var main_rifle: Dictionary = main._gun_activation_spec("rifle", "gun_activate")
	_assert(String(main_rifle.get("semantic", "")) == "hold_burst", "main wrapper should still resolve generic gun_activate to rifle burst: %s" % str(main_rifle))
	_assert(main._gun_activation_profile_supports_kind("gun_activate", "rifle", "bullet"), "main support wrapper should allow generic rifle activation.")
	_assert(not main._gun_activation_profile_supports_kind("laser_beam_activate", "rifle", "bullet"), "main support wrapper should reject mismatched laser profile.")
	_assert(main._gun_aim_input_mode_for_data({"module_action_profile": "laser_beam_activate"}) == "turn_keys", "main aim mode wrapper mismatch.")
	_assert(main._runtime_binding_profile({"module_part": {"module_action_profile": "laser_beam_activate"}}) == "laser_beam_activate", "main runtime binding profile wrapper mismatch.")
	_assert(main._runtime_binding_is_gun_activation({"module_part": {"module_action_profile": "laser_beam_activate"}}), "main runtime binding gun activation wrapper mismatch.")
	_assert(main._runtime_binding_gun_aim_input_mode({"module_part": {"module_action_profile": "laser_beam_activate", "gun_aim_input_mode": "movement_keys"}}) == "direction_keys", "main runtime binding aim mode wrapper mismatch.")
	_assert(not main._runtime_binding_gun_mobility_contract({"module_action_profile": "boot_action_driver"}).has("direction_boost_while_firing"), "main non-gun binding mobility wrapper should be empty.")
	var main_mobility: Dictionary = main._runtime_binding_gun_mobility_contract({"module_action_profile": "laser_beam_activate"})
	_assert(bool(main_mobility.get("direction_boost_while_firing", false)), "main gun binding mobility wrapper should expose projectile mobility contract: %s" % str(main_mobility))
	_assert(absf(float(main._binding_drive_allocation_for_node({"joint_drive_allocation_total": 48.0, "target_nodes": [1, 2]}, 2, 10.0)) - 24.0) < 0.001, "main drive allocation wrapper mismatch.")
	_assert(main._gun_drive_aim_speed_mult(0.45) < main._gun_drive_aim_speed_mult(1.8), "main gun drive wrapper mismatch.")
	if not failures.is_empty():
		print("GUN_ACTIVATION_SERVICE_CONTRACT_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("GUN_ACTIVATION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
