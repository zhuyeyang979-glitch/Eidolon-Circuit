extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
			"move_acceleration": 32.0,
			"movement_profile": "vector",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"a": Vector2.ZERO, "b": Vector2.RIGHT, "radius": 0.1}],
		},
	})
	unit.deploy(4.0, 0.8)
	return unit


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	var marker := source.find("func move_by_gameplay")
	if marker < 0:
		_fail("Fighter is missing move_by_gameplay.")
	var next_func := source.find("\nfunc ", marker + 1)
	var body := source.substr(marker, next_func - marker if next_func > marker else source.length() - marker)
	if body.contains("screen_input_to_gameplay_motion"):
		_fail("move_by_gameplay must not re-interpret already converted gameplay input.")
	if not FileAccess.get_file_as_string("res://scripts/main.gd").contains("move_by_gameplay(movement_input_vector"):
		_fail("Player battle input should call move_by_gameplay with the actual battle vector.")
	var main = _make_main()
	var unit = _make_unit()
	main.all_units = [unit]
	main.active_units[1]["hero"] = unit
	var raw := Vector2.RIGHT
	var vectors: Dictionary = main._battle_movement_vector_for_unit(unit, raw)
	var actual: Vector2 = vectors.get("actual", Vector2.ZERO)
	if actual.length() <= 0.01 or actual.distance_to(raw) > 0.001:
		_fail("Actual locomotion input should remain screen-stable gameplay input, got %s." % str(actual))
	unit.move_by_gameplay(actual, 0.12, MainScene.RING_LENGTH)
	if unit.velocity.length() <= 0.001 or unit.velocity.normalized().distance_to(actual.normalized()) > 0.08:
		_fail("move_by_gameplay should follow the already-converted vector; velocity=%s actual=%s." % [str(unit.velocity), str(actual)])
	print("BATTLE_MOVEMENT_NO_DOUBLE_TRANSFORM_PROBE ok actual=%s velocity=%s" % [str(actual), str(unit.velocity)])
	quit()
