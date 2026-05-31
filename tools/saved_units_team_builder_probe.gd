extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_saved_unit(main, name: String) -> Dictionary:
	var bp: Dictionary = main._blueprint_for(1, "hero", 0).duplicate(true)
	bp["unit_name"] = name
	return {"unit_library": true, "path": "probe://%s" % name, "role": "hero", "blueprint": bp, "unit_name": name}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var entry := _make_saved_unit(main, "Probe Team Unit A")
	var selected := [entry]
	if selected.size() != 1:
		_fail("Selected saved units should form a one-unit team draft.")
	var summary := main._saved_units_team_legality_summary(selected)
	if int(summary.get("count", 0)) != 1:
		_fail("Team legality summary should count the draft unit.")
	if int(Dictionary(summary.get("role_counts", {})).get("hero", 0)) < 1:
		_fail("Team draft should include a hero fixture.")
	print("SAVED_UNITS_TEAM_BUILDER_PROBE ok note=%s" % String(summary.get("note", "")))
	quit()
