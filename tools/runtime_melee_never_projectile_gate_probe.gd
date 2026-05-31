extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var module_part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(module_part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_two_link_blueprint(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.38, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 0,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _build_target_blueprint(main) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	main._append_component_root_node(nodes, "TARGET_CORE", Vector2(0.5, 0.5), _first_torso(main))
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": [], "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link runtime module missing.")
	var attacker_stats := main._compute_unit_stats(1, "hero", -1, _build_two_link_blueprint(main, module_index))
	var target_stats := main._compute_unit_stats(2, "hero", -1, _build_target_blueprint(main))
	var attacker = FighterScene.new()
	var target = FighterScene.new()
	root.add_child(attacker)
	root.add_child(target)
	attacker._ready()
	target._ready()
	attacker.setup_unit({"unit_name": "MELEE_GATE_ATTACKER", "owner_id": 1, "role": "hero", "stats": attacker_stats})
	target.setup_unit({"unit_name": "MELEE_GATE_TARGET", "owner_id": 2, "role": "hero", "stats": target_stats})
	attacker.deploy(4.0, 0.0)
	target.deploy(8.0, 0.0)
	main.active_units = {
		1: {"hero": attacker, "barrier": null, "puppet": []},
		2: {"hero": target, "barrier": null, "puppet": []},
	}
	var binding: Dictionary = Array(attacker_stats.get("runtime_module_bindings", []))[0]
	var event: Dictionary = attacker.begin_runtime_module_action("normal", binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Two-Link runtime action did not start.")
	event["module_action_profile"] = "two_link_forward_snap"
	event["runtime_binding"] = true
	event["projectile"] = true
	event["projectile_only"] = true
	event["projectile_style"] = "true_bullet"
	event["projectile_behavior"] = "true_bullet"
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main._resolve_attack(attacker, event)
	var message := String(main.battle_message)
	if message.contains("投射物") or message.contains("Projectile requires"):
		_fail("Runtime melee leaked into projectile warning: %s" % message)
	if bool(event.get("projectile", true)):
		_fail("Runtime melee event retained projectile=true after normalization.")
	print("RUNTIME_MELEE_NEVER_PROJECTILE_GATE_PROBE message='%s'" % message)
	quit()
