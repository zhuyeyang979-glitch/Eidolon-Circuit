extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, slot_key: String, part_name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", slot_key, part_name)
	if index < 0:
		_fail("Missing catalog part: %s/%s" % [slot_key, part_name])
	return main._selected_component("hero", slot_key, index)


func _expect_eq(label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		_fail("%s expected %s got %s" % [label, str(expected), str(actual)])


func _expect_close(label: String, actual: float, expected: float, tolerance: float = 0.01) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.3f got %.3f" % [label, expected, actual])


func _expect_gt(label: String, high: float, low: float) -> void:
	if high <= low:
		_fail("%s expected %.3f > %.3f" % [label, high, low])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var duel := _part(main, "muscle", "HUMANOVA DUEL CORE")
	var midfield := _part(main, "muscle", "SYNTAX MIDFIELD CORE")
	var stage := _part(main, "muscle", "FOLD STAGE TORSO")
	_expect_eq("duel shape", String(duel.get("shape", "")), "duelist_core")
	_expect_eq("midfield shape", String(midfield.get("shape", "")), "midfield_saddle")
	_expect_eq("stage shape", String(stage.get("shape", "")), "stage_chassis")
	_expect_eq("duel tier", String(duel.get("size_tier", "")), "S")
	_expect_eq("midfield tier", String(midfield.get("size_tier", "")), "M")
	_expect_eq("stage tier", String(stage.get("size_tier", "")), "L")
	_expect_eq("duel ports", int(duel.get("joint_ports", 0)), 4)
	_expect_eq("midfield ports", int(midfield.get("joint_ports", 0)), 5)
	_expect_eq("stage ports", int(stage.get("joint_ports", 0)), 6)
	_expect_gt("midfield mass over duel", float(midfield.get("mass", 0.0)), float(duel.get("mass", 0.0)))
	_expect_gt("stage mass over midfield", float(stage.get("mass", 0.0)), float(midfield.get("mass", 0.0)))
	_expect_gt("midfield hp over duel", float(midfield.get("hp", 0.0)), float(duel.get("hp", 0.0)))
	_expect_gt("stage hp over midfield", float(stage.get("hp", 0.0)), float(midfield.get("hp", 0.0)))
	_expect_gt("stage internal slots over duel", float(stage.get("torso_slots", 0)), float(duel.get("torso_slots", 0)))
	_expect_gt("stage software slots over midfield", float(stage.get("module_slots", 0)), float(midfield.get("module_slots", 0)))
	_expect_close("duel speed", float(duel.get("speed_mult", 0.0)), 1.12)

	var forearm := _part(main, "limb_muscle", "HUMANOVA FOREARM MYOMER")
	var thigh := _part(main, "limb_muscle", "HUMANOVA THIGH MYOMER")
	var steel := _part(main, "limb_muscle", "MONOCHROME STEEL SINEW")
	var colossus := _part(main, "limb_muscle", "COLOSSUS SINEW GIRDER")
	_expect_eq("forearm shape", String(forearm.get("shape", "")), "forearm_myomer")
	_expect_eq("thigh shape", String(thigh.get("shape", "")), "thigh_myomer")
	_expect_eq("steel shape", String(steel.get("shape", "")), "steel_sinew_beam")
	_expect_eq("colossus shape", String(colossus.get("shape", "")), "colossus_girder_muscle")
	_expect_eq("forearm tier", String(forearm.get("size_tier", "")), "S")
	_expect_eq("thigh tier", String(thigh.get("size_tier", "")), "M")
	_expect_eq("steel tier", String(steel.get("size_tier", "")), "M")
	_expect_eq("colossus tier", String(colossus.get("size_tier", "")), "XL")
	_expect_gt("thigh mass over forearm", float(thigh.get("mass", 0.0)), float(forearm.get("mass", 0.0)))
	_expect_gt("steel mass over thigh", float(steel.get("mass", 0.0)), float(thigh.get("mass", 0.0)))
	_expect_gt("colossus mass over steel", float(colossus.get("mass", 0.0)), float(steel.get("mass", 0.0)))
	_expect_gt("thigh hp over forearm", float(thigh.get("hp", 0.0)), float(forearm.get("hp", 0.0)))
	_expect_gt("steel hp over thigh", float(steel.get("hp", 0.0)), float(thigh.get("hp", 0.0)))
	_expect_gt("colossus hp over steel", float(colossus.get("hp", 0.0)), float(steel.get("hp", 0.0)))
	_expect_gt("thigh load over forearm", float(thigh.get("load_capacity", 0.0)), float(forearm.get("load_capacity", 0.0)))
	_expect_gt("steel load over thigh", float(steel.get("load_capacity", 0.0)), float(thigh.get("load_capacity", 0.0)))
	_expect_gt("colossus load over steel", float(colossus.get("load_capacity", 0.0)), float(steel.get("load_capacity", 0.0)))
	_expect_eq("forearm ends", int(forearm.get("connection_ends", 0)), 2)
	_expect_eq("thigh ends", int(thigh.get("connection_ends", 0)), 2)
	_expect_eq("steel ends", int(steel.get("connection_ends", 0)), 2)
	_expect_eq("colossus ends", int(colossus.get("connection_ends", 0)), 2)

	print("TORSO_LIMB_STAT_SHAPE_PROBE ok torso_mass=%.1f/%.1f/%.1f limb_mass=%.1f/%.1f/%.1f/%.1f" % [
		float(duel.get("mass", 0.0)),
		float(midfield.get("mass", 0.0)),
		float(stage.get("mass", 0.0)),
		float(forearm.get("mass", 0.0)),
		float(thigh.get("mass", 0.0)),
		float(steel.get("mass", 0.0)),
		float(colossus.get("mass", 0.0)),
	])
	quit()
