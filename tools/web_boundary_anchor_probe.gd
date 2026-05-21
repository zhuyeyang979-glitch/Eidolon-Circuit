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
		"unit_name": "WEB_ANCHOR_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {"mass": 40.0, "health": 100, "runtime_topology_segments": [], "runtime_module_bindings": []},
	})
	fighter.deploy(4.0, 1.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = _make_unit()
	var event := {"direction": Vector2.DOWN, "range": MainScene.STANDARD_WEB_TETHER_RANGE_M, "web_anchor_swing": true}
	var anchor: Dictionary = main._web_boundary_anchor_for_event(unit, event)
	if anchor.is_empty():
		_fail("Web did not anchor to the upper boundary within range.")
	var pos: Vector2 = anchor.get("position", Vector2.ZERO)
	if absf(pos.y - MainScene.BATTLE_HALF_HEIGHT) > 0.001:
		_fail("Upper boundary anchor has the wrong Y position.")
	var side_event := {"direction": Vector2.RIGHT, "range": MainScene.STANDARD_WEB_TETHER_RANGE_M, "web_anchor_swing": true}
	if not main._web_boundary_anchor_for_event(unit, side_event).is_empty():
		_fail("Left/right wrap edges must not provide web anchors.")
	print("WEB_BOUNDARY_ANCHOR_PROBE ok y=%.2f" % pos.y)
	quit()
