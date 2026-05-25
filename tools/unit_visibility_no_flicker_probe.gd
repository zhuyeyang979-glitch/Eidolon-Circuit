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
	main.camera_center = 4.0
	main.camera_mobius_s = 4.0
	main.camera_lane_center = 0.0
	var unit = FighterScene.new()
	unit.setup_unit({
		"owner_id": 2,
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
	unit.deploy(4.0, 0.0)
	main.units_root.add_child(unit)
	main.all_units = [unit]
	main.active_units[2]["hero"] = unit
	main._refresh_unit_screen_positions()
	if not unit.visible:
		_fail("Non-controlled unit should start visible before hysteresis check.")
		return
	var first_position: Vector2 = unit.position
	var hidden_projection := {
		"position": Vector2(INF, INF),
		"visible": false,
		"projection_source": "forced_test",
	}
	var grace_projection: Dictionary = main._apply_projection_hysteresis(unit, hidden_projection)
	unit.set_mobius_screen_projection(grace_projection, bool(grace_projection.get("visible", false)))
	if not unit.visible:
		_fail("Non-controlled unit should keep one-frame visibility grace instead of flickering.")
		return
	if unit.position.distance_to(first_position) > 0.01:
		_fail("Visibility grace should reuse the last valid screen position.")
		return
	var expired_projection: Dictionary = main._apply_projection_hysteresis(unit, hidden_projection)
	unit.set_mobius_screen_projection(expired_projection, bool(expired_projection.get("visible", false)))
	if unit.visible:
		_fail("Non-controlled unit should hide after the one-frame visibility grace expires.")
		return
	print("UNIT_VISIBILITY_NO_FLICKER_PROBE ok grace_position=%s source=%s" % [
		str(first_position),
		String(unit.get_meta("projection_source", "")),
	])
	quit()
