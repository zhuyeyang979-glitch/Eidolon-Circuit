extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var checked := 0
	var boosted := 0
	for i in range(main._catalog_for("hero", "booster").size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", "booster")[i])
		var drive_min := main._thruster_drive_allocation_min_for_part(part)
		var drive_max := main._thruster_drive_allocation_max_for_part(part)
		var boost_min := main._thruster_boost_brake_allocation_min_for_part(part)
		var boost_max := main._thruster_boost_brake_allocation_max_for_part(part)
		if drive_min > 0.0 and absf(drive_max - drive_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT) > 0.01:
			_fail("Drive allocation max should be 3x min for %s: %.3f -> %.3f" % [String(part.get("name", "BOOSTER")), drive_min, drive_max])
		if boost_min > 0.0:
			boosted += 1
			if absf(boost_max - boost_min * MainScene.THRUSTER_ALLOCATION_MAX_MULT) > 0.01:
				_fail("Boost/brake allocation max should be 3x min for %s: %.3f -> %.3f" % [String(part.get("name", "BOOSTER")), boost_min, boost_max])
		elif boost_max != 0.0:
			_fail("No-boost thruster should have 0..0 boost/brake range for %s" % String(part.get("name", "BOOSTER")))
		var high_payload := {
			"thruster_drive_allocated_momentum": drive_max * 4.0 + 1.0,
			"thruster_boost_brake_allocated_momentum": boost_max * 4.0 + 1.0,
		}
		var low_payload := {
			"thruster_drive_allocated_momentum": -100.0,
			"thruster_boost_brake_allocated_momentum": -100.0,
		}
		if absf(main._thruster_drive_allocated_for_payload(high_payload, part) - drive_max) > 0.01:
			_fail("Drive allocation did not clamp to max for %s" % String(part.get("name", "BOOSTER")))
		if absf(main._thruster_drive_allocated_for_payload(low_payload, part) - drive_min) > 0.01:
			_fail("Drive allocation did not clamp to min for %s" % String(part.get("name", "BOOSTER")))
		if absf(main._thruster_boost_brake_allocated_for_payload(high_payload, part) - boost_max) > 0.01:
			_fail("Boost/brake allocation did not clamp to max for %s" % String(part.get("name", "BOOSTER")))
		if absf(main._thruster_boost_brake_allocated_for_payload(low_payload, part) - boost_min) > 0.01:
			_fail("Boost/brake allocation did not clamp to min for %s" % String(part.get("name", "BOOSTER")))
		checked += 1
	if checked <= 0:
		_fail("No hero boosters found.")
	if boosted <= 0:
		_fail("Probe needs at least one boost-capable thruster.")
	print("THRUSTER_DUAL_ALLOCATION_RANGE_PROBE ok checked=%d boosted=%d" % [checked, boosted])
	quit()
