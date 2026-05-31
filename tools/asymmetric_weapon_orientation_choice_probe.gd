extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const AssemblyBoardRenderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part(main: Node, predicate: Callable) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if predicate.call(part):
			part["probe_index"] = i
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var scythe: Dictionary = _find_part(main, func(part: Dictionary) -> bool:
		return main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle")
	)
	if scythe.is_empty():
		_fail("No scythe terminal found in muscle catalog.")
		return
	if not main._part_supports_visual_handedness(scythe, "muscle"):
		_fail("Scythe terminal should support side-mount orientation choices.")
		return
	var node := AssemblyBoardRenderer.part_to_component_node("muscle", main._part_with_effective_terminal_geometry(scythe, "muscle"))
	if not bool(node.get("asymmetric_terminal", false)):
		_fail("Renderer component node did not expose asymmetric_terminal for scythe.")
		return
	if String(node.get("orientation_category", "")) != "orthogonal_side_mount":
		_fail("Renderer component node did not expose orthogonal_side_mount for scythe.")
		return
	if String(node.get("visual_mount_side", "")) != "right":
		_fail("Default scythe visual mount side should be right.")
		return
	var katana: Dictionary = _find_part(main, func(part: Dictionary) -> bool:
		return main._blade_weapon_family_for_part(part) == "katana" and main._part_counts_as_terminal_weapon(part, "muscle")
	)
	if not katana.is_empty() and main._part_supports_visual_handedness(katana, "muscle"):
		_fail("Symmetric/centerline katana should not force a left/right orientation choice.")
		return
	print("ASYMMETRIC_WEAPON_ORIENTATION_CHOICE_PROBE ok scythe=%s" % String(scythe.get("name", "")))
	quit()
