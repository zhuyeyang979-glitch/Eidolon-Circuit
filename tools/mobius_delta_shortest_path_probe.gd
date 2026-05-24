extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var loop := float(MainScene.RING_LENGTH)
	var from_coord := Vector2(loop - 0.10, 1.0)
	var to_coord := Vector2(0.10, -1.0)
	var delta := MobiusWorld.delta_vec(from_coord, to_coord, loop)
	if absf(delta.x - 0.20) > 0.01:
		_fail("Shortest Möbius seam delta should use adjacent lifted sheet; got x %.3f" % delta.x)
	if absf(delta.y) > 0.01:
		_fail("Shortest Möbius seam delta should flip lane on the adjacent sheet; got y %.3f" % delta.y)
	var torus_like_lane_delta := to_coord.y - from_coord.y
	if absf(torus_like_lane_delta) <= 1.5:
		_fail("Probe setup did not distinguish Möbius lane inversion from ordinary torus wrapping.")
	var many_loop_delta := MobiusWorld.delta_vec(Vector2(4.2, 0.4), Vector2(100.2, 0.4), loop)
	if many_loop_delta.length() > 0.01:
		_fail("Lifted coordinates several loops apart should still choose the nearest equivalent sheet; got %s" % [str(many_loop_delta)])
	print("MOBIUS_DELTA_SHORTEST_PATH_PROBE ok delta=(%.3f, %.3f)" % [delta.x, delta.y])
	quit()
