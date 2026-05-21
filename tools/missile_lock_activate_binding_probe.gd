extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _module_index(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == profile:
			return i
	return -1


func _part_index(main, name: String) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if String(main._selected_component("hero", "muscle", i).get("name", "")) == name:
			return i
	return -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _build_unit(main, module_index: int, gun_part_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", 0, Vector2.RIGHT)
	var gun: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "MISSILE", "muscle", gun_part_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	unit_bp["_probe_gun_node"] = gun
	return unit_bp


func _prepare_editor(main, unit_bp: Dictionary) -> void:
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _module_index(main, "missile_lock_activate")
	var missile_index := _part_index(main, MainScene.STANDARD_MISSILE_NAME)
	var laser_index := _part_index(main, MainScene.STANDARD_LASER_NAME)
	if module_index < 0 or missile_index < 0 or laser_index < 0:
		_fail("Missing module, missile, or laser catalog entry.")
		quit(1)
		return
	var module_part := main._selected_component("hero", "module", module_index)
	var missile_unit := _build_unit(main, module_index, missile_index)
	_prepare_editor(main, missile_unit)
	main._start_editor_module_binding_flow(0, module_part)
	main._complete_pending_module_binding_with_selection(missile_unit, [int(missile_unit.get("_probe_gun_node", -1))])
	if not bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Kestrel Missile Lock should accept standard missile terminal.")
	main._set_pending_module_attack_key(2)
	if Array(missile_unit.get("module_bindings", [])).size() != 1:
		_fail("Missile binding should save one binding.")
	var laser_unit := _build_unit(main, module_index, laser_index)
	_prepare_editor(main, laser_unit)
	main._start_editor_module_binding_flow(0, module_part)
	main._complete_pending_module_binding_with_selection(laser_unit, [int(laser_unit.get("_probe_gun_node", -1))])
	if bool(main.editor_pending_module_binding.get("target_selected", false)):
		_fail("Kestrel Missile Lock should reject laser gun terminals.")
	if failed:
		quit(1)
		return
	print("MISSILE_LOCK_ACTIVATE_BINDING_PROBE ok")
	quit()
