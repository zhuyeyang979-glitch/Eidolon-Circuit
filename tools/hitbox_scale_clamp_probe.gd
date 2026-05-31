extends SceneTree

const GameplayTransform := preload("res://scripts/gameplay_transform.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var near_scale := GameplayTransform.hitbox_scale_for_visual_scale(1.22)
	var far_scale := GameplayTransform.hitbox_scale_for_visual_scale(0.70)
	var min_scale := GameplayTransform.hitbox_scale_for_visual_scale(0.20)
	var max_scale := GameplayTransform.hitbox_scale_for_visual_scale(2.60)
	if absf(near_scale - 1.22) > 0.001:
		_fail("Strong hitbox scaling should fully match near visual scale.")
	if absf(far_scale - 0.70) > 0.001:
		_fail("Strong hitbox scaling should fully match far visual scale.")
	if absf(min_scale - GameplayTransform.DEFAULT_HITBOX_SCALE_MIN) > 0.001:
		_fail("Hitbox scale should keep a hard safety minimum.")
	if absf(max_scale - GameplayTransform.DEFAULT_HITBOX_SCALE_MAX) > 0.001:
		_fail("Hitbox scale should keep a hard safety maximum.")
	print("HITBOX_SCALE_CLAMP_PROBE ok far=%.2f near=%.2f clamp=%.2f..%.2f" % [far_scale, near_scale, min_scale, max_scale])
	quit()
