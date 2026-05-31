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
			"mass": 10.0,
			"move_speed": 5.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(ring_pos, lane)
	return unit


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
	var puppet = _make_unit(1, "puppet", 16.0, 0.8)
	puppet.set_meta("player_controlled", true)
	main.units_root.add_child(puppet)
	main.all_units = [puppet]
	main.active_units[1]["hero"] = null
	main.active_units[1]["puppet"] = [puppet]
	main._refresh_unit_screen_positions()
	if not puppet.visible:
		_fail("Role-switched controlled puppet should remain visible after stale Mobius projection.")
		return
	if not bool(puppet.get_meta("projection_guarded", false)):
		_fail("Role-switched controlled puppet should record projection guard diagnostics.")
		return
	if not bool(puppet.get_meta("projection_critical", false)):
		_fail("Role-switched controlled puppet should be tagged as projection-critical.")
		return
	print("CONTROLLED_UNIT_ROLE_SWITCH_VISIBILITY_PROBE ok pos=%s source=%s" % [
		str(puppet.position),
		String(puppet.get_meta("projection_source", "")),
	])
	quit()
