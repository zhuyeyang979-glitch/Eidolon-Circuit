extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 20,
			"mass": 12.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
			"move_speed": 4.0,
			"body_move_speed": 4.0,
			"move_acceleration": 20.0,
			"thruster_acceleration": 20.0,
			"movement_profile": "car",
			"heat_capacity": 40.0,
			"cooling": 20.0,
		},
	})
	unit.deploy(3.0, 0.0)
	unit.move_by(Vector2.DOWN, 0.25, MainScene.RING_LENGTH)
	if unit.velocity.y <= 0.001:
		_fail("Screen-down input should create positive vertical velocity even on runtime topology units.")
	unit.tick(0.25, MainScene.RING_LENGTH)
	if unit.mobius_v <= 0.001 or unit.lane <= 0.001:
		_fail("Vertical velocity should advance mobius_v and compatible lane.")
	var kept_v := float(unit.mobius_v)
	unit.lane = -2.0
	unit.tick(0.0, MainScene.RING_LENGTH)
	if absf(unit.mobius_v - kept_v) > 0.001:
		_fail("Per-frame compat sync must not overwrite authoritative mobius_v.")
	if absf(unit.lane - kept_v) > 0.001:
		_fail("Compatible lane should be projected back from mobius_v.")
	print("BATTLE_MOBIUS_VERTICAL_MOVEMENT_PROBE ok v=%.3f lane=%.3f" % [unit.mobius_v, unit.lane])
	quit()
