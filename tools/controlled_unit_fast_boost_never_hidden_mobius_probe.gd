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
			"boost_momentum": 210.0,
			"boost_speed": 18.0,
			"boost_duration": 0.22,
			"boost_cooldown": 0.5,
			"thruster_boost_extra_demand": 1.0,
			"boost_heat": 0.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(ring_pos, lane)
	return unit


func _readable(position: Vector2) -> bool:
	return position.x >= MainScene.ARENA_LEFT - 128.0 and position.x <= MainScene.ARENA_RIGHT + 128.0 and position.y >= MainScene.ARENA_TOP - 128.0 and position.y <= MainScene.ARENA_BOTTOM + 128.0


func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _max_abs_extent(bounds: Rect2) -> float:
	var end := bounds.position + bounds.size
	return maxf(absf(bounds.position.x), maxf(absf(bounds.position.y), maxf(absf(end.x), absf(end.y))))


func _runtime_art_attached(unit) -> Dictionary:
	var max_extent := 0.0
	var polygons := 0
	for raw_segment in unit._runtime_topology_world_segments(true, false):
		if not (raw_segment is Dictionary):
			continue
		var polygon: PackedVector2Array = unit._runtime_segment_polygon_local(Dictionary(raw_segment))
		if polygon.size() < 3:
			continue
		polygons += 1
		max_extent = maxf(max_extent, _max_abs_extent(_bounds(polygon)))
	return {"ok": polygons > 0 and max_extent <= 220.0, "polygons": polygons, "max_extent": max_extent}


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
	unit.set_meta("player_controlled", true)
	var guarded_frames := 0
	var boost_starts := 0
	for frame in range(180):
		if frame % 37 == 0:
			main.camera_mobius_s -= 2.2
			main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
		if frame % 45 == 0:
			var boost_dir := Vector2(1.0, sin(float(frame) * 0.19) * 0.32).normalized()
			if unit.boost(boost_dir, MainScene.RING_LENGTH):
				boost_starts += 1
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
		var art: Dictionary = _runtime_art_attached(unit)
		if not bool(art.get("ok", false)):
			_fail("Controlled fast Mobius unit root is visible but runtime art detached on frame %d; mobius_s=%.3f ring_pos=%.3f art=%s." % [frame, unit.mobius_s, unit.ring_pos, str(art)])
			return
	if boost_starts < 2:
		_fail("Probe did not start enough real boosts; boost_starts=%d." % boost_starts)
		return
	print("CONTROLLED_UNIT_FAST_BOOST_NEVER_HIDDEN_MOBIUS_PROBE ok boosts=%d guarded_frames=%d pos=%s" % [boost_starts, guarded_frames, str(unit.position)])
	quit()
