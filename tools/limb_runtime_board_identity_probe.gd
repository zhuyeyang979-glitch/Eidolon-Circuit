extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _polygons_close(a: PackedVector2Array, b: PackedVector2Array, epsilon: float = 0.002) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i].distance_to(b[i]) > epsilon:
			return false
	return true


func _init() -> void:
	var segment := {
		"node_index": 8,
		"part_kind": "limb_muscle",
		"name": "Runtime Steel Limb",
		"a": Vector2(2.0, 1.0),
		"b": Vector2(3.1, 1.0),
		"radius": 0.08,
		"material_class": "metal",
		"shape": "capsule",
		"source_shape": "steel_sinew_beam",
	}
	var node := Renderer.segment_to_component_node(segment)
	if String(node.get("shape", "")) != "steel_sinew_beam":
		_fail("segment_to_component_node lost source_shape; got %s." % String(node.get("shape", "")))
	if String(node.get("limb_visual_family", "")) != "steel_sinew_beam":
		_fail("Runtime limb visual family not preserved.")
	var runtime_poly := Renderer.runtime_segment_overlay_polygon(segment, Vector2.ZERO, 0.0, 100.0)
	var a := Vector2(segment.get("a", Vector2.ZERO)) * 100.0
	var b := Vector2(segment.get("b", Vector2.ZERO)) * 100.0
	var board_poly := Renderer.component_polygon((a + b) * 0.5, node, b - a, float(segment.get("radius", 0.0)) * 100.0, a.distance_to(b), true)
	if not _polygons_close(runtime_poly, board_poly):
		_fail("Runtime overlay polygon and board polygon diverged.")
	print("LIMB_RUNTIME_BOARD_IDENTITY_PROBE ok points=%d family=%s" % [runtime_poly.size(), String(node.get("limb_visual_family", ""))])
	quit()
