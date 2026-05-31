extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Barrier Tile Readability",
		"owner_id": 1,
		"role": "barrier",
		"stats": {
			"health": 120,
			"mass": 80,
			"primary_color": Color(0.1, 0.7, 0.95, 1.0),
			"accent_color": Color(1.0, 0.84, 0.22, 1.0),
			"barrier_map_tiles": [
				{
					"index": 0,
					"name": "READABLE HARDLIGHT WALL",
					"local_ring": 0.0,
					"local_lane": 0.0,
					"length": 0.86,
					"radius": 0.18,
					"orientation": "horizontal",
					"shape": "barrier_tile",
					"material_class": "barrier_wall",
					"damage_type": "laser",
				}
			],
		},
	})
	fighter.deploy(4.0, 0.0)
	fighter._refresh_visuals()
	var visible_lines := 0
	for raw_line in fighter.barrier_tile_lines:
		var line := raw_line as Line2D
		if line == null or not line.visible:
			continue
		visible_lines += 1
		if line.width < 35.0:
			_fail("Barrier tile visual should read as hard foreground geometry; width %.3f is too thin." % line.width)
		if line.default_color.a < 0.94:
			_fail("Barrier tile visual alpha should stay brighter than the Mobius background; alpha %.3f." % line.default_color.a)
		var brightness := maxf(line.default_color.r, maxf(line.default_color.g, line.default_color.b))
		if brightness < 0.92:
			_fail("Barrier tile visual should be brighter than atmospheric grid/dust.")
	if visible_lines != 1:
		_fail("Expected exactly one visible barrier tile visual, got %d." % visible_lines)
	var first_line := fighter.barrier_tile_lines[0] as Line2D
	print("BARRIER_TILE_READABILITY_PROBE width=%.2f alpha=%.2f" % [first_line.width, first_line.default_color.a])
	quit()
