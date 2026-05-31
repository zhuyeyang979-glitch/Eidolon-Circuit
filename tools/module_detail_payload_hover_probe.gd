extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_torso(main) -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if main._component_is_torso(part) and int(part.get("module_slots", 0)) > 0:
			return i
	return -1


func _module_index_by_profile(main, profile: String) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return i
	return -1


func _joined(values: Array) -> String:
	var text := ""
	for value in values:
		text += " %s" % String(value)
	return text


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "zh"
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var torso_index := _find_torso(main)
	if torso_index < 0:
		_fail("No torso with module slots found.")
	main._set_pending_canvas_part(unit_bp, "muscle", torso_index)
	var torso_node: int = main._add_topology_node_at(Vector2(500.0, 302.0))
	if torso_node < 0:
		_fail("Could not place torso.")
	main._open_editor_torso_detail(torso_node)
	var module_index := _module_index_by_profile(main, "blunt_shield_guard_bash")
	if module_index < 0:
		_fail("Shield Guard-Bash module missing.")
	main._drop_catalog_part_on_torso_detail("module", module_index, "software")
	var payloads: Array = Array(unit_bp.get("slot_payloads", []))
	if payloads.is_empty():
		_fail("Module payload was not installed on torso.")
	main._hover_torso_detail_payload("software", 0, 0)
	if main.editor_hover_popup_view == null or not main.editor_hover_popup_view.visible:
		_fail("Payload hover popup did not open.")
	if main.editor_hover_popup_view.size.y < 490.0:
		_fail("Payload hover popup is too short for module detail lines: %s" % str(main.editor_hover_popup_view.size))
	if String(main.editor_hover_popup_view.slot_key) != "module":
		_fail("Payload hover did not resolve to module slot.")
	var joined := _joined(Array(main.editor_hover_popup_view.detail_lines))
	for term in ["行动模块", "盾牌", "236X必杀", "214X必杀", "数据："]:
		if joined.find(term) < 0:
			_fail("Payload hover missing %s in %s" % [term, joined])
	print("MODULE_DETAIL_PAYLOAD_HOVER_PROBE ok")
	quit()
