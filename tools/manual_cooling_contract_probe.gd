extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "MANUAL_COOL", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var direct = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "manual_cooling": 20.0})
	direct.heat = 80.0
	direct.manual_cool(1.0)
	if absf(float(direct.heat) - 70.0) > 0.01:
		_fail("Manual cooling should immediately vent heat by manual_cooling.")
	var accelerated = _fighter({"heat_capacity": 100.0, "cooling": 10.0, "manual_cooling": 20.0})
	accelerated.heat = 80.0
	accelerated.manual_cool(1.0)
	accelerated.tick(1.0, 24.0)
	if float(accelerated.heat) > 54.1:
		_fail("Manual cooling should also apply the short accelerated cooling multiplier.")
	var passive = _fighter({"heat_capacity": 100.0, "cooling": 10.0, "manual_cooling": 20.0})
	passive.heat = 80.0
	passive.tick(1.0, 24.0)
	if float(passive.heat) - float(accelerated.heat) < 15.0:
		_fail("Manual cooling should be clearly stronger than passive idle cooling.")
	if failed:
		quit(1)
		return
	print("MANUAL_COOLING_CONTRACT_PROBE ok direct=%.1f accelerated=%.1f passive=%.1f" % [float(direct.heat), float(accelerated.heat), float(passive.heat)])
	quit()
