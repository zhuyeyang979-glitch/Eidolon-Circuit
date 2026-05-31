extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _index_by_name(main, slot_key: String, name: String) -> int:
	var index: int = main._component_index_by_exact_name("hero", slot_key, name)
	if index < 0:
		_fail("Missing %s catalog part: %s" % [slot_key, name])
	return index


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb_for(main, module_part: Dictionary) -> int:
	var target_kind := String(module_part.get("module_target_kind", ""))
	var required_degrees := int(module_part.get("required_joint_degrees", 0))
	var required_extension := float(module_part.get("required_extension_m", 0.0))
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		var embedded: Dictionary = main._embedded_joint_profile_for_part(part, "limb_muscle", module_part)
		var kind := String(embedded.get("kind", ""))
		if target_kind in ["ball_joint", "dual_ball_joint"] and kind == "ball" and int(embedded.get("angle", 0)) >= required_degrees:
			return i
		if target_kind in ["telescopic_joint", "dual_telescopic_joint"] and kind == "linear" and float(embedded.get("extension", 0.0)) >= required_extension:
			return i
	return 0


func _first_gun_for(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_gun_muscle(part, "muscle"):
			continue
		var gun_kind := String(part.get("gun_kind", main._gun_kind_for_data(part)))
		var ammo_kind := String(part.get("ammo_kind", main._ammo_kind_for_data(part)))
		if main._gun_activation_profile_supports_kind(profile, gun_kind, ammo_kind):
			return i
	return -1


func _first_melee_terminal(main, preferred_damage: String = "") -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle") and main._terminal_weapon_kind_for_part(part, "muscle") == "melee":
			if preferred_damage == "" or String(part.get("damage_type", "")).to_lower() == preferred_damage:
				return i
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._part_counts_as_terminal_weapon(part, "muscle") and main._terminal_weapon_kind_for_part(part, "muscle") == "melee":
			return i
	return -1


func _build_unit(main, module_index: int, terminal_index: int = -1, paired: bool = false) -> Dictionary:
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_index: int = _first_limb_for(main, module_part)
	var first_limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "L1", "limb_muscle", limb_index, Vector2.RIGHT)
	var target_node: int = first_limb
	if terminal_index >= 0:
		target_node = main._append_directed_component_node("hero", unit_bp, nodes, edges, first_limb, "GUN", "muscle", terminal_index, Vector2.RIGHT)
	else:
		var melee_terminal: int = _first_melee_terminal(main, "pierce" if String(module_part.get("module_action_profile", "")) == "rapier_feint_thrust" else "")
		if melee_terminal < 0:
			_fail("Missing melee terminal for module binding probe.")
		else:
			main._append_directed_component_node("hero", unit_bp, nodes, edges, first_limb, "TIP1", "muscle", melee_terminal, Vector2.RIGHT)
		if paired:
			var second_limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "L2", "limb_muscle", limb_index, Vector2.DOWN)
			if melee_terminal >= 0:
				main._append_directed_component_node("hero", unit_bp, nodes, edges, second_limb, "TIP2", "muscle", melee_terminal, Vector2.DOWN)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = "Backfilled Module Probe"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	unit_bp["_probe_target_node"] = target_node
	return unit_bp


func _bind_and_assert(main, module_name: String, profile: String, paired: bool = false) -> Dictionary:
	if failed:
		return {}
	var module_index := _index_by_name(main, "module", module_name)
	var terminal_index := _first_gun_for(main, profile) if profile == "grenade_arc_activate" else -1
	if profile == "grenade_arc_activate" and terminal_index < 0:
		_fail("Missing grenade/explosive terminal for salvo binding.")
	var unit_bp := _build_unit(main, module_index, terminal_index, paired)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, int(unit_bp.get("_probe_target_node", -1)))
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("%s did not expose a valid binding candidate: %s" % [module_name, String(candidate.get("note", candidate.get("reason", "")))])
		return {}
	var bound_bp: Dictionary = unit_bp
	var topology: Dictionary = bound_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	var root_index := int(candidate.get("root_index", -1))
	var target_nodes: Array = Array(candidate.get("target_nodes", []))
	if root_index >= 0 and root_index < nodes.size() and nodes[root_index] is Dictionary:
		var node: Dictionary = Dictionary(nodes[root_index]).duplicate(true)
		var modules: Array = Array(node.get("modules", []))
		if not modules.has(module_index):
			modules.append(module_index)
		node["modules"] = modules
		node["module"] = int(modules[0])
		node["attack_key"] = 1
		nodes[root_index] = node
		topology["nodes"] = nodes
		bound_bp["custom_topology"] = topology
	var drive_by_node: Dictionary = candidate.get("drive_by_node", {}) if candidate.get("drive_by_node", {}) is Dictionary else {}
	if drive_by_node.is_empty():
		drive_by_node = main._module_binding_drive_allocation_for_nodes("hero", bound_bp, nodes, target_nodes, main._selected_component("hero", "module", module_index))
	var joint_drive_total: float = main._module_binding_drive_total(drive_by_node)
	bound_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": String(candidate.get("target_kind", "limb")),
		"root_index": root_index,
		"target_nodes": target_nodes,
		"target_torso_node": int(candidate.get("target_torso_node", 0)),
		"joint_drive_allocation_by_node": drive_by_node,
		"allocated_limb_momentum_by_node": drive_by_node.duplicate(true),
		"allocated_limb_momentum": joint_drive_total,
		"joint_drive_allocation_total": joint_drive_total,
		"joint_drive_demand": joint_drive_total,
		"joint_output_momentum": main._module_binding_joint_output_for_nodes("hero", bound_bp, nodes, target_nodes, main._selected_component("hero", "module", module_index)),
		"binding_valid_note": "OK",
	}]
	var bindings: Array = main._runtime_module_bindings_for_blueprint("hero", bound_bp)
	if bindings.size() != 1:
		_fail("%s did not produce exactly one runtime binding. raw_bindings=%s payloads=%s" % [module_name, str(bound_bp.get("module_bindings", [])), str(bound_bp.get("slot_payloads", []))])
		return {}
	var binding: Dictionary = Dictionary(bindings[0])
	if not bool(binding.get("runtime_valid", false)):
		_fail("%s runtime binding invalid: %s." % [module_name, String(binding.get("binding_valid_note", ""))])
		return {}
	if String(binding.get("module_action_profile", "")) != profile:
		_fail("%s runtime profile expected %s, got %s." % [module_name, profile, String(binding.get("module_action_profile", ""))])
		return {}
	if profile == "grenade_arc_activate":
		if String(binding.get("target_kind", "")) != "gun_terminal":
			_fail("%s should bind as gun_terminal." % module_name)
			return {}
	else:
		var fighter := preload("res://scripts/fighter.gd").new()
		root.add_child(fighter)
		fighter._ready()
		var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, bound_bp)
		fighter.setup_unit({"unit_name": module_name, "owner_id": 1, "role": "hero", "stats": stats})
		fighter.deploy(0.0, 0.0)
		var event: Dictionary = fighter.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
		fighter.queue_free()
		if event.is_empty() or String(event.get("module_action_profile", "")) != profile:
			_fail("%s did not trigger in training/runtime path." % module_name)
			return {}
	return binding


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	_bind_and_assert(main, "COMBO ROUTER: BALANCE STRING", "swing_180")
	_bind_and_assert(main, "CLAMP ROUTER: VISE CLOSE", "inward_pincer_clamp", true)
	_bind_and_assert(main, "DUEL ROUTER: FEINT THRUST", "rapier_feint_thrust")
	_bind_and_assert(main, "SALVO ROUTER: EXPLOSIVE ARC", "grenade_arc_activate")
	if failed:
		return
	print("BACKFILLED_MODULE_BINDING_TRAINING_PROBE ok")
	quit()
