extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _catalog_index(main, slot: String, key: String) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = main._catalog_for("hero", slot)[i]
		if String(part.get("name", "")) == key or String(part.get("module_action_profile", "")) == key:
			return i
	return -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var module_index := _catalog_index(main, "module", "laser_beam_activate")
	var laser_index := _catalog_index(main, "muscle", MainScene.STANDARD_LASER_NAME)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", 0, Vector2.RIGHT)
	var gun: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "LASER", "muscle", laser_index, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0}]
	unit_bp["module_bindings"] = [{"software_slot_index": 0, "module_index": module_index, "attack_key": 1, "target_kind": "gun_terminal", "target_nodes": [gun], "target_torso_node": torso, "binding_valid_note": "OK"}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var stats := main._compute_unit_stats(1, "hero", -1, _build_unit(main))
	var attacker = FighterScene.new()
	root.add_child(attacker)
	attacker._ready()
	attacker.setup_unit({"unit_name": "LASER_NO_LOCK", "owner_id": 1, "role": "hero", "stats": stats})
	attacker.deploy(4.0, 0.0)
	main.active_units = {1: {"hero": attacker, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	var binding: Dictionary = Array(stats.get("runtime_module_bindings", []))[0]
	main.gun_activation_state[1] = {"binding": binding, "aim_direction": Vector2.RIGHT, "activation_semantic": "hold_beam", "action_name": "probe", "attack_index": 0, "fire_timer": 0.0}
	var event := main._runtime_gun_activation_event_for(1)
	if String(event.get("projectile_behavior", "")) == "true_bullet":
		_fail("Laser event must not masquerade as true_bullet.")
	main._release_runtime_gun_activation(1)
	if main.pending_true_bullet_shots.size() != 0:
		_fail("Releasing laser beam activation must not queue true-bullet locks.")
	print("LASER_NO_SNIPER_LOCK_PROBE ok")
	quit()

