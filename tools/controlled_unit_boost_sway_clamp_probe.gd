extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 8.0,
			"move_acceleration": 70.0,
			"movement_profile": "vector",
			"boost_momentum": 240.0,
			"boost_speed": 20.0,
			"boost_duration": 0.22,
			"boost_cooldown": 0.5,
			"thruster_boost_extra_demand": 1.0,
			"boost_heat": 0.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(MainScene.RING_LENGTH - 0.35, 0.0)
	unit.set_meta("player_controlled", true)
	return unit


func _readable(position: Vector2) -> bool:
	return position.x >= MainScene.ARENA_LEFT - 96.0 and position.x <= MainScene.ARENA_RIGHT + 96.0 and position.y >= MainScene.ARENA_TOP - 96.0 and position.y <= MainScene.ARENA_BOTTOM + 96.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.35
	main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
	main.camera_lane_center = 0.0
	var unit = _make_unit()
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	if not unit.boost(Vector2.RIGHT, MainScene.RING_LENGTH):
		_fail("Boost did not start for clamp probe.")
		return
	unit.body_sway_offset = Vector2(2800.0, -1800.0)
	main._update_camera_center()
	main._refresh_unit_screen_positions()
	await process_frame
	if not unit.visible:
		_fail("Boosting controlled unit became hidden while body sway was extreme.")
		return
	if not _readable(unit.position):
		_fail("Boosting controlled unit was not clamped to readable screen: %s." % str(unit.position))
		return
	if not bool(unit.get_meta("projection_critical", false)):
		_fail("Boosting controlled unit was not marked projection-critical.")
		return
	print("CONTROLLED_UNIT_BOOST_SWAY_CLAMP_PROBE ok pos=%s source=%s" % [str(unit.position), String(unit.get_meta("projection_source", ""))])
	quit()
