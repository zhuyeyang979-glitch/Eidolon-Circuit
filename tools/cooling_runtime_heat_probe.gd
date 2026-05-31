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
	fighter.setup_unit({"unit_name": "HEAT_TEST", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var plain = _fighter({"heat_capacity": 100.0, "cooling": 12.0})
	var laser = _fighter({"heat_capacity": 100.0, "cooling": 12.0, "laser_heat_relief": 0.25, "projectile_heat_relief": 0.1})
	var combo = _fighter({"heat_capacity": 100.0, "cooling": 12.0, "repeat_heat_relief": 0.2, "manual_cooling": 66.0, "overheat_clear_ratio": 0.48, "overheat_shutdown_mult": 0.7})
	plain.add_heat(40.0, "projectile laser gun")
	laser.add_heat(40.0, "projectile laser gun")
	if float(laser.heat) >= float(plain.heat):
		_fail("Laser relief should reduce laser projectile heat.")
	combo.add_heat(40.0, "gauntlet_special repeat module")
	if float(combo.heat) >= 40.0:
		_fail("Repeat relief should reduce module heat.")
	combo.trigger_overheat_shutdown("test")
	if combo.forced_cooling_timer > 0.22:
		_fail("Overheat shutdown multiplier should shorten forced cooling.")
	combo.manual_cool(2.0)
	if combo.overheated:
		_fail("High clear ratio and manual cooling should clear overheat in this controlled setup.")
	if failed:
		quit(1)
		return
	print("COOLING_RUNTIME_HEAT_PROBE ok plain=%.1f laser=%.1f combo=%.1f" % [float(plain.heat), float(laser.heat), float(combo.heat)])
	quit()
