extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const REQUIRED_FIELDS := [
	"cooling_rate",
	"heat_capacity",
	"heat_dissipation",
	"cooling_family",
	"mass",
	"cost",
	"slot_volume_tier",
]

const REQUIRED_FAMILIES := [
	"compact",
	"stable",
	"boost_sink",
	"melee_module",
	"ranged_low_heat",
	"titan_radiator",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var families := {}
	var ranks := {}
	for part_raw in main._catalog_for("hero", "cooling"):
		if not (part_raw is Dictionary):
			continue
		var part := Dictionary(part_raw)
		var name := String(part.get("name", "?"))
		for key in REQUIRED_FIELDS:
			if not part.has(key):
				_fail("%s missing %s" % [name, key])
		if part.has("cooling"):
			_fail("%s still exposes legacy cooling alias in v3 catalog output." % name)
		if float(part.get("cooling_rate", 0.0)) <= 0.0:
			_fail("%s has no cooling_rate." % name)
		families[String(part.get("cooling_family", ""))] = true
		ranks[int(main._volume_tier_rank(String(part.get("slot_volume_tier", "XS"))))] = true
	for family in REQUIRED_FAMILIES:
		if not families.has(family):
			_fail("Missing cooling family %s." % family)
	for rank in [1, 2, 3, 4, 5]:
		if not ranks.has(rank):
			_fail("Missing cooling slot tier rank %d." % rank)
	print("COOLING_GRADIENT_V3_PROBE ok families=%d" % families.size())
	quit()
