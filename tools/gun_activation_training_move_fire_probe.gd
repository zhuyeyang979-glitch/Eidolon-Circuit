extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	_release_actions()
	quit(1)


func _release_actions() -> void:
	for action in ["p1_up", "p1_down", "p1_left", "p1_right", "p1_face_left", "p1_face_right", "p1_attack_1"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _find_part(main, slot_key: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if bool(predicate.call(part)):
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var torso_index := _find_part(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var limb_index := 0
	var rifle_index := _find_part(main, "muscle", func(part: Dictionary) -> bool:
		return main._component_is_gun_muscle(part, "muscle") and String(part.get("gun_kind", main._gun_kind_for_data(part))) == "rifle" and String(part.get("ammo_kind", main._ammo_kind_for_data(part))) == "bullet"
	)
	var module_index := _find_part(main, "module", func(part: Dictionary) -> bool: return String(part.get("module_action_profile", "")) == "rifle_burst_activate")
	var engine_index := _find_part(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) >= 120.0)
	var booster_index := _find_part(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_demand_for_part(part) > 0.0)
	var cooling_index := _find_part(main, "cooling", func(_part: Dictionary) -> bool: return true)
	if [torso_index, rifle_index, module_index, engine_index, booster_index, cooling_index].has(-1):
		return {}
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso_node: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_node: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso_node, "ARM", "limb_muscle", limb_index, Vector2.RIGHT)
	var gun_node: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_node, "RIFLE", "muscle", rifle_index, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = "Gun Move Fire Training Probe"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [
		{"kind": "module", "module": module_index, "torso_node": torso_node},
		{"kind": "engine", "engine": engine_index, "internal_slot_index": 0, "torso_node": torso_node},
		{"kind": "booster", "booster": booster_index, "internal_slot_index": 1, "torso_node": torso_node},
		{"kind": "cooling", "cooling": cooling_index, "internal_slot_index": 2, "torso_node": torso_node},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var candidate: Dictionary = main._torso_detail_binding_candidate_for_node(unit_bp, 0, module_part, gun_node)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Rifle candidate rejected: %s" % String(candidate.get("note", candidate.get("reason", ""))))
		return {}
	var target_nodes: Array = Array(candidate.get("target_nodes", []))
	var drive_by_node: Dictionary = candidate.get("drive_by_node", {}) if candidate.get("drive_by_node", {}) is Dictionary else {}
	var node: Dictionary = Dictionary(nodes[gun_node]).duplicate(true)
	node["modules"] = [module_index]
	node["module"] = module_index
	node["attack_key"] = 1
	nodes[gun_node] = node
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": String(candidate.get("target_kind", "gun_terminal")),
		"root_index": int(candidate.get("root_index", gun_node)),
		"target_nodes": target_nodes,
		"target_torso_node": int(candidate.get("target_torso_node", torso_node)),
		"joint_drive_allocation_by_node": drive_by_node,
		"joint_drive_allocation_total": main._module_binding_drive_total(drive_by_node),
		"joint_drive_demand": main._module_binding_drive_total(drive_by_node),
		"joint_output_momentum": main._module_binding_joint_output_for_nodes("hero", unit_bp, nodes, target_nodes, module_part),
		"command_window_profile": String(module_part.get("command_window_profile", "")),
		"binding_valid_note": "OK",
	}]
	main.editor_working_blueprint = unit_bp
	return unit_bp.duplicate(true)


func _enter_training(main, unit_bp: Dictionary) -> void:
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp.duplicate(true)
	main.ai_battle_seat = 1
	main.training_seat_confirmed = true
	if not main._prepare_editor_canvas_training_import():
		_fail("Training import rejected: %s" % String(main.training_import_error_note))
	if not main._prepare_training_battle_loadouts():
		_fail("Training loadout rejected: %s" % String(main.training_import_error_note))
	main._begin_battle(MainScene.MODE_TRAINING, true)
	main.set_process(false)
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Training battle did not start.")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var unit_bp := _build_unit(main)
	if unit_bp.is_empty():
		_fail("Could not build legal rifle training unit.")
		return
	var preview_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if preview_bindings.is_empty():
		_fail("Built rifle unit has no runtime binding before training.")
		return
	_enter_training(main, unit_bp)
	var hero = Dictionary(main.active_units.get(1, {})).get("hero", null)
	if not main._is_live_unit(hero):
		_fail("Training did not spawn controllable hero.")
		return
	var bindings: Array = Array(hero.stats.get("runtime_module_bindings", []))
	if bindings.is_empty() or String(Dictionary(bindings[0]).get("module_action_profile", "")) != "rifle_burst_activate":
		_fail("Training hero did not keep rifle runtime binding.")
		return
	var before_coord: Vector2 = main._unit_combat_coord(hero)
	var ammo_before := main._current_ammo(hero, "bullet")
	_release_actions()
	Input.action_press("p1_attack_1")
	main._consume_battle_input_edges_once({"pressed": {"p1_attack_1": true}, "released": {}}, true)
	main._handle_player_battle_input(1, 0.12, "p1")
	main.battle_input_frame_active = false
	hero.tick(0.12, MainScene.RING_LENGTH)
	if not main._runtime_gun_activation_active(1):
		_fail("Rifle activation did not start from real training input.")
		return
	Input.action_press("p1_up")
	for i in range(5):
		main._handle_player_battle_input(1, 0.12, "p1")
		hero.tick(0.12, MainScene.RING_LENGTH)
	var after_coord: Vector2 = main._unit_combat_coord(hero)
	var ammo_after := main._current_ammo(hero, "bullet")
	if after_coord.y >= before_coord.y - 0.01:
		_fail("Training rifle unit did not move while firing; before=%s after=%s gate=%s input=%s velocity=%s collision_brake=%.3f speed=%.3f accel=%.3f mobius=(%.3f, %.3f) drive_note=%s" % [
			str(before_coord),
			str(after_coord),
			String(hero.get_meta("movement_gate_reason", "")),
			str(hero.get_meta("actual_move_input_vector", Vector2.ZERO)),
			str(hero.velocity),
			float(hero.get("collision_auto_brake_timer")),
			float(hero.stats.get("move_speed", 0.0)),
			float(hero.stats.get("move_acceleration", 0.0)),
			float(hero.get("mobius_s")),
			float(hero.get("mobius_v")),
			String(hero.stats.get("drive_note", "")),
		])
		return
	if ammo_after >= ammo_before:
		_fail("Training rifle unit moved test did not fire ammo; ammo %d -> %d." % [ammo_before, ammo_after])
		return
	var event: Dictionary = main._runtime_gun_activation_event_for(1)
	if event.is_empty() or not bool(event.get("projectile", false)):
		_fail("Training rifle activation lost projectile event while moving.")
		return
	_release_actions()
	print("GUN_ACTIVATION_TRAINING_MOVE_FIRE_PROBE ok moved=%.3f ammo=%d->%d" % [before_coord.distance_to(after_coord), ammo_before, ammo_after])
	quit()
