extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _split_sides(dirs: Array) -> Dictionary:
	var top: Array = []
	var bottom: Array = []
	var front := 0
	for dir in dirs:
		var v: Vector2 = dir
		if v.dot(Vector2.RIGHT) > 0.98 and absf(v.y) < 0.08:
			front += 1
		elif v.y < -0.02:
			top.append(v)
		elif v.y > 0.02:
			bottom.append(v)
	return {"front": front, "top": top, "bottom": bottom}


func _expect_symmetric_pairs(label: String, top: Array, bottom: Array) -> void:
	_expect(top.size() == bottom.size(), "%s side counts not symmetric: %d/%d" % [label, top.size(), bottom.size()])
	for i in range(top.size()):
		var a: Vector2 = top[i]
		var b: Vector2 = bottom[i]
		if absf(a.x - b.x) > 0.06 or absf(a.y + b.y) > 0.06:
			_fail("%s side port %d not mirrored: %s vs %s" % [label, i, str(a), str(b)])


func _hull_bounds(part: Dictionary) -> Rect2:
	var points := PartArt.torso_hull_local_points(part)
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)


func _expect_ports_on_boundary(count: int, part: Dictionary, offsets: Array) -> void:
	var bounds := _hull_bounds(part)
	for raw_offset in offsets:
		var p: Vector2 = raw_offset
		if p.x > bounds.end.x + 0.001 or p.x < bounds.position.x - 0.001:
			_fail("%d-port hull port drifted outside length bounds: %s vs %s" % [count, str(p), str(bounds)])
		if p.y > bounds.end.y + 0.001 or p.y < bounds.position.y - 0.001:
			_fail("%d-port hull port drifted outside width bounds: %s vs %s" % [count, str(p), str(bounds)])
		if absf(p.y) > 0.001 and absf(absf(p.y) - maxf(absf(bounds.position.y), absf(bounds.end.y))) < 0.001:
			_fail("%d-port hull port snapped to rectangular max width instead of shaped side: %s" % [count, str(p)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for count in range(1, 7):
		var torso := {
			"name": "%d PORT SADDLE TORSO" % count,
			"is_torso": true,
			"material_class": "torso",
			"joint_ports": count,
			"connection_ends": count,
		}
		var dirs: Array = main._torso_port_directions(torso)
		_expect(dirs.size() == count, "%d-port torso returned %d directions." % [count, dirs.size()])
		var offsets: Array = PartArt.torso_hull_port_local_offsets(torso, count)
		_expect(offsets.size() == count, "%d-port local offsets returned %d points." % [count, offsets.size()])
		_expect_ports_on_boundary(count, torso, offsets)
		var split := _split_sides(dirs)
		var expected_front := 1 if count in [1, 3, 5] else 0
		_expect(int(split["front"]) == expected_front, "%d-port torso front-center count expected %d got %d." % [count, expected_front, int(split["front"])])
		_expect_symmetric_pairs("%d-port torso" % count, split["top"], split["bottom"])
		match count:
			1:
				_expect(Array(split["top"]).is_empty() and Array(split["bottom"]).is_empty(), "1-port torso should only have the short-edge front port.")
			2, 3:
				_expect(Array(split["top"]).size() == 1, "%d-port torso should have one port on each waist." % count)
			4, 5:
				_expect(Array(split["top"]).size() == 2, "%d-port torso should have two ports on each waist." % count)
			6:
				_expect(Array(split["top"]).size() == 3, "6-port torso should have three ports on each waist.")
	var overport := {
		"name": "OLD OCTOPUS OVERPORT",
		"is_torso": true,
		"material_class": "torso",
		"joint_ports": 14,
		"connection_ends": 14,
	}
	_expect(main._torso_port_directions(overport).size() == 6, "Old over-port torso was not capped to 6 ports.")
	_expect(PartArt.connector_count_for("torso", overport) == 6, "PartArt connector count did not cap over-port torso to 6.")
	_expect(PartArt.shape_kind_for("torso", overport) == "saddle_torso", "PartArt torso shape kind is not saddle_torso.")
	print("TORSO_SADDLE_PORTS_PROBE ok 1-6 ports + overport clamp")
	quit()
