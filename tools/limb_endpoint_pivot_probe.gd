extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_close(label: String, actual: float, expected: float, tolerance: float = 0.006) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.4f got %.4f" % [label, expected, actual])


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	var root_pivot := Vector2(1.25, -0.5)
	var chain_spec := [
		{"part_kind": "joint", "radius": 0.0, "length": 0.0, "name": "SOFTWARE JOINT"},
		{"part_kind": "limb_muscle", "radius": 0.045, "length": 0.60, "name": "CONNECTOR"},
		{"part_kind": "terminal", "radius": 0.07, "length": 0.35, "name": "BLADE"},
	]
	var segments: Array = fighter._segments_from_limb_chain(0, {}, root_pivot, Vector2.RIGHT, chain_spec, false, 0.0)
	if segments.size() != 2:
		_fail("Expected connector + terminal segments, got %d." % segments.size())
	var connector: Dictionary = segments[0]
	var terminal: Dictionary = segments[1]
	var missing := Vector2(9999.0, 9999.0)
	var connector_start: Vector2 = connector.get("connection_start", missing)
	var connector_end: Vector2 = connector.get("connection_end", missing)
	var terminal_start: Vector2 = terminal.get("connection_start", missing)
	var terminal_tip: Vector2 = terminal.get("tip", missing)
	_assert_close("connector starts at logical joint endpoint", connector_start.distance_to(root_pivot), 0.0)
	_assert_close("connector rigid length", connector_start.distance_to(connector_end), 0.60)
	_assert_close("terminal socket starts at connector endpoint", terminal_start.distance_to(connector_end), 0.0)
	_assert_close("terminal functional tip radius", terminal_tip.distance_to(root_pivot), 0.95)
	_assert_close("connector center pivot radius", connector_start.lerp(connector_end, 0.5).distance_to(root_pivot), 0.30)
	if terminal.get("terminal_socket", missing) != terminal_start:
		_fail("Terminal segment did not expose its single connectable socket endpoint.")
	if terminal.get("terminal_tip", missing) != terminal_tip:
		_fail("Terminal segment did not expose its functional endpoint.")
	print("LIMB_ENDPOINT_PIVOT_PROBE connector=%.3f tip_radius=%.3f" % [
		connector_start.distance_to(connector_end),
		terminal_tip.distance_to(root_pivot),
	])
	quit()
