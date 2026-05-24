extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _node_for(main, role_key: String, slot_key: String, part_index: int) -> Dictionary:
	var label := "%s:%d" % [slot_key, part_index]
	var node: Dictionary = main._topology_component_node(0, label, Vector2(0.5, 0.5), slot_key, part_index)
	return node


func _check_role(main, role_key: String) -> Dictionary:
	var checked_limbs := 0
	var checked_muscles := 0
	var limb_catalog: Array = main._catalog_for(role_key, "limb_muscle")
	for i in range(limb_catalog.size()):
		var part: Dictionary = main._selected_component(role_key, "limb_muscle", i)
		var node := _node_for(main, role_key, "limb_muscle", i)
		var unit_bp := {"role": role_key, "custom_topology": {"nodes": [node], "edges": []}}
		var sockets: Array = main._topology_socket_ids_for_node(role_key, node, unit_bp)
		if not sockets.has("root_joint") or not sockets.has("distal"):
			_fail("%s limb_muscle[%d] %s sockets not normalized: %s" % [role_key, i, String(part.get("name", "")), str(sockets)])
		checked_limbs += 1
	var muscle_catalog: Array = main._catalog_for(role_key, "muscle")
	for i in range(muscle_catalog.size()):
		var part: Dictionary = main._selected_component(role_key, "muscle", i)
		var node := _node_for(main, role_key, "muscle", i)
		var unit_bp := {"role": role_key, "custom_topology": {"nodes": [node], "edges": []}}
		var sockets: Array = main._topology_socket_ids_for_node(role_key, node, unit_bp)
		if main._component_is_torso(part):
			if not bool(part.get("is_torso", false)):
				_fail("%s muscle[%d] %s is torso by material but missing normalized is_torso=true." % [role_key, i, String(part.get("name", ""))])
			if sockets.is_empty() or not String(sockets[0]).begins_with("torso_port:"):
				_fail("%s torso muscle[%d] %s sockets not torso ports: %s" % [role_key, i, String(part.get("name", "")), str(sockets)])
		else:
			if not sockets.has("root_joint"):
				_fail("%s muscle[%d] %s missing root_joint: %s" % [role_key, i, String(part.get("name", "")), str(sockets)])
			var connection_ends := int(part.get("connection_ends", 1))
			var terminal_like: bool = bool(main._part_counts_as_terminal_weapon(part, "muscle")) or bool(part.get("projectile", false)) or connection_ends <= 1
			if not terminal_like and not sockets.has("distal"):
				_fail("%s connector muscle[%d] %s missing distal: %s" % [role_key, i, String(part.get("name", "")), str(sockets)])
		checked_muscles += 1
	return {"limbs": checked_limbs, "muscles": checked_muscles}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var total_limbs := 0
	var total_muscles := 0
	for role_key in ["hero", "puppet", "barrier"]:
		var result := _check_role(main, role_key)
		total_limbs += int(result.get("limbs", 0))
		total_muscles += int(result.get("muscles", 0))
	print("ALL_LIMB_TOPOLOGY_INTERFACES_PROBE ok limbs=%d muscles=%d" % [total_limbs, total_muscles])
	quit()
