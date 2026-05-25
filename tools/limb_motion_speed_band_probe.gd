extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MotionBudgetScene := preload("res://scripts/motion_budget.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _duration_for(main, part: Dictionary, slot_key: String, momentum: float) -> float:
	var mass := maxf(0.45, float(part.get("mass", 1.0)))
	var distance: float = float(main._limb_motion_distance_for_part(part, slot_key))
	var cap: float = float(main._limb_joint_speed_cap_for_part(part, slot_key))
	var budget: Dictionary = MotionBudgetScene.estimate_motion_budget(
		{"mass": mass, "length": distance, "output": momentum, "joint_speed_cap": cap},
		{},
		rad_to_deg(1.0),
		0.0,
		1.0,
		"normal"
	)
	return float(budget.get("duration", 0.0))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var checked := 0
	var clamped_fast := []
	for raw_part in main._catalog_for("hero", "limb_muscle"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if main.has_method("_part_is_catalog_frozen") and bool(main._part_is_catalog_frozen("limb_muscle", part)):
			continue
		var drive_kind := String(main._joint_drive_kind_for_part(part, "limb_muscle"))
		if drive_kind == "rigid":
			continue
		var default_momentum := main._default_limb_allocated_momentum_for_part(part, "limb_muscle")
		var max_momentum := main._limb_momentum_max_for_part(part, "limb_muscle")
		var default_duration := _duration_for(main, part, "limb_muscle", default_momentum)
		var max_duration := _duration_for(main, part, "limb_muscle", max_momentum)
		var name := String(part.get("name", "LIMB"))
		if default_duration < 0.24:
			_fail("%s default motion duration is too close to instant: %.3f" % [name, default_duration])
		if max_duration < 0.24:
			clamped_fast.append("%s %.3f" % [name, max_duration])
		checked += 1
	if checked <= 0:
		_fail("No live driven limb entries checked.")
	if clamped_fast.size() > 0:
		_fail("Live limb max duration should not clamp to instant: %s" % ", ".join(clamped_fast))
	print("LIMB_MOTION_SPEED_BAND_PROBE ok checked=%d" % checked)
	quit()
