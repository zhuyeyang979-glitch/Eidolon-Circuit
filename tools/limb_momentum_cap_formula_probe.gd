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
	for raw_part in main._catalog_for("hero", "limb_muscle"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if main.has_method("_part_is_catalog_frozen") and bool(main._part_is_catalog_frozen("limb_muscle", part)):
			continue
		var drive_kind := String(main._joint_drive_kind_for_part(part, "limb_muscle"))
		if drive_kind == "rigid":
			continue
		var name := String(part.get("name", "LIMB"))
		var min_momentum := main._limb_momentum_min_for_part(part, "limb_muscle")
		var default_momentum := main._default_limb_allocated_momentum_for_part(part, "limb_muscle")
		var max_momentum := main._limb_momentum_max_for_part(part, "limb_muscle")
		var base_momentum := main._joint_output_momentum_base_for_part(part, "limb_muscle")
		if not (min_momentum + 0.001 < default_momentum and default_momentum <= max_momentum + 0.001):
			_fail("%s must satisfy min < default <= max; got %.2f %.2f %.2f" % [name, min_momentum, default_momentum, max_momentum])
		if base_momentum > max_momentum + 0.001:
			_fail("%s hidden base output %.2f exceeds visible max %.2f" % [name, base_momentum, max_momentum])
		if min_momentum > 0.0 and max_momentum / min_momentum > 8.0:
			_fail("%s momentum range is too wide after cap shrink: %.2f..%.2f" % [name, min_momentum, max_momentum])
		checked += 1
	if checked <= 0:
		_fail("No live driven limb entries checked.")
	print("LIMB_MOMENTUM_CAP_FORMULA_PROBE ok checked=%d" % checked)
	quit()
