extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(extra_stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var stats := {
		"heat_capacity": 100.0,
		"cooling": 0.0,
		"boost_heat_relief": 0.0,
		"repeat_heat_relief": 0.0,
		"projectile_heat_relief": 0.0,
		"laser_heat_relief": 0.0,
		"chemical_heat_relief": 0.0,
		"missile_heat_relief": 0.0,
	}
	for key in extra_stats.keys():
		stats[key] = extra_stats[key]
	fighter.setup_unit({"unit_name": "HEAT_MATRIX", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _assert_heat(label: String, tags: Array, stats: Dictionary, expected: float) -> void:
	var fighter = _fighter(stats)
	fighter.add_heat_event(50.0, tags, label)
	if absf(float(fighter.heat) - expected) > 0.01:
		_fail("%s expected heat %.2f, got %.2f" % [label, expected, float(fighter.heat)])
	var event: Dictionary = fighter.get_meta("last_heat_event", {})
	var event_tags: Array = event.get("heat_event_tags", [])
	for tag in tags:
		if not event_tags.has(String(tag)):
			_fail("%s did not record canonical tag %s in %s" % [label, String(tag), str(event_tags)])


func _init() -> void:
	_assert_heat("boost", ["boost"], {"boost_heat_relief": 0.2, "projectile_heat_relief": 0.7}, 40.0)
	_assert_heat("repeat", ["repeat"], {"repeat_heat_relief": 0.3, "boost_heat_relief": 0.7}, 35.0)
	_assert_heat("projectile", ["projectile"], {"projectile_heat_relief": 0.4, "repeat_heat_relief": 0.7}, 30.0)
	_assert_heat("laser", ["projectile", "laser"], {"projectile_heat_relief": 0.1, "laser_heat_relief": 0.25}, 37.5)
	_assert_heat("chemical", ["projectile", "chemical"], {"projectile_heat_relief": 0.1, "chemical_heat_relief": 0.2}, 40.0)
	_assert_heat("missile", ["projectile", "missile"], {"projectile_heat_relief": 0.1, "missile_heat_relief": 0.22}, 39.0)
	_assert_heat("external", ["external"], {"projectile_heat_relief": 0.72, "laser_heat_relief": 0.72}, 50.0)
	if failed:
		quit(1)
		return
	print("HEAT_EVENT_TAG_MATRIX_PROBE ok")
	quit()
