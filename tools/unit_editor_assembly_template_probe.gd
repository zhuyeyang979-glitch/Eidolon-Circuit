extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const SCREENSHOT_PATH := "res://assets/concepts/parts/image2_individual/unit_editor_assembly_template_overlay_v1.png"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _first_torso(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._component_is_torso(part):
			return i
	return 0


func _first_terminal_weapon(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part) and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return 0


func _save_screenshot() -> bool:
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		return false
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return false
	return image.save_png(SCREENSHOT_PATH) == OK


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("ASSEMBLY_TEMPLATE_PROBE skipped headless")
		quit(0)
		return
	root.size = Vector2i(1280, 720)
	var main := MainScene.new()
	root.add_child(main)
	await process_frame
	main.loading_auto_transitions_enabled = false
	main.ui_language = "zh"
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	await process_frame

	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_index := _first_torso(main)
	var weapon_index := _first_terminal_weapon(main)
	main._drop_catalog_part_on_board("muscle", torso_index, Vector2(390.0, 280.0))
	await process_frame
	main._drop_catalog_part_on_board("limb_muscle", 0, Vector2(462.0, 280.0))
	await process_frame
	main._drop_catalog_part_on_board("muscle", weapon_index, Vector2(536.0, 280.0))
	await process_frame
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	if nodes.is_empty():
		_fail("Probe failed to place topology nodes.")
		return
	var torso_node_index := -1
	for i in range(nodes.size()):
		if nodes[i] is Dictionary and main._topology_node_is_torso("hero", Dictionary(nodes[i]), unit_bp):
			torso_node_index = i
			break
	if torso_node_index < 0:
		_fail("Probe failed to place a torso node.")
		return
	var engine_part: Dictionary = main._selected_component("hero", "engine", 0)
	unit_bp["slot_payloads"] = [{
		"kind": "engine",
		"engine": 0,
		"part_name": String(engine_part.get("name", "")),
		"torso_node": torso_node_index,
	}]
	main.editor_open_torso_node_index = -1
	main.editor_panel_mode = "parts"
	main.editor_part_group_mode = "software_muscle"
	main.editor_part_filter_mode = "all"
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("booster")
	main._invalidate_editor_catalog_cache()
	main.editor_visual_revision_key = ""
	main._refresh_editor_visual_views()
	await process_frame
	var template: Dictionary = main.assembly_board_view.board_snapshot.get("assembly_template_model", {})
	if template.is_empty():
		print("ASSEMBLY_TEMPLATE_DEBUG role=%s board_mode=%s has_topology=%s snapshot_keys=%s revision=%s visual_revision=%s" % [
			String(MainScene.ROLE_ORDER[main.editor_role_index]),
			String(main.assembly_board_view.board_mode),
			str(unit_bp.has("custom_topology")),
			str(main.assembly_board_view.board_snapshot.keys()),
			String(main.assembly_board_view.board_snapshot.get("revision_key", "")),
			String(main.editor_visual_revision_key),
		])
		_fail("Assembly template model was not submitted to the board snapshot.")
		return
	print("ASSEMBLY_TEMPLATE_MODEL %s" % JSON.stringify(template))
	for frame in range(5):
		RenderingServer.force_draw()
		await process_frame
	if not _save_screenshot():
		_fail("Could not save screenshot to %s" % SCREENSHOT_PATH)
		return
	print("ASSEMBLY_TEMPLATE_SCREENSHOT %s" % SCREENSHOT_PATH)
	quit(0)
