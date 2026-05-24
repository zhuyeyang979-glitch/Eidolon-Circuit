extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_all(tags: PackedStringArray, required: Array) -> bool:
	for raw in required:
		if not tags.has(String(raw)):
			return false
	return true


func _node(shape: String, material: String, name: String = "") -> Dictionary:
	return {
		"slot": "limb_muscle",
		"name": name if name != "" else "%s %s" % [material, shape],
		"shape": shape,
		"material_class": material,
		"limb_material_visual": material,
	}


func _init() -> void:
	var cases := [
		{"node": _node("steel_sinew_beam", "metal"), "material": "metal", "tags": ["metal_rivets", "hard_edges", "i_beam"]},
		{"node": _node("ceramic_linear_strut", "ceramic"), "material": "ceramic", "tags": ["ceramic_plate_lines", "linear_rail"]},
		{"node": _node("barrier_strut", "wood", "TIMBER BARRIER STRUT"), "material": "wood", "tags": ["wood_grain", "timber_support"]},
		{"node": _node("flex_tendon", "flex"), "material": "flex", "tags": ["fiber_strands", "soft_bundle", "fiber_bundle"]},
		{"node": _node("chain_muscle", "chain"), "material": "chain", "tags": ["chain_segments", "metal_rivets"]},
		{"node": _node("colossus_girder_muscle", "metal"), "material": "metal", "tags": ["truss_girder", "giant_muscle_wrap"]},
		{"node": _node("barrier_strut", "hardlight", "HARDLIGHT BARRIER STRUT"), "material": "hardlight", "tags": ["barrier_glow_edges", "hard_barrier_beam"]},
	]
	for item in cases:
		var node: Dictionary = item.get("node", {})
		var material := String(item.get("material", ""))
		if PartArt.limb_material_visual(node) != material:
			_fail("Expected material %s for %s, got %s." % [material, String(node.get("name", "")), PartArt.limb_material_visual(node)])
		var tags := Renderer.limb_visual_detail_tags(node)
		if not _has_all(tags, Array(item.get("tags", []))):
			_fail("Missing material/detail tags for %s: have %s need %s" % [String(node.get("name", "")), str(tags), str(item.get("tags", []))])
	print("LIMB_MATERIAL_VISUAL_LAYERS_PROBE ok cases=%d" % cases.size())
	quit()
