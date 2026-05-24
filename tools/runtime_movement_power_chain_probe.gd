extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Fighter := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_stats() -> Dictionary:
	return {
		"role": "hero",
		"mass": 20.0,
		"move_efficiency": 1.0,
		"boost_efficiency": 2.0,
		"turn_efficiency": 1.0,
		"brake_efficiency": 1.0,
		"boost_duration": 0.3,
		"speed_mult": 1.0,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legacy := _base_stats()
	legacy["thruster_allocated_momentum"] = 120.0
	legacy["allocated_momentum"] = 120.0
	legacy["boost_momentum"] = 60.0
	legacy["speed_limit"] = 99.0
	main._apply_engine_momentum_budget(legacy, "hero")
	main._apply_thruster_momentum_stats(legacy, "hero")
	if float(legacy.get("move_speed", 0.0)) > 0.001 or float(legacy.get("boost_speed", 0.0)) > 0.001:
		_fail("Legacy-only momentum fields should not produce runtime movement or Boost speed.")
	var full := _base_stats()
	full["thruster_drive_demand"] = 100.0
	full["thruster_boost_extra_demand"] = 50.0
	full["thruster_boost_peak_demand"] = 150.0
	full["engine_momentum_output"] = 200.0
	main._apply_engine_momentum_budget(full, "hero")
	main._apply_thruster_momentum_stats(full, "hero")
	if absf(float(full.get("engine_drive_chain_ratio", 0.0)) - 1.0) > 0.001:
		_fail("Sufficient engine should give full drive chain ratio.")
	if absf(float(full.get("move_speed", 0.0)) - 5.0) > 0.001:
		_fail("Move speed should derive from effective drive demand / mass.")
	if absf(float(full.get("boost_speed", 0.0)) - 15.0) > 0.001:
		_fail("Boost speed should derive from effective Boost peak demand / mass.")
	var starved := _base_stats()
	starved["thruster_drive_demand"] = 100.0
	starved["thruster_boost_extra_demand"] = 50.0
	starved["thruster_boost_peak_demand"] = 150.0
	starved["engine_momentum_output"] = 25.0
	main._apply_engine_momentum_budget(starved, "hero")
	main._apply_thruster_momentum_stats(starved, "hero")
	if float(starved.get("engine_drive_chain_ratio", 0.0)) >= 1.0:
		_fail("Insufficient engine should reduce drive chain ratio.")
	if float(starved.get("move_speed", 0.0)) >= float(full.get("move_speed", 0.0)):
		_fail("Insufficient engine should not grant free move speed.")
	if float(starved.get("boost_speed", 0.0)) >= float(full.get("boost_speed", 0.0)):
		_fail("Insufficient engine should not grant free Boost speed.")
	var fighter := Fighter.new()
	root.add_child(fighter)
	fighter.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "probe", "stats": legacy})
	fighter.deploy(0.0, 0.0)
	if fighter.boost(Vector2.RIGHT, 100.0):
		_fail("Fighter should not Boost from legacy boost_momentum alone.")
	var fighter_ok := Fighter.new()
	root.add_child(fighter_ok)
	fighter_ok.setup_unit({"owner_id": 1, "role": "hero", "unit_name": "probe2", "stats": full})
	fighter_ok.deploy(0.0, 0.0)
	if not fighter_ok.boost(Vector2.RIGHT, 100.0):
		_fail("Fighter should Boost from normalized power-chain stats.")
	print("RUNTIME_MOVEMENT_POWER_CHAIN_PROBE ok full_move=%.3f starved_move=%.3f" % [float(full.get("move_speed", 0.0)), float(starved.get("move_speed", 0.0))])
	quit()
