extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _approx(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) <= eps


func _find_terminal(main, ranged: bool) -> Dictionary:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = catalog[i]
		if not main._part_counts_as_terminal_weapon(part, "muscle"):
			continue
		if bool(main._part_is_ranged_terminal_weapon(part)) == ranged:
			var copy := part.duplicate(true)
			copy["_index"] = i
			return copy
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var melee := _find_terminal(main, false)
	var ranged := _find_terminal(main, true)
	if melee.is_empty() or ranged.is_empty():
		_fail("Need both melee and ranged terminal weapons for size probe.")
	var melee_adjusted: Dictionary = main._part_with_effective_terminal_geometry(melee, "muscle")
	var ranged_adjusted: Dictionary = main._part_with_effective_terminal_geometry(ranged, "muscle")
	if not _approx(float(melee_adjusted.get("length", 0.0)), float(melee.get("length", 0.0)) * MainScene.TERMINAL_MELEE_GEOMETRY_MULTIPLIER):
		_fail("Melee terminal length not scaled by 0.62.")
	if not _approx(float(ranged_adjusted.get("length", 0.0)), float(ranged.get("length", 0.0)) * MainScene.TERMINAL_RANGED_GEOMETRY_MULTIPLIER):
		_fail("Ranged terminal length not scaled by 0.70.")
	if not _approx(float(melee_adjusted.get("radius", 0.0)), float(melee.get("radius", 0.0)) * MainScene.TERMINAL_RADIUS_GEOMETRY_MULTIPLIER):
		_fail("Terminal radius not scaled by 0.75.")
	var role_key := "hero"
	var unit_bp := {"custom_topology": {"nodes": [], "edges": []}}
	var node := main._topology_component_node(0, "TIP", Vector2(0.5, 0.5), "muscle", int(melee["_index"]))
	var extent := main._topology_node_edge_extent_units(role_key, node, unit_bp)
	var node_part: Dictionary = main._topology_node_part(role_key, node, unit_bp)
	var node_effective: Dictionary = main._part_with_effective_terminal_geometry(node_part, "muscle")
	if not _approx(extent, float(node_effective.get("length", 0.0)) * 0.5):
		_fail("Topology terminal edge extent must use effective length. extent=%.4f expected=%.4f" % [extent, float(node_effective.get("length", 0.0)) * 0.5])
	print("TERMINAL_WEAPON_SIZE_PROBE melee=%.3f ranged=%.3f extent=%.3f" % [float(melee_adjusted.get("length", 0.0)), float(ranged_adjusted.get("length", 0.0)), extent])
	quit()
