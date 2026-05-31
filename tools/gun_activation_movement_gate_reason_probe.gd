extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "Movement Gate Probe",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"health": 100,
			"move_speed": 4.0,
			"move_acceleration": 20.0,
			"mass": 18.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"node_index": 0, "part_kind": "torso"}],
		},
	})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	var fighter = _fighter()
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	fighter.move_by_gameplay(Vector2.RIGHT, 0.1, MainScene.RING_LENGTH)
	if String(fighter.get_meta("movement_gate_reason", "")) != "":
		_fail("Normal movement should not keep a gate reason: %s" % String(fighter.get_meta("movement_gate_reason", "")))
	fighter.melee_stagger_timer = 0.2
	fighter.move_by_gameplay(Vector2.RIGHT, 0.1, MainScene.RING_LENGTH)
	if String(fighter.get_meta("movement_gate_reason", "")) != "stagger":
		_fail("Stagger movement gate reason missing.")
	fighter.melee_stagger_timer = 0.0
	fighter.cooling_lock_timer = 0.2
	fighter.move_by_gameplay(Vector2.RIGHT, 0.1, MainScene.RING_LENGTH)
	if String(fighter.get_meta("movement_gate_reason", "")) != "cooling_lock":
		_fail("Cooling lock movement gate reason missing.")
	fighter.cooling_lock_timer = 0.0
	fighter.overheated = true
	fighter.forced_cooling_timer = 0.2
	fighter.cooling_lock_timer = 0.2
	fighter.move_by_gameplay(Vector2.RIGHT, 0.1, MainScene.RING_LENGTH)
	if String(fighter.get_meta("movement_gate_reason", "")) != "overheat_shutdown":
		_fail("Overheat shutdown movement gate reason missing.")
	fighter.overheated = false
	fighter.forced_cooling_timer = 0.0
	fighter.cooling_lock_timer = 0.0
	fighter.set_meta("active_cool_lock", 0.2)
	main._handle_player_battle_input(1, 0.1, "p1")
	if String(fighter.get_meta("movement_gate_reason", "")) != "active_cool_lock":
		_fail("Main input active cool lock reason missing.")
	fighter.set_meta("active_cool_lock", 0.0)
	fighter.set_meta("jammed_timer", 0.2)
	main._handle_player_battle_input(1, 0.1, "p1")
	if String(fighter.get_meta("movement_gate_reason", "")) != "jammed":
		_fail("Main input jammed reason missing.")
	print("GUN_ACTIVATION_MOVEMENT_GATE_REASON_PROBE ok")
	quit()
