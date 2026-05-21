extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var summary: Dictionary = main._team_summary(1)
	var blank_bp: Dictionary = main._editor_current_blueprint()
	var blank_stats: Dictionary = main._editor_current_stats()
	var nodes := Array(Dictionary(blank_bp.get("custom_topology", {})).get("nodes", [])).size()
	if String(main.editor_canvas_mode) != "blank":
		_fail("TeamEdit did not enter blank canvas mode.")
	if nodes != 0:
		_fail("Blank canvas still contains topology nodes.")
	if int(blank_stats.get("cost", -1)) != 0:
		_fail("Blank canvas cost is not zero.")
	if int(summary.get("units", -1)) != 0:
		_fail("Initial Team Match roster is not empty.")
	if int(summary.get("cost", -1)) != 0:
		_fail("Initial Team Match roster cost is not zero.")
	if main._editor_team_order_entries(1).size() != MainScene.ROSTER_UNIT_CAP:
		_fail("Team overview does not expose ten editable slots.")
	print("TEAM_MATCH_BLANK_TEAM_PROBE mode=%s canvas_cost=%d team_units=%d team_cost=%d slots=%d" % [
		String(main.editor_canvas_mode),
		int(blank_stats.get("cost", -1)),
		int(summary.get("units", -1)),
		int(summary.get("cost", -1)),
		main._editor_team_order_entries(1).size(),
	])
	quit()
