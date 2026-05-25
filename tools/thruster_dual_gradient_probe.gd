extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var by_family := {}
	var checked := 0
	for i in range(main._catalog_for("hero", "booster").size()):
		var part: Dictionary = main._thruster_with_drive_defaults(main._selected_component("hero", "booster", i))
		var family := String(part.get("thruster_family", "")).to_lower()
		var rank := int(main._payload_slot_volume_rank("booster", part, {"kind": "booster"}, "booster"))
		var drive_min := main._thruster_drive_allocation_min_for_part(part)
		var drive_max := main._thruster_drive_allocation_max_for_part(part)
		var boost_min := main._thruster_boost_brake_allocation_min_for_part(part)
		var boost_max := main._thruster_boost_brake_allocation_max_for_part(part)
		if drive_min <= 0.0 or drive_max + 0.01 < drive_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT:
			_fail("%s drive chain is not a valid 1x..3x range." % String(part.get("name", "?")))
		if boost_min > 0.0 and boost_max + 0.01 < boost_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT:
			_fail("%s boost/brake chain is not a valid 1x..3x range." % String(part.get("name", "?")))
		if not by_family.has(family):
			by_family[family] = {}
		by_family[family][rank] = maxf(float(by_family[family].get(rank, 0.0)), drive_max + boost_max)
		checked += 1
	for family in ["cruise_blue", "sustain_yellow", "overburn_red", "counter_brake", "swarm_micro", "titan_vector"]:
		if not by_family.has(family):
			_fail("Missing thruster family %s" % family)
	for family in by_family.keys():
		var previous := 0.0
		var ranks: Dictionary = by_family[family]
		for rank in range(1, 6):
			if not ranks.has(rank):
				continue
			var value := float(ranks[rank])
			if previous > 0.0 and value + 0.01 < previous * 0.62:
				_fail("%s rank %d dual allocation drops too sharply." % [String(family), rank])
			previous = maxf(previous, value)
	if checked <= 0:
		_fail("No boosters checked.")
	if failed:
		quit(1)
		return
	print("THRUSTER_DUAL_GRADIENT_PROBE ok checked=%d families=%d" % [checked, by_family.size()])
	quit()
