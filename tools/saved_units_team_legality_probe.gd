extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var empty_summary := main._saved_units_team_legality_summary([])
	if bool(empty_summary.get("valid", true)):
		_fail("Empty team draft should be illegal.")
	var entry := {
		"role": "hero",
		"path": "probe://hero",
		"unit_name": "Probe Legal Hero",
		"blueprint": main._make_editor_blank_blueprint("hero"),
	}
	var one_summary := main._saved_units_team_legality_summary([entry])
	if int(Dictionary(one_summary.get("role_counts", {})).get("hero", 0)) != 1:
		_fail("Legality summary should count hero entries.")
	print("SAVED_UNITS_TEAM_LEGALITY_PROBE ok empty=%s one=%s" % [String(empty_summary.get("note", "")), String(one_summary.get("note", ""))])
	quit()
