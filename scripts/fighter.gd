class_name Fighter
extends Node2D

const PartArt = preload("res://scripts/part_art.gd")
const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")
const MotionBudget = preload("res://scripts/motion_budget.gd")
const MobiusWorld = preload("res://scripts/mobius_world.gd")
const GameplayTransform = preload("res://scripts/gameplay_transform.gd")

signal knocked_out(unit)
signal combat_event(message: String)

const STATE_NORMAL = "normal"
const STATE_ARMOR = "armor"
const STATE_ACTIVE = "active"
const BATTLE_HALF_HEIGHT = 7.5
const BASE_MOVE_SPEED_MULT = 3.0
const HEAT_RATE_MULT = 0.5
const HEAT_TAG_PREFIX = "heat:"
const HEAT_TAG_EVENT_PREFIX = "heat_event:"
const PART_VISUAL_SCALE = 82.0
const MAX_PART_VISUAL_LINES = 48
const BODY_COLLIDER_EXPAND = 1.0
const ATTACK_COLLIDER_EXPAND = 1.0
const TWO_LINK_DEFAULT_STARTUP_RATIO = 1.0 / 3.0
const USE_ABSTRACT_TOPOLOGY_VISUALS = true
const TERMINAL_MELEE_GEOMETRY_MULTIPLIER = 0.62
const TERMINAL_RANGED_GEOMETRY_MULTIPLIER = 0.70
const TERMINAL_RADIUS_GEOMETRY_MULTIPLIER = 0.75
const PART_STIFFNESS_BASE_MOMENTUM = 768.0
const LIMB_INERTIA_PARTS = 18
const LIMB_SWING_SPRING = 32.0
const LIMB_SWING_DAMPING = 5.8
const BODY_SWING_SPRING = 18.0
const BODY_SWING_DAMPING = 4.6
const BODY_SWAY_SPRING = 24.0
const BODY_SWAY_DAMPING = 6.2
const LIMB_LINEAR_SPRING = 28.0
const LIMB_LINEAR_DAMPING = 6.0
const MODULE_CANCEL_PHASE_START = 0.42
const MODULE_CANCEL_PHASE_END = 0.66
const MODULE_CANCEL_MIN_POWER = 0.74
const MODULE_FULL_DECEL_VELOCITY = 0.12
const MODULE_FULL_DECEL_LINEAR_VELOCITY = 0.035
const PROJECTILE_DAMAGE_TYPES = ["bullet", "chemical", "laser"]
const MOVE_COMMAND_NONE = "none"
const MOVE_COMMAND_DRIVE = "drive"
const MOVE_COMMAND_BRAKE = "brake"
const BRAKE_REVERSE_READY_SECONDS = 0.9
const BRAKE_REVERSE_DIR_DOT = 0.82
const REAR_BRAKE_HALF_ANGLE_DEGREES = 50.0
const BOOST_COOLDOWN_DEFAULT = 0.5
const MOBIUS_VISUAL_SCALE_MIN = 0.05
const MOBIUS_VISUAL_SCALE_MAX_STEP = 0.045

var owner_id := 1
var role := "hero"
var unit_name := "Topology"
var group_name := ""
var max_health := 100
var health := 100
var active := false

var ring_pos := 0.0
var lane := 0.0
var mobius_s := 0.0
var mobius_v := 0.0
var mobius_twist_angle := 0.0
var mobius_depth01 := 0.5
var mobius_visual_scale := 1.0
var mobius_visual_scale_target := 1.0
var mobius_visual_scale_initialized := false
var visual_hitbox_scale := 1.0
var velocity := Vector2.ZERO
var facing := 1
var facing_angle := 0.0
var target_facing_angle := 0.0
var angular_velocity := 0.0
var turn_direction_bias := 0.0
var current_state := STATE_NORMAL
var state_timer := 0.0
var action_cooldown := 0.0
var heat := 0.0
var overheated := false
var moved_this_frame := false
var manual_cooling := false
var cooling_lock_timer := 0.0
var forced_cooling_timer := 0.0
var smoke_timer := 0.0
var boost_flash_timer := 0.0
var thruster_visual_timer := 0.0
var thruster_output_direction := Vector2.RIGHT
var boost_drive_timer := 0.0
var boost_drive_duration := 0.0
var boost_drive_velocity_remaining := Vector2.ZERO
var boost_drive_direction := Vector2.RIGHT
var boost_cooldown_timer := 0.0
var brake_reverse_ready_dir := Vector2.ZERO
var brake_reverse_ready_timer := 0.0
var brake_reverse_requires_repress := false
var last_action_direction := Vector2.RIGHT
var active_part_index := -1
var active_part_direction := Vector2.RIGHT
var active_part_timer := 0.0
var active_part_duration := 0.0
var active_part_state := STATE_NORMAL
var active_module_key := ""
var active_module_part_index := -1
var active_module_started_at := -999.0
var turn_input_active := false
var turn_input_timer := 0.0
var aim_pose_part_index := -1
var aim_pose_direction := Vector2.RIGHT
var aim_pose_timer := 0.0
var body_swing_angle := 0.0
var body_swing_velocity := 0.0
var body_sway_offset := Vector2.ZERO
var body_sway_velocity := Vector2.ZERO
var recovery_boost_timer := 0.0
var collision_auto_brake_timer := 0.0
var melee_stagger_timer := 0.0
var module_clamp_pin_timer := 0.0
var module_clamp_velocity_mult := 1.0
var limb_swing_angles: Array = []
var limb_swing_velocities: Array = []
var limb_linear_offsets: Array = []
var limb_linear_velocities: Array = []
var limb_drive_timers: Array = []
var limb_drive_durations: Array = []
var limb_drive_amplitudes: Array = []
var limb_drive_directions: Array = []
var limb_drive_states: Array = []
var runtime_module_actions: Array = []
var runtime_geometry_cache_segments_by_key := {}
var runtime_geometry_cache_colliders_key := ""
var runtime_geometry_cache_colliders: Array = []
var runtime_geometry_cache_builds := 0
var runtime_geometry_cache_hits := 0
var runtime_geometry_cache_misses := 0
var runtime_geometry_collider_builds := 0
var runtime_geometry_visual_redraw_key := ""
var runtime_status_curve_overlay_last_count := 0

var stats := {}
var primary_color := Color(0.1, 0.72, 0.9, 1.0)
var accent_color := Color(1.0, 0.86, 0.22, 1.0)

var barrier_tile_lines: Array = []
var state_flash: Polygon2D
var smoke_cloud: Polygon2D
var boost_flash: Polygon2D
var thruster_flames: Array = []
var heat_bar_back: Polygon2D
var heat_bar_fill: Polygon2D


func _ready() -> void:
	if state_flash == null:
		_build_visuals()
	visible = false


func _draw() -> void:
	runtime_status_curve_overlay_last_count = 0
	if _is_training_ball_dummy():
		_draw_training_ball_dummy()
		_draw_runtime_status_curve_overlay()
		return
	if _is_teamedit_runtime_unit() and _has_runtime_topology():
		_draw_runtime_assembly_board_unit()
		_draw_runtime_status_curve_overlay()


func setup_unit(config: Dictionary) -> void:
	if state_flash == null:
		_build_visuals()
	owner_id = int(config.get("owner_id", owner_id))
	role = String(config.get("role", role))
	unit_name = String(config.get("unit_name", unit_name))
	group_name = String(config.get("group_name", group_name))
	stats = config.get("stats", {}).duplicate(true)
	_invalidate_runtime_geometry_cache()
	max_health = int(stats.get("health", max_health))
	health = max_health

	var maybe_primary: Variant = stats.get("primary_color", primary_color)
	if maybe_primary is Color:
		primary_color = maybe_primary
	var maybe_accent: Variant = stats.get("accent_color", accent_color)
	if maybe_accent is Color:
		accent_color = maybe_accent

	_reset_limb_dynamics()
	_reset_part_damage_state()
	_reset_electronic_armor(true)
	_refresh_visuals()


func deploy(spawn_ring_pos: float, spawn_lane: float) -> void:
	mobius_s = spawn_ring_pos
	mobius_v = clampf(spawn_lane, -BATTLE_HALF_HEIGHT, BATTLE_HALF_HEIGHT)
	mobius_twist_angle = MobiusWorld.twist_angle(mobius_s)
	mobius_depth01 = 0.5
	mobius_visual_scale = 1.0
	mobius_visual_scale_target = 1.0
	mobius_visual_scale_initialized = false
	visual_hitbox_scale = GameplayTransform.hitbox_scale_for_visual_scale(mobius_visual_scale)
	scale = Vector2.ONE * mobius_visual_scale
	ring_pos = fposmod(mobius_s, 24.0)
	lane = mobius_v
	velocity = Vector2.ZERO
	facing = 1 if owner_id == 1 else -1
	set_facing_immediate(facing)
	health = max_health
	heat = 0.0
	overheated = false
	moved_this_frame = false
	manual_cooling = false
	cooling_lock_timer = 0.0
	forced_cooling_timer = 0.0
	smoke_timer = 0.0
	boost_flash_timer = 0.0
	thruster_visual_timer = 0.0
	boost_drive_timer = 0.0
	boost_drive_duration = 0.0
	boost_drive_velocity_remaining = Vector2.ZERO
	boost_drive_direction = Vector2.RIGHT
	boost_cooldown_timer = 0.0
	brake_reverse_ready_dir = Vector2.ZERO
	brake_reverse_ready_timer = 0.0
	brake_reverse_requires_repress = false
	recovery_boost_timer = 0.0
	melee_stagger_timer = 0.0
	module_clamp_pin_timer = 0.0
	module_clamp_velocity_mult = 1.0
	set_meta("melee_stagger_timer", 0.0)
	set_meta("clamp_pin_timer", 0.0)
	set_meta("clamp_velocity_mult", 1.0)
	set_meta("stagger_combo_active", false)
	set_meta("stagger_combo_id", 0)
	set_meta("stagger_combo_base_duration", 0.0)
	set_meta("stagger_combo_total_hits", 0)
	set_meta("stagger_combo_attacker_hits", {})
	set_meta("stagger_combo_opening_momentum", 0.0)
	set_meta("combo_transfer_momentum_cap", 0.0)
	body_swing_angle = 0.0
	body_swing_velocity = 0.0
	body_sway_offset = Vector2.ZERO
	body_sway_velocity = Vector2.ZERO
	last_action_direction = _forward_vector()
	thruster_output_direction = last_action_direction
	active_part_index = -1
	active_part_direction = last_action_direction
	active_part_timer = 0.0
	active_part_duration = 0.0
	active_part_state = STATE_NORMAL
	active_module_key = ""
	active_module_part_index = -1
	active_module_started_at = -999.0
	set_meta("active_module_key", "")
	set_meta("module_cancel_ready", false)
	set_meta("last_module_gate_reason", "")
	set_meta("last_melee_module_heat_key", "")
	set_meta("melee_module_heat_ledger", {})
	runtime_module_actions.clear()
	_invalidate_runtime_geometry_cache()
	aim_pose_part_index = -1
	aim_pose_direction = last_action_direction
	aim_pose_timer = 0.0
	_reset_limb_dynamics()
	_reset_part_damage_state()
	_reset_electronic_armor(true)
	current_state = STATE_NORMAL
	state_timer = 0.0
	action_cooldown = 0.0
	active = true
	visible = true
	_refresh_visuals()


func retire() -> void:
	active = false
	visible = false


func tick(delta: float, ring_length: float) -> void:
	if not active:
		return
	sync_mobius_from_compat(ring_length, false)
	if not _uses_heat_resource():
		heat = 0.0
		overheated = false
		manual_cooling = false

	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0:
			current_state = STATE_NORMAL
	if cooling_lock_timer > 0.0:
		cooling_lock_timer = maxf(0.0, cooling_lock_timer - delta)
	if forced_cooling_timer > 0.0:
		forced_cooling_timer = maxf(0.0, forced_cooling_timer - delta)
		manual_cooling = true
		smoke_timer = maxf(smoke_timer, 0.18)
	smoke_timer = maxf(0.0, smoke_timer - delta)
	boost_flash_timer = maxf(0.0, boost_flash_timer - delta)
	thruster_visual_timer = maxf(0.0, thruster_visual_timer - delta)
	boost_cooldown_timer = maxf(0.0, boost_cooldown_timer - delta)
	brake_reverse_ready_timer = maxf(0.0, brake_reverse_ready_timer - delta)
	if brake_reverse_ready_timer <= 0.0:
		brake_reverse_ready_dir = Vector2.ZERO
		brake_reverse_requires_repress = false
	recovery_boost_timer = maxf(0.0, recovery_boost_timer - delta * _recovery_response_multiplier())
	_tick_collision_auto_brake(delta)
	melee_stagger_timer = maxf(0.0, melee_stagger_timer - delta)
	set_meta("melee_stagger_timer", melee_stagger_timer)
	module_clamp_pin_timer = maxf(0.0, module_clamp_pin_timer - delta)
	if module_clamp_pin_timer > 0.0:
		var clamp_mult := clampf(module_clamp_velocity_mult, 0.05, 1.0)
		velocity *= clampf(lerpf(1.0, clamp_mult, minf(1.0, delta * 9.0)), 0.05, 1.0)
	else:
		module_clamp_velocity_mult = 1.0
	set_meta("clamp_pin_timer", module_clamp_pin_timer)
	set_meta("clamp_velocity_mult", module_clamp_velocity_mult)
	active_part_timer = maxf(0.0, active_part_timer - delta)
	if active_part_timer <= 0.0:
		active_part_index = -1
	aim_pose_timer = maxf(0.0, aim_pose_timer - delta)
	if aim_pose_timer <= 0.0:
		if aim_pose_part_index != -1:
			aim_pose_part_index = -1
			_invalidate_runtime_geometry_cache()
	_tick_turn_dynamics(delta)
	_tick_body_inertia(delta)
	_tick_limb_dynamics(delta)
	_tick_runtime_module_actions(delta)
	_tick_electronic_armor(delta)
	_tick_boost_drive(delta)

	action_cooldown = maxf(0.0, action_cooldown - delta)
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	var cooling: float = _runtime_cooling_rate()
	var cooling_mult := 0.35 if moved_this_frame or action_cooldown > 0.0 or current_state != STATE_NORMAL else 1.15
	if _is_straight_inertial_cooling():
		cooling_mult = 3.2
	if manual_cooling:
		cooling_mult = 3.2
	if _uses_heat_resource():
		heat = clampf(heat - cooling * cooling_mult * delta * HEAT_RATE_MULT, 0.0, heat_capacity)
		if heat >= heat_capacity:
			trigger_overheat_shutdown("heat cap")
		elif overheated and heat <= heat_capacity * _overheat_clear_ratio():
			overheated = false
	_clamp_velocity_to_speedometer()
	moved_this_frame = false
	manual_cooling = false
	mobius_s += velocity.x * delta
	mobius_v = clampf(mobius_v + velocity.y * delta, -BATTLE_HALF_HEIGHT, BATTLE_HALF_HEIGHT)
	mobius_twist_angle = MobiusWorld.twist_angle(mobius_s, ring_length)
	ring_pos = fposmod(mobius_s, maxf(0.001, ring_length))
	lane = mobius_v
	_refresh_visuals()


func sync_mobius_from_compat(ring_length: float, force_from_compat: bool = false) -> void:
	var loop := maxf(0.001, ring_length)
	if force_from_compat and absf(fposmod(mobius_s, loop) - fposmod(ring_pos, loop)) > 0.01:
		mobius_s = MobiusWorld.nearest_lifted_s(mobius_s, ring_pos, loop)
	if force_from_compat and absf(mobius_v - lane) > 0.01:
		mobius_v = clampf(lane, -BATTLE_HALF_HEIGHT, BATTLE_HALF_HEIGHT)
	mobius_v = clampf(mobius_v, -BATTLE_HALF_HEIGHT, BATTLE_HALF_HEIGHT)
	mobius_twist_angle = MobiusWorld.twist_angle(mobius_s, loop)
	ring_pos = fposmod(mobius_s, loop)
	lane = mobius_v


func set_facing_immediate(direction_sign: int) -> void:
	facing = 1 if direction_sign >= 0 else -1
	facing_angle = 0.0 if facing > 0 else PI
	target_facing_angle = facing_angle
	angular_velocity = 0.0
	turn_direction_bias = 0.0


func request_facing(direction_sign: int) -> void:
	if not active:
		return
	if melee_stagger_timer > 0.0:
		return
	if direction_sign == 0:
		return
	target_facing_angle = 0.0 if direction_sign > 0 else PI
	turn_direction_bias = 1.0 if direction_sign > 0 else -1.0


func request_turn(direction_sign: int, delta: float) -> void:
	if not active:
		return
	if melee_stagger_timer > 0.0:
		return
	if direction_sign == 0 or delta <= 0.0:
		return
	turn_input_active = true
	turn_input_timer = maxf(turn_input_timer, maxf(0.18, delta * 1.2))
	var command_rate: float = maxf(0.0, float(stats.get("turn_command_rate", stats.get("turn_speed", 0.0))))
	if command_rate <= 0.0001:
		return
	target_facing_angle = wrapf(target_facing_angle + float(direction_sign) * command_rate * delta, 0.0, TAU)
	turn_direction_bias = float(signi(direction_sign))


func set_turn_input_active(is_active: bool) -> void:
	turn_input_active = is_active
	if is_active:
		turn_input_timer = maxf(turn_input_timer, 0.18)
	else:
		turn_input_timer = 0.0
		target_facing_angle = facing_angle


func _tick_turn_dynamics(delta: float) -> void:
	turn_input_timer = maxf(0.0, turn_input_timer - delta)
	turn_input_active = turn_input_timer > 0.0
	if melee_stagger_timer > 0.0:
		var turn_damping: float = maxf(0.1, float(stats.get("turn_damping", 3.2)))
		angular_velocity = move_toward(angular_velocity, 0.0, turn_damping * delta * 0.6)
		facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
		_sync_facing_from_angle()
		return
	var angle_delta := _angle_delta(facing_angle, target_facing_angle)
	if absf(absf(angle_delta) - PI) < 0.001 and turn_direction_bias != 0.0:
		angle_delta = turn_direction_bias * PI
	var turn_speed: float = maxf(0.0, float(stats.get("turn_speed", 0.0)))
	var turn_acceleration: float = maxf(0.0, float(stats.get("turn_acceleration", 0.0)))
	var turn_damping: float = maxf(0.0, float(stats.get("turn_damping", 0.0)))
	if turn_speed <= 0.0001 or turn_acceleration <= 0.0001:
		angular_velocity = 0.0
		_sync_facing_from_angle()
		return
	if overheated and role == "hero":
		turn_speed *= 0.62
		turn_acceleration *= 0.58
	if current_state == STATE_ARMOR:
		turn_speed *= 0.58
		turn_acceleration *= 0.52
	elif current_state == STATE_ACTIVE:
		turn_speed *= 0.78
		turn_acceleration *= 0.72
	if not turn_input_active:
		var brake_accel := _turn_brake_acceleration()
		angular_velocity = move_toward(angular_velocity, 0.0, brake_accel * delta)
		facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
		target_facing_angle = facing_angle
		if absf(angular_velocity) < 0.002:
			angular_velocity = 0.0
		_sync_facing_from_angle()
		return
	var angular_acceleration := angle_delta * turn_acceleration * 3.2 - angular_velocity * turn_damping
	angular_velocity = clampf(angular_velocity + angular_acceleration * delta, -turn_speed, turn_speed)
	facing_angle = wrapf(facing_angle + angular_velocity * delta, 0.0, TAU)
	if absf(angle_delta) < 0.006 and absf(angular_velocity) < 0.04:
		facing_angle = target_facing_angle
		angular_velocity = 0.0
	_sync_facing_from_angle()


func _angle_delta(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle + PI, 0.0, TAU) - PI


func _sync_facing_from_angle() -> void:
	var x_axis := cos(facing_angle)
	if absf(x_axis) > 0.06:
		facing = 1 if x_axis >= 0.0 else -1


func _turn_brake_acceleration() -> float:
	var brake_power: float = maxf(0.0, float(stats.get("brake_power", 0.0)))
	var mass: float = maxf(1.0, float(stats.get("mass", 1.0)))
	var duration: float = maxf(0.04, float(stats.get("boost_duration", 0.3)))
	var allocated_momentum := maxf(0.0, float(stats.get("move_momentum", 0.0)))
	if allocated_momentum <= 0.0:
		allocated_momentum = maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var momentum_brake := brake_power / duration
	if momentum_brake <= 0.0:
		momentum_brake = (allocated_momentum / mass) / duration
	var damping_fallback := maxf(0.0, float(stats.get("turn_damping", 0.0)))
	return maxf(maxf(momentum_brake, damping_fallback), 0.1)


func _tick_boost_drive(delta: float) -> void:
	if boost_drive_timer <= 0.0 or boost_drive_velocity_remaining.length() <= 0.0001:
		boost_drive_timer = 0.0
		boost_drive_velocity_remaining = Vector2.ZERO
		return
	var step_ratio := clampf(delta / maxf(0.001, boost_drive_timer), 0.0, 1.0)
	var velocity_step := boost_drive_velocity_remaining * step_ratio
	velocity += velocity_step
	boost_drive_velocity_remaining -= velocity_step
	boost_drive_timer = maxf(0.0, boost_drive_timer - delta)
	thruster_output_direction = boost_drive_direction
	thruster_visual_timer = maxf(thruster_visual_timer, 0.08)
	moved_this_frame = true
	if boost_drive_timer <= 0.0 or boost_drive_velocity_remaining.length() <= 0.0001:
		boost_drive_timer = 0.0
		boost_drive_velocity_remaining = Vector2.ZERO


func _forward_vector() -> Vector2:
	var body_angle := facing_angle + body_swing_angle
	return Vector2(cos(body_angle), sin(body_angle)).normalized()


func forward_vector() -> Vector2:
	return _forward_vector()


func _side_vector() -> Vector2:
	var forward := _forward_vector()
	return Vector2(-forward.y, forward.x)


func _has_bidirectional_thrusters() -> bool:
	if bool(stats.get("bidirectional_thrusters", false)):
		return true
	var mount := String(stats.get("thruster_mount", stats.get("booster_mount", ""))).to_lower()
	return mount.contains("front_back") or mount.contains("omni") or mount.contains("bidirectional")


func _attitude_stabilization() -> float:
	return clampf(float(stats.get("recoil_stabilization", stats.get("attitude_control", 0.85))), 0.22, 2.6)


func _impulse_response_multiplier() -> float:
	return clampf(1.22 / (0.72 + _attitude_stabilization() * 0.42), 0.48, 1.52)


func _recovery_response_multiplier() -> float:
	return clampf(float(stats.get("recovery_response", 0.85)), 0.42, 1.72)


func _recovery_linger_multiplier() -> float:
	return clampf(1.36 / maxf(0.38, _recovery_response_multiplier()), 0.72, 2.05)


func _thruster_drive_direction(requested: Vector2) -> Vector2:
	if requested.length() <= 0.04:
		return Vector2.ZERO
	var desired := requested.normalized()
	if _has_runtime_topology():
		return desired
	if _has_bidirectional_thrusters():
		return desired
	return _direction_inside_thruster_cone(desired, float(stats.get("thruster_cone_degrees", 180.0)))


func _direction_inside_thruster_cone(desired: Vector2, cone_degrees: float) -> Vector2:
	if desired.length() <= 0.04:
		return Vector2.ZERO
	var forward := _forward_vector()
	var side := _side_vector()
	var forward_component := desired.dot(forward)
	var side_component := desired.dot(side)
	cone_degrees = clampf(cone_degrees, 20.0, 360.0)
	if cone_degrees >= 359.0:
		return desired.normalized()
	var cone_cos := cos(deg_to_rad(cone_degrees * 0.5))
	if forward_component >= cone_cos:
		return desired.normalized()
	if cone_degrees >= 179.0:
		if absf(side_component) <= 0.001:
			return Vector2.ZERO
		return (side * side_component).normalized()
	var side_sign := signf(side_component)
	if side_sign == 0.0:
		return Vector2.ZERO
	var clamped := forward * cone_cos + side * side_sign * sqrt(maxf(0.0, 1.0 - cone_cos * cone_cos))
	return clamped.normalized()


func _thruster_boost_direction(requested: Vector2) -> Vector2:
	if requested.length() <= 0.04:
		return Vector2.ZERO
	var desired := requested.normalized()
	var profile := String(stats.get("movement_profile", "omni")).to_lower()
	if profile == "car" and desired.dot(_forward_vector()) <= 0.0:
		return Vector2.ZERO
	var boost_angle := clampf(float(stats.get("boost_angle_degrees", 360.0)), 20.0, 360.0)
	if boost_angle >= 359.0:
		return desired
	var cone_cos := cos(deg_to_rad(boost_angle * 0.5))
	return desired if desired.dot(_forward_vector()) >= cone_cos else Vector2.ZERO


func _is_rear_brake_zone(input_dir: Vector2) -> bool:
	if input_dir.length() <= 0.04:
		return false
	var rear := -_forward_vector()
	var rear_dot := input_dir.normalized().dot(rear)
	var rear_limit := cos(deg_to_rad(REAR_BRAKE_HALF_ANGLE_DEGREES))
	return rear_dot >= rear_limit


func _speedometer_max_speed() -> float:
	var explicit_limit := maxf(0.0, float(stats.get("speedometer_max_speed", 0.0)))
	if explicit_limit > 0.001:
		return explicit_limit
	var body_speed := maxf(0.0, float(stats.get("move_speed", 0.0)))
	var boost_speed := maxf(0.0, float(stats.get("boost_speed", 0.0)))
	return maxf(1.0, maxf(body_speed * 3.0, boost_speed * 2.0) * 1.5)


func _clamp_velocity_to_speedometer() -> void:
	var limit := _speedometer_max_speed()
	if limit <= 0.001 or velocity.length() <= limit:
		return
	velocity = velocity.normalized() * limit


func _brake_delta_velocity() -> float:
	var brake_power: float = maxf(0.0, float(stats.get("brake_power", 0.0)))
	if brake_power > 0.0:
		return brake_power
	var allocated_momentum: float = maxf(0.0, float(stats.get("move_momentum", 0.0)))
	if allocated_momentum <= 0.0:
		allocated_momentum = maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var mass: float = maxf(1.0, float(stats.get("mass", 1.0)))
	return allocated_momentum / mass


func _boost_brake_acceleration() -> float:
	var boost_duration: float = maxf(0.04, float(stats.get("boost_duration", 0.3)))
	return _brake_delta_velocity() / boost_duration


func _can_velocity_brake() -> bool:
	return velocity.length() > 0.001 and _brake_delta_velocity() > 0.001


func _set_brake_reverse_ready(input_dir: Vector2) -> void:
	if input_dir.length() <= 0.04:
		return
	brake_reverse_ready_dir = input_dir.normalized()
	brake_reverse_ready_timer = BRAKE_REVERSE_READY_SECONDS
	brake_reverse_requires_repress = true
	set_meta("brake_reverse_ready_dir", brake_reverse_ready_dir)


func note_movement_input_released() -> void:
	if brake_reverse_ready_timer > 0.0 and brake_reverse_ready_dir.length() > 0.04:
		brake_reverse_requires_repress = false
	set_meta("move_input_released", true)


func note_movement_input_pressed(input_dir: Vector2) -> void:
	set_meta("move_input_just_pressed", true)
	set_meta("move_input_pressed_dir", input_dir.normalized() if input_dir.length() > 0.04 else Vector2.ZERO)


func _reverse_drive_allowed(input_vector: Vector2) -> bool:
	if input_vector.length() <= 0.04:
		return false
	if brake_reverse_ready_timer <= 0.0 or brake_reverse_ready_dir.length() <= 0.04:
		return false
	if brake_reverse_requires_repress:
		return false
	return input_vector.normalized().dot(brake_reverse_ready_dir.normalized()) >= BRAKE_REVERSE_DIR_DOT


func _brake_reverse_waiting_for_repress(input_vector: Vector2) -> bool:
	if input_vector.length() <= 0.04:
		return false
	if brake_reverse_ready_timer <= 0.0 or brake_reverse_ready_dir.length() <= 0.04:
		return false
	if not brake_reverse_requires_repress:
		return false
	return input_vector.normalized().dot(brake_reverse_ready_dir.normalized()) >= BRAKE_REVERSE_DIR_DOT


func _boost_request_is_reverse_only(input_vector: Vector2) -> bool:
	if input_vector.length() <= 0.04:
		return false
	if _reverse_drive_allowed(input_vector) or _brake_reverse_waiting_for_repress(input_vector):
		return true
	return _is_rear_brake_zone(input_vector)


func _input_should_velocity_brake(input_vector: Vector2) -> bool:
	if input_vector.length() <= 0.04 or velocity.length() <= 0.01:
		return false
	if _reverse_drive_allowed(input_vector):
		return false
	var input_dir := input_vector.normalized()
	var velocity_dir := velocity.normalized()
	return input_dir.dot(velocity_dir) <= -0.12


func _clear_brake_reverse_ready() -> void:
	brake_reverse_ready_dir = Vector2.ZERO
	brake_reverse_ready_timer = 0.0
	brake_reverse_requires_repress = false


func _apply_velocity_brake(delta: float, reason: String = "", full_boost: bool = false, input_dir: Vector2 = Vector2.ZERO) -> bool:
	if not _can_velocity_brake():
		return false
	var old_dir := velocity.normalized()
	var brake_step := _brake_delta_velocity() if full_boost else _boost_brake_acceleration() * maxf(0.0, delta)
	brake_step = minf(velocity.length(), brake_step)
	if brake_step <= 0.0001:
		return false
	velocity -= old_dir * brake_step
	if velocity.length() < 0.001 or velocity.dot(old_dir) <= 0.0:
		velocity = Vector2.ZERO
		if reason.begins_with("unusable_") or reason == "reverse_brake":
			_set_brake_reverse_ready(input_dir)
	moved_this_frame = true
	thruster_output_direction = -old_dir
	thruster_visual_timer = maxf(thruster_visual_timer, 0.18)
	boost_flash_timer = maxf(boost_flash_timer, 0.16)
	if reason != "":
		set_meta("last_velocity_brake_reason", reason)
	return true


func _movement_command_mode(input_vector: Vector2) -> String:
	if input_vector.length() <= 0.04:
		return MOVE_COMMAND_NONE
	if _reverse_drive_allowed(input_vector):
		set_meta("last_move_command_mode", "reverse")
		return MOVE_COMMAND_DRIVE
	if _brake_reverse_waiting_for_repress(input_vector):
		set_meta("last_move_command_mode", "none")
		return MOVE_COMMAND_NONE
	if _input_should_velocity_brake(input_vector):
		set_meta("last_move_command_mode", "brake" if _can_velocity_brake() else "none")
		return MOVE_COMMAND_BRAKE if _can_velocity_brake() else MOVE_COMMAND_NONE
	var desired := _thruster_drive_direction(input_vector)
	if desired.length() > 0.04:
		set_meta("last_move_command_mode", "drive")
		return MOVE_COMMAND_DRIVE
	set_meta("last_move_command_mode", "brake" if _can_velocity_brake() else "none")
	return MOVE_COMMAND_BRAKE if _can_velocity_brake() else MOVE_COMMAND_NONE


func _drive_direction_for_command(input_vector: Vector2, command_mode: String) -> Vector2:
	if command_mode == MOVE_COMMAND_DRIVE and _reverse_drive_allowed(input_vector):
		return input_vector.normalized()
	return _thruster_drive_direction(input_vector)


func move_by(input_vector: Vector2, delta: float, ring_length: float) -> void:
	var gameplay_vector := GameplayTransform.screen_input_to_gameplay_motion(input_vector)
	move_by_gameplay(gameplay_vector, delta, ring_length)


func move_by_gameplay(input_vector: Vector2, delta: float, ring_length: float) -> void:
	if not active or role == "barrier":
		return
	if melee_stagger_timer > 0.0:
		return
	if cooling_lock_timer > 0.0:
		return

	var speed: float = float(stats.get("move_speed", 0.0))
	if overheated and role == "hero":
		speed *= 0.58
	if current_state == STATE_ARMOR:
		speed *= 0.48
	elif current_state == STATE_ACTIVE:
		speed *= 0.72

	var desired := input_vector
	if desired.length() <= 0.04:
		set_meta("last_move_command_mode", "none")
		return
	if desired.length() > 1.0:
		desired = desired.normalized()
	if module_clamp_pin_timer > 0.0:
		desired *= clampf(module_clamp_velocity_mult, 0.05, 1.0)

	var command_mode := _movement_command_mode(desired)
	if command_mode == MOVE_COMMAND_NONE:
		return
	if command_mode == MOVE_COMMAND_BRAKE:
		_apply_velocity_brake(delta, "reverse_brake", false, desired)
		return
	var drive_dir := _drive_direction_for_command(desired, command_mode)
	if drive_dir.length() <= 0.04:
		set_meta("last_move_command_mode", "none")
		return
	drive_dir = drive_dir.normalized()
	moved_this_frame = true
	thruster_output_direction = drive_dir
	thruster_visual_timer = maxf(thruster_visual_timer, 0.16)

	var acceleration: float = float(stats.get("move_acceleration", 0.0))
	if speed <= 0.0001 or acceleration <= 0.0001:
		return
	var cornering: float = maxf(0.35, float(stats.get("cornering", 1.0)))
	if recovery_boost_timer > 0.0:
		var recovery_response := _recovery_response_multiplier()
		acceleration *= recovery_response
		cornering *= clampf(0.7 + recovery_response * 0.3, 0.62, 1.22)
	var target_velocity := Vector2(drive_dir.x * speed, drive_dir.y * speed)
	var needed_delta := target_velocity - velocity
	if needed_delta.length() <= 0.001:
		return
	velocity += needed_delta.limit_length(acceleration * cornering * delta)
	if not _reverse_drive_allowed(desired):
		_clear_brake_reverse_ready()


func apply_clamp_pin(seconds: float, velocity_mult: float) -> void:
	var duration := maxf(0.0, seconds)
	if duration <= 0.0:
		return
	module_clamp_pin_timer = maxf(module_clamp_pin_timer, duration)
	module_clamp_velocity_mult = minf(module_clamp_velocity_mult, clampf(velocity_mult, 0.05, 1.0))
	velocity *= module_clamp_velocity_mult
	action_cooldown = maxf(action_cooldown, duration * 0.35)
	set_meta("clamp_pin_timer", module_clamp_pin_timer)
	set_meta("clamp_velocity_mult", module_clamp_velocity_mult)


func module_clamp_pin_ratio() -> float:
	if module_clamp_pin_timer <= 0.0:
		return 0.0
	return clampf(1.0 - module_clamp_velocity_mult, 0.0, 1.0)


func begin_action(action_kind: String) -> Dictionary:
	if not active or action_cooldown > 0.0 or health <= 0:
		return {}
	if melee_stagger_timer > 0.0:
		return {}

	var cooldown_mult := 1.45 if overheated and role == "hero" else 1.0

	if action_kind == STATE_ARMOR:
		current_state = STATE_ARMOR
		state_timer = float(stats.get("armor_duration", 0.48))
		action_cooldown = float(stats.get("armor_cooldown", 0.34)) * cooldown_mult
		combat_event.emit("%s armored" % unit_name)
		return {
			"owner_id": owner_id,
			"state": STATE_ARMOR,
			"damage": int(stats.get("armor_damage", 7)),
			"range": float(stats.get("armor_range", 0.24)),
			"lane_range": float(stats.get("armor_lane_range", 0.2)),
			"knock": float(stats.get("armor_knock", 0.05)),
			"damage_type": String(stats.get("damage_type", "blunt")),
			"material_class": String(stats.get("material_class", "weapon")),
			"recoil": float(stats.get("recoil", 0.05)),
			"source_name": unit_name,
		}

	var attack_state := STATE_ACTIVE if action_kind == STATE_ACTIVE else STATE_NORMAL
	current_state = attack_state
	state_timer = float(stats.get("%s_duration" % attack_state, 0.22))
	action_cooldown = float(stats.get("%s_cooldown" % attack_state, 0.38)) * cooldown_mult

	return {
		"owner_id": owner_id,
		"state": attack_state,
		"damage": int(stats.get("%s_damage" % attack_state, 12)),
		"range": float(stats.get("%s_range" % attack_state, 0.48)),
		"lane_range": float(stats.get("%s_lane_range" % attack_state, 0.28)),
		"knock": float(stats.get("%s_knock" % attack_state, 0.12)),
		"damage_type": String(stats.get("damage_type", "blunt")),
		"material_class": String(stats.get("material_class", "weapon")),
		"recoil": float(stats.get("recoil", 0.06)),
		"source_name": unit_name,
	}


func begin_module_action(action_kind: String, module_key: String = "", part_index: int = -1, allow_same_frame_pair: bool = false) -> Dictionary:
	var gate := _module_action_gate(module_key, part_index, allow_same_frame_pair)
	if not bool(gate.get("allowed", false)):
		set_meta("last_module_gate_reason", String(gate.get("reason", "locked")))
		return {}
	if bool(gate.get("cancel", false)):
		action_cooldown = 0.0
	var event := begin_action(action_kind)
	if event.is_empty():
		return {}
	if module_key != "":
		active_module_key = module_key
		active_module_part_index = maxi(0, part_index)
		active_module_started_at = Time.get_ticks_msec() * 0.001
		set_meta("active_module_key", active_module_key)
		set_meta("active_module_part_index", active_module_part_index)
	event["module_key"] = module_key
	event["module_cancel"] = bool(gate.get("cancel", false))
	event["cancel_from_module"] = String(gate.get("previous_key", ""))
	event["cancel_phase"] = float(gate.get("phase", 1.0))
	return event


func _runtime_node_array(raw_nodes: Array) -> Array:
	var nodes: Array = []
	for raw_node in raw_nodes:
		nodes.append(int(raw_node))
	return nodes


func _runtime_node_array_has(raw_nodes: Array, node_index: int) -> bool:
	for raw_node in raw_nodes:
		if int(raw_node) == node_index:
			return true
	return false


func _is_runtime_blade_profile(profile: String) -> bool:
	return profile in [
		"blade_arc_return",
		"katana_quickdraw",
		"scythe_hook_return",
		"greatsword_commit_cleave",
		"triple_limb_cross_cut",
		"extend_slash_driver",
	]


func _runtime_sources_for_nodes(target_nodes: Array) -> Array:
	var sources: Array = []
	for raw_node in target_nodes:
		var source := _runtime_segment_source_by_node(int(raw_node))
		if not source.is_empty():
			sources.append(source)
	return sources


func _runtime_motion_positive_min(current: float, candidate: float) -> float:
	var value := maxf(0.0, candidate)
	if value <= 0.0:
		return current
	if current <= 0.0:
		return value
	return minf(current, value)


func _runtime_binding_allocation_for_node(binding: Dictionary, node_index: int) -> float:
	if binding.is_empty():
		return -1.0
	var by_node = binding.get("allocated_limb_momentum_by_node", binding.get("joint_drive_allocation_by_node", {}))
	if by_node is Dictionary:
		var allocations: Dictionary = by_node
		var string_key := str(node_index)
		if allocations.has(string_key):
			return maxf(0.0, float(allocations.get(string_key, 0.0)))
		if allocations.has(node_index):
			return maxf(0.0, float(allocations.get(node_index, 0.0)))
	var target_count := maxi(1, _runtime_node_array(Array(binding.get("target_nodes", []))).size())
	for key in ["allocated_limb_momentum", "joint_drive_allocation_total", "joint_drive_demand", "allocated_momentum"]:
		if binding.has(key):
			return maxf(0.0, float(binding.get(key, 0.0))) / float(target_count)
	return -1.0


func _runtime_source_allocated_momentum(source: Dictionary, binding: Dictionary = {}) -> float:
	var node_index := int(source.get("node_index", -1))
	var momentum := _runtime_binding_allocation_for_node(binding, node_index)
	if momentum < 0.0:
		momentum = float(source.get("allocated_limb_momentum", source.get("allocated_momentum", -1.0)))
	if momentum < 0.0:
		momentum = maxf(0.0, float(source.get("joint_output_momentum_base", 0.0)))
	else:
		momentum = maxf(0.0, momentum)
	var min_momentum := maxf(0.0, float(source.get("momentum_min", 0.0)))
	var max_momentum := maxf(0.0, float(source.get("momentum_max", 0.0)))
	if max_momentum > 0.0:
		momentum = minf(momentum, max_momentum)
	if min_momentum > 0.0:
		momentum = maxf(momentum, min_momentum)
	return momentum


func _runtime_edge_node(edge: Dictionary, key: String) -> int:
	return int(edge.get(key, -9999))


func _runtime_edge_socket_for_node(edge: Dictionary, node_index: int) -> String:
	if _runtime_edge_node(edge, "a_node") == node_index:
		return String(edge.get("a_socket", ""))
	if _runtime_edge_node(edge, "b_node") == node_index:
		return String(edge.get("b_socket", ""))
	return ""


func _runtime_socket_is_parent_side(socket_id: String) -> bool:
	return socket_id == "distal" or socket_id.begins_with("torso_port:")


func _runtime_socket_is_child_root(socket_id: String) -> bool:
	return socket_id == "root_joint"


func _runtime_child_nodes_for(parent_node: int) -> Array:
	var result: Array = []
	for raw_edge in Array(stats.get("runtime_topology_edges", [])):
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a := _runtime_edge_node(edge, "a_node")
		var b := _runtime_edge_node(edge, "b_node")
		if a == parent_node:
			var parent_socket := _runtime_edge_socket_for_node(edge, a)
			var child_socket := _runtime_edge_socket_for_node(edge, b)
			if _runtime_socket_is_parent_side(parent_socket) and _runtime_socket_is_child_root(child_socket):
				result.append(b)
		elif b == parent_node:
			var parent_socket_b := _runtime_edge_socket_for_node(edge, b)
			var child_socket_a := _runtime_edge_socket_for_node(edge, a)
			if _runtime_socket_is_parent_side(parent_socket_b) and _runtime_socket_is_child_root(child_socket_a):
				result.append(a)
	return result


func _runtime_downstream_motion_for_node(node_index: int, included_nodes: Dictionary) -> Dictionary:
	var mass := 0.0
	var length := 0.0
	var speed_cap := 0.0
	for raw_child in _runtime_child_nodes_for(node_index):
		var child := int(raw_child)
		if included_nodes.has(child):
			continue
		included_nodes[child] = true
		var source := _runtime_segment_source_by_node(child)
		if not source.is_empty():
			var a := _runtime_local_vector(source.get("a_local", Vector2.ZERO))
			var b := _runtime_local_vector(source.get("b_local", a))
			length += maxf(0.0, a.distance_to(b))
			mass += maxf(0.0, float(source.get("mass", 0.0)))
			speed_cap = _runtime_motion_positive_min(speed_cap, float(source.get("joint_speed_cap", 0.0)))
		var nested := _runtime_downstream_motion_for_node(child, included_nodes)
		mass += maxf(0.0, float(nested.get("mass", 0.0)))
		length += maxf(0.0, float(nested.get("length", 0.0)))
		speed_cap = _runtime_motion_positive_min(speed_cap, float(nested.get("joint_speed_cap", 0.0)))
	return {"mass": mass, "length": length, "joint_speed_cap": speed_cap}


func _runtime_sources_motion_stats(target_nodes: Array, binding: Dictionary = {}) -> Dictionary:
	var mass := 0.0
	var length := 0.0
	var output := 0.0
	var speed_cap := 0.0
	var sources: Array = []
	var included_nodes := {}
	for raw_node in target_nodes:
		var node_index := int(raw_node)
		if included_nodes.has(node_index):
			continue
		var source := _runtime_segment_source_by_node(node_index)
		if source.is_empty():
			continue
		included_nodes[node_index] = true
		sources.append(source)
		var a := _runtime_local_vector(source.get("a_local", Vector2.ZERO))
		var b := _runtime_local_vector(source.get("b_local", a))
		length += maxf(0.0, a.distance_to(b))
		mass += maxf(0.0, float(source.get("mass", 0.0)))
		output += _runtime_source_allocated_momentum(source, binding)
		speed_cap = _runtime_motion_positive_min(speed_cap, float(source.get("joint_speed_cap", 0.0)))
		var downstream := _runtime_downstream_motion_for_node(node_index, included_nodes)
		mass += maxf(0.0, float(downstream.get("mass", 0.0)))
		length += maxf(0.0, float(downstream.get("length", 0.0)))
		speed_cap = _runtime_motion_positive_min(speed_cap, float(downstream.get("joint_speed_cap", 0.0)))
	if mass <= 0.0:
		mass = maxf(1.0, float(stats.get("mass", 1.0)) * 0.18)
	if output <= 0.0:
		output = maxf(0.0, float(stats.get("action_drive_scale", 1.0))) * maxf(1.0, mass)
	return {"sources": sources, "mass": mass, "length": length, "output": output, "joint_speed_cap": speed_cap}


func _runtime_action_motion_budget(target_nodes: Array, module_part: Dictionary, angle_degrees: float, extension_m: float, fallback_duration: float, state_key: String = STATE_NORMAL, binding: Dictionary = {}) -> Dictionary:
	var motion := _runtime_sources_motion_stats(target_nodes, binding)
	return MotionBudget.estimate_motion_budget(motion, module_part, angle_degrees, extension_m, fallback_duration, state_key)


func _apply_whole_body_action_state(state_key: String, duration: float) -> void:
	if state_key in [STATE_ARMOR, STATE_ACTIVE]:
		current_state = state_key
		state_timer = maxf(state_timer, maxf(0.08, duration))
	else:
		current_state = STATE_NORMAL
		state_timer = 0.0


func begin_runtime_module_action(action_kind: String, binding: Dictionary, input_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	if not _has_runtime_topology() or not active or health <= 0:
		return {}
	if melee_stagger_timer > 0.0:
		set_meta("last_module_gate_reason", "stagger")
		return {}
	if action_cooldown > 0.0:
		set_meta("last_module_gate_reason", "cooldown")
		return {}
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var profile := String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))
	if profile == "blunt_gauntlet_extend_swing":
		return _begin_runtime_gauntlet_extend_swing_action(action_kind, binding, input_direction)
	if profile in ["blunt_shield_guard_bash", "blunt_hammer_windup_slam"]:
		return _begin_runtime_blunt_terminal_action(action_kind, binding, input_direction)
	if _is_runtime_blade_profile(profile):
		return _begin_runtime_blade_action(action_kind, binding, input_direction)
	if _is_runtime_generic_melee_profile(profile):
		return _begin_runtime_generic_melee_action(action_kind, binding, input_direction)
	if profile != "two_link_forward_snap":
		set_meta("last_module_gate_reason", "unsupported runtime module")
		return {}
	var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
	if target_nodes.size() != 2:
		set_meta("last_module_gate_reason", "runtime binding needs two nodes")
		return {}
	var attack_key := clampi(int(binding.get("attack_key", 1)), 1, 6)
	var state_key := action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL
	var fallback_duration := 0.62
	var motion_budget := _runtime_action_motion_budget(target_nodes, module_part, float(module_part.get("swing_arc_degrees", 180.0)), 0.0, fallback_duration, state_key, binding)
	var duration := maxf(0.12, float(motion_budget.get("duration", fallback_duration)))
	var cooldown := maxf(0.12, float(module_part.get("cooldown", binding.get("cooldown", duration * 0.72))))
	var startup_ratio := clampf(float(module_part.get("startup_ratio", module_part.get("two_link_straight_phase", TWO_LINK_DEFAULT_STARTUP_RATIO))), 0.05, 0.95)
	var joint_actuation_speed := maxf(0.0, float(motion_budget.get("contact_speed", 0.0)))
	_apply_whole_body_action_state(state_key, duration)
	action_cooldown = cooldown
	active_part_index = attack_key - 1
	active_part_state = state_key
	active_part_direction = input_direction.normalized() if input_direction.length() > 0.01 else _forward_vector()
	active_part_duration = duration
	active_part_timer = duration
	active_module_key = "runtime:%d:%s" % [attack_key, profile]
	active_module_part_index = attack_key - 1
	active_module_started_at = Time.get_ticks_msec() * 0.001
	set_meta("active_module_key", active_module_key)
	set_meta("active_module_part_index", active_module_part_index)
	var action := {
		"profile": profile,
		"target_nodes": target_nodes.duplicate(true),
		"attack_key": attack_key,
		"timer": duration,
		"duration": duration,
		"state": state_key,
		"binding": binding.duplicate(true),
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"joint_actuation_speed": joint_actuation_speed,
		"runtime_contact_speed": joint_actuation_speed,
		"driven_mass": float(motion_budget.get("driven_mass", 0.0)),
	}
	runtime_module_actions.append(action)
	_refresh_visuals()
	var base_damage := float(module_part.get("%s_damage" % state_key, module_part.get("damage", 8.0)))
	return {
		"owner_id": owner_id,
		"state": state_key,
		"damage": int(roundf(base_damage)),
		"range": float(module_part.get("range", 0.44)),
		"lane_range": float(module_part.get("lane_range", 0.24)),
		"knock": float(module_part.get("knock", 0.12)),
		"damage_type": String(module_part.get("damage_type", "blunt")),
		"material_class": String(module_part.get("material_class", "weapon")),
		"recoil": float(module_part.get("recoil", 0.05)),
		"source_name": unit_name,
		"attack_key": attack_key,
		"module_action_profile": profile,
		"runtime_binding": true,
		"runtime_target_nodes": target_nodes.duplicate(true),
		"muscle_node": attack_key - 1,
		"joint_actuation_speed": joint_actuation_speed,
		"runtime_contact_speed": joint_actuation_speed,
		"runtime_action_duration": duration,
		"runtime_action_base_duration": fallback_duration,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
	}


func _is_runtime_generic_melee_profile(profile: String) -> bool:
	return profile in [
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
	]


func _runtime_module_variant_key(module_part: Dictionary, binding: Dictionary) -> String:
	return String(module_part.get("module_variant_key", binding.get("module_variant_key", ""))).to_lower()


func _apply_module_variant_fields(payload: Dictionary, module_part: Dictionary, variant_key: String) -> void:
	if variant_key == "":
		return
	payload["module_variant_key"] = variant_key
	payload["module_visual_family"] = String(module_part.get("module_visual_family", variant_key))
	payload["module_variant_label"] = String(module_part.get("module_variant_label", ""))
	match variant_key:
		"balance_string":
			payload["combo_balance_window"] = float(module_part.get("combo_balance_window", 1.2))
			payload["combo_balance_cooldown_mult"] = float(module_part.get("combo_balance_cooldown_mult", 0.62))
			payload["combo_balance_requires_different_key"] = bool(module_part.get("combo_balance_requires_different_key", true))
		"vise_close":
			payload["clamp_pin_seconds"] = float(module_part.get("clamp_pin_seconds", 0.38))
			payload["clamp_velocity_mult"] = float(module_part.get("clamp_velocity_mult", 0.35))
			payload["clamp_knock_mult"] = float(module_part.get("clamp_knock_mult", 0.38))
		"pickup_dash":
			payload["pickup_dash_impulse"] = float(module_part.get("pickup_dash_impulse", 0.65))
			payload["pickup_dash_on_hit_impulse"] = float(module_part.get("pickup_dash_on_hit_impulse", 0.35))
			payload["route_lane_pull"] = float(module_part.get("route_lane_pull", 0.1))
		"crush_windup":
			payload["contact_momentum_mult"] = float(module_part.get("crush_contact_momentum_mult", 1.45))
			payload["crush_stagger_mult"] = float(module_part.get("crush_stagger_mult", 1.35))
			payload["whiff_recovery_mult"] = float(module_part.get("whiff_recovery_mult", 1.25))
			payload["runtime_contact_damage_mult"] = float(module_part.get("runtime_contact_damage_mult", 1.24))
		"feint_thrust":
			payload["feint_retarget_degrees"] = float(module_part.get("feint_retarget_degrees", 18.0))
			payload["feint_ghost_phase"] = float(module_part.get("feint_ghost_phase", 0.42))
			payload["feint_final_width_mult"] = float(module_part.get("feint_final_width_mult", 0.65))
		"explosive_arc_salvo":
			payload["salvo_arc_min_range"] = float(module_part.get("salvo_arc_min_range", 1.35))
			payload["salvo_arc_max_range"] = float(module_part.get("salvo_arc_max_range", 3.8))
			payload["salvo_hold_range_seconds"] = float(module_part.get("salvo_hold_range_seconds", 0.75))
			payload["salvo_landing_marker"] = bool(module_part.get("salvo_landing_marker", true))


func _commit_combo_balance_window(action: Dictionary) -> void:
	if String(action.get("module_variant_key", "")) != "balance_string":
		return
	var now := Time.get_ticks_msec() * 0.001
	set_meta("combo_balance_ready_until", now + maxf(0.05, float(action.get("combo_balance_window", 1.2))))
	set_meta("combo_balance_source_attack_key", int(action.get("attack_key", -1)))
	set_meta("combo_balance_cooldown_mult", clampf(float(action.get("combo_balance_cooldown_mult", 0.62)), 0.25, 1.0))


func _begin_runtime_generic_melee_action(action_kind: String, binding: Dictionary, input_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var profile := String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))
	var module_variant_key := _runtime_module_variant_key(module_part, binding)
	var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
	if target_nodes.is_empty():
		set_meta("last_module_gate_reason", "runtime binding needs target nodes")
		return {}
	var attack_key := clampi(int(binding.get("attack_key", 1)), 1, 6)
	var state_key := action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL
	var extension_m := maxf(0.0, float(module_part.get("module_extension_m", module_part.get("required_extension_m", binding.get("module_extension_m", 0.0)))))
	if profile == "pierce_telescopic_lunge":
		extension_m = maxf(extension_m, float(module_part.get("max_extension_m", 0.0)))
	var swing_arc := maxf(0.0, float(module_part.get("swing_arc_degrees", 120.0 if extension_m <= 0.0 else 0.0)))
	var fallback_duration := maxf(0.18, float(module_part.get("duration", 0.62)))
	var motion_budget := _runtime_action_motion_budget(target_nodes, module_part, swing_arc, extension_m, fallback_duration, state_key, binding)
	var duration := maxf(0.12, float(motion_budget.get("duration", fallback_duration)))
	var cooldown := maxf(0.12, float(module_part.get("cooldown", binding.get("cooldown", duration * 0.72))))
	var startup_ratio := clampf(float(module_part.get("startup_ratio", 0.333333)), 0.05, 0.95)
	var contact_speed := maxf(0.0, float(motion_budget.get("contact_speed", 0.0)))
	if module_variant_key == "crush_windup":
		contact_speed *= maxf(0.1, float(module_part.get("crush_contact_momentum_mult", 1.45)))
	var combo_refund_applied := false
	var now := Time.get_ticks_msec() * 0.001
	if now <= float(get_meta("combo_balance_ready_until", 0.0)) and int(get_meta("combo_balance_source_attack_key", -999)) != attack_key:
		cooldown *= clampf(float(get_meta("combo_balance_cooldown_mult", 1.0)), 0.25, 1.0)
		combo_refund_applied = true
		set_meta("combo_balance_ready_until", 0.0)
		set_meta("combo_balance_source_attack_key", -999)
	_apply_whole_body_action_state(state_key, duration)
	var active_direction := input_direction.normalized() if input_direction.length() > 0.01 else _forward_vector()
	if module_variant_key == "pickup_dash" and bool(module_part.get("pickup_dash_on_start", true)):
		var dash_impulse := maxf(0.0, float(module_part.get("pickup_dash_impulse", 0.65)))
		if dash_impulse > 0.0:
			velocity += active_direction * dash_impulse
			_clamp_velocity_to_speedometer()
			set_meta("last_pickup_dash_impulse", dash_impulse)
	action_cooldown = cooldown
	active_part_index = attack_key - 1
	active_part_state = state_key
	active_part_direction = active_direction
	active_part_duration = duration
	active_part_timer = duration
	active_module_key = "runtime:%d:%s" % [attack_key, profile]
	active_module_part_index = attack_key - 1
	active_module_started_at = Time.get_ticks_msec() * 0.001
	set_meta("active_module_key", active_module_key)
	set_meta("active_module_part_index", active_module_part_index)
	var action := {
		"profile": profile,
		"target_nodes": target_nodes.duplicate(true),
		"attack_key": attack_key,
		"timer": duration,
		"duration": duration,
		"state": state_key,
		"binding": binding.duplicate(true),
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"driven_mass": float(motion_budget.get("driven_mass", 0.0)),
		"generic_melee_pose": true,
		"module_extension_m": extension_m,
		"swing_arc_degrees": swing_arc,
		"combo_balance_refund_applied": combo_refund_applied,
		"module_base_cooldown": cooldown,
		"module_variant_hit_confirmed": false,
	}
	if module_variant_key == "feint_thrust":
		action["feint_base_direction"] = active_direction
		action["feint_retarget_direction"] = active_direction
	_apply_module_variant_fields(action, module_part, module_variant_key)
	runtime_module_actions.append(action)
	_refresh_visuals()
	var base_damage := float(module_part.get("%s_damage" % state_key, module_part.get("normal_damage", module_part.get("damage", 8.0))))
	var event := {
		"owner_id": owner_id,
		"state": state_key,
		"damage": int(roundf(base_damage)),
		"range": float(module_part.get("range", maxf(0.3, extension_m * 0.16 + 0.24))),
		"lane_range": float(module_part.get("lane_range", 0.24)),
		"knock": float(module_part.get("knock", 0.12)),
		"damage_type": String(module_part.get("damage_type", "blunt")),
		"material_class": String(module_part.get("material_class", "weapon")),
		"recoil": float(module_part.get("recoil", 0.05)),
		"source_name": unit_name,
		"attack_key": attack_key,
		"module_action_profile": profile,
		"runtime_binding": true,
		"runtime_target_nodes": target_nodes.duplicate(true),
		"muscle_node": attack_key - 1,
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"runtime_action_duration": duration,
		"runtime_action_base_duration": fallback_duration,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"combo_balance_refund_applied": combo_refund_applied,
	}
	_apply_module_variant_fields(event, module_part, module_variant_key)
	if module_variant_key == "vise_close":
		event["knock"] = float(event.get("knock", 0.12)) * clampf(float(module_part.get("clamp_knock_mult", 0.38)), 0.05, 1.0)
	return event


func _begin_runtime_blunt_terminal_action(action_kind: String, binding: Dictionary, input_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var profile := String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))
	var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
	if target_nodes.size() != 1:
		set_meta("last_module_gate_reason", "blunt terminal binding needs one terminal node")
		return {}
	var target_source := _runtime_segment_source_by_node(int(target_nodes[0]))
	if target_source.is_empty():
		set_meta("last_module_gate_reason", "blunt terminal segment missing")
		return {}
	var attack_key := clampi(int(binding.get("attack_key", 1)), 1, 6)
	var state_key := action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL
	var default_duration := 0.5 if profile == "blunt_shield_guard_bash" else 0.82
	var fallback_duration := default_duration
	var startup_ratio := clampf(float(module_part.get("startup_ratio", 0.26 if profile == "blunt_shield_guard_bash" else 0.45)), 0.05, 0.95)
	var root_local := _runtime_local_vector(target_source.get("a_local", Vector2.ZERO))
	var tip_local := _runtime_local_vector(target_source.get("b_local", root_local + Vector2.RIGHT * 0.5))
	var base_length := maxf(0.001, root_local.distance_to(tip_local))
	var swing_arc := deg_to_rad(maxf(0.0, float(module_part.get("swing_arc_degrees", 82.0 if profile == "blunt_shield_guard_bash" else 150.0))))
	var motion_budget := _runtime_action_motion_budget(target_nodes, module_part, rad_to_deg(swing_arc), 0.0, fallback_duration, state_key, binding)
	var duration := maxf(0.12, float(motion_budget.get("duration", fallback_duration)))
	var cooldown := maxf(0.12, float(module_part.get("cooldown", binding.get("cooldown", duration * 0.68))))
	var momentum_mult := maxf(0.1, float(module_part.get("blunt_momentum_mult", 1.2 if profile == "blunt_shield_guard_bash" else 1.45)))
	var command_variant := String(binding.get("runtime_command_variant", ""))
	if command_variant == "":
		if profile == "blunt_shield_guard_bash":
			command_variant = "armor_guard_bash" if state_key == STATE_ARMOR else ("active_shoulder_bash" if state_key == STATE_ACTIVE else "normal_guard")
		else:
			command_variant = "armor_overhead_slam" if state_key == STATE_ARMOR else ("active_side_slam" if state_key == STATE_ACTIVE else "normal_short_swing")
	if profile == "blunt_shield_guard_bash":
		if command_variant in ["armor_guard_bash", "active_shoulder_bash", "normal_forward_bash"]:
			momentum_mult *= 1.18
		elif command_variant == "normal_guard":
			momentum_mult *= 0.86
	else:
		if command_variant in ["armor_overhead_slam", "active_side_slam"]:
			momentum_mult *= 1.18
		elif command_variant == "normal_short_swing":
			momentum_mult *= 0.9
	var contact_speed := maxf(float(motion_budget.get("contact_speed", 0.0)), base_length * maxf(0.1, swing_arc) / maxf(0.001, duration)) * momentum_mult
	var special_heat_fraction := maxf(0.0, float(module_part.get("special_heat_fraction", 0.0)))
	if state_key in [STATE_ARMOR, STATE_ACTIVE] and special_heat_fraction > 0.0:
		add_heat(maxf(1.0, float(stats.get("heat_capacity", 100.0))) * special_heat_fraction, "heat:repeat heat:blunt")
	_apply_whole_body_action_state(state_key, duration)
	action_cooldown = cooldown
	active_part_index = attack_key - 1
	active_part_state = state_key
	active_part_direction = input_direction.normalized() if input_direction.length() > 0.01 else _forward_vector()
	active_part_duration = duration
	active_part_timer = duration
	active_module_key = "runtime:%d:%s" % [attack_key, profile]
	active_module_part_index = attack_key - 1
	active_module_started_at = Time.get_ticks_msec() * 0.001
	set_meta("active_module_key", active_module_key)
	set_meta("active_module_part_index", active_module_part_index)
	var action := {
		"profile": profile,
		"target_nodes": target_nodes.duplicate(true),
		"attack_key": attack_key,
		"timer": duration,
		"duration": duration,
		"state": state_key,
		"binding": binding.duplicate(true),
		"command_variant": command_variant,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"terminal_momentum_mult": momentum_mult,
		"driven_mass": float(motion_budget.get("driven_mass", 0.0)),
	}
	runtime_module_actions.append(action)
	_refresh_visuals()
	var base_damage := float(module_part.get("%s_damage" % state_key, module_part.get("normal_damage", module_part.get("damage", 10.0))))
	return {
		"owner_id": owner_id,
		"state": state_key,
		"damage": int(roundf(base_damage)),
		"range": float(module_part.get("range", 0.46)),
		"lane_range": float(module_part.get("lane_range", 0.26)),
		"knock": float(module_part.get("knock", 0.14)),
		"damage_type": String(module_part.get("damage_type", "blunt")),
		"material_class": String(module_part.get("material_class", "weapon")),
		"recoil": float(module_part.get("recoil", 0.06)),
		"source_name": unit_name,
		"attack_key": attack_key,
		"module_action_profile": profile,
		"runtime_binding": true,
		"runtime_target_nodes": target_nodes.duplicate(true),
		"muscle_node": attack_key - 1,
		"terminal_momentum_mult": momentum_mult,
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"runtime_action_duration": duration,
		"runtime_action_base_duration": fallback_duration,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
	}


func _begin_runtime_blade_action(action_kind: String, binding: Dictionary, input_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var profile := String(binding.get("module_action_profile", module_part.get("module_action_profile", "")))
	var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
	if target_nodes.is_empty():
		set_meta("last_module_gate_reason", "blade binding needs at least one limb node")
		return {}
	var min_bound_nodes := int(module_part.get("min_bound_nodes", 0))
	if min_bound_nodes > 0 and target_nodes.size() < min_bound_nodes:
		set_meta("last_module_gate_reason", "blade binding needs %d nodes" % min_bound_nodes)
		return {}
	var sources: Array = []
	for raw_node in target_nodes:
		var source := _runtime_segment_source_by_node(int(raw_node))
		if source.is_empty():
			continue
		sources.append(source)
	if sources.is_empty():
		set_meta("last_module_gate_reason", "blade segment missing")
		return {}
	var attack_key := clampi(int(binding.get("attack_key", 1)), 1, 6)
	var state_key := action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL
	var default_duration := 0.54
	match profile:
		"katana_quickdraw":
			default_duration = 0.34
		"scythe_hook_return":
			default_duration = 0.62
		"greatsword_commit_cleave":
			default_duration = 0.78
		"triple_limb_cross_cut":
			default_duration = 0.72
		"extend_slash_driver":
			default_duration = 0.64
	var fallback_duration := default_duration
	var startup_ratio := clampf(float(module_part.get("startup_ratio", 0.36)), 0.05, 0.95)
	var swing_arc := deg_to_rad(maxf(0.0, float(module_part.get("swing_arc_degrees", 180.0))))
	var chain_length := 0.0
	for source in sources:
		var a := _runtime_local_vector(Dictionary(source).get("a_local", Vector2.ZERO))
		var b := _runtime_local_vector(Dictionary(source).get("b_local", a))
		chain_length += maxf(0.0, a.distance_to(b))
	var extension_m := maxf(0.0, float(module_part.get("module_extension_m", 0.0))) if profile == "extend_slash_driver" else 0.0
	var motion_budget := _runtime_action_motion_budget(target_nodes, module_part, rad_to_deg(swing_arc), extension_m, fallback_duration, state_key, binding)
	var duration := maxf(0.12, float(motion_budget.get("duration", fallback_duration)))
	var cooldown := maxf(0.10, float(module_part.get("cooldown", binding.get("cooldown", duration * 0.72))))
	var contact_speed := maxf(float(motion_budget.get("contact_speed", 0.0)), (chain_length * maxf(0.1, swing_arc) + extension_m) / maxf(0.001, duration))
	if state_key == STATE_ARMOR:
		contact_speed *= 1.12
	elif state_key == STATE_ACTIVE:
		contact_speed *= 1.18
	var special_heat_fraction := maxf(0.0, float(module_part.get("special_heat_fraction", 0.0)))
	if state_key in [STATE_ARMOR, STATE_ACTIVE] and special_heat_fraction > 0.0:
		add_heat(maxf(1.0, float(stats.get("heat_capacity", 100.0))) * special_heat_fraction, "heat:repeat heat:blade")
	_apply_whole_body_action_state(state_key, duration)
	action_cooldown = cooldown
	active_part_index = attack_key - 1
	active_part_state = state_key
	active_part_direction = input_direction.normalized() if input_direction.length() > 0.01 else _forward_vector()
	active_part_duration = duration
	active_part_timer = duration
	active_module_key = "runtime:%d:%s" % [attack_key, profile]
	active_module_part_index = attack_key - 1
	active_module_started_at = Time.get_ticks_msec() * 0.001
	set_meta("active_module_key", active_module_key)
	set_meta("active_module_part_index", active_module_part_index)
	var command_variant := String(binding.get("runtime_command_variant", ""))
	if command_variant == "":
		if state_key == STATE_ARMOR:
			command_variant = "armor_special" if String(module_part.get("command_window_profile", "")) == "blade_complex_236_214" else "armor_forward_cut"
		elif state_key == STATE_ACTIVE:
			command_variant = "active_special" if String(module_part.get("command_window_profile", "")) == "blade_complex_236_214" else "active_reverse_cut"
		else:
			command_variant = "normal_sweep"
	var action := {
		"profile": profile,
		"target_nodes": target_nodes.duplicate(true),
		"attack_key": attack_key,
		"timer": duration,
		"duration": duration,
		"state": state_key,
		"binding": binding.duplicate(true),
		"command_variant": command_variant,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"extension_m": extension_m,
		"driven_mass": float(motion_budget.get("driven_mass", 0.0)),
	}
	runtime_module_actions.append(action)
	_refresh_visuals()
	var base_damage := float(module_part.get("%s_damage" % state_key, module_part.get("normal_damage", module_part.get("damage", 10.0))))
	return {
		"owner_id": owner_id,
		"state": state_key,
		"damage": int(roundf(base_damage)),
		"range": float(module_part.get("range", 0.46)),
		"lane_range": float(module_part.get("lane_range", 0.26)),
		"knock": float(module_part.get("knock", 0.12)),
		"damage_type": String(module_part.get("damage_type", "tear")),
		"material_class": String(module_part.get("material_class", "weapon")),
		"recoil": float(module_part.get("recoil", 0.05)),
		"source_name": unit_name,
		"attack_key": attack_key,
		"module_action_profile": profile,
		"runtime_binding": true,
		"runtime_target_nodes": target_nodes.duplicate(true),
		"muscle_node": attack_key - 1,
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"runtime_action_duration": duration,
		"runtime_action_base_duration": fallback_duration,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
	}


func _begin_runtime_gauntlet_extend_swing_action(action_kind: String, binding: Dictionary, input_direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
	if target_nodes.size() != 1:
		set_meta("last_module_gate_reason", "gauntlet binding needs one terminal node")
		return {}
	var target_source := _runtime_segment_source_by_node(int(target_nodes[0]))
	if target_source.is_empty():
		set_meta("last_module_gate_reason", "gauntlet segment missing")
		return {}
	var attack_key := clampi(int(binding.get("attack_key", 1)), 1, 6)
	var state_key := action_kind if action_kind in [STATE_NORMAL, STATE_ARMOR, STATE_ACTIVE] else STATE_NORMAL
	var fallback_duration := 0.68
	var startup_ratio := clampf(float(module_part.get("startup_ratio", 1.0 / 3.0)), 0.05, 0.95)
	var extension_m := maxf(0.0, float(module_part.get("module_extension_m", module_part.get("required_extension_m", 2.0))))
	var swing_degrees := float(module_part.get("swing_arc_degrees", 70.0))
	var root_local := _runtime_local_vector(target_source.get("a_local", Vector2.ZERO))
	var tip_local := _runtime_local_vector(target_source.get("b_local", root_local + Vector2.RIGHT * 0.5))
	var base_length := maxf(0.001, root_local.distance_to(tip_local))
	var motion_budget := _runtime_action_motion_budget(target_nodes, module_part, swing_degrees, extension_m, fallback_duration, state_key, binding)
	var duration := maxf(0.12, float(motion_budget.get("duration", fallback_duration)))
	var cooldown := maxf(0.12, float(module_part.get("cooldown", binding.get("cooldown", duration * 0.62))))
	var contact_speed := maxf(float(motion_budget.get("contact_speed", 0.0)), (extension_m + deg_to_rad(maxf(0.0, swing_degrees)) * base_length) / maxf(0.001, duration))
	contact_speed *= maxf(0.1, float(module_part.get("blunt_momentum_mult", 1.5)))
	if state_key in [STATE_ARMOR, STATE_ACTIVE]:
		var heat_fraction := maxf(0.0, float(module_part.get("special_heat_fraction", 0.1)))
		add_heat(maxf(1.0, float(stats.get("heat_capacity", 100.0))) * heat_fraction, "heat:repeat heat:gauntlet")
	_apply_whole_body_action_state(state_key, duration)
	action_cooldown = cooldown
	active_part_index = attack_key - 1
	active_part_state = state_key
	active_part_direction = input_direction.normalized() if input_direction.length() > 0.01 else _forward_vector()
	active_part_duration = duration
	active_part_timer = duration
	active_module_key = "runtime:%d:%s" % [attack_key, "blunt_gauntlet_extend_swing"]
	active_module_part_index = attack_key - 1
	active_module_started_at = Time.get_ticks_msec() * 0.001
	set_meta("active_module_key", active_module_key)
	set_meta("active_module_part_index", active_module_part_index)
	var command_variant := String(binding.get("runtime_command_variant", ""))
	if command_variant == "":
		if state_key == STATE_ARMOR:
			command_variant = "armor_inward_extend"
		elif state_key == STATE_ACTIVE:
			command_variant = "active_outward_extend"
		else:
			command_variant = "normal_extend"
	var action := {
		"profile": "blunt_gauntlet_extend_swing",
		"target_nodes": target_nodes.duplicate(true),
		"attack_key": attack_key,
		"timer": duration,
		"duration": duration,
		"state": state_key,
		"binding": binding.duplicate(true),
		"command_variant": command_variant,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"extension_m": extension_m,
		"driven_mass": float(motion_budget.get("driven_mass", 0.0)),
	}
	runtime_module_actions.append(action)
	_refresh_visuals()
	var base_damage := float(module_part.get("%s_damage" % state_key, module_part.get("damage", 12.0)))
	return {
		"owner_id": owner_id,
		"state": state_key,
		"damage": int(roundf(base_damage)),
		"range": float(module_part.get("range", 0.46)),
		"lane_range": float(module_part.get("lane_range", 0.28)),
		"knock": float(module_part.get("knock", 0.16)),
		"damage_type": String(module_part.get("damage_type", "blunt")),
		"material_class": String(module_part.get("material_class", "weapon")),
		"recoil": float(module_part.get("recoil", 0.05)),
		"source_name": unit_name,
		"attack_key": attack_key,
		"module_action_profile": "blunt_gauntlet_extend_swing",
		"runtime_binding": true,
		"runtime_target_nodes": target_nodes.duplicate(true),
		"muscle_node": attack_key - 1,
		"terminal_momentum_mult": maxf(1.0, float(module_part.get("blunt_momentum_mult", 1.5))),
		"joint_actuation_speed": contact_speed,
		"runtime_contact_speed": contact_speed,
		"runtime_action_duration": duration,
		"runtime_action_base_duration": fallback_duration,
		"startup_ratio": startup_ratio,
		"recovery_ratio": maxf(0.0, 1.0 - startup_ratio),
	}


func _module_variant_input_direction() -> Vector2:
	var raw: Variant = get_meta("gameplay_move_input_vector", Vector2.ZERO)
	if raw is Vector2 and raw.length() > 0.18:
		return raw.normalized()
	raw = get_meta("move_input_vector", Vector2.ZERO)
	if raw is Vector2 and raw.length() > 0.18:
		return raw.normalized()
	return Vector2.ZERO


func _module_variant_clamped_retarget(base_direction: Vector2, desired_direction: Vector2, max_degrees: float) -> Vector2:
	var base_dir := base_direction.normalized() if base_direction.length() > 0.01 else _forward_vector()
	var desired_dir := desired_direction.normalized() if desired_direction.length() > 0.01 else base_dir
	var max_angle := deg_to_rad(maxf(0.0, max_degrees))
	var signed_delta := clampf(base_dir.angle_to(desired_dir), -max_angle, max_angle)
	return base_dir.rotated(signed_delta).normalized()


func _tick_module_variant_action(action: Dictionary, _delta: float) -> Dictionary:
	if String(action.get("module_variant_key", "")) != "feint_thrust":
		return action
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	if phase > startup_ratio:
		return action
	var desired := _module_variant_input_direction()
	if desired.length() <= 0.01:
		return action
	var base_dir: Vector2 = action.get("feint_base_direction", active_part_direction)
	var retarget := _module_variant_clamped_retarget(base_dir, desired, float(action.get("feint_retarget_degrees", 18.0)))
	action["feint_retarget_direction"] = retarget
	set_meta("last_feint_retarget_direction", retarget)
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()
	return action


func _complete_module_variant_action(action: Dictionary) -> void:
	if String(action.get("module_variant_key", "")) != "crush_windup":
		return
	if bool(action.get("module_variant_hit_confirmed", false)):
		set_meta("last_crush_windup_result", "hit")
		return
	var whiff_mult := maxf(1.0, float(action.get("whiff_recovery_mult", 1.0)))
	var base_cooldown := maxf(0.0, float(action.get("module_base_cooldown", action.get("duration", 0.0))))
	var extra_recovery := base_cooldown * (whiff_mult - 1.0)
	if extra_recovery > 0.0:
		action_cooldown = maxf(action_cooldown, extra_recovery)
	set_meta("last_crush_windup_result", "whiff")
	set_meta("last_crush_whiff_recovery", extra_recovery)


func mark_runtime_module_variant_hit(attack_key: int, variant_key: String = "") -> void:
	if runtime_module_actions.is_empty():
		return
	var normalized_variant := variant_key.to_lower()
	for i in range(runtime_module_actions.size()):
		if not (runtime_module_actions[i] is Dictionary):
			continue
		var action: Dictionary = runtime_module_actions[i]
		if int(action.get("attack_key", -999)) != attack_key:
			continue
		if normalized_variant != "" and String(action.get("module_variant_key", "")).to_lower() != normalized_variant:
			continue
		action["module_variant_hit_confirmed"] = true
		runtime_module_actions[i] = action
		set_meta("last_module_variant_hit_key", String(action.get("module_variant_key", "")))
		return


func _tick_runtime_module_actions(delta: float) -> void:
	if runtime_module_actions.is_empty():
		return
	for i in range(runtime_module_actions.size() - 1, -1, -1):
		if not (runtime_module_actions[i] is Dictionary):
			runtime_module_actions.remove_at(i)
			continue
		var action: Dictionary = runtime_module_actions[i]
		action["timer"] = maxf(0.0, float(action.get("timer", 0.0)) - delta)
		action = _tick_module_variant_action(action, delta)
		if float(action["timer"]) <= 0.0:
			if String(action.get("profile", "")) == "two_link_forward_snap":
				_commit_runtime_two_link_forward_snap_pose(action)
			elif String(action.get("profile", "")) == "blunt_gauntlet_extend_swing":
				_commit_runtime_gauntlet_extend_swing_pose(action)
			elif String(action.get("profile", "")) in ["blunt_shield_guard_bash", "blunt_hammer_windup_slam"]:
				_commit_runtime_blunt_terminal_pose(action)
			elif _is_runtime_blade_profile(String(action.get("profile", ""))):
				_commit_runtime_blade_pose(action)
			_commit_combo_balance_window(action)
			_complete_module_variant_action(action)
			runtime_module_actions.remove_at(i)
			_refresh_visuals()
		else:
			runtime_module_actions[i] = action


func force_runtime_recovery_from_collision(node_index: int) -> void:
	if node_index < 0 or runtime_module_actions.is_empty():
		return
	for i in range(runtime_module_actions.size()):
		if not (runtime_module_actions[i] is Dictionary):
			continue
		var action: Dictionary = runtime_module_actions[i]
		var target_nodes: Array = Array(action.get("target_nodes", []))
		if not _runtime_node_array_has(target_nodes, node_index):
			continue
		var startup_ratio := clampf(float(action.get("startup_ratio", TWO_LINK_DEFAULT_STARTUP_RATIO)), 0.05, 0.95)
		if _runtime_action_phase(action) < startup_ratio:
			var duration := maxf(0.001, float(action.get("duration", 0.0)))
			action["timer"] = minf(float(action.get("timer", duration)), duration * (1.0 - startup_ratio))
			runtime_module_actions[i] = action


func force_runtime_recovery_from_gpu(node_index: int) -> void:
	if node_index < 0 or runtime_module_actions.is_empty():
		return
	for i in range(runtime_module_actions.size()):
		if not (runtime_module_actions[i] is Dictionary):
			continue
		var action: Dictionary = runtime_module_actions[i]
		var target_nodes: Array = Array(action.get("target_nodes", []))
		if not _runtime_node_array_has(target_nodes, node_index):
			continue
		var startup_ratio := clampf(float(action.get("startup_ratio", TWO_LINK_DEFAULT_STARTUP_RATIO)), 0.05, 0.95)
		var duration := maxf(0.001, float(action.get("duration", 0.0)))
		action["timer"] = minf(float(action.get("timer", duration)), duration * (1.0 - startup_ratio))
		runtime_module_actions[i] = action


func request_collision_auto_brake() -> void:
	if not active:
		return
	collision_auto_brake_timer = maxf(collision_auto_brake_timer, maxf(0.18, float(stats.get("boost_duration", 0.3)) * 1.4))


func _tick_collision_auto_brake(delta: float) -> void:
	if collision_auto_brake_timer <= 0.0:
		return
	collision_auto_brake_timer = maxf(0.0, collision_auto_brake_timer - delta)
	if velocity.length() <= 0.001:
		velocity = Vector2.ZERO
		return
	var duration := maxf(0.04, float(stats.get("boost_duration", 0.3)))
	var brake_accel := _brake_delta_velocity() / duration
	if brake_accel <= 0.0001:
		return
	var old_dir := velocity.normalized()
	var brake_step := minf(velocity.length(), brake_accel * delta)
	velocity -= old_dir * brake_step
	if velocity.length() < 0.001 or velocity.dot(old_dir) <= 0.0:
		velocity = Vector2.ZERO
	thruster_output_direction = -old_dir
	thruster_visual_timer = maxf(thruster_visual_timer, 0.12)


func _module_action_gate(module_key: String, part_index: int, allow_same_frame_pair: bool) -> Dictionary:
	if not active or health <= 0:
		return {"allowed": false, "reason": "inactive"}
	if melee_stagger_timer > 0.0:
		return {"allowed": false, "reason": "stagger"}
	if module_key == "":
		return {"allowed": action_cooldown <= 0.0, "reason": "cooldown"}
	var now := Time.get_ticks_msec() * 0.001
	if active_module_key == module_key:
		var paired_instant := allow_same_frame_pair and now - active_module_started_at <= 0.055
		if not paired_instant and not _module_curve_fully_decelerated(active_module_part_index):
			return {"allowed": false, "reason": "same_module_decelerating", "previous_key": active_module_key}
		if action_cooldown > 0.0 and not paired_instant:
			return {"allowed": false, "reason": "same_module_cooldown", "previous_key": active_module_key}
		return {"allowed": true, "reason": "same_module_ready", "previous_key": active_module_key}
	if action_cooldown <= 0.0:
		return {"allowed": true, "reason": "free", "previous_key": active_module_key}
	if active_module_key != "" and active_module_part_index >= 0:
		_ensure_limb_index(active_module_part_index)
		var phase := _limb_drive_phase(active_module_part_index)
		var power := _limb_drive_power(active_module_part_index)
		var in_peak_cancel := float(limb_drive_timers[active_module_part_index]) > 0.0 and phase >= MODULE_CANCEL_PHASE_START and phase <= MODULE_CANCEL_PHASE_END and power >= MODULE_CANCEL_MIN_POWER
		if in_peak_cancel:
			set_meta("module_cancel_ready", true)
			return {
				"allowed": true,
				"cancel": true,
				"reason": "peak_cancel",
				"previous_key": active_module_key,
				"phase": phase,
				"power": power,
			}
	set_meta("module_cancel_ready", false)
	return {"allowed": false, "reason": "cooldown", "previous_key": active_module_key}


func _module_curve_fully_decelerated(part_index: int) -> bool:
	if part_index < 0:
		return action_cooldown <= 0.0
	_ensure_limb_index(part_index)
	var drive_done := float(limb_drive_timers[part_index]) <= 0.0
	var angular_decelerated := absf(float(limb_swing_velocities[part_index])) <= MODULE_FULL_DECEL_VELOCITY
	var linear_velocity: Vector2 = limb_linear_velocities[part_index]
	var linear_decelerated := linear_velocity.length() <= MODULE_FULL_DECEL_LINEAR_VELOCITY
	return drive_done and angular_decelerated and linear_decelerated


func mark_part_action(part_index: int, direction: Vector2, action_state: String, duration: float = 0.0) -> void:
	active_part_index = maxi(0, part_index)
	active_part_state = action_state
	if direction.length() > 0.01:
		active_part_direction = direction.normalized()
		last_action_direction = active_part_direction
	else:
		active_part_direction = _forward_vector()
	var requested_duration: float = duration if duration > 0.0 else maxf(state_timer, action_cooldown * 0.55)
	var minimum_duration := 0.54
	if action_state == STATE_ACTIVE:
		minimum_duration = 0.66
	elif action_state == STATE_ARMOR:
		minimum_duration = 0.72
	active_part_duration = maxf(minimum_duration, requested_duration)
	active_part_timer = active_part_duration
	_start_limb_inertia(active_part_index, active_part_direction, action_state, active_part_duration)
	_refresh_visuals()


func set_aim_pose(part_index: int, direction: Vector2, hold_time: float = 0.12) -> void:
	if not active or part_index < 0:
		return
	var previous_scale := scale
	var previous_visual_scale := mobius_visual_scale
	var previous_target_scale := mobius_visual_scale_target
	var previous_hitbox_scale := visual_hitbox_scale
	aim_pose_part_index = part_index
	aim_pose_direction = direction.normalized() if direction.length() > 0.01 else _forward_vector()
	aim_pose_timer = maxf(aim_pose_timer, hold_time)
	_ensure_limb_index(part_index)
	limb_drive_directions[part_index] = aim_pose_direction
	limb_drive_timers[part_index] = maxf(float(limb_drive_timers[part_index]), hold_time * 0.55)
	limb_drive_durations[part_index] = maxf(float(limb_drive_durations[part_index]), hold_time)
	limb_drive_amplitudes[part_index] = lerpf(float(limb_drive_amplitudes[part_index]), 0.0, 0.58)
	limb_drive_states[part_index] = STATE_NORMAL
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()
	if not _is_teamedit_runtime_unit():
		mobius_visual_scale = previous_visual_scale
		mobius_visual_scale_target = previous_target_scale
		visual_hitbox_scale = previous_hitbox_scale
		scale = previous_scale


func _runtime_binding_for_attack_index(part_index: int) -> Dictionary:
	var desired_key := clampi(part_index + 1, 1, 6)
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if raw_binding is Dictionary and int(Dictionary(raw_binding).get("attack_key", -1)) == desired_key:
			return Dictionary(raw_binding)
	return {}


func muzzle_position_for_part(part_index: int) -> Vector2:
	if _has_runtime_topology():
		var binding := _runtime_binding_for_attack_index(part_index)
		var target_nodes: Array = _runtime_node_array(Array(binding.get("target_nodes", [])))
		var best_segment: Dictionary = {}
		for raw_segment in _runtime_topology_world_segments(false, true):
			if not (raw_segment is Dictionary):
				continue
			var segment: Dictionary = raw_segment
			var node_index := int(segment.get("node_index", -2))
			if _runtime_node_array_has(target_nodes, node_index):
				best_segment = segment
			elif best_segment.is_empty() and bool(segment.get("projectile", false)):
				best_segment = segment
		if not best_segment.is_empty():
			return best_segment.get("b", Vector2(ring_pos, lane))
		return Vector2(ring_pos, lane)
	return Vector2(ring_pos, lane)


func _reset_limb_dynamics() -> void:
	limb_swing_angles.clear()
	limb_swing_velocities.clear()
	limb_linear_offsets.clear()
	limb_linear_velocities.clear()
	limb_drive_timers.clear()
	limb_drive_durations.clear()
	limb_drive_amplitudes.clear()
	limb_drive_directions.clear()
	limb_drive_states.clear()
	var runtime_key_count := 0
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if raw_binding is Dictionary:
			runtime_key_count = maxi(runtime_key_count, int(Dictionary(raw_binding).get("attack_key", 0)))
	var count := maxi(LIMB_INERTIA_PARTS, runtime_key_count)
	for i in range(count):
		limb_swing_angles.append(0.0)
		limb_swing_velocities.append(0.0)
		limb_linear_offsets.append(Vector2.ZERO)
		limb_linear_velocities.append(Vector2.ZERO)
		limb_drive_timers.append(0.0)
		limb_drive_durations.append(0.001)
		limb_drive_amplitudes.append(0.0)
		limb_drive_directions.append(Vector2.ZERO)
		limb_drive_states.append(STATE_NORMAL)


func _ensure_limb_index(part_index: int) -> void:
	if limb_swing_angles.is_empty():
		_reset_limb_dynamics()
	var target_size := maxi(part_index + 1, LIMB_INERTIA_PARTS)
	while limb_swing_angles.size() < target_size:
		limb_swing_angles.append(0.0)
		limb_swing_velocities.append(0.0)
		limb_linear_offsets.append(Vector2.ZERO)
		limb_linear_velocities.append(Vector2.ZERO)
		limb_drive_timers.append(0.0)
		limb_drive_durations.append(0.001)
		limb_drive_amplitudes.append(0.0)
		limb_drive_directions.append(Vector2.ZERO)
		limb_drive_states.append(STATE_NORMAL)


func _reset_part_damage_state() -> void:
	set_meta("part_hp", {})
	set_meta("broken_part_segments", {})
	set_meta("limb_hp", {})
	set_meta("severed_limbs", {})
	set_meta("torso_unit_hp", {})
	set_meta("broken_torso_units", {})
	set_meta("disabled_parts", {})
	set_meta("part_fail_flash", 0.0)


func _reset_electronic_armor(full_restore: bool) -> void:
	var armor_max := maxf(0.0, float(stats.get("electronic_armor_max", 0.0)))
	set_meta("electronic_armor_max", armor_max)
	set_meta("shield_max", armor_max)
	if full_restore:
		set_meta("electronic_armor_hp", armor_max)
	else:
		set_meta("electronic_armor_hp", clampf(float(get_meta("electronic_armor_hp", armor_max)), 0.0, armor_max))
	set_meta("shield_hp", float(get_meta("electronic_armor_hp", armor_max)))
	set_meta("electronic_armor_flash", 0.0)


func _tick_electronic_armor(delta: float) -> void:
	var armor_max := maxf(0.0, float(get_meta("electronic_armor_max", stats.get("electronic_armor_max", 0.0))))
	if armor_max <= 0.0:
		set_meta("electronic_armor_flash", 0.0)
		return
	var armor_hp := clampf(float(get_meta("electronic_armor_hp", armor_max)), 0.0, armor_max)
	var regen := maxf(0.0, float(stats.get("electronic_armor_regen", 0.0)))
	if regen > 0.0 and active:
		armor_hp = minf(armor_max, armor_hp + regen * delta)
	set_meta("electronic_armor_hp", armor_hp)
	set_meta("shield_max", armor_max)
	set_meta("shield_hp", armor_hp)
	set_meta("electronic_armor_flash", maxf(0.0, float(get_meta("electronic_armor_flash", 0.0)) - delta))


func _armor_absorb_result(damage: int, armor_hp: float, damage_type: String) -> Dictionary:
	if damage <= 0 or armor_hp <= 0.0:
		return {"damage": damage, "armor_hp": armor_hp}
	var armor_multiplier := 2.0 if damage_type == "pierce" else 1.0
	var armor_pressure := float(damage) * armor_multiplier
	var armor_removed := minf(armor_hp, armor_pressure)
	var remaining_damage := maxf(0.0, float(damage) - armor_removed / armor_multiplier)
	return {
		"damage": int(ceilf(remaining_damage)),
		"armor_hp": maxf(0.0, armor_hp - armor_removed),
	}


func _apply_electronic_armor_absorb(damage: int, damage_type: String) -> int:
	var armor_max := maxf(0.0, float(get_meta("electronic_armor_max", stats.get("electronic_armor_max", 0.0))))
	if damage <= 0 or armor_max <= 0.0:
		return damage
	var armor_hp := clampf(float(get_meta("electronic_armor_hp", armor_max)), 0.0, armor_max)
	if armor_hp <= 0.0:
		return damage
	var result := _armor_absorb_result(damage, armor_hp, damage_type)
	set_meta("electronic_armor_hp", float(result.get("armor_hp", 0.0)))
	set_meta("shield_hp", float(result.get("armor_hp", 0.0)))
	set_meta("shield_max", armor_max)
	set_meta("electronic_armor_flash", 0.22)
	return int(result.get("damage", damage))


func _start_limb_inertia(part_index: int, direction: Vector2, action_state: String, duration: float) -> void:
	_ensure_limb_index(part_index)
	var drive_dir := direction.normalized() if direction.length() > 0.01 else _forward_vector()
	var side := signf(drive_dir.y)
	if side == 0.0:
		side = 1.0 if part_index % 2 == 0 else -1.0
	var state_scale := 1.0
	if action_state == STATE_ACTIVE:
		state_scale = 1.26
	elif action_state == STATE_ARMOR:
		state_scale = 1.08
	var duration_scale := clampf(duration / 0.68, 0.8, 1.45)
	var amplitude_scale := 0.88
	var requested_arc := 180.0
	var amplitude := side * deg_to_rad(requested_arc) * amplitude_scale * state_scale
	limb_drive_directions[part_index] = drive_dir
	limb_drive_amplitudes[part_index] = amplitude
	limb_drive_durations[part_index] = maxf(0.12, duration * 1.28)
	limb_drive_timers[part_index] = float(limb_drive_durations[part_index])
	limb_drive_states[part_index] = action_state
	var joint_motion_speed := 1.0
	var startup_kick := 1.15 + joint_motion_speed * 0.82
	limb_swing_velocities[part_index] = float(limb_swing_velocities[part_index]) + side * startup_kick * state_scale / duration_scale
	_start_body_swing_from_action(part_index, drive_dir, side, state_scale)


func _start_body_swing_from_action(part_index: int, drive_dir: Vector2, side: float, state_scale: float) -> void:
	return


func _tick_body_inertia(delta: float) -> void:
	var stabilization := _attitude_stabilization()
	var spring_mult := clampf(0.78 + stabilization * 0.24, 0.72, 1.42)
	var damping_mult := clampf(0.68 + stabilization * 0.36, 0.62, 1.62)
	var body_accel := -body_swing_angle * BODY_SWING_SPRING * spring_mult - body_swing_velocity * BODY_SWING_DAMPING * damping_mult
	body_swing_velocity += body_accel * delta
	body_swing_angle += body_swing_velocity * delta
	body_swing_angle = clampf(body_swing_angle, -0.36, 0.36)
	if absf(body_swing_angle) < 0.0008 and absf(body_swing_velocity) < 0.008:
		body_swing_angle = 0.0
		body_swing_velocity = 0.0
	var sway_accel := -body_sway_offset * BODY_SWAY_SPRING * spring_mult - body_sway_velocity * BODY_SWAY_DAMPING * damping_mult
	body_sway_velocity += sway_accel * delta
	body_sway_offset += body_sway_velocity * delta
	if body_sway_offset.length() < 0.04 and body_sway_velocity.length() < 0.08:
		body_sway_offset = Vector2.ZERO
		body_sway_velocity = Vector2.ZERO


func _tick_limb_dynamics(delta: float) -> void:
	_ensure_limb_index(0)
	for i in range(limb_swing_angles.size()):
		var angle := float(limb_swing_angles[i])
		var velocity_value := float(limb_swing_velocities[i])
		var linear_offset: Vector2 = limb_linear_offsets[i]
		var linear_velocity: Vector2 = limb_linear_velocities[i]
		var timer := float(limb_drive_timers[i])
		var drive_force := 0.0
		if timer > 0.0:
			timer = maxf(0.0, timer - delta)
			limb_drive_timers[i] = timer
			var duration := maxf(0.001, float(limb_drive_durations[i]))
			var phase := clampf(1.0 - timer / duration, 0.0, 1.0)
			var pulse := sin(phase * PI)
			var rebound := sin(phase * TAU)
			var target_angle := float(limb_drive_amplitudes[i]) * (0.9 * pulse + 0.3 * rebound)
			var group := {}
			var joint_motion_speed := 1.0
			drive_force = (target_angle - angle) * (34.0 + joint_motion_speed * 24.0)
			if _group_is_chain_like(group):
				var drive_dir: Vector2 = limb_drive_directions[i]
				if drive_dir.length() > 0.01:
					var whip_pull := pulse * absf(velocity_value) * 0.0024
					if not bool(group.get("topology_anchor_valid", false)):
						body_sway_velocity += drive_dir.normalized() * whip_pull * PART_VISUAL_SCALE
						body_swing_velocity -= signf(velocity_value) * whip_pull * 2.2
		var group_for_drag := {}
		var end_mass := _group_limb_end_mass(group_for_drag)
		var acceleration := drive_force - angle * LIMB_SWING_SPRING - velocity_value * (LIMB_SWING_DAMPING + sqrt(end_mass) * 0.12)
		velocity_value += acceleration * delta
		angle += velocity_value * delta
		angle = clampf(angle, -PI, PI)
		var linear_accel := -linear_offset * LIMB_LINEAR_SPRING - linear_velocity * LIMB_LINEAR_DAMPING
		linear_velocity += linear_accel * delta
		linear_offset += linear_velocity * delta
		linear_offset = linear_offset.limit_length(0.72)
		if timer <= 0.0 and absf(angle) < 0.002 and absf(velocity_value) < 0.018:
			angle = 0.0
			velocity_value = 0.0
		if timer <= 0.0 and linear_offset.length() < 0.001 and linear_velocity.length() < 0.01:
			linear_offset = Vector2.ZERO
			linear_velocity = Vector2.ZERO
		limb_swing_angles[i] = angle
		limb_swing_velocities[i] = velocity_value
		limb_linear_offsets[i] = linear_offset
		limb_linear_velocities[i] = linear_velocity


func _group_is_chain_like(group: Dictionary) -> bool:
	var motion := String(group.get("motion", ""))
	var material_class := String(group.get("material_class", ""))
	var muscle_name := String(group.get("muscle_name", "")).to_upper()
	var limb_name := String(group.get("limb_muscle_name", "")).to_upper()
	return motion.contains("chain") or motion in ["pendulum", "swing_aim", "auto_swing"] or material_class in ["chain", "whip_muscle", "whip_joint"] or muscle_name.contains("CHAIN") or muscle_name.contains("TENTACLE") or limb_name.contains("CHAIN") or limb_name.contains("WHIP") or limb_name.contains("TENTACLE")


func _group_limb_end_mass(group: Dictionary) -> float:
	var terminal_mass := maxf(0.0, float(group.get("terminal_weapon_mass", group.get("mass", 0.0))))
	var muscle_mass := maxf(0.0, float(group.get("muscle_mass", 0.0)))
	var fallback_mass := maxf(0.6, float(stats.get("mass", 8.0)) * 0.12)
	return maxf(0.45, terminal_mass + muscle_mass * 0.72 + fallback_mass * 0.18)


func _group_joint_motion_speed(group: Dictionary, state_scale: float = 1.0) -> float:
	var output_momentum := maxf(0.0, float(group.get("fixed_output_momentum", 0.0)))
	if output_momentum <= 0.0:
		output_momentum = maxf(0.0, float(group.get("joint_output_momentum", group.get("joint_output_momentum_base", 0.0))))
	var end_mass := _group_limb_end_mass(group)
	var motion := String(group.get("motion", "straight"))
	var motion_mult := 1.0
	if motion.contains("chain"):
		motion_mult = 1.18
	elif motion in ["pendulum", "swing_aim", "auto_swing", "pincer_clamp"]:
		motion_mult = 1.08
	elif motion.contains("thrust") or motion.contains("突击"):
		motion_mult = 1.12
	var speed_bonus := 1.0 + clampf(float(group.get("swing_speed_bonus", 0.0)), -0.45, 0.75)
	return clampf(output_momentum * motion_mult * speed_bonus * state_scale / maxf(0.45, end_mass), 0.04, 5.4)


func _limb_drive_phase(part_index: int) -> float:
	_ensure_limb_index(part_index)
	var duration := maxf(0.001, float(limb_drive_durations[part_index]))
	return clampf(1.0 - float(limb_drive_timers[part_index]) / duration, 0.0, 1.0) if float(limb_drive_timers[part_index]) > 0.0 else 1.0


func _limb_drive_power(part_index: int) -> float:
	_ensure_limb_index(part_index)
	if float(limb_drive_timers[part_index]) <= 0.0:
		return 0.0
	return sin(_limb_drive_phase(part_index) * PI)


func _aim_pose_active(part_index: int) -> bool:
	return part_index == aim_pose_part_index and aim_pose_timer > 0.0 and aim_pose_direction.length() > 0.01


func _limb_aim_direction(part_index: int, rest_direction: Vector2) -> Vector2:
	_ensure_limb_index(part_index)
	if _aim_pose_active(part_index):
		return aim_pose_direction.normalized()
	var drive_dir: Vector2 = limb_drive_directions[part_index]
	if float(limb_drive_timers[part_index]) <= 0.0 or drive_dir.length() <= 0.01:
		return rest_direction.normalized()
	var weight := clampf(0.18 + _limb_drive_power(part_index) * 0.82, 0.0, 1.0)
	var blended := rest_direction.normalized().lerp(drive_dir.normalized(), weight)
	return blended.normalized() if blended.length() > 0.01 else rest_direction.normalized()


func _limb_swing_angle(part_index: int) -> float:
	_ensure_limb_index(part_index)
	return float(limb_swing_angles[part_index])


func _limb_swing_velocity(part_index: int) -> float:
	_ensure_limb_index(part_index)
	return float(limb_swing_velocities[part_index])


func _limb_linear_offset(part_index: int, t: float = 1.0) -> Vector2:
	_ensure_limb_index(part_index)
	return Vector2(limb_linear_offsets[part_index]) * clampf(t, 0.0, 1.2)


func _limb_drive_state(part_index: int) -> String:
	_ensure_limb_index(part_index)
	return String(limb_drive_states[part_index]) if float(limb_drive_timers[part_index]) > 0.0 else STATE_NORMAL


func _event_melee_drive_power(event: Dictionary, part_index: int) -> float:
	if bool(event.get("projectile", false)):
		return 0.0
	var live_power := _limb_drive_power(part_index)
	if live_power > 0.04:
		return live_power
	var state := String(event.get("state", STATE_NORMAL))
	if state == STATE_ACTIVE:
		return 0.86
	if state == STATE_ARMOR:
		return 0.76
	return 0.68


func _has_barrier_tiles() -> bool:
	return role == "barrier" and Array(stats.get("barrier_map_tiles", [])).size() > 0


func _barrier_tile_axis(tile: Dictionary) -> Vector2:
	match String(tile.get("orientation", "horizontal")):
		"vertical":
			return Vector2(0.0, 1.0)
		"diagonal_pos":
			return Vector2(1.0, 0.74).normalized()
		"diagonal_neg":
			return Vector2(1.0, -0.74).normalized()
	return Vector2(1.0, 0.0)


func _barrier_tile_center(tile: Dictionary) -> Vector2:
	var origin := _runtime_combat_origin()
	return Vector2(origin.x + float(tile.get("local_ring", 0.0)), clampf(origin.y + float(tile.get("local_lane", 0.0)), -BATTLE_HALF_HEIGHT, BATTLE_HALF_HEIGHT))


func _barrier_tile_collider(tile: Dictionary) -> Dictionary:
	var center := _barrier_tile_center(tile)
	var radius := maxf(0.035, float(tile.get("radius", 0.08)))
	var length := maxf(0.06, float(tile.get("length", 0.28)))
	var shape := String(tile.get("shape", "barrier_tile"))
	if shape.contains("question") or shape.contains("cache") or shape.contains("field") or shape.contains("hatchery"):
		return {
			"shape": "circle",
			"part_kind": "barrier_tile",
			"part_index": int(tile.get("index", -1)),
			"name": String(tile.get("name", "BARRIER TILE")),
			"center": center,
			"radius": maxf(radius, length * 0.28),
			"mass": float(tile.get("mass", 1.0)),
			"material_class": String(tile.get("material_class", "barrier_wall")),
			"damage_type": String(tile.get("damage_type", "blunt")),
			"contact_damage": float(tile.get("contact_damage", tile.get("cage_damage", 2.0))),
			"momentum_threshold": float(tile.get("momentum_threshold", 0.0)),
			"damage_coeff": 1.0,
			"break_coeff": 0.5,
			"stiffness_momentum": PART_STIFFNESS_BASE_MOMENTUM,
			"path_stiffness_momentum": PART_STIFFNESS_BASE_MOMENTUM,
		}
	var axis := _barrier_tile_axis(tile)
	return {
		"shape": "capsule",
		"part_kind": "barrier_tile",
		"part_index": int(tile.get("index", -1)),
		"name": String(tile.get("name", "BARRIER TILE")),
		"a": center - axis * length * 0.5,
		"b": center + axis * length * 0.5,
		"radius": radius,
		"mass": float(tile.get("mass", 1.0)),
		"material_class": String(tile.get("material_class", "barrier_wall")),
		"damage_type": String(tile.get("damage_type", "blunt")),
		"contact_damage": float(tile.get("contact_damage", tile.get("cage_damage", 2.0))),
		"momentum_threshold": float(tile.get("momentum_threshold", 0.0)),
		"damage_coeff": 1.0,
		"break_coeff": 0.5,
		"stiffness_momentum": PART_STIFFNESS_BASE_MOMENTUM,
		"path_stiffness_momentum": PART_STIFFNESS_BASE_MOMENTUM,
	}


func _barrier_tile_colliders() -> Array:
	var colliders: Array = []
	for raw_tile in Array(stats.get("barrier_map_tiles", [])):
		if raw_tile is Dictionary:
			var tile: Dictionary = raw_tile
			colliders.append(_barrier_tile_collider(tile))
	return colliders


func _stiffness_size_multiplier_for_label(size_label: String) -> float:
	match String(size_label).to_upper():
		"XS":
			return 0.25
		"S":
			return 0.5
		"M":
			return 1.0
		"L":
			return 2.0
		"XL":
			return 4.0
	return 1.0


func _segment_size_multiplier(segment: Dictionary) -> float:
	if segment.has("size_tier"):
		return _stiffness_size_multiplier_for_label(String(segment.get("size_tier", "M")))
	var rank := int(segment.get("size_rank", 3))
	if rank <= 0:
		return 0.25
	if rank <= 1:
		return 0.5
	if rank <= 3:
		return 1.0
	if rank <= 5:
		return 2.0
	return 4.0


func _default_stiffness_for_segment(segment: Dictionary, part_kind: String) -> float:
	if segment.has("stiffness_momentum"):
		return maxf(1.0, float(segment.get("stiffness_momentum", 0.0)))
	var mult := _segment_size_multiplier(segment)
	match part_kind:
		"torso":
			return PART_STIFFNESS_BASE_MOMENTUM * 2.0 * mult
		"terminal":
			return PART_STIFFNESS_BASE_MOMENTUM * (0.8 if String(segment.get("terminal_weapon_kind", "")).to_lower() == "ranged" else 2.0) * mult
		"barrier_tile":
			return PART_STIFFNESS_BASE_MOMENTUM * mult
		_:
			return PART_STIFFNESS_BASE_MOMENTUM * mult


func _default_path_stiffness_for_segment(segment: Dictionary, part_kind: String) -> float:
	if segment.has("path_stiffness_momentum"):
		return maxf(1.0, float(segment.get("path_stiffness_momentum", 0.0)))
	var mult := _segment_size_multiplier(segment)
	var part_stiffness := _default_stiffness_for_segment(segment, part_kind)
	var torso_stiffness := PART_STIFFNESS_BASE_MOMENTUM * 2.0 * mult
	var limb_stiffness := PART_STIFFNESS_BASE_MOMENTUM * mult
	match part_kind:
		"torso":
			return part_stiffness
		"terminal":
			return maxf(1.0, minf(part_stiffness, minf(limb_stiffness, torso_stiffness)))
		"barrier_tile":
			return part_stiffness
		_:
			return maxf(1.0, minf(part_stiffness, torso_stiffness))


func part_colliders() -> Array:
	var colliders: Array = []
	if not active:
		return colliders
	if _is_training_ball_dummy():
		return [_training_ball_dummy_collider()]
	if _has_barrier_tiles():
		return _barrier_tile_colliders()
	if _is_teamedit_runtime_unit():
		return _runtime_cached_part_colliders()
	return colliders


func _runtime_cached_part_colliders() -> Array:
	if not _has_runtime_topology():
		return []
	var cache_key := _runtime_geometry_signature(true, true, "colliders")
	if runtime_geometry_cache_colliders_key == cache_key:
		runtime_geometry_cache_hits += 1
		return runtime_geometry_cache_colliders
	var colliders: Array = []
	var active_nodes := _runtime_active_collider_node_set()
	for raw_segment in _runtime_topology_world_segments(true, true):
		if not (raw_segment is Dictionary):
			continue
		var segment_dict: Dictionary = Dictionary(raw_segment).duplicate(true)
		var part_kind := String(segment_dict.get("part_kind", "limb_muscle"))
		var node_index := int(segment_dict.get("node_index", segment_dict.get("part_index", -999999)))
		var independent_damage := part_kind == "torso" or active_nodes.has(node_index)
		var part_name := String(segment_dict.get("name", part_kind.to_upper()))
		segment_dict["runtime_topology"] = true
		segment_dict["independent_damage"] = independent_damage
		if not independent_damage:
			segment_dict["damage_proxy"] = "torso"
			segment_dict["damage_proxy_torso_unit_index"] = int(segment_dict.get("torso_unit_index", 0))
		var runtime_polygon := _runtime_segment_polygon_world(segment_dict)
		if runtime_polygon.size() >= 3:
			segment_dict["shape"] = "polygon"
			segment_dict["polygon"] = runtime_polygon
			segment_dict["radius"] = 0.0
		else:
			segment_dict["radius"] = maxf(0.006, float(segment_dict.get("radius", 0.04)) * BODY_COLLIDER_EXPAND)
		segment_dict["part_index"] = -1 if part_kind == "torso" else _runtime_attack_index_for_segment(segment_dict)
		segment_dict["name"] = part_name
		var contact_group := _runtime_contact_group_for_segment(segment_dict)
		var contact_fields := _contact_fields_for_segment(contact_group, part_kind)
		if part_kind == "torso":
			contact_fields = {
				"damage_type": "blunt",
				"material_class": String(segment_dict.get("material_class", "body")),
				"contact_damage": 0.4,
				"contact_damage_mult": 0.08,
				"damage_coeff": 1.0,
				"break_coeff": 0.5,
				"contact_shape_kind": "rounded_torso",
			}
			segment_dict["torso_unit_index"] = int(segment_dict.get("node_index", 0))
		for key in contact_fields.keys():
			segment_dict[key] = contact_fields[key]
		if not segment_dict.has("contact_shape_kind"):
			segment_dict["contact_shape_kind"] = "rounded_terminal" if part_kind == "terminal" else ("rounded_panel" if part_kind == "barrier_tile" else "rounded_limb")
		if not segment_dict.has("stiffness_momentum"):
			segment_dict["stiffness_momentum"] = _default_stiffness_for_segment(segment_dict, part_kind)
		if not segment_dict.has("path_stiffness_momentum"):
			segment_dict["path_stiffness_momentum"] = _default_path_stiffness_for_segment(segment_dict, part_kind)
		colliders.append(_runtime_collider_with_bounds(segment_dict))
	runtime_geometry_cache_colliders_key = cache_key
	runtime_geometry_cache_colliders = colliders
	runtime_geometry_collider_builds += 1
	return runtime_geometry_cache_colliders


func _runtime_active_collider_node_set() -> Dictionary:
	var active_nodes := {}
	for raw_action in runtime_module_actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		for raw_node in Array(action.get("target_nodes", [])):
			active_nodes[int(raw_node)] = true
	return active_nodes


func _contact_fields_for_segment(group: Dictionary, part_kind: String) -> Dictionary:
	var material_class := String(group.get("melee_contact_class", group.get("material_class", "body")))
	if bool(group.get("projectile_only", false)) or material_class == "gun":
		material_class = "wood"
	var damage_type := String(group.get("damage_type", "blunt"))
	var base_damage := float(group.get("normal_damage_override", group.get("normal_damage", stats.get("normal_damage", 2))))
	match part_kind:
		"terminal":
			var ranged := _runtime_segment_is_ranged_weapon(group)
			return {
				"damage_type": damage_type,
				"material_class": material_class,
				"contact_damage": base_damage,
				"contact_damage_mult": 1.0,
				"damage_coeff": 0.8 if ranged else 3.2,
				"break_coeff": 0.5 if ranged else 1.0,
			}
		"limb_muscle":
			var chain_like := _group_is_chain_like(group) or material_class in ["chain", "whip_muscle", "whip_joint"]
			return {
				"damage_type": damage_type if chain_like else "blunt",
				"material_class": material_class if chain_like else "body",
				"contact_damage": base_damage * (0.54 if chain_like else 0.18),
				"contact_damage_mult": 0.62 if chain_like else 0.18,
				"damage_coeff": 1.8,
				"break_coeff": 0.5,
			}
		"joint":
			var joint_weapon := material_class == "whip_joint"
			return {
				"damage_type": damage_type if joint_weapon else "blunt",
				"material_class": material_class if joint_weapon else "body",
				"contact_damage": base_damage * (0.48 if joint_weapon else 0.12),
				"contact_damage_mult": 0.52 if joint_weapon else 0.14,
				"damage_coeff": 1.0,
				"break_coeff": 0.5,
			}
	return {
		"damage_type": "blunt",
		"material_class": "body",
		"contact_damage": 1.0,
		"contact_damage_mult": 0.12,
		"damage_coeff": 1.0,
		"break_coeff": 0.5,
	}


func contact_state_for_part(part_index: int) -> String:
	if part_index < 0:
		return STATE_NORMAL
	return _limb_drive_state(part_index)


func contact_velocity_for_collider(collider: Dictionary) -> Vector2:
	var center := _collider_center_local(collider)
	var total_velocity := velocity
	var body_origin := Vector2(ring_pos, lane)
	var body_rel := center - body_origin
	var body_w := angular_velocity + body_swing_velocity
	total_velocity += Vector2(-body_rel.y, body_rel.x) * body_w
	if bool(collider.get("runtime_topology", false)):
		total_velocity += _runtime_action_contact_velocity_for_collider(collider)

	var part_index := int(collider.get("part_index", -1))
	if part_index >= 0:
		_ensure_limb_index(part_index)
		if bool(collider.get("runtime_topology", false)):
			var pivot_world = collider.get("pivot", center)
			if not (pivot_world is Vector2):
				pivot_world = center
			var limb_rel := center - Vector2(pivot_world)
			var kind := String(collider.get("part_kind", ""))
			var kind_mult := 0.42
			match kind:
				"melee_sweep":
					kind_mult = 1.0
				"terminal":
					kind_mult = 1.0
				"limb_muscle":
					kind_mult = 0.72
				"joint":
					kind_mult = 0.46
			total_velocity += Vector2(limb_linear_velocities[part_index]) * (0.72 + kind_mult * 0.34)
			total_velocity += Vector2(-limb_rel.y, limb_rel.x) * float(limb_swing_velocities[part_index]) * kind_mult
			return total_velocity
	return total_velocity


func _runtime_action_contact_velocity_for_collider(collider: Dictionary) -> Vector2:
	if not bool(collider.get("runtime_topology", false)):
		return Vector2.ZERO
	var node_index := int(collider.get("node_index", -999999))
	if node_index < 0:
		return Vector2.ZERO
	for raw_action in runtime_module_actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		if not _runtime_node_array_has(Array(action.get("target_nodes", [])), node_index):
			continue
		var speed := maxf(0.0, float(action.get("runtime_contact_speed", action.get("joint_actuation_speed", 0.0))))
		if speed <= 0.001:
			var duration := maxf(0.001, float(action.get("duration", 0.62)))
			speed = _collider_center_local(collider).distance_to(Vector2(collider.get("pivot", Vector2(ring_pos, lane)))) * PI / duration
		var phase := _runtime_action_phase(action)
		var startup_ratio := _runtime_action_startup_ratio(action)
		var sign := 1.0 if phase <= startup_ratio else 0.62
		return _forward_vector().normalized() * speed * sign
	return Vector2.ZERO


func _collider_center_local(collider: Dictionary) -> Vector2:
	if String(collider.get("shape", "circle")) == "capsule":
		var a: Vector2 = collider.get("a", Vector2.ZERO)
		var b: Vector2 = collider.get("b", a)
		return (a + b) * 0.5
	if String(collider.get("shape", "circle")) == "polygon":
		var points: Array = Array(collider.get("polygon", []))
		if not points.is_empty():
			var sum := Vector2.ZERO
			var count := 0
			for raw_point in points:
				if raw_point is Vector2:
					sum += Vector2(raw_point)
					count += 1
			if count > 0:
				return sum / float(count)
	return collider.get("center", Vector2(ring_pos, lane))


func _runtime_segment_is_ranged_weapon(segment: Dictionary) -> bool:
	return String(segment.get("terminal_weapon_kind", "")).to_lower() == "ranged" or bool(segment.get("projectile", false))


func attack_collider_for_event(event: Dictionary) -> Dictionary:
	if not active:
		return {}
	if _is_teamedit_runtime_unit():
		if not bool(event.get("projectile", false)):
			return {}
		var target_nodes: Array = _runtime_node_array(Array(event.get("runtime_target_nodes", [])))
		var source_node := int(event.get("source_gun_node", event.get("source_node_index", event.get("muscle_node", -9999))))
		if target_nodes.is_empty() and source_node >= 0:
			target_nodes.append(source_node)
		var matched: Array = []
		for raw_segment in _runtime_topology_world_segments(false, true):
			if not (raw_segment is Dictionary):
				continue
			var segment: Dictionary = raw_segment
			if not target_nodes.is_empty() and _runtime_node_array_has(target_nodes, int(segment.get("node_index", -9999))):
				matched.append(segment)
		if matched.is_empty():
			if event.has("muzzle_combat_position") and event["muzzle_combat_position"] is Vector2:
				var muzzle_start: Vector2 = event["muzzle_combat_position"]
				var muzzle_direction := _forward_vector()
				if event.has("direction") and event["direction"] is Vector2:
					muzzle_direction = Vector2(event["direction"])
				if muzzle_direction.length() <= 0.01:
					muzzle_direction = _forward_vector()
				muzzle_direction = muzzle_direction.normalized()
				return {
					"shape": "capsule",
					"part_kind": "runtime_attack",
					"a": muzzle_start,
					"b": muzzle_start + muzzle_direction * maxf(0.12, float(event.get("range", 1.0))),
					"radius": maxf(0.012, float(event.get("lane_range", 0.12)) * 0.22),
					"part_index": source_node,
					"node_index": source_node,
					"source_gun_node": source_node,
					"runtime_topology": true,
					"runtime_attack": true,
				}
			set_meta("last_projectile_source_error", "runtime projectile missing target/source gun node")
			return {}
		var first_segment: Dictionary = matched[0]
		var last_segment: Dictionary = matched[matched.size() - 1]
		var start: Vector2 = first_segment.get("a", Vector2(ring_pos, lane))
		var end: Vector2 = last_segment.get("b", start)
		var radius := maxf(0.012, float(last_segment.get("radius", first_segment.get("radius", 0.04))) * ATTACK_COLLIDER_EXPAND)
		if bool(event.get("projectile", false)):
			if not _runtime_segment_is_ranged_weapon(last_segment):
				set_meta("last_projectile_source_error", "runtime projectile source node is not ranged")
				return {}
			var direction := _forward_vector()
			if event.has("direction") and event["direction"] is Vector2:
				direction = Vector2(event["direction"])
			if direction.length() <= 0.01:
				direction = _forward_vector()
			direction = direction.normalized()
			start = end
			if event.has("muzzle_combat_position") and event["muzzle_combat_position"] is Vector2:
				start = event["muzzle_combat_position"]
			end = start + direction * maxf(0.12, float(event.get("range", 1.0)))
			radius = maxf(radius * 0.42, float(event.get("lane_range", 0.12)) * 0.22)
			return {
				"shape": "capsule",
				"part_kind": "runtime_attack",
				"a": start,
				"b": end,
				"radius": radius,
				"part_index": int(event.get("muscle_node", -1)),
				"node_index": int(last_segment.get("node_index", source_node)),
				"source_gun_node": int(event.get("source_gun_node", source_node)),
				"muzzle_combat_position": start,
				"runtime_topology": true,
				"runtime_attack": true,
		}
		var strike_segment: Dictionary = last_segment
		var strike_polygon := _runtime_segment_polygon_world(strike_segment)
		if strike_polygon.size() >= 3:
			return {
				"shape": "polygon",
				"part_kind": String(strike_segment.get("part_kind", "runtime_attack")),
				"polygon": strike_polygon,
				"radius": 0.0,
				"part_index": int(event.get("muscle_node", strike_segment.get("node_index", -1))),
				"node_index": int(strike_segment.get("node_index", -1)),
				"terminal_weapon_kind": String(strike_segment.get("terminal_weapon_kind", "")),
				"damage_type": String(strike_segment.get("damage_type", event.get("damage_type", "blunt"))),
				"material_class": String(strike_segment.get("material_class", event.get("material_class", "weapon"))),
				"contact_damage": float(strike_segment.get("contact_damage", event.get("damage", 1.0))),
				"damage_coeff": float(strike_segment.get("damage_coeff", 2.5 if String(strike_segment.get("part_kind", "")) == "terminal" and String(strike_segment.get("terminal_weapon_kind", "")) != "ranged" else 1.0)),
				"break_coeff": float(strike_segment.get("break_coeff", 1.0 if String(strike_segment.get("part_kind", "")) == "terminal" and String(strike_segment.get("terminal_weapon_kind", "")) != "ranged" else 0.5)),
				"stiffness_momentum": float(strike_segment.get("stiffness_momentum", _default_stiffness_for_segment(strike_segment, String(strike_segment.get("part_kind", "terminal"))))),
				"path_stiffness_momentum": float(strike_segment.get("path_stiffness_momentum", _default_path_stiffness_for_segment(strike_segment, String(strike_segment.get("part_kind", "terminal"))))),
				"pivot": strike_segment.get("pivot", start),
				"a": strike_segment.get("a", start),
				"b": strike_segment.get("b", end),
				"runtime_topology": true,
				"runtime_attack": true,
			}
		return {
			"shape": "capsule",
			"part_kind": "runtime_attack",
			"a": start,
			"b": end,
			"radius": radius,
			"part_index": int(event.get("muscle_node", -1)),
			"runtime_topology": true,
			"runtime_attack": true,
		}
	return {}


func _collision_group_for_index(groups: Array, part_index: int) -> Dictionary:
	if not groups.is_empty():
		var clamped_index := clampi(part_index, 0, groups.size() - 1)
		if groups[clamped_index] is Dictionary:
			return groups[clamped_index]
	return {}


func _part_segment_key(part_index: int, part_kind: String) -> String:
	return "%d:%s" % [part_index, part_kind]


func _part_segment_broken(part_index: int, part_kind: String) -> bool:
	if part_index < 0:
		return false
	if has_meta("broken_part_segments") and get_meta("broken_part_segments") is Dictionary:
		var broken: Dictionary = get_meta("broken_part_segments")
		if bool(broken.get(_part_segment_key(part_index, part_kind), false)):
			return true
	if has_meta("severed_limbs") and get_meta("severed_limbs") is Dictionary:
		var severed: Dictionary = get_meta("severed_limbs")
		return bool(severed.get(str(part_index), false))
	return false


func _group_joint_radius_for_pose(group: Dictionary, body_length: float, body_radius: float) -> float:
	return 0.0


func _group_muscle_radius_for_pose(group: Dictionary, body_radius: float) -> float:
	return clampf(float(group.get("muscle_radius", maxf(0.018, body_radius * 0.16))) * 0.48, 0.006, 0.58)


func _group_terminal_is_ranged(group: Dictionary) -> bool:
	var explicit_kind := String(group.get("terminal_weapon_kind", "")).to_lower()
	if explicit_kind == "ranged":
		return true
	if explicit_kind == "melee":
		return false
	var material_class := String(group.get("material_class", "")).to_lower()
	var shape := String(group.get("shape", "")).to_lower()
	var name := String(group.get("muscle_name", group.get("name", ""))).to_lower()
	return bool(group.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"] or shape.contains("gun") or shape.contains("rifle") or shape.contains("cannon") or shape.contains("launcher") or name.contains("rifle") or name.contains("rail") or name.contains("laser") or name.contains("missile")


func _group_terminal_length_for_pose(group: Dictionary, fallback_length: float = 0.0) -> float:
	var raw_length := float(group.get("terminal_length", fallback_length))
	if bool(group.get("terminal_geometry_scaled", false)):
		return maxf(0.0, raw_length)
	var multiplier := TERMINAL_RANGED_GEOMETRY_MULTIPLIER if _group_terminal_is_ranged(group) else TERMINAL_MELEE_GEOMETRY_MULTIPLIER
	return maxf(0.0, raw_length * multiplier)


func _group_terminal_radius_for_pose(group: Dictionary, body_radius: float) -> float:
	var raw_radius := float(group.get("terminal_radius", maxf(0.012, body_radius * 0.12)))
	var scaled_radius := raw_radius if bool(group.get("terminal_geometry_scaled", false)) else raw_radius * TERMINAL_RADIUS_GEOMETRY_MULTIPLIER
	return clampf(scaled_radius * 1.04, 0.0, 1.45)


func _chain_entry(kind: String, length: float, radius: float, source: Dictionary = {}) -> Dictionary:
	var entry := {
		"part_kind": kind,
		"length": maxf(0.0, length),
		"radius": maxf(0.0, radius),
	}
	if source.has("name"):
		entry["name"] = source["name"]
	if source.has("rest_direction_local"):
		entry["rest_direction_local"] = source["rest_direction_local"]
	if source.has("relative_angle_to_previous"):
		entry["relative_angle_to_previous"] = source["relative_angle_to_previous"]
	if source.has("local_angle"):
		entry["local_angle"] = source["local_angle"]
	if source.has("node_index"):
		entry["node_index"] = source["node_index"]
	return entry


func _limb_chain_spec_for_group(group: Dictionary, body_length: float, body_radius: float, extension_distance: float = 0.0) -> Array:
	var spec: Array = []
	var raw_chain = group.get("downstream_chain", [])
	if raw_chain is Array and not Array(raw_chain).is_empty():
		for raw_entry in Array(raw_chain):
			if not (raw_entry is Dictionary):
				continue
			var entry: Dictionary = raw_entry
			var kind := String(entry.get("part_kind", ""))
			if kind == "muscle":
				kind = "terminal"
			if kind == "joint":
				continue
			if not (kind in ["limb_muscle", "terminal"]):
				continue
			var fallback_radius := _group_terminal_radius_for_pose(group, body_radius) if kind == "terminal" else _group_muscle_radius_for_pose(group, body_radius)
			var fallback_length := _group_terminal_length_for_pose(group, 0.0) if kind == "terminal" else float(group.get("muscle_length", maxf(0.12, body_length * 0.3)))
			spec.append(_chain_entry(kind, maxf(0.0, float(entry.get("length", fallback_length))), maxf(0.0, float(entry.get("radius", fallback_radius))), entry))
	if spec.is_empty():
		spec.append(_chain_entry("limb_muscle", clampf(float(group.get("muscle_length", maxf(0.12, body_length * 0.3))), 0.035, 4.0), _group_muscle_radius_for_pose(group, body_radius)))
		var terminal_length := clampf(_group_terminal_length_for_pose(group, 0.0), 0.0, 2.4)
		if terminal_length > 0.0:
			spec.append(_chain_entry("terminal", terminal_length, _group_terminal_radius_for_pose(group, body_radius)))
	if extension_distance > 0.0:
		for i in range(spec.size()):
			var entry: Dictionary = spec[i]
			if String(entry.get("part_kind", "")) == "limb_muscle":
				entry["length"] = maxf(0.0, float(entry.get("length", 0.0)) + extension_distance)
				spec[i] = entry
				break
	return spec


func _chain_axis_for_link(part_index: int, group: Dictionary, base_direction: Vector2, link_index: int, link_count: int, lane_bias: float) -> Vector2:
	var axis := base_direction.normalized()
	if axis.length() <= 0.01:
		axis = _forward_vector()
	var t := float(link_index) / maxf(1.0, float(link_count - 1))
	var side := signf(lane_bias)
	if side == 0.0:
		side = 1.0 if part_index % 2 == 0 else -1.0
	var action_phase := _limb_drive_phase(part_index)
	var action_pulse := _limb_drive_power(part_index)
	var swing_angle := _limb_swing_angle(part_index)
	var swing_velocity := _limb_swing_velocity(part_index)
	var idle_breath := sin(Time.get_ticks_msec() * 0.0015 + float(part_index)) * 0.035
	var inertial_lag := swing_angle * (0.42 + t * 2.05)
	var velocity_lag := clampf(swing_velocity * 0.052, -1.72, 1.72) * sin(t * PI)
	var traveling_wave := sin(t * PI * 2.55 - action_phase * TAU * 1.75) * action_pulse * 1.16 * side
	var tip_rebound := -swing_angle * t * t * 0.72
	var wave := inertial_lag + velocity_lag + traveling_wave + tip_rebound + idle_breath * side
	return axis.rotated(wave).normalized()


func _segments_from_limb_chain(part_index: int, group: Dictionary, root_pivot: Vector2, base_axis: Vector2, chain_spec: Array, chain_motion: bool, lane_bias: float) -> Array:
	var axis := base_axis.normalized()
	if axis.length() <= 0.01:
		axis = _forward_vector()
	var topology_chain := bool(group.get("topology_anchor_valid", false)) and group.has("downstream_chain")
	var current_joint_center := root_pivot
	var connection_end := root_pivot
	var has_connection_end := false
	var muscle_total := 0
	for raw_entry in chain_spec:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("part_kind", "")) in ["limb_muscle", "terminal"]:
			muscle_total += 1
	var two_link_profile := String(group.get("module_action_profile", "")) == "two_link_forward_snap"
	var two_link_active := two_link_profile and _limb_drive_power(part_index) > 0.02
	var two_link_phase := clampf(_limb_drive_phase(part_index), 0.0, 1.0)
	var two_link_straight_phase := clampf(float(group.get("two_link_straight_phase", 0.46)), 0.12, 0.88)
	var two_link_forward := _forward_vector().normalized()
	if two_link_forward.length() <= 0.01:
		two_link_forward = axis
	var two_link_side_sign := signf(float(group.get("two_link_ortho_side_sign", signf(lane_bias))))
	if two_link_side_sign == 0.0:
		two_link_side_sign = 1.0
	var two_link_ortho := two_link_forward.rotated(two_link_side_sign * PI * 0.5).normalized()
	var muscle_index := 0
	var segments: Array = []
	for entry_index in range(chain_spec.size()):
		if not (chain_spec[entry_index] is Dictionary):
			continue
		var entry: Dictionary = chain_spec[entry_index]
		var kind := String(entry.get("part_kind", ""))
		if kind == "joint":
			if entry_index == 0:
				current_joint_center = root_pivot
			elif has_connection_end:
				current_joint_center = connection_end
			has_connection_end = false
			continue
		if not (kind in ["limb_muscle", "terminal"]):
			continue
		if topology_chain and entry.has("rest_direction_local"):
			if muscle_index == 0:
				axis = base_axis.normalized()
			elif entry.has("local_angle"):
				axis = axis.rotated(float(entry.get("local_angle", entry.get("relative_angle_to_previous", 0.0)))).normalized()
			elif entry.has("relative_angle_to_previous"):
				axis = axis.rotated(float(entry.get("relative_angle_to_previous", 0.0))).normalized()
		elif entry.has("rest_direction_local"):
			var entry_axis := _world_vector_from_topology_local(entry.get("rest_direction_local"))
			if entry_axis.length() > 0.01:
				axis = entry_axis
		if chain_motion and not topology_chain and (kind == "limb_muscle" or not has_connection_end):
			axis = _chain_axis_for_link(part_index, group, axis, muscle_index, maxi(1, muscle_total), lane_bias)
		if two_link_active and muscle_index < 2:
			if two_link_phase <= two_link_straight_phase:
				var snap_t := clampf(two_link_phase / maxf(0.001, two_link_straight_phase), 0.0, 1.0)
				snap_t = snap_t * snap_t * (3.0 - 2.0 * snap_t)
				axis = axis.lerp(two_link_forward, snap_t).normalized()
			else:
				var return_t := clampf((two_link_phase - two_link_straight_phase) / maxf(0.001, 1.0 - two_link_straight_phase), 0.0, 1.0)
				return_t = return_t * return_t * (3.0 - 2.0 * return_t)
				var target_axis := two_link_ortho if muscle_index == 0 else two_link_forward
				axis = two_link_forward.lerp(target_axis, return_t).normalized()
		var length := maxf(0.0, float(entry.get("length", 0.0)))
		var radius := maxf(0.006, float(entry.get("radius", 0.02)))
		var start := current_joint_center
		if kind == "terminal" and has_connection_end:
			start = connection_end
		var end := start + axis * length
		if not _part_segment_broken(part_index, kind):
			segments.append({
				"shape": "capsule",
				"part_kind": kind,
				"a": start,
				"b": end,
				"connection_start": start,
				"connection_end": end,
				"tip": end,
				"terminal_socket": start if kind == "terminal" else null,
				"terminal_tip": end if kind == "terminal" else null,
				"terminal_handle_visible": kind == "terminal",
				"terminal_handle_start": start if kind == "terminal" else null,
				"radius": radius,
				"pivot": root_pivot,
				"local_joint_center": current_joint_center,
				"rotation_radius_start": start.distance_to(root_pivot),
				"rotation_radius_end": end.distance_to(root_pivot),
				"chain_index": muscle_index,
				"node_index": int(entry.get("node_index", -1)),
			})
		connection_end = end
		has_connection_end = true
		muscle_index += 1
	return segments


func _pose_from_segments(segments: Array, joint_radius: float, muscle_radius: float, terminal_radius: float, terminal_length: float, fallback_axis: Vector2, root_pivot: Vector2) -> Dictionary:
	var axis := fallback_axis.normalized()
	if axis.length() <= 0.01:
		axis = _forward_vector()
	var joint_segment := {}
	var muscle_segment := {}
	var terminal_segment := {}
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		match String(segment.get("part_kind", "")):
			"joint":
				if joint_segment.is_empty():
					joint_segment = segment
			"limb_muscle":
				if muscle_segment.is_empty():
					muscle_segment = segment
			"terminal":
				terminal_segment = segment
	var joint_center: Vector2 = root_pivot
	if not joint_segment.is_empty():
		joint_center = joint_segment.get("local_joint_center", joint_segment.get("pivot", root_pivot))
	var muscle_start := joint_center
	var muscle_end := muscle_start
	if not muscle_segment.is_empty():
		muscle_start = muscle_segment.get("connection_start", muscle_segment.get("a", muscle_start))
		muscle_end = muscle_segment.get("connection_end", muscle_segment.get("b", muscle_start))
		axis = (muscle_end - muscle_start).normalized() if muscle_end.distance_to(muscle_start) > 0.001 else axis
	var terminal_end := muscle_end
	if not terminal_segment.is_empty():
		terminal_end = terminal_segment.get("tip", terminal_segment.get("connection_end", terminal_segment.get("b", muscle_end)))
	return {
		"joint_center": joint_center,
		"joint_axis": axis,
		"joint_start": joint_center,
		"joint_end": joint_center,
		"muscle_start": muscle_start,
		"muscle_end": muscle_end,
		"terminal_end": terminal_end,
		"joint_radius": joint_radius,
		"muscle_radius": muscle_radius,
		"terminal_radius": terminal_radius,
		"terminal_length": terminal_length,
		"segments": segments,
	}


func _is_chain_motion(group: Dictionary) -> bool:
	var motion := String(group.get("motion", "straight"))
	var material_class := String(group.get("material_class", ""))
	var muscle_name := String(group.get("muscle_name", "")).to_upper()
	var limb_name := String(group.get("limb_muscle_name", "")).to_upper()
	return motion.contains("chain") or motion in ["pendulum", "swing_aim"] or material_class in ["chain", "whip_muscle", "whip_joint"] or muscle_name.contains("CHAIN") or muscle_name.contains("TENTACLE") or limb_name.contains("CHAIN") or limb_name.contains("WHIP") or limb_name.contains("TENTACLE")


func _topology_local_vector_from_group(group: Dictionary, key: String) -> Vector2:
	var raw_value = group.get(key, Vector2.ZERO)
	if raw_value is Vector2:
		return raw_value
	return Vector2.ZERO


func _world_vector_from_topology_local(raw_value) -> Vector2:
	if not (raw_value is Vector2):
		return Vector2.ZERO
	var local_vec: Vector2 = raw_value
	if local_vec.length() <= 0.0001:
		return Vector2.ZERO
	return (_forward_vector() * local_vec.x + _side_vector() * local_vec.y).normalized()


func _has_runtime_topology() -> bool:
	return bool(stats.get("teamedit_runtime_topology", false)) and Array(stats.get("runtime_topology_segments", [])).size() > 0


func _invalidate_runtime_geometry_cache() -> void:
	runtime_geometry_cache_segments_by_key.clear()
	runtime_geometry_cache_colliders_key = ""
	runtime_geometry_cache_colliders.clear()
	runtime_geometry_visual_redraw_key = ""


func _runtime_actions_cache_signature() -> String:
	if runtime_module_actions.is_empty():
		return "-"
	var parts: Array[String] = []
	for raw_action in runtime_module_actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		parts.append("%s:%d:%d:%d:%d:%d:%d" % [
			String(action.get("profile", "")),
			int(action.get("variant", STATE_NORMAL)),
			int(action.get("phase", 0)),
			int(action.get("node_index", -1)),
			int(round(float(action.get("timer", 0.0)) * 1000.0)),
			int(round(float(action.get("duration", 0.0)) * 1000.0)),
			int(round(float(action.get("phase_timer", 0.0)) * 1000.0)),
		])
	return "|".join(parts)


func _runtime_geometry_signature(include_torso: bool, include_dynamic: bool, kind: String) -> String:
	return "%s|%s|%s|%.3f|%.3f|%.4f|%s|%d" % [
		kind,
		str(include_torso),
		str(include_dynamic),
		ring_pos,
		lane,
		facing_angle,
		_runtime_actions_cache_signature(),
		Array(stats.get("runtime_topology_segments", [])).size(),
	]


func _runtime_visual_redraw_signature() -> String:
	return "%s|%.4f|%s|%d|%d|%d|%s|%d|%d|%d|%d" % [
		String(current_state),
		facing_angle,
		_runtime_actions_cache_signature(),
		int(round(state_timer * 1000.0)),
		int(round(heat * 100.0)),
		Array(stats.get("runtime_topology_segments", [])).size(),
		str(overheated),
		int(round(float(get_meta("electronic_armor_flash", 0.0)) * 1000.0)),
		aim_pose_part_index,
		int(round(aim_pose_timer * 1000.0)),
		int(round(aim_pose_direction.angle() * 1000.0)),
	]


func _runtime_collider_with_bounds(collider: Dictionary) -> Dictionary:
	var result: Dictionary = collider.duplicate(true)
	var raw_a = result.get("a", Vector2.ZERO)
	var raw_b = result.get("b", Vector2.ZERO)
	var a_for_center: Vector2 = raw_a if raw_a is Vector2 else Vector2.ZERO
	var b_for_center: Vector2 = raw_b if raw_b is Vector2 else a_for_center
	var raw_center = result.get("center", (a_for_center + b_for_center) * 0.5)
	var center: Vector2 = raw_center if raw_center is Vector2 else (a_for_center + b_for_center) * 0.5
	var min_point := center
	var max_point := center
	var radius := 0.0
	var polygon := Array(result.get("polygon", []))
	if polygon.size() > 0:
		min_point = polygon[0]
		max_point = polygon[0]
		for raw_point in polygon:
			var point: Vector2 = raw_point
			min_point.x = minf(min_point.x, point.x)
			min_point.y = minf(min_point.y, point.y)
			max_point.x = maxf(max_point.x, point.x)
			max_point.y = maxf(max_point.y, point.y)
			radius = maxf(radius, point.distance_to(center))
	else:
		var a: Vector2 = raw_a if raw_a is Vector2 else center
		var b: Vector2 = raw_b if raw_b is Vector2 else center
		var shape_radius := float(result.get("radius", 0.0))
		min_point = Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * shape_radius
		max_point = Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * shape_radius
		radius = maxf(a.distance_to(center), b.distance_to(center)) + shape_radius
	if radius <= 0.0:
		radius = maxf((max_point.x - min_point.x) * 0.5, (max_point.y - min_point.y) * 0.5)
	result["center"] = center
	result["bounding_radius"] = radius
	result["aabb_min"] = min_point
	result["aabb_max"] = max_point
	return result


func _runtime_local_vector(raw_value) -> Vector2:
	if raw_value is Vector2:
		return raw_value
	if raw_value is Dictionary:
		var value: Dictionary = raw_value
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	if raw_value is Array and Array(raw_value).size() >= 2:
		return Vector2(float(raw_value[0]), float(raw_value[1]))
	return Vector2.ZERO


func _runtime_combat_origin() -> Vector2:
	return Vector2(mobius_s, mobius_v)


func _runtime_local_to_world(local_point: Vector2) -> Vector2:
	return _runtime_combat_origin() + _forward_vector() * local_point.x + _side_vector() * local_point.y


func _runtime_segment_key(segment: Dictionary) -> String:
	return "%d:%s" % [int(segment.get("node_index", -1)), String(segment.get("part_kind", ""))]


func _runtime_segment_to_world(raw_segment: Dictionary) -> Dictionary:
	var result: Dictionary = raw_segment.duplicate(true)
	var local_a := _runtime_local_vector(raw_segment.get("a_local", Vector2.ZERO))
	var local_b := _runtime_local_vector(raw_segment.get("b_local", Vector2.ZERO))
	var world_a := _runtime_local_to_world(local_a)
	var world_b := _runtime_local_to_world(local_b)
	if String(raw_segment.get("shape", "")) == "polygon" or raw_segment.has("polygon_local"):
		var world_polygon: Array = []
		for raw_point in Array(raw_segment.get("polygon_local", [])):
			var local_point := _runtime_local_vector(raw_point)
			world_polygon.append(_runtime_local_to_world(local_point))
		if world_polygon.size() >= 3:
			result["shape"] = "polygon"
			result["polygon"] = world_polygon
		else:
			result["shape"] = "capsule"
	else:
		result["shape"] = "capsule"
	result["a"] = world_a
	result["b"] = world_b
	result["connection_start"] = world_a
	result["connection_end"] = world_b
	result["tip"] = world_b
	if String(result.get("part_kind", "")) == "terminal":
		result["terminal_socket"] = world_a
		result["terminal_tip"] = world_b
		result["terminal_handle_visible"] = true
		result["terminal_handle_start"] = world_a
	result["pivot"] = world_a
	result["local_joint_center"] = world_a
	result["rotation_radius_start"] = 0.0
	result["rotation_radius_end"] = world_a.distance_to(world_b)
	result["radius"] = maxf(0.006, float(raw_segment.get("radius", 0.025)))
	return result


func _runtime_segment_with_aim_pose(raw_segment: Dictionary) -> Dictionary:
	var node_index := int(raw_segment.get("node_index", -9999))
	if not _aim_pose_active(node_index) or not _runtime_segment_is_ranged_weapon(raw_segment):
		return raw_segment
	var local_a := _runtime_local_vector(raw_segment.get("a_local", Vector2.ZERO))
	var local_b := _runtime_local_vector(raw_segment.get("b_local", local_a))
	var old_local_dir := local_b - local_a
	var length := maxf(0.001, old_local_dir.length())
	var world_dir := aim_pose_direction.normalized() if aim_pose_direction.length() > 0.01 else _forward_vector()
	var new_local_dir := Vector2(world_dir.dot(_forward_vector()), world_dir.dot(_side_vector()))
	if new_local_dir.length() <= 0.001:
		new_local_dir = Vector2.RIGHT
	new_local_dir = new_local_dir.normalized()
	var old_angle := old_local_dir.angle() if old_local_dir.length() > 0.001 else 0.0
	var angle_delta := wrapf(new_local_dir.angle() - old_angle, -PI, PI)
	var adjusted := raw_segment.duplicate(true)
	adjusted["a_local"] = local_a
	adjusted["b_local"] = local_a + new_local_dir * length
	adjusted["axis_local"] = new_local_dir
	if raw_segment.has("polygon_local"):
		var rotated_polygon: Array = []
		for raw_point in Array(raw_segment.get("polygon_local", [])):
			var point := _runtime_local_vector(raw_point)
			rotated_polygon.append(local_a + (point - local_a).rotated(angle_delta))
		if rotated_polygon.size() >= 3:
			adjusted["polygon_local"] = rotated_polygon
	return adjusted


func _runtime_segment_polygon_world(segment: Dictionary) -> Array:
	if String(segment.get("shape", "")) == "polygon" and segment.has("polygon"):
		var polygon: Array = []
		for raw_point in Array(segment.get("polygon", [])):
			if raw_point is Vector2:
				polygon.append(Vector2(raw_point))
		if polygon.size() >= 3:
			return polygon
	var a: Vector2 = segment.get("a", Vector2(ring_pos, lane))
	var b: Vector2 = segment.get("b", a)
	var radius := maxf(0.002, float(segment.get("radius", 0.025)))
	var axis := b - a
	if axis.length() <= 0.0001:
		return [
			a + Vector2(-radius, -radius),
			a + Vector2(radius, -radius),
			a + Vector2(radius, radius),
			a + Vector2(-radius, radius),
		]
	var node := AssemblyBoardRenderer.segment_to_component_node(segment)
	var polygon := AssemblyBoardRenderer.component_polygon((a + b) * 0.5, node, axis, radius, a.distance_to(b), false)
	var result: Array = []
	for p in polygon:
		result.append(p)
	return result


func _runtime_segment_polygon_local(segment: Dictionary) -> PackedVector2Array:
	var local_points := PackedVector2Array()
	var center := Vector2(ring_pos, lane)
	var visual_scale := _runtime_visual_scale()
	for raw_point in _runtime_segment_polygon_world(segment):
		if raw_point is Vector2:
			local_points.append((Vector2(raw_point) - center).rotated(-rotation) * visual_scale)
	return local_points


func _draw_runtime_assembly_board_unit() -> void:
	var segments := _runtime_topology_world_segments(true, true)
	if segments.is_empty():
		return
	var material_color := _team_material_color()
	for raw_segment in segments:
		if raw_segment is Dictionary and String(Dictionary(raw_segment).get("part_kind", "")) == "torso":
			_draw_runtime_assembly_segment(Dictionary(raw_segment), material_color)
	for raw_segment in segments:
		if raw_segment is Dictionary and String(Dictionary(raw_segment).get("part_kind", "")) != "torso":
			_draw_runtime_assembly_segment(Dictionary(raw_segment), material_color)


func _runtime_status_curve_overlay_color() -> Color:
	if overheated:
		return Color(1.0, 0.18, 0.02, 0.46)
	if current_state == STATE_ARMOR and state_timer > 0.0:
		return Color(0.42, 0.72, 1.0, 0.48)
	if current_state == STATE_ACTIVE and state_timer > 0.0:
		return Color(1.0, 0.34, 0.86, 0.50)
	if float(get_meta("electronic_armor_flash", 0.0)) > 0.0:
		return Color(0.32, 0.92, 1.0, 0.50)
	return Color(0.0, 0.0, 0.0, 0.0)


func _runtime_status_curve_overlay_segments() -> Array:
	var overlay_color := _runtime_status_curve_overlay_color()
	if overlay_color.a <= 0.0:
		return []
	return _runtime_topology_world_segments(true, true)


func _draw_runtime_status_curve_overlay() -> void:
	var overlay_color := _runtime_status_curve_overlay_color()
	if overlay_color.a <= 0.0:
		return
	var segments := _runtime_topology_world_segments(true, true)
	if segments.is_empty():
		return
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		if String(Dictionary(raw_segment).get("part_kind", "")) != "torso":
			continue
		if AssemblyBoardRenderer.draw_runtime_segment_status_overlay(self, Dictionary(raw_segment), Vector2(ring_pos, lane), rotation, _runtime_visual_scale(), overlay_color, 3.3):
			runtime_status_curve_overlay_last_count += 1
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		if String(Dictionary(raw_segment).get("part_kind", "")) == "torso":
			continue
		if AssemblyBoardRenderer.draw_runtime_segment_status_overlay(self, Dictionary(raw_segment), Vector2(ring_pos, lane), rotation, _runtime_visual_scale(), overlay_color, 2.7):
			runtime_status_curve_overlay_last_count += 1


func _draw_runtime_assembly_segment(segment: Dictionary, material_color: Color) -> void:
	var part_kind := String(segment.get("part_kind", "limb_muscle"))
	var visual_group := _runtime_contact_group_for_segment(segment)
	var attack_index := _runtime_attack_index_for_segment(segment)
	var runtime_action := bool(segment.get("runtime_action", false))
	var action_flash := runtime_action or (attack_index >= 0 and _limb_drive_power(attack_index) > 0.04)
	var draw_segment := segment.duplicate(true)
	if part_kind == "torso":
		draw_segment["material_visual"] = String(stats.get("torso_visual_material", visual_group.get("material_visual", "metal")))
	else:
		draw_segment["material_visual"] = String(visual_group.get("material_visual", segment.get("material_visual", segment.get("material_class", ""))))
	if action_flash:
		var action_state := String(segment.get("runtime_action_state", active_part_state))
		draw_segment["runtime_action"] = true
		draw_segment["runtime_action_state"] = action_state
		draw_segment["runtime_action_phase"] = String(segment.get("runtime_action_phase", ""))
		draw_segment["runtime_action_progress"] = float(segment.get("runtime_action_progress", 0.0))
	draw_segment["material_class"] = String(visual_group.get("material_class", segment.get("material_class", "")))
	draw_segment["damage_type"] = String(visual_group.get("damage_type", segment.get("damage_type", "")))
	draw_segment["projectile_damage_type"] = String(visual_group.get("projectile_damage_type", segment.get("projectile_damage_type", "")))
	draw_segment["source_shape"] = String(visual_group.get("source_shape", segment.get("source_shape", segment.get("shape", ""))))
	draw_segment["weapon_family"] = String(visual_group.get("weapon_family", segment.get("weapon_family", "")))
	draw_segment["blunt_shield"] = bool(visual_group.get("blunt_shield", segment.get("blunt_shield", false)))
	draw_segment["blunt_gauntlet"] = bool(visual_group.get("blunt_gauntlet", segment.get("blunt_gauntlet", false)))
	draw_segment["blunt_hammer"] = bool(visual_group.get("blunt_hammer", segment.get("blunt_hammer", false)))
	AssemblyBoardRenderer.draw_runtime_segment(self, draw_segment, Vector2(ring_pos, lane), rotation, _runtime_visual_scale(), material_color, primary_color)


func _runtime_group_for_segment(segment: Dictionary) -> Dictionary:
	return {
		"name": String(segment.get("name", "PART")),
		"damage_type": String(segment.get("damage_type", "blunt")),
		"material_class": String(segment.get("material_class", "body")),
		"melee_contact_class": String(segment.get("material_class", "body")),
		"projectile": bool(segment.get("projectile", false)),
		"projectile_damage_type": String(segment.get("projectile_damage_type", segment.get("damage_type", "bullet"))),
		"projectile_style": String(segment.get("projectile_style", "")),
		"projectile_behavior": String(segment.get("projectile_behavior", "")),
		"projectile_momentum": float(segment.get("projectile_momentum", 0.0)),
		"gun_projectile_damage_mult": float(segment.get("gun_projectile_damage_mult", 0.0)),
		"projectile_width_m": float(segment.get("projectile_width_m", 0.0)),
		"projectile_range": float(segment.get("projectile_range", 0.0)),
		"projectile_speed_mult": float(segment.get("projectile_speed_mult", 0.0)),
		"fire_rate": float(segment.get("fire_rate", 0.0)),
		"fire_interval": float(segment.get("fire_interval", 0.0)),
		"laser_tick_interval": float(segment.get("laser_tick_interval", segment.get("fire_interval", 0.0))),
		"laser_charge_time": float(segment.get("laser_charge_time", 0.0)),
		"bullet_lock_radius": float(segment.get("bullet_lock_radius", 0.0)),
		"bullet_lock_time": float(segment.get("bullet_lock_time", 0.0)),
		"sniper_fire_delay": float(segment.get("sniper_fire_delay", segment.get("bullet_lock_time", 0.0))),
		"gun_kind": String(segment.get("gun_kind", "")),
		"ammo_kind": String(segment.get("ammo_kind", "")),
		"terminal_weapon_kind": String(segment.get("terminal_weapon_kind", "")),
		"shape": String(segment.get("shape", "")),
		"source_shape": String(segment.get("source_shape", segment.get("shape", ""))),
		"weapon_family": String(segment.get("weapon_family", "")),
		"blunt_shield": bool(segment.get("blunt_shield", false)),
		"blunt_gauntlet": bool(segment.get("blunt_gauntlet", false)),
		"blunt_hammer": bool(segment.get("blunt_hammer", false)),
		"normal_damage": float(segment.get("contact_damage", 1.0)),
		"normal_heat": float(segment.get("normal_heat", 0.0)),
	}


func _runtime_attack_index_for_segment(segment: Dictionary) -> int:
	var node_index := int(segment.get("node_index", -1))
	if node_index < 0:
		return -1
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if not (raw_binding is Dictionary):
			continue
		var binding: Dictionary = raw_binding
		if _runtime_node_array_has(Array(binding.get("target_nodes", [])), node_index):
			return clampi(int(binding.get("attack_key", 1)), 1, 6) - 1
	return -1


func _runtime_contact_group_for_segment(segment: Dictionary) -> Dictionary:
	return _runtime_group_for_segment(segment)


func _runtime_segment_source_by_node(node_index: int) -> Dictionary:
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func runtime_world_segment_for_node(node_index: int, include_dynamic: bool = true) -> Dictionary:
	for raw_segment in _runtime_topology_world_segments(true, include_dynamic):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment).duplicate(true)
	return {}


func runtime_group_for_node(node_index: int) -> Dictionary:
	var source := _runtime_segment_source_by_node(node_index)
	if source.is_empty():
		return {}
	return _runtime_group_for_segment(source)


func _runtime_action_phase(action: Dictionary) -> float:
	var duration := maxf(0.001, float(action.get("duration", 0.62)))
	return clampf(1.0 - float(action.get("timer", 0.0)) / duration, 0.0, 1.0)


func _runtime_action_startup_ratio(action: Dictionary) -> float:
	return clampf(float(action.get("startup_ratio", TWO_LINK_DEFAULT_STARTUP_RATIO)), 0.05, 0.95)


func _directed_lerp_angle(from_angle: float, to_angle: float, t: float, turn_sign: float) -> float:
	var delta := wrapf(to_angle - from_angle, -PI, PI)
	if turn_sign > 0.0 and delta < 0.0:
		delta += TAU
	elif turn_sign < 0.0 and delta > 0.0:
		delta -= TAU
	return from_angle + delta * clampf(t, 0.0, 1.0)


func _two_link_turn_sign_from_root(root_local: Vector2, base_first_dir: Vector2) -> float:
	var side_probe := root_local.y
	if absf(side_probe) <= 0.001:
		side_probe = base_first_dir.y
	return 1.0 if side_probe < 0.0 else -1.0


func _runtime_two_link_forward_snap_local_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var target_nodes: Array = _runtime_node_array(Array(action.get("target_nodes", [])))
	if target_nodes.size() != 2:
		return overrides
	var first_source := _runtime_segment_source_by_node(int(target_nodes[0]))
	var second_source := _runtime_segment_source_by_node(int(target_nodes[1]))
	if first_source.is_empty() or second_source.is_empty():
		return overrides
	var first_a := _runtime_local_vector(first_source.get("a_local", Vector2.ZERO))
	var first_b := _runtime_local_vector(first_source.get("b_local", first_a))
	var second_a := _runtime_local_vector(second_source.get("a_local", first_b))
	var second_b := _runtime_local_vector(second_source.get("b_local", second_a))
	var first_length := maxf(0.001, first_a.distance_to(first_b))
	var second_length := maxf(0.001, second_a.distance_to(second_b))
	var base_first_dir := (first_b - first_a).normalized()
	if base_first_dir.length() <= 0.001:
		base_first_dir = Vector2.RIGHT
	var base_second_dir := (second_b - second_a).normalized()
	if base_second_dir.length() <= 0.001:
		base_second_dir = Vector2.RIGHT
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	var forward_angle := 0.0
	var first_angle := base_first_dir.angle()
	var second_angle := base_second_dir.angle()
	var startup_turn_sign := _two_link_turn_sign_from_root(first_a, base_first_dir)
	if phase < startup_ratio:
		var t := sin((phase / startup_ratio) * PI * 0.5)
		first_angle = _directed_lerp_angle(base_first_dir.angle(), forward_angle, t, startup_turn_sign)
		second_angle = _directed_lerp_angle(base_second_dir.angle(), forward_angle, t, startup_turn_sign)
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		var t := sin(((phase - startup_ratio) / recovery_span) * PI * 0.5)
		first_angle = _directed_lerp_angle(forward_angle, PI, t, -startup_turn_sign)
		second_angle = forward_angle
	var root_local := first_a
	var first_dir := Vector2.RIGHT.rotated(first_angle).normalized()
	var second_dir := Vector2.RIGHT.rotated(second_angle).normalized()
	var first_override := first_source.duplicate(true)
	var second_override := second_source.duplicate(true)
	first_override["a_local"] = root_local
	first_override["b_local"] = root_local + first_dir * first_length
	first_override["axis_local"] = first_dir
	second_override["a_local"] = first_override["b_local"]
	second_override["b_local"] = Vector2(second_override["a_local"]) + second_dir * second_length
	second_override["axis_local"] = second_dir
	overrides[_runtime_segment_key(first_source)] = first_override
	overrides[_runtime_segment_key(second_source)] = second_override
	return overrides


func _runtime_two_link_forward_snap_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var local_overrides := _runtime_two_link_forward_snap_local_overrides(action)
	for key in local_overrides.keys():
		var source: Dictionary = Dictionary(local_overrides[key])
		var world := _runtime_segment_to_world(source)
		world["runtime_action"] = true
		world["runtime_action_state"] = String(action.get("state", STATE_NORMAL))
		var phase := _runtime_action_phase(action)
		var startup_ratio := _runtime_action_startup_ratio(action)
		var in_startup := phase <= startup_ratio
		world["runtime_action_phase"] = "startup" if in_startup else "recovery"
		world["runtime_action_progress"] = phase
		var target_nodes: Array = _runtime_node_array(Array(action.get("target_nodes", [])))
		if target_nodes.size() > 0:
			var first_source := _runtime_segment_source_by_node(int(target_nodes[0]))
			if not first_source.is_empty():
				world["pivot"] = _runtime_local_to_world(_runtime_local_vector(first_source.get("a_local", Vector2.ZERO)))
		overrides[key] = world
	return overrides


func _commit_runtime_two_link_forward_snap_pose(action: Dictionary) -> void:
	var finished_action := action.duplicate(true)
	finished_action["timer"] = 0.0
	var local_overrides := _runtime_two_link_forward_snap_local_overrides(finished_action)
	if local_overrides.is_empty():
		return
	var segments := Array(stats.get("runtime_topology_segments", [])).duplicate(true)
	for i in range(segments.size()):
		if not (segments[i] is Dictionary):
			continue
		var segment: Dictionary = segments[i]
		var key := _runtime_segment_key(segment)
		if not local_overrides.has(key):
			continue
		var updated := segment.duplicate(true)
		var override: Dictionary = Dictionary(local_overrides[key])
		updated["a_local"] = override.get("a_local", updated.get("a_local", Vector2.ZERO))
		updated["b_local"] = override.get("b_local", updated.get("b_local", Vector2.ZERO))
		updated["axis_local"] = override.get("axis_local", updated.get("axis_local", Vector2.RIGHT))
		segments[i] = updated
	stats["runtime_topology_segments"] = segments
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()


func _gauntlet_side_sign(root_local: Vector2, base_dir: Vector2) -> float:
	var side_probe := root_local.y
	if absf(side_probe) <= 0.001:
		side_probe = base_dir.y
	return -1.0 if side_probe < 0.0 else 1.0


func _runtime_gauntlet_target_angle(base_angle: float, side_sign: float, command_variant: String, module_part: Dictionary) -> float:
	var recovery_angle := deg_to_rad(float(module_part.get("recovery_angle_degrees", 15.0))) * side_sign
	var swing_angle := deg_to_rad(float(module_part.get("swing_arc_degrees", 70.0)))
	match command_variant:
		"normal_outward_swing", "active_outward_extend":
			return recovery_angle + side_sign * swing_angle
		"normal_inward_swing", "armor_inward_extend":
			return 0.0
	return recovery_angle


func _runtime_gauntlet_max_extension(command_variant: String, module_part: Dictionary, action: Dictionary) -> float:
	if command_variant in ["normal_extend", "armor_inward_extend", "active_outward_extend"]:
		return maxf(0.0, float(action.get("extension_m", module_part.get("module_extension_m", module_part.get("required_extension_m", 2.0)))))
	return 0.0


func _runtime_gauntlet_extend_swing_local_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var target_nodes: Array = _runtime_node_array(Array(action.get("target_nodes", [])))
	if target_nodes.size() != 1:
		return overrides
	var source := _runtime_segment_source_by_node(int(target_nodes[0]))
	if source.is_empty():
		return overrides
	var module_part: Dictionary = {}
	var binding: Dictionary = action.get("binding", {}) if action.get("binding", {}) is Dictionary else {}
	if binding.get("module_part", {}) is Dictionary:
		module_part = binding.get("module_part", {})
	var root_local := _runtime_local_vector(source.get("a_local", Vector2.ZERO))
	var tip_local := _runtime_local_vector(source.get("b_local", root_local + Vector2.RIGHT * 0.5))
	var base_length := maxf(0.001, root_local.distance_to(tip_local))
	var base_dir := (tip_local - root_local).normalized()
	if base_dir.length() <= 0.001:
		base_dir = Vector2.RIGHT
	var side_sign := _gauntlet_side_sign(root_local, base_dir)
	var recovery_angle := deg_to_rad(float(module_part.get("recovery_angle_degrees", 15.0))) * side_sign
	var command_variant := String(action.get("command_variant", "normal_extend"))
	var target_angle := _runtime_gauntlet_target_angle(base_dir.angle(), side_sign, command_variant, module_part)
	var max_extension := _runtime_gauntlet_max_extension(command_variant, module_part, action)
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	var angle := recovery_angle
	var extension := 0.0
	if phase < startup_ratio:
		var t := sin((phase / startup_ratio) * PI * 0.5)
		angle = lerp_angle(recovery_angle, target_angle, t)
		extension = lerpf(0.0, max_extension, t)
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		var t := sin(((phase - startup_ratio) / recovery_span) * PI * 0.5)
		angle = lerp_angle(target_angle, recovery_angle, t)
		extension = lerpf(max_extension, 0.0, t)
	var dir := Vector2.RIGHT.rotated(angle).normalized()
	var override := source.duplicate(true)
	override["a_local"] = root_local
	override["b_local"] = root_local + dir * (base_length + maxf(0.0, extension))
	override["axis_local"] = dir
	overrides[_runtime_segment_key(source)] = override
	return overrides


func _runtime_gauntlet_extend_swing_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var local_overrides := _runtime_gauntlet_extend_swing_local_overrides(action)
	for key in local_overrides.keys():
		var source: Dictionary = Dictionary(local_overrides[key])
		var world := _runtime_segment_to_world(source)
		world["runtime_action"] = true
		world["runtime_action_state"] = String(action.get("state", STATE_NORMAL))
		var phase := _runtime_action_phase(action)
		var startup_ratio := _runtime_action_startup_ratio(action)
		world["runtime_action_phase"] = "startup" if phase <= startup_ratio else "recovery"
		world["runtime_action_progress"] = phase
		world["pivot"] = _runtime_local_to_world(_runtime_local_vector(source.get("a_local", Vector2.ZERO)))
		overrides[key] = world
	return overrides


func _commit_runtime_gauntlet_extend_swing_pose(action: Dictionary) -> void:
	var finished_action := action.duplicate(true)
	finished_action["timer"] = 0.0
	var local_overrides := _runtime_gauntlet_extend_swing_local_overrides(finished_action)
	if local_overrides.is_empty():
		return
	var segments := Array(stats.get("runtime_topology_segments", [])).duplicate(true)
	for i in range(segments.size()):
		if not (segments[i] is Dictionary):
			continue
		var segment: Dictionary = segments[i]
		var key := _runtime_segment_key(segment)
		if not local_overrides.has(key):
			continue
		var updated := segment.duplicate(true)
		var override: Dictionary = Dictionary(local_overrides[key])
		updated["a_local"] = override.get("a_local", updated.get("a_local", Vector2.ZERO))
		updated["b_local"] = override.get("b_local", updated.get("b_local", Vector2.ZERO))
		updated["axis_local"] = override.get("axis_local", updated.get("axis_local", Vector2.RIGHT))
		segments[i] = updated
	stats["runtime_topology_segments"] = segments
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()


func _runtime_blunt_terminal_target_delta(profile: String, command_variant: String, module_part: Dictionary, side_sign: float) -> float:
	var arc := deg_to_rad(maxf(1.0, float(module_part.get("swing_arc_degrees", 82.0 if profile == "blunt_shield_guard_bash" else 150.0))))
	var recovery := deg_to_rad(float(module_part.get("recovery_angle_degrees", 10.0 if profile == "blunt_shield_guard_bash" else -18.0))) * side_sign
	if profile == "blunt_shield_guard_bash":
		match command_variant:
			"normal_forward_bash", "armor_guard_bash":
				return recovery + side_sign * arc * 0.58
			"normal_back_bash", "active_shoulder_bash":
				return recovery - side_sign * arc * 0.64
			"normal_guard":
				return recovery + side_sign * arc * 0.18
		return recovery
	match command_variant:
		"armor_overhead_slam":
			return recovery + side_sign * arc
		"active_side_slam", "normal_back_slam":
			return recovery - side_sign * arc * 0.85
		"normal_forward_slam":
			return recovery + side_sign * arc * 0.72
		"normal_short_swing":
			return recovery + side_sign * arc * 0.42
	return recovery


func _runtime_blunt_terminal_local_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var target_nodes: Array = _runtime_node_array(Array(action.get("target_nodes", [])))
	if target_nodes.size() != 1:
		return overrides
	var source := _runtime_segment_source_by_node(int(target_nodes[0]))
	if source.is_empty():
		return overrides
	var module_part: Dictionary = {}
	var binding: Dictionary = action.get("binding", {}) if action.get("binding", {}) is Dictionary else {}
	if binding.get("module_part", {}) is Dictionary:
		module_part = binding.get("module_part", {})
	var root_local := _runtime_local_vector(source.get("a_local", Vector2.ZERO))
	var tip_local := _runtime_local_vector(source.get("b_local", root_local + Vector2.RIGHT * 0.5))
	var base_length := maxf(0.001, root_local.distance_to(tip_local))
	var base_dir := (tip_local - root_local).normalized()
	if base_dir.length() <= 0.001:
		base_dir = Vector2.RIGHT
	var side_sign := _gauntlet_side_sign(root_local, base_dir)
	var profile := String(action.get("profile", "blunt_shield_guard_bash"))
	var command_variant := String(action.get("command_variant", "normal_guard"))
	var recovery_delta := deg_to_rad(float(module_part.get("recovery_angle_degrees", 10.0 if profile == "blunt_shield_guard_bash" else -18.0))) * side_sign
	var target_delta := _runtime_blunt_terminal_target_delta(profile, command_variant, module_part, side_sign)
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	var delta := recovery_delta
	if phase < startup_ratio:
		var t := sin((phase / startup_ratio) * PI * 0.5)
		delta = lerp_angle(recovery_delta, target_delta, t)
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		var t := sin(((phase - startup_ratio) / recovery_span) * PI * 0.5)
		delta = lerp_angle(target_delta, recovery_delta, t)
	var dir := base_dir.rotated(delta).normalized()
	var override := source.duplicate(true)
	override["a_local"] = root_local
	override["b_local"] = root_local + dir * base_length
	override["axis_local"] = dir
	overrides[_runtime_segment_key(source)] = override
	return overrides


func _runtime_blunt_terminal_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var local_overrides := _runtime_blunt_terminal_local_overrides(action)
	for key in local_overrides.keys():
		var source: Dictionary = Dictionary(local_overrides[key])
		var world := _runtime_segment_to_world(source)
		world["runtime_action"] = true
		world["runtime_action_state"] = String(action.get("state", STATE_NORMAL))
		var phase := _runtime_action_phase(action)
		var startup_ratio := _runtime_action_startup_ratio(action)
		world["runtime_action_phase"] = "startup" if phase <= startup_ratio else "recovery"
		world["runtime_action_progress"] = phase
		world["pivot"] = _runtime_local_to_world(_runtime_local_vector(source.get("a_local", Vector2.ZERO)))
		overrides[key] = world
	return overrides


func _commit_runtime_blunt_terminal_pose(action: Dictionary) -> void:
	var finished_action := action.duplicate(true)
	finished_action["timer"] = 0.0
	var local_overrides := _runtime_blunt_terminal_local_overrides(finished_action)
	if local_overrides.is_empty():
		return
	var segments := Array(stats.get("runtime_topology_segments", [])).duplicate(true)
	for i in range(segments.size()):
		if not (segments[i] is Dictionary):
			continue
		var segment: Dictionary = segments[i]
		var key := _runtime_segment_key(segment)
		if not local_overrides.has(key):
			continue
		var updated := segment.duplicate(true)
		var override: Dictionary = Dictionary(local_overrides[key])
		updated["a_local"] = override.get("a_local", updated.get("a_local", Vector2.ZERO))
		updated["b_local"] = override.get("b_local", updated.get("b_local", Vector2.ZERO))
		updated["axis_local"] = override.get("axis_local", updated.get("axis_local", Vector2.RIGHT))
		segments[i] = updated
	stats["runtime_topology_segments"] = segments
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()


func _runtime_blade_side_sign(root_local: Vector2, base_dir: Vector2) -> float:
	var side_probe := root_local.y
	if absf(side_probe) <= 0.001:
		side_probe = base_dir.y
	return 1.0 if side_probe < 0.0 else -1.0


func _runtime_blade_target_delta(command_variant: String, module_part: Dictionary, side_sign: float) -> float:
	var arc := deg_to_rad(maxf(1.0, float(module_part.get("swing_arc_degrees", 180.0))))
	match command_variant:
		"armor_forward_cut":
			return -side_sign * arc * 0.62
		"active_reverse_cut":
			return side_sign * arc * 0.86
		"armor_special":
			return -side_sign * arc
		"active_special":
			return side_sign * arc
	return side_sign * arc * 0.72


func _runtime_blade_action_local_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var target_nodes: Array = _runtime_node_array(Array(action.get("target_nodes", [])))
	if target_nodes.is_empty():
		return overrides
	var sources: Array = []
	for raw_node in target_nodes:
		var source := _runtime_segment_source_by_node(int(raw_node))
		if not source.is_empty():
			sources.append(source)
	if sources.is_empty():
		return overrides
	var binding: Dictionary = action.get("binding", {}) if action.get("binding", {}) is Dictionary else {}
	var module_part: Dictionary = binding.get("module_part", {}) if binding.get("module_part", {}) is Dictionary else {}
	var first_source: Dictionary = Dictionary(sources[0])
	var root_local := _runtime_local_vector(first_source.get("a_local", Vector2.ZERO))
	var first_b := _runtime_local_vector(first_source.get("b_local", root_local + Vector2.RIGHT * 0.5))
	var base_first_dir := (first_b - root_local).normalized()
	if base_first_dir.length() <= 0.001:
		base_first_dir = Vector2.RIGHT
	var side_sign := _runtime_blade_side_sign(root_local, base_first_dir)
	var command_variant := String(action.get("command_variant", "normal_sweep"))
	var target_delta := _runtime_blade_target_delta(command_variant, module_part, side_sign)
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	var delta := 0.0
	var extension_ratio := 0.0
	if phase < startup_ratio:
		var t := sin((phase / startup_ratio) * PI * 0.5)
		delta = lerpf(0.0, target_delta, t)
		extension_ratio = t
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		var t := sin(((phase - startup_ratio) / recovery_span) * PI * 0.5)
		delta = lerpf(target_delta, 0.0, t)
		extension_ratio = 1.0 - t
	var profile := String(action.get("profile", ""))
	var extension_m := maxf(0.0, float(action.get("extension_m", 0.0))) if profile == "extend_slash_driver" else 0.0
	var previous_b := root_local
	for i in range(sources.size()):
		var source: Dictionary = Dictionary(sources[i])
		var base_a := _runtime_local_vector(source.get("a_local", previous_b))
		var base_b := _runtime_local_vector(source.get("b_local", base_a + Vector2.RIGHT * 0.5))
		var base_dir := (base_b - base_a).normalized()
		if base_dir.length() <= 0.001:
			base_dir = Vector2.RIGHT
		var length := maxf(0.001, base_a.distance_to(base_b))
		if i == sources.size() - 1 and extension_m > 0.0:
			length += extension_m * extension_ratio
		var dir := base_dir.rotated(delta).normalized()
		var override := source.duplicate(true)
		override["a_local"] = previous_b
		override["b_local"] = previous_b + dir * length
		override["axis_local"] = dir
		overrides[_runtime_segment_key(source)] = override
		previous_b = override["b_local"]
	return overrides


func _runtime_blade_action_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var local_overrides := _runtime_blade_action_local_overrides(action)
	for key in local_overrides.keys():
		var source: Dictionary = Dictionary(local_overrides[key])
		var world := _runtime_segment_to_world(source)
		world["runtime_action"] = true
		world["runtime_action_state"] = String(action.get("state", STATE_NORMAL))
		var phase := _runtime_action_phase(action)
		var startup_ratio := _runtime_action_startup_ratio(action)
		world["runtime_action_phase"] = "startup" if phase <= startup_ratio else "recovery"
		world["runtime_action_progress"] = phase
		world["pivot"] = _runtime_local_to_world(_runtime_local_vector(source.get("a_local", Vector2.ZERO)))
		overrides[key] = world
	return overrides


func _commit_runtime_blade_pose(action: Dictionary) -> void:
	var finished_action := action.duplicate(true)
	finished_action["timer"] = 0.0
	var local_overrides := _runtime_blade_action_local_overrides(finished_action)
	if local_overrides.is_empty():
		return
	var segments := Array(stats.get("runtime_topology_segments", [])).duplicate(true)
	for i in range(segments.size()):
		if not (segments[i] is Dictionary):
			continue
		var segment: Dictionary = segments[i]
		var key := _runtime_segment_key(segment)
		if not local_overrides.has(key):
			continue
		var updated := segment.duplicate(true)
		var override: Dictionary = Dictionary(local_overrides[key])
		updated["a_local"] = override.get("a_local", updated.get("a_local", Vector2.ZERO))
		updated["b_local"] = override.get("b_local", updated.get("b_local", Vector2.ZERO))
		updated["axis_local"] = override.get("axis_local", updated.get("axis_local", Vector2.RIGHT))
		segments[i] = updated
	stats["runtime_topology_segments"] = segments
	_invalidate_runtime_geometry_cache()
	_refresh_visuals()


func _runtime_module_segment_overrides(body_length: float, body_radius: float) -> Dictionary:
	var overrides := {}
	for raw_action in runtime_module_actions:
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action
		var action_overrides := {}
		if String(action.get("profile", "")) == "two_link_forward_snap":
			action_overrides = _runtime_two_link_forward_snap_overrides(action)
		elif String(action.get("profile", "")) == "blunt_gauntlet_extend_swing":
			action_overrides = _runtime_gauntlet_extend_swing_overrides(action)
		elif String(action.get("profile", "")) in ["blunt_shield_guard_bash", "blunt_hammer_windup_slam"]:
			action_overrides = _runtime_blunt_terminal_overrides(action)
		elif _is_runtime_blade_profile(String(action.get("profile", ""))):
			action_overrides = _runtime_blade_action_overrides(action)
		elif bool(action.get("generic_melee_pose", false)):
			action_overrides = _runtime_generic_melee_overrides(action)
		else:
			continue
		for key in action_overrides.keys():
			overrides[key] = action_overrides[key]
	return overrides


func _runtime_generic_melee_overrides(action: Dictionary) -> Dictionary:
	var overrides := {}
	var phase := _runtime_action_phase(action)
	var startup_ratio := _runtime_action_startup_ratio(action)
	var pose_t := 0.0
	if phase <= startup_ratio:
		pose_t = sin((phase / maxf(0.001, startup_ratio)) * PI * 0.5)
	else:
		var recovery_span := maxf(0.001, 1.0 - startup_ratio)
		pose_t = cos(((phase - startup_ratio) / recovery_span) * PI * 0.5)
	pose_t = clampf(pose_t, 0.0, 1.0)
	var extension_m := maxf(0.0, float(action.get("module_extension_m", 0.0)))
	var swing_arc := deg_to_rad(maxf(0.0, float(action.get("swing_arc_degrees", 0.0))))
	var side_sign := -1.0 if String(action.get("state", STATE_NORMAL)) == STATE_ACTIVE else 1.0
	var variant_key := String(action.get("module_variant_key", ""))
	var target_index := 0
	for raw_node in Array(action.get("target_nodes", [])):
		var node_index := int(raw_node)
		var source := _runtime_segment_source_by_node(node_index)
		if source.is_empty():
			continue
		var root_local := _runtime_local_vector(source.get("a_local", Vector2.ZERO))
		var tip_local := _runtime_local_vector(source.get("b_local", root_local + Vector2.RIGHT * 0.5))
		var base_vector := tip_local - root_local
		var base_length := maxf(0.001, base_vector.length())
		var base_dir := base_vector.normalized()
		var dir := base_dir
		var pose_scale := pose_t
		if variant_key == "crush_windup":
			pose_scale = pow(pose_t, 1.35)
		elif variant_key == "feint_thrust":
			var ghost_phase := clampf(float(action.get("feint_ghost_phase", 0.42)), 0.12, 0.84)
			pose_scale = pose_t * 0.42 if phase <= startup_ratio * ghost_phase else pose_t
			var retarget: Vector2 = action.get("feint_retarget_direction", base_dir)
			if retarget.length() > 0.01:
				dir = retarget.normalized()
				base_dir = dir
		var local_side_sign := side_sign
		if variant_key == "vise_close" or String(action.get("profile", "")) == "inward_pincer_clamp":
			local_side_sign = -1.0 if target_index % 2 == 0 else 1.0
		if swing_arc > 0.001:
			dir = base_dir.rotated((swing_arc * 0.5 * local_side_sign) * pose_scale).normalized()
		var override := source.duplicate(true)
		override["a_local"] = root_local
		override["b_local"] = root_local + dir * (base_length + extension_m * pose_scale)
		override["axis_local"] = dir
		var world := _runtime_segment_to_world(override)
		world["runtime_action"] = true
		world["runtime_action_state"] = String(action.get("state", STATE_NORMAL))
		world["runtime_action_phase"] = "startup" if phase <= startup_ratio else "recovery"
		world["runtime_action_progress"] = phase
		world["module_variant_key"] = variant_key
		world["module_visual_family"] = String(action.get("module_visual_family", variant_key))
		if variant_key == "crush_windup":
			var damage_mult := maxf(0.1, float(action.get("runtime_contact_damage_mult", 1.24)))
			if world.has("damage_coeff"):
				world["damage_coeff"] = float(world.get("damage_coeff", 0.0)) * damage_mult
			world["contact_damage_mult"] = float(world.get("contact_damage_mult", 1.0)) * damage_mult
			world["runtime_contact_damage_mult"] = damage_mult
		elif variant_key == "vise_close":
			world["clamp_pin_seconds"] = float(action.get("clamp_pin_seconds", 0.38))
			world["clamp_velocity_mult"] = float(action.get("clamp_velocity_mult", 0.35))
		elif variant_key == "feint_thrust":
			world["feint_ghost_visible"] = phase <= startup_ratio * clampf(float(action.get("feint_ghost_phase", 0.42)), 0.12, 0.84)
			world["feint_retarget_direction"] = action.get("feint_retarget_direction", dir)
			world["contact_damage_mult"] = float(world.get("contact_damage_mult", 1.0)) * clampf(float(action.get("feint_final_width_mult", 0.65)), 0.35, 1.0)
		world["pivot"] = _runtime_local_to_world(root_local)
		overrides[_runtime_segment_key(source)] = world
		target_index += 1
	return overrides


func _runtime_topology_world_segments(include_torso: bool = true, include_dynamic: bool = true) -> Array:
	var cache_key := _runtime_geometry_signature(include_torso, include_dynamic, "segments")
	if runtime_geometry_cache_segments_by_key.has(cache_key):
		runtime_geometry_cache_hits += 1
		return runtime_geometry_cache_segments_by_key[cache_key]
	runtime_geometry_cache_misses += 1
	var segments := _runtime_topology_world_segments_uncached(include_torso, include_dynamic)
	runtime_geometry_cache_segments_by_key[cache_key] = segments
	runtime_geometry_cache_builds += 1
	return segments


func _runtime_topology_world_segments_uncached(include_torso: bool = true, include_dynamic: bool = true) -> Array:
	var result: Array = []
	if not _has_runtime_topology():
		return result
	var body_length: float = clampf(float(stats.get("length", 1.0)), 0.12, 4.5)
	var body_radius: float = clampf(float(stats.get("radius", 0.28)), 0.04, 3.2)
	var overrides := _runtime_module_segment_overrides(body_length, body_radius) if include_dynamic else {}
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if not (raw_segment is Dictionary):
			continue
		var source_segment: Dictionary = raw_segment
		var part_kind := String(source_segment.get("part_kind", ""))
		if part_kind == "torso" and not include_torso:
			continue
		if include_dynamic:
			source_segment = _runtime_segment_with_aim_pose(source_segment)
		var key := _runtime_segment_key(source_segment)
		if overrides.has(key):
			result.append(Dictionary(overrides[key]).duplicate(true))
		else:
			result.append(_runtime_segment_to_world(source_segment))
	return result


func _rest_direction_for_group(part_index: int, group: Dictionary, lane_bias: float) -> Vector2:
	return _forward_vector()


func _rest_direction_for_part(part_index: int, lane_bias: float) -> Vector2:
	return _forward_vector()


func barrier_pulse() -> Dictionary:
	if role != "barrier":
		return {}
	return begin_action(STATE_ACTIVE)


func manual_cool(delta: float) -> void:
	if not active or role != "hero":
		return
	if melee_stagger_timer > 0.0:
		return
	manual_cooling = true
	smoke_timer = 0.18
	cooling_lock_timer = maxf(cooling_lock_timer, 0.4)
	velocity = velocity.move_toward(Vector2.ZERO, 9.0 * delta)
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	heat = clampf(heat - float(stats.get("manual_cooling", 48.0)) * delta * HEAT_RATE_MULT, 0.0, heat_capacity)
	if overheated and heat <= heat_capacity * _overheat_clear_ratio():
		overheated = false
	_refresh_visuals()


func boost(direction: Vector2, ring_length: float) -> bool:
	if not active or role != "hero" or direction.length() < 0.1 or cooling_lock_timer > 0.0:
		return false
	if melee_stagger_timer > 0.0:
		return false
	if boost_cooldown_timer > 0.0:
		return false
	if _boost_request_is_reverse_only(direction):
		if _can_velocity_brake():
			_apply_velocity_brake(0.0, "reverse_brake", true, direction)
		else:
			set_meta("last_velocity_brake_reason", "reverse_boost_disabled")
		return false
	if _brake_reverse_waiting_for_repress(direction) or _input_should_velocity_brake(direction):
		_apply_velocity_brake(0.0, "reverse_brake", true, direction)
		return false
	var boost_extra_demand: float = maxf(0.0, float(stats.get("thruster_boost_extra_demand", 0.0)))
	var boost_total_momentum: float = maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var boost_speed: float = maxf(0.0, float(stats.get("boost_speed", 0.0)))
	var boost_duration := maxf(0.0, float(stats.get("boost_duration", 0.0)))
	if boost_extra_demand <= 0.0 or boost_duration <= 0.0 or (boost_total_momentum <= 0.0 and boost_speed <= 0.0):
		return false
	var boost_dir := _thruster_boost_direction(direction)
	if boost_dir.length() <= 0.04:
		_apply_velocity_brake(0.0, "unusable_boost_angle", true, direction)
		return false
	boost_dir = boost_dir.normalized()
	var recovery_return := recovery_boost_timer > 0.0 and velocity.length() > 0.08 and boost_dir.dot(-velocity.normalized()) > 0.18
	var thruster_family := String(stats.get("thruster_family", "")).to_lower()
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	var max_delta_v := boost_total_momentum / mass
	if boost_speed > 0.0:
		max_delta_v = maxf(max_delta_v, boost_speed - maxf(0.0, velocity.dot(boost_dir)))
	if recovery_return:
		var recovery_response := _recovery_response_multiplier()
		max_delta_v *= 1.08 + recovery_response * 0.22
		body_sway_velocity += boost_dir * 18.0 * _impulse_response_multiplier()
		body_swing_velocity -= _side_vector().dot(boost_dir) * 0.72 * _impulse_response_multiplier()
	elif recovery_boost_timer > 0.0:
		max_delta_v *= clampf(0.82 + _recovery_response_multiplier() * 0.18, 0.72, 1.16)
	if max_delta_v <= 0.001:
		return false
	boost_duration = maxf(0.04, boost_duration)
	boost_drive_direction = boost_dir
	boost_drive_duration = boost_duration
	boost_drive_timer = boost_duration
	boost_drive_velocity_remaining = boost_dir * max_delta_v
	var flash_duration := 0.34 if recovery_return else 0.18
	if thruster_family == "overburn_red":
		flash_duration += 0.12
	flash_duration = maxf(flash_duration, boost_duration)
	boost_flash_timer = maxf(boost_flash_timer, flash_duration)
	thruster_visual_timer = maxf(thruster_visual_timer, flash_duration)
	thruster_output_direction = boost_dir
	add_heat(maxf(0.0, float(stats.get("boost_heat", 0.0))), "heat:boost")
	moved_this_frame = true
	boost_cooldown_timer = maxf(boost_cooldown_timer, maxf(0.0, float(stats.get("boost_cooldown", BOOST_COOLDOWN_DEFAULT))))
	_refresh_visuals()
	return true


func trigger_overheat_shutdown(reason: String = "") -> void:
	if not _uses_heat_resource():
		return
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	heat = heat_capacity
	overheated = true
	var shutdown_mult := clampf(float(stats.get("overheat_shutdown_mult", 1.0)), 0.35, 1.0)
	forced_cooling_timer = maxf(forced_cooling_timer, float(stats.get("overheat_shutdown_seconds", 0.3)) * shutdown_mult)
	cooling_lock_timer = maxf(cooling_lock_timer, forced_cooling_timer)
	action_cooldown = maxf(action_cooldown, forced_cooling_timer)
	current_state = STATE_NORMAL
	state_timer = 0.0
	manual_cooling = true
	smoke_timer = maxf(smoke_timer, forced_cooling_timer + 0.12)
	velocity *= 0.82


func add_heat(amount: float, reason: String = "") -> void:
	if not _uses_heat_resource() or amount <= 0.0:
		return
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	heat = clampf(heat + _heat_amount_after_cooling_relief(amount, reason), 0.0, heat_capacity)
	if heat >= heat_capacity:
		trigger_overheat_shutdown(reason)


func _overheat_clear_ratio() -> float:
	return clampf(float(stats.get("overheat_clear_ratio", 0.42)), 0.3, 0.62)


func _runtime_cooling_rate() -> float:
	var rate := maxf(0.0, float(stats.get("cooling_rate", stats.get("cooling", 12.0))))
	rate = maxf(rate, float(stats.get("cooling", 0.0)))
	rate = maxf(rate, float(stats.get("thermal_dissipation_rate", 0.0)))
	rate = maxf(rate, float(stats.get("heat_dissipation", 0.0)))
	rate = maxf(rate, float(stats.get("runtime_cooling_rate", 0.0)))
	return rate


func _heat_amount_after_cooling_relief(amount: float, reason: String) -> float:
	var relief := 0.0
	for tag in _canonical_heat_tags_for_reason(reason):
		match String(tag):
			"boost":
				relief = maxf(relief, float(stats.get("boost_heat_relief", 0.0)))
			"repeat":
				relief = maxf(relief, float(stats.get("repeat_heat_relief", 0.0)))
			"projectile":
				relief = maxf(relief, float(stats.get("projectile_heat_relief", 0.0)))
			"laser":
				relief = maxf(relief, float(stats.get("laser_heat_relief", 0.0)))
			"chemical":
				relief = maxf(relief, float(stats.get("chemical_heat_relief", 0.0)))
			"missile":
				relief = maxf(relief, float(stats.get("missile_heat_relief", 0.0)))
	return amount * (1.0 - clampf(relief, 0.0, 0.72))


func _canonical_heat_tags_for_reason(reason: String) -> Array:
	var tags: Array = []
	var reason_key := reason.to_lower()
	var explicit_text := reason_key.replace(",", " ").replace(";", " ").replace("|", " ")
	for token in explicit_text.split(" ", false):
		var token_text := String(token).strip_edges()
		if token_text.begins_with(HEAT_TAG_PREFIX):
			_append_heat_tag(tags, token_text.substr(HEAT_TAG_PREFIX.length()))
		elif token_text.begins_with(HEAT_TAG_EVENT_PREFIX):
			_append_heat_tag(tags, token_text.substr(HEAT_TAG_EVENT_PREFIX.length()))
	if reason_key.contains("boost"):
		_append_heat_tag(tags, "boost")
	if reason_key.contains("gauntlet") or reason_key.contains("blade") or reason_key.contains("blunt") or reason_key.contains("combo") or reason_key.contains("module"):
		_append_heat_tag(tags, "repeat")
	if reason_key.contains("projectile") or reason_key.contains("gun") or reason_key.contains("ammo") or reason_key.contains("external heat"):
		_append_heat_tag(tags, "projectile")
	if reason_key.contains("laser"):
		_append_heat_tag(tags, "laser")
	if reason_key.contains("chemical"):
		_append_heat_tag(tags, "chemical")
	if reason_key.contains("missile") or reason_key.contains("explosive"):
		_append_heat_tag(tags, "missile")
	return tags


func _append_heat_tag(tags: Array, raw_tag: String) -> void:
	var tag := raw_tag.strip_edges().to_lower()
	if tag == "":
		return
	match tag:
		"gauntlet", "blade", "blunt", "combo", "module", "melee":
			tag = "repeat"
		"gun", "ammo", "bullet", "true_bullet", "bullet_hell", "web":
			tag = "projectile"
		"explosive", "grenade":
			tag = "missile"
	if tag == "laser" or tag == "chemical" or tag == "missile":
		if not tags.has("projectile"):
			tags.append("projectile")
	if not tags.has(tag):
		tags.append(tag)


func _is_straight_inertial_cooling() -> bool:
	if not _uses_heat_resource():
		return false
	if forced_cooling_timer > 0.0 or manual_cooling:
		return false
	if current_state != STATE_NORMAL or action_cooldown > 0.0:
		return false
	if velocity.length() < 0.42:
		return false
	if absf(angular_velocity) > 0.18:
		return false
	if moved_this_frame:
		var drive := thruster_output_direction.normalized() if thruster_output_direction.length() > 0.01 else Vector2.ZERO
		return drive.length() > 0.0 and drive.dot(velocity.normalized()) > 0.94
	return true


func apply_physics_impulse(direction: Vector2, impulse: float, part_index: int = -1, torque_hint: float = 0.0) -> void:
	if not active or direction.length() <= 0.01 or impulse <= 0.0:
		return
	var dir := direction.normalized()
	var mass_scale := 1.0 / sqrt(maxf(1.0, float(stats.get("mass", 1.0))))
	var response := _impulse_response_multiplier()
	var side_torque := _forward_vector().cross(dir)
	if absf(side_torque) < 0.05:
		side_torque = _side_vector().dot(dir)
	side_torque += torque_hint
	var swing_impulse := clampf(side_torque * impulse * mass_scale * 2.7 * response, -2.6, 2.6)
	body_swing_velocity += swing_impulse
	body_sway_velocity += dir * clampf(impulse * 30.0 * mass_scale * response, 2.0, 48.0)
	recovery_boost_timer = maxf(recovery_boost_timer, 1.2 * _recovery_linger_multiplier())
	boost_flash_timer = maxf(boost_flash_timer, 0.1)

	if part_index < 0:
		return
	_ensure_limb_index(part_index)
	var limb_push := dir * clampf(impulse * 0.18 * mass_scale * response, 0.014, 0.38)
	limb_linear_velocities[part_index] = Vector2(limb_linear_velocities[part_index]) + limb_push
	limb_swing_velocities[part_index] = float(limb_swing_velocities[part_index]) + clampf(side_torque * impulse * mass_scale * 6.4 * response, -8.2, 8.2)
	for neighbor in [part_index - 1, part_index + 1]:
		if neighbor < 0:
			continue
		_ensure_limb_index(neighbor)
		limb_linear_velocities[neighbor] = Vector2(limb_linear_velocities[neighbor]) + limb_push * 0.34
		limb_swing_velocities[neighbor] = float(limb_swing_velocities[neighbor]) + clampf(side_torque * impulse * mass_scale * 2.2 * response, -2.8, 2.8)


func _available_attack_reaction_cancel_momentum(countered: bool) -> float:
	var boost_momentum := maxf(0.0, float(stats.get("boost_momentum", 0.0)))
	var reaction_cancel := float(stats.get("reaction_cancel", 0.0))
	var cancel_mult := clampf(reaction_cancel * 0.52 + _attitude_stabilization() * 0.16, 0.0, 0.84)
	if countered:
		cancel_mult = maxf(cancel_mult, clampf(float(stats.get("reaction_cancel", 0.0)), 0.0, 0.92))
	return boost_momentum * cancel_mult


func apply_attack_reaction(direction: Vector2, velocity_impulse: float, part_index: int = -1, countered: bool = false) -> float:
	if not active or direction.length() <= 0.01 or velocity_impulse <= 0.0:
		return 0.0
	var dir := direction.normalized()
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	var reaction_momentum := velocity_impulse * mass
	var canceled_momentum := minf(reaction_momentum, _available_attack_reaction_cancel_momentum(countered))
	var residual_momentum := maxf(0.0, reaction_momentum - canceled_momentum)
	var residual_velocity := residual_momentum / mass
	var cancel_ratio := 0.0 if reaction_momentum <= 0.001 else canceled_momentum / reaction_momentum
	if residual_velocity > 0.0001:
		velocity += dir * residual_velocity
	var response := _impulse_response_multiplier()
	body_sway_velocity += dir * residual_velocity * 10.0 * response
	body_swing_velocity -= _side_vector().dot(dir) * residual_velocity * 0.52 * response
	recovery_boost_timer = maxf(recovery_boost_timer, (0.34 + residual_velocity * 0.8) * _recovery_linger_multiplier())
	if cancel_ratio > 0.02:
		thruster_output_direction = -dir
		thruster_visual_timer = maxf(thruster_visual_timer, 0.1 + cancel_ratio * 0.18)
		boost_flash_timer = maxf(boost_flash_timer, 0.08 + cancel_ratio * 0.1)
	if part_index >= 0:
		_ensure_limb_index(part_index)
		limb_linear_velocities[part_index] = Vector2(limb_linear_velocities[part_index]) + dir * residual_velocity * 0.08
	last_action_direction = -dir
	return residual_velocity


func apply_recoil(direction: Vector2, amount: float, countered: bool) -> void:
	if not active or direction.length() < 0.1:
		return
	var dir := direction.normalized()
	apply_attack_reaction(-dir, amount, -1, countered)
	last_action_direction = dir


func apply_projectile_recoil(projectile_direction: Vector2, projectile_momentum: float) -> void:
	if not active or projectile_direction.length() < 0.1 or projectile_momentum <= 0.0:
		return
	var dir := projectile_direction.normalized()
	var mass := maxf(1.0, float(stats.get("mass", 1.0)))
	var recoil_velocity := projectile_momentum / mass
	if recoil_velocity <= 0.0001:
		return
	velocity -= dir * recoil_velocity
	last_action_direction = dir
	request_collision_auto_brake()
	thruster_output_direction = dir
	thruster_visual_timer = maxf(thruster_visual_timer, 0.12)


func apply_melee_stagger(duration: float, momentum_gap: float = 0.0, stability_threshold: float = 0.0) -> void:
	if not active or duration <= 0.0:
		return
	var scaled_duration := duration / _recovery_response_multiplier()
	melee_stagger_timer = maxf(melee_stagger_timer, scaled_duration)
	set_meta("melee_stagger_timer", melee_stagger_timer)
	set_meta("last_melee_stagger_gap", momentum_gap)
	set_meta("last_melee_stability_threshold", stability_threshold)
	action_cooldown = maxf(action_cooldown, scaled_duration)
	current_state = STATE_NORMAL
	state_timer = 0.0
	recovery_boost_timer = maxf(recovery_boost_timer, scaled_duration + 0.42)
	body_sway_velocity += velocity.normalized() * clampf(momentum_gap * 0.018, 0.0, 18.0) * _impulse_response_multiplier() if velocity.length() > 0.01 else Vector2.ZERO
	boost_flash_timer = maxf(boost_flash_timer, 0.08)


func melee_stagger_ratio() -> float:
	return clampf(melee_stagger_timer / 0.72, 0.0, 1.0)


func try_cancel(input_vector: Vector2, delta: float) -> void:
	if action_cooldown <= 0.0 or input_vector.length() < 0.2 or last_action_direction.length() < 0.1:
		return
	var profile := String(stats.get("cancel_profile", "none"))
	if profile == "none":
		return
	var dot_value := input_vector.normalized().dot(last_action_direction.normalized())
	var allowed := false
	if profile == "reverse":
		allowed = dot_value < -0.55
	elif profile == "bidirectional":
		allowed = absf(dot_value) > 0.55
	elif profile == "retract":
		allowed = dot_value < -0.25
	if not allowed:
		return
	var cancel_power: float = float(stats.get("cancel_power", 0.0))
	action_cooldown = maxf(0.0, action_cooldown - cancel_power * delta)
	velocity += Vector2(input_vector.normalized().x, input_vector.normalized().y * 0.5) * cancel_power * delta


func take_hit(damage: int, source_state: String, attacker_owner: int, damage_type: String = "blunt", attacker_material_class: String = "weapon") -> bool:
	if not active or health <= 0:
		return false

	var final_damage := damage
	var counter_tiers: Dictionary = stats.get("counter_tiers", {})
	var projectile_damage := damage_type in PROJECTILE_DAMAGE_TYPES
	var counter_tier := 0 if projectile_damage else int(counter_tiers.get(damage_type, 0))
	final_damage = int(roundf(float(final_damage) * pow(0.8, float(counter_tier))))
	if not projectile_damage:
		var resistances: Dictionary = stats.get("resistances", {})
		final_damage = int(roundf(float(final_damage) * float(resistances.get(damage_type, 1.0))))
	if final_damage <= 0:
		state_timer = maxf(state_timer, 0.05)
		_refresh_visuals()
		return false
	final_damage = max(1, final_damage)
	if overheated and role == "hero":
		final_damage = max(1, int(roundf(float(final_damage) * 1.15)))
	final_damage = _apply_electronic_armor_absorb(final_damage, damage_type)
	if final_damage <= 0:
		state_timer = maxf(state_timer, 0.06)
		_refresh_visuals()
		return false
	if final_damage > 0 and float(get_meta("support_armor_timer", 0.0)) > 0.0 and float(get_meta("support_armor_hp", 0.0)) > 0.0:
		var armor_hp := float(get_meta("support_armor_hp", 0.0))
		var armor_result := _armor_absorb_result(final_damage, armor_hp, damage_type)
		armor_hp = float(armor_result.get("armor_hp", 0.0))
		set_meta("support_armor_hp", armor_hp)
		final_damage = int(armor_result.get("damage", final_damage))
		state_timer = maxf(state_timer, 0.06)
		if final_damage <= 0:
			_refresh_visuals()
			return false

	health = max(0, health - final_damage)
	state_timer = maxf(state_timer, 0.08)
	recovery_boost_timer = maxf(recovery_boost_timer, clampf(0.18 + float(final_damage) * 0.006, 0.22, 0.95) * _recovery_linger_multiplier())
	if health <= 0:
		active = false
		visible = false
		knocked_out.emit(self)
		return true

	_refresh_visuals()
	return false


func health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return clampf(float(health) / float(max_health), 0.0, 1.0)


func shield_value() -> float:
	return clampf(float(get_meta("shield_hp", get_meta("electronic_armor_hp", 0.0))), 0.0, shield_max_value())


func shield_max_value() -> float:
	return maxf(0.0, float(get_meta("shield_max", get_meta("electronic_armor_max", stats.get("electronic_armor_max", 0.0)))))


func shield_ratio() -> float:
	var shield_max := shield_max_value()
	if shield_max <= 0.0:
		return 0.0
	var display_span := maxf(float(max_health), shield_max)
	return clampf(shield_value() / maxf(1.0, display_span), 0.0, 1.0)


func _uses_heat_resource() -> bool:
	return role == "hero"


func _is_training_ball_dummy() -> bool:
	return bool(stats.get("training_ball_dummy", false)) or bool(get_meta("training_ball_dummy", false))


func _training_ball_dummy_collider() -> Dictionary:
	var radius := clampf(float(stats.get("radius", 0.6)), 0.04, 3.2)
	var mass := maxf(0.1, float(stats.get("mass", 1.0)))
	return {
		"shape": "circle",
		"part_kind": "torso",
		"part_index": -1,
		"node_index": 0,
		"name": String(stats.get("name", "TRAINING BALL")),
		"center": _runtime_combat_origin(),
		"radius": radius,
		"mass": mass,
		"material_class": "training_dummy",
		"damage_type": "blunt",
		"contact_damage": 0.0,
		"contact_damage_mult": 0.0,
		"damage_coeff": 0.0,
		"break_coeff": 0.0,
		"stiffness_momentum": maxf(1.0, float(stats.get("stiffness_momentum", mass * 18.0))),
		"path_stiffness_momentum": maxf(1.0, float(stats.get("path_stiffness_momentum", mass * 18.0))),
	}


func heat_ratio() -> float:
	if not _uses_heat_resource():
		return 0.0
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	return clampf(heat / heat_capacity, 0.0, 1.0)


func set_screen_position(screen_position: Vector2, is_visible_in_view: bool) -> void:
	visual_hitbox_scale = 1.0
	mobius_visual_scale = 1.0
	mobius_visual_scale_target = 1.0
	mobius_visual_scale_initialized = false
	scale = Vector2.ONE
	position = screen_position if _is_teamedit_runtime_unit() else screen_position + body_sway_offset
	set_meta("last_projection_visible", is_visible_in_view)
	set_meta("projection_guarded", false)
	set_meta("last_screen_position", screen_position)
	visible = active and is_visible_in_view


func set_mobius_screen_projection(projection: Dictionary, is_visible_in_view: bool) -> void:
	var screen_position: Vector2 = projection.get("position", position)
	var projection_visible := bool(projection.get("visible", is_visible_in_view))
	var projection_guarded := bool(projection.get("guarded", false))
	mobius_depth01 = clampf(float(projection.get("depth01", mobius_depth01)), 0.0, 1.0)
	var target_scale := maxf(MOBIUS_VISUAL_SCALE_MIN, float(projection.get("scale", 1.0)))
	mobius_visual_scale_target = target_scale
	if not mobius_visual_scale_initialized:
		mobius_visual_scale = target_scale
		mobius_visual_scale_initialized = true
	else:
		var scale_delta := target_scale - mobius_visual_scale
		var max_step: float = maxf(0.001, float(stats.get("mobius_visual_scale_max_step", MOBIUS_VISUAL_SCALE_MAX_STEP)))
		if absf(scale_delta) <= max_step:
			mobius_visual_scale = target_scale
		else:
			mobius_visual_scale += clampf(scale_delta, -max_step, max_step)
	visual_hitbox_scale = GameplayTransform.hitbox_scale_for_visual_scale(mobius_visual_scale)
	mobius_twist_angle = float(projection.get("twist_angle", mobius_twist_angle))
	position = screen_position if _is_teamedit_runtime_unit() else screen_position + body_sway_offset * mobius_visual_scale
	scale = Vector2.ONE * mobius_visual_scale
	set_meta("mobius_visual_scale_target", mobius_visual_scale_target)
	set_meta("mobius_visual_scale_applied", mobius_visual_scale)
	set_meta("last_projection_visible", projection_visible)
	set_meta("projection_guarded", projection_guarded)
	set_meta("projection_source", String(projection.get("projection_source", "mobius")))
	set_meta("last_screen_position", screen_position)
	z_index = int(projection.get("z_index", 0))
	visible = active and (is_visible_in_view or projection_guarded)


func _is_teamedit_runtime_unit() -> bool:
	return bool(stats.get("teamedit_runtime_topology", false))


func _runtime_visual_scale() -> float:
	return maxf(1.0, float(stats.get("runtime_visual_scale", PART_VISUAL_SCALE)))


func _runtime_state_flash_polygon() -> PackedVector2Array:
	var visual_scale := _runtime_visual_scale()
	var len := maxf(0.8, float(stats.get("length", 1.1)) * visual_scale)
	var rad := maxf(0.42, float(stats.get("radius", 0.28)) * visual_scale * 2.2)
	return PackedVector2Array([
		Vector2(-len * 0.55, -rad),
		Vector2(len * 0.45, -rad * 0.78),
		Vector2(len * 0.58, 0.0),
		Vector2(len * 0.45, rad * 0.78),
		Vector2(-len * 0.55, rad),
		Vector2(-len * 0.72, 0.0),
	])


func _draw_training_ball_dummy() -> void:
	var radius := clampf(float(stats.get("radius", 0.6)), 0.04, 3.2)
	var visual_radius := clampf(radius * PART_VISUAL_SCALE, 12.0, 190.0)
	var base := primary_color.lerp(Color(0.42, 0.62, 0.78, 1.0), 0.28)
	var edge := accent_color.lerp(Color.WHITE, 0.18)
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.0018) * 0.5
	draw_circle(Vector2.ZERO, visual_radius, Color(base.r, base.g, base.b, 0.72))
	draw_circle(Vector2(-visual_radius * 0.24, -visual_radius * 0.28), visual_radius * 0.36, Color(1.0, 1.0, 1.0, 0.10 + pulse * 0.04))
	draw_arc(Vector2.ZERO, visual_radius, 0.0, TAU, 64, Color(edge.r, edge.g, edge.b, 0.92), 2.4)
	draw_arc(Vector2.ZERO, visual_radius * 0.68, -PI * 0.88, PI * 0.88, 48, Color(edge.r, edge.g, edge.b, 0.36), 1.5)
	draw_arc(Vector2.ZERO, visual_radius * 0.38, -PI * 0.92, PI * 0.92, 36, Color(edge.r, edge.g, edge.b, 0.22), 1.1)
	draw_line(Vector2(-visual_radius * 0.94, 0.0), Vector2(visual_radius * 0.94, 0.0), Color(1.0, 1.0, 1.0, 0.12), 1.0)
	draw_line(Vector2(0.0, -visual_radius * 0.88), Vector2(0.0, visual_radius * 0.88), Color(1.0, 1.0, 1.0, 0.08), 1.0)


func _build_visuals() -> void:
	state_flash = _make_poly("StateFlash", [], Color(1.0, 1.0, 1.0, 0.3))
	smoke_cloud = _make_poly("CoolingSmoke", [], Color(0.76, 0.8, 0.78, 0.32))
	boost_flash = _make_poly("BoostFlash", [], Color(1.0, 0.55, 0.15, 0.4))
	boost_flash.z_index = -5
	for i in range(4):
		var flame := _make_poly("ThrusterFlame%d" % i, [], Color(1.0, 0.48, 0.08, 0.48))
		flame.z_index = -6
		thruster_flames.append(flame)
	for i in range(MAX_PART_VISUAL_LINES):
		var barrier_line := _make_line("BarrierTileVisual%d" % i, 10.0, Color(0.58, 0.96, 1.0, 0.96))
		barrier_tile_lines.append(barrier_line)
	heat_bar_back = _make_poly("HeatBack", [], Color(0.02, 0.02, 0.02, 0.65))
	heat_bar_fill = _make_poly("HeatFill", [], Color(1.0, 0.35, 0.14, 0.9))
	state_flash.visible = false
	smoke_cloud.visible = false
	boost_flash.visible = false
	for flame in thruster_flames:
		flame.visible = false
	for line in barrier_tile_lines:
		line.visible = false

func _refresh_visuals() -> void:

	if _is_teamedit_runtime_unit():
		scale = Vector2.ONE
		rotation = 0.0
		var runtime_material_color := _team_material_color()
		state_flash.visible = false
		_refresh_part_visuals(runtime_material_color)
		smoke_cloud.visible = smoke_timer > 0.0
		_refresh_thruster_flames()
		_set_heat_fill()
		return

	_refresh_part_visuals(_team_material_color())
	state_flash.visible = false
	smoke_cloud.visible = smoke_timer > 0.0
	_refresh_thruster_flames()
	_set_heat_fill()


func _refresh_thruster_flames() -> void:
	if boost_flash == null:
		return
	var speed := velocity.length()
	var move_ratio := clampf(speed / 2.2, 0.0, 1.0)
	var boost_ratio := clampf(boost_flash_timer / 0.34, 0.0, 1.0)
	var thrust_ratio := clampf(thruster_visual_timer / 0.2, 0.0, 1.0)
	var intensity := maxf(boost_ratio, thrust_ratio * 0.82)
	var thrust_direction := thruster_output_direction
	if thrust_direction.length() <= 0.001:
		thrust_direction = _forward_vector()
	var local_thrust := thrust_direction.normalized().rotated(-rotation)
	if local_thrust.length() <= 0.001:
		local_thrust = _forward_vector().rotated(-rotation)
	local_thrust = local_thrust.normalized()
	var flame_dir := -local_thrust
	var lateral := Vector2(-flame_dir.y, flame_dir.x)
	var body_length: float = clampf(float(stats.get("length", 1.0)), 0.12, 4.5)
	var body_radius: float = clampf(float(stats.get("radius", 0.28)), 0.04, 3.2)
	var rear_distance := maxf(18.0, body_length * PART_VISUAL_SCALE * (0.42 if role == "barrier" else 0.34))
	var nozzle_span := clampf(body_radius * PART_VISUAL_SCALE * 0.88, 8.0, 82.0)
	var nozzle_count := clampi(2 + int(round(body_radius * 1.2)), 2, thruster_flames.size())
	if intensity <= 0.035:
		boost_flash.visible = false
		for flame in thruster_flames:
			flame.visible = false
		return

	var tick := Time.get_ticks_msec() * 0.001
	for i in range(thruster_flames.size()):
		var flame: Polygon2D = thruster_flames[i]
		if i >= nozzle_count:
			flame.visible = false
			continue
		var lane_t := 0.0 if nozzle_count <= 1 else (float(i) / float(nozzle_count - 1) - 0.5)
		var base := -local_thrust * rear_distance + lateral * lane_t * nozzle_span
		var jitter := sin(tick * (18.0 + float(i) * 3.1) + float(i) * 1.7)
		var flame_len := (18.0 + move_ratio * 16.0 + thrust_ratio * 34.0 + boost_ratio * 70.0) * (0.82 + float(i % 2) * 0.12 + jitter * 0.08)
		var flame_width := clampf(4.5 + body_radius * PART_VISUAL_SCALE * 0.12, 5.0, 24.0) * (0.82 + boost_ratio * 0.46)
		var tip := base + flame_dir * flame_len + lateral * jitter * flame_width * 0.48
		flame.polygon = PackedVector2Array([
			base + lateral * flame_width,
			base - lateral * flame_width,
			tip,
		])
		var edge_heat := clampf(intensity + float(i) * 0.08, 0.0, 1.0)
		flame.color = _thruster_flame_color(0.28 + 0.48 * intensity, edge_heat)
		flame.visible = true

	boost_flash.visible = boost_ratio > 0.02
	if boost_flash.visible:
		var flash_width := maxf(nozzle_span * 0.78, 18.0)
		var flash_len := 38.0 + boost_ratio * 86.0
		var base_center := -local_thrust * (rear_distance + 4.0)
		boost_flash.polygon = PackedVector2Array([
			base_center + lateral * flash_width,
			base_center - lateral * flash_width,
			base_center + flame_dir * flash_len,
		])
		boost_flash.rotation = 0.0
		boost_flash.color = _thruster_flame_color(0.18 + boost_ratio * 0.4, 1.0)


func _thruster_flame_color(alpha: float, heat_ratio_hint: float = 1.0) -> Color:
	var flame := String(stats.get("flame_color", "")).to_lower()
	var style := String(stats.get("thruster_family", "")).to_lower()
	var color := Color(0.42, 0.88, 1.0, alpha)
	if flame.contains("yellow") or style.contains("sustain"):
		color = Color(1.0, 0.78 + 0.1 * heat_ratio_hint, 0.14, alpha)
	elif flame.contains("red") or style.contains("overburn") or style.contains("burst"):
		color = Color(1.0, 0.22 + 0.14 * heat_ratio_hint, 0.04, alpha)
	return color


func _refresh_part_visuals(material_color: Color) -> void:
	if _is_training_ball_dummy():
		for line in barrier_tile_lines:
			line.visible = false
		queue_redraw()
		return
	if _has_barrier_tiles():
		_refresh_barrier_tile_visuals(material_color)
		return
	if _is_teamedit_runtime_unit():
		for line in barrier_tile_lines:
			line.visible = false
		var redraw_key := _runtime_visual_redraw_signature()
		if redraw_key != runtime_geometry_visual_redraw_key:
			runtime_geometry_visual_redraw_key = redraw_key
			queue_redraw()
		return
	for line in barrier_tile_lines:
		line.visible = false
	return


func _refresh_barrier_tile_visuals(material_color: Color) -> void:
	for line in barrier_tile_lines:
		line.visible = false
	var center := Vector2(ring_pos, lane)
	var draw_index := 0
	var tick := Time.get_ticks_msec() * 0.001
	for raw_tile in Array(stats.get("barrier_map_tiles", [])):
		if draw_index >= barrier_tile_lines.size():
			break
		if not (raw_tile is Dictionary):
			continue
		var tile: Dictionary = raw_tile
		var line: Line2D = barrier_tile_lines[draw_index]
		var collider := _barrier_tile_collider(tile)
		var local_a := Vector2.ZERO
		var local_b := Vector2.ZERO
		var radius := float(collider.get("radius", tile.get("radius", 0.08)))
		if String(collider.get("shape", "capsule")) == "circle":
			var circle_center: Vector2 = collider.get("center", center)
			var pulse := sin(tick * 2.2 + float(draw_index) * 0.73) * 0.08
			local_a = (circle_center - center + Vector2(-radius * (0.72 + pulse), 0.0)) * PART_VISUAL_SCALE
			local_b = (circle_center - center + Vector2(radius * (0.72 + pulse), 0.0)) * PART_VISUAL_SCALE
		else:
			var segment_a: Vector2 = collider.get("a", center)
			var segment_b: Vector2 = collider.get("b", center)
			local_a = (segment_a - center) * PART_VISUAL_SCALE
			local_b = (segment_b - center) * PART_VISUAL_SCALE
		line.points = PackedVector2Array([local_a, local_b])
		line.width = clampf(radius * PART_VISUAL_SCALE * 2.45 * BODY_COLLIDER_EXPAND, 11.0, 96.0)
		line.default_color = _barrier_tile_color(tile, material_color)
		line.visible = true
		draw_index += 1


func _barrier_tile_color(tile: Dictionary, material_color: Color) -> Color:
	var material_class := String(tile.get("material_class", "barrier_wall"))
	var damage_type := String(tile.get("damage_type", "blunt"))
	var base := material_color.lerp(accent_color, 0.34)
	if material_class == "barrier_cache":
		base = Color(1.0, 0.86, 0.28, 0.98)
	elif material_class == "one_way_shield":
		base = Color(0.66, 0.96, 1.0, 0.96)
	elif material_class == "gravity_field":
		base = Color(0.78, 0.58, 1.0, 0.96)
	elif material_class == "coolant_field":
		base = Color(0.62, 1.0, 0.9, 0.98)
	elif material_class == "heat_field":
		base = Color(1.0, 0.42, 0.14, 0.97)
	elif damage_type == "laser":
		base = Color(0.56, 0.94, 1.0, 0.96)
	elif damage_type == "chemical":
		base = Color(0.72, 1.0, 0.32, 0.96)
	else:
		base = base.lerp(Color.WHITE, 0.16)
		base.a = maxf(base.a, 0.94)
	return base


func _group_is_ranged_weapon(group: Dictionary) -> bool:
	var material_class := String(group.get("material_class", ""))
	return bool(group.get("projectile", false)) or material_class in ["gun", "missile_launcher"]


func _team_material_color() -> Color:
	var material_class := String(stats.get("material_class", "weapon"))
	var base := primary_color
	if material_class in ["wood", "barrier_cache"]:
		base = primary_color.lerp(Color(0.72, 0.58, 0.36, 1.0), 0.34)
	elif material_class in ["gun", "ammo_payload"]:
		base = primary_color.lerp(accent_color, 0.52)
	elif material_class == "torso":
		base = primary_color.lerp(Color.WHITE, 0.1)
	elif material_class in ["barrier_wall", "one_way_shield", "gravity_field"]:
		base = primary_color.lerp(accent_color, 0.28)
	elif material_class in ["coolant_field", "support_node", "support_platform"]:
		base = primary_color.lerp(Color(0.82, 0.96, 0.92, 1.0), 0.2)
	elif material_class in ["heat_field", "resource_siphon", "trap_field"]:
		base = primary_color.lerp(accent_color, 0.34)
	else:
		base = primary_color.lerp(accent_color, 0.14)
	return base


func _apply_pseudo_3d_pose() -> void:
	if _is_teamedit_runtime_unit():
		scale = Vector2.ONE
		rotation = 0.0
		return
	if _has_barrier_tiles():
		scale = Vector2.ONE
		rotation = 0.0
		return
	var depth_scale := 1.0 + clampf(lane / BATTLE_HALF_HEIGHT, -1.0, 1.0) * 0.035
	var speed_lift := clampf(velocity.length() * 0.045, 0.0, 0.08)
	scale = Vector2(depth_scale + speed_lift, depth_scale + speed_lift)
	var target_rotation := clampf(velocity.y * 0.11 + velocity.x * 0.035, -0.22, 0.22)
	if role == "barrier":
		target_rotation *= 0.18
		scale = Vector2(1.0 + sin(Time.get_ticks_msec() * 0.0017) * 0.015, 0.94)
	rotation = lerpf(rotation, target_rotation, 0.16)


func _set_heat_fill() -> void:
	if heat_bar_fill == null or heat_bar_back == null:
		return
	var uses_heat := _uses_heat_resource()
	heat_bar_back.visible = uses_heat
	heat_bar_fill.visible = uses_heat
	if not uses_heat:
		return
	var heat_capacity: float = maxf(1.0, float(stats.get("heat_capacity", 100.0)))
	var ratio: float = clampf(heat / heat_capacity, 0.0, 1.0)
	var width: float = 76.0 * ratio
	var y_base: float = 48.0 * clampf(float(stats.get("radius", 0.28)), 0.08, 3.2) + 20.0
	heat_bar_fill.polygon = PackedVector2Array([
		Vector2(-38.0, y_base),
		Vector2(-38.0 + width, y_base),
		Vector2(-38.0 + width, y_base + 6.0),
		Vector2(-38.0, y_base + 6.0),
	])


func _make_poly(poly_name: String, points: Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = poly_name
	poly.polygon = PackedVector2Array(points)
	poly.color = color
	add_child(poly)
	return poly


func _make_line(line_name: String, line_width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = line_width
	line.default_color = color
	add_child(line)
	return line


