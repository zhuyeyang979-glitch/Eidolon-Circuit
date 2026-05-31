extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const FIREARMS := [
	{"gun_kind": "sniper", "ammo_kind": "bullet"},
	{"gun_kind": "sprayer", "ammo_kind": "chemical"},
	{"gun_kind": "rifle", "ammo_kind": "bullet"},
	{"gun_kind": "laser_gun", "ammo_kind": "laser"},
	{"gun_kind": "grenade_launcher", "ammo_kind": "explosive"},
	{"gun_kind": "missile_launcher", "ammo_kind": "explosive"},
	{"gun_kind": "web_gun", "ammo_kind": "web"},
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_index(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == "gun_activate":
			return i
	return -1


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _gun_index(main, gun_kind: String, ammo_kind: String) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_gun_muscle(part, "muscle"):
			continue
		if String(part.get("gun_kind", main._gun_kind_for_data(part))) != gun_kind:
			continue
		if String(part.get("ammo_kind", main._ammo_kind_for_data(part))) != ammo_kind:
			continue
		if not main._part_is_catalog_frozen("muscle", part):
			return i
	return -1


func _unit_with_gun(main, module_index: int, gun_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ARM", "limb_muscle", 0, Vector2.RIGHT)
	var gun: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "GUN", "muscle", gun_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	unit_bp["_probe_gun_node"] = gun
	return unit_bp


func _bind_case(main, module_index: int, firearm: Dictionary) -> void:
	var gun_kind := String(firearm.get("gun_kind", ""))
	var ammo_kind := String(firearm.get("ammo_kind", ""))
	var gun_index := _gun_index(main, gun_kind, ammo_kind)
	if gun_index < 0:
		_fail("Missing live firearm terminal %s/%s." % [gun_kind, ammo_kind])
		return
	var unit_bp := _unit_with_gun(main, module_index, gun_index)
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_canvas_mode = "blank"
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var gun_node := int(unit_bp.get("_probe_gun_node", -1))
	var candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, gun_node)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Generic Gun Activate candidate rejected %s/%s: %s" % [gun_kind, ammo_kind, String(candidate.get("note", ""))])
		return
	main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [])))
	main._set_pending_module_attack_key(1)
	var bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if bindings.size() != 1:
		_fail("Generic Gun Activate did not save one runtime binding for %s." % gun_kind)
		return
	var binding: Dictionary = bindings[0]
	if not bool(binding.get("runtime_valid", false)) or String(binding.get("module_action_profile", "")) != "gun_activate":
		_fail("Generic binding invalid for %s: %s." % [gun_kind, String(binding.get("binding_valid_note", ""))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var module_index := _module_index(main)
	if module_index < 0:
		_fail("Generic Gun Activate module missing.")
		return
	for firearm in FIREARMS:
		_bind_case(main, module_index, firearm)
	print("GUN_ACTIVATE_ALL_LIVE_FIREARMS_BINDING_PROBE ok count=%d" % FIREARMS.size())
	quit()
