extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main.mobius_enabled = true
	main.camera_mobius_s = MainScene.RING_LENGTH
	var raw_collider := {
		"shape": "circle",
		"center": Vector2(0.10, -1.0),
		"radius": 0.2,
	}
	var shifted: Dictionary = main._shift_collider_to_origin(raw_collider, MainScene.RING_LENGTH - 0.10, 1.0)
	var shifted_center: Vector2 = shifted.get("center", Vector2.ZERO)
	if absf(shifted_center.x - (MainScene.RING_LENGTH + 0.10)) > 0.01:
		_fail("Seam collider should align to adjacent lifted x sheet; got %.3f" % shifted_center.x)
	if absf(shifted_center.y - 1.0) > 0.01:
		_fail("Seam collider should flip lane on the adjacent Möbius sheet; got %.3f" % shifted_center.y)
	print("MOBIUS_COLLISION_SHEET_PROBE ok shifted=(%.3f, %.3f)" % [shifted_center.x, shifted_center.y])
	quit()
