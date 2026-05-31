extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_part(main: Node, predicate: Callable) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if predicate.call(part):
			return part
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var scythe := _find_part(main, func(part: Dictionary) -> bool:
		return main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle")
	)
	if scythe.is_empty():
		_fail("No scythe terminal found.")
		return
	if String(scythe.get("orientation_category", "")) != "orthogonal_side_mount":
		_fail("Scythe should expose orthogonal_side_mount category.")
		return
	if String(scythe.get("orientation_basis", "")) != "parent_normal":
		_fail("Scythe orientation basis should be parent_normal.")
		return
	if String(scythe.get("default_mount_side", "")) != "right":
		_fail("Scythe default mount side should be right.")
		return
	var choices: Array = Array(scythe.get("mount_side_choices", []))
	if not (choices.has("left") and choices.has("right")):
		_fail("Scythe mount side choices should include left/right.")
		return
	var katana := _find_part(main, func(part: Dictionary) -> bool:
		return main._blade_weapon_family_for_part(part) == "katana" and main._part_counts_as_terminal_weapon(part, "muscle")
	)
	if not katana.is_empty() and String(katana.get("orientation_category", "")) == "orthogonal_side_mount":
		_fail("Katana should not be an orthogonal side mount by default.")
		return
	print("ORTHOGONAL_SIDE_MOUNT_CATEGORY_PROBE ok scythe=%s" % String(scythe.get("name", "")))
	quit()
