extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartArt := preload("res://scripts/part_art.gd")

const LEGAL_FAMILIES := [
	"forearm_myomer",
	"thigh_myomer",
	"flex_tendon",
	"chain_muscle",
	"tentacle",
	"steel_sinew_beam",
	"ceramic_linear_strut",
	"colossus_girder_muscle",
	"barrier_strut",
	"fur_sleeve",
	"two_end_muscle",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var families := {}
	var live_count := 0
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if main._part_is_catalog_frozen("limb_muscle", part):
			continue
		live_count += 1
		var display: Dictionary = main._catalog_display_part("limb_muscle", part)
		var family := PartArt.limb_visual_family(display)
		if not LEGAL_FAMILIES.has(family):
			_fail("Illegal live limb visual family %s on %s." % [family, String(part.get("name", ""))])
		if family == "two_end_muscle":
			_fail("Live limb still falls back to generic two_end_muscle: %s." % String(part.get("name", "")))
		if String(display.get("limb_visual_family", "")) != family:
			_fail("Display metadata missing limb_visual_family for %s." % String(part.get("name", "")))
		if String(display.get("limb_material_visual", "")) == "":
			_fail("Display metadata missing limb_material_visual for %s." % String(part.get("name", "")))
		if Array(display.get("limb_role_tags", [])).is_empty():
			_fail("Display metadata missing role tags for %s." % String(part.get("name", "")))
		families[family] = int(families.get(family, 0)) + 1
	for required in ["forearm_myomer", "thigh_myomer", "flex_tendon", "chain_muscle", "steel_sinew_beam", "ceramic_linear_strut", "colossus_girder_muscle", "fur_sleeve"]:
		if not families.has(required):
			_fail("Live limb catalog lacks visual family %s." % required)
	print("LIMB_VISUAL_FAMILY_PROBE ok live=%d families=%s" % [live_count, str(families)])
	quit()
