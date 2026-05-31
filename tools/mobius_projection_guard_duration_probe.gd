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
	unit.deploy(2.0, 0.0)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	main._refresh_unit_screen_positions()
	var first_position: Vector2 = unit.position
	var hidden_projection := {
		"position": Vector2(INF, INF),
		"visible": false,
		"critical": true,
		"projection_source": "forced_guard_duration",
	}
	for frame in range(MainScene.MOBIUS_PROJECTION_CRITICAL_GRACE_FRAMES):
		var guarded_projection: Dictionary = main._apply_projection_hysteresis(unit, hidden_projection, MainScene.MOBIUS_PROJECTION_CRITICAL_GRACE_FRAMES)
		unit.set_mobius_screen_projection(guarded_projection, bool(guarded_projection.get("visible", false)))
		if not unit.visible:
			_fail("Critical unit projection guard expired too early on frame %d." % frame)
			return
		if unit.position.distance_to(first_position) > 0.01:
			_fail("Critical guard should keep the last finite screen position during a stale projection.")
			return
	print("MOBIUS_PROJECTION_GUARD_DURATION_PROBE ok frames=%d source=%s" % [
		MainScene.MOBIUS_PROJECTION_CRITICAL_GRACE_FRAMES,
		String(unit.get_meta("projection_source", "")),
	])
	quit()
