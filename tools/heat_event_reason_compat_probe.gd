extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "HEAT_REASON", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var laser_event := {
		"projectile": true,
		"gun_kind": "laser_gun",
		"ammo_kind": "laser",
		"projectile_style": "beam",
		"projectile_behavior": "laser",
	}
	var reason := main._heat_reason_for_projectile_event(laser_event)
	if reason.find("heat:projectile") < 0 or reason.find("heat:laser") < 0:
		_fail("Projectile heat reason should preserve explicit canonical heat tags.")
	var canonical = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	canonical.add_heat_event(40.0, ["projectile", "laser"], "laser_probe")
	var compat = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	compat.add_heat(40.0, "projectile laser gun")
	if absf(float(canonical.heat) - float(compat.heat)) > 0.01:
		_fail("Legacy projectile laser reason should match canonical tags.")
	var explicit = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "chemical_heat_relief": 0.35})
	explicit.add_heat(40.0, "heat_event:chemical heat:projectile")
	if absf(float(explicit.heat) - 26.0) > 0.01:
		_fail("Explicit heat_event tags should apply strongest matching relief.")
	var external = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.72})
	external.add_heat(40.0, "external heat field")
	if absf(float(external.heat) - 40.0) > 0.01:
		_fail("External heat reason should not be treated as generic projectile heat.")
	if failed:
		quit(1)
		return
	print("HEAT_EVENT_REASON_COMPAT_PROBE ok canonical=%.1f compat=%.1f external=%.1f" % [float(canonical.heat), float(compat.heat), float(external.heat)])
	quit()
