extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const REQUIRED_FIELDS := [
	"momentum_min",
	"momentum_max",
	"allocated_momentum",
	"move_efficiency",
	"boost_efficiency",
	"turn_efficiency",
	"brake_efficiency",
	"boost_momentum",
	"boost_duration",
	"boost_cooldown",
	"boost_heat",
	"boost_angle_degrees",
	"movement_profile",
	"thruster_family",
]

const REQUIRED_FAMILIES := [
	"cruise_blue",
	"sustain_yellow",
	"overburn_red",
	"counter_brake",
	"swarm_micro",
	"titan_vector",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ranks := {}
	var target_ranks := {}
	var families := {}
	for part_raw in main._catalog_for("hero", "booster"):
		if not (part_raw is Dictionary):
			continue
		var part := Dictionary(part_raw)
		var name := String(part.get("name", "?"))
		for key in REQUIRED_FIELDS:
			if not part.has(key):
				_fail("%s missing %s" % [name, key])
		for legacy in ["normal_thrust", "boost_power", "thruster_momentum", "boost_cone", "booster_size"]:
			if part.has(legacy):
				_fail("%s exposes legacy thruster field %s" % [name, legacy])
		if float(part.get("momentum_max", 0.0)) < float(part.get("momentum_min", 0.0)):
			_fail("%s has invalid momentum range." % name)
		var rank := int(main._payload_slot_volume_rank("booster", part, {"kind": "booster"}, "booster"))
		ranks[rank] = true
		families[String(part.get("thruster_family", "")).to_lower()] = true
		var median := float(MainScene.ECONOMY_MEDIAN_MASS_BY_RANK.get(rank, 48.0))
		if main._booster_normal_momentum_for_part(part) + 0.01 >= median * 2.0 and main._thruster_boost_total_momentum_for_part(part) + 0.01 >= median * 4.0:
			target_ranks[rank] = true
	for rank in [1, 2, 3, 4, 5]:
		if not ranks.has(rank):
			_fail("Missing thruster slot tier rank %d." % rank)
		if not target_ranks.has(rank):
			_fail("Missing same-tier movement target thruster for rank %d." % rank)
	for family in REQUIRED_FAMILIES:
		if not families.has(family):
			_fail("Missing thruster family %s." % family)
	print("THRUSTER_GRADIENT_V3_PROBE ok families=%d" % families.size())
	quit()
