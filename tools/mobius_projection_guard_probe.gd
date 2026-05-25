extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	main.camera_center = 0.0
	main.camera_mobius_s = 0.0
	main.camera_lane_center = 0.0
	var unit = FighterScene.new()
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 4.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(180.0, 0.4)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	main._refresh_unit_screen_positions()
	if not unit.visible:
		_fail("Projection guard should keep the controlled hero visible after a stale camera projection.")
		return
	if not bool(unit.get_meta("projection_guarded", false)):
		_fail("Projection guard should record guarded=true after camera resync.")
		return
	var center := Vector2((MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5, (MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5)
	if unit.position.distance_to(center) > 72.0:
		_fail("Projection guard should place the controlled hero near screen center; got %s." % str(unit.position))
		return
	if absf(main.camera_mobius_s - unit.mobius_s) > 0.01:
		_fail("Projection guard should resync camera_mobius_s to the controlled unit.")
		return
	print("MOBIUS_PROJECTION_GUARD_PROBE ok pos=%s camera=%.3f source=%s" % [
		str(unit.position),
		main.camera_mobius_s,
		String(unit.get_meta("projection_source", "")),
	])
	quit()
