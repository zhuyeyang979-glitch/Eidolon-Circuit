extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	var humanova_head := _find_component(main, "muscle", "HUMANOVA CONTROL HEAD")
	var ward_head := _find_component(main, "muscle", "CERAMIC WARD CONTROL HEAD")
	var tank_hull := _find_component(main, "muscle", "SPACE TANK HULL")
	var monster_hull := _find_component(main, "muscle", "MONSTER HULL TORSO")
	print("ATTITUDE_PROBE humanova=%.2f cipher=%.2f tank=%.2f monster=%.2f" % [
		main._torso_attitude_control_value(humanova_head),
		main._torso_attitude_control_value(ward_head),
		main._torso_attitude_control_value(tank_hull),
		main._torso_attitude_control_value(monster_hull),
	])
	quit()


func _find_component(main, slot_key: String, name: String) -> Dictionary:
	var catalog: Array = main.COMMON_CATALOG.get(slot_key, [])
	for raw_part in catalog:
		if raw_part is Dictionary and String(raw_part.get("name", "")).to_upper() == name.to_upper():
			return Dictionary(raw_part)
	return {}
