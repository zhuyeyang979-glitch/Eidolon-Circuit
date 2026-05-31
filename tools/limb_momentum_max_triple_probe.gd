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
	for slot in ["limb_muscle", "muscle"]:
		for i in range(main._catalog_for("hero", slot).size()):
			var part: Dictionary = Dictionary(main._catalog_for("hero", slot)[i])
			if main._component_is_torso(part) or main._joint_drive_kind_for_part(part, slot) == "rigid":
				continue
			var raw_max := main._limb_momentum_raw_max_for_part(part, slot)
			var scaled_max := main._limb_momentum_max_for_part(part, slot)
			if raw_max > 0.0 and absf(scaled_max - raw_max * MainScene.LIMB_MOMENTUM_MAX_SCALE) > 0.01:
				_fail("Limb max should be 3x raw for %s: raw %.3f scaled %.3f" % [String(part.get("name", "LIMB")), raw_max, scaled_max])
			checked += 1
	if checked <= 0:
		_fail("No driven limbs found.")
	print("LIMB_MOMENTUM_MAX_TRIPLE_PROBE ok checked=%d" % checked)
	quit()
