extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var torso := Renderer.saddle_polygon(Vector2.ZERO, Vector2.RIGHT, 1.0, 0.35, 0.7)
	if torso.size() < 12:
		_fail("Torso saddle collision hull is not rounded enough: %d points" % torso.size())
	var limb := Renderer.component_polygon(Vector2.ZERO, {"slot": "limb_muscle", "material_class": "metal"}, Vector2.RIGHT, 0.08, 0.8, false)
	if limb.size() < 10:
		_fail("Limb collision hull is still rectangular: %d points" % limb.size())
	var blade := Renderer.component_polygon(Vector2.ZERO, {"slot": "muscle", "terminal_weapon": true, "damage_type": "tear", "material_class": "weapon", "connection_ends": 1}, Vector2.RIGHT, 0.08, 0.7, false)
	if blade.size() < 10:
		_fail("Terminal weapon hull is not smooth: %d points" % blade.size())
	print("ROUNDED_COLLISION_SHAPE_PROBE ok torso=%d limb=%d blade=%d" % [torso.size(), limb.size(), blade.size()])
	quit()
