extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const POWER_DOCK_VIEW_PATH := "res://scripts/views/editor/unit_editor_power_dock_view.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_engine(main) -> int:
	for i in range(main._catalog_for("hero", "engine").size()):
		if main._engine_momentum_output_for_part(main._selected_component("hero", "engine", i)) > 0.0:
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	var engine_index := _first_engine(main)
	if module_index < 0 or engine_index < 0:
		_fail("Required engine or module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var chain: Array = []
	var parent := torso
	for i in range(7):
		var node := main._append_directed_component_node("hero", unit_bp, nodes, edges, parent, "L%d" % i, "limb_muscle", 0, Vector2.RIGHT)
		chain.append(node)
		parent = node
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	var by_node := {}
	for raw_node in chain:
		by_node[str(int(raw_node))] = 8.0
	unit_bp["module_bindings"] = [{
		"software_slot_index": 1,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": int(chain[0]),
		"target_nodes": chain.duplicate(true),
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": by_node,
		"joint_drive_allocation_by_node": by_node.duplicate(true),
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._refresh_unit_editor_power_allocation_dock()
	var entries: Array = main.editor_power_dock_view.entries
	var limb_count := 0
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "limb":
			limb_count += 1
	if limb_count < 6:
		_fail("Dock should expose all bound limb sliders, not truncate to the first few.")
	if float(main.editor_power_dock_view._max_scroll()) <= 0.0:
		_fail("Dock should become horizontally scrollable when entries exceed available width.")
	var source := FileAccess.get_file_as_string(POWER_DOCK_VIEW_PATH)
	if source.find("class_name UnitEditorPowerDockView") < 0:
		_fail("UnitEditorPowerDockView source should live in the extracted dock view file.")
	if source.contains("mini(entries.size(), 5)"):
		_fail("UnitEditorPowerDockView still hard-caps drawn entries at 5.")
	print("POWER_TOPBAR_ALL_BOUND_LIMBS_VISIBLE_PROBE ok entries=%d limbs=%d scroll=%.1f" % [entries.size(), limb_count, main.editor_power_dock_view._max_scroll()])
	quit()
