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
			"move_speed": 5.2,
			"move_acceleration": 34.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(ring_pos, lane)
	return unit


func _inside_readable_screen(position: Vector2) -> bool:
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
	main.camera_center = MainScene.RING_LENGTH - 0.35
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.35
	main.camera_lane_center = 0.0
	var unit = _make_unit(1, "hero", MainScene.RING_LENGTH - 0.35, 0.0)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	unit.velocity = Vector2(1.25, 0.18)
	for i in range(120):
		unit.tick(0.08, MainScene.RING_LENGTH)
		main._update_camera_center()
		main._refresh_unit_screen_positions()
		await process_frame
		if not unit.visible:
			_fail("Controlled Mobius hero became invisible on frame %d; source=%s guarded=%s." % [
				i,
				String(unit.get_meta("projection_source", "")),
				str(unit.get_meta("projection_guarded", false)),
			])
			return
		if not _inside_readable_screen(unit.position):
			_fail("Controlled Mobius hero drifted out of readable screen on frame %d: %s." % [i, str(unit.position)])
			return
	print("CONTROLLED_UNIT_NEVER_HIDDEN_MOBIUS_PROBE ok pos=%s guarded=%s source=%s" % [
		str(unit.position),
		str(unit.get_meta("projection_guarded", false)),
		String(unit.get_meta("projection_source", "")),
	])
	quit()
