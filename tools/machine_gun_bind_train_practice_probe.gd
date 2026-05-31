extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _rifle_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "rifle_burst_activate":
			return i
	return -1


func _rifle_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_gun_muscle(part, "muscle"):
			continue
		var gun_kind := String(part.get("gun_kind", main._gun_kind_for_data(part)))
		var ammo_kind := String(part.get("ammo_kind", main._ammo_kind_for_data(part)))
		if main._gun_activation_profile_supports_kind("rifle_burst_activate", gun_kind, ammo_kind):
			return i
	return -1


func _first_catalog_index(main, slot_key: String) -> int:
	return 0 if main._catalog_for("hero", slot_key).size() > 0 else -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _rifle_module(main)
	var gun_index := _rifle_terminal(main)
	if module_index < 0 or gun_index < 0:
		_fail("Missing rifle burst module or legal rifle terminal.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var gun_node := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "RIFLE", "muscle", gun_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = "Rifle Practice Probe"
	unit_bp["slot_payloads"] = [
		{"kind": "module", "module": module_index, "torso_node": torso},
		{"kind": "engine", "engine": _first_catalog_index(main, "engine"), "internal_slot_index": 0, "torso_node": torso},
		{"kind": "booster", "booster": _first_catalog_index(main, "booster"), "internal_slot_index": 1, "torso_node": torso},
		{"kind": "cooling", "cooling": _first_catalog_index(main, "cooling"), "internal_slot_index": 2, "torso_node": torso},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var candidate := main._pending_module_binding_candidate_for_node(unit_bp, gun_node)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Rifle terminal did not resolve to a legal machine-gun/rifle binding candidate: %s" % String(candidate.get("note", "")))
	main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [])))
	main._set_pending_module_attack_key(2)
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime_bindings.size() != 1:
		_fail("Rifle module binding did not create one runtime binding.")
	var binding: Dictionary = Dictionary(runtime_bindings[0])
	if not bool(binding.get("runtime_valid", false)) or String(binding.get("module_action_profile", "")) != "rifle_burst_activate":
		_fail("Rifle runtime binding invalid: %s profile=%s" % [String(binding.get("binding_valid_note", "")), String(binding.get("module_action_profile", ""))])
	if not main._tryout_editor_bound_module(2):
		_fail("Bound rifle module could not enter board practice/tryout.")
	if String(main.editor_bound_module_tryout.get("preview_kind", "")) != "projectile":
		_fail("Rifle tryout did not expose projectile preview.")
	print("MACHINE_GUN_BIND_TRAIN_PRACTICE_PROBE ok profile=%s" % String(binding.get("module_action_profile", "")))
	quit()
