extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _runtime_stats() -> Dictionary:
	return {
		"health": 100,
		"mass": 10.0,
		"move_speed": 9.0,
		"move_acceleration": 80.0,
		"movement_profile": "vector",
		"boost_momentum": 260.0,
		"boost_speed": 30.0,
		"boost_duration": 0.10,
		"boost_cooldown": 0.2,
		"thruster_boost_extra_demand": 1.0,
		"boost_heat": 0.0,
		"teamedit_runtime_topology": true,
		"runtime_visual_scale": 110.0,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"a_local": Vector2(-0.24, 0.0),
				"b_local": Vector2(0.24, 0.0),
				"radius": 0.12,
			},
			{
				"node_index": 1,
				"part_kind": "limb_muscle",
				"a_local": Vector2(0.24, 0.0),
				"b_local": Vector2(0.96, 0.0),
				"radius": 0.055,
			},
		],
	}


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


func _hide_overlay_layers(main) -> void:
	for layer in [main.menu_layer, main.editor_layer, main.saved_units_layer, main.scout_layer, main.settings_layer, main.hud_layer, main.loading_layer]:
		if layer != null:
			layer.visible = false
			for child in layer.get_children():
				if child is CanvasItem:
					child.visible = false


func _capture_viewport_image(main) -> Image:
	_hide_overlay_layers(main)
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	RenderingServer.force_draw()
	return root.get_viewport().get_texture().get_image().duplicate()


func _visible_pixels_near(image: Image, center: Vector2) -> int:
	var count := 0
	var width := image.get_width()
	var height := image.get_height()
	for yy in range(-38, 39, 2):
		for xx in range(-38, 39, 2):
			var x := clampi(int(round(center.x)) + xx, 0, width - 1)
			var y := clampi(int(round(center.y)) + yy, 0, height - 1)
			var c := image.get_pixel(x, y)
			var brightness := c.r + c.g + c.b
			if c.a > 0.45 and brightness > 0.10:
				count += 1
	return count


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.08
	main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
	main.camera_lane_center = 0.0
	_hide_overlay_layers(main)
	var unit = FighterScene.new()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": _runtime_stats(),
	})
	unit.deploy(MainScene.RING_LENGTH - 0.08, 0.0)
	unit.set_meta("player_controlled", true)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	if not unit.boost(Vector2.RIGHT, MainScene.RING_LENGTH):
		_fail("Boost did not start for seam render probe.")
		return
	var crossed := false
	for frame in range(12):
		unit.tick(0.035, MainScene.RING_LENGTH)
		if unit.mobius_s > MainScene.RING_LENGTH + 0.02:
			crossed = true
		main._update_camera_center()
		main._refresh_unit_screen_positions()
		var art: Dictionary = _runtime_art_attached(unit)
		if not bool(art.get("ok", false)):
			_fail("Controlled unit root stayed visible but runtime art detached after boost seam; frame=%d mobius_s=%.3f ring_pos=%.3f art=%s." % [frame, unit.mobius_s, unit.ring_pos, str(art)])
			return
		await process_frame
	if not crossed:
		_fail("Boost seam probe did not cross the Mobius seam; mobius_s=%.3f." % unit.mobius_s)
		return
	if not unit.visible:
		_fail("Controlled unit became hidden after boost seam crossing.")
		return
	var image := await _capture_viewport_image(main)
	var visible_pixels := _visible_pixels_near(image, unit.position)
	if visible_pixels < 16:
		_fail("Rendered unit footprint near controlled screen position is too weak after seam boost; pixels=%d pos=%s mobius_s=%.3f ring_pos=%.3f." % [visible_pixels, str(unit.position), unit.mobius_s, unit.ring_pos])
		return
	print("CONTROLLED_UNIT_BOOST_SEAM_RENDER_VISIBILITY_PROBE ok pixels=%d pos=%s mobius_s=%.3f ring_pos=%.3f" % [visible_pixels, str(unit.position), unit.mobius_s, unit.ring_pos])
	quit()
