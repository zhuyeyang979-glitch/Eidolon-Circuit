extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit() -> Node:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "WEB_SWING_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"mass": 40.0,
			"health": 100,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [],
			"runtime_module_bindings": [],
		},
	})
	fighter.deploy(4.0, 4.2)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = _make_unit()
	var hp_before := int(unit.health)
	var event := {
		"projectile": true,
		"projectile_only": true,
		"muscle_node": 0,
		"collision_group": {"projectile": true, "projectile_only": true, "material_class": "web_gun", "shape": "web_gun"},
		"direction": Vector2.DOWN,
		"range": MainScene.STANDARD_WEB_TETHER_RANGE_M,
		"projectile_style": "web",
		"travel_path": "tether",
		"web_strength": MainScene.STANDARD_WEB_TETHER_STRENGTH,
		"web_break_force": 999.0,
		"web_duration": MainScene.STANDARD_WEB_TETHER_DURATION,
		"web_anchor_swing": true,
	}
	var anchor: Dictionary = main._web_boundary_anchor_for_event(unit, event)
	if anchor.is_empty():
		_fail("Boundary anchor unavailable for swing velocity probe.")
	main._start_web_boundary_swing(unit, event, anchor.get("position", Vector2.ZERO))
	main._update_web_swings(0.35)
	if unit.velocity.length() <= 0.001:
		_fail("Boundary web swing did not apply real velocity.")
	if int(unit.health) != hp_before:
		_fail("Web swing itself should not deal HP damage.")
	print("WEB_ANCHOR_SWING_VELOCITY_PROBE velocity=%.3f" % unit.velocity.length())
	quit()
