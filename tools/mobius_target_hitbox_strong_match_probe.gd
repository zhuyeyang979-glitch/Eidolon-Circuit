extends SceneTree

const Fighter := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var near_unit = Fighter.new()
	root.add_child(near_unit)
	near_unit.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 1.42, "depth01": 1.0, "brightness": 1.1, "z_index": 42}, true)
	var far_unit = Fighter.new()
	root.add_child(far_unit)
	far_unit.set_mobius_screen_projection({"position": Vector2.ZERO, "scale": 0.55, "depth01": 0.0, "brightness": 0.64, "z_index": -18}, true)
	if absf(near_unit.visual_hitbox_scale - 1.30) > 0.001 or absf(far_unit.visual_hitbox_scale - 0.70) > 0.001:
		_fail("Strong target-hitbox matching must follow display scale and clamp at 0.70..1.30; got %.3f/%.3f." % [near_unit.visual_hitbox_scale, far_unit.visual_hitbox_scale])
		return
	print("MOBIUS_TARGET_HITBOX_STRONG_MATCH_PROBE ok near=%.2f far=%.2f" % [near_unit.visual_hitbox_scale, far_unit.visual_hitbox_scale])
	quit()
