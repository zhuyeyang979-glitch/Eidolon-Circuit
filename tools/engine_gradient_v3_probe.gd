extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const REQUIRED_FIELDS := [
	"engine_momentum_output",
	"engine_heat_coeff",
	"engine_family",
	"mass",
	"cost",
	"slot_volume_tier",
]

const REQUIRED_FAMILIES := [
	"balanced",
	"melee_drive",
	"ranged_control",
	"booster_core",
	"swarm_lite",
	"siege_reactor",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ranks := {}
	var families := {}
	for part_raw in main._catalog_for("hero", "engine"):
		if not (part_raw is Dictionary):
			continue
		var part := Dictionary(part_raw)
		var name := String(part.get("name", "?"))
		for key in REQUIRED_FIELDS:
			if not part.has(key):
				_fail("%s missing %s" % [name, key])
		for legacy in ["power", "energy", "idle_heat", "engine_torque", "engine_motion_scale", "required_power"]:
			if part.has(legacy):
				_fail("%s exposes legacy engine field %s" % [name, legacy])
		var rank := int(main._payload_slot_volume_rank("engine", part, {"kind": "engine"}, "engine"))
		ranks[rank] = true
		families[String(part.get("engine_family", "")).to_lower()] = true
		if float(part.get("engine_momentum_output", 0.0)) + 0.01 < main._economy_engine_momentum_target(rank):
			_fail("%s below same-tier momentum target." % name)
		if float(part.get("engine_heat_coeff", 0.0)) <= 0.0:
			_fail("%s has invalid engine_heat_coeff." % name)
	for rank in [1, 2, 3, 4, 5]:
		if not ranks.has(rank):
			_fail("Missing engine slot tier rank %d." % rank)
	for family in REQUIRED_FAMILIES:
		if not families.has(family):
			_fail("Missing engine family %s." % family)
	print("ENGINE_GRADIENT_V3_PROBE ok families=%d" % families.size())
	quit()
