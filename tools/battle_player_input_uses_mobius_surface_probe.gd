extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _make_main():
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.mobius_enabled = true
	main.camera_mobius_s = 0.0
	main.camera_center = 0.0
	main.camera_lane_center = 0.0
	main.mobius_rotation_state = {"twist_phase": 0.0, "twist_amplitude": 0.18, "pivot": Vector2(12.0, 0.0)}
	main._sync_camera_mobius_from_compat()
	return main


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"mass": 12.0,
			"move_speed": 4.0,
			"body_move_speed": 4.0,
			"move_acceleration": 28.0,
			"thruster_acceleration": 28.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(4.0, 0.0)
	return unit


func _install_unit(main, unit) -> void:
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit


func _action_for_vector(input_vector: Vector2) -> String:
	if input_vector == Vector2.UP:
		return "p1_up"
	if input_vector == Vector2.DOWN:
		return "p1_down"
	if input_vector == Vector2.LEFT:
		return "p1_left"
	return "p1_right"


func _find_surface_fixture(main, unit) -> Dictionary:
	var candidates := [
		{"coord": Vector2(3.0, 1.0), "input": Vector2.DOWN},
		{"coord": Vector2(5.6, 1.1), "input": Vector2.DOWN},
		{"coord": Vector2(7.2, -1.0), "input": Vector2.UP},
		{"coord": Vector2(9.0, 0.7), "input": Vector2.RIGHT},
		{"coord": Vector2(10.8, -0.8), "input": Vector2.LEFT},
	]
	for candidate in candidates:
		var coord: Vector2 = candidate["coord"]
		var input_vector: Vector2 = candidate["input"]
		unit.deploy(coord.x, coord.y)
		var raw: Vector2 = GameplayTransform.screen_input_to_gameplay_motion(input_vector)
		var surface: Vector2 = main._mobius_surface_input_for_unit(unit, input_vector)
		if surface.length() > 0.01 and surface.distance_to(raw) > 0.035:
			return {"coord": coord, "input": input_vector, "raw": raw, "surface": surface}
	return {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = _make_main()
	var unit = _make_unit()
	_install_unit(main, unit)
	var fixture := _find_surface_fixture(main, unit)
	if fixture.is_empty():
		_fail("Mobius surface input fixture did not differ from raw gameplay input; helper may still be a stub.")
	var coord: Vector2 = fixture["coord"]
	var input_vector: Vector2 = fixture["input"]
	var expected_surface: Vector2 = fixture["surface"]
	var raw: Vector2 = fixture["raw"]
	unit.deploy(coord.x, coord.y)
	unit.velocity = Vector2.ZERO
	_release_actions()
	Input.action_press(_action_for_vector(input_vector))
	await process_frame
	main._handle_player_battle_input(1, 0.12, "p1")
	var actual: Vector2 = unit.get_meta("actual_move_input_vector", Vector2.ZERO)
	if actual.distance_to(expected_surface) > 0.015:
		_fail("Player input path should use Mobius surface vector %s, got %s." % [str(expected_surface), str(actual)])
	if actual.distance_to(raw) < 0.025:
		_fail("Player input path still matches raw gameplay vector %s instead of surface vector." % str(raw))
	if unit.velocity.length() <= 0.001 or unit.velocity.normalized().distance_to(expected_surface.normalized()) > 0.08:
		_fail("Unit velocity should follow actual Mobius surface input; velocity=%s surface=%s." % [str(unit.velocity), str(expected_surface)])
	_release_actions()
	print("BATTLE_PLAYER_INPUT_USES_MOBIUS_SURFACE_PROBE ok raw=%s surface=%s actual=%s" % [str(raw), str(expected_surface), str(actual)])
	quit()
