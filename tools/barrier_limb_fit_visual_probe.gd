extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_p := poly[0]
	var max_p := poly[0]
	for p in poly:
		min_p = Vector2(minf(min_p.x, p.x), minf(min_p.y, p.y))
		max_p = Vector2(maxf(max_p.x, p.x), maxf(max_p.y, p.y))
	return Rect2(min_p, max_p - min_p)


func _has_tag(tags: PackedStringArray, options: Array) -> bool:
	for raw in options:
		if tags.has(String(raw)):
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var found := 0
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if main._part_is_catalog_frozen("limb_muscle", part):
			continue
		var display: Dictionary = main._catalog_display_part("limb_muscle", part)
		var fit_tags := PartArt.limb_barrier_fit_tags_for(display)
		if fit_tags.is_empty():
			continue
		found += 1
		var node := Renderer.part_to_component_node("limb_muscle", display)
		var family := PartArt.limb_visual_family(node)
		if not (family in ["steel_sinew_beam", "ceramic_linear_strut", "colossus_girder_muscle", "barrier_strut", "chain_muscle", "tentacle", "flex_tendon"]):
			_fail("Barrier-fit limb %s has soft/unreadable family %s." % [String(part.get("name", "")), family])
		var tags := Renderer.limb_visual_detail_tags(node)
		if not _has_tag(tags, ["hard_barrier_beam", "maze_fit", "i_beam", "linear_rail", "truss_girder", "chain_segments", "fiber_bundle"]):
			_fail("Barrier-fit limb lacks readable detail tags: %s tags=%s" % [String(part.get("name", "")), str(tags)])
		var poly := Renderer.component_polygon(Vector2.ZERO, node, Vector2.RIGHT, 10.0, 110.0, true)
		var rect := _bounds(poly)
		if rect.size.x < 90.0 or rect.size.y < 6.0:
			_fail("Barrier-fit limb visual too faint: %s bounds=%s" % [String(part.get("name", "")), str(rect)])
	if found < 4:
		_fail("Expected several barrier-fit limb visuals, found %d." % found)
	print("BARRIER_LIMB_FIT_VISUAL_PROBE ok fit_limbs=%d" % found)
	quit()
