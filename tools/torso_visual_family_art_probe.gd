extends SceneTree

const PartArt := preload("res://scripts/part_art.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)


func _shape_delta(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var total := 0.0
	var count := mini(a.size(), b.size())
	for i in range(count):
		total += a[i].distance_to(b[i])
	return total / maxf(1.0, float(count))


func _expect_family(part: Dictionary, expected: String) -> PackedVector2Array:
	var family := PartArt.torso_visual_family(part)
	if family != expected:
		_fail("%s expected family %s got %s" % [String(part.get("name", "")), expected, family])
	var points := PartArt.torso_hull_local_points(part)
	if points.size() < 16:
		_fail("%s hull has too few points: %d" % [String(part.get("name", "")), points.size()])
	var box := _bounds(points)
	if box.size.x <= 0.1 or box.size.y <= 0.1:
		_fail("%s hull bounds collapsed: %s" % [String(part.get("name", "")), str(box)])
	var ports := PartArt.torso_hull_port_local_offsets(part, int(part.get("joint_ports", 6)))
	if ports.size() != int(part.get("joint_ports", 6)):
		_fail("%s port count mismatch: %d" % [String(part.get("name", "")), ports.size()])
	return points


func _init() -> void:
	var robot := {"slot": "muscle", "is_torso": true, "name": "HUMANOVA DUEL CORE", "shape": "humanoid_chest", "joint_ports": 5}
	var ship := {"slot": "muscle", "is_torso": true, "name": "SYNTAX MIDFIELD CORE", "shape": "spacecraft_hull", "joint_ports": 6}
	var shell := {"slot": "muscle", "is_torso": true, "name": "CRAB TORSO CHASSIS", "shape": "crab_carcass", "joint_ports": 4}
	var spine := {"slot": "muscle", "is_torso": true, "name": "HOUND SPINE CHASSIS", "shape": "hound_spine", "joint_ports": 6}
	var robot_points := _expect_family(robot, "robot_core")
	var ship_points := _expect_family(ship, "spacecraft_hull")
	var shell_points := _expect_family(shell, "carapace")
	var spine_points := _expect_family(spine, "spine")
	if _shape_delta(robot_points, ship_points) < 0.04:
		_fail("Robot and spacecraft torso silhouettes are too similar.")
	if _shape_delta(shell_points, spine_points) < 0.04:
		_fail("Carapace and spine torso silhouettes are too similar.")
	var runtime_hull := Renderer.component_polygon(Vector2.ZERO, ship, Vector2.RIGHT, 0.09, 0.32, false)
	if runtime_hull.size() != ship_points.size():
		_fail("Runtime torso hull did not use PartArt hull source: %d vs %d" % [runtime_hull.size(), ship_points.size()])
	print("TORSO_VISUAL_FAMILY_ART_PROBE ok")
	quit(0)
