extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")
const PartArt := preload("res://scripts/part_art.gd")

const FAMILIES := [
	"forearm_myomer",
	"thigh_myomer",
	"flex_tendon",
	"chain_muscle",
	"steel_sinew_beam",
	"ceramic_linear_strut",
	"colossus_girder_muscle",
]


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


func _signature(poly: PackedVector2Array) -> String:
	var rect := _bounds(poly)
	return "%d|%.2f|%.2f|%.2f" % [poly.size(), rect.size.x, rect.size.y, rect.size.x / maxf(0.001, rect.size.y)]


func _init() -> void:
	var signatures := {}
	var widths := {}
	for family in FAMILIES:
		var node := {
			"slot": "limb_muscle",
			"name": family,
			"shape": family,
			"limb_visual_family": family,
			"material_class": "metal" if family.contains("steel") or family.contains("colossus") else "limb_muscle",
			"radius": 0.08,
		}
		var poly := Renderer.component_polygon(Vector2.ZERO, node, Vector2.RIGHT, 12.0, 96.0, true)
		if poly.size() < 6:
			_fail("%s polygon too simple: %d points." % [family, poly.size()])
		var rect := _bounds(poly)
		if rect.size.x < 80.0 or rect.size.y < 5.0:
			_fail("%s polygon has unreadable bounds %s." % [family, str(rect)])
		var sig := _signature(poly)
		if signatures.has(sig):
			_fail("%s shares polygon signature with %s: %s" % [family, String(signatures[sig]), sig])
		signatures[sig] = family
		widths[family] = rect.size.y
	if float(widths.get("forearm_myomer", 0.0)) >= float(widths.get("thigh_myomer", 0.0)):
		_fail("Forearm should read narrower than thigh.")
	if float(widths.get("steel_sinew_beam", 0.0)) <= float(widths.get("flex_tendon", 999.0)):
		_fail("Steel beam should read harder/wider than flex tendon.")
	if PartArt.limb_visual_family({"shape": "ceramic_linear_strut"}) != "ceramic_linear_strut":
		_fail("PartArt did not classify ceramic strut.")
	print("LIMB_SPECIFIC_POLYGON_PROBE ok signatures=%s" % str(signatures))
	quit()
