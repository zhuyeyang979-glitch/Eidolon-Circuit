extends RefCounted
class_name BootDriverProbeLib

const MainScene := preload("res://scripts/main.gd")


static func prepare_main(main) -> void:
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"


static func boot_module_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "boot_action_driver":
			return i
	return -1


static func first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


static func first_rotating_limb(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if String(part.get("name", "")) == "HUMANOVA THIGH MYOMER":
			return i
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not bool(part.get("terminal_weapon", false)) and String(part.get("embedded_joint_kind", "")).to_lower() in ["ball", "hybrid"]:
			return i
	return 0


static func standard_gauntlet_index(main) -> int:
	return first_part(main, func(part: Dictionary) -> bool:
		return String(part.get("name", "")) == MainScene.STANDARD_GAUNTLET_NAME
	)


static func first_part(main, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if predicate.call(part):
			return i
	return -1


static func build_fixture(main, terminal_index: int = -1, module_index: int = -1, include_binding: bool = true) -> Dictionary:
	prepare_main(main)
	if module_index < 0:
		module_index = boot_module_index(main)
	if terminal_index < 0:
		terminal_index = standard_gauntlet_index(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", first_rotating_limb(main), Vector2.RIGHT)
	var weapon: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "BOOT", "muscle", terminal_index, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	var weapon_part: Dictionary = main._selected_component("hero", "muscle", terminal_index)
	var extension: float = float(main._boot_driver_weapon_extension_m(weapon_part, module_part))
	if include_binding:
		unit_bp["module_bindings"] = [{
			"software_slot_index": 0,
			"module_index": module_index,
			"attack_key": 1,
			"target_kind": "boot_driver_limb_group",
			"root_index": limb,
			"target_nodes": [limb, weapon],
			"target_torso_node": torso,
			"boot_driver_rotating_node": limb,
			"boot_driver_weapon_node": weapon,
			"boot_driver_extension_m": extension,
			"binding_valid_note": "OK",
		}]
	return {
		"unit_bp": unit_bp,
		"torso": torso,
		"limb": limb,
		"weapon": weapon,
		"module_index": module_index,
		"terminal_index": terminal_index,
		"extension": extension,
	}


static func build_two_limb_fixture(main, module_index: int = -1) -> Dictionary:
	prepare_main(main)
	if module_index < 0:
		module_index = boot_module_index(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", first_rotating_limb(main), Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", first_rotating_limb(main), Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return {
		"unit_bp": unit_bp,
		"torso": torso,
		"limb_a": limb_a,
		"limb_b": limb_b,
		"module_index": module_index,
	}
