extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int, role: String, ring_pos: float, lane: float):
	var unit = FighterScene.new()
	unit.setup_unit({
		"owner_id": owner_id,
		"role": role,
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 9.0,
			"move_acceleration": 80.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(ring_pos, lane)
	return unit


func _readable(position: Vector2) -> bool:
	return position.x >= MainScene.ARENA_LEFT - 128.0 and position.x <= MainScene.ARENA_RIGHT + 128.0 and position.y >= MainScene.ARENA_TOP - 128.0 and position.y <= MainScene.ARENA_BOTTOM + 128.0


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
	main.camera_center = MainScene.RING_LENGTH - 0.6
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.6
	main.camera_lane_center = 0.0
	var unit = _make_unit(1, "hero", MainScene.RING_LENGTH - 0.55, 0.0)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	unit.velocity = Vector2(10.5, 2.0)
	var guarded_frames := 0
	for frame in range(180):
		if frame % 37 == 0:
			main.camera_mobius_s -= 2.2
			main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
		unit.velocity = Vector2(10.5, sin(float(frame) * 0.11) * 2.4)
		unit.tick(0.055, MainScene.RING_LENGTH)
		main._update_camera_center()
		main._refresh_unit_screen_positions()
		await process_frame
		if bool(unit.get_meta("projection_guarded", false)):
			guarded_frames += 1
		if not unit.visible:
			_fail("Controlled fast Mobius unit became hidden on frame %d; source=%s." % [frame, String(unit.get_meta("projection_source", ""))])
			return
		if not _readable(unit.position):
			_fail("Controlled fast Mobius unit left readable screen on frame %d: %s." % [frame, str(unit.position)])
			return
	print("CONTROLLED_UNIT_FAST_BOOST_NEVER_HIDDEN_MOBIUS_PROBE ok guarded_frames=%d pos=%s" % [guarded_frames, str(unit.position)])
	quit()
