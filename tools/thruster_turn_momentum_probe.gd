extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _stats_for_mass(mass: float) -> Dictionary:
	return {
		"mass": mass,
		"speed_mult": 1.0,
		"thruster_allocated_momentum": 96.0,
		"move_efficiency": 1.0,
		"turn_efficiency": 1.0,
		"boost_momentum": 192.0,
		"boost_duration": 0.3,
		"brake_efficiency": 1.0,
		"speed": 0.0,
	}


func _make_unit(stats: Dictionary):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit._ready()
	unit.setup_unit({
		"unit_name": "TURN_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": stats,
	})
	unit.deploy(1.0, 0.0)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var light := _stats_for_mass(12.0)
	var heavy := _stats_for_mass(48.0)
	main._apply_thruster_momentum_stats(light, "hero")
	main._apply_turn_stats(light, "hero")
	main._apply_thruster_momentum_stats(heavy, "hero")
	main._apply_turn_stats(heavy, "hero")
	if float(light.get("turn_speed", 0.0)) <= float(heavy.get("turn_speed", 0.0)):
		_fail("Same thruster momentum should turn the lighter mech faster.")
	if float(light.get("body_move_speed", 0.0)) <= float(heavy.get("body_move_speed", 0.0)):
		_fail("Same thruster momentum should move the lighter mech faster.")
	var expected_turn_accel := clampf(
		float(light.get("thruster_allocated_momentum", 0.0)) / maxf(1.0, float(light.get("mass", 1.0)))
		* MainScene.MOMENTUM_TURN_ACCEL_MULT
		* MainScene.MOMENTUM_TURN_MOMENTUM_MULT,
		0.0,
		40.8
	)
	if absf(float(light.get("turn_acceleration", 0.0)) - expected_turn_accel) > 0.01:
		_fail("Turn acceleration should use the current turning momentum coefficient.")
	var no_thruster := {"mass": 16.0, "speed": 3.0, "thruster_allocated_momentum": 0.0, "boost_momentum": 0.0}
	main._apply_thruster_momentum_stats(no_thruster, "hero")
	main._apply_turn_stats(no_thruster, "hero")
	if float(no_thruster.get("turn_speed", 0.0)) > 0.001 or float(no_thruster.get("body_move_speed", 0.0)) > 0.001:
		_fail("A mech without thruster momentum should not gain active move or turn speed.")
	var unit = _make_unit(no_thruster)
	var before_angle: float = unit.facing_angle
	unit.request_turn(1, 0.5)
	unit.tick(0.5, 24.0)
	if absf(unit.facing_angle - before_angle) > 0.001:
		_fail("request_turn should not rotate without thruster-derived turn speed.")
	if failed:
		quit(1)
		return
	print("THRUSTER_TURN_MOMENTUM_PROBE light_turn=%.3f heavy_turn=%.3f" % [float(light["turn_speed"]), float(heavy["turn_speed"])])
	quit()
