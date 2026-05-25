extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const GENERIC_GUN_CASES := {
	"sniper": ["bullet", "gun_activate"],
	"sprayer": ["chemical", "gun_activate"],
	"rifle": ["bullet", "rifle_burst_activate"],
	"laser_gun": ["laser", "laser_beam_activate"],
	"grenade_launcher": ["explosive", "grenade_arc_activate"],
	"missile_launcher": ["explosive", "missile_lock_activate"],
	"web_gun": ["web", "web_tether_activate"],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _gun_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "gun_activate":
			return i
	return -1


func _sniper_terminal(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._gun_activation_profile_supports_kind("gun_activate", String(part.get("gun_kind", main._gun_kind_for_data(part))), String(part.get("ammo_kind", main._ammo_kind_for_data(part)))):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _gun_module(main)
	var gun_index := _sniper_terminal(main)
	if module_index < 0 or gun_index < 0:
		_fail("Gun Activate module or legal gun terminal missing.")
	for gun_kind in GENERIC_GUN_CASES.keys():
		var expected: Array = GENERIC_GUN_CASES[gun_kind]
		var ammo_kind := String(expected[0])
		var effective_profile := String(expected[1])
		if not main._gun_activation_profile_supports_kind("gun_activate", String(gun_kind), ammo_kind):
			_fail("Generic Gun Activate UI contract rejected %s/%s." % [String(gun_kind), ammo_kind])
		if main._effective_gun_activation_profile("gun_activate", String(gun_kind), ammo_kind) != effective_profile:
			_fail("Generic Gun Activate UI contract resolved %s incorrectly." % String(gun_kind))
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var gun_node := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "GUN", "muscle", gun_index, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var candidate := main._pending_module_binding_candidate_for_node(unit_bp, gun_node)
	if candidate.is_empty() or not bool(candidate.get("valid", false)):
		_fail("Gun terminal did not resolve to a legal Gun Activate binding candidate: %s" % String(candidate.get("note", "")))
	main._complete_pending_module_binding_with_selection(unit_bp, Array(candidate.get("selection", [])))
	main._set_pending_module_attack_key(2)
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime_bindings.size() != 1:
		_fail("Gun Activate UI binding did not create one runtime binding.")
	var binding: Dictionary = Dictionary(runtime_bindings[0])
	if not bool(binding.get("runtime_valid", false)) or String(binding.get("target_kind", "")) != "gun_terminal":
		_fail("Gun Activate runtime binding invalid: %s" % String(binding.get("binding_valid_note", "")))
	print("GUN_ACTIVATE_BINDING_REAL_UI_PROBE ok")
	quit()
